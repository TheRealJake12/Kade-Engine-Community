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

		start();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	function start()
	{
		if (!FlxG.save.data.unload)
		{
			switch (cache.BaseCache.loadedBefore)
			{
				case false:
					FlxG.autoPause = false;
					new lime.app.Future<Void>(function()
					{
						// Finally, the loading screen doesn't crash a lot now.
						for (directory in [
							/* Regular stuff */ 'assets/images/',
							'assets/songs/',
							/* Shared stuff */ 'assets/shared/images/',
							'assets/shared/sounds/',
							'assets/shared/music/'
						])
						{
							cache.BaseCache.cacheStuff(directory);
						}
						haxe.Timer.delay(function() // this is fine
						{
							cache.BaseCache.loadedBefore = true;
							FlxG.autoPause = FlxG.save.data.autoPause;
							LoadingState.loadAndSwitchState(new PlayState());
							Debug.logTrace("Done");
						}, 600);
					}, true);
				case true:
					LoadingState.loadAndSwitchState(new PlayState());
					Debug.logTrace("Loaded Before, No Need To Load Again.");
			}
		}
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}
}
