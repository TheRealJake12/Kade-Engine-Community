package;

import flixel.FlxBasic;
import openfl.Lib;
import hscript.Parser;
import hscript.Interp;
import hscript.Expr;

class Script extends FlxBasic
{
	public var hscript:Interp;

	public static var hscriptreal:Script = null;

	public static var parser:Parser = new Parser();

	public static var scriptName:String = '';

	public override function new(script:String)
	{
		super();
		scriptName = script;
		hscript = new Interp();
	}

	public var variables(get, never):Map<String, Dynamic>;

	public function runScript(script:String)
	{
		var parser = new hscript.Parser();

		parser.allowTypes = true; // Allow typing of variables ex: 'var three:Int = 3;'.
        parser.allowJSON = true; // Allows 'JSON Compatibility' in HScript.
        parser.allowMetadata = true; // Allows Haxe Metadata declarations in HScript.

		try
		{
			var ast = parser.parseString(script);

			hscript.execute(ast);
		}
		catch (e)
		{
			Lib.application.window.alert(e.message, "HSCRIPT ERROR!1111");
		}
	}

	public function get_variables()
	{
		return hscript.variables;
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		Script.parser.line = 1;
		Script.parser.allowTypes = true;
		return hscript.execute(Script.parser.parseString(codeToRun));
	}

	public function setVariable(name:String, val:Dynamic)
	{
		hscript.variables.set(name, val);
	}

	public function getVariable(name:String):Dynamic
	{
		return hscript.variables.get(name);
	}

	public function executeFunc(funcName:String, ?args:Array<Any>):Dynamic
	{
		if (hscript == null)
			return null;

		if (hscript.variables.exists(funcName))
		{
			var func = hscript.variables.get(funcName);
			if (args == null)
			{
				var result = null;
				try
				{
					result = func();
				}
				catch (e)
				{
					Debug.logTrace('$e');
				}
				return result;
			}
			else
			{
				var result = null;
				try
				{
					result = Reflect.callMethod(null, func, args);
				}
				catch (e)
				{
					Debug.logTrace('$e');
				}
				return result;
			}
		}
		return null;
	}

	public function initHaxeModule()
	{
		if(hscriptreal == null)
		{
			Debug.logTrace('initializing haxe interp for: $scriptName');
			hscriptreal = new Script(scriptName); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		}
	}

	public override function destroy()
	{
		super.destroy();
		hscript = null;
	}
}