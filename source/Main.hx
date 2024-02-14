package;

import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import flixel.util.FlxColor;
import openfl.display.Bitmap;
import openfl.filters.ShaderFilter;
import flixel.system.FlxAssets.FlxShader;
import flash.display.StageQuality;
#if FEATURE_DISCORD
import Discord;
#end
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import lime.app.Application;
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
	var game = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: Init, // initial game state
		zoom: -1.0, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public static var mainClassState:Class<FlxState> = Init; // yoshubs jumpscare (I am aware of *the incident*)
	public static var gameContainer:Main = null; // Main instance to access when needed.
	public static var bitmapFPS:Bitmap;
	public static var focusMusicTween:FlxTween;
	public static var focused:Bool = true;

	public var hasWifi:Bool = true;

	var oldVol:Float = 1.0;
	var newVol:Float = 0.3;

	public static var watermarks = true; // Whether to put Kade Engine literally anywhere

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		// quick checks

		Lib.current.addChild(new Main());
	}

	public function new()
	{
		super();

		if (stage != null)
		{
			init();
		}
		else
		{
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE))
		{
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (game.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / game.width;
			var ratioY:Float = stageHeight / game.height;
			game.zoom = Math.min(ratioX, ratioY);
			game.width = Math.ceil(stageWidth / game.zoom);
			game.height = Math.ceil(stageHeight / game.zoom);
		}

		gameContainer = this;

		// Run this first so we can see logs.
		Debug.onInitProgram();

		#if !mobile
		fpsCounter = new KadeEngineFPS(10, 3, 0xFFFFFF);
		bitmapFPS = ImageOutline.renderImage(fpsCounter, 1, 0x000000, true);
		bitmapFPS.smoothing = true;
		#end

		// FlxTransitionableState.skipNextTransIn = true;
		game.framerate = 60;
		addChild(new FlxGame(game.width, game.height, game.initialState, #if (flixel < "5.0.0") game.zoom, #end game.framerate, game.framerate,
			game.skipSplash, game.startFullscreen));

		FlxG.game.setFilters([new ShaderFilter(new FlxShader())]);

		FlxG.game.stage.quality = StageQuality.LOW;

		FlxG.fixedTimestep = false;

		FlxG.signals.preStateSwitch.add(function()
		{
			var cache = cast(Assets.cache, AssetCache);
			for (key => font in cache.font)
				cache.removeFont(key);
			if (FlxG.save.data.unload)
			{
				for (key => sound in cache.sound)
					cache.removeSound(key);
			}
		});

		#if !mobile
		addChild(fpsCounter);
		toggleFPS(FlxG.save.data.fps);
		#end

		#if html5
		FlxG.autoPause = false;
		FlxG.mouse.visible = false;
		#end

		// Finish up loading debug tools.
		Debug.onGameStart();
		#if desktop
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
		#end
	}

	// motherfucker had to be special and have to be in main. smh.
	public static function dumpCache()
	{
		if (FlxG.save.data.unload && !FlxG.save.data.gpuRender)
		{
			#if PRELOAD_ALL
			@:privateAccess
			for (key in FlxG.bitmap._cache.keys())
			{
				var obj = FlxG.bitmap._cache.get(key);
				if (obj != null)
				{
					Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
				}
			}
			#if cpp
			cpp.vm.Gc.run(true);
			#end
			Assets.cache.clear("songs");
			#end
		}
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

	#if desktop
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
			+ '${MainMenuState.kecVer} Error Type: '
			+ e.error
			+
			"\nWoops! We fucked up somewhere! Report this window here : https://github.com/TheRealJake12/Kade-Engine-Community.git\n\n Why dont you join the discord while you're at it? : https://discord.gg/TKCzG5rVGf \n\n> Crash Handler written by: sqirra-rng";
		if (!FileSystem.exists("./logs/"))
			FileSystem.createDirectory("./logs/");
		File.saveContent(path, errMsg + "\n");
		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));
		Application.current.window.alert(errMsg, "Error!");
		Sys.exit(1);
	}

	function onWindowFocusOut()
	{
		focused = false;

		// Lower global volume when unfocused
		if (Type.getClass(FlxG.state) != PlayState) // imagine stealing my code smh
		{
			oldVol = FlxG.sound.volume;
			if (oldVol > 0.3)
			{
				newVol = 0.3;
			}
			else
			{
				if (oldVol > 0.1)
				{
					newVol = 0.1;
				}
				else
				{
					newVol = 0;
				}
			}

			if (focusMusicTween != null)
				focusMusicTween.cancel();
			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: newVol}, 0.5);

			if (PlayState.inDaPlay)
			{
				PlayState.instance.openSubState(new PauseSubState());

				PlayState.instance.persistentUpdate = false;
				PlayState.instance.persistentDraw = true;
				PlayState.instance.paused = true;

				if (!PlayState.SONG.splitVoiceTracks)
					PlayState.vocals.pause();
				else
				{
					PlayState.vocalsPlayer.pause();
					PlayState.vocalsEnemy.pause();
				}
				PlayState.inst.pause();
			}

			// Conserve power by lowering draw framerate when unfocuced
		}
		FlxG.drawFramerate = 30;
	}

	function onWindowFocusIn()
	{
		new FlxTimer().start(0.2, function(tmr:FlxTimer)
		{
			focused = true;
		});

		// Lower global volume when unfocused
		if (Type.getClass(FlxG.state) != PlayState)
		{
			// Normal global volume when focused
			if (focusMusicTween != null)
				focusMusicTween.cancel();

			focusMusicTween = FlxTween.tween(FlxG.sound, {volume: oldVol}, 0.5);

			// Bring framerate back when focused
			FlxG.drawFramerate = FlxG.save.data.fpsCap;
		}
		gameContainer.setFPSCap(FlxG.save.data.fpsCap);
	}
	#end

	var fpsCounter:KadeEngineFPS;

	public function toggleFPS(fpsEnabled:Bool):Void
	{
		fpsCounter.visible = fpsEnabled;
	}

	public function changeFPSColor(color:FlxColor)
	{
		fpsCounter.textColor = color;
	}

	public function setFPSCap(cap:Int)
	{
		FlxG.updateFramerate = cap;
		FlxG.drawFramerate = FlxG.updateFramerate;
	}

	public function getFPSCap():Float
	{
		return openfl.Lib.current.stage.frameRate;
	}

	public function getFPS():Float
	{
		return fpsCounter.currentFPS;
	}
}
