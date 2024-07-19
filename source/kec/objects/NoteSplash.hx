package kec.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import kec.backend.util.NoteStyleHelper;

typedef SplashData =
{
	/**
	 * The name of this animation.
	 */
	var ?name:String;
	var animations:Array<SplashAnims>;
	var ?antialiasing:Bool;
	var ?scale:Float;

	var ?minFps:Int;
	var ?maxFps:Int;
}

typedef SplashAnims = 
{
	var name:String;
	var prefix:String;
	var ?offsets:Array<Int>;
	var ?frameRate:Int;
	var ?frameIndices:Array<Int>;
}

class NoteSplash extends FlxSprite
{
	public var noteType:String = '';
	private var animOffsets:Map<String, Array<Dynamic>>;
	static var _lastCheckedType:String = '';
	
	public static var colors:Array<String> = ['purple', 'blue', 'green', 'red'];
	private static var configs:Map<String, SplashData> = new Map<String, SplashData>();
	static var rawJson = null;
	var minFps = 24;
	var maxFps = 26;

	public function new(x:Float = 0, y:Float = 0, noteType:String, noteData:Int)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();
		this.noteType = noteType;
		// because it doesn't know what to do if it ACTUALLY has notetype data.

		loadFrames();
		loadSplashData(Constants.notesplashSprite);
	}

	public function setupNoteSplash(x:Float, y:Float, note:Note)
	{
		visible = true;

		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		alpha = FlxG.save.data.alphaSplash;

		loadFrames(noteType);
		offset.set(0,0);

		var animNum:Int = FlxG.random.int(1, 2);

		var animToPlay:String;	

		if (!FlxG.save.data.stepMania)
			animToPlay = 'splash ${animNum} ${colors[note.noteData]}';
		else
			animToPlay = 'splash ${animNum} ${colors[note.originColor]}';

		playAnim(animToPlay);
	}

	function loadFrames(?noteType:String = '')
	{
		var texture:String = Constants.notesplashSprite;
		switch (PlayState.STYLE.style.toLowerCase())
		{
			case 'pixel':
				frames = Paths.getSparrowAtlas('hud/pixel/noteSplashes-pixels');
			default:
				frames = Paths.getSparrowAtlas(NoteStyleHelper.generateNotesplashSprite(texture, noteType.toLowerCase()), 'shared');
				if (frames == null)
					frames = Paths.getSparrowAtlas(NoteStyleHelper.generateNotesplashSprite(texture, ''), 'shared');
		}
		
		loadAnimations(loadSplashData(texture));
	}

	private function loadAnimations(config:SplashData)
	{
		if (frames != null)
		{
			for (anim in config.animations)
			{
				var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
				if (anim.frameIndices != null)
					animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", Std.int(frameRate), false);
				else
					animation.addByPrefix(anim.name, anim.prefix, Std.int(frameRate), false);
				animOffsets[anim.name] = anim.offsets == null ? [0, 0] : anim.offsets;
			}

			if (config.scale != null)
			{
				setGraphicSize(Std.int(width * config.scale));
				updateHitbox();
			}

			minFps = config.minFps == null ? 22 : config.minFps;
			maxFps = config.maxFps == null ? 26 : config.maxFps;

			antialiasing = config.antialiasing == null ? FlxG.save.data.antialiasing : config.antialiasing;
		}
	}

	private function loadSplashData(tex:String)
	{
		if (configs.exists(tex))
			return configs.get(tex);
		rawJson = Paths.loadData('images/splashes/' + Constants.notesplashSprite, 'shared');	
		var data:SplashData = cast rawJson;
		_lastCheckedType = tex;
		configs.set(tex, data);
		return data;
	}

	public function playAnim(name:String)
	{
		var daOffset = animOffsets.get(name);
		if (animOffsets.exists(name))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);
		animation.play(name, true);

		animation.curAnim.frameRate = FlxG.random.int(minFps, maxFps);
	}

	override function destroy()
	{
		configs.clear();
		rawJson = null;
		_lastCheckedType = '';
		animOffsets.clear();
		super.destroy();
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
