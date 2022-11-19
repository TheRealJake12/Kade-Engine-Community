package script;

import Type;
import flixel.FlxBasic;
import haxe.CallStack;
import haxe.Json;
import haxe.Log;
import hscript.Expr;
import hscript.Interp;
import hscript.Parser;
import openfl.Lib;
import sys.FileSystem;
import sys.io.File;
import cpp.CPPInterface;

using StringTools;

enum ScriptReturn
{
	PUASE;
	CONTINUE;
}

class Script extends FlxBasic
{
	public var variables(get, null):Map<String, Dynamic>;

	function get_variables()
		return _interp.variables;

	/**
	 *  The last Expr executed
	 *  Used for debugging
	 */
	public var ast(default, null):Expr;

	var _parser:Parser;
	var _interp:Interp;

	public var name:Null<String> = "_hscript";
	public var interacter:Interact;

	var _group:Null<ScriptGroup>;

	public function new()
	{
		super();

		_parser = new Parser();
		_parser.allowTypes = true;
		_parser.allowMetadata = false;
		_parser.allowJSON = false;

		_interp = new Interp();

		interacter = new Interact(this);

		set("new", function() {});
		set("destroy", function() {});
		set("update", (elapsed:Float) -> {});

		set("trace", Reflect.makeVarArgs(function(_)
		{
			Log.trace(Std.string(_.shift()), {
				lineNumber: _interp.posInfos() != null ? _interp.posInfos().lineNumber : -1,
				className: name,
				fileName: name,
				methodName: null,
				customParams: _.length > 0 ? _ : null
			});
		}));

		set("import", function(path:String, ?as:Null<String>)
		{
			try
			{
				if (path == null || path == "")
				{
					error("Path Not Specified!", '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Import Error!');
					return;
				}

				var clas = Type.resolveClass(path);

				if (clas == null)
				{
					error('Class Not Found!\nPath: ${path}', '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Import Error!');
					return;
				}

				var stringName:String = "";

				if (as != null)
					stringName = as;
				else
				{
					var arr = Std.string(clas).split(".");
					stringName = arr[arr.length - 1];
				}

				@:privateAccess
				if (!variables.exists(stringName) && !_interp.locals.exists(stringName))
				{
					set(stringName, clas);

					if (interacter.presetVars != [])
						interacter.presetVars.push(stringName);
				}
				else
				{
					error('$stringName is alreadly a variable in the script, please change the variable to a different name!',
						'${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Import Error!');
				}
			}
			catch (e)
			{
				error('${e}', '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Import Error!');
			}
		});

		set("addScript", function(scriptName:String):Dynamic
		{
			var hx:Null<String> = null;

			for (extn in ScriptUtil.extns)
			{
				var path:String = 'assets/scripts/$scriptName.$extn';

				if (FileSystem.exists(path))
				{
					hx = File.getContent(path);
					break;
				}
			}

			if (hx != null)
			{
				if (_group != null && _group.getScriptByTag(scriptName) == null)
					_group.addScript(scriptName).executeString(hx);
				else
				{
					if (_group == null)
						error('Script group not found!', '$name:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Adding Error!');
					else
						error('$scriptName is alreadly added as a Script!',
							'$name:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Adding Error!');
				}

				return _group.getScriptByTag(scriptName).interacter.getNewObj();
			}
			else
			{
				error('Script "$scriptName" not Found!', '$name:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Adding Error!');
			}
			return null;
		});

		set("getScript", function(scriptName:String):Null<Dynamic>
		{
			if (scriptName == name)
			{
				error('Cannot import current script!', '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Getting Error!');
				return null;
			}

			var script:Null<Script> = _group.getScriptByTag(scriptName);

			if (script != null && script.interacter.presetVars != [])
			{
				return script.interacter.getNewObj();
			}
			else
			{
				if (script == null)
					error('Script "$scriptName" not found!', '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Getting Error!');
				else
				{
					error('Script "$scriptName" is not ready for getting!',
						'${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Script Getting Error!');
				}

				return null;
			}
		});

		set("ScriptReturn", ScriptReturn);
	}

	public inline function get(name:String):Dynamic
	{
		return _interp.variables.get(name);
	}

	public inline function set(name:String, val:Dynamic)
	{
		_interp.variables.set(name, val);
	}

	public function executeFunc(name:String, ?args:Null<Array<Any>>):Null<Dynamic>
	{
		try
		{
			if (_interp == null)
				return null;

			if (_interp.variables.exists(name) && get(name) != null)
			{
				var func = get(name);

				if (func != null && Reflect.isFunction(func))
				{
					if (args != null && args != [])
					{
						return Reflect.callMethod(null, func, args);
					}
					else
					{
						return func();
					}
				}
			}
			return null;
		}
		catch (e)
		{
			error('$e', '${name}:${getCurLine() != null ? Std.string(getCurLine()) : ''}: Function Error');
			return null;
		}
	}

	public function executeString(script:String):Dynamic
	{
		ast = parseScript(script);
		if (ast != null)
			return execute(ast);

		return null;
	}

	function parseScript(script:String):Null<Expr>
	{
		try
		{
			return _parser.parseString(script, name);
		}
		catch (e:Dynamic)
		{
			error('${name}:${_parser.line}: characters ${e.pmin} - ${e.pmax}: ${StringTools.replace(e,'${name}:${_parser.line}:', '')}',
				'${name}:${_parser.line}: Script Parser Error!');
			return null;
		}
	}

	public override function update(elapsed:Float)
	{
		interacter.upadteObjs();

		executeFunc("update", [elapsed]);

		super.update(elapsed);
	}

	function execute(ast:Expr):Dynamic
	{
		try
		{
			interacter.loadPresetVars();

			var val = _interp.execute(ast);
			executeFunc("new");

			interacter.upadteObjs();

			return val;
		}
		catch (e:Dynamic)
		{
			error('$e \n${CallStack.toString(CallStack.exceptionStack())}');
		}
		return null;
	}

	public function error(errorMsg:String, ?winTitle:Null<String>)
	{
		trace(errorMsg);
		#if windows
		CPPInterface.messageBox(errorMsg, winTitle);
		#else
		Lib.application.window.alert(errorMsg, winTitle != null ? winTitle : '${name}: Script Error!');
		#end
	}

	public override function destroy()
	{
		super.destroy();

		executeFunc("destroy");

		_interp = null;
		_parser = null;

		interacter.destroy();
		interacter = null;

		return null;
	}

	function getCurLine():Null<Int>
	{
		return _interp.posInfos() != null ? _interp.posInfos().lineNumber : null;
	}
}
