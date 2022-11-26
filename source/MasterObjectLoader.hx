
#if FEATURE_MULTITHREADING
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxUI;
import flixel.graphics.FlxGraphic;
import sys.thread.Mutex;

/**
	From: https://github.com/KadeDev/Hex-The-Weekend-Update
	Credits: KadeDev the funni avg4k frogman 
**/
class MasterObjectLoader
{
	public static var mutex:Mutex;

	public static var Objects:Array<Dynamic> = [];

	public static function addObject(object:Dynamic):Void
	{
		if (Std.isOfType(object, FlxSprite))
		{
			var sprite:FlxSprite = cast(object, FlxSprite);
			if (sprite.graphic == null)
				return;
		}
		if (Std.isOfType(object, FlxUI))
			return;
		mutex.acquire();
		Objects.push(object);
		mutex.release();
	}

	public static function removeObject(object:Dynamic):Void
	{
		if (Std.isOfType(object, FlxSprite))
		{
			var sprite:FlxSprite = cast(object, FlxSprite);
			if (sprite.graphic == null)
				return;
		}
		if (Std.isOfType(object, FlxUI))
			return;
		mutex.acquire();
		Objects.remove(object);
		mutex.release();
	}

	public static function resetAssets(removeLoadingScreen:Bool = false):Void
	{
		var keep:Array<Dynamic> = [];
		mutex.acquire();
		var counter:Int = 0;
		for (object in Objects)
		{
			if (Std.isOfType(object, FlxSprite))
			{
				var sprite:FlxSprite = object;
				if (sprite.ID >= 99999 && !removeLoadingScreen) // loading screen assets
				{
					keep.push(sprite);
					continue;
				}
				FlxG.bitmap.remove(sprite.graphic);
				// sprite.destroy();
				counter++;
			}
			if (Std.isOfType(object, FlxGraphic))
			{
				var graph:FlxGraphic = object;
				FlxG.bitmap.remove(graph);
				// graph.destroy();
				counter++;
			}
		}
		Objects = [];
		for (k in keep)
			Objects.push(k);
		mutex.release();
	}
}
#end