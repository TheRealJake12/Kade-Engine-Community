package kec.objects;

import openfl.display.Sprite;

/**
 * designed to draw a Open FL Sprite as a FlxSprite (to allow layering and auto sizing for haxe flixel cameras)
 * Custom made for Kade Engine
 */
class OFLSprite extends FlxSprite
{
	public var flSprite:Sprite;

	public function new(x, y, width:Int, height:Int, Sprite:Sprite)
	{
		super(x, y);

		flSprite = Sprite;

		makeGraphic(width, height, FlxColor.TRANSPARENT);

		pixels.draw(flSprite);
	}
}
