package kec.states.editors;

import flixel.addons.display.FlxBackdrop;
import flixel.util.FlxSort;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.HorizontalSlider;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.OptionBox;
import haxe.ui.components.Spacer;
import haxe.ui.components.TextField;
import haxe.ui.components.Toggle;
import haxe.ui.containers.ContinuousHBox;
import haxe.ui.containers.Grid;
import haxe.ui.containers.HBox;
import haxe.ui.containers.TabView;
import haxe.ui.containers.VBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuBar;
import haxe.ui.containers.menus.MenuCheckBox;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import haxe.ui.styles.Style;
import haxe.ui.themes.Theme;
import haxe.ui.util.Color;
import kec.backend.HitSounds;
import kec.backend.PlayStateChangeables;
import kec.backend.chart.NoteData;
import kec.backend.chart.Section.SwagSection;
import kec.backend.chart.Section;
import kec.backend.chart.Event;
import kec.backend.chart.Song.SongData;
import kec.backend.chart.Song;
import kec.backend.chart.TimingStruct;
import kec.backend.util.HelperFunctions;
import kec.backend.util.NoteStyleHelper;
import kec.backend.util.Sort;
import kec.backend.util.Sort;
import kec.objects.Character;
import kec.objects.CoolText;
import kec.objects.note.Note;
import kec.objects.ui.HealthIcon;
import kec.states.editors.ChartingBox;
import kec.states.editors.SectionRender;
import openfl.Lib;
import openfl.events.Event as OpenFlEvent;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
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
	var noteTypes:Array<String>; // noteTypes basically
	var events:Array<String>; // even- you already know

	var noteType:String = "Normal"; // idfk

	public var SONG:SongData;
	public var lastUpdatedSection:SwagSection = null;

	public static final gridSize:Int = 45; // scale? GRID_SIZE?

	final notePos = 100; // General Note Pos

	public static final size = 0.5; // general size / spacing of things

	var currentSelectedEventName:String = "";
	var savedType:String = "BPM Change";
	var savedValue:String = "100";
	var savedValue2:String = "1";
	var currentEventPosition:Float = 0;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;
	public var curSelectedNoteObject:Note = null;

	public var copiedNotes:Array<Array<Dynamic>> = [];
	public var pastedNotes:Array<Note> = [];
	public var deletedNotes:Array<Array<Dynamic>> = [];
	public var lastAction:String = "";

	var curSelectedNote:Array<Dynamic>;
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
	var strumLine:FlxSprite;

	public static var lengthInSteps:Int = 0;
	public static var lengthInBeats:Int = 0;
	public static var lengthInSections:Int = 0;

	public var pitch:Float = 1.0;

	var sectionY = 0;

	var currentBPM:Float = 0;
	var doSnapShit:Bool = true;
	var defaultSnap:Bool = true;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	var curDiff:String = "";

	public var quantizations:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var mouseCursor:FlxSprite;

	public var waitingForRelease:Bool = false;
	public var selectBox:FlxSprite;

	public static var clean:Bool = false;

	public var selectInitialX:Float = 0;
	public var selectInitialY:Float = 0;

	public var infoText:CoolText;

	var sustainQuant:Float = 1.0;

	public var infoBG:FlxSprite;
	public var notetypetext:CoolText;
	public var helpText:CoolText;

	var _file:FileReference;

	public var id:Int = -1;

	public static final separatorWidth:Int = 4;

	private var editorArea:EditorArea;

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

		FlxG.mouse.visible = true;

		PlayState.inDaPlay = false;

		TimingStruct.clearTimings();
		SONG = PlayState.SONG;
		activeSong = SONG;

		loadSong(SONG.audioFile, false);

		curDiff = CoolUtil.difficultyArray[PlayState.storyDifficulty];

		Conductor.bpm = SONG.bpm;

		currentBPM = SONG.bpm;

		Constants.noteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.noteskin);
		Constants.cpuNoteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		Constants.noteskinPixelSprite = NoteStyleHelper.generatePixelSprite(FlxG.save.data.noteskin);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF111111;
		add(bg);

		lines = new FlxTypedGroup<FlxSprite>();
		texts = new FlxTypedGroup<FlxText>();

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

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
			+ "Alt+Left/Right : Change Quant" + "\n" + "Shift : Disable/Enable Quant" + "\n" + "Click : Place notes" + "\n" + "Up/Down : Move selected notes"
			+ "\n" + "Space : Play Song" + "\n" + "W-S : Go To Previous / Next Section" + "\n" + "Q-E : Change Sustain Amount" + "\n"
			+ "C-V : Change Sustain Change Quant" + "\n" + "Enter : Load Song Into PlayState" + "\n" + "Z/X Change Notetype." + "\n"
			+ "Press F1 to show/hide help text.";
		helpText.updateHitbox();
		helpText.scrollFactor.set();
		helpText.visible = FlxG.save.data.showHelp;
		initEvents();

		var currentIndex = 0;

		setSongTimings();
		recalculateAllSectionTimes();
		lengthInBeats = Math.round(TimingStruct.getBeatFromTime(inst.length));
		lengthInSteps = lengthInBeats * 4;
		lengthInSections = Std.int(lengthInBeats / 4);
		Debug.logTrace('Total Beats ${lengthInBeats}. Total Steps ${lengthInSteps} Probable Length In Sections ${lengthInSections}');
		createGrid();

		regenerateLines();
		updateNotes();

		add(lines);
		add(texts);

		add(curRenderedNotes);
		add(curRenderedSustains);
		add(strumLine);
		add(mouseCursor);

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
		selectBox = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
		selectBox.visible = false;
		selectBox.alpha = 0.4;
		add(selectBox);

		id = Lib.setInterval(autosaveSong, 5 * 60 * 1000);

		ui.x = 0;
		ui.y = 420;

		#if FEATURE_DISCORD
		kec.backend.Discord.changePresence("Chart Editor", "Charting : " + SONG.songName, null, true);
		#end

		super.create();
	}

	var updateFrame = 0;

	override function update(elapsed:Float)
	{
		if (inst != null)
		{
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
			Conductor.songPosition = inst.time;
		}

		if (curDecimalBeat < 0)
			curDecimalBeat = 0;
		var currentSeg = TimingStruct.getTimingAtBeat(curDecimalBeat);
		if (currentSeg != null)
		{
			var timingSegBpm = currentSeg.bpm;

			if (timingSegBpm != Conductor.bpm)
			{
				Debug.logInfo("BPM CHANGE to " + timingSegBpm);
				Conductor.bpm = timingSegBpm;
				recalculateAllSectionTimes();
			}
		}

		var lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 12), 0, 1);
		strumLine.y = FlxMath.lerp(getYfromStrum(inst.time), strumLine.y, lerpVal);
		// strumLine.y = getYfromStrum(inst.time);

		var weird = getSectionByTime(inst.time);

		if (weird != null)
		{
			if (lastUpdatedSection != getSectionByTime(inst.time))
			{
				lastUpdatedSection = weird;
				playerSection.selected = weird.playerSec;
			}
		}

		var doInput = true;

		if (FocusManager.instance.focus != null)
			doInput = false;

		for (note in curRenderedNotes)
		{
			var diff = note.strumTime - Conductor.songPosition;
			if (diff < 2000 && diff >= -4000) // Cutting it really close with rendered notes
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

		var mult:Float = FlxMath.lerp(0.75, iconP1.scale.x, FlxMath.bound(1 - (elapsed * 9 * pitch), 0, 1));
		if (!FlxG.save.data.motion)
			iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(0.75, iconP2.scale.x, FlxMath.bound(1 - (elapsed * 9 * pitch), 0, 1));
		if (!FlxG.save.data.motion)
			iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var interacting:Bool = Screen.instance.hasComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
		var mouseX:Float = quantizePos(FlxG.mouse.x - editorArea.x);
		mouseCursor.x = Math.min(editorArea.x + mouseX + separatorWidth * Math.floor(mouseX / gridSize / 4), editorArea.x + editorArea.width);
		mouseCursor.y = FlxMath.bound(getMouseY(), 0, editorArea.bottom - gridSize);
		mouseCursor.visible = (mouseValid() && !interacting);

		if (FlxG.mouse.justPressed && !waitingForRelease)
		{
			if (!FlxG.keys.pressed.CONTROL && mouseCursor.visible)
			{
				checkNoteSpawn();
			}
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
			curRenderedNotes.forEachAlive(function(n:Note)
			{
				if (n.overlaps(selectBox) && !n.charterSelected)
				{
					selectNote(n);
				}
			});
			selectBox.visible = false;
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

			if (FlxG.keys.justPressed.E)
				changeNoteSustain(Conductor.stepCrochet * sustainQuant);
			if (FlxG.keys.justPressed.Q)
				changeNoteSustain(-Conductor.stepCrochet * sustainQuant);

			if ((FlxG.keys.justPressed.A || FlxG.keys.justPressed.LEFT) && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
			{
				goToSection(curSection - 1);
			}
			else if ((FlxG.keys.justPressed.D || FlxG.keys.justPressed.RIGHT) && !FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT)
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
					selectedBoxes.forEachAlive(function(i:ChartingBox)
					{
						copiedNotes.push([
							i.connectedNote.strumTime,
							i.connectedNote.rawNoteData,
							i.connectedNote.sustainLength,
							i.connectedNote.noteType
						]);
					});

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

				selectedBoxes.forEachAlive(function(i:ChartingBox)
				{
					deletedNotes.push([
						{
							strumTime: i.connectedNote.strumTime,
							noteData: i.connectedNote.rawNoteData,
							sustainLength: i.connectedNote.sustainLength,
							noteType: i.connectedNote.noteType,
							beat: TimingStruct.getBeatFromTime(i.connectedNote.strumTime),
							isPlayer: i.connectedNote.mustPress
						}
					]);
					notesToBeDeleted.push(i.connectedNote);
				});

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
				var beat:Float = TimingStruct.getBeatFromTime(Conductor.songPosition);
				var snap:Float = quantization * 0.25;
				var increase:Float = 0.0;
				if (amount < 0)
					increase = 1 / snap;
				else
					increase = -1 / snap;

				var fuck:Float = (Math.fround(beat * snap) / snap) + increase;
				if (fuck < 0)
					fuck = 0;

				var data = TimingStruct.getTimingAtBeat(fuck);
				var lastDataIndex = TimingStruct.AllTimings.indexOf(data) - 1;
				if (lastDataIndex < 0)
					lastDataIndex = 0;

				var lastData = TimingStruct.AllTimings[lastDataIndex];

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
					var data:Int = note.rawNoteData;
					var noteDataToCheck:Int = data;
					var playerNote = noteDataToCheck >= 4;
					if (!playedSound[data])
					{
						if ((FlxG.save.data.playHitsounds && playerNote) || (FlxG.save.data.playHitsoundsE && !playerNote))
						{
							if (FlxG.save.data.hitSound == 0)
								daHitSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/snap', 'shared'));
							else
								daHitSound = new FlxSound()
									.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}', 'shared'));
							daHitSound.volume = hitsoundsVol.pos;
							daHitSound.play().pan = noteDataToCheck < 4 ? -0.3 : 0.3;
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
			+ quantizations[curQuant]
			+ "\n"
			+ "Quantization : "
			+ doSnapShit;
		infoText.updateHitbox();
		lastConductorPos = Conductor.songPosition;

		// I hate having things run in update all the time but fuck it
		songShit();

		super.update(elapsed);
	}

	function updateNotes()
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();
		var noteCounter = 0;

		for (section in SONG.notes)
		{
			if (section != null)
				for (i in 0...section.sectionNotes.length)
				{
					final songNotes:Array<Dynamic> = section.sectionNotes[i];
					var noteData = songNotes[1];
					var spawnTime = songNotes[0];
					var holdLength = songNotes[2];
					var noteType = songNotes[3];
					var beat = TimingStruct.getBeatFromTime(spawnTime);
					var playerNote:Bool = (songNotes[1] > 3);

					if (PlayStateChangeables.opponentMode)
						playerNote = !playerNote;

					var note:Note = new Note(spawnTime, noteData % 4, null, false, true, playerNote, beat);
					note.rawNoteData = noteData;
					note.noteType = noteType;
					note.sustainLength = holdLength;

					note.setGraphicSize(gridSize, gridSize);
					note.updateHitbox();
					note.x = editorArea.x + Math.floor(noteData * gridSize) + separatorWidth;
					if (noteData < 4)
						note.x -= separatorWidth;
					note.y = Math.floor(getYfromStrum(spawnTime));
					curRenderedNotes.add(note);

					if (holdLength > 0)
					{
						var sustainVis:FlxSprite = new FlxSprite(note.x + 20, note.y + gridSize).makeGraphic(1, 1);
						sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength)) - note.y));
						note.noteCharterObject = sustainVis;
						sustainVis.updateHitbox();

						curRenderedSustains.add(sustainVis);
					}
				}
		}
		curRenderedNotes.sort(FlxSort.byY, FlxSort.ASCENDING);
	}

	function regenerateLines()
	{
		lines.forEachAlive(function(spr:FlxSprite) spr.destroy());
		lines.clear();

		texts.forEachAlive(function(spr:FlxText) spr.destroy());
		texts.clear();

		if (SONG.eventObjects != null)
		{
			for (i in 0...lengthInBeats)
			{
				var pos = getYfromStrum(TimingStruct.getTimeFromBeat(i));
				var line = new FlxSprite(editorArea.x + separatorWidth, pos).makeGraphic(Std.int(gridSize * 8), 4, FlxColor.fromRGB(164, 41, 41));
				line.screenCenter(X);
				lines.add(line);
			}

			for (i in SONG.notes)
			{
				var pos = getYfromStrum(i.startTime);

				var line = new FlxSprite(editorArea.x + separatorWidth, pos).makeGraphic(Std.int(gridSize * 8), 4, FlxColor.fromRGB(42, 162, 162));
				line.screenCenter(X);
				lines.add(line);
			}

			for (i in SONG.eventObjects)
			{
				var seg = TimingStruct.getTimingAtBeat(i.beat);

				var posi:Float = 0;

				if (seg != null)
				{
					var start:Float = (i.beat - seg.startBeat) / (seg.bpm / 60);

					posi = seg.startTime + start;
				}

				var pos = getYfromStrum(posi * 1000);

				if (pos < 0)
					pos = 0;

				var type = i.type;

				var text = new FlxText(editorArea.x + (gridSize * 8) + separatorWidth, pos, 0, i.name + "\n" + type + "\n" + i.args[0] + "\n" + i.args[1], 16);
				text.borderStyle = OUTLINE_FAST;
				text.borderColor = FlxColor.BLACK;
				text.font = Paths.font("vcr.ttf");
				var line = new FlxSprite(editorArea.x + separatorWidth, pos).makeGraphic(Std.int(gridSize * 8), 4, FlxColor.YELLOW);
				line.screenCenter(X);
				lines.add(line);
				texts.add(text);
			}
		}
	}

	private function addNote():Void
	{
		destroyBoxes();

		var strum = getStrumTime(mouseCursor.y);
		var sec = getSectionByTime(strum);
		var spawnTime = strum;
		var noteData:Int = Math.floor((mouseCursor.x - editorArea.x) / gridSize);
		var holdLength = 0;
		var noteType = noteTypes[noteShitDrop.selectedIndex];
		var playerNote:Bool = (noteData > 3);

		if (PlayStateChangeables.opponentMode)
			playerNote = !playerNote;

		sec.sectionNotes.push([spawnTime, noteData, holdLength, noteType]); // retarded ass note saving

		Debug.logTrace("Note Data : " + noteData + " StrumTime : " + spawnTime + " Section Length : " + sec.sectionNotes.length);

		var note:Note = new Note(spawnTime, noteData % 4, null, false, true, playerNote, TimingStruct.getBeatFromTime(spawnTime));
		note.rawNoteData = noteData;
		note.sustainLength = holdLength;
		note.noteType = noteType;
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();
		note.x = editorArea.x + Math.floor(noteData * gridSize) + separatorWidth;
		if (noteData < 4)
			note.x -= separatorWidth;
		note.y = Math.floor(getYfromStrum(spawnTime));
		curRenderedNotes.add(note);

		curSelectedNote = sec.sectionNotes[sec.sectionNotes.length - 1];
		curSelectedNoteObject = note;
		createBox(note.x, note.y, note);
		note.charterSelected = true;
		curSelectedNoteObject.charterSelected = true;

		autosaveSong();
	}

	function selectNote(note:Note):Void
	{
		for (sec in SONG.notes)
		{
			if (sec != null)
				for (i in 0...sec.sectionNotes.length)
				{
					final check:Array<Dynamic> = sec.sectionNotes[i];
					final time = check[0];
					final data = check[1];
					final type = check[3];
					if (time == note.strumTime && data == note.rawNoteData && type == note.noteType)
					{
						curSelectedNote = sec.sectionNotes[i];
						curSelectedNoteObject = note;
						if (!note.charterSelected)
						{
							createBox(note.x, note.y, note);
							note.charterSelected = true;
							curSelectedNoteObject.charterSelected = true;
						}
					}
				}
		}
	}

	function deleteNote(existingNote:Note):Void
	{
		destroyBoxes();
		var sec = getSectionByTime(existingNote.strumTime);
		var i:Int = sec.sectionNotes.length;
		while (--i > -1)
		{
			if (sec.sectionNotes[i][0] == existingNote.strumTime && sec.sectionNotes[i][1] == existingNote.rawNoteData)
				sec.sectionNotes.remove(sec.sectionNotes[i]);
		}
		// thanks Chris(Dimensionscape) from the FNF thread
		curRenderedNotes.remove(existingNote);
		if (existingNote.sustainLength > 0)
			curRenderedSustains.remove(existingNote.noteCharterObject, true);

		curSelectedNote = null;
		// Debug.logTrace("tryna delete note");
	}

	function createBox(x:Float, y:Float, note:Note)
	{
		var box:ChartingBox = selectedBoxes.recycle(ChartingBox);
		box.setupBox(x, y, note);
	}

	function destroyBoxes()
	{
		selectedBoxes.forEachAlive(function(b:ChartingBox)
		{
			b.connectedNote.charterSelected = false;
			b.kill();
		});
	}

	override function destroy()
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();
		copiedNotes = null;
		pastedNotes = null;
		deletedNotes = null;
		curSelectedNoteObject = null;
		curSelectedNote = null;
		selectBox = null;
		events = null;
		characters = null;
		stages = null;
		gfs = null;
		noteStyles = null;
		noteTypes = null;

		destroyBoxes();
		FlxG.save.flush();
		super.destroy();
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote == null)
			return;

		curSelectedNote[2] += Math.ceil(value);
		curSelectedNote[2] = Math.max(curSelectedNote[2], 0);

		if (curSelectedNoteObject.noteCharterObject != null)
			curRenderedSustains.remove(curSelectedNoteObject.noteCharterObject, true);

		if (curSelectedNote[2] > 0)
		{
			var sustainVis:FlxSprite = new FlxSprite(curSelectedNoteObject.x + 20, curSelectedNoteObject.y + gridSize).makeGraphic(1, 1);
			sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(curSelectedNoteObject.strumTime + curSelectedNote[2])) - curSelectedNoteObject.y));
			sustainVis.updateHitbox();
			curSelectedNoteObject.sustainLength = curSelectedNote[2];
			curSelectedNoteObject.noteCharterObject = sustainVis;

			curRenderedSustains.add(sustainVis);
		}
	}

	function offsetSelectedNotes(offset:Float)
	{
		var toDelete:Array<Note> = [];
		var toBeAdded:Array<Note> = []; // retarded ass boxes
		// For each selected note...
		selectedBoxes.forEachAlive(function(b:ChartingBox)
		{
			var originalNote = b.connectedNote;
			toDelete.push(originalNote);
			var strum = originalNote.strumTime + offset;
			if (strum < 0)
			{
				Debug.logTrace("New Time Is 0 Or Less, Deleting Note.");
				return;
			}
			var sec = getSectionByTime(strum);

			var note:Note = new Note(strum, originalNote.noteData, originalNote.prevNote, false, true, originalNote.mustPress, originalNote.beat);
			note.rawNoteData = originalNote.rawNoteData;
			note.sustainLength = originalNote.sustainLength;
			note.noteType = originalNote.noteType;
			note.setGraphicSize(gridSize, gridSize);
			note.updateHitbox();
			note.x = editorArea.x + Math.floor(note.rawNoteData * gridSize) + separatorWidth;
			if (note.rawNoteData < 4)
				note.x -= separatorWidth;
			note.y = Math.floor(getYfromStrum(strum));
			pastedNotes.push(note);
			toBeAdded.push(note);
			curRenderedNotes.add(note);

			sec.sectionNotes.push([note.strumTime, note.rawNoteData, note.sustainLength, note.noteType]);

			if (note.sustainLength > 0)
			{
				var sustainVis:FlxSprite = new FlxSprite(note.x + 20, note.y + gridSize).makeGraphic(1, 1);
				sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength)) - note.y));
				note.noteCharterObject = sustainVis;
				sustainVis.updateHitbox();

				curRenderedSustains.add(sustainVis);
			}
			curSelectedNoteObject = note;
			curSelectedNoteObject.charterSelected = false;
		});

		for (note in toDelete)
		{
			deleteNote(note);
		}

		destroyBoxes();

		for (box in toBeAdded)
		{
			createBox(box.x, box.y, box);
		}

		toDelete = null;
		toBeAdded = null;

		// ok so basically theres a bug with color quant that it doesn't update the color until the grid updates.
		// when the grid updates, it causes a massive performance drop everytime we offset the notes. :/
		// actually its broken either way because theres a ghost note after offsetting sometimes. updateGrid anyway.
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
						var newData = [strum, i[1], i[2], i[3]];
						ii.sectionNotes.push(newData);

						var thing = ii.sectionNotes[ii.sectionNotes.length - 1];
						var gottaHitNote:Bool = false;
						if (i[1] > 3)
							gottaHitNote = true;
						else if (i[1] <= 3)
							gottaHitNote = false;

						if (PlayStateChangeables.opponentMode)
							gottaHitNote = !gottaHitNote;

						var note:Note = new Note(strum, Math.floor(i[1] % 4), null, false, true, gottaHitNote, i[3]);
						note.rawNoteData = i[1];
						note.sustainLength = i[2];
						note.noteType = i[3];
						note.setGraphicSize(gridSize, gridSize);
						note.updateHitbox();
						note.x = editorArea.x + Math.floor(note.rawNoteData * gridSize) + separatorWidth;
						if (note.rawNoteData < 4)
							note.x -= separatorWidth;
						note.y = Math.floor(getYfromStrum(strum));

						note.charterSelected = true;

						createBox(note.x, note.y, note);

						curRenderedNotes.add(note);

						pastedNotes.push(note);

						if (note.sustainLength > 0)
						{
							var sustainVis:FlxSprite = new FlxSprite(note.x + 20, note.y + gridSize).makeGraphic(1, 1);
							sustainVis.setGraphicSize(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength)) - note.y));
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

	function containsName(name:String, events:Array<Event>):Event
	{
		for (i in events)
		{
			if (i.name == name)
				return i;
		}
		return null;
	}

	inline function clearSection():Void
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

	inline function getStrumTime(yPos:Float):Float
	{
		return Conductor.stepCrochet * (yPos / gridSize);
		// return FlxMath.remapToRange(yPos, 0, Conductor.stepCrochet, 0, gridSize);
	}

	inline function getYfromStrum(strumTime:Float):Float
	{
		return gridSize * (strumTime / Conductor.stepCrochet);
		// return FlxMath.remapToRange(strumTime, 0, gridSize, 0, Conductor.stepCrochet);
	}

	inline function getSectionSteps(?section:Null<Int> = null)
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
		if (SONG.notes[section] != null && section < lengthInSections)
		{
			curSection = section;
			inst.time = (data.startTime + ((beat - data.startBeat) / (data.bpm / 60))) * 1000;
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
					vocals = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
			}
			else
			{
				if (SONG.needsVoices)
				{
					vocalsP = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'P'));
					vocalsE = new FlxSound().loadEmbedded(Paths.voices(SONG.audioFile, 'E'));
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
			vocalsP = new FlxSound();
			vocalsE = new FlxSound();
			FlxG.sound.list.add(vocalsP);
			FlxG.sound.list.add(vocalsE);
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

		var data:String = haxe.Json.stringify(json, null);

		var data:SongData = cast autoSaveData;
		var meta:SongMeta = {};
		var name:String = data.songId;
		if (autoSaveData.song != null)
		{
			meta = autoSaveData.songMeta != null ? cast autoSaveData.songMeta : {};
		}

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

		var data:String = haxe.Json.stringify(json, null);

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(#if desktop OpenFlEvent.SELECT #else OpenFlEvent.COMPLETE #end, onSaveComplete);
			_file.addEventListener(OpenFlEvent.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), SONG.songId.toLowerCase() + CoolUtil.getSuffixFromDiff(curDiff) + ".json");
		}
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(OpenFlEvent.COMPLETE, onSaveComplete);
		_file.removeEventListener(OpenFlEvent.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		NotificationManager.instance.addNotification({
			title: "Chart Saved.",
			body: "Chart Saved Successfully.",
			type: NotificationType.Success,
		});
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(OpenFlEvent.COMPLETE, onSaveComplete);
		_file.removeEventListener(OpenFlEvent.CANCEL, onSaveCancel);
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
		_file.removeEventListener(OpenFlEvent.COMPLETE, onSaveComplete);
		_file.removeEventListener(OpenFlEvent.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.error("Problem saving Level data");
		NotificationManager.instance.addNotification({
			title: "Error Saving Chart.",
			body: "There Has Been An Error Saving The Chart.",
			type: NotificationType.Error
		});
	}

	private function songShit()
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
			}
		}
	}

	function addAssetUI()
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

	function addNoteUI()
	{
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

		var quantiNotes = new CheckBox();
		quantiNotes.text = "Color Quant";
		quantiNotes.selected = FlxG.save.data.stepMania;
		quantiNotes.onClick = function(e)
		{
			FlxG.save.data.stepMania = !FlxG.save.data.stepMania;
			updateNotes();
		}

		box2.addComponent(noteShitDrop);
		box2.addComponent(typeLabel);
		box2.addComponent(quantiNotes);
	}

	function addSectionUI()
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
			destroyBoxes();
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
				copiedNote = [newStrumTime, note[1], note[2], note[3]];
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
				section.bpm = bpm.pos;

			if (SONG.eventObjects[0].type != "BPM Change")
				lime.app.Application.current.window.alert("i'm crying, first event isn't a bpm change. fuck you");
			else
				SONG.eventObjects[0].args[0] = bpm.pos;

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in SONG.eventObjects)
			{
				if (i.type == "BPM Change")
				{
					final beat:Float = i.beat;
					final bpm:Float = i.args[0];
					final endBeat:Float = Math.POSITIVE_INFINITY;

					TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset

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
		scrollSpeed.precision = 3;
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

		var eventList:Array<Event> = []; // existing events
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

			savedValue = event.args[0];
			savedValue2 = event.args[1];
			savedType = event.type;
			currentSelectedEventName = event.name;
			eventName.text = currentSelectedEventName;
			eventVal1.text = event.args[0] + "";
			eventVal2.text = event.args[1] + "";
			currentEventPosition = event.beat;
			eventPosition.text = Std.string(currentEventPosition);
			eventVal2.text = event.args[1] + "";
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
			var pog:Event = {
				name: "New Event " + HelperFunctions.truncateFloat(curDecimalBeat, 2),
				beat: HelperFunctions.truncateFloat(curDecimalBeat, 3),
				args: [SONG.bpm, 1],
				type: "BPM Change"
			};

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
			eventVal1.text = pog.args[0] + "";
			eventVal2.text = pog.args[1] + "";
			eventPosition.text = pog.beat + "";
			currentSelectedEventName = pog.name;
			currentEventPosition = pog.beat;
			savedValue = pog.args[0];
			savedValue2 = pog.args[1];
			savedType = pog.type;

			eventDrop.dataSource = existingEvents;
			eventDrop.selectItemBy(item -> item == currentSelectedEventName, true);
			eventTypes.selectItemBy(item -> item == savedType, true);

			if (pog.type == 'BPM Change')
			{
				setSongTimings();
				recalculateAllSectionTimes();
				updateNotes();
				destroyBoxes();
			}
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
			var pog:Event = {
				name: currentSelectedEventName,
				beat: currentEventPosition,
				args: [savedValue, savedValue2],
				type: savedType
			};

			var obj = containsName(pog.name, SONG.eventObjects);

			if (pog.name == "")
				return;

			if (obj != null)
				SONG.eventObjects.remove(obj);

			SONG.eventObjects.push(pog);
			SONG.eventObjects.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});

			existingEvents.clear();
			eventList.resize(0);
			for (event in 0...SONG.eventObjects.length)
			{
				existingEvents.add(SONG.eventObjects[event].name);
				eventList.push(SONG.eventObjects[event]);
			}
			eventDrop.dataSource = existingEvents;
			eventIndex = eventList.length - 1;
			eventDrop.selectItemBy(item -> item == pog.name, true);
			autosaveSong();

			if (pog.type == "BPM Change")
			{
				setSongTimings();
				recalculateAllSectionTimes();
				updateNotes();
				destroyBoxes();
				// may break things, but will improve performance when it isn't a bpm change
			}
			regenerateLines();

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
				SONG.eventObjects.push({
					name: "Init BPM",
					beat: 0,
					args: [SONG.bpm, 1],
					type: "BPM Change"
				});
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
			eventVal1.text = firstEvent.args[0] + "";
			eventVal2.text = firstEvent.args[1] + "";
			eventPosition.text = firstEvent.beat + "";
			currentSelectedEventName = firstEvent.name;
			currentEventPosition = firstEvent.beat;
			eventDrop.selectItemBy(item -> item == firstEvent.name, true);

			if (firstEvent.type == "BPM Change")
			{
				setSongTimings();
				recalculateAllSectionTimes();
				updateNotes();
				destroyBoxes();
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
			obj.beat = currentEventPosition;
			eventPosition.text = currentEventPosition + "";
		}

		eventPosition = new TextField();
		eventPosition.text = Std.string(SONG.eventObjects[0].beat);
		eventPosition.onChange = function(e)
		{
			var obj = containsName(currentSelectedEventName, SONG.eventObjects);
			if (obj == null)
				return;
			currentEventPosition = Std.parseFloat(eventPosition.text);
			obj.beat = currentEventPosition;
		}

		eventVal1 = new TextField();
		eventVal1.text = SONG.eventObjects[0].args[0];
		eventVal1.onChange = function(e)
		{
			savedValue = eventVal1.text;
		}

		eventVal2 = new TextField();
		eventVal2.text = SONG.eventObjects[0].args[1];
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

	function addTabs()
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

	function menuBarShit()
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
		saveSong.onClick = function(e)
		{
			saveLevel();
		}

		var loadAuto = new MenuItem();
		loadAuto.text = "Load Autosave";
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
				Debug.logTrace(e);
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

		file.addComponent(saveSong);
		file.addComponent(reloadChart);
		file.addComponent(reload);
		file.addComponent(loadAuto);
		file.addComponent(cleanSong);

		var dragTabs = new MenuCheckBox();
		dragTabs.text = "Drag Tablist";
		dragTabs.selected = FlxG.save.data.moveEditor;
		dragTabs.onClick = function(e)
		{
			FlxG.save.data.moveEditor = !FlxG.save.data.moveEditor;
			ui.draggable = FlxG.save.data.moveEditor;
			dragTabs.selected = FlxG.save.data.moveEditor;
		}

		metronome = new MenuCheckBox();
		metronome.text = "Metronome";
		metronome.selected = FlxG.save.data.chart_metronome;
		metronome.onClick = function(e)
		{
			FlxG.save.data.chart_metronome = !FlxG.save.data.chart_metronome;
			metronome.selected = FlxG.save.data.chart_metronome;
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
		hitsoundsP.selected = FlxG.save.data.playHitsounds;
		hitsoundsP.onClick = function(e)
		{
			FlxG.save.data.playHitsounds = !FlxG.save.data.playHitsounds;
			hitsoundsP.selected = FlxG.save.data.playHitsounds;
		}

		hitsoundsE = new MenuCheckBox();
		hitsoundsE.text = "Hitsounds (Opponent)";

		hitsoundsE.selected = FlxG.save.data.playHitsoundsE;
		hitsoundsE.onClick = function(e)
		{
			FlxG.save.data.playHitsoundsE = !FlxG.save.data.playHitsoundsE;
			hitsoundsE.selected = FlxG.save.data.playHitsoundsE;
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
		personal.addComponent(resetPos);
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

	private function initEvents()
	{
		var eventObjects:Array<Event> = [];

		if (SONG.eventObjects == null || SONG.eventObjects.length == 0)
			SONG.eventObjects = [
				{
					name: "Init BPM",
					beat: 0,
					args: [SONG.bpm, 1],
					type: "BPM Change"
				}
			];

		for (i in SONG.eventObjects)
			eventObjects.push({
				name: i.name,
				beat: i.beat,
				args: i.args,
				type: i.type
			});

		eventObjects.sort(Sort.sortEvents);
		SONG.eventObjects = eventObjects;
	}

	inline function mouseValid():Bool
	{
		// NOTE: we're checking the mouse's y so notes/events can't be placed outside of the grid

		return mouseCursor.x >= editorArea.x - separatorWidth
			&& mouseCursor.x < editorArea.x + editorArea.width
			&& FlxG.mouse.y >= 0
			&& FlxG.mouse.y < editorArea.bottom;
	}

	inline function getMouseY():Float
	{
		return (doSnapShit) ? quantizePosWithSnap(FlxG.mouse.y, quantization) : FlxG.mouse.y;
	}

	public static inline function quantizePos(position:Float):Float
	{
		return Math.ffloor(position / gridSize) * gridSize;
	}

	public static inline function quantizePosWithSnap(position:Float, snap:Int):Float
	{
		var mult:Float = gridSize * (16 / snap);
		return Math.ffloor(position / mult) * mult;
	}

	private function checkNoteSpawn()
	{
		var strumTime = getStrumTime(mouseCursor.y);
		var noteData:Int = Math.floor((mouseCursor.x - editorArea.x) / gridSize);
		var existingNote:Note = curRenderedNotes.getFirst((n) -> n.alive && n.rawNoteData == noteData && FlxG.mouse.overlaps(n));
		if (existingNote == null)
			addNote();
		else
			deleteNote(existingNote);
	}

	private inline function createGrid()
	{
		editorArea = new EditorArea();
		editorArea.bottom = getYfromStrum(inst.length);
		add(editorArea);

		mouseCursor = new FlxSprite().makeGraphic(gridSize, gridSize);
		mouseCursor.alpha = 1;
		mouseCursor.updateHitbox();
		mouseCursor.setPosition(editorArea.x, gridSize);
		mouseCursor.active = false;

		strumLine = new FlxSprite(0, -100);
		strumLine.makeGraphic(Std.int(gridSize * 8), 4, FlxColor.fromRGB(255, 25, 25));
		strumLine.updateHitbox();
		strumLine.screenCenter(X);
		strumLine.x += separatorWidth;
		strumLine.active = false;

		FlxG.camera.follow(strumLine, LOCKON);
		FlxG.camera.targetOffset.y = 100;
		add(mouseCursor);
		add(strumLine);
	}

	private function setSongTimings()
	{
		TimingStruct.clearTimings();

		var currentIndex = 0;
		for (event in SONG.eventObjects)
		{
			switch (event.type)
			{
				case 'BPM Change':
					{
						final beat:Float = event.beat;
						final endBeat:Float = Math.POSITIVE_INFINITY;
						final bpm = event.args[0];
						TimingStruct.addTiming(beat, bpm, endBeat, 0); // offset in this case = start time since we don't have a offset

						if (currentIndex != 0)
						{
							var data = TimingStruct.AllTimings[currentIndex - 1];
							data.endBeat = beat;
							data.length = ((data.endBeat - (data.startBeat)) / (data.bpm / 60));
							var step = ((60 / (data.bpm)) * 1000) / 4;
							TimingStruct.AllTimings[currentIndex].startStep = Math.floor((((data.endBeat / (data.bpm / 60)) * 1000) / step));
							TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
						}

						currentIndex++;
						recalculateAllSectionTimes();
					}
			}
		}

		// sort events by beat
		if (SONG.eventObjects != null)
		{
			SONG.eventObjects.sort(function(a, b)
			{
				if (a.beat < b.beat)
					return -1
				else if (a.beat > b.beat)
					return 1;
				else
					return 0;
			});
		}
	}
}
