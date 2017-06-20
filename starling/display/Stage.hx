// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.display;

import flash.display.BitmapData;
import flash.display3D.Context3D;
import flash.errors.IllegalOperationError;
import flash.geom.Matrix;
import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import starling.core.Starling;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.filters.FragmentFilter;
import starling.rendering.Painter;
import starling.rendering.RenderState;
import starling.utils.MatrixUtil;
import starling.utils.RectangleUtil;
import openfl.Vector;

/** Dispatched when the Flash container is resized. */
@:meta(Event(name="resize",type="starling.events.ResizeEvent"))

/** A Stage represents the root of the display tree.
 *  Only objects that are direct or indirect children of the stage will be rendered.
 *
 *  <p>This class represents the Starling version of the stage. Don't confuse it with its
 *  Flash equivalent: while the latter contains objects of the type
 *  <code>flash.display.DisplayObject</code>, the Starling stage contains only objects of the
 *  type <code>starling.display.DisplayObject</code>. Those classes are not compatible, and
 *  you cannot exchange one type with the other.</p>
 *
 *  <p>A stage object is created automatically by the <code>Starling</code> class. Don't
 *  create a Stage instance manually.</p>
 *
 *  <strong>Keyboard Events</strong>
 *
 *  <p>In Starling, keyboard events are only dispatched at the stage. Add an event listener
 *  directly to the stage to be notified of keyboard events.</p>
 *
 *  <strong>Resize Events</strong>
 *
 *  <p>When the Flash player is resized, the stage dispatches a <code>ResizeEvent</code>. The
 *  event contains properties containing the updated width and height of the Flash player.</p>
 *
 *  @see starling.events.KeyboardEvent
 *  @see starling.events.ResizeEvent
 *
 */
class Stage extends DisplayObjectContainer
{
  public var color(get, set):Int;
  public var stageWidth(get, set):Int;
  public var stageHeight(get, set):Int;
  public var starling(get, never):Starling;
  public var focalLength(get, set):Float;
  public var fieldOfView(get, set):Float;
  public var projectionOffset(get, set):Point;
  public var cameraPosition(get, never):Vector3D;

  private var _width:Int = 0;
  private var _height:Int = 0;
  private var _color:Int = 0;
  private var _fieldOfView:Float = 0;
  private var _projectionOffset:Point = null;
  private var _cameraPosition:Vector3D = null;
  private var _enterFrameEvent:EnterFrameEvent = null;
  private var _enterFrameListeners:Vector<DisplayObject> = null;

  // helper objects
  private static var sMatrix:Matrix = new Matrix();
  private static var sMatrix3D:Matrix3D = new Matrix3D();

  /** @private */
  public function new(width:Int, height:Int, color:Int = 0)
  {
    super();
    _width = width;
    _height = height;
    _color = color;
    _fieldOfView = 1.0;
    _projectionOffset = new Point();
    _cameraPosition = new Vector3D();
    _enterFrameEvent = new EnterFrameEvent(Event.ENTER_FRAME, 0.0);
    _enterFrameListeners = new Vector();
  }

  /** @inheritDoc */
  public function advanceTime(passedTime:Float):Void
  {
    _enterFrameEvent.reset(Event.ENTER_FRAME, false, passedTime);
    broadcastEvent(_enterFrameEvent);
  }

  /** Returns the object that is found topmost beneath a point in stage coordinates, or
   *  the stage itself if nothing else is found. */
  override public function hitTest(localPoint:Point):DisplayObject
  {
    if (!visible || !touchable)
    {
      return null;
    }

    // locations outside of the stage area shouldn't be accepted
    if (localPoint.x < 0 || localPoint.x > _width ||
      localPoint.y < 0 || localPoint.y > _height)
    {
      return null;
    }

    // if nothing else is hit, the stage returns itself as target
    var target:DisplayObject = super.hitTest(localPoint);
    return (target != null) ? target:this;
  }

  /** Draws the complete stage into a BitmapData object.
   *
   *  <p>If you encounter problems with transparency, start Starling in BASELINE profile
   *  (or higher). BASELINE_CONSTRAINED might not support transparency on all platforms.
   *  </p>
   *
   *  @param destination  If you pass null, the object will be created for you.
   *                      If you pass a BitmapData object, it should have the size of the
   *                      back buffer (which is accessible via the respective properties
   *                      on the Starling instance).
   *  @param transparent  If enabled, empty areas will appear transparent; otherwise, they
   *                      will be filled with the stage color.
   */
  public function drawToBitmapData(destination:BitmapData = null,
      transparent:Bool = true):BitmapData
  {
    var painter:Painter = Starling.painter_();
    var state:RenderState = painter.state;
    var context:Context3D = painter.context;

    if (destination == null)
    {
      var width:Int = context.backBufferWidth;
      var height:Int = context.backBufferHeight;
      destination = new BitmapData(width, height, transparent);
    }

    painter.pushState();
    state.renderTarget = null;
    state.setProjectionMatrix(0, 0, _width, _height, _width, _height, cameraPosition);

    if (transparent)
    {
      painter.clear();
    }
    else
    {
      painter.clear(_color, 1);
    }

    render(painter);
    painter.finishMeshBatch();

    context.drawToBitmapData(destination);
    context.present();  // required on some platforms to avoid flickering

    painter.popState();
    return destination;
  }

  /** Returns the stage bounds (i.e. not the bounds of its contents, but the rectangle
   *  spawned up by 'stageWidth' and 'stageHeight') in another coordinate system. */
  public function getStageBounds(targetSpace:DisplayObject, out:Rectangle = null):Rectangle
  {
    if (out == null)
    {
      out = new Rectangle();
    }

    out.setTo(0, 0, _width, _height);
    getTransformationMatrix(targetSpace, sMatrix);

    return RectangleUtil.getBounds(out, sMatrix, out);
  }

  // camera positioning

  /** Returns the position of the camera within the local coordinate system of a certain
   *  display object. If you do not pass a space, the method returns the global position.
   *  To change the position of the camera, you can modify the properties 'fieldOfView',
   *  'focalDistance' and 'projectionOffset'.
   */
  public function getCameraPosition(space:DisplayObject = null, out:Vector3D = null):Vector3D
  {
    getTransformationMatrix3D(space, sMatrix3D);

    return MatrixUtil.transformCoords3D(sMatrix3D,
        _width / 2 + _projectionOffset.x, _height / 2 + _projectionOffset.y,
        -focalLength, out
    );
  }

  // enter frame event optimization

  /** @private */
  @:allow(starling.display)
  private function addEnterFrameListener(listener:DisplayObject):Void
  {
    var index:Int = _enterFrameListeners.indexOf(listener);
    if (index < 0)
    {
      _enterFrameListeners[_enterFrameListeners.length] = listener;
    }
  }

  /** @private */
  @:allow(starling.display)
  private function removeEnterFrameListener(listener:DisplayObject):Void
  {
    var index:Int = _enterFrameListeners.indexOf(listener);
    if (index >= 0)
    {
      _enterFrameListeners.splice(index, 1);
    }
  }

  /** @private */
  @:allow(starling.display)
  override private function getChildEventListeners(object:DisplayObject, eventType:String,
      listeners:Vector<DisplayObject>):Void
  {
    if (eventType == Event.ENTER_FRAME && object == this)
    {
      var i:Int = 0;
      var length:Int = _enterFrameListeners.length;
      while (i < length)
      {
        listeners[listeners.length] = _enterFrameListeners[i];
        ++i;
      }
    }
    else
    {
      super.getChildEventListeners(object, eventType, listeners);
    }
  }

  // properties

  /** @private */
  override private function set_width(value:Float):Float
  {
    throw new IllegalOperationError("Cannot set width of stage");
    return value;
  }

  /** @private */
  override private function set_height(value:Float):Float
  {
    throw new IllegalOperationError("Cannot set height of stage");
    return value;
  }

  /** @private */
  override private function set_x(value:Float):Float
  {
    throw new IllegalOperationError("Cannot set x-coordinate of stage");
    return value;
  }

  /** @private */
  override private function set_y(value:Float):Float
  {
    throw new IllegalOperationError("Cannot set y-coordinate of stage");
    return value;
  }

  /** @private */
  override private function set_scaleX(value:Float):Float
  {
    throw new IllegalOperationError("Cannot scale stage");
    return value;
  }

  /** @private */
  override private function set_scaleY(value:Float):Float
  {
    throw new IllegalOperationError("Cannot scale stage");
    return value;
  }

  /** @private */
  override private function set_rotation(value:Float):Float
  {
    throw new IllegalOperationError("Cannot rotate stage");
    return value;
  }

  /** @private */
  override private function set_skewX(value:Float):Float
  {
    throw new IllegalOperationError("Cannot skew stage");
    return value;
  }

  /** @private */
  override private function set_skewY(value:Float):Float
  {
    throw new IllegalOperationError("Cannot skew stage");
    return value;
  }

  /** @private */
  override private function set_filter(value:FragmentFilter):FragmentFilter
  {
    throw new IllegalOperationError("Cannot add filter to stage. Add it to 'root' instead!");
    return value;
  }

  /** The background color of the stage. */
  private function get_color():Int
  {
    return _color;
  }
  private function set_color(value:Int):Int
  {
    _color = value;
    return value;
  }

  /** The width of the stage coordinate system. Change it to scale its contents relative
   *  to the <code>viewPort</code> property of the Starling object. */
  private function get_stageWidth():Int
  {
    return _width;
  }
  private function set_stageWidth(value:Int):Int
  {
    _width = value;
    return value;
  }

  /** The height of the stage coordinate system. Change it to scale its contents relative
   *  to the <code>viewPort</code> property of the Starling object. */
  private function get_stageHeight():Int
  {
    return _height;
  }
  private function set_stageHeight(value:Int):Int
  {
    _height = value;
    return value;
  }

  /** The Starling instance this stage belongs to. */
  private function get_starling():Starling
  {
    var instances:Vector<Starling> = Starling.all;
    var numInstances:Int = instances.length;

    for (i in 0...numInstances)
    {
      if (instances[i].stage == this)
      {
        return instances[i];
      }
    }

    return null;
  }

  /** The distance between the stage and the camera. Changing this value will update the
   *  field of view accordingly. */
  private function get_focalLength():Float
  {
    return _width / (2 * Math.tan(_fieldOfView / 2));
  }

  private function set_focalLength(value:Float):Float
  {
    _fieldOfView = 2 * Math.atan(stageWidth / (2 * value));
    return value;
  }

  /** Specifies an angle (radian, between zero and PI) for the field of view. This value
   *  determines how strong the perspective transformation and distortion apply to a Sprite3D
   *  object.
   *
   *  <p>A value close to zero will look similar to an orthographic projection; a value
   *  close to PI results in a fisheye lens effect. If the field of view is set to 0 or PI,
   *  nothing is seen on the screen.</p>
   *
   *  @default 1.0
   */
  private function get_fieldOfView():Float
  {
    return _fieldOfView;
  }
  private function set_fieldOfView(value:Float):Float
  {
    _fieldOfView = value;
    return value;
  }

  /** A vector that moves the camera away from its default position in the center of the
   *  stage. Use this property to change the center of projection, i.e. the vanishing
   *  point for 3D display objects. <p>CAUTION: not a copy, but the actual object!</p>
   */
  private function get_projectionOffset():Point
  {
    return _projectionOffset;
  }
  private function set_projectionOffset(value:Point):Point
  {
    _projectionOffset.setTo(value.x, value.y);
    return value;
  }

  /** The global position of the camera. This property can only be used to find out the
   *  current position, but not to modify it. For that, use the 'projectionOffset',
   *  'fieldOfView' and 'focalLength' properties. If you need the camera position in
   *  a certain coordinate space, use 'getCameraPosition' instead.
   *
   *  <p>CAUTION: not a copy, but the actual object!</p>
   */
  private function get_cameraPosition():Vector3D
  {
    return getCameraPosition(null, _cameraPosition);
  }
}