package kec.backend.chart;

import kec.backend.chart.format.Modern;

/**
 * Handy class that helps with beat and step measurements in song with variable bpm! 
 */
class TimingStruct
{
	public static var AllTimings:Array<TimingStruct> = [];

	public var bpm:Float = 0; // idk what does  this do

	public var startBeat:Float = 0; // BEATS
	public var startStep:Int = 0; // BAD MEASUREMENTS
	public var endBeat:Float = Math.POSITIVE_INFINITY; // BEATS

	public var startTime:Float = 0; // SECONDS

	public var length:Float = Math.POSITIVE_INFINITY; // in beats

	public static var lastTiming:TimingStruct;
	public static var nextTiming:TimingStruct;

	public function new(startBeat:Float, bpm:Float, endBeat:Float, offset:Float)
	{
		this.bpm = bpm;
		this.startBeat = startBeat;
		if (endBeat != -1)
			this.endBeat = endBeat;
		startTime = offset;
	}

	public static function clearTimings()
	{
		AllTimings.resize(0);
	}

	public static function addTiming(startBeat:Float, bpm, endBeat:Float, offset:Float):TimingStruct
	{
		var pog = new TimingStruct(startBeat, bpm, endBeat, offset);

		lastTiming = AllTimings[AllTimings.length - 1];
		if (lastTiming == null)
		{
			AllTimings.push(pog);
			return pog;
		}

		lastTiming.endBeat = startBeat;
		lastTiming.length = ((lastTiming.endBeat - lastTiming.startBeat) / (lastTiming.bpm / 60));
		var step = ((60 / lastTiming.bpm) * 1000) / 4;
		pog.startStep = Math.floor((((lastTiming.endBeat / (lastTiming.bpm / 60)) * 1000) / step));
		pog.startTime = lastTiming.startTime + lastTiming.length;

		AllTimings.push(pog);

		return pog;
	}

	public static function getBeatFromTime(time:Float)
	{
		var beat = -1.0;
		final seg = TimingStruct.getTimingAtTimestamp(time);

		if (seg != null)
			beat = seg.startBeat + (((time / 1000) - seg.startTime) * (seg.bpm / 60));

		return beat;
	}

	public static function getTimeFromLastTimingAtBeat(lastBeat:Float, curBeat:Float)
	{
		var time = -1.0;

		final seg = TimingStruct.getTimingAtBeat(lastBeat);
		if (seg != null)
			time = seg.startTime + ((curBeat - seg.startBeat) / (seg.bpm / 60));

		return time * 1000;
	}

	public static function getTimeFromBeat(beat:Float)
	{
		var time = -1.0;
		final seg = TimingStruct.getTimingAtBeat(beat);

		if (seg != null)
			time = seg.startTime + ((beat - seg.startBeat) / (seg.bpm / 60));

		return time * 1000;
	}

	public static function getTimingAtTimestamp(msTime:Float):TimingStruct
	{
		for (i in AllTimings)
		{
			if (msTime >= i.startTime * 1000 && msTime < (i.startTime + i.length) * 1000)
				return i;
		}
		return null;
	}

	public static function getTimingAtBeat(beat):TimingStruct
	{
		for (i in AllTimings)
		{
			if (i.startBeat <= beat && i.endBeat >= beat)
				return i;
		}
		return null;
	}

	public static function getBeatFromTimingTime(curTiming:TimingStruct, time:Float):Float
	{
		var beat = -1.0;
		final seg = curTiming;

		if (seg != null)
			beat = seg.startBeat + (((time / 1000) - seg.startTime) * (seg.bpm / 60));

		return beat;
	}

	public static function getTimeFromTimingBeat(curTiming:TimingStruct, beat:Float)
	{
		var time = -1.0;
		final seg = curTiming;

		if (seg != null)
			time = seg.startTime + ((beat - seg.startBeat) / (seg.bpm / 60));

		return time * 1000;
	}

	public static function setSongTimings(song:Modern)
	{
		TimingStruct.clearTimings();

		TimingStruct.addTiming(0, song.bpm, Math.POSITIVE_INFINITY, 0);
		var bpmIndex:Int = 0;
		for (event in song.eventObjects)
		{
			if (event.type == "BPM Change")
			{
				if (TimingStruct.AllTimings[bpmIndex] != null)
				{
					bpmIndex++;
					continue;
				}

				final beat:Float = event.beat;
				final endBeat:Float = Math.POSITIVE_INFINITY;
				final bpm = event.args[0];

				TimingStruct.addTiming(beat, bpm, endBeat, 0);

				bpmIndex++;
			}
		}
	}
}
