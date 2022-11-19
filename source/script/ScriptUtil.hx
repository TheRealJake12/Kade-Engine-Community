package script;

import StringTools;
import Highscore;
import Paths;
import flixel.FlxBasic;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxAssets.FlxShader;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import haxe.Json;
import Boyfriend;
import Character;
import Note;
import StaticArrow;
import openfl.Lib;
import openfl.filters.ShaderFilter;
import openfl.system.Capabilities;
import script.Script.ScriptReturn;
import Conductor;
import Section;
import Song;
import PlayState;
import CoolUtil;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class ScriptUtil
{
	public static final extns:Array<String> = ["hx", "hscript", "hsc", "hxs"];

	public static function getBasicScript():Script
	{
		var script = new Script();

		// Main Class
		script.set("Main", Main);

		// Haxe Classes
		script.set("Std", Std);
		script.set("Type", Type);
		script.set("Reflect", Reflect);
		script.set("Math", Math);
		script.set("StringTools", StringTools);
		script.set("Json", {parse: Json.parse, stringify: Json.stringify});

		#if sys
		script.set("FileSystem", FileSystem);
		script.set("File", File);
		script.set("Sys", Sys);
		#end

		return script;
	}

	public static function setUpFlixelScript(script:Script)
	{
		if (script == null)
			return;

		// OpenFL
		script.set("Lib", Lib);
		script.set("Capabilities", Capabilities);
		// Basic Stuff
		script.set("state", FlxG.state);
		script.set("camera", FlxG.camera);
		script.set("FlxG", FlxG);

		script.set("add", function(obj:FlxBasic)
		{
			FlxG.state.add(obj);
		});

		script.set("insert", function(postion:Int, obj:FlxBasic)
		{
			FlxG.state.insert(postion, obj);
		});

		script.set("remove", function(obj:FlxBasic)
		{
			FlxG.state.remove(obj);
		});

		script.set("FlxBasic", FlxBasic);
		script.set("FlxObject", FlxObject);

		// Sprites
		script.set("FlxSprite", FlxSprite);
		script.set("FlxGraphic", FlxGraphic);

		// Tweens
		script.set("FlxTween", FlxTween);
		script.set("FlxEase", FlxEase);

		// Timer
		script.set("FlxTimer", FlxTimer);

		// FlxText
		script.set("FlxText", FlxText);
		script.set("FlxTextFormat", FlxTextFormat);
		script.set("FlxTextFormatMarkerPair", FlxTextFormatMarkerPair);
		script.set("FlxTextBorderStyle", FlxTextBorderStyle);

		// Color Functions
		script.set("colorFromRGB", function(Red:Int, Green:Int, Blue:Int, Alpha:Int = 255)
		{
			return FlxColor.fromRGB(Red, Green, Blue, Alpha);
		});

		script.set("colorFromString", function(str:String)
		{
			return FlxColor.fromString(str);
		});

		// Sounds
		script.set("FlxSound", FlxSound);
	}

	public static function setUpFNFScript(script:Script)
	{
		if (script == null)
			return;

		// Save Data
		script.set("Highscore", Highscore);

		// Assets
		script.set("Paths", Paths);

		// Song
		script.set("Song", Song);
		script.set("Section", Section);
		script.set("Conductor", Conductor);

		// Objects
		script.set("Note", Note);
		script.set("StaticArrow", StaticArrow);
		script.set("Character", Character);
		script.set("Boyfriend", Boyfriend);
	}

	public static inline function findScriptsInDir(path:String, ?deepSearch:Bool = true):Array<String>
	{
		return CoolUtil.findFilesInPath(path, ["hx", "hscript", "hsc", "hxs"], true);
	}

	public static inline function hasPause(arr:Array<Dynamic>):Bool
	{
		return arr.contains(ScriptReturn.PUASE);
	}
}
