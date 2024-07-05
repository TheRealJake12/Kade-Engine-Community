package kec.substates;

import kec.backend.chart.Section.SwagSection;
import kec.backend.chart.Song.SongData;
import kec.backend.chart.TimingStruct;
import kec.backend.Controls;
import kec.backend.PlayerSettings;

class MusicBeatSubstate extends FlxSubState
{
	public function new()
	{
		super();
	}

	override function destroy()
	{
		#if desktop
		/*Application.current.window.onFocusIn.remove(onWindowFocusOut);
			Application.current.window.onFocusIn.remove(onWindowFocusIn); */
		#end
		super.destroy();
	}

	override function create()
	{
		FlxG.mouse.enabled = true;
		super.create();
		#if desktop
		/*Application.current.window.onFocusIn.add(onWindowFocusIn);
			Application.current.window.onFocusOut.add(onWindowFocusOut); */
		#end
	}

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	var oldStep:Int = 0;

	var curDecimalBeat:Float = 0;

	override function update(elapsed:Float)
	{
		curDecimalBeat = (((Conductor.songPosition * 0.001))) * (Conductor.bpm / 60);
		curBeat = Math.floor(curDecimalBeat);
		curStep = Math.floor(curDecimalBeat * 4);

		if (oldStep != curStep)
		{
			stepHit();
			oldStep = curStep;
		}

		super.update(elapsed);

		var fullscreenBind = FlxKey.fromString(FlxG.save.data.fullscreenBind);

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}
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
}
