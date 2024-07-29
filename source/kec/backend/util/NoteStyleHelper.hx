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
		if (Paths.fileExists('images/noteskins/${getNoteskinByID(id)}' + '-pixel' + (ends ? '-ends' : '') + ".png", IMAGE))
			return Paths.image('noteskins/${getNoteskinByID(id)}' + "-pixel" + (ends ? "-ends" : ""), 'shared');
		else
			return Paths.image("noteskins/Arrows-pixel" + (ends ? "-ends" : ""), 'shared');
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

	static public function generateNotesplashSprite(path:String, ?type:String = '')
	{
		if (type != '' && Paths.fileExists('images/notetypes/splashes/${path + type}.png', IMAGE))
			return 'notetypes/splashes/${path + type}';
		else
			return 'splashes/$path';
	}
}
