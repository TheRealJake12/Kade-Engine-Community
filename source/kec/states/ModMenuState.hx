package kec.states;

#if FEATURE_MODCORE
import haxe.ui.components.Button;
import kec.backend.modding.ModCore;
import flixel.group.FlxSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end

/**
 * Mod Menu Made By TheRealJake_12 With Some Elements Ripped From Psych Engine(I have no idea what I'm doing)
 *
 * Only Meant To Disable Mods, Not Load Them In Order.
 *
 * If Someone Wants To Order Them, Go Right Ahead.
 */
class ModMenuState extends MusicBeatState
{
	public static var eList = []; // enabled mods
	public static var existMods:Array<String> = []; // mods polymod detected in the folder

	private var button:Button; // remove 1 mod
	private var saveMods:Button; // save to file
	private var bg:FlxSprite;
	private var icons:FlxSpriteGroup; // modmenuicons

	override function create()
	{
		super.create();
		#if FEATURE_MODCORE
		existMods = ModCore.getAllMods();
		Polymod.loadOnlyMods(existMods);
		#end
		eList = parseList();
		createMUI();
		createHUI();
		Debug.logTrace('Mods In List ' + eList);
		Debug.logTrace('Avaliable Mods ' + existMods);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.M)
			MusicBeatState.switchState(new MainMenuState());
	}

	function createHUI()
	{
		button = new Button();
		button.x += 400;
		button.text = "Mods";
		button.onClick = function(e)
		{
			eList.pop();
			Debug.logTrace(eList.length);
		}
		saveMods = new Button();
		saveMods.x += 500;
		saveMods.text = "Save Mods";
		saveMods.onClick = function(e)
		{
			var fileStr = '';
			for (mod in eList)
			{
				mod.trim();
				if (fileStr.length > 0)
					fileStr += '\n';

				fileStr += mod;

				Debug.logTrace(fileStr);
			}
			#if FEATURE_FILESYSTEM
			File.saveContent('assets/shared/data/modList.txt', fileStr);
			#end
			Debug.logTrace(eList.length);
		}
		add(button);
		add(saveMods);
	}

	function createMUI()
	{
		icons = new FlxSpriteGroup();
		bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		for (i in 0...existMods.length)
		{
			var modIcon:FlxSprite = new FlxSprite().loadGraphic(Paths.image('missingMod'));
			modIcon.setGraphicSize(Std.int(modIcon.width * 0.25));
			modIcon.updateHitbox();
			modIcon.setPosition(50, 25);
			modIcon.y += 200 * i;
			icons.add(modIcon);
		}
		add(icons);
	}

	public static function parseList()
	{
		var list:Array<String> = [];
		#if FEATURE_MODCORE
		try
		{
			for (mod in existMods)
			{
				// trace('Mod: $mod');
				if (mod.trim().length < 1)
					continue;
				list.push(mod);

				Debug.logTrace(mod);
			}
		}
		catch (e)
		{
			Debug.logTrace(e);
		}
		#end
		return list;
	}
}
#end
