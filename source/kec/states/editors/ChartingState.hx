package kec.states.editors;

import haxe.ui.backend.flixel.UIState;
import kec.objects.editor.TextLine;
import kec.objects.editor.EditorSustain;
import kec.backend.HitSounds;
import kec.backend.PlayStateChangeables;
import kec.backend.chart.Event;
import kec.backend.chart.ChartData;
import kec.backend.chart.Song;
import kec.backend.chart.TimingStruct;
import kec.util.HelperFunctions;
import kec.util.NoteStyleHelper;
import kec.util.Sort;
import kec.backend.character.CharacterData;
import kec.objects.menu.CoolText;
import kec.objects.game.note.Note;
import kec.objects.game.HealthIcon;
import kec.objects.editor.ChartingBox;
import openfl.Lib;
import openfl.events.Event as OpenFlEvent;
import openfl.events.IOErrorEvent;
import kec.backend.chart.ChartNote;
import kec.backend.chart.Section;
import kec.objects.editor.EditorNote;
import kec.objects.editor.EditorGrid;
import kec.objects.editor.BeatLine;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.focus.FocusManager;
import flixel.util.FlxSort;
import kec.util.FileDialogHandler;
import haxe.ui.events.UIEvent;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end

@:build(haxe.ui.ComponentBuilder.build("assets/shared/data/editors/charter.xml"))
class ChartingState extends UIState
{
	public static var instance:ChartingState = null;

	public var SONG:ChartData;

	public var lastUpdatedSection:Section = null;

	public static final gridSize:Int = 45; // scale? GRID_SIZE?
	public static final separatorWidth:Int = 4;

	public static var lengthInSteps:Int = 0;
	public static var lengthInBeats:Int = 0;
	public static var lengthInSections:Int = 0;

	public var quantList:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
	public var curQuant = 3; // 16
	public var curType = 0;

	private var sustainQuant:Float = 1.0;

	public var waitingForRelease:Bool = false;

	private var maxBeat = 0;
	private var maxSectionIndex:Int = 0;

	public var end:Float = 1.0;

	private var paused(default, set):Bool = true;

	public var pitch:Float = 1.0;

	private var lastConductorPos:Float;
	private var snap:Bool = true;

	private var strumLine:FlxSprite;
	private var mouse:FlxSprite;

	public var selectBox:FlxSprite;

	private var curSelectedNote:ChartNote;
	private var curEvent:Event;

	var eventList:Array<Event> = []; // existing events
	var eventIndex:Int = 0;
	var existingEvents = new ArrayDataSource<String>(); // bullshit

	private var noteGroup:FlxTypedSpriteGroup<EditorNote>;
	private var sustainGroup:FlxTypedSpriteGroup<EditorSustain>;

	private var texts:FlxTypedGroup<TextLine>;
	private var lines:FlxTypedGroup<BeatLine>;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;
	public var curSelectedNoteObject:EditorNote = null;

	public var infoText:CoolText;

	private var grid:EditorGrid;

	public var infoBG:FlxSprite;
	public var notetypetext:CoolText;
	public var helpText:CoolText;

	private var iconP1:HealthIcon;
	private var iconP2:HealthIcon;

	private var inst:FlxSound;
	private var vocals:FlxSound;
	private var vocalsP:FlxSound;
	private var vocalsE:FlxSound;
	private var hitsound:FlxSound;
	private var metronome:FlxSound;

	private var noteCam:FlxCamera;
	private var uiCam:FlxCamera;

	private var player:CharacterData;
	private var opponent:CharacterData;
	var curDiff:String = "";

	public var selectInitialX:Float = 0;
	public var selectInitialY:Float = 0;

	private var noteTypes:Array<String> = null;

	public var id:Int = -1;

	private var noteCounter:Int = 0;

	private var maxNotes:Int = 0;
	private var unspawnNotes:Array<ChartNote> = [];

	var fileDialog:FileDialogHandler = new FileDialogHandler();

	// one does not realize how much flixel-ui is used until one sees an FNF chart editor. 💀

	/*
		>new chart editor
		>looks inside
		>kade engine chart editor
	 */
	override function create()
	{
		instance = this;
		FlxG.mouse.visible = true;

		lines = new FlxTypedGroup<BeatLine>();
		texts = new FlxTypedGroup<TextLine>();

		noteGroup = new FlxTypedSpriteGroup<EditorNote>();
		sustainGroup = new FlxTypedSpriteGroup<EditorSustain>();

		noteCam = FlxG.camera;
		uiCam = new FlxCamera();
		uiCam.bgColor.alpha = 0;
		FlxG.cameras.add(uiCam, false);

		if (FlxG.save.data.hitSound == 0)
			hitsound = FlxG.sound.load(Paths.sound('hitsounds/snap'));
		else
			hitsound = FlxG.sound.load(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}'));

		hitsound.autoDestroy = false;
		metronome = FlxG.sound.load(Paths.sound('metronome'));
		metronome.autoDestroy = false;

		super.create();

		PlayState.inDaPlay = false;
		SONG = PlayState.SONG;
		loadAudio(SONG.songId, false);

		inst.time = 0;
		Conductor.rate = 1;
		Conductor.bpm = SONG.eventObjects[0].args[0];
		TimingStruct.setSongTimings(SONG);
		Song.checkforSections(SONG, inst.length);
		Song.recalculateAllSectionTimes(SONG);
		calculateMaxBeat();
		checkforSections();
		setInitVars();

		for (sec in SONG.notes)
			for (i in sec.sectionNotes)
			{
				unspawnNotes.push(i);
				maxNotes++;
			}

		Debug.logTrace(maxNotes);

		activeSong = SONG;
		curEvent = SONG.eventObjects[0];
		Debug.logTrace('${TimingStruct.AllTimings.length} ${curTiming.endBeat}');
		lengthInBeats = Math.round(TimingStruct.getBeatFromTime(inst.length));
		lengthInSteps = lengthInBeats * 4;
		lengthInSections = Std.int(lengthInBeats / 4);
		Debug.logTrace('Total Beats ${lengthInBeats}. Total Steps ${lengthInSteps}. Length In Sections ${lengthInSections}');
		currentSection = getSectionByTime(0);

		curSection = 0;

		curDiff = CoolUtil.difficulties[PlayState.storyDifficulty];
		Constants.noteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.noteskin);
		Constants.cpuNoteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		Constants.noteskinPixelSprite = NoteStyleHelper.generatePixelSprite(FlxG.save.data.noteskin);

		noteTypes = CoolUtil.coolTextFile(Paths.txt('data/noteTypeList'));

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF333333;
		add(bg);
		createGrid();

		regenerateLines();

		end = getYFromTime(inst.length);

		player = new CharacterData(SONG.player1, true);
		opponent = new CharacterData(SONG.player2, false);

		iconP2 = new HealthIcon(opponent.icon, false);
		iconP1 = new HealthIcon(player.icon, true);
		iconP1.allowedToBop = iconP2.allowedToBop = true;

		iconP1.size.set(0.75, 0.75);
		iconP2.size.set(0.75, 0.75);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		iconP1.setPosition(850, 35);
		iconP2.setPosition(300, 35);

		infoText = new CoolText(970, 40, 16, 16, Paths.bitmapFont('fonts/vcr'));
		infoText.autoSize = true;
		infoText.antialiasing = true;
		infoText.updateHitbox();
		infoText.scrollFactor.set();

		infoBG = new FlxSprite(infoText.x - 5, infoText.y - 10).makeGraphic(335, 240, FlxColor.fromRGB(35, 35, 35));
		infoBG.scrollFactor.set();

		notetypetext = new CoolText(970, infoText.y + 200, 20, 20, Paths.bitmapFont('fonts/vcr'));
		notetypetext.autoSize = true;
		notetypetext.antialiasing = true;
		notetypetext.updateHitbox();
		notetypetext.scrollFactor.set();

		helpText = new CoolText(985, 485, 12, 12, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.antialiasing = true;
		helpText.text = "Help:" + "\n" + "CTRL-Left/Right : Change playback speed" + "\n" + "Ctrl+Drag Click : Select notes" + "\n" + "Ctrl+C : Copy notes"
			+ "\n" + "Ctrl+V : Paste notes" + "\n" + "Ctrl+Z : Undo" + "\n" + "Ctrl+BACKSPACE : Delete Selected Notes" + "\n"
			+ "Alt+Left/Right : Change Quant" + "\n" + "Tab : Disable/Enable Quant" + "\n" + "Click : Place notes" + "\n" + "Up/Down : Move selected notes"
			+ "\n" + "Space : Play Song" + "\n" + "W-S : Go To Previous / Next Section" + "\n" + "Q-E : Change Sustain Amount" + "\n"
			+ "C-V : Change Sustain Change Quant" + "\n" + "Enter : Load Song Into PlayState" + "\n" + "Z/X Change Notetype." + "\n"
			+ "Press F1 to show/hide help text.";
		helpText.updateHitbox();
		helpText.scrollFactor.set();
		helpText.visible = FlxG.save.data.showHelp;

		add(lines);
		add(texts);

		add(noteGroup);
		add(sustainGroup);
		add(strumLine);
		add(mouse);

		add(iconP1);
		add(iconP2);

		selectedBoxes = new FlxTypedGroup();
		add(selectedBoxes);

		add(infoBG);
		add(infoText);

		updateNotetypeText();
		add(notetypetext);
		add(helpText);

		selectBox = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
		selectBox.visible = false;
		selectBox.alpha = 0.4;
		add(selectBox);

		id = Lib.setInterval(backupChart, 5 * 60 * 1000);

		#if FEATURE_DISCORD
		kec.backend.Discord.changePresence("Chart Editor", "Charting : " + SONG.songName, null, true);
		#end

		initHUI();

		root.camera = uiCam;
	}

	var updateFrame = 0;

	override function update(elapsed:Float)
	{
		if (inst != null)
		{
			if (inst.time >= inst.length - 85)
			{
				inst.time = 0;
				Conductor.songPosition = 0;
				inst.pause();
				if (!SONG.splitVoiceTracks)
				{
					vocals.time = inst.time;
					vocals.pause();
				}
				else
				{
					vocalsP.time = inst.time;
					vocalsE.time = inst.time;
					vocalsP.pause();
					vocalsE.pause();
				}
				recalculateAllSectionTimes();
			}
			if (inst.playing)
			{
				inst.pitch = pitch;
				try
				{
					// We need to make CERTAIN vocals exist and are non-empty
					// before we try to play them. Otherwise the game crashes.
					if (!SONG.splitVoiceTracks)
					{
						if (vocals != null && vocals.length > 0)
							vocals.pitch = pitch;
					}
					else
					{
						if (vocalsP != null && vocalsP.length > 0)
							vocalsP.pitch = pitch;

						if (vocalsE != null && vocalsE.length > 0)
							vocalsE.pitch = pitch;
					}
				}
				catch (e)
				{
					Debug.logTrace("failed to pitch vocals (probably cuz they don't exist)");
				}
			}
			Conductor.songPosition = inst.time;
		}

		// final lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 12), 0, 1);
		// strumLine.y = FlxMath.lerp(getYFromTime(inst.time), strumLine.y, lerpVal);
		strumLine.y = getYFromTime(Conductor.songPosition);
		var diffX:Float = FlxG.mouse.x - grid.x;
		mouse.x = grid.x + Math.floor(diffX / gridSize) * gridSize;
		mouse.y = FlxMath.bound(getMouseY(), 0, end - gridSize);
		mouse.visible = mouseValid();

		if (FlxG.mouse.justPressed && !waitingForRelease)
		{
			if (!FlxG.keys.pressed.CONTROL && mouse.visible)
				checkNoteSpawn();
		}

		if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL)
		{
			if (!waitingForRelease)
			{
				destroyBoxes();

				waitingForRelease = true;
				selectBox.setPosition(FlxG.mouse.x, FlxG.mouse.y);
				selectBox.setGraphicSize(1, 1);
				selectBox.updateHitbox();
				selectInitialX = selectBox.x;
				selectInitialY = selectBox.y;
				selectBox.visible = true;
			}
			else
			{
				if (waitingForRelease)
				{
					selectBox.x = Math.min(FlxG.mouse.x, selectInitialX);
					selectBox.y = Math.min(FlxG.mouse.y, selectInitialY);
					selectBox.scale.x = Math.floor(Math.abs(FlxG.mouse.x - selectInitialX));
					selectBox.scale.y = Math.floor(Math.abs(FlxG.mouse.y - selectInitialY));
					selectBox.updateHitbox();
					selectBox.visible = true;
				}
			}
		}
		if (FlxG.mouse.justReleased && waitingForRelease)
		{
			waitingForRelease = false;
			noteGroup.forEachAlive(function(n:EditorNote)
			{
				if (n.overlaps(selectBox) && !n.selected)
					selectNote(n);
			});
			selectBox.visible = false;
		}

		if (FocusManager.instance.focus == null)
		{
			if (FlxG.keys.justPressed.F1)
			{
				FlxG.save.data.showHelp = !FlxG.save.data.showHelp;
				helpText.visible = FlxG.save.data.showHelp;
			}

			if (FlxG.keys.justPressed.TAB)
				snap = !snap;

			if (FlxG.keys.justPressed.F2)
				backupChart();

			if (FlxG.keys.justPressed.E)
				changeNoteSustain(Conductor.stepCrochet * sustainQuant);
			if (FlxG.keys.justPressed.Q)
				changeNoteSustain(-Conductor.stepCrochet * sustainQuant);

			if ((FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT) && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
				goToSection(curSection - 1);
			else if ((FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT) && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
				goToSection(curSection + 1);

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.BACKSPACE)
				selectedBoxes.forEachAlive(function(b:ChartingBox)
				{
					deleteNote(b.connectedNote, false);
					b.connectedNote.selected = false;
					b.kill();
				});

			if (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.LEFT)
			{
				curQuant--;
				if (curQuant < 0)
					curQuant = quantList.length - 1;
			} // fard

			if (FlxG.keys.pressed.ALT && FlxG.keys.justPressed.RIGHT)
			{
				curQuant++;
				if (curQuant > quantList.length - 1)
					curQuant = 0;
			}

			if (FlxG.keys.justPressed.C)
			{
				if (sustainQuant > 0.1)
					sustainQuant -= 0.1;
			}
			if (FlxG.keys.justPressed.V)
			{
				if (sustainQuant < 3) // realistically, why would you need anything higher than 2.
					sustainQuant += 0.1;
			}

			if (FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
			{
				var offsetSteps = FlxG.keys.pressed.CONTROL ? 16 : 1;
				var offsetSeconds = Conductor.stepCrochet * offsetSteps;

				var offset:Float = 0;
				if (FlxG.keys.justPressed.UP)
					offset -= offsetSeconds;
				if (FlxG.keys.justPressed.DOWN)
					offset += offsetSeconds;

				if (selectedBoxes.members.length > 0)
					offsetSelectedNotes(offset);
			}

			if (FlxG.keys.pressed.CONTROL)
			{
				if (FlxG.keys.justPressed.RIGHT)
					pitch += 0.05;
				else if (FlxG.keys.justPressed.LEFT)
					pitch -= 0.05;

				if (pitch > 3)
					pitch = 3;
				if (pitch <= 0.05)
					pitch = 0.05;
			}

			if (!FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
			{
				curType--;
				if (curType < 0)
					curType = noteTypes.length - 1;
				updateNotetypeText();
			}

			if (!FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
			{
				curType++;
				if (curType > noteTypes.length - 1)
					curType = 0;
				updateNotetypeText();
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				PlayState.SONG = SONG;
				inst.stop();
				try
				{
					if (!SONG.splitVoiceTracks)
						vocals.stop();
					else
					{
						vocalsP.stop();
						vocalsE.stop();
					}
				}
				setSongData();
				MusicBeatState.switchState(new PlayState());
				Lib.clearInterval(id);
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				PlayState.SONG = SONG;
				inst.stop();
				try
				{
					if (!SONG.splitVoiceTracks)
						vocals.stop();
					else
					{
						vocalsP.stop();
						vocalsE.stop();
					}
				}
				Constants.freakyPlaying = false;
				MusicBeatState.switchState(new FreeplayState());
				Lib.clearInterval(id);
			}

			if (FlxG.keys.justPressed.SPACE)
				paused = !paused;

			if (FlxG.mouse.wheel != 0)
				scroll(FlxG.mouse.wheel);
		}

		if (unspawnNotes.length > 0)
		{
			while (unspawnNotes[noteCounter] != null && unspawnNotes[noteCounter].time - Conductor.songPosition < 1800)
			{
				var spawnNote = unspawnNotes[noteCounter];
				var note:EditorNote = noteGroup.recycle(EditorNote);
				note.setup(spawnNote.time, spawnNote.data, spawnNote.length, spawnNote.type, TimingStruct.getBeatFromTime(spawnNote.time));
				note.setGraphicSize(gridSize, gridSize);
				note.updateHitbox();
				note.setPosition(grid.x + (gridSize * spawnNote.data), getYFromTime(spawnNote.time));
				noteCounter++;
				if (note.holdLength > 0)
				{
					var sustain:EditorSustain = sustainGroup.recycle(EditorSustain);
					sustain.setup(note.x + 20, note.y + gridSize, 8, Math.floor((getYFromTime(note.time + note.holdLength)) - note.y));
					note.sustain = sustain;
				}
				// noteGroup.sort(FlxSort.byY, FlxSort.ASCENDING);
				// sustainGroup.sort(FlxSort.byY, -1);
			}

			noteGroup.forEachAlive(function(n:EditorNote)
			{
				if (Conductor.songPosition - n.time > 1000)
				{
					n.kill();
					if (n.sustain != null)
						n.sustain.kill();
				}
			});
		}

		var playedSound:Array<Bool> = [false, false, false, false, false, false, false, false];
		noteGroup.forEachAlive(function(note:EditorNote)
		{
			if (note.time <= Conductor.songPosition)
			{
				if (note.time > lastConductorPos && inst.playing && note.data > -1 && note.hitsoundsEditor)
				{
					var data:Int = note.rawData;
					final noteDataToCheck:Int = data;
					final playerNote = noteDataToCheck >= 4;
					if (!playedSound[data])
					{
						if ((FlxG.save.data.playHitsounds && playerNote) || (FlxG.save.data.playHitsoundsE && !playerNote))
						{
							hitsound.stop();
							hitsound.time = 0;
							hitsound.play().pan = noteDataToCheck < 4 ? -0.3 : 0.3;
							playedSound[data] = true;
						}
						data = noteDataToCheck;
					}
				}
			}
		});

		infoText.text = "Song : "
			+ SONG.songName
			+ "\nDifficulty : "
			+ curDiff
			+ "\nSong Position : "
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition * 0.001, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(inst.length * 0.001, 2))
			+ "\nSpeed / Pitch :"
			+ Std.string(FlxMath.roundDecimal(pitch, 2))
			+ "\nCur Section : "
			+ curSection
			+ "\nCurBeat : "
			+ HelperFunctions.truncateFloat(curDecimalBeat, 3)
			+ "\nCurStep : "
			+ curStep
			+ "\nSustain Quant : "
			+ HelperFunctions.truncateFloat(sustainQuant, 2)
			+ "\nQuant : "
			+ quantList[curQuant]
			+ "\n"
			+ "Quantization : "
			+ snap;
		infoText.updateHitbox();
		lastConductorPos = Conductor.songPosition;
		super.update(elapsed);
	}

	function regenerateLines()
	{
		clearLines();

		for (i in 0...lengthInBeats)
		{
			final line:BeatLine = lines.recycle(BeatLine);
			line.setup(grid.x, getYFromTime(TimingStruct.getTimeFromBeat(i)), FlxColor.RED);
		}

		for (i in SONG.notes)
		{
			final line:BeatLine = lines.recycle(BeatLine);
			line.setup(grid.x, getYFromTime(i.startTime), FlxColor.WHITE);
		}

		for (i in SONG.eventObjects)
			addEventLine(i);
	}

	private function addEventLine(i:Event)
	{
		final seg = TimingStruct.getTimingAtBeat(i.beat);
		var posi:Float = 0;
		if (seg != null)
		{
			var start:Float = (i.beat - seg.startBeat) / (seg.bpm / 60);
			posi = seg.startTime + start;
		}

		var pos = getYFromTime(posi * 1000);
		if (pos < 0)
			pos = 0;

		final type = i.type;

		final text:TextLine = texts.recycle(TextLine);
		text.reuse(grid.x + (gridSize * 8), pos, 16);
		text.text = i.name + "\n" + type + "\n" + i.args[0] + "\n" + (i.args[1] == null ? "" : i.args[1]);
		text.updateHitbox();

		final line:BeatLine = lines.recycle(BeatLine);
		line.setup(grid.x, pos, FlxColor.YELLOW);
	}

	private function addNote()
	{
		destroyBoxes();
		final strumTime = getTimeFromY(mouse.y);
		final noteData:Int = Math.floor((mouse.x - grid.x) / gridSize);
		final section = getSectionByTime(strumTime);
		final chartNote:ChartNote = {
			time: strumTime,
			data: noteData,
			length: 0,
			type: "Normal"
		};
		var note:EditorNote = noteGroup.recycle(EditorNote);
		note.setup(chartNote.time, chartNote.data, chartNote.length, chartNote.type, TimingStruct.getBeatFromTime(chartNote.time));
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();
		note.setPosition(grid.x + (gridSize * chartNote.data), getYFromTime(chartNote.time));
		note.camera = noteGroup.camera;
		noteCounter++;
		maxNotes++;
		section.sectionNotes.push(chartNote);
		sortNotes(section);
		noteGroup.sort(FlxSort.byY, FlxSort.ASCENDING);
		Debug.logTrace("Adding Note At " + strumTime);
		createBox(note.x, note.y, note);
		curSelectedNote = chartNote;
		curSelectedNoteObject = note;
	}

	function selectNote(note:EditorNote):Void
	{
		for (sec in SONG.notes)
		{
			for (i in 0...sec.sectionNotes.length)
			{
				final secNote = sec.sectionNotes[i];
				final time = secNote.time;
				final data = secNote.data;
				final type = secNote.type;
				if (time == note.time && data == note.rawData && type == note.type)
				{
					curSelectedNote = secNote;
					curSelectedNoteObject = note;
					if (!note.selected)
					{
						createBox(note.x, note.y, note);
						note.selected = true;
						curSelectedNoteObject.selected = true;
					}
				}
			}
		}
	}

	private function deleteNote(n:EditorNote, removeBoxes:Bool = true)
	{
		if (removeBoxes)
			destroyBoxes();

		final section = getSectionByTime(n.time);
		var i:Int = section.sectionNotes.length;
		while (--i > -1)
		{
			if (section.sectionNotes[i].time == n.time && section.sectionNotes[i].data == n.rawData)
			{
				Debug.logTrace("Removing Note At " + n.time);
				section.sectionNotes.remove(section.sectionNotes[i]);
			}
		}
		sortNotes(section);

		if (n.sustain != null)
			n.sustain.kill();

		n.kill();
	}

	function createBox(x:Float, y:Float, note:EditorNote)
	{
		var box:ChartingBox = selectedBoxes.recycle(ChartingBox);
		box.setupBox(x, y, note);
	}

	function destroyBoxes()
	{
		selectedBoxes.forEachAlive(function(b:ChartingBox)
		{
			b.connectedNote.selected = false;
			b.kill();
		});
	}

	override function destroy()
	{
		noteGroup.forEachAlive(function(spr:EditorNote) spr.destroy());
		noteGroup.clear();
		sustainGroup.forEachAlive(function(spr:EditorSustain) spr.destroy());
		sustainGroup.clear();
		// I hate having things run in update all the time but fuck it
		backupChart();
		curSelectedNoteObject = null;
		curSelectedNote = null;
		selectBox = null;
		noteTypes = null;

		destroyBoxes();
		super.destroy();
	}

	function changeNoteSustain(value:Float):Void
	{
		final halfStep:Float = (Conductor.stepCrochet * 0.5);
		final val:Float = Math.round(value / halfStep) * halfStep;
		final note = curSelectedNoteObject;
		note.holdLength = note.holdLength + val;

		if (note.holdLength <= 0)
		{
			note.holdLength = 0;
			curSelectedNote.length = note.holdLength;
			if (note.sustain != null)
				note.sustain.kill();
			return;
		}
		Debug.logTrace(note.holdLength);
		if (note.sustain == null || !note.sustain.alive)
		{
			var sustain:EditorSustain = sustainGroup.recycle(EditorSustain);
			sustain.setup(note.x + 20, note.y + gridSize, 8, Math.floor((getYFromTime(note.time + note.holdLength)) - note.y));
			note.sustain = sustain;
		}
		else
			note.sustain.setup(note.x + 20, note.y + gridSize, 8, Math.floor((getYFromTime(note.time + note.holdLength)) - note.y));
		curSelectedNote.length = note.holdLength;
	}

	function offsetSelectedNotes(offset:Float)
	{
		var toDelete:Array<EditorNote> = [];
		var toBeAdded:Array<EditorNote> = []; // retarded ass boxes
		// For each selected note...
		selectedBoxes.forEachAlive(function(b:ChartingBox)
		{
			final originalNote = b.connectedNote;
			toDelete.push(originalNote);
			final strum = originalNote.time + offset;
			final sec = getSectionByTime(strum);
			if (strum < 0)
				return;

			sec.sectionNotes.push({
				data: originalNote.rawData,
				time: strum,
				length: originalNote.holdLength,
				type: originalNote.type
			});
		});

		for (note in toDelete)
			deleteNote(note);

		destroyBoxes();

		for (box in toBeAdded)
			createBox(box.x, box.y, box);

		toDelete = null;
		toBeAdded = null;
	}

	function containsName(name:String, events:Array<Event>):Event
	{
		for (i in events)
		{
			if (i.name == name)
				return i;
		}
		return null;
	}

	private inline function clearSection(index:Int)
		SONG.notes[index].sectionNotes = [];

	function swapSection(secit:Section)
	{
		destroyBoxes();
		for (i in 0...secit.sectionNotes.length)
		{
			var note = secit.sectionNotes[i];
			note.data = (note.data + 4) % 8;
			secit.sectionNotes[i] = note;
		}
	}

	inline function getTimeFromY(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, currentSection.lengthInSteps, 0, currentSection.lengthInSteps);
	}

	inline function getYFromTime(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, currentSection.lengthInSteps, 0, currentSection.lengthInSteps);
	}

	function goToSection(section:Int)
	{
		var beat = section * 4;
		var data = TimingStruct.getTimingAtBeat(beat);

		if (data == null)
			return;

		inst.time = (data.startTime + ((beat - data.startBeat) / (data.bpm / 60))) * 1000;
		var sec = getSectionByTime(inst.time);
		curSection = section;
		Debug.logTrace("Going too " + inst.time + " | Which is at " + beat + " | Section Index " + sec.index);

		if (inst.time < 0)
			inst.time = 0;
		else if (inst.time > inst.length)
			inst.time = inst.length;

		if (!SONG.splitVoiceTracks)
			vocals.time = inst.time;
		else
		{
			vocalsP.time = inst.time;
			vocalsE.time = inst.time;
		}
	}

	function updateNotetypeText()
	{
		notetypetext.text = "Note Type: " + noteTypes[curType];
		notetypetext.updateHitbox();
	}

	function backupChart():Void
	{
		if (!FlxG.save.data.autoSaving)
			return;

		final song = Json.stringify(SONG).trim();
		if (!FileSystem.exists('backups'))
			FileSystem.createDirectory('backups');
		var dateNow:String = Date.now().toString();
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		Debug.logTrace('Filed Saved To ${Sys.getCwd()}/backups As ${SONG.songId + dateNow}.json');
		File.saveContent('${Sys.getCwd()}/backups/${SONG.songId + dateNow}.json', song);
	}

	function loadAudio(daSong:String, reloadFromFile:Bool = false):Void
	{
		if (reloadFromFile)
		{
			if (!Song.doesChartExist(daSong, CoolUtil.getSuffixFromDiff(CoolUtil.difficulties[PlayState.storyDifficulty])))
			{
				Debug.logWarn("Couldn't Find Chart For " + daSong + " With A Difficulty Of " + CoolUtil.difficulties[PlayState.storyDifficulty]);
				return;
			}
			SONG = Song.loadFromJson(daSong, CoolUtil.getSuffixFromDiff(CoolUtil.difficulties[PlayState.storyDifficulty]));
			PlayState.SONG = SONG;
			MusicBeatState.switchState(new ChartingState());
		}

		final audioFile:String = SONG.audioFile;

		inst = FlxG.sound.load(Paths.inst(audioFile, false));
		inst.play();
		inst.pause();

		vocals = new FlxSound();
		vocalsP = new FlxSound();
		vocalsE = new FlxSound();
		if (!SONG.needsVoices)
			return;
		// I love doing this but it's so situational bruh
		switch (SONG.splitVoiceTracks)
		{
			case true:
				vocalsP = FlxG.sound.load(Paths.voices(audioFile, 'P'));
				vocalsE = FlxG.sound.load(Paths.voices(audioFile, 'E'));
				vocalsP.play();
				vocalsP.pause();
				vocalsE.play();
				vocalsE.pause();
			case false:
				vocals = FlxG.sound.load(Paths.voices(audioFile, ''));
				vocals.play();
				vocals.pause();
		}
	}

	function loadJson(songId:String, diff:String):Void
	{
		try
		{
			PlayState.storyDifficulty = CoolUtil.difficulties.indexOf(diff);
			PlayState.SONG = Song.loadFromJson(songId.toLowerCase(), CoolUtil.getSuffixFromDiff(diff));
			Debug.logTrace('$songId $diff');
			MusicBeatState.switchState(new ChartingState());
			Lib.clearInterval(id);
		}
		catch (e)
		{
			Debug.logError('Make Sure You Have A Valid JSON To Load. A Possible Solution Is Setting The Difficulty To Normal. Error: $e');
			return;
		}
	}

	private function saveChart()
	{
		SONG.chartVersion = Constants.chartVer;
		setSongData();
		final data:String = haxe.Json.stringify(SONG, null).trim();
		final chartName:String = SONG.songId + CoolUtil.getSuffixFromDiff(curDiff);
		fileDialog.save('$chartName.json', data, function() Debug.logTrace("Successfully Saved Chart"), null, function() Debug.logTrace("Error Saving Chart"));
	}

	private function setSongData()
	{
		try
		{
			SONG.player1 = playerSelect.text;
			SONG.player2 = opponentSelect.text;
			SONG.gfVersion = gfSelect.text;
			SONG.stage = stageSelect.text;
			SONG.style = styleSelect.text;

			SONG.songId = dataID.text;
			SONG.audioFile = dataAudio.text;
			SONG.songName = dataName.text;
		}
	}

	override function sectionHit()
	{
		super.sectionHit();
		if (curSection < 0)
			return;

		// clearRenderedNotes();
		sectionMustHit.selected = currentSection.mustHitSection;
	}

	override function beatHit(curBeat:Int)
	{
		super.beatHit(curBeat);
		playMetronome();
	}

	override function stepHit(curStep:Int)
	{
		super.stepHit(curStep);
		if (inst.playing)
		{
			iconP1.onStepHit(curStep);
			iconP2.onStepHit(curStep);
		}
	}

	inline function mouseValid():Bool
	{
		// NOTE: we're checking the mouse's y so notes/events can't be placed outside of the grid
		return mouse.x >= grid.x && mouse.x < grid.x + grid.width && FlxG.mouse.y >= 0 && FlxG.mouse.y < end;
	}

	inline function getMouseY():Float
	{
		final time = getTimeFromY(FlxG.mouse.getWorldPosition(mouse.camera).y);
		final quant:Float = quantList[curQuant];
		final beat = TimingStruct.getBeatFromTime(time);
		final snapShit = Math.floor(beat * quant) / quant;

		final newDummyY = getYFromTime(TimingStruct.getTimeFromBeat(snapShit));
		return (snap) ? newDummyY : FlxG.mouse.y;
	}

	public static inline function quantizePos(position:Float):Float
	{
		return Math.ffloor(position / gridSize) * gridSize;
	}

	// fard

	private function checkNoteSpawn()
	{
		final strumTime:Float = getTimeFromY(mouse.y);
		final noteData:Int = Math.floor((mouse.x - grid.x) / gridSize);
		final existingNote = noteGroup.members.filter(function(n:EditorNote)
		{
			return (n.time == strumTime && n.rawData == noteData && n.alive && FlxG.mouse.overlaps(n));
		});

		if (existingNote[0] != null)
			deleteNote(existingNote[0]);
		else
			addNote();
	}

	private inline function createGrid()
	{
		grid = new EditorGrid();
		end = getYFromTime(inst.length);
		add(grid);

		mouse = new FlxSprite().makeGraphic(gridSize, gridSize);
		mouse.alpha = 1;
		mouse.updateHitbox();
		mouse.setPosition(grid.x, gridSize);
		mouse.active = false;

		strumLine = new FlxSprite(0, -100);
		strumLine.makeGraphic(Std.int(gridSize * 8), 4, FlxColor.fromRGB(255, 25, 25));
		strumLine.updateHitbox();
		strumLine.screenCenter(X);
		strumLine.x += separatorWidth;
		strumLine.active = false;

		noteCam.follow(strumLine, LOCKON);
		noteCam.targetOffset.y = 100;
		add(mouse);
		add(strumLine);
	}

	function calculateMaxBeat()
		maxBeat = Math.round(TimingStruct.getBeatFromTime(inst.length));

	function checkforSections()
	{
		final totalBeats = maxBeat;
		maxSectionIndex = SONG.notes[SONG.notes.length - 1].index;
		Debug.logTrace(maxSectionIndex);

		var lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);

		while (lastSecBeat < totalBeats)
		{
			Debug.logTrace('LastBeat: $lastSecBeat | totalBeats: $totalBeats ');
			SONG.notes.push(newSection(SONG.notes[SONG.notes.length - 1].lengthInSteps, SONG.notes.length, true));
			recalculateAllSectionTimes();
			lastSecBeat = TimingStruct.getBeatFromTime(SONG.notes[SONG.notes.length - 1].endTime);
		}
	}

	private function set_paused(b:Bool)
	{
		switch (b)
		{
			case true:
				inst.pause();
				switch (SONG.splitVoiceTracks)
				{
					case true:
						vocalsP.pause();
						vocalsE.pause();
					case false: vocals.pause();
				}
			case false:
				inst.play();
				switch (SONG.splitVoiceTracks)
				{
					case true:
						vocalsP.play();
						vocalsE.play();
					case false: vocals.play();
				}
		}
		paused = b;
		return b;
	}

	private function scroll(pos:Int)
	{
		paused = true;

		final beat:Float = TimingStruct.getBeatFromTime(Conductor.songPosition);
		final snap:Float = 16 * 0.25;
		final increase:Float = 1 / snap;
		final wheelShit = pos > 0;

		if (wheelShit)
		{
			var fuck:Float = (Math.fround(beat * snap) / snap) - increase;
			if (fuck < 0)
				fuck = 0;
			final data = TimingStruct.getTimingAtBeat(fuck);
			var lastDataIndex = TimingStruct.AllTimings.indexOf(data) - 1;
			if (lastDataIndex < 0)
				lastDataIndex = 0;

			final lastData = TimingStruct.AllTimings[lastDataIndex];

			var pog = 0.0;
			var shitPosition = 0.0;

			if (beat < data.startBeat)
			{
				pog = (fuck - lastData.startBeat) / (lastData.bpm / 60);
				shitPosition = (lastData.startTime + pog) * 1000;
			}
			else if (beat > data.startBeat)
			{
				pog = (fuck - data.startBeat) / (data.bpm / 60);
				shitPosition = (data.startTime + pog) * 1000;
			}
			else
			{
				pog = fuck / (Conductor.bpm / 60);
				shitPosition = pog * 1000;
			}

			inst.time = shitPosition;
		}
		else
		{
			var fuck:Float = (Math.fround(beat * snap) / snap) + increase;
			if (fuck < 0)
				fuck = 0;
			final data = TimingStruct.getTimingAtBeat(fuck);
			var lastDataIndex = TimingStruct.AllTimings.indexOf(data) - 1;
			if (lastDataIndex < 0)
				lastDataIndex = 0;

			final lastData = TimingStruct.AllTimings[lastDataIndex];

			var pog = 0.0;
			var shitPosition = 0.0;
			if (beat < data.startBeat)
			{
				pog = (fuck - lastData.startBeat) / (lastData.bpm / 60);
				shitPosition = (lastData.startTime + pog) * 1000;
			}
			else if (beat > data.startBeat)
			{
				pog = (fuck - data.startBeat) / (data.bpm / 60);
				shitPosition = (data.startTime + pog) * 1000;
			}
			else
			{
				pog = fuck / (Conductor.bpm / 60);
				shitPosition = pog * 1000;
			}

			inst.time = shitPosition;
		}
		if (!SONG.splitVoiceTracks)
			vocals.time = inst.time;
		else
		{
			vocalsP.time = inst.time;
			vocalsE.time = inst.time;
		}
	}

	private inline function clearLines()
	{
		lines.forEachAlive(function(l:BeatLine) l.kill());
		texts.forEachAlive(function(t:TextLine) t.kill());
	}

	private inline function clearRenderedNotes()
	{
		noteGroup.forEachAlive(function(n:EditorNote) n.kill());
		sustainGroup.forEachAlive(function(n:EditorSustain) n.kill());
	}

	private function playMetronome()
	{
		metronome.stop();
		metronome.time = 0;
		metronome.play();
	}

	private function newSection(lengthInSteps:Int = 16, index:Int, mustHitSection:Bool = false):Section
	{
		var sec:Section = {
			bpm: SONG.bpm,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			index: index,
			lengthInSteps: lengthInSteps
		};
		return sec;
	}

	private function findEvent(name:String, type:String)
	{
		var theEVENT = eventList.filter(function(e:Event)
		{
			final ev = (e.name == name && e.type == type);
			return ev;
		});

		Debug.logTrace(theEVENT[0] == null);

		return theEVENT[0] == null ? null : theEVENT[0];
	}

	public inline function sortNotes(sec:Section):Void
		sec.sectionNotes.sort((a, b) -> Std.int(a.time - b.time));

	private function initHUI()
	{
		final characterList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		final gfList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));
		final stageList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		final styleList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/songStyleList'));
		final eventList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/eventList'));
		final diffList:Array<String> = CoolUtil.difficulties;
		var chars = new ArrayDataSource<String>();
		for (c in characterList)
			chars.add(c);

		var gfs = new ArrayDataSource<String>();
		for (c in gfList)
			gfs.add(c);

		var stages = new ArrayDataSource<String>();
		for (s in stageList)
			stages.add(s);

		var styles = new ArrayDataSource<String>();
		for (s in styleList)
			styles.add(s);
		var diffs = new ArrayDataSource<String>();
		for (d in diffList)
			diffs.add(d);

		var events = new ArrayDataSource<String>();
		for (e in eventList)
			events.add(e);
		for (event in SONG.eventObjects)
		{
			existingEvents.add(event.name);
			this.eventList.push(event);
		}

		playerSelect.dataSource = chars;
		opponentSelect.dataSource = chars;
		gfSelect.dataSource = gfs;
		stageSelect.dataSource = stages;
		styleSelect.dataSource = styles;
		diffSelect.dataSource = diffs;
		eventExistList.dataSource = existingEvents;
		eventTypes.dataSource = events;

		eventTypes.selectItemBy(item -> item == SONG.eventObjects[0].type, true);
		eventExistList.selectItemBy(item -> item == SONG.eventObjects[0].name, true);
		eventExistList.registerEvent(UIEvent.CLOSE, function(e:UIEvent)
		{
			curEvent = SONG.eventObjects[eventExistList.selectedIndex];
			Debug.logTrace(curEvent.name);
			if (findEvent(curEvent.name, curEvent.type) == null)
				return;

			eventName.value = curEvent.name;
			eventTypes.selectItemBy(item -> item == curEvent.type, true);
			eventValue1.value = curEvent.args[0];
			eventValue2.value = curEvent.args[1];
			eventPos.pos = curEvent.beat;
			Debug.logTrace("Found Event. Setting Values");
		});

		setHUIData();
	}

	private function setHUIData()
	{
		playerSelect.selectItemBy(item -> item == SONG.player1, true);
		opponentSelect.selectItemBy(item -> item == SONG.player2, true);
		gfSelect.selectItemBy(item -> item == SONG.gfVersion, true);
		stageSelect.selectItemBy(item -> item == SONG.stage, true);
		styleSelect.selectItemBy(item -> item == SONG.style, true);
		diffSelect.selectItemBy(item -> item == CoolUtil.difficulties[PlayState.storyDifficulty], true);
		eventName.text = curEvent.name;
		eventValue1.text = curEvent.args[0];
		eventValue2.text = curEvent.args[1];
		eventPos.pos = curEvent.beat;
		dataID.text = SONG.songId;
		dataName.text = SONG.songName;
		dataAudio.text = SONG.audioFile;
		dataBPM.pos = SONG.eventObjects[0].args[0];
		dataVoices.selected = SONG.needsVoices;
		dataSpeed.pos = SONG.speed;
		dataSplit.selected = SONG.splitVoiceTracks;
		sectionMustHit.onClick = _ -> currentSection.mustHitSection = !currentSection.mustHitSection;
		editorMetroVol.onChange = _ -> metronome.volume = (editorMetroVol.value / 100);

		editorHitsoundsP.selected = FlxG.save.data.playHitsounds;
		editorHitsoundsE.selected = FlxG.save.data.playHitsoundsE;
		editorHitsoundsP.onClick = _ -> FlxG.save.data.playHitsounds = !FlxG.save.data.playHitsounds;
		editorHitsoundsE.onClick = _ -> FlxG.save.data.playHitsoundsE = !FlxG.save.data.playHitsoundsE;

		editorAutoSave.selected = FlxG.save.data.autoSaving;
		editorAutoSave.onClick = _ -> FlxG.save.data.autoSaving = !FlxG.save.data.autoSaving;

		editorHitVol.onChange = _ -> hitsound.volume = (editorHitVol.value / 100);

		chartSave.onClick = _ -> saveChart();
		chartReload.onClick = _ -> loadAudio(dataID.text, true);
		diffSelect.registerEvent(UIEvent.CLOSE, function(e)
		{
			PlayState.storyDifficulty = CoolUtil.difficulties.indexOf(diffSelect.text);
			Debug.logTrace(CoolUtil.difficulties[PlayState.storyDifficulty]);
		});
		chartClear.onClick = function(e)
		{
			for (i in 0...maxSectionIndex)
			{
				clearSection(i);
			}
			clearRenderedNotes();
		}

		instVol.onChange = _ -> inst.volume = (instVol.value / 100);
		vocalVol.disabled = (SONG.needsVoices && SONG.splitVoiceTracks);
		vocalPVol.disabled = (SONG.needsVoices && !SONG.splitVoiceTracks);
		vocalEVol.disabled = (SONG.needsVoices && !SONG.splitVoiceTracks);
		vocalVol.onChange = _ -> if (vocals != null && !vocalVol.disabled) vocals.volume = (vocalVol.value / 100);
		vocalPVol.onChange = _ -> if (vocalsP != null && !vocalPVol.disabled) vocalsP.volume = (vocalPVol.value / 100);
		vocalEVol.onChange = _ -> if (vocalsE != null && !vocalEVol.disabled) vocalsE.volume = (vocalEVol.value / 100);
		dataSplit.onClick = function(e)
		{
			SONG.splitVoiceTracks = !SONG.splitVoiceTracks;
			loadAudio(SONG.songId);
		}
		dataVoices.onClick = function(e)
		{
			SONG.needsVoices = !SONG.needsVoices;
			loadAudio(SONG.songId);
		}
		eventAdd.onClick = function(e)
		{
			final eventPos = TimingStruct.getBeatFromTime(Conductor.songPosition);
			if (findEvent('New Event $eventPos', "BPM Change") != null)
			{
				Debug.logTrace("Event Already Exists Dumbass");
				return;
			}
			final newEvent:Event = {
				name: 'New Event $eventPos',
				type: "BPM Change",
				args: [SONG.eventObjects[0].args[0]],
				beat: eventPos
			};

			SONG.eventObjects.push(newEvent);
			eventList.push(newEvent);
			existingEvents.add(newEvent.name);
			eventExistList.dataSource = existingEvents;
			eventExistList.selectItemBy(item -> item == newEvent.name, true);
			addEventLine(newEvent);
		}
	}
}
