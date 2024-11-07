package kec.objects;

/**
 * ### A Regular Ass FlxSprite But With Offsets.
 */
class KECSprite extends FlxSprite
{
	public var offsets:Map<String, Array<Int>>;

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);
		offsets = new Map<String, Array<Int>>();
	}

	public function addOffset(name:String, x:Int = 0, y:Int = 0)
	{
		offsets[name] = [x, y];
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0, centerOffsets:Bool = true):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		final daOffset = offsets.get(AnimName);
		if (offsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

		if (!centerOffsets)
			return;

		if (animation.curAnim == null)
			return;

		this.centerOffsets();
		centerOrigin();
	}

	override function destroy()
	{
		offsets.clear();
		super.destroy();
	}
}
