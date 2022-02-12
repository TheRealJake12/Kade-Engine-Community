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
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import lime.app.Application;

using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var songs:Array<FreeplaySongMetadata> = [];

	var selector:FlxText;

	public static var rate:Float = 1.0;

	public static var curSelected:Int = 0;
	public static var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var comboText:FlxText;
	var diffText:FlxText;
	var diffCalcText:FlxText;
	var previewtext:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var combo:String = '';

	var bg:FlxSprite;

	private var coolColors:Array<FlxColor> = [-7072173, -7179779, -14535868, -7072173, -223529, -6237697, -34625]; // thanks people at Ralsei Engine
	private var rgb:Array<FlxColor> = [
		FlxColor.fromRGB(165, 0, 77), // Tutorial
		FlxColor.fromRGB(146, 113, 253), // Week 1
		FlxColor.fromRGB(34, 51, 68), // Week 2
		FlxColor.fromRGB(148, 22, 83), // Week 3
		FlxColor.fromRGB(255, 102, 169), // Week 4
		FlxColor.fromRGB(103, 255, 255), // Week 5
		FlxColor.fromRGB(255, 0, 72), // Week 6
	];

	private static var vocals:FlxSound = null;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	public static var openedPreview = false;

	public static var songData:Map<String, Array<SongData>> = [];

	public static function loadDiff(diff:Int, songId:String, array:Array<SongData>)
	{
		var diffName:String = "";

		switch (diff)
		{
			case 0:
				diffName = "-easy";
			case 2:
				diffName = "-hard";
		}
		if (FlxG.save.data.hardmode)
		{
			switch (diff)
			{
				case 0:
					diffName = "-easy";
				case 2:
					diffName = "-hard";
				case 3:
					diffName = "-oc";
			}
		}

		array.push(Song.conversionChecks(Song.loadFromJson(songId, diffName)));
	}

	public static var list:Array<String> = [];

	override function create()
	{
		Application.current.window.title = '${MainMenuState.kecVer} : In the Menus';

		clean();
		list = CoolUtil.coolTextFile(Paths.txt('data/freeplaySonglist'));

		cached = false;

		populateSongData();
		PlayState.inDaPlay = false;
		PlayState.currentSong = "bruh";

		#if !FEATURE_STEPMANIA
		trace("FEATURE_STEPMANIA was not specified during build, sm file loading is disabled.");
		#elseif FEATURE_STEPMANIA
		// TODO: Refactor this to use OpenFlAssets.
		if (FlxG.save.data.gen)
			trace("tryin to load sm files");
		#end

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Freeplay Menu", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		persistentUpdate = true;

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false, true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
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

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 135, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		diffCalcText = new FlxText(scoreText.x, scoreText.y + 66, 0, "", 24);
		diffCalcText.font = scoreText.font;
		add(diffCalcText);

		previewtext = new FlxText(scoreText.x, scoreText.y + 96, 0, "Rate: " + FlxMath.roundDecimal(rate, 2) + "x", 24);
		previewtext.font = scoreText.font;
		add(previewtext);

		comboText = new FlxText(diffText.x + 100, diffText.y, 0, "", 24);
		comboText.font = diffText.font;
		add(comboText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic(Paths.music('title'), 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		add(textBG);

		var text:String = "Press SPACE to preview the Song.";
		var size:Int = 16;

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, text, size);
		text.setFormat(Paths.font("vcr.ttf"), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		super.create();
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
			var meta = new FreeplaySongMetadata(songId, Std.parseInt(data[2]), data[1]);

			var diffs = [];
			var diffsThatExist = [];
			#if FEATURE_FILESYSTEM
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-oc')))
				diffsThatExist.push("Oc");
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-hard')))
				diffsThatExist.push("Hard");
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId-easy')))
				diffsThatExist.push("Easy");
			if (Paths.doesTextAssetExist(Paths.json('songs/$songId/$songId')))
				diffsThatExist.push("Normal");

			if (diffsThatExist.length == 0)
			{
				Debug.displayAlert(meta.songName + " Chart", "No difficulties found for chart, skipping.");
			}
			#else
			diffsThatExist = ["Easy", "Normal", "Hard"];
			#end

			if (diffsThatExist.contains("Easy"))
				FreeplayState.loadDiff(0, songId, diffs);
			if (diffsThatExist.contains("Normal"))
				FreeplayState.loadDiff(1, songId, diffs);
			if (diffsThatExist.contains("Hard"))
				FreeplayState.loadDiff(2, songId, diffs);
			if (diffsThatExist.contains("Oc"))
				FreeplayState.loadDiff(3, songId, diffs);

			meta.diffs = diffsThatExist;

			if (diffsThatExist.length != 3)

			FreeplayState.songData.set(songId, diffs);
			
			FreeplayState.songs.push(meta);

			#if FFEATURE_FILESYSTEM
			sys.thread.Thread.create(() ->
			{
				FlxG.sound.cache(Paths.inst(songId));
			});
			#else
			FlxG.sound.cache(Paths.inst(songId));
			#end
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new FreeplaySongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['dad'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		bg.color = FlxColor.interpolate(bg.color, rgb[songs[curSelected].week % rgb.length], CoolUtil.camLerpShit(0.045));

		// var coolerColor = rgb[rgb.length % songs[curSelected].week];
		var lerpColor = CoolUtil.camLerpShit(0.045);

		bg.color = FlxColor.interpolate(bg.color, rgb[songs[curSelected].week % rgb.length], CoolUtil.camLerpShit(0.045));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;
		comboText.text = combo + '\n';

		if (FlxG.sound.music.volume > 0.8)
		{
			FlxG.sound.music.volume -= 0.5 * FlxG.elapsed;
		}

		var upP = FlxG.keys.justPressed.UP;
		var downP = FlxG.keys.justPressed.DOWN;
		var accepted = FlxG.keys.justPressed.ENTER;
		var space = FlxG.keys.justPressed.SPACE;
		var dadDebug = FlxG.keys.justPressed.SIX;
		var charting = FlxG.keys.justPressed.SEVEN;
		var bfDebug = FlxG.keys.justPressed.ZERO;

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		// if (FlxG.keys.justPressed.SPACE && !openedPreview)
		// openSubState(new DiffOverview());

		if (FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.justPressed.LEFT)
			{
				rate -= 0.05;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}
			if (FlxG.keys.justPressed.RIGHT)
			{
				rate += 0.05;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}

			if (FlxG.keys.justPressed.R)
			{
				rate = 1;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}

			if (rate > 3)
			{
				rate = 3;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}
			else if (rate < 0.5)
			{
				rate = 0.5;
				diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
			}

			previewtext.text = "Rate: " + FlxMath.roundDecimal(rate, 2) + "x";
		}
		else
		{
			if (FlxG.keys.justPressed.LEFT)
				changeDiff(-1);
			if (FlxG.keys.justPressed.RIGHT)
				changeDiff(1);
		}

		#if cpp
		@:privateAccess
		{
			if (FlxG.sound.music.playing)
				lime.media.openal.AL.sourcef(FlxG.sound.music._channel.__source.__backend.handle, lime.media.openal.AL.PITCH, rate);
		}
		#end

		if (controls.BACK)
		{
			LoadingState.loadAndSwitchState(new MainMenuState());
			if (FlxG.save.data.unload)
			{
				Main.dumpCache();
			}
		}
		if (space)
		{
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		}

		if (accepted)
			loadSong();
		else if (charting)
			loadSong(true);

		// AnimationDebug and StageDebug are only enabled in debug builds.
		#if debug
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

		clean();
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
		PlayState.isStoryMode = false;
		PlayState.storyDifficulty = difficulty;
		PlayState.storyWeek = songs[curSelected].week;
		Debug.logInfo('Loading song ${PlayState.SONG.songName} from week ${PlayState.storyWeek} into Free Play...');
		#if FEATURE_STEPMANIA
		if (songs[curSelected].songCharacter == "sm")
		{
			Debug.logInfo('Song is a StepMania song!');
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

	function changeDiff(change:Int = 0)
	{
		if (!songs[curSelected].diffs.contains(CoolUtil.difficultyFromInt(curDifficulty + change)))
			return;

		curDifficulty += change;
		
		if (!FlxG.save.data.hardmode)
		{
			if (curDifficulty < 0)
				curDifficulty = 0;
			if (curDifficulty > 2)
				curDifficulty = 0;
		}
		else
		{
			if (curDifficulty < 0)
				curDifficulty = 3;
			if (curDifficulty > 3)
				curDifficulty = 0;
		}

		// adjusting the highscore song name to be compatible (changeDiff)
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

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		#end
		diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
		diffText.text = CoolUtil.difficultyFromInt(curDifficulty).toUpperCase();
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;
			
		if (FlxG.save.data.hardmode)
		{
			if (songs[curSelected].diffs.length != 3)
			{
				switch (songs[curSelected].diffs[0])
				{
					case "Easy":
						curDifficulty = 0;
					case "Normal":
						curDifficulty = 1;
					case "Hard":
						curDifficulty = 2;
					case "Oc":
						curDifficulty = 3;
				}
			}
		}
		else
		{
			if (songs[curSelected].diffs.length != 2)
			{
				switch (songs[curSelected].diffs[0])
				{
					case "Easy":
						curDifficulty = 0;
					case "Normal":
						curDifficulty = 1;
					case "Hard":
						curDifficulty = 2;
				}
			}
		}
		// selector.y = (70 * curSelected) + 30;

		// adjusting the highscore song name to be compatible (changeSelection)
		// would read original scores if we didn't change packages
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

		#if !switch
		intendedScore = Highscore.getScore(songHighscore, curDifficulty);
		combo = Highscore.getCombo(songHighscore, curDifficulty);
		// lerpScore = 0;
		#end

		diffCalcText.text = 'RATING: ${DiffCalc.CalculateDiff(songData.get(songs[curSelected].songName)[curDifficulty])}';
		diffText.text = CoolUtil.difficultyFromInt(curDifficulty).toUpperCase();

		#if PRELOAD_ALL
		if (songs[curSelected].songCharacter == "sm")
		{
			var data = songs[curSelected];
			if (FlxG.save.data.gen)
				trace("Loading " + data.path + "/" + data.sm.header.MUSIC);
			var bytes = File.getBytes(data.path + "/" + data.sm.header.MUSIC);
			var sound = new Sound();
			sound.loadCompressedDataFromByteArray(bytes.getData(), bytes.length);
			FlxG.sound.playMusic(sound);
		}
		#end

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

		if (openedPreview)
		{
			closeSubState();
			openSubState(new DiffOverview());
		}

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
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

class FreeplaySongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	#if FEATURE_STEPMANIA
	public var sm:SMFile;
	public var path:String;
	#end
	public var songCharacter:String = "";

	public var diffs = [];

	#if FEATURE_STEPMANIA
	public function new(song:String, week:Int, songCharacter:String, ?sm:SMFile = null, ?path:String = "")
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.sm = sm;
		this.path = path;
	}
	#else
	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
	#end
}
