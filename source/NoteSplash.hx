package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

typedef SplashData =
{
	/**
	 * The name of this animation.
	 */
	var name:String;

	/**
	 * The frame rate of this animation.
	 		* @default 24
	 */
	var fps:Int;

	/**
	 * The transparency of the notesplashes.
	 		* @default 24
	 */
	var alpha:Int;

	/**
	 * The X Offset so it can be centered better.
	 		* @default 90
	 */
	var xOffset:Int;

	/**
	 * The Y Offset so it can be centered better.
	 		* @default 80
	 */
	var yOffset:Int;

	// theres gonna be more but the fps fucks me so much rn
}

class NoteSplash extends FlxSprite
{
	public static var scales:Array<Float> = [0.7, 0.6, 0.55, 0.46];
	public static var swidths:Array<Float> = [160, 120, 110, 90];
	public static var posRest:Array<Int> = [0, 35, 50, 70];
	var name:String;
	var nameTwo:String;

	public static var anims:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(x:Float = 0, y:Float = 0, noteData:Int)
	{
		super(x, y);

		antialiasing = FlxG.save.data.antialiasing;
		loadSplashFrames1();
		loadSplashFrames2();
	}

	public function setupNoteSplash(x:Float, y:Float, noteData:Int)
	{
		visible = true;
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		var animNum:Int = FlxG.random.int(0, 1);

		animation.play('splash ' + animNum + " " + noteData);

		//animation.curAnim.frameRate += FlxG.random.int(0, 2);

		animation.finishCallback = function(name:String)
		{
			visible = false;
			kill();
		}
	}

	function loadSplashFrames1()
	{
		frames = PlayState.notesplashSprite;

		switch (FlxG.save.data.notesplash)
		{
			case 0:
				name = 'Default';
			case 1:
				name = 'Week7';
		}

		var rawJson = Paths.loadData('images/splashes/' + name, 'shared');
		var data:SplashData = cast rawJson;
		
		animation.addByPrefix('splash 0 0', 'note splash 1 purple', data.fps, false);
		animation.addByPrefix('splash 0 1', 'note splash 1 blue', data.fps, false);
		animation.addByPrefix('splash 0 2', 'note splash 1 green', data.fps, false);
		animation.addByPrefix('splash 0 3', 'note splash 1 red', data.fps, false);

		animation.addByPrefix('splash 1 0', 'note splash 2 purple', data.fps, false);
		animation.addByPrefix('splash 1 1', 'note splash 2 blue', data.fps, false);
		animation.addByPrefix('splash 1 2', 'note splash 2 green', data.fps, false);
		animation.addByPrefix('splash 1 3', 'note splash 2 red', data.fps, false);
		alpha = data.alpha;
		x += data.xOffset;
		y += data.yOffset; // lets stick to eight not nine
	}

	function loadSplashFrames2()
	{
		frames = PlayState.cpuNotesplashSprite;

		switch (FlxG.save.data.cpuNotesplash)
		{
			case 0:
				nameTwo = 'Default';
			case 1:
				nameTwo = 'Week7';
		}

		var rawJson = Paths.loadData('images/splashes/' + nameTwo, 'shared');
		var data2:SplashData = cast rawJson;

		animation.addByPrefix('splash 0 0', 'note splash 1 purple', data2.fps, false);
		animation.addByPrefix('splash 0 1', 'note splash 1 blue', data2.fps, false);
		animation.addByPrefix('splash 0 2', 'note splash 1 green', data2.fps, false);
		animation.addByPrefix('splash 0 3', 'note splash 1 red', data2.fps, false);

		animation.addByPrefix('splash 1 0', 'note splash 2 purple', data2.fps, false);
		animation.addByPrefix('splash 1 1', 'note splash 2 blue', data2.fps, false);
		animation.addByPrefix('splash 1 2', 'note splash 2 green', data2.fps, false);
		animation.addByPrefix('splash 1 3', 'note splash 2 red', data2.fps, false);
		alpha = data2.alpha;
		x += data2.xOffset;
		y += data2.yOffset; // lets stick to eight not nine
	}

	public function setupNoteSplash2(x:Float, y:Float, noteData:Int)
	{
		visible = true;
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		var animNum:Int = FlxG.random.int(0, 1);

		animation.play('splash ' + animNum + " " + noteData);

		//animation.curAnim.frameRate += FlxG.random.int(0, 2);

		animation.finishCallback = function(name:String)
		{
			visible = false;
			kill();
		}
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
		{
			if (animation.curAnim.finished)
				kill();
		}

		super.update(elapsed);
	}
}
