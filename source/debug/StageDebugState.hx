package debug;

import flixel.util.FlxColor;
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.util.FlxCollision;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import stages.Stage;
import flixel.tweens.FlxTween;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI9SliceSprite;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUIState;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUITooltip.FlxUITooltipStyle;
import flixel.addons.ui.FlxUIButton;

using StringTools;

class StageDebugState extends MusicBeatState
{
	public var daStage:String;
	public var daBf:String;
	public var daGf:String;
	public var opponent:String;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;
	private var camMenu:FlxCamera;

	var _file:FileReference;

	var gf:Character;
	var boyfriend:Boyfriend;
	var dad:Character;

	public static var Stage:Stage;

	public static var fromEditor = false;

	var fakeZoom = 1.0;

	var camFollow:FlxObject;
	var posText:FlxText;
	var helpBg:FlxSprite;
	var bgPos:FlxSprite;
	var curChar:FlxSprite;
	var curCharIndex:Int = 0;
	var curCharString:String;
	var curChars:Array<FlxSprite>;
	var dragging:Bool = false;
	var oldMousePosX:Int;
	var oldMousePosY:Int;
	var charMode:Bool = true;
	var usedObjects:Array<FlxSprite> = [];

	var UI_box:FlxUITabMenu;
	var UI_options:FlxUITabMenu;
	var stageDropDown:FlxUIDropDownMenu;
	var player1Drop:FlxUIDropDownMenu;
	var player2Drop:FlxUIDropDownMenu;
	var gfDrop:FlxUIDropDownMenu;
	var hasGF:FlxUICheckBox;
	var staticCam:FlxUICheckBox;
	var resetPos:FlxUIButton;

	var stageList:Array<String>;
	var charList:Array<String>;
	var gfList:Array<String>;
	var newStage:String = 'stage';

	public function new(daStage:String = 'stage', daGf:String = 'gf', daBf:String = 'bf', opponent:String = 'dad')
	{
		super();
		this.daStage = daStage;
		this.daGf = daGf;
		this.daBf = daBf;
		this.opponent = opponent;
		curCharString = opponent;
	}

	override function create()
	{
		Paths.clearUnusedMemory();
		FlxG.sound.music.stop();

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.audioFile));
		FlxG.sound.music.fadeIn(3, 0, 0.5);
		FlxG.mouse.visible = true;

		gf = new Character(400, 130, daGf);
		boyfriend = new Boyfriend(770, 450, daBf);
		dad = new Character(100, 100, opponent);

		dad.dance();
		boyfriend.dance();
		gf.dance();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		loadStage(daStage);

		curChar = curChars[curCharIndex];

		var positions = Stage.positions[daStage];
		if (positions != null)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person.curCharacter == char)
						person.setPosition(pos[0], pos[1]);
		}

		/*
			dad.moves = true;
			dad.active = true;
			boyfriend.active = true;
			boyfriend.moves = true;
			gf.active = true;
			gf.moves = true;
		 */

		PlayState.inDaPlay = false;

		camEditor = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camMenu = new FlxCamera();
		camMenu.bgColor.alpha = 0;

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camMenu, false);

		FlxG.cameras.setDefaultDrawTarget(camEditor, true);
		FlxG.camera.follow(camFollow);

		stageList = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		charList = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		gfList = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));

		var tabs = [
			{name: "Stage", label: 'Select Stage'},
			{name: "Characters", label: 'Select Characters'}
		];

		// var opt_tabs = [{name: "test", label: 'test'}];

		UI_options = new FlxUITabMenu(null, tabs, true);
		UI_options.camera = camMenu;

		UI_options.scrollFactor.set();
		UI_options.resize(300, 200);
		UI_options.x = FlxG.width - UI_options.width - 20;
		UI_options.y = FlxG.height - 300;
		add(UI_options);

		posText = new FlxText(0, 690);
		posText.setFormat(Paths.font('vcr.ttf'), 26, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		posText.scrollFactor.set();
		posText.cameras = [camHUD];

		bgPos = new FlxSprite(0, 900).makeGraphic(1280, 120, FlxColor.BLACK);
		bgPos.scrollFactor.set();
		bgPos.cameras = [camHUD];
		bgPos.alpha = 0;
		FlxTween.tween(bgPos, {alpha: 0.8, y: posText.y}, 1.2);
		add(bgPos);
		add(posText);

		addHelpText();
		addEditorUI();
		addCharacterUI();

		Conductor.changeBPM(PlayState.SONG.bpm);
	}

	function addEditorUI():Void
	{
		var tab_group = new FlxUI(null, UI_options);
		tab_group.name = "Stage";
		stageDropDown = new FlxUIDropDownMenu(10, 20, FlxUIDropDownMenu.makeStrIdLabelArray(stageList, true), function(stage:String)
		{
			newStage = stageList[Std.parseInt(stage)];
			Debug.logTrace('Selected Stage : ${newStage}');
		});
		stageDropDown.selectedLabel = newStage;

		hasGF = new FlxUICheckBox(150, 20, null, null, "Stage Has GF", 100);
		hasGF.checked = Stage.hasGF;
		hasGF.callback = function()
		{
			Stage.hasGF = !Stage.hasGF;
		};

		staticCam = new FlxUICheckBox(150, 40, null, null, "Static Camera", 100);
		staticCam.checked = Stage.staticCam;
		staticCam.callback = function()
		{
			Stage.staticCam = !Stage.staticCam;
		};

		resetPos = new FlxUIButton(150, 75, "Reset Character Positions", function()
		{
			resetPositions();
		});

		tab_group.add(stageDropDown);
		tab_group.add(hasGF);
		tab_group.add(staticCam);
		tab_group.add(resetPos);

		UI_options.addGroup(tab_group);
	}

	function addCharacterUI():Void
	{
		var char = new FlxUI(null, UI_options);
		char.name = "Characters";
		player1Drop = new FlxUIDropDownMenu(10, 10, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(char:String)
		{
			daBf = charList[Std.parseInt(char)];
			Debug.logTrace('Player 1 : ${daBf}');
		});
		player1Drop.selectedLabel = daBf;

		player2Drop = new FlxUIDropDownMenu(150, 10, FlxUIDropDownMenu.makeStrIdLabelArray(charList, true), function(char:String)
		{
			opponent = charList[Std.parseInt(char)];
			Debug.logTrace('Player 2 : ${opponent}');
		});
		player2Drop.selectedLabel = opponent;

		gfDrop = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(gfList, true), function(char:String)
		{
			daGf = gfList[Std.parseInt(char)];
			Debug.logTrace('GF : ${daGf}');
		});
		gfDrop.selectedLabel = daGf;

		char.add(gfDrop);
		char.add(player2Drop);
		char.add(player1Drop);

		UI_options.addGroup(char);
	}

	function reloadStage(leStage:String)
	{
		Debug.logTrace('Reloading Stage...');
		curCharIndex = 0;
		curChars = [];
		for (i in Stage.toAdd)
		{
			remove(i);
		}

		for (i => array in Stage.layInFront)
		{
			for (bg in array)
				remove(bg);
		}

		Stage.destroy();

		remove(dad);
		remove(boyfriend);
		remove(gf);

		Paths.runGC();
		Paths.clearUnusedMemory();

		if (FlxG.save.data.gen)
			Debug.logTrace('Removing Characters...');

		dad = new Character(dad.x, dad.y, opponent, false);
		boyfriend = new Boyfriend(boyfriend.x, boyfriend.y, daBf);
		gf = new Character(gf.x, gf.y, daGf, false);

		Stage = new Stage(leStage);

		Stage.loadStageData(leStage);

		Stage.initStageProperties();

		Stage.initCamPos();

		curChars = [dad, boyfriend, gf];
		if (dad.replacesGF)
		{
			gf.visible = false;
			dad.setPosition(gf.x, gf.y);
		}

		if (!gf.visible || !Stage.hasGF) // for when gf is an opponent
			curChars.pop();
		curChar = curChars[curCharIndex];

		camFollow.setPosition(Stage.camPosition[0], Stage.camPosition[1]);

		getNextObject();
		getNextChar();

		fakeZoom = Stage.camZoom;

		if (FlxG.save.data.gen)
			Debug.logTrace('Initalize New Stage Data...');

		for (i in Stage.toAdd)
		{
			add(i);
		}

		if (FlxG.save.data.gen)
			Debug.logTrace('Add Characters And Stage Sprites...');

		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					if (Stage.hasGF && hasGF.checked)
						add(gf);
					for (bg in array)
						add(bg);
				case 1:
					add(dad);
					for (bg in array)
						add(bg);
				case 2:
					add(boyfriend);
					for (bg in array)
						add(bg);
			}
		}

		Paths.clearUnusedMemory();

		Debug.logTrace('Stage Loaded.');

		// Idk why I felt like I had to add traces. Feels more cooler than it should be.
	}

	function loadStage(leStage:String)
	{
		Stage = new Stage(leStage);

		Stage.loadStageData(leStage);

		Stage.initStageProperties();

		Stage.initCamPos();

		newStage = leStage;

		curChars = [dad, boyfriend, gf];
		if (dad.replacesGF)
		{
			gf.visible = false;
			dad.setPosition(gf.x, gf.y);
		}

		if (!gf.visible || !Stage.hasGF) // for when gf is an opponent
			curChars.pop();
		curChar = curChars[curCharIndex];

		getNextObject();
		getNextChar();

		camFollow.setPosition(Stage.camPosition[0], Stage.camPosition[1]);

		fakeZoom = Stage.camZoom;

		for (i in Stage.toAdd)
		{
			add(i);
		}

		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					if (Stage.hasGF)
						add(gf);
					for (bg in array)
						add(bg);
				case 1:
					add(dad);
					for (bg in array)
						add(bg);
				case 2:
					add(boyfriend);
					for (bg in array)
						add(bg);
			}
		}
	}

	function resetPositions()
	{
		var positions = Stage.positions[newStage];
		if (positions != null)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person != null)
						if (person.curCharacter == char)
							person.setPosition(pos[0], pos[1]);
		}

		Debug.logTrace("Reset Character Positions.");
	}

	var helpText:FlxText;

	function addHelpText():Void
	{
		var helpTextValue = "Help:\nQ/E : Zoom in and out\nI-J-K-L : Pan Camera\nA-D : Change Object Alpha\nSpace : Cycle Object\nShift : Switch Mode (Char/Stage)\nClick and Drag : Move Active Object\nZ/X : Rotate Object\nR : Reset Rotation\nEnter : Reload Selected Stage\nF12: Save Stage Properties To File\nESC : Return To Game\nF4 : Hide/Unhide Editor UI \nPress F1 To Hide/Unhide Help Text\n";
		helpText = new FlxText(1200, 10, 0, helpTextValue, 18);
		helpText.setFormat(Paths.font('vcr.ttf'), 18, FlxColor.WHITE, FlxTextAlign.RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		helpText.scrollFactor.set();
		helpText.cameras = [camHUD];
		helpText.color = FlxColor.WHITE;
		helpText.alpha = 0;
		FlxTween.tween(helpText, {x: 885, alpha: 1}, 1.2);

		helpBg = new FlxSprite(2000, 0).makeGraphic(450, 250, FlxColor.BLACK);
		helpBg.scrollFactor.set();
		helpBg.cameras = [camHUD];
		helpBg.alpha = 0;
		FlxTween.tween(helpBg, {alpha: 0.65, x: 875}, 1.2);

		add(helpBg);
		add(helpText);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justReleased.ENTER)
			reloadStage(newStage);

		Stage.update(elapsed);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.justPressed.E)
			fakeZoom += 0.05;

		if (FlxG.keys.justPressed.Q)
		{
			if (fakeZoom > 0.15) // me when floating point error
				fakeZoom -= 0.05;
		}

		FlxG.watch.addQuick('Camera Zoom', FlxG.camera.zoom);

		FlxG.camera.zoom = FlxMath.lerp(fakeZoom, FlxG.camera.zoom, 0.95);

		if (FlxG.keys.justPressed.SHIFT)
		{
			charMode = !charMode;
			dragging = false;
			if (charMode)
				getNextChar();
			else
				getNextObject();
		}

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			var addToCam:Float = 500 * elapsed;
			if (FlxG.keys.pressed.CONTROL)
				addToCam *= 4;

			if (FlxG.keys.pressed.I)
				camFollow.y -= addToCam;
			else if (FlxG.keys.pressed.K)
				camFollow.y += addToCam;

			if (FlxG.keys.pressed.J)
				camFollow.x -= addToCam;
			else if (FlxG.keys.pressed.L)
				camFollow.x += addToCam;
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			if (charMode)
			{
				getNextChar();
			}
			else
			{
				getNextObject();
			}
		}

		if (FlxG.mouse.pressed && FlxG.mouse.overlaps(curChar) && !dragging)
		{
			dragging = true;
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justMoved)
		{
			curChar.setPosition(-(oldMousePosX - FlxG.mouse.x) + curChar.x, -(oldMousePosY - FlxG.mouse.y) + curChar.y);
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justReleased || FlxG.keys.justPressed.TAB)
			dragging = false;

		if (FlxG.keys.pressed.Z)
			curChar.angle -= 1 * Math.ceil(elapsed);
		if (FlxG.keys.pressed.X)
			curChar.angle += 1 * Math.ceil(elapsed);
		if (FlxG.keys.pressed.R)
			curChar.angle = 0;

		if (FlxG.keys.justPressed.UP)
			curChar.y -= 1;

		if (FlxG.keys.justPressed.DOWN)
			curChar.y += 1;

		if (FlxG.keys.justPressed.LEFT)
			curChar.x -= 1;

		if (FlxG.keys.justPressed.RIGHT)
			curChar.x += 1;

		if (FlxG.keys.justPressed.A)
		{
			curChar.alpha = FlxMath.roundDecimal(curChar.alpha - 0.05, 2);
		}
		if (FlxG.keys.justPressed.D)
		{
			curChar.alpha += 0.05;
		}

		if (FlxG.keys.justPressed.F4)
		{
			camHUD.visible = !camHUD.visible;
			camMenu.visible = !camMenu.visible;
		}

		if (FlxG.keys.justPressed.F11)
			saveBoyPos();
		if (FlxG.keys.justPressed.F12)
			saveProperties();

		posText.text = (curCharString.toUpperCase() + " X: " + curChar.x + " Y: " + curChar.y + " Alpha: " + curChar.alpha + " Rotation: " + curChar.angle
			+ " Camera Zoom " + fakeZoom);

		if (FlxG.keys.justPressed.ESCAPE)
		{
			FlxG.sound.music.stop();
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			MainMenuState.freakyPlaying = true;
			Conductor.changeBPM(102, false);
			if (!fromEditor)
				MusicBeatState.switchState(new FreeplayState());
			else
				MusicBeatState.switchState(new SelectEditorsState());
		}

		if (FlxG.keys.justPressed.F1)
			FlxG.save.data.showHelp = !FlxG.save.data.showHelp;

		helpText.visible = FlxG.save.data.showHelp;
		helpBg.visible = FlxG.save.data.showHelp;

		super.update(elapsed);
	}

	override function destroy()
	{
		super.destroy();
	}

	function updateMousePos()
	{
		oldMousePosX = FlxG.mouse.x;
		oldMousePosY = FlxG.mouse.y;
	}

	function getNextObject():Void
	{
		for (key => value in Stage.swagBacks)
		{
			if (!usedObjects.contains(value))
			{
				usedObjects.push(value);
				curCharString = key;
				curChar = value;
				return;
			}
		}
		usedObjects = [];
		getNextObject();
	}

	function getNextChar()
	{
		curCharIndex += 1;
		if (curCharIndex >= curChars.length)
		{
			curChar = curChars[0];
			curCharIndex = 0;
		}
		else
			curChar = curChars[curCharIndex];
		switch (curCharIndex)
		{
			case 0:
				curCharString = opponent;
			case 1:
				curCharString = daBf;
			case 2:
				curCharString = daGf;
		}
	}

	function saveProperties()
	{
		var b = boyfriend.curCharacter;
		var g = gf.curCharacter;
		var d = dad.curCharacter;
		var json:stages.StageData = {
			staticCam: staticCam.checked,
			camZoom: fakeZoom,
			hasGF: hasGF.checked,
			camPosition: [camFollow.x, camFollow.y],
			positions: [b => [boyfriend.x, boyfriend.y], g => [gf.x, gf.y], d => [dad.x, dad.y]]
		};

		// weirdest fuckin code for jsons ever
		var data:String = haxe.Json.stringify(json, null, " ");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), Stage.curStage + ".json");
		}
	}

	function saveBoyPos():Void
	{
		var result = "";

		for (spriteName => sprite in Stage.swagBacks)
		{
			var text = spriteName + " X: " + sprite.x + " Y: " + sprite.y + " Alpha: " + sprite.alpha + " Rotation: " + sprite.angle;
			result += text + "\n";
		}
		var curCharIndex:Int = 0;
		var char:String = '';

		for (sprite in curChars)
		{
			switch (curCharIndex)
			{
				case 0:
					char = opponent;
				case 1:
					char = daBf;
				case 2:
					char = daGf;
			}
			result += char
				+ ' X: '
				+ curChars[curCharIndex].x + " Y: " + curChars[curCharIndex].y + " Alpha: " + curChars[curCharIndex].alpha + " Rotation: " +
					curChars[curCharIndex].angle + "\n";
			++curCharIndex;
		}

		result += 'Camera Zoom: ' + fakeZoom;

		if ((result != null) && (result.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(result.trim(), daStage + "Positions.txt");
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			dad.dance(true);
			boyfriend.dance(true);
			if (Stage.hasGF)
				gf.dance(true);
		}
	}

	/**
	 * Called when the save file dialog is completed.
	 */
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved Positions DATA.");
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Positions data");
	}
}
