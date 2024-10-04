package kec.backend;

import flixel.graphics.FlxGraphic;

/**
 * Constant / Globally Used Variables.
 */
class Constants
{
	public static final kecVer:String = 'Kade Engine Community 1.9.4 PRE-RELEASE 3';
	public static final keVer:String = "Kade Engine 1.8.1";
	public static final chartVer:String = "KEC2";
	public static var freakyPlaying:Bool = true;
	public static final textArray:Array<String> = [
		// thanks bolo, I find these ones really funny (I am sorry for stealing code)
		"Yeah I use Kade Engine *insert gay fat guy dancing* (-Bolo)",
		"Kade engine *insert burning PC gif* (-Bolo)",
		"This is my kingdom cum (-Bolo)",
		"God i love futabu!! so fucking much (-McChomk)", // God died in vain 💀
		"Are you really reading this thing? (-Bolo)",
		"I'm not gay, I'm default :trollface: (-Bolo)",
		"I love men (-HomoKori)",
		"Why do I have a pic of Mario with massive tits on my phone? (-Rudy)",
		"Boner (-Red Radiant)",
		"My Balls Itch (-TheRealJake_12)",
		"Sus Sus Amogus (-Mryoyo123YT)",
		"Man I'm Dead (-TheRealJake_12)",
		"Jesse! We Need To Cook Crystal Meth! (-TheRealJake_12)",
		"Also Try BoloVEVO Kade Engine!",
		"The Basement (-TheRealJake_12)",
		#if windows
		'${Sys.environment()["USERNAME"]}! Get down from the tree and put your clothes on, dammit. (-Antonella)',
		#elseif web
		"You're On Web. Why The FUCK Are You On Web. You Can't Get Good Easter Eggs. Mother Fucker.",
		#else
		'${Sys.environment()["USER"]}! Get down from the tree and put your clothes on, dammit. (-Antonella)',
		#end
		'"not working" (-TechDev)',
		"yesd (-TechDev)",
		"JAKEEEEEE (-TechDev)"
	];

	// Noteskin And Notesplash Related Stuff.
	public static var noteskinSprite:String;
	public static var cpuNoteskinSprite:String;
	public static var notesplashSprite:String;
	public static var noteskinPixelSprite:FlxGraphic;
	public static var noteskinPixelSpriteEnds:FlxGraphic;
	public static final defaultBF:String = 'bf';
	public static final defaultOP:String = 'dad';
	public static final defaultGF:String = 'gf';
	// Note Animation Names
	public static final noteColors:Array<String> = ['purple', 'blue', 'green', 'red'];
	// Animation Names
	public static final singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static final discordRpc:String = "898970552600002561";
}
