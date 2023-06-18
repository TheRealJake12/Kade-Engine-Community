package;

import flixel.FlxSprite;
import flixel.FlxG;

using StringTools;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	var char:String = '';
	var isPlayer:Bool = false;

	public var hasWinningIcon:Bool = false;
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char);
		scrollFactor.set();
	}

	public var isOldIcon:Bool = false;

	public function swapOldIcon():Void
	{
		isOldIcon = !isOldIcon;

		if (isOldIcon)
			changeIcon('bf-old');
		else
			changeIcon(PlayState.SONG.player1);
	}

	public function changeIcon(newChar:String):Void
	{
		if (newChar != 'bf-pixel' && newChar != 'bf-old')
			newChar = newChar.split('-')[0].trim();

		if (newChar != char)
		{
			if (animation.getByName(newChar) == null)
			{
				var name:String = 'icons/icon-' + newChar;
				var file:Dynamic = Paths.image(name);
				loadGraphic(file); // Load stupidly first for getting the file size
				if (width == 450)
					hasWinningIcon = true;
				loadGraphic(file, true, 150, 150); // Then load it fr
				updateHitbox();

				if (!hasWinningIcon)
					animation.add(newChar, [0, 1], 0, false, isPlayer);
				else
					animation.add(newChar, [0, 1, 2], 0, false, isPlayer);
			}
			if (char.endsWith('-pixel') || char.startsWith('senpai') || char.startsWith('spirit'))
				antialiasing = false
			else
				antialiasing = FlxG.save.data.antialiasing;
			animation.play(newChar);
			char = newChar;
		}

		initialWidth = width;
		initialHeight = height;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
