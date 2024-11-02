package kec.objects.editor;

class EditorSustain extends FlxSprite
{
	public function new()
	{
		super();
		moves = active = false;
		makeGraphic(1, 1);
	}

	public function setup(x:Float, y:Float, sizeX:Float, sizeY:Float)
	{
		setGraphicSize(sizeX, sizeY);
		updateHitbox();
		setPosition(x, y);
		visible = true;
	}

	override function kill()
	{
		visible = false;
		super.kill();
	}
}
