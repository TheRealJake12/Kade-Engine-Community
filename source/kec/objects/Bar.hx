package kec.objects;

import flixel.math.FlxRect;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;

class Bar extends FlxSpriteGroup
{
	public var leftBar:FlxSprite;
	public var rightBar:FlxSprite;
	public var background:FlxSprite;

	public var variableValue:Void->Float = null;
	public var percentage(default, set):Float = 0;
	public var limits:Dynamic = {min: 0, max: 1};

	public var goesToRight(default, set):Bool = true;
	public var imageCenter(default, null):Float = 0;

	public var barWidth(default, set):Int = 1;
	public var barHeight(default, set):Int = 1;
	public var barOffset:FlxPoint = new FlxPoint(3, 3);

	public function new(x:Float, y:Float, image:String = 'healthBar', variableValue:Void->Float = null, boundingX:Float = 0, boundingY:Float = 1)
	{
		super(x, y);

		this.variableValue = variableValue;
		setLimits(boundingX, boundingY);

		background = new FlxSprite().loadGraphic(Paths.image(image));
		leftBar = new FlxSprite().makeGraphic(Std.int(background.width), Std.int(background.height), FlxColor.WHITE);
		rightBar = new FlxSprite().makeGraphic(Std.int(background.width), Std.int(background.height), FlxColor.WHITE);

		barWidth = Std.int(background.width - 6);
		barHeight = Std.int(background.height - 6);

		add(leftBar);
		add(rightBar);
		add(background);
		redoClips();
	}

	public var enabled:Bool = true;

	override function update(elapsed:Float)
	{
		if (!enabled)
		{
			super.update(elapsed);
			return;
		}

		if (variableValue != null)
		{
			var value:Null<Float> = FlxMath.remapToRange(FlxMath.bound(variableValue(), limits.min, limits.max), limits.min, limits.max, 0, 100);
			percentage = (value != null ? value : 0);
		}
		else
			percentage = 0;

		super.update(elapsed);
	}

	public function setColors(left:FlxColor = null, right:FlxColor = null)
	{
		if (left != null)
			leftBar.color = left;
		if (right != null)
			rightBar.color = right;
	}

	public function setLimits(min:Float, max:Float)
	{
		limits.min = min;
		limits.max = max;
	}

	public function updateHealthBar()
	{
		if (leftBar == null || rightBar == null)
			return;

		leftBar.setPosition(background.x, background.y);
		rightBar.setPosition(background.x, background.y);

		var leftSize:Float = 0;

		if (goesToRight)
			leftSize = FlxMath.lerp(0, barWidth, percentage / 100);
		else
			leftSize = FlxMath.lerp(0, barWidth, 1 - percentage / 100);

		final rightRect = FlxRect.get(barOffset.x + leftSize, barOffset.y, barWidth - leftSize, barHeight);
		final leftRect = FlxRect.get(barOffset.x, barOffset.y, leftSize, barHeight);

		imageCenter = leftBar.x + leftSize + barOffset.x;

		leftBar.clipRect = leftRect;
		rightBar.clipRect = rightRect;
		FlxDestroyUtil.put(leftRect);
		FlxDestroyUtil.put(rightRect);
	}

	public function redoClips()
	{
		if (leftBar != null)
		{
			leftBar.setGraphicSize(Std.int(background.width), Std.int(background.height));
			leftBar.updateHitbox();
			leftBar.clipRect = FlxRect.get(0, 0, Std.int(background.width), Std.int(background.height));
		}
		if (rightBar != null)
		{
			rightBar.setGraphicSize(Std.int(background.width), Std.int(background.height));
			rightBar.updateHitbox();
			rightBar.clipRect = FlxRect.get(0, 0, Std.int(background.width), Std.int(background.height));
		}
		updateHealthBar();
	}

	private function set_percentage(value:Float)
	{
		var doUpdate:Bool = false;

		if (value != percentage)
			doUpdate = true;
		percentage = value;

		if (doUpdate)
			updateHealthBar();

		return value;
	}

	private function set_goesToRight(value:Bool)
	{
		goesToRight = value;
		updateHealthBar();
		return value;
	}

	private function set_barWidth(value:Int)
	{
		barWidth = value;
		redoClips();
		return value;
	}

	private function set_barHeight(value:Int)
	{
		barHeight = value;
		redoClips();
		return value;
	}
}
