package kec.backend.chart;

import kec.backend.chart.Song.SongData;

class ChartConverter
{
	public static function convertEtc(song:SongData):SongData
	{
		song.eventObjects = checkEvents(song);
		song.eventObjects = convertEvents(song);
		var currentIndex = 0;
		var index = 0;
		var ba = song.bpm;
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

		if (song.notes == null)
		{
			song.notes = [];

			song.notes.push(Song.newSection(song));
		}

		// If the section array exists but there's nothing we push at least 1 section to play.
		if (song.notes.length == 0)
			song.notes.push(Song.newSection(song));

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
		for (i => section in song.notes)
		{
			section.index = i;
			final currentBeat = 4 * index;

			final currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

			if (section.lengthInSteps == null)
				section.lengthInSteps = 16;

			if (currentSeg == null)
				continue;

			final beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);

			if (section.changeBPM && section.bpm != ba)
			{
				ba = section.bpm;
				song.eventObjects.push({
					name: "FNF BPM Change " + section.index,
					beat: beat,
					args: [section.bpm],
					type: "BPM Change"
				});
			}
			section.playerSec = section.mustHitSection;

			for (ii in section.sectionNotes)
			{
				// try not to brick the game challenge (impossible (thanks bolo))
				if (section.mustHitSection)
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

				final strumTime = ii[0];
				final noteData = ii[1];
				final length = ii[2];

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
		}
		sortEvents(song);
		song.chartVersion = Constants.chartVer;
		return song;
	}

	public static function convertKEC2(song:SongData):SongData
	{
		song.eventObjects = convertEvents(song);
		sortEvents(song);
		for (i => section in song.notes)
		{
			section.index = i;
		}
		if (song.style == null)
			song.style = "Default";
		song.chartVersion = Constants.chartVer;
		return song;
	}

	private static function checkEvents(song:SongData):Array<Event>
	{
		if (song.eventObjects == null)
			song.eventObjects = [
				{
					name: "Init BPM",
					beat: 0,
					args: [song.bpm],
					type: "BPM Change"
				}
			];
		return song.eventObjects;
	}

	private static function convertEvents(song:SongData):Array<Event>
	{
		var newEvents:Array<Event> = [];
		for (i in song.eventObjects)
		{
			switch (i.type)
			{
				case "BPM Change":
					newEvents.push({
						name: i.name,
						beat: i.position,
						args: [Std.parseFloat(i.value)],
						type: "BPM Change"
					});

				case "Scroll Speed Change":
					newEvents.push({
						name: i.name,
						beat: i.position,
						args: [Std.parseFloat(i.value), Std.parseFloat(i.value2)],
						type: "Scroll Speed Change"
					});
				default:
					newEvents.push({
						name: i.name,
						beat: i.position,
						args: [i.value, i.value2],
						type: i.type
					});
			}
		}
		song.eventObjects.resize(0);
		// Debug.logTrace(newEvents[0].args[0] + ' ${song.songId}');
		return newEvents;
	}

	public static function sortEvents(song:SongData)
	{
		if (song.eventObjects != null)
		{
			song.eventObjects.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});
		}
	}
}
