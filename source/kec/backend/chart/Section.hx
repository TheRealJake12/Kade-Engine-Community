package kec.backend.chart;

typedef SwagSection =
{
	var ?startTime:Null<Float>;
	var ?endTime:Null<Float>;
	var sectionNotes:Array<Array<Dynamic>>;
	var lengthInSteps:Null<Int>;
	var ?mustHitSection:Bool;
	var bpm:Float;
	var changeBPM:Bool;
	var playerSec:Bool;
	var index:Int;
}
