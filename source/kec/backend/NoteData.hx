package kec.backend;

@:structInit
class NoteData
{
	/**
	 * Note Position In A Chart In MS
	 */
	public var strumTime:Float;

	/**
	 * What Direction / Player A Note Is. Kind Of Like An ID.
	 */
	public var noteData:Int;

	/**
	 * If Sustain Length Is Greater Than 0, It's A Sustain Note. General Sustain Length.
	 */
	public var sustainLength:Float;

	/**
	 * The Type Of Note It Is (Normal, Hurt, Must Press, Alt, GF, etc.)
	 */
	public var noteType:String;

	/**
	 * Is The Note A Player Note
	 */
	public var isPlayer:Bool;

	/**
	 * What Beat The Note Is At.
	 */
	public var beat:Float;
}
