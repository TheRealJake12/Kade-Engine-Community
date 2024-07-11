package kec.substates;

/// Code created by Rozebud for FPS Plus (thanks rozebud)
// modified by KadeDev for use in Kade Engine/Tricky
import flixel.util.FlxAxes;
import kec.backend.Options.Option;
import kec.backend.PlayerSettings;
import flixel.input.FlxInput;
import flixel.effects.FlxFlicker;
import flixel.input.FlxKeyManager;

using StringTools;

class KeyBindMenu extends FlxSubState
{
	var keyTextDisplay:FlxText;
	var keyWarning:FlxText;
	var warningTween:FlxTween;
	var keyText:Array<String> = [
		"LEFT", "DOWN", "UP", "RIGHT", "PAUSE", "RESET", "MUTE", "VOLUME UP", "VOLUME DOWN", "FULLSCREEN"
	];
	var defaultKeys:Array<String> = ["A", "S", "W", "D", "ENTER", "R", "NUMPADZERO", "NUMPADMINUS", "NUMPADPLUS", "F"];
	var curSelected:Int = 0;

	var keys:Array<String> = [
		FlxG.save.data.leftBind, FlxG.save.data.downBind, FlxG.save.data.upBind, FlxG.save.data.rightBind, FlxG.save.data.pauseBind, FlxG.save.data.resetBind,
		FlxG.save.data.muteBind, FlxG.save.data.volUpBind, FlxG.save.data.volDownBind, FlxG.save.data.fullscreenBind
	];

	var tempKey:String = "";
	var blacklist:Array<String> = ["ESCAPE", "BACKSPACE", "SPACE", "TAB"];

	var blackBox:FlxSprite;
	var infoText:FlxText;

	var state:String = "select";

	override function create()
	{
		for (i in 0...keys.length)
		{
			var k = keys[i];
			if (k == null)
				keys[i] = defaultKeys[i];
		}

		persistentUpdate = true;

		keyTextDisplay = new FlxText(-10, 0, 1280, "", 72);
		keyTextDisplay.scrollFactor.set(0, 0);
		keyTextDisplay.setFormat("VCR OSD Mono", 42, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		keyTextDisplay.borderSize = 3;
		keyTextDisplay.borderQuality = 1;

		blackBox = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackBox);
		add(keyTextDisplay);

		blackBox.alpha = 0;
		keyTextDisplay.alpha = 0;

		FlxTween.tween(keyTextDisplay, {alpha: 1}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(infoText, {alpha: 1}, 1.4, {ease: FlxEase.expoInOut});
		FlxTween.tween(blackBox, {alpha: 0.7}, 1, {ease: FlxEase.expoInOut});

		textUpdate();

		super.create();
	}

	var frames = 0;

	override function update(elapsed:Float)
	{
		if (frames <= 10)
			frames++;

		switch (state)
		{
			case "select":
				if (FlxG.keys.justPressed.UP)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(-1);
				}

				if (FlxG.keys.justPressed.DOWN)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					changeItem(1);
				}

				if (FlxG.keys.justPressed.ENTER)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					state = "input";
				}
				else if (FlxG.keys.justPressed.ESCAPE)
				{
					quit();
				}
				else if (FlxG.keys.justPressed.BACKSPACE)
				{
					reset();
				}

			case "input":
				tempKey = keys[curSelected];
				keys[curSelected] = "?";
				textUpdate();
				state = "waiting";

			case "waiting":
				if (FlxG.keys.justPressed.ESCAPE)
				{
					keys[curSelected] = tempKey;
					state = "select";
					FlxG.sound.play(Paths.sound('confirmMenu'));
				}
				else if (FlxG.keys.justPressed.ENTER)
				{
					addKey(defaultKeys[curSelected]);
					save();
					state = "select";
				}
				else if (FlxG.keys.justPressed.ANY)
				{
					addKey(FlxG.keys.getIsDown()[0].ID.toString());
					save();
					state = "select";
				}

			case "exiting":

			default:
				state = "select";
		}

		if (FlxG.keys.justPressed.ANY)
			textUpdate();

		super.update(elapsed);
	}

	function textUpdate()
	{
		keyTextDisplay.text = "\n\n";

		for (i in 0...4)
		{
			var textStart = (i == curSelected) ? "> " : "  ";
			keyTextDisplay.text += textStart + keyText[i] + ": " + ((keys[i] != keyText[i]) ? (keys[i] + " / ") : "") + keyText[i] + " ARROW\n";
		}
		var textStartPause = (4 == curSelected) ? "> " : "  ";
		keyTextDisplay.text += textStartPause + keyText[4] + ": " + (keys[4]) + "\n";

		var textStartReset = (5 == curSelected) ? "> " : "  ";
		keyTextDisplay.text += textStartReset + keyText[5] + ": " + (keys[5]) + "\n";

		for (i in 6...9)
		{
			var textStart = (i == curSelected) ? "> " : "  ";
			keyTextDisplay.text += textStart + keyText[i] + ": " + keys[i] + "\n";
		}
		var textStartReset = (9 == curSelected) ? "> " : "  ";
		keyTextDisplay.text += textStartReset + keyText[9] + ": " + (keys[9]) + "\n";

		keyTextDisplay.screenCenter();
	}

	function save()
	{
		FlxG.save.data.upBind = keys[2];
		FlxG.save.data.downBind = keys[1];
		FlxG.save.data.leftBind = keys[0];
		FlxG.save.data.rightBind = keys[3];
		FlxG.save.data.pauseBind = keys[4];
		FlxG.save.data.resetBind = keys[5];

		FlxG.save.data.muteBind = keys[6];
		FlxG.save.data.volUpBind = keys[7];
		FlxG.save.data.volDownBind = keys[8];
		FlxG.save.data.fullscreenBind = keys[9];

		FlxG.sound.muteKeys = [FlxKey.fromString(keys[6])];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(keys[8])];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(keys[7])];

		FlxG.save.flush();

		PlayerSettings.player1.controls.loadKeyBinds();
	}

	function reset()
	{
		for (i in 0...5)
		{
			keys[i] = defaultKeys[i];
		}
		quit();
	}

	function quit()
	{
		state = "exiting";

		save();

		FlxTween.tween(keyTextDisplay, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(blackBox, {alpha: 0}, 1.1, {
			ease: FlxEase.expoInOut,
			onComplete: function(flx:FlxTween)
			{
				close();
			}
		});
		FlxTween.tween(infoText, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
	}

	public var lastKey:String = "";

	function addKey(r:String)
	{
		var shouldReturn:Bool = true;

		var notAllowed:Array<String> = [];
		var swapKey:Int = -1;

		for (x in blacklist)
		{
			notAllowed.push(x);
		}

		trace(notAllowed);

		for (x in 0...keys.length)
		{
			var oK = keys[x];
			if (oK == r)
			{
				swapKey = x;
				keys[x] = null;
			}
			if (notAllowed.contains(oK))
			{
				keys[x] = null;
				lastKey = oK;
				return;
			}
		}

		if (notAllowed.contains(r))
		{
			keys[curSelected] = tempKey;
			lastKey = r;
			return;
		}

		lastKey = "";

		if (shouldReturn)
		{
			// Swap keys instead of setting the other one as null
			if (swapKey != -1)
			{
				keys[swapKey] = tempKey;
			}
			keys[curSelected] = r;
			FlxG.sound.play(Paths.sound('scrollMenu'));
		}
		else
		{
			keys[curSelected] = tempKey;
			lastKey = r;
		}
	}

	function changeItem(_amount:Int = 0)
	{
		curSelected += _amount;

		if (curSelected > 9)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = 9;
	}
}
