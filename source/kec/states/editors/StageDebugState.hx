package kec.states.editors;

import flixel.group.FlxGroup;
import flixel.util.FlxCollision;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import kec.stages.Stage;
import kec.objects.Character;
/*
	>stage editor
	>uses stage object.
 */
import haxe.ui.dragdrop.DragManager;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.TextField;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.data.ArrayDataSource;

class StageDebugState extends MusicBeatState
{
	public var daStage:String;
	public var daBf:String;
	public var daGf:String;
	public var opponent:String;

	private var camEditor:FlxCamera;
	private var camHUD:FlxCamera;

	var _file:FileReference;

	var gf:Character;
	var boyfriend:Character;
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
	var ui:TabView;
	var box:ContinuousHBox;
	var box2:ContinuousHBox;
	var vbox1:VBox;
	var vbox3:VBox;
	var grid:Grid;

	var playerDrop:DropDown;
	var opponentDrop:DropDown;
	var stageDrop:DropDown;
	var gfDrop:DropDown;

	var hasGF:CheckBox;
	var staticCam:CheckBox;
	var resetCharPos:Button;

	var stageDirectory:TextField;

	var moveEditorToggle:CheckBox;
	var saveEditor:Button;
	var resetEditor:Button;

	var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)
	var forcedToIdle:Bool = false; // change if bf and dad are forced to idle to every (idleBeat) beats of the song

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
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.sound.music.stop();

		FlxG.sound.playMusic(Paths.inst(PlayState.SONG.audioFile));
		FlxG.sound.music.fadeIn(3, 0, 0.5);
		FlxG.mouse.visible = true;

		#if FEATURE_DISCORD
		kec.backend.Discord.changePresence("Stage Editor", null, null, true);
		#end

		stageList = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		charList = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		gfList = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));

		gf = new Character(400, 130, daGf);
		boyfriend = new Character(770, 450, daBf);
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

		FlxG.cameras.reset(camEditor);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.setDefaultDrawTarget(camEditor, true);

		FlxG.camera.follow(camFollow);

		ui = new TabView();
		ui.text = "huh";
		ui.draggable = FlxG.save.data.moveEditor;
		ui.width = 250;
		ui.height = 200;
		ui.x = 1030;
		ui.y = 490;
		ui.cameras = [camHUD];

		addTabs();
		addAssetUI();
		addPropertyUI();

		add(ui);

		// var opt_tabs = [{name: "test", label: 'test'}];
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

		Conductor.changeBPM(PlayState.SONG.bpm);
	}

	inline function addTabs()
	{
		box = new ContinuousHBox();
		box.padding = 5;
		box.width = 300;
		box.text = "Assets";

		box2 = new ContinuousHBox();
		box2.width = 300;
		box2.padding = 5;
		box2.text = "Properties";

		ui.addComponent(box);
		ui.addComponent(box2);
	}

	inline function addAssetUI()
	{
		var vbox1:VBox = new VBox();
		var vbox2:VBox = new VBox();
		var grid = new Grid();

		var playerLabel = new Label();
		playerLabel.text = "Player";

		var opLabel = new Label();
		opLabel.text = "Opponent";

		var gfLabel = new Label();
		gfLabel.text = "GF";

		playerDrop = new DropDown();
		playerDrop.width = 100;
		playerDrop.text = daBf;

		opponentDrop = new DropDown();
		opponentDrop.width = 100;
		opponentDrop.text = opponent;

		gfDrop = new DropDown();
		gfDrop.width = 100;
		gfDrop.text = daGf;

		var ds = new ArrayDataSource<Dynamic>();
		for (c in 0...charList.length)
		{
			ds.add(charList[c]);
		}
		playerDrop.dataSource = ds;
		playerDrop.selectItemBy(item -> item == daBf, true);
		playerDrop.onChange = function(e)
		{
			daBf = charList[playerDrop.selectedIndex];
		}

		opponentDrop.dataSource = ds;
		opponentDrop.selectItemBy(item -> item == opponent, true);
		opponentDrop.onChange = function(e)
		{
			opponent = charList[opponentDrop.selectedIndex];
		}

		var gfs = new ArrayDataSource<Dynamic>();
		for (g in 0...gfList.length)
		{
			gfs.add(gfList[g]);
		}

		gfDrop.dataSource = gfs;
		gfDrop.selectItemBy(item -> item == daGf, true);
		gfDrop.onChange = function(e)
		{
			daGf = gfList[gfDrop.selectedIndex];
		}

		vbox1.addComponent(playerLabel);
		vbox1.addComponent(playerDrop);
		vbox2.addComponent(opLabel);
		vbox2.addComponent(opponentDrop);
		vbox1.addComponent(gfLabel);
		vbox1.addComponent(gfDrop);

		grid.addComponent(vbox1);
		grid.addComponent(vbox2);

		box.addComponent(grid);
	}

	inline function addPropertyUI()
	{
		var grid = new Grid();
		var vbox1:VBox = new VBox();
		var vbox2:VBox = new VBox();

		stageDrop = new DropDown();
		stageDrop.text = daStage;
		stageDrop.width = 100;

		stageDirectory = new TextField();
		stageDirectory.width = 100;
		stageDirectory.text = Stage.stageDir;

		var sdLabel = new Label();
		sdLabel.text = "Stage Directory";

		var stages = new ArrayDataSource<Dynamic>();
		for (stage in 0...stageList.length)
		{
			stages.add(stageList[stage]);
		}
		stageDrop.dataSource = stages;
		stageDrop.selectItemBy(item -> item == daStage, true);
		stageDrop.onChange = function(e)
		{
			newStage = stageList[stageDrop.selectedIndex];
			Debug.logTrace(newStage);
		}

		hasGF = new CheckBox();
		hasGF.text = "Stage Has GF";
		hasGF.selected = Stage.hasGF;
		hasGF.onClick = function(e)
		{
			Stage.hasGF = hasGF.selected;
		}

		staticCam = new CheckBox();
		staticCam.text = "Static Camera";
		staticCam.selected = Stage.staticCam;
		staticCam.onClick = function(e)
		{
			Stage.staticCam = staticCam.selected;
		}

		resetCharPos = new Button();
		resetCharPos.text = "Reset Char Positions";
		resetCharPos.onClick = function(e)
		{
			resetPositions();
			Debug.logTrace('${ui.x} ${ui.y}');
		}

		moveEditorToggle = new CheckBox();
		moveEditorToggle.text = "Drag Editor?";
		moveEditorToggle.selected = FlxG.save.data.moveEditor;
		moveEditorToggle.onClick = function(e)
		{
			FlxG.save.data.moveEditor = !FlxG.save.data.moveEditor;
			ui.draggable = FlxG.save.data.moveEditor;
		}

		vbox1.addComponent(stageDrop);
		vbox2.addComponent(sdLabel);
		vbox2.addComponent(stageDirectory);
		vbox2.addComponent(hasGF);
		vbox2.addComponent(staticCam);
		vbox2.addComponent(resetCharPos);
		vbox2.addComponent(moveEditorToggle);

		grid.addComponent(vbox1);
		grid.addComponent(vbox2);

		box2.addComponent(grid);
	}

	function reloadStage(leStage:String)
	{
		Debug.logTrace('Reloading Stage...');
		curCharIndex = 0;
		curChars = [];
		for (i in Stage.toAdd)
		{
			remove(i, true);
		}

		for (i => array in Stage.layInFront)
		{
			for (bg in array)
				remove(bg, true);
		}

		Stage.destroy();

		remove(dad);
		remove(boyfriend);
		remove(gf);

		Paths.clearUnusedMemory();
		Paths.runGC();

		if (FlxG.save.data.gen)
			Debug.logTrace('Removing Characters...');

		dad = new Character(dad.x, dad.y, opponent, false);
		boyfriend = new Character(boyfriend.x, boyfriend.y, daBf);
		gf = new Character(gf.x, gf.y, daGf, false);

		Stage = new Stage(leStage);

		Stage.inEditor = true;

		Stage.loadStageData(leStage);

		Stage.initStageProperties();

		stageDirectory.text = Stage.stageDir;

		Stage.initCamPos();

		curChars = [dad, boyfriend, gf];
		if (dad.replacesGF)
		{
			gf.visible = false;
			dad.setPosition(gf.x, gf.y);
		}

		hasGF.selected = Stage.hasGF;

		if (!gf.visible || !Stage.hasGF) // for when gf is an opponent
			curChars.pop();
		curChar = curChars[curCharIndex];

		camFollow.setPosition(Stage.camPosition[0], Stage.camPosition[1]);

		if (charMode)
		{
			getNextChar();
		}
		else
		{
			getNextObject();
		}

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
					if (Stage.hasGF && hasGF.selected)
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
		Paths.runGC();

		Debug.logTrace('Stage Loaded.');

		// Idk why I felt like I had to add traces. Feels more cooler than it should be.
	}

	function loadStage(leStage:String)
	{
		Stage = new Stage(leStage);

		Stage.inEditor = true;

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

		if (charMode)
		{
			getNextChar();
		}
		else
		{
			getNextObject();
		}

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

		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 4), 0, 1);
		FlxG.camera.zoom = FlxMath.lerp(fakeZoom, FlxG.camera.zoom, lerpVal);

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
		@:privateAccess
		{
			if (FlxG.mouse.pressed && FlxG.mouse.overlaps(curChar) && !dragging && DragManager.instance._currentComponent == null)
			{
				dragging = true;
				updateMousePos();
			}

			if (dragging && FlxG.mouse.justMoved && DragManager.instance._currentComponent == null)
			{
				curChar.setPosition(-(oldMousePosX - FlxG.mouse.x) + curChar.x, -(oldMousePosY - FlxG.mouse.y) + curChar.y);
				updateMousePos();
			}
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
			Conductor.changeBPM(102);
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
		var json:kec.stages.StageData = {
			staticCam: staticCam.selected,
			camZoom: fakeZoom,
			hasGF: hasGF.selected,
			camPosition: [camFollow.x, camFollow.y],
			positions: [b => [boyfriend.x, boyfriend.y], g => [gf.x, gf.y], d => [dad.x, dad.y]],
			directory: stageDirectory.text
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

		if (curBeat % idleBeat == 0)
		{
			if (idleToBeat)
				dad.dance(forcedToIdle);
			if (idleToBeat)
				boyfriend.dance(forcedToIdle);
			if (gf != null && idleToBeat)
				gf.dance(forcedToIdle);
		}
		else if (curBeat % idleBeat != 0)
		{
			if (boyfriend.isDancing)
				boyfriend.dance(forcedToIdle);
			if (dad.isDancing)
				dad.dance(forcedToIdle);
			if (gf != null && gf.isDancing)
				gf.dance(forcedToIdle);
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
