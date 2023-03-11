using StringTools;

typedef WeekJSON =
{
	var songs:Array<String>;

	var number:Int;
	var characters:Array<String>;
	var weekName:String;
}

class WeekData
{
	public static var weeksLoaded:Map<String, WeekData> = new Map<String, WeekData>();
	public static var weeksList:Array<String> = [];

	public var songs:Array<Dynamic>;
	public var characters:Array<String>;
}
