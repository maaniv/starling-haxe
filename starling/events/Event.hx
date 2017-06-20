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

import starling.utils.StringUtil;
import openfl.Vector;

/** Event objects are passed as parameters to event listeners when an event occurs.
 *  This is Starling's version of the Flash Event class.
 *
 *  <p>EventDispatchers create instances of this class and send them to registered listeners.
 *  An event object contains information that characterizes an event, most importantly the
 *  event type and if the event bubbles. The target of an event is the object that
 *  dispatched it.</p>
 *
 *  <p>For some event types, this information is sufficient; other events may need additional
 *  information to be carried to the listener. In that case, you can subclass "Event" and add
 *  properties with all the information you require. The "EnterFrameEvent" is an example for
 *  this practice; it adds a property about the time that has passed since the last frame.</p>
 *
 *  <p>Furthermore, the event class contains methods that can stop the event from being
 *  processed by other listeners - either completely or at the next bubble stage.</p>
 *
 *  @see EventDispatcher
 */
class Event
{
  public var bubbles(get, never):Bool;
  public var target(get, never):EventDispatcher;
  public var currentTarget(get, never):EventDispatcher;
  public var type(get, never):String;
  public var data(get, never):Dynamic;
  @:allow(starling.events) private var stopsPropagation(get, never):Bool;
  @:allow(starling.events) private var stopsImmediatePropagation(get, never):Bool;

  /** Event type for a display object that is added to a parent. */
  public static inline var ADDED:String = "added";
  /** Event type for a display object that is added to the stage */
  public static inline var ADDED_TO_STAGE:String = "addedToStage";
  /** Event type for a display object that is entering a new frame. */
  public static inline var ENTER_FRAME:String = "enterFrame";
  /** Event type for a display object that is removed from its parent. */
  public static inline var REMOVED:String = "removed";
  /** Event type for a display object that is removed from the stage. */
  public static inline var REMOVED_FROM_STAGE:String = "removedFromStage";
  /** Event type for a triggered button. */
  public static inline var TRIGGERED:String = "triggered";
  /** Event type for a resized Flash Player. */
  public static inline var RESIZE:String = "resize";
  /** Event type that may be used whenever something finishes. */
  public static inline var COMPLETE:String = "complete";
  /** Event type for a (re)created stage3D rendering context. */
  public static inline var CONTEXT3D_CREATE:String = "context3DCreate";
  /** Event type that is dispatched by the Starling instance directly before rendering. */
  public static inline var RENDER:String = "render";
  /** Event type that indicates that the root DisplayObject has been created. */
  public static inline var ROOT_CREATED:String = "rootCreated";
  /** Event type for an animated object that requests to be removed from the juggler. */
  public static inline var REMOVE_FROM_JUGGLER:String = "removeFromJuggler";
  /** Event type that is dispatched by the AssetManager after a context loss. */
  public static inline var TEXTURES_RESTORED:String = "texturesRestored";
  /** Event type that is dispatched by the AssetManager when a file/url cannot be loaded. */
  public static inline var IO_ERROR:String = "ioError";
  /** Event type that is dispatched by the AssetManager when a file/url cannot be loaded. */
  public static inline var SECURITY_ERROR:String = "securityError";
  /** Event type that is dispatched by the AssetManager when an xml or json file couldn't
   *  be parsed. */
  public static inline var PARSE_ERROR:String = "parseError";
  /** Event type that is dispatched by the Starling instance when it encounters a problem
   *  from which it cannot recover, e.g. a lost device context. */
  public static inline var FATAL_ERROR:String = "fatalError";

  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var CHANGE:String = "change";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var CANCEL:String = "cancel";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var SCROLL:String = "scroll";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var OPEN:String = "open";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var CLOSE:String = "close";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var SELECT:String = "select";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var READY:String = "ready";
  /** An event type to be utilized in custom events. Not used by Starling right now. */
  public static inline var UPDATE:String = "update";

  private static var sEventPool:Vector<Event> = new Vector();

  private var _target:EventDispatcher = null;
  private var _currentTarget:EventDispatcher = null;
  private var _type:String = null;
  private var _bubbles:Bool = false;
  private var _stopsPropagation:Bool = false;
  private var _stopsImmediatePropagation:Bool = false;
  private var _data:Dynamic = null;

  /** Creates an event object that can be passed to listeners. */
  public function new(type:String, bubbles:Bool = false, data:Dynamic = null)
  {
    _type = type;
    _bubbles = bubbles;
    _data = data;
  }

  /** Prevents listeners at the next bubble stage from receiving the event. */
  public function stopPropagation():Void
  {
    _stopsPropagation = true;
  }

  /** Prevents any other listeners from receiving the event. */
  public function stopImmediatePropagation():Void
  {
    _stopsPropagation = _stopsImmediatePropagation = true;
  }

  /** Returns a description of the event, containing type and bubble information. */
  public function toString():String
  {
    return StringUtil.format("[{0} type=\"{1}\" bubbles={2}]",
        [Type.getClassName(Type.getClass(this)).split("::").pop(), _type, _bubbles]
    );
  }

  /** Indicates if event will bubble. */
  private function get_bubbles():Bool
  {
    return _bubbles;
  }

  /** The object that dispatched the event. */
  private function get_target():EventDispatcher
  {
    return _target;
  }

  /** The object the event is currently bubbling at. */
  private function get_currentTarget():EventDispatcher
  {
    return _currentTarget;
  }

  /** A string that identifies the event. */
  private function get_type():String
  {
    return _type;
  }

  /** Arbitrary data that is attached to the event. */
  private function get_data():Dynamic
  {
    return _data;
  }

  // properties for internal use

  /** @private */
  @:allow(starling.events)
  private function setTarget(value:EventDispatcher):Void
  {
    _target = value;
  }

  /** @private */
  @:allow(starling.events)
  private function setCurrentTarget(value:EventDispatcher):Void
  {
    _currentTarget = value;
  }

  /** @private */
  @:allow(starling.events)
  private function setData(value:Dynamic):Void
  {
    _data = value;
  }

  /** @private */
  @:allow(starling.events)
  private function get_stopsPropagation():Bool
  {
    return _stopsPropagation;
  }

  /** @private */
  @:allow(starling.events)
  private function get_stopsImmediatePropagation():Bool
  {
    return _stopsImmediatePropagation;
  }

  // event pooling

  /** @private */
  @:allow(starling) private static function fromPool(type:String, bubbles:Bool = false, data:Dynamic = null):Event
  {
    if (sEventPool.length > 0)
    {
      return sEventPool.pop().reset(type, bubbles, data);
    }
    else
    {
      return new Event(type, bubbles, data);
    }
  }

  /** @private */
  @:allow(starling) private static function toPool(event:Event):Void
  {
    event._data = event._target = event._currentTarget = null;
    sEventPool[sEventPool.length] = event;
  }

  /** @private */
  @:allow(starling) private function reset(type:String, bubbles:Bool = false, data:Dynamic = null):Event
  {
    _type = type;
    _bubbles = bubbles;
    _data = data;
    _target = _currentTarget = null;
    _stopsPropagation = _stopsImmediatePropagation = false;
    return this;
  }
}
