package stages;

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

		if (weekData.directory == null)
			weekData.directory = 'week${PlayState.storyWeek}';

		return weekData;
	}
}
