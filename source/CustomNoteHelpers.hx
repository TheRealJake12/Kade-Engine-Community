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
	public static var xmlData = [];

	public static function updateNoteskins()
	{
		noteskinArray = [];
		xmlData = [];
		#if FEATURE_FILESYSTEM
		var count:Int = 0;
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/noteskins")))
		{
			if (i.contains("-pixel"))
				continue;
			if (i.endsWith(".xml"))
			{
				xmlData.push(sys.io.File.getContent(FileSystem.absolutePath("assets/shared/images/noteskins") + "/" + i));
				continue;
			}

			if (!i.endsWith(".png"))
				continue;
			noteskinArray.push(i.replace(".png", ""));
		}
		#else
		noteskinArray = ["Arrows", "Circles"];
		#end

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
		return Paths.getSparrowAtlas('noteskins/${CustomNoteHelpers.Skin.getNoteskinByID(FlxG.save.data.noteskin)}', 'shared');
	}

	static public function generatePixelSprite(id:Int, ends:Bool = false)
	{
		return Paths.image('noteskins/${CustomNoteHelpers.Skin.getNoteskinByID(FlxG.save.data.noteskin)}-pixel${(ends ? '-ends' : '')}', "shared");
	}
}

class Splash
{
	public static var notesplashArray = [];
	public static var xmlData = [];

	public static function updateNotesplashes()
	{
		notesplashArray = [];
		xmlData = [];
		#if FEATURE_FILESYSTEM
		var count:Int = 0;
		for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/splashes")))
		{
			if (i.endsWith(".xml"))
			{
				xmlData.push(sys.io.File.getContent(FileSystem.absolutePath("assets/shared/images/splashes") + "/" + i));
				continue;
			}
			if (!i.endsWith(".png"))
				continue;
			notesplashArray.push(i.replace(".png", ""));
		}
		#else
		notesplashArray = ["Default", "Week7"];
		#end

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
		#if FEATURE_FILESYSTEM
		// TODO: Make this use OpenFlAssets.

		var path = FileSystem.absolutePath("assets/shared/images/splashes") + "/" + getNotesplashByID(id);
		var data:BitmapData = BitmapData.fromFile(path + ".png");

		return FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(data), xmlData[id]);
		#else
		return Paths.getSparrowAtlas('splashes/Week7', "shared");
		#end
	}
}