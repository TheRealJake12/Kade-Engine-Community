package kec.objects;

import haxe.Timer;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxColor;
import haxe.Int64;
import openfl.system.System;
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

	public dynamic function updateText():Void
	{ // so people can override it in hscript
		final stateText:String = (FlxG.save.data.showState ? "Game State: " + Main.mainClassState : "");
		final watermark:String = (FlxG.save.data.fpsmark ? Constants.kecVer : "");
		var items:String = "";
		#if (gl_stats && !disable_cffi && (!html5 || !canvas))
		items = (FlxG.save.data.glDebug ? "Items Rendered: " + Context3DStats.totalDrawCalls() : "");
		#end
		text = 'FPS: ${currentFPS}' + '\n${memoryMegas}' + '\n$stateText' + '\n$items' + '\n$watermark';
	}

	inline function get_memoryMegas():String
	{
		var memoryUsage = (FlxG.save.data.mem ? "Memory Usage: " : "");
		var mem = Int64.make(0, System.totalMemory);

		var taskMemoryMegas = Int64.make(0, kec.backend.util.MemoryUtil.getMemoryfromProcess());

		if (FlxG.save.data.mem)
		{
			#if windows
			if (taskMemoryMegas >= 0x40000000)
				memoryUsage += (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 / 0x400 * 1000) / 1000) + " GB";
			else if (taskMemoryMegas >= 0x100000)
				memoryUsage += (Math.round(cast(taskMemoryMegas, Float) / 0x400 / 0x400 * 1000) / 1000) + " MB";
			else if (taskMemoryMegas >= 0x400)
				memoryUsage += (Math.round(cast(taskMemoryMegas, Float) / 0x400 * 1000) / 1000) + " KB";
			else
				memoryUsage += taskMemoryMegas + " B)";
			#else
			mem = flixel.util.FlxStringUtil.formatBytes(mem);
			memoryUsage += mem;
			// linux and other operating systems die when cpp code. Can't be 99.5% accurate like windows
			#end
		}

		return memoryUsage;
	}
}
