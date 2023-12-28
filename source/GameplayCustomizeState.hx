import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.FlxCamera;
import flixel.math.FlxPoint;
import flixel.FlxObject;
#if FEATURE_DISCORD
import Discord;
#end
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.ui.Keyboard;
import flixel.FlxSprite;
import flixel.FlxG;
import stages.Stage;

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

	var sick:FlxSprite;

	var pixelShitPart1:String = '';
	var pixelShitPart2:String = '';
	var pixelShitPart3:String = 'shared';
	var pixelShitPart4:String = null;

	private var camHUD:SwagCamera;
	private var camGame:SwagCamera;
	private var camOverlay:FlxCamera;
	private var camFollow:FlxObject;
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public var dad:Character;
	public var gf:Character;
	public var boyfriend:Boyfriend;

	public static var Stage:Stage;
	public static var freeplayBf:String = 'bf';
	public static var freeplayDad:String = 'dad';
	public static var freeplayGf:String = 'gf';
	public static var freeplayNoteStyle:String = 'normal';
	public static var freeplayStage:String = 'stage';
	public static var freeplaySong:String = 'bopeebo';
	public static var freeplayWeek:Int = 1;

	public override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		Discord.changePresence("Customizing Gameplay Modules", null);
		#end

		instance = this;

		sick = new FlxSprite().loadGraphic(Paths.image('sick', 'shared'));
		sick.antialiasing = FlxG.save.data.antialiasing;
		sick.scrollFactor.set();
		sick.setGraphicSize(Std.int(sick.width * 0.7));

		// Conductor.changeBPM(102);
		persistentUpdate = true;

		var stageCheck:String = 'stage';

		super.create();

		camHUD = new SwagCamera();
		camHUD.bgColor.alpha = 0;

		camOverlay = new SwagCamera();
		camOverlay.bgColor.alpha = 0;

		// Game Camera (where stage and characters are)
		FlxG.cameras.reset(camGame);

		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOverlay, false);

		camHUD.zoom = FlxG.save.data.zoom;
		camOverlay.zoom = 1;

		var camFollow = new FlxObject(0, 0, 1, 1);

		FlxG.camera.follow(camFollow, LOCKON, 0.01);
		// FlxG.camera.setScrollBounds(0, FlxG.width, 0, FlxG.height);
		FlxG.camera.zoom = 0.9;
		FlxG.camera.focusOn(camFollow.getPosition());

		dad = new Character(100, 100, 'dad');

		if (dad.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load opponent: " + freeplayDad + ". Loading default opponent"]);
			#end
			dad = new Character(100, 100, 'dad');
		}

		boyfriend = new Boyfriend(770, 450, 'bf');

		if (boyfriend.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load boyfriend: " + freeplayBf + ". Loading default boyfriend"]);
			#end
			boyfriend = new Boyfriend(770, 450, 'bf');
		}

		var gfCheck:String = 'gf';

		gf = new Character(400, 130, 'gf');

		if (gf.frames == null)
		{
			#if debug
			FlxG.log.warn(["Couldn't load gf: " + freeplayGf + ". Loading default gf"]);
			#end
			gf = new Character(400, 130, 'gf');
		}

		Stage = new Stage(stageCheck);

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

		var camPos:FlxPoint = new FlxPoint(dad.getGraphicMidpoint().x + 400, dad.getGraphicMidpoint().y);

		camFollow.setPosition(camPos.x, camPos.y);

		add(gf);
		add(boyfriend);
		add(dad);

		add(sick);

		add(camFollow);

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

		FlxG.mouse.visible = true;
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);

		if (FlxG.save.data.zoom < 0.8)
			FlxG.save.data.zoom = 0.8;

		if (FlxG.save.data.zoom > 1.2)
			FlxG.save.data.zoom = 1.2;

		FlxG.camera.zoom = FlxMath.lerp(0.9, FlxG.camera.zoom, 0.95);
		camHUD.zoom = FlxMath.lerp(FlxG.save.data.zoom, camHUD.zoom, 0.95);

		if (FlxG.mouse.overlaps(sick) && FlxG.mouse.pressed)
		{
			sick.x = (FlxG.mouse.x - sick.width / 2) - 60;
			sick.y = (FlxG.mouse.y - sick.height) - 60;
		}

		if (FlxG.keys.justPressed.Q)
		{
			FlxG.save.data.zoom += 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
		}

		if (FlxG.keys.justPressed.E)
		{
			FlxG.save.data.zoom -= 0.02;
			camHUD.zoom = FlxG.save.data.zoom;
		}

		if (FlxG.mouse.overlaps(sick) && FlxG.mouse.justReleased)
		{
			FlxG.save.data.changedHitX = sick.x;
			FlxG.save.data.changedHitY = sick.y;
			FlxG.save.data.changedHit = true;
		}

		if (FlxG.keys.justPressed.R)
		{
			sick.x = defaultX;
			sick.y = defaultY;
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

			var noteTypeCheck:String = 'normal';
			babyArrow.downScroll = FlxG.save.data.downscroll;

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
