package {
import flash.display.Sprite;
import flash.utils.setTimeout;

public class Test extends Sprite {
  public function Test() {
    Deferred
      .next(function ():void {
        trace('hehe');
      })
      .next(function ():void {
        trace('hoho');
      });
  }

  private function _outputEventLoopInterval():void {

  }
}
}
