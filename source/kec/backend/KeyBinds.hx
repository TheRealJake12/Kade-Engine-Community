package kec.backend;

import flixel.input.FlxInput;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionInputDigital;
import flixel.input.actions.FlxActionManager;
import flixel.input.actions.FlxActionSet;
import flixel.input.keyboard.FlxKey;

class KeyBinds
{
	public static function resetBinds():Void
	{
		FlxG.save.data.upBind = "W";
		FlxG.save.data.downBind = "S";
		FlxG.save.data.leftBind = "A";
		FlxG.save.data.rightBind = "D";
		FlxG.save.data.muteBind = "NUMPADZERO";
		FlxG.save.data.volUpBind = "PLUS";
		FlxG.save.data.volDownBind = "MINUS";
		FlxG.save.data.fullscreenBind = "F4";
		FlxG.save.data.pauseBind = "ENTER";
		FlxG.save.data.resetBind = "R";
		FlxG.sound.muteKeys = ["ZERO", "NUMPADZERO"];
		FlxG.sound.volumeDownKeys = ["MINUS", "NUMPADMINUS"];
		FlxG.sound.volumeUpKeys = ["PLUS", "NUMPADPLUS"];
		PlayerSettings.player1.controls.loadKeyBinds();
	}

	public static function keyCheck():Void
	{
		if (FlxG.save.data.upBind == null)
			FlxG.save.data.upBind = "W";
		if (FlxG.save.data.downBind == null)
			FlxG.save.data.downBind = "S";
		if (FlxG.save.data.leftBind == null)
			FlxG.save.data.leftBind = "A";
		if (FlxG.save.data.rightBind == null)
			FlxG.save.data.rightBind = "D";
		if (FlxG.save.data.pauseBind == null)
			FlxG.save.data.pauseBind = "ENTER";
		if (FlxG.save.data.resetBind == null)
			FlxG.save.data.resetBind = "R";
		if (FlxG.save.data.muteBind == null)
			FlxG.save.data.muteBind = "NUMPADZERO";
		if (FlxG.save.data.volumeUpKeys == null)
			FlxG.save.data.volumeUpKeys = ["PLUS"];
		if (FlxG.save.data.fullscreenBind == null)
			FlxG.save.data.fullscreenBind = "F4";
		if (FlxG.save.data.volumeDownKeys == null)
			FlxG.save.data.volumeDownKeys = ["MINUS"];
	}
}
