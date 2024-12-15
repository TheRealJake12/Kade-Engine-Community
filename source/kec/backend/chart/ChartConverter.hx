package kec.backend.chart;

import moonchart.formats.fnf.FNFKade.FNFKadeFormat;
import openfl.utils.Assets as OpenFlAssets;
import moonchart.formats.fnf.*;
import moonchart.formats.fnf.legacy.*;

using kec.backend.tools.StringTools;

/**
 * ### Tool To Convert Chart Formats.
 * ### Will Be Done Automatically.
 */
class ChartConverter
{
	public static function convert(data:Dynamic, name:String, diff:String):ChartData
	{
		final formattedName:String = Paths.formatToSongPath(name);
		final diffi:String = StringTools.replace(diff, '-', '');
		final chart:Dynamic = (data.song == null) ? data : ((data.song is String) ? data : data.song);

		if (chart == null)
		{
			Debug.logWarn('$formattedName was null');
			return null;
		}

		// if else if else if else simulator
		final toFind:String = 'data/songs/$formattedName/$formattedName$diff';

		if (chart?.chartVersion == 'KEC1')
		{
			return convertKEC1(data);
		}

		// Debug.logTrace((data.song is String) ? "Unwrapped" : "Wrapped");
		// Debug.logTrace((data.song == null) ? "Was Null" : "Wasn't Null");
		final chartPath:String = OpenFlAssets.getPath(Paths.json(toFind));

		if (Reflect.hasField(chart.notes[0], "sectionBeats"))
		{
			final psych = new FNFPsych().fromFile(chartPath, null, diffi);
			final kade = new FNFKade().fromFormat(psych, diffi);
			Debug.logTrace('Psych To Kade For $name with diff $diff');
			return compat(kade.data.song);
		}

		if (Reflect.hasField(chart, "generatedBy"))
		{
			final metaPath:String = OpenFlAssets.getPath(Paths.json('data/songs/$formattedName/metadata'));
			final vslice = new FNFVSlice().fromFile(chartPath, metaPath, diffi);
			final kade = new FNFKade().fromFormat(vslice, diffi);
			Debug.logTrace('VSlice To Kade For $name with diff $diff');
			// Debug.logTrace('${vslice.meta.songName} ${kade.data.song.songId}');
			return compat(kade.data.song, vslice.meta.songName);
		}

		if (Reflect.hasField(chart.notes[0], "altAnim") || Reflect.hasField(chart.notes[0], "typeOfSection"))
		{
			final legacy = new FNFLegacy().fromFile(chartPath, null, diffi);
			final kade = new FNFKade().fromFormat(legacy, diffi);
			Debug.logTrace('Legacy To Kade For $name with diff $diff');
			return compat(kade.data.song);
		}

		if (Reflect.hasField(chart, "chartVersion") || Reflect.hasField(chart, "eventObjects"))
		{
			final kadeOne = new FNFKade().fromFile(chartPath, null, diffi);
			Debug.logTrace('Kade For $name with diff $diff');
			return compat(kadeOne.data.song);
		}

		// because conversion isn't perfect
		Debug.logTrace("No Format Could Be Found. Force Convert From Legacy Anyway.");
		final legacy = new FNFLegacy().fromFile(chartPath, null, diffi);
		final kade = new FNFKade().fromFormat(legacy, diffi);
		Debug.logTrace('Legacy To Kade For $name with diff $diff');
		return compat(kade.data.song);
	}

	public static function compat(data:Dynamic, ?name:String = null):ChartData
	{
		var songName:String = name ?? data.songId;
		songName = songName.toTitleCase();
		final songId:String = songName.toLowerKebabCase();
		// retarded
		var newSong:ChartData = {
			songId: songId,
			songName: songName,
			audioFile: songId,
			stage: data.stage,
			notes: convertNotes(data),
			player1: data.player1,
			player2: data.player2,
			gfVersion: data.gfVersion,
			validScore: data.validScore,
			speed: data.speed,
			bpm: data.bpm,
			eventObjects: [
				{
					name: 'Init BPM',
					type: "BPM Change",
					args: [data.bpm],
					beat: 0
				}
			],
			chartVersion: Constants.chartVer,
			needsVoices: data.needsVoices,
			splitVoiceTracks: Paths.fileExists('songs/$songId/VoicesP.ogg'), // pisses me off a lot
			style: "Default"
		}
		Paths.runGC();
		return newSong;
	}

	public static function convertNotes(song:Dynamic):Array<Section>
	{
		final data:FNFKadeFormat = song;
		var newNotes:Array<Section> = [];
		var index = 0;
		var currentIndex = 0;
		TimingStruct.clearTimings();

		for (i in data.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.position;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, i.value, endBeat, 0); // offset in this case = start time since we don't have a offset

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
			final currentBeat = 4 * index;
			final currentSeg = TimingStruct.getTimingAtBeat(currentBeat);
			newNotes.push({
				index: i,
				sectionNotes: [],
				bpm: currentSeg.bpm,
				mustHitSection: section.mustHitSection,
				lengthInSteps: 16,
				startTime: section.startTime,
			}); // create a blank for now
			// vibrant:dad:0:#123123

			for (ii in section.sectionNotes)
			{
				if (section.mustHitSection)
					ii[1] = (ii[1] + 4) % 8;

				if (ii[3] == null || ii[3] == 0)
					ii[3] = "Normal";

				final strumTime = ii[0];
				final noteData = ii[1];
				final holdLength = ii[2];
				final nType = ii[3];
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
		TimingStruct.clearTimings();
		return newNotes;
	}

	// convert KEC1 to KEC2
	public static function convertKEC1(song:Dynamic):ChartData
	{
		final data:KEC1Format = cast song.song;

		data.eventObjects = convertEvents(data);
		var newNotes:Array<Section> = [];
		var index = 0;
		var currentIndex = 0;

		if (data.style == null)
			data.style = "Default";

		TimingStruct.clearTimings();
		for (i in data.eventObjects)
		{
			if (i.type == "BPM Change")
			{
				var beat:Float = i.beat;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, Std.parseFloat(i.args[0]), endBeat, 0); // offset in this case = start time since we don't have a offset
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
		final newSong:ChartData = {
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
		// Song.recalculateAllSectionTimes(newSong);
		newNotes = null;
		return newSong;
	}

	private static function checkEvents(song:KEC1Format):Array<Event>
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
		}
		return song.eventObjects;
	}

	private static function convertEvents(song:KEC1Format):Array<Event>
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

typedef KEC1Format =
{
	var songName:String;
	var songId:String;
	var ?song:String;
	var chartVersion:String;
	var notes:Array<KEC1Section>;
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

typedef KEC1Section =
{
	var sectionNotes:Array<Array<Dynamic>>;
	var ?lengthInSteps:Null<Int>;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var ?index:Int;
	var ?playerSec:Bool;
}
