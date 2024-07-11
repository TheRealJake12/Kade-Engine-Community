package kec.states;

import lime.app.Application;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
#if FEATURE_DISCORD
import kec.backend.Discord;
#end
import openfl.Assets;
import flixel.group.FlxGroup;
#if cpp
import cpp.vm.Gc;
#end
import kec.objects.Alphabet;

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var wackyImage:FlxSprite;

	var trackedAssets:Array<FlxBasic> = [];

	override public function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if cpp
		Gc.run(true);
		Gc.compact();
		Gc.run(false);
		Gc.enable(true);
		#end

		Main.mainClassState = TitleState;

		Main.gameContainer.checkInternetConnection();

		#if FEATURE_DISCORD
		if (Main.gameContainer.hasWifi)
		{
			Discord.load();
		}
		#end

		curWacky = FlxG.random.getObject(getIntroTextShit());
		if (FlxG.save.data.gen)
			Debug.logInfo('Hello.');

		super.create();

		FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 0.5, FlxPoint.weak(0, -1), NEW);
		FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.4, FlxPoint.weak(0, 1), NEW);

		#if !cpp
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
		#else
		startIntro();
		#end
	}

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	function startIntro()
	{
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		logoBl = new FlxSprite(-150, -1000);
		if (Main.watermarks)
		{
			logoBl.frames = Paths.getSparrowAtlas('KECLogoOrange');
			logoBl.x += 125;
			logoBl.scale.set(1.2, 1.2);
		}
		else
		{
			logoBl.frames = Paths.getSparrowAtlas('KadeEngineLogoBumpin');
		}
		logoBl.antialiasing = FlxG.save.data.antialiasing;
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logoBl.updateHitbox();

		gfDance = new FlxSprite(1000, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = FlxG.save.data.antialiasing;
		add(gfDance);
		add(logoBl);

		titleText = new FlxSprite(100, FlxG.height * 0.8);
		titleText.frames = Paths.getSparrowAtlas('titleEnter');
		titleText.animation.addByPrefix('idle', "ENTER IDLE0", 24);
		titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		titleText.antialiasing = FlxG.save.data.antialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);
		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		credTextShit.visible = false;

		ngSpr = new FlxSprite(0, FlxG.height * 0.52).loadGraphic(Paths.image('credshit/meredo'));
		add(ngSpr);
		ngSpr.alpha = 0;
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.scale.set(0.6, 0.6);
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = FlxG.save.data.antialiasing;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		if (initialized)
			new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				skipIntro();
			});
		else
		{
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(102);
			initialized = true;
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('data/introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		var pressedEnter:Bool = controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		super.update(elapsed);

		if (pressedEnter && !transitioning && skippedIntro || FlxG.mouse.justPressed && !transitioning && skippedIntro)
		{
			if (FlxG.save.data.flashing)
			{
				titleText.animation.play('press');
				FlxG.camera.flash(FlxColor.WHITE, 1);
			}

			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				if (Main.gameContainer.hasWifi && !FlxG.save.data.developer)
				{
					var http = new haxe.Http("https://raw.githubusercontent.com/TheRealJake12/Kade-Engine-Community/master/version.downloadMe");
					var returnedData:Array<String> = [];

					http.onData = function(data:String)
					{
						returnedData[0] = data.substring(0, data.indexOf(';'));
						Debug.logTrace('Github Version : ' + returnedData[0]);
						returnedData[1] = data.substring(data.indexOf('-'), data.length);
						if (!MainMenuState.kecVer.contains(returnedData[0].trim()) && !OutdatedSubState.leftState)
						{
							if (!MainMenuState.kecVer.contains("PRE-RELEASE"))
								Debug.logTrace('The Latest Github Version Is ' + returnedData[0] + ' While Your Version Is ' + MainMenuState.kecVer);
							else
								Debug.logTrace('You Are On A Pre-Release Build. Report Any Bugs You Encounter. Version : ${MainMenuState.kecVer}');
							OutdatedSubState.needVer = returnedData[0];
							OutdatedSubState.currChanges = returnedData[1];
							MusicBeatState.switchState(new OutdatedSubState());
						}
						else
						{
							MusicBeatState.switchState(new MainMenuState());
						}
					}

					http.onError = function(error)
					{
						Debug.logTrace('Error: $error');
						new FlxTimer().start(2, function(tmr:FlxTimer)
						{
							{
								MusicBeatState.switchState(new MainMenuState());
							}
						});
					}

					http.request();
				}
				else
				{
					MusicBeatState.switchState(new MainMenuState());
				}
			});
		}

		if (pressedEnter && !skippedIntro && initialized || FlxG.mouse.justPressed && !skippedIntro && initialized)
		{
			skipIntro();
		}
	}

	function createCoolText(textArray:Array<String>, ?offset:Float = 0)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true);
			money.screenCenter(X);
			money.y += (i * 60) + 200 + offset;
			if (credGroup != null && textGroup != null)
			{
				money.alpha = 0;
				credGroup.add(money);
				textGroup.add(money);
				for (object in money.members)
				{
					var flxSprite:FlxSprite = cast object;
					FlxTween.tween(flxSprite, {alpha: 1}, .5, {ease: FlxEase.quadOut});
				}
			}
		}
	}

	function addMoreText(text:String, ?offset:Float = 0)
	{
		if (textGroup != null && credGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200 + offset;
			coolText.alpha = 0;
			credGroup.add(coolText);
			textGroup.add(coolText);
			for (object in coolText.members)
			{
				var flxSprite:FlxSprite = cast object;
				FlxTween.tween(flxSprite, {alpha: 1}, .5, {ease: FlxEase.quadOut});
			}
		}
	}

	function deleteCoolText()
	{
		for (object in textGroup.members)
		{
			var flxSprite:FlxSprite = cast object;
			FlxTween.tween(flxSprite, {alpha: 0}, .5, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					credGroup.remove(textGroup.members[0], true);
					textGroup.remove(textGroup.members[0], true);
				}
			});
		}
	}

	override function beatHit()
	{
		super.beatHit();

		logoBl.animation.play('bump', true);
		danceLeft = !danceLeft;

		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');

		switch (curBeat)
		{
			case 0:
				deleteCoolText();
			case 1:
				createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			case 3:
				addMoreText('present');
			case 4:
				deleteCoolText();
			case 5:
				if (Main.watermarks)
					createCoolText(['KE Community', 'by']);
				else
					createCoolText(['KE Community', 'by']);
			case 7:
				{
					addMoreText('TheRealJake_12');
					FlxTween.tween(ngSpr, {alpha: 1}, .2, {ease: FlxEase.quadOut});
				}
			case 8:
				deleteCoolText();
				FlxTween.tween(ngSpr, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
			case 9:
				createCoolText([curWacky[0]]);
			case 11:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				addMoreText('Friday');
			case 14:
				addMoreText('Night');
			case 15:
				addMoreText('Funkin');

			case 16:
				skipIntro();
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			if (FlxG.save.data.gen)
				Debug.logInfo("Skipping intro...");

			remove(ngSpr);

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);
			if (!Main.watermarks)
				FlxTween.tween(logoBl, {y: -100}, 1.4, {ease: FlxEase.expoInOut});
			else
				FlxTween.tween(logoBl, {y: -30}, 1.4, {ease: FlxEase.expoInOut});
			FlxTween.tween(gfDance, {x: FlxG.width * 0.4}, 1.4, {ease: FlxEase.expoInOut});

			logoBl.angle = -4;

			new FlxTimer().start(0.01, function(tmr:FlxTimer)
			{
				if (logoBl.angle == -4)
					FlxTween.angle(logoBl, logoBl.angle, 4, 4, {ease: FlxEase.quartInOut});
				if (logoBl.angle == 4)
					FlxTween.angle(logoBl, logoBl.angle, -4, 4, {ease: FlxEase.quartInOut});
			}, 0);

			FlxG.sound.music.time = 9400; // 9.4 seconds

			skippedIntro = true;
		}
	}
}
