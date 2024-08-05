package kec.backend.chart;

class Conductor
{
	public static var bpm(default, set):Float;
	public static var crochet:Float = ((60 / bpm) * 1000) / multiplier; // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var multiplier:Float = 1; // rate or pitch or whatever.

	public static var rawPosition:Float;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000); // is calculated in create(), is safeFrames in milliseconds
	public static var timeScale:Float = Conductor.safeZoneOffset / 166;

	private static function set_bpm(value:Float)
	{
		if (bpm != value)
		{
			bpm = value * multiplier;
			crochet = ((60 / bpm) * 1000) / multiplier;
			stepCrochet = crochet / 4;
		}
		return value;
	}

	public static function recalculateTimings()
	{
		Conductor.safeFrames = FlxG.save.data.frames;
		Conductor.safeZoneOffset = Math.floor((Conductor.safeFrames / 60) * 1000);
		Conductor.timeScale = Conductor.safeZoneOffset / 166;
	}
}
