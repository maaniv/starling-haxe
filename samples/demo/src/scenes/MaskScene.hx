package scenes;

import flash.geom.Point;
import starling.core.Starling;
import starling.display.Canvas;
import starling.display.Image;
import starling.display.Quad;
import starling.display.Sprite;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.filters.ColorMatrixFilter;
import starling.text.TextField;

class MaskScene extends Scene
{
  private var _contents:Sprite;
  private var _scene_mask:Canvas;
  private var _maskDisplay:Canvas;

  public function new()
  {
    super();
    _contents = new Sprite();
    addChild(_contents);

    var stageWidth:Float = Starling.current.stage.stageWidth;
    var stageHeight:Float = Starling.current.stage.stageHeight;

    var touchQuad:Quad = new Quad(stageWidth, stageHeight);
    touchQuad.alpha = 0;  // only used to get touch events
    addChildAt(touchQuad, 0);

    var image:Image = new Image(Game.assets.getTexture("flight_00"));
    image.x = (stageWidth - image.width) / 2;
    image.y = 80;
    _contents.addChild(image);

    // just to prove it works, use a filter on the image.
    var cm:ColorMatrixFilter = new ColorMatrixFilter();
    cm.adjustHue(-0.5);
    image.filter = cm;

    var maskText:TextField = new TextField(256, 128,
    "Move the mouse (or a finger) over the screen to move the mask.");
    maskText.x = (stageWidth - maskText.width) / 2;
    maskText.y = 260;
    maskText.format.size = 20;
    _contents.addChild(maskText);

    _maskDisplay = createCircle();
    _maskDisplay.alpha = 0.1;
    _maskDisplay.touchable = false;
    addChild(_maskDisplay);

    _scene_mask = createCircle();
    _contents.mask = _scene_mask;

    addEventListener(TouchEvent.TOUCH, onTouch);
  }

  override private function onTouch(event:TouchEvent):Void
  {
    //var touch:Touch = event.getTouch(this, TouchPhase.HOVER) != null ||
    // event.getTouch(this, TouchPhase.BEGAN) != null ||
    // event.getTouch(this, TouchPhase.MOVED) != null;

    var touch = event.getTouch(this, TouchPhase.HOVER);
    if (touch == null) touch = event.getTouch(this, TouchPhase.BEGAN);
    if (touch == null) touch = event.getTouch(this, TouchPhase.MOVED);

    if (touch != null)
    {
      var localPos:Point = touch.getLocation(this);
      _scene_mask.x = _maskDisplay.x = localPos.x;
      _scene_mask.y = _maskDisplay.y = localPos.y;
    }
  }

  private function createCircle():Canvas
  {
    var circle:Canvas = new Canvas();
    circle.beginFill(0xff0000);
    circle.drawCircle(0, 0, 100);
    circle.endFill();
    return circle;
  }
}
