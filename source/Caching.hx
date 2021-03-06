#if FEATURE_FILESYSTEM
package;

import lime.app.Application;
#if FEATURE_DISCORD
import Discord.DiscordClient;
#end
import openfl.display.BitmapData;
import openfl.utils.Assets as OpenFlAssets;
import flixel.ui.FlxBar;
import haxe.Exception;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.input.keyboard.FlxKey;
import haxe.Json;

using StringTools;

class Caching extends MusicBeatState
{
	var toBeDone = 0;
	var done = 0;

	var loaded = false;

	var text:FlxText;
	var kadeLogo:FlxSprite;

	public static var bitmapData:Map<String, FlxGraphic>;

	var characters = [];

	var songs = [];
	var noteskins = [];
	var music = [];
	var sounds = [];
	var funkay:FlxSprite;

	var shitz:FlxText;

	override function create()
	{
		FlxG.save.bind('funkin', 'ninjamuffin99');

		PlayerSettings.init();

		#if FEATURE_DISCORD
		// Updating Discord Rich Presence
		DiscordClient.changePresence("I Have A Chad PC (Caching)", null);
		#end

		KadeEngineData.initSave();

		// It doesn't reupdate the list before u restart rn lmao
		CustomNoteHelpers.Skin.updateNoteskins();

		FlxG.mouse.visible = false;

		FlxG.worldBounds.set(0, 0);

		bitmapData = new Map<String, FlxGraphic>();

		funkay = new FlxSprite(0, 0).loadGraphic(Paths.image('funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.scale.set(0.76, 0.67);
		funkay.antialiasing = FlxG.save.data.antialiasing;
		add(funkay);
		funkay.scrollFactor.set();
		funkay.screenCenter();

		shitz = new FlxText(12, 12, 0, "Loading...", 12);
		shitz.scrollFactor.set();
		shitz.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(shitz);

		FlxGraphic.defaultPersist = false;

		#if FEATURE_FILESYSTEM
		if (FlxG.save.data.cacheCharacters)
		{
			for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/characters")))
			{
				if (!i.endsWith(".png"))
					continue;
				characters.push(i);
			}
		}

		// TODO: Get the audio list from OpenFlAssets.
		if (FlxG.save.data.cacheSongs)
			songs = Paths.listSongsToCache();

		if (FlxG.save.data.cacheSounds)
			sounds = Paths.listAudioToCache(true);
		
		// TODO: Get the song list from OpenFlAssets.
		#end

		toBeDone =  Lambda.count(noteskins) + Lambda.count(characters) + Lambda.count(songs) + Lambda.count(music) + Lambda.count(sounds);

		add(kadeLogo);
		add(text);

		#if FEATURE_MULTITHREADING
		// update thread

		sys.thread.Thread.create(() ->
		{
			while (!loaded)
			{
				if (toBeDone != 0 && done != toBeDone)
				{
					shitz.alpha = 1;
					shitz.text = "Loading... (" + done + "/" + toBeDone + ")";
				}
			}
		});

		// cache thread
		sys.thread.Thread.create(() ->
		{
			cache();
		});
		#end

		super.create();
	}

	var calledDone = false;

	override function update(elapsed)
	{
		super.update(elapsed);
	}

	function cache()
	{
		#if FEATURE_FILESYSTEM

		for (i in characters)
		{
			var replaced = i.replace(".png", "");
			var imagePath = Paths.image('characters/' + replaced, 'shared');
			var data = OpenFlAssets.getBitmapData(imagePath);
			var graph = FlxGraphic.fromBitmapData(data);
			if (FlxG.save.data.general)
			{
				Debug.logTrace('Caching character graphic $i ($imagePath)...');
			}
			graph.persist = true;
			bitmapData.set(replaced, graph);
			done++;
		}

		for (i in songs)
		{
			var inst = Paths.inst(i);
			if (Paths.doesSoundAssetExist(inst))
			{
				FlxG.sound.cache(inst);
			}

			var voices = Paths.voices(i);
			if (Paths.doesSoundAssetExist(voices))
			{
				FlxG.sound.cache(voices);
			}

			done++;
		}

		for (i in music)
		{
			var replaced = i.replace(".ogg", "");
			var music = Paths.music(replaced, 'shared');
			if (Paths.doesSoundAssetExist(music))
			{
				FlxG.sound.cache(music);
			}

			done++;
		}
		loaded = true;
		#end
		FlxG.switchState(new OptionsDirect());
	}
}
#end