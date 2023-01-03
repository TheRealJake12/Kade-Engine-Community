package;

import openfl.utils.Future;
import openfl.media.Sound;
import flixel.system.FlxSound;
#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import Song.SongData;
import flixel.input.gamepad.FlxGamepad;
import flash.text.TextField;
import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import FreeplaySubState;
import Modifiers;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import Script;
import flixel.tweens.FlxEase;
import flixel.util.FlxTimer;
import flixel.FlxCamera;
import debug.AnimationDebug;
import debug.ChartingState;

using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var songs:Array<FreeplaySongMetadata> = [];
	public static var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	var selector:FlxText;

	public static var rate:Float = 1.0;

	public static var curSelected:Int = 0;

	public static var curPlayed:Int = 0;
	#if FEATURE_HSCRIPT
	// Hscript
	public var script:Script;
	#end

	public static var curDifficulty:Int = 1;
	public var executeHScript = false;
	public var runHscript = false;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var diffCalcText:FlxText;
	var previewtext:FlxText;
	var helpText:FlxText;
	var lerpScore:Int = 0;
	var intendedaccuracy:Float = 0.00;
	var intendedScore:Int = 0;
	var letter:String;
	var combo:String = 'N/A';
	var lerpaccuracy:Float = 0.00;

	var intendedColor:Int;
	var colorTween:FlxTween;

	var bg:FlxSprite;

	var Inst:FlxSound;
	var opponentText:FlxText;

	public static var openMod:Bool = false;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	private static var curPlaying:Bool = false;

	public static var songText:Alphabet;

	private var iconArray:Array<HealthIcon> = [];

	public static var icon:HealthIcon;

	public static var songData:Map<String, Array<SongData>> = [];

	public static var instance:FreeplayState;

	public static function loadDiff(diff:Int, songId:String, array:Array<SongData>)
		array.push(Song.conversionChecks(Song.loadFromJson(songId, CoolUtil.suffixDiffsArray[diff])));

	public static var list:Array<String> = [];

	override function create()
	{
		FlxG.mouse.visible = true;
		instance = this;
		
		Main.dumpCache();
			
		Paths.clearStoredMemory();
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		#if FEATURE_HSCRIPT
			executeHScript = OpenFlAssets.exists(Paths.hx('assets/scripts/states/freeplay/script'));
		#end

		if (FlxG.save.data.gen)
		{
			Debug.logInfo('Freeplay Script? $executeHScript at ${Paths.hx('assets/scripts/states/freeplay/script')}');
		}

		cached = false;

		bg = new FlxSprite().loadGraphic(Paths.image2('menuDesat'));

		/*for (i in 0...songs.length - 1)
			songs[i].diffs.reverse(); */

		populateSongData();
		PlayState.inDaPlay = false;
		PlayState.currentSong = "bruh";

		#if !FEATURE_STEPMANIA
		if (FlxG.save.data.gen)
			Debug.logTrace("FEATURE_STEPMANIA was not specified during build, sm file loading is disabled.");
		#elseif FEATURE_STEPMANIA
		// TODO: Refactor this to use OpenFlAssets.
		if (FlxG.save.data.gen)
			trace("tryin to load sm files");
		for (i in FileSystem.readDirectory("assets/sm/"))
		{
			if (FileSystem.isDirectory("assets/sm/" + i))
			{
				trace("Reading SM file dir " + i);
				for (file in FileSystem.readDirectory("assets/sm/" + i))
				{
					if (file.contains(" "))
						FileSystem.rename("assets/sm/" + i + "/" + file, "assets/sm/" + i + "/" + file.replace(" ", "_"));
					if (file.endsWith(".sm") && !FileSystem.exists("assets/sm/" + i + "/converted.json"))
					{
						trace("reading " + file);
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						trace("Converting " + file.header.TITLE);
						var data = file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", file, "assets/sm/" + i);
						songs.push(meta);
						var song = Song.loadFromJsonRAW(data);
						songData.set(file.header.TITLE, [song, song, song]);
					}
					else if (FileSystem.exists("assets/sm/" + i + "/converted.json") && file.endsWith(".sm"))
					{
						trace("reading " + file);
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						trace("Converting " + file.header.TITLE);
						var data = file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", file, "assets/sm/" + i);
						songs.push(meta);
						var song = Song.loadFromJsonRAW(File.getContent("assets/sm/" + i + "/converted.json"));
						trace("got content lol");
						songData.set(file.header.TITLE, [song, song, song]);
					}
				}
			}
		}
		#end

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		persistentUpdate = persistentDraw = true;

		// LOAD CHARACTERS
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songFixedName = StringTools.replace(songs[i].songName, "-", " ");
			songText = new Alphabet(0, (70 * i) + 30, songFixedName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			icon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.65, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var bottomBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(Std.int(FlxG.width), 26, 0xFF000000);
		bottomBG.alpha = 0.6;
		add(bottomBG);

		var bottomText:String = #if !mobile #if PRELOAD_ALL "  Press SPACE to listen to the Song Instrumental / Click and scroll through the songs with your MOUSE /"
			+ #else "  Click and scroll through the songs with your MOUSE /"
			+ #end #end
		" Your offset is "
		+ FlxG.save.data.offset
		+ "ms "
		+ (FlxG.save.data.optimize ? "/ Optimized" : "");

		var downText:FlxText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, bottomText, 16);
		downText.setFormat(Paths.font("vcr.ttf"), 16, FlxColor.WHITE, LEFT);
		downText.scrollFactor.set();
		add(downText);

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 337, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		opponentText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		opponentText.font = scoreText.font;
		add(opponentText);

		comboText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		comboText.font = scoreText.font;
		add(comboText);

		diffText = new FlxText(scoreText.x, scoreText.y + 106, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		diffCalcText = new FlxText(scoreText.x, scoreText.y + 136, 0, "", 24);
		diffCalcText.font = scoreText.font;
		add(diffCalcText);

		previewtext = new FlxText(scoreText.x, scoreText.y + 166, 0, "Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >", 24);
		previewtext.font = scoreText.font;
		add(previewtext);

		helpText = new FlxText(scoreText.x, scoreText.y + 211, 0, "", 20);
		helpText.text = "LEFT-RIGHT to change Difficulty\n\n" + "SHIFT + LEFT-RIGHT to change Rate\n" + "if it's possible\n\n"
			+ "CTRL to open Gameplay Modifiers\n" + "";
		helpText.font = scoreText.font;
		helpText.color = 0xFFfaff96;
		add(helpText);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		if (!openMod)
		{
			changeSelection();
			changeDiff();
		}

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		PlayStateChangeables.modchart = FlxG.save.data.modcharts;
		PlayStateChangeables.botPlay = FlxG.save.data.botplay;
		PlayStateChangeables.opponentMode = FlxG.save.data.opponent;
		PlayStateChangeables.mirrorMode = FlxG.save.data.mirror;
		PlayStateChangeables.holds = FlxG.save.data.sustains;
		PlayStateChangeables.healthDrain = FlxG.save.data.hdrain;
		PlayStateChangeables.healthGain = FlxG.save.data.hgain;
		PlayStateChangeables.healthLoss = FlxG.save.data.hloss;
		PlayStateChangeables.practiceMode = FlxG.save.data.practice;
		PlayStateChangeables.skillIssue = FlxG.save.data.noMisses;

		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			Conductor.changeBPM(102);
		}

		#if desktop
		if (!FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
		{
			try
			{
				rate = 1;
				var hmm = songData.get(songs[curSelected].songName)[curDifficulty];
				FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0.7, true);
				curPlayed = curSelected;
				FlxG.sound.music.fadeIn(0.75, 0, 0.8);
				MainMenuState.freakyPlaying = false;

				Paths.clearUnusedMemory();
			}
			catch (e)
			{
				Debug.logError(e);
			}
		}
		#end

		#if FEATURE_HSCRIPT
		if (executeHScript)
		{
			startScript();
		}

		if (executeHScript && script != null)
		{
			script.executeFunc("create");
		}
		#end

		super.create();
		Paths.clearUnusedMemory();
	}

	public static var cached:Bool = false;

	/**
	 * Load song data from the data files.
	 */
	static function populateSongData()
	{
		cached = false;
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		songData = [];
		songs = [];

		for (i in 0...list.length)
		{
			var data:Array<String> = list[i].split(':');
			var songId = data[0];
			var color = data[3];

			if (color == null)
			{
				color = "#9271fd";
			}

			var meta = new FreeplaySongMetadata(songId, Std.parseInt(data[2]), data[1], FlxColor.fromString(color));

			var diffs = [];
			var diffsThatExist = [];

			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-easy')))
				diffsThatExist.push("Easy");
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId')))
				diffsThatExist.push("Normal");
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-hard')))
				diffsThatExist.push("Hard");

			var customDiffs = CoolUtil.coolTextFile(Paths.txt('data/songs/$songId/customDiffs'));

			if (customDiffs != null)
			{
				for (i in 0...customDiffs.length)
				{
					var cDiff = customDiffs[i];
					if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-${cDiff.toLowerCase()}')))
					{
						diffsThatExist.push(cDiff);
						CoolUtil.suffixDiffsArray.push('-${cDiff.toLowerCase()}');
						CoolUtil.difficultyArray.push(cDiff);
					}
				}
			}

			if (diffsThatExist.length == 0)
			{
				if (FlxG.fullscreen)
					FlxG.fullscreen = !FlxG.fullscreen;
			}

			if (diffsThatExist.contains("Easy"))
				FreeplayState.loadDiff(0, songId, diffs);
			if (diffsThatExist.contains("Normal"))
				FreeplayState.loadDiff(1, songId, diffs);
			if (diffsThatExist.contains("Hard"))
				FreeplayState.loadDiff(2, songId, diffs);

			if (customDiffs != null)
			{
				for (i in 0...customDiffs.length)
				{
					var cDiff = customDiffs[i];
					if (diffsThatExist.contains(cDiff))
						FreeplayState.loadDiff(CoolUtil.difficultyArray.indexOf(cDiff), songId, diffs);
				}
			}

			meta.diffs = diffsThatExist;

			if (diffsThatExist.length < 3)
				trace("I ONLY FOUND " + diffsThatExist);

			FreeplayState.songData.set(songId, diffs);
			FreeplayState.songs.push(meta);
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:String)
	{
		var meta = new FreeplaySongMetadata(songName, weekNum, songCharacter, FlxColor.fromString(color));

		var diffs = [];
		var diffsThatExist = [];

		if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName-easy')))
			diffsThatExist.push("Easy");
		if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName')))
			diffsThatExist.push("Normal");
		if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName-hard')))
			diffsThatExist.push("Hard");

		var customDiffs = CoolUtil.coolTextFile(Paths.txt('data/songs/$songName/customDiffs'));

		if (customDiffs != null)
		{
			for (i in 0...customDiffs.length)
			{
				var cDiff = customDiffs[i];
				if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName-${cDiff.toLowerCase()}')))
				{
					diffsThatExist.push(cDiff);
					CoolUtil.suffixDiffsArray.push('-${cDiff.toLowerCase()}');
					CoolUtil.difficultyArray.push(cDiff);
				}
			}
		}

		if (diffsThatExist.length == 0)
		{
			if (FlxG.fullscreen)
				FlxG.fullscreen = !FlxG.fullscreen;
		}

		if (diffsThatExist.contains("Easy"))
			FreeplayState.loadDiff(0, songName, diffs);
		if (diffsThatExist.contains("Normal"))
			FreeplayState.loadDiff(1, songName, diffs);
		if (diffsThatExist.contains("Hard"))
			FreeplayState.loadDiff(2, songName, diffs);

		if (customDiffs != null)
		{
			for (i in 0...customDiffs.length)
			{
				var cDiff = customDiffs[i];
				if (diffsThatExist.contains(cDiff))
					FreeplayState.loadDiff(CoolUtil.difficultyArray.indexOf(cDiff), songName, diffs);
			}
		}

		meta.diffs = diffsThatExist;

		if (diffsThatExist.length < 3)
			trace("I ONLY FOUND " + diffsThatExist);

		songData.set(songName, diffs);

		songs.push(meta);
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>, ?color:String)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num], color);

			if (songCharacters.length != 1)
				num++;
		}
	}

	public var updateFrame = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		Conductor.songPosition = FlxG.sound.music.time * rate;

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		lerpaccuracy = FlxMath.lerp(lerpaccuracy, intendedaccuracy, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1) / (openfl.Lib.current.stage.frameRate / 60));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (Math.abs(lerpaccuracy - intendedaccuracy) <= 0.001)
			lerpaccuracy = intendedaccuracy;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		if (combo == "")
		{
			comboText.text = "RANK: N/A";
			comboText.alpha = 0.5;
		}
		else
		{
			comboText.text = "RANK: " + letter + " | " + combo + " (" + HelperFunctions.truncateFloat(lerpaccuracy, 2) + "%)\n";
			comboText.alpha = 1;
		}

		opponentText.text = "OPPONENT MODE: " + (FlxG.save.data.opponent ? "ON" : "OFF");

		if (FlxG.sound.music.volume > 0.8)
		{
			FlxG.sound.music.volume -= 0.5 * FlxG.elapsed;
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = FlxG.keys.justPressed.ENTER && !FlxG.keys.pressed.ALT;
		var dadDebug = FlxG.keys.justPressed.SIX;
		var charting = FlxG.keys.justPressed.SEVEN;
		var bfDebug = FlxG.keys.justPressed.ZERO;

		#if FEATURE_HSCRIPT
		if (executeHScript && script != null)
		{
			script.setVariable('cameraZoom', FlxG.camera.zoom);
			script.executeFunc('update', [elapsed]);
		}
		#end

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (FlxG.mouse.wheel != 0)
			{
				#if desktop
				changeSelection(-FlxG.mouse.wheel);
				#else
				if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
					changeSelection(1);
				else if (FlxG.mouse.wheel > 0)
					changeSelection(-1);
				#end
			}
			
			if (upP || controls.UP_P)
			{
				changeSelection(-1);
			}
			if (downP || controls.DOWN_P)
			{
				changeSelection(1);
			}
		}
		previewtext.text = "Rate: " + FlxMath.roundDecimal(rate, 2) + "x";

		if (!MainMenuState.freakyPlaying)
		{
			var bpmRatio = Conductor.bpm / 100;

			var mult:Float = FlxMath.lerp(1, iconArray[curSelected].scale.x, CoolUtil.boundTo(1 - (elapsed * 35 * rate), 0, 1));
			iconArray[curSelected].scale.set(mult, mult);

			iconArray[curSelected].updateHitbox();
		}

		previewtext.alpha = 1;

		if (FlxG.keys.justPressed.CONTROL && !openMod && !MusicBeatState.switchingState)
		{
			openMod = true;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			openSubState(new FreeplaySubState.ModMenu());
		}

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (FlxG.keys.pressed.SHIFT) // && songs[curSelected].songName.toLowerCase() != "tutorial")
			{
				if (FlxG.keys.justPressed.LEFT || controls.LEFT_P)
				{
					rate -= 0.05;
					updateDiffCalc();
					updateScoreText();
				}
				if (FlxG.keys.justPressed.RIGHT || controls.RIGHT_P)
				{
					rate += 0.05;
					updateDiffCalc();
					updateScoreText();
				}

				if (FlxG.keys.justPressed.R)
				{
					rate = 1;
					updateDiffCalc();
					updateScoreText();
				}

				if (rate > 3)
				{
					rate = 3;
					updateDiffCalc();
					updateScoreText();
				}
				else if (rate < 0.5)
				{
					rate = 0.5;
					updateDiffCalc();
					updateScoreText();
				}

				previewtext.text = "Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >";
			}
			else
			{
				if (FlxG.keys.justPressed.LEFT || controls.LEFT_P)
					changeDiff(-1);
				if (FlxG.keys.justPressed.RIGHT || controls.RIGHT_P)
					changeDiff(1);
				
				if (FlxG.mouse.justPressedRight){
					changeDiff(1);
				}	
			}

			#if desktop
			if (FlxG.keys.justPressed.SPACE)
			{
				try
				{
					var hmm = songData.get(songs[curSelected].songName)[curDifficulty];
					FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0.7, true);
					curPlayed = curSelected;
					FlxG.sound.music.fadeIn(0.75, 0, 0.8);
					MainMenuState.freakyPlaying = false;

					Conductor.changeBPM(hmm.bpm);
					Conductor.mapBPMChanges(hmm);
					Conductor.bpm = hmm.bpm;

					Paths.clearUnusedMemory();
				}
				catch (e)
				{
					Debug.logError(e);
				}
			}
			#end
		}

		var hmm = songData.get(songs[curPlayed].songName)[curDifficulty];

		TimingStruct.clearTimings();
		var currentIndex = 0;
		if (hmm != null && hmm.eventObjects != null)
		{
			for (i in hmm.eventObjects)
			{
				if (i.type == "BPM Change")
				{
					var beat:Float = i.position * rate;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					var bpm = i.value * rate;

					TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset
					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = ((data.endBeat - data.startBeat) / (data.bpm / 60)) / rate;
						var step = (((60 / data.bpm) * 1000) / rate) / 4;

						TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step) / rate);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length / rate;
					}
					currentIndex++;
				}
			}
		}

		if (FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
		{
			var timingSeg = TimingStruct.getTimingAtBeat(curDecimalBeat);

			if (timingSeg != null)
			{
				var timingSegBpm = timingSeg.bpm;

				if (timingSegBpm != Conductor.bpm)
				{
					Conductor.changeBPM(timingSegBpm, false);
				}
			}
		}

		#if cpp
		@:privateAccess
		{
			if (FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
			{
				#if (lime >= "8.0.0")
				FlxG.sound.music._channel.__source.__backend.setPitch(rate);
				#else
				lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, rate);
				#end
			}
		}
		#elseif html5
		@:privateAccess
		{
			if (FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
			{
				#if (lime >= "8.0.0" && lime_howlerjs)
				FlxG.sound.music._channel.__source.__backend.setPitch(rate);
				#else
				FlxG.sound.music._channel.__source.__backend.parent.buffer.__srcHowl.rate(rate);
				#end
			}
		}
		#end

		#if html5
		diffCalcText.text = "RATING: N/A";
		diffCalcText.alpha = 0.5;
		#end

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (controls.BACK)
			{
				MusicBeatState.switchState(new MainMenuState());
				if (colorTween != null)
				{
					colorTween.cancel();
				}
			}

			for (item in grpSongs.members)
				if (accepted
					|| (((FlxG.mouse.overlaps(item) && item.targetY == 0) || (FlxG.mouse.overlaps(iconArray[curSelected])))
						&& FlxG.mouse.pressed))
				{
					loadSong();
					break;
				}
			#if debug
			// Going to charting state via Freeplay is only enable in debug builds.
			else if (charting)
				loadSong(true);

			// AnimationDebug and StageDebug are only enabled in debug builds.

			if (dadDebug)
			{
				loadAnimDebug(true);
			}
			if (bfDebug)
			{
				loadAnimDebug(false);
			}
			#end
		}

		if (openMod)
		{
			for (i in 0...iconArray.length)
				iconArray[i].alpha = 0;

			for (item in grpSongs.members)
				item.alpha = 0;
		}
	}

	override function beatHit()
	{
		super.beatHit();
	}

	override function stepHit()
	{
		super.stepHit();

		if (!MainMenuState.freakyPlaying)
		{

			if (FlxG.save.data.motion){
				if (curStep % Math.round(4 * rate) == 0)
				{
					iconArray[curSelected].scale.set(1.2, 1.2);

					iconArray[curSelected].updateHitbox();
				}
			}
		}
	}

	function loadAnimDebug(dad:Bool = true)
	{
		// First, get the song data.
		var hmm;
		try
		{
			hmm = songData.get(songs[curSelected].songName)[curDifficulty];
			if (hmm == null)
				return;
		}
		catch (ex)
		{
			return;
		}
		PlayState.SONG = hmm;

		var character = dad ? PlayState.SONG.player2 : PlayState.SONG.player1;

		LoadingState.loadAndSwitchState(new AnimationDebug(character));
	}

	function loadSong(isCharting:Bool = false)
	{
		loadSongInFreePlay(songs[curSelected].songName, curDifficulty, isCharting);
	}

	/**
	 * Load into a song in free play, by name.
	 * This is a static function, so you can call it anywhere.
	 * @param songName The name of the song to load. Use the human readable name, with spaces.
	 * @param isCharting If true, load into the Chart Editor instead.
	 */
	public static function loadSongInFreePlay(songName:String, difficulty:Int, isCharting:Bool, reloadSong:Bool = false)
	{
		// Make sure song data is initialized first.
		if (songData == null || Lambda.count(songData) == 0)
			populateSongData();

		var currentSongData;
		try
		{
			if (songData.get(songName) == null)
				return;

			currentSongData = songData.get(songName)[difficulty];

			if (songData.get(songName)[difficulty] == null)
				return;
		}
		catch (ex)
		{
			return;
		}
		
		PlayState.SONG = currentSongData;
		PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(songs[curSelected].diffs[difficulty]);
		PlayState.storyWeek = songs[curSelected].week;
		PlayState.isStoryMode = false;

		Debug.logInfo('Loading song ${PlayState.SONG.songName} from week ${PlayState.storyWeek} into Free Play...');
		#if FEATURE_STEPMANIA
		if (songs[curSelected].songCharacter == "sm")
		{
			PlayState.isSM = true;
			PlayState.sm = songs[curSelected].sm;
			PlayState.pathToSm = songs[curSelected].path;
		}
		else
			PlayState.isSM = false;
		#else
		PlayState.isSM = false;
		#end

		PlayState.songMultiplier = rate;

		if (isCharting)
			LoadingState.loadAndSwitchState(new ChartingState(reloadSong));
		else
			LoadingState.loadAndSwitchState(new PlayState());
	}

	override function destroy()
	{
		#if FEATURE_HSCRIPT
		if (executeHScript && script != null)
		{
			script.executeFunc("destroy");
			script.destroy();
		}
		#end
		super.destroy();
	}

	public function startScript()
	{
		#if FEATURE_HSCRIPT
		var path:String;

		if (Script.scriptName == null || Script.scriptName == '' || Script.scriptName == 'freeplay')
			path = Paths.hx('states/freeplay', 'scripts');
		else
			path = Paths.hx('states/freeplay', 'scripts');

		var hxdata:String = "";

		if (FileSystem.exists(path))
			hxdata = File.getContent(path);

		if (hxdata != "")
		{
			script = new Script(Script.scriptName);

			script.variables.set('setVar', function(name:String, value:Dynamic)
			{
				FreeplayState.variables.set(name, value);
			});

			script.variables.set('getVar', function(name:String)
			{
				var result:Dynamic = null;
				if (FreeplayState.variables.exists(name))
					result = FreeplayState.variables.get(name);
				return result;
			});

			script.variables.set('removeVar', function(name:String)
			{
				if (FreeplayState.variables.exists(name))
				{
					FreeplayState.variables.remove(name);
					return true;
				}
				return false;
			});
			script.setVariable("destroy", function()
			{
			});

			script.setVariable("create", function()
			{
			});
			script.setVariable("import", function(lib:String, ?as:Null<String>) // Does this even work?
			{
				if (lib != null && Type.resolveClass(lib) != null)
				{
					script.setVariable(as != null ? as : lib, Type.resolveClass(lib));
				}
			});
			script.setVariable("update", function()
			{
			});
			script.setVariable("fromRGB", function(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255)
			{
				return FlxColor.fromRGB(Red, Green, Blue, Alpha);
			});

			// Move the shits

			// PRESET CLASSES
			script.setVariable("PlayState", instance);
			script.setVariable("FlxTween", FlxTween);
			script.setVariable("TweenManager", PlayState.tweenManager);
			script.setVariable("FlxEase", FlxEase);
			script.setVariable("FlxSprite", FlxSprite);
			script.setVariable("Math", Math);
			script.setVariable("FlxG", FlxG); // maybe handle save data??
			script.setVariable("FlxTimer", FlxTimer);
			script.setVariable("Main", Main);
			script.setVariable("Conductor", Conductor);
			script.setVariable("Std", Std);
			script.setVariable("FlxTextBorderStyle", FlxTextBorderStyle);
			script.setVariable("Paths", Paths);
			script.setVariable("CENTER", FlxTextAlign.CENTER);
			script.setVariable("FlxTextFormat", FlxTextFormat);
			script.setVariable("FlxTextFormatMarkerPair", FlxTextFormatMarkerPair);
			script.setVariable("FlxCamera", FlxCamera);
			script.setVariable("Alphabet", Alphabet);

			script.setVariable("Debug", Debug);
			script.setVariable("KadeEngineData", KadeEngineData);
			

			script.runScript(hxdata);
		}
		#end
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = songs[curSelected].diffs.length-1;
		if (curDifficulty >= songs[curSelected].diffs.length)
			curDifficulty = 0;	

		updateScoreText();
		updateDiffCalc();
		diffText.text = 'DIFFICULTY: < ' + songs[curSelected].diffs[curDifficulty].toUpperCase() + ' >';
	}

	function updateScoreText()
	{
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		// adjusting the highscore song name to be compatible (changeDiff)
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
			case 'M.I.L.F':
				songHighscore = 'Milf';
		}
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty, rate);
		combo = Highscore.getCombo(songHighscore, curDifficulty, rate);
		letter = Highscore.getLetter(songHighscore, curDifficulty, rate);
		intendedaccuracy = Highscore.getAcc(songHighscore, curDifficulty, rate);
		#end
	}

	public function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		changeDiff();

		var newColor:Int = songs[curSelected].color;
		if (newColor != intendedColor)
		{
			if (colorTween != null)
			{
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 0.5, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween)
				{
					colorTween = null;
				}
			});
		}
		var songHighscore = StringTools.replace(songs[curSelected].songName, " ", "-");
		switch (songHighscore)
		{
			case 'Dad-Battle':
				songHighscore = 'Dadbattle';
			case 'Philly-Nice':
				songHighscore = 'Philly';
			case 'M.I.L.F':
				songHighscore = 'Milf';
		}

		updateScoreText();

		var hmm;
		try
		{
			hmm = songData.get(songs[curSelected].songName)[curDifficulty];
			if (hmm != null)
				GameplayCustomizeState.freeplayNoteStyle = hmm.noteStyle;
		}
		catch (ex)
		{
		}

		var bullShit:Int = 0;

		if (!openMod && !MusicBeatState.switchingState)
		{
			for (i in 0...iconArray.length)
			{
				iconArray[i].alpha = 0.6;
			}

			iconArray[curSelected].alpha = 1;
		}

		for (item in grpSongs.members)
		{
			if (!openMod && !MusicBeatState.switchingState)
			{
				item.targetY = bullShit - curSelected;
				bullShit++;

				item.alpha = 0.6;
				// item.setGraphicSize(Std.int(item.width * 0.8));

				if (item.targetY == 0)
				{
					item.alpha = 1;
					// item.setGraphicSize(Std.int(item.width));
				}
			}
		}
	}

	public function updateDiffCalc():Void
	{
		if (songData.get(songs[curSelected].songName)[curDifficulty] != null)
		{
			diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			diffCalcText.alpha = 1;
			diffText.alpha = 1;
		}
		else
		{
			Debug.logError('Error on calculating difficulty rate from song: ${songs[curSelected].songName}');
			diffCalcText.alpha = 0.5;
			diffText.alpha = 0.5;
			diffCalcText.text = 'RATING: N/A';
		}
	}
}

class FreeplaySongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	#if FEATURE_STEPMANIA
	public var sm:SMFile;
	public var path:String;
	#end
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var diffs = [];

	#if FEATURE_STEPMANIA
	public function new(song:String, week:Int, songCharacter:String, ?color:FlxColor, ?sm:SMFile = null, ?path:String = "")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.sm = sm;
		this.path = path;
	}
	#else
	public function new(song:String, week:Int, songCharacter:String, ?color:FlxColor)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
	}
	#end
}
