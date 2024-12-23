package kec.objects.menu;

/**
	* A Multipurpose Button Useful For Many Menus.

	Author : TheRealJake_12
 */
class MenuButton extends FlxSprite
{
	public var onClick:() -> Void;
	public var onRelease:() -> Void;
	public var onHover:() -> Void;
	public var onExit:() -> Void;
	public var blockInput:Bool = false;
	public var targSize:Float = 1.0;

	private var _hoverCheck:Bool = false;

	/**
	 * An All Purpose Button Used For Main Menu.
	 * @param x    The Starting X Position.
	 * @param y    The Starting Y Position.
	 * @param image    The Image To Load. Has To Be In The `shared/images` Folder. Can Load Any Subfolders From There.
	 * @param atlas    If It Should Look For A SparrowAtlas Instead 
	 */
	public function new(x:Float, y:Float, image:String = "", ?atlas:Bool = false)
	{
		super(x, y);

		onClick = function()
		{
		};
		onRelease = function()
		{
		};
		onHover = function()
		{
		};
		onExit = function()
		{
		};
		loadImage(image, atlas);
	}

	public function loadImage(path:String, atlas:Bool)
	{
		switch (atlas)
		{
			case true:
				frames = Paths.getSparrowAtlas(path);
			case false:
				loadGraphic(Paths.image(path));
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		if (blockInput)
			return;

		final lerp = CoolUtil.smoothLerp(scale.x, targSize, elapsed, 0.2);
		scale.set(lerp, lerp);

		if (FlxG.mouse.overlaps(this) && !_hoverCheck)
		{
			_hoverCheck = true;
			onHover();
		}
		else if (!FlxG.mouse.overlaps(this) && _hoverCheck)
		{
			_hoverCheck = false;
			onExit();
		}
		if (FlxG.mouse.overlaps(this))
		{
			if (FlxG.mouse.justPressed)
				onClick();
			else if (FlxG.mouse.justReleased)
				onRelease();
		}
	}
}
