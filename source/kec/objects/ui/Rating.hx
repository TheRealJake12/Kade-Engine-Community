package kec.objects.ui;

class Rating extends UIComponent
{
	public function loadRating(ratingName:String)
	{
		if (lastName != ratingName)
		{
			loadGraphic(Paths.image('hud/${style.style.toLowerCase()}/' + ratingName));
			setGraphicSize(Std.int(width * style.scale * 0.7));
			updateHitbox();
		}
		lastName = ratingName;
		alpha = 1;
		if (style.antialiasing == false)
			antialiasing = false;

		velocity.x -= FlxG.random.int(0, 10);
		acceleration.y = 550;
		velocity.y -= FlxG.random.int(140, 175);
	}
}
