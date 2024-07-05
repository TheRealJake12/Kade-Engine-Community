package kec.backend.util;

#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.utils.Assets as OpenFlAssets;

class NoteStyleHelper
{
	public static var noteskinArray = [];
	public static var notesplashArray = ['Default', 'Psych']; // Defaults, should be in this order normally.

	public static function updateNoteskins()
	{
		noteskinArray = [];
		for (i in CoolUtil.readAssetsDirectoryFromLibrary('assets/shared/images/noteskins', 'IMAGE'))
		{
			if (i.contains("-pixel"))
				continue;

			if (!i.endsWith(".png"))
				continue;

			noteskinArray.push(i.replace(".png", ""));
		}
		return noteskinArray;
	}

	public static function getNoteskins()
	{
		return noteskinArray;
	}

	public static function getNoteskinByID(id:Int)
	{
		if (noteskinArray[id] != null)
			return noteskinArray[id];
		else
		{
			FlxG.save.data.noteskin = 0;
			FlxG.save.data.cpuNoteskin = 0;
			return noteskinArray[0];
		}
	}

	static public function generateNoteskinSprite(id:Int)
	{
		return 'noteskins/${getNoteskinByID(id)}';
	}

	static public function generatePixelSprite(id:Int, ends:Bool = false)
	{
		if (!OpenFlAssets.exists('assets/shared/images/noteskins/${getNoteskinByID(id)}' + '-pixel' + (ends ? '-ends' : '') + ".png", IMAGE))
		{
			// .png moment
			return Paths.image("noteskins/Arrows-pixel" + (ends ? "-ends" : ""), 'shared');
		}
		else
			return Paths.image('noteskins/${getNoteskinByID(id)}' + "-pixel" + (ends ? "-ends" : ""), 'shared');
	}

	public static function updateNotesplashes()
	{
		notesplashArray = [];
		for (i in CoolUtil.readAssetsDirectoryFromLibrary('assets/shared/images/splashes', 'IMAGE'))
		{
			if (!i.endsWith(".png"))
				continue;

			notesplashArray.push(i.replace(".png", ""));
		}
		return notesplashArray;
	}

	public static function getNotesplash()
	{
		return notesplashArray;
	}

	public static function getNotesplashByID(id:Int)
	{
		if (notesplashArray[id] != null)
			return notesplashArray[id];
		else
		{
			FlxG.save.data.notesplash = 0;
			return notesplashArray[0];
		}
	}

	static public function generateNotesplashSprite(id:Int, ?type:String = '')
	{
		if (type != '' && OpenFlAssets.exists('assets/shared/images/notetypes/splashes/${getNotesplashByID(id) + type}.png'))
			return 'notetypes/splashes/${getNotesplashByID(id) + type}';
		else
			return 'splashes/${getNotesplashByID(id)}';
	}
}
