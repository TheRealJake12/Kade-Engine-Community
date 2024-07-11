package;

#if macro
import haxe.macro.*;
import haxe.macro.Expr;

/**
 * Macros containing additional help functions to expand HScript capabilities.
 */
class ClassMacro
{
	public static function addAdditionalClasses()
	{
		for (inc in [
			// FLIXEL
			"flixel.util",
			"flixel.ui",
			"flixel.tweens",
			"flixel.tile",
			"flixel.text",
			"flixel.sound",
			"flixel.path",
			"flixel.math",
			"flixel.input",
			"flixel.group",
			"flixel.graphics",
			"flixel.effects",
			"flixel.animation",
			// FLIXEL ADDONS
			"flixel.addons.api",
			"flixel.addons.display",
			"flixel.addons.effects",
			"flixel.addons.text",
			"flixel.addons.tile",
			"flixel.addons.transition",
			"flixel.addons.util",
			// OTHER LIBRARIES & STUFF
			#if VIDEOS "hxvlc.flixel", "hxvlc.openfl", #end
			// BASE HAXE
			"DateTools",
			"EReg",
			"Lambda",
			"StringBuf",
			"haxe.crypto",
			"haxe.display",
			"haxe.exceptions",
			"haxe.extern",
		])
			Compiler.include(inc, ["haxe.ui"]);

		if (Context.defined("sys"))
		{
			for (inc in ["sys", "openfl.net"])
			{
				Compiler.include(inc);
			}
		}

		Compiler.include("kec", [#if !FEATURE_STEPMANIA "kec.backend.util.smTools" #end]);
	}
}
#end
