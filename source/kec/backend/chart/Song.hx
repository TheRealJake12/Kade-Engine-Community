package kec.backend.chart;

import kec.backend.chart.format.*;

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

	public static function loadFromJson(songId:String, difficulty:String):Modern
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
			rawMetaJson = Paths.loadJSON('songs/$songId/_meta');
		else
		{
			if (FlxG.save.data.gen)
				Debug.logInfo('Hey, you didn\'t include a _meta.json with your song files (id ${songId}).Won\'t break anything but you should probably add one anyway.');
		}
		if (rawMetaJson == null)
			return null;
		else
			return cast rawMetaJson;
	}

	public static function conversionChecks(song:Dynamic):Modern
	{
		if (song?.chartVersion == Constants.chartVer)
			return song;

		final oldFormat:Legacy = cast song.song;

		if (oldFormat.chartVersion != null)
		{
			switch (oldFormat.chartVersion)
			{
				case "KEC1":
					return ChartConverter.convertKEC2(song);
				default:
					return ChartConverter.convertKade(song);
			}
		}
		if (song.format == 'psych_v1_convert')
		{
			Debug.logTrace('${song.song} was a PSYCHKIGD chart');
			return ChartConverter.convertPsychV1(song);
		}
		else
		{
			Debug.logWarn("Your Chart Format Is Fucked.");
			return ChartConverter.convertEtc(song);
		}
		return song;
	}

	public static function parseJSONshit(songId:String, jsonData:Dynamic, jsonMetaData:Dynamic):Modern
	{
		final songData = cast jsonData;
		return Song.conversionChecks(songData);
	}

	public static function checkforSections(SONG:Modern, songLength:Float)
	{
		var totalBeats = TimingStruct.getBeatFromTime(songLength);

		var lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);

		while (lastSecBeat < totalBeats)
		{
			SONG.notes.push(Song.newSection(SONG, SONG.notes[SONG.notes.length - 1].lengthInSteps, SONG.notes.length, true));

			recalculateAllSectionTimes(SONG, SONG.notes.length - 1);
			lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);
		}
	}

	public static function recalculateAllSectionTimes(activeSong:Modern, startIndex:Int = 0)
	{
		trace("RECALCULATING SECTION TIMES");

		if (activeSong == null)
			return;

		for (i in startIndex...activeSong.notes.length) // loops through sections
		{
			var section:Section = activeSong.notes[i];

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

	public static function newSection(song:Modern, lengthInSteps:Int = 16, index:Int = -1, mustHitSection:Bool = false):Section
	{
		var sec:Section = {
			lengthInSteps: lengthInSteps,
			bpm: song.bpm,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			index: index
		};

		return sec;
	}

	public static function oldSection(song:Legacy, lengthInSteps:Int = 16, index:Int = -1, mustHitSection:Bool = false):LegacySection
	{
		var sec:LegacySection = {
			lengthInSteps: lengthInSteps,
			bpm: song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			index: index
		};

		return sec;
	}
}
