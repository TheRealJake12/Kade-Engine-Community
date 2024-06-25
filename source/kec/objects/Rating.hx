package kec.objects;

import kec.backend.chart.Song.StyleData;
import kec.backend.Ratings.RatingWindow;
import kec.backend.PlayStateChangeables;

class Rating extends FlxSprite
{
	public var style:StyleData;
	public var rating:RatingWindow;
	public var styleName:String = null;
	public var lastRating:String = null;

	public inline function setup()
	{
		x = FlxG.save.data.changedHitX;
		y = FlxG.save.data.changedHitY;
		velocity.set(0, 0);
		acceleration.set(0, 0);
		alpha = 0.001;
	}

	public function new(image:String = "marv", rating:RatingWindow)
	{
		super();
		moves = true;
		this.rating = rating;
	}

	public inline function loadRating(ratingName:String)
	{
		if (PlayStateChangeables.botPlay)
			return;
		if (lastRating != ratingName)
		{
			loadGraphic(Paths.image('hud/$styleName/' + ratingName));
			setGraphicSize(Std.int(width * style.scale * 0.7));
			updateHitbox();
		}
		lastRating = ratingName;
		alpha = 1;
		if (style.antialiasing == false)
			antialiasing = false;

		velocity.x -= FlxG.random.int(0, 10);
		acceleration.y = 550;
		velocity.y -= FlxG.random.int(140, 175);
	}

	public inline function fadeOut()
	{
		if (PlayStateChangeables.botPlay)
			return;
		PlayState.instance.createTween(this, {alpha: 0}, 0.2, {
			startDelay: (Conductor.crochet * Math.pow(PlayState.songMultiplier, 2)) * 0.001,
		});
	}
}
