package;

import flixel.util.FlxTimer;
import CoolUtil.CoolText;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.Lib;
import PlayState;
import Options;
import Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.ui.FlxBar;

using StringTools;

class OptionCata extends FlxSprite
{
	public var title:String;

	public static var instance:OptionCata;

	public var options:Array<Option>;

	public var optionObjects:FlxTypedGroup<OptionText>;

	public var titleObject:FlxText;

	public var middle:Bool = false;

	public var text:OptionText;
	public var graphics:Array<FlxSprite> = [];

	public function new(x:Float, y:Float, _title:String, _options:Array<Option>, middleType:Bool = false)
	{
		super(x, y);
		title = _title;
		middle = middleType;
		graphics = [];

		var blackGraphic = new FlxSprite().makeGraphic(295, 64, FlxColor.BLACK);
		var cumGraphic = new FlxSprite().makeGraphic(295, 64, FlxColor.WHITE);

		graphics.push(blackGraphic);
		graphics.push(cumGraphic);

		if (!middleType)
			loadGraphic(graphics[0].graphic);
		alpha = 0.4;

		options = _options;

		optionObjects = new FlxTypedGroup();

		titleObject = new FlxText((middleType ? 1180 / 2 : x), y + (middleType ? 0 : 16), 0, title);
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.borderSize = 3;

		if (middleType)
		{
			titleObject.x = 50 + ((1180 / 2) - (titleObject.fieldWidth / 2));
		}
		else
			titleObject.x += (width / 2) - (titleObject.fieldWidth / 2);

		titleObject.scrollFactor.set();

		scrollFactor.set();

		for (i in 0...options.length)
		{
			var opt = options[i];
			text = new OptionText(middleType ? 0 : 75, (46 * i) + 175, 35, 35, Paths.bitmapFont('fonts/vcr'));
			text.autoSize = true;
			text.borderStyle = FlxTextBorderStyle.OUTLINE;
			text.borderSize = 2;
			text.antialiasing = FlxG.save.data.antialiasing;
			text.targetY = i;
			text.alpha = 0.4;
			text.ID = i;

			text.text = opt.getValue();
			text.updateHitbox();

			if (middleType)
				text.alignment = FlxTextAlign.RIGHT;

			text.scrollFactor.set();

			optionObjects.add(text);
		}
	}

	public function changeColor(color:FlxColor)
	{
		if (color == FlxColor.BLACK)
			loadGraphic(graphics[0].graphic);
		else if (color == FlxColor.WHITE)
			loadGraphic(graphics[1].graphic);
	}

	override function destroy()
	{
		for (graphic in graphics)
			graphic.destroy();
		graphics.resize(0);
		for (shit in optionObjects)
		{
			shit.destroy();
		}

		optionObjects.clear();

		options.resize(0);

		super.destroy();
	}
}

class OptionsMenu extends MusicBeatSubstate
{
	public static var instance:OptionsMenu;

	public var background:FlxSprite;

	public var selectedCat:OptionCata;

	public var selectedOption:Option;

	public var selectedCatIndex = 0;
	public var selectedOptionIndex = 0;

	public var isInCat:Bool = false;

	public var options:Array<OptionCata>;

	public static var isInPause = false;

	public var shownStuff:FlxTypedGroup<OptionText>;

	public static var visibleRange = [164, 640];

	var changedOption = false;

	public var menu:FlxTypedGroup<FlxSprite>;

	public var descText:CoolText;
	public var descBack:FlxSprite;

	var saveIndex:Int = 0;

	var saveOptIndex:Int = 0;

	public function new(pauseMenu:Bool = false)
	{
		super();

		isInPause = pauseMenu;

		options = [
			new OptionCata(50, 40, "Gameplay", [
				new DownscrollOption("Toggle making the notes scroll down rather than up."),
				new CamZoomOption("Toggle the camera zoom in-game."),
				new GhostTapOption("Toggle counting pressing a directional input when no arrow is there as a miss."),
				new AccuracyDOption("Change how accuracy is calculated. (Accurate = Simple, Complex = Milisecond Based)"),
				new ScrollSpeedOption("Change your scroll speed. (1 = Chart dependent)"),
				new OffsetThing("Change the note visual offset (how many milliseconds a note looks like it is offset in a chart)"),
				new HitSoundOption("Toogle hitsound every time you hit a Strum Note."),
				new HitSoundVolume("Set hitsound volume."),
				new HitSoundMode("Set at what condition you want the hitsound to play."),
				new BotPlay("A bot plays for you!"),
				new ResetButtonOption("Toggle pressing R to gameover."),
				new InstantRespawn("Toggle if you instantly respawn after dying."),
				new DFJKOption(),
				new Judgement("Create a custom judgement preset"),
				new CustomizeGameplay("Drag and drop gameplay modules to your prefered positions!")
			]),
			new OptionCata(345, 40, "Appearance", [
				new NoteskinOption("Change your Noteskin"),
				new CPUNoteskinOption("Change the CPU Noteskin"),
				#if desktop
				new NotesplashOption("Change your Notesplash"), new CPUNotesplashOption("Change the CPU Notesplash"),
				#end
				new CPUSplash("Allows The CPU To Do Notesplashes"),
				new NotesplashesOption("Uses Notesplashes (Only use it on Arrow skins or else theres gonna be some visual bugs(wrong offsets))."),
				new RotateSpritesOption("Should the game rotate the sprites to do color quantization (turn off for bar skins)"),
				new LowMotion("Makes The Icons Not Bump On The Healthbar."),
				#if desktop
				new BorderlessWindow("Turns Off The Window Border."),
				#end
				new ScrollAlpha("Changes the Transparancy of the Hold Notes."),
				new MiddleScrollOption("Put your lane in the center or on the right."),
				new HealthBarOption("Toggles health bar visibility"),
				new JudgementCounter("Show your judgements that you've gotten in the song"),
				new LaneUnderlayOption("How transparent your lane is, higher = more visible."),
				new StepManiaOption("Sets the colors of the arrows depending on quantization instead of direction."),
				new AccuracyOption("Display accuracy information on the info bar."),
				new RoundAccuracy("Round your accuracy to the nearest whole number for the score text (cosmetic only)."),
				new SongPositionOption("Show the song's current position as a scrolling bar."),
				new Colour("The Healthbar Color For Each Character."),
				new NPSDisplayOption("Shows your current Notes Per Second on the info bar."),
				new RatingPopup("Toggle Ratings (SICK!, MARV!) From Showing Up Ingame."),
				new RatingStack("Allows Ratings To Stack And Look Cooler But Is More Distracting."),
				new CpuStrums("Toggle the CPU's strumline lighting up when it hits a note."),
			]),
			new OptionCata(640, 40, "Misc", [
				new FlashingLightsOption("Toggle flashing lights that can cause epileptic seizures and strain."),
				new AutoPauseOption("Makes The Game Stop Updating/Running When Tabbed Out Of The Game."),
				new WatermarkOption("Enable and disable all watermarks from the engine."),
				new MissSoundsOption("Toggle miss sounds playing when you don't hit a note."),
				new ScoreScreen("Show the score screen after the end of a song"),
				new ShowInput("Display every single input on the score screen."),
				#if FEATURE_MODCORE
				new CanLoadMods("Allows Modcore To Detect Mods In The Mods Folder"),
				#end
			]),
			new OptionCata(935, 40, "Saves", [
				#if !web
				new ReplayOption("Watch Replays"), new SaveReplayOption("Allows Replays To Be Saved When A Song Ends."),
				#end
				new ResetScoreOption("Reset your score on all songs and weeks. This is irreversible!"),
				new LockWeeksOption("Reset your story mode progress. This is irreversible!"),
				new ResetSettings("Reset ALL your settings. This is irreversible!")
			]),
			new OptionCata(50, 104, "Perf", [
				new FPSOption("Toggle the FPS Counter"),
				#if desktop
				new FPSCapOption("Change your FPS Cap."), new Memory("Toggle the Memory Counter"),
				#end
				new ShowState("Shows The Current Game State. Makes Debugging Easier."),
				new GPURendering("Makes All Sprites Load Into VRAM, Reducing Normal RAM Usage. (Not Recommended For ~3GB VRAM)"), // Ill come back to this. I'm tired asf
				new BorderFps("Adds A Border To Make The FPS Display Easier To See. (Uses A Ton Of CPU And A Little GPU)"),
				new WaterMarkFPS("Shows What Version Of The Game You Are Running In The FPS Counter."),
				new RainbowFPSOption("Make the FPS Counter flicker through rainbow colors."),
				#if desktop
				new Resolution("Change The Resolution The Game Plays In. (Press Enter To Apply.)"),
				#end
				new BackgroundsOption("Toggles Backrounds From Being Visible. (Good Performance Booster.)"),
				new General("Traces things in the debug console or logs. Affects performance in debug builds."),
				new EditorRes("Not showing the editor grid will greatly increase editor performance"),
				new DistractionsAndEffectsOption("Turns On Extra Images That Reduce Your FPS Significantly(Week 5 and 7 esp)"),
				new Optimization("Nothing but Your Strumline is visible. Best Performance."),
				new AntialiasingOption("Toggle antialiasing, improving graphics quality at a slight performance penalty."),
				// new FXAAOption("Enable FXAA Antialiasing. (EXTREME PERFORMANCE IMPACT! ONLY ENABLE IF YOUR PC HAS LIKE AN RTX CARD!)"),
				#if desktop
				new UnloadSongs("Unload Songs And Characters"), new UnloadNow("Clears All Cache We Can Remove"),
				#end

			]),
			new OptionCata(345, 104, "Experimental", [
				new OldCharter("Uses Kade Engine 1.5.4 Chart System.(HIGH CHANCES OF CRASHING!)"),

			]),
			new OptionCata(-1, 155, "Editing Keybinds", [
				new LeftKeybind("The left note's keybind"),
				new DownKeybind("The down note's keybind"),
				new UpKeybind("The up note's keybind"),
				new RightKeybind("The right note's keybind"),
				new PauseKeybind("The keybind used to pause the game"),
				new ResetBind("The keybind used to die instantly"),
				new MuteBind("The keybind used to mute game audio"),
				new VolUpBind("The keybind used to turn the volume up"),
				new VolDownBind("The keybind used to turn the volume down"),
				new FullscreenBind("The keybind used to fullscreen the game")
			], true),
			new OptionCata(-1, 160, "Editing Judgements", [
				new MarvMSOption("How many milliseconds are in the MARV hit window"),
				new SickMSOption("How many milliseconds are in the SICK hit window"),
				new GoodMsOption("How many milliseconds are in the GOOD hit window"),
				new BadMsOption("How many milliseconds are in the BAD hit window"),
				new ShitMsOption("How many milliseconds are in the SHIT hit window")
			], true)
		];

		instance = this;

		menu = new FlxTypedGroup<FlxSprite>();

		shownStuff = new FlxTypedGroup<OptionText>();

		background = new FlxSprite(50, 40).makeGraphic(1180, 640, FlxColor.BLACK);
		background.alpha = 0.6;
		background.scrollFactor.set();

		descBack = new FlxSprite(50, 642).makeGraphic(1180, 38, FlxColor.BLACK);
		descBack.alpha = 0.4;
		descBack.scrollFactor.set();

		if (isInPause)
		{
			var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0;
			bg.scrollFactor.set();
			menu.add(bg);

			descBack.alpha = 0.4;
			background.alpha = 0.6;
			bg.alpha = 0.6;

			cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		}

		selectedCat = options[0];
		selectedOption = selectedCat.options[0];
		descText = new CoolText(65, 648, 20, 20, Paths.bitmapFont('fonts/vcr'));
		descText.autoSize = false;
		descText.fieldWidth = 1750;
		descText.antialiasing = FlxG.save.data.antialiasing;
		descText.borderStyle = FlxTextBorderStyle.OUTLINE;
		descText.borderSize = 2;

		isInCat = true;

		switchCat(selectedCat);

		selectedOption = selectedCat.options[0];

		super.create();
		openCallback = refresh;
	}

	override function create()
	{
		instance = this;

		menu.add(background);

		menu.add(descBack);

		selectedCat = options[0];

		add(menu);

		add(shownStuff);

		add(descBack);
		add(descText);

		isInCat = true;

		for (i in 0...options.length - 1)
		{
			if (i > 5) // impoirtant
				continue;
			var cat = options[i];
			add(cat);
			add(cat.titleObject);
		}

		switchCat(selectedCat);

		super.create();
	}

	function refresh()
	{
		switchCat(selectedCat);
	}

	public function switchCat(cat:OptionCata, toSubCat:Bool = false, fromSubCat:Bool = false)
	{
		if (toSubCat)
		{
			saveIndex = options.indexOf(selectedCat);
			saveOptIndex = selectedOptionIndex;
			isInCat = false;
		}
		else if (!fromSubCat)
		{
			saveIndex = 0;
			saveOptIndex = 0;
			selectedOptionIndex = 0;
		}

		visibleRange = [164, 640];
		/*if (cat.middle)
			visibleRange = [Std.int(cat.titleObject.y), 640]; */

		if (selectedCatIndex > options.length - 3 && !toSubCat)
			selectedCatIndex = 0;

		if (selectedCat.middle)
			remove(selectedCat.titleObject);

		selectedCat.changeColor(FlxColor.BLACK);
		selectedCat.alpha = 0.5;
		selectedCat = cat;
		selectedCat.alpha = 0.4;
		selectedCat.changeColor(FlxColor.WHITE);

		if (fromSubCat)
		{
			selectedOption = selectedCat.options[saveOptIndex];
			selectedOptionIndex = saveOptIndex;
			isInCat = false;
		}
		else
		{
			selectedOption = selectedCat.options[0];
			selectedOptionIndex = 0;
		}

		for (leStuff in shownStuff)
		{
			shownStuff.remove(leStuff, true);
		}

		shownStuff.members.resize(0);
		shownStuff.clear();

		if (selectedCat.middle)
			add(selectedCat.titleObject);

		if (!isInCat)
			selectOption(selectedOption);

		for (opt in selectedCat.optionObjects.members)
			opt.targetY = opt.ID - 5;

		for (i in selectedCat.optionObjects)
			shownStuff.add(i);

		updateOptColors();
	}

	public function selectOption(option:Option)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		selectedOption = option;

		if (!isInCat)
		{
			object.text = "> " + option.getValue();
			updateOptColors();

			descText.text = option.getDescription();
		}
	}

	var exiting:Bool = false;
	var holdTime:Float = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var accept = false;
		var right = false;
		var left = false;
		var up = false;
		var down = false;
		var any = false;
		var escape = false;
		var clickedCat = false;
		var rightHold = FlxG.keys.pressed.RIGHT || (gamepad != null ? gamepad.pressed.DPAD_RIGHT : false);

		var leftHold = FlxG.keys.pressed.LEFT || (gamepad != null ? gamepad.pressed.DPAD_LEFT : false);

		changedOption = false;

		accept = controls.ACCEPT || FlxG.keys.justPressed.ENTER || (gamepad != null ? gamepad.justPressed.A : false);
		right = controls.RIGHT_P || FlxG.keys.justPressed.RIGHT || (gamepad != null ? gamepad.justPressed.DPAD_RIGHT : false);
		left = controls.LEFT_P || FlxG.keys.justPressed.LEFT || (gamepad != null ? gamepad.justPressed.DPAD_LEFT : false);
		up = controls.UP_P || FlxG.keys.justPressed.UP || (gamepad != null ? gamepad.justPressed.DPAD_UP : false);
		down = controls.DOWN_P || FlxG.keys.justPressed.DOWN || (gamepad != null ? gamepad.justPressed.DPAD_DOWN : false);

		any = FlxG.keys.justPressed.ANY || (gamepad != null ? gamepad.justPressed.ANY : false);
		escape = FlxG.keys.justPressed.ESCAPE || (gamepad != null ? gamepad.justPressed.B : false);

		if (selectedCat != null && !exiting)
		{
			for (i in selectedCat.optionObjects.members)
			{
				if (selectedCat.middle)
				{
					i.screenCenter(X);
					i.updateHitbox();
				}

				// I wanna die!!!
				if (i.y < visibleRange[0] - 24 || i.y > visibleRange[1] - 24)
				{
					if (i.visible)
						i.visible = false;
				}
				else
				{
					if (!i.visible)
						i.visible = true;

					if (selectedCat.optionObjects.members[selectedOptionIndex].text != i.text || isInCat)
						i.alpha = 0.5;
					else
						i.alpha = 1;
				}
			}
		}

		if (isInCat)
		{
			descText.text = "Please select a category";

			descText.color = FlxColor.WHITE;
			descText.updateHitbox();

			if (selectedOption != null)
			{
				if (right)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedCatIndex++;

					FlxG.save.flush();

					if (selectedCatIndex > options.length - 3)
						selectedCatIndex = 0;
					if (selectedCatIndex < 0)
						selectedCatIndex = options.length - 3;

					switchCat(options[selectedCatIndex]);
				}
				else if (left)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedCatIndex--;

					FlxG.save.flush();

					if (selectedCatIndex > options.length - 3)
						selectedCatIndex = 0;
					if (selectedCatIndex < 0)
						selectedCatIndex = options.length - 3;

					switchCat(options[selectedCatIndex]);
				}
			}

			if (accept)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedOptionIndex = 0;
				isInCat = false;
				selectOption(selectedCat.options[0]);
			}

			if (escape)
			{
				if (!isInPause)
				{
					exiting = true;
					FlxTween.tween(background, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					for (i in 0...selectedCat.optionObjects.length)
					{
						FlxTween.tween(selectedCat.optionObjects.members[i], {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					}
					for (i in 0...options.length - 1)
					{
						FlxTween.tween(options[i].titleObject, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
						FlxTween.tween(options[i], {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					}
					FlxTween.tween(descText, {alpha: 0}, 0.5, {ease: FlxEase.smootherStepInOut});
					FlxTween.tween(descBack, {alpha: 0}, 0.5, {
						ease: FlxEase.smootherStepInOut,
						onComplete: function(twn:FlxTween)
						{
							close();

							MusicBeatState.switchState(new MainMenuState());
						}
					});
				}
				else
				{
					PauseSubState.goBack = true;
					PlayState.instance.updateSettings();
					close();
				}
			}
		}
		else
		{
			if (selectedOption != null)
				if (selectedOption.acceptType)
				{
					if (escape && selectedOption.waitingType)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						selectedOption.waitingType = false;
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
						return;
					}
					else if (any)
					{
						var object = selectedCat.optionObjects.members[selectedOptionIndex];
						selectedOption.onType(gamepad == null ? FlxG.keys.getIsDown()[0].ID.toString() : gamepad.firstJustPressedID());
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
					}
				}

			if (selectedOption.acceptType)
				if (accept)
				{
					var prev = selectedOptionIndex;
					var object = selectedCat.optionObjects.members[selectedOptionIndex];
					selectedOption.press();

					if (selectedOptionIndex == prev)
					{
						FlxG.save.flush();
						object.text = "> " + selectedOption.getValue();
						object.updateHitbox();
					}
				}

			#if !mobile
			if (FlxG.mouse.wheel != 0)
			{
				if (FlxG.mouse.wheel < 0)
					down = true;
				else if (FlxG.mouse.wheel > 0)
					up = true;
			}
			#end

			var bullShit:Int = 0;

			for (option in selectedCat.optionObjects.members)
			{
				if (selectedOptionIndex > 5)
				{
					option.targetY = bullShit - selectedOptionIndex;
					bullShit++;
				}
			}

			if (down)
			{
				if (selectedOption.acceptType)
					selectedOption.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
				selectedOptionIndex++;

				if (selectedOptionIndex < 0)
				{
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;
				}
				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
				{
					if (options[selectedCatIndex].options.length >= 6)
					{
						for (option in selectedCat.optionObjects.members)
						{
							var leY = option.targetY;
							option.targetY = leY + (selectedOptionIndex - 6);
						}
					}
					selectedOptionIndex = 0;
					Debug.logTrace('returning');
				}

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}
			else if (up)
			{
				if (selectedOption.acceptType)
					selectedOption.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				selectedCat.optionObjects.members[selectedOptionIndex].text = selectedOption.getValue();
				selectedOptionIndex--;

				if (selectedOptionIndex < 0)
				{
					selectedOptionIndex = options[selectedCatIndex].options.length - 1;
				}
				if (selectedOptionIndex > options[selectedCatIndex].options.length - 1)
				{
					selectedOptionIndex = 0;
				}

				selectOption(options[selectedCatIndex].options[selectedOptionIndex]);
			}
			if (!selectedOption.acceptType)
			{
				if (right)
					changeOptionValue(true);
				else if (left)
					changeOptionValue(false);

				if (selectedOption.getAccept())
				{
					if (rightHold || leftHold)
						holdTime += elapsed;
					else
						resetHoldTime();

					if (holdTime > 0.5)
					{
						if (Math.floor(elapsed) % 10 == 0)
						{
							if (rightHold)
								changeOptionValue(true);
							else if (leftHold)
								changeOptionValue(false);
						}
					}
				}
			}

			if (changedOption)
				updateOptColors();

			if (escape)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));

				PlayerSettings.player1.controls.loadKeyBinds();

				if (selectedCat.middle)
				{
					switchCat(options[saveIndex], false, true);
				}
				else
				{
					if (selectedCat.optionObjects != null)
						for (i in selectedCat.optionObjects.members)
						{
							if (i != null)
							{
								if (selectedOptionIndex > 5)
								{
									i.targetY += (selectedOptionIndex - 5);
									i.y = i.rawY;
								}
							}
						}

					for (object in selectedCat.optionObjects.members)
					{
						object.text = selectedCat.options[selectedCat.optionObjects.members.indexOf(object)].getValue();
						object.updateHitbox();
					}
					selectedOptionIndex = 0;

					isInCat = true;
				}
			}
		}

		#if !mobile
		if (!isInPause)
		{
			for (i in 0...options.length - 1)
			{
				if (i <= 5)
				{
					clickedCat = ((FlxG.mouse.overlaps(options[i].titleObject) || FlxG.mouse.overlaps(options[i]))
						&& FlxG.mouse.justPressed);
					if (clickedCat)
					{
						FlxG.sound.play(Paths.sound('scrollMenu'));
						selectedCatIndex = i;
						switchCat(options[i]);
						selectedOptionIndex = 0;
						isInCat = false;
						selectOption(selectedCat.options[0]);
					}
				}
			}
		}
		#end
	}

	override function destroy():Void
	{
		instance = null;
		for (cata in options)
			if (cata != null)
				cata.destroy();
		options.resize(0);

		super.destroy();
	}

	function resetHoldTime()
	{
		holdTime = 0;
	}

	function changeOptionValue(?right:Bool = false)
	{
		var object = selectedCat.optionObjects.members[selectedOptionIndex];

		if (right)
			selectedOption.right();
		else
			selectedOption.left();
		changedOption = true;

		object.text = "> " + selectedOption.getValue();
		object.updateHitbox();
	}

	function updateOptColors():Void
	{
		for (i in 0...selectedCat.options.length)
		{
			var opt = selectedCat.options[i];
			var optObject = selectedCat.optionObjects.members[i];
			opt.updateBlocks();

			if (opt.blocked)
				optObject.color = FlxColor.YELLOW;
			else
				optObject.color = FlxColor.WHITE;
		}
	}
}

class OptionText extends CoolText
{
	public var targetY:Float = 0;

	public var rawY:Float = 0;

	public var lerpFinished:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var optLerp = CoolUtil.boundTo(elapsed * 15, 0, 1);

		rawY = (targetY * 45.75) + 405;
		y = FlxMath.lerp(y, rawY, optLerp);

		lerpFinished = y == rawY;
	}
}
