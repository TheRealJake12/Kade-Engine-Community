package kec.substates;

import kec.backend.Controls.Control;
import flixel.addons.transition.FlxTransitionableState;
import kec.objects.Alphabet;
import kec.backend.PlayStateChangeables;
import kec.backend.chart.Song;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	public static var goToOptions:Bool = false;
	public static var goBack:Bool = false;

	var tweenManager:FlxTweenManager = null;

	var pauseOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices = [];

	var menuItems:Array<String> = [];

	var curSelected:Int = 0;

	public static var playingPause:Bool = false;

	var pauseMusic:FlxSound;
	var bg:FlxSprite;
	var levelDifficulty:FlxText;

	var levelInfo:FlxText;

	public function new()
	{
		Paths.clearUnusedMemory();
		super();

		openCallback = refresh;

		tweenManager = new FlxTweenManager();

		if (CoolUtil.difficultyArray.length < 2)
			pauseOG.remove('Change Difficulty'); // No need to change difficulty if there is only one!

		menuItems = pauseOG;

		for (i in 0...CoolUtil.difficultyArray.length)
		{
			var diff:String = '' + CoolUtil.difficultyArray[i];
			difficultyChoices.push(diff);
		}
		difficultyChoices.push('BACK');

		bg = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		bg.scale.set(FlxG.width, FlxG.height);
		bg.updateHitbox();
		bg.alpha = 0;
		bg.scrollFactor.set();

		levelInfo = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.songName.toUpperCase();
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();

		levelDifficulty = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyFromInt(PlayState.storyDifficulty).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		regenMenu();
	}

	override public function create()
	{
		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		add(bg);

		add(levelInfo);

		add(levelDifficulty);

		add(grpMenuShit);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

		add(grpMenuShit);

		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
		super.create();
	}

	#if !mobile
	var oldPos = FlxG.mouse.getScreenPosition();
	#end

	override function update(elapsed:Float)
	{
		tweenManager.update(elapsed);

		super.update(elapsed);

		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		#if !mobile
		if (FlxG.mouse.wheel != 0)
			#if desktop
			changeSelection(-FlxG.mouse.wheel);
			#else
			if (FlxG.mouse.wheel < 0)
				changeSelection(1);
			if (FlxG.mouse.wheel > 0)
				changeSelection(-1);
			#end
		#end

		if (bg.alpha > 0.6)
			bg.alpha = 0.6;

		if (controls.UP_P)
		{
			changeSelection(-1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}
		else if (controls.DOWN_P)
		{
			changeSelection(1);
			FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
		}

		if ((controls.ACCEPT && !FlxG.keys.pressed.ALT) || FlxG.mouse.pressed)
		{
			var daSelected:String = menuItems[curSelected];

			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					PlayState.storyDifficulty = curSelected;
					PlayState.SONG = Song.loadFromJson(PlayState.SONG.songId.toLowerCase(),
						CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[PlayState.storyDifficulty]));
					PlayState.startTime = 0;
					MusicBeatState.resetState();
					return;
				}

				menuItems = pauseOG;
				regenMenu();
			}

			pauseMusic.pause();

			switch (daSelected)
			{
				case "Resume":
					close();
					if (!PlayState.instance.speedChanged)
						PlayState.instance.scrollSpeed = (FlxG.save.data.scrollSpeed == 1 ? PlayState.SONG.speed : FlxG.save.data.scrollSpeed) * PlayState.instance.scrollMult;
					PlayStateChangeables.botPlay = FlxG.save.data.botplay;

				case "Restart Song":
					PlayState.startTime = 0;
					FlxTransitionableState.skipNextTransOut = true;
					MusicBeatState.resetState();
				case 'Change Difficulty':
					menuItems = difficultyChoices;
					regenMenu();
				case "Options":
					goToOptions = true;
					close();
				case "BACK":
					menuItems = pauseOG;
					regenMenu();
				case "Exit to menu":
					PlayState.startTime = 0;
					PlayState.stageTesting = false;
					PlayState.inDaPlay = false;
					#if FEATURE_LUAMODCHART
					if (PlayState.luaModchart != null)
					{
						PlayState.luaModchart.die();
						PlayState.luaModchart = null;
					}
					#end

					if (PlayState.isStoryMode)
					{
						GameplayCustomizeState.freeplayNoteStyle = 'normal';
						MusicBeatState.switchState(new StoryMenuState());
					}
					else
					{
						MusicBeatState.switchState(new FreeplayState());
					}
			}
		}
	}

	override function destroy()
	{
		tweenManager.clear();
		tweenManager.destroy();
		pauseMusic.destroy();

		super.destroy();
	}

	override function close()
	{
		tweenManager.clear();
		pauseMusic.pause();

		super.close();
	}

	private function regenMenu():Void
	{
		while (grpMenuShit.members.length > 0)
		{
			grpMenuShit.remove(grpMenuShit.members[0], true);
		}

		for (i in 0...menuItems.length)
		{
			var songText = new Alphabet(90, 320, menuItems[i], true);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		curSelected = 0;
		changeSelection();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
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

	private function refresh()
	{
		for (i in 0...grpMenuShit.length - 1)
		{
			grpMenuShit.members[i].y = (70 * i) + 30;
		}

		pauseMusic.volume = 0;
		pauseMusic.play();

		levelInfo.y = 15;
		levelDifficulty.y = 15 + 32;

		bg.alpha = 0;
		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		tweenManager.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		tweenManager.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		tweenManager.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		changeSelection();
	}
}
