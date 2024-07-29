package kec.backend;

import kec.backend.util.HelperFunctions;

class Stats
{
	public static var weekScore:Int = 0;
	public static var campaignScore:Int = 0;

	// Amount Of Ratings
	public static var shits:Int = 0;
	public static var bads:Int = 0;
	public static var goods:Int = 0;
	public static var sicks:Int = 0;
	public static var marvs:Int = 0;
    
	// Misses, Campaign Ratings Used For The Score Screen.
	public static var misses:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignMarvs:Int = 0;
	public static var campaignSicks:Int = 0;
	public static var campaignGoods:Int = 0;
	public static var campaignBads:Int = 0;
	public static var campaignShits:Int = 0;
	public static var campaignAccuracy:Float = 0.00;

	// Accuracy. totalNotesHit Used For Accuracy.
	public static var accuracy:Float = 0.00;

	public static var accuracyDefault:Float = 0.00;

	public static var totalNotesHitDefault:Float = 0;
	public static var totalNotesHit:Float = 0;

	public static var totalPlayed:Int = 0;

	// Current Score
	public static var songScore:Int = 0;

	public static function resetStats()
	{
		weekScore = 0;
		campaignScore = songScore = 0;
		shits = bads = goods = sicks = marvs = 0;
		misses = campaignMisses = campaignMarvs = campaignSicks = campaignGoods = campaignBads = campaignShits = 0;
		accuracy = accuracyDefault = totalNotesHitDefault = totalNotesHit = totalPlayed = 0;
		campaignAccuracy = 0;
	}

	public static function addCampaignStats()
	{
		campaignAccuracy += HelperFunctions.truncateFloat(accuracy, 2) / PlayState.instance.initStoryLength;
		campaignMarvs += marvs;
		campaignMisses += misses;
		campaignSicks += sicks;
		campaignGoods += goods;
		campaignBads += bads;
		campaignShits += shits;
	}
}