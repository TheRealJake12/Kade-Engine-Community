package kec.objects.editor;

import flixel.addons.display.FlxBackdrop;
import kec.states.editors.ChartingState;

class EditorGrid extends FlxSpriteGroup
{
	public var grid:FlxBackdrop;

	public function new()
	{
		super(FlxG.width * 0.5 - ChartingState.gridSize * 4);
		var graphic = new FlxSprite().makeGraphic(Std.int(ChartingState.gridSize * 8), FlxG.height, FlxColor.fromRGB(0, 0, 0));
		grid = new FlxBackdrop(graphic.graphic, Y);
		grid.alpha = 0.75;
		add(grid);
		active = false;
	}
}
