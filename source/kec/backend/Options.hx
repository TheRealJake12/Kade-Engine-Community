package kec.backend;

import lime.app.Application;
import lime.system.DisplayMode;
import kec.backend.Controls.KeyboardScheme;
import openfl.display.FPS;
import openfl.Lib;
import kec.substates.OptionsMenu;
import kec.backend.util.HelperFunctions;
import kec.backend.util.NoteStyleHelper;
import kec.backend.util.Highscore;

class Option
{
	public function new()
	{
		display = updateDisplay();
	}

	private var description:String = "";

	public var pauseDesc:String = "This option cannot be toggled in the pause menu.";

	private var display:String;
	private var acceptValues:Bool = false;

	public var blocked:Bool = false;

	public var acceptType:Bool = false;

	public var waitingType:Bool = false;

	public final function getDisplay():String
	{
		return display;
	}

	public final function getAccept():Bool
	{
		return acceptValues;
	}

	public final function getDescription():String
	{
		return description;
	}

	public function getValue():String
	{
		return updateDisplay();
	};

	public function onType(text:String)
	{
	}

	public function updateBlocks()
	{
	}

	// Returns whether the label is to be updated.
	public function press():Bool
	{
		return true;
	}

	private function updateDisplay():String
	{
		return "";
	}

	public function left():Bool
	{
		return false;
	}

	public function right():Bool
	{
		return false;
	}
}

class DFJKOption extends Option
{
	public function new()
	{
		super();
		description = "Edit your keybindings";
		acceptType = true;
	}

	public override function press():Bool
	{
		OptionsMenu.instance.selectedCatIndex = 6;
		OptionsMenu.instance.switchCat(OptionsMenu.instance.options[6], true);
		return false;
	}

	private override function updateDisplay():String
	{
		return "Edit Keybindings";
	}
}

class UpKeybind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.upBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "UP: " + (waitingType ? "> " + FlxG.save.data.upBind + " <" : FlxG.save.data.upBind) + "";
	}
}

class DownKeybind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.downBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "DOWN: " + (waitingType ? "> " + FlxG.save.data.downBind + " <" : FlxG.save.data.downBind) + "";
	}
}

class RightKeybind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.rightBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "RIGHT: " + (waitingType ? "> " + FlxG.save.data.rightBind + " <" : FlxG.save.data.rightBind) + "";
	}
}

class LeftKeybind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.leftBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "LEFT: " + (waitingType ? "> " + FlxG.save.data.leftBind + " <" : FlxG.save.data.leftBind) + "";
	}
}

class PauseKeybind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.pauseBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "PAUSE: " + (waitingType ? "> " + FlxG.save.data.pauseBind + " <" : FlxG.save.data.pauseBind) + "";
	}
}

class ResetBind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.resetBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "RESET: " + (waitingType ? "> " + FlxG.save.data.resetBind + " <" : FlxG.save.data.resetBind) + "";
	}
}

class MuteBind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.muteBind = text;
			waitingType = false;
			FlxG.sound.muteKeys = [FlxKey.fromString(Std.string(FlxG.save.data.muteBind))];
		}
	}

	public override function press()
	{
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "VOLUME MUTE: " + (waitingType ? "> " + FlxG.save.data.muteBind + " <" : FlxG.save.data.muteBind) + "";
	}
}

class VolUpBind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.volUpBind = text;
			waitingType = false;
			FlxG.sound.volumeUpKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volUpBind))];
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "VOLUME UP: " + (waitingType ? "> " + FlxG.save.data.volUpBind + " <" : FlxG.save.data.volUpBind) + "";
	}
}

class VolDownBind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.volDownBind = text;
			waitingType = false;
			FlxG.sound.volumeDownKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volDownBind))];
		}
	}

	public override function press()
	{
		Debug.logTrace("keybind change");
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "VOLUME DOWN: " + (waitingType ? "> " + FlxG.save.data.volDownBind + " <" : FlxG.save.data.volDownBind) + "";
	}
}

class FullscreenBind extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptType = true;
	}

	public override function onType(text:String)
	{
		if (waitingType)
		{
			FlxG.save.data.fullscreenBind = text;
			waitingType = false;
		}
	}

	public override function press()
	{
		waitingType = !waitingType;

		return true;
	}

	private override function updateDisplay():String
	{
		return "FULLSCREEN:  " + (waitingType ? "> " + FlxG.save.data.fullscreenBind + " <" : FlxG.save.data.fullscreenBind) + "";
	}
}

class RoundAccuracy extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.roundAccuracy = !FlxG.save.data.roundAccuracy;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Round Accuracy: < " + (FlxG.save.data.roundAccuracy ? "Enabled" : "Disabled") + " >";
	}
}

class CpuStrums extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.cpuStrums = !FlxG.save.data.cpuStrums;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "CPU Strums: < " + (FlxG.save.data.cpuStrums ? "Light up" : "Stay static") + " >";
	}
}

class DownscrollOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Scroll: < " + (FlxG.save.data.downscroll ? "Downscroll" : "Upscroll") + " >";
	}
}

class GhostTapOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.ghost = !FlxG.save.data.ghost;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Ghost Tapping: < " + (FlxG.save.data.ghost ? "Enabled" : "Disabled") + " >";
	}
}

class AccuracyOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.accuracyDisplay = !FlxG.save.data.accuracyDisplay;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Accuracy Display < " + (!FlxG.save.data.accuracyDisplay ? "Disabled" : "Enabled") + " >";
	}
}

class SongPositionOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.songPosition = !FlxG.save.data.songPosition;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	public override function getValue():String
	{
		return "Song Position Bar: < " + (!FlxG.save.data.songPosition ? "Disabled" : "Enabled") + " >";
	}
}

class QualityOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.quality = !FlxG.save.data.quality;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Stage Quality: < " + (FlxG.save.data.quality ? "High" : "Low") + " >";
	}
}

class Colour extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		if (!FlxG.save.data.healthBar)
			return false;
		FlxG.save.data.colour = !FlxG.save.data.colour;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Colored HP Bars: < " + (FlxG.save.data.colour ? "Enabled" : "Disabled") + " >";
	}
}

class StepManiaOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.stepMania = !FlxG.save.data.stepMania;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Color Quantization: < " + (!FlxG.save.data.stepMania ? "Disabled" : "Enabled") + " >";
	}
}

class ResetButtonOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.resetButton = !FlxG.save.data.resetButton;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Reset Button: < " + (!FlxG.save.data.resetButton ? "Disabled" : "Enabled") + " >";
	}
}

class InstantRespawn extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.InstantRespawn = !FlxG.save.data.InstantRespawn;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Instant Respawn: < " + (!FlxG.save.data.InstantRespawn ? "Disabled" : "Enabled") + " >";
	}
}

class FlashingLightsOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.flashing = !FlxG.save.data.flashing;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Flashing Lights: < " + (!FlxG.save.data.flashing ? "Disabled" : "Enabled") + " >";
	}
}

class AntialiasingOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.antialiasing = !FlxG.save.data.antialiasing;
		display = updateDisplay();
		FlxSprite.defaultAntialiasing = FlxG.save.data.antialiasing;
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Antialiasing: < " + (!FlxG.save.data.antialiasing ? "Disabled" : "Enabled") + " >";
	}
}

class MissSoundsOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.missSounds = !FlxG.save.data.missSounds;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Miss Sounds: < " + (!FlxG.save.data.missSounds ? "Disabled" : "Enabled") + " >";
	}
}

class ShowInput extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.inputShow = !FlxG.save.data.inputShow;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Show Inputs On Score Screen: < " + (FlxG.save.data.inputShow ? "Enabled" : "Disabled") + " >";
	}
}

class Judgement extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
		acceptValues = true;
		acceptType = true;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		OptionsMenu.instance.selectedCatIndex = 7;
		OptionsMenu.instance.switchCat(OptionsMenu.instance.options[7], true);
		return true;
	}

	private override function updateDisplay():String
	{
		return "Edit Judgements";
	}
}

class MarvMSOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc + " (Press R to reset)";
		acceptValues = true;
	}

	public override function left():Bool
	{
		FlxG.save.data.marvMs -= 0.1;
		if (FlxG.save.data.marvMs < 0)
			FlxG.save.data.marvMs = 0;
		FlxG.save.data.marvMs = HelperFunctions.truncateFloat(FlxG.save.data.marvMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		FlxG.save.data.marvMs += 0.1;
		FlxG.save.data.marvMs = HelperFunctions.truncateFloat(FlxG.save.data.marvMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function onType(char:String)
	{
		if (char.toLowerCase() == "r")
			FlxG.save.data.marvMs = 25;
	}

	private override function updateDisplay():String
	{
		return "MARVELOUS: < " + FlxG.save.data.marvMs + " ms >";
	}
}

class SickMSOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc + " (Press R to reset)";
		acceptValues = true;
	}

	public override function left():Bool
	{
		FlxG.save.data.sickMs -= 0.1;
		if (FlxG.save.data.sickMs < 0)
			FlxG.save.data.sickMs = 0;
		FlxG.save.data.sickMs = HelperFunctions.truncateFloat(FlxG.save.data.sickMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		FlxG.save.data.sickMs += 0.1;
		FlxG.save.data.sickMs = HelperFunctions.truncateFloat(FlxG.save.data.sickMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function onType(char:String)
	{
		if (char.toLowerCase() == "r")
			FlxG.save.data.sickMs = 45;
	}

	private override function updateDisplay():String
	{
		return "SICK: < " + FlxG.save.data.sickMs + " ms >";
	}
}

class GoodMsOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc + " (Press R to reset)";
		acceptType = true;
		acceptValues = true;
	}

	public override function left():Bool
	{
		FlxG.save.data.goodMs--;
		if (FlxG.save.data.goodMs < 0)
			FlxG.save.data.goodMs = 0;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		FlxG.save.data.goodMs++;
		display = updateDisplay();
		return true;
	}

	public override function onType(char:String)
	{
		if (char.toLowerCase() == "r")
			FlxG.save.data.goodMs = 90;
	}

	private override function updateDisplay():String
	{
		return "GOOD: < " + FlxG.save.data.goodMs + " ms >";
	}
}

class BadMsOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc + " (Press R to reset)";
		acceptValues = true;
	}

	public override function left():Bool
	{
		FlxG.save.data.badMs -= 0.1;
		if (FlxG.save.data.badMs < 0)
			FlxG.save.data.badMs = 0;
		FlxG.save.data.badMs = HelperFunctions.truncateFloat(FlxG.save.data.badMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		FlxG.save.data.badMs += 0.1;
		FlxG.save.data.badMs = HelperFunctions.truncateFloat(FlxG.save.data.badMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function onType(char:String)
	{
		if (char.toLowerCase() == "r")
			FlxG.save.data.badMs = 135;
	}

	private override function updateDisplay():String
	{
		return "BAD: < " + FlxG.save.data.badMs + " ms >";
	}
}

class ShitMsOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc + " (Press R to reset)";
		acceptValues = true;
	}

	public override function left():Bool
	{
		FlxG.save.data.shitMs -= 0.1;
		if (FlxG.save.data.shitMs < 0)
			FlxG.save.data.shitMs = 0;
		FlxG.save.data.shitMs = HelperFunctions.truncateFloat(FlxG.save.data.shitMs, 1);
		display = updateDisplay();
		return true;
	}

	public override function onType(char:String)
	{
		if (char.toLowerCase() == "r")
			FlxG.save.data.shitMs = 180;
	}

	public override function right():Bool
	{
		FlxG.save.data.shitMs += 0.1;
		FlxG.save.data.shitMs = HelperFunctions.truncateFloat(FlxG.save.data.shitMs, 1);
		display = updateDisplay();
		return true;
	}

	private override function updateDisplay():String
	{
		return "SHIT: < " + FlxG.save.data.shitMs + " ms >";
	}
}

class FPSOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.fps = !FlxG.save.data.fps;
		Main.gameContainer.toggleFPS(FlxG.save.data.fps);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "FPS Counter: < " + (!FlxG.save.data.fps ? "Disabled" : "Enabled") + " >";
	}
}

class ScoreScreen extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.scoreScreen = !FlxG.save.data.scoreScreen;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Score Screen: < " + (FlxG.save.data.scoreScreen ? "Enabled" : "Disabled") + " >";
	}
}

class FPSCapOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
	}

	public override function press():Bool
	{
		return false;
	}

	private override function updateDisplay():String
	{
		return "FPS Cap: < " + FlxG.save.data.fpsCap + " >";
	}

	override function right():Bool
	{
		#if html5
		return false;
		#end
		if (FlxG.save.data.fpsCap >= 900)
		{
			FlxG.save.data.fpsCap = 900;
			Main.gameContainer.setFPSCap(900);
		}
		else
			FlxG.save.data.fpsCap++;
		Main.gameContainer.setFPSCap(FlxG.save.data.fpsCap);

		return true;
	}

	override function left():Bool
	{
		#if html5
		return false;
		#end
		if (FlxG.save.data.fpsCap > 900)
			FlxG.save.data.fpsCap = 900;
		else if (FlxG.save.data.fpsCap < 60)
			FlxG.save.data.fpsCap = 60;
		else
			FlxG.save.data.fpsCap--;
		Main.gameContainer.setFPSCap(FlxG.save.data.fpsCap);
		return true;
	}

	override function getValue():String
	{
		return updateDisplay();
	}
}

class ScrollSpeedOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
	}

	public override function press():Bool
	{
		return false;
	}

	private override function updateDisplay():String
	{
		return "Scroll Speed: < " + HelperFunctions.truncateFloat(FlxG.save.data.scrollSpeed, 1) + " >";
	}

	override function right():Bool
	{
		FlxG.save.data.scrollSpeed += 0.1;

		if (FlxG.save.data.scrollSpeed < 1)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.scrollSpeed > 4)
			FlxG.save.data.scrollSpeed = 4;
		return true;
	}

	override function getValue():String
	{
		return "Scroll Speed: < " + HelperFunctions.truncateFloat(FlxG.save.data.scrollSpeed, 1) + " >";
	}

	override function left():Bool
	{
		FlxG.save.data.scrollSpeed -= 0.1;

		if (FlxG.save.data.scrollSpeed < 1)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.scrollSpeed > 4)
			FlxG.save.data.scrollSpeed = 4;

		return true;
	}
}

class RainbowFPSOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.fpsRain = !FlxG.save.data.fpsRain;
		Main.gameContainer.changeFPSColor(FlxColor.WHITE);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "FPS Rainbow : <" + (!FlxG.save.data.fpsRain ? "Disabled" : "Enabled") + " >";
	}
}

class NPSDisplayOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.npsDisplay = !FlxG.save.data.npsDisplay;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "NPS Display: < " + (!FlxG.save.data.npsDisplay ? "Disabled" : "Enabled") + " >";
	}
}

class CacheNow extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
		acceptType = true;
	}

	public override function press():Bool
	{
		MusicBeatState.switchState(new Caching());
		return false;
	}

	private override function updateDisplay():String
	{
		return "Cache";
	}
}

class AccuracyDOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.accuracyMod = FlxG.save.data.accuracyMod == 1 ? 0 : 1;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Accuracy Mode: < " + (FlxG.save.data.accuracyMod == 0 ? "Accurate" : "Complex") + " >";
	}
}

class CustomizeGameplay extends Option
{
	public function new(desc:String)
	{
		super();
		acceptType = true;
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		trace("switch");
		LoadingState.loadAndSwitchState(new GameplayCustomizeState());
		return false;
	}

	private override function updateDisplay():String
	{
		return "Customize Gameplay";
	}
}

class WatermarkOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		Main.watermarks = !Main.watermarks;
		FlxG.save.data.watermark = Main.watermarks;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Watermarks: < " + (Main.watermarks ? "Enabled" : "Disabled") + " >";
	}
}

class OffsetThing extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.offset--;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.offset++;
		display = updateDisplay();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Visual offset: < " + HelperFunctions.truncateFloat(FlxG.save.data.offset, 0) + " >";
	}

	public override function getValue():String
	{
		return "Visual offset: < " + HelperFunctions.truncateFloat(FlxG.save.data.offset, 0) + " >";
	}
}

class BotPlay extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.botplay = !FlxG.save.data.botplay;
		trace('BotPlay : ' + FlxG.save.data.botplay);
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
		return "BotPlay: < " + (FlxG.save.data.botplay ? "Enabled" : "Disabled") + " >";
}

class CamZoomOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.camzoom = !FlxG.save.data.camzoom;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Camera Zoom On Beats: < " + (!FlxG.save.data.camzoom ? "Disabled" : "Enabled") + " >";
	}
}

class JudgementCounter extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.judgementCounter = !FlxG.save.data.judgementCounter;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Judgement Counter: < " + (FlxG.save.data.judgementCounter ? "Enabled" : "Disabled") + " >";
	}
}

class MiddleScrollOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.middleScroll = !FlxG.save.data.middleScroll;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Middle Scroll: < " + (FlxG.save.data.middleScroll ? "Enabled" : "Disabled") + " >";
	}
}

class RotateSpritesOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.rotateSprites = !FlxG.save.data.rotateSprites;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Rotate Notes: < " + (FlxG.save.data.rotateSprites ? "Enabled" : "Disabled") + " >";
	}
}

class NoteskinOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.noteskin--;
		if (FlxG.save.data.noteskin < 0)
			FlxG.save.data.noteskin = NoteStyleHelper.getNoteskins().length - 1;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.noteskin++;
		if (FlxG.save.data.noteskin > NoteStyleHelper.getNoteskins().length - 1)
			FlxG.save.data.noteskin = 0;
		display = updateDisplay();
		return true;
	}

	public override function getValue():String
	{
		return "Current Noteskin: < " + NoteStyleHelper.getNoteskinByID(FlxG.save.data.noteskin) + " >";
	}
}

class CPUNoteskinOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.cpuNoteskin--;
		if (FlxG.save.data.cpuNoteskin < 0)
			FlxG.save.data.cpuNoteskin = NoteStyleHelper.getNoteskins().length - 1;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.cpuNoteskin++;
		if (FlxG.save.data.cpuNoteskin > NoteStyleHelper.getNoteskins().length - 1)
			FlxG.save.data.cpuNoteskin = 0;
		display = updateDisplay();
		return true;
	}

	public override function getValue():String
	{
		return "Current CPU Noteskin: < " + NoteStyleHelper.getNoteskinByID(FlxG.save.data.cpuNoteskin) + " >";
	}
}

class HealthBarOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.healthBar = !FlxG.save.data.healthBar;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Health Bar: < " + (FlxG.save.data.healthBar ? "Enabled" : "Disabled") + " >";
	}
}

class LaneUnderlayOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
	}

	override function right():Bool
	{
		FlxG.save.data.laneTransparency += 0.1;

		if (FlxG.save.data.laneTransparency < 0)
			FlxG.save.data.laneTransparency = 0;

		if (FlxG.save.data.laneTransparency > 1)
			FlxG.save.data.laneTransparency = 1;
		return true;
	}

	override function getValue():String
	{
		return "Current Lane Underlay transparency: " + HelperFunctions.truncateFloat(FlxG.save.data.laneTransparency, 1);
	}

	override function left():Bool
	{
		FlxG.save.data.laneTransparency -= 0.1;

		if (FlxG.save.data.laneTransparency < 0)
			FlxG.save.data.laneTransparency = 0;

		if (FlxG.save.data.laneTransparency > 1)
			FlxG.save.data.laneTransparency = 1;

		return true;
	}
}

class LockWeeksOption extends Option
{
	var confirm:Bool = false;

	public function new(desc:String)
	{
		super();
		acceptType = true;
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		if (!confirm)
		{
			confirm = true;
			display = updateDisplay();
			return true;
		}
		FlxG.save.data.weekUnlocked = 1;
		StoryMenuState.weekUnlocked = [true, true];
		confirm = false;
		trace('Weeks Locked');
		display = updateDisplay();
		return true;
	}

	private override function updateDisplay():String
	{
		return confirm ? "Confirm Story Reset" : "Reset Story Progress";
	}
}

#if FEATURE_MODCORE
class CanLoadMods extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.loadMods = !FlxG.save.data.loadMods;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Mod Loading: < " + (!FlxG.save.data.loadMods ? "Disabled" : "Enabled") + " >";
	}
}
#end

class ResetScoreOption extends Option
{
	var confirm:Bool = false;

	public function new(desc:String)
	{
		super();
		acceptType = true;
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		if (!confirm)
		{
			confirm = true;
			display = updateDisplay();
			return true;
		}
		FlxG.save.data.songScores = null;
		for (key in Highscore.songScores.keys())
		{
			Highscore.songScores[key] = 0;
		}
		FlxG.save.data.songCombos = null;
		for (key in Highscore.songCombos.keys())
		{
			Highscore.songCombos[key] = '';
		}
		confirm = false;
		trace('Highscores Wiped');
		display = updateDisplay();
		return true;
	}

	private override function updateDisplay():String
	{
		return confirm ? "Confirm Score Reset" : "Reset Score";
	}
}

class Optimization extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.optimize = !FlxG.save.data.optimize;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Optimization < " + (FlxG.save.data.optimize ? "Enabled" : "Disabled") + " >";
	}
}

class NotesplashesOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.notesplashes = !FlxG.save.data.notesplashes;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Notesplashes < " + (FlxG.save.data.notesplashes ? "Enabled" : "Disabled") + " >";
	}
}

class CPUSplash extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.cpuSplash = !FlxG.save.data.cpuSplash;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "CPU Notesplashes < " + (FlxG.save.data.cpuSplash ? "Enabled" : "Disabled") + " >";
	}
}

class General extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.gen = !FlxG.save.data.gen;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "General Tracing < " + (FlxG.save.data.gen ? "Enabled" : "Disabled") + " >";
	}
}

class LowMotion extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.motion = !FlxG.save.data.motion;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Icon Bumping: < " + (!FlxG.save.data.motion ? "Enabled" : "Disabled") + " >";
	}
}

class ScrollAlpha extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
	}

	public override function press():Bool
	{
		return false;
	}

	private override function updateDisplay():String
	{
		return ("Hold Note Transparency");
	}

	override function right():Bool
	{
		FlxG.save.data.alpha += 0.1;

		if (FlxG.save.data.alpha < 0.1)
			FlxG.save.data.alpha = 0.1;

		if (FlxG.save.data.alpha > 1)
			FlxG.save.data.alpha = 1;
		return true;
	}

	override function getValue():String
	{
		return "Hold Note Transparency: " + HelperFunctions.truncateFloat(FlxG.save.data.alpha, 1);
	}

	override function left():Bool
	{
		FlxG.save.data.alpha -= 0.1;

		if (FlxG.save.data.alpha < 0.1)
			FlxG.save.data.alpha = 0.1;

		if (FlxG.save.data.alpha > 1)
			FlxG.save.data.alpha = 1;

		return true;
	}
}

class SplashAlpha extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
	}

	public override function press():Bool
	{
		return false;
	}

	private override function updateDisplay():String
	{
		return ("Notesplash Transparency");
	}

	override function right():Bool
	{
		FlxG.save.data.alphaSplash += 0.1;

		if (FlxG.save.data.alphaSplash < 0.1)
			FlxG.save.data.alphaSplash = 0.1;

		if (FlxG.save.data.alphaSplash > 1)
			FlxG.save.data.alphaSplash = 1;
		return true;
	}

	override function getValue():String
	{
		return "Notesplash Transparency: " + HelperFunctions.truncateFloat(FlxG.save.data.alphaSplash, 1);
	}

	override function left():Bool
	{
		FlxG.save.data.alphaSplash -= 0.1;

		if (FlxG.save.data.alphaSplash < 0.1)
			FlxG.save.data.alphaSplash = 0.1;

		if (FlxG.save.data.alphaSplash > 1)
			FlxG.save.data.alphaSplash = 1;

		return true;
	}
}

class FXAAOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.fxaa = !FlxG.save.data.fxaa;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "FXAA Antialiasing: < " + (!FlxG.save.data.fxaa ? "Disabled" : "Enabled") + " >";
	}
}

class WaterMarkFPS extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.fpsmark = !FlxG.save.data.fpsmark;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "FPS Watermark: < " + (FlxG.save.data.fpsmark ? "Enabled" : "Disabled") + " >";
	}
}

class UnloadSongs extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.unload = !FlxG.save.data.unload;
		kec.backend.util.BaseCache.loadedBefore = false;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Persistant Memory: < " + (FlxG.save.data.unload ? "Disabled" : "Enabled") + " >";
	}
}

class UnloadNow extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;

		Paths.clearUnusedMemory();
		return false;
	}

	private override function updateDisplay():String
	{
		return ('Clears All Cache We Can Remove.');
	}
}

class Memory extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.mem = !FlxG.save.data.mem;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Memory Counter: < " + (!FlxG.save.data.mem ? "Disabled" : "Enabled") + " >";
	}
}

class ShowState extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.showState = !FlxG.save.data.showState;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Show The Current Game State: < " + (!FlxG.save.data.showState ? "Disabled" : "Enabled") + " >";
	}
}

class NotesplashOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.notesplash--;
		if (FlxG.save.data.notesplash < 0)
			FlxG.save.data.notesplash = NoteStyleHelper.getNotesplash().length - 1;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.notesplash++;
		if (FlxG.save.data.notesplash > NoteStyleHelper.getNotesplash().length - 1)
			FlxG.save.data.notesplash = 0;
		display = updateDisplay();
		return true;
	}

	public override function getValue():String
	{
		return "Current Notesplash Skin: < " + NoteStyleHelper.getNotesplashByID(FlxG.save.data.notesplash) + " >";
	}
}

class CPUNotesplashOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.cpuNotesplash--;
		if (FlxG.save.data.cpuNotesplash < 0)
			FlxG.save.data.cpuNotesplash = NoteStyleHelper.getNotesplash().length - 1;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.cpuNotesplash++;
		if (FlxG.save.data.cpuNotesplash > NoteStyleHelper.getNotesplash().length - 1)
			FlxG.save.data.cpuNotesplash = 0;
		display = updateDisplay();
		return true;
	}

	public override function getValue():String
	{
		return "Current CPU Notesplashes: < " + NoteStyleHelper.getNotesplashByID(FlxG.save.data.cpuNotesplash) + " >";
	}
}

class BorderlessWindow extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.borderless = !FlxG.save.data.borderless;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Borderless Window : < " + (!FlxG.save.data.borderless ? "Disabled" : "Enabled") + " >";
	}
}

class OpenGLStatsOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.glDebug = !FlxG.save.data.glDebug;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "OpenGL Debug Information : < " + (!FlxG.save.data.glDebug ? "Disabled" : "Enabled") + " >";
	}
}

class BackgroundsOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.background = !FlxG.save.data.background;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Backgrounds: < " + (!FlxG.save.data.background ? "Disabled" : "Enabled") + " >";
	}
}

class HitSoundOption extends Option
{
	var daHitSound:FlxSound = new FlxSound();

	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.hitSound--;
		if (FlxG.save.data.hitSound < 0)
			FlxG.save.data.hitSound = HitSounds.getSound().length - 1;
		display = updateDisplay();
		if (FlxG.save.data.hitSound != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
			daHitSound.volume = FlxG.save.data.hitVolume;
			daHitSound.play();
		}
		return true;
	}

	public override function right():Bool
	{
		FlxG.save.data.hitSound++;
		if (FlxG.save.data.hitSound > HitSounds.getSound().length - 1)
			FlxG.save.data.hitSound = 0;
		display = updateDisplay();
		if (FlxG.save.data.hitSound != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
			daHitSound.volume = FlxG.save.data.hitVolume;
			daHitSound.play();
		}
		return true;
	}

	public override function getValue():String
	{
		return "Hitsound Style: < " + HitSounds.getSoundByID(FlxG.save.data.hitSound) + " >";
	}
}

class HitSoundVolume extends Option
{
	var daHitSound:FlxSound = new FlxSound();

	public function new(desc:String)
	{
		super();
		description = desc;

		acceptValues = true;
	}

	public override function press():Bool
	{
		return false;
	}

	private override function updateDisplay():String
	{
		return "Hitsound Volume: < " + HelperFunctions.truncateFloat(FlxG.save.data.hitVolume, 1) + " >";
	}

	override function right():Bool
	{
		FlxG.save.data.hitVolume += 0.1;

		if (FlxG.save.data.hitVolume < 0)
			FlxG.save.data.hitVolume = 0;

		if (FlxG.save.data.hitVolume > 1)
			FlxG.save.data.hitVolume = 1;

		if (FlxG.save.data.hitSound != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
			daHitSound.volume = FlxG.save.data.hitVolume;
			daHitSound.play();
		}
		return true;
	}

	override function getValue():String
	{
		return "Hitsound Volume: < " + HelperFunctions.truncateFloat(FlxG.save.data.hitVolume, 1) + " >";
	}

	override function left():Bool
	{
		FlxG.save.data.hitVolume -= 0.1;

		if (FlxG.save.data.hitVolume < 0)
			FlxG.save.data.hitVolume = 0;

		if (FlxG.save.data.hitVolume > 1)
			FlxG.save.data.hitVolume = 1;

		if (FlxG.save.data.hitSound != 0)
		{
			daHitSound.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
			daHitSound.volume = FlxG.save.data.hitVolume;
			daHitSound.play();
		}

		return true;
	}
}

class HitSoundMode extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.strumHit = !FlxG.save.data.strumHit;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Hitsound Mode: < " + (FlxG.save.data.strumHit ? "On Key Hit" : "On Note Hit") + " >";
	}
}

class Resolution extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
		acceptValues = true;
		acceptType = true;
	}

	public override function press():Bool
	{
		FlxG.resizeWindow(intToMode(FlxG.save.data.resolution)[0], intToMode(FlxG.save.data.resolution)[1]);
		FlxG.resizeGame(intToMode(FlxG.save.data.resolution)[0], intToMode(FlxG.save.data.resolution)[1]);

		display = updateDisplay();
		return true;
	}

	override function left():Bool
	{
		if (FlxG.save.data.resolution == 0)
			return false;

		FlxG.save.data.resolution -= 1;
		return true;
	}

	override function getValue():String
	{
		return "Resolution <" + intToMode(FlxG.save.data.resolution)[0] + 'x' + intToMode(FlxG.save.data.resolution)[1] + " >";
	}

	private override function updateDisplay():String
	{
		return "Resolution < " + intToMode(FlxG.save.data.resolution)[0] + 'x' + intToMode(FlxG.save.data.resolution)[1] + " >";
	}

	function intToMode(i:Int):Array<Int>
	{
		var resolution:Array<Int> = [];
		switch (i)
		{
			case 0:
				resolution = [640, 360];
			case 1:
				resolution = [768, 432];
			case 2:
				resolution = [896, 504];
			case 3:
				resolution = [1024, 576];
			case 4:
				resolution = [1152, 648];
			case 5:
				resolution = [1280, 720];
			case 6:
				resolution = [1920, 1080];
		}
		return resolution;
	}

	override function right():Bool
	{
		if (FlxG.save.data.resolution == 6)
			return false;

		FlxG.save.data.resolution += 1;
		// Debug.logTrace("Current Resolution == " + FlxG.save.data.resolution);

		return true;
	}
}

class AutoPauseOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.autoPause = !FlxG.save.data.autoPause;
		FlxG.autoPause = FlxG.save.data.autoPause;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Auto Pause: < " + (!FlxG.save.data.autoPause ? "Disabled" : "Enabled") + " >";
	}
}

class Shaders extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		FlxG.save.data.shaders = !FlxG.save.data.shaders;
		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Shader Effects : < " + (!FlxG.save.data.shaders ? "off" : "on") + " >";
	}
}

class GPURendering extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;

		#if html5
		description = "This option is handled automaticly by browser.";
		#end
	}

	public override function left():Bool
	{
		#if !html5
		if (OptionsMenu.isInPause)
			return false;

		FlxG.save.data.gpuRender = !FlxG.save.data.gpuRender;
		display = updateDisplay();
		return true;
		#else
		return false;
		#end
	}

	public override function right():Bool
	{
		#if !html5
		if (OptionsMenu.isInPause)
			return false;
		left();
		return true;
		#else
		return false;
		#end
	}

	private override function updateDisplay():String
	{
		#if !html5
		return "GPU Rendering: < " + (!FlxG.save.data.gpuRender ? "Disabled" : "Enabled") + " >";
		#else
		return "GPU Rendering: < " + "Auto" + " >";
		#end
	}
}

class SmoothHealthOption extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.smoothHealthbar = !FlxG.save.data.smoothHealthbar;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Smooth Healthbar: < " + (FlxG.save.data.smoothHealthbar ? "Enabled" : "Disabled") + " >";
	}
}

class NoteCamMovement extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.noteCamera = !FlxG.save.data.noteCamera;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Note Camera Movement: < " + (FlxG.save.data.noteCamera ? "Enabled" : "Disabled") + " >";
	}
}

class DeveloperMode extends Option
{
	public function new(desc:String)
	{
		super();
		description = desc;
	}

	public override function left():Bool
	{
		FlxG.save.data.developer = !FlxG.save.data.developer;

		display = updateDisplay();
		return true;
	}

	public override function right():Bool
	{
		left();
		return true;
	}

	private override function updateDisplay():String
	{
		return "Developer Mode: < " + (FlxG.save.data.developer ? "Enabled" : "Disabled") + " >";
	}
}

class MaxRatingAmountOption extends Option
{
	public function new(desc:String)
	{
		super();
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function right():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		if (FlxG.save.data.maxRatings >= 30)
			FlxG.save.data.maxRatings = 30;
		else
			FlxG.save.data.maxRatings++;
		display = updateDisplay();
		return true;
	}

	public override function left():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		if (FlxG.save.data.maxRatings > 30)
			FlxG.save.data.maxRatings = 30;
		else if (FlxG.save.data.maxRatings < 2)
			FlxG.save.data.maxRatings = 1;
		else
			FlxG.save.data.maxRatings--;
		return true;
	}

	private override function updateDisplay():String
	{
		return "Rating Cap: < " + FlxG.save.data.maxRatings + " >";
	}
}

class ResetSettings extends Option
{
	var confirm:Bool = false;

	public function new(desc:String)
	{
		super();
		acceptType = true;
		if (OptionsMenu.isInPause)
		{
			blocked = true;
			description = pauseDesc;
		}
		else
			description = desc;
	}

	public override function press():Bool
	{
		if (OptionsMenu.isInPause)
			return false;
		if (!confirm)
		{
			confirm = true;
			display = updateDisplay();
			return true;
		}
		FlxG.save.data.weekUnlocked = null;
		FlxG.save.data.downscroll = null;
		FlxG.save.data.antialiasing = null;
		FlxG.save.data.missSounds = null;
		FlxG.save.data.accuracyDisplay = null;
		FlxG.save.data.offset = null;
		FlxG.save.data.songPosition = null;
		FlxG.save.data.fps = null;
		FlxG.save.data.changedHit = null;
		FlxG.save.data.fpsRain = null;
		FlxG.save.data.fpsCap = null;
		FlxG.save.data.scrollSpeed = null;
		FlxG.save.data.npsDisplay = null;
		FlxG.save.data.frames = null;
		FlxG.save.data.accuracyMod = null;
		FlxG.save.data.watermark = null;
		FlxG.save.data.ghost = null;
		FlxG.save.data.quality = null;
		FlxG.save.data.colour = null;
		FlxG.save.data.stepMania = null;
		FlxG.save.data.flashing = null;
		FlxG.save.data.resetButton = null;
		FlxG.save.data.botplay = null;
		FlxG.save.data.roundAccuracy = null;
		FlxG.save.data.cpuStrums = null;
		FlxG.save.data.smoothHealthbar = null;
		FlxG.save.data.camzoom = null;
		FlxG.save.data.scoreScreen = null;
		FlxG.save.data.inputShow = null;
		FlxG.save.data.optimize = null;
		FlxG.save.data.laneTransparency = 0;
		// custom shit
		FlxG.save.data.hitsound = null;
		FlxG.save.data.notesplashes = null;
		FlxG.save.data.mem = null;
		FlxG.save.data.unload = null;
		FlxG.save.data.gen = null;
		FlxG.save.data.oldcharter = null;
		FlxG.save.data.motion = null;
		FlxG.save.data.fpsMark = null;
		FlxG.save.data.borderless = null;
		FlxG.save.data.resolution = null;
		FlxG.save.data.autoPause = null;
		FlxG.save.data.background = null;
		FlxG.save.data.hitSound = null;
		FlxG.save.data.hitVolume = null;
		FlxG.save.data.strumHit = null;
		FlxG.save.data.cpuSplash = null;
		FlxG.save.data.showState = null;
		FlxG.save.data.loadMods = null;
		FlxG.save.data.glDebug = null;
		FlxG.save.data.shaders = null;
		FlxG.save.data.alphaSplash = null;
		FlxG.save.data.showRating = null;
		FlxG.save.data.showNum = null;
		FlxG.save.data.showMs = null;
		FlxG.save.data.noteCamera = null;
		FlxG.save.data.showHelp = null;
		FlxG.save.data.playHitsounds = null;
		FlxG.save.data.playHitsoundsE = null;
		FlxG.save.data.developer = null;
		FlxG.save.data.maxRatings = null;

		KadeEngineData.initSave();
		confirm = false;
		trace('All settings have been reset');
		display = updateDisplay();
		return true;
	}

	private override function updateDisplay():String
	{
		return confirm ? "Confirm Settings Reset" : "Reset Settings";
	}
}
