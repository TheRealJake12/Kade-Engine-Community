package debug;

import Song.SongMeta;
import lime.app.Application;
#if FEATURE_FILESYSTEM
import sys.io.File;
import sys.FileSystem;
#end
import flixel.addons.ui.FlxUIButton;
import flixel.FlxObject;
import flixel.addons.ui.FlxUIText;
import Section.SwagSection;
import Song.SongData;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUI;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.addons.ui.FlxUITabMenu;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.sound.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.media.Sound;
import openfl.net.FileReference;
import CoolUtil.CoolText;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end

using StringTools;

@:access(flixel.system.FlxSound._sound)
@:access(openfl.media.Sound.__buffer)
class ChartingState extends MusicBeatState
{
	public static var instance:ChartingState = null;

	public var notename:String = "";

	var _file:FileReference;

	public var inst:FlxSound;

	public var snap:Int = 16;

	public static var curSnap:Int = 3;

	public var snapArray:Array<Int> = [4, 8, 12, 16, 20, 24, 32, 48, 64];

	public var deezNuts:Map<Int, Int> = new Map<Int, Int>(); // snap conversion map

	var UI_box:FlxUITabMenu;
	var UI_options:FlxUITabMenu;

	public static var lengthInSteps:Float = 0;
	public static var lengthInBeats:Float = 0;

	public var speed = 1.0;

	var noteShit:Int = 0;
	var shits:Array<String> = ['normal', 'hurt', 'mustpress'];
	var notetypetext:CoolText;

	public var beatsShown:Float = 1; // for the zoom factor
	public var zoomFactor:Float = 0.4;

	/**
	 * Array of notes showing when each section STARTS in STEPS
	 * Usually rounded up??
	 */
	// var curSection:Int = 0;
	public static var lastSection:Int = 0;

	var bpmTxt:CoolText;

	var strumLine:FlxSprite;
	var curSong:String = 'Dad Battle';
	var amountSteps:Int = 0;
	var bullshitUI:FlxGroup;
	var writingNotesText:FlxText;
	var highlight:FlxSprite;
	var sectionToCopy:Int = 0;

	var GRID_SIZE:Int = 40;

	var subDivisions:Float = 1;
	var defaultSnap:Bool = true;

	var dummyArrow:FlxSprite;

	var curRenderedNotes:FlxTypedGroup<Note>;
	var curRenderedSustains:FlxTypedGroup<FlxSprite>;

	public var sectionRenderes:FlxTypedGroup<SectionRender>;

	var gridBG:FlxSprite;

	public static var _song:SongData;

	var typingShit:FlxInputText;
	var typingShit2:FlxInputText;
	/*
	 * WILL BE THE CURRENT / LAST PLACED NOTE
	**/
	var curSelectedNote:Array<Dynamic>;

	var tempBpm:Float = 0;
	var gridBlackLine:FlxSprite;
	var vocals:FlxSound;
	var vocalsPlayer:FlxSound;
	var vocalsEnemy:FlxSound;

	var player2:Character;
	var player1:Boyfriend;

	public static var leftIcon:HealthIcon;
	public static var rightIcon:HealthIcon;

	var height = 0;

	private var lastNote:Note;

	public var lines:FlxTypedGroup<FlxSprite>;

	public var snapText:FlxText;

	var camFollow:FlxObject;

	public var waveform:Waveform;

	public static var latestChartVersion = "2";

	public function new(reloadOnInit:Bool = false)
	{
		super();
		// If we're loading the charter from an arbitrary state, we need to reload the song on init,
		// but if we're not, then reloading the song is a performance drop.
		this.reloadOnInit = reloadOnInit;
	}

	var reloadOnInit = false;
	var curDiff:String = "";

	override function create()
	{
		#if FEATURE_DISCORD
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		instance = this;

		speed = PlayState.songMultiplier;
		// curSection = lastSection;

		PlayState.noteskinSprite = CustomNoteHelpers.Skin.generateNoteskinSprite(FlxG.save.data.noteskin);

		FlxG.mouse.visible = true;

		PlayState.inDaPlay = false;

		deezNuts.set(4, 1);
		deezNuts.set(8, 2);
		deezNuts.set(12, 3);
		deezNuts.set(16, 4);
		deezNuts.set(24, 6);
		deezNuts.set(32, 8);
		deezNuts.set(64, 16);

		if (FlxG.save.data.showHelp == null)
			FlxG.save.data.showHelp = true;

		if (FlxG.save.data.playHitsounds == null)
			FlxG.save.data.playHitsounds = false;

		sectionRenderes = new FlxTypedGroup<SectionRender>();
		lines = new FlxTypedGroup<FlxSprite>();
		texts = new FlxTypedGroup<FlxText>();

		TimingStruct.clearTimings();

		if (PlayState.SONG != null)
		{
			_song = PlayState.SONG;
		}
		else
		{
			_song = {
				chartVersion: latestChartVersion,
				songId: 'test',
				song: 'test',
				songName: 'Test',
				audioFile: 'test',
				splitVoiceTracks: false,
				notes: [],
				eventObjects: [],
				bpm: 150,
				needsVoices: true,
				player1: 'bf',
				player2: 'dad',
				gfVersion: 'gf',
				noteStyle: 'normal',
				stage: 'stage',
				speed: 1,
				validScore: true
			};
		}

		player2 = new Character(0, 0, _song.player2);
		player1 = new Boyfriend(0, 0, _song.player1);

		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.scrollFactor.set();
		bg.color = 0xFF0C0C0C;
		add(bg);

		if (_song.chartVersion == null)
			_song.chartVersion = "2";

		// var blackBorder:FlxSprite = new FlxSprite(60,10).makeGraphic(120,100,FlxColor.BLACK);
		// blackBorder.scrollFactor.set();

		// blackBorder.alpha = 0.3;

		snapText = new FlxText(60, 10, 0, "", 14);
		snapText.font = Paths.font("vcr.ttf");
		snapText.scrollFactor.set();

		curRenderedNotes = new FlxTypedGroup<Note>();
		curRenderedSustains = new FlxTypedGroup<FlxSprite>();

		tempBpm = _song.bpm;

		addSection();

		activeSong = _song;

		// sections = _song.notes;

		curDiff = CoolUtil.difficultyArray[PlayState.storyDifficulty];

		loadSong(_song.audioFile, reloadOnInit);
		Conductor.changeBPM(_song.bpm);

		leftIcon = new HealthIcon(player1.healthIcon, player1.iconAnimated, false);
		rightIcon = new HealthIcon(player2.healthIcon, player2.iconAnimated, false);

		Application.current.window.title = '${MainMenuState.kecVer}: In The Chart Editor';

		var index = 0;

		if (_song.eventObjects == null)
			_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "1", "BPM Change")];

		if (_song.eventObjects.length == 0)
			_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "1", "BPM Change")];

		var currentIndex = 0;

		for (i in _song.eventObjects)
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

		var sections = Math.floor(((lengthInSteps + 16)) / 16);

		var targetY = getYfromStrum(inst.length);

		for (awfgaw in 0...Math.round(targetY / 640)) // grids/steps
		{
			var renderer = new SectionRender(0, 640 * awfgaw, GRID_SIZE);
			if (_song.notes[awfgaw] == null)
				_song.notes.push(newSection(16, true, false, false));

			renderer.section = _song.notes[awfgaw];

			sectionRenderes.add(renderer);

			var down = getYfromStrum(renderer.section.startTime) * zoomFactor;

			var sectionicon = _song.notes[awfgaw].mustHitSection ? new HealthIcon(player1.healthIcon,
				player1.iconAnimated).clone() : new HealthIcon(player2.healthIcon, player2.iconAnimated).clone();
			sectionicon.x = -95;
			sectionicon.y = down - 75;
			sectionicon.setGraphicSize(0, 45);

			renderer.icon = sectionicon;
			renderer.lastUpdated = _song.notes[awfgaw].mustHitSection;

			add(sectionicon);
			height = Math.floor(renderer.y);
		}

		addGrid(1);

		gridBlackLine = new FlxSprite(gridBG.width / 2).makeGraphic(4, height, FlxColor.BLACK);
		gridBlackLine.alpha = 0.5;

		// leftIcon.scrollFactor.set();
		// rightIcon.scrollFactor.set();

		leftIcon.setGraphicSize(0, 45);
		rightIcon.setGraphicSize(0, 45);

		add(leftIcon);
		add(rightIcon);

		leftIcon.setPosition(0, -100);
		rightIcon.setPosition(gridBG.width / 2, -100);

		leftIcon.scrollFactor.set();
		rightIcon.scrollFactor.set();

		bpmTxt = new CoolText(985, 25, 16, 16, Paths.bitmapFont('fonts/vcr'));
		bpmTxt.autoSize = true;
		bpmTxt.antialiasing = true;
		bpmTxt.updateHitbox();
		bpmTxt.scrollFactor.set();
		add(bpmTxt);

		notetypetext = new CoolText(825, 650, 28, 28, Paths.bitmapFont('fonts/vcr'));
		notetypetext.autoSize = true;
		notetypetext.antialiasing = true;
		notetypetext.updateHitbox();
		notetypetext.scrollFactor.set();
		add(notetypetext);

		strumLine = new FlxSprite(0, 0).makeGraphic(Std.int(GRID_SIZE * 8), 4);

		dummyArrow = new FlxSprite().makeGraphic(GRID_SIZE, GRID_SIZE);
		dummyArrow.alpha = 0.4;
		var tabs = [
			{name: "Song", label: 'Song Data'},
			{name: "Section", label: 'Section Data'},
			{name: "Note", label: 'Note Data'},
			{name: "Assets", label: 'Assets'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);

		UI_box.scrollFactor.set();
		UI_box.resize(300, 400);
		UI_box.x = FlxG.width / 2 + 40;
		UI_box.y = 20;

		var opt_tabs = [
			{name: "Options", label: 'Charting Options'},
			{name: "Events", label: 'Song Events'}
		];

		UI_options = new FlxUITabMenu(null, opt_tabs, true);

		UI_options.scrollFactor.set();
		UI_options.selected_tab = 0;
		UI_options.resize(300, 200);
		UI_options.x = UI_box.x;
		UI_options.y = FlxG.height - 300;
		add(UI_options);
		add(UI_box);

		addAssetUI();
		addSongUI();
		addSectionUI();
		addNoteUI();
		addOptionsUI();
		addEventsUI();

		if (FlxG.save.data.autoSaving)
			openfl.Lib.setInterval(autosaveSong, 5 * 60 * 1000); // <arubz> * 60 * 1000

		camFollow = new FlxObject(280, 0, 1, 1);
		add(camFollow);

		FlxG.camera.follow(camFollow);

		updateNotetypeText();
		regenerateLines();
		updateGrid();

		add(sectionRenderes);
		add(dummyArrow);
		add(lines);
		add(texts);
		add(gridBlackLine);
		add(strumLine);
		add(curRenderedNotes);
		add(curRenderedSustains);
		selectedBoxes = new FlxTypedGroup();

		add(selectedBoxes);
		// add(blackBorder);
		add(snapText);

		Paths.clearUnusedMemory();
		super.create();
	}

	public var texts:FlxTypedGroup<FlxText>;

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

		if (_song.eventObjects != null)
			for (i in _song.eventObjects)
			{
				var seg = TimingStruct.getTimingAtBeat(i.position);

				var posi:Float = 0;

				if (seg != null)
				{
					var start:Float = (i.position - seg.startBeat) / (seg.bpm / 60);

					posi = seg.startTime + start;
				}

				var pos = getYfromStrum(posi * 1000) * zoomFactor;

				if (pos < 0)
					pos = 0;

				var type = i.type;

				var text = new FlxText(-190, pos, 0, i.name + "\n" + type + "\n" + i.value + "\n" + i.value2, 16);
				text.borderStyle = OUTLINE_FAST;
				text.borderColor = FlxColor.BLACK;
				text.font = Paths.font("vcr.ttf");
				var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLUE);

				line.alpha = 0.2;

				lines.add(line);
				texts.add(text);

				add(line);
				add(text);
			}
		for (i in sectionRenderes)
		{
			var pos = getYfromStrum(i.section.startTime) * zoomFactor;
			i.icon.y = pos - 75;

			var line = new FlxSprite(0, pos).makeGraphic(Std.int(GRID_SIZE * 8), 4, FlxColor.BLACK);
			line.alpha = 0.5;
			lines.add(line);
		}
	}

	function addGrid(?divisions:Float = 1)
	{
		// This here is because non-integer numbers aren't supported as grid sizes, making the grid slowly 'drift' as it goes on
		var h = GRID_SIZE / divisions;
		if (Math.floor(h) != h)
			h = GRID_SIZE;

		remove(gridBG);
		gridBG = new FlxSprite(0, 0).makeGraphic(40 * 8, 40 * 16);

		var totalHeight = 0;

		// add(gridBG);

		remove(gridBlackLine);
		gridBlackLine = new FlxSprite(0 + gridBG.width / 2).makeGraphic(4, Std.int(Math.floor(lengthInSteps)), FlxColor.BLACK);
		gridBlackLine.alpha = 0.5;
		add(gridBlackLine);
	}

	var stepperDiv:FlxUINumericStepper;
	var check_snap:FlxUICheckBox;
	var listOfEvents:FlxUIDropDownMenu;
	var currentSelectedEventName:String = "";
	var savedType:String = "BPM Change";
	var savedValue:String = "100";
	var savedValue2:String = "1";
	var currentEventPosition:Float = 0;

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

	public var chartEvents:Array<Song.Event> = [];

	public var blockTypes:Array<FlxUIInputText> = [];

	private var blockSteppers:Array<FlxUINumericStepper> = [];
	private var blockScroll:Array<FlxUIDropDownMenu> = [];

	function addEventsUI()
	{
		if (_song.eventObjects == null)
		{
			_song.eventObjects = [new Song.Event("Init BPM", 0, _song.bpm, "1", "BPM Change")];
		}

		var firstEvent = "";

		if (Lambda.count(_song.eventObjects) != 0)
		{
			firstEvent = _song.eventObjects[0].name;
		}

		var eventList:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/eventList'));

		var listLabel = new FlxText(10, 5, 'List of Events');
		listLabel.font = Paths.font("vcr.ttf");
		var nameLabel = new FlxText(150, 5, 'Event Name');
		nameLabel.font = Paths.font("vcr.ttf");
		var eventName = new FlxUIInputText(150, 20, 80, "");
		eventName.font = Paths.font("vcr.ttf");
		var typeLabel = new FlxText(10, 45, 'Type of Event');
		typeLabel.font = Paths.font("vcr.ttf");
		var eventType = new FlxUIDropDownMenu(10, 60, FlxUIDropDownMenu.makeStrIdLabelArray(eventList, true));
		blockScroll.push(eventType);
		var valueLabel = new FlxText(150, 45, 'Event Value');
		valueLabel.font = Paths.font("vcr.ttf");

		var value2Label = new FlxText(10, 85, 'Event Value 2');
		value2Label.font = Paths.font("vcr.ttf");

		var eventValue = new FlxUIInputText(150, 60, 80, "");
		eventValue.font = Paths.font("vcr.ttf");

		var eventValue2 = new FlxUIInputText(10, 100, 80, "");
		eventValue2.font = Paths.font("vcr.ttf");

		blockTypes.push(eventName);
		blockTypes.push(eventValue);
		blockTypes.push(eventValue2);

		var eventSave = new FlxUIButton(10, 155, "Save Event", function()
		{
			var pog:Song.Event = new Song.Event(currentSelectedEventName, currentEventPosition, savedValue, savedValue2, savedType);

			var obj = containsName(pog.name, _song.eventObjects);

			if (pog.name == "")
				return;

			if (obj != null)
				_song.eventObjects.remove(obj);
			_song.eventObjects.push(pog);

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in _song.eventObjects)
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
			}

			updateGrid();

			regenerateLines();

			var listofnames = [];

			for (key => value in _song.eventObjects)
			{
				listofnames.push(value.name);
			}

			listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

			listOfEvents.selectedLabel = pog.name;

			autosaveSong();
		});
		var posLabel = new FlxText(150, 85, 'Event Position');
		posLabel.font = Paths.font("vcr.ttf");
		var eventPos = new FlxUIInputText(150, 100, 80, "");
		blockTypes.push(eventPos);
		eventPos.font = Paths.font("vcr.ttf");
		var eventAdd = new FlxUIButton(95, 155, "Add Event", function()
		{
			var pog:Song.Event = new Song.Event("New Event " + HelperFunctions.truncateFloat(curDecimalBeat, 3),
				HelperFunctions.truncateFloat(curDecimalBeat, 3), _song.bpm, "1", "BPM Change");

			var obj = containsName(pog.name, _song.eventObjects);

			if (obj != null)
				return;

			_song.eventObjects.push(pog);

			eventName.text = pog.name;
			eventType.selectedLabel = pog.type;
			eventValue.text = pog.value + "";
			eventValue2.text = pog.value2 + "";
			eventPos.text = pog.position + "";
			currentSelectedEventName = pog.name;
			currentEventPosition = pog.position;

			savedType = pog.type;
			savedValue = pog.value + "";
			savedValue2 = pog.value2 + "";

			var listofnames = [];

			for (key => value in _song.eventObjects)
			{
				listofnames.push(value.name);
			}

			listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

			listOfEvents.selectedLabel = pog.name;

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in _song.eventObjects)
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
		});
		var eventRemove = new FlxUIButton(180, 155, "Remove Event", function()
		{
			var obj = containsName(listOfEvents.selectedLabel, _song.eventObjects);

			if (obj == null)
				return;

			_song.eventObjects.remove(obj);

			var firstEvent = _song.eventObjects[0];

			if (firstEvent == null)
			{
				_song.eventObjects.push(new Song.Event("Init BPM", 0, _song.bpm, "1", "BPM Change"));
				firstEvent = _song.eventObjects[0];
			}

			eventName.text = firstEvent.name;
			eventType.selectedLabel = firstEvent.type;
			eventValue.text = firstEvent.value + "";
			eventValue2.text = firstEvent.value2 + "";
			eventPos.text = firstEvent.position + "";
			currentSelectedEventName = firstEvent.name;
			currentEventPosition = firstEvent.position;

			// savedType = firstEvent.type;
			// savedValue = firstEvent.value + '';
			// savedValue2 = firstEvent.value2 + '';

			var listofnames = [];

			for (key => value in _song.eventObjects)
			{
				listofnames.push(value.name);
			}

			listOfEvents.setData(FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true));

			listOfEvents.selectedLabel = firstEvent.name;

			TimingStruct.clearTimings();

			var currentIndex = 0;
			for (i in _song.eventObjects)
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
			}

			updateGrid();

			regenerateLines();
		});
		var updatePos = new FlxUIButton(150, 120, "Update Pos", function()
		{
			var obj = containsName(currentSelectedEventName, _song.eventObjects);
			if (obj == null)
				return;
			currentEventPosition = curDecimalBeat;
			obj.position = currentEventPosition;
			eventPos.text = currentEventPosition + "";
		});

		var listofnames = [];

		var firstEventObject = null;

		for (event in _song.eventObjects)
		{
			var name = Reflect.field(event, "name");
			var type = Reflect.field(event, "type");
			var pos = Reflect.field(event, "position");
			var value = Reflect.field(event, "value");
			var value2 = Reflect.field(event, "value2");

			var eventt = new Song.Event(name, pos, value, value2, type);

			chartEvents.push(eventt);
			listofnames.push(name);
		}

		_song.eventObjects = chartEvents;

		if (listofnames.length == 0)
			listofnames.push("");

		if (_song.eventObjects.length != 0)
			firstEventObject = _song.eventObjects[0];

		if (firstEvent != "")
		{
			eventName.text = firstEventObject.name;
			eventType.selectedLabel = firstEventObject.type;
			eventValue.text = firstEventObject.value + "";
			eventValue2.text = firstEventObject.value2 + "";
			currentSelectedEventName = firstEventObject.name;
			currentEventPosition = firstEventObject.position;
			eventPos.text = currentEventPosition + "";
		}

		listOfEvents = new FlxUIDropDownMenu(10, 20, FlxUIDropDownMenu.makeStrIdLabelArray(listofnames, true), function(name:String)
		{
			var event = containsName(listOfEvents.selectedLabel, _song.eventObjects);

			if (event == null)
				return;

			savedValue = event.value;
			savedValue2 = event.value2;
			savedType = event.type;

			eventName.text = event.name;
			eventValue.text = savedValue + "";
			eventValue2.text = savedValue2 + "";
			eventPos.text = event.position + "";
			eventType.selectedLabel = savedType;
			currentSelectedEventName = event.name;
			currentEventPosition = event.position;

			Debug.logTrace('Event Type: ${savedType}, Event Value 1: ${savedValue}, Event Value 2: ${savedValue2}.');
		});

		blockScroll.push(listOfEvents);

		eventValue.callback = function(string:String, string2:String)
		{
			savedValue = string;
		};

		eventValue2.callback = function(string:String, string2:String)
		{
			savedValue2 = string;
		};

		eventType.callback = function(type:String)
		{
			savedType = eventType.selectedLabel;
		};

		eventName.callback = function(string:String, string2:String)
		{
			var obj = containsName(currentSelectedEventName, _song.eventObjects);
			if (obj == null)
			{
				currentSelectedEventName = string;
				return;
			}
			obj = containsName(string, _song.eventObjects);
			if (obj != null)
				return;
			obj = containsName(currentSelectedEventName, _song.eventObjects);
			obj.name = string;
			currentSelectedEventName = string;
		};

		blockTypes.push(eventPos);
		blockTypes.push(eventValue);
		blockTypes.push(eventValue2);
		blockTypes.push(eventName);

		var tab_events = new FlxUI(null, UI_options);
		tab_events.name = "Events";
		tab_events.add(posLabel);
		tab_events.add(valueLabel);
		tab_events.add(value2Label);
		tab_events.add(nameLabel);
		tab_events.add(listLabel);
		tab_events.add(typeLabel);
		tab_events.add(eventName);
		tab_events.add(eventValue);
		tab_events.add(eventValue2);
		tab_events.add(eventSave);
		tab_events.add(eventAdd);
		tab_events.add(eventRemove);
		tab_events.add(eventPos);
		tab_events.add(updatePos);
		tab_events.add(eventType);
		tab_events.add(listOfEvents);
		UI_options.addGroup(tab_events);
	}

	var metronome:FlxUICheckBox;
	var hitsoundsVol:FlxUINumericStepper;

	function addOptionsUI()
	{
		var hitsounds = new FlxUICheckBox(10, 20, null, null, "Play hitsounds", 100);
		hitsounds.checked = FlxG.save.data.playHitsounds;
		hitsounds.callback = function()
		{
			FlxG.save.data.playHitsounds = !FlxG.save.data.playHitsounds;
		};

		hitsoundsVol = new FlxUINumericStepper(125, 21, 0.1, 1, 0, 1, 1);
		hitsoundsVol.value = FlxG.save.data.hitVolume;
		hitsoundsVol.name = 'options_vol';

		blockSteppers.push(hitsoundsVol);

		var volLabel = new FlxText(95, 3, 0, 'Hitsound Volume', 14);
		volLabel.font = Paths.font("vcr.ttf");

		metronome = new FlxUICheckBox(10, 50, null, null, "Metronome Enabled", 100, function()
		{
			FlxG.save.data.chart_metronome = metronome.checked;
		});
		if (FlxG.save.data.chart_metronome == null)
			FlxG.save.data.chart_metronome = false;
		metronome.checked = FlxG.save.data.chart_metronome;

		var opponentMode = new FlxUICheckBox(10, 80, null, null, "Opponent Mode", 100);
		opponentMode.checked = FlxG.save.data.opponent;
		opponentMode.callback = function()
		{
			FlxG.save.data.opponent = !FlxG.save.data.opponent;
		}

		var autosaveBool = new FlxUICheckBox(10, 110, null, null, "Auto Saving", 100);
		autosaveBool.checked = FlxG.save.data.autoSaving;
		autosaveBool.callback = function()
		{
			FlxG.save.data.autoSaving = !FlxG.save.data.autoSaving;
		};

		check_snap = new FlxUICheckBox(80, 25, null, null, "Snap to grid", 100);
		check_snap.checked = defaultSnap;
		check_snap.callback = function()
		{
			defaultSnap = check_snap.checked;
		};

		var difficulties:Array<String> = CoolUtil.difficultyArray;
		var diffDrop = new FlxUIDropDownMenu(120, 75, FlxUIDropDownMenu.makeStrIdLabelArray(difficulties, true), function(diff:String)
		{
			if (curDiff != difficulties[Std.parseInt(diff)])
			{
				curDiff = difficulties[Std.parseInt(diff)];
				loadJson(_song.songId, curDiff);
			}
			Debug.logTrace("Selected Difficulty : " + curDiff);
		});
		diffDrop.selectedLabel = curDiff;
		blockScroll.push(diffDrop);

		var diffLabel = new FlxText(100, 50, 0, 'Current Difficulty', 14);
		diffLabel.font = Paths.font("vcr.ttf");

		var tab_options = new FlxUI(null, UI_options);
		tab_options.name = "Options";
		tab_options.add(hitsounds);
		tab_options.add(hitsoundsVol);
		tab_options.add(volLabel);
		tab_options.add(metronome);
		tab_options.add(opponentMode);
		tab_options.add(autosaveBool);
		tab_options.add(diffDrop);
		tab_options.add(diffLabel);
		UI_options.addGroup(tab_options);
	}

	function addAssetUI():Void
	{
		var characters:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/characterList'));
		var gfVersions:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/gfVersionList'));
		var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
		var noteStyles:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/noteStyleList'));

		var player1DropDown = new FlxUIDropDownMenu(10, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player1 = characters[Std.parseInt(character)];
		});
		player1DropDown.selectedLabel = _song.player1;

		var player1Label = new FlxText(10, 80, 0, 'Player 1', 14);
		player1Label.font = Paths.font("vcr.ttf");

		var player2DropDown = new FlxUIDropDownMenu(140, 100, FlxUIDropDownMenu.makeStrIdLabelArray(characters, true), function(character:String)
		{
			_song.player2 = characters[Std.parseInt(character)];
		});
		player2DropDown.selectedLabel = _song.player2;

		var player2Label = new FlxText(140, 80, 0, 'Player 2', 14);
		player2Label.font = Paths.font("vcr.ttf");

		var gfVersionDropDown = new FlxUIDropDownMenu(10, 200, FlxUIDropDownMenu.makeStrIdLabelArray(gfVersions, true), function(gfVersion:String)
		{
			_song.gfVersion = gfVersions[Std.parseInt(gfVersion)];
		});
		gfVersionDropDown.selectedLabel = _song.gfVersion;

		var gfVersionLabel = new FlxText(10, 180, 0, 'Girlfriend', 14);
		gfVersionLabel.font = Paths.font("vcr.ttf");

		var stageDropDown = new FlxUIDropDownMenu(140, 200, FlxUIDropDownMenu.makeStrIdLabelArray(stages, true), function(stage:String)
		{
			_song.stage = stages[Std.parseInt(stage)];
		});
		stageDropDown.selectedLabel = _song.stage;

		var stageLabel = new FlxText(140, 180, 64, 'Stage', 14);
		stageLabel.font = Paths.font("vcr.ttf");

		var noteStyleDropDown = new FlxUIDropDownMenu(10, 300, FlxUIDropDownMenu.makeStrIdLabelArray(noteStyles, true), function(noteStyle:String)
		{
			_song.noteStyle = noteStyles[Std.parseInt(noteStyle)];
		});

		noteStyleDropDown.selectedLabel = _song.noteStyle;

		var noteStyleLabel = new FlxText(10, 280, 0, 'Note Skin', 14);
		noteStyleLabel.font = Paths.font("vcr.ttf");

		blockScroll.push(player1DropDown);
		blockScroll.push(player2DropDown);
		blockScroll.push(gfVersionDropDown);
		blockScroll.push(stageDropDown);
		blockScroll.push(noteStyleDropDown);

		var tab_group_assets = new FlxUI(null, UI_box);
		tab_group_assets.name = "Assets";
		tab_group_assets.add(noteStyleDropDown);
		tab_group_assets.add(noteStyleLabel);
		tab_group_assets.add(gfVersionDropDown);
		tab_group_assets.add(gfVersionLabel);
		tab_group_assets.add(stageDropDown);
		tab_group_assets.add(stageLabel);
		tab_group_assets.add(player1DropDown);
		tab_group_assets.add(player2DropDown);
		tab_group_assets.add(player1Label);
		tab_group_assets.add(player2Label);

		UI_box.addGroup(tab_group_assets);
	}

	function addSongUI():Void
	{
		var UI_songTitle = new FlxUIInputText(10, 10, 70, _song.songId, 8);
		typingShit = UI_songTitle;

		var UI_audioFile = new FlxUIInputText(10, 200, 70, _song.audioFile, 8);
		typingShit2 = UI_audioFile;
		var audioLabel:FlxText = new FlxText(85, 200, 0, "Audio Track", 12);
		audioLabel.font = Paths.font('vcr.ttf');

		var check_voices = new FlxUICheckBox(10, 25, null, null, "Has voice track", 100);
		check_voices.checked = _song.needsVoices;
		// _song.needsVoices = check_voices.checked;
		check_voices.callback = function()
		{
			_song.needsVoices = check_voices.checked;
		};

		var check_split = new FlxUICheckBox(10, 40, null, null, "Split Voice Track", 100);
		check_split.checked = _song.splitVoiceTracks;
		// _song.needsVoices = check_voices.checked;
		check_split.callback = function()
		{
			_song.splitVoiceTracks = check_split.checked;
		};

		var saveButton:FlxUIButton = new FlxUIButton(110, 8, "Save", function()
		{
			saveLevel();
		});

		var reloadSong:FlxUIButton = new FlxUIButton(saveButton.x + saveButton.width + 10, saveButton.y, "Reload Audio", function()
		{
			if (inst.playing)
			{
				inst.stop();
				if (!_song.splitVoiceTracks)
					vocals.stop();
				else
				{
					vocalsPlayer.stop();
					vocalsEnemy.stop();
				}
			}
			loadSong(_song.audioFile.toLowerCase(), false);
			// goofy song overlapping and raping your ears
		});

		var reloadSongJson:FlxUIButton = new FlxUIButton(reloadSong.x, saveButton.y + 30, "Reload JSON", function()
		{
			loadJson(_song.songId.toLowerCase(), curDiff);
		});

		var restart = new FlxUIButton(10, 170, "Reset Chart", function()
		{
			for (ii in 0..._song.notes.length)
			{
				for (i in 0..._song.notes[ii].sectionNotes.length)
				{
					_song.notes[ii].sectionNotes = [];
				}
			}
			resetSection(true);
		});

		var loadAutosaveBtn:FlxUIButton = new FlxUIButton(reloadSongJson.x, reloadSongJson.y + 30, 'Load AutoSave', loadAutosave);
		var stepperBPM:FlxUINumericStepper = new FlxUINumericStepper(10, 65, 0.1, 100, 1.0, 666, 1); // cap the bpm
		stepperBPM.value = Conductor.bpm;
		stepperBPM.name = 'song_bpm';
		blockSteppers.push(stepperBPM);

		var stepperBPMLabel = new FlxText(74, 65, 0, 'BPM', 11);
		stepperBPMLabel.font = Paths.font("vcr.ttf");

		var stepperSpeed:FlxUINumericStepper = new FlxUINumericStepper(10, 80, 0.1, 1, 0, 10, 1);
		stepperSpeed.value = _song.speed;
		stepperSpeed.name = 'song_speed';
		blockSteppers.push(stepperSpeed);

		var stepperSpeedLabel = new FlxText(74, 80, 0, 'Scroll Speed', 11);
		stepperSpeedLabel.font = Paths.font("vcr.ttf");

		var stepperVocalVol:FlxUINumericStepper = new FlxUINumericStepper(10, 95, 0.1, 1, 0, 10, 1);
		if (!_song.splitVoiceTracks)
		{
			stepperVocalVol.value = vocals.volume;
		}
		else
		{
			stepperVocalVol.value = vocalsPlayer.volume;
		}
		stepperVocalVol.name = 'song_vocalvol';
		blockSteppers.push(stepperVocalVol);

		var stepperPlayerVol:FlxUINumericStepper = new FlxUINumericStepper(10, 125, 0.1, 1, 0, 10, 1);
		if (!_song.splitVoiceTracks)
		{
			stepperPlayerVol.value = vocals.volume;
		}
		else
		{
			stepperPlayerVol.value = vocalsPlayer.volume;
		}
		stepperPlayerVol.name = 'song_playervol';
		blockSteppers.push(stepperPlayerVol);

		var stepperEnemyVol:FlxUINumericStepper = new FlxUINumericStepper(10, 140, 0.1, 1, 0, 10, 1);
		if (!_song.splitVoiceTracks)
		{
			stepperEnemyVol.value = vocals.volume;
		}
		else
		{
			stepperEnemyVol.value = vocalsEnemy.volume;
		}
		stepperEnemyVol.name = 'song_enemyvol';
		blockSteppers.push(stepperEnemyVol);

		var stepperVocalVolLabel = new FlxText(74, 95, 0, "Vocal Volume", 12);
		stepperVocalVolLabel.font = Paths.font("vcr.ttf");

		var stepperPlayerVolLabel = new FlxText(74, 125, 0, "Player Vocal Volume", 12);
		stepperPlayerVolLabel.font = Paths.font("vcr.ttf");

		var stepperEnemyVolLabel = new FlxText(74, 140, 0, "Enemy Vocal Volume", 12);
		stepperEnemyVolLabel.font = Paths.font("vcr.ttf");

		var stepperSongVol:FlxUINumericStepper = new FlxUINumericStepper(10, 110, 0.1, 1, 0, 10, 1);
		stepperSongVol.value = inst.volume;
		stepperSongVol.name = 'song_instvol';
		blockSteppers.push(stepperSongVol);

		var stepperSongVolLabel = new FlxText(74, 110, 0, 'Instrumental Volume', 12);
		stepperSongVolLabel.font = Paths.font("vcr.ttf");

		var shiftNoteDialLabel = new FlxText(10, 245, 0, 'Shift All Notes by # Sections', 12);
		shiftNoteDialLabel.font = Paths.font("vcr.ttf");
		var stepperShiftNoteDial:FlxUINumericStepper = new FlxUINumericStepper(10, 260, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDial.name = 'song_shiftnote';
		var shiftNoteDialLabel2 = new FlxText(10, 275, 0, 'Shift All Notes by # Steps', 12);
		shiftNoteDialLabel2.font = Paths.font("vcr.ttf");
		var stepperShiftNoteDialstep:FlxUINumericStepper = new FlxUINumericStepper(10, 290, 1, 0, -1000, 1000, 0);
		stepperShiftNoteDialstep.name = 'song_shiftnotems';
		var shiftNoteDialLabel3 = new FlxText(10, 305, 0, 'Shift All Notes by # ms', 12);
		shiftNoteDialLabel3.font = Paths.font("vcr.ttf");
		var stepperShiftNoteDialms:FlxUINumericStepper = new FlxUINumericStepper(10, 320, 1, 0, -1000, 1000, 2);
		stepperShiftNoteDialms.name = 'song_shiftnotems';

		blockSteppers.push(stepperSongVol);
		blockSteppers.push(stepperShiftNoteDial);
		blockSteppers.push(stepperShiftNoteDialms);
		blockSteppers.push(stepperShiftNoteDialstep);

		var shiftNoteButton:FlxUIButton = new FlxUIButton(10, 335, "Shift", function()
		{
			shiftNotes(Std.int(stepperShiftNoteDial.value), Std.int(stepperShiftNoteDialstep.value), Std.int(stepperShiftNoteDialms.value));
		});

		blockTypes.push(UI_songTitle);
		blockTypes.push(UI_audioFile);
		// sfjl

		var tab_group_song = new FlxUI(null, UI_box);
		tab_group_song.name = "Song";
		tab_group_song.add(UI_songTitle);
		tab_group_song.add(UI_audioFile);
		tab_group_song.add(restart);
		tab_group_song.add(check_voices);
		tab_group_song.add(check_split);
		// tab_group_song.add(check_mute_inst);
		tab_group_song.add(saveButton);
		tab_group_song.add(reloadSong);
		tab_group_song.add(reloadSongJson);
		tab_group_song.add(loadAutosaveBtn);
		tab_group_song.add(stepperBPM);
		tab_group_song.add(stepperBPMLabel);
		tab_group_song.add(stepperSpeed);
		tab_group_song.add(stepperSpeedLabel);
		tab_group_song.add(stepperVocalVol);
		tab_group_song.add(stepperVocalVolLabel);

		tab_group_song.add(stepperPlayerVol);
		tab_group_song.add(stepperPlayerVolLabel);

		tab_group_song.add(stepperEnemyVol);
		tab_group_song.add(stepperEnemyVolLabel);

		tab_group_song.add(stepperSongVol);
		tab_group_song.add(stepperSongVolLabel);
		tab_group_song.add(shiftNoteDialLabel);
		tab_group_song.add(stepperShiftNoteDial);
		tab_group_song.add(shiftNoteDialLabel2);
		tab_group_song.add(stepperShiftNoteDialstep);
		tab_group_song.add(shiftNoteDialLabel3);
		tab_group_song.add(stepperShiftNoteDialms);
		tab_group_song.add(shiftNoteButton);
		tab_group_song.add(audioLabel);
		// tab_group_song.add(hitsounds);

		UI_box.addGroup(tab_group_song);
	}

	override function sectionHit()
	{
		curSection + 1;
	}

	var stepperLength:FlxUINumericStepper;
	var check_mustHitSection:FlxUICheckBox;
	var check_changeBPM:FlxUICheckBox;
	var stepperSectionBPM:FlxUINumericStepper;
	var check_CPUAltAnim:FlxUICheckBox;
	var check_playerAltAnim:FlxUICheckBox;

	var notesCopied:Array<Dynamic>;

	function addSectionUI():Void
	{
		var tab_group_section = new FlxUI(null, UI_box);
		tab_group_section.name = 'Section';

		var copyButton:FlxUIButton = new FlxUIButton(10, 130, "Copy Section", function()
		{
			copiedNotes = [];
			sectionToCopy = curSection;
			var secit = _song.notes[curSection];
			for (i in 0...secit.sectionNotes.length)
			{
				var note:Array<Dynamic> = secit.sectionNotes[i];
				copiedNotes.push(note);
			}

			/*
				for (fuck in 0...sec.sectionNotes.length)
				{
					var note:Array<Dynamic> = sec.sectionNotes[fuck];
					copiedNotes.push(note);
				}
			 */
		});

		var pasteButton:FlxUIButton = new FlxUIButton(100, 130, "Paste Section", function()
		{
			while (selectedBoxes.members.length != 0)
			{
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
				selectedBoxes.clear();
			}

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
				if (note[4] != null)
					copiedNote = [newStrumTime, note[1], note[2], note[3], note[4]];
				else
					copiedNote = [newStrumTime, note[1], note[2], note[3]];
				_song.notes[curSection].sectionNotes.push(copiedNote);
			}
			updateGrid();
		});

		var clearSectionButton:FlxUIButton = new FlxUIButton(10, 150, "Clear Section", clearSection);

		var swapSection:FlxUIButton = new FlxUIButton(10, 170, "Swap Section", function()
		{
			var secit = _song.notes[curSection];

			if (secit != null)
			{
				var secit = _song.notes[curSection];

				if (secit != null)
				{
					swapSection(secit);
				}
			}
		});
		check_mustHitSection = new FlxUICheckBox(10, 30, null, null, "Camera Points to Player?", 100, null, function()
		{
			var sect = lastUpdatedSection;

			if (sect == null)
				return;

			sect.mustHitSection = check_mustHitSection.checked;
			updateHeads();

			for (i in sectionRenderes)
			{
				if (i.section.startTime == sect.startTime)
				{
					var cachedY = i.icon.y;
					remove(i.icon);
					var sectionicon = check_mustHitSection.checked ? new HealthIcon(player1.healthIcon,
						player1.iconAnimated).clone() : new HealthIcon(player2.healthIcon, player2.iconAnimated).clone();
					sectionicon.x = -95;
					sectionicon.y = cachedY;
					sectionicon.setGraphicSize(0, 45);

					i.icon = sectionicon;
					i.lastUpdated = sect.mustHitSection;

					add(sectionicon);
				}
			}
		});
		check_mustHitSection.checked = true;
		// _song.needsVoices = check_mustHit.checked;

		check_CPUAltAnim = new FlxUICheckBox(10, 340, null, null, "CPU Alternate Animation", 100);
		check_CPUAltAnim.name = 'check_CPUAltAnim';

		check_playerAltAnim = new FlxUICheckBox(180, 340, null, null, "Player Alternate Animation", 100);
		check_playerAltAnim.name = 'check_playerAltAnim';

		var refresh = new FlxUIButton(10, 60, 'Refresh Section', function()
		{
			var section = getSectionByTime(Conductor.songPosition);

			if (section == null)
				return;

			check_mustHitSection.checked = section.mustHitSection;
			check_CPUAltAnim.checked = section.CPUAltAnim;
			check_playerAltAnim.checked = section.playerAltAnim;

			updateGrid();
			updateNoteUI();
		});

		var startSection:FlxUIButton = new FlxUIButton(10, 85, "Play Here", function()
		{
			PlayState.SONG = _song;
			inst.stop();
			if (!_song.splitVoiceTracks)
				vocals.stop();
			else
			{
				vocalsPlayer.stop();
				vocalsEnemy.stop();
			}
			PlayState.startTime = _song.notes[curSection].startTime;
			for (i in _song.notes)
			{
				if (i.startTime > inst.length)
					_song.notes.remove(i);
			}
			Main.dumpCache();
			LoadingState.loadAndSwitchState(new PlayState());
			clean();
		});

		var duetButton:FlxUIButton = new FlxUIButton(10, copyButton.y + 95, "Duet Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSection].sectionNotes)
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
				_song.notes[curSection].sectionNotes.push(i);
			}

			updateGrid();
		});

		var mirrorButton:FlxUIButton = new FlxUIButton(duetButton.x + 100, duetButton.y, "Mirror Notes", function()
		{
			var duetNotes:Array<Array<Dynamic>> = [];
			for (note in _song.notes[curSection].sectionNotes)
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
				// _song.notes[curSec].sectionNotes.push(i);
			}

			while (selectedBoxes.members.length != 0)
			{
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
				selectedBoxes.clear();
			}

			updateGrid();
		});

		var randomizeNotes:FlxUIButton = new FlxUIButton(mirrorButton.x + 100, mirrorButton.y, "Randomize Notes", function()
		{
			for (i in _song.notes)
			{
				for (e in i.sectionNotes)
				{
					if (e[1] >= 4 && e[1] <= 7)
					{
						e[1] = FlxG.random.int(4, 7);
					}
					else
					{
						e[1] = FlxG.random.int(0, 3);
					}
				}
			}
			updateGrid();
			updateNoteUI();
		});

		tab_group_section.add(refresh);
		tab_group_section.add(startSection);
		// tab_group_section.add(stepperCopy);
		// tab_group_section.add(stepperCopyLabel);
		tab_group_section.add(check_mustHitSection);
		tab_group_section.add(check_CPUAltAnim);
		tab_group_section.add(check_playerAltAnim);
		tab_group_section.add(copyButton);
		tab_group_section.add(pasteButton);
		tab_group_section.add(clearSectionButton);
		tab_group_section.add(swapSection);
		tab_group_section.add(duetButton);
		tab_group_section.add(mirrorButton);
		tab_group_section.add(randomizeNotes);

		UI_box.addGroup(tab_group_section);
	}

	var stepperSusLength:FlxUINumericStepper;

	var tab_group_note:FlxUI;

	function goToSection(section:Int)
	{
		var beat = section * 4;
		var data = TimingStruct.getTimingAtTimestamp(beat);

		if (data == null)
			return;

		inst.time = (data.startTime + ((beat - data.startBeat) / (data.bpm / 60))) * 1000;
		if (!_song.splitVoiceTracks)
			vocals.time = inst.time;
		else
		{
			vocalsPlayer.time = inst.time;
			vocalsEnemy.time = inst.time;
		}
		curSection = section;
		if (inst.time < 0)
			inst.time = 0;
		else if (inst.time > inst.length)
			inst.time = inst.length;
	}

	public var check_naltAnim:FlxUICheckBox;

	var strumTimeInputText:FlxUIInputText;

	function addNoteUI():Void
	{
		tab_group_note = new FlxUI(null, UI_box);
		tab_group_note.name = 'Note';

		writingNotesText = new FlxUIText(20, 100, 0, "");
		writingNotesText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		stepperSusLength = new FlxUINumericStepper(10, 10, Conductor.stepCrochet / 2, 0, 0, Conductor.stepCrochet * 16 * 4);
		stepperSusLength.value = 0;
		stepperSusLength.name = 'note_susLength';
		blockSteppers.push(stepperSusLength);

		check_naltAnim = new FlxUICheckBox(10, 150, null, null, "Toggle Alternative Animation", 100);
		check_naltAnim.callback = function()
		{
			if (curSelectedNote != null)
			{
				for (i in selectedBoxes)
				{
					i.connectedNoteData[3] = check_naltAnim.checked;

					for (ii in _song.notes)
					{
						for (n in ii.sectionNotes)
							if (n[0] == i.connectedNoteData[0] && n[1] == i.connectedNoteData[1])
								n[3] = i.connectedNoteData[3];
					}
				}
			}
		}

		strumTimeInputText = new FlxUIInputText(10, 65, 180, "0");
		blockTypes.push(strumTimeInputText);

		var stepperSusLengthLabel = new FlxText(74, 10, 'Note Sustain Length');
		stepperSusLengthLabel.font = Paths.font("vcr.ttf");

		var applyLength:FlxUIButton = new FlxUIButton(10, 100, 'Apply Data');

		tab_group_note.add(new FlxText(10, 50, 0, 'Strum time (in miliseconds):'));
		tab_group_note.add(stepperSusLength);
		tab_group_note.add(strumTimeInputText);
		tab_group_note.add(stepperSusLengthLabel);
		tab_group_note.add(check_naltAnim);

		UI_box.addGroup(tab_group_note);

		/*player2 = new Character(0,0, _song.player2);
			player1 = new Boyfriend(player2.width * 0.2,0 + player2.height, _song.player1);

			player1.y = player1.y - player1.height;

			player2.setGraphicSize(Std.int(player2.width * 0.2));
			player1.setGraphicSize(Std.int(player1.width * 0.2));

			UI_box.add(player1);
			UI_box.add(player2); */
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
				for (ii in _song.notes)
				{
					if (ii.startTime <= strum && ii.endTime > strum)
					{
						// alright we're in this section lets paste the note here.
						var newData = [strum, i[1], i[2], i[3], i[4], i[5]];
						ii.sectionNotes.push(newData);

						var thing = ii.sectionNotes[ii.sectionNotes.length - 1];

						var note:Note = new Note(strum, Math.floor(i[1] % 4), null, false, true, true, i[3], i[4], i[5]);
						note.rawNoteData = i[1];
						note.sustainLength = i[2];
						note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
						note.updateHitbox();
						note.x = Math.floor(i[1] * GRID_SIZE);

						note.charterSelected = true;

						note.y = Math.floor(getYfromStrum(strum) * zoomFactor);

						var box = new ChartingBox(note.x, note.y, note);
						box.connectedNoteData = thing;
						selectedBoxes.add(box);

						curRenderedNotes.add(note);

						pastedNotes.push(note);

						if (note.sustainLength > 0)
						{
							var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 2,
								note.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y));

							note.noteCharterObject = sustainVis;

							curRenderedSustains.add(sustainVis);
						}
						continue;
					}
					section++;
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
			for (ii in _song.notes)
			{
				if (ii.startTime <= strum && ii.endTime > strum)
				{
					// alright we're in this section lets paste the note here.
					var newData:Array<Dynamic> = [
						strum,
						originalNote.rawNoteData,
						originalNote.sustainLength,
						originalNote.isAlt,
						originalNote.beat,
						originalNote.noteShit
					];
					ii.sectionNotes.push(newData);

					var thing = ii.sectionNotes[ii.sectionNotes.length - 1];

					var note:Note = new Note(strum, originalNote.noteData, originalNote.prevNote, false, true, true, originalNote.isAlt, originalNote.beat,
						originalNote.noteShit);
					note.rawNoteData = originalNote.rawNoteData;
					note.sustainLength = originalNote.sustainLength;
					note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
					note.updateHitbox();
					note.x = Math.floor(originalNote.rawNoteData * GRID_SIZE);
					note.y = Math.floor(getYfromStrum(strum) * zoomFactor);

					var box = new ChartingBox(note.x, note.y, note);
					box.connectedNoteData = thing;
					// Add to selection after the fact to avoid tomfuckery.
					toAdd.push(box);

					curRenderedNotes.add(note);

					pastedNotes.push(note);

					if (note.sustainLength > 0)
					{
						var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 2,
							note.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y));

						note.noteCharterObject = sustainVis;

						curRenderedSustains.add(sustainVis);
					}

					selectNote(note);
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

		updateNoteUI();

		updateGrid();

		// ok so basically theres a bug with color quant that it doesn't update the color until the grid updates.
		// when the grid updates, it causes a massive performance drop everytime we offset the notes. :/
		// actually its broken either way because theres a ghost note after offsetting sometimes. updateGrid anyway.
		// now sustains don't get shifted. I don't know.
	}

	function loadSong(daSong:String, reloadFromFile:Bool = false):Void
	{
		inst = new FlxSound().loadEmbedded(Paths.inst(_song.audioFile));
		if (inst != null)
		{
			inst.stop();
		}
		if (reloadFromFile)
		{
			var diff:String = CoolUtil.getSuffixFromDiff(curDiff);
			_song = Song.conversionChecks(Song.loadFromJson(PlayState.SONG.songId, diff));
		}
		else
		{
			_song = PlayState.SONG;
		}
		// WONT WORK FOR TUTORIAL OR TEST SONG!!! REDO LATER
		if (!_song.splitVoiceTracks)
		{
			if (_song.needsVoices)
				vocals = new FlxSound().loadEmbedded(Paths.voices(_song.audioFile));
			else
				vocals = new FlxSound();
			FlxG.sound.list.add(vocals);
		}
		else
		{
			if (_song.needsVoices)
			{
				vocalsPlayer = new FlxSound().loadEmbedded(Paths.voices(_song.audioFile, 'P'));
				vocalsEnemy = new FlxSound().loadEmbedded(Paths.voices(_song.audioFile, 'E'));
			}
			else
			{
				vocalsPlayer = new FlxSound();
				vocalsEnemy = new FlxSound();
			}
			FlxG.sound.list.add(vocalsPlayer);
			FlxG.sound.list.add(vocalsEnemy);
		}

		FlxG.sound.list.add(inst);

		inst.play();
		inst.pause();
		if (!_song.splitVoiceTracks)
		{
			vocals.play();
			vocals.pause();
		}
		else
		{
			vocalsPlayer.play();
			vocalsEnemy.play();
			vocalsPlayer.pause();
			vocalsEnemy.pause();
		}

		inst.onComplete = function()
		{
			if (!_song.splitVoiceTracks)
			{
				vocals.pause();
				vocals.time = 0;
			}
			else
			{
				vocalsPlayer.pause();
				vocalsPlayer.time = 0;
				vocalsEnemy.pause();
				vocalsEnemy.time = 0;
			}
			inst.pause();
			inst.time = 0;
		};
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>)
	{
		if (id == FlxUICheckBox.CLICK_EVENT)
		{
			var check:FlxUICheckBox = cast sender;
			var label = check.getLabel().text;
			switch (label)
			{
				case "CPU Alternate Animation":
					getSectionByTime(Conductor.songPosition).CPUAltAnim = check.checked;
				case "Player Alternate Animation":
					getSectionByTime(Conductor.songPosition).playerAltAnim = check.checked;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			var nums:FlxUINumericStepper = cast sender;
			var wname = nums.name;
			FlxG.log.add(wname);

			switch (wname)
			{
				case 'section_length':
					if (nums.value <= 4)
						nums.value = 4;
					getSectionByTime(Conductor.songPosition).lengthInSteps = Std.int(nums.value);
					updateGrid();

				case 'song_speed':
					if (nums.value <= 0)
						nums.value = 0;
					_song.speed = nums.value;

				case 'song_bpm':
					if (nums.value <= 0)
						nums.value = 1;
					_song.bpm = nums.value;

					if (_song.eventObjects[0].type != "BPM Change")
						Application.current.window.alert("i'm crying, first event isn't a bpm change. fuck you");
					else
					{
						_song.eventObjects[0].value = nums.value;
						regenerateLines();
					}

					TimingStruct.clearTimings();

					var currentIndex = 0;
					for (i in _song.eventObjects)
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

					updateGrid();

				// poggers();

				case 'note_susLength':
					if (curSelectedNote == null)
						return;

					if (nums.value <= 0)
						nums.value = 0;
					curSelectedNote[2] = nums.value;
					updateGrid();

				case 'song_vocalvol':
					if (!_song.splitVoiceTracks)
						vocals.volume = nums.value;
					else
					{
						vocalsPlayer.volume = nums.value;
						vocalsEnemy.volume = nums.value;
					}
				case 'song_playervol':
					if (!_song.splitVoiceTracks)
						vocals.volume = nums.value;
					else
					{
						vocalsPlayer.volume = nums.value;
					}

				case 'song_enemyvol':
					if (!_song.splitVoiceTracks)
						vocals.volume = nums.value;
					else
					{
						vocalsEnemy.volume = nums.value;
					}

				case 'song_instvol':
					inst.volume = nums.value;
				case 'options_vol':
					if (nums.value <= 0.1)
						nums.value = 0.1;
					hitsoundsVol.value = nums.value;

				case 'divisions':
					subDivisions = nums.value;
					updateGrid();
			}
		}
		else if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (curSelectedNote != null)
			{
				if (sender == strumTimeInputText)
				{
					var value:Float = Std.parseFloat(strumTimeInputText.text);
					if (Math.isNaN(value))
						value = 0;
					curSelectedNote[0] = value;
					updateGrid();
				}
			}
		}

		// FlxG.log.add(id + " WEED " + sender + " WEED " + data + " WEED " + params);
	}

	var updatedSection:Bool = false;

	/* this function got owned LOL
		function lengthBpmBullshit():Float
		{
			if (getSectionByTime(Conductor.songPosition).changeBPM)
				return getSectionByTime(Conductor.songPosition).lengthInSteps * (getSectionByTime(Conductor.songPosition).bpm / _song.bpm);
			else
				return getSectionByTime(Conductor.songPosition).lengthInSteps;
	}*/
	function poggers()
	{
		var notes = [];

		for (section in _song.notes)
		{
			var removed = [];

			for (note in section.sectionNotes)
			{
				// commit suicide
				var old = [note[0], note[1], note[2], note[3], note[4]];
				old[0] = TimingStruct.getTimeFromBeat(old[4]);
				old[2] = TimingStruct.getTimeFromBeat(TimingStruct.getBeatFromTime(old[0]));
				if (old[0] < section.startTime && old[0] < section.endTime)
				{
					notes.push(old);
					removed.push(note);
				}
				if (old[0] > section.endTime && old[0] > section.startTime)
				{
					notes.push(old);
					removed.push(note);
				}
			}

			for (i in removed)
			{
				section.sectionNotes.remove(i);
			}
		}

		for (section in _song.notes)
		{
			var saveRemove = [];

			for (i in notes)
			{
				if (i[0] >= section.startTime && i[0] <= section.endTime)
				{
					saveRemove.push(i);
					section.sectionNotes.push(i);
				}
			}

			for (i in saveRemove)
				notes.remove(i);
		}

		for (i in curRenderedNotes)
		{
			i.strumTime = TimingStruct.getTimeFromBeat(i.beat);
			i.y = Math.floor(getYfromStrum(i.strumTime) * zoomFactor);
			i.sustainLength = TimingStruct.getTimeFromBeat(TimingStruct.getBeatFromTime(i.sustainLength));
			if (i.noteCharterObject != null)
			{
				i.noteCharterObject.y = i.y + 40;
				i.noteCharterObject.makeGraphic(8, Math.floor((getYfromStrum(i.strumTime + i.sustainLength) * zoomFactor) - i.y), FlxColor.WHITE);
			}
		}
	}

	function stepStartTime(step):Float
	{
		return Conductor.bpm / (step / 4) / 60;
	}

	function sectionStartTime(?customIndex:Int = -1):Float
	{
		if (customIndex == -1)
			customIndex = curSection;
		var daBPM:Float = Conductor.bpm;
		var daPos:Float = 0;
		for (i in 0...customIndex)
		{
			daPos += 4 * (1000 * 60 / daBPM);
		}
		return daPos;
	}

	var writingNotes:Bool = false;
	var doSnapShit:Bool = false;

	function swapSection(secit:SwagSection)
	{
		for (i in 0...secit.sectionNotes.length)
		{
			var note:Array<Dynamic> = secit.sectionNotes[i];
			note[1] = (note[1] + 4) % 8;
			secit.sectionNotes[i] = note;
		}

		updateGrid();
	}

	public var diff:Float = 0;

	public var changeIndex = 0;

	public var currentBPM:Float = 0;
	public var lastBPM:Float = 0;

	public var updateFrame = 0;
	public var lastUpdatedSection:SwagSection = null;

	public function resizeEverything()
	{
		regenerateLines();

		for (i in curRenderedNotes.members)
		{
			if (i == null)
				continue;
			i.y = getYfromStrum(i.strumTime) * zoomFactor;
			if (i.noteCharterObject != null)
			{
				curRenderedSustains.remove(i.noteCharterObject);
				var sustainVis:FlxSprite = new FlxSprite(i.x + (GRID_SIZE * 0.5) - 2,
					i.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(i.strumTime + i.sustainLength) * zoomFactor) - i.y), FlxColor.WHITE);

				i.noteCharterObject = sustainVis;
				curRenderedSustains.add(i.noteCharterObject);
			}
		}
	}

	public var shownNotes:Array<Note> = [];

	public var snapSelection = 3;

	public var selectedBoxes:FlxTypedGroup<ChartingBox>;

	public var waitingForRelease:Bool = false;
	public var selectBox:FlxSprite;

	public var copiedNotes:Array<Array<Dynamic>> = [];
	public var pastedNotes:Array<Note> = [];
	public var deletedNotes:Array<Array<Dynamic>> = [];

	public var selectInitialX:Float = 0;
	public var selectInitialY:Float = 0;

	public var lastAction:String = "";

	var lastConductorPos:Float;

	override function update(elapsed:Float)
	{
		try
		{
			if (inst != null)
				if (inst.time > inst.length - 85)
				{
					inst.pause();
					inst.time = inst.length - 85;
					if (!_song.splitVoiceTracks)
					{
						vocals.pause();
						vocals.time = vocals.length - 85;
					}
					else
					{
						vocalsPlayer.pause();
						vocalsPlayer.time = vocalsPlayer.length - 85;
						vocalsEnemy.pause();
						vocalsEnemy.time = vocalsEnemy.length - 85;
					}
				}

			#if debug
			FlxG.watch.addQuick("Renderers", sectionRenderes.length);
			FlxG.watch.addQuick("Notes", curRenderedNotes.length);
			FlxG.watch.addQuick("Rendered Notes ", shownNotes.length);
			#end

			if (inst != null)
			{
				if (inst.playing)
				{
					inst.pitch = speed;
					try
					{
						// We need to make CERTAIN vocals exist and are non-empty
						// before we try to play them. Otherwise the game crashes.
						if (!_song.splitVoiceTracks)
						{
							if (vocals != null && vocals.length > 0)
							{
								vocals.pitch = speed;
							}
						}
						else
						{
							if (vocalsPlayer != null && vocalsPlayer.length > 0)
							{
								vocalsPlayer.pitch = speed;
							}

							if (vocalsEnemy != null && vocalsEnemy.length > 0)
							{
								vocalsEnemy.pitch = speed;
							}
						}
					}
					catch (e)
					{
						Debug.logTrace("failed to pitch vocals (probably cuz they don't exist)");
					}
				}
			}

			for (i in sectionRenderes)
			{
				var diff = i.y - strumLine.y;
				if (diff < 2200 && diff >= -2200)
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

			shownNotes = [];

			for (note in curRenderedNotes)
			{
				var diff = note.strumTime - Conductor.songPosition;
				if (diff < 1675 && diff >= -3500) // Cutting it really close with rendered notes
				{
					shownNotes.push(note);
					if (note.sustainLength > 0)
					{
						note.noteCharterObject.active = true;
						note.noteCharterObject.visible = true;
					}
					note.active = true;
					note.visible = true;
				}
				else
				{
					note.active = false;
					note.visible = false;
					if (note.sustainLength > 0)
					{
						if (note.noteCharterObject != null)
							if (note.noteCharterObject.y != note.y)
							{
								note.noteCharterObject.active = false;
								note.noteCharterObject.visible = false;
							}
					}
				}
			}

			/*
				note culling code above
			 */

			for (ii in selectedBoxes.members)
			{
				ii.x = ii.connectedNote.x;
				ii.y = ii.connectedNote.y;
			}

			var doInput = true;

			for (inputText in blockTypes)
			{
				if (inputText.hasFocus)
				{
					doInput = false;
					break;
				}
			}

			if (doInput)
			{
				for (stepper in blockSteppers)
				{
					@:privateAccess
					var leText:FlxUIInputText = cast(stepper.text_field, FlxUIInputText);
					if (leText.hasFocus)
					{
						doInput = false;
						break;
					}
				}
			}

			if (doInput)
			{
				for (dropDownMenu in blockScroll)
				{
					if (dropDownMenu.dropPanel.visible)
					{
						doInput = false;
						break;
					}
				}
			}

			if (doInput)
			{
				if (FlxG.mouse.wheel != 0)
				{
					if (inst.playing)
					{
						inst.pause();

						if (!_song.splitVoiceTracks)
							vocals.pause();
						else
						{
							vocalsPlayer.pause();
							vocalsEnemy.pause();
						}
					}

					if (FlxG.keys.pressed.CONTROL && !waitingForRelease)
					{
						var amount = FlxG.mouse.wheel;

						if (amount > 0)
							amount = 0;

						var increase:Float = 0;

						if (amount < 0)
							increase = -0.02;
						else
							increase = 0.02;

						zoomFactor += increase;

						if (zoomFactor > 2)
							zoomFactor = 2;

						if (zoomFactor < 0.2)
							zoomFactor = 0.2;
						resizeEverything();
					}
					else
					{
						var amount = FlxG.mouse.wheel;

						if (amount > 0 && strumLine.y < 0)
							amount = 0;

						if (doSnapShit)
						{
							var increase:Float = 0;
							var beats:Float = 0;

							if (amount < 0)
							{
								increase = 1 / deezNuts.get(snap);
								beats = (Math.floor((curDecimalBeat * deezNuts.get(snap)) + 0.001) / deezNuts.get(snap)) + increase;
							}
							else
							{
								increase = -1 / deezNuts.get(snap);
								beats = ((Math.ceil(curDecimalBeat * deezNuts.get(snap)) - 0.001) / deezNuts.get(snap)) + increase;
							}

							var data = TimingStruct.getTimingAtBeat(beats);

							if (beats <= 0)
								inst.time = 0;

							var bpm = data != null ? data.bpm : _song.bpm;

							if (data != null)
							{
								inst.time = (data.startTime + ((beats - data.startBeat) / (bpm / 60))) * 1000;
							}
						}
						else
							inst.time -= (FlxG.mouse.wheel * Conductor.stepCrochet * 0.4);

						if (!_song.splitVoiceTracks)
							vocals.time = inst.time;
						else
						{
							vocalsPlayer.time = inst.time;
							vocalsEnemy.time = inst.time;
						}
					}
				}

				if (FlxG.keys.justPressed.ESCAPE)
					LoadingState.loadAndSwitchState(new FreeplayState());

				if (FlxG.keys.pressed.SHIFT)
				{
					if (FlxG.keys.justPressed.RIGHT)
					{
						speed += 0.1;
					}
					else if (FlxG.keys.justPressed.LEFT)
					{
						speed -= 0.1;
					}

					if (speed > 3)
						speed = 3;
					if (speed <= 0.01)
						speed = 0.1;
				}
				else
				{
					if (FlxG.keys.justPressed.RIGHT && !FlxG.keys.pressed.CONTROL)
					{
						goToSection(curSection + 1);
					}
					else if (FlxG.keys.justPressed.LEFT && !FlxG.keys.pressed.CONTROL)
					{
						goToSection(curSection - 1);
					}
				}

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
					remove(selectBox);
				}

				if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.D)
				{
					lastAction = "delete";
					var notesToBeDeleted = [];
					deletedNotes = [];
					for (i in 0...selectedBoxes.members.length)
					{
						deletedNotes.push([
							selectedBoxes.members[i].connectedNote.strumTime,
							selectedBoxes.members[i].connectedNote.rawNoteData,
							selectedBoxes.members[i].connectedNote.sustainLength
						]);
						notesToBeDeleted.push(selectedBoxes.members[i].connectedNote);
					}

					for (i in notesToBeDeleted)
					{
						deleteNote(i);
					}
				}

				if (FlxG.keys.justPressed.DELETE)
				{
					lastAction = "delete";
					var notesToBeDeleted = [];
					deletedNotes = [];
					for (i in 0...selectedBoxes.members.length)
					{
						deletedNotes.push([
							selectedBoxes.members[i].connectedNote.strumTime,
							selectedBoxes.members[i].connectedNote.rawNoteData,
							selectedBoxes.members[i].connectedNote.sustainLength
						]);
						notesToBeDeleted.push(selectedBoxes.members[i].connectedNote);
					}

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

					offsetSelectedNotes(offset);
				}

				if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.C)
				{
					if (selectedBoxes.members.length != 0)
					{
						copiedNotes = [];
						for (i in selectedBoxes.members)
							copiedNotes.push([
								i.connectedNote.strumTime,
								i.connectedNote.rawNoteData,
								i.connectedNote.sustainLength,
								i.connectedNote.isAlt,
								i.connectedNote.beat,
								i.connectedNote.noteShit
							]);

						var firstNote = copiedNotes[0][0];

						for (i in copiedNotes) // normalize the notes
						{
							i[0] = i[0] - firstNote;
						}
					}
				}

				if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.V)
				{
					if (copiedNotes.length != 0)
					{
						while (selectedBoxes.members.length != 0)
						{
							selectedBoxes.members[0].connectedNote.charterSelected = false;
							selectedBoxes.members[0].destroy();
							selectedBoxes.members.remove(selectedBoxes.members[0]);
							selectedBoxes.clear();
						}
						pasteNotesFromArray(copiedNotes);

						lastAction = "paste";
					}
				}

				if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
				{
					switch (lastAction)
					{
						case "paste":
							if (pastedNotes.length != 0)
							{
								for (i in pastedNotes)
								{
									if (curRenderedNotes.members.contains(i))
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
			}

			if (updateFrame == 4)
			{
				TimingStruct.clearTimings();

				var currentIndex = 0;
				for (i in _song.eventObjects)
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

			snapText.text = "";

			if (FlxG.keys.justPressed.RIGHT && FlxG.keys.pressed.CONTROL)
			{
				snapSelection++;
				var index = 6;
				if (snapSelection > 6)
					snapSelection = 6;
				if (snapSelection < 0)
					snapSelection = 0;
				for (v in deezNuts.keys())
				{
					if (index == snapSelection)
					{
						snap = v;
					}
					index--;
				}
			}
			if (FlxG.keys.justPressed.LEFT && FlxG.keys.pressed.CONTROL)
			{
				snapSelection--;
				if (snapSelection > 6)
					snapSelection = 6;
				if (snapSelection < 0)
					snapSelection = 0;
				var index = 6;
				for (v in deezNuts.keys())
				{
					if (index == snapSelection)
					{
						snap = v;
					}
					index--;
				}
			}

			if (FlxG.keys.justPressed.SHIFT)
				doSnapShit = !doSnapShit;

			doSnapShit = defaultSnap;
			if (FlxG.keys.pressed.SHIFT)
			{
				doSnapShit = !defaultSnap;
			}

			check_snap.checked = doSnapShit;

			Conductor.songPosition = inst.time;

			_song.songId = typingShit.text;
			_song.audioFile = typingShit2.text;

			var timingSeg = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);

			var start = Conductor.songPosition;

			if (timingSeg != null)
			{
				var timingSegBpm = timingSeg.bpm;
				currentBPM = timingSegBpm;

				if (currentBPM != Conductor.bpm)
				{
					Conductor.changeBPM(currentBPM, false);
				}

				var pog:Float = (curDecimalBeat - timingSeg.startBeat) / (Conductor.bpm / 60);

				start = (timingSeg.startTime + pog) * 1000;
			}

			var weird = getSectionByTime(start);

			if (weird != null)
			{
				if (lastUpdatedSection != getSectionByTime(start))
				{
					lastUpdatedSection = weird;
					check_mustHitSection.checked = weird.mustHitSection;
					check_CPUAltAnim.checked = weird.CPUAltAnim;
					check_playerAltAnim.checked = weird.playerAltAnim;
				}
			}

			strumLine.y = getYfromStrum(start) * zoomFactor;
			camFollow.y = strumLine.y;

			var left = FlxG.keys.justPressed.ONE;
			var down = FlxG.keys.justPressed.TWO;
			var up = FlxG.keys.justPressed.THREE;
			var right = FlxG.keys.justPressed.FOUR;
			var leftO = FlxG.keys.justPressed.FIVE;
			var downO = FlxG.keys.justPressed.SIX;
			var upO = FlxG.keys.justPressed.SEVEN;
			var rightO = FlxG.keys.justPressed.EIGHT;

			if (FlxG.keys.justPressed.F1)
			{
				FlxG.save.data.showHelp = !FlxG.save.data.showHelp;
			}

			var pressArray = [left, down, up, right, leftO, downO, upO, rightO];
			var delete = false;

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
					if (FlxG.mouse.x > 0 && FlxG.mouse.x < 0 + gridBG.width && FlxG.mouse.y > 0 && FlxG.mouse.y < 0 + height)
					{
						addNote();
					}
				}
			}

			if (FlxG.mouse.x > 0 && FlxG.mouse.x < gridBG.width && FlxG.mouse.y > 0 && FlxG.mouse.y < height)
			{
				dummyArrow.visible = true;

				dummyArrow.x = Math.floor(FlxG.mouse.x / GRID_SIZE) * GRID_SIZE;

				if (doSnapShit)
				{
					var time = getStrumTime(FlxG.mouse.y / zoomFactor);

					var beat = TimingStruct.getBeatFromTime(time);
					var snapped = Math.round(beat * deezNuts.get(snap)) / deezNuts.get(snap);

					dummyArrow.y = getYfromStrum(TimingStruct.getTimeFromBeat(snapped)) * zoomFactor;
				}
				else
				{
					dummyArrow.y = FlxG.mouse.y;
				}
			}
			else
				dummyArrow.visible = false;

			if (doInput)
			{
				if (FlxG.keys.justPressed.ENTER)
				{
					lastSection = curSection;

					PlayState.SONG = _song;
					inst.stop();
					if (!_song.splitVoiceTracks)
						vocals.stop();
					else
					{
						vocalsPlayer.stop();
						vocalsEnemy.stop();
					}
					for (i in _song.notes)
					{
						if (i.startTime > inst.length)
							_song.notes.remove(i);
					}
					Main.dumpCache();

					LoadingState.loadAndSwitchState(new PlayState());
					clean();
				}

				if (curSelectedNote != null && curSelectedNote[2] > -1)
				{
					if (FlxG.keys.justPressed.E)
					{
						changeNoteSustain(Conductor.stepCrochet);
					}
					if (FlxG.keys.justPressed.Q)
					{
						changeNoteSustain(-Conductor.stepCrochet);
					}
				}

				if (FlxG.keys.justPressed.C && !FlxG.keys.pressed.CONTROL)
				{
					var sect = _song.notes[curSection];

					sect.mustHitSection = !sect.mustHitSection;
					updateHeads();
					check_mustHitSection.checked = sect.mustHitSection;
					var i = sectionRenderes.members[curSection];
					var cachedY = i.icon.y;
					remove(i.icon);
					var sectionicon = sect.mustHitSection ? new HealthIcon(player1.healthIcon,
						player1.iconAnimated).clone() : new HealthIcon(player2.healthIcon, player2.iconAnimated).clone();
					sectionicon.x = -95;
					sectionicon.y = cachedY;
					sectionicon.setGraphicSize(0, 45);

					i.icon = sectionicon;
					i.lastUpdated = sect.mustHitSection;

					add(sectionicon);
				}
				if (FlxG.keys.justPressed.V && !FlxG.keys.pressed.CONTROL)
				{
					var secit = _song.notes[curSection];

					if (secit != null)
					{
						swapSection(secit);
					}
				}

				if (FlxG.keys.justPressed.TAB)
				{
					if (FlxG.keys.pressed.SHIFT)
					{
						UI_box.selected_tab -= 1;
						if (UI_box.selected_tab < 0)
							UI_box.selected_tab = 3;
					}
					else
					{
						UI_box.selected_tab += 1;
						if (UI_box.selected_tab > 3)
							UI_box.selected_tab = 0;
					}
				}

				if (!FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
				{
					this.noteShit--;
					if (noteShit < 0)
					{
						noteShit = shits.length - 1;
					}
					updateNotetypeText();
				}

				if (!FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.X)
				{
					this.noteShit++;
					if (noteShit == shits.length)
						noteShit = 0;
					updateNotetypeText();
				}

				if (!typingShit.hasFocus && !typingShit2.hasFocus)
				{
					var shiftThing:Int = 1;
					if (FlxG.keys.pressed.SHIFT)
						shiftThing = 4;
					if (FlxG.keys.justPressed.SPACE)
					{
						if (inst.playing)
						{
							inst.pause();
							if (!_song.splitVoiceTracks)
								vocals.pause();
							else
							{
								vocalsPlayer.pause();
								vocalsEnemy.pause();
							}
						}
						else
						{
							inst.time = lastConductorPos;
							if (!_song.splitVoiceTracks)
							{
								vocals.time = inst.time;
								vocals.play();
							}
							else
							{
								vocalsPlayer.time = inst.time;
								vocalsEnemy.time = inst.time;
								vocalsPlayer.play();
								vocalsEnemy.play();
							}
							inst.play();
						}
					}

					if (inst.time < 0 || curDecimalBeat < 0)
						inst.time = 0;

					if (!FlxG.keys.pressed.SHIFT)
					{
						if (FlxG.keys.pressed.W || FlxG.keys.pressed.S)
						{
							inst.pause();
							if (!_song.splitVoiceTracks)
								vocals.pause();
							else
							{
								vocalsPlayer.pause();
								vocalsEnemy.pause();
							}

							var daTime:Float = 700 * FlxG.elapsed;

							if (FlxG.keys.pressed.W)
							{
								inst.time -= daTime;
							}
							else
								inst.time += daTime;

							if (!_song.splitVoiceTracks)
								vocals.time = inst.time;
							else
							{
								vocalsPlayer.time = inst.time;
								vocalsEnemy.time = inst.time;
							}
						}
					}
					else
					{
						if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S)
						{
							inst.pause();
							if (!_song.splitVoiceTracks)
								vocals.pause();
							else
							{
								vocalsPlayer.pause();
								vocalsEnemy.pause();
							}

							var daTime:Float = Conductor.stepCrochet * 2;

							if (FlxG.keys.justPressed.W)
							{
								inst.time -= daTime;
							}
							else
								inst.time += daTime;

							if (!_song.splitVoiceTracks)
								vocals.time = inst.time;
							else
							{
								vocalsPlayer.time = inst.time;
								vocalsEnemy.time = inst.time;
							}
						}
					}
				}
			}
			_song.bpm = tempBpm;
		}
		catch (e)
		{
			Debug.logError("Error\n" + e);
		}
		var playedSound:Array<Bool> = [false, false, false, false];
		var daHitSound:FlxSound;
		curRenderedNotes.forEachAlive(function(note:Note)
		{
			if (FlxG.save.data.playHitsounds)
			{
				if (note.strumTime <= Conductor.songPosition)
				{
					if (note.strumTime > lastConductorPos && inst.playing && note.noteData > -1)
					{
						var data:Int = note.noteData % 4;
						var noteDataToCheck:Int = note.noteData;
						if (noteDataToCheck > -1 && note.mustPress != _song.notes[curSection].mustHitSection)
							noteDataToCheck += 4;
						if (!playedSound[data])
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
							daHitSound.volume = hitsoundsVol.value;
							daHitSound.play().pan = note.noteData < 4 ? -0.3 : 0.3;
							playedSound[data] = true;

							data = note.noteData;
							if (note.mustPress != _song.notes[curSection].mustHitSection)
							{
								data += 4;
							}
						}
					}
				}
			}
		});

		lastConductorPos = Conductor.songPosition;

		bpmTxt.text = Std.string(FlxMath.roundDecimal(Conductor.songPosition / 1000, 2))
			+ " / "
			+ Std.string(FlxMath.roundDecimal(inst.length / 1000, 2))
			+ "\nCur Section: "
			+ curSection
			+ "\nCurBeat: "
			+ HelperFunctions.truncateFloat(curDecimalBeat, 3)
			+ "\nCurStep: "
			+ curStep
			+ "\nZoom: "
			+ HelperFunctions.truncateFloat(zoomFactor, 2)
			+ "\nSpeed: "
			+ HelperFunctions.truncateFloat(speed, 1)
			+ "\n\nSnap: "
			+ snap
			+ "\n"
			+ (doSnapShit ? "Snap enabled" : "Snap disabled")
			+
			(FlxG.save.data.showHelp ? "\n\nHelp:\nCtrl-MWheel : Zoom in/out\nShift-Left/Right :\n Change playback speed\nCtrl-Drag Click : Select notes\nCtrl-C : Copy notes\nCtrl-V : Paste notes\nCtrl-Z : Undo\nDelete : Delete selection\nCTRL-Left/Right :\n  Change Snap\nHold Shift : Disable Snap\nClick:\n  Place notes\nUp/Down :\n  Move selected notes 1 step\nShift-Up/Down :\n  Move selected notes 1 beat\nSpace: Play Music\nEnter : Preview\n Z/X Change Notetype.\nPress F1 to hide/show this!" : "");
		bpmTxt.updateHitbox();

		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();

		if (metronome.checked)
			FlxG.sound.play(Paths.sound('Metronome_Tick'));
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
					curRenderedSustains.remove(curSelectedNoteObject.noteCharterObject);

				remove(curSelectedNoteObject.noteCharterObject);

				var sustainVis:FlxSprite = new FlxSprite(curSelectedNoteObject.x + (GRID_SIZE * 0.5) - 2,
					curSelectedNoteObject.y + GRID_SIZE).makeGraphic(8,
						Math.floor((getYfromStrum(curSelectedNoteObject.strumTime + curSelectedNote[2]) * zoomFactor) - curSelectedNoteObject.y));
				curSelectedNoteObject.sustainLength = curSelectedNote[2];
				curSelectedNoteObject.noteCharterObject = sustainVis;

				curRenderedSustains.add(sustainVis);
			}
		}

		updateGrid();
		updateNoteUI();
	}

	function resetSection(songBeginning:Bool = false):Void
	{
		inst.pause();
		if (!_song.splitVoiceTracks)
			vocals.pause();
		else
		{
			vocalsPlayer.pause();
			vocalsEnemy.pause();
		}

		// Basically old shit from changeSection???
		inst.time = 0;
		if (!_song.splitVoiceTracks)
			vocals.time = inst.time;
		else
		{
			vocalsPlayer.time = inst.time;
			vocalsEnemy.time = inst.time;
		}

		updateGrid();
		if (!songBeginning)
			updateSectionUI();
	}

	function changeSection(sec:Int = 0, ?updateMusic:Bool = true):Void
	{
		if (_song.notes[sec] != null)
		{
			curSection = sec;

			updateGrid();

			if (updateMusic)
			{
				inst.pause();
				inst.time = sectionStartTime();
				if (!_song.splitVoiceTracks)
				{
					if (vocals != null)
					{
						vocals.pause();
						vocals.time = inst.time;
					}
				}
				else
				{
					if (vocalsPlayer != null)
					{
						vocalsPlayer.pause();
						vocalsPlayer.time = inst.time;
					}
					if (vocalsEnemy != null)
					{
						vocalsEnemy.pause();
						vocalsEnemy.time = inst.time;
					}
				}
			}

			updateGrid();
			updateSectionUI();
		}
	}

	function copySection(sec:SwagSection)
	{
	}

	function updateSectionUI():Void
	{
		var sec = getSectionByTime(Conductor.songPosition);

		if (sec == null)
		{
			check_mustHitSection.checked = true;
			check_CPUAltAnim.checked = false;
			check_playerAltAnim.checked = false;
		}
		else
		{
			check_mustHitSection.checked = sec.mustHitSection;
			check_CPUAltAnim.checked = sec.CPUAltAnim;
			check_playerAltAnim.checked = sec.playerAltAnim;
		}
	}

	function updateHeads():Void
	{
		var mustHit = check_mustHitSection.checked;
		#if FEATURE_FILESYSTEM
		var head = (mustHit ? player1.healthIcon : player2.healthIcon);
		var i = sectionRenderes.members[curSection];

		function iconUpdate(failsafe:Bool = false):Void
		{
			var sect = _song.notes[curSection];
			var cachedY = i.icon.y;
			remove(i.icon);
			var sectionicon = new HealthIcon(failsafe ? (mustHit ? 'bf' : 'face') : head).clone();
			sectionicon.x = -95;
			sectionicon.y = cachedY;
			sectionicon.setGraphicSize(0, 45);

			i.icon = sectionicon;
			i.lastUpdated = sect.mustHitSection;

			add(sectionicon);
		}

		// fail-safe
		// TODO: Refactor this to use OpenFlAssets.
		if (!Paths.fileExists("images/icons/icon-" + head.split("-")[0] + ".png", IMAGE)
			&& !Paths.fileExists("images/icons/icon-" + head + ".png", IMAGE))
		{
			if (i.icon.animation.curAnim == null)
				iconUpdate(true);
		}
		//
		else if (i.icon.animation.curAnim.name != head
			&& i.icon.animation.curAnim.name != head.split("-")[0]
			|| head == 'bf-pixel'
			&& i.icon.animation.curAnim.name != 'bf-pixel')
		{
			if (i.icon.animation.getByName(head) != null)
				i.icon.animation.play(head);
			else
				iconUpdate();
		}
		#else
		leftIcon.animation.play(mustHit ? player1.healthIcon : player2.healthIcon);
		rightIcon.animation.play(mustHit ? player2.healthIcon : player1.healthIcon);
		#end
	}

	function updateNoteUI():Void
	{
		if (curSelectedNote != null)
		{
			stepperSusLength.value = curSelectedNote[2];
			if (curSelectedNote[3] != null)
				check_naltAnim.checked = curSelectedNote[3];
			else
			{
				curSelectedNote[3] = false;
				check_naltAnim.checked = false;
			}

			strumTimeInputText.text = '' + curSelectedNote[0];
		}
	}

	function updateGrid():Void
	{
		// curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		// curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();

		var currentSection = 0;

		for (section in _song.notes)
		{
			if (section != null)
				for (i in section.sectionNotes)
				{
					var seg = TimingStruct.getTimingAtTimestamp(i[0]);
					var daNoteInfo = i[1];
					var daStrumTime = i[0];
					var daSus = i[2];
					var daShit = i[5];
					var daBeat = TimingStruct.getBeatFromTime(daStrumTime);

					var note:Note = new Note(daStrumTime, daNoteInfo % 4, null, false, true, true, i[3], daBeat, daShit);
					note.rawNoteData = daNoteInfo;
					note.sustainLength = daSus;
					note.strumTime = daStrumTime;
					note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
					note.updateHitbox();
					note.x = Math.floor(daNoteInfo * GRID_SIZE);

					note.y = Math.floor(getYfromStrum(daStrumTime) * zoomFactor);

					if (curSelectedNote != null)
						if (curSelectedNote[0] == note.strumTime)
							lastNote = note;

					curRenderedNotes.add(note);

					var stepCrochet = (((60 / seg.bpm) * 1000) / 4);

					if (daSus > 0)
					{
						var sustainVis:FlxSprite = new FlxSprite(note.x + (GRID_SIZE * 0.5) - 2,
							note.y + GRID_SIZE).makeGraphic(8, Math.floor((getYfromStrum(note.strumTime + note.sustainLength) * zoomFactor) - note.y));

						note.noteCharterObject = sustainVis;

						curRenderedSustains.add(sustainVis);
					}
				}
			currentSection++;
		}
	}

	private function addSection(lengthInSteps:Int = 16):Void
	{
		var daPos:Float = 0;
		var start:Float = 0;

		var bpm = _song.bpm;
		for (i in 0...curSection)
		{
			for (ii in TimingStruct.AllTimings)
			{
				var data = TimingStruct.getTimingAtTimestamp(start);
				if ((data != null ? data.bpm : _song.bpm) != bpm && bpm != ii.bpm)
					bpm = ii.bpm;
			}
			start += (4 * (60 / bpm)) * 1000;
		}

		var sec:SwagSection = {
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: true,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			CPUAltAnim: false,
			playerAltAnim: false
		};

		_song.notes.push(sec);
	}

	function selectNote(note:Note):Void
	{
		var swagNum:Int = 0;

		for (sec in _song.notes)
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

		updateNoteUI();
	}

	function deleteNote(note:Note):Void
	{
		while (selectedBoxes.members.length != 0)
		{
			selectedBoxes.members[0].connectedNote.charterSelected = false;
			selectedBoxes.members[0].destroy();
			selectedBoxes.members.remove(selectedBoxes.members[0]);
			selectedBoxes.clear();
		}

		lastNote = note;

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
			for (i in _song.notes)
			{
				for (n in i.sectionNotes)
					if (n[0] == note.strumTime && n[1] == note.rawNoteData)
						i.sectionNotes.remove(n);
			}
		}

		curRenderedNotes.remove(note);

		if (note.sustainLength > 0)
			curRenderedSustains.remove(note.noteCharterObject);

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

		// updateNoteUI();
	}

	function clearSection():Void
	{
		while (selectedBoxes.members.length != 0)
		{
			selectedBoxes.members[0].connectedNote.charterSelected = false;
			selectedBoxes.members[0].destroy();
			selectedBoxes.members.remove(selectedBoxes.members[0]);
			selectedBoxes.clear();
		}

		_song.notes[curSection].sectionNotes = [];
		updateGrid();
		updateNoteUI();
	}

	function clearSong():Void
	{
		for (daSection in 0..._song.notes.length)
		{
			_song.notes[daSection].sectionNotes = [];
		}

		updateGrid();
	}

	private function newSection(lengthInSteps:Int = 16, mustHitSection:Bool = false, CPUAltAnim:Bool = true, playerAltAnim:Bool = true):SwagSection
	{
		var daPos:Float = 0;

		var currentSeg = TimingStruct.AllTimings[TimingStruct.AllTimings.length - 1];

		var currentBeat = 4;

		for (i in _song.notes)
			currentBeat += 4;

		if (currentSeg == null)
			return null;

		var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

		daPos = (currentSeg.startTime + start) * 1000;

		var sec:SwagSection = {
			startTime: daPos,
			endTime: Math.POSITIVE_INFINITY,
			lengthInSteps: lengthInSteps,
			bpm: _song.bpm,
			changeBPM: false,
			mustHitSection: mustHitSection,
			sectionNotes: [],
			typeOfSection: 0,
			altAnim: false,
			CPUAltAnim: CPUAltAnim,
			playerAltAnim: playerAltAnim
		};

		return sec;
	}

	/*
		function recalculateAllSectionTimes()
		{
			var savedNotes:Array<Dynamic> = [];

			for (i in 0..._song.notes.length) // loops through sections
			{
				var section = _song.notes[i];

				var currentBeat = 4 * i;

				var currentSeg = TimingStruct.getTimingAtBeat(currentBeat);

				if (currentSeg == null)
					return;

				var start:Float = (currentBeat - currentSeg.startBeat) / (currentSeg.bpm / 60);

				section.startTime = (currentSeg.startTime + start) * 1000;

				if (i != 0)
					_song.notes[i - 1].endTime = section.startTime;
				section.endTime = Math.POSITIVE_INFINITY;
			}
		}
	 */
	function shiftNotes(measure:Int = 0, step:Int = 0, ms:Int = 0):Void
	{
		var newSong = [];

		var millisecadd = (((measure * 4) + step / 4) * (60000 / currentBPM)) + ms;
		var totaladdsection = Std.int((millisecadd / (60000 / currentBPM) / 4));
		if (millisecadd > 0)
		{
			for (i in 0...totaladdsection)
			{
				newSong.unshift(newSection());
			}
		}
		for (daSection1 in 0..._song.notes.length)
		{
			newSong.push(newSection(16, _song.notes[daSection1].mustHitSection, _song.notes[daSection1].CPUAltAnim, _song.notes[daSection1].playerAltAnim));
		}

		for (daSection in 0...(_song.notes.length))
		{
			var aimtosetsection = daSection + Std.int((totaladdsection));
			if (aimtosetsection < 0)
				aimtosetsection = 0;
			newSong[aimtosetsection].mustHitSection = _song.notes[daSection].mustHitSection;
			updateHeads();
			newSong[aimtosetsection].CPUAltAnim = _song.notes[daSection].CPUAltAnim;
			newSong[aimtosetsection].playerAltAnim = _song.notes[daSection].playerAltAnim;
			for (daNote in 0...(_song.notes[daSection].sectionNotes.length))
			{
				var newtiming = _song.notes[daSection].sectionNotes[daNote][0] + millisecadd;
				if (newtiming < 0)
				{
					newtiming = 0;
				}
				var futureSection = Math.floor(newtiming / 4 / (60000 / currentBPM));
				_song.notes[daSection].sectionNotes[daNote][0] = newtiming;
				newSong[futureSection].sectionNotes.push(_song.notes[daSection].sectionNotes[daNote]);
			}
		}
		_song.notes = newSong;
		recalculateAllSectionTimes();
		updateGrid();
		updateSectionUI();
		updateNoteUI();
	}

	/*
		public function getSectionByTime(ms:Float, ?changeCurSectionIndex:Bool = false):SwagSection
		{
			var index = 0;

			for (i in _song.notes)
			{
				if (ms >= i.startTime && ms < i.endTime)
				{
					if (changeCurSectionIndex)
						curSection = index;
					return i;
				}
				index++;
			}

			return null;
		}
	 */
	public function getNoteByTime(ms:Float)
	{
		for (i in _song.notes)
		{
			for (n in i.sectionNotes)
				if (n[0] == ms)
					return i;
		}
		return null;
	}

	public var curSelectedNoteObject:Note = null;

	private function addNote(?n:Note):Void
	{
		var strum = getStrumTime(dummyArrow.y) / zoomFactor;

		var section = getSectionByTime(strum);

		if (section == null)
			return;
		var noteStrum = strum;
		var noteData = Math.floor(FlxG.mouse.x / GRID_SIZE);
		var noteSus = 0;
		var noteShit = shits[this.noteShit];
		// you can change this to `var noteShit = noteShitDropDown.selectedLabel;` for using the dropdown but I dont like the dropdown, its faster to press Z and X.
		if (FlxG.save.data.gen)
			Debug.logTrace("Adding note with " + Std.int(strum) + " from dummyArrow with data " + noteData + " With A Notetype Of " + noteShit);

		if (n != null)
			section.sectionNotes.push([
				n.strumTime,
				n.noteData,
				n.sustainLength,
				false,
				TimingStruct.getBeatFromTime(n.strumTime),
				n.noteShit
			]);
		else
			section.sectionNotes.push([
				noteStrum,
				noteData,
				noteSus,
				false,
				TimingStruct.getBeatFromTime(noteStrum),
				noteShit
			]);

		var thingy = section.sectionNotes[section.sectionNotes.length - 1];

		curSelectedNote = thingy;

		var seg = TimingStruct.getTimingAtTimestamp(noteStrum);

		if (n == null)
		{
			var note:Note = new Note(noteStrum, noteData % 4, null, false, true, true, null, TimingStruct.getBeatFromTime(noteStrum), noteShit);
			note.rawNoteData = noteData;
			note.sustainLength = noteSus;
			note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
			note.updateHitbox();
			note.x = Math.floor(noteData * GRID_SIZE);

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;

			while (selectedBoxes.members.length != 0)
			{
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
			}

			curSelectedNoteObject.charterSelected = true;

			note.y = Math.floor(getYfromStrum(noteStrum) * zoomFactor);

			var box = new ChartingBox(note.x, note.y, note);
			box.connectedNoteData = thingy;
			selectedBoxes.add(box);

			curRenderedNotes.add(note);
		}
		else
		{
			var note:Note = new Note(n.strumTime, n.noteData % 4, null, false, true, true, n.isAlt, TimingStruct.getBeatFromTime(n.strumTime), noteShit);
			note.beat = TimingStruct.getBeatFromTime(n.strumTime);
			note.rawNoteData = n.noteData;
			note.sustainLength = noteSus;
			note.setGraphicSize(Math.floor(GRID_SIZE), Math.floor(GRID_SIZE));
			note.updateHitbox();
			note.x = Math.floor(n.noteData * GRID_SIZE);

			if (curSelectedNoteObject != null)
				curSelectedNoteObject.charterSelected = false;
			curSelectedNoteObject = note;

			while (selectedBoxes.members.length != 0)
			{
				selectedBoxes.members[0].connectedNote.charterSelected = false;
				selectedBoxes.members[0].destroy();
				selectedBoxes.members.remove(selectedBoxes.members[0]);
			}

			var box = new ChartingBox(note.x, note.y, note);
			box.connectedNoteData = thingy;
			selectedBoxes.add(box);

			curSelectedNoteObject.charterSelected = true;

			note.y = Math.floor(getYfromStrum(n.strumTime) * zoomFactor);

			curRenderedNotes.add(note);
		}

		updateNoteUI();

		autosaveSong();
	}

	function getStrumTime(yPos:Float):Float
	{
		return FlxMath.remapToRange(yPos, 0, lengthInSteps, 0, lengthInSteps);
	}

	function getYfromStrum(strumTime:Float):Float
	{
		return FlxMath.remapToRange(strumTime, 0, lengthInSteps, 0, lengthInSteps);
	}

	private var daSpacing:Float = 0.3;

	function getNotes():Array<Dynamic>
	{
		var noteData:Array<Dynamic> = [];

		for (i in _song.notes)
		{
			noteData.push(i.sectionNotes);
		}

		return noteData;
	}

	function loadJson(songId:String, diff:String):Void
	{
		try
		{
			PlayState.storyDifficulty = CoolUtil.difficultyArray.indexOf(diff);
			PlayState.SONG = Song.loadFromJson(songId, CoolUtil.getSuffixFromDiff(diff));

			LoadingState.loadAndSwitchState(new ChartingState());
		}
		catch (e)
		{
			Debug.logError('Make Sure You Have A Valid JSON To Load. Error: $e');
			return;
		}
	}

	function updateNotetypeText()
	{
		switch (noteShit)
		{
			case 0:
				notename = "Normal";
			case 1:
				notename = "Hurt";
			case 2:
				notename = "Must Press";
		}
		notetypetext.text = "Note Type: " + notename;
		notetypetext.updateHitbox();
	}

	function cleanObjects()
	{
		remove(leftIcon);
		remove(rightIcon);

		leftIcon.kill();
		leftIcon.destroy();

		rightIcon.kill();
		rightIcon.destroy();

		player1 = null;
		player2 = null;

		var toRemove = [];

		for (i in _song.notes)
		{
			if (i.startTime > inst.length)
				toRemove.push(i);
		}

		for (i in toRemove)
			_song.notes.remove(i);
	}

	override function destroy()
	{
		curRenderedNotes.forEachAlive(function(spr:Note) spr.destroy());
		curRenderedNotes.clear();
		curRenderedSustains.forEachAlive(function(spr:FlxSprite) spr.destroy());
		curRenderedSustains.clear();
		sectionRenderes.forEachAlive(function(huh:SectionRender) huh.destroy());
		sectionRenderes.clear();
		selectedBoxes.forEachAlive(function(huh:ChartingBox) huh.destroy());
		selectedBoxes.clear();

		cleanObjects();

		super.destroy();
	}

	private function saveLevel()
	{
		for (i in _song.notes)
		{
			if (i.startTime > inst.length)
				_song.notes.remove(i);
		}

		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, null, " ");

		if ((data != null) && (data.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data.trim(), _song.songId.toLowerCase() + CoolUtil.getSuffixFromDiff(curDiff) + ".json");
		}
	}

	function autosaveSong():Void
	{
		if (FlxG.save.data.autoSaving)
		{
			FlxG.save.data.autosave = Json.stringify({
				"song": _song,
			});

			trace('Chart Saved');
			FlxG.save.flush();
		}
		else
		{
			trace('You Have Auto Saving Disabled.');
		}
	}

	function loadAutosave():Void
	{
		var autoSaveData = Json.parse(FlxG.save.data.autosave);

		var json = {
			"song": _song
		};

		var data:String = Json.stringify(json, null, " ");

		var data:SongData = cast autoSaveData;
		var meta:SongMeta = {};
		var name:String = data.songId;
		if (autoSaveData.song != null)
		{
			meta = autoSaveData.songMeta != null ? cast autoSaveData.songMeta : {};
		}

		PlayState.SONG = Song.parseJSONshit(data.songId, data, meta);
		for (i in _song.notes)
		{
			if (i.startTime > inst.length)
				_song.notes.remove(i);
		}
		LoadingState.loadAndSwitchState(new ChartingState());
		clean();
	}

	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
		FlxG.log.notice("Successfully saved LEVEL DATA.");
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
	}

	function getSectionSteps(?section:Null<Int> = null)
	{
		if (section == null)
			section = curSection;
		var val:Null<Float> = null;

		if (_song.notes[section] != null)
			val = _song.notes[section].lengthInSteps;
		return val != null ? val : 16;
	}
}
