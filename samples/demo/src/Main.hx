
import openfl.errors.Error;
import openfl.events.Event;
import starling.utils.RectangleUtil;
import openfl.geom.Rectangle;
import starling.core.Starling;

#if debug
//import debugger.HaxeRemote;
#end

class Main extends openfl.display.Sprite {
  public function new () {
#if debug
    //new debugger.HaxeRemote(true, "localhost");
    //new debugger.Local(true);
#end
    super();

    //game_ = new Game();

    //for(i in 2...2) trace("i: ", i);

    this.stage.addEventListener(Event.RESIZE, onResize, false, 2147483647,
      true);

    var starling:Starling = new Starling(Game, stage);
    starling.stage.stageWidth = Constants.GameWidth;
    starling.stage.stageHeight = Constants.GameHeight;
    starling.showStats = true;
    starling.simulateMultitouch = true;
    //starling.skipUnchangedFrames = true;
    starling.start();
  }

  private function onResize(e:openfl.events.Event):Void
  {
    trace("onResize: ", stage.stageWidth, stage.stageHeight);
    var viewPort = RectangleUtil.fit(
      new Rectangle(0, 0, Constants.GameWidth, Constants.GameHeight),
      new Rectangle(0, 0, stage.stageWidth, stage.stageHeight));
    try
    {
      Starling.current.viewPort = viewPort;
    }
    catch(error:Error) {
      trace("onResize exception");
    }
  }

  //var game_:Game = null;
}
