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
	// new stuff based on vanilla
	public var stepsBetween:Int = 4;
	public var winningAmount:Float = 0.8 * 2;
	public var losingAmount:Float = 0.2 * 2;
	public var max:Float = 2.0;

	public static final defaultSize:Int = 150;

	public var sizeMult:Float = 0.1;

	public var allowedToBop:Bool = true;
	public var size:FlxPoint = new FlxPoint(1, 1);

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
			if (isAnimated)
			{
				offset.set(0, 0);

				frames = Paths.getSparrowAtlas('icons/animated/${newChar}');
				animation.addByPrefix('Idle', 'Idle', 24, false, isPlayer);
				animation.addByPrefix('Lose', 'Lose', 24, false, isPlayer);

				addOffset('Idle', 0, 0);
				addOffset('Lose', 0, 0);
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
					animation.add('Idle', [0], 0, false, isPlayer);
					animation.add('Lose', [1], 0, false, isPlayer);
					if (hasWinningIcon)
						animation.add('Win', [2], 0, false, isPlayer);
				}
			}

			if (char.endsWith('-pixel') || char.startsWith('senpai') || char.startsWith('spirit'))
				antialiasing = false
			else
				antialiasing = FlxG.save.data.antialiasing;

			char = newChar;
			animation.play('Idle');

			scrollFactor.set();
		}
		playAnimation('Idle');
		initTargetSize();
	}

	public function onStepHit(step:Int)
	{
		if ((FlxG.save.data.motion && allowedToBop) && step % stepsBetween == 0)
		{
			// Make the icon increase in size (the update function causes them to lerp back down).
			if (this.width > this.height)
				setGraphicSize(Std.int(this.width + (defaultSize * this.size.x * sizeMult)), 0);
			else
				setGraphicSize(0, Std.int(this.height + (defaultSize * this.size.y * sizeMult)));
			this.updateHitbox();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.save.data.motion && allowedToBop)
		{
			if (this.width > this.height)
			{
				// Apply linear interpolation while accounting for frame rate.
				var targetSize:Int = Std.int(CoolUtil.coolLerp(this.width, defaultSize * this.size.x, 0.15));
				setGraphicSize(targetSize, 0);
			}
			else
			{
				var targetSize:Int = Std.int(CoolUtil.coolLerp(this.height, defaultSize * this.size.y, 0.15));
				setGraphicSize(0, targetSize);
			}
			this.updateHitbox();
		}

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}

	inline function initTargetSize():Void
	{
		setGraphicSize(defaultSize);
		updateHitbox();
	}

	/**
	 * @return Name of the current animation being played by this health icon.
	 */
	public function getCurrentAnimation():String
	{
		if (this.animation == null || this.animation.curAnim == null)
			return "";
		return this.animation.curAnim.name;
	}

	public function updateHealthIcon(health:Float):Void
	{
		// We want to efficiently handle animation playback

		// Here, we use the current animation name to track the current state
		// of a simple state machine. Neat!

		switch (getCurrentAnimation())
		{
			case "Idle":
				if (health < losingAmount)
					playAnimation("Lose");
				else if (health > winningAmount)
					playAnimation("Win");
				else
					playAnimation("Idle");
			case "Win":
				if (health < winningAmount)
					playAnimation("Idle");
				else
					playAnimation("Win");
			case "Lose":
				if (health > losingAmount)
					playAnimation("Idle");
				else
					playAnimation("Lose");
			case '':
				playAnimation("Idle");
			default:
				playAnimation("Idle");
		}
	}

	public function hasAnimation(id:String):Bool
	{
		if (this.animation == null)
			return false;

		return this.animation.getByName(id) != null;
	}

	public function finishedAnim()
	{
		if (this.animation == null)
			return false;

		if (this.animation.curAnim.finished)
			return true;
		else
			return false;
	}

	function playAnimation(newAnim:String)
	{
		if (hasAnimation(newAnim) && finishedAnim())
		{
			this.animation.play(newAnim, true, false);
			var daOffset = animOffsets.get(newAnim);

			if (animOffsets.exists(newAnim))
				offset.set(daOffset[0], daOffset[1]);
			else
				offset.set(0, 0);
			return;
		}
	}
}
