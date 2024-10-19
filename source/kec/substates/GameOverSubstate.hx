package kec.substates;

import kec.objects.Character;
import kec.backend.PlayStateChangeables;

class GameOverSubstate extends MusicBeatSubstate
{
	public var bf:Character;

	var camFollow:FlxObject;
	var stageSuffix:String = "";

	public static var instance:GameOverSubstate = null;

	public function new()
	{
		super();
	}

	override function create()
	{
		Paths.clearCache();
		instance = this;

		var daBf:String = '';
		var char:Character = PlayState.instance.boyfriend;
		if (PlayStateChangeables.opponentMode)
			char = PlayState.instance.dad;

		var styleShit:String = (PlayState.STYLE.style == null ? 'default' : PlayState.STYLE.style).toLowerCase();
		var daBf:String = '';
		switch (char.data.char)
		{
			default:
				daBf = char.data.deadChar;
		}

		if (daBf == null || daBf.length == 0)
			daBf = 'bf-dead';

		if (styleShit != 'default')
			stageSuffix = '-${styleShit}';

		Conductor.songPosition = 0;

		bf = new Character(char.getScreenPosition().x, char.getScreenPosition().y, daBf);
		camFollow = new FlxObject(bf.getMidpoint().x + bf.data.camPos[0], bf.getMidpoint().y + bf.data.camPos[1], 1, 1);
		add(bf);
		add(camFollow);

		if (Paths.fileExists('sounds/styles/$styleShit/fnf_loss_sfx.ogg'))
			FlxG.sound.play(Paths.sound('styles/$styleShit/fnf_loss_sfx'));
		else
			FlxG.sound.play(Paths.sound('styles/default/fnf_loss_sfx'));
		Conductor.bpm = 100;

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		bf.playAnim('firstDeath');
		super.create();
	}

	var startVibin:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.ACCEPT)
		{
			endBullshit();
		}

		if (controls.BACK)
		{
			FlxG.sound.music.stop();

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new FreeplayState());
		}

		if (bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if (!PlayStateChangeables.opponentMode && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
		{
			if (PlayState.SONG.stage == 'tank')
			{
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix), 0.2);
				FlxG.sound.play(Paths.sound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25)), 1, false, null, true, function()
				{
					if (!isEnding)
					{
						FlxG.sound.music.fadeIn(0.2, 1, 4);
					}
				});
			}
			else
				FlxG.sound.playMusic(Paths.music('gameOver' + stageSuffix));

			startVibin = true;
		}

		if (FlxG.sound.music.playing)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (startVibin && !isEnding)
		{
			bf.playAnim('deathLoop', bf.animForces.get(bf.animation.curAnim.name));
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			PlayState.startTime = 0;
			isEnding = true;
			if (bf.animOffsets.exists('deathConfirm'))
				bf.playAnim('deathConfirm', true);

			FlxG.sound.music.stop();

			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					MusicBeatState.switchState(new PlayState());
				});
			});
		}
	}

	override function destroy()
	{
		instance = null;
		super.destroy();
	}
}
