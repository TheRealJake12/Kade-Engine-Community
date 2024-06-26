package kec.objects;

import kec.backend.Ratings;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.text.TextFieldAutoSize;
import flixel.system.FlxAssets;
import openfl.text.TextFormat;
import flash.display.Graphics;
import flash.display.Shape;
import openfl.display.Sprite;
import flash.text.TextField;
import flash.text.TextFormatAlign;

typedef HitNote =
{
	var diff:Float;
	var rating:RatingWindow;
	var strumTime:Float;
}

class HitGraph extends Sprite
{
	public var history:Array<HitNote> = [];

	public var _width:Float = 0;

	public var _height:Float = 0;

	public var _rectHeight:Float = 0;

	public var xPos:Float = 0;

	public var yPos:Float = 0;

	var earlyText:TextField;

	var lateText:TextField;

	public function new(x:Float, y:Float, width:Float, height:Float)
	{
		super();
		_width = width;
		_height = height;
		_rectHeight = height + (height / 3);
		xPos = x;
		yPos = y;

		graphics.clear();

		drawContents();
	}

	private function drawContents():Void
	{
		drawRectBackground();
		setupText();
		drawGraph();
	}

	private function drawRectBackground()
	{
		graphics.lineStyle(1, FlxColor.BLACK.to24Bit(), 0);
		graphics.beginFill(FlxColor.BLACK.to24Bit(), 0.6);
		graphics.drawRect(0, 0, _width, _rectHeight);
		graphics.endFill();
	}

	private function drawJudgeLine(ms:Float, color:FlxColor)
	{
		var y_position = FlxMath.remapToRange((_height / 2) + ms, (_height / 2), (_height / 2) + Ratings.timingWindows[0].timingWindow, _height / 2, _height)
			+ ((_rectHeight - _height) / 2);

		var daColor = color.to24Bit();
		graphics.lineStyle(1, daColor, 0);
		graphics.beginFill(daColor, 0.4);

		graphics.drawRect(0, y_position - (1.5 / 2), _width, 1.5);
		graphics.endFill();
	}

	private function setupText()
	{
		lateText = createTextField(7, 7, FlxColor.WHITE, 12);
		earlyText = createTextField(7, _rectHeight - 21, FlxColor.WHITE, 12);

		earlyText.text = "Early (" + -Ratings.timingWindows[0].timingWindow + "ms)";
		lateText.text = "Late (" + Ratings.timingWindows[0].timingWindow + "ms)";

		addChild(earlyText);
		addChild(lateText);
	}

	private function drawGraph()
	{
		// MID LINE
		drawJudgeLine(0, 0xFFFFFF);

		var posVals = Ratings.timingWindows.copy();

		for (i in 0...(posVals.length * 2))
		{
			var id = i;
			if (id >= posVals.length)
				id -= posVals.length;
			var color = posVals[id].displayColor;
			var ms = posVals[id].timingWindow;

			if (i >= posVals.length)
				ms = -ms;

			drawJudgeLine(ms, color);
		}
	}

	private function drawHitNotes()
	{
		for (i in 0...history.length)
		{
			var x_position = (history[i].strumTime / (PlayState.inst.length / PlayState.songMultiplier)) * (_width);
			var y_position = FlxMath.remapToRange((_height / 2) + history[i].diff, (_height / 2), (_height / 2) + Ratings.timingWindows[0].timingWindow,
				_height / 2, _height)
				+ ((_rectHeight - _height) / 2);

			graphics.beginFill(history[i].rating.displayColor.to24Bit());
			graphics.drawRect(x_position - 2, y_position - 2, 4, 4);
			graphics.endFill();
		}
	}

	public function update()
	{
		drawHitNotes();
	}

	public function addToHistory(noteDiff:Float, noteRating:RatingWindow, noteStrum:Float)
	{
		history.push({diff: noteDiff, rating: noteRating, strumTime: noteStrum});
	}

	public function destroy()
	{
		FlxDestroyUtil.removeChild(this, earlyText);
		FlxDestroyUtil.removeChild(this, lateText);
		history.resize(0);
		history = null;
	}

	public static function createTextField(X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):TextField
	{
		return initTextField(new TextField(), X, Y, Color, Size);
	}

	public static function initTextField<T:TextField>(tf:T, X:Float = 0, Y:Float = 0, Color:FlxColor = FlxColor.WHITE, Size:Int = 12):T
	{
		tf.x = X;
		tf.y = Y;
		tf.multiline = false;
		tf.wordWrap = false;
		tf.embedFonts = true;
		tf.selectable = false;
		#if flash
		tf.antiAliasType = AntiAliasType.NORMAL;
		tf.gridFitType = GridFitType.PIXEL;
		#end
		tf.defaultTextFormat = new TextFormat("assets/fonts/vcr.ttf", Size, Color.to24Bit());
		tf.alpha = Color.alphaFloat;
		tf.autoSize = TextFieldAutoSize.LEFT;
		return tf;
	}
}
