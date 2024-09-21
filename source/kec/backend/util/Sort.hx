package kec.backend.util;

import flixel.util.FlxSort;
import haxe.ds.ArraySort;
import kec.objects.note.Note;
import kec.backend.chart.ChartNote;
import kec.backend.chart.Event;
import kec.objects.ui.UIComponent;

/**
 * Class Used For Sorting Things Globally Instead Of Being Specific To States.
 */
class Sort
{
	public static inline function sortNotes(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static inline function sortChartNotes(Obj1:ChartNote, Obj2:ChartNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.time, Obj2.time);
	}

	public static inline function sortEvents(e1:Event, e2:Event)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, e1.beat, e2.beat);
	}

	public static inline function sortUI(order:Int, a:UIComponent, b:UIComponent):Int
	{
		return FlxSort.byValues(-1, a.startTime, b.startTime);
	}
}
