package kec.states.editors;

import kec.backend.chart.Section.SwagSection;

class SectionRender extends FlxSprite
{
	public var section:SwagSection;
	public var icon:FlxSprite;
	public var lastUpdated:Bool;

	public function new(x:Float, y:Float, GRID_SIZE:Int, ?Height:Int = 16)
	{
		super(x, y);

		makeGraphic(1, 1, FlxColor.fromRGB(35, 35, 35));
		scale.set(GRID_SIZE * 8, GRID_SIZE * Height);
		updateHitbox();
		antialiasing = false;
		moves = false;
	}

	override function update(elapsed)
	{
	}

	override function destroy()
	{
		section = null;
		icon = null;
		super.destroy();
	}
}
