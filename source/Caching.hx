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

	override function create()
	{
		FlxG.save.bind('funkin', 'ninjamuffin99');

		PlayerSettings.init();

		KadeEngineData.initSave();

		// It doesn't reupdate the list before u restart rn lmao
		NoteskinHelpers.updateNoteskins();

		FlxG.sound.muteKeys = [FlxKey.fromString(FlxG.save.data.muteBind)];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(FlxG.save.data.volDownBind)];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(FlxG.save.data.volUpBind)];

		FlxG.mouse.visible = false;

		FlxG.worldBounds.set(0, 0);

		bitmapData = new Map<String, FlxGraphic>();

		text = new FlxText(FlxG.width / 2, FlxG.height / 2 + 300, 0, "Loading...");
		text.size = 34;
		text.alignment = FlxTextAlign.CENTER;
		text.alpha = 1;

		kadeLogo = new FlxSprite(FlxG.width / 2, FlxG.height / 2).loadGraphic(Paths.loadImage('KadeEngineLogoOld'));
		kadeLogo.x -= kadeLogo.width / 2;
		kadeLogo.y -= kadeLogo.height / 2 + 100;
		text.y -= kadeLogo.height / 2 - 125;
		text.x -= 170;
		kadeLogo.setGraphicSize(Std.int(kadeLogo.width * 0.6));
		if (FlxG.save.data.antialiasing != null)
			kadeLogo.antialiasing = FlxG.save.data.antialiasing;
		else
			kadeLogo.antialiasing = true;

		kadeLogo.alpha = 1;

		FlxGraphic.defaultPersist = FlxG.save.data.cacheImages;

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

		if (FlxG.save.data.cacheMusic)
			music = Paths.listAudioToCache(false);

		if (FlxG.save.data.cacheSounds)
			sounds = Paths.listAudioToCache(true);

		if (FlxG.save.data.cacheNoteskin)
			{
				for (i in FileSystem.readDirectory(FileSystem.absolutePath("assets/shared/images/noteskins")))
				{
					if (!i.endsWith(".png"))
						continue;
					noteskins.push(i);
				}
			}
		
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
					text.alpha = 1;
					text.text = "Loading... (" + done + "/" + toBeDone + ")";
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
