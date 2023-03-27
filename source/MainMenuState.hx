package;

import Controls.KeyboardScheme;
import flixel.util.FlxTimer;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;
import flixel.addons.display.FlxBackdrop;
#if FEATURE_MODCORE
import ModCore;
#end

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var nightly:String = "";
	public static var kecVer:String = "Funkin' In The Alley DEMO";
	public static var keVer:String = "Kade Engine 1.8.1";
	public static var curSelected:Int = 0;
	public static var freakyPlaying:Bool;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var colorArray:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 200),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(200, 160, 0),
		FlxColor.fromRGB(200, 127, 0),
		FlxColor.fromRGB(160, 0, 0)
	];

	public static var textArray:Array<String> = [
		"500+  Giftcards! (-KookerFoxYT)",
		"bro became starfire from teen titans go (-Monomouse)",
		"YOUR ARGUMENT, IS NOW INVALID! (-Monomouse)",
		"south park refernc!!!11 (-Maicon)",
		"JHJJTLKGFD WHY IS MILKY SO LOUD IN THE EXPORT (-CHS)",
		#if web
		"You're on web. Why the FUCK are you on web. You can't get even decent easter eggs, bitch."
		#end
	];

	public var logo:FlxSprite;

	public static var myBalls:FlxText;

	private var camGame:SwagCamera;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'discord', 'options'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#end

	var magenta:FlxBackdrop;
	var bg:FlxBackdrop;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		Conductor.changeBPM(102, false);

		#if FEATURE_MODCORE
		if (FlxG.save.data.loadMods)
			ModCore.initialize();
		#end

		FlxG.mouse.visible = true;

		Application.current.window.title = '${MainMenuState.kecVer} : In the Menus';

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			freakyPlaying = true;
		}
		Conductor.changeBPM(102);

		if (!FlxG.save.data.watermark)
			optionShit.remove('discord');
		camGame = new SwagCamera();

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		bg = new FlxBackdrop(Paths.image('menuDesat'), X, 0, 0);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		FlxG.cameras.reset(new SwagCamera());
		FlxG.camera.follow(camFollow, null, 0.06);

		magenta = new FlxBackdrop(Paths.image('menuDesat'), X, 0, 0);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = FlxG.save.data.antialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, 0);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0, 0.25);
			menuItem.antialiasing = FlxG.save.data.antialiasing;

			switch (i)
			{
				case 0:
					menuItem.setPosition(130, 50);
				case 1:
					menuItem.setPosition(300, 185);
				case 2:
					menuItem.setPosition(190, 320);
				case 3:
					menuItem.setPosition(420, 440);
				case 4:
					menuItem.setPosition(600, 570);
			}
		}

		logo = new FlxSprite(900, 0);
		logo.frames = Paths.getSparrowAtlas("KadeEngineLogoBumpin");
		logo.x = 800;
		logo.y = -60;
		logo.scale.set(0.55, 0.55);
		logo.animation.addByPrefix("bump", "logo bumpin", 24);
		logo.antialiasing = FlxG.save.data.antialiasing;
		logo.updateHitbox();

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, 'Alley Engine | Funkin In The Alley', 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(versionShit);

		myBalls = new FlxText(3, FlxG.height - 35, 0, textArray[FlxG.random.int(0, textArray.length - 1)], 12);
		myBalls.scrollFactor.set();
		myBalls.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(myBalls);
		add(logo);

		changeItem();

		controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);

		tweenColorShit();

		super.create();
		Paths.clearUnusedMemory();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.save.data.borderless)
		{
			FlxG.stage.window.borderless = true;
		}
		else
		{
			FlxG.stage.window.borderless = false;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (FlxG.keys.justPressed.UP || controls.UP_P)
			{
				changeItem(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (FlxG.keys.justPressed.DOWN || controls.DOWN_P)
			{
				changeItem(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}

			if (controls.BACK || FlxG.mouse.justPressedRight)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (FlxG.keys.justPressed.F7)
			{
				PlayState.SONG = Song.loadFromJson('salvation', '-hard');
				PlayState.isStoryMode = false;
				LoadingState.loadAndSwitchState(new PlayState());
			}

			var shiftMult:Int = 1;

			#if !mobile
			if (FlxG.mouse.overlaps(menuItems, FlxG.camera))
			{
				menuItems.forEach(function(daSprite:FlxSprite)
				{
					if (FlxG.mouse.overlaps(daSprite) && curSelected != daSprite.ID)
					{
						curSelected = daSprite.ID;
						FlxG.sound.play(Paths.sound('scrollMenu'));
						changeItem();
					}
				});
			}

			if (FlxG.mouse.wheel != 0)
			{
				changeItem(-shiftMult * FlxG.mouse.wheel);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			#end

			if (FlxG.keys.justPressed.SEVEN)
			{
				MusicBeatState.switchState(new SelectEditorsState());
			}

			bg.x += 2;
			magenta.x += 2;

			if (FlxG.mouse.overlaps(menuItems, FlxG.camera) && FlxG.mouse.justPressed || controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'discord')
				{
					fancyOpenURL("https://discord.gg/TKCzG5rVGf");
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					if (FlxG.save.data.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {alpha: 0}, 1.3, {
								ease: FlxEase.quadOut,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							if (FlxG.save.data.flashing)
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									goToState();
								});
							}
							else
							{
								new FlxTimer().start(1, function(tmr:FlxTimer)
								{
									goToState();
								});
							}
						}
					});
				}
			}
		}

		super.update(elapsed);
	}

	function goToState()
	{
		var daChoice:String = optionShit[curSelected];
		{
			switch (daChoice)
			{
				case 'story mode':
					MusicBeatState.switchState(new StoryMenuState());
				case 'freeplay':
					MusicBeatState.switchState(new FreeplayState());
				case 'options':
					transIn = FlxTransitionableState.defaultTransIn;
					transOut = FlxTransitionableState.defaultTransOut;
					MusicBeatState.switchState(new OptionsDirect());
			}
		}
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if (menuItems.length > 4)
				{
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
			}
		});
	}

	override function beatHit()
	{
		super.beatHit();

		logo.animation.play('bump', true);
	}

	function tweenColorShit()
	{
		var beforeInt = FlxG.random.int(0, 6);
		var randomInt = FlxG.random.int(0, 6);

		FlxTween.color(bg, 4, bg.color, colorArray[beforeInt], {
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
