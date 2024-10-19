package kec.states;

import flixel.group.FlxGroup;
import openfl.Assets;
import kec.objects.Alphabet;

class TitleState extends MusicBeatState
{
	private static var seenBefore:Bool = false;
	private var clickedBefore:Bool = false;

	private var danceLeft:Bool = false;
	private var introText:Array<String> = [];

	private var gf:FlxSprite;
	private var logo:FlxSprite;
	private var enter:FlxSprite;
	private var jake:FlxSprite;
	private var textGroup:FlxTypedGroup<Alphabet>;

	public function new()
	{
		super();

		FlxG.mouse.visible = true;
		introText = FlxG.random.getObject(getRandomText());

		Conductor.bpm = 102;
		gf = new FlxSprite(0, 50);
		gf.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gf.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gf.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gf.alpha = 0.0001;

		logo = new FlxSprite(25, -1000);
		logo.frames = Paths.getSparrowAtlas('KECLogoOrange');
		logo.animation.addByPrefix('bump', 'logo bumpin', 24, false);
		logo.alpha = 0.0001;

		enter = new FlxSprite(100, 625);
		enter.frames = Paths.getSparrowAtlas('titleEnter');
		enter.animation.addByPrefix('idle', "ENTER IDLE0", 24);
		enter.animation.addByPrefix('press', "ENTER PRESSED", 24);
		enter.animation.play('idle');
		enter.alpha = 0.0001;

		textGroup = new FlxTypedGroup<Alphabet>();
		add(textGroup);

		jake = new FlxSprite(0, FlxG.height * 0.55).loadGraphic(Paths.image('credshit/jake'));
		jake.setGraphicSize(256, 256);
		jake.updateHitbox();
		jake.screenCenter(X);
		jake.alpha = 0.001;
		add(jake);

		add(logo);
		add(gf);
		add(enter);
	}

	override function create()
	{
		Paths.clearCache();

		FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
		FlxG.sound.music.fadeIn(10, 0, 0.7);
		if (seenBefore)
			show();
		super.create();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;
		if (controls.ACCEPT || FlxG.mouse.justPressed)
			decide();
		super.update(elapsed);
	}

	override function beatHit()
	{
		logo.animation.play('bump', true);
		danceLeft = !danceLeft;

		if (danceLeft)
			gf.animation.play('danceRight');
		else
			gf.animation.play('danceLeft');

		super.beatHit();

		if (seenBefore)
			return;

		switch (curBeat)
		{
			case 0:
				deleteText();
			case 1:
				setText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			case 3:
				addText('present');
			case 4:
				deleteText();
			case 5:
				setText(['KE Community', 'by']);
			case 7:
				addText('TheRealJake_12');
				createTween(jake, {alpha: 1}, .2, {ease: FlxEase.quadOut});
			case 8:
				deleteText();
				createTween(jake, {alpha: 0}, 0.5, {ease: FlxEase.quadOut});
			case 9:
				setText([introText[0]]);
			case 11:
				addText(introText[1]);
			case 12:
				deleteText();
			case 13:
				addText('Friday');
			case 14:
				addText('Night');
			case 15:
				addText('Funkin');
			case 16:
				show();
		}
	}

	private function show()
	{
		seenBefore = true;	
		deleteText();
		remove(textGroup);
		remove(jake);
		FlxG.camera.flash(FlxColor.WHITE, 3);
		createTween(enter, {alpha: 1}, 1.5, {ease: FlxEase.cubeOut});
		createTween(logo, {y: -30, alpha: 1}, 0.75, {ease: FlxEase.cubeOut});
		createTween(gf, {x: FlxG.width * 0.42, alpha: 1}, 1, {ease: FlxEase.cubeOut});
		createTween(enter, {alpha: 1}, 1, {ease: FlxEase.cubeOut});
		FlxG.sound.music.time = 9400; // 9.4 seconds
	}

	private function pizzaTime()
	{
		if (clickedBefore)
			return;
		clickedBefore = true;
		FlxG.camera.flash(0x4CFFFFFF, 0.75);
		FlxG.sound.play(Paths.sound('confirmMenu', true));
		enter.animation.play('press', true);
		FlxTimer.wait(1, function()
		{
			MusicBeatState.switchState(new MainMenuState());
		});
	}

	private function decide()
	{
		switch(seenBefore)
		{
			case false:
				show();
			case true:
				pizzaTime();
		}
	}

	private function setText(text:Array<String>)
	{
		for (i in 0...text.length)
		{
			var alph:Alphabet = new Alphabet(0, 0 + (i * 60) + 200, text[i], true);
			alph.screenCenter(X);
			textGroup.add(alph);
			alph.alpha = 0;
			createTween(alph, {alpha: 1}, .5, {ease: FlxEase.quadOut});
		}
	}

	private function addText(text:String)
	{
		if (textGroup != null)
		{
			var alph:Alphabet = new Alphabet(0, 0 + (textGroup.length * 60) + 200, text, true);
			alph.screenCenter(X);
			alph.alpha = 0;
			createTween(alph, {alpha: 1}, .5, {ease: FlxEase.quadOut});
			textGroup.add(alph);
		}
	}

	private function deleteText()
	{
		for (object in textGroup.members)
		{
			final flxSprite:FlxSprite = cast object;
			createTween(flxSprite, {alpha: 0}, .5, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					textGroup.remove(textGroup.members[0], true);
				}
			});
		}
	}

	private function getRandomText()
	{
		final fullText:String = Assets.getText(Paths.txt('data/introText'));
		final firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
			swagGoodArray.push(i.split('--'));

		return swagGoodArray;
	}
}
