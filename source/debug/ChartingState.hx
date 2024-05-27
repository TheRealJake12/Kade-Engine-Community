package debug;

import Section.SwagSection;
import Song.SongData;
import Song.SongMeta;
import haxe.ui.events.UIEvent;
import openfl.Lib;
import haxe.ui.notifications.NotificationType;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.focus.FocusManager;
import haxe.ui.components.Spacer;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.OptionBox;
import haxe.ui.components.TextField;
import haxe.ui.components.Toggle;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.styles.Style;
import haxe.ui.themes.Theme;
import haxe.ui.util.Color;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.components.HorizontalSlider;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end

class ChartingState extends MusicBeatState
{
	public static var instance:ChartingState = null;

	var ui:TabView;
	var menu:MenuBar;

	var box:ContinuousHBox;
	var box2:ContinuousHBox;
	var box3:ContinuousHBox;
	var box4:HBox;
	var box5:ContinuousHBox;

	var vbox1:VBox;
	var vbox3:VBox;
	var grid:Grid;

	// Assets
	var playerDrop:DropDown;
	var opponentDrop:DropDown;
	var stageDrop:DropDown;
	var gfDrop:DropDown;
	var noteStyleDrop:DropDown;

	// Song
	var song:TextField;
	var songName:TextField;
	var audioFileName:TextField;

	var hasVoices:CheckBox;
	var isSplit:CheckBox;

	var bpm:NumberStepper;
	var scrollSpeed:NumberStepper;
	var instVol:NumberStepper;
	var vocalVol:NumberStepper;
	var vocalPVol:NumberStepper;
	var vocalEVol:NumberStepper;
	var diffDrop:DropDown;

	// Note
	var strumTime:TextField;
	var noteShitDrop:DropDown;

	// Section
	var playerSection:CheckBox;
	var refreshSec:Button;
	var clearSec:Button;
	var swapSec:Button;
	var duet:Button;
	var mirror:Button;
	var copySec:Button;
	var pasteSec:Button;
	var clearCopiedNotes:Button;

	var secBox:VBox;
	var secBox2:VBox;
	var secGrid:Grid;
	var secGrid2:Grid;

	// Personal
	var metronome:MenuCheckBox;
	var hitsoundsVol:HorizontalSlider;
	var hitsoundsP:MenuCheckBox;
	var hitsoundsE:MenuCheckBox;
	var oppMode:MenuCheckBox;

	var daHitSound:FlxSound;

	// Events
	var eventDrop:DropDown;
	var eventTypes:DropDown;
	var eventAdd:Button;
	var eventRemove:Button;
	var eventName:TextField;
	var eventVal1:TextField;
	var eventVal2:TextField;
	var eventPosition:TextField;
	var eventPos:Button;
	var eventSave:Button;

	// dfjk
	var characters:Array<String>;
	var stages:Array<String>;
	var gfs:Array<String>;
	var noteStyles:Array<String>; // noteStyles basically
	var noteTypes:Array<String>; // noteShit basically
	var events:Array<String>; // even- you already know

	var noteType:String = "Normal"; // idfk

	public var SONG:SongData;
	public var lastUpdatedSection:SwagSection = null;

	public var noteSize:Int = 50; // scale? GRID_SIZE?

	var notePos = 100; // General Note Pos
	var sectionPos = 100; // Where gray BG is.
	var size = 0.5; // general size / spacing of things

	var currentSelectedEventName:String = "";
	var savedType:String = "BPM Change";
	var savedValue:String = "100";
	var savedValue2:String = "1";
	var currentEventPosition:Float = 0;

	public var chartEvents:Array<Song.Event> = [];

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;
	var sectionRenderers:FlxTypedGroup<SectionRender>;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;
	public var curSelectedNoteObject:Note = null;

	public var copiedNotes:Array<Array<Dynamic>> = [];
	public var pastedNotes:Array<Note> = [];
	public var deletedNotes:Array<Array<Dynamic>> = [];
	public var lastAction:String = "";

	var curSelectedNote:Array<Dynamic>;
	private var lastNote:Note;
	var texts:FlxTypedGroup<FlxText>;
	var lines:FlxTypedGroup<FlxSprite>;

	var inst:FlxSound;
	var vocals:FlxSound;
	var vocalsP:FlxSound;
	var vocalsE:FlxSound;

	var iconP1:HealthIcon;
	var iconP2:HealthIcon;

	var player:Character;
	var opponent:Character;

	var lastConductorPos:Float;

	var camFollow:FlxObject;
	var strumLine:FlxSprite;

	public static var lengthInSteps:Float = 0;
	public static var lengthInBeats:Float = 0;

	public var pitch:Float = 1.0;

	var sectionY = 0;

	var currentBPM:Float = 0;
	var doSnapShit:Bool = true;
	var defaultSnap:Bool = true;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	var curDiff:String = "";

	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var middleLine:FlxSprite;
	var gridBG:FlxSprite;
	var dummyArrow:FlxSprite;
	var gridBlackLine:FlxSprite;

	public var waitingForRelease:Bool = false;
	public var selectBox:FlxSprite;

	public static var clean:Bool = false;

	public var selectInitialX:Float = 0;
	public var selectInitialY:Float = 0;

	public var infoText:CoolUtil.CoolText;

	var sustainQuant:Float = 1.0;

	public var infoBG:FlxSprite;
	public var notetypetext:CoolUtil.CoolText;
	public var helpText:CoolUtil.CoolText;

	var _file:FileReference;

	public var id:Int = -1;

	// one does not realize how much flixel-ui is used until one sees an FNF chart editor. 💀

	/*
		>new chart editor
		>looks inside
		>kade engine chart editor
	 */
	override function create()
	{
		instance = this;

		if (clean)
		{
			Paths.clearStoredMemory();
			Paths.clearUnusedMemory();
			Debug.logTrace("Cleaning");
			Paths.runGC();
			clean = false;
		}

		ui = new TabView();
		ui.text = "huh";
		ui.draggable = FlxG.save.data.moveEditor;
		ui.height = 300;

		menu = new MenuBar();
		menu.continuous = true;
		menu.height = 30;
		menu.width = FlxG.width;

		#if FEATURE_DISCORD
		Discord.changePresence("Chart Editor", null, null, true);
		#end

		FlxG.mouse.visible = true;

		PlayState.inDaPlay = false;

		TimingStruct.clearTimings();
		SONG = PlayState.SONG;

		loadSong(SONG.audioFile, false);

		curDiff = CoolUtil.difficultyArray[PlayState.storyDifficulty];

		// Song.sortSectionNotes(SONG);

		activeSong = SONG;

		Conductor.changeBPM(SONG.bpm);

		PlayState.noteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.noteskin);
		PlayState.cpuNoteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		PlayState.noteskinPixelSprite = CustomNoteHelpers.Skin.generatePixelSprite(FlxG.save.data.noteskin);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF111111;
		add(bg);

		lines = new FlxTypedGroup<FlxSprite>();
		texts = new FlxTypedGroup<FlxText>();
		sectionRenderers = new FlxTypedGroup<SectionRender>();
		add(sectionRenderers);

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		camFollow = new FlxObject(280, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow);

		characters = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		gfs = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));
		stages = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		noteTypes = CoolUtil.coolTextFile(Paths.txt('data/noteTypeList'));
		noteStyles = CoolUtil.coolTextFile(Paths.txt('data/songStyleList'));
		events = CoolUtil.coolTextFile(Paths.txt('data/eventList'));

		player = new Character(0, 0, SONG.player1, true);
		opponent = new Character(0, 0, SONG.player2, false);

		iconP2 = new HealthIcon(opponent.healthIcon, opponent.iconAnimated, false);
		iconP1 = new HealthIcon(player.healthIcon, player.iconAnimated, true);

		iconP1.scale.set(0.7, 0.7);
		iconP2.scale.set(0.7, 0.7);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		iconP1.setPosition(850, 35);
		iconP2.setPosition(350, 35);

		infoText = new CoolUtil.CoolText(970, 40, 16, 16, Paths.bitmapFont('fonts/vcr'));
		infoText.autoSize = true;
		infoText.antialiasing = true;
		infoText.updateHitbox();
		infoText.scrollFactor.set();

		infoBG = new FlxSprite(infoText.x - 5, infoText.y - 10).makeGraphic(335, 240, FlxColor.fromRGB(35, 35, 35));
		infoBG.scrollFactor.set();

		notetypetext = new CoolUtil.CoolText(970, infoText.y + 200, 20, 20, Paths.bitmapFont('fonts/vcr'));
		notetypetext.autoSize = true;
		notetypetext.antialiasing = true;
		notetypetext.updateHitbox();
		notetypetext.scrollFactor.set();

		if (FlxG.save.data.showHelp == null)
			FlxG.save.data.showHelp = true;

		helpText = new CoolUtil.CoolText(985, 485, 12, 12, Paths.bitmapFont('fonts/vcr'));
		helpText.autoSize = true;
		helpText.antialiasing = true;
		helpText.text = "Help:" + "\n" + "CTRL-Left/Right : Change playback speed" + "\n" + "Ctrl+Drag Click : Select notes" + "\n" + "Ctrl+C : Copy notes"
			+ "\n" + "Ctrl+V : Paste notes" + "\n" + "Ctrl+Z : Undo" + "\n" + "Ctrl+BACKSPACE : Delete Selected Notes" + "\n"
			+ "Alt+Left/Right : Change Quant" + "\n" + "Shift : Disable/Enable Quant" + "\n" + "Click : Place notes" + "\n" + "Up/Down : Move selected notes"
			+ "\n" + "Space : Play Song" + "\n" + "W-S : Go To Previous / Next Section" + "\n" + "Q-E : Change Sustain Amount" + "\n"
			+ "C-V : Change Sustain Change Quant" + "\n" + "Enter : Load Song Into PlayState" + "\n" + "Z/X Change Notetype." + "\n"
			+ "Press F1 to show/hide help text.";
		helpText.updateHitbox();
		helpText.scrollFactor.set();
		helpText.visible = FlxG.save.data.showHelp;

		dummyArrow = new FlxSprite().makeGraphic(50, 50);
		dummyArrow.alpha = 0.5;
		dummyArrow.updateHitbox();

		strumLine = new FlxSprite(sectionPos, -100);
		strumLine.makeGraphic(Std.int(50 * 8), 4, FlxColor.fromRGB(255, 25, 25));
		strumLine.alpha = 0.8;

		gridBG = new FlxSprite(notePos, 0).makeGraphic(50 * 8, 50 * 16);

		if (SONG.eventObjects == null || SONG.eventObjects.length == 0)
			SONG.eventObjects = [new Song.Event("Init BPM", 0, '${SONG.bpm}', "1", "BPM Change")];

		var currentIndex = 0;

		for (i in SONG.eventObjects)
		{
			var name = Reflect.field(i, "name");
			var type = Reflect.field(i, "type");
			var pos = Reflect.field(i, "position");
			var value = Reflect.field(i, "value");
			var value2 = Reflect.field(i, "value2");

			if (type == "BPM Change")
			{
				var beat:Float = pos;

				var endBeat:Float = Math.POSITIVE_INFINITY;

				TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

				if (currentIndex != 0)
				{
					var data = TimingStruct.AllTimings[currentIndex - 1];
					data.endBeat = beat;
					data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
					var step = ((60 / data.bpm) * 1000) / 4;
					TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
					TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
				}

				currentIndex++;
			}
		}

		var lastSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];

		for (i in 0...TimingStruct.AllTimings.length)
		{
			var seg = TimingStruct.AllTimings[i];
			if (i == TimingStruct.AllTimings.length - 1)
				lastSeg = seg;
		}
		recalculateAllSectionTimes();

		for (i in 0...9000000) // REALLY HIGH BEATS just cuz like ig this is the upper limit, I mean ur chart is probably going to run like ass anyways
		{
			var seg = TimingStruct.getTimingAtBeat(i);

			var start:Float = (i - seg.startBeat) / (seg.bpm / 60);

			var time = (seg.startTime + start) * 1000;

			if (time > inst.length)
				break;

			lengthInBeats = i;
		}

		lengthInSteps = lengthInBeats * 4;

		loadRenders();

		regenerateLines();
		updateNotes();

		middleLine = new FlxSprite(660, 0).makeGraphic(4, FlxG.height, FlxColor.GRAY);
		middleLine.scrollFactor.x = 0;
		// middleLine.camera = camGrid;
		add(lines);
		add(middleLine);
		add(texts);

		add(curRenderedNotes);
		add(curRenderedSustains);
		add(strumLine);
		add(dummyArrow);

		add(iconP1);
		add(iconP2);
		menuBarShit();

		addTabs();
		addAssetUI();
		addNoteUI();
		addSectionUI();
		addSongUI();
		addEventUI();

		selectedBoxes = new FlxTypedGroup();
		add(selectedBoxes);

		add(infoBG);
		add(infoText);

		updateNotetypeText();
		add(notetypetext);
		add(helpText);

		add(ui);
		add(menu);

		id = Lib.setInterval(autosaveSong, 5 * 60 * 1000);

		ui.x = 0;
		ui.y = 420;
		super.create();
	}

	var updateFrame = 0;

	override function update(elapsed:Float)
	{
		Conductor.songPosition = inst.time;
		if (inst != null)
			if (inst.time > inst.length - 85)
			{
				inst.pause();
				inst.time = inst.length - 85;
				if (!SONG.splitVoiceTracks)
				{
					vocals.pause();
					vocals.time = vocals.length - 85;
				}
				else
				{
					vocalsP.pause();
					vocalsP.time = vocalsP.length - 85;
					vocalsE.pause();
					vocalsE.time = vocalsE.length - 85;
				}
			}

		if (inst != null)
		{
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
						{
							vocals.pitch = pitch;
						}
					}
					else
					{
						if (vocalsP != null && vocalsP.length > 0)
						{
							vocalsP.pitch = pitch;
						}

						if (vocalsE != null && vocalsE.length > 0)
						{
							vocalsE.pitch = pitch;
						}
					}
				}
				catch (e)
				{
					Debug.logTrace("failed to pitch vocals (probably cuz they don't exist)");
				}
			}
		}
		if (updateFrame == 4)
		{
			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				if (i.type == "BPM Change")
				{
					var beat:Float = i.position;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, i.value, endBeat, 0); // offset in this case = start time since we don't have a offset

					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}

					currentIndex++;
				}
			}

			recalculateAllSectionTimes();

			regenerateLines();
			updateFrame++;
		}
		else if (updateFrame != 5)
			updateFrame++;

		var timingSeg = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);

		var start = Conductor.songPosition;

		if (timingSeg != null)
		{
			var timingSegBpm = timingSeg.bpm;
			currentBPM = timingSegBpm;

			if (currentBPM != Conductor.bpm)
			{
				Conductor.changeBPM(currentBPM);
			}

			var pog:Float = (curDecimalBeat - timingSeg.startBeat) / (Conductor.bpm / 60);

			start = (timingSeg.startTime + pog) * 1000;
		}

		strumLine.y = getYfromStrum(start) * size;
		middleLine.y = strumLine.y - 360;
		camFollow.y = strumLine.y;

		var weird = getSectionByTime(start);

		if (weird != null)
		{
			if (lastUpdatedSection != getSectionByTime(start))
			{
				lastUpdatedSection = weird;
				playerSection.selected = weird.playerSec;
			}
		}

		var doInput = true;

		if (FocusManager.instance.focus != null)
		{
			doInput = false;
		}

		for (i in sectionRenderers)
		{
			var diff = i.y - strumLine.y;
			if (diff < 1000 && diff >= -1000)
			{
				i.active = true;
				i.visible = true;
			}
			else
			{
				i.active = false;
				i.visible = false;
			}
		}

		for (note in curRenderedNotes)
		{
			var diff = note.strumTime - Conductor.songPosition;
			if (diff < 700 && diff >= -3500) // Cutting it really close with rendered notes
			{
				note.active = true;
				note.visible = true;

				if (note.noteCharterObject != null)
				{
					note.noteCharterObject.active = true;
					note.noteCharterObject.visible = true;
				}
			}
			else
			{
				note.active = false;
				note.visible = false;

				if (note.noteCharterObject != null)
				{
					if (note.noteCharterObject.y != note.y)
					{
						note.noteCharterObject.active = false;
						note.noteCharterObject.visible = false;
					}
				}
			}
		}

		// I hate having things run in update all the time but fuck it
		songShit();

		var mult:Float = FlxMath.lerp(0.75, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * PlayState.songMultiplier), 0, 1));
		if (!FlxG.save.data.motion)
			iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(0.75, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * PlayState.songMultiplier), 0, 1));
		if (!FlxG.save.data.motion)
			iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		if (FlxG.mouse.justPressed && !waitingForRelease)
		{
			if (FlxG.mouse.overlaps(curRenderedNotes))
			{
				curRenderedNotes.forEach(function(note:Note)
				{
					if (FlxG.mouse.overlaps(note))
					{
						if (FlxG.keys.pressed.CONTROL)
						{
							selectNote(note);
						}
						else
						{
							deleteNote(note);
						}
					}
				});
			}
			else
			{
				if ((FlxG.mouse.justPressed && !FlxG.keys.pressed.CONTROL)
					&& FlxG.mouse.x > notePos - 1
					&& FlxG.mouse.x < gridBG.width + notePos
					&& FlxG.mouse.y > 0
					&& FlxG.mouse.y < 0 + sectionY)
				{
					addNote();
				}
			}
		}

		if (FlxG.mouse.x > notePos - 1 && FlxG.mouse.x < gridBG.width + notePos && FlxG.mouse.y > 0 && FlxG.mouse.y < sectionY)
		{
			dummyArrow.visible = true;

			dummyArrow.x = Math.floor(FlxG.mouse.x / noteSize) * noteSize;

			if (doSnapShit)
			{
				var time = getStrumTime(FlxG.mouse.y / size);

				var beat = TimingStruct.getBeatFromTime(time);
				var snap = quantization / 4;
				var snapped = Math.round(beat * snap) / snap;

				dummyArrow.y = getYfromStrum(TimingStruct.getTimeFromBeat(snapped)) * size;
			}
			else
			{
				dummyArrow.y = FlxG.mouse.y;
			}
		}
		else
			dummyArrow.visible = false;

		if (FlxG.mouse.pressed && FlxG.keys.pressed.CONTROL)
		{
			if (!waitingForRelease)
			{
				while (selectedBoxes.members.length != 0)
				{
					selectedBoxes.members[0].connectedNote.charterSelected = false;
					selectedBoxes.members[0].destroy();
					selectedBoxes.members.remove(selectedBoxes.members[0]);
				}

				waitingForRelease = true;
				selectBox = new FlxSprite(FlxG.mouse.x, FlxG.mouse.y);
				selectBox.makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
				selectBox.alpha = 0.4;

				selectInitialX = selectBox.x;
				selectInitialY = selectBox.y;

				add(selectBox);
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

					// selectBox.makeGraphic(Math.floor(Math.abs(FlxG.mouse.x - selectInitialX)), Math.floor(Math.abs(FlxG.mouse.y - selectInitialY)),FlxColor.fromRGB(173, 216, 230));
				}
			}
		}
		if (FlxG.mouse.justReleased && waitingForRelease)
		{
			waitingForRelease = false;

			for (i in curRenderedNotes)
			{
				if (i.overlaps(selectBox) && !i.charterSelected)
				{
					selectNote(i);
				}
			}
			selectBox.destroy();
			remove(selectBox, true);
		}

		if (doInput)
		{
			if (FlxG.keys.justPressed.F1)
			{
				FlxG.save.data.showHelp = !FlxG.save.data.showHelp;
				helpText.visible = FlxG.save.data.showHelp;
			}

			if (FlxG.keys.justPressed.SHIFT)
				doSnapShit = !doSnapShit;

			if (curSelectedNote != null && curSelectedNote[2] > -1)
			{
				if (FlxG.keys.justPressed.E)
				{
					changeNoteSustain(Conductor.stepCrochet * sustainQuant);
				}
				if (FlxG.keys.justPressed.Q)
				{
					changeNoteSustain(-Conductor.stepCrochet * sustainQuant);
				}
			}

			if (FlxG.keys.justPressed.W && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
			{
				goToSection(curSection - 1);
			}
			else if (FlxG.keys.justPressed.S && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
			{
				goToSection(curSection + 1);
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

			if (FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.C)
			{
				if (selectedBoxes.members.length != 0)
				{
					copiedNotes = [];
					for (i in selectedBoxes.members)
					{
						copiedNotes.push([
							i.connectedNote.strumTime,
							i.connectedNote.rawNoteData,
							i.connectedNote.sustainLength,
							i.connectedNote.beat,
							i.connectedNote.noteShit
						]);
					}

					var firstNote = copiedNotes[0][0];

					for (i in copiedNotes) // normalize the notes
					{
						i[0] = i[0] - firstNote;
					}
				}
			}

			if (FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.V)
			{
				if (copiedNotes.length != 0)
				{
					destroyBoxes();
					pasteNotesFromArray(copiedNotes);

					lastAction = "paste";
				}
			}

			if (FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.Z)
			{
				switch (lastAction)
				{
					case "paste":
						if (pastedNotes.length != 0)
						{
							for (i in pastedNotes)
							{
								deleteNote(i);
							}
							updateNotes();

							pastedNotes = [];
						}
					case "delete":
						if (deletedNotes.length != 0)
						{
							pasteNotesFromArray(deletedNotes, false);
							deletedNotes = [];
						}
				}
			}

			if (FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.BACKSPACE)
			{
				lastAction = "delete";
				var notesToBeDeleted = [];
				deletedNotes = [];
				for (i in 0...selectedBoxes.members.length)
				{
					deletedNotes.push([
						selectedBoxes.members[i].connectedNote.strumTime,
						selectedBoxes.members[i].connectedNote.rawNoteData,
						selectedBoxes.members[i].connectedNote.sustainLength,
						selectedBoxes.members[i].connectedNote.beat,
						selectedBoxes.members[i].connectedNote.noteShit
					]);
					notesToBeDeleted.push(selectedBoxes.members[i].connectedNote);
				}

				for (i in notesToBeDeleted)
				{
					deleteNote(i);
				}
				updateNotes();
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
				{
					pitch += 0.05;
				}
				else if (FlxG.keys.justPressed.LEFT)
				{
					pitch -= 0.05;
				}

				if (pitch > 3)
					pitch = 3;
				if (pitch <= 0.05)
					pitch = 0.05;
			}

			if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT)
			{
				curQuant++;
				if (curQuant > quantizations.length - 1)
					curQuant = 0;

				quantization = quantizations[curQuant];
			}

			if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL && FlxG.keys.pressed.ALT)
			{
				curQuant--;
				if (curQuant < 0)
					curQuant = quantizations.length - 1;

				quantization = quantizations[curQuant];
			}

			if (!FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
			{
				noteShitDrop.selectedIndex--;
				if (noteShitDrop.selectedIndex < 0)
				{
					noteShitDrop.selectedIndex = noteTypes.length - 1;
				}
				noteType = noteTypes[noteShitDrop.selectedIndex];
				updateNotetypeText();
			}

			if (!FlxG.keys.pressed.ALT && !FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
			{
				noteShitDrop.selectedIndex++;
				if (noteShitDrop.selectedIndex == noteTypes.length)
					noteShitDrop.selectedIndex = 0;

				noteType = noteTypes[noteShitDrop.selectedIndex];
				updateNotetypeText();
			}

			if (FlxG.keys.justPressed.ENTER)
			{
				PlayState.SONG = SONG;
				inst.stop();
				if (!SONG.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsP.stop();
					vocalsE.stop();
				}
				MusicBeatState.switchState(new PlayState());
				Lib.clearInterval(id);
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				PlayState.SONG = SONG;
				inst.stop();
				if (!SONG.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsP.stop();
					vocalsE.stop();
				}
				MusicBeatState.switchState(new FreeplayState());
				Lib.clearInterval(id);
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				if (inst.playing)
				{
					inst.pause();
					if (!SONG.splitVoiceTracks)
						vocals.pause();
					else
					{
						vocalsP.pause();
						vocalsE.pause();
					}
				}
				else
				{
					inst.time = lastConductorPos;
					if (!SONG.splitVoiceTracks)
					{
						vocals.time = inst.time;
						vocals.play();
					}
					else
					{
						vocalsP.time = inst.time;
						vocalsE.time = inst.time;
						vocalsP.play();
						vocalsE.play();
					}
					inst.play();
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				if (inst.playing)
				{
					inst.pause();

					if (!SONG.splitVoiceTracks)
						vocals.pause();
					else
					{
						vocalsP.pause();
						vocalsE.pause();
					}
				}

				var amount = FlxG.mouse.wheel;

				if (amount > 0 && strumLine.y < -100)
					amount = 0;

				if (doSnapShit)
				{
					var increase:Float = 0;
					var beats:Float = 0;
					var snap = quantization / 4;

					if (amount < 0)
					{
						increase = 1 / snap;
						beats = (Math.floor((curDecimalBeat * snap) + 0.001) / snap) + increase;
					}
					else
					{
						increase = -1 / snap;
						beats = ((Math.ceil(curDecimalBeat * snap) - 0.001) / snap) + increase;
					}

					var data = TimingStruct.getTimingAtBeat(beats);
					if (beats <= 0)
						inst.time = 0;

					var bpm = data != null ? data.bpm : SONG.bpm;

					if (data != null)
					{
						inst.time = (data.startTime + ((beats - data.startBeat) / (bpm / 60))) * 1000;
					}
				}
				else
				{
					if (amount < 0)
						inst.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);
				}

				if (!SONG.splitVoiceTracks)
					vocals.time = inst.time;
				else
				{
					vocalsP.time = inst.time;
					vocalsE.time = inst.time;
				}
			}
		}

		var playedSound:Array<Bool> = [false, false, false, false, false, false, false, false];
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			if (note.strumTime <= Conductor.songPosition)
			{
				if (note.strumTime > lastConductorPos && inst.playing && note.noteData > -1 && note.hitsoundsEditor)
				{
					var data:Int = note.noteData;
					var noteDataToCheck:Int = note.noteData;
					var playerNote = note.noteData >= 4;
					if (!playedSound[data])
					{
						if ((FlxG.save.data.playHitsounds && playerNote) || (FlxG.save.data.playHitsoundsE && !playerNote))
						{
							if (FlxG.save.data.hitSound == 0)
							{
								daHitSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/snap', 'shared'));
							}
							else
							{
								daHitSound = new FlxSound()
									.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
							}
							daHitSound.volume = hitsoundsVol.pos;
							daHitSound.play().pan = note.noteData < 4 ? -0.3 : 0.3;
							playedSound[data] = true;
						}
						data = note.noteData;
					}
				}
			}
		});

		infoText.text = "Song : "
			+ SONG.songName
			+ "\nDifficulty : "
			+ curDiff
			+ "\nSong Position : "
			+ Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(inst.length / 1000, 2))
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
			+ quantizations[curQuant]
			+ "\n"
			+ "Quantization : "
			+ doSnapShit;
		infoText.updateHitbox();
		lastConductorPos = Conductor.songPosition;

		super.update(elapsed);
	}

	function updateNotes()
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();

		var curSection = 0;

		for (section in SONG.notes)
		{
			if (section != null)
				for (i in section.sectionNotes)
				{
					var seg = TimingStruct.getTimingAtTimestamp(i[0]);
					var daNoteInfo = i[1];
					var daStrumTime = i[0];
					var daSus = i[2];
					var daType = i[4];
					var daBeat = TimingStruct.getBeatFromTime(daStrumTime);

					var gottaHitNote:Bool = false;
					if (daNoteInfo > 3)
						gottaHitNote = true;
					else if (daNoteInfo <= 3)
						gottaHitNote = false;

					var note:Note = new Note(daStrumTime, daNoteInfo, null, false, true, gottaHitNote, daBeat);
					note.rawNoteData = daNoteInfo;
					note.noteShit = daType;
					note.sustainLength = daSus;
					note.strumTime = daStrumTime;

					note.setGraphicSize(Math.floor(noteSize), Math.floor(noteSize));
					note.updateHitbox();
					note.x = Math.floor(note.rawNoteData * noteSize) + notePos;
					note.y = Math.floor(getYfromStrum(daStrumTime) * size);
					curRenderedNotes.add(note);

					if (daSus > 0)
					{
						var sustainVis:FlxSprite = new FlxSprite(note.x + (50 * size) - 2, note.y + 50).makeGraphic(1, 1);
						sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * size) - note.y));
						note.noteCharterObject = sustainVis;
						sustainVis.updateHitbox();

						curRenderedSustains.add(sustainVis);
					}
				}
		}
	}

	function regenerateLines()
	{
		while (lines.members.length > 0)
		{
			lines.members[0].destroy();
			lines.members.remove(lines.members[0]);
		}

		while (texts.members.length > 0)
		{
			texts.members[0].destroy();
			texts.members.remove(texts.members[0]);
		}

		if (SONG.eventObjects != null)
		{
			for (i in sectionRenderers)
			{
				var pos = getYfromStrum(i.section.startTime) * size;

				var line = new FlxSprite(100, pos).makeGraphic(Std.int(noteSize * 8), 4, FlxColor.BLACK);
				line.alpha = 1;
				lines.add(line);
			}

			for (i in SONG.eventObjects)
			{
				var seg = TimingStruct.getTimingAtBeat(i.position);

				var posi:Float = 0;

				if (seg != null)
				{
					var start:Float = (i.position - seg.startBeat) / (seg.bpm / 60);

					posi = seg.startTime + start;
				}

				var pos = getYfromStrum(posi * 1000) * size;

				if (pos < 0)
					pos = 0;

				var type = i.type;

				var text = new FlxText(500, pos, 0, i.name + "\n" + type + "\n" + i.value + "\n" + i.value2, 16);
				text.borderStyle = OUTLINE_FAST;
				text.borderColor = FlxColor.BLACK;
				text.font = Paths.font("vcr.ttf");
				var line = new FlxSprite(100, pos).makeGraphic(Std.int(noteSize * 8), 4, FlxColor.BLUE);

				line.alpha = 0.5;

				lines.add(line);
				texts.add(text);
			}
		}
	}

	inline function loadRenders()
	{
		var sections = Math.floor(((lengthInSteps + 16)) / 16);

		var targetY = getYfromStrum(inst.length);

		for (awfgaw in 0...Math.round(targetY / 600)) // grids/steps
		{
			var renderer = new SectionRender(sectionPos, 600 * awfgaw, 50);
			if (SONG.notes[awfgaw] == null)
				SONG.notes.push(newSection(16, true));

			renderer.section = SONG.notes[awfgaw];

			sectionRenderers.add(renderer);
			sectionY = Math.floor(renderer.y);
		}
	}

	private function addNote(?n:Note):Void
	{
		destroyBoxes();

		var strum = getStrumTime(dummyArrow.y) / 0.5;

		var section = getSectionByTime(strum);

		if (section == null)
			return;
		var noteStrum = strum;
		var noteData = Std.int(Math.floor(dummyArrow.x - sectionPos) / 50);
		var noteSus = 0;
		var noteShit = noteTypes[noteShitDrop.selectedIndex];

		for (note in section.sectionNotes)
		{
			if (note[0] == noteStrum && note[1] == noteData)
			{
				Debug.logWarn('A note is already in this place. Deleting...');

				for (otherNote in curRenderedNotes)
				{
					if (otherNote.strumTime == noteStrum && otherNote.rawNoteData == noteData)
						deleteNote(otherNote);
				}
				return;
			}
		}

		if (n != null)
			section.sectionNotes.push([
				n.strumTime,
				n.noteData,
				n.sustainLength,
				TimingStruct.getBeatFromTime(n.strumTime),
				n.noteShit
			]);
		else
			section.sectionNotes.push([noteStrum, noteData, noteSus, TimingStruct.getBeatFromTime(noteStrum), noteShit]);

		if (FlxG.save.data.gen)
			Debug.logTrace("Adding note with " + noteStrum + " with data " + noteData + " With A Notetype Of " + noteShit);

		var seg = TimingStruct.getTimingAtTimestamp(noteStrum);

		var gottaHitNote:Bool = false;
		if (noteData > 3)
			gottaHitNote = true;
		else if (noteData <= 3)
			gottaHitNote = false;

		if (n == null)
		{
			var note:Note = new Note(noteStrum, noteData, null, false, true, gottaHitNote, TimingStruct.getBeatFromTime(noteStrum));
			note.rawNoteData = noteData;
			note.sustainLength = noteSus;
			note.noteShit = noteShit;
			note.setGraphicSize(Math.floor(noteSize), Math.floor(noteSize));
			note.updateHitbox();
			note.x = Math.floor(note.rawNoteData * noteSize) + notePos;

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;

			curSelectedNoteObject.charterSelected = true;
			note.y = Math.floor(getYfromStrum(noteStrum) * size);
			curRenderedNotes.add(note);
			selectNote(note);
		}
		else
		{
			var note:Note = new Note(n.strumTime, n.noteData, null, false, true, gottaHitNote, TimingStruct.getBeatFromTime(n.strumTime));
			note.rawNoteData = n.noteData;
			note.sustainLength = noteSus;
			note.noteShit = noteShit;
			note.setGraphicSize(Math.floor(noteSize), Math.floor(noteSize));
			note.updateHitbox();
			note.x = Math.floor(note.rawNoteData * noteSize) + notePos;

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;

			curSelectedNoteObject.charterSelected = true;
			note.y = Math.floor(getYfromStrum(noteStrum) * size);
			curRenderedNotes.add(note);
			selectNote(note);
		}
		var thingy = section.sectionNotes[section.sectionNotes.length - 1];

		curSelectedNote = thingy;

		autosaveSong();
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (sec in SONG.notes)
		{
			swagNum = 0;
			if (sec != null)
				for (i in sec.sectionNotes)
				{
					if (i[0] == note.strumTime && i[1] == note.rawNoteData)
					{
						curSelectedNote = sec.sectionNotes[swagNum];
						if (curSelectedNoteObject != null)
							curSelectedNoteObject.charterSelected = false;

						curSelectedNoteObject = note;
						if (!note.charterSelected)
						{
							var box = new ChartingBox(note.x, note.y, note);
							box.connectedNoteData = i;
							selectedBoxes.add(box);
							note.charterSelected = true;
							curSelectedNoteObject.charterSelected = true;
						}
					}
					swagNum += 1;
				}
		}
	}

	function deleteNote(note:Note):Void
	{
		destroyBoxes();

		var section = getSectionByTime(note.strumTime);

		var found = false;

		if (section != null)
		{
			for (i in section.sectionNotes)
			{
				if (i[0] == note.strumTime && i[1] == note.rawNoteData)
				{
					section.sectionNotes.remove(i);
					found = true;
				}
			}
		}

		if (!found) // backup check
		{
			for (i in SONG.notes)
			{
				for (n in i.sectionNotes)
					if (n[0] == note.strumTime && n[1] == note.rawNoteData)
						i.sectionNotes.remove(n);
			}
		}
		curRenderedNotes.remove(note, true);

		curSelectedNote = null;
		strumTime.text = "0";

		if (note.sustainLength > 0)
			curRenderedSustains.remove(note.noteCharterObject, true);

		for (i in 0...selectedBoxes.members.length)
		{
			var box = selectedBoxes.members[i];
			if (box.connectedNote == note)
			{
				selectedBoxes.members.remove(box);
				box.destroy();
				return;
			}
		}

		note.kill();
		note.destroy();
		note = null;
	}

	inline function destroyBoxes()
	{
		while (selectedBoxes.members.length != 0)
		{
			selectedBoxes.members[0].connectedNote.charterSelected = false;
			selectedBoxes.members[0].destroy();
			selectedBoxes.members.remove(selectedBoxes.members[0]);
		}
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote != null)
		{
			if (curSelectedNote[2] != null)
			{
				curSelectedNote[2] += Math.ceil(value);
				curSelectedNote[2] = Math.max(curSelectedNote[2], 0);

				if (curSelectedNoteObject.noteCharterObject != null)
					curRenderedSustains.remove(curSelectedNoteObject.noteCharterObject, true);

				if (curSelectedNote[2] > 0)
				{
					var sustainVis:FlxSprite = new FlxSprite(curSelectedNoteObject.x + (noteSize * size) - 2, curSelectedNoteObject.y + noteSize);
					sustainVis.makeGraphic(1, 1);
					sustainVis.setGraphicSize(8,
						Math.floor((getYfromStrum(curSelectedNoteObject.strumTime + curSelectedNote[2]) * size) - curSelectedNoteObject.y));
					sustainVis.updateHitbox();

					curSelectedNoteObject.sustainLength = curSelectedNote[2];
					curSelectedNoteObject.noteCharterObject = sustainVis;

					curRenderedSustains.add(sustainVis);
				}
			}
		}
	}

	function offsetSelectedNotes(offset:Float)
	{
		var toDelete:Array<Note> = [];
		var toAdd:Array<ChartingBox> = [];

		// For each selected note...
		for (i in 0...selectedBoxes.members.length)
		{
			var originalNote = selectedBoxes.members[i].connectedNote;
			// Delete after the fact to avoid tomfuckery.
			toDelete.push(originalNote);

			var strum = originalNote.strumTime + offset;
			// Remove the old note.
			// Find the position in the song to put the new note.
			for (ii in SONG.notes)
			{
				if (ii.startTime <= strum && ii.endTime > strum)
				{
					// alright we're in this section lets paste the note here.
					var newData:Array<Dynamic> = [
						strum,
						originalNote.rawNoteData,
						originalNote.sustainLength,
						originalNote.beat,
						originalNote.noteShit
					];
					ii.sectionNotes.push(newData);

					var thing = ii.sectionNotes[ii.sectionNotes.length - 1];

					var gottaHitNote:Bool = false;
					if (originalNote.noteData > 3)
						gottaHitNote = true;
					else if (originalNote.noteData <= 3)
						gottaHitNote = false;

					var note:Note = new Note(strum, originalNote.noteData, originalNote.prevNote, false, true, gottaHitNote, originalNote.beat);
					note.rawNoteData = originalNote.rawNoteData;
					note.sustainLength = originalNote.sustainLength;
					note.noteShit = originalNote.noteShit;
					note.setGraphicSize(Math.floor(noteSize), Math.floor(noteSize));
					note.updateHitbox();
					note.x = Math.floor(originalNote.rawNoteData * noteSize) + notePos;
					note.y = Math.floor(getYfromStrum(strum) * size);

					note.charterSelected = true;

					var box = new ChartingBox(note.x, note.y, note);
					box.connectedNoteData = thing;
					// Add to selection after the fact to avoid tomfuckery.
					toAdd.push(box);

					curRenderedNotes.add(note);

					pastedNotes.push(note);

					if (note.sustainLength > 0)
					{
						var sustainVis:FlxSprite = new FlxSprite(note.x + (50 * size) - 2, note.y + 50).makeGraphic(1, 1);
						sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * size) - note.y));
						sustainVis.updateHitbox();

						note.noteCharterObject = sustainVis;

						curRenderedSustains.add(sustainVis);
					}

					// selectNote(note);
					continue;
				}
			}
		}

		for (note in toDelete)
		{
			deleteNote(note);
		}
		for (box in toAdd)
		{
			selectedBoxes.add(box);
		}

		updateNotes();

		// ok so basically theres a bug with color quant that it doesn't update the color until the grid updates.
		// when the grid updates, it causes a massive performance drop everytime we offset the notes. :/
		// actually its broken either way because theres a ghost note after offsetting sometimes. updateGrid anyway.
		// now sustains don't get shifted. I don't know.
	}

	function pasteNotesFromArray(array:Array<Array<Dynamic>>, fromStrum:Bool = true)
	{
		if (copiedNotes.length < 0)
		{
			return;
		}
		else
		{
			for (i in array)
			{
				var strum:Float = i[0];
				if (fromStrum)
					strum += Conductor.songPosition;
				var section = 0;
				for (ii in SONG.notes)
				{
					if (ii.startTime <= strum && ii.endTime > strum)
					{
						// alright we're in this section lets paste the note here.
						var newData:Array<Any> = [strum, i[1], i[2], i[3], i[4]];
						ii.sectionNotes.push(newData);

						var thing = ii.sectionNotes[ii.sectionNotes.length - 1];
						var gottaHitNote:Bool = false;
						if (i[1] > 3)
							gottaHitNote = true;
						else if (i[1] <= 3)
							gottaHitNote = false;
						var note:Note = new Note(strum, newData[1], null, false, true, gottaHitNote, newData[3]);
						note.rawNoteData = newData[1];
						note.sustainLength = newData[2];
						note.noteShit = newData[4];
						note.setGraphicSize(Math.floor(noteSize), Math.floor(noteSize));
						note.updateHitbox();
						note.x = Math.floor(note.rawNoteData * noteSize) + notePos;
						note.y = Math.floor(getYfromStrum(strum) * size);

						note.charterSelected = true;

						var box = new ChartingBox(note.x, note.y, note);
						box.connectedNoteData = thing;
						selectedBoxes.add(box);

						curRenderedNotes.add(note);

						pastedNotes.push(note);

						if (note.sustainLength > 0)
						{
							var sustainVis:FlxSprite = new FlxSprite(note.x + (50 * size) - 2, note.y + 50).makeGraphic(1, 1);
							sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * size) - note.y));
							sustainVis.updateHitbox();
							note.noteCharterObject = sustainVis;

							curRenderedSustains.add(sustainVis);
						}
						continue;
					}
					section++;
				}
			}
			updateNotes();
		}
	}

	function containsName(name:String, events:Array<Song.Event>):Song.Event
	{
		for (i in events)
		{
			var thisName = Reflect.field(i, "name");

			if (thisName == name)
				return i;
		}
		return null;
	}

	function clearSection():Void
	{
		destroyBoxes();

		SONG.notes[curSection].sectionNotes = [];
		updateNotes();
	}

	function swapSection(secit:SwagSection)
	{
		destroyBoxes();
		for (i in 0...secit.sectionNotes.length)
		{
			var note:Array<Dynamic> = secit.sectionNotes[i];
			note[1] = (note[1] + 4) % 8;
			secit.sectionNotes[i] = note;
		}

		updateNotes();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, 16, 0, 16);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, 16, 0, 16);
	}

	function getSectionSteps(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSection;
		var val:Null<Float> = null;

		if (SONG.notes[section] != null)
			val = SONG.notes[section].lengthInSteps;
		return val != null ? val : 16;
	}

	function goToSection(section:Int)
	{
		var beat = section * 4;
		var data = TimingStruct.getTimingAtTimestamp(beat);

		if (data == null)
			return;

		inst.time = (data.startTime + ((beat - data.startBeat) / (data.bpm / 60))) * 1000;
		if (!SONG.splitVoiceTracks)
			vocals.time = inst.time;
		else
		{
			vocalsP.time = inst.time;
			vocalsE.time = inst.time;
		}
		curSection = section;
		if (inst.time < 0)
			inst.time = 0;
		else if (inst.time > inst.length)
			inst.time = inst.length;
	}

	function updateNotetypeText()
	{
		notetypetext.text = "Note Type: " + noteType;
		notetypetext.updateHitbox();
	}

	function autosaveSong():Void
	{
		if (FlxG.save.data.autoSaving)
		{
			FlxG.save.data.autosave = haxe.Json.stringify({
				"song": SONG,
			});

			trace('Chart Saved');
			FlxG.save.flush();
		}
		else
		{
			trace('You Have Auto Saving Disabled.');
		}
	}

	function loadSong(daSong:String, reloadFromFile:Bool = false):Void
	{
		inst = FlxG.sound.load(Paths.inst(SONG.audioFile));
		if (inst != null)
		{
			inst.stop();
		}
		if (reloadFromFile)
		{
			var diff:String = CoolUtil.getSuffixFromDiff(curDiff);
			SONG = Song.conversionChecks(Song.loadFromJson(SONG.songId, diff));
		}
		try
		{
			if (!SONG.splitVoiceTracks)
			{
				if (SONG.needsVoices)
					vocals = FlxG.sound.load(Paths.voices(SONG.audioFile));
				else
					vocals = new FlxSound();
				FlxG.sound.list.add(vocals);
			}
			else
			{
				if (SONG.needsVoices)
				{
					vocalsP = FlxG.sound.load(Paths.voices(SONG.audioFile, 'P'));
					vocalsE = FlxG.sound.load(Paths.voices(SONG.audioFile, 'E'));
				}
				else
				{
					vocalsP = new FlxSound();
					vocalsE = new FlxSound();
				}
				FlxG.sound.list.add(vocalsP);
				FlxG.sound.list.add(vocalsE);
			}
		}
		catch (e)
		{
			vocals = new FlxSound();
			FlxG.sound.list.add(vocals);
			SONG.splitVoiceTracks = false;
			Debug.logTrace("Your Song Doesn't Have A Voice File Or Something Else. Make Sure Your Song Has The Correct Audio." + e);
		}
		FlxG.sound.list.add(inst);

		inst.play();
		inst.pause();
		if (!SONG.splitVoiceTracks)
		{
			vocals.play();
			vocals.pause();
		}
		else
		{
			vocalsP.play();
			vocalsE.play();
			vocalsP.pause();
			vocalsE.pause();
		}

		inst.onComplete = function()
		{
			if (!SONG.splitVoiceTracks)
			{
				vocals.pause();
				vocals.time = 0;
			}
			else
			{
				vocalsP.pause();
				vocalsP.time = 0;
				vocalsE.pause();
				vocalsE.time = 0;
			}
			inst.pause();
			inst.time = 0;
		};
	}

	function loadAutosave():Void
	{
		var autoSaveData = Json.parse(FlxG.save.data.autosave);

		var json = {
			"song": SONG
		};

		var data:String = haxe.Json.stringify(json, null, " ");

		var data:SongData = cast autoSaveData;
		var meta:SongMeta = {};
		var name:String = data.songId;
		if (autoSaveData.song != null)
		{
			meta = autoSaveData.songMeta != null ? cast autoSaveData.songMeta : {};
		}

		// fard

		PlayState.SONG = Song.parseJSONshit(data.songId, data, meta);
		LoadingState.loadAndSwitchState(new ChartingState());
		Lib.clearInterval(id);
	}

	function loadJson(songId:String, diff:String):Void
	{
		try
		{
			PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(diff);
			PlayState.SONG = Song.loadFromJson(songId.toLowerCase(), CoolUtil.getSuffixFromDiff(diff));

			Debug.logTrace(songId);
			// mustCleanMem = true;

			LoadingState.loadAndSwitchState(new ChartingState());
			Lib.clearInterval(id);
		}
		catch (e)
		{
			NotificationManager.instance.addNotification({
				title: "Error Changing Difficulty.",
				body: "Make Sure A Difficulty Exists For The One You Want To Change To.",
				type: NotificationType.Error
			});
			Debug.logError('Make Sure You Have A Valid JSON To Load. A Possible Solution Is Setting The Difficulty To Normal. Error: $e');
			return;
		}
	}

	private function saveLevel()
	{
		SONG.chartVersion = Song.latestChart;

		var json = {
			"song": SONG
		};

		var data:String = haxe.Json.stringify(json, null, " ");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop Event.SELECT #else Event.COMPLETE #end, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), SONG.songId.toLowerCase() + CoolUtil.getSuffixFromDiff(curDiff) + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
		NotificationManager.instance.addNotification({
			title: "Chart Saved Successfully.",
			body: "Your Chart Was Saved Without Error.",
			type: NotificationType.Success
		});
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		NotificationManager.instance.addNotification({
			title: "Chart Save Cancelled.",
			body: "Cancelled Saving Chart.",
			type: NotificationType.Info
		});
	}

	/**
	 * Called if there is an error while saving the gameplay recording.
	 */
	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
		NotificationManager.instance.addNotification({
			title: "Error Saving Chart.",
			body: "There Has Been An Error Saving The Chart.",
			type: NotificationType.Error
		});
	}

	inline function songShit()
	{
		try
		{
			if (SONG != null)
			{
				SONG.player1 = playerDrop.text;
				SONG.player2 = opponentDrop.text;
				SONG.gfVersion = gfDrop.text;
				SONG.stage = stageDrop.text;
				SONG.style = noteStyleDrop.text;

				SONG.songId = song.text;
				SONG.audioFile = audioFileName.text;
				SONG.songName = songName.text;

				if (curSelectedNote != null)
				{
					strumTime.text = curSelectedNote[0];
				}
			}
		}
	}

	inline function addAssetUI()
	{
		var vbox1:VBox = new VBox();
		var vbox2:VBox = new VBox();
		var grid = new Grid();

		playerDrop = new DropDown();
		playerDrop.text = SONG.player1;
		playerDrop.width = 100;

		var p1Label = new Label();
		p1Label.text = "Player";
		p1Label.verticalAlign = "center";

		opponentDrop = new DropDown();
		opponentDrop.text = SONG.player2;
		opponentDrop.width = 100;

		var p2Label = new Label();
		p2Label.text = "Opponent";
		p2Label.verticalAlign = "center";

		gfDrop = new DropDown();
		gfDrop.text = SONG.gfVersion;
		gfDrop.width = 75;

		var gfLabel = new Label();
		gfLabel.text = "GF";
		gfLabel.verticalAlign = "center";

		stageDrop = new DropDown();
		stageDrop.text = SONG.stage;
		stageDrop.width = 100;

		var stageLabel = new Label();
		stageLabel.text = "Stage";
		stageLabel.verticalAlign = "center";

		noteStyleDrop = new DropDown();
		noteStyleDrop.text = SONG.style;
		noteStyleDrop.width = 100;

		var nsLabel = new Label();
		nsLabel.text = "Song Style";
		nsLabel.verticalAlign = "center";

		var ds = new ArrayDataSource<Dynamic>();
		for (c in 0...characters.length)
		{
			ds.add(characters[c]);
		}
		playerDrop.dataSource = ds;
		opponentDrop.dataSource = ds;

		var gfList = new ArrayDataSource<Dynamic>();
		for (gf in 0...gfs.length)
		{
			gfList.add(gfs[gf]);
		}
		gfDrop.dataSource = gfList;

		var stageList = new ArrayDataSource<Dynamic>();
		for (stage in 0...stages.length)
		{
			stageList.add(stages[stage]);
		}
		stageDrop.dataSource = stageList;

		var styleList = new ArrayDataSource<Dynamic>();
		for (style in 0...noteStyles.length)
		{
			styleList.add(noteStyles[style]);
		}
		noteStyleDrop.dataSource = styleList;

		vbox1.addComponent(p1Label);
		vbox1.addComponent(playerDrop);
		vbox2.addComponent(p2Label);
		vbox2.addComponent(opponentDrop);
		vbox2.addComponent(stageLabel);
		vbox2.addComponent(stageDrop);
		vbox1.addComponent(gfLabel);
		vbox1.addComponent(gfDrop);
		vbox1.addComponent(nsLabel);
		vbox1.addComponent(noteStyleDrop);

		grid.addComponent(vbox1);
		grid.addComponent(vbox2);

		box.addComponent(grid);
	}

	inline function addNoteUI()
	{
		strumTime = new TextField();
		strumTime.text = "0";
		strumTime.onChange = function(e)
		{
			if (curSelectedNote == null)
				return;
			var value:Float = Std.parseFloat(strumTime.text);
			if (Math.isNaN(value))
				value = 0;
			curSelectedNote[0] = value;
			// updateNotes();
		}

		var timeLabel = new Label();
		timeLabel.text = "Strum Time (In MS)";
		timeLabel.verticalAlign = "center";

		noteShitDrop = new DropDown();
		noteShitDrop.text = "Normal";
		noteShitDrop.width = 100;

		var typeList = new ArrayDataSource<Dynamic>();
		for (type in 0...noteTypes.length)
		{
			typeList.add(noteTypes[type]);
		}
		noteShitDrop.dataSource = typeList;
		noteShitDrop.selectedIndex = 0;
		noteShitDrop.onChange = function(e)
		{
			noteType = noteTypes[noteShitDrop.selectedIndex];
		}

		var typeLabel = new Label();
		typeLabel.text = "Note Type";
		typeLabel.verticalAlign = "center";

		box2.addComponent(strumTime);
		box2.addComponent(timeLabel);
		box2.addComponent(noteShitDrop);
		box2.addComponent(typeLabel);
	}

	inline function addSectionUI()
	{
		secBox = new VBox();
		secBox2 = new VBox();
		secGrid = new Grid();
		secGrid2 = new Grid();

		playerSection = new CheckBox();
		playerSection.text = "Camera Focus P1";
		playerSection.selected = true;
		playerSection.onClick = function(e)
		{
			var sect = lastUpdatedSection;

			if (sect == null)
				return;

			sect.playerSec = playerSection.selected;
		}

		refreshSec = new Button();
		refreshSec.text = "Refresh All Sections";
		refreshSec.onClick = function(e)
		{
			var section = getSectionByTime(Conductor.songPosition);

			if (section == null)
				return;

			playerSection.selected = section.playerSec;

			updateNotes();
		}

		clearSec = new Button();
		clearSec.text = "Clear Section";
		clearSec.onClick = function(e)
		{
			clearSection();
		}

		swapSec = new Button();
		swapSec.text = "Swap Section";
		swapSec.onClick = function(e)
		{
			var secit = SONG.notes[curSection];

			if (secit != null)
			{
				var secit = SONG.notes[curSection];

				if (secit != null)
				{
					swapSection(secit);
				}
			}
		}

		duet = new Button();
		duet.text = "Duet Notes";
		duet.onClick = function(e)
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in SONG.notes[curSection].sectionNotes)
			{
				var boob = note[1];
				if (boob > 3)
				{
					boob -= 4;
				}
				else
				{
					boob += 4;
				}

				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				SONG.notes[curSection].sectionNotes.push(i);
			}

			updateNotes();
		}

		mirror = new Button();
		mirror.text = "Mirror Notes";
		mirror.onClick = function(e)
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in SONG.notes[curSection].sectionNotes)
			{
				var boob = note[1] % 4;
				boob = 3 - boob;
				if (note[1] > 3)
					boob += 4;

				note[1] = boob;
				var copiedNote:Array<Dynamic> = [note[0], boob, note[2], note[3]];
				// duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				// SONG.notes[curSec].sectionNotes.push(i);
			}

			destroyBoxes();

			updateNotes();
		}

		var sectionToCopy:Int = 0;

		copySec = new Button();
		copySec.text = "Copy Section";
		copySec.onClick = function(e)
		{
			copiedNotes = [];
			sectionToCopy = curSection;
			var secit = SONG.notes[curSection];
			for (i in 0...secit.sectionNotes.length)
			{
				var note:Array<Dynamic> = secit.sectionNotes[i];
				copiedNotes.push(note);
			}
		}

		pasteSec = new Button();
		pasteSec.text = "Paste Section";
		pasteSec.onClick = function(e)
		{
			destroyBoxes();

			if (copiedNotes == null || copiedNotes.length < 1)
			{
				return;
			}

			var addToTime:Float = Conductor.stepCrochet * (getSectionSteps() * (curSection - sectionToCopy));
			// trace('Time to add: ' + addToTime);
			for (note in copiedNotes)
			{
				var copiedNote:Array<Dynamic> = [];
				var newStrumTime:Float = note[0] + addToTime;
				copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
				SONG.notes[curSection].sectionNotes.push(copiedNote);
			}

			updateNotes();
		}

		clearCopiedNotes = new Button();
		clearCopiedNotes.text = "Clear Copied Notes";
		clearCopiedNotes.onClick = function(e)
		{
			copiedNotes = [];
		}

		secBox.addComponent(playerSection); // really weird methods
		secBox.addComponent(refreshSec);
		secBox.addComponent(clearSec);
		secBox.addComponent(copySec);
		secBox.addComponent(pasteSec);
		secBox.addComponent(clearCopiedNotes);
		secBox.addComponent(swapSec);
		secBox.addComponent(mirror);
		secBox.addComponent(duet);

		secGrid.addComponent(secBox);

		box3.addComponent(secGrid);
	}

	function addSongUI()
	{
		vbox1 = new VBox();
		vbox3 = new VBox();
		grid = new Grid();
		var grid2 = new Grid();

		song = new TextField();
		song.text = SONG.songId;
		song.width = 100;

		var songId = new Label();
		songId.text = "Song ID";
		songId.verticalAlign = "center";

		songName = new TextField();
		songName.text = SONG.songName;
		songName.width = 100;

		var displayName = new Label();
		displayName.text = "Display Name";
		displayName.verticalAlign = "center";

		audioFileName = new TextField();
		audioFileName.text = SONG.audioFile;
		audioFileName.width = 100;

		var audioFile = new Label();
		audioFile.text = "Audio File";
		audioFile.verticalAlign = "center";

		hasVoices = new CheckBox();
		hasVoices.selected = SONG.needsVoices;
		hasVoices.text = "Use Vocals";
		hasVoices.onClick = function(e)
		{
			SONG.needsVoices = !SONG.needsVoices;
		}

		isSplit = new CheckBox();
		isSplit.text = "Split Vocals";
		isSplit.selected = SONG.splitVoiceTracks;
		isSplit.onClick = function(e)
		{
			SONG.splitVoiceTracks = !SONG.splitVoiceTracks;
		}

		bpm = new NumberStepper();
		bpm.max = 666; // this is a reference that you will likely not understand FNVX
		bpm.min = 1;
		bpm.precision = 3;
		bpm.step = 0.1;
		bpm.pos = SONG.bpm;
		bpm.decimalSeparator = ".";
		bpm.onChange = function(e)
		{
			SONG.bpm = bpm.pos;
			for (section in SONG.notes)
			{
				section.bpm = bpm.pos;
			}

			if (SONG.eventObjects[0].type != "BPM Change")
				lime.app.Application.current.window.alert("i'm crying, first event isn't a bpm change. fuck you");
			else
			{
				SONG.eventObjects[0].value = bpm.pos;
			}

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				var name = Reflect.field(i, "name");
				var type = Reflect.field(i, "type");
				var pos = Reflect.field(i, "position");
				var value = Reflect.field(i, "value");
				var value2 = Reflect.field(i, "value2");

				if (type == "BPM Change")
				{
					var beat:Float = pos;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}

					currentIndex++;
				}
			}

			recalculateAllSectionTimes();

			regenerateLines();

			updateNotes();
		}

		var bpmLabel = new Label();
		bpmLabel.text = "BPM";
		bpmLabel.verticalAlign = "center";

		scrollSpeed = new NumberStepper();
		scrollSpeed.max = 10;
		scrollSpeed.min = 0.1;
		scrollSpeed.precision = 2;
		scrollSpeed.step = 0.1;
		scrollSpeed.pos = SONG.speed;
		scrollSpeed.decimalSeparator = ".";
		scrollSpeed.autoCorrect = true;
		scrollSpeed.onChange = function(e)
		{
			SONG.speed = scrollSpeed.pos;
		}

		var ssLabel = new Label();
		ssLabel.text = "Scroll Speed";
		ssLabel.verticalAlign = "center";

		instVol = new NumberStepper();
		instVol.max = 1;
		instVol.min = 0;
		instVol.precision = 2;
		instVol.step = 0.1;
		instVol.pos = inst.volume;
		instVol.decimalSeparator = ".";
		instVol.onChange = function(e)
		{
			inst.volume = instVol.pos;
		}

		var iVolLabel = new Label();
		iVolLabel.text = "Inst Volume";
		iVolLabel.verticalAlign = "center";

		vocalVol = new NumberStepper();
		vocalVol.max = 1;
		vocalVol.min = 0;
		vocalVol.precision = 2;
		vocalVol.step = 0.1;
		if (vocals != null)
			vocalVol.pos = vocals.volume;

		vocalVol.decimalSeparator = ".";
		vocalVol.onChange = function(e)
		{
			if (vocals != null)
				vocals.volume = vocalVol.pos;
		}

		var vVolLabel = new Label();
		vVolLabel.text = "Vocals Volume";
		vVolLabel.verticalAlign = "center";

		vocalPVol = new NumberStepper();
		vocalPVol.max = 1;
		vocalPVol.min = 0;
		vocalPVol.precision = 2;
		vocalPVol.step = 0.1;
		if (vocalsP != null)
			vocalPVol.pos = vocalsP.volume;

		vocalPVol.decimalSeparator = ".";
		vocalPVol.onChange = function(e)
		{
			if (vocalsP != null)
				vocalsP.volume = vocalPVol.pos;
		}

		var vpVolLabel = new Label();
		vpVolLabel.text = "Vocals (Player) Volume";
		vpVolLabel.verticalAlign = "center";

		vocalEVol = new NumberStepper();
		vocalEVol.max = 1;
		vocalEVol.min = 0;
		vocalEVol.precision = 2;
		vocalEVol.step = 0.1;
		if (vocalsE != null)
			vocalEVol.pos = vocalsE.volume;
		vocalEVol.decimalSeparator = ".";
		vocalEVol.onChange = function(e)
		{
			if (vocalsE != null)
				vocalsE.volume = vocalEVol.pos;
		}
		var difficulties:Array<String> = CoolUtil.difficultyArray;
		diffDrop = new DropDown();
		diffDrop.width = 95;
		diffDrop.onChange = function(e)
		{
			if (!diffDrop.dropDownOpen)
			{
				if (curDiff != difficulties[diffDrop.selectedIndex])
				{
					curDiff = difficulties[diffDrop.selectedIndex];
					loadJson(SONG.songId.toLowerCase(), curDiff);
				}
				Debug.logTrace("Selected Difficulty : " + curDiff);
			}
		}
		var diffList = new ArrayDataSource<Dynamic>();
		for (diff in 0...difficulties.length)
		{
			diffList.add(difficulties[diff]);
		}
		diffDrop.dataSource = diffList;
		diffDrop.selectItemBy(item -> item == curDiff, true);

		var veVolLabel = new Label();
		veVolLabel.text = "Vocals (Enemy) Volume";
		veVolLabel.verticalAlign = "center";

		grid.addComponent(song);
		grid.addComponent(songId);

		grid.addComponent(songName);
		grid.addComponent(displayName);

		grid.addComponent(audioFileName);
		grid.addComponent(audioFile);

		grid2.addComponent(bpm);
		grid2.addComponent(bpmLabel);

		grid2.addComponent(scrollSpeed);
		grid2.addComponent(ssLabel);

		grid2.addComponent(instVol);
		grid2.addComponent(iVolLabel);

		grid2.addComponent(vocalVol);
		grid2.addComponent(vVolLabel);

		grid2.addComponent(vocalPVol);
		grid2.addComponent(vpVolLabel);

		grid2.addComponent(vocalEVol);
		grid2.addComponent(veVolLabel);

		vbox1.addComponent(grid);
		vbox1.addComponent(grid2);

		vbox3.addComponent(hasVoices);
		vbox3.addComponent(isSplit);
		vbox3.addComponent(diffDrop);

		box4.addComponent(vbox1);
		box4.addComponent(vbox3);
	}

	function addEventUI()
	{
		var vbox:VBox = new VBox();
		var vbox2 = new VBox();
		var grid = new Grid();

		var eventList:Array<Song.Event> = []; // existing events
		var eventIndex:Int = 0;
		var existingEvents = new ArrayDataSource<Dynamic>();
		for (event in 0...SONG.eventObjects.length)
		{
			existingEvents.add(SONG.eventObjects[event].name);
			eventList.push(SONG.eventObjects[event]);
		}

		var eventTypeList = new ArrayDataSource<Dynamic>();
		for (event in 0...events.length)
		{
			eventTypeList.add(events[event]);
		}

		var existingLabel = new Label();
		existingLabel.text = "Existing Events";

		var eventListLabel = new Label();
		eventListLabel.text = "Event Types";

		var eventNameLabel = new Label();
		eventNameLabel.text = "Current Event Name";

		var value1Label = new Label();
		value1Label.text = "Event Value 1";

		var value2Label = new Label();
		value2Label.text = "Event Value 2";

		var posLabel = new Label();
		posLabel.text = "Event Position";

		// existing events
		eventDrop = new DropDown();
		eventDrop.width = 125;

		eventDrop.selectedIndex = 0;
		eventDrop.dataSource = existingEvents;
		eventDrop.registerEvent(UIEvent.CLOSE, function(e:UIEvent)
		{
			eventIndex = eventDrop.selectedIndex;
			var event = containsName(eventList[eventIndex].name, SONG.eventObjects);
			if (event == null)
				return;

			savedValue = event.value;
			savedValue2 = event.value2;
			savedType = event.type;
			currentSelectedEventName = event.name;
			eventName.text = currentSelectedEventName;
			eventVal1.text = event.value + "";
			eventVal2.text = event.value2 + "";
			currentEventPosition = event.position;
			eventPosition.text = Std.string(currentEventPosition);
			eventVal2.text = event.value2 + "";
			Debug.logTrace('$currentSelectedEventName $savedType $savedValue $savedValue2 $currentEventPosition');
			eventTypes.selectItemBy(item -> item == savedType, true);
		});
		eventIndex = eventDrop.selectedIndex;

		eventTypes = new DropDown();
		eventTypes.width = 125;
		eventTypes.dataSource = eventTypeList;
		eventTypes.selectedIndex = 0;
		eventTypes.onChange = function(e)
		{
			savedType = events[eventTypes.selectedIndex];
		}

		eventAdd = new Button();
		eventAdd.text = "Add Event";
		eventAdd.onClick = function(e)
		{
			var pog:Song.Event = new Song.Event("New Event " + HelperFunctions.truncateFloat(curDecimalBeat, 2),
				HelperFunctions.truncateFloat(curDecimalBeat, 3), '${SONG.bpm}', "1", "BPM Change");

			var obj = containsName(pog.name, SONG.eventObjects);

			if (obj != null)
				return;

			SONG.eventObjects.push(pog);
			existingEvents.clear();
			eventList = [];
			for (event in 0...SONG.eventObjects.length)
			{
				existingEvents.add(SONG.eventObjects[event].name);
				eventList.push(SONG.eventObjects[event]);
			}

			eventName.text = pog.name;
			eventVal1.text = pog.value + "";
			eventVal2.text = pog.value2 + "";
			eventPosition.text = pog.position + "";
			currentSelectedEventName = pog.name;
			currentEventPosition = pog.position;
			savedValue = pog.value;
			savedValue2 = pog.value2;
			savedType = pog.type;

			eventDrop.dataSource = existingEvents;

			Debug.logTrace(currentSelectedEventName);
			eventDrop.selectItemBy(item -> item == currentSelectedEventName, true);

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				var name = Reflect.field(i, "name");
				var type = Reflect.field(i, "type");
				var pos = Reflect.field(i, "position");
				var value = Reflect.field(i, "value");
				var value2 = Reflect.field(i, "value2");
				if (type == "BPM Change")
				{
					var beat:Float = pos;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}

					currentIndex++;
				}
			}

			recalculateAllSectionTimes();
			regenerateLines();
		}

		eventName = new TextField();
		eventName.text = SONG.eventObjects[0].name;
		eventName.onChange = function(e)
		{
			// currentSelectedEventName = eventName.text;
			var obj = containsName(currentSelectedEventName, SONG.eventObjects);
			if (obj == null)
			{
				currentSelectedEventName = eventName.text;
				return;
			}
			obj = containsName(eventName.text, SONG.eventObjects);
			if (obj != null)
				return;
			obj = containsName(currentSelectedEventName, SONG.eventObjects);
			obj.name = eventName.text;
			currentSelectedEventName = eventName.text;
		}

		eventSave = new Button();
		eventSave.text = "Save Event";
		eventSave.onClick = function(e)
		{
			var pog:Song.Event = new Song.Event(currentSelectedEventName, currentEventPosition, savedValue, savedValue2, savedType);

			var obj = containsName(pog.name, SONG.eventObjects);

			if (pog.name == "")
				return;

			if (obj != null)
			{
				SONG.eventObjects.remove(obj);
				Debug.logTrace("isn't null, removing");
			}

			SONG.eventObjects.push(pog);

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				var name = Reflect.field(i, "name");
				var type = Reflect.field(i, "type");
				var pos = Reflect.field(i, "position");
				var value = Reflect.field(i, "value");
				var value2 = Reflect.field(i, "value2");

				if (type == "BPM Change")
				{
					var beat:Float = pos;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}

					currentIndex++;
				}
			}

			if (pog.type == "BPM Change")
			{
				recalculateAllSectionTimes();
				updateNotes();

				// may break things, but will improve performance when it isn't a bpm change
			}

			regenerateLines();

			existingEvents.clear();
			eventList = [];
			for (event in 0...SONG.eventObjects.length)
			{
				existingEvents.add(SONG.eventObjects[event].name);
				eventList.push(SONG.eventObjects[event]);
			}

			eventDrop.dataSource = existingEvents;
			eventIndex = eventList.length - 1;
			eventDrop.selectItemBy(item -> item == pog.name, true);
			autosaveSong();

			Debug.logTrace('$currentSelectedEventName $currentEventPosition $savedType');
		}

		eventRemove = new Button();
		eventRemove.text = "Remove Event";
		eventRemove.onClick = function(e)
		{
			var obj = containsName(currentSelectedEventName, SONG.eventObjects);

			if (obj == null)
				return;

			SONG.eventObjects.remove(obj);

			var firstEvent = SONG.eventObjects[0];

			if (firstEvent == null)
			{
				SONG.eventObjects.push(new Song.Event("Init BPM", 0, '${SONG.bpm}', "1", "BPM Change"));
				firstEvent = SONG.eventObjects[0];
			}

			existingEvents.clear();
			eventList = [];
			for (event in 0...SONG.eventObjects.length)
			{
				existingEvents.add(SONG.eventObjects[event].name);
				eventList.push(SONG.eventObjects[event]);
			}

			eventIndex = eventList.length - 1;
			eventDrop.dataSource = existingEvents;

			eventName.text = firstEvent.name;
			eventVal1.text = firstEvent.value + "";
			eventVal2.text = firstEvent.value2 + "";
			eventPosition.text = firstEvent.position + "";
			currentSelectedEventName = firstEvent.name;
			currentEventPosition = firstEvent.position;
			eventDrop.selectItemBy(item -> item == firstEvent.name, true);

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				var name = Reflect.field(i, "name");
				var type = Reflect.field(i, "type");
				var pos = Reflect.field(i, "position");
				var value = Reflect.field(i, "value");
				var value2 = Reflect.field(i, "value2");

				if (type == "BPM Change")
				{
					var beat:Float = pos;

					var endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, value, endBeat, 0); // offset in this case = start time since we don't have a offset

					if (currentIndex != 0)
					{
						var data = TimingStruct.AllTimings[currentIndex - 1];
						data.endBeat = beat;
						data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
						var step = ((60 / data.bpm) * 1000) / 4;
						TimingStruct.AllTimings[currentIndex].startStep = Math.floor(((data.endBeat / (data.bpm / 60)) * 1000) / step);
						TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
					}

					currentIndex++;
				}
			}

			if (obj.type == "BPM Change")
			{
				recalculateAllSectionTimes();
				updateNotes();
			}

			regenerateLines();
		}

		eventPos = new Button();
		eventPos.text = "Update Position";
		eventPos.onClick = function(e)
		{
			var obj = containsName(currentSelectedEventName, SONG.eventObjects);
			if (obj == null)
				return;
			currentEventPosition = HelperFunctions.truncateFloat(curDecimalBeat, 3);
			obj.position = currentEventPosition;
			eventPosition.text = currentEventPosition + "";
		}

		eventPosition = new TextField();
		eventPosition.text = Std.string(SONG.eventObjects[0].position);
		eventPosition.onChange = function(e)
		{
			var obj = containsName(currentSelectedEventName, SONG.eventObjects);
			if (obj == null)
				return;
			currentEventPosition = Std.parseFloat(eventPosition.text);
			obj.position = currentEventPosition;
		}

		eventVal1 = new TextField();
		eventVal1.text = SONG.eventObjects[0].value;
		eventVal1.onChange = function(e)
		{
			savedValue = eventVal1.text;
		}

		eventVal2 = new TextField();
		eventVal2.text = SONG.eventObjects[0].value2;
		eventVal2.onChange = function(e)
		{
			savedValue2 = eventVal2.text;
		}

		vbox.addComponent(existingLabel);
		vbox.addComponent(eventDrop);
		vbox.addComponent(eventListLabel);
		vbox.addComponent(eventTypes);
		vbox.addComponent(eventNameLabel);
		vbox.addComponent(eventName);
		vbox.addComponent(value1Label);
		vbox.addComponent(eventVal1);
		vbox.addComponent(value2Label);
		vbox.addComponent(eventVal2);
		vbox.addComponent(posLabel);
		vbox.addComponent(eventPosition);
		vbox2.addComponent(eventAdd);
		vbox2.addComponent(eventSave);
		vbox2.addComponent(eventRemove);
		vbox2.addComponent(eventPos);
		grid.addComponent(vbox);
		grid.addComponent(vbox2);
		box5.addComponent(grid);

		// dfjk
	}

	inline function addTabs()
	{
		box = new ContinuousHBox();
		box.padding = 5;
		box.width = 300;
		box.text = "Assets";

		box2 = new ContinuousHBox();
		box2.width = 300;
		box2.padding = 5;
		box2.text = "Note";

		box3 = new ContinuousHBox();
		box3.width = 300;
		box3.padding = 5;
		box3.text = "Section";

		box4 = new HBox();
		box4.width = 300;
		box4.padding = 5;
		box4.text = "Song";
		// box4.color = daColor;

		box5 = new ContinuousHBox();
		box5.width = 300;
		box5.padding = 5;
		box5.text = "Events";
		// box5.color = daColor;
		// ignore

		ui.addComponent(box);
		ui.addComponent(box2);
		ui.addComponent(box3);
		ui.addComponent(box4);
		ui.addComponent(box5);
	}

	inline function menuBarShit()
	{
		var spac = new Spacer();
		spac.width = 210;
		var file = new Menu();
		file.text = "Chart";
		var personal = new Menu();
		personal.text = "Preferences";
		var game = new Menu();
		game.text = "Game";

		var box = new VBox();

		var saveSong = new MenuItem();
		saveSong.text = "Save Chart";
		saveSong.shortcutText = "Ctrl+S";
		saveSong.onClick = function(e)
		{
			saveLevel();
		}

		var loadAuto = new MenuItem();
		loadAuto.text = "Load Autosave";
		loadAuto.shortcutText = "Ctrl+A+S";
		loadAuto.onClick = function(e)
		{
			loadAutosave();
		}

		var reload = new MenuItem();
		reload.text = "Reload Audio";
		reload.onClick = function(e)
		{
			try
			{
				if (inst.playing)
				{
					inst.stop();
					if (!SONG.splitVoiceTracks)
						vocals.stop();
					else
					{
						vocalsP.stop();
						vocalsE.stop();
					}
				}
				loadSong(SONG.audioFile.toLowerCase(), false);
			}
			catch (e)
			{
				Debug.logTrace(e);
			}
			// goofy song overlapping and raping your ears
		}

		var reloadChart = new MenuItem();
		reloadChart.text = "Reload Chart";
		reloadChart.onClick = function(e)
		{
			var clean = false;
			loadJson(SONG.songId.toLowerCase(), curDiff);
		}

		var cleanSong = new MenuItem();
		cleanSong.text = "Clear Chart";
		cleanSong.onClick = function(e)
		{
			NotificationManager.instance.addNotification({
				title: "Are You Sure You Want To Clear The Chart?",
				body: "All Notes Will Be Cleared.",
				type: NotificationType.Error,
				actions: [
					{
						text: "Clear",
						callback: (data) ->
						{
							for (daSection in 0...SONG.notes.length)
							{
								SONG.notes[daSection].sectionNotes = [];
							}

							updateNotes();
							NotificationManager.instance.addNotification({
								title: "Chart Cleared.",
								body: "All Notes Cleared.",
								type: NotificationType.Success,
							});
							return true;
						}
					},
					{
						text: "Nevermind",
						callback: (data) ->
						{
							return true;
						}
					}
				]
			});
		}

		var create = new MenuItem();
		create.text = "Create Blank Chart";
		create.onClick = function(e)
		{
			var cleaned = {
				songId: 'test',
				songName: 'Test',
				audioFile: 'test',
				chartVersion: "KEC1",
				splitVoiceTracks: true,
				notes: [],
				eventObjects: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				style: 'Default',
				stage: 'stage',
				speed: 1,
				validScore: true
			};

			var cleanedData = Json.parse(haxe.Json.stringify({
				"song": cleaned
			}));

			var data:SongData = cast cleanedData;
			var meta:SongMeta = {};
			if (cleanedData.song != null)
			{
				meta = cleanedData.songMeta != null ? cast cleanedData.songMeta : {};
			}
			PlayState.SONG = Song.parseJSONshit(data.songId, data, meta);
			MusicBeatState.switchState(new ChartingState());
			// doo doo fard
		}

		file.addComponent(saveSong);
		file.addComponent(reloadChart);
		file.addComponent(reload);
		file.addComponent(loadAuto);
		file.addComponent(cleanSong);
		file.addComponent(create);

		var dragTabs = new MenuCheckBox();
		dragTabs.text = "Drag Tablist";
		dragTabs.selected = FlxG.save.data.moveEditor;
		dragTabs.onClick = function(e)
		{
			FlxG.save.data.moveEditor = !FlxG.save.data.moveEditor;
			ui.draggable = FlxG.save.data.moveEditor;
		}

		metronome = new MenuCheckBox();
		metronome.text = "Metronome";
		if (FlxG.save.data.chart_metronome == null)
			FlxG.save.data.chart_metronome = false;
		metronome.selected = FlxG.save.data.chart_metronome;
		metronome.onClick = function(e)
		{
			FlxG.save.data.chart_metronome = !FlxG.save.data.chart_metronome;
		}
		var hsv = new Label();
		hsv.text = "Hitsound Volume";
		hsv.horizontalAlign = "center";

		hitsoundsVol = new HorizontalSlider();
		hitsoundsVol.max = 1;
		hitsoundsVol.min = 0;
		hitsoundsVol.precision = 2;
		hitsoundsVol.step = 0.05;
		hitsoundsVol.minorTicks = 0.05;
		hitsoundsVol.majorTicks = 0.25;
		hitsoundsVol.pos = 0.5; // pissed me off so badly

		hitsoundsP = new MenuCheckBox();
		hitsoundsP.text = "Hitsounds (Player)";
		if (FlxG.save.data.playHitsounds == null)
			FlxG.save.data.playHitsounds = false;
		hitsoundsP.selected = FlxG.save.data.playHitsounds;
		hitsoundsP.onClick = function(e)
		{
			FlxG.save.data.playHitsounds = !FlxG.save.data.playHitsounds;
		}

		hitsoundsE = new MenuCheckBox();
		hitsoundsE.text = "Hitsounds (Opponent)";
		if (FlxG.save.data.playHitsoundsE == null)
			FlxG.save.data.playHitsoundsE = false;
		hitsoundsE.selected = FlxG.save.data.playHitsoundsE;
		hitsoundsE.onClick = function(e)
		{
			FlxG.save.data.playHitsoundsE = !FlxG.save.data.playHitsoundsE;
		}

		oppMode = new MenuCheckBox();
		oppMode.text = "Opponent Mode";
		oppMode.selected = FlxG.save.data.opponent;
		oppMode.onClick = function(e)
		{
			FlxG.save.data.opponent = !FlxG.save.data.opponent;
		}

		var savePos = new MenuItem();
		savePos.text = "Save Tablist Position";
		savePos.onClick = function(e)
		{
			FlxG.save.data.editorPos = [ui.x, ui.y];
		}

		var resetPos = new MenuItem();
		resetPos.text = "Reset Tablist Position";
		resetPos.onClick = function(e)
		{
			FlxG.save.data.editorPos = [0, 420];
			ui.x = 0;
			ui.y = 420;
		}

		personal.addComponent(dragTabs);
		box.addComponent(hsv);
		personal.addComponent(box);
		personal.addComponent(hitsoundsVol);
		personal.addComponent(hitsoundsP);
		personal.addComponent(hitsoundsE);
		personal.addComponent(metronome);
		personal.addComponent(oppMode);

		var playHere = new MenuItem();
		playHere.text = "Playtest At Timestamp";
		playHere.onClick = function(e)
		{
			PlayState.SONG = SONG;

			PlayState.startTime = inst.time;
			inst.stop();
			if (!SONG.splitVoiceTracks)
				vocals.stop();
			else
			{
				vocalsP.stop();
				vocalsE.stop();
			}
			MusicBeatState.switchState(new PlayState());
			Lib.clearInterval(id);
		}
		game.addComponent(playHere);

		menu.addComponent(spac);
		menu.addComponent(file);
		menu.addComponent(personal);
		menu.addComponent(game);
	}

	override function beatHit()
	{
		super.beatHit();
		if (!FlxG.save.data.motion && inst.playing && (curBeat % 2 == 0))
		{
			iconP1.scale.set(0.7, 0.7);
			iconP2.scale.set(0.7, 0.7);

			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		if (FlxG.save.data.chart_metronome)
			FlxG.sound.play(Paths.sound('Metronome_Tick'));
	}

	override function stepHit()
	{
		super.stepHit();
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false):SwagSection
	{
		var daPos:Float = 0;

		var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];

		var currentBeat = 4;

		for (i in SONG.notes)
			currentBeat += 4;

		if (currentSeg == null)
			return null;

		var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

		daPos = (currentSeg.startTime + start) * 1000;

		var sec:SwagSection = {
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			bpm: SONG.bpm,
			changeBPM: false,
			lengthInSteps: 16,
			playerSec: true,
			sectionNotes: [],
		};

		return sec;
	}
}
