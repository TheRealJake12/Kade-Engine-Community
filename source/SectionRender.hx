import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import Section.SwagSection;
import flixel.addons.display.FlxGridOverlay;
import flixel.FlxSprite;

class SectionRender extends FlxSprite
{
	public var section:SwagSection;
	public var icon:FlxSprite;
	public var lastUpdated:Bool;

	public function new(x:Float, y:Float, GRID_SIZE:Int, ?Height:Int = 16)
	{
		super(x, y);

		makeGraphic(1, 1, 0xFF2F2F2F);
		scale.set(GRID_SIZE * 8, GRID_SIZE * Height);
		updateHitbox();
		antialiasing = false;
	}

	override function update(elapsed)
	{
	}
}
