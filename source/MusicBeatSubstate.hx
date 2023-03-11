package;

import lime.app.Application;
import openfl.Lib;
import flixel.text.FlxText;
import flixel.FlxG;
import flixel.FlxSubState;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	override function destroy()
	{
		Application.current.window.onFocusIn.remove(onWindowFocusOut);
		Application.current.window.onFocusIn.remove(onWindowFocusIn);
		super.destroy();
	}

	override function create()
	{
		super.create();
	}

	private var lastBeat:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;

	var curDecimalBeat:Float = 0;

	var oldStep:Int = 0;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function update(elapsed:Float)
	{
		curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);
		curBeat = Math.floor(curDecimalBeat);
		curStep = Math.floor(curDecimalBeat * 4);

		if (oldStep != curStep)
		{
			stepHit();
			oldStep = curStep;
		}

		super.update(elapsed);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	function onWindowFocusOut():Void
	{
		if (PlayState.inDaPlay)
		{
			if (!PlayState.instance.paused && !PlayState.instance.endingSong && PlayState.instance.songStarted)
			{
				Debug.logTrace("Lost Focus");
				PlayState.instance.openSubState(new PauseSubState());
				PlayState.boyfriend.stunned = true;

				PlayState.instance.persistentUpdate = false;
				PlayState.instance.persistentDraw = true;
				PlayState.instance.paused = true;

				PlayState.instance.vocals.pause();
				FlxG.sound.music.pause();
			}
		}
	}

	function onWindowFocusIn():Void
	{
		if (PlayState.inDaPlay)
		{
			if (FlxG.save.data.gen)
				Debug.logTrace("Gained Focus");

			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);

			PlayState.instance.vocals.play();
			FlxG.sound.music.play();
		}
	}
}
