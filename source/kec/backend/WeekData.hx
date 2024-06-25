package kec.backend;

typedef WeekData =
{
	var songs:Array<String>;
	var characters:Array<String>;
	var weekName:String;
	var difficulties:Array<String>;
	var ?background:String;
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
