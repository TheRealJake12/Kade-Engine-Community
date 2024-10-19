package kec.substates.editors;

/**
 * Ripped Code From Pause and another mod of mine
 */
class CharacterEditorHelpText extends MusicBeatSubstate
{
	var text:FlxText = null;
	var bg:FlxSprite = null;

	public function new()
	{
		super();
		openCallback = refresh;
		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.scrollFactor.set();
		bg.screenCenter();
		bg.alpha = 0;

		text = new FlxText(0, 0, 0, "", 24);
		text.text = "Z/X - Change Current Frame\n
        W/S - Change Selected Animation\n
        LEFT/DOWN/UP/RIGHT - Change Offsets\n
        I/J/K/L - Move Camera\n
        Q/E - Zoom Camera\n
        SPACE - Play Animation\n
        BACK - Leave Editor\n
		ALT - Change Character To Drag\n
        F1 - Show Help Text (This)";
		text.setFormat(Paths.font('vcr.ttf'), 24, FlxColor.WHITE, CENTER, OUTLINE_FAST, FlxColor.BLACK);
		text.borderSize = 1;
		text.updateHitbox();
		text.scrollFactor.set();
		text.screenCenter();
		text.alpha = 0;
	}

	override function create()
	{
		super.create();
		add(bg);
		add(text);
		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.F1)
		{
			createTween(bg, {alpha: 0}, 1, {ease: FlxEase.cubeIn});
			createTween(text, {alpha: 0}, 1, {
				ease: FlxEase.cubeIn,
				onComplete: function(t)
				{
					close();
				}
			});
		}
	}

	private function refresh()
	{
		createTween(bg, {alpha: 0.8}, 0.4, {ease: FlxEase.cubeOut});
		createTween(text, {alpha: 1}, 0.4, {ease: FlxEase.cubeOut});
	}
}
