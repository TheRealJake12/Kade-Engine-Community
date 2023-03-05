import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

class OptionsDirect extends MusicBeatState
{
	override function create()
	{
		var menuBG:FlxSprite;
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		FlxG.camera.fade(FlxColor.BLACK, 0.6, true);

		if (FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('optionsmenu'));
		}
		else if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('optionsmenu'));
		}

		persistentUpdate = false;

		menuBG = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.antialiasing;
		add(menuBG);

		CustomNoteHelpers.Skin.updateNoteskins();
		CustomNoteHelpers.Splash.updateNotesplashes();

		openSubState(new OptionsMenu());
	}
}
