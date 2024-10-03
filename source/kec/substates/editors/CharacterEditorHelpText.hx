package kec.substates.editors;

/**
 * Ripped Code From Pause and another mod of mine
 */
class CharacterEditorHelpText extends MusicBeatSubstate
{
	var tweenManager:FlxTweenManager = null;
	var text:FlxText = null;
	var bg:FlxSprite = null;

	public function new()
	{
		super();
		openCallback = refresh;
		tweenManager = new FlxTweenManager();
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
		tweenManager.update(elapsed);
		super.update(elapsed);

		if (FlxG.keys.justPressed.F1)
		{
			tweenManager.tween(bg, {alpha: 0}, 1, {ease: FlxEase.cubeIn});
			tweenManager.tween(text, {alpha: 0}, 1, {
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
		tweenManager.tween(bg, {alpha: 0.8}, 0.4, {ease: FlxEase.cubeOut});
		tweenManager.tween(text, {alpha: 1}, 0.4, {ease: FlxEase.cubeOut});
	}
}
