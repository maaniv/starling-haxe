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

import starling.utils.StringUtil;
import flash.system.System;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.EnterFrameEvent;
import starling.events.Event;
import starling.rendering.Painter;
import starling.styles.MeshStyle;
import starling.text.BitmapFont;
import starling.text.TextField;
import starling.utils.Align;

/** A small, lightweight box that displays the current framerate, memory consumption and
 *  the number of draw calls per frame. The display is updated automatically once per frame. */
class StatsDisplay extends Sprite
{
  private var supportsGpuMem(get, never):Bool;
  public var drawCount(get, set):Int;
  public var fps(get, set):Float;
  public var memory(get, set):Float;
  public var gpuMemory(get, set):Float;

  private static inline var UPDATE_INTERVAL:Float = 0.5;
  private static var B_TO_MB:Float = 1.0 / (1024 * 1024);  // convert from bytes to MB

  private var _background:Quad = null;
  private var _labels:TextField = null;
  private var _values:TextField = null;

  private var _frameCount:Int = 0;
  private var _totalTime:Float = 0;

  private var _fps:Float = 0;
  private var _memory:Float = 0;
  private var _gpuMemory:Float = 0;
  private var _drawCount:Int = 0;
  private var _skipCount:Int = 0;

  /** Creates a new Statistics Box. */
  @:allow(starling.core)
  private function new()
  {
    super();
    var fontName:String = BitmapFont.MINI;
    var fontSize:Float = BitmapFont.NATIVE_SIZE;
    var fontColor:Int = 0xffffff;
    var width:Float = 90;
    var height:Float = (supportsGpuMem) ? 35:27;
    var gpuLabel:String = (supportsGpuMem) ? "\ngpu memory:":"";
    var labels:String = "frames/sec:\nstd memory:" + gpuLabel + "\ndraw calls:";

    _labels = new TextField(Std.int(width), Std.int(height), labels);
    _labels.format.setTo(fontName, fontSize, fontColor, Align.LEFT);
    _labels.batchable = true;
    _labels.x = 2;

    _values = new TextField(Std.int(width - 1), Std.int(height), "");
    _values.format.setTo(fontName, fontSize, fontColor, Align.RIGHT);
    _values.batchable = true;

    _background = new Quad(width, height, 0x0);

    // make sure that rendering takes 2 draw calls
    if (_background.style.type != MeshStyle)
    {
      _background.style = new MeshStyle();
    }
    if (_labels.style.type != MeshStyle)
    {
      _labels.style = new MeshStyle();
    }
    if (_values.style.type != MeshStyle)
    {
      _values.style = new MeshStyle();
    }

    addChild(_background);
    addChild(_labels);
    addChild(_values);

    addEventListener(Event.ADDED_TO_STAGE, onAddedToStage);
    addEventListener(Event.REMOVED_FROM_STAGE, onRemovedFromStage);
  }

  private function onAddedToStage():Void
  {
    addEventListener(Event.ENTER_FRAME, onEnterFrame);
    _totalTime = _frameCount = _skipCount = 0;
    update();
  }

  private function onRemovedFromStage():Void
  {
    removeEventListener(Event.ENTER_FRAME, onEnterFrame);
  }

  private function onEnterFrame(event:EnterFrameEvent):Void
  {
    _totalTime += event.passedTime;
    _frameCount++;

    if (_totalTime > UPDATE_INTERVAL)
    {
      update();
      _totalTime = _frameCount = _skipCount = 0;
    }
  }

  /** Updates the displayed values. */
  public function update():Void
  {
    _background.color = (_skipCount > _frameCount / 2) ? 0x003F00:0x0;
    _fps = (_totalTime > 0) ? _frameCount / _totalTime:0;
    _memory = System.totalMemory * B_TO_MB;
    _gpuMemory = (supportsGpuMem) ? Reflect.getProperty(Starling.context_(), "totalGPUMemory") * B_TO_MB : -1;

    var fpsText:String = StringUtil.toFixed(_fps, (_fps < 100) ? 1:0);
    var memText:String = StringUtil.toFixed(_memory, (_memory < 100) ? 1:0);
    var gpuMemText:String = StringUtil.toFixed(_gpuMemory, (_gpuMemory < 100) ? 1:0);
    var drwText:String = Std.string((_totalTime > 0) ? _drawCount - 2:_drawCount);  // ignore self

    _values.text = fpsText + "\n" + memText + "\n" +
        ((_gpuMemory >= 0) ? gpuMemText + "\n":"") + drwText;
  }

  /** Call this once in every frame that can skip rendering because nothing changed. */
  public function markFrameAsSkipped():Void
  {
    _skipCount += 1;
  }

  override public function render(painter:Painter):Void
  {
    // By calling 'finishQuadBatch' and 'excludeFromCache', we can make sure that the stats
    // display is always rendered with exactly two draw calls. That is taken into account
    // when showing the drawCount value (see 'ignore self' comment above)

    painter.excludeFromCache(this);
    painter.finishMeshBatch();
    super.render(painter);
  }

  /** Indicates if the current runtime supports the 'totalGPUMemory' API. */
  private function get_supportsGpuMem():Bool
  {
    return Reflect.getProperty(Starling.context_(), "totalGPUMemory") != null;
  }

  /** The number of Stage3D draw calls per second. */
  private function get_drawCount():Int
  {
    return _drawCount;
  }
  private function set_drawCount(value:Int):Int
  {
    _drawCount = value;
    return value;
  }

  /** The current frames per second (updated twice per second). */
  private function get_fps():Float
  {
    return _fps;
  }
  private function set_fps(value:Float):Float
  {
    _fps = value;
    return value;
  }

  /** The currently used system memory in MB. */
  private function get_memory():Float
  {
    return _memory;
  }
  private function set_memory(value:Float):Float
  {
    _memory = value;
    return value;
  }

  /** The currently used graphics memory in MB. */
  private function get_gpuMemory():Float
  {
    return _gpuMemory;
  }
  private function set_gpuMemory(value:Float):Float
  {
    _gpuMemory = value;
    return value;
  }
}
