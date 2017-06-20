// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.events;

import flash.errors.Error;
import flash.geom.Point;
import starling.core.Starling;
import starling.display.DisplayObject;
import starling.display.Stage;
import flash.Lib;
import openfl.Vector;

typedef HoverData = {
  var touch:Touch;
  var target:DisplayObject;
  var bubbleChain:Vector<EventDispatcher>;
};

/** The TouchProcessor is used to convert mouse and touch events of the conventional
 *  Flash stage to Starling's TouchEvents.
 *
 *  <p>The Starling instance listens to mouse and touch events on the native stage. The
 *  attributes of those events are enqueued (right as they are happening) in the
 *  TouchProcessor.</p>
 *
 *  <p>Once per frame, the "advanceTime" method is called. It analyzes the touch queue and
 *  figures out which touches are active at that moment; the properties of all touch objects
 *  are updated accordingly.</p>
 *
 *  <p>Once the list of touches has been finalized, the "processTouches" method is called
 *  (that might happen several times in one "advanceTime" execution; no information is
 *  discarded). It's responsible for dispatching the actual touch events to the Starling
 *  display tree.</p>
 *
 *  <strong>Subclassing TouchProcessor</strong>
 *
 *  <p>You can extend the TouchProcessor if you need to have more control over touch and
 *  mouse input. For example, you could filter the touches by overriding the "processTouches"
 *  method, throwing away any touches you're not interested in and passing the rest to the
 *  super implementation.</p>
 *
 *  <p>To use your custom TouchProcessor, assign it to the "Starling.touchProcessor"
 *  property.</p>
 *
 *  <p>Note that you should not dispatch TouchEvents yourself, since they are
 *  much more complex to handle than conventional events (e.g. it must be made sure that an
 *  object receives a TouchEvent only once, even if it's manipulated with several fingers).
 *  Always use the base implementation of "processTouches" to let them be dispatched. That
 *  said: you can always dispatch your own custom events, of course.</p>
 */
class TouchProcessor
{
  public var simulateMultitouch(get, set):Bool;
  public var multitapTime(get, set):Float;
  public var multitapDistance(get, set):Float;
  public var root(get, set):DisplayObject;
  public var stage(get, never):Stage;
  public var numCurrentTouches(get, never):Int;

  private var _stage:Stage = null;
  private var _root:DisplayObject = null;
  private var _elapsedTime:Float = 0;
  private var _lastTaps:Vector<Touch> = null;
  private var _shiftDown:Bool = false;
  private var _ctrlDown:Bool = false;
  private var _multitapTime:Float = 0.3;
  private var _multitapDistance:Float = 25;
  private var _touchEvent:TouchEvent = null;

  private var _touchMarker:TouchMarker = null;
  private var _simulateMultitouch:Bool = false;

  /** A vector of arrays with the arguments that were passed to the "enqueue"
   *  method (the oldest being at the end of the vector). */
  private var _queue:Vector<Array<Dynamic>>;

  /** The list of all currently active touches. */
  private var _currentTouches:Vector<Touch>;

  /** Helper objects. */
  private static var sUpdatedTouches:Vector<Touch> = new Vector();
  private static var sHoveringTouchData:Vector<HoverData> = new Vector();
  private static var sHelperPoint:Point = new Point();

  /** Creates a new TouchProcessor that will dispatch events to the given stage. */
  public function new(stage:Stage)
  {
    _root = _stage = stage;
    _elapsedTime = 0.0;
    _currentTouches = new Vector();
    _queue = new Vector();
    _lastTaps = new Vector();
    _touchEvent = new TouchEvent(TouchEvent.TOUCH);

    _stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
    _stage.addEventListener(KeyboardEvent.KEY_UP, onKey);
    monitorInterruptions(true);
  }

  /** Removes all event handlers on the stage and releases any acquired resources. */
  public function dispose():Void
  {
    monitorInterruptions(false);
    _stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey);
    _stage.removeEventListener(KeyboardEvent.KEY_UP, onKey);
    if (_touchMarker != null)
    {
      _touchMarker.dispose();
    }
  }

  /** Analyzes the current touch queue and processes the list of current touches, emptying
   *  the queue while doing so. This method is called by Starling once per frame. */
  public function advanceTime(passedTime:Float):Void
  {
    var i:Int;
    var touch:Touch;

    _elapsedTime += passedTime;
    sUpdatedTouches.length = 0;

    // remove old taps
    if (_lastTaps.length > 0)
    {
      i = _lastTaps.length - 1;
      while (i >= 0)
      {
        if (_elapsedTime - _lastTaps[i].timestamp > _multitapTime)
        {
          _lastTaps.splice(i, 1);
        }
        --i;
      }
    }

    while (_queue.length > 0)
    {
      // Set touches that were new or moving to phase 'stationary'.
      for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(_currentTouches) type: Vector<Touch> */ in _currentTouches)
      {
        if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED)
        {
          touch.phase = TouchPhase.STATIONARY;
        }
      }

      // analyze new touches, but each ID only once
      while (_queue.length > 0 &&
      !containsTouchWithID(sUpdatedTouches, _queue[_queue.length - 1][0]))
      {
        var touchArgs:Array<Dynamic> = _queue.pop();
        touch = createOrUpdateTouch(
                touchArgs[0], touchArgs[1], touchArgs[2], touchArgs[3],
                touchArgs[4], touchArgs[5], touchArgs[6]
        );

        sUpdatedTouches[sUpdatedTouches.length] = touch;
      }

      // process the current set of touches (i.e. dispatch touch events)
      processTouches(sUpdatedTouches, _shiftDown, _ctrlDown);

      // remove ended touches
      i = _currentTouches.length - 1;
      while (i >= 0)
      {
        if (_currentTouches[i].phase == TouchPhase.ENDED)
        {
          _currentTouches.splice(i, 1);
        }
        --i;
      }

      sUpdatedTouches.length = 0;
    }
  }

  /** Dispatches TouchEvents to the display objects that are affected by the list of
   *  given touches. Called internally by "advanceTime". To calculate updated targets,
   *  the method will call "hitTest" on the "root" object.
   *
   *  @param touches    a list of all touches that have changed just now.
   *  @param shiftDown  indicates if the shift key was down when the touches occurred.
   *  @param ctrlDown   indicates if the ctrl or cmd key was down when the touches occurred.
   */
  private function processTouches(touches:Vector<Touch>,
      shiftDown:Bool, ctrlDown:Bool):Void
  {
    sHoveringTouchData.length = 0;

    // the same touch event will be dispatched to all targets;
    // the 'dispatch' method makes sure each bubble target is visited only once.
    _touchEvent.resetTo(TouchEvent.TOUCH, _currentTouches, shiftDown, ctrlDown);

    // hit test our updated touches
    for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(touches) type: Vector<Touch> */ in touches)
    {
      // hovering touches need special handling (see below)
      if (touch.phase == TouchPhase.HOVER && touch.target != null)
      {
        sHoveringTouchData[sHoveringTouchData.length] = {
              touch: touch,
              target: touch.target,
              bubbleChain: touch.bubbleChain
            };
      }  // avoiding 'push'

      if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.BEGAN)
      {
        sHelperPoint.setTo(touch.globalX, touch.globalY);
        touch.target = _root.hitTest(sHelperPoint);
      }
    }

    // if the target of a hovering touch changed, we dispatch the event to the previous
    // target to notify it that it's no longer being hovered over.
    for (touchData/* AS3HX WARNING could not determine type for var: touchData exp: EIdent(sHoveringTouchData) type: Vector<Dynamic> */ in sHoveringTouchData)
    {
      if (touchData.touch.target != touchData.target)
      {
        _touchEvent.dispatch(touchData.bubbleChain);
      }
    }

    // dispatch events for the rest of our updated touches
    for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(touches) type: Vector<Touch> */ in touches)
    {
      touch.dispatchEvent(_touchEvent);
    }

    // clean up any references
    _touchEvent.resetTo(TouchEvent.TOUCH);
  }

  /** Enqueues a new touch our mouse event with the given properties. */
  public function enqueue(touchID:Int, phase:String, globalX:Float, globalY:Float,
      pressure:Float = 1.0, width:Float = 1.0, height:Float = 1.0):Void
  {
    _queue.unshift([touchID, phase, globalX, globalY, pressure, width, height]);

    // multitouch simulation (only with mouse)
    if (_ctrlDown && _touchMarker != null && touchID == 0)
    {
      _touchMarker.moveMarker(globalX, globalY, _shiftDown);
      _queue.unshift([1, phase, _touchMarker.mockX, _touchMarker.mockY]);
    }
  }

  /** Enqueues an artificial touch that represents the mouse leaving the stage.
   *
   *  <p>On OS X, we get mouse events from outside the stage; on Windows, we do not.
   *  This method enqueues an artificial hover point that is just outside the stage.
   *  That way, objects listening for HOVERs over them will get notified everywhere.</p>
   */
  public function enqueueMouseLeftStage():Void
  {
    var mouse:Touch = getCurrentTouch(0);
    if (mouse == null || mouse.phase != TouchPhase.HOVER)
    {
      return;
    }

    var offset:Int = 1;
    var exitX:Float = mouse.globalX;
    var exitY:Float = mouse.globalY;
    var distLeft:Float = mouse.globalX;
    var distRight:Float = _stage.stageWidth - distLeft;
    var distTop:Float = mouse.globalY;
    var distBottom:Float = _stage.stageHeight - distTop;
    var minDist:Float = Math.min(Math.min(Math.min(distLeft, distRight), distTop), distBottom);

    // the new hover point should be just outside the stage, near the point where
    // the mouse point was last to be seen.

    if (minDist == distLeft)
    {
      exitX = -offset;
    }
    else
    {
      if (minDist == distRight)
      {
        exitX = _stage.stageWidth + offset;
      }
      else
      {
        if (minDist == distTop)
        {
          exitY = -offset;
        }
        else
        {
          exitY = _stage.stageHeight + offset;
        }
      }
    }

    enqueue(0, TouchPhase.HOVER, exitX, exitY);
  }

  /** Force-end all current touches. Changes the phase of all touches to 'ENDED' and
   *  immediately dispatches a new TouchEvent (if touches are present). Called automatically
   *  when the app receives a 'DEACTIVATE' event. */
  public function cancelTouches():Void
  {
    if (_currentTouches.length > 0)
    {
      // abort touches
      for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(_currentTouches) type: Vector<Touch> */ in _currentTouches)
      {
        if (touch.phase == TouchPhase.BEGAN || touch.phase == TouchPhase.MOVED ||
          touch.phase == TouchPhase.STATIONARY)
        {
          touch.phase = TouchPhase.ENDED;
          touch.cancelled = true;
        }
      }

      // dispatch events
      processTouches(_currentTouches, _shiftDown, _ctrlDown);
    }

    // purge touches
    _currentTouches.length = 0;
    _queue.length = 0;
  }

  private function createOrUpdateTouch(touchID:Int, phase:String,
      globalX:Float, globalY:Float,
      pressure:Float = 1.0,
      width:Float = 1.0, height:Float = 1.0):Touch
  {
    var touch:Touch = getCurrentTouch(touchID);

    if (touch == null)
    {
      touch = new Touch(touchID);
      addCurrentTouch(touch);
    }

    touch.globalX = globalX;
    touch.globalY = globalY;
    touch.phase = phase;
    touch.timestamp = _elapsedTime;
    touch.pressure = pressure;
    touch.width = width;
    touch.height = height;

    if (phase == TouchPhase.BEGAN)
    {
      updateTapCount(touch);
    }

    return touch;
  }

  private function updateTapCount(touch:Touch):Void
  {
    var nearbyTap:Touch = null;
    var minSqDist:Float = _multitapDistance * _multitapDistance;

    for (tap/* AS3HX WARNING could not determine type for var: tap exp: EIdent(_lastTaps) type: Vector<Touch> */ in _lastTaps)
    {
      var sqDist:Float = Math.pow(tap.globalX - touch.globalX, 2) +
      Math.pow(tap.globalY - touch.globalY, 2);
      if (sqDist <= minSqDist)
      {
        nearbyTap = tap;
        break;
      }
    }

    if (nearbyTap != null)
    {
      touch.tapCount = nearbyTap.tapCount + 1;
      _lastTaps.splice(_lastTaps.indexOf(nearbyTap), 1);
    }
    else
    {
      touch.tapCount = 1;
    }

    _lastTaps[_lastTaps.length] = touch.clone();
  }

  private function addCurrentTouch(touch:Touch):Void
  {
    var i:Int = _currentTouches.length - 1;
    while (i >= 0)
    {
      if (_currentTouches[i].id == touch.id)
      {
        _currentTouches.splice(i, 1);
      }
      --i;
    }

    _currentTouches[_currentTouches.length] = touch;
  }

  private function getCurrentTouch(touchID:Int):Touch
  {
    for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(_currentTouches) type: Vector<Touch> */ in _currentTouches)
    {
      if (touch.id == touchID)
      {
        return touch;
      }
    }

    return null;
  }

  private function containsTouchWithID(touches:Vector<Touch>, touchID:Int):Bool
  {
    for (touch/* AS3HX WARNING could not determine type for var: touch exp: EIdent(touches) type: Vector<Touch> */ in touches)
    {
      if (touch.id == touchID)
      {
        return true;
      }
    }

    return false;
  }

  /** Indicates if multitouch simulation should be activated. When the user presses
   *  ctrl/cmd (and optionally shift), he'll see a second touch cursor that mimics the first.
   *  That's an easy way to develop and test multitouch when there's only a mouse available.
   */
  private function get_simulateMultitouch():Bool
  {
    return _simulateMultitouch;
  }
  private function set_simulateMultitouch(value:Bool):Bool
  {
    if (simulateMultitouch == value)
    {
      return value;
    }  // no change

    _simulateMultitouch = value;
    var target:Starling = Starling.current;

    var createTouchMarker:Void->Void = null;
    createTouchMarker = function():Void
    {
      target.removeEventListener(Event.CONTEXT3D_CREATE, createTouchMarker);

      if (_touchMarker == null)
      {
        _touchMarker = new TouchMarker();
        _touchMarker.visible = false;
        _stage.addChild(_touchMarker);
      }
    }

    if (value && _touchMarker == null)
    {
      if (Starling.current.contextValid)
      {
        createTouchMarker();
      }
      else
      {
        target.addEventListener(Event.CONTEXT3D_CREATE, createTouchMarker);
      }
    }
    else
    {
      if (!value && _touchMarker != null)
      {
        _touchMarker.removeFromParent(true);
        _touchMarker = null;
      }
    }

    return value;
  }

  /** The time period (in seconds) in which two touches must occur to be recognized as
   *  a multitap gesture. */
  private function get_multitapTime():Float
  {
    return _multitapTime;
  }
  private function set_multitapTime(value:Float):Float
  {
    _multitapTime = value;
    return value;
  }

  /** The distance (in points) describing how close two touches must be to each other to
   *  be recognized as a multitap gesture. */
  private function get_multitapDistance():Float
  {
    return _multitapDistance;
  }
  private function set_multitapDistance(value:Float):Float
  {
    _multitapDistance = value;
    return value;
  }

  /** The base object that will be used for hit testing. Per default, this reference points
   *  to the stage; however, you can limit touch processing to certain parts of your game
   *  by assigning a different object. */
  private function get_root():DisplayObject
  {
    return _root;
  }
  private function set_root(value:DisplayObject):DisplayObject
  {
    _root = value;
    return value;
  }

  /** The stage object to which the touch events are (per default) dispatched. */
  private function get_stage():Stage
  {
    return _stage;
  }

  /** Returns the number of fingers / touch points that are currently on the stage. */
  private function get_numCurrentTouches():Int
  {
    return _currentTouches.length;
  }

  // keyboard handling

  private function onKey(event:KeyboardEvent):Void
  {
    if (event.keyCode == 17 || event.keyCode == 15)
    {
      // ctrl or cmd key
      {
        var wasCtrlDown:Bool = _ctrlDown;
        _ctrlDown = event.type == KeyboardEvent.KEY_DOWN;

        if (_touchMarker != null && wasCtrlDown != _ctrlDown)
        {
          _touchMarker.visible = _ctrlDown;
          _touchMarker.moveCenter(_stage.stageWidth / 2, _stage.stageHeight / 2);

          var mouseTouch:Touch = getCurrentTouch(0);
          var mockedTouch:Touch = getCurrentTouch(1);

          if (mouseTouch != null)
          {
            _touchMarker.moveMarker(mouseTouch.globalX, mouseTouch.globalY);
          }

          if (wasCtrlDown && mockedTouch != null && mockedTouch.phase != TouchPhase.ENDED)
          {
            // end active touch ...
            _queue.unshift([1, TouchPhase.ENDED, mockedTouch.globalX, mockedTouch.globalY]);
          }
          else
          {
            if (_ctrlDown && mouseTouch != null)
            {
              // ... or start new one
              if (mouseTouch.phase == TouchPhase.HOVER || mouseTouch.phase == TouchPhase.ENDED)
              {
                _queue.unshift([1, TouchPhase.HOVER, _touchMarker.mockX, _touchMarker.mockY]);
              }
              else
              {
                _queue.unshift([1, TouchPhase.BEGAN, _touchMarker.mockX, _touchMarker.mockY]);
              }
            }
          }
        }
      }
    }
    else
    {
      if (event.keyCode == 16)
      {
        // shift key
        {
          _shiftDown = event.type == KeyboardEvent.KEY_DOWN;
        }
      }
    }
  }

  // interruption handling

  private function monitorInterruptions(enable:Bool):Void
  {
    // if the application moves into the background or is interrupted (e.g. through
    // an incoming phone call), we need to abort all touches.

    try
    {
      if (enable)
        Lib.current.stage.addEventListener("deactivate", onInterruption, false, 0, true);
      else
        Lib.current.stage.removeEventListener("deactivate", onInterruption);
    }
    catch (e:Error) {} // we're not running in AIR
  }

  private function onInterruption(event:Dynamic):Void
  {
    cancelTouches();
  }
}

