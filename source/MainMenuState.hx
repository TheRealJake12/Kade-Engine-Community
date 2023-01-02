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
import ModCore;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var nightly:String = "";
	public static var kecVer:String = 'Kade Engine Community 1.7';
	public static var keVer:String = "Kade Engine 1.8.1";
	public static var curSelected:Int = 0;
	public static var freakyPlaying:Bool;

	var menuItems:FlxTypedGroup<FlxSprite>;
	private var camGame:FlxCamera;

	#if !switch
	var optionShit:Array<String> = ['story mode', 'freeplay', 'donate', 'options'];
	#else
	var optionShit:Array<String> = ['story mode', 'freeplay'];
	#end

	var magenta:FlxSprite;
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

		ModCore.initialize();

		FlxG.mouse.visible = true;

		Application.current.window.title = '${MainMenuState.kecVer} : In the Menus';

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			freakyPlaying = true;
		}

		camGame = new FlxCamera();

		FlxG.cameras.reset(camGame);
		FlxCamera.defaultCameras = [camGame];

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);
		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image2('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image2('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = FlxG.save.data.antialiasing;
		magenta.color = 0xFFfd719b;
		//add(magenta);

		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var tex = Paths.getSparrowAtlas('FNF_main_menu_assets');

		var scale:Float = 1;

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			menuItem.frames = tex;
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			menuItem.scrollFactor.set(0, 0.25);
			menuItem.antialiasing = FlxG.save.data.antialiasing;

			changeItem();
			menuItem.x = 120 + (i * 160);
		}
		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(5, FlxG.height - 18, 0, keVer + (Main.watermarks ? " " + kecVer + "" : ""), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(versionShit);

		if (FlxG.save.data.dfjk)
			controls.setKeyboardScheme(KeyboardScheme.Solo, true);
		else
			controls.setKeyboardScheme(KeyboardScheme.Duo(true), true);

		changeItem(0, false);

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
				changeItem(-1, true);
			}

			if (FlxG.keys.justPressed.DOWN || controls.DOWN_P)
			{
				changeItem(1, true);
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
						changeItem();
					}
				});
			} 

			if (FlxG.mouse.wheel != 0)
			{
				changeItem(-shiftMult * FlxG.mouse.wheel, true);
			}
			#end


			#if debug
			if (FlxG.keys.justPressed.SEVEN)
			{
				MusicBeatState.switchState(new SelectEditorsState());
			}
			#end

			if (FlxG.mouse.overlaps(menuItems, FlxG.camera) && FlxG.mouse.justPressed || controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					fancyOpenURL("https://ninja-muffin24.itch.io/funkin");
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

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
					// transIn = FlxTransitionableState.defaultTransIn;
					// transOut = FlxTransitionableState.defaultTransOut;
					MusicBeatState.switchState(new OptionsDirect());
			}
		}
	}

	function changeItem(huh:Int = 0, ?sound:Bool = false)
	{
		curSelected += huh;

		if (sound = true)
			FlxG.sound.play(Paths.sound('scrollMenu'));

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
}