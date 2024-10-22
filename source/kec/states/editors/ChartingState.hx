package kec.states.editors;

import kec.objects.editor.TextLine;
import kec.objects.editor.EditorSustain;
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
import kec.backend.chart.Event;
import kec.backend.chart.format.Modern;
import kec.backend.chart.Song;
import kec.backend.chart.TimingStruct;
import kec.backend.util.HelperFunctions;
import kec.backend.util.NoteStyleHelper;
import kec.backend.util.Sort;
import kec.backend.util.Sort;
import kec.backend.character.CharacterData;
import kec.objects.CoolText;
import kec.objects.note.Note;
import kec.objects.ui.HealthIcon;
import kec.objects.editor.ChartingBox;
import openfl.Lib;
import openfl.events.Event as OpenFlEvent;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import kec.backend.chart.ChartNote;
import kec.backend.chart.format.Section;
import kec.objects.editor.EditorNote;
import kec.objects.editor.EditorGrid;
import kec.objects.editor.BeatLine;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end

class ChartingState extends MusicBeatState
{
	public static var instance:ChartingState = null;

	var ui:TabView;
	var entireUI:VBox;
	var menu:MenuBar;

	var box:ContinuousHBox;
	var box2:ContinuousHBox;
	var box3:ContinuousHBox;
	var box4:HBox;
	var box5:ContinuousHBox;

	var vbox1:VBox;
	var vbox3:VBox;
	var uiGrid:Grid;

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

	public var SONG:Modern;
	public var lastUpdatedSection:Section = null;

	public static final gridSize:Int = 45; // scale? GRID_SIZE?

	final notePos = 100; // General Note Pos

	public static final size = 0.5; // general size / spacing of things

	var currentSelectedEventName:String = "";
	var savedType:String = "BPM Change";
	var savedValue:String = "100";
	var savedValue2:String = "1";
	var currentEventPosition:Float = 0;

	var noteGroup:FlxTypedGroup<EditorNote>;
	var sustainGroup:FlxTypedGroup<EditorSustain>;
	private var noteCounter:Int = 0;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;
	public var curSelectedNoteObject:EditorNote = null;

	public var copiedNotes:Array<ChartNote> = [];
	public var pastedNotes:Array<EditorNote> = [];
	public var deletedNotes:Array<ChartNote> = [];
	public var lastAction:String = "";

	var curSelectedNote:ChartNote;
	var texts:FlxTypedGroup<TextLine>;
	var lines:FlxTypedGroup<BeatLine>;

	var inst:FlxSound;
	var vocals:FlxSound;
	var vocalsP:FlxSound;
	var vocalsE:FlxSound;

	var iconP1:HealthIcon;
	var iconP2:HealthIcon;

	var player:CharacterData;
	var opponent:CharacterData;

	var lastConductorPos:Float;
	var strumLine:FlxSprite;

	public static var lengthInSteps:Int = 0;
	public static var lengthInBeats:Int = 0;
	public static var lengthInSections:Int = 0;

	public var pitch:Float = 1.0;

	var snap:Bool = true;
	var defaultSnap:Bool = true;

	public static var quantization:Int = 16;
	public static var curQuant = 3;

	var curDiff:String = "";

	public var quantList:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];

	var mouse:FlxSprite;

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

	private var grid:EditorGrid;
	private var maxBeat = 0;

	public var end:Float = 1.0;

	private var paused(default, set):Bool = true;

	// one does not realize how much flixel-ui is used until one sees an FNF chart editor. 💀

	/*
		>new chart editor
		>looks inside
		>kade engine chart editor
	 */
	override function create()
	{
		instance = this;

		Paths.clearCache();

		ui = new TabView();
		ui.text = "huh";
		ui.draggable = FlxG.save.data.moveEditor;
		ui.height = 300;

		menu = new MenuBar();
		menu.continuous = true;
		menu.height = 30;
		menu.width = FlxG.width;

		FlxG.mouse.visible = true;

		lines = new FlxTypedGroup<BeatLine>();
		texts = new FlxTypedGroup<TextLine>();

		noteGroup = new FlxTypedGroup<EditorNote>();
		sustainGroup = new FlxTypedGroup<EditorSustain>();

		PlayState.inDaPlay = false;
		SONG = PlayState.SONG;
		loadSong(SONG.audioFile, false);

		inst.time = 0;
		Conductor.rate = 1;
		Conductor.bpm = SONG.eventObjects[0].args[0];
		TimingStruct.setSongTimings(SONG);
		Song.checkforSections(SONG, inst.length);
		Song.recalculateAllSectionTimes(SONG);
		setInitVars();

		activeSong = SONG;
		Debug.logTrace('${TimingStruct.AllTimings.length} ${curTiming.endBeat}');
		lengthInBeats = Math.round(TimingStruct.getBeatFromTime(inst.length));
		lengthInSteps = lengthInBeats * 4;
		lengthInSections = Std.int(lengthInBeats / 4);
		Debug.logTrace('Total Beats ${lengthInBeats}. Total Steps ${lengthInSteps} Probable Length In Sections ${lengthInSections}');
		currentSection = getSectionByTime(0);

		curSection = 0;

		curDiff = CoolUtil.difficulties[PlayState.storyDifficulty];
		Constants.noteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.noteskin);
		Constants.cpuNoteskinSprite = NoteStyleHelper.generateNoteskinSprite(FlxG.save.data.cpuNoteskin);
		Constants.noteskinPixelSprite = NoteStyleHelper.generatePixelSprite(FlxG.save.data.noteskin);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF111111;
		add(bg);

		characters = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		gfs = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));
		stages = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		noteTypes = CoolUtil.coolTextFile(Paths.txt('data/noteTypeList'));
		noteStyles = CoolUtil.coolTextFile(Paths.txt('data/songStyleList'));
		events = CoolUtil.coolTextFile(Paths.txt('data/eventList'));

		createGrid();

		regenerateLines();

		end = getYFromTime(inst.length);

		player = new CharacterData(SONG.player1, true);
		opponent = new CharacterData(SONG.player2, false);

		iconP2 = new HealthIcon(opponent.icon, false);
		iconP1 = new HealthIcon(player.icon, true);

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

		entireUI = new VBox();
		menuBarShit();
		entireUI.addComponent(menu);
		var tempSpacer = new Spacer();
		tempSpacer.height = 420;
		entireUI.addComponent(tempSpacer);
		entireUI.addComponent(ui);

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

		add(entireUI);

		selectBox = new FlxSprite(0, 0).makeGraphic(1, 1, FlxColor.fromRGB(173, 216, 230));
		selectBox.visible = false;
		selectBox.alpha = 0.4;
		add(selectBox);

		id = Lib.setInterval(backupChart, 5 * 60 * 1000);

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

		final lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 12), 0, 1);
		strumLine.y = FlxMath.lerp(getYFromTime(inst.time), strumLine.y, lerpVal);
		// strumLine.y = getYFromTime(inst.time);

		var weird = getSectionByTime(inst.time);

		if (weird != null)
		{
			if (lastUpdatedSection != getSectionByTime(inst.time))
			{
				lastUpdatedSection = weird;
				playerSection.selected = weird.mustHitSection;
			}
		}

		var interacting:Bool = Screen.instance.hasComponentUnderPoint(FlxG.mouse.screenX, FlxG.mouse.screenY);
		var mouseX:Float = quantizePos(FlxG.mouse.x - grid.x);
		mouse.x = Math.min(grid.x + mouseX + separatorWidth * Math.floor(mouseX / gridSize / 4), grid.x + grid.width);
		mouse.y = FlxMath.bound(getMouseY(), 0, end - gridSize);
		mouse.visible = (mouseValid() && !interacting);

		if (FlxG.mouse.justPressed && !waitingForRelease)
		{
			if (!FlxG.keys.pressed.CONTROL && mouse.visible)
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
			noteGroup.forEachAlive(function(n:EditorNote)
			{
				if (n.overlaps(selectBox) && !n.selected)
				{
					selectNote(n);
				}
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

			if (FlxG.keys.justPressed.C)
			{
				curQuant--;
				if (curQuant < 0)
					curQuant = quantList.length - 1;
			}

			if (FlxG.keys.justPressed.V)
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

			if (FlxG.keys.pressed.CONTROL && !FlxG.keys.pressed.ALT && FlxG.keys.justPressed.C)
			{
				if (selectedBoxes.members.length != 0)
				{
					copiedNotes = [];
					selectedBoxes.forEachAlive(function(i:ChartingBox)
					{
						copiedNotes.push({
							time: i.connectedNote.time,
							data: i.connectedNote.rawData,
							length: i.connectedNote.holdLength,
							type: i.connectedNote.type
						});
					});

					var firstNote = copiedNotes[0].time;

					for (i in copiedNotes) // normalize the notes
						i.time = i.time - firstNote;
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
					deletedNotes.push({
						time: i.connectedNote.time,
						data: i.connectedNote.rawData,
						length: i.connectedNote.holdLength,
						type: i.connectedNote.type,
					});
					notesToBeDeleted.push(i.connectedNote);
				});

				for (i in notesToBeDeleted)
				{
					deleteNote(i);
				}
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
				paused = !paused;

			if (FlxG.mouse.wheel != 0)
				scroll(FlxG.mouse.wheel);
		}

		var playedSound:Array<Bool> = [false, false, false, false, false, false, false, false];
		noteGroup.forEachAlive(function(note:EditorNote)
		{
			if (note.time <= Conductor.songPosition)
			{
				if (note.time > lastConductorPos && inst.playing && note.data > -1 && note.hitsoundsEditor)
				{
					var data:Int = note.rawData;
					var noteDataToCheck:Int = data;
					var playerNote = noteDataToCheck >= 4;
					if (!playedSound[data])
					{
						if ((FlxG.save.data.playHitsounds && playerNote) || (FlxG.save.data.playHitsoundsE && !playerNote))
						{
							if (FlxG.save.data.hitSound == 0)
								daHitSound = new FlxSound().loadEmbedded(Paths.sound('hitsounds/snap'));
							else
								daHitSound = new FlxSound()
									.loadEmbedded(Paths.sound('hitsounds/${HitSounds.getSoundByID(FlxG.save.data.hitSound).toLowerCase()}'));
							daHitSound.volume = hitsoundsVol.pos;
							daHitSound.play().pan = noteDataToCheck < 4 ? -0.3 : 0.3;
							playedSound[data] = true;
						}
						data = noteDataToCheck;
					}
				}
			}
		});

		while (noteCounter < currentSection.sectionNotes.length)
		{
			final chartNote = currentSection.sectionNotes[noteCounter];
			var note:EditorNote = noteGroup.recycle(EditorNote);
			note.setup(chartNote.time, chartNote.data, chartNote.length, chartNote.type, TimingStruct.getBeatFromTime(chartNote.time));
			note.setGraphicSize(gridSize, gridSize);
			note.updateHitbox();
			note.setPosition(grid.x + (gridSize * chartNote.data), getYFromTime(chartNote.time));
			if (note.holdLength > 0)
			{
				var sustain:EditorSustain = sustainGroup.recycle(EditorSustain);
				sustain.setup(note.x + 20, note.y + gridSize, 8, Math.floor((getYFromTime(note.time + note.holdLength)) - note.y));
			}
			noteCounter++;
		}

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
		songShit();
		super.update(elapsed);
	}

	function regenerateLines()
	{
		lines.forEachAlive(function(l:BeatLine) l.kill());
		texts.forEachAlive(function(t:TextLine) t.kill());

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

			var type = i.type;

			final text:TextLine = texts.recycle(TextLine);
			text.reuse(grid.x + (gridSize * 8) + separatorWidth, pos, 16);
			text.text = i.name + "\n" + type + "\n" + i.args[0] + "\n" + i.args[1];
			text.updateHitbox();

			final line:BeatLine = lines.recycle(BeatLine);
			line.setup(grid.x, pos, FlxColor.YELLOW);
		}
	}

	private function addNote():Void
	{
		destroyBoxes();

		var strum = (mouse.y);
		var spawnTime = strum;
		var noteData:Int = Math.floor((mouse.x - grid.x) / gridSize);
		var noteType = noteTypes[noteShitDrop.selectedIndex];
		var playerNote:Bool = (noteData > 3);
		var sec = getSectionByTime(strum);

		if (PlayStateChangeables.opponentMode)
			playerNote = !playerNote;

		sec.sectionNotes.push({
			time: spawnTime,
			data: noteData,
			length: 0,
			type: noteType
		}); // retarded ass note saving

		Debug.logTrace("Note Data : " + noteData + " StrumTime : " + spawnTime);

		var note:EditorNote = noteGroup.recycle(EditorNote);
		note.setup(spawnTime, noteData, 0, noteType, TimingStruct.getBeatFromTime(spawnTime));
		note.setGraphicSize(gridSize, gridSize);
		note.updateHitbox();
		note.x = grid.x + Math.floor(noteData * gridSize) + separatorWidth;
		if (noteData < 4)
			note.x -= separatorWidth;
		note.y = Math.floor(getYFromTime(spawnTime));

		curSelectedNote = sec.sectionNotes[sec.sectionNotes.length - 1];
		curSelectedNoteObject = note;
		createBox(note.x, note.y, note);
		note.selected = true;
		curSelectedNoteObject.selected = true;
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

	function deleteNote(existingNote:EditorNote):Void
	{
		destroyBoxes();
		var sec = getSectionByTime(existingNote.time);
		var i:Int = sec.sectionNotes.length;
		while (--i > -1)
		{
			if (sec.sectionNotes[i].time == existingNote.time && sec.sectionNotes[i].data == existingNote.rawData)
				sec.sectionNotes.remove(sec.sectionNotes[i]);
		}
		// thanks Chris(Dimensionscape) from the FNF thread
		existingNote.kill();
		if (existingNote.holdLength > 0)
			existingNote.noteCharterObject.kill();

		curSelectedNote = null;
		// Debug.logTrace("tryna delete note");
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
		super.destroy();
	}

	function changeNoteSustain(value:Float):Void
	{
		if (curSelectedNote == null)
			return;

		curSelectedNote.length += Math.ceil(value);
		curSelectedNote.length = Math.max(curSelectedNote.length, 0);
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

		// ok so basically theres a bug with color quant that it doesn't update the color until the grid updates.
		// when the grid updates, it causes a massive performance drop everytime we offset the notes. :/
		// actually its broken either way because theres a ghost note after offsetting sometimes. updateGrid anyway.
	}

	function pasteNotesFromArray(array:Array<ChartNote>, fromStrum:Bool = true)
	{
		if (copiedNotes.length < 0)
			return;
		else
		{
			for (i in array)
			{
				var strum:Float = i.time;
				if (fromStrum)
					strum += Conductor.songPosition;
				var section = 0;
				for (ii in SONG.notes)
				{
					if (ii.startTime <= strum && ii.endTime > strum)
					{
						// alright we're in this section lets paste the note here.
						ii.sectionNotes.push({
							time: strum,
							data: i.data,
							length: i.length,
							type: i.type
						});
					}
					section++;
				}
			}
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
	}

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
		Debug.logTrace("Going too " + inst.time + " | " + section + " | Which is at " + beat + " | Section Index " + sec.index);

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
		notetypetext.text = "Note Type: " + noteType;
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
	}

	function loadAutosave():Void
	{
		var autoSaveData = Json.parse(FlxG.save.data.autosave);

		var json = {
			"song": SONG
		};

		var data:String = haxe.Json.stringify(json, null);

		var data:Modern = cast autoSaveData;
		var meta:SongMeta = {};
		var name:String = data.songId;
		if (autoSaveData.song != null)
		{
			meta = autoSaveData.songMeta != null ? cast autoSaveData.songMeta : {};
		}

		PlayState.SONG = Song.parseJSONshit(data.songId, data, meta);
		MusicBeatState.switchState(new ChartingState());
		Lib.clearInterval(id);
	}

	function loadJson(songId:String, diff:String):Void
	{
		try
		{
			PlayState.storyDifficulty = CoolUtil.difficulties.indexOf(diff);
			PlayState.SONG = Song.loadFromJson(songId.toLowerCase(), CoolUtil.getSuffixFromDiff(diff));

			Debug.logTrace(songId);
			// mustCleanMem = true;

			MusicBeatState.switchState(new ChartingState());
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
		SONG.chartVersion = Constants.chartVer;

		var data:String = haxe.Json.stringify(SONG, null);

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

			sect.mustHitSection = playerSection.selected;
		}

		refreshSec = new Button();
		refreshSec.text = "Refresh All Sections";
		refreshSec.onClick = function(e)
		{
			var section = getSectionByTime(Conductor.songPosition);

			if (section == null)
				return;

			playerSection.selected = section.mustHitSection;
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
			var duetNotes:Array<ChartNote> = [];
			for (note in SONG.notes[curSection].sectionNotes)
			{
				var boob = note.data;
				if (boob > 3)
					boob -= 4;
				else
					boob += 4;

				var copiedNote:ChartNote = {
					time: note.time,
					data: boob,
					length: note.length,
					type: note.type
				};
				duetNotes.push(copiedNote);
			}

			for (i in duetNotes)
			{
				SONG.notes[curSection].sectionNotes.push(i);
			}
		}

		mirror = new Button();
		mirror.text = "Mirror Notes";
		mirror.onClick = function(e)
		{
			var mirrored:Array<ChartNote> = [];
			for (note in SONG.notes[curSection].sectionNotes)
			{
				var boob = note.data % 4;
				boob = 3 - boob;
				if (note.data > 3)
					boob += 4;

				var copiedNote:ChartNote = {
					time: note.time,
					data: boob,
					length: note.length,
					type: note.type
				};
				mirrored.push(copiedNote);
			}

			for (i in mirrored)
			{
				SONG.notes[curSection].sectionNotes.push(i);
			}

			destroyBoxes();
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
				var note:ChartNote = secit.sectionNotes[i];
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

			var addToTime:Float = Conductor.stepCrochet * (16 * (curSection - sectionToCopy));
			// trace('Time to add: ' + addToTime);
			for (note in copiedNotes)
			{
				var newStrumTime:Float = note.time + addToTime;
				var copiedNote:ChartNote = {
					time: newStrumTime,
					data: note.data,
					length: note.length,
					type: note.type
				};
				SONG.notes[curSection].sectionNotes.push(copiedNote);
			}
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
		uiGrid = new Grid();
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
			if (SONG.bpm != bpm.pos)
			{
				SONG.bpm = bpm.pos;
				SONG.eventObjects[0].args[0] = bpm.pos;
				recalculateAllSectionTimes();
				calculateMaxBeat();
				checkforSections();
				regenerateLines();
				if (SONG.eventObjects[0].type != "BPM Change")
					lime.app.Application.current.window.alert("i'm crying, first event isn't a bpm change. fuck you");
				else
					SONG.eventObjects[0].args[0] = bpm.pos;
			}
		}

		var bpmLabel = new Label();
		bpmLabel.text = "BPM";
		bpmLabel.verticalAlign = "center";

		scrollSpeed = new NumberStepper();
		scrollSpeed.max = 10;
		scrollSpeed.min = 0.1;
		scrollSpeed.precision = 3;
		scrollSpeed.step = 0.05;
		scrollSpeed.pos = SONG.speed;
		scrollSpeed.decimalSeparator = ".";
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
		var difficulties:Array<String> = CoolUtil.difficulties;
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

		uiGrid.addComponent(song);
		uiGrid.addComponent(songId);

		uiGrid.addComponent(songName);
		uiGrid.addComponent(displayName);

		uiGrid.addComponent(audioFileName);
		uiGrid.addComponent(audioFile);

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

		vbox1.addComponent(uiGrid);
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
							for (daSection in SONG.notes)
							{
								for (i in 0...daSection.sectionNotes.length)
									daSection.sectionNotes = [];
							}
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

		/*
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
					bpm: 150,
					needsVoices: true,
					player1: 'bf',
					player2: 'dad',
					gfVersion: 'gf',
					style: 'Default',
					stage: 'stage',
					speed: 1,
					validScore: true,
					eventObjects: [
						{
							name: "Init BPM",
							beat: 0,
							args: [150],
							type: "BPM Change"
						}
					]
				};

				var cleanedData = Json.parse(haxe.Json.stringify({
					"song": cleaned
				}));

				var data:Modern = cast cleanedData;
				var meta:SongMeta = {};
				if (cleanedData.song != null)
				{
					meta = cleanedData.songMeta != null ? cast cleanedData.songMeta : {};
				}
				PlayState.SONG = Song.parseJSONshit(data.songId, data, meta);
				clean = true;
				MusicBeatState.switchState(new ChartingState());
			}
			broken for now, smth smth events smh
		 */

		file.addComponent(saveSong);
		file.addComponent(reloadChart);
		file.addComponent(reload);
		file.addComponent(loadAuto);
		file.addComponent(cleanSong);
		// file.addComponent(create);

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

	override function sectionHit()
	{
		super.sectionHit();
		if (curSection < 0)
			return;

		noteGroup.forEachAlive(function(n:EditorNote)
		{
			n.kill();
		});

		sustainGroup.forEachAlive(function(n:EditorSustain)
		{
			n.kill();
		});
		noteCounter = 0;
	}

	override function beatHit()
	{
		super.beatHit();

		if (FlxG.save.data.chart_metronome)
			FlxG.sound.play(Paths.sound('Metronome_Tick'));
	}

	override function stepHit()
	{
		super.stepHit();
		if (inst.playing)
		{
			iconP1.onStepHit(curStep);
			iconP2.onStepHit(curStep);
		}
	}

	inline function mouseValid():Bool
	{
		// NOTE: we're checking the mouse's y so notes/events can't be placed outside of the grid

		return mouse.x >= grid.x - separatorWidth && mouse.x < grid.x + grid.width && FlxG.mouse.y >= 0 && FlxG.mouse.y < end;
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
		var strumTime = getTimeFromY(mouse.y);
		var noteData:Int = Math.floor((mouse.x - grid.x) / gridSize);
		var existingNote:EditorNote = noteGroup.getFirst((n) -> n.alive && n.rawData == noteData && FlxG.mouse.overlaps(n));
		if (existingNote == null)
			addNote();
		else
			deleteNote(existingNote);
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

		FlxG.camera.follow(strumLine, LOCKON);
		FlxG.camera.targetOffset.y = 100;
		add(mouse);
		add(strumLine);
	}

	function calculateMaxBeat()
		maxBeat = Math.round(TimingStruct.getBeatFromTime(inst.length));

	function checkforSections()
	{
		final totalBeats = maxBeat;

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
}
