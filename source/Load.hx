package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import lime.app.Future;

class Load extends MusicBeatState
{
	var load:FlxSprite = new FlxSprite(0, 0);

	override public function create()
	{
		FlxG.sound.music.stop();
		load.loadGraphic(Paths.image('funkay'));
		load.setGraphicSize(0, FlxG.height);
		load.updateHitbox();
		add(load);
		super.create();

		LoadingState.loadAndSwitchState(new PlayState());
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function start()
	{
		LoadingState.loadAndSwitchState(new PlayState());
	}
}
