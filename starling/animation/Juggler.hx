// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.animation;

import flash.errors.ArgumentError;
import haxe.Constraints.Function;
import starling.events.Event;
import starling.events.EventDispatcher;
import openfl.Vector;

/** The Juggler takes objects that implement IAnimatable (like Tweens) and executes them.
 *
 *  <p>A juggler is a simple object. It does no more than saving a list of objects implementing
 *  "IAnimatable" and advancing their time if it is told to do so (by calling its own
 *  "advanceTime"-method). When an animation is completed, it throws it away.</p>
 *
 *  <p>There is a default juggler available at the Starling class:</p>
 *
 *  <pre>
 *  var juggler:Juggler = Starling.juggler;
 *  </pre>
 *
 *  <p>You can create juggler objects yourself, just as well. That way, you can group
 *  your game into logical components that handle their animations independently. All you have
 *  to do is call the "advanceTime" method on your custom juggler once per frame.</p>
 *
 *  <p>Another handy feature of the juggler is the "delayCall"-method. Use it to
 *  execute a function at a later time. Different to conventional approaches, the method
 *  will only be called when the juggler is advanced, giving you perfect control over the
 *  call.</p>
 *
 *  <pre>
 *  juggler.delayCall(object.removeFromParent, 1.0);
 *  juggler.delayCall(object.addChild, 2.0, theChild);
 *  juggler.delayCall(function():void { rotation += 0.1; }, 3.0);
 *  </pre>
 *
 *  @see Tween
 *  @see DelayedCall
 */
class Juggler implements IAnimatable
{
  public var elapsedTime(get, never):Float;
  public var timeScale(get, set):Float;
  private var objects(get, never):Vector<IAnimatable>;

  private var _objects:Vector<IAnimatable> = null;
  private var _objectIDs:Map<IAnimatable, Int> = null;
  private var _elapsedTime:Float = 0;
  private var _timeScale:Float = 0;

  private static var sCurrentObjectID:Int = 0;

  /** Create an empty juggler. */
  public function new()
  {
    _elapsedTime = 0;
    _timeScale = 1.0;
    _objects = new Vector();
    _objectIDs = new Map();
  }

  /** Adds an object to the juggler.
   *
   *  @return Unique numeric identifier for the animation. This identifier may be used
   *          to remove the object via <code>removeByID()</code>.
   */
  public function add(object:IAnimatable):Int
  {
    return addWithID(object, getNextID());
  }

  private function addWithID(object:IAnimatable, objectID:Int):Int
  {
    if (object != null && !_objectIDs.exists(object))
    {
      var dispatcher:EventDispatcher = try cast(object, EventDispatcher) catch(e:Dynamic) null;
      if (dispatcher != null)
      {
        dispatcher.addEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
      }

      _objects[_objects.length] = object;
      _objectIDs[object] = objectID;

      return objectID;
    }
    else
    {
      return 0;
    }
  }

  /** Determines if an object has been added to the juggler. */
  public function contains(object:IAnimatable):Bool
  {
    return _objectIDs.exists(object);
  }

  /** Removes an object from the juggler.
   *
   *  @return The (now meaningless) unique numeric identifier for the animation, or zero
   *          if the object was not found.
   */
  public function remove(object:IAnimatable):Int
  {
    var objectID:Int = 0;

    if (object != null && _objectIDs.exists(object))
    {
      var dispatcher:EventDispatcher = try cast(object, EventDispatcher) catch(e:Dynamic) null;
      if (dispatcher != null)
      {
        dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
      }

      var index:Int = _objects.indexOf(object);
      _objects[index] = null;

      objectID = _objectIDs[object];
      _objectIDs.remove(object);
    }

    return objectID;
  }

  /** Removes an object from the juggler, identified by the unique numeric identifier you
   *  received when adding it.
   *
   *  <p>It's not uncommon that an animatable object is added to a juggler repeatedly,
   *  e.g. when using an object-pool. Thus, when using the <code>remove</code> method,
   *  you might accidentally remove an object that has changed its context. By using
   *  <code>removeByID</code> instead, you can be sure to avoid that, since the objectID
   *  will always be unique.</p>
   *
   *  @return if successful, the passed objectID; if the object was not found, zero.
   */
  public function removeByID(objectID:Int):Int
  {
    var i:Int = _objects.length - 1;
    while (i >= 0)
    {
      var object:IAnimatable = _objects[i];

      if (_objectIDs[object] == objectID)
      {
        remove(object);
        return objectID;
      }
      --i;
    }

    return 0;
  }

  /** Removes all tweens with a certain target. */
  public function removeTweens(target:Dynamic):Void
  {
    if (target == null)
    {
      return;
    }

    var i:Int = _objects.length - 1;
    while (i >= 0)
    {
      var tween:Tween = try cast(_objects[i], Tween) catch(e:Dynamic) null;
      if (tween != null && tween.target == target)
      {
        tween.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
        _objects[i] = null;
        _objectIDs.remove(tween);
      }
      --i;
    }
  }

  /** Removes all delayed and repeated calls with a certain callback. */
  public function removeDelayedCalls(callback:Function):Void
  {
    if (callback == null)
    {
      return;
    }

    var i:Int = _objects.length - 1;
    while (i >= 0)
    {
      var delayedCall:DelayedCall = try cast(_objects[i], DelayedCall) catch(e:Dynamic) null;
      if (delayedCall != null && delayedCall.callback == callback)
      {
        delayedCall.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
        _objects[i] = null;
        _objectIDs.remove(delayedCall);
      }
      --i;
    }
  }

  /** Figures out if the juggler contains one or more tweens with a certain target. */
  public function containsTweens(target:Dynamic):Bool
  {
    if (target != null)
    {
      var i:Int = _objects.length - 1;
      while (i >= 0)
      {
        var tween:Tween = try cast(_objects[i], Tween) catch(e:Dynamic) null;
        if (tween != null && tween.target == target)
        {
          return true;
        }
        --i;
      }
    }

    return false;
  }

  /** Figures out if the juggler contains one or more delayed calls with a certain callback. */
  public function containsDelayedCalls(callback:Function):Bool
  {
    if (callback != null)
    {
      var i:Int = _objects.length - 1;
      while (i >= 0)
      {
        var delayedCall:DelayedCall = try cast(_objects[i], DelayedCall) catch(e:Dynamic) null;
        if (delayedCall != null && delayedCall.callback == callback)
        {
          return true;
        }
        --i;
      }
    }

    return false;
  }

  /** Removes all objects at once. */
  public function purge():Void
  {
    // the object vector is not purged right away, because if this method is called
    // from an 'advanceTime' call, this would make the loop crash. Instead, the
    // vector is filled with 'null' values. They will be cleaned up on the next call
    // to 'advanceTime'.

    var i:Int = _objects.length - 1;
    while (i >= 0)
    {
      var object:IAnimatable = _objects[i];
      var dispatcher:EventDispatcher = try cast(object, EventDispatcher) catch(e:Dynamic) null;
      if (dispatcher != null)
      {
        dispatcher.removeEventListener(Event.REMOVE_FROM_JUGGLER, onRemove);
      }
      _objects[i] = null;
      _objectIDs.remove(object);
      --i;
    }
  }

  /** Delays the execution of a function until <code>delay</code> seconds have passed.
   *  This method provides a convenient alternative for creating and adding a DelayedCall
   *  manually.
   *
   *  @return Unique numeric identifier for the delayed call. This identifier may be used
   *          to remove the object via <code>removeByID()</code>.
   */
  public function delayCall(call:Function, delay:Float, args:Array<Dynamic> = null):Int
  {
    if (call == null)
    {
      throw new ArgumentError("call must not be null");
    }

    var delayedCall:DelayedCall = DelayedCall.fromPool(call, delay, args);
    delayedCall.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledDelayedCallComplete);
    return add(delayedCall);
  }

  /** Runs a function at a specified interval (in seconds). A 'repeatCount' of zero
   *  means that it runs indefinitely.
   *
   *  @return Unique numeric identifier for the delayed call. This identifier may be used
   *          to remove the object via <code>removeByID()</code>.
   */
  public function repeatCall(call:Function, interval:Float, repeatCount:Int = 0, args:Array<Dynamic> = null):Int
  {
    if (call == null)
    {
      throw new ArgumentError("call must not be null");
    }

    var delayedCall:DelayedCall = DelayedCall.fromPool(call, interval, args);
    delayedCall.repeatCount = repeatCount;
    delayedCall.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledDelayedCallComplete);
    return add(delayedCall);
  }

  private function onPooledDelayedCallComplete(event:Event):Void
  {
    DelayedCall.toPool(try cast(event.target, DelayedCall) catch(e:Dynamic) null);
  }

  /** Utilizes a tween to animate the target object over <code>time</code> seconds. Internally,
   *  this method uses a tween instance (taken from an object pool) that is added to the
   *  juggler right away. This method provides a convenient alternative for creating
   *  and adding a tween manually.
   *
   *  <p>Fill 'properties' with key-value pairs that describe both the
   *  tween and the animation target. Here is an example:</p>
   *
   *  <pre>
   *  juggler.tween(object, 2.0, {
   *      transition: Transitions.EASE_IN_OUT,
   *      delay: 20, // -> tween.delay = 20
   *      x: 50      // -> tween.animate("x", 50)
   *  });
   *  </pre>
   *
   *  <p>To cancel the tween, call 'Juggler.removeTweens' with the same target, or pass
   *  the returned 'IAnimatable' instance to 'Juggler.remove()'. Do not use the returned
   *  IAnimatable otherwise; it is taken from a pool and will be reused.</p>
   *
   *  <p>Note that some property types may be animated in a special way:</p>
   *  <ul>
   *    <li>If the property contains the string <code>color</code> or <code>Color</code>,
   *        it will be treated as an unsigned integer with a color value
   *        (e.g. <code>0xff0000</code> for red). Each color channel will be animated
   *        individually.</li>
   *    <li>The same happens if you append the string <code>#rgb</code> to the name.</li>
   *    <li>If you append <code>#rad</code>, the property is treated as an angle in radians,
   *        making sure it always uses the shortest possible arc for the rotation.</li>
   *    <li>The string <code>#deg</code> does the same for angles in degrees.</li>
   *  </ul>
   */
  public function tween(target:Dynamic, time:Float, properties:Dynamic):Int
  {
    if (target == null)
    {
      throw new ArgumentError("target must not be null");
    }

    var tween:Tween = Tween.fromPool(target, time);

    for (property in Reflect.fields(properties))
    {
      var value:Dynamic = Reflect.field(properties, property);

      if (Reflect.getProperty(tween, property) != null)
      {
        Reflect.setProperty(tween, property, value);
      }
      else
      {
        if (Reflect.getProperty(target, Tween.getPropertyName(property)) != null)
        {
          tween.animate(property, value);
        }
        else
        {
          throw new ArgumentError("Invalid property: " + property);
        }
      }
    }

    tween.addEventListener(Event.REMOVE_FROM_JUGGLER, onPooledTweenComplete);
    return add(tween);
  }

  private function onPooledTweenComplete(event:Event):Void
  {
    Tween.toPool(try cast(event.target, Tween) catch(e:Dynamic) null);
  }

  /** Advances all objects by a certain time (in seconds). */
  public function advanceTime(time:Float):Void
  {
    var numObjects:Int = _objects.length;
    var currentIndex:Int = 0;

    time *= _timeScale;
    if (numObjects == 0 || time == 0)
    {
      return;
    }
    _elapsedTime += time;

    // there is a high probability that the "advanceTime" function modifies the list
    // of animatables. we must not process new objects right now (they will be processed
    // in the next frame), and we need to clean up any empty slots in the list.

    var i:Int = 0;
    while(i < numObjects)
    {
      var object:IAnimatable = _objects[i];
      if (object != null)
      {
        // shift objects into empty slots along the way
        if (currentIndex != i)
        {
          _objects[currentIndex] = object;
          _objects[i] = null;
        }

        object.advanceTime(time);
        ++currentIndex;
      }
      ++i;
    }

    if (currentIndex != i)
    {
      numObjects = _objects.length;  // count might have changed!

      while (i < numObjects)
      {
        _objects[Std.int(currentIndex++)] = _objects[Std.int(i++)];     // TODO: ?????
      }

      _objects.length = currentIndex;
    }
  }

  private function onRemove(event:Event):Void
  {
    var objectID:Int = remove(try cast(event.target, IAnimatable) catch(e:Dynamic) null);

    if (objectID != 0)
    {
      var tween:Tween = try cast(event.target, Tween) catch(e:Dynamic) null;
      if (tween != null && tween.isComplete)
      {
        addWithID(tween.nextTween, objectID);
      }
    }
  }

  private static function getNextID():Int
  {
    return ++sCurrentObjectID;
  }

  /** The total life time of the juggler (in seconds). */
  private function get_elapsedTime():Float
  {
    return _elapsedTime;
  }

  /** The scale at which the time is passing. This can be used for slow motion or time laps
   *  effects. Values below '1' will make all animations run slower, values above '1' faster.
   *  @default 1.0 */
  private function get_timeScale():Float
  {
    return _timeScale;
  }
  private function set_timeScale(value:Float):Float
  {
    _timeScale = value;
    return value;
  }

  /** The actual vector that contains all objects that are currently being animated. */
  private function get_objects():Vector<IAnimatable>
  {
    return _objects;
  }
}

