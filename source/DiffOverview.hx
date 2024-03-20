package;

import flixel.FlxCamera;
import flixel.math.FlxRect;
import Song.SongData;
import Section.SwagSection;
import flixel.sound.FlxSound;
import flixel.input.gamepad.FlxGamepad;
import flixel.util.FlxAxes;
import flixel.FlxSubState;
import Options.Option;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.input.FlxKeyManager;

using StringTools;

class DiffOverview extends MusicBeatSubstate
{
	var blackBox:FlxSprite;

	var handOne:Array<Float>;
	var handTwo:Array<Float>;

	var giantText:FlxText;

	var SONG:SongData;
	var strumLine:FlxSprite;
	var camHUD:FlxCamera;

	var offset:FlxText;

	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];

	public static var playerStrums:FlxTypedGroup<StaticArrow> = null;

	override function create()
	{
		Conductor.songPosition = 0;
		Conductor.lastSongPos = 0;

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		var camGame = new FlxCamera();

		FlxG.cameras.add(camGame);

		FlxG.cameras.add(camHUD, false);

		playerStrums = new FlxTypedGroup<StaticArrow>();

		var currentSongData:SongData = null;
		try
		{
			currentSongData = Song.loadFromJson(FreeplayState.instance.songs[FreeplayState.curSelected].songName,
				CoolUtil.getSuffixFromDiff(CoolUtil.difficultyArray[
					CoolUtil.difficultyArray.indexOf(FreeplayState.instance.songs[FreeplayState.curSelected].diffs[FreeplayState.curDifficulty])
				]));
		}
		catch (ex)
		{
			Debug.logError(ex);
			return;
		}

		PlayState.noteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.noteskin);

		SONG = currentSongData;

		strumLine = new FlxSprite(0, (FlxG.height / 2) - 295).makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		add(strumLine);

		blackBox = new FlxSprite(0, 0).makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		blackBox.alpha = 0;
		blackBox.screenCenter();
		add(blackBox);

		handOne = DiffCalc.lastDiffHandOne;
		handTwo = DiffCalc.lastDiffHandTwo;

		generateStaticArrows(0);

		add(playerStrums);

		generateSong(SONG.songId);

		strumLine.cameras = [camHUD];
		playerStrums.cameras = [camHUD];
		notes.cameras = [camHUD];
		blackBox.cameras = [camHUD];

		blackBox.x = playerStrums.members[0].x;
		blackBox.y = strumLine.y;

		camHUD.zoom = 0.6;
		blackBox.height = camHUD.height;

		camHUD.x += 280;
		blackBox.y -= 100;
		blackBox.x -= 100;

		offset = new FlxText(10, FlxG.height
			- 40, 0,
			"Offset: "
			+ HelperFunctions.truncateFloat(FlxG.save.data.offset, 0)
			+ " (LEFT/RIGHT to decrease/increase)", 16);
		offset.setBorderStyle(FlxTextBorderStyle.OUTLINE, FlxColor.BLACK, 4, 1);
		offset.color = FlxColor.WHITE;
		offset.scrollFactor.set();
		add(offset);

		FlxTween.tween(blackBox, {alpha: 0.9}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(camHUD, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});
		FlxTween.tween(offset, {alpha: 1}, 0.5, {ease: FlxEase.expoInOut});

		trace('pog');

		super.create();
	}

	function generateStaticArrows(player:Int, ?tween:Bool = true):Void
	{
		for (i in 0...4)
		{
			var babyArrow:StaticArrow = new StaticArrow(-10, strumLine.y, player, i);

			var noteTypeCheck:String = 'normal';
			babyArrow.downScroll = FlxG.save.data.downscroll;

			babyArrow.loadLane();

			babyArrow.x += Note.swagWidth * i;

			babyArrow.updateHitbox();
			babyArrow.scrollFactor.set();

			if (tween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;
				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: 1}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else
				babyArrow.alpha = 1;

			babyArrow.ID = i;

			babyArrow.x += 20;
			playerStrums.add(babyArrow);

			babyArrow.playAnim('static');
			babyArrow.x += 98.5; // Tryna make it not offset because it was pissing me off + Psych Engine has it somewhat like this.
			babyArrow.x += ((FlxG.width / 2) * player);
		}
	}

	function endSong()
	{
		if (stopDoingShit)
			return;
	}

	function resyncVocals():Void
	{
		FlxG.sound.music.pause();
		FlxG.sound.music.resume();
		FlxG.sound.music.time = Conductor.songPosition * FreeplayState.rate;
		if (!SONG.splitVoiceTracks)
		{
			if (!vocals.playing || vocals.time != Conductor.songPosition * FreeplayState.rate)
			{
				vocals.pause();

				if (!(vocals.length < FlxG.sound.music.time))
				{
					vocals.play();

					vocals.time = Conductor.songPosition * FreeplayState.rate;
				}
			}
		}
		else
		{
			if (!vocalsPlayer.playing || vocalsPlayer.time != Conductor.songPosition * FreeplayState.rate)
			{
				vocalsPlayer.pause();

				if (!(vocalsPlayer.length < FlxG.sound.music.time))
				{
					vocalsPlayer.play();

					vocalsPlayer.time = Conductor.songPosition * FreeplayState.rate;
				}
			}

			if (!vocalsEnemy.playing || vocalsEnemy.time != Conductor.songPosition * FreeplayState.rate)
			{
				vocalsEnemy.pause();

				if (!(vocalsEnemy.length < FlxG.sound.music.time))
				{
					vocalsEnemy.play();

					vocalsEnemy.time = Conductor.songPosition * FreeplayState.rate;
				}
			}
		}

		if (FlxG.sound.music.playing)
		{
			FlxG.sound.music.pitch = FreeplayState.rate;
			if (!SONG.splitVoiceTracks)
			{
				if (vocals.playing)
					vocals.pitch = FreeplayState.rate;
			}
			else
			{
				if (vocalsPlayer.playing && vocalsEnemy.playing)
				{
					vocalsPlayer.pitch = FreeplayState.rate;
					vocalsEnemy.pitch = FreeplayState.rate;
				}
			}
		}
	}

	public var stopDoingShit = false;

	override function stepHit()
	{
		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20)
		{
			trace("resync");
			resyncVocals();
		}
	}

	function offsetChange()
	{
		for (i in unspawnNotes)
			i.strumTime = i.baseStrum + FlxG.save.data.offset;
		for (i in notes)
			i.strumTime = i.baseStrum + FlxG.save.data.offset;
	}

	var frames = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// input

		if (frames < 10)
		{
			frames++;
			return;
		}

		if (stopDoingShit)
			return;

		if (FlxG.keys.pressed.O)
		{
			stopDoingShit = true;
			quit();
		}

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
			if (gamepad.justPressed.X)
			{
				stopDoingShit = true;
				quit();
			}

		/*if (FlxG.keys.pressed.RIGHT)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					FlxG.save.data.offset++;
					offsetChange();
				}
			}
			if (FlxG.keys.pressed.LEFT)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					FlxG.save.data.offset--;
					offsetChange();
				}
			}

			if (FlxG.keys.justPressed.RIGHT)
			{
				FlxG.save.data.offset++;
				offsetChange();
			}
			if (FlxG.keys.justPressed.LEFT)
			{
				FlxG.save.data.offset--;
				offsetChange();
			}


			offset.text = "Offset: " + HelperFunctions.truncateFloat(FlxG.save.data.offset,0) + " (LEFT/RIGHT to decrease/increase, SHIFT to go faster) - Time: " + HelperFunctions.truncateFloat(Conductor.songPosition / 1000,0) + "s - Step: " + currentStep;
		 */

		if (vocals != null)
			if (vocals.playing)
				Conductor.songPosition += FlxG.elapsed * 1000;

		if (unspawnNotes[0] != null)
		{
			if (unspawnNotes[0].strumTime - Conductor.songPosition < 3500)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.add(dunceNote);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		notes.forEachAlive(function(daNote:Note)
		{
			// instead of doing stupid y > FlxG.height
			// we be men and actually calculate the time :)
			if (daNote.tooLate)
			{
				daNote.active = false;
				daNote.visible = false;
			}
			else
			{
				daNote.visible = true;
				daNote.active = true;
			}

			daNote.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y
				- 0.45 * (Conductor.songPosition - daNote.strumTime) * FlxMath.roundDecimal(SONG.speed, 2));

			if (daNote.isSustainNote)
			{
				daNote.y -= daNote.height / 2;

				if ((!daNote.mustPress || daNote.wasGoodHit || daNote.prevNote.wasGoodHit && !daNote.canBeHit)
					&& daNote.y + daNote.offset.y * daNote.scale.y <= (strumLine.y + Note.swagWidth / 2))
				{
					// Clip to strumline
					var swagRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
					swagRect.y = (playerStrums.members[Math.floor(Math.abs(daNote.noteData))].y + Note.swagWidth / 2 - daNote.y) / daNote.scale.y;
					swagRect.height -= swagRect.y;

					daNote.clipRect = swagRect;
				}
			}

			daNote.visible = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].visible;
			daNote.x = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].x;
			if (!daNote.isSustainNote)
				daNote.angle = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].angle;
			daNote.alpha = playerStrums.members[Math.floor(Math.abs(daNote.noteData))].alpha;

			// auto hit

			if (daNote.y < strumLine.y)
			{
				// Force good note hit regardless if it's too late to hit it or not as a fail safe
				if (daNote.canBeHit && daNote.mustPress || daNote.tooLate && daNote.mustPress)
				{
					daNote.wasGoodHit = true;
					vocals.volume = 1;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			}
		});
	}

	function quit()
	{
		FlxTween.tween(blackBox, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(camHUD, {alpha: 0}, 1, {ease: FlxEase.expoInOut});
		FlxTween.tween(offset, {alpha: 0}, 1, {ease: FlxEase.expoInOut});

		FreeplayState.openedPreview = false;

		vocals.fadeOut();
		FlxG.sound.music.fadeOut(1, 0, function(twn:FlxTween)
		{
			FlxG.sound.playMusic(Paths.music(FlxG.save.data.watermark ? "freakyMenu" : "ke_freakyMenu"));
			MainMenuState.freakyPlaying = true;
			closeSubState();
		});
	}

	var vocals:FlxSound;
	var vocalsPlayer:FlxSound;
	var vocalsEnemy:FlxSound;

	var notes:FlxTypedGroup<Note>;
	var unspawnNotes:Array<Note> = [];

	public function generateSong(dataPath:String):Void
	{
		// FlxG.log.add(ChartParser.parse());

		var songData = SONG;

		Conductor.changeBPM(songData.bpm);

		if (!SONG.splitVoiceTracks)
		{
			if (SONG.needsVoices)
				vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile));
			else
				vocals = new FlxSound();

			if (FlxG.save.data.gen)
				trace('loaded vocals');

			FlxG.sound.list.add(vocals);
		}
		else
		{
			if (SONG.needsVoices)
			{
				vocalsPlayer = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'P'));
				vocalsEnemy = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'E'));
			}
			else
			{
				vocalsEnemy = new FlxSound();
				vocalsPlayer = new FlxSound();
			}

			if (FlxG.save.data.gen)
				trace('loaded vocals');

			FlxG.sound.list.add(vocalsPlayer);
			FlxG.sound.list.add(vocalsEnemy);
		}

		Conductor.bpm = SONG.bpm * FreeplayState.rate;

		Conductor.crochet = ((60 / (SONG.bpm * FreeplayState.rate) * 1000));
		Conductor.stepCrochet = Conductor.crochet / 4;

		PlayState.instance.fakeCrochet = Conductor.crochet;
		PlayState.instance.fakeNoteStepCrochet = PlayState.instance.fakeCrochet / 4;
		// recalculateAllSectionTimes();

		notes = new FlxTypedGroup<Note>();
		add(notes);

		var noteData:Array<SwagSection>;

		// NEW SHIT
		noteData = songData.notes;

		var playerCounter:Int = 0;

		var daBeats:Int = 0; // Not exactly representative of 'daBeats' lol, just how much it has looped
		for (section in noteData)
		{
			var coolSection:Int = Std.int(section.lengthInSteps / 4);

			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = (songNotes[0] - FlxG.save.data.offset - SONG.offset) / FreeplayState.rate;
				if (daStrumTime < 0)
					daStrumTime = 0;
				var daNoteData:Int = Std.int(songNotes[1] % 4);
				var daNoteType:String = songNotes[5];
				var daBeat = TimingStruct.getBeatFromTime(daStrumTime);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3 && !PlayStateChangeables.opponentMode)
					gottaHitNote = !section.mustHitSection;
				else if (songNotes[1] <= 3 && PlayStateChangeables.opponentMode)
					gottaHitNote = !section.mustHitSection;

				var oldNote:Note;
				if (unspawnNotes.length > 0)
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				else
					oldNote = null;

				var swagNote = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote, daBeat);
				swagNote.noteShit = daNoteType;

				if (PlayStateChangeables.holds)
				{
					swagNote.sustainLength = songNotes[2] / FreeplayState.rate;
				}
				else
				{
					swagNote.sustainLength = 0;
				}

				swagNote.scrollFactor.set(0, 0);

				var susLength:Float = swagNote.sustainLength;

				var anotherCrochet:Float = Conductor.crochet;
				var anotherStepCrochet:Float = anotherCrochet / 4;
				susLength = susLength / anotherStepCrochet;

				unspawnNotes.push(swagNote);

				var type = 0;

				if (susLength > 0)
				{
					swagNote.isParent = true;
					for (susNote in 0...Std.int(Math.max(susLength, 2)))
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
						var sustainNote = new Note(daStrumTime + (anotherStepCrochet * susNote) + anotherStepCrochet, daNoteData, oldNote, true, false,
							gottaHitNote, 0);

						sustainNote.noteShit = daNoteType;

						sustainNote.scrollFactor.set();
						unspawnNotes.push(sustainNote);

						sustainNote.mustPress = gottaHitNote;

						sustainNote.parent = swagNote;
						swagNote.children.push(sustainNote);
						sustainNote.spotInLine = type;
						type++;
					}
				}

				swagNote.mustPress = gottaHitNote;

				if (swagNote.mustPress)
				{
					swagNote.x += FlxG.width / 2; // general offset
				}
			}
			daBeats += 1;
		}

		// trace(unspawnNotes.length);
		// playerCounter += 1;

		unspawnNotes.sort(sortByShit);

		Conductor.changeBPM(SONG.bpm);

		FlxG.sound.playMusic(Paths.inst(SONG.songId), 1, false);
		FlxG.sound.music.onComplete = endSong;
		vocals.play();
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}
}
