package kec.states;

import kec.objects.CoolText;
import kec.backend.chart.Song.Style;
import kec.backend.util.DiffCalc;
import kec.backend.PlayStateChangeables;
import kec.backend.chart.TimingStruct;
import openfl.media.Sound;
import flixel.effects.FlxFlicker;
#if FEATURE_STEPMANIA
import kec.backend.util.smTools.SMFile;
#end
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import kec.backend.chart.Song.SongData;
import lime.app.Application;
import flash.text.TextField;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_DISCORD
import kec.backend.Discord;
#end
import kec.substates.FreeplaySubState;
import kec.backend.Modifiers;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import kec.states.editors.ChartingState;
import kec.objects.Alphabet;
import kec.objects.ui.HealthIcon;
import kec.backend.chart.Song;
import kec.backend.util.Highscore;
import kec.backend.util.HelperFunctions;

class FreeplayState extends MusicBeatState
{
	public var songs:Array<FreeplaySongMetadata> = [];

	private var camGame:FlxCamera;
	var lerpSelected:Float = 0;

	public static var rate:Float = 1.0;
	public static var lastRate:Float = 1.0;
	public static var currentSongPlaying:String = '';

	public static var curSelected:Int = 0;

	public static var curPlayed:Int = 0;

	public static var curDifficulty:Int = 1;

	var scoreText:CoolText;
	var comboText:CoolText;
	var diffText:CoolText;
	var diffCalcText:CoolText;
	var previewtext:CoolText;
	var helpText:CoolText;
	var opponentText:CoolText;
	var lerpScore:Int = 0;
	var intendedaccuracy:Float = 0.00;
	var intendedScore:Int = 0;
	var letter:String;
	var combo:String = 'N/A';
	var lerpaccuracy:Float = 0.00;

	var intendedColor:Int;
	var colorTween:FlxTween;

	var bg:FlxSprite;

	var inst:FlxSound = null;

	public static var openMod:Bool = false;

	private var grpSongs:FlxTypedGroup<Alphabet>;

	private static var curPlaying:Bool = false;

	public static var songText:Alphabet;

	private var iconArray:Array<HealthIcon> = [];

	public static var icon:HealthIcon;

	public var songData:Map<String, Array<SongData>> = [];

	public static var instance:FreeplayState = null;

	public static var loadedSongData:Bool = false;

	public static var songRating:Map<String, Dynamic> = [];

	public static var songRatingOp:Map<String, Dynamic> = [];
	public static var doUpdateText:Bool = true;
	public static var alreadyPressed:Bool = false;

	function loadDiff(diff:Int, songId:String, array:Array<SongData>)
		array.push(Song.loadFromJson(songId, CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[diff])));

	public static var list:Array<String> = [];

	override function create()
	{var stamp = haxe.Timer.stamp();
		instance = this;
		PlayState.SONG = null;
		FlxG.mouse.visible = true;
		alreadyPressed = false;
		doUpdateText = true;

		#if desktop
		Application.current.window.title = '${MainMenuState.kecVer} : In the Menus';
		#end

		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));
		cached = false;

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));

		PlayState.inDaPlay = false;

		/*for (i in 0...songs.length - 1)
			songs[i].diffs.reverse(); */

		populateSongData();

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		Discord.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		camGame = new FlxCamera();
		FlxG.cameras.reset(new FlxCamera());

		persistentUpdate = persistentDraw = true;

		// LOAD CHARACTERS
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songFixedName = StringTools.replace(songs[i].songName, "-", " ");
			songText = new Alphabet(90, 320, songFixedName, true);
			songText.targetY = i;
			grpSongs.add(songText);

			icon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			songText.visible = songText.active = songText.isMenuItem = false;
			icon.visible = icon.active = false;

			iconArray.push(icon);
			add(icon);
		}

		scoreText = new CoolText(FlxG.width * 0.6525, 10, 31, 31, Paths.bitmapFont('fonts/vcr'));
		scoreText.autoSize = true;
		scoreText.fieldWidth = FlxG.width;
		scoreText.antialiasing = FlxG.save.data.antialiasing;

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

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 337, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		var downText:CoolText = new CoolText(bottomBG.x, bottomBG.y + 4, 14.5, 16, Paths.bitmapFont('fonts/vcr'));
		downText.autoSize = true;
		downText.antialiasing = FlxG.save.data.antialiasing;
		downText.scrollFactor.set();
		downText.text = bottomText;
		downText.updateHitbox();
		add(downText);

		comboText = new CoolText(scoreText.x, scoreText.y + 36, 23, 23, Paths.bitmapFont('fonts/vcr'));
		comboText.autoSize = true;

		comboText.antialiasing = FlxG.save.data.antialiasing;
		add(comboText);

		opponentText = new CoolText(scoreText.x, scoreText.y + 66, 23, 23, Paths.bitmapFont('fonts/vcr'));
		opponentText.autoSize = true;

		opponentText.antialiasing = FlxG.save.data.antialiasing;
		add(opponentText);

		diffText = new CoolText(scoreText.x, scoreText.y + 106, 23, 23, Paths.bitmapFont('fonts/vcr'));

		diffText.antialiasing = FlxG.save.data.antialiasing;
		add(diffText);

		diffCalcText = new CoolText(scoreText.x, scoreText.y + 136, 23, 23, Paths.bitmapFont('fonts/vcr'));
		diffCalcText.autoSize = true;

		diffCalcText.antialiasing = FlxG.save.data.antialiasing;
		add(diffCalcText);

		previewtext = new CoolText(scoreText.x, scoreText.y + 166, 23, 23, Paths.bitmapFont('fonts/vcr'));
		previewtext.text = "Rate: < " + FlxMath.roundDecimal(rate, 2) + "x >";
		previewtext.autoSize = true;

		previewtext.antialiasing = FlxG.save.data.antialiasing;

		add(previewtext);

		helpText = new CoolText(scoreText.x, scoreText.y + 200, 18, 18, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.text = "LEFT-RIGHT to change Difficulty\n\n" + "SHIFT + LEFT-RIGHT to change Rate\n" + "if it's possible\n\n"
			+ "CTRL to open Gameplay Modifiers\n" + "";

		helpText.antialiasing = FlxG.save.data.antialiasing;
		helpText.color = 0xFFfaff96;
		helpText.updateHitbox();
		add(helpText);

		add(scoreText);

		if (curSelected >= songs.length)
			curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;
		lerpSelected = curSelected;

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
			MainMenuState.freakyPlaying = true;
			Conductor.changeBPM(102);
		}

		if (!FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
		{
			dotheMusicThing();
		}

		updateTexts();

		if (!openMod)
		{
			changeSelection();
			changeDiff();
		}

		super.create();
		Paths.clearUnusedMemory();
		Debug.logTrace("Took " + Std.string(FlxMath.roundDecimal(haxe.Timer.stamp() - stamp, 3)) + " Seconds To Load Freeplay.");
	}

	public static var cached:Bool = false;

	/**
	 * Load song data from the data files.
	 */
	function populateSongData()
	{
		cached = false;
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

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

			for (i in 0...CoolUtil.difficultyArray.length)
			{
				var leDiff = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[i]);
				if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId$leDiff')))
					diffsThatExist.push(CoolUtil.difficultyArray[i]);
			}

			var customDiffs = CoolUtil.coolTextFile(Paths.txt('data/songs/$songId/customDiffs'));

			if (customDiffs != null)
			{
				for (i in 0...customDiffs.length)
				{
					var cDiff = customDiffs[i];
					if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-${cDiff.toLowerCase()}')))
					{
						if (FlxG.save.data.gen)
							Debug.logTrace('New Difficulties detected for $songId: $cDiff');
						if (!diffsThatExist.contains(cDiff))
							diffsThatExist.push(cDiff);

						if (!CoolUtil.difficultyArray.contains(cDiff))
							CoolUtil.difficultyArray.push(cDiff);
					}
				}
			}

			if (diffsThatExist.length == 0)
			{
				if (FlxG.fullscreen)
					FlxG.fullscreen = !FlxG.fullscreen;
				Debug.displayAlert(meta.songName + " Chart", "No difficulties found for chart, skipping.");
			}

			if (!loadedSongData)
			{
				for (i in 0...CoolUtil.difficultyArray.length)
				{
					var leDiff = CoolUtil.difficultyArray[i];
					if (diffsThatExist.contains(leDiff))
						loadDiff(CoolUtil.difficultyArray.indexOf(leDiff), songId, diffs);
				}
				if (customDiffs != null)
				{
					for (i in 0...customDiffs.length)
					{
						var cDiff = customDiffs[i];
						if (diffsThatExist.contains(cDiff))
							loadDiff(CoolUtil.difficultyArray.indexOf(cDiff), songId, diffs);
					}
				}

				songData.set(songId, diffs);

				if (songData.get(songId) != null)
					for (diff in songData.get(songId))
					{
						var leData = songData.get(songId)[songData.get(songId).indexOf(diff)];
						if (!songRating.exists(leData.songId))
							songRating.set(Highscore.formatSong(leData.songId, songData.get(songId).indexOf(diff), 1), DiffCalc.CalculateDiff(leData));

						if (!songRatingOp.exists(leData.songId))
							songRatingOp.set(Highscore.formatSong(leData.songId, songData.get(songId).indexOf(diff), 1), DiffCalc.CalculateDiff(leData, true));
					}
			}

			meta.diffs = diffsThatExist;
			songs.push(meta);
		}

		#if FEATURE_STEPMANIA
		for (i in FileSystem.readDirectory("assets/sm/"))
		{
			if (FileSystem.isDirectory("assets/sm/" + i))
			{
				for (file in FileSystem.readDirectory("assets/sm/" + i))
				{
					if (file.contains(" "))
						FileSystem.rename("assets/sm/" + i + "/" + file, "assets/sm/" + i + "/" + file.replace(" ", "_"));
					if (file.endsWith(".sm") && !FileSystem.exists("assets/sm/" + i + "/converted.json"))
					{
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						file.jsonPath = "assets/sm/" + i + "/converted.json";
						var data = file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", FlxColor.fromString("#9a9b9c"), file, "assets/sm/" + i);
						meta.diffs = ['Normal'];
						songs.push(meta);
						var song = Song.loadFromJsonRAW(data);
						instance.songData.set(file.header.TITLE, [song]);

						if (songData.get(song.songId) != null)
						{
							for (diff in songData.get(song.songId))
							{
								if (!songRating.exists(song.songId))
									songRating.set(Highscore.formatSong(song.songId, songData.get(song.songId)
										.indexOf(diff), 1), DiffCalc.CalculateDiff(song));

								if (!songRatingOp.exists(song.songId))
									songRatingOp.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song, true));
							}
						}
					}
					else if (FileSystem.exists("assets/sm/" + i + "/converted.json") && file.endsWith(".sm"))
					{
						var file:SMFile = SMFile.loadFile("assets/sm/" + i + "/" + file.replace(" ", "_"));
						file.jsonPath = "assets/sm/" + i + "/converted.json";

						file.convertToFNF("assets/sm/" + i + "/converted.json");
						var meta = new FreeplaySongMetadata(file.header.TITLE, 0, "sm", FlxColor.fromString("#9a9b9c"), file, "assets/sm/" + i);
						meta.diffs = ['Normal'];
						songs.push(meta);
						var song = Song.loadFromJsonRAW(File.getContent("assets/sm/" + i + "/converted.json"));

						instance.songData.set(file.header.TITLE, [song]);

						if (songData.get(song.songId) != null)
						{
							for (diff in songData.get(song.songId))
							{
								if (!songRating.exists(song.songId))
									songRating.set(Highscore.formatSong(song.songId, songData.get(song.songId)
										.indexOf(diff), 1), DiffCalc.CalculateDiff(song));

								if (!songRatingOp.exists(song.songId))
									songRatingOp.set(Highscore.formatSong(song.songId, songData.get(song.songId).indexOf(diff), 1),
										DiffCalc.CalculateDiff(song, true));
							}
						}
					}
				}
			}
		}
		#end

		instance.songData.clear();
		loadedSongData = true;
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:String)
	{
		if (color == null)
		{
			color = "#9271fd";
		}
		var meta = new FreeplaySongMetadata(songName, weekNum, songCharacter, FlxColor.fromString(color));

		var diffs = [];
		var diffsThatExist = [];

		for (i in 0...CoolUtil.difficultyArray.length)
		{
			var leDiff = CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[i]);
			if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName$leDiff')))
				diffsThatExist.push(CoolUtil.difficultyArray[i]);
		}

		var customDiffs = CoolUtil.coolTextFile(Paths.txt('data/songs/$songName/customDiffs'));

		if (customDiffs != null)
		{
			for (i in 0...customDiffs.length)
			{
				var cDiff = customDiffs[i];
				if (Paths.doesTextAssetExist(Paths.json('songs/$songName/$songName-${cDiff.toLowerCase()}')))
				{
					Debug.logTrace('New Difficulties detected for $songName: $cDiff');
					if (!diffsThatExist.contains(cDiff))
						diffsThatExist.push(cDiff);

					if (!CoolUtil.difficultyArray.contains(cDiff))
						CoolUtil.difficultyArray.push(cDiff);
				}
			}
		}

		if (diffsThatExist.length == 0)
		{
			if (FlxG.fullscreen)
				FlxG.fullscreen = !FlxG.fullscreen;
			Debug.displayAlert(meta.songName + " Chart", "No difficulties found for chart, skipping.");
		}

		if (!loadedSongData)
		{
			for (i in 0...CoolUtil.difficultyArray.length)
			{
				var leDiff = CoolUtil.difficultyArray[i];
				if (diffsThatExist.contains(leDiff))
					loadDiff(CoolUtil.difficultyArray.indexOf(leDiff), songName, diffs);
			}
			if (customDiffs != null)
			{
				for (i in 0...customDiffs.length)
				{
					var cDiff = customDiffs[i];
					if (diffsThatExist.contains(cDiff))
						loadDiff(CoolUtil.difficultyArray.indexOf(cDiff), songName, diffs);
				}
			}

			songData.set(songName, diffs);
			trace('loaded diffs for ' + songName);

			if (songData.get(songName) != null)
				for (diff in songData.get(songName))
				{
					var leData = songData.get(songName)[songData.get(songName).indexOf(diff)];
					if (!songRating.exists(leData.songId))
						songRating.set(Highscore.formatSong(leData.songId, songData.get(songName).indexOf(diff), 1), DiffCalc.CalculateDiff(leData));

					if (!songRatingOp.exists(leData.songId))
						songRatingOp.set(Highscore.formatSong(leData.songId, songData.get(songName).indexOf(diff), 1), DiffCalc.CalculateDiff(leData, true));
				}
		}
		meta.diffs = diffsThatExist;
		instance.songs.push(meta);

		instance.songData.clear();
		loadedSongData = true;
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
		Conductor.songPosition = FlxG.sound.music.time * rate;

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

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

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		lerpaccuracy = FlxMath.lerp(lerpaccuracy, intendedaccuracy, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1) / (openfl.Lib.current.stage.frameRate / 60));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		if (Math.abs(lerpaccuracy - intendedaccuracy) <= 0.001)
			lerpaccuracy = intendedaccuracy;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		scoreText.updateHitbox();
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
		comboText.updateHitbox();

		opponentText.text = "OPPONENT MODE: " + (FlxG.save.data.opponent ? "ON" : "OFF");
		opponentText.updateHitbox();

		if (FlxG.sound.music.volume > 0.8)
		{
			FlxG.sound.music.volume -= 0.5 * FlxG.elapsed;
		}
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = FlxG.keys.justPressed.ENTER && !FlxG.keys.pressed.ALT;
		var charting = FlxG.keys.justPressed.SEVEN;

		if (!openMod && !MusicBeatState.switchingState && doUpdateText)
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

			if (upP)
			{
				changeSelection(-1);
			}
			if (downP)
			{
				changeSelection(1);
			}
		}
		previewtext.text = "Rate: " + FlxMath.roundDecimal(rate, 2) + "x";
		previewtext.updateHitbox();
		previewtext.alpha = 1;

		if (FlxG.keys.justPressed.CONTROL && !openMod && !MusicBeatState.switchingState && doUpdateText)
		{
			openMod = true;
			FlxG.sound.play(Paths.sound('scrollMenu'));
			openSubState(new kec.substates.FreeplaySubState.ModMenu());
		}

		if (!openMod && !MusicBeatState.switchingState && doUpdateText)
		{
			if (FlxG.keys.pressed.SHIFT) // && songs[curSelected].songName.toLowerCase() != "tutorial")
			{
				if (FlxG.keys.justPressed.LEFT || controls.LEFT_P)
				{
					rate -= 0.05;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}
				if (FlxG.keys.justPressed.RIGHT || controls.RIGHT_P)
				{
					rate += 0.05;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}

				if (FlxG.keys.justPressed.R)
				{
					rate = 1;
					lastRate = rate;
					updateDiffCalc();
					updateScoreText();
				}

				if (rate > 3)
				{
					rate = 3;
					lastRate = rate;
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
				previewtext.updateHitbox();
			}
			else
			{
				if (FlxG.keys.justPressed.LEFT || controls.LEFT_P)
					changeDiff(-1);
				if (FlxG.keys.justPressed.RIGHT || controls.RIGHT_P)
					changeDiff(1);

				if (FlxG.mouse.justPressedRight)
				{
					changeDiff(1);
				}
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				dotheMusicThing();
			}
		}

		if (FlxG.sound.music != null && !MainMenuState.freakyPlaying)
		{
			if (FlxG.sound.music.playing)
			{
				if (curTiming != null)
				{
					var curBPM = curTiming.bpm;

					if (curBPM != Conductor.bpm)
					{
						Debug.logInfo("BPM CHANGE to " + curBPM);
						Conductor.changeBPM(curBPM);
					}
				}
			}
		}

		if (FlxG.sound.music.playing && !MainMenuState.freakyPlaying)
		{
			FlxG.sound.music.pitch = rate;
		}

		#if html5
		diffCalcText.text = "RATING: N/A";
		diffCalcText.alpha = 0.5;
		#end

		if (!openMod && !MusicBeatState.switchingState)
		{
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new MainMenuState());
				if (colorTween != null)
				{
					colorTween.cancel();
				}
			}

			for (item in grpSongs.members)
				if (accepted
					|| (((FlxG.mouse.overlaps(item) && item.targetY == curSelected) || (FlxG.mouse.overlaps(iconArray[curSelected])))
						&& FlxG.mouse.justPressed))
				{
					doUpdateText = false;
					fard();
					break;
				}
					// Going to charting state via Freeplay is only enable in debug builds.
				// Liar
				else if (charting)
				{
					doUpdateText = false;
					fard(true);
					break;
				}

			// StageDebug are only enabled in debug builds.
			// Liar
		}

		if (openMod)
		{
			for (i in 0...iconArray.length)
				iconArray[i].alpha = 0;

			for (item in grpSongs.members)
				item.alpha = 0;
		}

		updateTexts(elapsed);
		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();
	}

	override function stepHit()
	{
		super.stepHit();
	}

	var playinSong:SongData;

	private function dotheMusicThing():Void
	{
		#if desktop
		try
		{
			FlxG.sound.music.stop();

			activeSong = playinSong;

			if (currentSongPlaying != songs[curSelected].songName)
			{
				var songPath:String = null;

				switch (songs[curSelected].songCharacter)
				{
					case "sm":
						#if (FEATURE_FILESYSTEM && FEATURE_STEPMANIA)
						songPath = FileSystem.absolutePath(songs[curSelected].path + "/" + songs[curSelected].sm.header.MUSIC);
						#end
					default:
						songPath = Paths.inst(songs[curSelected].songName, true);
				}

				FlxG.sound.playMusic(songPath, 0.7, true);

				songPath = null;
			}

			MainMenuState.freakyPlaying = false;

			TimingStruct.clearTimings();

			curTiming = null;

			var currentIndex = 0;
			rate = lastRate;

			currentSongPlaying = songs[curSelected].songName;
		}
		#end
	}

	function fard(farding:Bool = false)
	{
		if (!alreadyPressed)
		{
			FlxFlicker.flicker(grpSongs.members[curSelected], 1, 0.05, false, false, function(flick:FlxFlicker)
			{
				loadSongInFreePlay(songs[curSelected].songName, curDifficulty, farding);
			});

			FlxFlicker.flicker(iconArray[curSelected], 1, 0.05, false, false);

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.4);
			alreadyPressed = true;
		}
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
		var currentSongData:SongData = null;
		try
		{
			switch (instance.songs[curSelected].songCharacter)
			{
				#if FEATURE_STEPMANIA
				case "sm":
					currentSongData = Song.loadFromJsonRAW(#if FEATURE_FILESYSTEM File.getContent(instance.songs[curSelected].sm.jsonPath) #else OpenFlAssets.getText(instance.songs[curSelected].songName) #end);
				#end
				default:
					currentSongData = Song.loadFromJson(instance.songs[curSelected].songName,
						CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[CoolUtil.difficultyArray.indexOf(instance.songs[curSelected].diffs[difficulty])]));
			}
		}
		catch (ex)
		{
			Debug.logError(ex);
			return;
		}

		PlayState.SONG = currentSongData;
		PlayState.STYLE = Style.loadJSONFile(PlayState.SONG.style.toLowerCase());
		PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(instance.songs[curSelected].diffs[difficulty]);
		PlayState.storyWeek = instance.songs[curSelected].week;
		PlayState.isStoryMode = false;

		// Debug.logInfo('Loading song ${PlayState.SONG.songId} from week ${PlayState.storyWeek} into Free Play...');
		#if FEATURE_STEPMANIA
		if (instance.songs[curSelected].songCharacter == "sm")
		{
			PlayState.isSM = true;
			PlayState.sm = instance.songs[curSelected].sm;
			PlayState.pathToSm = instance.songs[curSelected].path;
		}
		else
			PlayState.isSM = false;
		#else
		PlayState.isSM = false;
		#end

		PlayState.songMultiplier = rate;
		lastRate = rate;
		
		instance.updateTexts();
		openMod = false;

		if (isCharting)
		{
			ChartingState.clean = true;
			LoadingState.loadAndSwitchState(new ChartingState(), true);
		}
		else
			LoadingState.loadAndSwitchState(new PlayState(), true);
	}

	override function destroy()
	{
		super.destroy();
	}

	function changeDiff(change:Int = 0)
	{
		if (songs[curSelected].diffs.length > 0)
		{
			curDifficulty += change;

			if (curDifficulty < 0)
				curDifficulty = songs[curSelected].diffs.length - 1;
			if (curDifficulty > songs[curSelected].diffs.length - 1)
				curDifficulty = 0;

			diffText.text = 'DIFFICULTY: < ' + songs[curSelected].diffs[curDifficulty] + ' >';
			diffText.alpha = 1;
		}
		else
		{
			diffText.text = 'DIFFICULTY: < N/A >';
			diffText.alpha = 0.5;
		}

		diffText.updateHitbox();
		updateScoreText();
		updateDiffCalc();
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
		var abDiff = CoolUtil.difficultyArray.indexOf(songs[curSelected].diffs[curDifficulty]);
		#if !switch
		intendedScore = Highscore.getScore(songHighscore, abDiff, rate);
		combo = Highscore.getCombo(songHighscore, abDiff, rate);
		letter = Highscore.getLetter(songHighscore, abDiff, rate);
		intendedaccuracy = Highscore.getAcc(songHighscore, abDiff, rate);
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
			{
				Conductor.changeBPM(hmm.bpm);
				GameplayCustomizeState.freeplayBf = hmm.player1;
				GameplayCustomizeState.freeplayDad = hmm.player2;
				GameplayCustomizeState.freeplayGf = hmm.gfVersion;
				GameplayCustomizeState.freeplayNoteStyle = hmm.noteStyle;
				GameplayCustomizeState.freeplayStage = hmm.stage;
				GameplayCustomizeState.freeplaySong = hmm.songId;
				GameplayCustomizeState.freeplayWeek = songs[curSelected].week;
			}
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
				bullShit++;

				item.alpha = 0.6;

				if (item.targetY == curSelected)
					item.alpha = 1;
			}
		}
	}

	public function updateDiffCalc():Void
	{
		if (songs[curSelected].diffs[curDifficulty] != null)
		{
			var toShow = 0.0;
			toShow = FlxG.save.data.opponent ? HelperFunctions.truncateFloat(songRatingOp.get(Highscore.formatSong(songs[curSelected].songName, curDifficulty,
				1)) * rate,
				2) : HelperFunctions.truncateFloat(songRating.get(Highscore.formatSong(songs[curSelected].songName, curDifficulty, 1)) * rate, 2);
			diffCalcText.text = 'RATING: ${toShow}';
			diffCalcText.alpha = 1;
		}
		else
		{
			Debug.logError('Error on calculating difficulty rate from song: ${songs[curSelected].songName}');
			diffCalcText.alpha = 0.5;
			diffCalcText.text = 'RATING: N/A';
		}
		diffCalcText.updateHitbox();
	}

	var _drawDistance:Int = 4;
	var _lastVisibles:Array<Int> = [];

	public function updateTexts(elapsed:Float = 0.0)
	{
		if (doUpdateText)
		{
			lerpSelected = FlxMath.lerp(lerpSelected, curSelected, CoolUtil.boundTo(elapsed * 9.6, 0, 1));
			for (i in _lastVisibles)
			{
				grpSongs.members[i].visible = grpSongs.members[i].active = false;
				iconArray[i].visible = iconArray[i].active = false;
			}
			_lastVisibles = [];

			var min:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected - _drawDistance)));
			var max:Int = Math.round(Math.max(0, Math.min(songs.length, lerpSelected + _drawDistance)));
			for (i in min...max)
			{
				var item:Alphabet = grpSongs.members[i];
				item.visible = item.active = true;
				item.x = ((item.targetY - lerpSelected) * item.distancePerItem.x) + item.startPosition.x;
				item.y = ((item.targetY - lerpSelected) * 1.3 * item.distancePerItem.y) + item.startPosition.y;

				var icon:HealthIcon = iconArray[i];
				icon.visible = icon.active = true;
				_lastVisibles.push(i);
			}
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
