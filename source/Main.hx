package;

import flixel.FlxGame;
import openfl.display.DisplayObject;
import haxe.ui.Toolkit;
import kec.objects.FrameCounter;
#if FEATURE_DISCORD
import kec.backend.Discord;
#end
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import lime.app.Application;
#if VIDEOS
import hxvlc.util.Handle;
#end
#if desktop
// crash handler stuff
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;
import openfl.system.System;
#end
import openfl.utils.AssetCache;

using StringTools;

class Main extends Sprite
{
	final game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: Init, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public var hasWifi:Bool = true;
	public static var focused:Bool = true;

	private var oldVol:Float = 1.0;
	private var newVol:Float = 0.3;

	private var curGame:FlxGame;
	public static var gameContainer:Main = null; // Main instance to access when needed.
	public var frameCounter:FrameCounter = null;

	public static var mainClassState:Class<FlxState> = Init; // yoshubs jumpscare (I am aware of *the incident*)
	public static var focusMusicTween:FlxTween;

	public function new()
	{
		super();
		setupGame();
	}

	private function setupGame():Void
	{
		gameContainer = this;
		initHaxeUI();
		kec.backend.Debug.onInitProgram();

		frameCounter = new FrameCounter(10, 3, 0xFFFFFF);
		curGame = new Game(game.width, game.height, game.initialState, game.framerate, game.skipSplash, game.startFullscreen);

		@:privateAccess
		curGame._customSoundTray = kec.objects.SoundTray;

		addChild(curGame);

		FlxG.fixedTimestep = false;
		
		addChild(frameCounter);
		fpsVisible(FlxG.save.data.fps);

		FlxG.signals.preStateSwitch.add(function()
		{
			Paths.clearCache();
		});

		#if VIDEOS
		Handle.initAsync();
		#end
		Debug.onGameStart();

		#if cpp
		cpp.vm.Gc.enable(true);
		#end

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
	}

	public function checkInternetConnection()
	{
		Debug.logInfo('Checking Internet connection Through URL: "https://www.google.com".');
		var http = new haxe.Http("https://www.google.com");
		http.onStatus = function(status:Int)
		{
			switch status
			{
				case 200: // success
					hasWifi = true;
					Debug.logInfo('Connected.');
				default: // error
					hasWifi = false;
					Debug.logInfo('No Internet Connection.');
			}
		};

		http.onError = function(e)
		{
			hasWifi = false;
			Debug.logInfo('No Internet Connection.');
		}

		http.request();
	}
	
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;
		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();
		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");
		path = "./logs/" + "Crashlog " + dateNow + ".txt";
		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}
		errMsg += "\nUncaught Error: "
			+ "Version : "
			+ '${Constants.kecVer} Error Type: '
			+ e.error
			+
			"\nWoops! We fucked up somewhere! Report this window here : https://github.com/TheRealJake12/Kade-Engine-Community.git\n\n Why dont you join the discord while you're at it? : https://discord.gg/TKCzG5rVGf \n\n> Crash Handler written by: sqirra-rng";
		Sys.println(errMsg);
		#if FEATURE_LOGGING
		if (!FileSystem.exists("./logs/"))
			FileSystem.createDirectory("./logs/");
		File.saveContent(path, errMsg + "\n");
		Sys.println("Crash dump saved in " + Path.normalize(path));
		#end
		Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}

	public function setFPSCap(cap:Int)
	{
		FlxG.updateFramerate = cap;
		FlxG.drawFramerate = FlxG.updateFramerate;
	}

	public inline function fpsVisible(visible:Bool)
		return gameContainer.frameCounter.visible = visible;

	public inline function setFPSPos(x:Int, y:Int)
	{
		gameContainer.frameCounter.x = x;
		gameContainer.frameCounter.y = y;
	}

	public inline function setFPSColor(col:Int)
		return gameContainer.frameCounter.textColor = col;

	function onWindowFocusOut()
	{
		focused = false;

		// Lower global volume when unfocused
		oldVol = FlxG.sound.volume;
		if (oldVol > 0.3)
			newVol = 0.3;
		else
		{
			if (oldVol > 0.1)
				newVol = 0.1;
			else
				newVol = 0;
		}

		if (focusMusicTween != null)
			focusMusicTween.cancel();
		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);

		// Conserve power by lowering draw framerate when unfocuced
		FlxG.drawFramerate = 60;
	}

	function onWindowFocusIn()
	{
		focused = true;
		if (focusMusicTween != null)
			focusMusicTween.cancel();

		focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);
		gameContainer.setFPSCap(FlxG.save.data.fpsCap);
	}

	function initHaxeUI():Void
	{
		Toolkit.init();
		Toolkit.theme = 'dark'; // don't be cringe
		Toolkit.autoScale = false;
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
