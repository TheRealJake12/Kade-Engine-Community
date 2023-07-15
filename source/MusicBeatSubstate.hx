package;

import flixel.text.FlxText;
import flixel.input.gamepad.FlxGamepad;
import flixel.FlxG;
import flixel.FlxSubState;
import flixel.input.keyboard.FlxKey;

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
		curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);
		curBeat = Math.floor(curDecimalBeat);
		curStep = Math.floor(curDecimalBeat * 4);

		if (oldStep != curStep)
		{
			stepHit();
			oldStep = curStep;
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;
		if (gamepad != null)
			KeyBinds.gamepad = true;
		else
			KeyBinds.gamepad = false;

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
