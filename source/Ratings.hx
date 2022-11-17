import flixel.FlxG;

class Ratings
{
	public static function GenerateComboRank(accuracy:Float) // generate a letter ranking
	{
		var comboranking:String = "N/A";
		if (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods == 0) // Marvelous (SICK) Full Combo
			comboranking = "(MFC)";
		else if (PlayState.misses == 0 && PlayState.bads == 0 && PlayState.shits == 0 && PlayState.goods >= 1) // Good Full Combo (Nothing but Goods & Sicks)
			comboranking = "(GFC)";
		else if (PlayState.misses == 0) // Regular FC
			comboranking = "(FC)";
		else if (PlayState.misses < 10) // Single Digit Combo Breaks
			comboranking = "(SDCB)";
		else
			comboranking = "(Clear)";

		return comboranking;
		// WIFE TIME :)))) (based on Wife3)
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
		else if (PlayStateChangeables.botPlay && !PlayState.loadRep)
			letterRanking = "BotPlay";
		else if (PlayStateChangeables.practiceMode)
			letterRanking = "PRACTICE";
		return letterRanking;
	}

	public static var timingWindows = [];

	public static function judgeNote(noteDiff:Float)
	{
		var diff = Math.abs(noteDiff);
		for (index in 0...timingWindows.length) // based on 4 timing windows, will break with anything else
		{
			var time = timingWindows[index];
			var nextTime = index + 1 > timingWindows.length - 1 ? 0 : timingWindows[index + 1];
			if (diff < time && diff >= nextTime)
			{
				switch (index)
				{
					case 0: // shit
						return "shit";
					case 1: // bad
						return "bad";
					case 2: // good
						return "good";
					case 3: // sick
						return "sick";
					case 4: // marvelous
						return "marv";
				}
			}
		}
		return "good";
	}

	public static function CalculateRanking(score:Int, scoreDef:Int, nps:Int, maxNPS:Int, accuracy:Float):String
	{
		return (FlxG.save.data.npsDisplay ? // NPS Toggle
			"NPS: "
			+ nps
			+ " (Max "
			+ maxNPS
			+ ")"
			+ (!PlayStateChangeables.botPlay || PlayState.loadRep ? " | " : "") : "") + // 	NPS
			(!PlayStateChangeables.botPlay
				|| PlayState.loadRep ? "Score:" + (Conductor.safeFrames != 10 ? score + " (" + scoreDef + ")" : "" + score) + // Score
					(FlxG.save.data.accuracyDisplay ? // Accuracy Toggle
						" | Combo Breaks:"
						+ PlayState.misses // 	Misses/Combo Breaks
						+ (!FlxG.save.data.healthBar ? " | Health:"
							+ (!PlayStateChangeables.opponentMode ? Math.round(PlayState.instance.health * 50) : Math.round(100
								- (PlayState.instance.health * 50)))
							+ "%" : "")
						+ " | Accuracy:"
						+ (PlayStateChangeables.botPlay && !PlayState.loadRep ? "N/A" : HelperFunctions.truncateFloat(accuracy, 2) + " %")
						+ // 	Accuracy
						" | "
						+ GenerateComboRank(accuracy)
						+ " "
						+ (!PlayStateChangeables.practiceMode ? GenerateLetterRank(accuracy) : 'PRACTICE') : "") : ""); // 	Letter Rank
	}
}
