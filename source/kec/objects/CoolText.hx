package kec.objects;

import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;

/**
	* Helper Class of FlxBitmapText
	** WARNING: NON-LEFT ALIGNMENT might break some position properties such as X,Y and functions like screenCenter()
	** NOTE: IF YOU WANT TO USE YOUR CUSTOM FONT MAKE SURE THEY ARE SET TO SIZE = 32
	* @param 	sizeX	Be aware that this size property can could be not equal to FlxText size.
	* @param 	sizeY	Be aware that this size property can could be not equal to FlxText size.
	* @param 	bitmapFont	Optional parameter for component's font prop
 */
class CoolText extends FlxBitmapText
{
	public function new(xPos:Float, yPos:Float, sizeX:Float, sizeY:Float, ?bitmapFont:FlxBitmapFont)
	{
		super(bitmapFont);
		x = xPos;
		y = yPos;
		scale.set(sizeX / (font.size - 2), sizeY / (font.size - 2));
		text = '';

		updateHitbox();
	}

	override function destroy()
	{
		super.destroy();
	}

	override function update(elapsed)
	{
		super.update(elapsed);
	}
	/*public function centerXPos()
		{
			var offsetX = 0;
			if (alignment == FlxTextAlign.LEFT)
				x = ((FlxG.width - textWidth) / 2);
			else if (alignment == FlxTextAlign.CENTER)
				x = ((FlxG.width - (frameWidth - textWidth)) / 2) - frameWidth;
				
	}*/
}
