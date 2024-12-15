package kec.objects.ui;

class HealthIcon extends KECSprite
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
	// new stuff based on vanilla
	public var stepsBetween:Int = 4;
	public var winningAmount:Float = 0.8 * 2;
	public var losingAmount:Float = 0.2 * 2;
	public var max:Float = 2.0;

	public static final defaultSize:Int = 150;

	public var sizeMult:Float = 0.1;

	public var allowedToBop:Bool = true;
	public var size:FlxPoint = new FlxPoint(1, 1);
	public final animationNames:Array<String> = ['Idle', 'Lose', 'Win'];

	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();

		this.isPlayer = isPlayer;
		changeIcon(char);
		allowedToBop = FlxG.save.data.iconBop;
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
		if (newChar == char)
			return;

		char = newChar;
		var name:String = 'icon-' + newChar;
		switch (Paths.fileExists('images/icons/animated/' + name + '.png'))
		{
			case true:
				frames = Paths.getSparrowAtlas('icons/animated/$name');
				for (i in animationNames)
					animation.addByPrefix(i, i, 24, false, isPlayer);

			case false:
				if (!Paths.fileExists('images/icons/$name.png'))
					name = 'icon-face';
				final graphic = Paths.image('icons/$name');
				final iSize:Float = Math.round(graphic.width / graphic.height);
				loadGraphic(graphic, true, Math.floor(graphic.width / iSize), Math.floor(graphic.height));
				updateHitbox();
				for (i in 0...frames.frames.length)
					animation.add(animationNames[i], [i], 0, false, isPlayer);
		}
		animation.play('Idle');

		if (char.endsWith('-pixel') || char.startsWith('senpai') || char.startsWith('spirit'))
			antialiasing = false
		else
			antialiasing = FlxG.save.data.antialiasing;

		scrollFactor.set();
		playAnimation('Idle');
		initTargetSize();
	}

	public function onStepHit(step:Int)
	{
		if (!allowedToBop)
			return;

		if (step % stepsBetween != 0)
			return;
		// Make the icon increase in size (the update function causes them to lerp back down).
		if (this.width > this.height)
			setGraphicSize(Std.int(this.width + (defaultSize * this.size.x * sizeMult)), 0);
		else
			setGraphicSize(0, Std.int(this.height + (defaultSize * this.size.y * sizeMult)));
		this.updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);

		if (!allowedToBop)
			return;

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

	public function playAnimation(newAnim:String)
	{
		if (!hasAnimation(newAnim) && !finishedAnim())
			return;
		this.animation.play(newAnim, false, false);
		final daOffset = offsets.get(newAnim);

		if (offsets.exists(newAnim))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
		return;
	}
}
