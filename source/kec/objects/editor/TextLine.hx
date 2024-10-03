package kec.objects.editor;

class TextLine extends FlxText
{
	public function reuse(x:Float, y:Float, size:Int)
	{
		setPosition(x, y);
		text = '';
		updateHitbox();
		setFormat(Paths.font('vcr.ttf'), size, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		borderSize = 2;
		borderQuality = 1;
		active = false;
		visible = true;
	}

	override function kill()
	{
		super.kill();
		text = '';
		visible = false;
	}
}
