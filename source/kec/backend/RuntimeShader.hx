package kec.backend;

import flixel.addons.display.FlxRuntimeShader;

class RuntimeShader extends FlxRuntimeShader
{
	public var name = null;

	public function new(name:String, frag:String, vertex:String)
	{
		super(frag, vertex);
		this.name = name;
	}
}
