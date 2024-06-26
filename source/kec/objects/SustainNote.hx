package kec.objects;

import flixel.math.FlxRect;
import kec.backend.util.NoteStyleHelper;
import kec.backend.PlayStateChangeables;

class SustainNote extends Note
{
	public var parent:Note;
	public var prevNote:Note;
	public var isSustainEnd:Bool = false;
	public var sustainActive = false;

	public static var defaultPlayerSkin(default, never):String = 'noteskins/Arrows';
	public static var defaultCpuSkin(default, never):String = 'noteskins/Arrows';

	public var noteYOff:Float = 0;
	static var _lastValidChecked:String; // optimization

	public function setupSus(strumTime:Float, prevNote:Note = null, parent:Note = null)
	{   
		resetSus();
		this.strumTime = strumTime;
		this.parent = parent;
		this.noteData = parent.noteData;
		this.isPlayer = parent.isPlayer;
		this.prevNote = prevNote;
		reloadNote('');
		playAnims();
	}
    
    public function resetSus()
	{
        scale.y = 0.7;
		isSustainEnd = false;
		sustainActive = false;
		clipRect = FlxDestroyUtil.put(clipRect);
	}

	private function playAnims()
	{
		stepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
			2) * speedMultiplier);
		noteYOff = -stepHeight + Note.swagWidth * 0.5;

		if (PlayStateChangeables.useDownscroll)
			flipY = true;

		x += width * 0.5;
		originColor = prevNote.originColor;
		originAngle = prevNote.originAngle;

		animation.play(Note.dataColor[Std.int(originColor % 4)] + 'holdend'); // This works both for normal colors and quantization colors
		updateHitbox();

		x -= width * 0.5;

		// if (noteTypeCheck == 'pixel')
		//	x += 30;

		if (prevNote != null)
		{
			prevNote.animation.play(Note.dataColor[prevNote.originColor] + 'hold');
			prevNote.updateHitbox();
			prevNote.scale.y *= (stepHeight / prevNote.height);

			if (noteTypeCheck != 'pixel')
				prevNote.scale.y *= 1.0 + (1.0 / prevNote.frameHeight) * 1.05;

			prevNote.updateHitbox();
		}
	}

	override function reloadNote(texture:String = '')
	{
		if (texture == null)
			texture = '';

		var skin:String = texture;

		if (texture.length < 1)
		{
			if (!PlayStateChangeables.opponentMode)
				skin = isPlayer ? PlayState.noteskinSprite : PlayState.cpuNoteskinSprite;
			else
				skin = isPlayer ? PlayState.cpuNoteskinSprite : PlayState.noteskinSprite;

			if (skin == null || skin.length < 1)
				skin = isPlayer ? defaultPlayerSkin : defaultCpuSkin;
		}

		var animName:String = null;
		if (animation.curAnim != null)
		{
			animName = animation.curAnim.name;
		}

		var lastScaleY:Float = scale.y;
		var skinPostfix:String = '';
		var customSkin:String = skin + skinPostfix;
		var path:String = '';

		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + customSkin + '.png', IMAGE))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else
			skinPostfix = '';

		if (PlayState.SONG != null && PlayState.STYLE != null)
			noteTypeCheck = PlayState.STYLE.style.toLowerCase();
		else
			noteTypeCheck = 'normal';

		switch (noteTypeCheck)
		{
			case 'pixel':
				loadGraphic(PlayState.noteskinPixelSpriteEnds, true, 17, 17);

				loadPixelAnims();
				antialiasing = false;
			default:
				frames = Paths.getSparrowAtlas(skin);
				loadNoteAnims();
		}

		if (animName != null)
			animation.play(animName, true);

		updateHitbox();
	}

	override function loadNoteAnims()
	{
		for (i in 0...4)
		{
			animation.addByPrefix(Note.dataColor[i] + 'hold', Note.dataColor[i] + ' hold'); // Hold
			animation.addByPrefix(Note.dataColor[i] + 'holdend', Note.dataColor[i] + ' tail'); // Tails
		}
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	override function loadPixelAnims()
	{
		for (i in 0...4)
		{
			animation.add(Note.dataColor[i] + 'hold', [i]); // Holds
			animation.add(Note.dataColor[i] + 'holdend', [i + 4]); // Tails
		}
		setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var newStepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
			2) * speedMultiplier);

		if (stepHeight != newStepHeight)
		{
			stepHeight = newStepHeight;
			noteYOff = -stepHeight + Note.swagWidth * 0.5;
		}

		flipY = PlayStateChangeables.useDownscroll;

		isSustainEnd = spotInLine == parent.children.length - 1;
		alpha = !sustainActive
			&& (parent.tooLate || parent.wasGoodHit) ? (modAlpha * FlxG.save.data.alpha) * 0.5 : modAlpha * FlxG.save.data.alpha; // This is the correct way
	}

	@:noCompletion
	override function set_y(value:Float):Float
	{
		if (PlayStateChangeables.useDownscroll)
			value -= height - Note.swagWidth;
		return super.set_y(value);
	}

	@:noCompletion
	override function set_clipRect(rect:FlxRect):FlxRect
	{
		clipRect = rect;

		if (frames != null)
			frame = frames.frames[animation.frameIndex];

		return rect;
	}
}
