package kec.stages;

typedef StageData =
{
	var ?staticCam:Bool;
	var ?camZoom:Float;
	var ?camPosition:Array<Float>;
	var ?hasGF:Bool;
	var ?positions:Map<String, Array<Float>>;
	var ?directory:String;
}

class StageJSON
{
	public static function loadJSONFile(stage:String):StageData
	{
		var rawJson = Paths.loadJSON('stages/$stage');
		return parseStage(rawJson);
	}

	public static function parseStage(json:Dynamic):StageData
	{
		var weekData:StageData = cast json;

		return weekData;
	}
}
