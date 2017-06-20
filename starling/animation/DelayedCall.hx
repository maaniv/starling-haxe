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

import haxe.Constraints.Function;
import starling.events.Event;
import starling.events.EventDispatcher;
import openfl.Vector;

/** A DelayedCall allows you to execute a method after a certain time has passed. Since it
 *  implements the IAnimatable interface, it can be added to a juggler. In most cases, you
 *  do not have to use this class directly; the juggler class contains a method to delay
 *  calls directly.
 *
 *  <p>DelayedCall dispatches an Event of type 'Event.REMOVE_FROM_JUGGLER' when it is finished,
 *  so that the juggler automatically removes it when its no longer needed.</p>
 *
 *  @see Juggler
 */
class DelayedCall extends EventDispatcher implements IAnimatable
{
  public var isComplete(get, never):Bool;
  public var totalTime(get, never):Float;
  public var currentTime(get, never):Float;
  public var repeatCount(get, set):Int;
  public var callback(get, never):Function;
  public var arguments(get, never):Array<Dynamic>;

  private var _currentTime:Float = 0;
  private var _totalTime:Float = 0;
  private var _callback:Function = null;
  private var _args:Array<Dynamic> = null;
  private var _repeatCount:Int = 0;

  /** Creates a delayed call. */
  public function new(callback:Function, delay:Float, args:Array<Dynamic> = null)
  {
    super();
    reset(callback, delay, args);
  }

  /** Resets the delayed call to its default values, which is useful for pooling. */
  public function reset(callback:Function, delay:Float, args:Array<Dynamic> = null):DelayedCall
  {
    _currentTime = 0;
    _totalTime = Math.max(delay, 0.0001);
    _callback = callback;
    _args = args;
    _repeatCount = 1;

    return this;
  }

  /** @inheritDoc */
  public function advanceTime(time:Float):Void
  {
    var previousTime:Float = _currentTime;
    _currentTime += time;

    if (_currentTime > _totalTime)
    {
      _currentTime = _totalTime;
    }

    if (previousTime < _totalTime && _currentTime >= _totalTime)
    {
      if (_repeatCount == 0 || _repeatCount > 1)
      {
        Reflect.callMethod(null, _callback, _args);

        if (_repeatCount > 0)
        {
          _repeatCount -= 1;
        }
        _currentTime = 0;
        advanceTime((previousTime + time) - _totalTime);
      }
      else
      {
        // save call & args: they might be changed through an event listener
        var call:Function = _callback;
        var args:Array<Dynamic> = _args;

        // in the callback, people might want to call "reset" and re-add it to the
        // juggler; so this event has to be dispatched *before* executing 'call'.
        dispatchEventWith(Event.REMOVE_FROM_JUGGLER);
        Reflect.callMethod(null, call, args);
      }
    }
  }

  /** Advances the delayed call so that it is executed right away. If 'repeatCount' is
  * anything else than '1', this method will complete only the current iteration. */
  public function complete():Void
  {
    var restTime:Float = _totalTime - _currentTime;
    if (restTime > 0)
    {
      advanceTime(restTime);
    }
  }

  /** Indicates if enough time has passed, and the call has already been executed. */
  private function get_isComplete():Bool
  {
    return _repeatCount == 1 && _currentTime >= _totalTime;
  }

  /** The time for which calls will be delayed (in seconds). */
  private function get_totalTime():Float
  {
    return _totalTime;
  }

  /** The time that has already passed (in seconds). */
  private function get_currentTime():Float
  {
    return _currentTime;
  }

  /** The number of times the call will be repeated.
   *  Set to '0' to repeat indefinitely. @default 1 */
  private function get_repeatCount():Int
  {
    return _repeatCount;
  }
  private function set_repeatCount(value:Int):Int
  {
    _repeatCount = value;
    return value;
  }

  /** The callback that will be executed when the time is up. */
  private function get_callback():Function
  {
    return _callback;
  }

  /** The arguments that the callback will be executed with.
   *  Beware: not a copy, but the actual object! */
  private function get_arguments():Array<Dynamic>
  {
    return _args;
  }

  // delayed call pooling

  private static var sPool:Vector<DelayedCall> = new Vector();

  /** @private */
  @:allow(starling) private static function fromPool(call:Function, delay:Float,
      args:Array<Dynamic> = null):DelayedCall
  {
    if (sPool.length > 0)
    {
      return sPool.pop().reset(call, delay, args);
    }
    else
    {
      return new DelayedCall(call, delay, args);
    }
  }

  /** @private */
  @:allow(starling) private static function toPool(delayedCall:DelayedCall):Void
  {
    // reset any object-references, to make sure we don't prevent any garbage collection
    delayedCall._callback = null;
    delayedCall._args = null;
    delayedCall.removeEventListeners();
    sPool.push(delayedCall);
  }
}
