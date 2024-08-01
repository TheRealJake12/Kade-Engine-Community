package;

import flixel.util.typeLimit.NextState.InitialState;
import openfl.display.DisplayObject;
import lime.math.Rectangle;
import flixel.graphics.tile.FlxDrawBaseItem;
import flixel.FlxGame;

// https://github.com/FNF-CNE-Devs/CodenameEngine/blob/main/source/funkin/backend/system/FunkinGame.hx
// Credits to this peeps.
// DO NOT TOUCH ANYTHING.
class Game extends FlxGame
{
	var skipNextTickUpdate:Bool = false;

	public var volume:Float = 1.0;

	public override function new(gameWidth = 0, gameHeight = 0, ?initialState:InitialState, frameRate = 60, skipSplash = false, startFullscreen = false)
	{
		super(gameWidth, gameHeight, initialState, frameRate, frameRate, skipSplash, startFullscreen);
	}

	public override function switchState()
	{
		// Basic reset stuff
		FlxG.cameras.reset();
		FlxG.inputs.onStateSwitch();
		#if FLX_SOUND_SYSTEM
		FlxG.sound.destroy();
		#end

		FlxG.signals.preStateSwitch.dispatch();

		#if FLX_RECORD
		FlxRandom.updateStateSeed();
		#end

		// Destroy the old state (if there is an old state)
		if (_state != null)
			_state.destroy();

		// Finally assign and create the new state
		_state = _nextState.createInstance();
		_state._constructor = _nextState;
		_nextState = null;

		if (_gameJustStarted)
			FlxG.signals.preGameStart.dispatch();

		FlxG.signals.preStateCreate.dispatch(_state);

		_state.create();

		if (_gameJustStarted)
			gameStart();

		#if FLX_DEBUG
		debugger.console.registerObject("state", _state);
		#end

		FlxG.signals.postStateSwitch.dispatch();

		draw();
		_total = ticks = getTicks();
		skipNextTickUpdate = true;
	}

	public override function onEnterFrame(t)
	{
		if (skipNextTickUpdate != (skipNextTickUpdate = false))
			_total = ticks = getTicks();
		super.onEnterFrame(t);
	}

	// Get rid of hit test function because mouse memory ramp up during first move (-Bolo)
	@:noCompletion private override function __hitTest(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool,
			hitObject:DisplayObject):Bool
		return true;

	@:noCompletion override private function __hitTestHitArea(x:Float, y:Float, shapeFlag:Bool, stack:Array<DisplayObject>, interactiveOnly:Bool,
			hitObject:DisplayObject):Bool
		return true;

	@:noCompletion private override function __hitTestMask(x:Float, y:Float):Bool
		return true;
}
