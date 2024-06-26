package kec.objects;

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
	public var lateHitMult:Float = 1.0;
	public var earlyHitMult:Float = 1.0;
	public var insideCharter:Bool = false;

	public var charterSelected:Bool = false;

	public var rStrumTime:Float = 0;

	public var isPlayer:Bool = true;
	public var noteData:Int = 0;
	public var rawNoteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var modifiedByLua:Bool = false;
	public var sustainLength:Float = 0;
	public var originColor:Int = 0; // The sustain note's original note's color
	public var noteSection:Int = 0;

	public var noteShit(default, set):String = null;
	public var canPlayAnims:Bool = true; // if a note plays the sing animations
	public var canNoteSplash:Bool = true; // if a note can notesplash on Sick! and Marv!
	public var causesMisses:Bool = true; // if a note will do noteMiss or something.
	public var botplayHit:Bool = true; // if botplay should hit the note.
	public var canRate:Bool = true; // if it should do ratings, popup score and whatnot.
	public var missHealth:Float = 0.08; // default health you miss.
	public var hitsoundsEditor:Bool = true; // if a note plays a hitsound in the chart editor.
	public var gfNote:Bool = false; // if GF plays the note instead of the player / opponent.

	public var luaID:Int = 0;

	public var noteCharterObject:FlxSprite;

	public var noteScore:Float = 1;

	public var beat:Float = 0;

	public static var swagWidth:Float = 160 * 0.7;
	public static final PURP_NOTE:Int = 0;
	public static final GREEN_NOTE:Int = 2;
	public static final BLUE_NOTE:Int = 1;
	public static final RED_NOTE:Int = 3;

	public var rating:RatingWindow;

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)

	public static final dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	public static final quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, GREEN_NOTE, 2];
	public static final arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var isParent:Bool = false;
	public var spotInLine:Int = 0;

	public var children:Array<SustainNote> = [];

	public var stepHeight:Float = 0;

	public var distance:Float = 2000;
	public var speedMultiplier:Float = 1.0;
	public var overrideDistance:Bool = false; // Set this to true if you know what are you doing.

	public var modAlpha:Float = 1;

	public static var defaultPlayerSkin(default, never):String = 'noteskins/Arrows';
	public static var defaultCpuSkin(default, never):String = 'noteskins/Arrows';

	public var texture(default, set):String = null;

	// defaults if no noteStyle was found in chart
	var noteTypeCheck:String = 'normal';

	#if FEATURE_LUAMODCHART
	public var LuaNote:LuaNote;
	#end

	public function setup(strumTime:Float, noteData:Int, ?isPlayer:Bool = false, beat:Float)
	{
		resetProperties();
		this.noteData = noteData;
		this.strumTime = strumTime;
		rStrumTime = strumTime;
		this.isPlayer = this.isPlayer = isPlayer;
		rawNoteData = this.noteData;
		reloadNote(null);

		if (this.strumTime < 0)
			this.strumTime = 0;

		y -= 2000;
		lateHitMult = 1;

		if (PlayStateChangeables.mirrorMode)
		{
			this.noteData = Std.int(Math.abs(3 - noteData));
			noteData = Std.int(Math.abs(3 - noteData));
		}

		x += swagWidth * noteData;
		originColor = noteData;
		var animToPlay:String = '';
		animToPlay = dataColor[Std.int(originColor % 4)] + 'Scroll';

		if (FlxG.save.data.stepMania && !(PlayState.instance != null ? PlayState.instance.executeModchart : false))
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
			animToPlay = dataColor[Std.int(col % 4)] + 'Scroll';
		}

		animation.play(animToPlay);

		centerOffsets();
		centerOrigin();

		updateHitbox();
	}

	public function resetProperties()
	{
		// something something recycle no like existing properties
		this.noteData = 0;
		this.rawNoteData = 0;
		this.strumTime = 0;
		noteShit = "Normal";
		beat = 0;
		moves = false;
		luaID = 0;
		lateHitMult = 1;
		distance = 2000;
		speedMultiplier = 1.0;
		modifiedByLua = false;
		sustainLength = 0;
		insideCharter = false;
		charterSelected = false;
		earlyHitMult = 1;
		modAlpha = 1;
		alpha = 1;
		isParent = false;
		isPlayer = true;
		tooLate = false;
		canBeHit = false;
		wasGoodHit = false;
		modAngle = localAngle = originAngle = 0;
		scale.y = 0.7;
		rating = null;
		flipY = false;
		children.resize(0);
	}

	private function set_texture(value:String):String
	{
		if (texture != value)
			reloadNote(value);

		texture = value;
		return value;
	}

	private function set_noteShit(value:String):String
	{
		if (noteShit != value)
		{
			switch (value.toLowerCase())
			{
				case 'hurt':
					canPlayAnims = false;
					canNoteSplash = true;
					causesMisses = false;
					botplayHit = false;
					canRate = false;
					missHealth = 0;
					hitsoundsEditor = false;
					switch (NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin])
					{
						default:
							texture = "notetypes/hurt_Arrows";
						case "Circles":
							texture = "notetypes/hurt_Circles";
					}
				case 'isPlayer':
					set_noteShit('Must Press'); // backwards compatabilty for charts before the KEC1 format.
				case 'must press':
					canPlayAnims = true;
					canNoteSplash = true;
					botplayHit = true;
					canRate = true;
					missHealth = 0.8;
					hitsoundsEditor = true;
					switch (NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin])
					{
						default:
							texture = "notetypes/isPlayer_Arrows";
						case "Circles":
							texture = "notetypes/isPlayer_Circles";
					}
				case 'no animation':
					canPlayAnims = false;
					canNoteSplash = true;
					causesMisses = true;
					missHealth = 0.08;
					botplayHit = true;
					canRate = true;
					hitsoundsEditor = true;
				case 'gf':
					gfNote = true;
					canPlayAnims = true;
					canNoteSplash = true;
					causesMisses = true;
					missHealth = 0.08;
					botplayHit = true;
					canRate = true;
					hitsoundsEditor = true;
				default:
					canPlayAnims = true;
					canNoteSplash = true;
					causesMisses = true;
					missHealth = 0.08;
					botplayHit = true;
					canRate = true;
					hitsoundsEditor = true;
			}
			noteShit = value;
		}
		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?inCharter:Bool = false, ?isPlayer:Bool = false, ?bet:Float = 0)
	{
		super();
		setup(strumTime, noteData, isPlayer, bet);
		this.beat = bet;
	}

	static var _lastValidChecked:String; // optimization

	public function reloadNote(texture:String = '')
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
				loadGraphic(PlayState.noteskinPixelSprite, true, 17, 17);

				loadPixelAnims();
				antialiasing = false;
			default:
				frames = Paths.getSparrowAtlas(skin);
				loadNoteAnims();
				antialiasing = FlxG.save.data.antialiasing;
		}

		if (animName != null)
			animation.play(animName, true);

		if (noteTypeCheck != 'pixel')
		{
			if (animation.curAnim != null && !animation.curAnim.name.endsWith('end'))
			{
				scale.y = lastScaleY;
			}
		}

		updateHitbox();
	}

	function loadNoteAnims()
	{
		for (i in 0...4)
		{
			animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
		}
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelAnims()
	{
		for (i in 0...4)
		{
			animation.add(dataColor[i] + 'Scroll', [i + 4]); // Normal notes
		}

		setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
		updateHitbox();
	}

	override function update(elapsed:Float)
	{
		// This updates hold notes height to current scroll Speed in case of scroll Speed changes.
		super.update(elapsed);

		if (!modifiedByLua)
			angle = modAngle + localAngle;
		else
			angle = modAngle;

		if (!insideCharter)
		{
			if (isPlayer)
			{
				switch (noteShit.toLowerCase())
				{
					case 'hurt':
						if (strumTime - Conductor.songPosition <= ((Ratings.timingWindows[0].timingWindow) * 0.2)
							&& strumTime - Conductor.songPosition >= (-Ratings.timingWindows[0].timingWindow) * 0.4)
						{
							canBeHit = true;
						}
						else
						{
							canBeHit = false;
						}
						if (strumTime - Conductor.songPosition < -Ratings.timingWindows[0].timingWindow && !wasGoodHit)
							tooLate = true;
					default:
						if (strumTime - Conductor.songPosition <= (((Ratings.timingWindows[0].timingWindow) * lateHitMult))
							&& strumTime - Conductor.songPosition >= (((-Ratings.timingWindows[0].timingWindow) * earlyHitMult)))
							canBeHit = true;
						else
							canBeHit = false;
						if (strumTime - Conductor.songPosition < (-Ratings.timingWindows[0].timingWindow) && !wasGoodHit)
							tooLate = true;
				}
			}

			if (tooLate && !wasGoodHit)
			{
				if (alpha > modAlpha * 0.3)
					alpha = modAlpha * 0.3;
			}
		}
	}

	override public function destroy()
	{
		if (noteCharterObject != null)
			noteCharterObject.destroy();

		super.destroy();

		frames = null;

		_lastValidChecked = '';
	}
}
