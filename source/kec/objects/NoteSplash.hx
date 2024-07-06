package kec.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import kec.backend.util.NoteStyleHelper;

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

	var minFps:Int;
	var maxFps:Int;
	// theres gonna be more but the fps fucks me so much rn
}

class NoteSplash extends FlxSprite
{
	public var noteType:String = '';

	var name:String;

	public static var anims:Array<String> = ['purple', 'blue', 'green', 'red'];

	var rawJson = null;

	public function new(x:Float = 0, y:Float = 0, noteType:String, noteData:Int)
	{
		super(x, y);

		rawJson = Paths.loadData('images/splashes/' + NoteStyleHelper.notesplashArray[FlxG.save.data.notesplash], 'shared');

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

		if (note.noteType == null
			|| note.noteType.toLowerCase() == 'normal'
			|| note.noteType == "0") // *proper* noteType checking to make sure it isn't null.
			noteType = '';

		loadAnims(noteType);

		var animNum:Int = FlxG.random.int(0, 1);

		if (!FlxG.save.data.stepMania)
			animation.play('splash ' + animNum + " " + note.noteData);
		else
			animation.play('splash ' + animNum + " " + note.originColor);
		var data:SplashData = cast rawJson;
		var minFps = 24;
		var maxFps = 26;
		switch (PlayState.STYLE.style)
		{
			case 'pixel':
				minFps = 22;
				maxFps = 26;
			default:
				minFps = data.minFps;
				maxFps = data.maxFps;
		}

		animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);

		animation.finishCallback = function(name:String)
		{
			visible = false;
			kill();
		}
	}

	function loadAnims(?noteType:String = '')
	{
		var data:SplashData = cast rawJson;
		switch (PlayState.STYLE.style.toLowerCase())
		{
			case 'pixel':
				frames = Paths.getSparrowAtlas('hud/pixel/noteSplashes-pixels');
				for (i in 0...4)
				{
					animation.addByPrefix('splash 0 ' + i, 'note splash 1 ' + anims[i], 24, false);
					animation.addByPrefix('splash 1 ' + i, 'note splash 2 ' + anims[i], 24, false);
				}
			default:
				frames = Paths.getSparrowAtlas(NoteStyleHelper.generateNotesplashSprite(FlxG.save.data.notesplash, noteType.toLowerCase()), 'shared');
				if (frames == null)
					frames = Paths.getSparrowAtlas(NoteStyleHelper.generateNotesplashSprite(0, ''), 'shared');
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
