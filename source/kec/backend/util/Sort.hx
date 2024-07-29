package kec.backend.util;

import flixel.util.FlxSort;
import haxe.ds.ArraySort;
import kec.objects.Note;
import kec.backend.chart.NoteData;
import kec.backend.chart.Song.Event;
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

	public static inline function sortNoteData(Obj1:NoteData, Obj2:NoteData):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public static inline function sortEvents(e1:Event, e2:Event)
	{
		return FlxSort.byValues(FlxSort.ASCENDING, e1.position, e2.position);
	}

	public static inline function sortUI(order:Int, a:UIComponent, b:UIComponent):Int
	{
		return FlxSort.byValues(-1, a.startTime, b.startTime);
	}
}
