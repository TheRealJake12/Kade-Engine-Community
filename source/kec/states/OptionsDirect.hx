package kec.states;

import flixel.addons.transition.FlxTransitionableState;
import kec.backend.util.NoteStyleHelper;

class OptionsDirect extends MusicBeatState
{
	override function create()
	{
		var menuBG:FlxSprite;
		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		FlxG.camera.fade(FlxColor.BLACK, 0.6, true);

		if (MainMenuState.freakyPlaying)
		{
			FlxG.sound.playMusic(Paths.music('options'));
			MainMenuState.freakyPlaying = false;
		}

		persistentUpdate = false;

		menuBG = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		menuBG.color = 0xFF2F2F2F;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.antialiasing;
		add(menuBG);

		NoteStyleHelper.updateNoteskins();
		NoteStyleHelper.updateNotesplashes();

		openSubState(new kec.substates.OptionsMenu());
	}
}
