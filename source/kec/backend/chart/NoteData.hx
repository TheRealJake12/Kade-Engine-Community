package kec.backend.chart;

typedef NoteData =
{
	/**
	 * Note Position In A Chart In MS
	 */
	var strumTime:Float;

	/**
	 * What Direction / Player A Note Is. Kind Of Like An ID.
	 */
	var noteData:Int;

	/**
	 * If Sustain Length Is Greater Than 0, It's A Sustain Note. General Sustain Length.
	 */
	var sustainLength:Float;

	/**
	 * The Type Of Note It Is (Normal, Hurt, Must Press, Alt, GF, etc.)
	 */
	var noteType:String;

	var ?isPlayer:Bool;
	var ?beat:Float;
}
