package kec.states;

import kec.util.NoteStyleHelper;

class OptionsDirect extends MusicBeatState
{
	var menuBG:FlxSprite;

	public static var instance:OptionsDirect = null;

	override function create()
	{
		instance = this;
		Paths.clearCache();
		FlxG.camera.fade(FlxColor.BLACK, 0.6, true);

		if (Constants.freakyPlaying)
		{
			FlxG.sound.playMusic(Paths.music('options'));
			Constants.freakyPlaying = false;
		}

		persistentUpdate = false;

		pushSub(new kec.substates.OptionsMenu());
		menuBG = new FlxSprite().loadGraphic(Paths.image("menuDesat"));
		menuBG.color = 0xFF2F2F2F;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.antialiasing;
		add(menuBG);

		NoteStyleHelper.updateNoteskins();
		NoteStyleHelper.updateNotesplashes();

		super.create();

		openSubState(subStates[0]);
	}
}
