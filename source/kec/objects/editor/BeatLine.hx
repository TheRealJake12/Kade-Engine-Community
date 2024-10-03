package kec.objects.editor;

import kec.states.editors.ChartingState;

class BeatLine extends FlxSprite
{
	public function new()
	{
		super();
		makeGraphic(1, 1, FlxColor.WHITE);
		scale.set(Std.int(ChartingState.gridSize * 8), 4);
		updateHitbox();
		moves = active = false;
	}

	public function setup(x:Float, y:Float, color:FlxColor)
	{
		this.color = color;
		setPosition(x, y);
	}
}
