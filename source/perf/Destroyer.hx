package perf;

import flash.media.Sound;
import flixel.FlxG;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.Json;
import lime.utils.Assets;
import openfl.system.System;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display3D.textures.Texture;
import openfl.display.BitmapData;
import flixel.system.FlxSound;

using StringTools;
/*
	this entire hx file is just things that destroy music and hopefully fix some memory leaks
 */
class Destroyer
{
	inline public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static var currentTrackedTextures:Map<String, Texture> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function killMusic(songsArray:Array<FlxSound>)
	{
		// FUCK YOU HTML5
		#if PRELOAD_ALL
		// neat function thing for songs
		for (i in 0...songsArray.length)
		{
			// stop
			songsArray[i].stop();
			songsArray[i].destroy();
		}
		#end
	}

	public static function excludeAsset(key:String)
	{
		if (!dumpExclusions.contains(key))
			dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> = ['assets/music/freakyMenu.$SOUND_EXT', 'assets/shared/music/breakfast.$SOUND_EXT'];

	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		if (FlxG.save.data.unload)
		{
			#if FEATURE_MULTITHREADING
			// clear remaining objects
			MasterObjectLoader.resetAssets();
			#end

			// clear anything not in the tracked assets list
			var counterAssets:Int = 0;

			@:privateAccess
			for (key in FlxG.bitmap._cache.keys())
			{
				var obj = FlxG.bitmap._cache.get(key);
				if (obj != null && !currentTrackedAssets.exists(key))
				{
					OpenFlAssets.cache.removeBitmapData(key);
					OpenFlAssets.cache.clearBitmapData(key);
					OpenFlAssets.cache.clear(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					counterAssets++;
					//Debug.logTrace('Cleared and removed $counterAssets cached assets.');
				}
			}

			#if PRELOAD_ALL
			// clear all sounds that are cached
			var counterSound:Int = 0;
			for (key in currentTrackedSounds.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
				{
					// trace('test: ' + dumpExclusions, key);
					OpenFlAssets.cache.removeSound(key);
					OpenFlAssets.cache.clearSounds(key);
					currentTrackedSounds.remove(key);
					counterSound++;
					//Debug.logTrace('Cleared and removed $counterSound cached sounds.');
				}
			}

			// Clear everything everything that's left
			var counterLeft:Int = 0;
			for (key in OpenFlAssets.cache.getKeys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
				{
					OpenFlAssets.cache.clear(key);
					counterLeft++;
					//Debug.logTrace('Cleared and removed $counterLeft cached leftover assets.');
				}
			}

			// flags everything to be cleared out next unused memory clear
			localTrackedAssets = [];
			openfl.Assets.cache.clear("songs");
			#end
		}
	}

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		if (FlxG.save.data.unload)
		{
			// clear non local assets in the tracked assets list
			var counter:Int = 0;
			for (key in currentTrackedAssets.keys())
			{
				// if it is not currently contained within the used local assets
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
				{
					// get rid of it
					var obj = currentTrackedAssets.get(key);
					@:privateAccess
					if (obj != null)
					{
						var isTexture:Bool = currentTrackedTextures.exists(key);
						if (isTexture)
						{
							var texture = currentTrackedTextures.get(key);
							texture.dispose();
							texture = null;
							currentTrackedTextures.remove(key);
						}
						OpenFlAssets.cache.removeBitmapData(key);
						OpenFlAssets.cache.clearBitmapData(key);
						OpenFlAssets.cache.clear(key);
						FlxG.bitmap._cache.remove(key);
						obj.destroy();
						currentTrackedAssets.remove(key);
						counter++;
						//Debug.logTrace('Cleared and removed $counter assets.');
						//holy fucking shit bolo you like your traces dont you
					}
				}
			}
			// run the garbage collector for good measure lmfao

			System.gc();
		}
	}
}
