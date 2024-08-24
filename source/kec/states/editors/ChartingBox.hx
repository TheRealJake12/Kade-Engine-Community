package kec.states.editors;

import kec.objects.note.Note;
import kec.backend.chart.NoteData;

class ChartingBox extends FlxSprite
{
	public var connectedNote:Note;

	public function new(x, y)
	{
		super(x, y);
	}

	public function setupBox(x, y, cn:Note)
	{
		connectedNote = cn;
		this.x = x;
		this.y = y;
		visible = true;
		active = true;
		makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
		setGraphicSize(ChartingState.gridSize, ChartingState.gridSize);
		updateHitbox();
		alpha = 0.3;
	}

	override function kill()
	{
		super.kill();
		visible = false;
		active = false;
		connectedNote = null;
	}
}
