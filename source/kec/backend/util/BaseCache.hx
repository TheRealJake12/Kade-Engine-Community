package kec.backend.util;

import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;

/**
 * Author @SGWLFNF In The Haxe Server.
 */
class BaseCache
{
	public static var cacheAmount:Int = 0;
	public static var loadedBefore = false;

	public static function addImage(image:String)
	{
		var placebo = cast new FlxSprite().loadGraphic(Paths.image(image));
		placebo.graphic.persist = true;
		placebo.graphic.destroyOnNoUse = false;
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
			for (sound in CoolUtil.readAssetsDirectoryFromLibrary(baseDirectory, 'SOUND'))
			{
				var filePath:String = '$sound';

				// Debug.logTrace('$filePath ' + OpenFlAssets.exists(filePath, IMAGE));

				if (sound.endsWith('.' + Paths.SOUND_EXT))
				{
					if (OpenFlAssets.exists(filePath, SOUND))
					{
						BaseCache.addSound(filePath);
						// Debug.logTrace('Caching Sound $filePath...');
						cacheAmount++;
					}
				}
			}

			for (image in CoolUtil.readAssetsDirectoryFromLibrary(baseDirectory, 'IMAGE'))
			{
				var filePath:String = image;
				if (filePath.endsWith('.png'))
				{
					if (OpenFlAssets.exists(filePath, IMAGE))
					{
						var bruh = filePath.replace('assets/shared/images/', '');
						var fard = bruh.replace('.png', '');
						addImage(fard);
						// Debug.logTrace('Caching Image $fard');
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
