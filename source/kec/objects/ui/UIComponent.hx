package kec.objects.ui;

import kec.backend.chart.Song.StyleData;

/**
 * Class Used For UI Components Like Ratings And Combo Numbers.
 * Exists Only Because Of Sorting And Recycling.
 */
class UIComponent extends FlxSprite
{
	public var startTime:Float;
	// Conductor Song Position. The Meat And Potatos Of Sorting.
	public var style:StyleData = null;
	// The Style. Used For Scaling, Antialiasing, And Image Pathing.
	public var lastName:String = null;

	// To Avoid Loading The Same Image Multiple Times. lol.
	// Handles The Fading Out.

	public function new()
	{
		super();
	}

	public function setup()
	{
		velocity.set(0, 0);
		acceleration.set(0, 0);
		alpha = 0.001;
		moves = true;
		startTime = Conductor.songPosition;
	}

	public function fadeOut()
	{
		PlayState.instance.createTween(this, {alpha: 0}, 0.2, {
			startDelay: (Conductor.crochet * Math.pow(PlayState.songMultiplier, 2)) * 0.001,
			onComplete: function(t:FlxTween)
			{
				kill();
			}
		});
	}
}
