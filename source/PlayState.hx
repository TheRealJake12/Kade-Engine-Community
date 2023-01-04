package;

import flixel.group.FlxSpriteGroup;
import CustomFadeTransition;
import Shaders;
import flixel.util.FlxSpriteUtil;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_LUAMODCHART
import LuaClass.LuaCamera;
import LuaClass.LuaCharacter;
import LuaClass.LuaNote;
#end
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import lime.media.openal.AL;
import Song.Event;
import openfl.media.Sound;
#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.io.File;
import Sys;
import sys.FileSystem;
#end
import openfl.ui.KeyLocation;
import openfl.events.Event;
import haxe.EnumTools;
import openfl.ui.Keyboard;
import openfl.events.KeyboardEvent;
import Replay.Ana;
import Replay.Analysis;
import flixel.input.keyboard.FlxKey;
import haxe.Exception;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import openfl.utils.AssetType;
import lime.graphics.Image;
import flixel.graphics.FlxGraphic;
import openfl.utils.AssetManifest;
import openfl.utils.AssetLibrary;
import lime.app.Application;
import lime.media.AudioContext;
import lime.media.AudioManager;
import openfl.Lib;
import Section.SwagSection;
import Song.SongData;
import WiggleEffect.WiggleEffectType;
import flixel.FlxBasic;
import flixel.FlxCamera;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.effects.FlxTrail;
import flixel.addons.effects.FlxTrailArea;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.atlas.FlxAtlas;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.ui.FlxBar;
import flixel.util.FlxCollision;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import flixel.util.FlxStringUtil;
import flixel.util.FlxTimer;
import haxe.Json;
import openfl.display.BlendMode;
import openfl.display.StageQuality;
import openfl.filters.ShaderFilter;
import openfl.display.Shader;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
#if FEATURE_HSCRIPT
import script.Script;
import script.ScriptGroup;
import script.ScriptUtil;
#end
// Orginization Imports
import debug.StageDebugState;
import debug.AnimationDebug;
import debug.ChartingState;

import stages.Stage;
import stages.TankmenBG;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;

	public static var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	// SONG MULTIPLIER STUFF
	var speedChanged:Bool = false;

	public var previousRate:Float = songMultiplier;
	public static var songMultiplier:Float = 1.0;

	// Scroll Speed changes multiplier
	public var scrollMult:Float = 1.0;

	// SCROLL SPEED
	public var scrollSpeed(default, set):Float = 1.0;
	public var scrollTween:FlxTween;

	public static var SONG:SongData;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var storyDifficulty:Int = 1;
	public static var weekSong:Int = 0;
	public static var weekScore:Int = 0;
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;
	public static var marvs:Int = 0;

	public static var tweenManager:FlxTweenManager;
	public static var timerManager:FlxTimerManager;

	#if FEATURE_HSCRIPT
	// Hscript
	public var scripts:ScriptGroup;
	#end

	//Character Animation Related
	public var canPlayAnims:Bool = false; // if a note plays the sing animations
	public var canNoteSplash:Bool = true; // if a note can notesplash on Sick! and Marv!
	var currentFrames:Int = 0;
	var idleToBeat:Bool = true; // change if bf and dad would idle to the beat of the song
	var idleBeat:Int = 2; // how frequently bf and dad would play their idle animation(1 - every beat, 2 - every 2 beats and so on)
	var forcedToIdle:Bool = false; // change if bf and dad are forced to idle to every (idleBeat) beats of the song
	var allowedToHeadbang:Bool = true; // Will decide if gf is allowed to headbang depending on the song
	var allowedToCheer:Bool = false; // Will decide if gf is allowed to cheer depending on the song

	// Animation common suffixes
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static var lastRating:FlxSprite;
	public static var lastCombo:FlxSprite;
	public static var lastScore:Array<FlxSprite> = [];

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public var cameraSpeed:Float = 1;

	public static var songPosBG:FlxSprite;

	public var visibleCombos:Array<FlxSprite> = [];

	public var addedBotplay:Bool = false;

	public var visibleNotes:Array<Note> = [];

	public static var songPosBar:FlxBar;

	public static var noteskinSprite:FlxAtlasFrames;
	public static var cpuNoteskinSprite:FlxAtlasFrames;
	public static var notesplashSprite:FlxAtlasFrames;
	public static var cpuNotesplashSprite:FlxAtlasFrames;
	public static var noteskinPixelSprite:BitmapData;
	public static var noteskinPixelSpriteEnds:BitmapData;

	public static var rep:Replay;
	public static var loadRep:Bool = false;
	public static var inResults:Bool = false;

	public static var inDaPlay:Bool = false;

	public static var noteBools:Array<Bool> = [false, false, false, false];

	var songLength:Float = 0;
	var kadeEngineWatermark:FlxText;

	#if FEATURE_DISCORD
	var storyDifficultyText:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var vocals:FlxSound;
	public var inst:FlxSound;

	public static var isSM:Bool = false;
	#if FEATURE_STEPMANIA
	public static var sm:SMFile;
	public static var pathToSm:String;
	#end

	public static var dad:Character;
	public static var gf:Character;
	public static var boyfriend:Boyfriend;

	public var notes:FlxTypedGroup<Note>;

	public var unspawnNotes:Array<Note> = [];

	public var strumLine:FlxSprite;

	private var curSection:Int = 0;

	private var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	private var camFollow:FlxObject;

	private static var prevCamFollow:FlxObject;

	public var laneunderlay:FlxSprite;
	public var laneunderlayOpponent:FlxSprite;

	public static var strumLineNotes:FlxTypedGroup<StaticArrow> = null;
	public static var playerStrums:FlxTypedGroup<StaticArrow> = null;
	public static var cpuStrums:FlxTypedGroup<StaticArrow> = null;

	private var camZooming:Bool = false;
	private var theMotionThing:Bool = FlxG.save.data.motion;
	private var curSong:String = "";

	private var gfSpeed:Int = 1;

	public var health:Float = 1;

	private var combo:Int = 0;

	public static var misses:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignMarvs:Int = 0;
	public static var campaignSicks:Int = 0;
	public static var campaignGoods:Int = 0;
	public static var campaignBads:Int = 0;
	public static var campaignShits:Int = 0;

	public var accuracy:Float = 0.00;

	private var accuracyDefault:Float = 0.00;
	private var totalNotesHit:Float = 0;
	private var totalNotesHitDefault:Float = 0;
	private var totalPlayed:Int = 0;
	private var ss:Bool = false;

	private var healthBarBG:FlxSprite;
	private var healthBar:FlxBar;
	private var songPositionBar:Float = 0;

	private var generatedMusic:Bool = false;
	private var startingSong:Bool = false;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;
	public var camHUD:FlxCamera;
	public var camSustains:FlxCamera;
	public var camNotes:FlxCamera;

	private var camGame:FlxCamera;

	public var camOther:FlxCamera;

	public var camHUDShaders:Array<ShaderEffect> = [];
	public var camGameShaders:Array<ShaderEffect> = [];
	public var camNotesShaders:Array<ShaderEffect> = [];
	public var shaderUpdates:Array<Float->Void> = [];
	public var camStrumsShaders:Array<ShaderEffect> = [];
	public var overlayShaders:Array<ShaderEffect> = [];
	var tankmanRun:FlxTypedGroup<TankmenBG>;

	public var cannotDie = false;

	public static var offsetTesting:Bool = false;

	public var isSMFile:Bool = false;

	var notesHitArray:Array<Date> = [];

	public var dialogue:Array<String> = ['dad:blah blah blah', 'bf:coolswag'];

	var songName:FlxText;

	var altSuffix:String = "";

	public var currentSection:SwagSection;

	var fc:Bool = true;

	var wiggleShit:WiggleEffect = new WiggleEffect();

	var talking:Bool = true;

	var trackedAssets:Array<FlxBasic> = [];

	public static var currentSong = "noneYet";

	public var songScore:Int = 0;

	var songScoreDef:Int = 0;
	var scoreTxt:FlxText;
	var judgementCounter:FlxText;
	var replayTxt:FlxText;

	var needSkip:Bool = false;
	var skipActive:Bool = false;
	var skipText:FlxText;
	var skipTo:Float;

	public static var campaignScore:Int = 0;
	public var camStrums:FlxCamera;
	public var arrowsGenerated:Bool = false;

	public static var theFunne:Bool = true;

	var funneEffect:FlxSprite;
	var inCutscene:Bool = false;
	var usedTimeTravel:Bool = false;

	public static var stageTesting:Bool = false;

	var camPos:FlxPoint;

	public var randomVar = false;

	public static var Stage:Stage;

	public static var repPresses:Int = 0;
	public static var repReleases:Int = 0;

	public static var timeCurrently:Float = 0;
	public static var timeCurrentlyR:Float = 0;

	var noteShit:Note;

	// Will fire once to prevent debug spam messages and broken animations
	private var triggeredAlready:Bool = false;

	// Per song additive offset
	public static var songOffset:Float = 0;
	public var inCinematic:Bool = false;
	var newLerp:Float = 0;
	var camLerp = #if !html5 0.04 * (30 / (cast(Lib.current.getChildAt(0), Main))
		.getFPS()) * songMultiplier; #else 0.09 * (30 / (cast(Lib.current.getChildAt(0), Main)).getFPS()) * songMultiplier; #end

	// BotPlay text
	private var botPlayState:FlxText;
	// Replay shit
	private var saveNotes:Array<Dynamic> = [];
	private var saveJudge:Array<String> = [];
	private var replayAna:Analysis = new Analysis(); // replay analysis

	public static var highestCombo:Int = 0;

	public var executeModchart = false;
	public var executeHScript = false;
	public var runHscript = false;
	public var overlayCam:FlxCamera;

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	public static var startTime = 0.0;

	public function addObject(object:FlxBasic)
	{
		add(object);
	}

	public function removeObject(object:FlxBasic)
	{
		remove(object);
	}

	override public function create()
	{
		Paths.clearStoredMemory();
		#if FEATURE_HSCRIPT
		scripts = new ScriptGroup();
		scripts.onAddScript.push(onAddScript);
		#end

		FlxG.mouse.visible = false;
		instance = this;

		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();


		PlayerSettings.player1.controls.loadKeyBinds();

		Ratings.timingWindows = [
			FlxG.save.data.shitMs,
			FlxG.save.data.badMs,
			FlxG.save.data.goodMs,
			FlxG.save.data.sickMs,
			FlxG.save.data.marvMs
		];

		Application.current.window.title = '${MainMenuState.kecVer}: ' + SONG.song + ' ' + CoolUtil.difficultyArray[storyDifficulty];

		// grab variables here too or else its gonna break stuff later on
		GameplayCustomizeState.freeplayBf = SONG.player1;
		GameplayCustomizeState.freeplayDad = SONG.player2;
		GameplayCustomizeState.freeplayGf = SONG.gfVersion;
		GameplayCustomizeState.freeplayNoteStyle = SONG.noteStyle;
		GameplayCustomizeState.freeplayStage = SONG.stage;
		GameplayCustomizeState.freeplaySong = SONG.songId;
		GameplayCustomizeState.freeplayWeek = storyWeek;

		previousRate = songMultiplier - 0.05;

		if (previousRate < 1.00)
			previousRate = 1;

		if (FlxG.save.data.fpsCap > 420)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(420);

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		inDaPlay = true;
		if (currentSong != SONG.song)
		{
			currentSong = SONG.song;
			Paths.clearStoredMemory();
			if (!FlxG.save.data.gpuRender)
				Main.dumpCache();
		}
		marvs = 0;
		sicks = 0;
		bads = 0;
		shits = 0;
		goods = 0;

		misses = 0;

		highestCombo = 0;
		repPresses = 0;
		repReleases = 0;
		inResults = false;

		PlayStateChangeables.useDownscroll = FlxG.save.data.downscroll;
		PlayStateChangeables.safeFrames = FlxG.save.data.frames;
		PlayStateChangeables.scrollSpeed = FlxG.save.data.scrollSpeed * songMultiplier;
		PlayStateChangeables.Optimize = FlxG.save.data.optimize;

		if (!isStoryMode)
		{
			PlayStateChangeables.modchart = FlxG.save.data.modcharts;
			PlayStateChangeables.opponentMode = FlxG.save.data.opponent;
			PlayStateChangeables.mirrorMode = FlxG.save.data.mirror;
			PlayStateChangeables.holds = FlxG.save.data.sustains;
			PlayStateChangeables.healthDrain = FlxG.save.data.hdrain;
			PlayStateChangeables.healthGain = FlxG.save.data.hgain;
			PlayStateChangeables.healthLoss = FlxG.save.data.hloss;
			PlayStateChangeables.practiceMode = FlxG.save.data.practice;
			PlayStateChangeables.skillIssue = FlxG.save.data.noMisses;
		}
		else
		{
			PlayStateChangeables.modchart = true;
			PlayStateChangeables.opponentMode = false;
			PlayStateChangeables.mirrorMode = false;
			PlayStateChangeables.holds = true;
			PlayStateChangeables.healthDrain = false;
			PlayStateChangeables.healthGain = 1;
			PlayStateChangeables.healthLoss = 1;
			PlayStateChangeables.practiceMode = false;
			PlayStateChangeables.skillIssue = false;
		}

		#if FEATURE_LUAMODCHART
		executeModchart = OpenFlAssets.exists(Paths.lua('songs/${PlayState.SONG.songId}/modchart')) && PlayStateChangeables.modchart;
		if (isSM)
			executeModchart = OpenFlAssets.exists(pathToSm + "/modchart.lua");
		#end
		#if !cpp
		executeModchart = false;
		#end
		
		if (FlxG.save.data.gen){
			Debug.logInfo('Searching for Lua Modchart? ($executeModchart) at ${Paths.lua('songs/${PlayState.SONG.songId}/modchart')}');
			//Debug.logInfo('Searching for HScript? ($executeHScript) at ${Paths.hscript('songs/${PlayState.SONG.songId}/script')}');
		}
		

		if (executeModchart)
			songMultiplier = 1;

		#if FEATURE_DISCORD
		storyDifficultyText = CoolUtil.difficultyFromInt(storyDifficulty);

		iconRPC = SONG.player2;
		
		switch (iconRPC)
		{
			case 'senpai-angry':
				iconRPC = 'senpai';
			case 'monster-christmas':
				iconRPC = 'monster';
			case 'mom-car':
				iconRPC = 'mom';
		}
		
		if (isStoryMode)
		{
			detailsText = "Story Mode: Week " + storyWeek;
		}
		else
		{
			detailsText = "Freeplay";
		}
		
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end
		
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camSustains = new FlxCamera();
		camSustains.height = 1300;
		camSustains.bgColor.alpha = 0;
		camStrums = new FlxCamera();
		camStrums.height = 1300;
		camStrums.bgColor.alpha = 0;
		camNotes = new FlxCamera();
		camNotes.height = 1300;
		camNotes.bgColor.alpha = 0;
		overlayCam = new FlxCamera();
		overlayCam.bgColor.alpha = 0;

		// Game Camera (where stage and characters are)
		FlxG.cameras.reset(camGame);

		// HUD Camera (Health Bar, scoreTxt, etc)
		FlxG.cameras.add(camHUD);

		// StrumLine Camera
		FlxG.cameras.add(camStrums);

		// Long Notes camera
		FlxG.cameras.add(camSustains);

		// Single Notes camera
		FlxG.cameras.add(camNotes);

		FlxG.cameras.add(overlayCam);

		camHUD.zoom = PlayStateChangeables.zoom;
		camStrums.zoom = camHUD.zoom;

		FlxCamera.defaultCameras = [camGame];

		persistentUpdate = true;
		persistentDraw = true;

		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', '');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		Conductor.bpm = SONG.bpm;
		#if FEATURE_HSCRIPT
			scripts.setAll("bpm", Conductor.bpm);
		#end

		if (SONG.eventObjects == null)
		{
			SONG.eventObjects = [new Song.Event("Init BPM", 0, SONG.bpm, "BPM Change")];
		}

		// if the song has dialogue, so we don't accidentally try to load a nonexistant file and crash the game
		if (Paths.doesTextAssetExist(Paths.txt('data/songs/${PlayState.SONG.songId}/dialogue')))
		{
			dialogue = CoolUtil.coolTextFile(Paths.txt('data/songs/${PlayState.SONG.songId}/dialogue'));
		}

		if (isStoryMode)
		{
			switch (storyWeek)
			{
				case 7:
					inCinematic = true;
				case 5:
					if (PlayState.SONG.songId == 'winter-horrorland')
						inCinematic = true;
			}
		}

		// defaults if no stage was found in chart
		var stageCheck:String = 'stage';

		// If the stage isn't specified in the chart, we use the story week value.
		if (SONG.stage == null)
		{
			switch (storyWeek)
			{
				case 2:
					stageCheck = 'halloween';
				case 3:
					stageCheck = 'philly';
				case 4:
					stageCheck = 'limo';
				case 5:
					if (SONG.songId == 'winter-horrorland')
					{
						stageCheck = 'mallEvil';
					}
					else
					{
						stageCheck = 'mall';
					}
				case 6:
					if (SONG.songId == 'thorns')
					{
						stageCheck = 'schoolEvil';
					}
					else
					{
						stageCheck = 'school';
					}
				case 7:
					stageCheck = 'tank';	
			}
		}
		else
		{
			stageCheck = SONG.stage;
		}

		if (isStoryMode)
			songMultiplier = 1;

		// defaults if no gf was found in chart
		var gfCheck:String = 'gf';

		if (SONG.gfVersion == null)
		{
			switch (storyWeek)
			{
				case 4:
					gfCheck = 'gf-car';
				case 5:
					gfCheck = 'gf-christmas';
				case 6:
					gfCheck = 'gf-pixel';
				case 7:
					gfCheck	= 'gfTank';
			}
		}
		else
		{
			gfCheck = SONG.gfVersion;
		}

		if (!stageTesting || !FlxG.save.data.optimize)
		{
			gf = new Character(400, 130, gfCheck);

			if (!FlxG.save.data.optimize && gf.frames == null)
			{
				#if debug
				FlxG.log.warn(["Couldn't load gf: " + gfCheck + ". Loading default gf"]);
				#end
				gf = new Character(400, 130, 'gf');
			}

			boyfriend = new Boyfriend(770, 450, SONG.player1);

			if (!FlxG.save.data.optimize && boyfriend.frames == null)
			{
				#if debug
				FlxG.log.warn(["Couldn't load boyfriend: " + SONG.player1 + ". Loading default boyfriend"]);
				#end
				boyfriend = new Boyfriend(770, 450, 'bf');
			}

			dad = new Character(100, 100, SONG.player2);

			if (!FlxG.save.data.optimize && dad.frames == null)
			{
				#if debug
				FlxG.log.warn(["Couldn't load opponent: " + SONG.player2 + ". Loading default opponent"]);
				#end
				dad = new Character(100, 100, 'dad');
			}
		}

		#if FEATURE_HSCRIPT
		initScripts();

		scripts.executeAllFunc("create");
		#end
		

		if (!stageTesting)
			Stage = new Stage(SONG.stage);

		var positions = Stage.positions[Stage.curStage];
		if (positions != null && !stageTesting)
		{
			for (char => pos in positions)
				for (person in [boyfriend, gf, dad])
					if (person.curCharacter == char)
						person.setPosition(pos[0], pos[1]);
		}
			if (!FlxG.save.data.optimize){
				gf.x += gf.charPos[0];
				gf.y += gf.charPos[1];
				dad.x += dad.charPos[0];
				dad.y += dad.charPos[1];
				boyfriend.x += boyfriend.charPos[0];
				boyfriend.y += boyfriend.charPos[1];

				if (dad.hasTrail)
				{
					if (FlxG.save.data.distractions)
					{
						// trailArea.scrollFactor.set();
						if (!FlxG.save.data.optimize)
						{
							var evilTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069);
							// evilTrail.changeValuesEnabled(false, false, false, false);
							// evilTrail.changeGraphic()
							add(evilTrail);
						}
						// evilTrail.scrollFactor.set(1.1, 1.1);
					}
				}
				if (FlxG.save.data.background)
					Stage.update(0);

			if (FlxG.save.data.background)
			{
				for (i in Stage.toAdd)
				{
					add(i);
				}

				if (FlxG.save.data.distractions)
				{
					if (SONG.songId == 'stress')
					{
						switch (gf.curCharacter)
						{
							case 'pico-speaker':
								Character.loadMappedAnims();
						}
					}
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
						case 3:
					}
				}	
			}
			}	
		
			

		if (!FlxG.save.data.optimize)
		{
			camPos = new FlxPoint(dad.getGraphicMidpoint().x + dad.camPos[0], dad.getGraphicMidpoint().y + dad.camPos[1]);

			switch (Stage.curStage)
			{
				case 'halloween':
					camPos = new FlxPoint(gf.getMidpoint().x + dad.camPos[0], gf.getMidpoint().y + dad.camPos[1]);
				case 'stage':
					if (dad.replacesGF)
						camPos = new FlxPoint(dad.getGraphicMidpoint().x + dad.camPos[0] - 200, dad.getGraphicMidpoint().y + dad.camPos[1]);
				case 'mallEvil':
					camPos = new FlxPoint(boyfriend.getMidpoint().x - 100 + boyfriend.camPos[0], boyfriend.getMidpoint().y - 100 + boyfriend.camPos[1]);
				default:
					camPos = new FlxPoint(dad.getGraphicMidpoint().x + dad.camPos[0], dad.getGraphicMidpoint().y + dad.camPos[1]);
			}
		}
		else
		{
			camPos = new FlxPoint(0, 0);
		}

		if (dad.replacesGF)
		{
			if (!stageTesting)
				dad.setPosition(gf.x, gf.y);
			gf.visible = false;

			camPos.x += 600;
			//tweenCamIn();
		}

		Stage.update(0);

		if (loadRep)
		{
			FlxG.watch.addQuick('rep rpesses', repPresses);
			FlxG.watch.addQuick('rep releases', repReleases);
			// FlxG.watch.addQuick('Queued',inputsQueued);

			PlayStateChangeables.useDownscroll = rep.replay.isDownscroll;
			PlayStateChangeables.safeFrames = rep.replay.sf;
			PlayStateChangeables.botPlay = true;
		}

		var doof = null;

		if (isStoryMode)
		{
			doof = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = startCountdown;
		}

		if (!isStoryMode && songMultiplier == 1)
		{
			var firstNoteTime = Math.POSITIVE_INFINITY;
			var playerTurn = false;
			for (index => section in SONG.notes)
			{
				if (section.sectionNotes.length > 0 && !isSM)
				{
					if (section.startTime > 5000)
					{
						needSkip = true;
						skipTo = section.startTime - 1000;
					}
					break;
				}
				else if (isSM)
				{
					for (note in section.sectionNotes)
					{
						if (note[0] < firstNoteTime)
						{
							if (!PlayStateChangeables.Optimize)
							{
								firstNoteTime = note[0];
								if (note[1] > 3)
									playerTurn = true;
								else
									playerTurn = false;
							}
							else if (note[1] > 3)
							{
								firstNoteTime = note[0];
							}
						}
					}
					if (index + 1 == SONG.notes.length)
					{
						var timing = ((!playerTurn && !PlayStateChangeables.Optimize) ? firstNoteTime : TimingStruct.getTimeFromBeat(TimingStruct.getBeatFromTime(firstNoteTime)
							- 4));
						if (timing > 5000)
						{
							needSkip = true;
							skipTo = timing - 1000;
						}
					}
				}
			}
		}

		Conductor.songPosition = -5000;
		Conductor.rawPosition = Conductor.songPosition;

		strumLine = new FlxSprite(0, 50).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();

		if (PlayStateChangeables.useDownscroll)
			strumLine.y = FlxG.height - 165;

		laneunderlayOpponent = new FlxSprite(0, 0).makeGraphic(110 * 4 + 50, FlxG.height * 2);
		laneunderlayOpponent.alpha = FlxG.save.data.laneTransparency;
		laneunderlayOpponent.color = FlxColor.BLACK;
		laneunderlayOpponent.scrollFactor.set();

		laneunderlay = new FlxSprite(0, 0).makeGraphic(110 * 4 + 50, FlxG.height * 2);
		laneunderlay.alpha = FlxG.save.data.laneTransparency;
		laneunderlay.color = FlxColor.BLACK;
		laneunderlay.scrollFactor.set();

		if (isStoryMode)
		{
			if (inCutscene)
			{
				laneunderlayOpponent.alpha = 0;
				laneunderlay.alpha = 0;
			}
		}
		
		if (!FlxG.save.data.middleScroll)
		{
			add(laneunderlayOpponent);
		}
		add(laneunderlay);	

		strumLineNotes = new FlxTypedGroup<StaticArrow>();
		add(strumLineNotes);

		playerStrums = new FlxTypedGroup<StaticArrow>();
		cpuStrums = new FlxTypedGroup<StaticArrow>();
		
		noteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.noteskin);
		noteskinPixelSprite = CustomNoteHelpers.Skin.generatePixelSprite(FlxG.save.data.noteskin);
		noteskinPixelSpriteEnds = CustomNoteHelpers.Skin.generatePixelSprite(FlxG.save.data.noteskin, true);

		cpuNoteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);

		notesplashSprite = CustomNoteHelpers.Splash.generateNotesplashSprite(FlxG.save.data.notesplash);

		
		var tweenBoolshit = !isStoryMode || storyPlaylist.length >= 3 || SONG.songId == 'tutorial';

		generateStaticArrows(0, tweenBoolshit);
		generateStaticArrows(1, tweenBoolshit);

		laneunderlay.screenCenter(Y);
		laneunderlayOpponent.screenCenter(Y);

		if (FlxG.save.data.gen)
		{
			if (SONG.songId == null)
				Debug.logInfo('SongID Is Null.');
			else
				Debug.logInfo('Succesfully Loaded ' + SONG.songName);
		}

		generateSong(SONG.songId);


		#if FEATURE_LUAMODCHART
		if (executeModchart)
		{
			luaModchart = ModchartState.createModchartState();
			luaModchart.executeState('start', [PlayState.SONG.songId]);
		}
		#end

		if (FlxG.save.data.noteSplashes)
		{
			if (SONG.noteStyle == 'pixel')
				precacheThing('weeb/pixelUI/noteSplashes-pixels', 'image', 'week6');
		}

		// Update lane underlay positions AFTER static arrows :)
		if (arrowsGenerated)
		{
			laneunderlay.x = playerStrums.members[0].x - 25;

			if (!FlxG.save.data.optimize && !FlxG.save.data.middleScroll || executeModchart)
			{
				laneunderlayOpponent.x = cpuStrums.members[0].x - 25;
			}
		}

		laneunderlay.screenCenter(Y);
		laneunderlayOpponent.screenCenter(Y);

		#if FEATURE_LUAMODCHART
		if (executeModchart)
		{
			new LuaCamera(camGame, "camGame").Register(ModchartState.lua);
			new LuaCamera(camHUD, "camHUD").Register(ModchartState.lua);
			new LuaCamera(camSustains, "camSustains").Register(ModchartState.lua);
			new LuaCamera(camSustains, "camNotes").Register(ModchartState.lua);
			new LuaCamera(camStrums, "camStrums").Register(ModchartState.lua);
			new LuaCharacter(dad, "dad").Register(ModchartState.lua);
			new LuaCharacter(gf, "gf").Register(ModchartState.lua);
			new LuaCharacter(boyfriend, "boyfriend").Register(ModchartState.lua);
		}
		#end

		var index = 0;

		if (startTime != 0)
		{
			var toBeRemoved = [];
			for (i in 0...unspawnNotes.length)
			{
				var dunceNote:Note = unspawnNotes[i];

				if (dunceNote.strumTime <= startTime)
					toBeRemoved.push(dunceNote);
			}

			for (i in toBeRemoved)
				unspawnNotes.remove(i);
			if (FlxG.save.data.gen)
			{
				Debug.logInfo("Removed " + toBeRemoved.length + " cuz of start time");
			}
		}

		camFollow = new FlxObject(0, 0, 1, 1);

		camFollow.setPosition(camPos.x, camPos.y);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		add(camFollow);

		FlxG.camera.follow(camFollow, LOCKON, 0.07 * (60 / Application.current.window.frameRate));
		FlxG.camera.zoom = Stage.camZoom;
		FlxG.camera.focusOn(camFollow.getPosition());

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		FlxG.fixedTimestep = false;

		healthBarBG = new FlxSprite(0, FlxG.height * 0.9).loadGraphic(Paths.image2('healthBar'));
		if (PlayStateChangeables.useDownscroll)
			healthBarBG.y = 50;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), this,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		// healthBar

		// Add watermark
		kadeEngineWatermark = new FlxText(4, healthBarBG.y
			+ 50, 0,
			PlayState.SONG.song
			+ (FlxMath.roundDecimal(songMultiplier, 2) != 1.00 ? " (" + FlxMath.roundDecimal(songMultiplier, 2) + "x)" : "")
			+ " - "
			+ CoolUtil.difficultyFromInt(storyDifficulty),
			16);
		kadeEngineWatermark.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		kadeEngineWatermark.scrollFactor.set();
		add(kadeEngineWatermark);

		if (PlayStateChangeables.useDownscroll)
			kadeEngineWatermark.y = FlxG.height * 0.9 + 45;

		scoreTxt = new FlxText(FlxG.width / 2 - 235, healthBarBG.y + 50, 0, "", 20);
		scoreTxt.screenCenter(X);
		scoreTxt.scrollFactor.set();
		scoreTxt.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		//scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS, accuracy);
		if (!FlxG.save.data.healthBar)
			scoreTxt.y = healthBarBG.y;

		add(scoreTxt);

		judgementCounter = new FlxText(20, 0, 0, "", 20);
		judgementCounter.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		judgementCounter.borderSize = 2;
		judgementCounter.borderQuality = 2;
		judgementCounter.scrollFactor.set();
		judgementCounter.cameras = [camHUD];
		judgementCounter.screenCenter(Y);
		judgementCounter.text = 'Marvelous: ${marvs}\nSicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${misses}';
		if (FlxG.save.data.judgementCounter)
		{
			add(judgementCounter);
		}

		replayTxt = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (PlayStateChangeables.useDownscroll ? 100 : -100), 0, "REPLAY",
			20);
		replayTxt.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		replayTxt.borderSize = 4;
		replayTxt.borderQuality = 2;
		replayTxt.scrollFactor.set();
		replayTxt.cameras = [camHUD];
		if (loadRep)
		{
			add(replayTxt);
		}
		botPlayState = new FlxText(healthBarBG.x + healthBarBG.width / 2 - 75, healthBarBG.y + (PlayStateChangeables.useDownscroll ? 100 : -100), 0,
			"BOTPLAY", 20);
		botPlayState.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botPlayState.scrollFactor.set();
		botPlayState.borderSize = 4;
		botPlayState.borderQuality = 2;
		botPlayState.cameras = [camHUD];
		if (PlayStateChangeables.botPlay && !loadRep)
			add(botPlayState);

		addedBotplay = PlayStateChangeables.botPlay;

		iconP1 = new HealthIcon(boyfriend.curCharacter, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);

		iconP2 = new HealthIcon(dad.curCharacter, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);

		if (FlxG.save.data.healthBar)
		{
			add(healthBarBG);
			add(healthBar);
			add(iconP1);
			add(iconP2);

			if (FlxG.save.data.colour)
				healthBar.createFilledBar(dad.barColor, boyfriend.barColor);
			else
				healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}

		strumLineNotes.cameras = [camHUD];
		notes.cameras = [camNotes];
		healthBar.cameras = [camHUD];
		healthBarBG.cameras = [camHUD];
		iconP1.cameras = [camHUD];
		iconP2.cameras = [camHUD];
		scoreTxt.cameras = [camHUD];
		laneunderlay.cameras = [camHUD];
		laneunderlayOpponent.cameras = [camHUD];
		//sfjl

		if (isStoryMode)
			doof.cameras = [camHUD];
		kadeEngineWatermark.cameras = [camHUD];

		startingSong = true;
		if (!FlxG.save.data.optimize)
		{
			dad.dance();
			boyfriend.dance();
			gf.dance();
		}

		if (inCutscene)
			removeStaticArrows();

		if (isStoryMode)
		{
			switch (StringTools.replace(curSong, " ", "-").toLowerCase())
			{
				case "winter-horrorland":
					var blackScreen:FlxSprite = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					add(blackScreen);
					blackScreen.scrollFactor.set();
					camHUD.visible = false;
					camStrums.visible = false;
					removeStaticArrows();

					new FlxTimer().start(0.1, function(tmr:FlxTimer)
					{
						remove(blackScreen);
						FlxG.sound.play(Paths.sound('Lights_Turn_On'));
						camFollow.y = -2050;
						camFollow.x += 200;
						FlxG.camera.focusOn(camFollow.getPosition());
						FlxG.camera.zoom = 1.5;

						new FlxTimer().start(1, function(tmr:FlxTimer)
						{
							camHUD.visible = true;
							remove(blackScreen);
							FlxTween.tween(FlxG.camera, {zoom: Stage.camZoom}, 2.5, {
								ease: FlxEase.quadInOut,
								onComplete: function(twn:FlxTween)
								{
									startCountdown();
									camHUD.visible = true;
									camStrums.visible = true;
								}
							});
						});
					});
				case 'senpai':
					schoolIntro(doof);
				case 'roses':
					generateStaticArrows(0, false);
					generateStaticArrows(1, false);
					FlxG.sound.play(Paths.sound('ANGRY'));
					schoolIntro(doof);
				case 'thorns':
					schoolIntro(doof);
				case 'ugh', 'guns', 'stress':
					if (!FlxG.save.data.stressMP4 && FlxG.save.data.background)
						tankIntro();
					else
					{
						removeStaticArrows();
						#if VIDEOS
						playCutscene('${SONG.songId}Cutscene.mp4', false);
						#end
					}	
				default:
					startCountdown();
			}
		}
		else
		{
			new FlxTimer().start(1, function(timer)
			{
				if (!inCutscene)
					startCountdown();
			});
		}

		if (!loadRep)
			rep = new Replay("na");

		// This allow arrow key to be detected by flixel. See https://github.com/HaxeFlixel/flixel/issues/2190
		FlxG.keys.preventDefaultKeys = [];
		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, releaseInput);

		super.create();

		
		if (FlxG.save.data.distractions && FlxG.save.data.background)
		{
			if (gfCheck == 'pico-speaker' && Stage.curStage == 'tank')
			{
				if (FlxG.save.data.distractions)
				{
					var firstTank:TankmenBG = new TankmenBG(20, 500, true);
					firstTank.resetShit(20, 600, true);
					firstTank.strumTime = 10;
					if (Stage.swagBacks['tankmanRun'] != null)
					{
						Stage.swagBacks['tankmanRun'].add(firstTank);

						for (i in 0...TankmenBG.animationNotes.length)
						{
							if (FlxG.random.bool(16))
							{
								var tankBih = Stage.swagBacks['tankmanRun'].recycle(TankmenBG);
								tankBih.strumTime = TankmenBG.animationNotes[i].strumTime;
								tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i].noteData < 2);
								Stage.swagBacks['tankmanRun'].add(tankBih);
							}
						}
					}
				}
			}
		}

		if (!isStoryMode)
			tankIntroEnd = true;

		if (FlxG.save.data.hitSound != 0)
			precacheThing("hitsounds/" + HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase(), 'sound', 'shared');	

		precacheThing('alphabet', 'image', null);

		precacheThing('breakfast', 'music', 'shared');
		if (FlxG.save.data.notesplashes){
			switch(FlxG.save.data.notesplash){
				case 0:
					precacheThing('splashes/Default', 'image', 'shared');
				case 1:
					precacheThing('splashes/Week7', 'image', 'shared');	
			}
		}
		Paths.clearUnusedMemory();
		#if FEATURE_HSCRIPT
			scripts.executeAllFunc("createPost");
		#end
	}

	public var tankIntroEnd:Bool = false;

	function tankIntro()
	{
		dad.visible = false;
		precacheThing('DISTORTO', 'music', 'week7');
		var tankManEnd:Void->Void = function()
		{
			tankIntroEnd = true;
			var timeForStuff:Float = Conductor.crochet / 1000 * 5;
			createTween(FlxG.camera, {zoom: Stage.camZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			startCountdown();
			camStrums.visible = true;
			camHUD.visible = true;
			dad.visible = true;
			FlxG.sound.music.stop();

			var cutSceneStuff:Array<FlxSprite> = [Stage.swagBacks['tankman']];
			if (SONG.songId == 'stress' && !FlxG.save.data.stressMP4)
			{
				cutSceneStuff.push(Stage.swagBacks['bfCutscene']);
				cutSceneStuff.push(Stage.swagBacks['gfCutscene']);
			}
			for (char in cutSceneStuff)
			{
				char.kill();
				remove(char);
				char.destroy();
			}
			Paths.clearUnusedMemory();
		}

		switch (SONG.songId)
		{
			case 'ugh':
				removeStaticArrows();
				camHUD.visible = false;
				precacheThing('wellWellWell', 'sound', 'week7');
				precacheThing('killYou', 'sound', 'week7');
				precacheThing('bfBeep', 'sound', 'week7');
				var WellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.sound('wellWellWell', 'week7'));

				FlxG.sound.list.add(WellWellWell);

				FlxG.sound.playMusic(Paths.music('DISTORTO', 'week7'));
				FlxG.sound.music.fadeIn();
				Stage.swagBacks['tankman'].animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				Stage.swagBacks['tankman'].animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				Stage.swagBacks['tankman'].animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;
				camFollow.x = 436.5;
				camFollow.y = 520;

				// Well well well, what do we got here?
				createTimer(0.1, function(tmr:FlxTimer)
				{
					WellWellWell.play(true);
				});

				// Move camera to BF
				createTimer(3, function(tmr:FlxTimer)
				{
					camFollow.x += 400;
					camFollow.y += 60;
					// Beep!
					createTimer(1.5, function(tmr:FlxTimer)
					{
						boyfriend.playAnim('singUP', true);
						FlxG.sound.play(Paths.sound('bfBeep'));
					});

					// Move camera to Tankman
					createTimer(3, function(tmr:FlxTimer)
					{
						camFollow.x = 436.5;
						camFollow.y = 520;
						boyfriend.dance();
						Stage.swagBacks['tankman'].animation.play('killYou', true);
						FlxG.sound.play(Paths.sound('killYou'));

						// We should just kill you but... what the hell, it's been a boring day... let's see what you've got!
						createTimer(6.1, function(tmr:FlxTimer)
						{
							tankManEnd();
						});
					});
				});

			case 'guns':
				precacheThing('tankSong2', 'sound', 'week7');
				FlxG.sound.playMusic(Paths.music('DISTORTO', 'week7'), 0, false);
				FlxG.sound.music.fadeIn();

				var tightBars:FlxSound = new FlxSound().loadEmbedded(Paths.sound('tankSong2', 'week7'));
				FlxG.sound.list.add(tightBars);

				laneunderlayOpponent.alpha = FlxG.save.data.laneTransparency;
				laneunderlay.alpha = FlxG.save.data.laneTransparency;

				createTimer(0.01, function(tmr:FlxTimer)
				{
					tightBars.play(true);
				});

				createTimer(0.5, function(tmr:FlxTimer)
				{
					createTween(camStrums, {alpha: 0}, 1.5, {ease: FlxEase.quadInOut});
					createTween(camHUD, {alpha: 0}, 1.5, {
						ease: FlxEase.quadInOut,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = false;
							camHUD.alpha = 1;
							camStrums.visible = false;
							camStrums.alpha = 1;
							removeStaticArrows();
							laneunderlayOpponent.alpha = 0;
							laneunderlay.alpha = 0;
						}
					});
				});

				Stage.swagBacks['tankman'].animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				Stage.swagBacks['tankman'].animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				createTimer(1, function(tmr:FlxTimer)
				{
					camFollow.x = 436.5;
					camFollow.y = 520;
				});

				createTimer(4, function(tmr:FlxTimer)
				{
					camFollow.y -= 150;
					camFollow.x += 100;
				});
				createTimer(1, function(tmr:FlxTimer)
				{
					createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2}, 3, {ease: FlxEase.quadInOut});

					createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 3});
					createTween(FlxG.camera, {zoom: Stage.camZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 3.5});
				});

				createTimer(4, function(tmr:FlxTimer)
				{
					gf.playAnim('sad', true);
					gf.animation.finishCallback = function(name:String)
					{
						gf.playAnim('sad', true);
					};
				});

				createTimer(11.6, function(tmr:FlxTimer)
				{
					camFollow.x = 440;
					camFollow.y = 534.5;
					tankManEnd();

					gf.dance();
					gf.animation.finishCallback = null;
				});

			case 'stress':
				if (!FlxG.save.data.stressMP4){
					laneunderlayOpponent.alpha = FlxG.save.data.laneTransparency;
				laneunderlay.alpha = FlxG.save.data.laneTransparency;
				precacheThing('stressCutscene', 'sound', 'week7');

				precacheThing('cutscenes/stress2', 'image', 'week7');

				createTimer(0.5, function(tmr:FlxTimer)
				{
					createTween(camStrums, {alpha: 0}, 1.5, {ease: FlxEase.quadInOut});
					createTween(camHUD, {alpha: 0}, 1.5, {
						ease: FlxEase.quadInOut,
						onComplete: function(twn:FlxTween)
						{
							camHUD.visible = false;
							camHUD.alpha = 1;
							camStrums.visible = false;
							camStrums.alpha = 1;
							removeStaticArrows();
							laneunderlayOpponent.alpha = 0;
							laneunderlay.alpha = 0;
						}
					});
				});

				gf.visible = false;
				boyfriend.visible = false;
				createTimer(1, function(tmr:FlxTimer)
				{
					camFollow.x = 436.5;
					camFollow.y = 534.5;
					createTween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
				});

				Stage.swagBacks['bfCutscene'].animation.finishCallback = function(name:String)
				{
					Stage.swagBacks['bfCutscene'].animation.play('idle');
				}

				Stage.swagBacks['dummyGf'].animation.finishCallback = function(name:String)
				{
					Stage.swagBacks['dummyGf'].animation.play('idle');
				}

				var cutsceneSnd:FlxSound = new FlxSound().loadEmbedded(Paths.sound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				Stage.swagBacks['tankman'].animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				Stage.swagBacks['tankman'].animation.play('godEffingDamnIt', true);

				createTimer(0.01, function(tmr:FlxTimer) // Fixes sync????
				{
					cutsceneSnd.play(true);
				});

				createTimer(14.2, function(tmr:FlxTimer)
				{
					Stage.swagBacks['bfCutscene'].animation.finishCallback = null;
					Stage.swagBacks['dummyGf'].animation.finishCallback = null;
				});

				createTimer(15.2, function(tmr:FlxTimer)
				{
					createTween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					createTween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});
					createTimer(2.3, function(tmr:FlxTimer)
					{
						camFollow.x = 630;
						camFollow.y = 425;
						FlxG.camera.zoom = 0.9;
					});

					Stage.swagBacks['dummyGf'].visible = false;
					Stage.swagBacks['gfCutscene'].visible = true;
					Stage.swagBacks['gfCutscene'].animation.play('dieBitch', true);
					Stage.swagBacks['gfCutscene'].animation.finishCallback = function(name:String)
					{
						if (name == 'dieBitch') // Next part
						{
							Stage.swagBacks['gfCutscene'].animation.play('getRektLmao', true);
							Stage.swagBacks['gfCutscene'].offset.set(224, 445);
						}
						else
						{
							Stage.swagBacks['gfCutscene'].visible = false;
							Stage.swagBacks['picoCutscene'].visible = true;
							Stage.swagBacks['picoCutscene'].animation.play('anim', true);

							boyfriend.visible = true;
							Stage.swagBacks['bfCutscene'].visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String)
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
								}
							};

							Stage.swagBacks['picoCutscene'].animation.finishCallback = function(name:String)
							{
								Stage.swagBacks['picoCutscene'].visible = false;
								gf.visible = true;
								Stage.swagBacks['picoCutscene'].animation.finishCallback = null;
							};
							Stage.swagBacks['gfCutscene'].animation.finishCallback = null;
						}
					};
				});

				createTimer(19.5, function(tmr:FlxTimer)
				{
					Stage.swagBacks['tankman'].frames = Paths.getSparrowAtlas('cutscenes/stress2', 'week7');
					Stage.swagBacks['tankman'].animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					Stage.swagBacks['tankman'].animation.play('lookWhoItIs', true);
					Stage.swagBacks['tankman'].x += 90;
					Stage.swagBacks['tankman'].y += 6;

					createTimer(0.5, function(tmr:FlxTimer)
					{
						camFollow.x = 436.5;
						camFollow.y = 534.5;
					});
				});

				createTimer(31.2, function(tmr:FlxTimer)
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String)
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); // Instantly goes to last frame
						}
					};
					FlxG.camera.follow(camFollow, LOCKON, 1);

					camFollow.setPosition(1100, 625);
					FlxG.camera.zoom = 1.3;

					createTimer(1, function(tmr:FlxTimer)
					{
						FlxG.camera.zoom = 0.9;
						camFollow.setPosition(440, 534.5);
					});
				});
				createTimer(35.5, function(tmr:FlxTimer)
				{
					tankManEnd();
					boyfriend.animation.finishCallback = null;
				});
			}
		}
	}

	public function addShaderToCamera(camera:String, effect:ShaderEffect)
	{
		switch (camera.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camHUDShaders)
					newCamEffects.push(new ShaderFilter(i.shader));
				camHUD.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camGameShaders)
					newCamEffects.push(new ShaderFilter(i.shader));
				camGame.setFilters(newCamEffects);
			case 'camnotes' | 'notes':
				camNotesShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camNotesShaders)
					newCamEffects.push(new ShaderFilter(i.shader));
				camNotes.setFilters(newCamEffects);
			case 'camstrums' | 'strums':
				camStrumsShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in camStrumsShaders)
					newCamEffects.push(new ShaderFilter(i.shader));
				camStrums.setFilters(newCamEffects);
			case 'overlay' | 'camoverlay':
				overlayShaders.push(effect);
				var newCamEffects:Array<BitmapFilter> = [];
				for (i in overlayShaders)
					newCamEffects.push(new ShaderFilter(i.shader));
				overlayCam.setFilters(newCamEffects);
		}
	}

	public function clearShaderFromCamera(camera:String)
	{
		switch (camera.toLowerCase())
		{
			case 'camhud' | 'hud':
				camHUDShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camHUD.setFilters(newCamEffects);
			case 'camgame' | 'game':
				camGameShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				camGame.setFilters(newCamEffects);
			case 'overlay' | 'overlaycam':
				overlayShaders = [];
				var newCamEffects:Array<BitmapFilter> = [];
				overlayCam.setFilters(newCamEffects);	
		}
	}

	function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100).makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();

		if (PlayState.SONG.songId == 'roses' || PlayState.SONG.songId == 'thorns')
		{
			remove(black);

			if (PlayState.SONG.songId == 'thorns')
			{
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer)
		{
			black.alpha -= 0.15;

			if (black.alpha > 0)
			{
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (PlayState.SONG.songId == 'thorns')
					{
						add(senpaiEvil);
						senpaiEvil.alpha = 0;
						new FlxTimer().start(0.3, function(swagTimer:FlxTimer)
						{
							senpaiEvil.alpha += 0.15;
							if (senpaiEvil.alpha < 1)
							{
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');
								FlxG.sound.play(Paths.sound('Senpai_Dies'), 1, false, null, true, function()
								{
									remove(senpaiEvil);
									remove(red);
									FlxG.camera.fade(FlxColor.WHITE, 0.01, true, function()
									{
										add(dialogueBox);
									}, true);
								});
								new FlxTimer().start(3.2, function(deadTime:FlxTimer)
								{
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else
					{
						add(dialogueBox);
					}
				}
				else
					startCountdown();

				remove(black);
			}
		});
	}

	var startTimer:FlxTimer;
	var perfectMode:Bool = false;
	var luaWiggles:Array<WiggleEffect> = [];

	#if FEATURE_LUAMODCHART
	public static var luaModchart:ModchartState = null;
	#end

	var keys = [false, false, false, false];

	function startCountdown():Void
	{
		if (inCinematic || inCutscene)
		{
			FlxTween.tween(laneunderlay, {alpha: FlxG.save.data.laneTransparency}, 0.75);
			if (!FlxG.save.data.middleScroll)
				FlxTween.tween(laneunderlayOpponent, {alpha: FlxG.save.data.laneTransparency}, 0.75);

			if (!arrowsGenerated)
			{
				generateStaticArrows(1, true);

				generateStaticArrows(0, true);
			}
		}

		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("countdown")))
			return;
		#end
		
		inCinematic = false;
		inCutscene = false;

		// appearStaticArrows();

		talking = false;
		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;

		#if FEATURE_STEPMANIA
		if (isSM){
			if (FlxG.sound.music.playing)
				FlxG.sound.music.stop();
		}
		else{
			if (inst.playing)
				inst.stop();
			if (vocals != null)
				vocals.stop();
		}
		#else
		if (inst.playing)
			inst.stop();
		if (vocals != null)
			vocals.stop();
		#end
		

		var swagCounter:Int = 0;

		startTimer = createTimer((Conductor.crochet / 1000), function(tmr:FlxTimer)
		{
			// this just based on beatHit stuff but compact
			if (!FlxG.save.data.optimize)
			{
				if (allowedToHeadbang && swagCounter % gfSpeed == 0)
					gf.dance();

				if (swagCounter % Math.floor(idleBeat * songMultiplier) == 0)
				{
					if (boyfriend != null && idleToBeat && !boyfriend.animation.curAnim.name.endsWith("miss"))
						boyfriend.dance(forcedToIdle);
					if (dad != null && idleToBeat)
						dad.dance(forcedToIdle);
				}
				else if (swagCounter % Math.floor(idleBeat * songMultiplier) != 0)
				{
					if (boyfriend != null && boyfriend.isDancing && !boyfriend.animation.curAnim.name.endsWith("miss"))
						boyfriend.dance();
					if (dad != null && dad.isDancing)
						dad.dance();
				}
			}

			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);
			introAssets.set('pixel', ['weeb/pixelUI/ready-pixel', 'weeb/pixelUI/set-pixel', 'weeb/pixelUI/date-pixel']);

			var introAlts:Array<String> = introAssets.get('default');
			var week6Bullshit:String = 'shared';

			if (SONG.noteStyle == 'pixel')
			{
				introAlts = introAssets.get('pixel');
				altSuffix = '-pixel';
				week6Bullshit = 'week6';
			}

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3' + altSuffix), 0.6);
				case 1:
					var ready:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[0], week6Bullshit));
					ready.scrollFactor.set();
					ready.scale.set(0.7, 0.7);
					ready.cameras = [camHUD];
					ready.updateHitbox();

					if (SONG.noteStyle == 'pixel')
						ready.setGraphicSize(Std.int(ready.width * CoolUtil.daPixelZoom));

					ready.screenCenter();
					add(ready);
					createTween(ready, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro2' + altSuffix), 0.6);
				case 2:
					var set:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[1], week6Bullshit));
					set.scrollFactor.set();
					set.scale.set(0.7, 0.7);
					if (SONG.noteStyle == 'pixel')
						set.setGraphicSize(Std.int(set.width * CoolUtil.daPixelZoom));
					set.cameras = [camHUD];
					set.screenCenter();
					add(set);
					createTween(set, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('intro1' + altSuffix), 0.6);
				case 3:
					var go:FlxSprite = new FlxSprite().loadGraphic(Paths.image(introAlts[2], week6Bullshit));
					go.scrollFactor.set();
					go.scale.set(0.7, 0.7);
					go.cameras = [camHUD];
					if (SONG.noteStyle == 'pixel')
						go.setGraphicSize(Std.int(go.width * CoolUtil.daPixelZoom));

					go.updateHitbox();

					go.screenCenter();
					add(go);
					createTween(go, {alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
					FlxG.sound.play(Paths.sound('introGo' + altSuffix), 0.6);
			}
			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("countTick", [swagCounter]);
			#end

			swagCounter += 1;
		}, 4);
	}

	var previousFrameTime:Int = 0;
	var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;

	private function getKey(charCode:Int):String
	{
		for (key => value in FlxKey.fromStringMap)
		{
			if (charCode == value)
				return key;
		}
		return null;
	}

	private function releaseInput(evt:KeyboardEvent):Void
	{
		@:privateAccess
		var key = FlxKey.toStringMap.get(evt.keyCode);

		var binds:Array<String> = [
			FlxG.save.data.leftBind,
			FlxG.save.data.downBind,
			FlxG.save.data.upBind,
			FlxG.save.data.rightBind
		];

		var data = -1;

		switch (evt.keyCode) // arrow keys
		{
			case 37:
				data = 0;
			case 40:
				data = 1;
			case 38:
				data = 2;
			case 39:
				data = 3;
		}

		for (i in 0...binds.length) // binds
		{
			if (binds[i].toLowerCase() == key.toLowerCase())
				data = i;
		}

		if (data == -1)
			return;

		keys[data] = false;
	}

	public var closestNotes:Array<Note> = [];

	private function handleInput(evt:KeyboardEvent):Void
	{
		var canMiss:Bool = !FlxG.save.data.ghost;

		if (PlayStateChangeables.botPlay || loadRep || paused)
			return;

		@:privateAccess
		var key = FlxKey.toStringMap.get(evt.keyCode);

		var binds:Array<String> = [
			FlxG.save.data.leftBind,
			FlxG.save.data.downBind,
			FlxG.save.data.upBind,
			FlxG.save.data.rightBind
		];

		var data = -1;
		var notesStopped:Bool = false;

		switch (evt.keyCode) // arrow keys
		{
			case 37:
				data = 0;
			case 40:
				data = 1;
			case 38:
				data = 2;
			case 39:
				data = 3;
		}

		var ana = new Ana(Conductor.songPosition, null, false, "miss", data);

		for (i in 0...binds.length) // binds
		{
			if (binds[i].toLowerCase() == key.toLowerCase())
				data = i;
		}
		if (data == -1)
		{
			return;
		}
		if (keys[data])
		{
			return;
		}

		keys[data] = true;

		closestNotes = [];

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit)
			{
				closestNotes.push(daNote);
				canMiss = true;
			}
		});

		var dataNotes = [];
		var coolNote = null;

		closestNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
		for (i in closestNotes)
			if (i.noteData == data && !i.isSustainNote)
				dataNotes.push(i);

		if (dataNotes.length > 0)
		{
			for (i in 0...dataNotes.length)
			{
				var note = dataNotes[i];

				for (i in dataNotes)
				{
					coolNote = i;
					break;

					if (!note.isSustainNote && ((note.strumTime - coolNote.strumTime) < 2) && note.noteData == data)
					{
						note.kill();
						notes.remove(note, true);
						note.destroy();
					}
					else
						notesStopped = true;
				}
				
				if (!notesStopped)
				{
					if (!PlayStateChangeables.opponentMode)
						boyfriend.holdTimer = 0;
					else
						dad.holdTimer = 0;
					goodNoteHit(coolNote);
					var noteDiff:Float = -(coolNote.strumTime - Conductor.songPosition);
					ana.hit = true;
					ana.hitJudge = Ratings.judgeNote(noteDiff);
					ana.nearestNote = [coolNote.strumTime, coolNote.noteData, coolNote.sustainLength];
				}
			}
		}
		else
		{
			#if FEATURE_HSCRIPT
			scripts.executeAllFunc("ghostTap", [key]);
			#end
			
			if (canMiss){
				noteMissPress(data);
			}
		}
	}
	//sadly stolen from Psych. Im sorry :(((
	function noteMissPress(direction:Int = 1):Void
	{
		if (FlxG.save.data.ghost)
			return;

		if (!boyfriend.stunned)
		{
			if (!PlayStateChangeables.opponentMode)
				health -= 0.15 * PlayStateChangeables.healthLoss;
			else
				health += 0.15 * PlayStateChangeables.healthLoss;
			if (combo > 5 && gf != null && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
			}
			combo = 0;
			
			songScore -= 10;
			var ana = new Ana(Conductor.songPosition, null, false, "miss", direction);
			ana.hit = false;
			ana.hitJudge = "shit";
			ana.nearestNote = [];
			if (!endingSong)
			{
				misses++;
			}
			totalPlayed++;

			if (FlxG.save.data.missSounds)
			{
				FlxG.sound.play(Paths.soundRandom('missnote' + altSuffix, 1, 3), FlxG.random.float(0.1, 0.2));
			}
			if (!FlxG.save.data.optimize)
			{
				boyfriend.playAnim('sing' + dataSuffix[direction] + 'miss', true);
			}
			vocals.volume = 0;
			updateAccuracy();
		}
	}

	public var songStarted = false;

	public var doAnything = false;

	public var bar:FlxSprite;

	function startSong():Void
	{
		startingSong = false;
		songStarted = true;
		previousFrameTime = FlxG.game.ticks;
		lastReportedPlayheadPosition = 0;

		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("startSong")))
			return;
		#end
		
		if (isSM)
			FlxG.sound.music.play();
		else{
			inst.play();
			vocals.play();
		}		

		
		if (!FlxG.save.data.optimize)
		{
			if (allowedToHeadbang)
				gf.dance();
			if (idleToBeat && !boyfriend.animation.curAnim.name.startsWith("sing"))
				boyfriend.dance(forcedToIdle);
			if (idleToBeat && !dad.animation.curAnim.name.startsWith("sing") && !PlayStateChangeables.opponentMode)
				dad.dance(forcedToIdle);

			// Song check real quick
			switch (SONG.songId)
			{
				case 'bopeebo' | 'philly' | 'blammed' | 'cocoa' | 'eggnog':
					allowedToCheer = true;
				default:
					allowedToCheer = false;
			}
		}
		
		switch (curSong)
		{
			case 'Bopeebo' | 'Philly Nice' | 'Blammed' | 'Cocoa' | 'Eggnog':
				allowedToCheer = true;
			default:
				allowedToCheer = false;
		}

		#if FEATURE_LUAMODCHART
		if (executeModchart)
			luaModchart.executeState("songStart", [null]);
		#end

		#if FEATURE_DISCORD
		DiscordClient.changePresence(detailsText
			+ " "
			+ SONG.song
			+ " ("
			+ storyDifficultyText
			+ ") "
			+ Ratings.GenerateLetterRank(accuracy),
			"\nAcc: "
			+ HelperFunctions.truncateFloat(accuracy, 2)
			+ "% | Score: "
			+ songScore
			+ " | Misses: "
			+ misses, iconRPC);
		#end

		recalculateAllSectionTimes();
		
		#if FEATURE_STEPMANIA
		if (isSM)
			songLength = ((FlxG.sound.music.length / songMultiplier) / 1000);
		else
			songLength = ((inst.length / songMultiplier) / 1000);
		#else
		songLength = ((inst.length / songMultiplier) / 1000);
		#end

		songPosBG = new FlxSprite(0, FlxG.height - 710).loadGraphic(Paths.image2('healthBar', 'shared'));

		if (PlayStateChangeables.useDownscroll)
			songPosBG.y = FlxG.height - 37;

		songPosBG.screenCenter(X);
		songPosBG.scrollFactor.set();
		songPosBar = new FlxBar(640 - (Std.int(songPosBG.width - 100) / 2), songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 100),
			Std.int(songPosBG.height + 6), this, 'songPositionBar', 0, songLength);
		songPosBar.alpha = 0;
		songPosBar.scrollFactor.set();
		songPosBar.createFilledBar(FlxColor.BLACK, dad.barColor);
		songPosBar.numDivisions = 150;
		add(songPosBar);

		bar = new FlxSprite(songPosBar.x, songPosBar.y).makeGraphic(Math.floor(songPosBar.width), Math.floor(songPosBar.height), FlxColor.TRANSPARENT);
		bar.alpha = 0;
		add(bar);

		FlxSpriteUtil.drawRect(bar, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT,
			{thickness: 4, color: (!FlxG.save.data.background ? FlxColor.WHITE : FlxColor.BLACK)});

		songPosBG.width = songPosBar.width;

		songName = new FlxText(songPosBG.x + (songPosBG.width / 2) - (SONG.songName.length * 5), songPosBG.y - 15, 0, SONG.song, 16);
		songName.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songName.scrollFactor.set();

		songName.text = SONG.song + ' (' + FlxStringUtil.formatTime(songLength, false) + ')';
		songName.y = songPosBG.y + (songPosBG.height / 3);
		songName.alpha = 0;
		songName.visible = FlxG.save.data.songPosition;
		add(songName);

		songPosBG.cameras = [camHUD];
		bar.cameras = [camHUD];
		songPosBar.cameras = [camHUD];
		songName.cameras = [camHUD];

		songName.screenCenter(X);

		songName.visible = FlxG.save.data.songPosition;
		songPosBar.visible = FlxG.save.data.songPosition;
		bar.visible = FlxG.save.data.songPosition;

		if (FlxG.save.data.songPosition)
		{
			createTween(songName, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
			createTween(songPosBar, {alpha: 0.85}, 0.5, {ease: FlxEase.circOut});
			createTween(bar, {alpha: 1}, 0.5, {ease: FlxEase.circOut});
		}

		if (inst != null)
			inst.time = startTime;
		if (vocals != null)
			vocals.time = startTime;
		Conductor.songPosition = startTime;
		startTime = 0;

		for (i in 0...unspawnNotes.length)
			if (unspawnNotes[i].strumTime < startTime)
				unspawnNotes.remove(unspawnNotes[i]);

		if (needSkip)
		{
			skipActive = true;
			skipText = new FlxText(healthBarBG.x + 80, 500, 500);
			skipText.text = "Press Space to Skip Intro";
			skipText.size = 30;
			skipText.color = FlxColor.WHITE;
			skipText.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 2, 1);
			skipText.cameras = [camHUD];
			skipText.alpha = 0;
			createTween(skipText, {alpha: 1}, 0.2);
			add(skipText);
		}
	}

	var debugNum:Int = 0;

	public function generateSong(dataPath:String):Void
	{
		notes = new FlxTypedGroup<Note>();
		add(notes);

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		#if FEATURE_HSCRIPT
		scripts.setAll("bpm", Conductor.bpm);
		#end

		if (!paused)
		{
			#if FEATURE_STEPMANIA
			if (!isStoryMode && isSM)
			{
				var bytes = File.getBytes(pathToSm + "/" + sm.header.MUSIC);
				var sound = new Sound();
				sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
				FlxG.sound.playMusic(sound);
			}
			#end
		}

		curSong = songData.songId;

		#if FEATURE_STEPMANIA
		if (SONG.needsVoices && !isSM)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.songId));
		else
			vocals = new FlxSound();
		#else
		if (SONG.needsVoices)
			vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.songId));
		else
			vocals = new FlxSound();
		#end

		inst = new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.songId));
		FlxG.sound.list.add(inst);

		FlxG.sound.list.add(vocals);

		inst.pause();

		if(isSM)
			FlxG.sound.music.pause();

		addSongTiming();

		if (PlayStateChangeables.skillIssue)
		{
			var redVignette:FlxSprite = new FlxSprite().loadGraphic(Paths.image2('nomisses_vignette', 'shared'));
			redVignette.screenCenter();
			redVignette.cameras = [camHUD];
			add(redVignette);
		}
		
		Conductor.crochet = ((60 / (SONG.bpm) * 1000));
		Conductor.stepCrochet = Conductor.crochet / 4;
		
		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0;

		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0] / songMultiplier;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = songNotes[5];

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3 && !PlayStateChangeables.opponentMode)
					gottaHitNote = !section.mustHitSection;
				else if (songNotes[1] <= 3 && PlayStateChangeables.opponentMode)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote:Note;

				if (gottaHitNote)
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false, true, null, songNotes[4], daNoteType);
				else
					swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false, false, null, songNotes[4], daNoteType);

				if ((!gottaHitNote && FlxG.save.data.middleScroll && FlxG.save.data.optimize && !PlayStateChangeables.opponentMode
					&& !PlayStateChangeables.healthDrain)
					|| (!gottaHitNote && FlxG.save.data.middleScroll && FlxG.save.data.optimize && PlayStateChangeables.opponentMode
						&& !PlayStateChangeables.healthDrain))
					continue;

				if (PlayStateChangeables.holds)
				{
					swagNote.sustainLength = TimingStruct.getTimeFromBeat((TimingStruct.getBeatFromTime(songNotes[2] / songMultiplier)));
				}
				else
				{
					swagNote.sustainLength = 0;
				}
				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				swagNote.isAlt = songNotes[3]
					|| ((section.altAnim || section.CPUAltAnim) && !gottaHitNote)
					|| (section.playerAltAnim && gottaHitNote)
					|| (PlayStateChangeables.opponentMode && gottaHitNote && (section.altAnim || section.CPUAltAnim))
					|| (PlayStateChangeables.opponentMode && !gottaHitNote && section.playerAltAnim);

				if (susLength > 0)
					swagNote.isParent = true;

				var type = 0;

				for (susNote in 0...Math.floor(susLength))
				{
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

					var sustainNote:Note;

					if (gottaHitNote)
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, false,
							true, null, songNotes[4], daNoteType);
					else
						sustainNote = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + Conductor.stepCrochet, daNoteData, oldNote, true, false,
							false, null, songNotes[4], daNoteType);
					sustainNote.scrollFactor.set();
					unspawnNotes.push(sustainNote);
					sustainNote.isAlt = songNotes[3]
							|| ((section.altAnim || section.CPUAltAnim) && !gottaHitNote)
							|| (section.playerAltAnim && gottaHitNote)
							|| (PlayStateChangeables.opponentMode && gottaHitNote && (section.altAnim || section.CPUAltAnim))
							|| (PlayStateChangeables.opponentMode && !gottaHitNote && section.playerAltAnim);

					sustainNote.mustPress = gottaHitNote;

					if (sustainNote.mustPress)
					{
						sustainNote.x += FlxG.width / 3; // general offset
					}

					sustainNote.parent = swagNote;
					swagNote.children.push(sustainNote);
					sustainNote.spotInLine = type;
					type++;
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 3; // general offset
				}
			}
			daBeats += 1;
		}

		unspawnNotes.sort(sortByShit);

		generatedMusic = true;
		if (FlxG.save.data.gen)
		{
			Debug.logInfo('Generated Chart');
		}
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function spawnNoteSplashOnNote(note:Note)
	{
		if (note != null)
		{
			var strum = playerStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash(strum.x, strum.y, note.noteData);
			}
		}
	}

	function spawnNoteSplashOnNoteDad(note:Note)
	{
		if (note != null)
		{
			var strum = cpuStrums.members[note.noteData];
			if (strum != null)
			{
				spawnNoteSplash2(strum.x, strum.y, note.noteData);
			}
		}
	}
	 
	//I wanna softcode but I suck ass :(((
	var name:String;

	public function NoteSplashesSpawn(daNote:Note, ?name:String = 'Default')
	{
		this.name = name;
		var sploosh:FlxSprite = new FlxSprite(playerStrums.members[daNote.noteData].x + 10.5, playerStrums.members[daNote.noteData].y - 20);
		sploosh.antialiasing = FlxG.save.data.antialiasing;
		switch (SONG.noteStyle){
			case 'pixel':
					var tex:flixel.graphics.frames.FlxAtlasFrames = Paths.getSparrowAtlas('weeb/pixelUI/noteSplashes-pixels', 'week6');
					sploosh.frames = tex;
					sploosh.animation.addByPrefix('splash 0 0', 'note splash 1 purple', 24, false);
					sploosh.animation.addByPrefix('splash 0 1', 'note splash 1  blue', 24, false);
					sploosh.animation.addByPrefix('splash 0 2', 'note splash 1 green', 24, false);
					sploosh.animation.addByPrefix('splash 0 3', 'note splash 1 red', 24, false);
					sploosh.animation.addByPrefix('splash 1 0', 'note splash 2 purple', 24, false);
					sploosh.animation.addByPrefix('splash 1 1', 'note splash 2 blue', 24, false);
					sploosh.animation.addByPrefix('splash 1 2', 'note splash 2 green', 24, false);
					sploosh.animation.addByPrefix('splash 1 3', 'note splash 2 red', 24, false);

					add(sploosh);
					sploosh.cameras = [camStrums];

					if (!FlxG.save.data.stepMania)
						sploosh.animation.play('splash ' + FlxG.random.int(0, 1) + " " + daNote.noteData);
					else
						sploosh.animation.play('splash ' + FlxG.random.int(0, 1) + " " + daNote.originColor);
					sploosh.alpha = 0.6;
					sploosh.offset.x += 90;
					sploosh.offset.y += 80;
					sploosh.animation.finishCallback = function(name) sploosh.kill();

					sploosh.update(0);
				default:
				switch(FlxG.save.data.notesplash){
					case 0:
						name = 'Default';
					case 1:
						name = 'Week7';
				}

			var rawJson = Paths.loadData('images/splashes/' + name);
			var data:SplashData = cast rawJson;
			
			if (FlxG.save.data.notesplashes)
			{
				sploosh.frames = PlayState.notesplashSprite;
				sploosh.animation.addByPrefix('splash 0 0', 'note splash 1 purple', data.fps, false);
				sploosh.animation.addByPrefix('splash 0 1', 'note splash 1 blue', data.fps, false);
				sploosh.animation.addByPrefix('splash 0 2', 'note splash 1 green', data.fps, false);
				sploosh.animation.addByPrefix('splash 0 3', 'note splash 1 red', data.fps, false);
				add(sploosh);
				sploosh.cameras = [camStrums];
				if (!FlxG.save.data.stepMania)
					sploosh.animation.play('splash 0 '+ daNote.noteData);
				else
					sploosh.animation.play('splash 0 ' + daNote.originColor);
				sploosh.alpha = data.alpha;
				sploosh.offset.x += data.xOffset;
				sploosh.offset.y += data.yOffset; // lets stick to eight not nine
				sploosh.animation.finishCallback = function(name) sploosh.kill();
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data);
		grpNoteSplashes.add(splash);
	}

	public function spawnNoteSplash2(x:Float, y:Float, data:Int)
	{
		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash2(x, y, data);
		grpNoteSplashes.add(splash);
	}

	private function generateStaticArrows(player:Int, ?tween:Bool = true):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StaticArrow = new StaticArrow(-10, strumLine.y);

			var noteTypeCheck:String = 'normal';

			//if (PlayStateChangeables.Optimize && player == 0)
				//continue;

			if (SONG.noteStyle == null)
			{
				switch (storyWeek)
				{
					case 6:
						noteTypeCheck = 'pixel';
				}
			}
			else
			{
				noteTypeCheck = SONG.noteStyle;
			}

			switch (noteTypeCheck)
			{
				case 'pixel':
					#if html5
					babyArrow.loadGraphic(Paths.image('noteskins/Arrows-pixel', 'shared'), true, 12, 17);
					#else
					babyArrow.loadGraphic(noteskinPixelSprite, true, 17, 17);
					#end

					babyArrow.animation.add('green', [6]);
					babyArrow.animation.add('red', [7]);
					babyArrow.animation.add('blue', [5]);
					babyArrow.animation.add('purple', [4]);

					babyArrow.setGraphicSize(Std.int(babyArrow.width * CoolUtil.daPixelZoom));
					babyArrow.updateHitbox();
					babyArrow.antialiasing = false;

					babyArrow.x += Note.swagWidth * i;
					babyArrow.animation.add('static', [i]);
					babyArrow.animation.add('pressed', [4 + i, 8 + i], 12, false);
					babyArrow.animation.add('confirm', [12 + i, 16 + i], 12, false);

					for (j in 0...4)
					{
						babyArrow.animation.add('dirCon' + j, [12 + j, 16 + j], 12, false);
					}

				default:
					#if html5
					babyArrow.frames = Paths.getSparrowAtlas('noteskins/Arrows', 'shared');
					#else
					if (!PlayStateChangeables.opponentMode){
						if (player == 0)
							babyArrow.frames = cpuNoteskinSprite;
						else
							babyArrow.frames = noteskinSprite;
					}
					else{
						if (player == 1)
							babyArrow.frames = cpuNoteskinSprite;
						else
							babyArrow.frames = noteskinSprite;
					}

					#end
					for (j in 0...4)
					{
						babyArrow.animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
						babyArrow.animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
					}

					var lowerDir:String = dataSuffix[i].toLowerCase();

					babyArrow.animation.addByPrefix('static', 'arrow' + dataSuffix[i]);
					babyArrow.animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
					babyArrow.animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

					babyArrow.animation.addByPrefix('green', 'arrow static instance 1');
					babyArrow.animation.addByPrefix('blue', 'arrow static instance 2');
					babyArrow.animation.addByPrefix('purple', 'arrow static instance 3');
					babyArrow.animation.addByPrefix('red', 'arrow static instance 4');

					babyArrow.animation.addByPrefix('static', 'arrow static instance 1');
					babyArrow.animation.addByPrefix('pressed', 'left press instance 1', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'left confirm instance 1', 24, false);

					babyArrow.animation.addByPrefix('static', 'arrow static instance 2');
					babyArrow.animation.addByPrefix('pressed', 'down press instance 1', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'down confirm instance 1', 24, false);

					babyArrow.animation.addByPrefix('static', 'arrow static instance 4');
					babyArrow.animation.addByPrefix('pressed', 'up press instance 1', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'up confirm instance 1', 24, false);

					babyArrow.animation.addByPrefix('static', 'arrow static instance 3');
					babyArrow.animation.addByPrefix('pressed', 'right press instance 1', 24, false);
					babyArrow.animation.addByPrefix('confirm', 'right confirm instance 1', 24, false);

					babyArrow.x += Note.swagWidth * i;

					babyArrow.antialiasing = FlxG.save.data.antialiasing;
					babyArrow.setGraphicSize(Std.int(babyArrow.width * 0.7));
			}

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (tween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				createTween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
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
						babyArrow.x -= 275 / Math.pow(FlxG.save.data.zoom, 3);
				}
				else
				{
					babyArrow.x += 311.5;
					if (player == 1)
						babyArrow.x += 275 / Math.pow(FlxG.save.data.zoom, 3);
				}
			}

			strumLineNotes.add(babyArrow);
		}
		arrowsGenerated = true;
	}

	private function appearStaticArrows():Void
	{
		var index = 0;
		strumLineNotes.forEach(function(babyArrow:FlxSprite)
		{
			if (isStoryMode && !FlxG.save.data.middleScroll || (PlayStateChangeables.Optimize))
				babyArrow.visible = true;
			if (index > 3 && FlxG.save.data.middleScroll)
				babyArrow.visible = true;
			index++;
		});
	}

	function tweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			#if FEATURE_STEPMANIA
			if (isSM){
				if (FlxG.sound.music.playing)
					FlxG.sound.music.pause();
			}
			else{
				if (inst.playing)
					inst.pause();
				if (vocals != null)
					if (vocals.playing)
						vocals.pause();
			}
			#else
			if (inst.playing)
				inst.pause();

			if (vocals != null)
				if (vocals.playing)
					vocals.pause();
			#end

			#if FEATURE_DISCORD
			DiscordClient.changePresence("PAUSED on "
				+ SONG.song
				+ " ("
				+ storyDifficultyText
				+ ") "
				+ Ratings.GenerateLetterRank(accuracy),
				"\nAcc: "
				+ HelperFunctions.truncateFloat(accuracy, 2)
				+ "% | Score: "
				+ songScore
				+ " | Misses: "
				+ misses, iconRPC);
			#end
			if (!startTimer.finished)
				startTimer.active = false;
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (PauseSubState.goToOptions)
		{
			if (PauseSubState.goBack)
			{
				if (FlxG.save.data.gen)
					Debug.logTrace("Paused.");

				PauseSubState.goToOptions = false;
				PauseSubState.goBack = false;
				openSubState(new PauseSubState());
			}
			else
				openSubState(new OptionsMenu(true));
		}
		else if (paused)
		{
			#if FEATURE_HSCRIPT
			if (!ScriptUtil.hasPause(scripts.executeAllFunc("resume")))
			{
				if (inst != null && !startingSong)
				{
					resyncVocals();
				}

				if (!startTimer.finished)
					startTimer.active = true;
				paused = false;

				#if FEATURE_DISCORD
				if (startTimer.finished)
				{
					DiscordClient.changePresence(detailsText
						+ " "
						+ SONG.song
						+ " ("
						+ storyDifficultyText
						+ ") "
						+ Ratings.GenerateLetterRank(accuracy),
						"\nAcc: "
						+ HelperFunctions.truncateFloat(accuracy, 2)
						+ "% | Score: "
						+ songScore
						+ " | Misses: "
						+ misses, iconRPC, true,
						songLength
						- Conductor.songPosition);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
				}
				#end
			}	
			#else
			if (inst != null && !startingSong)
				{
					resyncVocals();
				}

				if (!startTimer.finished)
					startTimer.active = true;
				paused = false;

				#if FEATURE_DISCORD
				if (startTimer.finished)
				{
					DiscordClient.changePresence(detailsText
						+ " "
						+ SONG.song
						+ " ("
						+ storyDifficultyText
						+ ") "
						+ Ratings.GenerateLetterRank(accuracy),
						"\nAcc: "
						+ HelperFunctions.truncateFloat(accuracy, 2)
						+ "% | Score: "
						+ songScore
						+ " | Misses: "
						+ misses, iconRPC, true,
						songLength
						- Conductor.songPosition);
				}
				else
				{
					DiscordClient.changePresence(detailsText, SONG.song + " (" + storyDifficultyText + ") " + Ratings.GenerateLetterRank(accuracy), iconRPC);
				}
				#end
				#end

		}

		super.closeSubState();
	}

	function resyncVocals():Void
	{
		if (endingSong)
			return;
		if (isSM){
			FlxG.sound.music.pause();
			FlxG.sound.music.resume();
			FlxG.sound.music.time = Conductor.songPosition * songMultiplier;
		}	
		else
		{
			vocals.pause();
			inst.pause();

			inst.resume();
			inst.time = Conductor.songPosition * songMultiplier;
			vocals.time = inst.time;
			vocals.resume();
		}

		#if cpp
		if (inst.playing)
			@:privateAccess
		{
			#if (lime >= "8.0.0")
			inst._channel.__source.__backend.setPitch(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.setPitch(songMultiplier);
			#else
			lime.media.openal.AL.sourcef(inst._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			#end
		}
		#elseif html5
		if (inst.playing)
			@:privateAccess
		{
			#if lime_howlerjs
			#if (lime >= "8.0.0")
			inst._channel.__source.__backend.setPitch(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.setPitch(songMultiplier);
			#else
			inst._channel.__source.__backend.parent.buffer.__srcHowl.rate(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.parent.buffer.__srcHowl.rate(songMultiplier);
			#end
			#end
		}
		#end
	}

	public var paused:Bool = false;

	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var nps:Int = 0;
	var maxNPS:Int = 0;

	public var stopUpdate = false;

	public var currentBPM = 0;

	public var updateFrame = 0;

	public var pastScrollChanges:Array<Song.Event> = [];

	var currentLuaIndex = 0;

	override public function update(elapsed:Float)
	{
		#if FEATURE_HSCRIPT
		if (scripts != null)
		{
			scripts.update(elapsed);
		}
		#end
		#if !debug
		perfectMode = false;
		#end
		if (!PlayStateChangeables.Optimize)
			Stage.update(elapsed);

		if (!addedBotplay && FlxG.save.data.botplay)
		{
			PlayStateChangeables.botPlay = true;
			addedBotplay = true;
			add(botPlayState);
		}

		if (FlxG.save.data.borderless)
		{
			FlxG.stage.window.borderless = true;
		}
		else
		{
			FlxG.stage.window.borderless = false;
		}

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 14000 * songMultiplier)
			{
				var dunceNote:Note = unspawnNotes[0];
				#if FEATURE_HSCRIPT
				if (!ScriptUtil.hasPause(scripts.executeAllFunc("spawnNote", [dunceNote])))
				{
					notes.add(dunceNote);
				}
				#else
				notes.add(dunceNote);
				#end

				#if FEATURE_LUAMODCHART
				if (executeModchart)
				{
					new LuaNote(dunceNote, currentLuaIndex);
					dunceNote.luaID = currentLuaIndex;
				}
				#end

				if (executeModchart)
				{
					#if FEATURE_LUAMODCHART
					if (!dunceNote.isSustainNote)
						dunceNote.cameras = [camNotes];
					else
						dunceNote.cameras = [camSustains];
					#end
				}
				else
				{
					dunceNote.cameras = [camHUD];
				}

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
				currentLuaIndex++;
			}
		}

		if (!paused)
		{
			tweenManager.update(elapsed);
			timerManager.update(elapsed);
		}

		if (generatedMusic && !paused && songStarted && songMultiplier < 1)
		{
			if (Conductor.songPosition * songMultiplier >= inst.time + 25 || Conductor.songPosition * songMultiplier <= inst.time - 25)
			{
				resyncVocals();
			}
		}

		if (nps >= 0)
			updateScoreText();

		#if cpp
		if (inst.playing)
			@:privateAccess
		{
			#if (lime >= "8.0.0")
			inst._channel.__source.__backend.setPitch(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.setPitch(songMultiplier);
			#else
			lime.media.openal.AL.sourcef(inst._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			if (vocals.playing)
				lime.media.openal.AL.sourcef(vocals._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, songMultiplier);
			#end
		}
		#elseif html5
		if (inst.playing)
			@:privateAccess
		{
			#if lime_howlerjs
			#if (lime >= "8.0.0")
			inst._channel.__source.__backend.setPitch(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.setPitch(songMultiplier);
			#else
			inst._channel.__source.__backend.parent.buffer.__srcHowl.rate(songMultiplier);
			if (vocals.playing)
				vocals._channel.__source.__backend.parent.buffer.__srcHowl.rate(songMultiplier);
			#end
			#end
		}
		#end

		if (generatedMusic)
		{
			if (songStarted && !endingSong && isSM)
			{
				if ((FlxG.sound.music.length / songMultiplier) - Conductor.songPosition <= 0)
				{
					if (FlxG.save.data.gen)
						Debug.logTrace("we're fuckin ending the song ");
					if (FlxG.save.data.songPosition)
					{
						FlxTween.tween(judgementCounter, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(kadeEngineWatermark, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(songName, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(songPosBar, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(bar, {alpha: 0}, 1, {ease: FlxEase.circIn});
					}
					endingSong = true;
					endSong();
				}
			}
			else if (songStarted && !endingSong)
			{
				if ((inst.length / songMultiplier) - Conductor.songPosition <= 0)
				{
					if (FlxG.save.data.gen)
						Debug.logTrace("we're fuckin ending the song ");
					if (FlxG.save.data.songPosition)
					{
						FlxTween.tween(judgementCounter, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(scoreTxt, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(kadeEngineWatermark, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(songName, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(songPosBar, {alpha: 0}, 1, {ease: FlxEase.circIn});
						FlxTween.tween(bar, {alpha: 0}, 1, {ease: FlxEase.circIn});
					}
					endingSong = true;
					endSong();
				}
			}
		}

		if (inst.playing)
		{
			var timingSeg = TimingStruct.getTimingAtBeat(curDecimalBeat);

			if (timingSeg != null)
			{
				var timingSegBpm = timingSeg.bpm;

				if (timingSegBpm != Conductor.bpm)
				{
					Conductor.changeBPM(timingSegBpm, false);
					Conductor.crochet = ((60 / (timingSegBpm) * 1000)) / songMultiplier;
					Conductor.stepCrochet = Conductor.crochet / 4;
				}
			}

			var newScroll = 1.0;

			for (i in SONG.eventObjects)
			{
				switch (i.type)
				{
					case "Scroll Speed Change":
						if (i.position <= curDecimalBeat && !pastScrollChanges.contains(i))
						{
							pastScrollChanges.push(i);
							newScroll = i.value;
						}
				}
			}

			if (newScroll != 0)
				PlayStateChangeables.scrollSpeed *= newScroll;
		}

		if (PlayStateChangeables.botPlay && FlxG.keys.justPressed.ONE)
			camHUD.visible = !camHUD.visible;

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null && songStarted)
		{
			luaModchart.setVar('songPos', Conductor.songPosition);
			luaModchart.setVar('hudZoom', camHUD.zoom);
			luaModchart.setVar('curBeat', HelperFunctions.truncateFloat(curDecimalBeat, 3));
			luaModchart.setVar('cameraZoom', FlxG.camera.zoom);
			luaModchart.executeState('update', [elapsed]);

			for (key => value in luaModchart.luaWiggles)
			{
				value.update(elapsed);
			}

			PlayStateChangeables.useDownscroll = luaModchart.getVar("downscroll", "bool");

			PlayStateChangeables.middleScroll = luaModchart.getVar("middleScroll", "bool");

			/*for (i in 0...strumLineNotes.length) {
				var member = strumLineNotes.members[i];
				member.x = luaModchart.getVar("strum" + i + "X", "float");
				member.y = luaModchart.getVar("strum" + i + "Y", "float");
				member.angle = luaModchart.getVar("strum" + i + "Angle", "float");
			}*/

			FlxG.camera.angle = luaModchart.getVar('cameraAngle', 'float');
			camHUD.angle = luaModchart.getVar('camHudAngle', 'float');

			if (luaModchart.getVar("showOnlyStrums", 'bool'))
			{
				healthBarBG.visible = false;
				kadeEngineWatermark.visible = false;
				healthBar.visible = false;
				iconP1.visible = false;
				iconP2.visible = false;
				scoreTxt.visible = false;
			}
			else
			{
				healthBarBG.visible = true;
				kadeEngineWatermark.visible = true;
				healthBar.visible = true;
				iconP1.visible = true;
				iconP2.visible = true;
				scoreTxt.visible = true;
			}

			var p1 = luaModchart.getVar("strumLine1Visible", 'bool');
			var p2 = luaModchart.getVar("strumLine2Visible", 'bool');

			for (i in 0...4)
			{
				strumLineNotes.members[i].visible = p1;
				if (i <= playerStrums.length)
					playerStrums.members[i].visible = p2;
			}

			camNotes.zoom = camHUD.zoom;
			camNotes.x = camHUD.x;
			camNotes.y = camHUD.y;
			camNotes.angle = camHUD.angle;
			camSustains.zoom = camHUD.zoom;
			camSustains.x = camHUD.x;
			camSustains.y = camHUD.y;
			camSustains.angle = camHUD.angle;
		}
		#end
		
		{
			var balls = notesHitArray.length - 1;
			while (balls >= 0)
			{
				var cock:Date = notesHitArray[balls];
				if (cock != null && cock.getTime() + 1000 < Date.now().getTime())
					notesHitArray.remove(cock);
				else
					balls = 0;
				balls--;
			}
			nps = notesHitArray.length;
			if (nps > maxNPS)
				maxNPS = nps;
		}

		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

		scoreTxt.screenCenter(X);

		var pauseBind = FlxKey.fromString(FlxG.save.data.pauseBind);
		var gppauseBind = FlxKey.fromString(FlxG.save.data.gppauseBind);

		if ((FlxG.keys.anyJustPressed([pauseBind])) && startedCountdown && canPause && !cannotDie)
		{
			persistentUpdate = false;
			persistentDraw = true;
			paused = true;

			// 1 / 1000000 chance for Gitaroo Man easter egg
			// happened to me way to frequently. Annoying
			if (FlxG.random.bool(0.0001))
			{
				FlxG.switchState(new GitarooPause());
			}
			else
				openSubState(new PauseSubState());
		}

		if (FlxG.keys.justPressed.FIVE && songStarted)
		{
			songMultiplier = 1;
			cannotDie = true;
			MusicBeatState.switchState(new WaveformTestState());
			PlayState.stageTesting = false;
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
		}

		if (FlxG.keys.justPressed.SEVEN && songStarted)
		{
			songMultiplier = 1;
			cannotDie = true;
			
			MusicBeatState.switchState(new ChartingState());
			PlayState.stageTesting = false;
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
		}

		var iconLerp = CoolUtil.boundTo(1 - (elapsed * 35 * songMultiplier), 0, 1);

		iconP1.setGraphicSize(Std.int(FlxMath.lerp(150, iconP1.width, iconLerp)));
		iconP2.setGraphicSize(Std.int(FlxMath.lerp(150, iconP2.width, iconLerp)));
		iconP1.updateHitbox();
		iconP2.updateHitbox();
		if (health >= 2 && !PlayStateChangeables.opponentMode)
			health = 2;

		var iconOffset:Float = 26;
		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (health > 2)
			health = 2;
		if (healthBar.percent < 20)
			iconP1.animation.curAnim.curFrame = 1;
		else
			iconP1.animation.curAnim.curFrame = 0;

		if (healthBar.percent > 80)
			iconP2.animation.curAnim.curFrame = 1;
		else
			iconP2.animation.curAnim.curFrame = 0;

		/* if (FlxG.keys.justPressed.NINE)
			FlxG.switchState(new Charting()); */

		if (FlxG.keys.justPressed.SIX)
		{
			LoadingState.loadAndSwitchState(new AnimationDebug(dad.curCharacter));
			PlayState.stageTesting = false;
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
		}

		if (!PlayStateChangeables.Optimize)
			if (FlxG.keys.justPressed.EIGHT && songStarted)
			{
				paused = true;
				new FlxTimer().start(0.3, function(tmr:FlxTimer)
				{
					for (bg in Stage.toAdd)
					{
						remove(bg);
					}
					for (array in Stage.layInFront)
					{
						for (bg in array)
							remove(bg);
					}
					for (group in Stage.swagGroup)
					{
						remove(group);
					}
					remove(boyfriend);
					remove(dad);
					remove(gf);
				});
				LoadingState.loadAndSwitchState(new StageDebugState(Stage.curStage, gf.curCharacter, boyfriend.curCharacter, dad.curCharacter));
				FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
				FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
				{
					luaModchart.die();
					luaModchart = null;
				}
				#end
			}

		if (FlxG.keys.justPressed.NUMPADSEVEN)
		{
			MusicBeatState.switchState(new AnimationDebug(boyfriend.curCharacter));
			PlayState.stageTesting = false;
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
			{
				luaModchart.die();
				luaModchart = null;
			}
			#end
		}

		if (FlxG.keys.justPressed.TWO && songStarted)
		{
			if (!usedTimeTravel && Conductor.songPosition + 10000 < inst.length)
			{
				usedTimeTravel = true;
				inst.pause();
				vocals.pause();
				Conductor.songPosition += 10000;
				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.strumTime - 500 < Conductor.songPosition)
					{
						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});

				inst.time = Conductor.songPosition;
				inst.resume();
				vocals.time = Conductor.songPosition;
				vocals.resume();
				new FlxTimer().start(0.5, function(tmr:FlxTimer)
				{
					usedTimeTravel = false;
				});
			}
		}

		if (skipActive && Conductor.songPosition >= skipTo)
		{
			remove(skipText);
			skipActive = false;
		}

		if (FlxG.keys.justPressed.SPACE && skipActive)
		{
			if (isSM){
				FlxG.sound.music.pause();
				Conductor.songPosition = skipTo;
				Conductor.rawPosition = skipTo;
				FlxG.sound.music.time = Conductor.songPosition;
				FlxG.sound.music.resume();
			}
			else{
				inst.pause();
				vocals.pause();
				Conductor.songPosition = skipTo;
				Conductor.rawPosition = skipTo;
				inst.time = Conductor.songPosition;
				inst.resume();
				vocals.time = Conductor.songPosition;
				vocals.resume();
			}
			FlxTween.tween(skipText, {alpha: 0}, 0.2, {
				onComplete: function(tw)
				{
					remove(skipText);
				}
			});
			skipActive = false;
		}

		if (startingSong)
		{
			if (startedCountdown)
			{
				Conductor.songPosition += FlxG.elapsed * 1000;
				Conductor.rawPosition = Conductor.songPosition;
				if (Conductor.songPosition >= 0)
				{
					startSong();
				}
			}
		}
		else
		{
			Conductor.songPosition += FlxG.elapsed * 1000;
			Conductor.rawPosition = inst.time;
			
			songPositionBar = (Conductor.songPosition - songLength) / 1000;
			
			currentSection = getSectionByTime(Conductor.songPosition / songMultiplier);
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;
				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}
				var curTime:Float = inst.time / songMultiplier;

				if (curTime < 0)
					curTime = 0;
				var secondsTotal:Int = Math.floor(((curTime - songLength) / 1000));

				if (secondsTotal < 0)
					secondsTotal = 0;
				songName.text = SONG.song + ' (' + FlxStringUtil.formatTime((songLength - secondsTotal), false) + ')';
			}
		}

		if (generatedMusic && currentSection != null)
		{
			if (allowedToCheer)
			{
				if (gf.animation.curAnim.name == 'danceLeft'
					|| gf.animation.curAnim.name == 'danceRight'
					|| gf.animation.curAnim.name == 'idle')
				{
					switch (curSong)
					{
						case 'Philly Nice':
							{
								if (curBeat < 250)
								{
									if (curBeat != 184 && curBeat != 216)
									{
										if (curBeat % 16 == 8)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Bopeebo':
							{
								if (curBeat > 5 && curBeat < 130)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
						case 'Blammed':
							{
								if (curBeat > 30 && curBeat < 190)
								{
									if (curBeat < 90 || curBeat > 128)
									{
										if (curBeat % 4 == 2)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Cocoa':
							{
								if (curBeat < 170)
								{
									if (curBeat < 65 || curBeat > 130 && curBeat < 145)
									{
										if (curBeat % 16 == 15)
										{
											if (!triggeredAlready)
											{
												gf.playAnim('cheer');
												triggeredAlready = true;
											}
										}
										else
											triggeredAlready = false;
									}
								}
							}
						case 'Eggnog':
							{
								if (curBeat > 10 && curBeat != 111 && curBeat < 220)
								{
									if (curBeat % 8 == 7)
									{
										if (!triggeredAlready)
										{
											gf.playAnim('cheer');
											triggeredAlready = true;
										}
									}
									else
										triggeredAlready = false;
								}
							}
					}
				}
			}

			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				luaModchart.setVar("mustHit", currentSection.mustHitSection);
			#end

			if (camFollow.x != dad.getMidpoint().x + 150 && !currentSection.mustHitSection)
			{
				var offsetX = 0;
				var offsetY = 0;
				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
				{
					offsetX = luaModchart.getVar("followXOffset", "float");
					offsetY = luaModchart.getVar("followYOffset", "float");
				}
				#end
				camFollow.setPosition(dad.getMidpoint().x + 150 + offsetX, dad.getMidpoint().y - 100 + offsetY);
				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
					luaModchart.executeState('playerTwoTurn', []);
				#end

				#if FEATURE_HSCRIPT
				scripts.executeAllFunc("playerTwoTurn");
				#end
				// camFollow.setPosition(lucky.getMidpoint().x - 120, lucky.getMidpoint().y + 210);

				switch (dad.curCharacter)
				{
					case 'mom' | 'mom-car':
						camFollow.y = dad.getMidpoint().y;
					case 'senpai' | 'senpai-angry':
						camFollow.y = dad.getMidpoint().y - 430;
						camFollow.x = dad.getMidpoint().x - 100;
				}
			}

			if (currentSection.mustHitSection && camFollow.x != boyfriend.getMidpoint().x - 100)
			{
				var offsetX = 0;
				var offsetY = 0;
				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
				{
					offsetX = luaModchart.getVar("followXOffset", "float");
					offsetY = luaModchart.getVar("followYOffset", "float");
				}
				#end
				camFollow.setPosition(boyfriend.getMidpoint().x - 100 + offsetX, boyfriend.getMidpoint().y - 100 + offsetY);

				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
					luaModchart.executeState('playerOneTurn', []);
				#end

				#if FEATURE_HSCRIPT
				scripts.executeAllFunc("playerOneTurn");
				#end
				if (!PlayStateChangeables.Optimize)
					switch (Stage.curStage)
					{
						case 'limo':
							camFollow.x = boyfriend.getMidpoint().x - 300;
						case 'mall':
							camFollow.y = boyfriend.getMidpoint().y - 200;
						case 'school':
							camFollow.x = boyfriend.getMidpoint().x - 200;
							camFollow.y = boyfriend.getMidpoint().y - 200;
						case 'schoolEvil':
							camFollow.x = boyfriend.getMidpoint().x - 200;
							camFollow.y = boyfriend.getMidpoint().y - 200;
					}
			}
		}

		if (camZooming)
		{
			if (FlxG.save.data.zoom < 0.8)
				FlxG.save.data.zoom = 0.8;
			if (FlxG.save.data.zoom > 1.2)
				FlxG.save.data.zoom = 1.2;
			var bpmRatio = SONG.bpm / 100;

			FlxG.camera.zoom = FlxMath.lerp(Stage.camZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * songMultiplier), 0, 1));
			camHUD.zoom = FlxMath.lerp(FlxG.save.data.zoom, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * bpmRatio * songMultiplier), 0, 1));
			camNotes.zoom = camHUD.zoom;
			camSustains.zoom = camHUD.zoom;
			camStrums.zoom = camHUD.zoom;
		}

		FlxG.watch.addQuick("curBPM", Conductor.bpm);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		

		if ((health <= 0 && !cannotDie && !PlayStateChangeables.practiceMode && !PlayStateChangeables.opponentMode)
			|| (health > 2 && !cannotDie && !PlayStateChangeables.practiceMode && PlayStateChangeables.opponentMode))
			{
				if (!usedTimeTravel)
				{
					boyfriend.stunned = true;
					persistentUpdate = false;
					persistentDraw = false;
					paused = true;
					vocals.stop();
					inst.stop();
					if (FlxG.save.data.InstantRespawn || (PlayStateChangeables.opponentMode))
					{
						MusicBeatState.resetState();
					}
					else
					{
						if (!PlayStateChangeables.opponentMode){
							openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
						}
					}

					#if FEATURE_DISCORD
					DiscordClient.changePresence("GAME OVER -- "
					+ SONG.song
						+ " ("
						+ storyDifficultyText
						+ ") "
						+ Ratings.GenerateLetterRank(accuracy),
						"\nAcc: "
						+ HelperFunctions.truncateFloat(accuracy, 2)
						+ "% | Score: "
						+ songScore
						+ " | Misses: "
						+ misses, iconRPC);
					#end
				}
				else
					health = 1;
				}
		if (!inCutscene && FlxG.save.data.resetButton)
		{
			var resetBind = FlxKey.fromString(FlxG.save.data.resetBind);

			if ((FlxG.keys.anyJustPressed([resetBind])))
			{
				boyfriend.stunned = true;
				persistentUpdate = false;
				persistentDraw = false;
				paused = true;
				vocals.stop();
				inst.stop();
				if (FlxG.save.data.InstantRespawn
					|| FlxG.save.data.optimize
					|| (PlayStateChangeables.opponentMode && !dad.animOffsets.exists('firstDeath')))
				{
					MusicBeatState.resetState();
				}
				else
				{
					if (!PlayStateChangeables.opponentMode)
						openSubState(new GameOverSubstate(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));
					else
						openSubState(new GameOverSubstate(dad.getScreenPosition().x, dad.getScreenPosition().y));
				}

				isDead = true;

				#if FEATURE_DISCORD
				DiscordClient.changePresence("GAME OVER -- "
					+ SONG.song
					+ " ("
					+ storyDifficultyText
					+ ") "
					+ Ratings.GenerateLetterRank(accuracy),
					"\nAcc: "
					+ HelperFunctions.truncateFloat(accuracy, 2)
					+ "% | Score: "
					+ songScore
					+ " | Misses: "
					+ misses, iconRPC);
				#end
			}
		}

		if (generatedMusic && !(inCutscene || inCinematic))
		{
			var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
			var stepHeight = (0.45 * Conductor.stepCrochet * FlxMath.roundDecimal((PlayState.SONG.speed * PlayState.songMultiplier) * PlayState.songMultiplier,
				2));

			//hell
			#if FEATURE_HSCRIPT
			if (!ScriptUtil.hasPause(scripts.executeAllFunc("notesUpdate"))){
				scripts.executeAllFunc("notesUpdate");
			};
			#end
			
			notes.forEachAlive(function(daNote:Note)
			{
				var strum:FlxTypedGroup<StaticArrow> = playerStrums;
				if (!daNote.mustPress)
					strum = cpuStrums;
			
				var strumX = strum.members[daNote.noteData].x;
				var strumAngle = strum.members[daNote.noteData].modAngle;
				var strumDirection = strum.members[daNote.noteData].direction;
				var angleDir = strumDirection * Math.PI / 180;
				daNote.modAngle = strumDirection - 90 + strumAngle;
				daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
				if (!daNote.modifiedByLua)
				{
					if (PlayStateChangeables.useDownscroll)
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
								+
								0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * (FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed,
									2)))
								- daNote.noteYOff;
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
								+
								0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * (FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed,
									2)))
								- daNote.noteYOff;
						if (daNote.isSustainNote)
						{
							daNote.y -= daNote.height - stepHeight;

							if ((PlayStateChangeables.botPlay
								|| !daNote.mustPress
								|| daNote.wasGoodHit
								|| holdArray[Math.floor(Math.abs(daNote.noteData))])
								&& daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= (strumLine.y + Note.swagWidth / 2))
							{
								var swagRect = new FlxRect(0, 0, daNote.frameWidth * 2, daNote.frameHeight * 2);
								swagRect.height = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
									+ Note.swagWidth / 2
									- daNote.y) / daNote.scale.y;
								swagRect.y = daNote.frameHeight - swagRect.height;

								daNote.clipRect = swagRect;
							}
						}
					}
					else
					{
						if (daNote.mustPress)
							daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
								- 0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * (FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed,
									2)))
								+ daNote.noteYOff;
						else
							daNote.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
								- 0.45 * ((Conductor.songPosition - daNote.strumTime) / songMultiplier) * (FlxMath.roundDecimal(PlayStateChangeables.scrollSpeed == 1 ? SONG.speed : PlayStateChangeables.scrollSpeed,
									2)))
								+ daNote.noteYOff;
						if (daNote.isSustainNote)
						{
							if ((PlayStateChangeables.botPlay
								|| !daNote.mustPress
								|| daNote.wasGoodHit
								|| holdArray[Math.floor(Math.abs(daNote.noteData))])
								&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
							{
								var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								swagRect.y = (strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].y
									+ Note.swagWidth / 2
									- daNote.y) / daNote.scale.y;
								swagRect.height -= swagRect.y;

								daNote.clipRect = swagRect;
							}
						}
					}
				}

				if (!daNote.mustPress)
				{
					if (Conductor.songPosition >= daNote.strumTime && daNote.noteShit != 'hurt' && daNote.noteShit != 'mustpress')
						opponentNoteHit(daNote);
				}

				if (daNote.mustPress && !daNote.modifiedByLua)
				{
					daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
					if (!daNote.isSustainNote)
						daNote.modAngle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].modAngle;
					if (daNote.sustainActive)
					{
						if (executeModchart)
							daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;
					}
					daNote.modAngle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].modAngle;
				}
				else if (!daNote.wasGoodHit && !daNote.modifiedByLua)
				{
					daNote.visible = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].visible;
					if (!daNote.isSustainNote)
						daNote.modAngle = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].modAngle;
					if (daNote.sustainActive)
					{
						if (executeModchart)
							daNote.alpha = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].alpha;
					}
					daNote.modAngle = strumLineNotes.members[Math.floor(Math.abs(daNote.noteData))].modAngle;
				}

				//there was some code idk what it did but it fucked with color quantization shit. ik its a feature not many like but I like it.

				if (!daNote.mustPress && FlxG.save.data.middleScroll && !executeModchart)
					daNote.visible = false;

				if (daNote.isSustainNote)
				{
					daNote.x += 36.5;
					if (SONG.noteStyle == 'pixel')
						daNote.x -= 7;
				}

				if (daNote.isSustainNote && daNote.wasGoodHit && Conductor.songPosition >= daNote.strumTime)
				{
					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
				else if ((daNote.mustPress && !PlayStateChangeables.useDownscroll || daNote.mustPress && PlayStateChangeables.useDownscroll)&& daNote.mustPress&& daNote.strumTime / songMultiplier - Conductor.songPosition / songMultiplier < -(166 * Conductor.timeScale)&& songStarted)
				{
					switch (daNote.noteShit)
					{
						case 'hurt':
							if (daNote.isSustainNote && daNote.wasGoodHit)
							{
								daNote.kill();
								notes.remove(daNote, true);
							}
						case 'mustpress':
							if (daNote.isSustainNote && daNote.wasGoodHit)
							{
								daNote.kill();
								notes.remove(daNote, true);
							}
							else{
							if (loadRep && daNote.isSustainNote)
							{
								if (findByTime(daNote.strumTime) != null)
									totalNotesHit += 1;
								else
								{
									vocals.volume = 0;
									if (theFunne && !daNote.isSustainNote)
									{
										noteMiss(daNote.noteData, daNote);
									}
									if (daNote.isParent)
									{
										health -= 0.8;
										for (i in daNote.children)
										{
											i.alpha = 0.3;
											i.sustainActive = false;
										}
									}
									else
									{
										if (!daNote.wasGoodHit&& daNote.isSustainNote&& daNote.sustainActive&& daNote.spotInLine != daNote.parent.children.length)
										{
											for (i in daNote.parent.children)
											{
												i.alpha = 0.3;
												i.sustainActive = false;
											}
											if (daNote.parent.wasGoodHit)
											{
												misses++;
												totalNotesHit -= 1;
											}
											updateAccuracy();
										}
										else if (!daNote.wasGoodHit && !daNote.isSustainNote)
										{
											health -= 0.3;
										}
									}
								}
							}
							else
							{
								vocals.volume = 0;
								if (theFunne && !daNote.isSustainNote)
								{
									if (PlayStateChangeables.botPlay)
									{
										//daNote.rating = "marv";
										goodNoteHit(daNote);
									}
									else
										noteMiss(daNote.noteData, daNote);
								}

								if (daNote.isParent && daNote.visible)
								{
									health -= 0.8;
									for (i in daNote.children)
									{
										i.alpha = 0.3;
										i.sustainActive = false;
									}
								}
								else
								{
									if (!daNote.wasGoodHit&& daNote.isSustainNote&& daNote.sustainActive&& daNote.spotInLine != daNote.parent.children.length)
									{
										for (i in daNote.parent.children)
										{
											i.alpha = 0.3;
											i.sustainActive = false;
										}
										if (daNote.parent.wasGoodHit)
										{
											misses++;
											totalNotesHit -= 1;
										}
										updateAccuracy();
									}
									else if (!daNote.wasGoodHit && !daNote.isSustainNote)
									{
										health -= 0.8;
									}
								}
									daNote.visible = false;
									daNote.kill();
									notes.remove(daNote, true);
								}
							}

						// note bitches
						//custom noteshit p1
						default:
						{
						if (daNote.isSustainNote && daNote.wasGoodHit)
						{
							daNote.kill();
							notes.remove(daNote, true);
						}
						else
						{
							if (loadRep && daNote.isSustainNote)
							{
								if (findByTime(daNote.strumTime) != null)
									totalNotesHit += 1;
								else
								{
									if (theFunne && !daNote.isSustainNote)
									{
										noteMiss(daNote.noteData, daNote);
									}
									if (daNote.isParent)
									{
										if (!PlayStateChangeables.opponentMode)
											health -= (0.15 * PlayStateChangeables.healthLoss) / daNote.parent.children.length;
										else
											health += (0.15 * PlayStateChangeables.healthLoss) / daNote.parent.children.length;
										for (i in daNote.children)
										{
											i.alpha = 0.3;
											i.sustainActive = false;
										}
										noteMiss(daNote.noteData, daNote);
									}
									else
									{
										if (!daNote.wasGoodHit&& daNote.isSustainNote&& daNote.sustainActive&& daNote.spotInLine != daNote.parent.children.length)
										{
											for (i in daNote.parent.children)
											{
												i.alpha = 0.3;
												i.sustainActive = false;
											}
											if (daNote.parent.wasGoodHit)
											{
												misses++;
												totalNotesHit -= 1;
											}
											updateAccuracy();
										}
										else if (!daNote.wasGoodHit && !daNote.isSustainNote)
										{
											if (!PlayStateChangeables.opponentMode)
												health -= (0.15 * PlayStateChangeables.healthLoss) / daNote.parent.children.length;
											else
												health += (0.15 * PlayStateChangeables.healthLoss) / daNote.parent.children.length;
											noteMiss(daNote.noteData, daNote);
										}
									}
								}
							}
							else
							{
								vocals.volume = 0;
								if (theFunne && !daNote.isSustainNote)
								{
									if (PlayStateChangeables.botPlay)
									{
										//daNote.rating = "marv";
										goodNoteHit(daNote);
									}
								}

								if (daNote.isParent && daNote.visible)
								{
									health -= 0.15;
									for (i in daNote.children)
									{
										i.alpha = 0.3;
										i.sustainActive = false;
									}
									noteMiss(daNote.noteData, daNote);
								}
								else
								{
									if (!daNote.wasGoodHit&& daNote.isSustainNote&& daNote.sustainActive&& daNote.spotInLine != daNote.parent.children.length)
									{
										for (i in daNote.parent.children)
										{
											i.alpha = 0.3;
											i.sustainActive = false;
										}
										if (daNote.parent.wasGoodHit)
										{
											misses++;
											totalNotesHit -= 1;
										}
										updateAccuracy();
									}
									else if (!daNote.wasGoodHit && !daNote.isSustainNote)
									{
										if (!PlayStateChangeables.opponentMode)
											health -= (0.15 * PlayStateChangeables.healthLoss);
										else
											health += (0.15 * PlayStateChangeables.healthLoss);
										noteMiss(daNote.noteData, daNote);
									}
								}
									daNote.visible = false;
									daNote.kill();
									notes.remove(daNote, true);
								}
							}
						}
					}
				}
			});
		}

		if (FlxG.save.data.cpuStrums)
		{
			cpuStrums.forEach(function(spr:StaticArrow)
			{
				if (spr.animation.finished)
				{
					spr.playAnim('static');
					spr.centerOffsets();
				}
			});
		}

		if (!inCutscene && songStarted)
			keyShit();
		#if debug
		if (FlxG.keys.justPressed.ONE)
			endSong();
		#end
		super.update(elapsed);
		for (i in shaderUpdates)
			i(elapsed);
		#if FEATURE_HSCRIPT
		if (scripts != null)
			scripts.executeAllFunc("updatePost", [elapsed]);
		#end	
	}

	public function getSectionByTime(ms:Float):SwagSection
	{
		for (i in SONG.notes)
		{
			var start = TimingStruct.getTimeFromBeat((TimingStruct.getBeatFromTime(i.startTime)));
			var end = TimingStruct.getTimeFromBeat((TimingStruct.getBeatFromTime(i.endTime)));

			if (ms >= start && ms < end)
			{
				return i;
			}
		}

		return null;
	}

	function recalculateAllSectionTimes()
	{
		for (i in 0...SONG.notes.length)
		{
			var section = SONG.notes[i];

			var currentBeat = 4 * i;

			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (currentSeg == null)
				return;

			var start:Float = (currentBeat - currentSeg.startBeat) / ((currentSeg.bpm) / 60);

			section.startTime = (currentSeg.startTime + start) * 1000;

			if (i != 0)
				SONG.notes[i - 1].endTime = section.startTime;
			section.endTime = Math.POSITIVE_INFINITY;
		}
	}

	function endSong():Void
	{
		endingSong = true;
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, handleInput);
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, releaseInput);

		if (!loadRep)
			rep.SaveReplay(saveNotes, saveJudge, replayAna);
		else
		{
			PlayStateChangeables.botPlay = false;
			PlayStateChangeables.scrollSpeed = 1 / songMultiplier;
		}

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.save.data.fpsCap > 420)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(420);

		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			luaModchart.die();
			luaModchart = null;
		}
		#end

		canPause = false;
		inst.volume = 0;
		vocals.volume = 0;
		inst.stop();
		vocals.stop();
		if (SONG.validScore)
		{
			Highscore.saveScore(PlayState.SONG.songId, Math.round(songScore), storyDifficulty, songMultiplier);
			Highscore.saveCombo(PlayState.SONG.songId, Ratings.GenerateComboRank(accuracy), storyDifficulty, songMultiplier);
			Highscore.saveAcc(PlayState.SONG.songId, HelperFunctions.truncateFloat(accuracy, 2), storyDifficulty, songMultiplier);
			Highscore.saveLetter(PlayState.SONG.songId, Ratings.GenerateLetterRank(accuracy), storyDifficulty, songMultiplier);
		}

		if (offsetTesting)
		{
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			offsetTesting = false;
			LoadingState.loadAndSwitchState(new OptionsMenu());
			FlxG.save.data.offset = offsetTest;
		}
		else if (stageTesting)
		{
			new FlxTimer().start(0.3, function(tmr:FlxTimer)
			{
				for (bg in Stage.toAdd)
				{
					remove(bg);
				}
				for (array in Stage.layInFront)
				{
					for (bg in array)
						remove(bg);
				}
				remove(boyfriend);
				remove(dad);
				remove(gf);
			});
			LoadingState.loadAndSwitchState(new StageDebugState(Stage.curStage));
		}
		else
		{
			if (isStoryMode)
			{
				campaignScore += Math.round(songScore);
				campaignMisses += misses;
				campaignSicks += sicks;
				campaignGoods += goods;
				campaignBads += bads;
				campaignShits += shits;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					paused = true;
					inst.stop();
					vocals.stop();
					if (FlxG.save.data.scoreScreen)
					{
						paused = true;
						persistentUpdate = false;
						openSubState(new ResultsScreen());
						createTimer(1, function(tmr:FlxTimer)
						{
							inResults = true;
						});
					}
					else
					{
						GameplayCustomizeState.freeplayNoteStyle = 'normal';
						GameplayCustomizeState.freeplayWeek = 1;
						FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
						MainMenuState.freakyPlaying = true;
						Conductor.changeBPM(102);
						MusicBeatState.switchState(new StoryMenuState());
					}

					#if FEATURE_LUAMODCHART
					if (luaModchart != null)
					{
						luaModchart.die();
						luaModchart = null;
					}
					#end

					if (SONG.validScore)
					{
						Highscore.saveWeekScore(storyWeek, campaignScore, storyDifficulty, 1);
					}
				}
				else
				{
					var diff:String = CoolUtil.suffixDiffsArray[storyDifficulty];

					FlxTransitionableState.skipNextTransIn = true;
					FlxTransitionableState.skipNextTransOut = true;

					if (FlxTransitionableState.skipNextTransIn)
					{
						CustomFadeTransition.nextCamera = null;
					}

					Debug.logInfo('PlayState: Loading next story song ${PlayState.storyPlaylist[0]}-${diff}');

					PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0], diff);
					inst.stop();

					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
			{
				paused = true;
				if (isSM)
					FlxG.sound.music.stop();
				else{
					inst.stop();
				vocals.stop();
				}	

				if (FlxG.save.data.scoreScreen)
				{
					persistentUpdate = false;
					openSubState(new ResultsScreen());
					new FlxTimer().start(1, function(tmr:FlxTimer)
					{
						inResults = true;
					});
				}
				else
				{
					MusicBeatState.switchState(new FreeplayState());
				}
			}
		}
	}

	function percentageOfSong():Float
	{
		return (Conductor.songPosition / songLength) * 100;
	}

	public var endingSong:Bool = false;

	var hits:Array<Float> = [];
	var offsetTest:Float = 0;

	public function getRatesScore(rate:Float, score:Float):Float
	{
		var rateX:Float = 1;
		var lastScore:Float = score;
		var pr = rate - 0.05;
		if (pr < 1.00)
			pr = 1;

		while (rateX <= pr)
		{
			if (rateX > pr)
				break;
			lastScore = score + ((lastScore * rateX) * 0.022);
			rateX += 0.05;
		}

		var actualScore = Math.round(score + (Math.floor((lastScore * pr)) * 0.022));

		return actualScore;
	}

	var timeShown = 0;
	var currentTimingShown:FlxText = null;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float;
		if (daNote != null)
			noteDiff = -(daNote.strumTime - Conductor.songPosition);
		else
			noteDiff = Conductor.safeZoneOffset;
		var wife:Float = EtternaFunctions.wife3(-noteDiff, Conductor.timeScale);
		vocals.volume = 1;
		var placement:String = Std.string(combo);
		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;
		coolText.y -= 350;
		coolText.cameras = [camHUD];

		var rating:FlxSprite = new FlxSprite();
		var score:Float = 350;

		if (FlxG.save.data.accuracyMod == 1)
			totalNotesHit += wife;

		var daRating = Ratings.judgeNote(noteDiff);

		switch (daNote.noteShit){
			case 'hurt':
			canNoteSplash = false;
			//goes unused because it doesn't get called to do so.
			case 'mustpress':
			canNoteSplash = false;
			default:
			canNoteSplash = true;
		}

		switch (daRating)
		{
			case 'shit':
				score = 50;
				shits++;
				ss = false;
				if (!PlayStateChangeables.opponentMode)
				{
					health -= 0.2 * PlayStateChangeables.healthLoss;
					if (PlayStateChangeables.skillIssue)
						health = 0;
				}
				else
				{
					health += 0.2 * PlayStateChangeables.healthLoss;
					if (PlayStateChangeables.skillIssue)
						health = 2.1;
				}
			/*if (FlxG.save.data.accuracyMod == 0)
				totalNotesHit -= 1; */
			case 'bad':
				score = 100;
				if (!PlayStateChangeables.opponentMode)
					health -= 0.06 * PlayStateChangeables.healthLoss;
				else
					health += 0.06 * PlayStateChangeables.healthLoss;
				ss = false;
				bads++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.50;
			case 'good':
				health += 0.02;
				score = 200;
				ss = false;
				goods++;
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 0.75;
			case 'sick':
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				sicks++;
				if (FlxG.save.data.notesplashes && canNoteSplash)
				{
					NoteSplashesSpawn(daNote);
				}
				if (!PlayStateChangeables.opponentMode && health < 2)
				{
					health += 0.15 * PlayStateChangeables.healthGain;
				}
				else if (PlayStateChangeables.opponentMode && health > 0)
				{
					health -= 0.15 * PlayStateChangeables.healthGain;
				}
			case 'marv':
				if (FlxG.save.data.accuracyMod == 0)
					totalNotesHit += 1;
				marvs++;
				if (FlxG.save.data.notesplashes && canNoteSplash)
				{
					NoteSplashesSpawn(daNote);
				}
				if (!PlayStateChangeables.opponentMode && health < 2)
				{
					health += 0.06 * PlayStateChangeables.healthGain;
				}
				else if (PlayStateChangeables.opponentMode && health > 0)
				{
					health -= 0.06 * PlayStateChangeables.healthGain;
				}
		}

		if (songMultiplier >= 1.05)
			score = getRatesScore(songMultiplier, score);
		
		songScore += Math.round(score);

		var pixelShitPart1:String = "";
		var pixelShitPart2:String = '';
		var pixelShitPart3:String = null;

		if (SONG.noteStyle == 'pixel')
		{
			pixelShitPart1 = 'weeb/pixelUI/';
			pixelShitPart2 = '-pixel';
			pixelShitPart3 = 'week6';
		}
		rating.loadGraphic(Paths.image2(pixelShitPart1 + daRating + pixelShitPart2, pixelShitPart3));
		rating.screenCenter();
		rating.y -= 50;
		rating.x = coolText.x - 125;

		if (!FlxG.save.data.middleScroll || PlayStateChangeables.Optimize|| !FlxG.save.data.popup)
			rating.x = (coolText.x - 125)
		else
			rating.x = (coolText.x + 200);

		if (FlxG.save.data.changedHit)
		{
			rating.x = FlxG.save.data.changedHitX;
			rating.y = FlxG.save.data.changedHitY;
		}
		rating.acceleration.y = 550;
		rating.velocity.y -= FlxG.random.int(140, 175);
		rating.velocity.x -= FlxG.random.int(0, 10);

		var msTiming = HelperFunctions.truncateFloat(noteDiff / songMultiplier, 3);
		if (PlayStateChangeables.botPlay && !loadRep)
			msTiming = 0;

		if (loadRep)
			msTiming = HelperFunctions.truncateFloat(findByTime(daNote.strumTime)[3], 3);

		if (currentTimingShown != null)
			remove(currentTimingShown);

		currentTimingShown = new FlxText(0, 0, 0, "0ms");
		timeShown = 0;
		switch (daRating)
		{
			case 'shit' | 'bad':
				currentTimingShown.color = FlxColor.RED;
			case 'good':
				currentTimingShown.color = FlxColor.WHITE;
			case 'sick':
				currentTimingShown.color = FlxColor.WHITE;
			case 'marv':
				currentTimingShown.color = FlxColor.CYAN;
		}
		currentTimingShown.borderStyle = OUTLINE;
		currentTimingShown.borderSize = 1;
		currentTimingShown.borderColor = FlxColor.BLACK;
		currentTimingShown.text = msTiming + "ms";
		currentTimingShown.size = 20;

		if (msTiming >= 0.03 && offsetTesting)
		{
			hits.shift();
			hits.shift();
			hits.shift();
			hits.pop();
			hits.pop();
			hits.pop();
			hits.push(msTiming);

			var total = 0.0;

			for (i in hits)
				total += i;

			offsetTest = HelperFunctions.truncateFloat(total / hits.length, 2);
		}

		if (currentTimingShown.alpha != 1)
			currentTimingShown.alpha = 1;

		if (!PlayStateChangeables.botPlay || loadRep)
		{
			if (FlxG.save.data.popup)
				add(currentTimingShown);
		}

		var comboSpr:FlxSprite = new FlxSprite().loadGraphic(Paths.image2(pixelShitPart1 + 'combo' + pixelShitPart2, pixelShitPart3));
		comboSpr.screenCenter();
		comboSpr.x = rating.x;
		comboSpr.y = rating.y + 100;
		comboSpr.acceleration.y = 600;
		comboSpr.velocity.y -= 150;

		if (!FlxG.save.data.rateStack)
		{
			if(lastRating != null) lastRating.kill();
			lastRating = rating;
		}

		if (lastCombo != null)
			lastCombo.kill();
		lastCombo = comboSpr;

		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				lastScore[0].kill();
				lastScore.remove(lastScore[0]);
			}
		}	

		currentTimingShown.screenCenter();
		if (!FlxG.save.data.middleScroll)
			currentTimingShown.x = comboSpr.x + 100;
		else
		{
			currentTimingShown.x = rating.x + 30;
			currentTimingShown.alignment = FlxTextAlign.RIGHT;
		}
		currentTimingShown.x = comboSpr.x + 100;
		currentTimingShown.y = rating.y + 100;
		currentTimingShown.acceleration.y = 600;
		currentTimingShown.velocity.y -= 150;

		comboSpr.velocity.x += FlxG.random.int(1, 10);
		currentTimingShown.velocity.x += comboSpr.velocity.x;
		if (!PlayStateChangeables.botPlay || loadRep)
		{
			if (FlxG.save.data.popup)
				add(rating);
		}

		if (SONG.noteStyle != 'pixel')
		{
			rating.setGraphicSize(Std.int(rating.width * 0.7));
			rating.antialiasing = FlxG.save.data.antialiasing;
			comboSpr.setGraphicSize(Std.int(comboSpr.width * 0.7));
			comboSpr.antialiasing = FlxG.save.data.antialiasing;
		}
		else
		{
			rating.setGraphicSize(Std.int(rating.width * CoolUtil.daPixelZoom * 0.7));
			comboSpr.setGraphicSize(Std.int(comboSpr.width * CoolUtil.daPixelZoom * 0.7));
		}

		currentTimingShown.updateHitbox();
		comboSpr.updateHitbox();
		rating.updateHitbox();

		currentTimingShown.cameras = [camHUD];
		comboSpr.cameras = [camHUD];
		rating.cameras = [camHUD];

		var seperatedScore:Array<Int> = [];

		var comboSplit:Array<String> = (combo + "").split('');

		if (combo > highestCombo)
			highestCombo = combo;
		
		if (comboSplit.length == 1)
		{
			seperatedScore.push(0);
			seperatedScore.push(0);
		}
		else if (comboSplit.length == 2)
			seperatedScore.push(0);

		for (i in 0...comboSplit.length)
		{
			var str:String = comboSplit[i];
			seperatedScore.push(Std.parseInt(str));
		}

		if (!FlxG.save.data.rateStack)
		{
			if (lastCombo != null) lastCombo.kill();
			lastCombo = comboSpr;
		}

		var daLoop:Int = 0;
		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite().loadGraphic(Paths.image2(pixelShitPart1 + 'num' + Std.int(i) + pixelShitPart2, pixelShitPart3));
			numScore.screenCenter();
			numScore.x = rating.x + (43 * daLoop) - 50;

			if (!FlxG.save.data.middleScroll)
				numScore.x = rating.x + (43 * daLoop) - 50;
			else
				numScore.x = rating.x + (43 * daLoop) + 150;
			numScore.x = rating.x + (43 * daLoop) - 50;
			numScore.y = rating.y + 100;
			numScore.cameras = [camHUD];

			if (SONG.noteStyle != 'pixel')
			{
				numScore.antialiasing = FlxG.save.data.antialiasing;
				numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			}
			else
			{
				numScore.setGraphicSize(Std.int(numScore.width * CoolUtil.daPixelZoom));
			}
			numScore.updateHitbox();

			numScore.acceleration.y = FlxG.random.int(200, 300);
			numScore.velocity.y -= FlxG.random.int(140, 160);
			numScore.velocity.x = FlxG.random.float(-5, 5);

			if (FlxG.save.data.popup)
				add(numScore);

			if (!FlxG.save.data.rateStack)
				lastScore.push(numScore);
			else
				visibleCombos.push(numScore);	

			if (FlxG.save.data.rateStack){
				createTween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						visibleCombos.remove(numScore);
						numScore.kill();
					},
					onUpdate: function(tween:FlxTween)
					{
						if (!visibleCombos.contains(numScore))
						{
							tween.cancel();
							numScore.destroy();
						}
					},
					startDelay: Conductor.crochet * 0.002 * Math.pow(songMultiplier, 2)
				});
			}
			else{
				createTween(numScore, {alpha: 0}, 0.2, {
					onComplete: function(tween:FlxTween)
					{
						lastScore.remove(numScore);
						numScore.kill();
					},
					onUpdate: function(tween:FlxTween)
					{
						if (!lastScore.contains(numScore))
						{
							tween.cancel();
							numScore.destroy();
						}
					},
					startDelay: Conductor.crochet * 0.002 * Math.pow(songMultiplier, 2)
				});
			}
			

			if (visibleCombos.length > seperatedScore.length + 20)
			{
				for (i in 0...seperatedScore.length - 1)
				{
					visibleCombos.remove(visibleCombos[visibleCombos.length - 1]);
				}
			}

			daLoop++;
		}

		coolText.text = Std.string(seperatedScore);

		createTween(rating, {alpha: 0}, 0.2, {
			startDelay: (Conductor.crochet * Math.pow(songMultiplier, 2)) * 0.001
		});

		createTween(currentTimingShown, {alpha: 0}, 0.1, {startDelay: (Conductor.crochet * Math.pow(songMultiplier, 2)) * 0.0005});

		curSection += 1;
	}

	public function NearlyEquals(value1:Float, value2:Float, unimportantDifference:Float = 10):Bool
	{
		return Math.abs(FlxMath.roundDecimal(value1, 1) - FlxMath.roundDecimal(value2, 1)) < unimportantDifference;
	}

	var upHold:Bool = false;
	var downHold:Bool = false;
	var rightHold:Bool = false;
	var leftHold:Bool = false;

	// THIS FUNCTION JUST FUCKS WIT HELD NOTES AND BOTPLAY/REPLAY (also gamepad shit)

	private function keyShit():Void
	{
		var holdArray:Array<Bool> = [controls.LEFT, controls.DOWN, controls.UP, controls.RIGHT];
		var pressArray:Array<Bool> = [controls.LEFT_P, controls.DOWN_P, controls.UP_P, controls.RIGHT_P];
		var releaseArray:Array<Bool> = [controls.LEFT_R, controls.DOWN_R, controls.UP_R, controls.RIGHT_R];
		var keynameArray:Array<String> = ['left', 'down', 'up', 'right'];
		#if FEATURE_LUAMODCHART
		if (luaModchart != null)
		{
			for (i in 0...pressArray.length)
			{
				if (pressArray[i] == true)
				{
					luaModchart.executeState('keyPressed', [keynameArray[i]]);
				}
			};

			for (i in 0...releaseArray.length)
			{
				if (releaseArray[i] == true)
				{
					luaModchart.executeState('keyReleased', [keynameArray[i]]);
				}
			};
		};
		#end
		
		if (PlayStateChangeables.botPlay)
		{
			holdArray = [false, false, false, false];
			pressArray = [false, false, false, false];
			releaseArray = [false, false, false, false];
		}

		var anas:Array<Ana> = [null, null, null, null];

		if (FlxG.save.data.hitSound != 0 && pressArray.contains(true))
		{
			if (FlxG.save.data.strumHit)
			{
				var daHitSound:FlxSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}',
					'shared'));
				daHitSound.volume = FlxG.save.data.hitVolume;
				daHitSound.play();
			}
		}

		for (i in 0...pressArray.length)
			if (pressArray[i])
				anas[i] = new Ana(Conductor.songPosition, null, false, "miss", i);
		
		if (holdArray.contains(true) && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress && holdArray[daNote.noteData] && daNote.sustainActive)
				{
					goodNoteHit(daNote);
				}
			});
		}

		if ((KeyBinds.gamepad &&  !FlxG.keys.justPressed.ANY))
		{
			if (pressArray.contains(true) && generatedMusic)
			{
				if (!PlayStateChangeables.opponentMode)
					boyfriend.holdTimer = 0;
				else
					dad.holdTimer = 0;

				var possibleNotes:Array<Note> = [];
				var directionList:Array<Int> = [];
				var dumbNotes:Array<Note> = [];
				var directionsAccounted:Array<Bool> = [false, false, false, false];

				notes.forEachAlive(function(daNote:Note)
				{
					if (daNote.canBeHit && daNote.mustPress && !daNote.wasGoodHit && !directionsAccounted[daNote.noteData])
					{
						if (directionList.contains(daNote.noteData))
						{
							directionsAccounted[daNote.noteData] = true;
							for (coolNote in possibleNotes)
							{
								if (coolNote.noteData == daNote.noteData && Math.abs(daNote.strumTime - coolNote.strumTime) < 10)
								{ // if it's the same note twice at < 10ms distance, just delete it
									// EXCEPT u cant delete it in this loop cuz it fucks with the collection lol
									dumbNotes.push(daNote);
									break;
								}
								else if (coolNote.noteData == daNote.noteData && daNote.strumTime < coolNote.strumTime)
								{ // if daNote is earlier than existing note (coolNote), replace
									possibleNotes.remove(coolNote);
									possibleNotes.push(daNote);
									break;
								}
							}
						}
						else
						{
							directionsAccounted[daNote.noteData] = true;
							possibleNotes.push(daNote);
							directionList.push(daNote.noteData);
						}
					}
				});

				for (note in dumbNotes)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
				var hit = [false, false, false, false];

				if (perfectMode)
					goodNoteHit(possibleNotes[0]);
				else if (possibleNotes.length > 0)
				{
					if (!FlxG.save.data.ghost)
					{
						for (shit in 0...pressArray.length)
						{
							if (pressArray[shit] && !directionList.contains(shit))
								noteMiss(shit, null);
						}
					}
					for (coolNote in possibleNotes)
					{
						if (pressArray[coolNote.noteData] && !hit[coolNote.noteData])
						{
							if (mashViolations != 0)
								mashViolations--;
							hit[coolNote.noteData] = true;
							scoreTxt.color = FlxColor.WHITE;
							var noteDiff:Float = -(coolNote.strumTime - Conductor.songPosition);
							anas[coolNote.noteData].hit = true;
							anas[coolNote.noteData].hitJudge = Ratings.judgeNote(noteDiff);
							anas[coolNote.noteData].nearestNote = [coolNote.strumTime, coolNote.noteData, coolNote.sustainLength];
							goodNoteHit(coolNote);
						}
					}
				};

				if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || PlayStateChangeables.botPlay))
				{
					if (boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss'))
						boyfriend.dance();
				}
			}

			if (!loadRep)
				for (i in anas)
					if (i != null)
						replayAna.anaArray.push(i); // put em all there
		}
		if (PlayStateChangeables.botPlay)
			notes.forEachAlive(function(daNote:Note)
			{
				if (daNote.mustPress && Conductor.songPosition >= daNote.strumTime && daNote.noteShit != 'hurt')
				{
					// Force good note hit regardless if it's too late to hit it or not as a fail safe
					if (loadRep)
					{
						// trace('ReplayNote ' + tmpRepNote.strumtime + ' | ' + tmpRepNote.direction);
						var n = findByTime(daNote.strumTime);
						if (n != null)
						{
							goodNoteHit(daNote);
							if (!PlayStateChangeables.opponentMode)
								boyfriend.holdTimer = 0;
							else
								dad.holdTimer = 0;
						}
					}
					else
					{
						goodNoteHit(daNote);
						if (!PlayStateChangeables.opponentMode)
							boyfriend.holdTimer = 0;
						else
							dad.holdTimer = 0;
					}
				}
			});

		if (!FlxG.save.data.optimize){
			if (boyfriend.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || PlayStateChangeables.botPlay || PlayStateChangeables.opponentMode))
			{
				if (boyfriend.animation.curAnim.name.startsWith('sing')
					&& !boyfriend.animation.curAnim.name.endsWith('miss')
					&& (boyfriend.animation.curAnim.curFrame >= 10 || boyfriend.animation.curAnim.finished))
					boyfriend.dance();
			}
		}

		if (PlayStateChangeables.opponentMode)
		{
			if (!FlxG.save.data.optimize)
			{
				if (dad.holdTimer > Conductor.stepCrochet * 4 * 0.001 && (!holdArray.contains(true) || PlayStateChangeables.botPlay))
				{
					if (dad.animation.curAnim.name.startsWith('sing') && !dad.animation.curAnim.name.endsWith('miss') && (boyfriend.animation.curAnim.curFrame >= 10 || dad.animation.curAnim.finished))
					{
						dad.dance();
					}
				}
			}
		}
		

		playerStrums.forEach(function(spr:StaticArrow)
		{
			if (!PlayStateChangeables.botPlay)
			{
				if (keys[spr.ID]
					&& spr.animation.curAnim.name != 'confirm'
					&& spr.animation.curAnim.name != 'pressed'
					&& !spr.animation.curAnim.name.startsWith('dirCon'))
					spr.playAnim('pressed', false);
				if (!keys[spr.ID])
					spr.playAnim('static', false);
			}
			else if (FlxG.save.data.cpuStrums || (PlayStateChangeables.botPlay))
			{
				if (spr.animation.finished)
					spr.playAnim('static');
			}
		});
	}

	public function findByTime(time:Float):Array<Dynamic>
	{
		for (i in rep.replay.songNotes)
		{
			// trace('checking ' + Math.round(i[0]) + ' against ' + Math.round(time));
			if (i[0] == time)
				return i;
		}
		return null;
	}

	public function findByTimeIndex(time:Float):Int
	{
		for (i in 0...rep.replay.songNotes.length)
		{
			// trace('checking ' + Math.round(i[0]) + ' against ' + Math.round(time));
			if (rep.replay.songNotes[i][0] == time)
				return i;
		}
		return -1;
	}

	public var fuckingVolume:Float = 1;
	public var useVideo = false;

	public var playingDathing = false;

	public var videoSprite:FlxSprite;

	function noteMiss(direction:Int = 1, ?daNote:Note):Void
	{
			if (!boyfriend.stunned)
			{
				if (combo > 5 && gf.animOffsets.exists('sad') && !PlayStateChangeables.opponentMode)
				{
					gf.playAnim('sad');
				}
				if (combo != 0)
				{
					combo = 0;
				}
				misses++;

				if (daNote != null)
				{
					if (!loadRep)
					{
						saveNotes.push([
							daNote.strumTime,
							0,
							direction,
							-(166 * Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166)
						]);
						saveJudge.push("miss");
					}
				}
				else if (!loadRep)
				{
					saveNotes.push([
						Conductor.songPosition,
						0,
						direction,
						-(166 * Math.floor((PlayState.rep.replay.sf / 60) * 1000) / 166)
					]);
					saveJudge.push("miss");
				}

				totalNotesHit -= 1;

				if (daNote != null)
				{
					if (!daNote.isSustainNote)
						songScore -= 10;
				}
				else
					songScore -= 10;

				if (FlxG.save.data.missSounds)
				{
					FlxG.sound.play(Paths.soundRandom('missnote' + altSuffix, 1, 3), FlxG.random.float(0.1, 0.2));
				}

				if (!FlxG.save.data.optimize)
				{
					if (!PlayStateChangeables.opponentMode)
						boyfriend.playAnim('sing' + dataSuffix[direction] + 'miss', true);
					else if (PlayStateChangeables.opponentMode && dad.animOffsets.exists('sing' + dataSuffix[direction] + 'miss'))
						dad.playAnim('sing' + dataSuffix[direction] + 'miss', true);
				}

				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
					luaModchart.executeState('playerOneMiss', [direction, Conductor.songPosition]);
				#end
				#if FEATURE_HSCRIPT
				scripts.executeAllFunc("noteMiss", [daNote]);
				#end

				updateAccuracy();
				updateScoreText();
			}
	}
	
	function updateAccuracy()
	{
		totalPlayed += 1;
		accuracy = Math.max(0, totalNotesHit / totalPlayed * 100);
		accuracyDefault = Math.max(0, totalNotesHitDefault / totalPlayed * 100);
		#if FEATURE_HSCRIPT
		if (ScriptUtil.hasPause(scripts.executeAllFunc("updateAccuracy")))
			return;
		#end	
		
		judgementCounter.text = 'Marvelous: ${marvs} \nSicks: ${sicks}\nGoods: ${goods}\nBads: ${bads}\nShits: ${shits}\nMisses: ${misses}';
	}

	function updateScoreText()
	{
		scoreTxt.text = Ratings.CalculateRanking(songScore, songScoreDef, nps, maxNPS,(FlxG.save.data.roundAccuracy ? FlxMath.roundDecimal(accuracy, 0) : accuracy));
	}

	function receptorTween()
	{
		for (i in 0...strumLineNotes.length)
		{
			createTween(strumLineNotes.members[i], {modAngle: strumLineNotes.members[i].modAngle + 360}, 0.5 / songMultiplier,
				{ease: FlxEase.smootherStepInOut});
		}
	}

	function getKeyPresses(note:Note):Int
	{
		var possibleNotes:Array<Note> = [];

		notes.forEachAlive(function(daNote:Note)
		{
			if (daNote.canBeHit && daNote.mustPress)
			{
				possibleNotes.push(daNote);
				possibleNotes.sort((a, b) -> Std.int(a.strumTime - b.strumTime));
			}
		});
		if (possibleNotes.length == 1)
			return possibleNotes.length + 1;
		return possibleNotes.length;
	}

	var mashing:Int = 0;
	var mashViolations:Int = 0;

	var etternaModeScore:Int = 0;

	function noteCheck(controlArray:Array<Bool>, note:Note):Void
	{
		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);

		note.rating = Ratings.judgeNote(noteDiff);

		if (controlArray[note.noteData])
		{
			goodNoteHit(note, (mashing > getKeyPresses(note)));
		}
	}

	function opponentNoteHit(daNote:Note):Void
	{
		if (SONG.songId != 'tutorial')
			camZooming = FlxG.save.data.camzoom;
		var altAnim:String = "";
		var curSection:Int = Math.floor((curStep / 16));

		if (daNote.isAlt)
		{
			altAnim = '-alt';
		}

		if (daNote.isParent)
			for (i in daNote.children)
				i.sustainActive = true;

		if (!PlayStateChangeables.opponentMode)
			dad.holdTimer = 0;
		else
			boyfriend.holdTimer = 0;

		if (PlayStateChangeables.healthDrain)
		{
			if (!daNote.isSustainNote)
			{
				updateScoreText();
				if (!PlayStateChangeables.opponentMode)
				{
					health -= .04 * PlayStateChangeables.healthLoss;
					if (health <= 0.01)
					{
						health = 0.01;
					}
				}
				else
				{
					health += .04 * PlayStateChangeables.healthLoss;
					if (health >= 2)
						health = 2;
				}
			}
			else
			{
			}
		}
		// Accessing the animation name directly to play it
		if (!daNote.isParent && daNote.parent != null)
		{
			if (daNote.spotInLine != daNote.parent.children.length - 1)
			{
				var singData:Int = Std.int(Math.abs(daNote.noteData));

				if (!FlxG.save.data.optimize)
				{
					if (PlayStateChangeables.opponentMode)
						boyfriend.playAnim('sing' + dataSuffix[singData] + altAnim, true);
					else
						dad.playAnim('sing' + dataSuffix[singData] + altAnim, true);
				}
				if (FlxG.save.data.cpuStrums)
				{
					cpuStrums.forEach(function(spr:StaticArrow)
					{
						pressArrow(spr, spr.ID, daNote);
					});
				}
				#if FEATURE_LUAMODCHART
				if (luaModchart != null)
					if (!PlayStateChangeables.opponentMode)
						luaModchart.executeState('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
					else
						luaModchart.executeState('playerOneSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
				#end

				#if FEATURE_HSCRIPT
				scripts.executeAllFunc("opponentNoteHit", [daNote]);
				#end

				if (SONG.needsVoices)
					vocals.volume = 1;
			}
		}
		else
		{
			var singData:Int = Std.int(Math.abs(daNote.noteData));

			if (!FlxG.save.data.optimize)
			{
				if (PlayStateChangeables.opponentMode)
					boyfriend.playAnim('sing' + dataSuffix[singData] + altAnim, true);
				else
					dad.playAnim('sing' + dataSuffix[singData] + altAnim, true);
			}
			if (FlxG.save.data.cpuStrums)
			{
				cpuStrums.forEach(function(spr:StaticArrow)
				{
					pressArrow(spr, spr.ID, daNote);
				});
			}
			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				if (!PlayStateChangeables.opponentMode)
					luaModchart.executeState('playerTwoSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
				else
					luaModchart.executeState('playerOneSing', [Math.abs(daNote.noteData), Conductor.songPosition]);
			#end
			if (!PlayStateChangeables.opponentMode)
				dad.holdTimer = 0;
			else
				boyfriend.holdTimer = 0;
			if (SONG.needsVoices)
				vocals.volume = 1;
		}
		daNote.active = false;
		daNote.kill();
		notes.remove(daNote, true);
		daNote.destroy();
	}

	function goodNoteHit(note:Note, resetMashViolation = true):Void
	{
		if (mashing != 0)
			mashing = 0;

		// add newest note to front of notesHitArray
		// the oldest notes are at the end and are removed first
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;

		var noteDiff:Float = -(note.strumTime - Conductor.songPosition);

		if (loadRep)
		{
			noteDiff = findByTime(note.strumTime)[3];
			note.rating = rep.replay.songJudgements[findByTimeIndex(note.strumTime)];
		}
		else
			note.rating = Ratings.judgeNote(noteDiff);

		if (note.rating == "miss")
			return;
		
		if (!note.isSustainNote)
			notesHitArray.unshift(Date.now());

		if (!resetMashViolation && mashViolations >= 1)
			mashViolations--;

		if (mashViolations < 0)
			mashViolations = 0;
			
		var altAnim:String = "";
		if (note.isAlt)
		{
			altAnim = '-alt';
		}

		switch (note.noteShit){
			case 'hurt':
				health -= 0.8;
				canPlayAnims = false;
			case 'mustpress':
				health += 0.8;
				canPlayAnims = false;
			default:	
				canPlayAnims = true;
		}	

		#if FEATURE_HSCRIPT
		scripts.executeAllFunc("goodNoteHit", [note]);
		#end

		if (canPlayAnims && !note.wasGoodHit && !note.isSustainNote)
		{
			combo += 1;
			popUpScore(note);
			if (FlxG.save.data.hitSound != 0)
			{
				if (!FlxG.save.data.strumHit)
				{
					var daHitSound:FlxSound = new FlxSound()
						.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
					daHitSound.volume = FlxG.save.data.hitVolume;
					daHitSound.play();
				}
			}
			if (note.isParent)
				for (i in note.children)
					i.sustainActive = true;
			
			if (!FlxG.save.data.optimize)
			{
				if (PlayStateChangeables.opponentMode)
					dad.playAnim('sing' + dataSuffix[note.noteData] + altAnim, true);
				else
					boyfriend.playAnim('sing' + dataSuffix[note.noteData] + altAnim, true);
			}
		}

		if (canPlayAnims && note.isSustainNote)
		{
			if (!FlxG.save.data.optimize)
			{
				if (PlayStateChangeables.opponentMode)
					dad.playAnim('sing' + dataSuffix[note.noteData] + altAnim, true);
				else
					boyfriend.playAnim('sing' + dataSuffix[note.noteData] + altAnim, true);
			}
		}
		
			playerStrums.forEach(function(spr:StaticArrow)
			{
				pressArrow(spr, spr.ID, note);
			});

			#if FEATURE_LUAMODCHART
			if (luaModchart != null)
				luaModchart.executeState('playerOneSing', [note.noteData, Conductor.songPosition]);
			#end

			if (!loadRep && note.mustPress)
			{
				var array = [note.strumTime, note.sustainLength, note.noteData, noteDiff];
				if (note.isSustainNote)
					array[1] = -1;
				saveNotes.push(array);
				saveJudge.push(note.rating);
			}

			if (!note.wasGoodHit)
			{
				if (!PlayStateChangeables.botPlay)
				{
					playerStrums.forEach(function(spr:StaticArrow)
					{
						pressArrow(spr, spr.ID, note);
					});
				}
			}

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
			else
			{
				note.wasGoodHit = true;
			}
			if (!note.isSustainNote)
			{
				updateAccuracy();
				updateScoreText();
			}
	}

	function pressArrow(spr:StaticArrow, idCheck:Int, daNote:Note)
	{
		if (Math.abs(daNote.noteData) == idCheck)
		{
			if (!FlxG.save.data.stepMania)
			{
				spr.playAnim('confirm', true);
			}
			else
			{
				spr.playAnim('dirCon' + daNote.originColor, true);
				spr.localAngle = daNote.originAngle;
			}
		}
	}

	var danced:Bool = false;

	override function stepHit()
	{
		super.stepHit();
		if (!paused)
		{
			var bpmRatio:Float = Conductor.bpm / 100;
			if (Math.abs(Conductor.songPosition * songMultiplier) > Math.abs(inst.time + (25 * bpmRatio))
				|| Math.abs(Conductor.songPosition * songMultiplier) < Math.abs(inst.time - (25 * bpmRatio)))
			{
				resyncVocals();
			}
		}

		if (curSong == 'ugh')
		{
			if (curStep == 59 * songMultiplier)
			{
				dad.playAnim('ugh');
			}

			if (curStep == 443 * songMultiplier)
			{
				dad.playAnim('ugh');
			}

			if (curStep == 523 * songMultiplier)
			{
				dad.playAnim('ugh');
			}

			if (curStep == 828)
			{
				dad.playAnim('ugh');
			}
		}

		if (curSong == 'stress' )
		{
			if (curStep == 736 * songMultiplier)
			{
				dad.playAnim('good');
			}
		}

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.setVar('curStep', curStep);
			luaModchart.executeState('stepHit', [curStep]);
		}
		#end
		#if FEATURE_HSCRIPT
			scripts.setAll("curStep", curStep);
			scripts.executeAllFunc("stepHit", [curStep]);
		#end

		if (isStoryMode)
		{
			if (SONG.songId == 'eggnog' && curStep == 938)
			{
				var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom,
					-FlxG.height * FlxG.camera.zoom).makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
				blackShit.scrollFactor.set();
				add(blackShit);
				camHUD.visible = false;
				camStrums.visible = false;

				FlxG.sound.play(Paths.sound('Lights_Shut_off'));
				createTimer(1.5, function(tmr)
				{
					endSong();
				});
			}
		}

			if (!endingSong && currentSection != null)
			{
				if (!FlxG.save.data.optimize)
				{
					if (curStep % Math.floor(64 * songMultiplier) == Math.floor(60 * songMultiplier)
						&& SONG.songId == 'tutorial'
						&& dad.curCharacter == 'gf'
						&& curStep > 64 * songMultiplier
						&& curStep < 192 * songMultiplier)
					{
						if (vocals.volume != 0)
						{
							boyfriend.playAnim('hey', true);
							dad.playAnim('cheer', true);
						}
						else
						{
							dad.playAnim('sad', true);
							FlxG.sound.play(Paths.soundRandom('GF_', 1, 4, 'shared'), 0.3);
						}
					}
				}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (generatedMusic)
		{
			notes.sort(FlxSort.byY, (PlayStateChangeables.useDownscroll ? FlxSort.ASCENDING : FlxSort.DESCENDING));
		}

		#if FEATURE_LUAMODCHART
		if (executeModchart && luaModchart != null)
		{
			luaModchart.executeState('beatHit', [curBeat]);
		}
		#end

		if (currentSection != null && !FlxG.save.data.optimize)
		{
			if (curBeat % Math.floor(idleBeat * songMultiplier) == 0)
			{
				if (idleToBeat && !dad.animation.curAnim.name.startsWith('sing'))
					dad.dance(forcedToIdle, currentSection.CPUAltAnim);
				if (idleToBeat && !boyfriend.animation.curAnim.name.startsWith('sing'))
					boyfriend.dance(forcedToIdle, currentSection.playerAltAnim);
			}
			else if (curBeat % Math.floor(idleBeat * songMultiplier) != 0)
			{
				if (boyfriend.isDancing && !boyfriend.animation.curAnim.name.startsWith('sing'))
					boyfriend.dance(forcedToIdle, currentSection.CPUAltAnim);
				if (dad.isDancing && !dad.animation.curAnim.name.startsWith('sing'))
					dad.dance(forcedToIdle, currentSection.CPUAltAnim);
			}
		}

		wiggleShit.update(Conductor.crochet);

		if (FlxG.save.data.camzoom && songMultiplier == 1)
		{
			if (PlayState.SONG.songId == 'milf' && curBeat >= 168 && curBeat < 200 && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 / songMultiplier;
				camHUD.zoom += 0.03 / songMultiplier;
			}

			if (camZooming && FlxG.camera.zoom < 1.35 && curBeat % 4 == 0)
			{
				FlxG.camera.zoom += 0.015 / songMultiplier;
				camHUD.zoom += 0.03 / songMultiplier;
			}
		}
		if (!theMotionThing)
		{
			if (songMultiplier == 1)
			{
				iconP1.setGraphicSize(Std.int(iconP1.width + 30));
				iconP2.setGraphicSize(Std.int(iconP2.width + 30));

				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}
			else
			{
				iconP1.setGraphicSize(Std.int(iconP1.width + 4));
				iconP2.setGraphicSize(Std.int(iconP2.width + 4));

				iconP1.updateHitbox();
				iconP2.updateHitbox();
			}
		}

		if (!endingSong && currentSection != null)
		{
			if (allowedToHeadbang)
			{
				gf.dance();
			}

			if (curBeat % 8 == 7 && curSong == 'bopeebo')
			{
				boyfriend.playAnim('hey', true);
			}

			if (curBeat % 16 == 15 && SONG.songId == 'tutorial' && dad.curCharacter == 'gf' && curBeat > 16 && curBeat < 48)
			{
				if (vocals.volume != 0)
				{
					boyfriend.playAnim('hey', true);
					dad.playAnim('cheer', true);
				}
				else
				{
					dad.playAnim('sad', true);
				}
			}

			if (PlayStateChangeables.Optimize)
				if (vocals.volume == 0 && !currentSection.mustHitSection)
					vocals.volume = 1;
		}
		#if FEATURE_HSCRIPT
			scripts.setAll("curBeat", curBeat);
			scripts.executeAllFunc("beatHit", [beatHit]);
		#end
	}

	public var cleanedSong:SongData;

	function poggers(?cleanTheSong = false)
	{
		var notes = [];

		if (cleanTheSong)
		{
			cleanedSong = SONG;

			for (section in cleanedSong.notes)
			{
				var removed = [];

				for (note in section.sectionNotes)
				{
					var old = note[0];
					if (note[0] < section.startTime)
					{
						notes.push(note);
						removed.push(note);
					}
					if (note[0] > section.endTime)
					{
						notes.push(note);
						removed.push(note);
					}
				}

				for (i in removed)
				{
					section.sectionNotes.remove(i);
				}
			}

			for (section in cleanedSong.notes)
			{
				var saveRemove = [];

				for (i in notes)
				{
					if (i[0] >= section.startTime && i[0] < section.endTime)
					{
						saveRemove.push(i);
						section.sectionNotes.push(i);
					}
				}

				for (i in saveRemove)
					notes.remove(i);
			}

			SONG = cleanedSong;
		}
		else
		{
			for (section in SONG.notes)
			{
				var removed = [];

				for (note in section.sectionNotes)
				{
					var old = note[0];
					if (note[0] < section.startTime)
					{
						notes.push(note);
						removed.push(note);
					}
					if (note[0] > section.endTime)
					{
						notes.push(note);
						removed.push(note);
					}
				}

				for (i in removed)
				{
					section.sectionNotes.remove(i);
				}
			}

			for (section in SONG.notes)
			{
				var saveRemove = [];

				for (i in notes)
				{
					if (i[0] >= section.startTime && i[0] < section.endTime)
					{
						saveRemove.push(i);
						section.sectionNotes.push(i);
					}
				}

				for (i in saveRemove)
					notes.remove(i);
			}

			SONG = cleanedSong;
		}
	}

	override function add(Object:FlxBasic):FlxBasic
	{
		trackedAssets.insert(trackedAssets.length, Object);
		return super.add(Object);
	}

	function unloadAssets():Void{
		if (FlxG.save.data.unload){
			for (asset in trackedAssets){
				remove(asset);
			}
		}
	}

	override function destroy(){
		#if FEATURE_HSCRIPT
		scripts.destroy();
		#end
		super.destroy();
	}
	function HealthDrain():Void
	{
		//FlxG.sound.play(Paths.sound("Vine Boom"), 2);
		//boyfriend.playAnim("hit", true);
		new FlxTimer().start(0.01, function(tmr:FlxTimer)
		{
			health -= 0.005;
		}, 300);
	}

	public static function cancelMusicFadeTween()
	{
		if (FlxG.sound.music.fadeTween != null)
		{
			FlxG.sound.music.fadeTween.cancel();
		}
		FlxG.sound.music.fadeTween = null;
	}

	function ttweenCamIn():Void
	{
		FlxTween.tween(FlxG.camera, {zoom: 2}, (Conductor.stepCrochet * 4 / 1000), {ease: FlxEase.elasticInOut});
	}

	#if FEATURE_HSCRIPT
	function initScripts()
	{
		if (scripts == null)
			return;

		var scriptData:Map<String, String> = [];

		// SONG && GLOBAL SCRIPTS
		var files:Array<String> = SONG.songId == null ? [] : ScriptUtil.findScriptsInDir(Paths.getPreloadPath("data/songs/" + Paths.formatToSongPath(SONG.songId)));
		
		if (FileSystem.exists("assets/scripts/states/playstate"))
		{
			for (_ in ScriptUtil.findScriptsInDir("assets/scripts/states/playstate"))
				files.push(_);
		}
		if (FlxG.save.data.gen)
			Debug.logTrace(files);

		for (file in files)
		{
			var hx:Null<String> = null;

			if (FileSystem.exists(file))
				hx = File.getContent(file);


			if (hx != null)
			{
				var scriptName:String = CoolUtil.getFileStringFromPath(file);

				if (!scriptData.exists(scriptName))
				{
					scriptData.set(scriptName, hx);
				}
			}
		}

		for (scriptName => hx in scriptData)
		{
			if (scripts.getScriptByTag(scriptName) == null)
				scripts.addScript(scriptName).executeString(hx);
			else
			{
				scripts.getScriptByTag(scriptName).error("Duplacite Script Error!", '$scriptName: Duplicate Script');
			}
		}
	}

	private var eventsPushed:Array<Dynamic> = [];

	public function initSongEvents()
	{
		if (!FileSystem.exists("assets/scripts/events"))
			return;

		var hxFiles:Map<String, String> = [];

		for (scriptName => hxData in hxFiles)
		{
			if (scripts.getScriptByTag(scriptName) == null)
				scripts.addScript(scriptName).executeString(hxData);
			else
			{
				scripts.getScriptByTag(scriptName).error("Duplacite Script Error!", '$scriptName: Duplicate Script');
			}
		}
	}

	function initEventScript(name:String) {}

	function onAddScript(script:Script)
	{
		script.set("PlayState", PlayState);
		script.set("game", PlayState.instance);
		script.set("Debug", Debug);
		script.set("health", health);

		// FUNCTIONS

		//  CREATION FUNCTIONS
		script.set("create", function() {});
		script.set("createPost", function() {});

		//  COUNTDOWN
		script.set("countdown", function() {});
		script.set("countTick", function(?tick:Int) {});

		//  SONG FUNCTIONS
		script.set("startSong", function() {}); // ! HAS PAUSE
		script.set("endSong", function() {}); // ! HAS PAUSE
		script.set("beatHit", function(?beat:Int) {});
		script.set("stepHit", function(?step:Int) {});

		//  NOTE FUNCTIONS
		script.set("spawnNote", function(?note:Note) {}); // ! HAS PAUSE
		script.set("goodNoteHit", function(?note:Note) {});
		script.set("opponentNoteHit", function(?note:Note) {});
		script.set("noteMiss", function(?note:Note) {});

		script.set("playerOneTurn", function(?note:Note)
		{
		});
		script.set("playerTwoTurn", function(?note:Note)
		{
		});
		script.set("noteMiss", function(?note:Note)
		{
		});

		script.set("notesUpdate", function() {}); // ! HAS PAUSE

		script.set("ghostTap", function(?direction:Int) {});

		//  EVENT FUNCTIONS
		script.set("event", function(?event:String, ?val1:Dynamic, ?val2:Dynamic) {}); // ! HAS PAUSE

		//  PAUSING / RESUMING
		script.set("pause", function() {}); // ! HAS PAUSE
		script.set("resume", function() {}); // ! HAS PAUSE

		//  GAMEOVER
		script.set("gameOver", function() {}); // ! HAS PAUSE

		//  MISC
		script.set("update", function(?elapsed:Float) {});	
		script.set("updatePost", function(?elapsed:Float) {});
		script.set("updateScore", function(?miss:Bool = false) {}); // ! HAS PAUSE

		// VARIABLES

		script.set("curStep", 0);
		script.set("curBeat", 0);
		script.set("bpm", 0);

		// OBJECTS
		script.set("camGame", camGame);
		script.set("camHUD", camHUD);
		script.set("camFollow", camFollow);

		// CHARACTERS
		script.set("boyfriend", boyfriend);
		script.set("dad", dad);
		script.set("gf", gf);

		// NOTES
		script.set("notes", notes);
		script.set("strumLineNotes", strumLineNotes);

		script.set("unspawnNotes", unspawnNotes);

		// MISC
		script.set("add", function(obj:FlxBasic, ?front:Bool = false)
		{
			if (front)
			{
				getInstance().add(obj);
			}
			else
			{
				if (PlayState.instance.isDead)
				{
					GameOverSubstate.instance.insert(GameOverSubstate.instance.members.indexOf(GameOverSubstate.instance.bf), obj);
				}
				else
				{
					var position:Int = PlayState.instance.members.indexOf(PlayState.gf);
					if (PlayState.instance.members.indexOf(PlayState.boyfriend) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.boyfriend);
					}
					else if (PlayState.instance.members.indexOf(PlayState.dad) < position)
					{
						position = PlayState.instance.members.indexOf(PlayState.dad);
					}
					PlayState.instance.insert(position, obj);
				}
			}
		});
	}
	#end

	public static inline function getInstance()
	{
		return PlayState.instance.isDead ? GameOverSubstate.instance : PlayState.instance;
	}

	public function createTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween
	{
		var tween:FlxTween = tweenManager.tween(Object, Values, Duration, Options);
		tween.manager = tweenManager;
		return tween;
	}

	public function createTweenNum(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween
	{
		var tween:FlxTween = tweenManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
		tween.manager = tweenManager;
		return tween;
	}

	public function createTimer(Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
	{
		var timer:FlxTimer = new FlxTimer();
		timer.manager = timerManager;
		return timer.start(Time, OnComplete, Loops);
	}

	function set_scrollSpeed(value:Float):Float // STOLEN FROM PSYCH ENGINE ONLY SPRITE SCALING PART.
	{
		speedChanged = true;
		if (generatedMusic)
		{
			var ratio:Float = value / scrollSpeed;
			for (note in notes)
			{
				if (note.animation.curAnim != null)
					if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					{
						note.scale.y *= ratio;
						note.updateHitbox();
					}
			}
			for (note in unspawnNotes)
			{
				if (note.animation.curAnim != null)
					if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end'))
					{
						note.scale.y *= ratio;
						note.updateHitbox();
					}
			}
		}
		scrollSpeed = value;
		return value;
	}

	public function precacheThing(target:String, type:String, ?library:String = null)
	{
		switch (type)
		{
			case 'image':
				Paths.image2(target, library);
			case 'sound':
				Paths.sound(target, library);
			case 'music':
				Paths.music(target, library);
		}
	}

	public static function getFlxEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}

	function removeStaticArrows(?destroy:Bool = false)
	{
		if (arrowsGenerated)
		{
			playerStrums.forEach(function(babyArrow:StaticArrow)
			{
				playerStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			cpuStrums.forEach(function(babyArrow:StaticArrow)
			{
				cpuStrums.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			strumLineNotes.forEach(function(babyArrow:StaticArrow)
			{
				strumLineNotes.remove(babyArrow);
				if (destroy)
					babyArrow.destroy();
			});
			arrowsGenerated = false;
		}
	}

	private function addSongTiming()
	{
		TimingStruct.clearTimings();

		var currentIndex = 0;
		for (i in SONG.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.position;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				var bpm = i.value * songMultiplier;

				TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = ((data.endBeat - (data.startBeat)) / (data.bpm / 60));
					var step = ((60 / (data.bpm)) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}

		recalculateAllSectionTimes();
	}
	
	function playCutscene(name:String, ?atend:Bool)
	{
		#if VIDEOS
		inCutscene = true;

		var diff:String = CoolUtil.suffixDiffsArray[storyDifficulty];

		var video:VideoHandler = new VideoHandler();
		FlxG.sound.music.stop();
		video.finishCallback = function()
		{
			if (atend == true)
			{
				if (storyPlaylist.length <= 0)
					LoadingState.loadAndSwitchState(new StoryMenuState());
				else
				{
					SONG = Song.loadFromJson(storyPlaylist[0].toLowerCase(), diff);
					LoadingState.loadAndSwitchState(new PlayState());
				}
			}
			else
				startCountdown();
		}
		video.playVideo(Paths.video(name));
		#else
		FlxG.log.warn("Platform Not Supported.");
		#end
	}
}

typedef SplashData =
{
	/**
	 * The name of this animation.
	 */
	var name:String;
	/**
	 * The frame rate of this animation.
	 		* @default 24
	 */
	var fps:Int;

	/**
	 * The transparency of the notesplashes.
	 		* @default 24
	 */
	var alpha:Int;

	/**
	 * The X Offset so it can be centered better.
	 		* @default 90
	 */
	var xOffset:Int;

	/**
	 * The Y Offset so it can be centered better.
	 		* @default 80
	 */
	var yOffset:Int;	
	//theres gonna be more but the fps fucks me so much rn
}
