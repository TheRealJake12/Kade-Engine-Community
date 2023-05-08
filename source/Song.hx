package;

import Section.SwagSection;
import flixel.FlxG;
import haxe.Json;
import haxe.format.JsonParser;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets;

using StringTools;

class Event
{
	public var name:String;
	public var position:Float;
	public var value:Float;
	public var type:String;

	public function new(name:String, pos:Float, value:Float, type:String)
	{
		this.name = name;
		this.position = pos;
		this.value = value;
		this.type = type;
	}
}

typedef SongData =
{
	@:deprecated
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
}

typedef SongMeta =
{
	var ?offset:Int;
	var ?name:String;
}

class Song
{
	public static var latestChart:String = "KEC 1.7.2";

	public static function loadFromJsonRAW(rawJson:String)
	{
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
			// LOL GOING THROUGH THE BULLSHIT TO CLEAN IDK WHATS STRANGE
		}
		var jsonData = Json.parse(rawJson);

		return parseJSONshit("rawsong", jsonData, ["name" => jsonData.name]);
	}

	public static function loadFromJson(songId:String, diffSuffix:String):SongData
	{
		var songFile = '$songId/$songId$diffSuffix';

		// Debug.logInfo('Loading song JSON: $songFile');

		var rawJson = Paths.loadJSON('songs/$songFile');

		var songData:SongData = cast rawJson.song;
		var metaData:SongMeta = loadMetadata(songId);

		return parseJSONData(songId, songData, metaData);
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

		if (songData.songFile == null)
		{
			songData.songFile = songId;
		}
		else
		{
			trace('SONG DATA IS ${songData.songFile} BLABLABLA');
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
			song.eventObjects = [new Song.Event("Init BPM", 0, song.bpm, "BPM Change")];

		for (i in song.eventObjects)
		{
			var name = Reflect.field(i, "name");
			var type = Reflect.field(i, "type");
			var pos = Reflect.field(i, "position");
			var value = Reflect.field(i, "value");

			convertedStuff.push(new Song.Event(name, pos, value, type));
		}

		song.eventObjects = convertedStuff;

		if (song.noteStyle == null)
			song.noteStyle = "normal";

		if (song.gfVersion == null)
			song.gfVersion = "gf";

		TimingStruct.clearTimings();

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
					data.length = ((data.endBeat - data.startBeat) / (data.bpm / 60));
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}

		if (song.notes == null)
		{
			song.notes = [];

			song.notes.push(newSection(song));
		}

		if (song.notes.length == 0)
			song.notes.push(newSection(song));

		for (section in song.notes)
		{
			for (notes in section.sectionNotes)
			{
				if (section.mustHitSection)
				{
					var bool = false;
					if (notes[1] <= 3)
					{
						notes[1] += 4;
						bool = true;
					}
					if (notes[1] > 3)
						if (!bool)
							notes[1] -= 4;
				}

				if (notes[2] == -1) // REMOVE EVENT NOTES FROM OTHER ENGINES
					section.sectionNotes.remove(notes);
			}

			if (section.lengthInSteps == null)
				section.lengthInSteps = 16;
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
				song.eventObjects.push(new Song.Event("FNF BPM Change " + index, beat, i.bpm, "BPM Change"));
			}

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

		songData.songId = songId;

		// Enforce default values for optional fields.
		if (songData.validScore == null)
			songData.validScore = true;

		// Inject info from _meta.json.
		var songMetaData:SongMeta = cast jsonMetaData;
		if (songMetaData.name != null)
		{
			songData.songName = songMetaData.name;
		}
		else
		{
			songData.songName = songId.split('-').join(' ');
		}

		songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;

		return Song.conversionChecks(songData);
	}

	public static function loadJson(jsonInput:String, ?folder:String):SongData
	{
		// pre lowercasing the song name (update)
		var folderLowercase = StringTools.replace(folder, " ", "-").toLowerCase();
		switch (folderLowercase)
		{
			case 'dad-battle':
				folderLowercase = 'dadbattle';
			case 'philly-nice':
				folderLowercase = 'philly';
		}

		var rawJson = Assets.getText(Paths.json('songs' + '/' + folderLowercase + '/' + jsonInput.toLowerCase())).trim();

		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		return parseJSON(rawJson);
	}

	public static function parseJSON(rawJson:String):SongData
	{
		var swagShit:SongData = cast Json.parse(rawJson).song;
		swagShit.validScore = true;
		return swagShit;
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
				if (sortedNote[0] >= section.startTime && sortedNote[0] < section.endTime)
					section.sectionNotes.push(sortedNote);
			}
		}
	}
}
