package;

import LuaClass;
import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class StaticArrow extends FlxSprite
{
	#if FEATURE_LUAMODCHART
	public var luaObject:LuaReceptor;
	#end
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	public var laneFollowsReceptor:Bool = true;
	public var bgLane:FlxSprite;

	public var direction:Float = 90;

	public var downScroll:Bool = false;

	public function new(xx:Float, yy:Float)
	{
		x = xx;
		y = yy;
		super(x, y);
		updateHitbox();
	}

	public function loadLane()
	{
		bgLane = new FlxSprite(0, 0).makeGraphic(Std.int(Note.swagWidth), 2160);
		bgLane.antialiasing = FlxG.save.data.antialiasing;
		bgLane.color = FlxColor.BLACK;
		bgLane.visible = true;
		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.x = x - 2;
		bgLane.y += -300;
		bgLane.updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;
		super.update(elapsed);

		/*if (FlxG.keys.justPressed.THREE)
			{
				localAngle += 10;
		}*/

		bgLane.angle = direction - 90;
		if (laneFollowsReceptor)
			bgLane.x = (x - 2) - (bgLane.angle / 2);

		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.visible = visible;
	}

	public function playAnim(AnimName:String, ?force:Bool = false):Void
	{
		animation.play(AnimName, force);

		updateHitbox();

		if (frames != null)
		{
			offset.set(frameWidth / 2, frameHeight / 2);

			offset.x -= 54;
			offset.y -= 56;
		}

		angle = localAngle + modAngle;
	}
}
