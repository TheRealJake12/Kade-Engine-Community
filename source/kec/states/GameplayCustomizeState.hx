package kec.states;

import flixel.addons.display.FlxExtendedMouseSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import kec.stages.Stage;
import kec.backend.chart.Song.Style;
import kec.objects.game.note.StaticArrow;
import kec.objects.game.Character;
#if FEATURE_DISCORD
import kec.backend.Discord;
#end
import kec.backend.PlayStateChangeables;
import kec.objects.game.note.Note;
import kec.util.NoteStyleHelper;
import kec.backend.PlayerSettings;
import haxe.ui.backend.flixel.UIState;

@:build(haxe.ui.ComponentBuilder.build("assets/shared/data/editors/gameplay.xml"))
class GameplayCustomizeState extends UIState
{
	var defaultX:Float = FlxG.width * 0.55 - 135;
	var defaultY:Float = FlxG.height / 2 - 50;

	var text:FlxText;
	var blackBorder:FlxSprite;

	public static var instance:GameplayCustomizeState = null;

	var strumLine:FlxSprite;
	var strumLineNotes:FlxTypedGroup<StaticArrow>;

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

	var currentTimingShown:FlxText = new FlxText(0, 0, 0, "0ms");

	public override function create()
	{
		Paths.clearCache();
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		Discord.changePresence("Customizing Gameplay Modules", null);
		#end
		instance = this;

		if (PlayState.STYLE == null)
			PlayState.STYLE = Style.loadJSONFile('default');

		// Conductor.changeBPM(102);
		persistentUpdate = true;

		var stageCheck:String = 'stage';

		Stage = new Stage('stage');
		Stage.inEditor = true;
		Stage.loadStageData('stage');
		Stage.initStageProperties();

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
		FlxG.camera.zoom = Stage.camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		dad = new Character(100, 100, 'dad');
		boyfriend = new Character(770, 450, 'bf');
		gf = new Character(400, 130, 'gf');

		var positions = Stage.positions[Stage.curStage];
		if (positions != null)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person.data.char == char)
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

		sick = new FlxExtendedMouseSprite(0, 0);
		sick.frames = Paths.getSparrowAtlas('hud/default/default');
		sick.animation.addByPrefix('marv', 'marv', 1);
		sick.animation.play('marv');
		sick.scrollFactor.set();
		sick.setGraphicSize(Std.int(sick.frameWidth * 0.7));
		sick.updateHitbox();
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

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		generateStaticArrows();
		appearStaticArrows();

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
		strumLineNotes.cameras = [camHUD];

		text.scrollFactor.set();

		add(blackBorder);
		add(text);

		createTween(text, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});
		createTween(blackBorder, {y: FlxG.height - 18}, 2, {ease: FlxEase.elasticInOut});

		if (!FlxG.save.data.changedHit)
		{
			FlxG.save.data.changedHitX = defaultX;
			FlxG.save.data.changedHitY = defaultY;
		}

		sick.x = FlxG.save.data.changedHitX;
		sick.y = FlxG.save.data.changedHitY;

		currentTimingShown.x = sick.x + 100;
		currentTimingShown.y = sick.y + 100;

		FlxG.mouse.visible = true;
		super.create();
		initHUI();

		root.camera = camOverlay;
	}

	inline function initHUI():Void
	{
		rating.selected = FlxG.save.data.showRating;
		rating.onClick = function(e)
		{
			FlxG.save.data.showRating = !FlxG.save.data.showRating;
			sick.visible = FlxG.save.data.showRating;
		};

		combo.selected = FlxG.save.data.showNum;
		combo.onClick = function(e)
		{
			FlxG.save.data.showNum = !FlxG.save.data.showNum;
		};

		timing.selected = FlxG.save.data.showMs;
		timing.onClick = function(e)
		{
			FlxG.save.data.showMs = !FlxG.save.data.showMs;
			currentTimingShown.visible = FlxG.save.data.showMs;
		};
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		Stage.update(elapsed);

		final lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 12), 0, 1);
		FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, lerpVal);
		camHUD.zoom = FlxMath.lerp(FlxG.save.data.zoom, camHUD.zoom, lerpVal);

		if (FlxG.keys.justPressed.E)
		{
			FlxG.save.data.zoom += 0.02;
			if (FlxG.save.data.zoom > 1.2)
				FlxG.save.data.zoom = 1.2;
		}

		if (FlxG.keys.justPressed.Q)
		{
			FlxG.save.data.zoom -= 0.02;
			if (FlxG.save.data.zoom < 0.8)
				FlxG.save.data.zoom = 0.8;
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
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = false;
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			flixel.addons.transition.FlxTransitionableState.skipNextTransOut = true;
			MusicBeatState.switchState(new OptionsDirect());
		}
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);

		if (curBeat % 2 == 0)
		{
			boyfriend.dance();
			dad.dance();
		}
		gf.dance();
	}

	// ripped from play state cuz im lazy

	private function generateStaticArrows():Void
	{
		final seX:Float = (PlayStateChangeables.middleScroll ? -278 : 42);
		final seY:Float = strumLine.y;
		for (i in 0...8)
		{
			final isPlayer:Bool = i > 3;
			final id:Int = i % 4;
			var babyArrow:StaticArrow = new StaticArrow(seX, seY, id, isPlayer);
			babyArrow.downScroll = PlayStateChangeables.useDownscroll;
			babyArrow.alpha = 0;
			babyArrow.ID = i;

			if (!isPlayer)
			{
				if (PlayStateChangeables.middleScroll)
				{
					babyArrow.x += 310;
					if (i > 1)
					{ // Up and Right
						babyArrow.x += FlxG.width / 2 + 25;
					}
				}
			}

			babyArrow.x += Note.swagWidth * id;
			babyArrow.x += 50;
			babyArrow.x += ((FlxG.width / 2) * (isPlayer ? 1 : 0));

			strumLineNotes.add(babyArrow);
		}
	}

	private function appearStaticArrows(t:Bool = true):Void
	{
		var index:Int = 0;
		strumLineNotes.forEachAlive(function(n:StaticArrow)
		{
			var targetAlpha:Float = 1;
			if (index < 4)
			{
				if (PlayStateChangeables.middleScroll)
					targetAlpha = 0.35;
			}

			if (t)
			{
				n.y -= 10;
				n.modAlpha = 0;
				createTween(n, {y: n.y + 10, modAlpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * index % 4)});
			}
			else
			{
				n.modAlpha = targetAlpha;
			}

			index++;
		});
	}
}
