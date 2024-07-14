package kec.objects.ui;

import kec.backend.chart.Song.StyleData;

class IntroSprite extends FlxSprite
{
	public static var images:Array<String> = ['ready', 'set', 'go'];
	public static var style:StyleData;

	public function new(image:String)
	{
		super();
		if (Paths.fileExists('hud/${style.style.toLowerCase()}/$image', IMAGE))
			loadGraphic(Paths.image('hud/${style.style.toLowerCase()}/$image'));
		else
			loadGraphic(Paths.image('hud/default/$image'));	
		alpha = 0.0001;
		scrollFactor.set();
		scale.set(0.8, 0.8);
		updateHitbox();
		moves = true;

		if (style.antialiasing == false)
			antialiasing = false;

		setGraphicSize(Std.int(width * style.scale));
		screenCenter();
	}

	public inline function appear()
	{
		alpha = 1;
		velocity.set(0, 150);
		PlayState.instance.createTween(this, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
		});
	}
}
