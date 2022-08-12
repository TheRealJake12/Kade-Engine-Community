package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;

class NoteSplash extends FlxSprite
{
	public static var scales:Array<Float> = [0.7, 0.6, 0.55, 0.46];
	public static var swidths:Array<Float> = [160, 120, 110, 90];
	public static var posRest:Array<Int> = [0, 35, 50, 70];

	public static var anims:Array<String> = ['purple','blue','green','red'];

	public function new(x:Float = 0, y:Float = 0, noteData:Int)
	{
		super(x, y);

		setupNoteSplash(x, y, noteData);
		setupNoteSplash2(x, y, noteData);
	}

	public function setupNoteSplash(x:Float, y:Float, noteData:Int)
	{	
		frames = PlayState.notesplashSprite;	
		antialiasing = FlxG.save.data.antialiasing;

		switch (noteData)
		{
			case 0: // Purple
				setPosition(x - Note.swagWidth * 0.95 + 20, y - Note.swagWidth);
			case 1: // Blue
				setPosition(x - Note.swagWidth * 0.95 + 25, y - Note.swagWidth + 32);
			case 2: // Green
				setPosition(x - Note.swagWidth * 0.95 + 45, y - Note.swagWidth + 32);
			case 3: // Red
				setPosition(x - Note.swagWidth * 0.95 + 45, y - Note.swagWidth + 32);
		}
		
		alpha = 1;	

		for (i in 0...anims.length)
		{
			animation.addByPrefix(anims[i], 'notesplash ' + anims[i], 48, false);
			animation.addByPrefix(anims[i], 'note impact 1 ' + anims[i], 30, false);
			animation.addByPrefix(anims[i], 'note impact 2 ' + anims[i], 30, false);
		}

		// x -= 100;
		// y -= 100;

		animation.play(anims[noteData]);
	}

	public function setupNoteSplash2(x:Float, y:Float, noteData:Int, ?isPlayer:Bool = false)
	{
		frames = PlayState.cpuNotesplashSprite;
		antialiasing = FlxG.save.data.antialiasing;

		switch (noteData)
		{
			case 0: // Purple
				setPosition(x - Note.swagWidth * 0.95 + 20, y - Note.swagWidth);
			case 1: // Blue
				setPosition(x - Note.swagWidth * 0.95 + 25, y - Note.swagWidth + 32);
			case 2: // Green
				setPosition(x - Note.swagWidth * 0.95 + 45, y - Note.swagWidth + 32);
			case 3: // Red
				setPosition(x - Note.swagWidth * 0.95 + 45, y - Note.swagWidth + 32);
		}
		alpha = 1;	

		for (i in 0...anims.length)
		{
			animation.addByPrefix(anims[i], 'notesplash ' + anims[i], 48, false);
			animation.addByPrefix(anims[i], 'note impact 1 ' + anims[i], 30, false);
			animation.addByPrefix(anims[i], 'note impact 2 ' + anims[i], 30, false);
		}

		// x -= 100;
		// y -= 100;

		animation.play(anims[noteData]);
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
			if (animation.curAnim.finished)
				kill();

		super.update(elapsed);
	}
}