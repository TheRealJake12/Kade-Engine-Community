package kec.backend;

import kec.backend.PlayStateChangeables;
import kec.backend.util.HelperFunctions;

class Ratings
{
	public static var timingWindows:Array<RatingWindow> = [];

	public static function GenerateComboRank(accuracy:Float) // generate a letter ranking
	{
		var comboranking:String = "";

		if (PlayState.misses == 0)
		{
			var reverseWindows = timingWindows.copy();
			reverseWindows.reverse();
			for (rate in reverseWindows)
			{
				if (rate.count > 0)
				{
					comboranking = '(${rate.comboRanking})';
				}
			}
		}
		else if (PlayState.misses < 10) // Single Digit Combo Breaks
			comboranking = "(SDCB)";
		else
			comboranking = "(Clear)";
		return comboranking;
	}

	public static function GenerateLetterRank(accuracy:Float)
	{
		var letterRanking:String = "";
		var wifeConditions:Array<Bool> = [
			accuracy >= 99.9935, // AAAAA
			accuracy >= 99.980, // AAAA:
			accuracy >= 99.970, // AAAA.
			accuracy >= 99.955, // AAAA
			accuracy >= 99.90, // AAA:
			accuracy >= 99.80, // AAA.
			accuracy >= 99.70, // AAA
			accuracy >= 99, // AA:
			accuracy >= 96.50, // AA.
			accuracy >= 93, // AA
			accuracy >= 90, // A:
			accuracy >= 85, // A.
			accuracy >= 80, // A
			accuracy >= 70, // B
			accuracy >= 60, // C
			accuracy < 60 // D
		];

		for (i in 0...wifeConditions.length)
		{
			var b = wifeConditions[i];

			if (b)
			{
				switch (i)
				{
					case 0:
						letterRanking += "AAAAA";
					case 1:
						letterRanking += "AAAA:";
					case 2:
						letterRanking += "AAAA.";
					case 3:
						letterRanking += "AAAA";
					case 4:
						letterRanking += "AAA:";
					case 5:
						letterRanking += "AAA.";
					case 6:
						letterRanking += "AAA";
					case 7:
						letterRanking += "AA:";
					case 8:
						letterRanking += "AA.";
					case 9:
						letterRanking += "AA";
					case 10:
						letterRanking += "A:";
					case 11:
						letterRanking += "A.";
					case 12:
						letterRanking += "A";
					case 13:
						letterRanking += "B";
					case 14:
						letterRanking += "C";
					case 15:
						letterRanking += "D";
				}
				break;
			}
		}
		if (accuracy == 0 && !PlayStateChangeables.practiceMode)
			letterRanking = "N/A";
		else if (PlayStateChangeables.botPlay)
			letterRanking = "BotPlay";
		else if (PlayStateChangeables.practiceMode)
			letterRanking = "PRACTICE";
		return letterRanking;
	}

	public static function judgeNote(noteDiff:Float):RatingWindow
	{
		var diff = Math.abs(noteDiff);

		var shitWindows:Array<RatingWindow> = timingWindows.copy();
		shitWindows.reverse();

		if (PlayStateChangeables.botPlay)
			return shitWindows[0];

		for (index in 0...shitWindows.length)
		{
			if (diff <= shitWindows[index].timingWindow)
			{
				return shitWindows[index];
			}
		}
		return shitWindows[shitWindows.length - 1];
	}

	public static function CalculateRanking(score:Int, scoreDef:Int, nps:Int, maxNPS:Int, accuracy:Float):String
	{
		return (FlxG.save.data.npsDisplay ? // NPS Toggle
			"NPS: "
			+ nps
			+ " (Max "
			+ maxNPS
			+ ")"
			+ (!PlayStateChangeables.botPlay ? " | " : "") : "") + // 	NPS
			(!PlayStateChangeables.botPlay ? "Score:" + score + // Score
				(FlxG.save.data.accuracyDisplay ? // Accuracy Toggle
					" | Combo Breaks:"
					+ PlayState.misses // 	Misses/Combo Breaks
					+ (!FlxG.save.data.healthBar ? " | Health:"
						+ (!PlayStateChangeables.opponentMode ? Math.round(PlayState.instance.health * 50) : Math.round(100 - (PlayState.instance.health * 50)))
						+ "%" : "")
					+ " | Accuracy:"
					+ (PlayStateChangeables.botPlay ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %")
					+ // 	Accuracy
					" | "
					+ GenerateComboRank(accuracy)
					+ " "
					+ (!PlayStateChangeables.practiceMode ? GenerateLetterRank(accuracy) : 'PRACTICE') : "") : ""); // 	Letter Rank
	}
}

class RatingWindow
{
	public var name:String;
	public var timingWindow:Float;
	public var displayColor:FlxColor;
	public var healthBonus:Float;
	public var scoreBonus:Float;
	public var defaultTimingWindow:Float;
	public var causeMiss:Bool;
	public var doNoteSplash:Bool;
	public var count:Int = 0;
	public var accuracyBonus:Float;

	public var pluralSuffix:String;

	public var comboRanking:String;

	public function new(name:String, timingWindow:Float, comboRanking:String, displayColor:FlxColor, healthBonus:Float, scoreBonus:Float, accuracyBonus:Float,
			causeMiss:Bool, doNoteSplash:Bool)
	{
		this.name = name;
		this.timingWindow = timingWindow;
		this.comboRanking = comboRanking;
		this.displayColor = displayColor;
		this.healthBonus = healthBonus;
		this.scoreBonus = scoreBonus;
		this.accuracyBonus = accuracyBonus;
		this.causeMiss = causeMiss;
		this.doNoteSplash = doNoteSplash;
	}

	public static function createRatings(judgeStyle:Null<String>):Void
	{
		Ratings.timingWindows = [];

		switch (judgeStyle.toLowerCase())
		{
			default:
				var ratings:Array<String> = ['Shit', 'Bad', 'Good', 'Sick', 'Marv'];
				var timings:Array<Float> = [
					FlxG.save.data.shitMs,
					FlxG.save.data.badMs,
					FlxG.save.data.goodMs,
					FlxG.save.data.sickMs,
					FlxG.save.data.marvMs
				];
				var colors:Array<FlxColor> = [FlxColor.RED, FlxColor.RED, FlxColor.GREEN, FlxColor.WHITE, FlxColor.CYAN];
				var acc:Array<Float> = [-1.00, 0.5, 0.75, 1.00, 1.00];

				var healthBonuses:Array<Float> = [-0.2, -0.06, 0, 0.04, 0.06];
				var scoreBonuses:Array<Int> = [-300, 0, 200, 350, 350];
				var defaultTimings:Array<Float> = [100.0, 95.0, 75.0, 35.0, 20.0];
				var missArray:Array<Bool> = [false, false, false, false, false];
				var splashArray:Array<Bool> = [false, false, false, true, true];
				var suffixes:Array<String> = ['s', 's', 's', 's', 's'];
				var combos:Array<String> = ['', 'FC', 'GFC', 'PFC', 'MFC'];
				for (i in 0...ratings.length)
				{
					var rClass = new RatingWindow(ratings[i], timings[i], combos[i], colors[i], healthBonuses[i], scoreBonuses[i], acc[i], missArray[i],
						splashArray[i]);
					rClass.defaultTimingWindow = defaultTimings[i];
					rClass.pluralSuffix = suffixes[i];
					Ratings.timingWindows.push(rClass);
				}
				// its bad to have defaults for shit like this. esp for modcore compat
		}

		if (Ratings.timingWindows.length == 0)
			createRatings(null);
	}
}
