package kec.states;

import lime.app.Application;

class OutdatedSubState extends MusicBeatState
{
	public static var leftState:Bool = false;

	public static var needVer:String = "IDFK LOL";
	public static var currChanges:String = "dk";

	private var bgColors:Array<String> = ['#314d7f', '#4e7093', '#70526e', '#594465'];
	private var colorRotation:Int = 1;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		super.create();
		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stageback', 'shared'));
		bg.screenCenter();
		bg.antialiasing = FlxG.save.data.antialiasing;
		add(bg);

		var txt:FlxText = new FlxText(0, 0, FlxG.width,
			"Your KEC is outdated!\nYou are on "
			+ MainMenuState.kecVer
			+ "\nwhile the most recent version is "
			+ needVer
			+ "."
			+ "\n\nWhat's new:\n\n"
			+ currChanges
			+ "\n\nPress Space to view the full changelog and update\nor ENTER to ignore this",
			32);

		if (MainMenuState.kecVer.contains("PRE-RELEASE"))
			txt.text = "You are on\n"
				+ MainMenuState.kecVer
				+ "\nWhich is a PRE-RELEASE BUILD!"
				+ "\n\nReport all bugs to the author of the pre-release.\nSpace/Escape ignores this.";

		txt.setFormat("VCR OSD Mono", 23, FlxColor.fromRGB(200, 200, 200), CENTER);
		txt.borderColor = FlxColor.BLACK;
		txt.borderSize = 2;
		txt.borderStyle = FlxTextBorderStyle.OUTLINE;
		txt.screenCenter();
		add(txt);

		// 6% chance of MOM appearing instead of KEC
		if (FlxG.random.bool(6) && !MainMenuState.kecVer.contains("PRE-RELEASE"))
			// YOU KNOW WHO ELSE IS OUTDATED? MY MOM!
		{
			var mom:FlxText = new FlxText(0, 0, FlxG.width,
				"Your MOM is outdated!\nYou are on "
				+ MainMenuState.kecVer
				+ "\nwhile the most recent version is "
				+ needVer
				+ "."
				+ "\n\nWhat's new:\n\n"
				+ currChanges
				+ "\n\nPress Space to view the full changelog and update\nor ENTER to ignore this",
				32);

			mom.setFormat("VCR OSD Mono", 23, FlxColor.fromRGB(200, 200, 200), CENTER);
			mom.borderColor = FlxColor.BLACK;
			mom.borderSize = 3;
			mom.borderStyle = FlxTextBorderStyle.OUTLINE;
			mom.screenCenter();
			remove(txt);

			add(mom);
		}

		FlxTween.color(bg, 2, bg.color, FlxColor.fromString(bgColors[colorRotation]));

		new FlxTimer().start(2, function(tmr:FlxTimer)
		{
			FlxTween.color(bg, 2, bg.color, FlxColor.fromString(bgColors[colorRotation]));
			if (colorRotation < (bgColors.length - 1))
				colorRotation++;
			else
				colorRotation = 0;
		}, 0);

		Paths.clearUnusedMemory();
	}

	override function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.SPACE && !MainMenuState.kecVer.contains("PRE-RELEASE"))
		{
			fancyOpenURL("https://therealjake12.github.io/Kade-Engine-Community/changelogs/changelog-" + needVer);
		}
		else if (controls.ACCEPT)
		{
			leftState = true;
			MusicBeatState.switchState(new MainMenuState());
		}
		if (controls.BACK)
		{
			leftState = true;
			MusicBeatState.switchState(new MainMenuState());
		}
		super.update(elapsed);
	}
}
