package kec.substates;

import kec.objects.Character;
import kec.backend.PlayStateChangeables;

class GameOverSubstate extends MusicBeatSubstate
{
	public var bf:Character;

	public var dad:Character;

	var camFollow:FlxObject;

	var charX:Float = 0;

	var charY:Float = 0;

	var stageSuffix:String = "";

	public static var instance:GameOverSubstate = null;

	public function new()
	{
		super();
	}

	override function create()
	{
		Paths.clearUnusedMemory();
		instance = this;

		var daBf:String = '';
		var styleShit:String = (PlayState.STYLE.style == null ? 'default' : PlayState.STYLE.style).toLowerCase();
		switch (PlayState.instance.boyfriend.curCharacter)
		{
			case 'bf-pixel':
				stageSuffix = '-pixel';
				daBf = 'bf-pixel-dead';
			default:
				daBf = PlayState.instance.boyfriend.deadChar;
		}

		var leDad:String = '';
		switch (PlayState.instance.dad.curCharacter)
		{
			default:
				leDad = PlayState.instance.dad.deadChar;
		}

		Conductor.songPosition = 0;

		if (PlayStateChangeables.opponentMode)
		{
			dad = new Character(PlayState.instance.dad.getScreenPosition().x, PlayState.instance.dad.getScreenPosition().y, leDad);
			camFollow = new FlxObject(dad.getMidpoint().x + dad.camPos[0], dad.getMidpoint().y + dad.camPos[1], 1, 1);
			add(dad);
		}
		else
		{
			bf = new Character(PlayState.instance.boyfriend.getScreenPosition().x, PlayState.instance.boyfriend.getScreenPosition().y, daBf, true);
			camFollow = new FlxObject(bf.getMidpoint().x + bf.camPos[0], bf.getMidpoint().y + bf.camPos[1], 1, 1);
			add(bf);
		}

		add(camFollow);

		FlxG.sound.play(Paths.sound('styles/$styleShit/fnf_loss_sfx'));
		Conductor.changeBPM(100);

		// FlxG.camera.followLerp = 1;
		// FlxG.camera.focusOn(FlxPoint.get(FlxG.width / 2, FlxG.height / 2));
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;
		if (PlayStateChangeables.opponentMode)
			dad.playAnim('firstDeath');
		else
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
			{
				GameplayCustomizeState.freeplayNoteStyle = 'normal';
				MusicBeatState.switchState(new StoryMenuState());
			}
			else
				MusicBeatState.switchState(new FreeplayState());
		}

		if ((!PlayStateChangeables.opponentMode && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.curFrame == 12)
			|| (PlayStateChangeables.opponentMode && dad.animation.curAnim.name == 'firstDeath' && dad.animation.curAnim.curFrame == 12))
		{
			FlxG.camera.follow(camFollow, LOCKON, 0.01);
		}

		if ((!PlayStateChangeables.opponentMode && bf.animation.curAnim.name == 'firstDeath' && bf.animation.curAnim.finished)
			|| (PlayStateChangeables.opponentMode && dad.animation.curAnim.name == 'firstDeath' && dad.animation.curAnim.finished))
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
			if (PlayStateChangeables.opponentMode)
			{
				dad.playAnim('deathLoop', dad.animForces.get(dad.animation.curAnim.name));
			}
			else
			{
				bf.playAnim('deathLoop', bf.animForces.get(bf.animation.curAnim.name));
			}
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			PlayState.startTime = 0;
			isEnding = true;
			if (PlayStateChangeables.opponentMode)
			{
				if (dad.animOffsets.exists('deathConfirm'))
					dad.playAnim('deathConfirm', true);
			}
			else
			{
				if (bf.animOffsets.exists('deathConfirm'))
					bf.playAnim('deathConfirm', true);
			}

			FlxG.sound.music.stop();

			FlxG.sound.play(Paths.music('gameOverEnd' + stageSuffix));
			new FlxTimer().start(0.7, function(tmr:FlxTimer)
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function()
				{
					LoadingState.loadAndSwitchState(new PlayState());
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
