package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class SelectEditorsState extends MusicBeatState
{
	var editors:Array<String> = ['Character Editor', 'Stage Editor', 'Chart Editor'];

	private var grpTexts:FlxTypedGroup<Alphabet>;

	private var curSelected = 0;

	private var bgColors:Array<String> = ['#314d7f', '#4e7093', '#70526e', '#594465'];
	
	private var colorRotation:Int = 1;

	public function new()
	{
		super();
	}

	var bgSprite:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		bgSprite = new FlxSprite(0, 0).loadGraphic(Paths.loadImage('menuDesat'));
		bgSprite.scrollFactor.set(1.0, 1.0);
		bgSprite.screenCenter();

		add(bgSprite);

		FlxTween.color(bgSprite, 2, bgSprite.color, FlxColor.fromString(bgColors[colorRotation]));

		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			FlxTween.color(bgSprite, 2, bgSprite.color, FlxColor.fromString(bgColors[colorRotation]));
			if (colorRotation < (bgColors.length - 1))
				colorRotation++;
			else
				colorRotation = 0;
		}, 0);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...editors.length)
		{
			var text:Alphabet = new Alphabet(0, (70 * i) + 30, editors[i], true, false);
			text.isMenuItem = true;
			text.targetY = i;
			grpTexts.add(text);
		}
		changeSelection();

		super.create();
		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		var yes = controls.ACCEPT;
		var no = controls.BACK;
		var up = FlxG.keys.justPressed.UP;
		var down = FlxG.keys.justPressed.DOWN;

		if (up)
			changeSelection(-1);
		if (down)
			changeSelection(1);

		if (no)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (yes)
		{
			switch (editors[curSelected])
			{
				case 'Character Editor':
					LoadingState.loadAndSwitchState(new debug.AnimationDebug());
				case 'Stage Editor':
					LoadingState.loadAndSwitchState(new debug.StageDebugState());
				case 'Chart Editor':
					LoadingState.loadAndSwitchState(new debug.ChartingState());
			}
			FlxG.sound.music.volume = 0;
		}

		var thing:Int = 0;
		for (item in grpTexts.members)
		{
			item.targetY = thing - curSelected;
			thing++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		super.update(elapsed);
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = editors.length - 1;
		if (curSelected >= editors.length)
			curSelected = 0;
	}
}
