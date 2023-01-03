package;

#if cpp
import cpp.CPPInterface;
#end
import flixel.FlxG;
import flixel.input.gamepad.FlxGamepad;
import openfl.Lib;
import flixel.graphics.FlxGraphic;
#if FEATURE_MULTITHREADING
import sys.thread.Mutex;
#end

class Init extends MusicBeatState
{
    override function create(){
		#if FEATURE_MULTITHREADING
		MasterObjectLoader.mutex = new Mutex();
		#end
        #if windows
		CPPInterface.darkMode();
		#end

		#if cpp
		cpp.NativeGc.enable(true);
		cpp.NativeGc.run(true);
		#end

		#if FEATURE_FILESYSTEM
		if (!sys.FileSystem.exists(Sys.getCwd() + "/assets/replays"))
			sys.FileSystem.createDirectory(Sys.getCwd() + "/assets/replays");
		#end

		if (FlxG.save.data.fpsCap > 420)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(420);
		
		FlxG.mouse.load(Paths.image('curser'));

		FlxG.save.bind('kec' #if (flixel < "5.0.0"), 'therealjake12' #end);

        PlayerSettings.init();

		KadeEngineData.initSave();

		KeyBinds.keyCheck();

		CustomNoteHelpers.Skin.updateNoteskins();
		CustomNoteHelpers.Splash.updateNotesplashes();

		if (FlxG.save.data.volDownBind == null)
			FlxG.save.data.volDownBind = "MINUS";
		if (FlxG.save.data.volUpBind == null)
			FlxG.save.data.volUpBind = "PLUS";

		FlxG.sound.muteKeys = [FlxKey.fromString(Std.string(FlxG.save.data.muteBind))];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volDownBind))];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(Std.string(FlxG.save.data.volUpBind))];	

		FlxG.worldBounds.set(0, 0);

		FlxGraphic.defaultPersist = true;

		MusicBeatState.initSave = true;

		Highscore.load();

        super.create();

		FlxG.autoPause = FlxG.save.data.autoPause;
		FlxG.mouse.visible = true;
    }
    override function update(elapsed:Float){
		if (FlxG.save.data.fpsCap > 420)
			(cast(Lib.current.getChildAt(0), Main)).setFPSCap(420);

		if (FlxG.save.data.borderless)
		{
			FlxG.stage.window.borderless = true;
		}
		else
		{
			FlxG.stage.window.borderless = false;
		}

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

		(cast(Lib.current.getChildAt(0), Main)).setFPSCap(FlxG.save.data.fpsCap);

        FlxG.switchState(new TitleState());
    }
}