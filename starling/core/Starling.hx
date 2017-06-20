// =================================================================================================
//
//	Starling Framework
//	Copyright Gamua GmbH. All Rights Reserved.
//
//	This program is free software. You can redistribute and/or modify it
//	in accordance with the terms of the accompanying license agreement.
//
// =================================================================================================

package starling.core;

import flash.errors.ArgumentError;
import flash.errors.Error;
import flash.display.Shape;
import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DProfile;
import flash.errors.IllegalOperationError;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Rectangle;
import flash.system.Capabilities;
import flash.text.TextField;
import flash.text.TextFieldAutoSize;
import flash.text.TextFormat;
import flash.text.TextFormatAlign;
import flash.ui.Mouse;
import flash.ui.Multitouch;
import flash.ui.MultitouchInputMode;
import starling.animation.Juggler;
import starling.display.DisplayObject;
import starling.display.Stage;
import starling.events.EventDispatcher;
import starling.events.ResizeEvent;
import starling.events.TouchPhase;
import starling.events.TouchProcessor;
import starling.rendering.Painter;
import starling.utils.Align;
import starling.utils.RectangleUtil;
import starling.utils.SystemUtil;
//import flash.display.DisplayObject;
//import flash.display.DisplayObjectContainer;
import openfl.Vector;

/** Dispatched when a new render context is created. The 'data' property references the context. */
@:meta(Event(name="context3DCreate",type="starling.events.Event"))

/** Dispatched when the root class has been created. The 'data' property references that object. */
@:meta(Event(name="rootCreated",type="starling.events.Event"))

/** Dispatched when a fatal error is encountered. The 'data' property contains an error string. */
@:meta(Event(name="fatalError",type="starling.events.Event"))

/** Dispatched when the display list is about to be rendered. This event provides the last
 *  opportunity to make changes before the display list is rendered. */
@:meta(Event(name="render",type="starling.events.Event"))

/** The Starling class represents the core of the Starling framework.
 *
 *  <p>The Starling framework makes it possible to create 2D applications and games that make
 *  use of the Stage3D architecture introduced in Flash Player 11. It implements a display tree
 *  system that is very similar to that of conventional Flash, while leveraging modern GPUs
 *  to speed up rendering.</p>
 *
 *  <p>The Starling class represents the link between the conventional Flash display tree and
 *  the Starling display tree. To create a Starling-powered application, you have to create
 *  an instance of the Starling class:</p>
 *
 *  <pre>var starling:Starling = new Starling(Game, stage);</pre>
 *
 *  <p>The first parameter has to be a Starling display object class, e.g. a subclass of
 *  <code>starling.display.Sprite</code>. In the sample above, the class "Game" is the
 *  application root. An instance of "Game" will be created as soon as Starling is initialized.
 *  The second parameter is the conventional (Flash) stage object. Per default, Starling will
 *  display its contents directly below the stage.</p>
 *
 *  <p>It is recommended to store the Starling instance as a member variable, to make sure
 *  that the Garbage Collector does not destroy it. After creating the Starling object, you
 *  have to start it up like this:</p>
 *
 *  <pre>starling.start();</pre>
 *
 *  <p>It will now render the contents of the "Game" class in the frame rate that is set up for
 *  the application (as defined in the Flash stage).</p>
 *
 *  <strong>Context3D Profiles</strong>
 *
 *  <p>Stage3D supports different rendering profiles, and Starling works with all of them. The
 *  last parameter of the Starling constructor allows you to choose which profile you want.
 *  The following profiles are available:</p>
 *
 *  <ul>
 *    <li>BASELINE_CONSTRAINED: provides the broadest hardware reach. If you develop for the
 *        browser, this is the profile you should test with.</li>
 *    <li>BASELINE: recommend for any mobile application, as it allows Starling to use a more
 *        memory efficient texture type (RectangleTextures). It also supports more complex
 *        AGAL code.</li>
 *    <li>BASELINE_EXTENDED: adds support for textures up to 4096x4096 pixels. This is
 *        especially useful on mobile devices with very high resolutions.</li>
 *    <li>STANDARD_CONSTRAINED, STANDARD, STANDARD_EXTENDED: each provide more AGAL features,
 *        among other things. Most Starling games will not gain much from them.</li>
 *  </ul>
 *
 *  <p>The recommendation is to deploy your app with the profile "auto" (which makes Starling
 *  pick the best available of those), but to test it in all available profiles.</p>
 *
 *  <strong>Accessing the Starling object</strong>
 *
 *  <p>From within your application, you can access the current Starling object anytime
 *  through the static method <code>Starling.current</code>. It will return the active Starling
 *  instance (most applications will only have one Starling object, anyway).</p>
 *
 *  <strong>Viewport</strong>
 *
 *  <p>The area the Starling content is rendered into is, per default, the complete size of the
 *  stage. You can, however, use the "viewPort" property to change it. This can be  useful
 *  when you want to render only into a part of the screen, or if the player size changes. For
 *  the latter, you can listen to the RESIZE-event dispatched by the Starling
 *  stage.</p>
 *
 *  <strong>Native overlay</strong>
 *
 *  <p>Sometimes you will want to display native Flash content on top of Starling. That's what the
 *  <code>nativeOverlay</code> property is for. It returns a Flash Sprite lying directly
 *  on top of the Starling content. You can add conventional Flash objects to that overlay.</p>
 *
 *  <p>Beware, though, that conventional Flash content on top of 3D content can lead to
 *  performance penalties on some (mobile) platforms. For that reason, always remove all child
 *  objects from the overlay when you don't need them any longer.</p>
 *
 *  <strong>Multitouch</strong>
 *
 *  <p>Starling supports multitouch input on devices that provide it. During development,
 *  where most of us are working with a conventional mouse and keyboard, Starling can simulate
 *  multitouch events with the help of the "Shift" and "Ctrl" (Mac: "Cmd") keys. Activate
 *  this feature by enabling the <code>simulateMultitouch</code> property.</p>
 *
 *  <strong>Skipping Unchanged Frames</strong>
 *
 *  <p>It happens surprisingly often in an app or game that a scene stays completely static for
 *  several frames. So why redraw the stage at all in those situations? That's exactly the
 *  point of the <code>skipUnchangedFrames</code>-property. If enabled, static scenes are
 *  recognized as such and the back buffer is simply left as it is. On a mobile device, the
 *  impact of this feature can't be overestimated! There's simply no better way to enhance
 *  battery life. Make it a habit to always activate it; look at the documentation of the
 *  corresponding property for details.</p>
 *
 *  <strong>Handling a lost render context</strong>
 *
 *  <p>On some operating systems and under certain conditions (e.g. returning from system
 *  sleep), Starling's stage3D render context may be lost. Starling will try to recover
 *  from a lost context automatically; to be able to do this, it will cache textures in
 *  RAM. This will take up quite a bit of extra memory, though, which might be problematic
 *  especially on mobile platforms. To avoid the higher memory footprint, it's recommended
 *  to load your textures with Starling's "AssetManager"; it is smart enough to recreate a
 *  texture directly from its origin.</p>
 *
 *  <p>In case you want to react to a context loss manually, Starling dispatches an event with
 *  the type "Event.CONTEXT3D_CREATE" when the context is restored, and textures will execute
 *  their <code>root.onRestore</code> callback, to which you can attach your own logic.
 *  Refer to the "Texture" class for more information.</p>
 *
 *  <strong>Sharing a 3D Context</strong>
 *
 *  <p>Per default, Starling handles the Stage3D context itself. If you want to combine
 *  Starling with another Stage3D engine, however, this may not be what you want. In this case,
 *  you can make use of the <code>shareContext</code> property:</p>
 *
 *  <ol>
 *    <li>Manually create and configure a context3D object that both frameworks can work with
 *        (ideally through <code>RenderUtil.requestContext3D</code> and
 *        <code>context.configureBackBuffer</code>).</li>
 *    <li>Initialize Starling with the stage3D instance that contains that configured context.
 *        This will automatically enable <code>shareContext</code>.</li>
 *    <li>Call <code>start()</code> on your Starling instance (as usual). This will make
 *        Starling queue input events (keyboard/mouse/touch).</li>
 *    <li>Create a game loop (e.g. using the native <code>ENTER_FRAME</code> event) and let it
 *        call Starling's <code>nextFrame</code> as well as the equivalent method of the other
 *        Stage3D engine. Surround those calls with <code>context.clear()</code> and
 *        <code>context.present()</code>.</li>
 *  </ol>
 *
 *  <p>The Starling wiki contains a <a href="http://goo.gl/BsXzw">tutorial</a> with more
 *  information about this topic.</p>
 *
 *  @see starling.utils.AssetManager
 *  @see starling.textures.Texture
 *
 */
class Starling extends EventDispatcher
{
  private var touchEventTypes(get, never):Array<Dynamic>;
  private var mustAlwaysRender(get, never):Bool;
  public var isStarted(get, never):Bool;
  public var juggler(get, never):Juggler;
  public var painter(get, never):Painter;
  public var context(get, never):Context3D;
  public var simulateMultitouch(get, set):Bool;
  public var enableErrorChecking(get, set):Bool;
  public var antiAliasing(get, set):Int;
  public var viewPort(get, set):Rectangle;
  public var contentScaleFactor(get, never):Float;
  public var nativeOverlay(get, never):Sprite;
  public var showStats(get, set):Bool;
  public var stage(get, never):Stage;
  public var stage3D(get, never):Stage3D;
  public var nativeStage(get, never):flash.display.Stage;
  public var root(get, never):DisplayObject;
  public var rootClass(get, set):Class<Dynamic>;
  public var shareContext(get, set):Bool;
  public var profile(get, never):String;
  public var supportHighResolutions(get, set):Bool;
  public var skipUnchangedFrames(get, set):Bool;
  public var touchProcessor(get, set):TouchProcessor;
  public var frameID(get, never):Int;
  public var contextValid(get, never):Bool;
  public static var current(get, never):Starling;
  public static var all(get, never):Vector<Starling>;
  public static var multitouchEnabled(get, set):Bool;

  /** The version of the Starling framework. */
  public static inline var VERSION:String = "2.1";

  // members

  private var _stage:Stage = null;  // starling.display.stage!
  private var _rootClass:Class<Dynamic> = null;
  private var _root:DisplayObject = null;
  private var _juggler:Juggler = null;
  private var _painter:Painter = null;
  private var _touchProcessor:TouchProcessor = null;
  private var _antiAliasing:Int = 0;
  private var _frameTimestamp:Float = 0;
  private var _frameID:Int = 0;
  private var _leftMouseDown:Bool = false;
  private var _statsDisplay:StatsDisplay = null;
  private var _started:Bool = false;
  private var _rendering:Bool = false;
  private var _supportHighResolutions:Bool = false;
  private var _skipUnchangedFrames:Bool = false;
  private var _showStats:Bool = false;

  private var _viewPort:Rectangle = null;
  private var _previousViewPort:Rectangle = null;
  private var _clippedViewPort:Rectangle = null;

  private var _nativeStage:flash.display.Stage = null;
  private var _nativeStageEmpty:Bool = false;
  private var _nativeOverlay:Sprite = null;

  private static var sCurrent:Starling = null;
  private static var sAll:Vector<Starling> = new Vector();

  // construction

  /** Creates a new Starling instance.
   *  @param rootClass  A subclass of 'starling.display.DisplayObject'. It will be created
   *                    as soon as initialization is finished and will become the first child
   *                    of the Starling stage. Pass <code>null</code> if you don't want to
   *                    create a root object right away. (You can use the
   *                    <code>rootClass</code> property later to make that happen.)
   *  @param stage      The Flash (2D) stage.
   *  @param viewPort   A rectangle describing the area into which the content will be
   *                    rendered. Default: stage size
   *  @param stage3D    The Stage3D object into which the content will be rendered. If it
   *                    already contains a context, <code>sharedContext</code> will be set
   *                    to <code>true</code>. Default: the first available Stage3D.
   *  @param renderMode The Context3D render mode that should be requested.
   *                    Use this parameter if you want to force "software" rendering.
   *  @param profile    The Context3D profile that should be requested.
   *
   *                    <ul>
   *                    <li>If you pass a profile String, this profile is enforced.</li>
   *                    <li>Pass an Array of profiles to make Starling pick the first
   *                        one that works (starting with the first array element).</li>
   *                    <li>Pass the String "auto" to make Starling pick the best available
   *                        profile automatically.</li>
   *                    </ul>
   */
  public function new(rootClass:Class<Dynamic>, stage:flash.display.Stage,
      viewPort:Rectangle = null, stage3D:Stage3D = null,
      renderMode:String = "auto", profile:Dynamic = "auto")
  {
    super();
    if (stage == null)
    {
      throw new ArgumentError("Stage must not be null");
    }
    if (viewPort == null)
    {
      viewPort = new Rectangle(0, 0, stage.stageWidth, stage.stageHeight);
    }
    if (stage3D == null)
    {
      stage3D = stage.stage3Ds[0];
    }

    // TODO it might make sense to exchange the 'renderMode' and 'profile' parameters.

    SystemUtil.initialize();
    sAll.push(this);
    makeCurrent();

    _rootClass = rootClass;
    _viewPort = viewPort;
    _previousViewPort = new Rectangle();
    _stage = new Stage(Std.int(viewPort.width), Std.int(viewPort.height), stage.color);
    _nativeOverlay = new Sprite();
    _nativeStage = stage;
    _nativeStage.addChild(_nativeOverlay);
    _touchProcessor = new TouchProcessor(_stage);
    _juggler = new Juggler();
    _antiAliasing = 0;
    _supportHighResolutions = false;
    _painter = new Painter(stage3D);
    _frameTimestamp = Math.round(haxe.Timer.stamp() * 1000) / 1000.0;
    _frameID = 1;

    // all other modes are problematic in Starling, so we force those here
    stage.scaleMode = StageScaleMode.NO_SCALE;
    stage.align = StageAlign.TOP_LEFT;

    // register touch/mouse event handlers
    for (touchEventType in touchEventTypes)
    {
      stage.addEventListener(touchEventType, onTouch, false, 0, true);
    }

    // register other event handlers
    stage.addEventListener(Event.ENTER_FRAME, onEnterFrame, false, 0, true);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey, false, 0, true);
    stage.addEventListener(KeyboardEvent.KEY_UP, onKey, false, 0, true);
    stage.addEventListener(Event.RESIZE, onResize, false, 0, true);
    stage.addEventListener(Event.MOUSE_LEAVE, onMouseLeave, false, 0, true);

    stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false, 10, true);
    stage3D.addEventListener(ErrorEvent.ERROR, onStage3DError, false, 10, true);

    if (_painter.shareContext)
    {
      haxe.Timer.delay(initialize, 1);
    }
    else
    {
      if (!SystemUtil.supportsDepthAndStencil)
      {
        trace("[Starling] Mask support requires 'depthAndStencil' to be enabled" +
            " in the application descriptor.");
      }

      _painter.requestContext3D(renderMode, profile);
    }
  }

  /** Disposes all children of the stage and the render context; removes all registered
   *  event listeners. */
  public function dispose():Void
  {
    stop(true);

    _nativeStage.removeEventListener(Event.ENTER_FRAME, onEnterFrame, false);
    _nativeStage.removeEventListener(KeyboardEvent.KEY_DOWN, onKey, false);
    _nativeStage.removeEventListener(KeyboardEvent.KEY_UP, onKey, false);
    _nativeStage.removeEventListener(Event.RESIZE, onResize, false);
    _nativeStage.removeEventListener(Event.MOUSE_LEAVE, onMouseLeave, false);
    _nativeStage.removeChild(_nativeOverlay);

    stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated, false);
    stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextRestored, false);
    stage3D.removeEventListener(ErrorEvent.ERROR, onStage3DError, false);

    for (touchEventType in touchEventTypes)
    {
      _nativeStage.removeEventListener(touchEventType, onTouch, false);
    }

    _touchProcessor.dispose();
    _painter.dispose();
    _stage.dispose();

    var index:Int = sAll.indexOf(this);
    if (index != -1)
    {
      sAll.splice(index, 1);
    }
    if (sCurrent == this)
    {
      sCurrent = null;
    }
  }

  // functions

  private function initialize():Void
  {
    makeCurrent();
    updateViewPort(true);

    // ideal time: after viewPort setup, before root creation
    dispatchEventWith(Event.CONTEXT3D_CREATE, false, context);

    initializeRoot();
    _frameTimestamp = Math.round(haxe.Timer.stamp() * 1000) / 1000.0;
  }

  private function initializeRoot():Void
  {
    if (_root == null && _rootClass != null)
    {
      _root = Type.createInstance(_rootClass, []);
      if (_root == null)
      {
        throw new Error("Invalid root class: " + _rootClass);
      }
      _stage.addChildAt(_root, 0);

      dispatchEventWith(starling.events.Event.ROOT_CREATED, false, _root);
    }
  }

  /** Calls <code>advanceTime()</code> (with the time that has passed since the last frame)
   *  and <code>render()</code>. */
  public function nextFrame():Void
  {
    var now:Float = Math.round(haxe.Timer.stamp() * 1000) / 1000.0;
    var passedTime:Float = now - _frameTimestamp;
    _frameTimestamp = now;

    // to avoid overloading time-based animations, the maximum delta is truncated.
    if (passedTime > 1.0)
    {
      passedTime = 1.0;
    }

    // after about 25 days, 'getTimer()' will roll over. A rare event, but still ...
    if (passedTime < 0.0)
    {
      passedTime = 1.0 / _nativeStage.frameRate;
    }

    advanceTime(passedTime);
    render();
  }

  /** Dispatches ENTER_FRAME events on the display list, advances the Juggler
   *  and processes touches. */
  public function advanceTime(passedTime:Float):Void
  {
    if (!contextValid)
    {
      return;
    }

    makeCurrent();

    _touchProcessor.advanceTime(passedTime);
    _stage.advanceTime(passedTime);
    _juggler.advanceTime(passedTime);
  }

  /** Renders the complete display list. Before rendering, the context is cleared; afterwards,
   *  it is presented (to avoid this, enable <code>shareContext</code>).
   *
   *  <p>This method also dispatches an <code>Event.RENDER</code>-event on the Starling
   *  instance. That's the last opportunity to make changes before the display list is
   *  rendered.</p> */
  public function render():Void
  {
    if (!contextValid)
    {
      return;
    }

    makeCurrent();
    updateViewPort();

    var doRedraw:Bool = _stage.requiresRedraw || mustAlwaysRender;
    if (doRedraw)
    {
      dispatchEventWith(starling.events.Event.RENDER);

      var shareContext:Bool = _painter.shareContext;
      var scaleX:Float = _viewPort.width / _stage.stageWidth;
      var scaleY:Float = _viewPort.height / _stage.stageHeight;

      _painter.nextFrame();
      _painter.pixelSize = 1.0 / contentScaleFactor;
      _painter.state.setProjectionMatrix(
          (_viewPort.x < 0) ? -_viewPort.x / scaleX : 0.0,
          (_viewPort.y < 0) ? -_viewPort.y / scaleY : 0.0,
          _clippedViewPort.width / scaleX,
          _clippedViewPort.height / scaleY,
          _stage.stageWidth, _stage.stageHeight, _stage.cameraPosition
      );

      if (!shareContext)
      {
        _painter.clear(_stage.color, 0.0);
      }

      _stage.render(_painter);
      _painter.finishFrame();
      _painter.frameID = ++_frameID;

      if (!shareContext)
      {
        _painter.present();
      }
    }

    if (_statsDisplay != null)
    {
      _statsDisplay.drawCount = _painter.drawCount;
      if (!doRedraw)
      {
        _statsDisplay.markFrameAsSkipped();
      }
    }
  }

  private function updateViewPort(forceUpdate:Bool = false):Void
  {
    // the last set viewport is stored in a variable; that way, people can modify the
    // viewPort directly (without a copy) and we still know if it has changed.

    if (forceUpdate || !RectangleUtil.compare(_viewPort, _previousViewPort))
    {
      _previousViewPort.setTo(_viewPort.x, _viewPort.y, _viewPort.width, _viewPort.height);

      // Constrained mode requires that the viewport is within the native stage bounds;
      // thus, we use a clipped viewport when configuring the back buffer. (In baseline
      // mode, that's not necessary, but it does not hurt either.)

      _clippedViewPort = _viewPort.intersection(
              new Rectangle(0, 0, _nativeStage.stageWidth, _nativeStage.stageHeight)
        );

      // var contentScaleFactor:Float =
      // (_supportHighResolutions) ? _nativeStage.contentsScaleFactor:1.0;
      var contentScaleFactor:Float = 1.0;

      _painter.configureBackBuffer(_clippedViewPort, contentScaleFactor,
          _antiAliasing, true
      );
    }
  }

  private function updateNativeOverlay():Void
  {
    _nativeOverlay.x = _viewPort.x;
    _nativeOverlay.y = _viewPort.y;
    _nativeOverlay.scaleX = _viewPort.width / _stage.stageWidth;
    _nativeOverlay.scaleY = _viewPort.height / _stage.stageHeight;
  }

  /** Stops Starling right away and displays an error message on the native overlay.
   *  This method will also cause Starling to dispatch a FATAL_ERROR event. */
  public function stopWithFatalError(message:String):Void
  {
    var background:Shape = new Shape();
    background.graphics.beginFill(0x0, 0.8);
    background.graphics.drawRect(0, 0, _stage.stageWidth, _stage.stageHeight);
    background.graphics.endFill();

    var textField:TextField = new TextField();
    var textFormat:TextFormat = new TextFormat("Verdana", 14, 0xFFFFFF);
    textFormat.align = TextFormatAlign.CENTER;
    textField.defaultTextFormat = textFormat;
    textField.wordWrap = true;
    textField.width = _stage.stageWidth * 0.75;
    textField.autoSize = TextFieldAutoSize.CENTER;
    textField.text = message;
    textField.x = (_stage.stageWidth - textField.width) / 2;
    textField.y = (_stage.stageHeight - textField.height) / 2;
    textField.background = true;
    textField.backgroundColor = 0x550000;

    updateNativeOverlay();
    nativeOverlay.addChild(background);
    nativeOverlay.addChild(textField);
    stop(true);

    trace("[Starling]", message);
    dispatchEventWith(starling.events.Event.FATAL_ERROR, false, message);
  }

  /** Make this Starling instance the <code>current</code> one. */
  public function makeCurrent():Void
  {
    sCurrent = this;
  }

  /** As soon as Starling is started, it will queue input events (keyboard/mouse/touch);
   *  furthermore, the method <code>nextFrame</code> will be called once per Flash Player
   *  frame. (Except when <code>shareContext</code> is enabled: in that case, you have to
   *  call that method manually.) */
  public function start():Void
  {
    _started = _rendering = true;
    _frameTimestamp = Math.round(haxe.Timer.stamp() * 1000) / 1000.0;

    // mainly for Android: force redraw when app moves into foreground
    haxe.Timer.delay(setRequiresRedraw, 100);
  }

  /** Stops all logic and input processing, effectively freezing the app in its current state.
   *  Per default, rendering will continue: that's because the classic display list
   *  is only updated when stage3D is. (If Starling stopped rendering, conventional Flash
   *  contents would freeze, as well.)
   *
   *  <p>However, if you don't need classic Flash contents, you can stop rendering, too.
   *  On some mobile systems (e.g. iOS), you are even required to do so if you have
   *  activated background code execution.</p>
   */
  public function stop(suspendRendering:Bool = false):Void
  {
    _started = false;
    _rendering = !suspendRendering;
  }

  /** Makes sure that the next frame is actually rendered.
   *
   *  <p>When <code>skipUnchangedFrames</code> is enabled, some situations require that you
   *  manually force a redraw, e.g. when a RenderTexture is changed. This method is the
   *  easiest way to do so; it's just a shortcut to <code>stage.setRequiresRedraw()</code>.
   *  </p>
   */
  public function setRequiresRedraw():Void
  {
    _stage.setRequiresRedraw();
  }

  // event handlers

  private function onStage3DError(event:ErrorEvent):Void
  {
    if (event.errorID == 3702)
    {
      var mode:String = (Capabilities.playerType == "Desktop") ? "renderMode":"wmode";
      stopWithFatalError("Context3D not available! Possible reasons: wrong " + mode +
          " or missing device support.");
    }
    else
    {
      stopWithFatalError("Stage3D error: " + event.text);
    }
  }

  private function onContextCreated(event:Event):Void
  {
    stage3D.removeEventListener(Event.CONTEXT3D_CREATE, onContextCreated);
    stage3D.addEventListener(Event.CONTEXT3D_CREATE, onContextRestored, false, 10, true);

    trace("[Starling] Context ready. Display Driver:", context.driverInfo);
    initialize();
  }

  private function onContextRestored(event:Event):Void
  {
    trace("[Starling] Context restored.");
    updateViewPort(true);
    dispatchEventWith(Event.CONTEXT3D_CREATE, false, context);
  }

  private function onEnterFrame(event:Event):Void
  {
    // On mobile, the native display list is only updated on stage3D draw calls.
    // Thus, we render even when Starling is paused.

    if (!shareContext)
    {
      if (_started)
      {
        nextFrame();
      }
      else
      {
        if (_rendering)
        {
          render();
        }
      }
    }

    updateNativeOverlay();
  }

  private function onKey(event:KeyboardEvent):Void
  {
    if (!_started)
    {
      return;
    }

    var keyEvent:starling.events.KeyboardEvent = new starling.events.KeyboardEvent(
    event.type, event.charCode, event.keyCode, event.keyLocation,
    event.ctrlKey, event.altKey, event.shiftKey);

    makeCurrent();
    _stage.dispatchEvent(keyEvent);

    if (keyEvent.isDefaultPrevented())
    {
      event.preventDefault();
    }
  }

  private function onResize(event:Event):Void
  {
    var stageWidth:Int = cast(event.target, openfl.display.Stage).stageWidth;
    var stageHeight:Int = cast(event.target, openfl.display.Stage).stageHeight;

    var dispatchResizeEvent:Void->Void = null;
    dispatchResizeEvent = function():Void
    {
      // on Android, the context is not valid while we're resizing. To avoid problems
      // with user code, we delay the event dispatching until it becomes valid again.

      makeCurrent();
      removeEventListener(Event.CONTEXT3D_CREATE, dispatchResizeEvent);
      _stage.dispatchEvent(new ResizeEvent(Event.RESIZE, stageWidth, stageHeight));
    }

    if (contextValid)
    {
      dispatchResizeEvent();
    }
    else
    {
      addEventListener(Event.CONTEXT3D_CREATE, dispatchResizeEvent);
    }
  }

  private function onMouseLeave(event:Event):Void
  {
    _touchProcessor.enqueueMouseLeftStage();
  }

  private function onTouch(event:Event):Void
  {
    if (!_started)
    {
      return;
    }

    var globalX:Float;
    var globalY:Float;
    var touchID:Int;
    var phase:String = null;
    var pressure:Float = 1.0;
    var width:Float = 1.0;
    var height:Float = 1.0;

    // figure out general touch properties
    if (Std.is(event, MouseEvent))
    {
      var mouseEvent:MouseEvent = cast(event);
      globalX = mouseEvent.stageX;
      globalY = mouseEvent.stageY;
      touchID = 0;

      // MouseEvent.buttonDown returns true for both left and right button (AIR supports
      // the right mouse button). We only want to react on the left button for now,
      // so we have to save the state for the left button manually.
      if (event.type == MouseEvent.MOUSE_DOWN)
      {
        _leftMouseDown = true;
      }
      else
      {
        if (event.type == MouseEvent.MOUSE_UP)
        {
          _leftMouseDown = false;
        }
      }
    }
    else
    {
      var touchEvent:TouchEvent = cast(event);

      // On a system that supports both mouse and touch input, the primary touch point
      // is dispatched as mouse event as well. Since we don't want to listen to that
      // event twice, we ignore the primary touch in that case.

      if (Mouse.supportsCursor && touchEvent.isPrimaryTouchPoint)
      {
        return;
      }
      else
      {
        globalX = touchEvent.stageX;
        globalY = touchEvent.stageY;
        touchID = touchEvent.touchPointID;
        pressure = touchEvent.pressure;
        width = touchEvent.sizeX;
        height = touchEvent.sizeY;
      }
    }

    // figure out touch phase
    var _sw0_ = (event.type);

    switch (_sw0_)
    {
      case TouchEvent.TOUCH_BEGIN:phase = TouchPhase.BEGAN;
      case TouchEvent.TOUCH_MOVE:phase = TouchPhase.MOVED;
      case TouchEvent.TOUCH_END:phase = TouchPhase.ENDED;
      case MouseEvent.MOUSE_DOWN:phase = TouchPhase.BEGAN;
      case MouseEvent.MOUSE_UP:phase = TouchPhase.ENDED;
      case MouseEvent.MOUSE_MOVE:
        phase = ((_leftMouseDown) ? TouchPhase.MOVED:TouchPhase.HOVER);
    }

    // move position into viewport bounds
    globalX = _stage.stageWidth * (globalX - _viewPort.x) / _viewPort.width;
    globalY = _stage.stageHeight * (globalY - _viewPort.y) / _viewPort.height;

    // enqueue touch in touch processor
    _touchProcessor.enqueue(touchID, phase, globalX, globalY, pressure, width, height);

    // allow objects that depend on mouse-over state to be updated immediately
    if (event.type == MouseEvent.MOUSE_UP && Mouse.supportsCursor)
    {
      _touchProcessor.enqueue(touchID, TouchPhase.HOVER, globalX, globalY);
    }
  }

  private function get_touchEventTypes():Array<Dynamic>
  {
    var types:Array<Dynamic> = [];

    if (multitouchEnabled)
    {
      types.push(TouchEvent.TOUCH_BEGIN);
      types.push(TouchEvent.TOUCH_MOVE);
      types.push(TouchEvent.TOUCH_END);

    }

    if (!multitouchEnabled || Mouse.supportsCursor)
    {
      types.push(MouseEvent.MOUSE_DOWN);
      types.push(MouseEvent.MOUSE_MOVE);
      types.push(MouseEvent.MOUSE_UP);

    }

    return types;
  }

  private function get_mustAlwaysRender():Bool
  {
    // On mobile, and in some browsers with the "baselineConstrained" profile, the
    // standard display list is only rendered after calling "context.present()".
    // In such a case, we cannot omit frames if there is any content on the stage.

    if (!_skipUnchangedFrames || _painter.shareContext)
    {
      return true;
    }
    else
    {
      if (SystemUtil.isDesktop && profile != Context3DProfile.BASELINE_CONSTRAINED)
      {
        return false;
      }
      else
      {
        // Rendering can be skipped when both this and previous frame are empty.
        var nativeStageEmpty:Bool = IsNativeDisplayObjectEmpty.isNativeDisplayObjectEmpty(_nativeStage);
        var mustAlwaysRender:Bool = !nativeStageEmpty || !_nativeStageEmpty;
        _nativeStageEmpty = nativeStageEmpty;

        return mustAlwaysRender;
      }
    }
  }

  // properties

  /** Indicates if this Starling instance is started. */
  private function get_isStarted():Bool
  {
    return _started;
  }

  /** The default juggler of this instance. Will be advanced once per frame. */
  private function get_juggler():Juggler
  {
    return _juggler;
  }

  /** The painter, which is used for all rendering. The same instance is passed to all
   *  <code>render</code>methods each frame. */
  private function get_painter():Painter
  {
    return _painter;
  }

  /** The render context of this instance. */
  private function get_context():Context3D
  {
    return _painter.context;
  }

  /** Indicates if multitouch simulation with "Shift" and "Ctrl"/"Cmd"-keys is enabled.
   *  @default false */
  private function get_simulateMultitouch():Bool
  {
    return _touchProcessor.simulateMultitouch;
  }
  private function set_simulateMultitouch(value:Bool):Bool
  {
    _touchProcessor.simulateMultitouch = value;
    return value;
  }

  /** Indicates if Stage3D render methods will report errors. It's recommended to activate
   *  this when writing custom rendering code (shaders, etc.), since you'll get more detailed
   *  error messages. However, it has a very negative impact on performance, and it prevents
   *  ATF textures from being restored on a context loss. Never activate for release builds!
   *
   *  @default false */
  private function get_enableErrorChecking():Bool
  {
    return _painter.enableErrorChecking;
  }
  private function set_enableErrorChecking(value:Bool):Bool
  {
    _painter.enableErrorChecking = value;
    return value;
  }

  /** The anti-aliasing level. 0 - none, 16 - maximum. @default 0 */
  private function get_antiAliasing():Int
  {
    return _antiAliasing;
  }
  private function set_antiAliasing(value:Int):Int
  {
    if (_antiAliasing != value)
    {
      _antiAliasing = value;
      if (contextValid)
      {
        updateViewPort(true);
      }
    }
    return value;
  }

  /** The viewport into which Starling contents will be rendered. */
  private function get_viewPort():Rectangle
  {
    return _viewPort;
  }
  private function set_viewPort(value:Rectangle):Rectangle
  {
    _viewPort = value.clone();
    return value;
  }

  /** The ratio between viewPort width and stage width. Useful for choosing a different
   *  set of textures depending on the display resolution. */
  private function get_contentScaleFactor():Float
  {
    return (_viewPort.width * _painter.backBufferScaleFactor) / _stage.stageWidth;
  }

  /** A Flash Sprite placed directly on top of the Starling content. Use it to display native
   *  Flash components. */
  private function get_nativeOverlay():Sprite
  {
    return _nativeOverlay;
  }

  /** Indicates if a small statistics box (with FPS, memory usage and draw count) is
   *  displayed.
   *
   *  <p>When the box turns dark green, more than 50% of the frames since the box' last
   *  update could skip rendering altogether. This will only happen if the property
   *  <code>skipUnchangedFrames</code> is enabled.</p>
   *
   *  <p>Beware that the memory usage should be taken with a grain of salt. The value is
   *  determined via <code>System.totalMemory</code> and does not take texture memory
   *  into account. It is recommended to use Adobe Scout for reliable and comprehensive
   *  memory analysis.</p>
   */
  private function get_showStats():Bool
  {
    return _showStats;
  }
  private function set_showStats(value:Bool):Bool
  {
    _showStats = value;

    if (value)
    {
      if (_statsDisplay != null)
      {
        _stage.addChild(_statsDisplay);
      }
      else
      {
        showStatsAt();
      }
    }
    else
    {
      if (_statsDisplay != null)
      {
        _statsDisplay.removeFromParent();
      }
    }
    return value;
  }

  /** Displays the statistics box at a certain position. */
  public function showStatsAt(horizontalAlign:String = "left",
      verticalAlign:String = "top", scale:Float = 1):Void
  {
    _showStats = true;

    var onRootCreated:Void->Void = null;
    onRootCreated = function():Void
    {
      if (_showStats)
      {
        showStatsAt(horizontalAlign, verticalAlign, scale);
      }
      removeEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
    }

    if (context == null)
    {
      // Starling is not yet ready - we postpone this until it's initialized.
      addEventListener(starling.events.Event.ROOT_CREATED, onRootCreated);
    }
    else
    {
      var stageWidth:Int = _stage.stageWidth;
      var stageHeight:Int = _stage.stageHeight;

      if (_statsDisplay == null)
      {
        _statsDisplay = new StatsDisplay();
        _statsDisplay.touchable = false;
      }

      _stage.addChild(_statsDisplay);
      _statsDisplay.scaleX = _statsDisplay.scaleY = scale;

      if (horizontalAlign == Align.LEFT)
      {
        _statsDisplay.x = 0;
      }
      else
      {
        if (horizontalAlign == Align.RIGHT)
        {
          _statsDisplay.x = stageWidth - _statsDisplay.width;
        }
        else
        {
          if (horizontalAlign == Align.CENTER)
          {
            _statsDisplay.x = (stageWidth - _statsDisplay.width) / 2;
          }
          else
          {
            throw new ArgumentError("Invalid horizontal alignment: " + horizontalAlign);
          }
        }
      }

      if (verticalAlign == Align.TOP)
      {
        _statsDisplay.y = 0;
      }
      else
      {
        if (verticalAlign == Align.BOTTOM)
        {
          _statsDisplay.y = stageHeight - _statsDisplay.height;
        }
        else
        {
          if (verticalAlign == Align.CENTER)
          {
            _statsDisplay.y = (stageHeight - _statsDisplay.height) / 2;
          }
          else
          {
            throw new ArgumentError("Invalid vertical alignment: " + verticalAlign);
          }
        }
      }
    }
  }

  /** The Starling stage object, which is the root of the display tree that is rendered. */
  private function get_stage():Stage
  {
    return _stage;
  }

  /** The Flash Stage3D object Starling renders into. */
  private function get_stage3D():Stage3D
  {
    return _painter.stage3D;
  }

  /** The Flash (2D) stage object Starling renders beneath. */
  private function get_nativeStage():flash.display.Stage
  {
    return _nativeStage;
  }

  /** The instance of the root class provided in the constructor. Available as soon as
   *  the event 'ROOT_CREATED' has been dispatched. */
  private function get_root():DisplayObject
  {
    return _root;
  }

  /** The class that will be instantiated by Starling as the 'root' display object.
   *  Must be a subclass of 'starling.display.DisplayObject'.
   *
   *  <p>If you passed <code>null</code> as first parameter to the Starling constructor,
   *  you can use this property to set the root class at a later time. As soon as the class
   *  is instantiated, Starling will dispatch a <code>ROOT_CREATED</code> event.</p>
   *
   *  <p>Beware: you cannot change the root class once the root object has been
   *  instantiated.</p>
   */
  private function get_rootClass():Class<Dynamic>
  {
    return _rootClass;
  }
  private function set_rootClass(value:Class<Dynamic>):Class<Dynamic>
  {
    if (_rootClass != null && _root != null)
    {
      throw new Error("Root class may not change after root has been instantiated");
    }
    else
    {
      if (_rootClass == null)
      {
        _rootClass = value;
        if (context != null)
        {
          initializeRoot();
        }
      }
    }
    return value;
  }

  /** Indicates if another Starling instance (or another Stage3D framework altogether)
   *  uses the same render context. If enabled, Starling will not execute any destructive
   *  context operations (e.g. not call 'configureBackBuffer', 'clear', 'present', etc.
   *  This has to be done manually, then. @default false */
  private function get_shareContext():Bool
  {
    return _painter.shareContext;
  }
  private function set_shareContext(value:Bool):Bool
  {
    _painter.shareContext = value;
    return value;
  }

  /** The Context3D profile of the current render context, or <code>null</code>
   *  if the context has not been created yet. */
  private function get_profile():String
  {
    return _painter.profile;
  }

  /** Indicates that if the device supports HiDPI screens Starling will attempt to allocate
   *  a larger back buffer than indicated via the viewPort size. Note that this is used
   *  on Desktop only; mobile AIR apps still use the "requestedDisplayResolution" parameter
   *  the application descriptor XML. @default false */
  private function get_supportHighResolutions():Bool
  {
    return _supportHighResolutions;
  }
  private function set_supportHighResolutions(value:Bool):Bool
  {
    if (_supportHighResolutions != value)
    {
      _supportHighResolutions = value;
      if (contextValid)
      {
        updateViewPort(true);
      }
    }
    return value;
  }

  /** When enabled, Starling will skip rendering the stage if it hasn't changed since the
   *  last frame. This is great for apps that remain static from time to time, since it will
   *  greatly reduce power consumption. You should activate this whenever possible!
   *
   *  <p>The reason why it's disabled by default is just that it causes problems with Render-
   *  and VideoTextures. When you use those, you either have to disable this property
   *  temporarily, or call <code>setRequiresRedraw()</code> (ideally on the stage) whenever
   *  those textures are changing. Otherwise, the changes won't show up.</p>
   *
   *  @default false
   */
  private function get_skipUnchangedFrames():Bool
  {
    return _skipUnchangedFrames;
  }
  private function set_skipUnchangedFrames(value:Bool):Bool
  {
    _skipUnchangedFrames = value;
    _nativeStageEmpty = false;
    return value;
  }

  /** The TouchProcessor is passed all mouse and touch input and is responsible for
   *  dispatching TouchEvents to the Starling display tree. If you want to handle these
   *  types of input manually, pass your own custom subclass to this property. */
  private function get_touchProcessor():TouchProcessor
  {
    return _touchProcessor;
  }
  private function set_touchProcessor(value:TouchProcessor):TouchProcessor
  {
    if (value == null)
    {
      throw new ArgumentError("TouchProcessor must not be null");
    }
    else
    {
      if (value != _touchProcessor)
      {
        _touchProcessor.dispose();
        _touchProcessor = value;
      }
    }
    return value;
  }

  /** The number of frames that have been rendered since this instance was created. */
  private function get_frameID():Int
  {
    return _frameID;
  }

  /** Indicates if the Context3D object is currently valid (i.e. it hasn't been lost or
   *  disposed). */
  private function get_contextValid():Bool
  {
    return _painter.contextValid;
  }

  // static properties

  /** The currently active Starling instance. */
  private static function get_current():Starling
  {
    return sCurrent;
  }

  /** All Starling instances. <p>CAUTION: not a copy, but the actual object! Do not modify!</p> */
  private static function get_all():Vector<Starling>
  {
    return sAll;
  }

  /** The render context of the currently active Starling instance. */
  public static function context_():Context3D
  {
    return (sCurrent != null) ? sCurrent.context:null;
  }

  /** The default juggler of the currently active Starling instance. */
  public static function juggler_():Juggler
  {
    return (sCurrent != null) ? sCurrent._juggler:null;
  }

  /** The painter used for all rendering of the currently active Starling instance. */
  public static function painter_():Painter
  {
    return (sCurrent != null) ? sCurrent._painter:null;
  }

  /** The contentScaleFactor of the currently active Starling instance. */
  public static function contentScaleFactor_():Float
  {
    return (sCurrent != null) ? sCurrent.contentScaleFactor:1.0;
  }

  /** Indicates if multitouch input should be supported. */
  private static function get_multitouchEnabled():Bool
  {
    return Multitouch.inputMode == MultitouchInputMode.TOUCH_POINT;
  }

  private static function set_multitouchEnabled(value:Bool):Bool
  {
    if (sCurrent != null)
    {
      throw new IllegalOperationError(
      "'multitouchEnabled' must be set before Starling instance is created");
    }
    else
    {
      Multitouch.inputMode = (value) ? MultitouchInputMode.TOUCH_POINT:
          MultitouchInputMode.NONE;
    }
    return value;
  }

  /** The number of frames that have been rendered since the current instance was created. */
  public static function frameID_():Int
  {
    return (sCurrent != null) ? sCurrent._frameID:0;
  }
}
/**
 * Class for isNativeDisplayObjectEmpty
 */
@:final class IsNativeDisplayObjectEmpty
{
  // put here to avoid naming conflicts
  public static function isNativeDisplayObjectEmpty(object:openfl.display.DisplayObject):Bool
  {
    if (object == null)
    {
      return true;
    }
    else
    {
      if (Std.is(object, openfl.display.DisplayObjectContainer))
      {
        var container:openfl.display.DisplayObjectContainer = cast(object);
        var numChildren:Int = container.numChildren;

        for (i in 0...numChildren)
        {
          if (!isNativeDisplayObjectEmpty(container.getChildAt(i)))
          {
            return false;
          }
        }

        return true;
      }
      else
      {
        return !object.visible;
      }
    }
  }

  public function new()
  {
  }
}
