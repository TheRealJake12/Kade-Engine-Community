package kec.objects;

import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxColor;
import haxe.Int64;
import openfl.system.System;
import kec.util.HelperFunctions;
import kec.util.MemoryUtil;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
#end

class FrameCounter extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	/**
		The current memory usage (WARNING: this is NOT your total program memory usage, rather it shows the garbage collector memory)
	**/
	public var memoryMegas(get, never):String;
	public var gcMemory(get, never):String;

	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat("Monsterrat", 14, color);
		autoSize = LEFT;
		multiline = true;
		text = "FPS: ";

		times = [];
	}

	var deltaTimeout:Float = 0.0;

	// Event Handlers
	private override function __enterFrame(deltaTime:Float):Void
	{
		if (!visible)
			return;
		if (FlxG.save.data.fpsRain)
			textColor = FlxColor.fromHSB(FlxG.game.ticks * 0.25, 1, 1, 1);
		final now:Float = haxe.Timer.stamp() * 1000;
		times.push(now);
		while (times[0] < now - 1000)
			times.shift();
		// prevents the overlay from updating every frame, why would you need to anyways @crowplexus
		if (deltaTimeout < 50)
		{
			deltaTimeout += deltaTime;
			return;
		}

		currentFPS = times.length < FlxG.updateFramerate ? times.length : FlxG.updateFramerate;
		updateText();
		deltaTimeout = 0.0;
	}

	private inline function updateText():Void
	{
		final stateText:String = (FlxG.save.data.showState ? "Game State: " + Main.mainClassState : "");
		final watermark:String = (FlxG.save.data.fpsmark ? Constants.kecVer : "");
		var items:String = "";
		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		items = (FlxG.save.data.glDebug ? "Items Rendered: " + Context3DStats.totalDrawCalls() : "");
		#end
		text = 'FPS: ${currentFPS}' + '\n${memoryMegas}${gcMemory}' + '\n$stateText' + '\n$items' + '\n$watermark';
	}

	static final intervalArray:Array<String> = ['B', 'KB', 'MB', 'GB', 'TB', 'PB', 'EB', 'ZB', 'YB'];

	public static function getInterval(size:Float)
	{
		var data:Int = 0;
		while (size > 1024 && data < intervalArray.length - 1)
		{
			data++;
			size = (size / 1024);
		}

		final truncatedSize:Float = HelperFunctions.truncateFloat(size, 1);

		return '$truncatedSize ${intervalArray[data]}';
	}

	/**
	 * Method which outputs a formatted string displaying the current memory usage.
	 * @return String
	 */
	inline function get_memoryMegas():String
	{
		if (!FlxG.save.data.mem)
			return "";
		final memory:Float = MemoryUtil.getMemoryfromProcess();
		return 'Memory Usage : ${getInterval(memory)}';
	}

	inline function get_gcMemory():String
	{
		if (!FlxG.save.data.mem)
			return "";
		final memory:Float = MemoryUtil.getGCMem();
		return ' | GC : ${getInterval(memory)}';
	}
}
