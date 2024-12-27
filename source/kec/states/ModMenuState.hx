package kec.states;

import kec.objects.mod.ModCard;
#if FEATURE_MODCORE
import haxe.ui.components.Button;
import kec.backend.ModCore;
import flixel.group.FlxSpriteGroup;
import polymod.Polymod.ModMetadata;
import polymod.Polymod;
import kec.objects.menu.CoolText;
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
	private var bg:FlxSprite;
	private var modGroup:FlxTypedSpriteGroup<ModCard>;
	private var curSelected:Int = 0;

	override function create()
	{
		super.create();
		ModCore.enabledMods = FlxG.save.data.enabledMods;

		createMUI();
		Debug.logTrace('Avaliable Mods ' + ModCore.modsToLoad);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (controls.UP_P)
			scroll(-1);

		if (controls.DOWN_P)
			scroll(1);

		if (FlxG.mouse.wheel != 0)
		{
			#if desktop
			scroll(-FlxG.mouse.wheel);
			#else
			if (FlxG.mouse.wheel < 0) // HTML5 BRAIN'T
				scroll(1);
			else if (FlxG.mouse.wheel > 0)
				scroll(-1);
			#end
		}

		if (controls.ACCEPT)
			checkMod();

		if (controls.BACK)
			MusicBeatState.switchState(new MainMenuState());
	}

	private function scroll(fard:Int = 0)
	{
		curSelected += fard;
		if (curSelected < 0)
			curSelected = modGroup.length - 1;
		if (curSelected >= modGroup.length)
			curSelected = 0;
		var bullShit:Int = 0;

		for (item in modGroup.members)
		{
			item.targY = bullShit - curSelected;
			bullShit++;
		}
	}

	private function checkMod()
	{
		if (ModCore.enabledMods.contains(ModCore.modsToLoad[curSelected]))
		{
			ModCore.enabledMods.remove(ModCore.modsToLoad[curSelected]);
			modGroup.members[curSelected].alpha = 0.5;
			Debug.logTrace('Disabled Mod : ' + ModCore.modsToLoad[curSelected]);
		}
		else
		{
			ModCore.enabledMods.push(ModCore.modsToLoad[curSelected]);
			modGroup.members[curSelected].alpha = 1;
			Debug.logTrace('Enabled Mod : ' + ModCore.modsToLoad[curSelected]);
		}
	}

	function createMUI()
	{
		modGroup = new FlxTypedSpriteGroup<ModCard>();
		for (i in 0...ModCore.modsToLoad.length)
		{
			modGroup.add(new ModCard(150, 0, i, ModCore.modTitles[i], ModCore.modDescriptions[i]));

			if (!ModCore.enabledMods.contains(ModCore.modsToLoad[i]))
				modGroup.members[i].alpha = 0.5;
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuBGBlue'));
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);
		add(modGroup);
	}

	override function destroy()
	{
		super.destroy();
		FlxG.save.data.enabledMods = ModCore.enabledMods;
		Debug.logTrace(ModCore.enabledMods);
	}
}
#end
