package;

import kec.util.FilterUtils;
#if cpp
import kec.backend.cpp.CPPInterface;
#end
import openfl.Lib;
import flixel.graphics.FlxGraphic;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;

class Init extends MusicBeatState
{
	override function create()
	{
		#if windows
		CPPInterface.darkMode();
		#end

		Paths.initialize();

		FlxG.save.bind('kec' #if (flixel < "5.0.0"), 'therealjake12' #end);

		kec.backend.PlayerSettings.init();

		kec.backend.KadeEngineData.initSave();

		kec.backend.KeyBinds.keyCheck();
		FilterUtils.initializeFilters();
		kec.backend.Discord.load();

		FilterUtils.setColorBlindess(FlxG.save.data.colorblind);

		// Gotta run this before any assets get loaded.
		kec.backend.ModCore.initialize();

		kec.util.NoteStyleHelper.updateNoteskins();
		kec.util.NoteStyleHelper.updateNotesplashes();

		if (FlxG.save.data.volDownBind == null)
			FlxG.save.data.volDownBind = "MINUS";
		if (FlxG.save.data.volUpBind == null)
			FlxG.save.data.volUpBind = "PLUS";

		FlxG.sound.muteKeys = [FlxKey.fromString(Std.string(FlxG.save.data.muteBind))];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volDownBind))];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volUpBind))];

		FlxG.worldBounds.set(0, 0);

		FlxG.mouse.load('assets/shared/images/curser.png');

		kec.util.Highscore.load();

		FlxG.autoPause = FlxG.save.data.autoPause;
		FlxG.mouse.visible = true;

		switch (FlxG.save.data.resolution)
		{
			case 0:
				FlxG.resizeWindow(640, 360);
				FlxG.resizeGame(640, 360);
			case 1:
				FlxG.resizeWindow(768, 432);
				FlxG.resizeGame(768, 432);
			case 2:
				FlxG.resizeWindow(896, 504);
				FlxG.resizeGame(896, 504);
			case 3:
				FlxG.resizeWindow(1024, 576);
				FlxG.resizeGame(1024, 576);
			case 4:
				FlxG.resizeWindow(1152, 648);
				FlxG.resizeGame(1152, 648);
			case 5:
				FlxG.resizeWindow(1280, 720);
				FlxG.resizeGame(1280, 720);
			case 6:
				FlxG.resizeWindow(1920, 1080);
				FlxG.resizeGame(1920, 1080);
		}

		super.create();

		FlxG.switchState(new TitleState());
	}
}
