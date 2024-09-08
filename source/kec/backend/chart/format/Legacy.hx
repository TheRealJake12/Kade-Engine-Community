package kec.backend.chart.format;

typedef Legacy =
{
	var songName:String;
	var songId:String;
	var ?song:String;
	var chartVersion:String;
	var notes:Array<LegacySection>;
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
