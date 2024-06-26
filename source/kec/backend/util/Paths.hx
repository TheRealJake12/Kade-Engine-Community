package kec.backend.util;

import flash.media.Sound;
import haxe.ui.ToolkitAssets;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.utils.Assets;
import openfl.system.System;
import openfl.display3D.textures.RectangleTexture;
import openfl.utils.AssetType;
import openfl.utils.Assets as OpenFlAssets;
import openfl.display3D.textures.Texture;
import openfl.display.BitmapData;
import flixel.graphics.frames.FlxBitmapFont;
#if cpp
import cpp.vm.Gc;
#end

using StringTools;

class Paths
{
	public static var SOUND_EXT = #if web "mp3" #else "ogg" #end;

	public static var currentLevel:String;
	public static var localTrackedAssets:Array<String> = [];
	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];
	public static var currentTrackedSounds:Map<String, Sound> = [];

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	static public function formatToSongPath(path:String)
	{
		return path.toLowerCase().replace(' ', '-');
	}

	public static function getPath(file:String, ?type:AssetType = TEXT, ?library:Null<String> = null):String
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, 'weeks', currentLevel);
				if (OpenFlAssets.exists(levelPath, type))
					return levelPath;
			}
		}

		return getSharedPath(file);
	}

	static public function getLibraryPath(file:String, library = "shared")
	{
		return if (library == "shared") getSharedPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String, ?level:String)
	{
		if (level == null)
			level = library;
		var returnPath = '$library:assets/$level/$file';
		return returnPath;
	}

	inline public static function getSharedPath(file:String = '')
	{
		return 'assets/shared/$file';
	}

	// Sprite content caching with GPU based on Forever Engine texture compression.

	/**
	 * For a given key and library for an image, returns the corresponding BitmapData.
	 		* We can probably move the cache handling here.
	 * @param key 
	 * @param library 
	 * @return BitmapData
	 */
	public static function loadImage(key:String, ?library:String = null, ?gpuRender:Bool):FlxGraphic
	{
		var path:String = '';

		path = getPath('images/$key.png', IMAGE, library);

		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(key))
			{
				// credits to raltyro for the simpler gpu rendering
				var bitmap = OpenFlAssets.getBitmapData(path);
				var graph:FlxGraphic = null;
				if (gpuRender && bitmap.image != null)
				{
					@:privateAccess {
						bitmap.lock();
						if (bitmap.__texture == null)
						{
							bitmap.image.premultiplied = true;
							bitmap.getTexture(FlxG.stage.context3D);
						}
						bitmap.getSurface();
						bitmap.disposeImage();
						bitmap.image.data = null;
						bitmap.image = null;
						bitmap.readable = true;
					}
				}

				graph = FlxGraphic.fromBitmapData(bitmap, false, key, false);
				graph.persist = true;

				currentTrackedAssets.set(key, graph);
			}

			localTrackedAssets.push(key);
			return currentTrackedAssets.get(key);
		}

		Debug.logWarn('Could not find image at path $path');
		return null;
	}

	static public function loadJSON(key:String, ?library:String):Dynamic
	{
		var rawJson = '';

		try
		{
			rawJson = OpenFlAssets.getText(Paths.json(key, library)).trim();
		}
		catch (e)
		{
			Debug.logError('Error loading JSON. $e');
			rawJson = null;
		}

		// Perform cleanup on files that have bad data at the end.
		if (rawJson != null)
		{
			while (!rawJson.endsWith("}"))
			{
				rawJson = rawJson.substr(0, rawJson.length - 1);
			}
		}

		try
		{
			// Attempt to parse and return the JSON data.
			if (rawJson != null)
			{
				return Json.parse(rawJson);
			}

			return null;
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);

			// Return null.
			return null;
		}
	}

	static public function loadData(key:String, ?library:String):Dynamic
	{
		var rawJson = OpenFlAssets.getText(Paths.data(key, library)).trim();

		// just for other files for jsons shits

		// Perform cleanup on files that have bad data at the end.
		while (!rawJson.endsWith("}"))
		{
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		try
		{
			// Attempt to parse and return the JSON data.
			return Json.parse(rawJson);
		}
		catch (e)
		{
			Debug.logError("AN ERROR OCCURRED parsing a JSON file.");
			Debug.logError(e.message);

			// Return null.
			return null;
		}
	}

	static public function hscript(key:String, ?library:String)
	{
		return getPath('data/$key.hx', TEXT, library);
	}

	static public function hx(key:String, ?library:String)
	{
		return getPath('$key.hx', TEXT, library);
	}

	public static function songMeta(key:String, ?library:String)
	{
		return getPath('data/songs/$key/_meta.json', TEXT, library);
	}

	static public function file(file:String, ?library:String, type:AssetType = TEXT)
	{
		return getPath(file, type, library);
	}

	static public function lua(key:String, ?library:String)
	{
		return getPath('data/$key.lua', TEXT, library);
	}

	static public function luaImage(key:String, ?library:String)
	{
		return getPath('data/$key.png', IMAGE, library);
	}

	static public function txt(key:String, ?library:String)
	{
		return getPath('$key.txt', TEXT, library);
	}

	static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	static public function imageXml(key:String, ?library:String)
	{
		return getPath('images/$key.xml', TEXT, library);
	}

	static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	static public function data(key:String, ?library:String)
	{
		return getPath(key + '.json', TEXT, library);
	}

	static public function shaderFragment(key:String, ?library:String)
	{
		return getPath('shaders/$key.frag', TEXT, library);
	}

	static public function shaderVertex(key:String, ?library:String)
	{
		return getPath('shaders/$key.vert', TEXT, library);
	}

	static public function sound(key:String, ?library:String):Any
	{
		var sound:Sound = loadSound('sounds', key, library);
		return sound;
	}

	public static function soundOld(key:String, ?library:String):String
	{
		return getPath('sounds/$key.${SOUND_EXT}', SOUND, library);
	}

	static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	static public function animJson(key:String, ?library:String)
	{
		return getPath('images/$key/Animation.json', TEXT, library);
	}

	static public function spriteMapJson(key:String, ?library:String)
	{
		return getPath('images/$key/spritemap.json', TEXT, library);
	}

	static public function image(key:String, ?library:String, ?gpuRender:Bool):FlxGraphic
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		var image:FlxGraphic = loadImage(key, library, gpuRender);
		return image;
	}

	static public function oldImage(key:String, ?library:String)
	{
		return getPath('images/$key.png', IMAGE, library);
	}

	#if VIDEOS
	static public function video(key:String)
	{
		return 'assets/videos/$key';
	}
	#end

	static public function music(key:String, ?library:String, ?returnString:Bool = false):Any
	{
		var file:Dynamic;
		if (!returnString)
			file = loadSound('music', key, library);
		else
			file = getPath('music/$key.$SOUND_EXT', SOUND, library);
		return file;
	}

	static public function voices(song:String, ?char:String = '', ?returnString:Bool = false):Any
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase() + '/Voices$char';
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}

		var file:Dynamic;
		#if PRELOAD_ALL
		if (!returnString)
			file = loadSound(null, songLowercase, 'songs');
		else
			file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#else
		file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#end
		return file;
	}

	static public function inst(song:String, ?returnString:Bool = false):Any
	{
		var songLowercase = StringTools.replace(song, " ", "-").toLowerCase() + '/Inst';
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}
		var file:Dynamic;
		#if PRELOAD_ALL
		if (!returnString)
			file = loadSound(null, songLowercase, 'songs');
		else
			file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#else
		file = 'songs:assets/songs/$songLowercase.$SOUND_EXT';
		#end

		return file;
	}

	public static function loadSound(path:Null<String>, key:String, ?library:String)
	{
		// I hate this so god damn much
		var gottenPath:String = '$key.$SOUND_EXT';
		if (path != null)
			gottenPath = '$path/$gottenPath';
		gottenPath = getPath(gottenPath, SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);
		if (!currentTrackedSounds.exists(gottenPath))
		{
			var retKey:String = (path != null) ? '$path/$key' : key;
			retKey = ((path == 'songs') ? 'songs:' : '') + getPath('$retKey.$SOUND_EXT', SOUND, library);
			if (OpenFlAssets.exists(retKey, SOUND))
			{
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(retKey));
			}
			else
			{
				Debug.logTrace("Sound File Not Found At " + gottenPath);
				return null;
			}
		}
		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	static public function doesSoundAssetExist(path:String)
	{
		if (path == null || path == "")
			return false;
		return OpenFlAssets.exists(path, AssetType.SOUND) || OpenFlAssets.exists(path, AssetType.MUSIC);
	}

	static public function doesTextAssetExist(path:String)
	{
		return OpenFlAssets.exists(path, AssetType.TEXT);
	}

	static public function font(key:String)
	{
		return 'assets/fonts/$key';
	}

	static public function bitmapFont(key:String, ?library:String):FlxBitmapFont
	{
		return FlxBitmapFont.fromAngelCode(image(key, library), fontXML(key, library));
	}

	static public function fontXML(key:String, ?library:String):Xml
	{
		return Xml.parse(OpenFlAssets.getText(getPath('images/$key.fnt', TEXT, library)));
	}

	static public function fileExists(key:String, type:AssetType, ?library:String)
	{
		if (OpenFlAssets.exists(getPath(key, type, library)))
			return true;

		return false;
	}

	public static var dumpExclusions:Array<String> = [
		'assets/shared/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/ke_freakyMenu.$SOUND_EXT'
	];

	public static function clearStoredMemory(?cleanUnused:Bool = false)
	{
		if (FlxG.save.data.unload)
		{
			// clear anything not in the tracked assets list
			@:privateAccess
			if (ToolkitAssets.instance._imageCache != null)
			{
				for (key in ToolkitAssets.instance._imageCache.keys())
				{
					ToolkitAssets.instance._imageCache.remove(key);
				}
			}

			@:privateAccess
			for (key in FlxG.bitmap._cache.keys())
			{
				var obj = cast(FlxG.bitmap._cache.get(key), FlxGraphic);
				if (obj != null && !currentTrackedAssets.exists(key))
				{
					obj.persist = false;
					obj.destroyOnNoUse = true;

					OpenFlAssets.cache.removeBitmapData(key);

					FlxG.bitmap._cache.remove(key);

					FlxG.bitmap.removeByKey(key);

					if (obj.bitmap.__texture != null)
					{
						obj.bitmap.__texture.dispose();
						obj.bitmap.__texture = null;
					}

					FlxG.bitmap.remove(obj);

					obj.dump();

					obj.bitmap.disposeImage();
					FlxDestroyUtil.dispose(obj.bitmap);
					obj.bitmap = null;

					obj.destroy();
					obj = null;
				}
			}

			// clear all sounds that are cached
			for (key in currentTrackedSounds.keys())
			{
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
				{
					// trace('test: ' + dumpExclusions, key);
					OpenFlAssets.cache.clear(key);
					OpenFlAssets.cache.removeSound(key);
					currentTrackedSounds.remove(key);
				}
			}

			FlxG.sound.list.forEachAlive(function(sound:flixel.sound.FlxSound):Void
			{
				FlxG.sound.list.remove(sound, true);
				sound.stop();
				sound.destroy();
			});
			FlxG.sound.list.clear();

			// this totally isn't copied from polymod/backends/LimeBackend.hx trust me

			var lime_cache:lime.utils.AssetCache = cast lime.utils.Assets.cache;

			for (key in lime_cache.image.keys())
				lime_cache.image.remove(key);
			for (key in lime_cache.font.keys())
				lime_cache.font.remove(key);
			for (key in lime_cache.audio.keys())
			{
				lime_cache.audio.get(key).dispose();
				lime_cache.audio.remove(key);
			};

			// thanks vortex from the FNF thread

			#if FEATURE_MODCORE
			polymod.Polymod.clearCache();
			#end

			#if !html5
			openfl.Assets.cache.clear("songs");
			#end
			// flags everything to be cleared out next unused memory clear
			localTrackedAssets = [];
			runGC();
		}
	}

	/// haya I love you for the base cache dump I took to the max
	public static function clearUnusedMemory()
	{
		if (FlxG.save.data.unload)
		{
			// clear non local assets in the tracked assets list
			@:privateAccess
			if (ToolkitAssets.instance._imageCache != null)
			{
				for (key in ToolkitAssets.instance._imageCache.keys())
				{
					ToolkitAssets.instance._imageCache.remove(key);
				}
			}

			for (key in currentTrackedAssets.keys())
			{
				// if it is not currently contained within the used local assets
				if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
				{
					// get rid of it
					var obj = cast(currentTrackedAssets.get(key), FlxGraphic);
					@:privateAccess
					if (obj != null)
					{
						obj.persist = false;
						obj.destroyOnNoUse = true;
						OpenFlAssets.cache.removeBitmapData(key);
						OpenFlAssets.cache.clearBitmapData(key);
						OpenFlAssets.cache.clear(key);

						FlxG.bitmap._cache.remove(key);
						FlxG.bitmap.removeByKey(key);

						if (obj.bitmap.__texture != null)
						{
							obj.bitmap.__texture.dispose();
							obj.bitmap.__texture = null;
						}

						FlxG.bitmap.remove(obj);

						obj.dump();
						obj.bitmap.disposeImage();
						FlxDestroyUtil.dispose(obj.bitmap);

						obj.bitmap = null;

						obj.destroy();

						obj = null;

						currentTrackedAssets.remove(key);
					}
				}
			}
			runGC();
			// to be safe that NO gc memory is left.
		}
	}

	public static function runGC()
	{
		#if cpp
		cpp.vm.Gc.enable(true);
		#end
		// Run built-in garbage collector
		#if sys
		openfl.system.System.gc();
		#end
	}

	static public function getSparrowAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSparrow(image('characters/$key', library, gpuRender), file('images/characters/$key.xml', library));
		}
		return FlxAtlasFrames.fromSparrow(image(key, library, gpuRender), file('images/$key.xml', library));
	}

	/**
	 * Senpai in Thorns uses this instead of Sparrow and IDK why.
	 */
	static public function getPackerAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
		{
			return FlxAtlasFrames.fromSpriteSheetPacker(loadImage('characters/$key', library, gpuRender), file('images/characters/$key.txt', library));
		}
		return FlxAtlasFrames.fromSpriteSheetPacker(loadImage(key, library, gpuRender), file('images/$key.txt', library));
	}

	static public function getJSONAtlas(key:String, ?library:String, ?isCharacter:Bool = false, ?gpuRender:Bool)
	{
		gpuRender = gpuRender != null ? gpuRender : FlxG.save.data.gpuRender;
		if (isCharacter)
			return FlxAtlasFrames.fromTexturePackerJson(image('characters/$key', library, gpuRender), file('images/characters/$key.json', library));

		return FlxAtlasFrames.fromTexturePackerJson(image(key, library), file('images/$key.json', library));
	}
}
