package kec.objects.ui;

class ComboNumber extends UIComponent
{
	public function new()
	{
		super();
		frames = Paths.getSparrowAtlas('hud/${UIComponent.style.style.toLowerCase()}/${UIComponent.style.style.toLowerCase()}', 'shared');
		if (UIComponent.style.antialiasing == false)
			antialiasing = false;
		addAnims();
		alpha = 0;
	}

	public function loadNum(num:Int)
	{
		animation.play('num$num', true);
		setGraphicSize(Std.int(frameWidth * UIComponent.style.scale));
		updateHitbox();
		alpha = 1;
		acceleration.y = FlxG.random.int(200, 300);
		velocity.y -= FlxG.random.int(140, 160);
		velocity.x = FlxG.random.float(-5, 5);
	}

	public function addAnims()
	{
		for (i in 0...9)
		{
			animation.addByPrefix('num$i', 'num$i', 1, false);
		}
	}
}
