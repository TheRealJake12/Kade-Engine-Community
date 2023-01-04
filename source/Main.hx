package;

import lime.app.Application;
import flixel.graphics.FlxGraphic;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import openfl.Assets;
import flixel.util.FlxColor;
import openfl.display.Bitmap;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import openfl.Lib;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.events.Event;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

#if desktop
// crash handler stuff
import lime.app.Application;
import openfl.events.UncaughtErrorEvent;
import haxe.CallStack;
import haxe.io.Path;
import Discord.DiscordClient;
import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

using StringTools;
#end

class Main extends Sprite
{
	var gameWidth:Int = 1280; // Width of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var gameHeight:Int = 720; // Height of the game in pixels (might be less / more in actual pixels depending on your zoom).
	var initialState:Class<FlxState> = Init; // The FlxState the game starts with.
	var zoom:Float = -1; // If -1, zoom is automatically calculated to fit the window dimensions. (Removed from Flixel 5.0.0)
	var framerate:Int = 60; // How many frames per second the game should run at.
	var skipSplash:Bool = true; // Whether to skip the flixel splash screen that appears in release mode.
	var startFullscreen:Bool = false; // Whether to start the game in fullscreen on desktop targets

	public static var instance:Main;
	public static var bitmapFPS:Bitmap;
	public static var focusMusicTween:FlxTween;
	public static var focused:Bool = true;
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
		instance = this;

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

		#if !cpp
		framerate = 60;
		#end

		// Run this first so we can see logs.
		Debug.onInitProgram();		

		// Gotta run this before any assets get loaded.
		ModCore.initialize();

		#if !mobile
		fpsCounter = new KadeEngineFPS(10, 3, 0xFFFFFF);
		bitmapFPS = ImageOutline.renderImage(fpsCounter, 1, 0x000000, true);
		bitmapFPS.smoothing = true;
		#end

		//FlxTransitionableState.skipNextTransIn = true;

		#if (flixel >= "5.0.0")
		game = new FlxGame(gameWidth, gameHeight, initialState, framerate, framerate, skipSplash, startFullscreen);
		#else
		game = new FlxGame(gameWidth, gameHeight, initialState, zoom, framerate, framerate, skipSplash, startFullscreen);
		#end
		addChild(game);

		#if FEATURE_DISCORD
		DiscordClient.initialize();

		Application.current.onExit.add(function(exitCode)
		{
			DiscordClient.shutdown();
		});
		#end

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
		#end
		Application.current.window.onFocusOut.add(onWindowFocusOut);
		Application.current.window.onFocusIn.add(onWindowFocusIn);
	}
	//motherfucker had to be special and have to be in main. smh.
	public static function dumpCache()
	{
		if (FlxG.save.data.unload && !FlxG.save.data.gpuRender){
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
		Assets.cache.clear("songs");
		//Assets.cache.clear("images");
		#end
		}
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
			+ "Version : " + '${MainMenuState.kecVer} Error Type: '
			+ e.error
			+ "\nWoops! We fucked up somewhere! Report this window here : https://github.com/TheRealJake12/Kade-Engine-Community.git\n\n Why dont you join the discord while you're at it? : https://discord.gg/TKCzG5rVGf \n\n> Crash Handler written by: sqirra-rng";
		if (!FileSystem.exists("./logs/"))
			FileSystem.createDirectory("./logs/");
		File.saveContent(path, errMsg + "\n");
		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));
		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();
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
			if (FlxG.save.data.gen)
				Debug.logTrace("Lost Focus");

			if (PlayState.inDaPlay){
				PlayState.instance.openSubState(new PauseSubState());

				PlayState.boyfriend.stunned = true;

				PlayState.instance.persistentUpdate = false;
				PlayState.instance.persistentDraw = true;
				PlayState.instance.paused = true;

				if (PlayState.isSM){
					PlayState.instance.vocals.pause();
					PlayState.instance.inst.pause();
				}
				else{
					FlxG.sound.music.pause();
				}
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

		if (FlxG.save.data.gen)
			Debug.logTrace("Gained Focus");

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
		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);
	}
	#end

	var game:FlxGame;

	var fpsCounter:KadeEngineFPS;
	
	public function toggleFPS(fpsEnabled:Bool):Void
	{
		fpsCounter.visible = fpsEnabled;
	}

	public function changeFPSColor(color:FlxColor)
	{
		fpsCounter.textColor = color;
	}

	public function setFPSCap(cap:Float)
	{
		var framerate = Std.int(cap);
		openfl.Lib.current.stage.frameRate = cap;
		if (framerate > FlxG.drawFramerate)
		{
			FlxG.updateFramerate = framerate;
			FlxG.drawFramerate = framerate;
		}
		else
		{
			FlxG.drawFramerate = framerate;
			FlxG.updateFramerate = framerate;
		}
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
