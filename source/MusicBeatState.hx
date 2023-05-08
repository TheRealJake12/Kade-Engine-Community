package;

import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.ui.FlxUI;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
import flixel.group.FlxGroup.FlxTypedGroup;
import openfl.Lib;
import flixel.FlxBasic;
import lime.app.Application;
import flixel.input.keyboard.FlxKey;
import Section.SwagSection;
import Song.SongData;

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	var step = 0.0;
	var startInMS = 0.0;
	var activeSong:SongData = null;

	var oldStep:Int = -1;

	private var curSection:Int = 0;

	private var currentSection:SwagSection = null;

	private var curDecimalBeat:Float = 0;

	private var oldSection:Int = -1;
	private var curTiming:TimingStruct = null;

	public static var currentColor = 0;
	public static var switchingState:Bool = false;

	private var assets:Array<FlxBasic> = [];

	public static var initSave:Bool = false;

	private var controls(get, never):Controls;
	var fullscreenBind:FlxKey;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.75, true));
		}
		fullscreenBind = FlxKey.fromString(Std.string(FlxG.save.data.fullscreenBind));
		FlxTransitionableState.skipNextTransOut = false;

		super.create();
		TimingStruct.clearTimings();
		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}

	override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		var result = super.remove(Object, Splice);
		return result;
	}

	public function clean()
	{
		if (FlxG.save.data.optimize)
		{
			for (i in assets)
			{
				remove(i);
			}
		}
	}

	public function destroyObject(Object:Dynamic):Void
	{
		if (Std.isOfType(Object, FlxSprite))
		{
			var spr:FlxSprite = cast(Object, FlxSprite);
			spr.kill();
			remove(spr, true);
			spr.destroy();
			spr = null;
		}
		else if (Std.isOfType(Object, FlxTypedGroup))
		{
			var grp:FlxTypedGroup<Dynamic> = cast(Object, FlxTypedGroup<Dynamic>);
			for (ObjectGroup in grp.members)
			{
				if (Std.isOfType(ObjectGroup, FlxSprite))
				{
					var spr:FlxSprite = cast(ObjectGroup, FlxSprite);
					spr.kill();
					remove(spr, true);
					spr.destroy();
					spr = null;
				}
			}
		}
	}

	override function destroy()
	{
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

	override function add(Object:FlxBasic):FlxBasic
	{
		if (Std.isOfType(Object, FlxUI))
			return null;

		if (Std.isOfType(Object, FlxSprite))
			var spr:FlxSprite = cast(Object, FlxSprite);

		// Debug.logTrace(Object);
		assets.push(Object);
		var result = super.add(Object);
		return result;
	}

	override function update(elapsed:Float)
	{
		if (curDecimalBeat < 0)
			curDecimalBeat = 0;

		if (Conductor.songPosition < 0)
			curDecimalBeat = 0;
		else
		{
			if (curTiming == null)
			{
				setFirstTiming();
			}
			if (curTiming != null)
			{
				/* Not necessary to get a timing every frame if it's the same one. Instead if the current timing endBeat is equal or greater
					than the current Beat meaning that the timing ended the game will check for a new timing (for bpm change events basically), 
					and also to get a lil more of performance */

				if (curDecimalBeat > curTiming.endBeat)
				{
					Debug.logTrace('Current Timing ended, checking for next Timing...');
					curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
					step = ((60 / curTiming.bpm) * 1000) / 4;
					startInMS = (curTiming.startTime * 1000);
				}

				#if debug
				FlxG.watch.addQuick("Current Conductor Timing Seg", curTiming.bpm);
				#end

				curDecimalBeat = TimingStruct.getBeatFromTime(Conductor.songPosition);

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				// Bromita uwu
				try
				{
					if (currentSection == null)
					{
						currentSection = getSectionByTime(Conductor.songPosition);
						if (activeSong != null)
							curSection = activeSong.notes.indexOf(currentSection);
					}

					if (currentSection != null)
					{
						if (Conductor.songPosition >= currentSection.endTime || Conductor.songPosition < currentSection.startTime)
						{
							currentSection = getSectionByTime(Conductor.songPosition);
							if (activeSong != null)
								curSection = activeSong.notes.indexOf(currentSection);
						}
					}
				}
				catch (e)
				{
					// Debug.logError('Section is null you fucking dumbass uninstall Flixel and kys');
				}

				if (oldSection != curSection)
				{
					sectionHit();
					oldSection = curSection;
				}

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}
			}
			else
			{
				curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);

				curBeat = Math.floor(curDecimalBeat);
				curStep = Math.floor(curDecimalBeat * 4);

				// Bromita uwu
				try
				{
					if (currentSection == null)
					{
						currentSection = getSectionByTime(0);
						curSection = 0;
					}

					if (currentSection != null)
					{
						if (Conductor.songPosition >= currentSection.endTime || Conductor.songPosition < currentSection.startTime)
						{
							currentSection = getSectionByTime(Conductor.songPosition);

							curSection = activeSong.notes.indexOf(currentSection);
						}
					}
				}
				catch (e)
				{
					// Debug.logError('Section is null you fucking dumbass uninstall Flixel and kys');
				}

				if (oldSection != curSection)
				{
					sectionHit();
					oldSection = curSection;
				}

				if (oldStep != curStep)
				{
					stepHit();
					oldStep = curStep;
				}
			}
		}	

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		super.update(elapsed);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}

	function getSectionByTime(ms:Float):SwagSection
	{
		if (activeSong == null)
			return null;

		if (activeSong.notes == null)
			return null;

		for (i in activeSong.notes)
		{
			if (ms >= i.startTime && ms < i.endTime)
			{
				return i;
			}
		}
		return null;
	}

	function recalculateAllSectionTimes(startIndex:Int = 0)
	{
		if (activeSong == null)
			return;

		for (i in startIndex...activeSong.notes.length) // loops through sections
		{
			var section:SwagSection = activeSong.notes[i];

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

	private function setFirstTiming()
	{
		curTiming = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);
		if (curTiming != null)
		{
			step = ((60 / curTiming.bpm) * 1000) / 4;
			startInMS = (curTiming.startTime * 1000);
		}
	}

	public function sectionHit():Void
	{
		// do literally nothing dumbass
	}

	public static function switchState(nextState:FlxState)
	{
		MusicBeatState.switchingState = true;
		// Custom made Trans in
		Main.mainClassState = Type.getClass(nextState);
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.4, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.resetState();
				};
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					MusicBeatState.switchingState = false;
					FlxG.switchState(nextState);
				};
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}
}
