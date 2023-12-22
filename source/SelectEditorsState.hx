package;

import flixel.FlxG;
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

		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			MainMenuState.freakyPlaying = true;
			Conductor.changeBPM(102, false);
		}

		bgSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
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
			var text:Alphabet = new Alphabet(0, 320 + (70 * i), editors[i], true);
			text.changeX = false;
			text.isMenuItem = true;
			text.targetY = i;
			text.snapToPosition();
			text.screenCenter(X);
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

		if (FlxG.mouse.wheel != 0)
		{
			#if desktop
			changeSelection(-FlxG.mouse.wheel);
			#else
			if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
				changeSelection(1);
			else if (FlxG.mouse.wheel > 0)
				changeSelection(-1);
			#end
		}	

		if (no)
		{
			MusicBeatState.switchState(new MainMenuState());
		}

		if (yes)
		{
			switch (editors[curSelected])
			{
				case 'Character Editor':
					debug.AnimationDebug.fromEditor = true;
					LoadingState.loadAndSwitchState(new debug.AnimationDebug());
				case 'Stage Editor':
					PlayState.SONG = Song.loadFromJson('test', '');
					debug.StageDebugState.fromEditor = true;
					LoadingState.loadAndSwitchState(new debug.StageDebugState('stage'));
				case 'Chart Editor':
					PlayState.SONG = Song.loadFromJson('test', '');
					PlayState.storyDifficulty = 1;
					PlayState.storyWeek = 0;
					PlayState.isStoryMode = false;
					PlayState.isSM = false;
					PlayState.songMultiplier = 1;
					LoadingState.loadAndSwitchState(new debug.ChartingState(true), true);
			}
			FlxG.sound.music.volume = 0;
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

		var bullShit:Int = 0;

		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}	
	}
}
