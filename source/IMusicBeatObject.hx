package;

/**
 * Implements beatHit and stepHit for objects
 * Author : BoloVEVO
 */
interface IMusicBeatObject
{
	public function stepHit(step:Int):Void;

	public function beatHit(beat:Int):Void;
}
