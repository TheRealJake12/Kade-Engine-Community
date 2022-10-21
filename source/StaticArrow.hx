package;

import LuaClass;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;
import PlayState;

using StringTools;

class StaticArrow extends FlxSprite
{
	#if FEATURE_LUAMODCHART
	public var luaObject:LuaReceptor;
	#end
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	public var direction:Float = 90;

	public var downScroll:Bool = false;

	public function new(xx:Float, yy:Float)
	{
		x = xx;
		y = yy;
		super(x, y);
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;
		super.update(elapsed);

		if (FlxG.keys.justPressed.THREE)
		{
			localAngle += 10;
		}
	}

	public function playAnim(AnimName:String, ?force:Bool = false):Void
	{
		animation.play(AnimName, force);

		if (!AnimName.startsWith('dirCon'))
		{
			localAngle = 0;
		}
		updateHitbox();
		offset.set(frameWidth / 2, frameHeight / 2);

		offset.x -= 54;
		offset.y -= 56;

		angle = localAngle + modAngle;
	}
}
