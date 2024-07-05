package kec.objects.ui;

class HealthIcon extends FlxSprite
{
	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public var animOffsets:Map<String, Array<Dynamic>>;

	var char:String = '';
	var isPlayer:Bool = false;

	public var isAnimated:Bool = false;
	public var hasWinningIcon:Bool = false;
	public var initialWidth:Float = 0;
	public var initialHeight:Float = 0;

	public function new(char:String = 'bf', isAnimated:Bool = false, isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		this.isAnimated = isAnimated;

		animOffsets = new Map<String, Array<Dynamic>>();

		changeIcon(char, isAnimated);
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

	public function changeIcon(newChar:String, isAnimated:Bool = false):Void
	{
		if (newChar != 'bf-pixel' && newChar != 'bf-old')
			newChar = newChar.split('-')[0].trim();

		if (newChar != char)
		{
			if (isAnimated == true)
			{
				offset.set(0, 0);

				frames = Paths.getSparrowAtlas('icons/animated/${newChar}');
				animation.addByPrefix('Idle', 'Idle', 24, true, isPlayer);
				animation.addByPrefix('Lose', 'Lose', 24, true, isPlayer);

				addOffset('Idle', 0, 0);
				addOffset('Lose', 0, 0);

				playAnim('Idle', true);
			}
			else
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
				animation.play(newChar);
			}

			if (char.endsWith('-pixel') || char.startsWith('senpai') || char.startsWith('spirit'))
				antialiasing = false
			else
				antialiasing = FlxG.save.data.antialiasing;

			char = newChar;

			scrollFactor.set();
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

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
		{
			offset.set(0, 0);
		}
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
