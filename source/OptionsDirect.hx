import flixel.addons.transition.FlxTransitionableState;
import flixel.FlxG;
import flixel.FlxSprite;

class OptionsDirect extends MusicBeatState
{
	override function create()
	{
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('optionsmenu'));
		}
		else if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('optionsmenu'));
		}

		persistentUpdate = false;

		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.loadImage("menuDesat"));
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
