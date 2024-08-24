package kec.backend.chart;

typedef Event =
{
	var name:String;
	var beat:Float;
	var type:String;
	var args:Array<Dynamic>;
	// conversion
	var ?value:Dynamic;
	var ?value2:Dynamic;
	var ?position:Float;
}
