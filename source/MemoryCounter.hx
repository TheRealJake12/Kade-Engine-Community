package;

import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.system.System;

class MemoryCounter extends TextField
{
	#if flash
	private var currentTime: Float;
	#end

	/**
		The current frame rate, expressed using frames-per-second
	**/
	public function new(x:Float = 100, y:Float = 10, color:Int = 0xFFFFFF)
	{
		super();

		this.x = x;
		this.y = y;

		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName, 14, color);
		text = memoryUsage();

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	// Event Handlers
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		text = memoryUsage();
	}

	private static function memoryUsage(): String
	{
		var usage: Float = System.totalMemory;
		var mag = " bytes";
		
		if (usage >= 1024 * 1024 * 1024)
		{
			usage /= 1024 * 1024 * 1024;
			mag = " GB";
		}
		else if (usage >= 1024 * 1024)
		{
			usage /= 1024 * 1024;
			mag = " MB";
		}
		else if (usage >= 1024)
		{
			usage /= 1024;
			mag = " KB";
		}
		
		usage = Math.ffloor(usage * 100) / 100;
		return Std.string(usage) + mag;
	}
}