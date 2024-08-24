package kec.backend.chart;

import kec.backend.chart.Section.SwagSection;

typedef StyleData =
{
	var style:String;
	var scale:Float;
	var antialiasing:Bool;
	var noteskinP:String;
	var noteskinE:String;
	var notesplash:String;
	var hudStyle:String;
}

class Style
{
	public static function loadJSONFile(style:String):StyleData
	{
		var rawJson = Paths.loadJSON('styles/$style');
		return parseWeek(rawJson);
	}

	public static function parseWeek(json:Dynamic):StyleData
	{
		var styleData:StyleData = cast json;

		return styleData;
	}
}

typedef SongData =
{
	/**
		* The readable name of the song, as displayed to the user.
				* Can be any string. 
				Actually Used Now Instead Of Song.	
	 */
	var songName:String;

	/**
	 * The internal name of the song, as used in the file system.
	 */
	var songId:String;

	/**
	 * Old Display Name. Only Used For Formatting Now.
	 */
	var ?song:String;

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
	var ?noteStyle:String;
	var style:String;
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
	public static var latestChart:String = "KEC1";

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
		song.eventObjects = convertEvents(song.eventObjects);
		if (song.chartVersion == latestChart)
			return song;

		var ba = song.bpm;

		var eventObjects:Array<Event> = [];

		if (song.eventObjects == null)
			song.eventObjects = [
				{
					name: "Init BPM",
					beat: 0,
					args: [ba, "1"],
					type: "BPM Change"
				}
			];

		for (i in song.eventObjects)
		{
			eventObjects.push({
				name: i.name,
				beat: i.beat,
				args: i.args,
				type: i.type
			});
		}

		song.eventObjects = eventObjects;

		var index = 0;

		if (song.songName == null)
		{
			if (song.song != null)
				song.songName = song.song;
			else
				song.songName = song.songId;
		}

		if (song.noteStyle == 'pixel')
			song.style = "Pixel";

		if (song.style == null)
			song.style = "Default";

		if (song.gfVersion == null)
			song.gfVersion = "gf";

		if (song.stage == null)
			song.stage = "stage";

		if (song.splitVoiceTracks == null)
			song.splitVoiceTracks = false;

		var currentIndex = 0;
		for (i in song.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.beat * Conductor.rate;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, i.args[0] * Conductor.rate, endBeat, 0); // offset in this case = start time since we don't have a offset

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
			var currentBeat = 4 * index;

			var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (i.lengthInSteps == null)
				i.lengthInSteps = 16;

			if (currentSeg == null)
				continue;

			var beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);

			if (i.changeBPM && i.bpm != ba)
			{
				ba = i.bpm;
				song.eventObjects.push({
					name: "FNF BPM Change " + index,
					beat: beat,
					args: [i.bpm, 1],
					type: "BPM Change"
				});
			}

			for (ii in i.sectionNotes)
			{
				// try not to brick the game challenge (impossible (thanks bolo))
				if (i.mustHitSection)
				{
					var bool = false;
					if (ii[1] <= 3)
					{
						ii[1] += 4;
						bool = true;
					}
					if (ii[1] > 3)
						if (!bool)
							ii[1] -= 4;
				}

				i.playerSec = i.mustHitSection;

				var strumTime = ii[0];
				var noteData = ii[1];
				var length = ii[2];

				if (ii[3] == null || !Std.isOfType(ii[3], String))
					ii[3] = 'Normal';
				var type = ii[3];

				ii.resize(0);

				ii.push(strumTime);
				ii.push(noteData);
				ii.push(length);
				ii.push(type);
				// simple conversion
				// nvm, retarded conversion

				if (ii[4] != null && Std.isOfType(ii[4], String))
					ii[3] = ii[4];
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

		if (songData.audioFile == null)
			songData.audioFile = songId;

		// Enforce default values for optional fields.
		if (songData.validScore == null)
			songData.validScore = true;

		// Inject info from _meta.json.
		var songMetaData:SongMeta = cast jsonMetaData;
		if (songMetaData != null)
		{
			songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;
		}

		return Song.conversionChecks(songData);
	}

	private static function convertEvents(events:Array<Event>)
	{
		var newEvents:Array<Event> = [];
		for (i in events)
			newEvents.push({
				name: i.name,
				beat: i.position,
				args: [i.value, i.value2],
				type: i.type
			});
		events.resize(0);
		newEvents.sort(Sort.sortEvents);
		return newEvents;
	}

	private static function newSection(song:SongData, playerSec:Bool = true):SwagSection
	{
		var sec:SwagSection = {
			bpm: song.bpm,
			changeBPM: false,
			playerSec: playerSec,
			lengthInSteps: 16,
			sectionNotes: [],
		};

		return sec;
	}
}
