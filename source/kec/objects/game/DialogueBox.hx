package kec.objects.game;

import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.input.FlxKeyManager;
import kec.backend.PlayerSettings;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';

	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;
	var skipText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;
	var face:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;

	var sound:FlxSound;
	var hasSound:Bool = false;
	var songId:String = "fard";

	public var curLine:Int = 0;

	var objList:Array<FlxObject> = [];

	// for tweens

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		curLine = 0;
		songId = PlayState.SONG.songId.toLowerCase();

		switch (songId)
		{
			case 'senpai':
				sound = new FlxSound().loadEmbedded(Paths.music('Lunchbox'), true);
				sound.volume = 0;
				FlxG.sound.list.add(sound);
				sound.fadeIn(1, 0, 0.8);
				hasSound = true;
			case 'thorns':
				sound = new FlxSound().loadEmbedded(Paths.music('LunchboxScary'), true);
				sound.volume = 0;
				FlxG.sound.list.add(sound);
				sound.fadeIn(1, 0, 0.8);
				hasSound = true;
		}

		bgFade = new FlxSprite(0, 0).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.screenCenter();
		bgFade.alpha = 0;
		add(bgFade);

		FlxTween.tween(bgFade, {alpha: 0.7}, 4);

		box = new FlxSprite(-20, 45);

		var hasDialog = false;
		this.dialogueList = dialogueList;

		switch (songId)
		{
			case 'senpai':
				hasDialog = true;
				portraitLeft = new FlxSprite(-20, 40);
				portraitLeft.frames = Paths.getSparrowAtlas('stages/school/senpaiPortrait');
				portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
				portraitLeft.setGraphicSize(Std.int(portraitLeft.width * CoolUtil.daPixelZoom * 0.9));
				portraitLeft.updateHitbox();
				portraitLeft.antialiasing = false;
				portraitLeft.scrollFactor.set();
				add(portraitLeft);
				portraitLeft.visible = false;

				portraitRight = new FlxSprite(0, 40);
				portraitRight.frames = Paths.getSparrowAtlas('stages/school/bfPortrait');
				portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
				portraitRight.setGraphicSize(Std.int(portraitRight.width * CoolUtil.daPixelZoom * 0.9));
				portraitRight.updateHitbox();
				portraitRight.antialiasing = false;
				portraitRight.scrollFactor.set();
				add(portraitRight);
				portraitRight.visible = false;

				box.frames = Paths.getSparrowAtlas('hud/pixel/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
				box.antialiasing = false;
			case 'roses':
				hasDialog = true;
				FlxG.sound.play(Paths.sound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('hud/pixel/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);
				box.antialiasing = false;

				portraitLeft = new FlxSprite(-20, 40);
				portraitLeft.frames = Paths.getSparrowAtlas('stages/school/senpaiPortrait');
				portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
				portraitLeft.setGraphicSize(Std.int(portraitLeft.width * CoolUtil.daPixelZoom * 0.9));
				portraitLeft.updateHitbox();
				portraitLeft.antialiasing = false;
				portraitLeft.scrollFactor.set();
				add(portraitLeft);
				portraitLeft.visible = false;

				portraitRight = new FlxSprite(0, 40);
				portraitRight.frames = Paths.getSparrowAtlas('stages/school/bfPortrait');
				portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
				portraitRight.setGraphicSize(Std.int(portraitRight.width * CoolUtil.daPixelZoom * 0.9));
				portraitRight.updateHitbox();
				portraitRight.antialiasing = false;
				portraitRight.scrollFactor.set();
				add(portraitRight);
				portraitRight.visible = false;
			case 'thorns':
				hasDialog = true;
				box.frames = Paths.getSparrowAtlas('hud/pixel/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);
				box.antialiasing = false;

				portraitLeft = new FlxSprite(-250, -50).loadGraphic(Paths.image('stages/school/spiritFaceForward'));
				portraitLeft.setGraphicSize(Std.int(portraitLeft.width * 6));
				portraitLeft.antialiasing = false;
				add(portraitLeft);
				portraitLeft.visible = false;

				portraitRight = new FlxSprite(0, 40);
				portraitRight.frames = Paths.getSparrowAtlas('stages/school/bfPortrait');
				portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
				portraitRight.setGraphicSize(Std.int(portraitRight.width * CoolUtil.daPixelZoom * 0.9));
				portraitRight.updateHitbox();
				portraitRight.antialiasing = false;
				portraitRight.scrollFactor.set();
				add(portraitRight);
				portraitRight.visible = false;
		}

		if (!hasDialog)
			return;

		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * CoolUtil.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		portraitLeft.screenCenter(X);
		if (songId == 'thorns')
			portraitLeft.setPosition(320, 170); // retarded ass screenCenter;
		skipText = new FlxText(10, 10, Std.int(FlxG.width * 0.6), "", 24);
		skipText.font = Paths.font("vcr.ttf");
		skipText.antialiasing = true;
		skipText.color = 0x000000;
		skipText.text = 'Press Backspace To Skip.';
		skipText.setFormat(Paths.font("vcr.ttf"), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE_FAST, FlxColor.BLACK);
		add(skipText);
		handSelect = new FlxSprite(FlxG.width * 0.9, FlxG.height * 0.9).loadGraphic(Paths.image('hud/pixel/hand_textbox'));
		handSelect.antialiasing = false;
		add(handSelect);

		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = 'Pixel Arial 11 Bold';
		dropText.color = 0xFFD89494;
		add(dropText);

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = 'Pixel Arial 11 Bold';
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound('pixelText'), 0.6)];
		add(swagDialogue);
		// dialogue.x = 90;
		// add(dialogue);
		objList = [box, bgFade, portraitLeft, portraitRight, swagDialogue, dropText, skipText];
		if (songId == 'thorns')
		{
			swagDialogue.color = FlxColor.WHITE;
			dropText.color = FlxColor.BLACK;
		}
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		if (PlayerSettings.player1.controls.BACK && !isEnding)
			endDialogue();
		if (PlayerSettings.player1.controls.ACCEPT && dialogueStarted == true)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.8);
			if (dialogueList[curLine] == null)
			{
				if (!isEnding)
					endDialogue();
			}
			else
				startDialogue();
		}

		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();
		swagDialogue.resetText(dialogueList[curLine]);
		swagDialogue.start(0.04, true);
		switch (curCharacter)
		{
			case 'dad':
				portraitRight.visible = false;
				if (!portraitLeft.visible && songId != 'roses')
				{
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			case 'bf':
				portraitLeft.visible = false;
				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
		}

		lineHit(1);
	}

	function endDialogue()
	{
		isEnding = true;
		if (hasSound)
			sound.fadeOut(2.2, 0);
		if (objList.length > 0)
			for (obj in objList)
			{
				FlxTween.globalManager.completeTweensOf(obj);
				FlxTween.tween(obj, {alpha: 0}, 1);
			}
		FlxTimer.wait(1.25, function():Void
		{
			finishThing();
			kill();
		});
	}

	public function lineHit(line:Int)
	{
		curLine += line;
		/*
			if (dialogueList[curLine] != null)
				switch (songId)
				{
					case 'senpai':
						switch (curLine)
						{
							case 2:
						}
				}
		 */
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[curLine].split(":");
		curCharacter = splitName[1];
		dialogueList[curLine] = dialogueList[curLine].substr(splitName[1].length + 2).trim();
	}
}
