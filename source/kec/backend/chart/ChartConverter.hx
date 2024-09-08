package kec.backend.chart;

import kec.backend.chart.format.*;

class ChartConverter
{
	public static function convertEtc(song:Dynamic):Modern
	{
		final data:Legacy = cast song.song;
		data.eventObjects = checkEvents(data);
		data.eventObjects = convertEvents(data);
		var currentIndex = 0;
		var index = 0;
		var ba = song.bpm;
		if (data.songName == null)
		{
			if (data.song != null)
				data.songName = data.song;
			else
				data.songName = data.songId;
		}

		if (data.noteStyle == 'pixel')
			data.style = "Pixel";

		if (data.style == null)
			data.style = "Default";

		if (data.gfVersion == null)
			data.gfVersion = "gf";

		if (data.stage == null)
			data.stage = "stage";

		if (data.splitVoiceTracks == null)
			data.splitVoiceTracks = false;

		// If the song has null sections.
		if (data.notes == null)
		{
			data.notes = [];
			data.notes.push(Song.oldSection(data));
		}

		// If the section array exists but there's nothing we push at least 1 section to play.
		if (data.notes.length == 0)
			data.notes.push(Song.oldSection(song));
		var newNotes:Array<Section> = [];
		TimingStruct.clearTimings();

		for (i in data.eventObjects)
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
		for (i => section in data.notes)
		{
			section.index = i;
			final currentBeat = 4 * index;
			final currentSeg = TimingStruct.getTimingAtBeat(currentBeat);
			newNotes.push({
				index: i,
				sectionNotes: [],
				bpm: section.bpm,
				mustHitSection: section.mustHitSection,
				lengthInSteps : 16,
				startTime: currentSeg.startTime,
			}); // create a blank for now
			

			if (section.lengthInSteps == null)
				section.lengthInSteps = 16;

			if (currentSeg == null)
				continue;

			final beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);

			if (section.changeBPM && section.bpm != ba)
			{
				ba = section.bpm;
				data.eventObjects.push({
					name: "FNF BPM Change " + section.index,
					beat: beat,
					args: [section.bpm],
					type: "BPM Change"
				});
			}
			section.mustHitSection = section.playerSec;
			if (Reflect.hasField(section, 'playerSec'))
				Reflect.deleteField(section, 'playerSec');
			var fard:Int = 0;

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
				final holdLength = ii[2];

				if (ii[3] == null || !Std.isOfType(ii[3], String))
					ii[3] = 'Normal';
				var nType = ii[3];

				ii.resize(0);
				// simple conversion
				// nvm, retarded conversion
				newNotes[i].sectionNotes.push({
					time: strumTime,
					data: noteData,
					length: holdLength,
					type: nType
				});
			}
			index++;
		}
		final events:Array<Event> = sortEvents(data.eventObjects);
		final newSong:Modern = {
			songName: data.songName,
			songId: data.songId,
			audioFile: data.audioFile,
			notes: newNotes,
			player1: data.player1,
			player2: data.player2,
			gfVersion: data.gfVersion,
			stage: data.stage,
			bpm: data.bpm,
			speed: data.speed,
			needsVoices: data.needsVoices,
			style: data.style,
			eventObjects: events,
			splitVoiceTracks: data.splitVoiceTracks,
			chartVersion: Constants.chartVer
		};
		Song.recalculateAllSectionTimes(newSong);
		newNotes = null;
		return newSong;
	}

	public static function convertKEC2(song:Dynamic):Modern
	{
		final data:Legacy = cast song.song;
		data.eventObjects = convertEvents(data);
		var newNotes:Array<Section> = [];
		var index = 0;
		var currentIndex = 0;
		// If the song has null sections.
		if (data.notes == null)
		{
			data.notes = [];
			data.notes.push(Song.oldSection(data));
		}

		// If the section array exists but there's nothing we push at least 1 section to play.
		if (data.notes.length == 0)
			data.notes.push(Song.oldSection(song));
		TimingStruct.clearTimings();
		for (i in data.eventObjects)
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
		for (i => section in data.notes)
		{
			section.index = i;
			final currentBeat = 4 * index;
			final currentSeg = TimingStruct.getTimingAtBeat(currentBeat);
			newNotes.push({
				index: i,
				sectionNotes: [],
				bpm: section.bpm,
				mustHitSection: section.mustHitSection,
				lengthInSteps: 16,
				startTime: currentSeg.startTime
			}); // create a blank for now
			final beat:Float = currentSeg.startBeat + (currentBeat - currentSeg.startBeat);
			section.mustHitSection = section.playerSec;
			if (Reflect.hasField(section, 'playerSec'))
				Reflect.deleteField(section, 'playerSec');
			newNotes[i].index = i;
			for (ii in section.sectionNotes)
			{
				final strumTime = ii[0];
				final noteData = ii[1];
				final holdLength = ii[2];
				final nType = ii[3];

				ii.resize(0);
				// simple conversion
				// nvm, retarded conversion

				newNotes[i].sectionNotes.push({
					time: strumTime,
					data: noteData,
					length: holdLength,
					type: nType
				});
			}
			index++;
		}
		final newSong:Modern = {
			songName: data.songName,
			songId: data.songId,
			audioFile: data.audioFile,
			notes: newNotes,
			player1: data.player1,
			player2: data.player2,
			gfVersion: data.gfVersion,
			stage: data.stage,
			bpm: data.bpm,
			speed: data.speed,
			needsVoices: data.needsVoices,
			style: data.style,
			eventObjects: data.eventObjects,
			splitVoiceTracks: data.splitVoiceTracks,
			chartVersion: Constants.chartVer
		};
		Song.recalculateAllSectionTimes(newSong);
		newNotes = null;
		return newSong;
	}

	private static function checkEvents(song:Legacy):Array<Event>
	{
		if (song.eventObjects == null)
		{
			song.eventObjects = [
				{
					name: "Init BPM",
					beat: 0,
					args: [song.bpm],
					type: "BPM Change"
				}
			];
			Debug.logTrace(song.eventObjects);
		}
		return song.eventObjects;
	}

	private static function convertEvents(song:Legacy):Array<Event>
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

	public static function sortEvents(arr:Array<Event>):Array<Event>
	{
		if (arr != null)
		{
			arr.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});
		}
		return arr;
	}
}
