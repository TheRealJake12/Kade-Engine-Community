#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import openfl.display.BitmapData;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxG;

using StringTools;

class Skin
{
	public static var noteskinArray = [];

	var ignoreList = ["Arrows", "Circles"];

	public static function updateNoteskins()
	{
		for (i in CoolUtil.readAssetsDirectoryFromLibrary('assets/shared/images/noteskins', 'IMAGE', 'shared'))
		{
			if (i.contains("-pixel"))
				continue;

			if (!i.endsWith(".png"))
				continue;
			var thingy = i.replace("assets/shared/images/noteskins/", "");

			// Debug.logTrace(i);

			noteskinArray.push(thingy.replace(".png", ""));
		}

		return noteskinArray;
	}

	public static function getNoteskins()
	{
		return noteskinArray;
	}

	public static function getNoteskinByID(id:Int)
	{
		return noteskinArray[id];
	}

	static public function generateNoteskinSprite(id:Int)
	{
		return 'noteskins/${getNoteskinByID(id)}';
	}

	static public function generatePixelSprite(id:Int, ends:Bool = false)
	{
		if (!Paths.fileExists('images/noteskins/${getNoteskinByID(id)}' + "-pixel" + (ends ? "-ends" : ""), IMAGE))
			return Paths.image("noteskins/Arrows-pixel" + (ends ? "-ends" : ""), 'shared');
		else
			return Paths.image('noteskins/${getNoteskinByID(id)}' + "-pixel" + (ends ? "-ends" : ""));
	}
}

class Splash
{
	public static var notesplashArray = ['Default', 'Psych', 'Week7'];

	public static function updateNotesplashes()
	{
		return notesplashArray;
	}

	public static function getNotesplash()
	{
		return notesplashArray;
	}

	public static function getNotesplashByID(id:Int)
	{
		return notesplashArray[id];
	}

	static public function generateNotesplashSprite(id:Int)
	{
		return 'splashes/${getNotesplashByID(id)}';
	}
}
