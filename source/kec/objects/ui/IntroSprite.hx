package kec.objects.ui;

import kec.backend.chart.Song.StyleData;

class IntroSprite extends FlxSprite
{
	public static var images:Array<String> = ['ready', 'set', 'go'];

	public function new()
	{
		super();
		frames = Paths.getSparrowAtlas('hud/${UIComponent.style.style.toLowerCase()}/intro');
		addAnims();
		alpha = 0.0001;
		scrollFactor.set();
		scale.set(0.8, 0.8);
		updateHitbox();
		moves = true;

		if (UIComponent.style.antialiasing == false)
			antialiasing = false;

		setGraphicSize(Std.int(width * UIComponent.style.scale));
		screenCenter();
	}

	public inline function appear(num:Int)
	{
		animation.play('$num');
		alpha = 1;
		velocity.set(0, 150);
		PlayState.instance.createTween(this, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
		});
	}

	public function addAnims()
	{
		for (i in 0...images.length)
		{
			animation.addByPrefix('$i', images[i], 1, false);
		}
	}
}
