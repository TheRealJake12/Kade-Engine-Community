package kec.states.editors;

import kec.objects.Note;

class ChartingBox extends FlxSprite
{
	public var connectedNote:Note;
	public var connectedNoteData:Array<Dynamic>;

	public function new(x, y, originalNote:Note)
	{
		super(x, y);
		connectedNote = originalNote;

		makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
		setGraphicSize(ChartingState.gridSize, ChartingState.gridSize);
		updateHitbox();
		alpha = 0.3;
	}
}
