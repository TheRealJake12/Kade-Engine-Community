package;

import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import PlayState;
import LuaClass;
import flixel.math.FlxRect;

using StringTools;

class Note extends FlxSprite
{
	public var strumTime:Float = 0;
	public var baseStrum:Float = 0;
	public var lateHitMult:Float = 1.0;
	public var earlyHitMult:Float = 1.0;

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

	public var noteShit:String = 'normal';
	public var canPlayAnims:Bool = false; // if a note plays the sing animations
	public var canNoteSplash:Bool = true; // if a note can notesplash on Sick! and Marv!
	public var causesMisses:Bool = true; // if a note will do noteMiss or something.

	public var luaID:Int = 0;

	public var isAlt:Bool = false;

	public var noteCharterObject:FlxSprite;

	public var noteScore:Float = 1;

	public var noteYOff:Float = 0;

	public var beat:Float = 0;

	public static var swagWidth:Float = 160 * 0.7;
	public static var PURP_NOTE:Int = 0;
	public static var GREEN_NOTE:Int = 2;
	public static var BLUE_NOTE:Int = 1;
	public static var RED_NOTE:Int = 3;

	public var rating:String = "shit";

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)

	public var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	public var quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, GREEN_NOTE, 2];
	public var arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var isParent:Bool = false;
	public var parent:Note = null;
	public var spotInLine:Int = 0;
	public var sustainActive:Bool = true;

	public var children:Array<Note> = [];

	public var stepHeight:Float = 0;

	public var distance:Float = 2000;
	public var speedMultiplier:Float = 1.0;
	public var overrideDistance:Bool = false; // Set this to true if you know what are you doing.

	#if FEATURE_LUAMODCHART
	public var LuaNote:LuaNote;
	#end

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false, ?inCharter:Bool = false, ?isPlayer:Bool = false,
			?isAlt:Bool = false, ?bet:Float = 0, ?noteShit:String = 'normal', ?speedMultiplier:Float = 1.0)
	{
		super();

		if (noteShit == null || noteShit == '0' || noteShit == 'false' || noteShit == 'true')
			noteShit = 'normal';
		this.noteShit = noteShit; // FFFFFFFFFFFFFFFFFFFFFFUUUUUUUUUUUUUUUUUUUUUUUUUUUU
		if (prevNote == null)
			prevNote = this;

		this.speedMultiplier = speedMultiplier;
		beat = bet;
		this.isAlt = isAlt;

		this.prevNote = prevNote;
		isSustainNote = sustainNote;
		moves = false;
		lateHitMult = isSustainNote ? 0.5 : 1;

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
			#if FEATURE_STEPMANIA
			if (PlayState.isSM)
			{
				rStrumTime = strumTime;
			}
			else
				rStrumTime = strumTime;
			#else
			rStrumTime = strumTime;
			#end
		}

		if (this.strumTime < 0)
			this.strumTime = 0;

		this.noteData = noteData;

		if (PlayStateChangeables.mirrorMode)
		{
			this.noteData = Std.int(Math.abs(3 - noteData));
			noteData = Std.int(Math.abs(3 - noteData));
		}

		// le note shit behaviour
		switch (noteShit)
		{
			case 'hurt':
				canPlayAnims = false;
				canNoteSplash = false;
				causesMisses = false;
			case 'mustpress':
				canPlayAnims = false;
				canNoteSplash = false;
			default:
				canPlayAnims = true;
				canNoteSplash = true;
				causesMisses = true;
		}

		var daStage:String = ((PlayState.instance != null && !PlayStateChangeables.Optimize) ? PlayState.instance.Stage.curStage : 'stage');

		// defaults if no noteStyle was found in chart
		var noteTypeCheck:String = 'normal';

		if (inCharter)
		{
			switch (noteShit)
			{
				case 'hurt':
					{
						frames = Paths.getSparrowAtlas("notetypes/type1", 'shared');
						for (i in 0...4)
						{
							animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
							animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
							animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
						}
					}
				case 'mustpress':
					frames = Paths.getSparrowAtlas("notetypes/type2", 'shared');
					for (i in 0...4)
					{
						animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
						animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
						animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
					}
				default:
					{
						frames = PlayState.noteskinSprite;
						for (i in 0...4)
						{
							animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
							animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + '0'); // Normal notes old

							animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
							animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold piece'); // Hold old

							animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
							animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' hold end'); // Tails old

							animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?

							// For Legacy Noteskins.
						}
					}
			}

			setGraphicSize(Std.int(width * 0.7));
			updateHitbox();
			antialiasing = FlxG.save.data.antialiasing;
		}
		else
		{
			if (PlayState.SONG.noteStyle == null)
			{
				switch (PlayState.storyWeek)
				{
					case 6:
						noteTypeCheck = 'pixel';
				}
			}
			else
			{
				noteTypeCheck = PlayState.SONG.noteStyle;
			}

			switch (noteTypeCheck)
			{
				case 'pixel':
					switch (noteShit)
					{
						case 'hurt':
							{
								frames = Paths.getSparrowAtlas("notetypes/type1", 'shared');
								for (i in 0...4)
								{
									animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
									animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
									animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
								}
								setGraphicSize(Std.int(width / 1.5));
								updateHitbox();
							}

						case 'mustpress':
							{
								frames = Paths.getSparrowAtlas("notetypes/type2", 'shared');
								for (i in 0...4)
								{
									animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
									animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
									animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
								}
								setGraphicSize(Std.int(width / 1.5));
								updateHitbox();
							}
						default:
							#if html5
							loadGraphic(Paths.image('noteskins/Arrows-pixel', 'shared'), true, 12, 12);
							if (isSustainNote)
								loadGraphic(Paths.image('noteskins/Arrows-pixel-ends', 'shared'), true, 7, 6);
							#else
							loadGraphic(PlayState.noteskinPixelSprite, true, 17, 17);
							if (isSustainNote)
								loadGraphic(PlayState.noteskinPixelSpriteEnds, true, 7, 6);
							#end
							for (i in 0...4)
							{
								animation.add(dataColor[i] + 'Scroll', [i + 4]); // Normal notes
								animation.add(dataColor[i] + 'hold', [i]); // Holds
								animation.add(dataColor[i] + 'holdend', [i + 4]); // Tails
							}

							setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
							updateHitbox();
					}

				default:
					switch (noteShit)
					{
						case 'hurt':
							{
								frames = Paths.getSparrowAtlas("notetypes/type1", 'shared');
								for (i in 0...4)
								{
									animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
									animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
									animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
								}
							}

						case 'mustpress':
							frames = Paths.getSparrowAtlas("notetypes/type2", 'shared');
							for (i in 0...4)
							{
								animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
								animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
								animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
							}
						default:
							{
								if (isPlayer)
									frames = PlayState.noteskinSprite;
								else
									frames = PlayState.cpuNoteskinSprite;
								for (i in 0...4)
								{
									animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + ' alone'); // Normal notes
									animation.addByPrefix(dataColor[i] + 'Scroll', dataColor[i] + '0'); // Normal notes old

									animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold'); // Hold
									animation.addByPrefix(dataColor[i] + 'hold', dataColor[i] + ' hold piece'); // Hold old

									animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' tail'); // Tails
									animation.addByPrefix(dataColor[i] + 'holdend', dataColor[i] + ' hold end'); // Tails old

									animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?

									// For Legacy Noteskins.
								}
							}
					}

					setGraphicSize(Std.int(width * 0.7));
					updateHitbox();

					antialiasing = FlxG.save.data.antialiasing;
			}
		}

		x += swagWidth * noteData;
		animation.play(dataColor[noteData] + 'Scroll');
		originColor = noteData; // The note's origin color will be checked by its sustain notes

		if (FlxG.save.data.stepMania && !isSustainNote && !(PlayState.instance != null ? PlayState.instance.executeModchart : false))
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

			animation.play(dataColor[col] + 'Scroll');

			originColor = col;

			if (FlxG.save.data.rotateSprites) // ok honestly who the fuck wanted this. Im keeping it for a challenge but what the fuck
			{
				localAngle -= arrowAngles[col];
				localAngle += arrowAngles[noteData];
				originAngle = localAngle;
			}
		}

		if (isSustainNote && prevNote != null)
		{
			stepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
				2) * speedMultiplier);
			noteYOff = -stepHeight + swagWidth * 0.5;

			noteScore * 0.2;
			alpha = FlxG.save.data.alpha;

			if (FlxG.save.data.downscroll)
				flipY = true;

			x += width / 2;

			originColor = prevNote.originColor;
			originAngle = prevNote.originAngle;

			animation.play(dataColor[originColor] + 'holdend'); // This works both for normal colors and quantization colors
			updateHitbox();

			x -= width / 2;

			// if (noteTypeCheck == 'pixel')
			//	x += 30;

			if (inCharter)
				x += 30;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(dataColor[prevNote.originColor] + 'hold');
				prevNote.updateHitbox();

				prevNote.scale.y *= stepHeight / prevNote.height;
				prevNote.updateHitbox();

				if (antialiasing)
					switch (FlxG.save.data.noteskin)
					{
						case 0:
							prevNote.scale.y *= 1.0064 + (1.0 / prevNote.frameHeight);
						default:
							prevNote.scale.y *= 0.995 + (1.0 / prevNote.frameHeight);
					}
				prevNote.updateHitbox();
				updateHitbox();
			}
		}
	}

	override function update(elapsed:Float)
	{
		// This updates hold notes height to current scroll Speed in case of scroll Speed changes.
		super.update(elapsed);

		var newStepHeight = (((0.45 * PlayState.instance.fakeNoteStepCrochet)) * FlxMath.roundDecimal(PlayState.instance.scrollSpeed == 1 ? PlayState.SONG.speed : PlayState.instance.scrollSpeed,
			2) * speedMultiplier);

		if (stepHeight != newStepHeight)
		{
			stepHeight = newStepHeight;
			if (isSustainNote)
			{
				noteYOff = -stepHeight + swagWidth * 0.5;
			}
		}

		if (!isSustainNote)
		{
			if (!modifiedByLua)
				angle = modAngle + localAngle;
			else
				angle = modAngle;
		}

		if (!modifiedByLua)
		{
			if (!sustainActive)
			{
				alpha = FlxG.save.data.alpha - 0.3;
			}
		}

		if (mustPress)
		{
			switch (noteShit)
			{
				case 'hurt':
					if (strumTime - Conductor.songPosition <= ((Ratings.timingWindows[0]) * 0.2)
						&& strumTime - Conductor.songPosition >= (-Ratings.timingWindows[0]) * 0.4)
					{
						canBeHit = true;
					}
					else
					{
						canBeHit = false;
					}
					if (strumTime - Conductor.songPosition < -Ratings.timingWindows[0] && !wasGoodHit)
						tooLate = true;
				default:
					if (strumTime - Conductor.songPosition <= (((Ratings.timingWindows[0]) * lateHitMult))
						&& strumTime - Conductor.songPosition >= (((-Ratings.timingWindows[0]) * earlyHitMult)))
						canBeHit = true;
			}
			/*if (strumTime - Conductor.songPosition < (-166 * Conductor.timeScale) && !wasGoodHit)
				tooLate = true; */
		}
		else
		{
			canBeHit = false;
			// if (strumTime <= Conductor.songPosition)
			//	wasGoodHit = true;
		}

		if (tooLate && !wasGoodHit)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
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
