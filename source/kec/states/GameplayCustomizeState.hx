package kec.states;

import haxe.ui.containers.VBox;
import flixel.addons.display.FlxExtendedMouseSprite;
import haxe.ui.components.CheckBox;
import haxe.ui.containers.Panel;
import haxe.ui.containers.Box;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import kec.stages.Stage;
import kec.backend.chart.Song.Style;
import kec.objects.StaticArrow;
import kec.objects.Character;
#if FEATURE_DISCORD
import kec.backend.Discord;
#end
import kec.backend.PlayStateChangeables;
import kec.objects.Note;
import kec.backend.util.NoteStyleHelper;
import kec.backend.PlayerSettings;

class GameplayCustomizeState extends MusicBeatState
{
	var defaultX:Float = FlxG.width * 0.55 - 135;
	var defaultY:Float = FlxG.height / 2 - 50;

	var text:FlxText;
	var blackBorder:FlxSprite;

	public static var instance:GameplayCustomizeState = null;

	var laneunderlay:FlxSprite;
	var laneunderlayOpponent:FlxSprite;

	var strumLine:FlxSprite;
	var strumLineNotes:FlxTypedGroup<FlxSprite>;
	var playerStrums:FlxTypedGroup<StaticArrow>;
	var cpuStrums:FlxTypedGroup<StaticArrow>;

	var camPos:FlxPoint;

	var background:FlxSprite;
	var curt:FlxSprite;
	var front:FlxSprite;

	var sick:FlxExtendedMouseSprite;

	var pixelShitPart1:String = '';
	var pixelShitPart2:String = '';
	var pixelShitPart3:String = 'shared';
	var pixelShitPart4:String = null;

	private var camHUD:FlxCamera;
	private var camGame:FlxCamera;
	private var camOverlay:FlxCamera;
	private var camFollow:FlxObject;
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Character;

	public static var Stage:Stage;
	public static var freeplayBf:String = 'bf';
	public static var freeplayDad:String = 'dad';
	public static var freeplayGf:String = 'gf';
	public static var freeplayNoteStyle:String = 'default';
	public static var freeplayStage:String = 'stage';
	public static var freeplaySong:String = 'bopeebo';
	public static var freeplayWeek:Int = 1;

	var ui:Panel;
	var box:VBox;
	var daRating:CheckBox;
	var daCombo:CheckBox;
	var daTiming:CheckBox;

	var currentTimingShown:FlxText = new FlxText(0, 0, 0, "0ms");

	public override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		Discord.changePresence("Customizing Gameplay Modules", null);
		#end
		instance = this;

		if (PlayState.STYLE == null)
			PlayState.STYLE = Style.loadJSONFile('default');

		var styleShit:String = (PlayState.STYLE.style == null ? 'default' : PlayState.STYLE.style).toLowerCase();

		if (styleShit == null)
			styleShit = 'default';

		// Conductor.changeBPM(102);
		persistentUpdate = true;

		var stageCheck:String = 'stage';

		super.create();

		switch (styleShit)
		{
			case 'pixel':
				PlayState.noteskinPixelSprite = NoteStyleHelper.generatePixelSprite(FlxG.save.data.noteskin);
				PlayState.noteskinPixelSpriteEnds = NoteStyleHelper.generatePixelSprite(FlxG.save.data.noteskin, true);
			case 'default':
				PlayState.noteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.noteskin);
				PlayState.cpuNoteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		}

		Stage = new Stage(freeplayStage);
		Stage.inEditor = true;
		Stage.loadStageData(freeplayStage);
		Stage.initStageProperties();

		var directory:String = 'shared';
		var otherDir:String = Stage.stageDir;

		if (otherDir != null)
			directory = otherDir;

		if (!Stage.doesExist)
		{
			Debug.logTrace('Stage Does Not Exist For ${Stage.curStage}. Loading Default Stage.');
			Stage.loadStageData('stage');
			Stage.initStageProperties();
		}

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;

		camOverlay = new FlxCamera();
		camOverlay.bgColor.alpha = 0;

		Stage.initCamPos();

		// Game Camera (where stage and characters are)
		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOverlay, false);
		FlxG.camera.zoom = Stage.camZoom;
		camHUD.zoom = FlxG.save.data.zoom;
		camOverlay.zoom = 1;

		var camFollow = new FlxObject(0, 0, 1, 1);
		var camPos:FlxPoint = new FlxPoint(0, 0);
		camPos.set(Stage.camPosition[0], Stage.camPosition[1]);
		camFollow.setPosition(camPos.x, camPos.y);
		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = Stage.camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		ui = new Panel();
		ui.padding = 5;
		ui.text = "Gameplay Modules";
		ui.width = 200;
		ui.height = 100;
		ui.draggable = true;
		ui.camera = camOverlay;

		dad = new Character(100, 100, freeplayDad);

		if (dad.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load opponent: " + freeplayDad + ". Loading default opponent"]);
			#end
			dad = new Character(100, 100, 'dad');
		}

		boyfriend = new Character(770, 450, freeplayBf);

		if (boyfriend.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load boyfriend: " + freeplayBf + ". Loading default boyfriend"]);
			#end
			boyfriend = new Character(770, 450, 'bf');
		}

		// defaults if no gf was found in chart
		var gfCheck:String = 'gf';

		if (freeplayGf == null)
		{
			switch (freeplayWeek)
			{
				case 4:
					gfCheck = 'gf-car';
				case 5:
					gfCheck = 'gf-christmas';
				case 6:
					gfCheck = 'gf-pixel';
				case 7:
					gfCheck = 'gfTank';
			}
		}
		else
			gfCheck = freeplayGf;

		gf = new Character(400, 130, freeplayGf);

		if (gf.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load gf: " + freeplayGf + ". Loading default gf"]);
			#end
			gf = new Character(400, 130, 'gf');
		}

		var positions = Stage.positions[Stage.curStage];
		if (positions != null)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person.curCharacter == char)
						person.setPosition(pos[0], pos[1]);
		}
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
					gf.scrollFactor.set(0.95, 0.95);
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

		sick = new FlxExtendedMouseSprite(0, 0, Paths.image('hud/$styleShit/sick'));
		sick.setGraphicSize(Std.int(sick.width * PlayState.STYLE.scale * 0.7));
		sick.updateHitbox();
		sick.scrollFactor.set();
		if (PlayState.STYLE.antialiasing == false)
			sick.antialiasing = false;
		sick.visible = FlxG.save.data.showRating;
		sick.enableMouseDrag();
		add(sick);

		currentTimingShown.color = FlxColor.CYAN;
		currentTimingShown.font = Paths.font('vcr.ttf');
		currentTimingShown.borderStyle = OUTLINE_FAST;
		currentTimingShown.borderSize = 1;
		currentTimingShown.borderColor = FlxColor.BLACK;
		currentTimingShown.text = "0ms";
		currentTimingShown.size = 20;

		currentTimingShown.alignment = FlxTextAlign.RIGHT;
		currentTimingShown.visible = FlxG.save.data.showMs;
		add(currentTimingShown);

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (FlxG.save.data.downscroll)
			strumLine.y = FlxG.height - 165;

		strumLineNotes = new FlxTypedGroup<FlxSprite>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();
		cpuStrums = new FlxTypedGroup<StaticArrow>();

		generateStaticArrows(0);
		generateStaticArrows(1);

		text = new FlxText(5, FlxG.height + 40, 0,
			"Click and drag around gameplay elements to customize their positions. Press R to reset. Q/E to change zoom. Press Escape to go back.", 12);
		text.scrollFactor.set();
		text.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		blackBorder = new FlxSprite(-30, FlxG.height + 40).makeGraphic(1, 1, FlxColor.BLACK);
		blackBorder.alpha = 0.6;
		blackBorder.setGraphicSize(Std.int(text.width + 900), Std.int(text.height + 600));
		blackBorder.updateHitbox();
		blackBorder.cameras = [camOverlay];
		text.cameras = [camOverlay];

		sick.cameras = [camHUD];
		currentTimingShown.cameras = [camHUD];
		strumLine.cameras = [camHUD];
		playerStrums.cameras = [camHUD];
		cpuStrums.cameras = [camHUD];
		strumLineNotes.cameras = [camHUD];

		text.scrollFactor.set();

		add(blackBorder);
		add(text);

		FlxTween.tween(text, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});
		FlxTween.tween(blackBorder, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});

		if (!FlxG.save.data.changedHit)
		{
			FlxG.save.data.changedHitX = defaultX;
			FlxG.save.data.changedHitY = defaultY;
		}

		sick.x = FlxG.save.data.changedHitX;
		sick.y = FlxG.save.data.changedHitY;

		currentTimingShown.x = sick.x + 100;
		currentTimingShown.y = sick.y + 100;

		addMenuUI();
		ui.x = 1080;
		ui.y = 600;

		add(ui);

		FlxG.mouse.visible = true;
		Paths.clearUnusedMemory();
	}

	inline function addMenuUI():Void
	{
		box = new VBox();
		daRating = new CheckBox();
		daRating.text = "Show Rating";
		daRating.selected = FlxG.save.data.showRating;
		daRating.onClick = function(e)
		{
			FlxG.save.data.showRating = !FlxG.save.data.showRating;
			sick.visible = FlxG.save.data.showRating;
		};

		daCombo = new CheckBox();
		daCombo.text = "Show Combo Number";
		daCombo.selected = FlxG.save.data.showNum;
		daCombo.onClick = function(e)
		{
			FlxG.save.data.showNum = !FlxG.save.data.showNum;
		};

		daTiming = new CheckBox();
		daTiming.text = "Show MS Timing";
		daTiming.selected = FlxG.save.data.showMs;
		daTiming.onClick = function(e)
		{
			FlxG.save.data.showMs = !FlxG.save.data.showMs;
			currentTimingShown.visible = FlxG.save.data.showMs;
		};

		box.addComponent(daRating);
		box.addComponent(daCombo);
		box.addComponent(daTiming);

		ui.addComponent(box);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		Stage.update(elapsed);

		if (FlxG.save.data.zoom < 0.8)
			FlxG.save.data.zoom = 0.8;

		if (FlxG.save.data.zoom > 1.2)
			FlxG.save.data.zoom = 1.2;

		FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(FlxG.save.data.zoom, camHUD.zoom, 0.95);

		if (FlxG.keys.justPressed.E)
		{
			FlxG.save.data.zoom += 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
		}

		if (FlxG.keys.justPressed.Q)
		{
			FlxG.save.data.zoom -= 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
		}

		if (sick.x != defaultX && sick.y != defaultY)
		{
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = true;

			currentTimingShown.x = sick.x + 100;
			currentTimingShown.y = sick.y + 100;
		}

		if (FlxG.keys.justPressed.R)
		{
			sick.x = defaultX;
			sick.y = defaultY;
			currentTimingShown.x = sick.x + 100;
			currentTimingShown.y = sick.y + 100;
			FlxG.save.data.zoom = 1;
			camHUD.zoom = FlxG.save.data.zoom;
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = false;
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new OptionsDirect());
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			dad.dance();
		}
		else if (dad.curCharacter == 'spooky' || dad.curCharacter == 'gf')
			dad.dance();

		gf.dance();

		trace('beat');
	}

	// ripped from play state cuz im lazy

	private function generateStaticArrows(player:Int, ?tween:Bool = true):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StaticArrow = new StaticArrow(-10, strumLine.y, player, i);
			babyArrow.downScroll = FlxG.save.data.downscroll;

			babyArrow.noteTypeCheck = freeplayNoteStyle;
			babyArrow.reloadNote();

			babyArrow.loadLane();

			babyArrow.x += Note.swagWidth * i;

			if (tween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = 1;

			babyArrow.ID = i;

			switch (player)
			{
				case 0:
					if (!PlayStateChangeables.opponentMode)
					{
						babyArrow.x += 20;
						cpuStrums.add(babyArrow);
					}
					else
					{
						babyArrow.x += 20;
						playerStrums.add(babyArrow);
					}
				case 1:
					if (!PlayStateChangeables.opponentMode)
					{
						playerStrums.add(babyArrow);
						babyArrow.x -= 5;
					}
					else
					{
						babyArrow.x -= 20;
						cpuStrums.add(babyArrow);
					}
			}

			babyArrow.playAnim('static');
			babyArrow.x += 98.5; // Tryna make it not offset because it was pissing me off + Psych Engine has it somewhat like this.
			babyArrow.x += ((FlxG.width / 2) * player);

			if (FlxG.save.data.middleScroll || FlxG.save.data.optimize)
			{
				if (!PlayStateChangeables.opponentMode)
				{
					babyArrow.x -= 303.5;
					if (player == 0)
						babyArrow.x -= 275 / Math.pow(PlayStateChangeables.zoom, 3);
				}
				else
				{
					babyArrow.x += 311.5;
					if (player == 1)
						babyArrow.x += 275 / Math.pow(PlayStateChangeables.zoom, 3);
				}
			}

			strumLineNotes.add(babyArrow);
		}
	}
}
