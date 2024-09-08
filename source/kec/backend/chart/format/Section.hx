package kec.backend.chart.format;

/**
 * Old Section Shit For Conversion
 */
typedef Section =
{
	var ?startTime:Null<Float>;
	var ?endTime:Null<Float>;
	var sectionNotes:Array<ChartNote>;
	var lengthInSteps:Null<Int>;
	var mustHitSection:Bool;
	var bpm:Float;
	var index:Int;
}
