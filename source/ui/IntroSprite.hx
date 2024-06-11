package ui;

import Song.StyleData;

class IntroSprite extends FlxSprite
{
	public static var images:Array<String> = ['ready', 'set', 'go'];
	public static var style:StyleData;

	public function new(image:String, num:Int = 0)
	{
		super();
		loadGraphic(Paths.image('hud/${style.style.toLowerCase()}/$image'));
		alpha = 0.0001;
		scrollFactor.set();
		scale.set(0.7, 0.7);
		updateHitbox();

		if (style.antialiasing == false)
			antialiasing = false;

		setGraphicSize(Std.int(width * style.scale));
		screenCenter();
	}

    public inline function appear()
    {
        alpha = 1;
		PlayState.instance.createTween(this, {alpha: 0}, Conductor.crochet / 1000, {
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween)
			{
				destroy();
			}
		});
    }
}
