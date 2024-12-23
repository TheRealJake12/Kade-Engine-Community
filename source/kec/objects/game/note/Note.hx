package kec.objects.game.note;

import kec.backend.lua.LuaClass;
import flixel.math.FlxRect;
import kec.backend.Ratings.RatingWindow;
import kec.backend.util.NoteStyleHelper;
import kec.backend.PlayStateChangeables;
import kec.backend.Ratings;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var baseStrum:Float = 0;
	public var lateHitMult:Float = 0.5;
	public var earlyHitMult:Float = 1.0;
	public var insideCharter:Bool = false;

	public var charterSelected:Bool = false;

	public var rStrumTime:Float = 0;

	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var rawNoteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var prevNote:Note;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var originColor:Int = 0; // The sustain note's original note's color
	public var noteSection:Int = 0;
	public var isSustainEnd:Bool = false;

	public var noteType(default, set):String = null;
	public var canPlayAnims:Bool = true; // if a note plays the sing animations
	public var canNoteSplash:Bool = true; // if a note can notesplash on Sick! and Marv!
	public var causesMisses:Bool = true; // if a note will do noteMiss or something.
	public var botplayHit:Bool = true; // if botplay should hit the note.
	public var canRate:Bool = true; // if it should do ratings, popup score and whatnot.
	public var missHealth:Float = 0.08; // default health you miss.
	public var hitsoundsEditor:Bool = true; // if a note plays a hitsound in the chart editor.
	public var gfNote:Bool = false; // if GF plays the note instead of the player / opponent.
	public var quantNote:Bool = true; // rotate

	public var luaID:Int = 0;

	public var noteCharterObject:FlxSprite;

	public var noteScore:Float = 1;

	public var noteYOff:Float = 0;

	public var beat:Float = 0;

	public static final swagWidth:Float = 160 * 0.7;
	public static final PURP_NOTE:Int = 0;
	public static final GREEN_NOTE:Int = 2;
	public static final BLUE_NOTE:Int = 1;
	public static final RED_NOTE:Int = 3;

	public var rating:RatingWindow;

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)

	public static final quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, GREEN_NOTE, 2];
	public static final arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var isParent:Bool = false;
	public var parent:Note = null;
	public var spotInLine:Int = 0;
	public var sustainActive(default, set):Bool = false;

	public var children:Array<Note> = [];

	public var stepHeight:Float = 0;

	public var distance:Float = 2000;
	public var speedMultiplier:Float = 1.0;
	public var overrideDistance:Bool = false; // Set this to true if you know what are you doing.

	/**
	 * Alpha helper to modify note alpha in-game (modcharts), use this instead of note.alpha
	 */
	public var modAlpha(default, set):Float = 1.0;

	/**
	 * Alpha helper for master note alpha, use this instead of note.alpha
	 */
	public var localAlpha(default, set):Float = 1.0;

	public static var defaultPlayerSkin(default, never):String = 'noteskins/Arrows';
	public static var defaultCpuSkin(default, never):String = 'noteskins/Arrows';

	public var texture(default, set):String = null;

	public var isPlayer:Bool = true;

	// defaults if no noteStyle was found in chart
	var noteTypeCheck:String = 'normal';

	#if FEATURE_LUAMODCHART
	public var LuaNote:LuaNote;
	#end

	private function set_texture(value:String):String
	{
		if (texture == value)
			return value;

		reloadNote(value);
		return texture = value;
	}

	private function set_noteType(value:String):String
	{
		if (noteType == value)
			return value;
		switch (value.toLowerCase())
		{
			case 'hurt':
				canPlayAnims = false;
				canNoteSplash = true;
				causesMisses = false;
				botplayHit = false;
				canRate = false;
				missHealth = 0;
				sustainActive = true;
				hitsoundsEditor = false;
				if (Paths.fileExists('images/notetypes/hurt_'
					+ NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin]
					+ '.png'))
					texture = 'notetypes/hurt_' + NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin];
				else
					texture = "notetypes/hurt_Arrows";
				quantNote = true;
			case 'mustpress':
				set_noteType('Must Press'); // backwards compatabilty for charts before the KEC1 format.
			case 'must press':
				canPlayAnims = true;
				canNoteSplash = true;
				botplayHit = true;
				canRate = true;
				missHealth = 0.8;
				hitsoundsEditor = true;
				if (Paths.fileExists('images/notetypes/mustpress_'
					+ NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin]
					+ '.png'))
					texture = 'notetypes/mustpress_' + NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin];
				else
					texture = "notetypes/mustpress_Arrows";
				quantNote = true;
			case 'no animation':
				canPlayAnims = false;
				canNoteSplash = true;
				causesMisses = true;
				missHealth = 0.08;
				botplayHit = true;
				canRate = true;
				hitsoundsEditor = true;
				quantNote = true;
			case 'gf':
				gfNote = true;
				canPlayAnims = true;
				canNoteSplash = true;
				causesMisses = true;
				missHealth = 0.08;
				botplayHit = true;
				canRate = true;
				hitsoundsEditor = true;
				quantNote = true;
			default:
				canPlayAnims = true;
				canNoteSplash = true;
				causesMisses = true;
				missHealth = 0.06;
				botplayHit = true;
				canRate = true;
				hitsoundsEditor = true;
				quantNote = true;
		}
		return noteType = value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inCharter:Bool = false, ?isPlayer:Bool = false,
			?bet:Float = 0)
	{
		super();
		this.noteType = noteType; // FFFFFFFFFFFFFFFFFFFFFFUUUUUUUUUUUUUUUUUUUUUUUUUUUU
		insideCharter = inCharter;
		this.isPlayer = isPlayer;
		if (prevNote == null)
			prevNote = this;

		beat = bet;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		moves = false;

		x += 50;
		// MAKE SURE ITS DEFINITELY OFF SCREEN?
		y -= 2000;

		if (inCharter)
		{
			this.strumTime = strumTime;
			rStrumTime = strumTime;
		}
		else
		{
			this.strumTime = strumTime;
			rStrumTime = strumTime;
		}

		if (this.strumTime < 0)
			this.strumTime = 0;

		this.noteData = noteData;

		if (PlayStateChangeables.mirrorMode)
		{
			this.noteData = Std.int(Math.abs(3 - noteData));
			noteData = Std.int(Math.abs(3 - noteData));
		}

		texture = '';

		// x += swagWidth * (noteData);
		var animToPlay:String = '';
		animToPlay = Constants.noteColors[Std.int(noteData % 4)] + 'Scroll';
		x += swagWidth * noteData;

		originColor = noteData; // The note's origin color will be checked by its sustain notes

		if (FlxG.save.data.stepMania
			&& quantNote
			&& !isSustainNote
			&& !(PlayState.instance != null ? PlayState.instance.executeModchart : false))
		{
			var col:Int = 0;

			var beatRow = Math.round(beat * 48);
			// STOLEN ETTERNA CODE (IN 2002)

			if (beatRow % (192 / 4) == 0)
				col = quantityColor[0];
			else if (beatRow % (192 / 8) == 0)
				col = quantityColor[2];
			else if (beatRow % (192 / 12) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 16) == 0)
				col = quantityColor[6];
			else if (beatRow % (192 / 24) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 32) == 0)
				col = quantityColor[4];

			originColor = col;

			localAngle -= arrowAngles[col];
			localAngle += arrowAngles[Std.int(noteData % 4)];
			originAngle = localAngle;
			animToPlay = Constants.noteColors[Std.int(col % 4)] + 'Scroll';
		}

		animation.play(animToPlay);

		if (isSustainNote && prevNote != null)
		{
			stepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
				2) * speedMultiplier);
			noteYOff = -stepHeight + swagWidth * 0.5;

			noteScore * 0.2;

			if (PlayStateChangeables.useDownscroll)
				flipY = true;

			x += width * 0.5;

			originColor = prevNote.originColor;
			originAngle = prevNote.originAngle;

			animation.play(Constants.noteColors[Std.int(originColor % 4)] + 'holdend'); // This works both for normal colors and quantization colors
			updateHitbox();

			x -= width * 0.5;

			if (inCharter)
				x += 30;

			isSustainEnd = true;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(Constants.noteColors[prevNote.originColor] + 'hold');
				prevNote.updateHitbox();
				prevNote.scale.y *= (stepHeight / prevNote.height);

				if (noteTypeCheck != 'pixel')
					prevNote.scale.y *= 1.0 + (1.0 / prevNote.frameHeight) * 1.05;

				prevNote.updateHitbox();
				prevNote.isSustainEnd = false;
			}
		}
		else if (!isSustainNote)
		{
			centerOffsets();
			centerOrigin();
		}
	}

	static var _lastValidChecked:String; // optimization

	public function reloadNote(texture:String = '')
	{
		if (texture == null)
			texture = '';

		var skin:String = texture;

		if (texture.length < 1)
		{
			skin = isPlayer ? Constants.noteskinSprite : Constants.cpuNoteskinSprite;

			if (skin == null || skin.length < 1)
				skin = isPlayer ? defaultPlayerSkin : defaultCpuSkin;
		}

		var animName:String = null;
		if (animation.curAnim != null)
			animName = animation.curAnim.name;

		var lastScaleY:Float = scale.y;
		var skinPostfix:String = '';
		var customSkin:String = skin + skinPostfix;
		var path:String = '';

		if (customSkin == _lastValidChecked || Paths.fileExists('images/' + customSkin + '.png'))
		{
			skin = customSkin;
			_lastValidChecked = customSkin;
		}
		else
			skinPostfix = '';

		if (PlayState.SONG != null && PlayState.STYLE != null)
			noteTypeCheck = PlayState.STYLE.style.toLowerCase();
		else
			noteTypeCheck = 'default';

		switch (noteTypeCheck)
		{
			case 'pixel':
				loadGraphic(Constants.noteskinPixelSprite, true, 17, 17);
				if (isSustainNote)
					loadGraphic(Constants.noteskinPixelSpriteEnds, true, 7, 6);

				loadPixelAnims();
				antialiasing = false;
			default:
				frames = Paths.getSparrowAtlas(skin);
				loadNoteAnims();
				antialiasing = FlxG.save.data.antialiasing;
				if (!isSustainNote)
				{
					centerOffsets();
					centerOrigin();
				}
		}

		if (animName != null)
			animation.play(animName, true);

		if (noteTypeCheck != 'pixel')
		{
			if (isSustainNote && (animation.curAnim != null && !animation.curAnim.name.endsWith('end')))
				scale.y = lastScaleY;
		}

		updateHitbox();
	}

	function loadNoteAnims()
	{
		for (i in 0...4)
		{
			if (isSustainNote)
			{
				animation.addByPrefix(Constants.noteColors[i] + 'hold', Constants.noteColors[i] + ' hold'); // Hold
				animation.addByPrefix(Constants.noteColors[i] + 'holdend', Constants.noteColors[i] + ' tail'); // Tails
			}
			else
				animation.addByPrefix(Constants.noteColors[i] + 'Scroll', Constants.noteColors[i] + ' alone'); // Normal notes
		}
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelAnims()
	{
		for (i in 0...4)
		{
			if (isSustainNote)
			{
				animation.add(Constants.noteColors[i] + 'hold', [i]); // Holds
				animation.add(Constants.noteColors[i] + 'holdend', [i + 4]); // Tails
			}
			else
				animation.add(Constants.noteColors[i] + 'Scroll', [i + 4]); // Normal notes
		}

		setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		// This updates hold notes height to current scroll Speed in case of scroll Speed changes.
		super.update(elapsed);

		if (!isSustainNote)
		{
			if (!modifiedByLua)
				angle = modAngle + localAngle;
			else
				angle = modAngle;
		}

		if (insideCharter)
			return;

		if (isSustainNote)
		{
			final newStepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
				2) * speedMultiplier);

			if (stepHeight != newStepHeight)
			{
				stepHeight = newStepHeight;
				if (isSustainNote)
					noteYOff = -stepHeight + swagWidth * 0.5;
			}

			flipY = PlayStateChangeables.useDownscroll;
		}

		if (mustPress)
		{
			switch (noteType.toLowerCase())
			{
				case 'hurt':
					canBeHit = (strumTime - Conductor.elapsedPosition <= ((Ratings.timingWindows[0].timingWindow) * 0.2)
						&& strumTime - Conductor.elapsedPosition >= (-Ratings.timingWindows[0].timingWindow) * 0.4);
					tooLate = (strumTime - Conductor.elapsedPosition < -Ratings.timingWindows[0].timingWindow && !wasGoodHit);
				default:
					canBeHit = (strumTime - Conductor.elapsedPosition <= (((Ratings.timingWindows[0].timingWindow) * lateHitMult))
						&& strumTime - Conductor.elapsedPosition >= (((-Ratings.timingWindows[0].timingWindow) * earlyHitMult)));
					tooLate = (strumTime - Conductor.elapsedPosition < (-Ratings.timingWindows[0].timingWindow) && !wasGoodHit);
			}
		}
	}

	override public function destroy()
	{
		if (noteCharterObject != null)
			noteCharterObject.destroy();

		super.destroy();
	}

	@:noCompletion
	override function set_y(value:Float):Float
	{
		if (isSustainNote)
			if (PlayStateChangeables.useDownscroll)
				value -= height - swagWidth;
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

	public function followStaticArrow(parent:StaticArrow)
	{
		final leSpeed:Float = PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed;
		if (isSustainNote)
			x = (parent.x + (parent._cos * distance)) + (swagWidth / 3);
		else
			x = parent.x + (parent._cos * distance);

		if (isSustainNote && noteTypeCheck == 'pixel')
			x -= 5;

		if (!overrideDistance)
		{
			if (parent.downScroll)
				distance = (0.45 * (Conductor.elapsedPosition - strumTime)) * (FlxMath.roundDecimal(leSpeed, 2)) - noteYOff;
			else
				distance = (-0.45 * (Conductor.elapsedPosition - strumTime)) * (FlxMath.roundDecimal(leSpeed, 2)) + noteYOff;
		}

		y = parent.y + (parent._sin * distance);

		// modchart shit

		visible = parent.visible;
		if (!isSustainNote)
			modAngle = parent.modAngle;

		if (isSustainNote)
			modAlpha = parent.modAlpha * FlxG.save.data.alpha; // This is the correct way
		else
			modAlpha = parent.modAlpha;
	}

	public function clipToStaticArrow(parent:StaticArrow)
	{
		if (!isSustainNote || !sustainActive || !causesMisses)
			return;

		final center:Float = parent.y + swagWidth * 0.5;
		final swagRect:FlxRect = FlxRect.get(0, 0, frameWidth, frameHeight);

		switch (parent.downScroll)
		{
			case true:
				if (y - offset.y * scale.y + height >= center)
				{
					swagRect.width = frameWidth;
					swagRect.height = (center - y) / scale.y;
					swagRect.y = frameHeight - swagRect.height;
				}
			case false:
				if (y + offset.y * scale.y <= center)
				{
					swagRect.y = (center - y) / scale.y;
					swagRect.width = width / scale.x;
					swagRect.height = (height / scale.y) - swagRect.y;
				}
		}
		clipRect = swagRect;
		swagRect.put();
	}

	function set_sustainActive(b:Bool)
	{
		sustainActive = b;
		if (!b && !wasGoodHit)
			localAlpha = (localAlpha * 0.5);

		return b;
	}

	function set_localAlpha(a:Float)
	{
		localAlpha = a;
		alpha = localAlpha * modAlpha;
		return a;
	}

	function set_modAlpha(a:Float)
	{
		modAlpha = a;
		alpha = localAlpha * modAlpha;
		return a;
	}
}
