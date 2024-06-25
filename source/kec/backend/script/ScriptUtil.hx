package kec.backend.script;

import StringTools;
import flixel.graphics.FlxGraphic;
import flixel.system.FlxAssets.FlxShader;
import haxe.Json;
import openfl.Lib;
import openfl.filters.ShaderFilter;
import openfl.system.Capabilities;
import kec.backend.script.Script.ScriptReturn;
import flixel.addons.display.FlxRuntimeShader;
#if FEATURE_FILESYSTEM
import sys.FileSystem;
import sys.io.File;
#end
import kec.objects.Character;
import kec.objects.Note;
import kec.objects.StaticArrow;
import kec.objects.NoteSplash;
import kec.backend.chart.Conductor;
import kec.backend.chart.Section;
import kec.backend.chart.Song;
import kec.backend.util.CoolUtil;
import kec.backend.util.Highscore;

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

		#if FEATURE_FILESYSTEM
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
		script.set("ShaderFitler", ShaderFilter);

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

		// Shaders
		script.set("FlxShader", FlxShader);
		script.set("FlxRuntimeShader", FlxRuntimeShader);

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
		script.set("WeekData", WeekData.Week);
		script.set("Highscore", Highscore);
		script.set("Stage", kec.stages.Stage);

		// Assets
		script.set("Paths", Paths);

		// Song
		script.set("Song", Song);
		script.set("Section", Section);
		script.set("Conductor", Conductor);

		// Objects
		script.set("Note", Note);
		script.set("StaticArrow", StaticArrow);
		script.set("NoteSplash", NoteSplash);
		script.set("Character", Character);
	}

	public static inline function hasPause(arr:Array<Dynamic>):Bool
	{
		return arr.contains(ScriptReturn.PUASE);
	}
}
