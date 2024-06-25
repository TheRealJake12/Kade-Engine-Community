package kec.backend.script;

class ScriptGroup extends FlxBasic
{
	public var scripts:Array<Script> = [];

	public var onAddScript:Array<Script->Void> = [];

	public override function new()
	{
		super();
	}

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		for (_ in scripts)
		{
			if (_ != null)
				_.update(elapsed);
		}
	}

	public function addScript(tag:Null<String>):Script
	{
		var script:Script = ScriptUtil.getBasicScript();
		ScriptUtil.setUpFlixelScript(script);
		ScriptUtil.setUpFNFScript(script);

		@:privateAccess
		script._group = this;

		if (tag != null)
		{
			script.set("name", tag);
			script.name = tag;
		}
		else
		{
			var i:Int = 0;
			for (script in scripts)
			{
				if (script == null)
					continue;

				if (script.name.toLowerCase().contains("_hscript"))
					i++;
			}

			script.set("name", '_hscript$i');
			script.name = '_hscript$i';
		}

		for (func in onAddScript)
		{
			if (func == null)
				continue;
			func(script);
		}

		scripts.push(script);

		return script;
	}

	public function executeAllFunc(name:String, ?args:Array<Any>):Array<Dynamic>
	{
		var returns:Array<Dynamic> = [];

		for (_ in scripts)
		{
			if (_ == null)
				continue;

			returns.push(_.executeFunc(name, args));
		}

		return returns;
	}

	public function setAll(name:String, val:Dynamic)
	{
		for (_ in scripts)
		{
			if (_ == null)
				continue;

			_.set(name, val);
		}
	}

	public function getAll(name:String):Array<Dynamic>
	{
		var returns:Array<Dynamic> = [];

		for (_ in scripts)
		{
			if (_ == null)
				continue;

			returns.push(_.get(name));
		}

		return returns;
	}

	public function getScriptByTag(tag:String):Null<Script>
	{
		for (_ in scripts)
		{
			if (_ == null)
				continue;

			if (_.name != null && _.name == tag)
				return _;
		}

		return null;
	}

	public override function destroy()
	{
		super.destroy();

		for (_ in scripts)
		{
			if (_ == null)
				continue;

			_.destroy();
			_ = null;
		}

		scripts = [];
	}
}
