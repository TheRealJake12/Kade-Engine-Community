package kec.objects.ui;

class ComboNumber extends UIComponent
{
	public function loadNum(num:Int)
	{
		loadGraphic(Paths.image('hud/${style.style.toLowerCase()}/num$num'));
		setGraphicSize(Std.int(width * style.scale));
		updateHitbox();
		alpha = 1;
		acceleration.y = FlxG.random.int(200, 300);
		velocity.y -= FlxG.random.int(140, 160);
		velocity.x = FlxG.random.float(-5, 5);
		if (style.antialiasing == false)
			antialiasing = false;
	}
}
