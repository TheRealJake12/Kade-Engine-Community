package stages;

import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxBasic;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import openfl.filters.ShaderFilter;
import flixel.util.FlxColor;
import openfl.display.BlendMode;
import flixel.math.FlxMath;
import flixel.math.FlxAngle;

#if FEATURE_HSCRIPT
import script.Script;
import script.ScriptGroup;
import script.ScriptUtil;
#end

class NewStage extends MusicBeatState
{
	public var curStage:String = '';
    public static var instance:Stage = null;
    public var camZoom:Float; // The zoom of the camera to have at the start of the game
    public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
    public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
    // Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
    public var swagBacks:Map<String,
	Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
    public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
    public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
    public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
    public var slowBacks:Map<Int,
	Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"
    public var positions:Map<String, Map<String, Array<Int>>> = []; // Tryna make it work with hscript
    var stages:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/stageList'));
    var loadedStages:Array<String> = null;



	#if FEATURE_HSCRIPT
	// Hscript stages
	public var scriptedStages:ScriptGroup;
	#end

    public function new(daStage:String){
        super();
        daStage = curStage;

        if (camZoom == null)
		    camZoom = 0.9;

        if (curStage == null)
            curStage = 'stage';

        for (i in stages)
        {
			var thing = Paths.hscript('stages/' + curStage);
			Debug.logTrace(curStage);
        }

    }

    override function add()
    {
		scriptedStages.executeAllFunc("create");
        super.add();
    }
}