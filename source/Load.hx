package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import perf.Destroyer;

class Load extends MusicBeatState
{
    var load:FlxSprite = new FlxSprite(0);

    override public function create()
    {
       Destroyer.clearStoredMemory();
       Destroyer.clearUnusedMemory();
        load.loadGraphic(Paths.image('funkay')); 
        load.screenCenter();
        load.scale.set(0.76, 0.67);
        add(load);
        new FlxTimer().start(2, function(tmr:FlxTimer)
        {
            LoadingState.loadAndSwitchState(new PlayState());
        });
        super.create();
    }
    override function update(elapsed:Float)
    {
        super.update(elapsed);
    }

}