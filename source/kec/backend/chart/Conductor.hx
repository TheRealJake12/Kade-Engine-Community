package kec.backend.chart;

class Conductor
{
	/**
	 * Current BPM of the song
	 */
	public static var bpm(default, set):Null<Float> = 60;

	/**
	 * Beats in miliseconds
	 */
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds

	/**
	 * Steps in miliseconds
	 */
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds

	/**
	 * Elapsed position since music started regardless of the playback rate
	 */
	public static var elapsedPosition:Float = -5000.0;

	/**
	 * Unused var for song offset. TODO: make it useful?
	 */
	public static var offset:Float = 0;

	/**
	 * Current playback rate the music is using, used to calculate song position regarding playback rate!
	 */
	public static var rate:Float = 1.0;

	/**
	 * Approach of music time, used to resync music if a lag spike occurs!
	 */
	public static var songPosition:Float = 0.0;

	private static function set_bpm(value:Float)
	{
		if (bpm == value)
			return value;
		bpm = value;
		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
		Debug.logTrace(bpm);
		return value;
	}
}
