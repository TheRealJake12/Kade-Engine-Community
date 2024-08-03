package kec.substates;

import flixel.addons.transition.Transition;
import flixel.addons.transition.TransitionData;
import flixel.util.FlxGradient;
import kec.substates.MusicBeatSubstate;

class CustomFadeTransition extends MusicBeatSubstate
{
	public var finishCallback:Void->Void;

	private var leTween:FlxTween;

	private var inTween:FlxTween;

	public var nextCamera:FlxCamera;

	public var isTransIn:Bool = false;

	var transBlack:FlxSprite;
	var transGradient:FlxSprite;

	var duration:Float = 0;

	public function new(duration:Float)
	{
		super();

		this.duration = duration;
		var width:Int = Std.int(FlxG.width);
		var height:Int = Std.int(FlxG.height);
		transGradient = FlxGradient.createGradientFlxSprite(width, height, [0x0, FlxColor.BLACK]);
		transGradient.scrollFactor.set();

		transBlack = new FlxSprite().makeGraphic(width, height + 400, FlxColor.BLACK);
		transBlack.scrollFactor.set();

		transGradient.x -= (width - FlxG.width) / 2;
		transBlack.x = transGradient.x;

		openCallback = refresh;
	}

	override function create()
	{
		transBlack.setPosition(0, 0);
		transGradient.setPosition(0, 0);

		add(transGradient);
		add(transBlack);
		transBlack.alpha = 0;
		transGradient.alpha = 0;
		super.create();
	}

	private function refresh()
	{
		transBlack.setPosition(0, 0);
		transGradient.setPosition(0, 0);
		transBlack.alpha = 0;
		transGradient.alpha = 0;
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
		transition();
	}

	private function transition()
	{
		transBlack.alpha = 1;
		transGradient.alpha = 1;
		if (isTransIn)
		{
			transGradient.flipY = false;
			transGradient.y = transBlack.y - transBlack.height;
			inTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
						finishCallback();
					close();
				},
				ease: FlxEase.linear
			});
		}
		else
		{
			transGradient.flipY = true;
			transGradient.y = -transGradient.height;
			transBlack.y = transGradient.y - transBlack.height + 50;
			leTween = FlxTween.tween(transGradient, {y: transGradient.height + 50}, duration, {
				onComplete: function(twn:FlxTween)
				{
					if (finishCallback != null)
					{
						finishCallback();
					}
				},
				ease: FlxEase.linear
			});
		}
	}

	var camStarted:Bool = false;

	override function update(elapsed:Float)
	{
		if (isTransIn)
			transBlack.y = transGradient.y + transGradient.height;
		else
			transBlack.y = transGradient.y - transBlack.height;

		var camList = FlxG.cameras.list;
		camera = camList[camList.length - 1];
		transBlack.cameras = [camera];
		transGradient.cameras = [camera];

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
		super.close();
	}
}
