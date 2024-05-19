package;

import cache.BaseCache;
import haxe.Timer;

using StringTools;

class Caching extends MusicBeatState
{
	var toBeDone = 0;
	var done = 0;

	var loaded = false;

	var text:FlxText;
	var images = [];
	var sounds = [];
	var shitz:FlxText;
	var kadeLogo:FlxSprite;

	override function create()
	{
		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		Discord.changePresence("I Have A Chad PC (Caching)", null);
		#end

		text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300, 0, "Loading...");
		text.size = 34;
		text.alignment = FlxTextAlign.CENTER;
		text.alpha = 1;
		text.font = Paths.font("vcr.ttf");

		kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.image('KadeEngineLogoOld'));
		kadeLogo.screenCenter();
		text.y -= kadeLogo.height / 2 - 125;
		text.x -= 170;

		kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.6));
		if (FlxG.save.data.antialiasing != null)
			kadeLogo.antialiasing = FlxG.save.data.antialiasing;
		else
			kadeLogo.antialiasing = true;

		kadeLogo.alpha = 0;

		add(kadeLogo);
		add(text);
		for (imageDir in ['assets/shared/images/'])
		{
			list('image', imageDir);
		}

		for (soundDir in ['assets/songs/', 'assets/shared/sounds/', 'assets/shared/music/',])
		{
			list('sound', soundDir);
		}

		// TODO: Get the song list from OpenFlAssets.
		// TODO: Remove All The OpenFlAssets TODOs

		toBeDone = Lambda.count(images) + Lambda.count(sounds);

		#if FEATURE_MULTITHREADING
		// update thread
		if (!BaseCache.loadedBefore)
		{
			sys.thread.Thread.create(() ->
			{
				while (!loaded)
				{
					if (toBeDone != 0 && BaseCache.cacheAmount != toBeDone)
					{
						var alpha = HelperFunctions.truncateFloat(BaseCache.cacheAmount / toBeDone * 100, 2) / 100;
						kadeLogo.alpha = alpha;
						text.text = "Loading... (" + BaseCache.cacheAmount + "/" + toBeDone + ")";
					}
				}
			});

			// cache thread
			haxe.Timer.delay(function() // this is fine
			{
				start();
			}, 600);
		}
		else
		{
			MusicBeatState.switchState(new OptionsDirect());
			Debug.logTrace("Loaded Before, No Need To Load Again.");
		}
		#end

		super.create();
	}

	function start()
	{
		if (!FlxG.save.data.unload)
		{
			switch (cache.BaseCache.loadedBefore)
			{
				case false:
					actuallyCache(FlxG.save.data.gpuRender); // gpu rendering fucks me in the ass again
				case true:
					MusicBeatState.switchState(new OptionsDirect());
					Debug.logTrace("Loaded Before, No Need To Load Again.");
			}
		}
		else
			MusicBeatState.switchState(new OptionsDirect());
	}

	function actuallyCache(gpuRender:Bool)
	{
		FlxG.autoPause = false;
		var stamp = Timer.stamp();
		switch (gpuRender)
		{
			case true:
				for (directory in [
					'assets/songs/',
					'assets/shared/images/',
					'assets/shared/sounds/',
					'assets/shared/music/'
				])
				{
					cache.BaseCache.cacheStuff(directory);
				}
				haxe.Timer.delay(function() // this is fine
				{
					cache.BaseCache.loadedBefore = true;
					FlxG.autoPause = FlxG.save.data.autoPause;
					loaded = true;
					MusicBeatState.switchState(new OptionsDirect());
					Debug.logTrace("Done");
					Debug.logTrace(Timer.stamp() - stamp);
				}, 600);
			case false:
				new lime.app.Future<Void>(function()
				{
					for (directory in [
						'assets/songs/',
						'assets/shared/images/',
						'assets/shared/sounds/',
						'assets/shared/music/'
					])
					{
						cache.BaseCache.cacheStuff(directory);
					}
					haxe.Timer.delay(function() // this is fine
					{
						cache.BaseCache.loadedBefore = true;
						FlxG.autoPause = FlxG.save.data.autoPause;
						loaded = true;
						MusicBeatState.switchState(new OptionsDirect());
						Debug.logTrace("Done");
						Debug.logTrace(Timer.stamp() - stamp);
					}, 600);
				}, true);
		}
	}

	var calledDone = false;

	override function update(elapsed)
	{
		super.update(elapsed);
	}

	function list(type:String, dir:String)
	{
		switch (type)
		{
			case 'image':
				for (file in CoolUtil.readAssetsDirectoryFromLibrary(dir, 'IMAGE'))
				{
					images.push(file);
				}
			case 'sound':
				for (file in CoolUtil.readAssetsDirectoryFromLibrary(dir, 'SOUND'))
				{
					sounds.push(file);
				}
		}
	}
}
