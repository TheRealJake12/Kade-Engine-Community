package kec.states.editors;

import flixel.addons.display.FlxBackdrop;
import openfl.display.BitmapData;
import flixel.addons.display.FlxGridOverlay;

using kec.states.editors.MakeRect;

/**
 * Heavily Insprired By sword_352's chart editor.
 * Can't even say heavily inspired, it's all his code lol.
 */
class EditorArea extends FlxSpriteGroup
{
	public var playerSide:FlxBackdrop;
	public var opponentSide:FlxBackdrop;
	public final colorOne = 0xFF2F2F2F;
	public final colorTwo = 0xFF525252;
	public var bottom(default, set):Float = 0;

	public function new():Void
	{
		super(FlxG.width * 0.5 - ChartingState.gridSize * 4);

		var grid:BitmapData = createGrid(colorOne, colorTwo);
		opponentSide = new FlxBackdrop(grid, Y);
		add(opponentSide);

		playerSide = new FlxBackdrop(grid, Y);
		playerSide.x = playerSide.width + ChartingState.separatorWidth;
		add(playerSide);

		// editorWalls walls
		for (i in 0...3)
		{
			var separator:FlxSprite = new FlxSprite(x + ChartingState.gridSize * 4 * i);
			separator.makeRect(ChartingState.separatorWidth, FlxG.height, FlxColor.BLACK, false, "fard");
			separator.x += separator.width * (i - 2);
			separator.x = Math.floor(separator.x); // avoids weird width
			separator.scrollFactor.set();
			group.add(separator);
		}

		active = false;
	}

	override function get_width():Float
	{
		return playerSide.width + opponentSide.width + ChartingState.separatorWidth;
	}

	function set_bottom(v:Float):Float
	{
		return bottom = v;
	}

	private inline function createGrid(c1:Int, c2:Int):BitmapData
	{
		return FlxGridOverlay.createGrid(ChartingState.gridSize, ChartingState.gridSize, ChartingState.gridSize * 4, ChartingState.gridSize * 2, true, c1, c2);
	}
}
