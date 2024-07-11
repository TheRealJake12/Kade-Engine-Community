package kec.states.editors;

class MakeRect
{
	public static inline function makeRect(sprite:FlxSprite, width:Float = 100, height:Float = 100, col:FlxColor = FlxColor.WHITE, unique:Bool = true,
			?key:String):FlxSprite
	{
		sprite.makeGraphic(1, 1, col, unique, key);
		sprite.scale.set(width, height);
		sprite.updateHitbox();
		return sprite;
	}
}