package;

import Conductor.BPMChangeEvent;
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

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var curDecimalBeat:Float = 0;
	public static var currentColor = 0;
	public static var switchingState:Bool = false;

	private var assets:Array<FlxBasic> = [];
	public static var initSave:Bool = false;

	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	override function create()
	{
		var skip:Bool = FlxTransitionableState.skipNextTransOut;

		if (!skip)
		{
			openSubState(new CustomFadeTransition(0.7, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
		Paths.clearUnusedMemory();

		super.create();
		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}

	override function remove(Object:FlxBasic, Splice:Bool = false):FlxBasic
	{
		#if FEATURE_MULTITHREADING
		MasterObjectLoader.removeObject(Object);
		#end
		var result = super.remove(Object, Splice);
		return result;
	}

	public function clean()
	{
		if (FlxG.save.data.unload){
			#if FEATURE_MULTITHREADING
			for (i in MasterObjectLoader.Objects)
			{
				destroyObject(i);
			}
			#else
			for (i in assets)
			{
				remove(i);
			}
			#end
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
		#if FEATURE_MULTITHREADING
		MasterObjectLoader.addObject(Object);
		#else
		assets.push(Object);
		#end
		var result = super.add(Object);
		return result;
	}


	override function update(elapsed:Float)
	{
		if (Conductor.songPosition < 0)
			curDecimalBeat = 0;
		else
		{
			var data = TimingStruct.getTimingAtTimestamp(Conductor.songPosition);

			if (data != null)
			{
				FlxG.watch.addQuick("Current Conductor Timing Seg", data.bpm);

				Conductor.crochet = ((60 / data.bpm) * 1000) / PlayState.songMultiplier;

				var step = ((60 / data.bpm) * 1000) / 4;
				var startInMS = (data.startTime * 1000);

				curDecimalBeat = data.startBeat + ((((Conductor.songPosition / 1000)) - data.startTime) * (data.bpm / 60));
				var ste:Int = Math.floor(data.startStep + ((Conductor.songPosition) - startInMS) / step);
				if (ste >= 0)
				{
					if (ste > curStep)
					{
						for (i in curStep...ste)
						{
							curStep++;
							updateBeat();
							stepHit();
						}
					}
					else if (ste < curStep)
					{
						// Song reset?
						curStep = ste;
						updateBeat();
						stepHit();
					}
				}
			}
			else
			{
				curDecimalBeat = (((Conductor.songPosition / 1000))) * (Conductor.bpm / 60);
				var nextStep:Int = Math.floor((Conductor.songPosition) / Conductor.stepCrochet);
				if (nextStep >= 0)
				{
					if (nextStep > curStep)
					{
						for (i in curStep...nextStep)
						{
							curStep++;
							updateBeat();
							stepHit();
						}
					}
					else if (nextStep < curStep)
					{
						// Song reset?
						curStep = nextStep;
						updateBeat();
						stepHit();
					}
				}
				Conductor.crochet = ((60 / Conductor.bpm) * 1000) / PlayState.songMultiplier;
			}
		}

		super.update(elapsed);
	}

	private function updateBeat():Void
	{
		lastBeat = curBeat;
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Int
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		return lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
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

	public static function switchState(nextState:FlxState)
	{
		MusicBeatState.switchingState = true;
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.3, false));
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
