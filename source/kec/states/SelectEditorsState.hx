package kec.states;

import kec.objects.Alphabet;
import kec.objects.CoolText;
import kec.objects.ui.HealthIcon;
import kec.backend.chart.Song;

class SelectEditorsState extends MusicBeatState
{
	var editors:Array<String> = ['Stage Editor', 'Chart Editor'];
	var icons = ['tankman', 'sm'];

	private var grpTexts:FlxTypedGroup<Alphabet>;

	private var curSelected = 0;
	private var iconArray:Array<HealthIcon> = [];

	var back:FlxSprite;
	var info:CoolText;

	var colorArray:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 200),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(200, 160, 0),
		FlxColor.fromRGB(200, 127, 0),
		FlxColor.fromRGB(160, 0, 0)
	];

	public static var icon:HealthIcon;

	public function new()
	{
		super();
	}

	var bgSprite:FlxSprite;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		FlxG.mouse.visible = true;

		if (MainMenuState.freakyPlaying)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			MainMenuState.freakyPlaying = true;
			Conductor.changeBPM(102);
		}

		bgSprite = new FlxSprite(0, 0).loadGraphic(Paths.image('menuDesat'));
		bgSprite.scrollFactor.set(1.0, 1.0);
		bgSprite.screenCenter();
		add(bgSprite);

		back = new FlxSprite(0, 700).makeGraphic(1, 1, FlxColor.BLACK);
		back.setGraphicSize(FlxG.width, 50);
		back.screenCenter(X);
		back.alpha = 0.6;
		add(back);

		info = new CoolText(225, 680, 32, 32, Paths.bitmapFont('fonts/vcr'));
		info.autoSize = true;
		info.text = "huh";
		info.antialiasing = FlxG.save.data.antialiasing;
		info.updateHitbox();
		info.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		info.borderSize = 2;
		add(info);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		for (i in 0...editors.length)
		{
			var text:Alphabet = new Alphabet(0, 280 + (70 * i), editors[i], true);
			text.changeX = false;
			text.isMenuItem = true;
			text.targetY = i;
			text.snapToPosition();
			text.screenCenter(X);
			grpTexts.add(text);

			icon = new HealthIcon(icons[i]);
			icon.sprTracker = text;
			iconArray.push(icon);
			add(icon);
		}
		changeSelection();

		tweenColorShit();

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
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if (yes)
		{
			goToEditor();
		}

		super.update(elapsed);
	}

	function goToEditor()
	{
		switch (editors[curSelected])
		{
			case 'Stage Editor':
				PlayState.SONG = Song.loadFromJson('test', '');
				kec.states.editors.StageDebugState.fromEditor = true;
				LoadingState.loadAndSwitchState(new kec.states.editors.StageDebugState('stage'));
			case 'Chart Editor':
				PlayState.SONG = Song.loadFromJson('test', '');
				PlayState.storyDifficulty = 1;
				PlayState.storyWeek = 0;
				PlayState.isStoryMode = false;
				PlayState.isSM = false;
				PlayState.songMultiplier = 1;
				LoadingState.loadAndSwitchState(new kec.states.editors.ChartingState(), true);
		}
		FlxG.sound.music.stop();
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

		switch (curSelected)
		{
			case 0:
				info.text = "Stage Editor, Move The Positions Of Stage Assets.";
			case 1:
				info.text = "Chart Editor, Place Notes And Create Charts.";
		}
		info.updateHitbox();

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

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

	function tweenColorShit()
	{
		var beforeInt = FlxG.random.int(0, 6);
		var randomInt = FlxG.random.int(0, 6);

		FlxTween.color(bgSprite, 4, bgSprite.color, colorArray[beforeInt], {
			onComplete: function(twn)
			{
				if (beforeInt != randomInt)
					beforeInt = randomInt;

				tweenColorShit();
			}
		});
		// thanks bolo lmao
	}
}
