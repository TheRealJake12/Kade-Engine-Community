package kec.objects;

import haxe.Timer;
import openfl.display.FPS;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import flixel.util.FlxColor;
import openfl.Lib;
import haxe.Int64;
import openfl.system.System;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end

class KadeEngineFPS extends TextField
{
	public var currentFPS(default, null):Int;

	private var times:Array<Float>;

	public var memoryMegas:Dynamic = 0;
	public var taskMemoryMegas:Dynamic = 0;
	public var memoryUsage:String = '';
	public var displayFPS:String;

	private var cacheCount:Int;

	public var bitmap:Bitmap;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000)
	{
		super();

		x = inX;

		y = inY;

		selectable = false;

		defaultTextFormat = new TextFormat('VCR OSD Mono', 14, inCol);

		text = "FPS: ";

		currentFPS = 0;

		cacheCount = 0;

		times = [];

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 340;

		height = 100;
	}

	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	var skippedFrames = 0;

	public static var currentColor = 0;

	private function onEnter(_)
	{
		if (FlxG.save.data.fpsRain)
		{
			if (currentColor >= array.length)
				currentColor = 0;
			currentColor = Math.round(FlxMath.lerp(0, array.length, skippedFrames / (FlxG.save.data.fpsCap / 3)));
			(cast(Lib.current.getChildAt(0), Main)).changeFPSColor(array[currentColor]);
			currentColor++;
			skippedFrames++;
			if (skippedFrames > (FlxG.save.data.fpsCap / 3))
				skippedFrames = 0;
		}

		var now = Timer.stamp();

		times.push(now);

		while (times[0] < now - 1)
			times.shift();

		var currentCount = times.length;
		var stateText:String = (FlxG.save.data.showState ? "Game State: " + Main.mainClassState : "");
		var lmao:String = (FlxG.save.data.fpsmark ? (Main.watermarks ? "\n" + MainMenuState.kecVer : "\n" + "Kade Engine 1.8.1") : "");
		displayFPS = (FlxG.save.data.fps ? "FPS: " + currentFPS : "");
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > FlxG.save.data.fpsCap)
			currentFPS = FlxG.save.data.fpsCap;

		if (visible)
		{
			memoryUsage = (FlxG.save.data.mem ? "Memory Usage: " : "");
			memoryMegas = Int64.make(0, System.totalMemory);

			taskMemoryMegas = Int64.make(0, kec.backend.util.MemoryUtil.getMemoryfromProcess());

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
				memoryMegas = flixel.util.FlxStringUtil.formatBytes(memoryMegas);
				memoryUsage += memoryMegas;
				// linux and other operating systems die when cpp code. Can't be 99.5% accurate like windows
				#end
			}

			text = ('${displayFPS}\n' + '$memoryUsage\n' + stateText + lmao);

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			if (FlxG.save.data.glDebug)
			{
				text += "\nItems Rendered: " + Context3DStats.totalDrawCalls();
				// text += "\nStage3D Draw Cells: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			}
			#end
		}

		cacheCount = currentCount;
	}
}
