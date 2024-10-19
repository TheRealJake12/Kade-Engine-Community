package kec.states;

import kec.backend.chart.format.Section;
import flixel.addons.transition.FlxTransitionableState;
import kec.backend.Controls;
import kec.backend.PlayerSettings;
import kec.backend.chart.TimingStruct;
import kec.backend.chart.format.Modern;
import kec.backend.util.NoteStyleHelper;
import kec.states.FreeplayState;
import kec.substates.CustomFadeTransition;
import kec.substates.MusicBeatSubstate;

class MusicBeatState extends FlxTransitionableState
{
	private var curStep(default, set):Int = 0;
	private var curBeat(default, set):Int = 0;
	private var curSection(default, set):Int = 0;
	var step = 0.0;
	var startInMS = 0.0;
	var activeSong:Modern = null;

	private var currentSection:Section = null;

	private var curDecimalBeat:Float = 0;

	private var curTiming:TimingStruct = null;

	public static var switchingState:Bool = false;

	public static var initSave:Bool = false;

	private var controls(get, never):Controls;
	var fullscreenBind:FlxKey;

	public static var transSubstate:CustomFadeTransition;

	var subStates:Array<MusicBeatSubstate>;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	// Tween And Timer Manager. Don't Mess With These.
	public var tweenManager:FlxTweenManager;
	public var timerManager:FlxTimerManager;

	public function new()
	{
		super();
		subStates = [];
		// Setup The Tween / Timer Manager.
		tweenManager = new FlxTweenManager();
		timerManager = new FlxTimerManager();
	}

	override function create()
	{
		transSubstate = new CustomFadeTransition(0.4);
		destroySubStates = false;
		fullscreenBind = FlxKey.fromString(Std.string(FlxG.save.data.fullscreenBind));

		var skip:Bool = FlxTransitionableState.skipNextTransOut;
		if (!skip)
		{
			if (transSubstate != null)
			{
				transSubstate.isTransIn = true;
				transSubstate.executeTransition();
			}
		}
		FlxTransitionableState.skipNextTransOut = false;
		FlxG.stage.window.borderless = FlxG.save.data.borderless;
		Main.gameContainer.setFPSCap(FlxG.save.data.fpsCap);

		super.create();

		transSubstate.camera = FlxG.cameras.list[FlxG.cameras.list.length - 1];
	}

	override function destroy()
	{
		if (!PlayState.inDaPlay)
		{
			FreeplayState.songRating.clear();
			FreeplayState.songRatingOp.clear();
			FreeplayState.loadedSongData = false;
		}

		curTiming = null;
		currentSection = null;
		FlxDestroyUtil.destroyArray(subStates);

		if (transSubstate != null)
		{
			transSubstate.destroy();
			transSubstate = null;
		}

		timerManager.clear();
		tweenManager.clear();

		super.destroy();
	}

	public function fancyOpenURL(schmancy:String)
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [schmancy, "&"]);
		#else
		FlxG.openURL(schmancy);
		#end
	}

	function pushSub(subsState:MusicBeatSubstate)
	{
		subStates.push(subsState);
	}

	function clearSubs()
	{
		var i = subStates.length;
		while (--i > -1)
		{
			Debug.logTrace("destroying substate #" + i);
			subStates[i].destroy();
			subStates.remove(subStates[i]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// DO NOT COMMENT THIS OUT.
		tweenManager.update(elapsed);
		timerManager.update(elapsed);

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
			FlxG.fullscreen = !FlxG.fullscreen;

		if (transSubstate != null)
			if (transSubstate.active)
				transSubstate.update(elapsed);

		if (curDecimalBeat < 0)
			curDecimalBeat = 0;

		if (Conductor.songPosition <= 0)
			return;

		if (curTiming != null)
		{
			/* Not necessary to get a timing every frame if it's the same one. Instead if the current timing endBeat is equal or greater
				than the current Beat meaning that the timing ended the game will check for a new timing (for bpm change events basically), 
				and also to get a lil more of performance */

			if (curDecimalBeat >= curTiming.endBeat)
			{
				Debug.logTrace("Looking For Next Timing Going Forwards");
				curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
				Conductor.bpm = curTiming.bpm * Conductor.rate;
			}
			else if (curDecimalBeat < curTiming.startBeat)
			{
				Debug.logTrace('Looking For Next Timing Going Backwards');
				curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
				Conductor.bpm = curTiming.bpm * Conductor.rate;
			}

			#if debug
			FlxG.watch.addQuick("Current Conductor Timing Seg", curTiming.bpm);

			FlxG.watch.addQuick("Current Conductor Time", Conductor.songPosition);
			#end

			curDecimalBeat = TimingStruct.getBeatFromTimingTime(curTiming, Conductor.songPosition);

			curStep = Math.floor(curDecimalBeat * 4);
			curBeat = Math.floor(curDecimalBeat);
			if (currentSection == null)
			{
				Debug.logTrace('trying to find section at pos ${Conductor.songPosition}');
				currentSection = getSectionByTime(Conductor.songPosition);

				if (currentSection != null)
					curSection = currentSection.index;
			}

			if (currentSection != null)
			{
				if (Conductor.songPosition >= currentSection.endTime)
				{
					currentSection = getSectionByIndex(curSection +
						1); // Searching by index is very slow if we have too many sections, instead we assign a index to every section.
					if (currentSection != null)
						curSection = currentSection.index;
				}
				else if (Conductor.songPosition < currentSection.startTime)
				{
					currentSection = getSectionByIndex(curSection - 1); // Searching by index is very slow if we have too many sections, instead we assign a index to every section.
					if (currentSection != null)
						curSection = currentSection.index;
				}
			}
		}
		else
		{
			curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);

			curStep = Math.floor(curDecimalBeat * 4);
			curBeat = Math.floor(curDecimalBeat);

			if (currentSection == null)
			{
				currentSection = getSectionByTime(0);
				curSection = 0;
			}

			if (currentSection != null)
			{
				if (Conductor.songPosition >= currentSection.endTime)
				{
					currentSection = getSectionByIndex(curSection +
						1); // Searching by index is very slow if we have too many sections, instead we assign a index to every section.
					if (currentSection != null)
						curSection = currentSection.index;
				}
			}
		}
	}

	private function set_curStep(v:Int)
	{
		if (curStep == v)
			return v;

		curStep = v;
		stepHit();

		return v;
	}

	private function set_curBeat(v:Int)
	{
		if (curBeat == v)
			return v;

		curBeat = v;
		beatHit();
		return v;
	}

	private function set_curSection(v:Int)
	{
		if (curSection == v)
			return v;

		curSection = v;
		sectionHit();
		return v;
	}

	public function stepHit():Void
	{
	}

	public function beatHit():Void
	{
	}

	public function sectionHit():Void
	{
	}

	public static function switchState(nextState:FlxState)
	{
		MusicBeatState.switchingState = true;
		Main.mainClassState = Type.getClass(nextState);
		if (!FlxTransitionableState.skipNextTransIn)
		{
			if (transSubstate != null)
			{
				transSubstate.isTransIn = false;

				transSubstate.finishCallback = function()
				{
					MusicBeatState.switchingState = false;

					return FlxG.switchState(nextState);
				};
				transSubstate.executeTransition();
			}
			else
			{
				MusicBeatState.switchingState = false;

				return FlxG.switchState(nextState);
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		FlxG.resetState();
	}

	public inline static function getState():MusicBeatState
		return cast(FlxG.state, MusicBeatState);

	private function setFirstTiming()
	{
		curTiming = TimingStruct.getTimingAtTimestamp(0);
	}

	public function changeTime(time:Float)
	{
		Conductor.songPosition = time;
		curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
	}

	function getSectionByTime(ms:Float):Section
	{
		if (activeSong == null)
			return null;

		if (activeSong.notes == null)
			return null;

		for (i in activeSong.notes)
		{
			if (ms < i.startTime || ms > i.endTime)
				continue;

			return i;
		}

		return null;
	}

	function getSectionByIndex(index:Int):Section
	{
		if (activeSong == null)
			return null;

		if (activeSong.notes == null)
			return null;

		return activeSong.notes[index];
	}

	function recalculateAllSectionTimes(startIndex:Int = 0)
	{
		if (activeSong == null)
			return;

		for (i in startIndex...activeSong.notes.length) // loops through sections
		{
			var section:Section = activeSong.notes[i];

			var currentBeat:Float = 0.0;

			currentBeat = (section.lengthInSteps / 4) * (i + 1);

			for (k in 0...i)
				currentBeat -= ((section.lengthInSteps / 4) - (activeSong.notes[k].lengthInSteps / 4));

			section.endTime = TimingStruct.getTimeFromBeat(currentBeat);

			if (i != 0)
				section.startTime = activeSong.notes[i - 1].endTime;
			else
				section.startTime = 0;
		}
	}

	function setInitVars()
	{
		curTiming = null;
		currentSection = null;
		Conductor.songPosition = 0;
		curSection = -1;
		curDecimalBeat = -1;
		curBeat = -1;
		curStep = -1;
		setFirstTiming();
	}

	override function draw()
	{
		super.draw();

		if (transSubstate != null && transSubstate.visible)
			transSubstate.draw();
	}

	public function createTween(Object:Dynamic, Values:Dynamic, Duration:Float, ?Options:TweenOptions):FlxTween
	{
		var tween:FlxTween = tweenManager.tween(Object, Values, Duration, Options);
		tween.manager = tweenManager;
		return tween;
	}

	public function createTweenNum(FromValue:Float, ToValue:Float, Duration:Float = 1, ?Options:TweenOptions, ?TweenFunction:Float->Void):FlxTween
	{
		var tween:FlxTween = tweenManager.num(FromValue, ToValue, Duration, Options, TweenFunction);
		tween.manager = tweenManager;
		return tween;
	}

	public function createTimer(Time:Float = 1, ?OnComplete:FlxTimer->Void, Loops:Int = 1):FlxTimer
	{
		var timer:FlxTimer = new FlxTimer();
		timer.manager = timerManager;
		return timer.start(Time, OnComplete, Loops);
	}
}
