//import openfl.utils.ByteArray;
import starling.text.TextField;
import starling.textures.TextureAtlas;
import starling.text.BitmapFont;
import openfl.system.Capabilities;
import flash.system.System;
import flash.ui.Keyboard;
import scenes.Scene;
import starling.core.Starling;
import starling.display.Button;
import starling.display.Image;
import starling.display.Sprite;
import starling.events.Event;
import starling.events.KeyboardEvent;
import starling.utils.AssetManager;
import starling.textures.Texture;
import openfl.Assets;
//import flash.utils.ByteArray;

class Game extends Sprite
{
  public static var assets(get, never):AssetManager;

  // Embed the Ubuntu Font. Beware: the 'embedAsCFF'-part IS REQUIRED!!!
  @:meta(Embed(source="../../demo/assets/fonts/Ubuntu-R.ttf",embedAsCFF="false",fontFamily="Ubuntu"))

  private static var UbuntuRegular:Class<Dynamic>;

  private var _mainMenu:MainMenu;
  private var _currentScene:Scene;

  private static var sAssets:AssetManager;

  public function new()
  {
    super();
    //touchable = false;
    addEventListener(Event.ADDED_TO_STAGE, OnStageAdded);
  }

  function OnStageAdded(event:Event):Void {
    removeEventListener(Event.ADDED_TO_STAGE, OnStageAdded);

    var assets:AssetManager = new AssetManager();

    assets.verbose = Capabilities.isDebugger;

    // Timer.delay(function()
    // {

        var atlasTexture:Texture = Texture.fromBitmapData(Assets.getBitmapData("assets/textures/1x/atlas.png"), false);
        var atlasXml = Xml.parse(Assets.getText("assets/textures/1x/atlas.xml"));
        var desyrelTexture:Texture = Texture.fromBitmapData(Assets.getBitmapData("assets/fonts/1x/desyrel.png"), false);
        var desyrelXml = Xml.parse(Assets.getText("assets/fonts/1x/desyrel.fnt"));
        TextField.registerBitmapFont(new BitmapFont(desyrelTexture, desyrelXml));
        assets.addTexture("atlas", atlasTexture);
        assets.addTextureAtlas("atlas", new TextureAtlas(atlasTexture, atlasXml));
        assets.addTexture("background", Texture.fromBitmapData(Assets.getBitmapData("assets/textures/1x/background.jpg"), false));
        #if flash
        assets.addSound("wing_flap", Assets.getSound("assets/audio/wing_flap.mp3"));
  var compressedTexture = Assets.getBytes("assets/textures/1x/compressed_texture.atf");
  assets.addByteArray("compressed_texture", compressedTexture);
        #else
        assets.addSound("wing_flap", Assets.getSound("assets/audio/wing_flap.ogg"));
  //var compressedByteArray:ByteArray = Assets.getBytes("assets/textures/1x/compressed_texture.atf");
  // var compressedTexture = Texture.fromData(compressedByteArray);
  // assets.addTexture("compressed_texture", compressedTexture);
        #end

        start(assets);
        // onComplete(assets);
    // }, 0);
  }

  public function start(assets:AssetManager):Void
  {
    sAssets = assets;
    addChild(new Image(assets.getTexture("background")));
    showMainMenu();

    addEventListener(Event.TRIGGERED, onButtonTriggered);
    stage.addEventListener(KeyboardEvent.KEY_DOWN, onKey);
  }

  private function showMainMenu():Void
  {
    // now would be a good time for a clean-up
    // System.pauseForGCIfCollectionImminent(0);
    System.gc();

    if (_mainMenu == null)
    {
      _mainMenu = new MainMenu();
    }

    addChild(_mainMenu);
  }

  private function onKey(event:KeyboardEvent):Void
  {
    if (event.keyCode == Keyboard.SPACE)
    {
      Starling.current.showStats = !Starling.current.showStats;
    }
    else
    {
      if (event.keyCode == Keyboard.X)
      {
        Starling.context_().dispose();
      }
    }
  }

  private function onButtonTriggered(event:Event):Void
  {
    var button:Button = cast(event.target);

    if (button.name == "backButton")
    {
      closeScene();
    }
    else
    {
      //cpp.vm.Profiler.start("/mnt/data-1/maaniv/starling-demo/bin/linux64/cpp/release/bin/log.txt");
      showScene(button.name);
      //cpp.vm.Profiler.stop();
    }
  }

  private function closeScene():Void
  {
    _currentScene.removeFromParent(true);
    _currentScene = null;
    showMainMenu();
  }

  private function showScene(name:String):Void
  {
    if (_currentScene != null)
    {
      return;
    }

    var sceneClass:Class<Dynamic> = Type.resolveClass(name);
    _currentScene = Type.createInstance(sceneClass, []);
    _mainMenu.removeFromParent();
    addChild(_currentScene);
  }

  private static function get_assets():AssetManager
  {
    return sAssets;
  }
}
