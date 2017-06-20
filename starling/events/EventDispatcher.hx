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

import haxe.Constraints.Function;
import starling.display.DisplayObject;
import openfl.Vector;

/** The EventDispatcher class is the base class for all classes that dispatch events.
 *  This is the Starling version of the Flash class with the same name.
 *
 *  <p>The event mechanism is a key feature of Starling's architecture. Objects can communicate
 *  with each other through events. Compared the the Flash event system, Starling's event system
 *  was simplified. The main difference is that Starling events have no "Capture" phase.
 *  They are simply dispatched at the target and may optionally bubble up. They cannot move
 *  in the opposite direction.</p>
 *
 *  <p>As in the conventional Flash classes, display objects inherit from EventDispatcher
 *  and can thus dispatch events. Beware, though, that the Starling event classes are
 *  <em>not compatible with Flash events:</em> Starling display objects dispatch
 *  Starling events, which will bubble along Starling display objects - but they cannot
 *  dispatch Flash events or bubble along Flash display objects.</p>
 *
 *  @see Event
 *  @see starling.display.DisplayObject DisplayObject
 */
class EventDispatcher
{
  private var _eventListeners:Map<String, Vector<Function>> = null;

  /** Helper object. */
  private static var sBubbleChains:Array<Dynamic> = new Array();

  /** Creates an EventDispatcher. */
  public function new()
  {
  }

  /** Registers an event listener at a certain object. */
  public function addEventListener(type:String, listener:Function):Void
  {
    if (_eventListeners == null)
    {
      _eventListeners = new Map();
    }

    var listeners:Vector<Function> = _eventListeners.get(type);
    if (listeners == null)
    {
      var vec:Vector<Function> = new Vector();
      vec.push(listener);
      _eventListeners[type] = vec;
    }
    else
    {
      if (listeners.indexOf(listener) == -1)
      {
        // check for duplicates
        listeners[listeners.length] = listener;
      }
    }
  }

  /** Removes an event listener from the object. */
  public function removeEventListener(type:String, listener:Function):Void
  {
    if (_eventListeners != null)
    {
      var listeners = _eventListeners[type];
      var numListeners:Int = (listeners != null) ? listeners.length:0;

      if (numListeners > 0)
      {
        // we must not modify the original vector, but work on a copy.
        // (see comment in 'invokeEvent')

        var index:Int = listeners.indexOf(listener);

        if (index != -1)
        {
          var restListeners:Vector<Function> = listeners.slice(0, index);

          for (i in index + 1...numListeners)
          {
            restListeners[i - 1] = listeners[i];
          }

          _eventListeners[type] = restListeners;
        }
      }
    }
  }

  /** Removes all event listeners with a certain type, or all of them if type is null.
   *  Be careful when removing all event listeners: you never know who else was listening. */
  public function removeEventListeners(type:String = null):Void
  {
    if (type != null && _eventListeners != null)
    {
      _eventListeners.remove(type);
    }
    else
    {
      _eventListeners = null;
    }
  }

  /** Dispatches an event to all objects that have registered listeners for its type.
   *  If an event with enabled 'bubble' property is dispatched to a display object, it will
   *  travel up along the line of parents, until it either hits the root object or someone
   *  stops its propagation manually. */
  public function dispatchEvent(event:Event):Void
  {
    var bubbles:Bool = event.bubbles;

    if (!bubbles && (_eventListeners == null || !_eventListeners.exists(event.type)))
    {
      return;
    }  // no need to do anything

    // we save the current target and restore it later;
    // this allows users to re-dispatch events without creating a clone.

    var previousTarget:EventDispatcher = event.target;
    event.setTarget(this);

    if (bubbles && Std.is(this, DisplayObject))
    {
      bubbleEvent(event);
    }
    else
    {
      invokeEvent(event);
    }

    if (previousTarget != null)
    {
      event.setTarget(previousTarget);
    }
  }

  /** @private
   *  Invokes an event on the current object. This method does not do any bubbling, nor
   *  does it back-up and restore the previous target on the event. The 'dispatchEvent'
   *  method uses this method internally. */
  @:allow(starling.events)
  private function invokeEvent(event:Event):Bool
  {
    var listeners = (_eventListeners != null) ? _eventListeners[event.type] : null;
    var numListeners:Int = (listeners == null) ? 0:listeners.length;

    if (numListeners != 0)
    {
      event.setCurrentTarget(this);

      // we can enumerate directly over the vector, because:
      // when somebody modifies the list while we're looping, "addEventListener" is not
      // problematic, and "removeEventListener" will create a new Vector, anyway.

      for (i in 0...numListeners)
      {
        var listener:Function = listeners[i];
        #if flash
        var numArgs:Int = untyped listener.length;
        #elseif neko
        var numArgs:Int = untyped ($nargs)(listener);
        #else
        var numArgs:Int = 2;
        #end

        if (numArgs == 0)
        {
          listener();
        }
        else
        {
          if (numArgs == 1)
          {
            listener(event);
          }
          else
          {
            listener(event, event.data);
          }
        }

        if (event.stopsImmediatePropagation)
        {
          return true;
        }
      }

      return event.stopsPropagation;
    }
    else
    {
      return false;
    }
  }

  /** @private */
  @:allow(starling.events)
  private function bubbleEvent(event:Event):Void
  {
    // we determine the bubble chain before starting to invoke the listeners.
    // that way, changes done by the listeners won't affect the bubble chain.

    var chain:Vector<EventDispatcher>;
    var element:DisplayObject = cast(this);
    var length:Int = 1;

    if (sBubbleChains.length > 0)
    {
      chain = sBubbleChains.pop();chain[0] = element;
    }
    else
    {
      chain = new Vector();
      chain.push(element);
    }

    while ((element = element.parent) != null)
    {
      chain[Std.int(length++)] = element;     // TODO: ???????
    }

    for (i in 0...length)
    {
      var stopPropagation:Bool = chain[i].invokeEvent(event);
      if (stopPropagation)
      {
        break;
      }
    }

    chain.length = 0;
    sBubbleChains[sBubbleChains.length] = chain;
  }

  /** Dispatches an event with the given parameters to all objects that have registered
   *  listeners for the given type. The method uses an internal pool of event objects to
   *  avoid allocations. */
  public function dispatchEventWith(type:String, bubbles:Bool = false, data:Dynamic = null):Void
  {
    if (bubbles || hasEventListener(type))
    {
      var event:Event = Event.fromPool(type, bubbles, data);
      dispatchEvent(event);
      Event.toPool(event);
    }
  }

  /** If called with one argument, figures out if there are any listeners registered for
   *  the given event type. If called with two arguments, also determines if a specific
   *  listener is registered. */
  public function hasEventListener(type:String, listener:Function = null):Bool
  {
    var listeners:Vector<Function> = (_eventListeners != null) ? _eventListeners[type] : null;
    if (listeners == null)
    {
      return false;
    }
    else
    {
      if (listener != null)
      {
        return listeners.indexOf(listener) != -1;
      }
      else
      {
        return listeners.length != 0;
      }
    }
  }
}
