package kec.backend.chart.format;

typedef LegacySection =
{
	var sectionNotes:Array<Array<Dynamic>>;
	var ?lengthInSteps:Null<Int>;
	var mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var ?index:Int;
	var ?playerSec:Bool;
}
