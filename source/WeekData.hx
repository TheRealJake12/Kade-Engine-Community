import openfl.utils.Assets as OpenFlAssets;

typedef WeekData =
{
	var songs:Array<String>;
	var characters:Array<String>;
	var weekName:String;
	var difficulties:Array<String>;
}

class Week
{
	public static function loadJSONFile(week:String):WeekData
	{
		var rawJson = Paths.loadJSON('weeks/$week');
		return parseWeek(rawJson);
	}

	public static function parseWeek(json:Dynamic):WeekData
	{
		var weekData:WeekData = cast json;

		return weekData;
	}
}
