package kec.substates;

import flixel.addons.transition.Transition;
import flixel.addons.transition.TransitionData;
import flixel.util.FlxGradient;
import kec.substates.MusicBeatSubstate;

/**
 *
 * Transition overrides
 * @author Shadow_Mario_
 *
**/
class CustomFadeTransition extends FlxSpriteGroup
{
	public var finishCallback:Void->Void;

	private var leTween:FlxTween;

	private var inTween:FlxTween;

	public var isTransIn:Bool = false;

	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float = 0;

	public function new(duration:Float)
	{
		super();
		visible = false;
		active = false;
		scrollFactor.set(0, 0);

		this.duration = duration;
		var width:Int = Std.int(FlxG.width);
		var height:Int = Std.int(FlxG.height);
		transGradient = FlxGradient.createGradientFlxSprite(width, height, [0x0, FlxColor.BLACK]);
		transGradient.scrollFactor.set();

		transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
		transBlack.scrollFactor.set();

		transGradient.x -= (width - FlxG.width) / 2;
		transBlack.x = transGradient.x;

		transBlack.setPosition(0, 0);
		transGradient.setPosition(0, 0);

		add(transGradient);
		add(transBlack);

		camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	private function resetTrans() // prepare to change your pronouns
	{
		visible = false;
		active = false;

		transGradient.scale.x = 1 / camera.zoom;
		transGradient.scale.y = 1 / camera.zoom;
		transGradient.updateHitbox();

		transBlack.setPosition(0, 0);
		transGradient.setPosition(0, 0); // Send them to brazil, before tweening they get their correct position

		if (leTween != null)
		{
			leTween.cancel();
			leTween.destroy();
		}
		if (inTween != null)
		{
			inTween.cancel();
			inTween.destroy();
		}
	}

	public function executeTransition() // suicide
	{
		resetTrans();

		if (isTransIn)
		{
			transGradient.y = transBlack.y - transBlack.height;
			transGradient.flipY = false;

			inTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
						finishCallback();
				},
				ease: FlxEase.linear
			});
		}
		else
		{
			transGradient.y = -transGradient.height;
			transGradient.flipY = true;

			leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
						finishCallback();
				},
				ease: FlxEase.linear
			});
		}

		active = true;
		visible = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;
	}

	override function destroy()
	{
		if (leTween != null)
		{
			if (finishCallback != null)
				finishCallback();
			leTween.cancel();
			leTween.destroy();
		}
		if (inTween != null)
		{
			if (finishCallback != null)
				finishCallback();
			inTween.cancel();
			inTween.destroy();
		}
		if (finishCallback != null)
			finishCallback = null;
		super.destroy();
	}
}