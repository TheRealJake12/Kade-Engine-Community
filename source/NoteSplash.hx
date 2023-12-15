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

	public var noteType:String = '';

	var name:String;

	public static var anims:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function new(x:Float = 0, y:Float = 0, noteType:String, noteData:Int)
	{
		super(x, y);

		this.noteType = noteType;

		// because it doesn't know what to do if it ACTUALLY has notetype data.	

		loadAnims();

		antialiasing = FlxG.save.data.antialiasing;
	}

	public function setupNoteSplash(x:Float, y:Float, note:Note)
	{
		visible = true;

		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = FlxG.save.data.alphaSplash;

		if (note.noteShit == null || note.noteShit == 'normal' || note.noteShit == "0") // *proper* noteType checking to make sure it isn't null.
			noteType = '';

		loadAnims(noteType);

		var animNum:Int = FlxG.random.int(0, 1);

		if (!FlxG.save.data.stepMania)
			animation.play('splash ' + animNum + " " + note.noteData);
		else
			animation.play('splash ' + animNum + " " + note.originColor);

		animation.curAnim.frameRate += FlxG.random.int(0, 2);

		animation.finishCallback = function(name:String)
		{
			visible = false;
			kill();
		}
	}

	function loadAnims(?noteType:String = '')
	{
		var rawJson = Paths.loadData('images/splashes/' + CustomNoteHelpers.Splash.notesplashArray[FlxG.save.data.notesplash], 'shared');
		var data:SplashData = cast rawJson;
		switch (PlayState.SONG.noteStyle)
		{
			case 'pixel':
				frames = Paths.getSparrowAtlas('weeb/pixelUI/noteSplashes-pixels', 'week6');
				for (i in 0...4)
				{
					animation.addByPrefix('splash 0 ' + i, 'note splash 1 ' + anims[i], 24, false);
					animation.addByPrefix('splash 1 ' + i, 'note splash 2 ' + anims[i], 24, false);
				}
			default:
				frames = Paths.getSparrowAtlas(CustomNoteHelpers.Splash.generateNotesplashSprite(FlxG.save.data.notesplash, noteType), 'shared');
				if (frames == null)
					frames = Paths.getSparrowAtlas(CustomNoteHelpers.Splash.generateNotesplashSprite(0, ''), 'shared');
				for (i in 0...4)
				{
					animation.addByPrefix('splash 0 ' + i, 'note splash 1 ' + anims[i], data.fps, false);
					animation.addByPrefix('splash 1 ' + i, 'note splash 2 ' + anims[i], data.fps, false);
				}
		}

		offset.set(data.xOffset, data.yOffset);
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
