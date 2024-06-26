package kec.substates;

import openfl.Lib;
import kec.backend.Modifiers;
import kec.backend.Controls.Control;
import flash.text.TextField;
import flixel.ui.FlxBar;
import kec.backend.PlayerSettings;

// Uuh... Direct copy of OptionsMenu.hx xD
class ModMenu extends MusicBeatSubstate
{
	public static var instance:ModMenu;

	public var background:FlxSprite;

	public var selectedModifier:Modifier;

	public var selectedModifierIndex = 0;

	public var modifiers:Array<Modifier>;

	public var shownStuff:FlxTypedGroup<FlxText>;

	public static var visibleRange = [114, 640];

	public var menu:FlxTypedGroup<FlxSprite>;

	public var descText:FlxText;
	public var descBack:FlxSprite;
	public var descTop:FlxSprite;

	public var modObjects:FlxTypedGroup<FlxText>;

	public var titleObject:FlxText;

	public var text:FlxText;

	var changedMod = false;

	override function create()
	{
		modObjects = new FlxTypedGroup();

		modifiers = [
			new OpponentMode("Toggle to play as the opponent."),
			new Mirror("Flip Notes horizontally (Up is Down, Left is Right)"),
			new Practice("Skill issue? Try this, and u'll get better :D ."),
			new NoMissesMode("Skill issuen't? Try this, a single miss you die!"),
			new Sustains("Toggle Hold Notes in song chart."),
			new Modchart("Toggle Song Modchart if it has it."),
			new HealthDrain("Toggle Opponent Health Drain when singing."),
			new HealthGain("Toggle how many health you want to gain."),
			new HealthLoss("Toggle how many health you want to loss.")
		];

		titleObject = new FlxText(176, 49, 0, 'GAMEPLAY MODIFIERS');
		titleObject.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		titleObject.borderSize = 3;

		for (i in 0...modifiers.length)
		{
			var mod = modifiers[i];
			text = new FlxText(72, titleObject.y + 72 + (46 * i), 0, mod.getValue());
			text.setFormat(Paths.font("vcr.ttf"), 35, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.borderSize = 3;
			text.borderQuality = 1;
			text.scrollFactor.set();
			text.alpha = 0.4;
			text.visible = true;
			modObjects.add(text);
		}

		instance = this;

		menu = new FlxTypedGroup<FlxSprite>();

		shownStuff = new FlxTypedGroup<FlxText>();

		selectedModifier = modifiers[0];

		background = new FlxSprite(30, 40).makeGraphic(690, 640, FlxColor.BLACK);
		background.alpha = 0.5;
		background.scrollFactor.set();
		menu.add(background);

		descTop = new FlxSprite(30, 39).makeGraphic(690, 55, FlxColor.BLACK);
		descTop.alpha = 0.3;
		descTop.scrollFactor.set();
		menu.add(descTop);

		descBack = new FlxSprite(30, 642).makeGraphic(690, 38, FlxColor.BLACK);
		descBack.alpha = 0.3;
		descBack.scrollFactor.set();
		menu.add(descBack);

		add(menu);
		add(shownStuff);

		descText = new FlxText(62, 648);
		descText.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, FlxTextAlign.LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.borderSize = 2;

		add(descBack);
		add(descText);

		add(titleObject);

		selectedModifier = modifiers[0];

		selectModifier(selectedModifier);

		super.create();
	}

	public function selectModifier(mod:Modifier)
	{
		var object = modObjects.members[selectedModifierIndex];

		try
		{
			visibleRange = [114, 640];

			for (i in 0...modifiers.length)
			{
				var opt = modObjects.members[i];
				opt.y = titleObject.y + 54 + (46 * i);
			}

			while (shownStuff.members.length != 0)
			{
				shownStuff.members.remove(shownStuff.members[0]);
			}

			for (i in modObjects)
				shownStuff.add(i);

			for (i in modObjects.members)
			{
				if (i.y < visibleRange[0] - 24)
					i.alpha = 0;
				else if (i.y > visibleRange[1] - 24)
					i.alpha = 0;
				else
				{
					i.alpha = 0.4;
				}
			}
		}
		catch (e)
		{
			Debug.logError("Fuck.\n" + e);
			selectedModifierIndex = 0;
		}

		selectedModifier = mod;

		object.alpha = 1;

		object.text = "> " + mod.getValue();

		descText.text = mod.getDescription();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var accept = false;
		var right = false;
		var left = false;
		var up = false;
		var down = false;
		var any = false;
		var escape = false;

		changedMod = false;

		accept = FlxG.keys.justPressed.ENTER;
		right = FlxG.keys.justPressed.RIGHT;
		left = FlxG.keys.justPressed.LEFT;
		up = FlxG.keys.justPressed.UP;
		down = FlxG.keys.justPressed.DOWN;

		any = FlxG.keys.justPressed.ANY;
		escape = FlxG.keys.justPressed.ESCAPE;

		#if !mobile
		if (FlxG.mouse.wheel != 0)
		{
			if (FlxG.mouse.wheel < 0)
				down = true;
			else if (FlxG.mouse.wheel > 0)
				up = true;
		}
		#end

		if (selectedModifier != null)
			if (selectedModifier.acceptType)
			{
				if (escape && selectedModifier.waitingType)
				{
					FlxG.sound.play(Paths.sound('scrollMenu'));
					selectedModifier.waitingType = false;
					var object = modObjects.members[selectedModifierIndex];
					object.text = "> " + selectedModifier.getValue();
					return;
				}
				else if (any)
				{
					var object = modObjects.members[selectedModifierIndex];
					selectedModifier.onType(FlxG.keys.getIsDown()[0].ID.toString());
					object.text = "> " + selectedModifier.getValue();
				}
			}

		if (selectedModifier.acceptType || !selectedModifier.acceptType)
		{
			if (accept)
			{
				var prev = selectedModifierIndex;
				var object = modObjects.members[selectedModifierIndex];
				selectedModifier.press();

				if (selectedModifierIndex == prev)
				{
					FlxG.save.flush();

					object.text = "> " + selectedModifier.getValue();
				}
			}

			if (down || controls.DOWN_P)
			{
				if (selectedModifier.acceptType)
					selectedModifier.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
				selectedModifierIndex++;

				// just kinda ignore this math lol

				if (selectedModifierIndex > modifiers.length - 1)
				{
					for (i in 0...modifiers.length)
					{
						var opt = modObjects.members[i];
						opt.y = titleObject.y + 54 + (46 * i);
					}
					selectedModifierIndex = 0;
				}

				if (selectedModifierIndex != 0 && selectedModifierIndex != modifiers.length - 1 && modifiers.length > 6)
				{
					if (selectedModifierIndex >= (modifiers.length - 1) / 2)
						for (i in modObjects.members)
						{
							i.y -= 46;
						}
				}

				selectModifier(modifiers[selectedModifierIndex]);
			}
			else if (up || controls.UP_P)
			{
				if (selectedModifier.acceptType)
					selectedModifier.waitingType = false;
				FlxG.sound.play(Paths.sound('scrollMenu'));
				modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
				selectedModifierIndex--;

				// just kinda ignore this math lol

				if (selectedModifierIndex < 0)
				{
					selectedModifierIndex = modifiers.length - 1;

					if (modifiers.length > 6)
						for (i in modObjects.members)
						{
							i.y -= (46 * ((modifiers.length - 1) / 2));
						}
				}

				if (selectedModifierIndex != 0 && modifiers.length > 6)
				{
					if (selectedModifierIndex >= (modifiers.length - 1) / 2)
						for (i in modObjects.members)
						{
							i.y += 46;
						}
				}

				if (selectedModifierIndex < (modifiers.length - 1) / 2)
				{
					for (i in 0...modifiers.length)
					{
						var opt = modObjects.members[i];
						opt.y = titleObject.y + 54 + (46 * i);
					}
				}

				selectModifier(modifiers[selectedModifierIndex]);
			}

			if (right || controls.RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				var object = modObjects.members[selectedModifierIndex];
				selectedModifier.right();

				FlxG.save.flush();
				changedMod = true;
				object.text = "> " + selectedModifier.getValue();
			}
			else if (left || controls.LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				var object = modObjects.members[selectedModifierIndex];
				selectedModifier.left();
				changedMod = true;
				FlxG.save.flush();

				object.text = "> " + selectedModifier.getValue();
			}
			if (escape || controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));

				PlayerSettings.player1.controls.loadKeyBinds();

				FlxG.state.closeSubState();

				FreeplayState.openMod = false;

				FreeplayState.instance.changeSelection();

				for (i in 0...modifiers.length)
				{
					var opt = modObjects.members[i];
					opt.y = titleObject.y + 54 + (46 * i);
				}
				modObjects.members[selectedModifierIndex].text = selectedModifier.getValue();
				if (modObjects != null)
					for (i in modObjects.members)
					{
						if (i != null)
						{
							if (i.y < visibleRange[0] - 24)
								i.alpha = 0;
							else if (i.y > visibleRange[1] - 24)
								i.alpha = 0;
							else
							{
								i.alpha = 0.4;
							}
						}
					}
			}
			#if !html5
			if (changedMod)
				FreeplayState.instance.updateDiffCalc();
			#end
		}
	}
}
