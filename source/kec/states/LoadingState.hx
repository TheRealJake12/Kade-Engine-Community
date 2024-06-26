package kec.states;

import lime.app.Promise;
import lime.app.Future;
import openfl.utils.Assets as OpenFlAssets;
import lime.utils.Assets as LimeAssets;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import haxe.io.Path;
import flixel.addons.transition.FlxTransitionableState;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 1.0;

	var loadingText:FlxText;
	var target:FlxState;
	var stopMusic = false;
	var callbacks:MultiCallback;

	var logo:FlxSprite;

	var danceLeft:Bool = false;

	var loadBar:FlxSprite;
	var targetShit:Float = 0;

	public static var instance:LoadingState = null;

	function new(target:FlxState, stopMusic:Bool)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
	}

	var gfDance:FlxSprite;

	override function create()
	{
		instance = this;

		#if NO_PRELOAD_ALL
		initSongsManifest().onComplete(function(lib)
		{
			callbacks = new MultiCallback(onLoad);
			var introComplete = callbacks.add("introComplete");

			if (PlayState.SONG != null)
			{
				checkLoadSong(getSongPath());
				if (PlayState.SONG.needsVoices)
					checkLoadSong(getVocalPath());
			}

			// Essential libraries (characters,notes,gameplay elements)
			checkLibrary("shared");
			if (FlxG.save.data.background)
			{
				if (PlayState.storyWeek > 0)
					checkLibrary("week" + PlayState.storyWeek); // Non-important libraries for optimization (stages, unique-week elements, in-game cutscenes)
				else
					checkLibrary("tutorial");
			}

			if (GameplayCustomizeState.freeplayNoteStyle == 'pixel') // Essential library for Customize gameplay. (Very light)
				checkLibrary("week6");

			var fadeTime = 0.5;
			FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true);
			new FlxTimer().start(fadeTime + MIN_TIME, function(_) introComplete());
		});
		#else
		onLoad();
		#end
		logo = new FlxSprite(-150, -100);
		logo.frames = Paths.getSparrowAtlas('logoBumpin');

		logo.antialiasing = FlxG.save.data.antialiasing;
		logo.animation.addByPrefix('bump', 'logo bumpin', 24);
		logo.animation.play('bump');
		logo.updateHitbox();
		// logoBl.screenCenter();
		// logoBl.color = FlxColor.BLACK;

		gfDance = new FlxSprite(FlxG.width * 0.4, FlxG.height * 0.07);
		gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = FlxG.save.data.antialiasing;

		loadingText = new FlxText(FlxG.width * 8, FlxG.height * 0.07, 0, "Loading", 42);
		loadingText.antialiasing = false;
		loadingText.setFormat(Paths.font('pixel.otf'), 42, 0xFFFFFF, CENTER);
		loadingText.screenCenter();

		loadingText.x -= 425;
		loadingText.y += 125;

		add(gfDance);
		add(logo);
		add(loadingText);

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xfffffab8);
		loadBar.screenCenter(X);
		loadBar.antialiasing = FlxG.save.data.antialiasing;
		add(loadBar);

		FlxTransitionableState.skipNextTransOut = false;

		super.create();
	}

	function checkLoadSong(path:String)
	{
		if (path != null)
		{
			if (!OpenFlAssets.cache.hasSound(path.toString()))
			{
				/*var library = OpenFlAssets.getLibrary("songs");
					final symbolPath = daPath.split(":").pop();
					@:privateAccess
					library.types.set(symbolPath, SOUND);
					@:privateAccess
					library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]); */

				var callback = callbacks.add("song:" + path.toString());
				OpenFlAssets.loadSound(path.toString()).onComplete(function(_)
				{
					callback();
				});
			}
		}
	}

	function checkLibrary(library:String)
	{
		Debug.logInfo('$library exists? ${OpenFlAssets.hasLibrary(library)}');
		if (OpenFlAssets.getLibrary(library) == null)
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			OpenFlAssets.loadLibrary(library).onComplete(function(_)
			{
				callback();
			});
		}
	}

	override function beatHit()
	{
		logo.animation.play('bump');
		danceLeft = !danceLeft;

		if (danceLeft)
			gfDance.animation.play('danceRight');
		else
			gfDance.animation.play('danceLeft');
		super.beatHit();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		#if debug
		if (FlxG.keys.justPressed.SPACE)
			Debug.logTrace('fired: ' + callbacks.getFired() + " unfired:" + callbacks.getUnfired());
		#end
		if (callbacks != null)
		{
			loadingText.text = 'Loading [${callbacks.length - callbacks.numRemaining}/${callbacks.length}]';
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);
			loadBar.scale.x += 0.5 * (targetShit - loadBar.scale.x);
		}
	}

	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		MusicBeatState.switchState(target);
	}

	static function getSongPath()
	{
		return Paths.inst(PlayState.SONG.songId);
	}

	static function getVocalPath()
	{
		return Paths.voices(PlayState.SONG.songId);
	}

	inline static public function loadAndSwitchState(target:FlxState, stopMusic = false)
	{
		MusicBeatState.switchState(getNextState(target, stopMusic));
	}

	static function getNextState(target:FlxState, stopMusic = false):FlxState
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		return target;
	}

	#if NO_PRELOAD_ALL
	static function isSoundLoaded(path:String):Bool
	{
		return OpenFlAssets.cache.hasSound(path);
	}

	static function isLibraryLoaded(library:String):Bool
	{
		return OpenFlAssets.getLibrary(library) != null;
	}
	#end

	override function destroy()
	{
		super.destroy();

		callbacks = null;
	}

	static function initSongsManifest()
	{
		// TODO: Hey, wait, does this break ModCore?

		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = OpenFlAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
				promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;

	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();

	public function new(callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}

	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;

				if (logId != null)
					log('fired $id, $numRemaining remaining');

				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}

	inline function log(msg):Void
	{
		if (logId != null)
			trace('$logId: $msg');
	}

	public function getFired()
		return fired.copy();

	public function getUnfired()
		return [for (id in unfired.keys()) id];
}
