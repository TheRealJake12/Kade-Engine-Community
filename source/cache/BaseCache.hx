package cache;

import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Author @SGWLFNF In The Haxe Server.
 */
class BaseCache
{
	public static var cacheAmount:Int = 0;
	public static var loadedBefore = false;

	public static function addImage(image:String):Void
	{ // There we go. Much better than before
		var cacheImage:FlxSprite = cast new FlxSprite().loadGraphic(image);
		cacheImage.graphic.persist = cacheImage.graphic.destroyOnNoUse = !cacheImage.graphic.destroyOnNoUse;
		FlxG.bitmap.add(image, false, image); // Literally the only way
	}

	public static function addSound(sound:String):Void
	{
		var cacheSound:FlxSound = cast new FlxSound().loadEmbedded(sound);
		cacheSound.volume = 0.0001;
		cacheSound.play();
		cacheSound.stop();
	}

	public static function cacheStuff(baseDirectory:String):Void
	{
		try
		{
			for (image in CoolUtil.readAssetsDirectoryFromLibrary(baseDirectory, 'IMAGE'))
			{
				var filePath:String = '$image';

				// Debug.logTrace('$filePath ' + OpenFlAssets.exists(filePath, IMAGE));

				if (image.endsWith('.png'))
				{
					if (OpenFlAssets.exists(filePath, IMAGE))
					{
						BaseCache.addImage(filePath);
						Debug.logTrace('Caching Image $filePath...');
						cacheAmount++;
					}
				}
			}

			for (sound in CoolUtil.readAssetsDirectoryFromLibrary(baseDirectory, 'SOUND'))
			{
				var filePath:String = '$sound';

				// Debug.logTrace('$filePath ' + OpenFlAssets.exists(filePath, IMAGE));

				if (sound.endsWith('.' + Paths.SOUND_EXT))
				{
					if (OpenFlAssets.exists(filePath, SOUND))
					{
						BaseCache.addSound(filePath);
						Debug.logTrace('Caching Sound $filePath...');
						cacheAmount++;
					}
				}
			}
		}
		catch (e)
		{
			Debug.logTrace("Error Loading A File.");
		}
	}
}
