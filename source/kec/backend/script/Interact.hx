package kec.backend.script;

class Interact extends FlxBasic
{
	public var presetVars:Array<String> = [];

	var parent:Script;

	public var interactObjs:Array<Dynamic> = [];

	public function new(_:Script)
	{
		super();
		parent = _;
	}

	public function loadPresetVars()
	{
		for (str in parent.variables.keys())
		{
			presetVars.push(str);
		}
	}

	public function getNewObj():Dynamic
	{
		var newObj:Dynamic = {};
		interactObjs.push(newObj);

		if (presetVars != [])
		{
			updateObjVars(newObj);
		}

		return newObj;
	}

	public function upadteObjs()
	{
		if (presetVars == [])
			return;

		for (obj in interactObjs)
		{
			if (obj == null)
				continue;

			updateObjVars(obj);
		}
	}

	function updateObjVars(interactObj:Dynamic)
	{
		var newVars:Array<String> = getObjsNewVars(interactObj);
		var varsToUpdate:Map<String, Dynamic> = getVarsToUpdate(interactObj);

		for (varName in newVars)
		{
			try
			{
				@:privateAccess
				var val:Dynamic = parent._interp.resolve(varName);
				Reflect.setProperty(interactObj, varName, val);
			}
			catch (e)
			{
				parent.error("INTERACTION ERROR: " + Std.string(e), '${parent.name}: Interaction Error!');
			}
		}
	}

	function getVarsToUpdate(interactObj:Dynamic):Map<String, Dynamic>
	{
		var newVars:Array<String> = getObjsNewVars(interactObj);

		var varsToUpdate:Map<String, Dynamic> = [];

		if (interactObj != null && interactObj != {})
		{
			for (fieldName in Reflect.fields(interactObj))
			{
				if (!newVars.contains(fieldName))
					continue;
				try
				{
					@:privateAccess
					var curVal:Dynamic = parent._interp.resolve(fieldName);

					if (Reflect.getProperty(interactObj, fieldName) != curVal)
					{
						varsToUpdate.set(fieldName, Reflect.getProperty(interactObj, fieldName));
					}
				}
			}
		}

		return varsToUpdate;
	}

	function getObjsNewVars(interactObj:Dynamic):Array<String>
	{
		if (presetVars == [])
			return [];

		var newVars:Array<String> = [];

		@:privateAccess
		for (map in [parent.variables, parent._interp.locals])
		{
			for (str in map.keys())
			{
				var isScriptCheck:Bool = false;

				@:privateAccess
				var group:Null<ScriptGroup> = parent._group;

				if (group != null)
				{
					var scriptNames:Array<String> = [];

					for (script in group.scripts)
					{
						if (script != parent)
							scriptNames.push(script.name);
					}

					isScriptCheck = scriptNames.contains(str);
				}

				if (!presetVars.contains(str) && !isScriptCheck && !newVars.contains(str))
					newVars.push(str);
			}
		}

		return newVars;
	}
}
