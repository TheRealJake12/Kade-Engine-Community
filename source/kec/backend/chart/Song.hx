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
		if (song.chartVersion == Constants.chartVer)
			return song;

		switch (song.chartVersion)
		{
			case "KEC1":
				return ChartConverter.convertKEC2(song);
			default:
				return ChartConverter.convertEtc(song);
		}

		song.chartVersion = Constants.chartVer;

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
			songData.offset = songMetaData.offset != null ? songMetaData.offset : 0;

		return Song.conversionChecks(songData);
	}

	public static function recalculateAllSectionTimes(activeSong:SongData, startIndex:Int = 0)
	{
		trace("RECALCULATING SECTION TIMES");

		if (activeSong == null)
			return;

		for (i in startIndex...activeSong.notes.length) // loops through sections
		{
			var section:SwagSection = activeSong.notes[i];

			var endBeat:Float = 0.0;

			endBeat = (section.lengthInSteps / 4) * (i + 1);

			for (k in 0...i)
				endBeat -= ((section.lengthInSteps / 4) - (activeSong.notes[k].lengthInSteps / 4));

			section.endTime = TimingStruct.getTimeFromBeat(endBeat);

			if (i != 0)
				section.startTime = activeSong.notes[i - 1].endTime;
			else
				section.startTime = 0;

			// Debug.logTrace('Section #$i | startTime: ${section.startTime} | endtime: ${section.endTime}');
		}
	}

	public static function sortSectionNotes(song:SongData)
	{
		var newNotes:List<Array<Dynamic>> = new List();

		for (section in song.notes)
		{
			if (section.sectionNotes != null)
			{
				for (songNotes in section.sectionNotes)
				{
					newNotes.add(songNotes);
				}
			}

			section.sectionNotes.splice(0, section.sectionNotes.length);
		}

		for (section in song.notes)
		{
			for (sortedNote in newNotes)
			{
				if (sortedNote[0] >= section.startTime && sortedNote[0] < section.endTime)
				{
					section.sectionNotes.push(sortedNote);
				}
			}
		}

		newNotes.clear();
	}

	public static function checkforSections(SONG:SongData, songLength:Float)
	{
		var totalBeats = TimingStruct.getBeatFromTime(songLength);

		var lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);

		while (lastSecBeat < totalBeats)
		{
			SONG.notes.push(Song.newSection(SONG, SONG.notes[SONG.notes.length - 1].lengthInSteps, SONG.notes.length, true, false, false));

			recalculateAllSectionTimes(SONG, SONG.notes.length - 1);
			lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);
		}
	}

	public static function newSection(song:SongData, lengthInSteps:Int = 16, index:Int = -1, mustHitSection:Bool = false, CPUAltAnim:Bool = true,
			playerAltAnim:Bool = true):SwagSection
	{
		var sec:SwagSection = {
			lengthInSteps: lengthInSteps,
			bpm: song.bpm,
			changeBPM: false,
			playerSec: mustHitSection,
			sectionNotes: [],
			index: index
		};

		return sec;
	}
}
