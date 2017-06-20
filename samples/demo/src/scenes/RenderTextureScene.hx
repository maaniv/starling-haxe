package scenes;

import flash.geom.Point;
import starling.display.BlendMode;
import starling.display.Button;
import starling.display.Image;
import starling.events.Event;
import starling.events.TouchEvent;
import starling.events.TouchPhase;
import starling.text.TextField;
import starling.textures.RenderTexture;
import utils.MenuButton;

class RenderTextureScene extends Scene
{
  private var _renderTexture:RenderTexture;
  private var _canvas:Image;
  private var _brush:Image;
  private var _button:Button;
  private var _colors:Map<Int, UInt>;

  public function new()
  {
    super();
    _colors = new Map();
    _renderTexture = new RenderTexture(320, 435);

    _canvas = new Image(_renderTexture);
    _canvas.addEventListener(TouchEvent.TOUCH, onTouch);
    addChild(_canvas);

    _brush = new Image(Game.assets.getTexture("brush"));
    _brush.pivotX = _brush.width / 2;
    _brush.pivotY = _brush.height / 2;
    _brush.blendMode = BlendMode.NORMAL;

    var infoText:TextField = new TextField(256, 128, "Touch the screen\nto draw!");
    infoText.format.size = 24;
    infoText.x = Constants.CenterX - infoText.width / 2;
    infoText.y = Constants.CenterY - infoText.height / 2;
    _renderTexture.draw(infoText);
    infoText.dispose();

    _button = new MenuButton("Mode: Draw");
    _button.x = Std.int(Constants.CenterX - _button.width / 2);
    _button.y = 15;
    _button.addEventListener(Event.TRIGGERED, onButtonTriggered);
    addChild(_button);
  }

  override private function onTouch(event:TouchEvent):Void
  {
    // touching the canvas will draw a brush texture. The 'drawBundled' method is not
    // strictly necessary, but it's faster when you are drawing with several fingers
    // simultaneously.

    _renderTexture.drawBundled(function():Void
        {
          var touches = event.getTouches(_canvas);

          for (touch in touches)
          {
            if (touch.phase == TouchPhase.BEGAN)
            {
              var max_int:UInt = 0xFFFFFFFF;
              _colors[touch.id] = Std.int(Math.random() * max_int);
            }

            if (touch.phase == TouchPhase.HOVER || touch.phase == TouchPhase.ENDED)
            {
              continue;
            }

            var location:Point = touch.getLocation(_canvas);
            _brush.x = location.x;
            _brush.y = location.y;
            _brush.color = _colors[touch.id];
            _brush.rotation = Math.random() * Math.PI * 2.0;

            _renderTexture.draw(_brush);

            // necessary because 'Starling.skipUnchangedFrames == true'
            setRequiresRedraw();
          }
        });
  }

  private function onButtonTriggered():Void
  {
    if (_brush.blendMode == BlendMode.NORMAL)
    {
      _brush.blendMode = BlendMode.ERASE;
      _button.text = "Mode: Erase";
    }
    else
    {
      _brush.blendMode = BlendMode.NORMAL;
      _button.text = "Mode: Draw";
    }
  }

  override public function dispose():Void
  {
    _renderTexture.dispose();
    super.dispose();
  }
}
