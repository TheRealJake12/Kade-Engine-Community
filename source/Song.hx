package;

import Section.SwagSection;
import flixel.FlxG;

using StringTools;

class Event
{
	public var name:String;
	public var position:Float;
	public var value:Dynamic;
	public var value2:Dynamic;
	public var type:String;

	public function new(name:String, pos:Float, value:Dynamic, value2:Dynamic, type:String)
	{
		this.name = name;
		this.position = pos;
		this.value = value;
		this.value2 = value2;
		this.type = type;
	}
}

typedef SongData =
{
	var ?song:String;

	/**
	 * The readable name of the song, as displayed to the user.
	 		* Can be any string.
	 */
	var songName:String;

	/**
	 * The internal name of the song, as used in the file system.
	 */
	var songId:String;

	var ?songFile:String;
	var chartVersion:String;
	var notes:Array<SwagSection>;
	var eventObjects:Array<Event>;
	var bpm:Float;
	var needsVoices:Bool;
	var speed:Float;
	var player1:String;
	var player2:String;
	var gfVersion:String;
	var noteStyle:String;
	var stage:String;
	var ?validScore:Bool;
	var ?offset:Int;
	var ?splitVoiceTracks:Bool;
	var ?audioFile:String;
}

typedef SongMeta =
{
	var ?offset:Int;
	var ?name:String;
}

class Song
{
	public static var latestChart:String = MainMenuState.kecVer;

	public static function loadFromJsonRAW(rawJson:String)
	{
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}

		var jsonData = Json.parse(rawJson);

		return parseJSONshit('rawsong', jsonData, 'rawname');
	}

	public static function loadFromJson(songId:String, difficulty:String):SongData
	{
		var songFile = '$songId/$songId$difficulty';

		var rawJson = Paths.loadJSON('songs/$songFile');
		var metaData:SongMeta = loadMetadata(songId);

		return parseJSONshit(songId, rawJson, metaData);
	}

	public static function parseJSONData(songId:String, jsonData:Dynamic, jsonMetaData:Dynamic):SongData
	{
		if (jsonData == null)
			return null;
		var songData:SongData = cast jsonData;

		songData.songId = songId;

		var songMetaData:SongMeta = cast jsonMetaData;

		/**
		 * Default values.
		 */
		if (songData.noteStyle == null)
			songData.noteStyle = "normal";

		if (songData.audioFile == null)
		{
			songData.audioFile = songId;
		}

		if (songData.validScore == null)
			songData.validScore = true;

		// Inject info from _meta.json.
		if (songMetaData != null)
		{
			if (songMetaData.name != null)
			{
				songData.songName = songMetaData.name;
			}
			else
			{
				songData.songName = songId.split('-').join(' ');
			}

			songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;
		}

		return Song.conversionChecks(songData);
	}

	public static function loadMetadata(songId:String):SongMeta
	{
		var rawMetaJson = null;
		if (Paths.doesTextAssetExist(Paths.songMeta(songId)))
		{
			rawMetaJson = Paths.loadJSON('songs/$songId/_meta');
		}
		else
		{
			if (FlxG.save.data.gen)
				Debug.logInfo('Hey, you didn\'t include a _meta.json with your song files (id ${songId}).Won\'t break anything but you should probably add one anyway.');
		}
		if (rawMetaJson == null)
		{
			return null;
		}
		else
		{
			return cast rawMetaJson;
		}
	}

	public static function conversionChecks(song:SongData):SongData
	{
		var ba = song.bpm;

		var index = 0;
		var convertedStuff:Array<Song.Event> = [];

		if (song.eventObjects == null)
			song.eventObjects = [new Song.Event("Init BPM", 0, song.bpm, "1", "BPM Change")];

		for (i in song.eventObjects)
		{
			var name = Reflect.field(i, "name");
			var type = Reflect.field(i, "type");
			var pos = Reflect.field(i, "position");
			var value = Reflect.field(i, "value");
			var value2 = Reflect.field(i, "value2");

			if (value2 == null)
				value2 = "1";

			convertedStuff.push(new Song.Event(name, pos, value, value2, type));
		}

		song.eventObjects = convertedStuff;

		if (song.noteStyle == null)
			song.noteStyle = "normal";

		if (song.gfVersion == null)
			song.gfVersion = "gf";

		if (song.stage == null)
			song.stage = "stage";	

		TimingStruct.clearTimings();

		if (song.splitVoiceTracks == null)
			song.splitVoiceTracks = false;

		var currentIndex = 0;
		for (i in song.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.position * PlayState.songMultiplier;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, i.value * PlayState.songMultiplier, endBeat, 0); // offset in this case = start time since we don't have a offset

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}

		for (i in song.notes)
		{
			if (i.altAnim)
				i.CPUAltAnim = i.altAnim;

			var currentBeat = 4 * index;

			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (currentSeg == null)
				continue;

			var beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);

			if (i.changeBPM && i.bpm != ba)
			{
				ba = i.bpm;
				song.eventObjects.push(new Song.Event("FNF BPM Change " + index, beat, '${i.bpm}', "1", "BPM Change"));
			}

			if (i.lengthInSteps == null)
				i.lengthInSteps = 16;

			for (ii in i.sectionNotes)
			{
				if (song.chartVersion == null)
				{
					ii[3] = false;
					ii[4] = TimingStruct.getBeatFromTime(ii[0]);
				}

				if (ii[3] == 0)
					ii[3] == false;
			}

			index++;
		}

		song.chartVersion = latestChart;

		return song;
	}

	public static function parseJSONshit(songId:String, jsonData:Dynamic, jsonMetaData:Dynamic):SongData
	{
		var songData:SongData = cast jsonData.song;

		if (songData.songId == null)
			songData.songId = songId;

		if (songData.songName == null)
			songData.songName = songId;

		if (songData.song == null)
			songData.song = songId;

		if (songData.audioFile == null)
			songData.audioFile = songId;

		// Enforce default values for optional fields.
		if (songData.validScore == null)
			songData.validScore = true;

		// Inject info from _meta.json.
		var songMetaData:SongMeta = cast jsonMetaData;
		if (songMetaData != null)
		{
			if (songMetaData.name != null)
			{
				songData.songName = songMetaData.name;
			}
			else
			{
				songData.songName = songData.songName.split('-').join(' ');
			}

			songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;
		}
		else
		{
			songData.songName = songData.songName.split('-').join(' ');
		}

		return Song.conversionChecks(songData);
	}

	private static function newSection(song:SongData, lengthInSteps:Int = 16, mustHitSection:Bool = false, CPUAltAnim:Bool = true,
			playerAltAnim:Bool = true):SwagSection
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			CPUAltAnim: CPUAltAnim,
			playerAltAnim: playerAltAnim
		};

		return sec;
	}

	public static function sortSectionNotes(song:SongData)
	{
		var newNotes:Array<Array<Dynamic>> = [];

		for (section in song.notes)
		{
			if (section.sectionNotes != null)
			{
				for (songNotes in section.sectionNotes)
				{
					newNotes.push(songNotes);
				}
			}
			section.sectionNotes.resize(0);
		}

		for (section in song.notes)
		{
			for (sortedNote in newNotes)
			{
				if (sortedNote[0] / PlayState.songMultiplier >= section.startTime
					&& sortedNote[0] / PlayState.songMultiplier < section.endTime)
					section.sectionNotes.push(sortedNote);
			}
		}
	}
}
