package kec.backend.util;

import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxBitmapFont;
import flixel.text.FlxBitmapText;
#if VIDEOS
import hxvlc.flixel.FlxVideo as VideoHandler;
import hxvlc.util.Handle;
#end
#if FEATURE_FILESYSTEM
import sys.io.File;
import Sys;
import sys.FileSystem;
#end
import haxe.io.Path;
import lime.utils.Assets as LimeAssets;

using StringTools;

class CoolUtil
{
	public static var defaultDifficulties:Array<String> = ['Easy', "Normal", "Hard"];
	public static var suffixDiffsArray:Array<String> = ['-easy', "", "-hard"];

	public static var customDifficulties:Array<String> = [];

	public static var difficultyArray:Array<String> = getGlobalDiffs();
	public static var defaultDifficulty:String = 'Normal'; // The chart that has no suffix and starting difficulty on Freeplay/Story Mode
	public static var noteShitArray:Array<String> = ['Alt', 'Hurt', 'Must Press']; // Grabs the custom notetypes (not normal)

	public static var difficulties:Array<String> = [];

	public static function difficultyFromInt(difficulty:Int):String
	{
		return difficultyArray[difficulty];
	}

	public static function getDifficultyFilePath(num:Null<Int> = null)
	{
		if (num == null)
			num = PlayState.storyDifficulty;

		var fileSuffix:String = difficulties[num];
		if (fileSuffix != defaultDifficulty)
		{
			fileSuffix = '-' + fileSuffix;
		}
		else
		{
			fileSuffix = '';
		}
		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString():String
	{
		return difficulties[PlayState.storyDifficulty].toUpperCase();
	}

	static function getGlobalDiffs():Array<String>
	{
		var returnArray:Array<String> = [];
		if (defaultDifficulties.length > 0)
			for (el in defaultDifficulties)
				returnArray.push(el);

		if (customDifficulties.length > 0)
			for (el2 in customDifficulties)
				returnArray.push(el2);

		return returnArray;
	}

	inline public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function fpsLerp(v1:Float, v2:Float, ratio:Float):Float
	{
		return FlxMath.lerp(v1, v2, getFPSRatio(ratio));
	}

	public static function getFPSRatio(ratio:Float):Float
	{
		return FlxMath.bound(ratio * 60 * FlxG.elapsed, 0, 1);
	}

	/**
	 * Linearly interpolate between two values.
	 *
	 * @param base The starting value, when `progress <= 0`.
	 * @param target The ending value, when `progress >= 1`.
	 * @param progress Value used to interpolate between `base` and `target`.
	 * @return The interpolated value.
	 */
	public static function lerp(base:Float, target:Float, progress:Float):Float
	{
		return base + progress * (target - base);
	}

	/**
	 * Perform a framerate-independent linear interpolation between the base value and the target.
	 * @param current The current value.
	 * @param target The target value.
	 * @param elapsed The time elapsed since the last frame.
	 * @param duration The total duration of the interpolation. Nominal duration until remaining distance is less than `precision`.
	 * @param precision The target precision of the interpolation. Defaults to 1% of distance remaining.
	 * @see https://twitter.com/FreyaHolmer/status/1757918211679650262
	 *
	 * @return A value between the current value and the target value.
	 */
	public static function smoothLerp(current:Float, target:Float, elapsed:Float, duration:Float, precision:Float = 1 / 100):Float
	{
		// An alternative algorithm which uses a separate half-life value:
		// var halfLife:Float = -duration / logBase(2, precision);
		// lerp(current, target, 1 - exp2(-elapsed / halfLife));

		if (current == target)
			return target;

		var result:Float = lerp(current, target, 1 - Math.pow(precision, elapsed / duration));

		// TODO: Is there a better way to ensure a lerp which actually reaches the target?
		// Research a framerate-independent PID lerp.
		if (Math.abs(result - target) < (precision * target))
			result = target;

		return result;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function getSuffixFromDiff(diff:String):String
	{
		var suffix = '';
		if (diff != 'Normal')
			suffix = '-${diff.toLowerCase()}';

		return suffix;
	}

	public static var daPixelZoom:Float = 6;

	public static function camLerpShit(lerp:Float):Float
	{
		return lerp * (FlxG.elapsed / (1 / 60));
	}

	/*
	 * just lerp that does camLerpShit for u so u dont have to do it every time
	 */
	public static function coolLerp(a:Float, b:Float, ratio:Float):Float
	{
		return FlxMath.lerp(a, b, camLerpShit(ratio));
	}

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String>;

		try
		{
			daList = OpenFlAssets.getText(path).trim().split('\n');
		}
		catch (e)
		{
			daList = null;
		}

		if (daList != null)
			for (i in 0...daList.length)
			{
				daList[i] = daList[i].trim();
			}

		return daList;
	}

	public static function coolStringFile(path:String):Array<String>
	{
		var daList:Array<String> = path.trim().split('\n');

		for (i in 0...daList.length)
		{
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];
		for (i in min...max)
		{
			dumbArray.push(i);
		}
		return dumbArray;
	}

	inline public static function colorFromString(color:String):FlxColor
	{
		var hideChars = ~/[\t\n\r]/;
		var color:String = hideChars.split(color).join('').trim();
		if (color.startsWith('0x'))
			color = color.substr(4);

		var colorNum:Null<FlxColor> = FlxColor.fromString(color);
		if (colorNum == null)
			colorNum = FlxColor.fromString('#$color');
		return colorNum != null ? colorNum : FlxColor.WHITE;
	}

	/**
		* Similar to FileSystem.readDirectory() using OpenFLAssets (manifest.json)
		** WARNING: This function doesn't replace FileSystem.readDirectory(), this only lists the assets that came with the build, 
		* if you drag new files to the assets folder it won't be detected!
		** NOTE: Newer files dragged via ModCore/Polymod are detected!
		* @param path The specific directory you want to read.
		* @param library The library you want to scan. Ex: shared.
	 */
	public static function readAssetsDirectoryFromLibrary(path:String, ?type:String, ?library:String = 'default', ?removePath:Bool = true):Array<String>
	{
		var lib = LimeAssets.getLibrary(library);
		var list:Array<String> = lib.list(type);
		var stringList = [];
		for (hmm in list)
		{
			if (hmm.startsWith(path))
			{
				var bruh = null;
				if (removePath)
					bruh = hmm.replace('$path/', '');
				else
					bruh = hmm;
				stringList.push(bruh);
			}
		}

		stringList.sort(Reflect.compare);

		return stringList;
	}

	public static var loadingVideos:Array<String> = [];
	public static var loadedVideos:Array<String> = [];

	public static function precacheVideo(name:String):Void
	{
		#if VIDEOS
		if (FileSystem.exists(Paths.video(name)))
		{
			if (!loadedVideos.contains(name))
			{
				var cache:VideoHandler = new VideoHandler();
				cache.mute = true;
				cache.load(Paths.video(name));
				loadedVideos.push(name);
				FlxG.log.add('Video file has been cached: ' + name);
			}
			else
			{
				FlxG.log.add('Video file has already been cached: ' + name);
			}
		}
		else
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
		}
		#else
		FlxG.log.warn('Platform not supported!');
		#end
	}

	public static inline function getFileStringFromPath(file:String):String
	{
		return Path.withoutDirectory(Path.withoutExtension(file));
	}
}
