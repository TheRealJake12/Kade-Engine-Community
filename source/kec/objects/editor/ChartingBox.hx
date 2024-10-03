package kec.objects.editor;

import kec.objects.editor.EditorNote;
import kec.states.editors.ChartingState;

class ChartingBox extends FlxSprite
{
	public var connectedNote:EditorNote;

	public function new(x, y)
	{
		super(x, y);
	}

	public function setupBox(x, y, cn:EditorNote)
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
