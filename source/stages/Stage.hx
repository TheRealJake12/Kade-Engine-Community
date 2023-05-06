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

class Stage extends MusicBeatState
{
	public var curStage:String = '';
	public var ground:FlxSprite;
	public var tankWatchtower:FlxSprite;
	public var tankGround:FlxSprite;
	public var tankmanRun:FlxTypedGroup<TankmenBG>;
	public var foregroundSprites:FlxTypedGroup<TankBGSprite>;

	public static var instance:Stage = null;

	public var camZoom:Float; // The zoom of the camera to have at the start of the game
	public var hideLastBG:Bool = false; // True = hide last BGs and show ones from slowBacks on certain step, False = Toggle visibility of BGs from SlowBacks on certain step
	// Use visible property to manage if BG would be visible or not at the start of the game
	public var tweenDuration:Float = 2; // How long will it tween hiding/showing BGs, variable above must be set to True for tween to activate
	public var toAdd:Array<Dynamic> = []; // Add BGs on stage startup, load BG in by using "toAdd.push(bgVar);"
	// Layering algorithm for noobs: Everything loads by the method of "On Top", example: You load wall first(Every other added BG layers on it), then you load road(comes on top of wall and doesn't clip through it), then loading street lights(comes on top of wall and road)
	public var swagBacks:Map<String,
		Dynamic> = []; // Store BGs here to use them later (for example with slowBacks, using your custom stage event or to adjust position in stage debug menu(press 8 while in PlayState with debug build of the game))
	public var swagGroup:Map<String, FlxTypedGroup<Dynamic>> = []; // Store Groups
	public var animatedBacks:Array<FlxSprite> = []; // Store animated backgrounds and make them play animation(Animation must be named Idle!! Else use swagGroup/swagBacks and script it in stepHit/beatHit function of this file!!)
	public var layInFront:Array<Array<FlxSprite>> = [[], [], []]; // BG layering, format: first [0] - in front of GF, second [1] - in front of opponent, third [2] - in front of boyfriend(and technically also opponent since Haxe layering moment)
	public var slowBacks:Map<Int,
		Array<FlxSprite>> = []; // Change/add/remove backgrounds mid song! Format: "slowBacks[StepToBeActivated] = [Sprites,To,Be,Changed,Or,Added];"
	public var hasGF:Bool = true; // Whether The Stage Has GF In It Or Not.
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// BGs still must be added by using toAdd Array for them to show in game after slowBacks take effect!!
	// All of the above must be set or used in your stage case code block!!
	public var positions:Map<String, Map<String, Array<Int>>> = [
		// Assign your characters positions on stage here!
		'halloween' => ['spooky' => [100, 300], 'monster' => [100, 200]],
		'philly' => ['pico' => [100, 400]],
		'limo' => ['bf-car' => [1030, 230]],
		'mall' => ['bf-christmas' => [970, 450], 'parents-christmas' => [-400, 100]],
		'mallEvil' => ['bf-christmas' => [1090, 450], 'monster-christmas' => [100, 150]],
		'school' => [
			'gf-pixel' => [580, 430],
			'bf-pixel' => [970, 670],
			'senpai' => [250, 460],
			'senpai-angry' => [250, 460]
		],
		'schoolEvil' => ['gf-pixel' => [580, 430], 'bf-pixel' => [970, 670], 'spirit' => [-50, 200]],
		'tank' => [
			'tankman' => [50, 225],
			'bf' => [850, 400],
			'bf-holding-gf' => [850, 370],
			'gftank' => [330, 110],
			'pico-speaker' => [330, 165]
		]
	];

	public function new(daStage:String)
	{
		super();

		this.curStage = daStage;
		camZoom = 1.05; // Don't change zoom here, unless you want to change zoom of every stage that doesn't have custom one

		if (!FlxG.save.data.optimize && FlxG.save.data.background)
		{
			switch (daStage)
			{
				case 'halloween':
					{
						if (FlxG.save.data.distractions)
						{
							var hallowTex = Paths.getSparrowAtlas('halloween_bg', 'week2');

							var halloweenBG = new FlxSprite(-200, -80);
							halloweenBG.frames = hallowTex;
							halloweenBG.animation.addByPrefix('idle', 'halloweem bg0');
							halloweenBG.animation.addByPrefix('lightning', 'halloweem bg lightning strike', Std.int(24 * PlayState.songMultiplier), false);
							halloweenBG.animation.play('idle');
							halloweenBG.antialiasing = FlxG.save.data.antialiasing;
							swagBacks['halloweenBG'] = halloweenBG;
							toAdd.push(halloweenBG);
						}
						else
						{
							var halloweenBG = new FlxSprite(-200, -80).loadGraphic(Paths.image('halloween_bg_low', 'week2'));
							halloweenBG.antialiasing = FlxG.save.data.antialiasing;
							swagBacks['halloweenBG'] = halloweenBG;
							toAdd.push(halloweenBG);
						}
						PlayState.instance.precacheThing('thunder_1', 'sound', 'shared');
						PlayState.instance.precacheThing('thunder_2', 'sound', 'shared');
					}
				case 'philly':
					{
						var bg:FlxSprite = new FlxSprite(-100).loadGraphic(Paths.image('philly/sky', 'week3'));
						bg.scrollFactor.set(0.1, 0.1);
						bg.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var city:FlxSprite = new FlxSprite(-10).loadGraphic(Paths.image('philly/city', 'week3'));
						city.scrollFactor.set(0.3, 0.3);
						city.setGraphicSize(Std.int(city.width * 0.85));
						city.updateHitbox();
						city.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['city'] = city;
						toAdd.push(city);

						var phillyCityLights = new FlxTypedGroup<FlxSprite>();
						if (FlxG.save.data.distractions)
						{
							swagGroup['phillyCityLights'] = phillyCityLights;
							toAdd.push(phillyCityLights);
						}

						for (i in 0...5)
						{
							var light:FlxSprite = new FlxSprite(city.x).loadGraphic(Paths.image('philly/win' + i, 'week3'));
							light.scrollFactor.set(0.3, 0.3);
							light.visible = false;
							light.setGraphicSize(Std.int(light.width * 0.85));
							light.updateHitbox();
							light.antialiasing = FlxG.save.data.antialiasing;
							phillyCityLights.add(light);
						}

						var streetBehind:FlxSprite = new FlxSprite(-40, 50).loadGraphic(Paths.image('philly/behindTrain', 'week3'));
						streetBehind.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['streetBehind'] = streetBehind;
						toAdd.push(streetBehind);

						var phillyTrain = new FlxSprite(2000, 360).loadGraphic(Paths.image('philly/train', 'week3'));
						phillyTrain.antialiasing = FlxG.save.data.antialiasing;
						if (FlxG.save.data.distractions)
						{
							swagBacks['phillyTrain'] = phillyTrain;
							toAdd.push(phillyTrain);
						}

						trainSound = new FlxSound().loadEmbedded(Paths.sound('train_passes', 'shared'));
						FlxG.sound.list.add(trainSound);

						// var cityLights:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.win0.png);

						var street:FlxSprite = new FlxSprite(-40, streetBehind.y).loadGraphic(Paths.image('philly/street', 'week3'));
						street.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['street'] = street;
						toAdd.push(street);
					}
				case 'limo':
					{
						camZoom = 0.90;

						var skyBG:FlxSprite = new FlxSprite(-120, -50).loadGraphic(Paths.image('limo/limoSunset', 'week4'));
						skyBG.scrollFactor.set(0.1, 0.1);
						skyBG.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['skyBG'] = skyBG;
						toAdd.push(skyBG);

						var bgLimo:FlxSprite = new FlxSprite(-200, 480);
						bgLimo.frames = Paths.getSparrowAtlas('limo/bgLimo', 'week4');
						bgLimo.animation.addByPrefix('drive', "background limo pink", Std.int(24 * PlayState.songMultiplier));
						bgLimo.animation.play('drive');
						bgLimo.scrollFactor.set(0.4, 0.4);
						bgLimo.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['bgLimo'] = bgLimo;
						toAdd.push(bgLimo);

						var fastCar:FlxSprite;
						fastCar = new FlxSprite(-300, 160).loadGraphic(Paths.image('limo/fastCarLol', 'week4'));
						fastCar.antialiasing = FlxG.save.data.antialiasing;
						fastCar.visible = false;
						var grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();

						if (FlxG.save.data.distractions)
						{
							swagGroup['grpLimoDancers'] = grpLimoDancers;
							toAdd.push(grpLimoDancers);

							for (i in 0...5)
							{
								var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 130, bgLimo.y - 400);
								dancer.scrollFactor.set(0.4, 0.4);
								grpLimoDancers.add(dancer);
								swagBacks['dancer' + i] = dancer;
							}

							swagBacks['fastCar'] = fastCar;
							layInFront[2].push(fastCar);
							resetFastCar();
						}

						var overlayShit:FlxSprite = new FlxSprite(-500, -600).loadGraphic(Paths.image('limo/limoOverlay', 'week4'));
						overlayShit.alpha = 0.5;
						// add(overlayShit);

						// var shaderBullshit = new BlendModeEffect(new OverlayShader(), FlxColor.RED);

						// FlxG.camera.setFilters([new ShaderFilter(cast shaderBullshit.shader)]);

						// overlayShit.shader = shaderBullshit;

						var limoTex = Paths.getSparrowAtlas('limo/limoDrive', 'week4');

						var limo = new FlxSprite(-120, 550);
						limo.frames = limoTex;
						limo.animation.addByPrefix('drive', "Limo stage", 24);
						limo.animation.play('drive');
						limo.antialiasing = FlxG.save.data.antialiasing;
						layInFront[0].push(limo);
						swagBacks['limo'] = limo;

						if (!FlxG.save.data.distractions)
						{
							grpLimoDancers.kill();
							grpLimoDancers.destroy();
							fastCar.kill();
							fastCar.destroy();
						}
					}
				case 'mall':
					{
						camZoom = 0.80;

						var bg:FlxSprite = new FlxSprite(-1000, -500).loadGraphic(Paths.image('christmas/bgWalls', 'week5'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.2, 0.2);
						bg.active = false;
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var upperBoppers = new FlxSprite(-240, -90);
						upperBoppers.frames = Paths.getSparrowAtlas('christmas/upperBop', 'week5');
						upperBoppers.animation.addByPrefix('idle', "Upper Crowd Bob", Std.int(24 * PlayState.songMultiplier), false);
						upperBoppers.antialiasing = FlxG.save.data.antialiasing;
						upperBoppers.scrollFactor.set(0.33, 0.33);
						upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
						upperBoppers.updateHitbox();
						if (FlxG.save.data.distractions)
						{
							swagBacks['upperBoppers'] = upperBoppers;
							toAdd.push(upperBoppers);
							animatedBacks.push(upperBoppers);
						}

						var bgEscalator:FlxSprite = new FlxSprite(-1100, -600).loadGraphic(Paths.image('christmas/bgEscalator', 'week5'));
						bgEscalator.antialiasing = FlxG.save.data.antialiasing;
						bgEscalator.scrollFactor.set(0.3, 0.3);
						bgEscalator.active = false;
						bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
						bgEscalator.updateHitbox();
						swagBacks['bgEscalator'] = bgEscalator;
						toAdd.push(bgEscalator);

						var tree:FlxSprite = new FlxSprite(370, -250).loadGraphic(Paths.image('christmas/christmasTree', 'week5'));
						tree.antialiasing = FlxG.save.data.antialiasing;
						tree.scrollFactor.set(0.40, 0.40);
						swagBacks['tree'] = tree;
						toAdd.push(tree);

						var bottomBoppers = new FlxSprite(-300, 140);
						bottomBoppers.frames = Paths.getSparrowAtlas('christmas/bottomBop', 'week5');
						bottomBoppers.animation.addByPrefix('idle', 'Bottom Level Boppers', Std.int(24 * PlayState.songMultiplier), false);
						bottomBoppers.antialiasing = FlxG.save.data.antialiasing;
						bottomBoppers.scrollFactor.set(0.9, 0.9);
						bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
						bottomBoppers.updateHitbox();
						if (FlxG.save.data.distractions)
						{
							swagBacks['bottomBoppers'] = bottomBoppers;
							toAdd.push(bottomBoppers);
							animatedBacks.push(bottomBoppers);
						}

						var fgSnow:FlxSprite = new FlxSprite(-600, 700).loadGraphic(Paths.image('christmas/fgSnow', 'week5'));
						fgSnow.active = false;
						fgSnow.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['fgSnow'] = fgSnow;
						toAdd.push(fgSnow);

						var santa = new FlxSprite(-840, 150);
						santa.frames = Paths.getSparrowAtlas('christmas/santa', 'week5');
						santa.animation.addByPrefix('idle', 'santa idle in fear', Std.int(24 * PlayState.songMultiplier), false);
						santa.antialiasing = FlxG.save.data.antialiasing;
						if (FlxG.save.data.distractions)
						{
							swagBacks['santa'] = santa;
							toAdd.push(santa);
							animatedBacks.push(santa);
						}
						if (!FlxG.save.data.distractions)
						{
							upperBoppers.kill();
							bottomBoppers.kill();
							upperBoppers.destroy();
							bottomBoppers.destroy();
						}
					}
				case 'mallEvil':
					{
						var bg:FlxSprite = new FlxSprite(-400, -500).loadGraphic(Paths.image('christmas/evilBG', 'week5'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.2, 0.2);
						bg.active = false;
						bg.setGraphicSize(Std.int(bg.width * 0.8));
						bg.updateHitbox();
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var evilTree:FlxSprite = new FlxSprite(300, -300).loadGraphic(Paths.image('christmas/evilTree', 'week5'));
						evilTree.antialiasing = FlxG.save.data.antialiasing;
						evilTree.scrollFactor.set(0.2, 0.2);
						swagBacks['evilTree'] = evilTree;
						toAdd.push(evilTree);

						var evilSnow:FlxSprite = new FlxSprite(-200, 700).loadGraphic(Paths.image("christmas/evilSnow", 'week5'));
						evilSnow.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['evilSnow'] = evilSnow;
						toAdd.push(evilSnow);
					}
				case 'school':
					{
						// defaultCamZoom = 0.9;

						var bgSky = new FlxSprite().loadGraphic(Paths.image('weeb/weebSky', 'week6'));
						bgSky.scrollFactor.set(0.1, 0.1);
						swagBacks['bgSky'] = bgSky;
						toAdd.push(bgSky);

						var repositionShit = -200;

						var bgSchool:FlxSprite = new FlxSprite(repositionShit, 0).loadGraphic(Paths.image('weeb/weebSchool', 'week6'));
						bgSchool.scrollFactor.set(0.6, 0.90);
						swagBacks['bgSchool'] = bgSchool;
						toAdd.push(bgSchool);

						var bgStreet:FlxSprite = new FlxSprite(repositionShit).loadGraphic(Paths.image('weeb/weebStreet', 'week6'));
						bgStreet.scrollFactor.set(0.95, 0.95);
						swagBacks['bgStreet'] = bgStreet;
						toAdd.push(bgStreet);

						var fgTrees:FlxSprite = new FlxSprite(repositionShit + 170, 130).loadGraphic(Paths.image('weeb/weebTreesBack', 'week6'));
						fgTrees.scrollFactor.set(0.9, 0.9);
						swagBacks['fgTrees'] = fgTrees;
						toAdd.push(fgTrees);

						var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
						var treetex = Paths.getPackerAtlas('weeb/weebTrees', 'week6');
						bgTrees.frames = treetex;
						bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18],
							Std.int(12 * PlayState.songMultiplier));
						bgTrees.animation.play('treeLoop');
						bgTrees.scrollFactor.set(0.85, 0.85);
						swagBacks['bgTrees'] = bgTrees;
						toAdd.push(bgTrees);

						var treeLeaves:FlxSprite = new FlxSprite(repositionShit, -40);
						treeLeaves.frames = Paths.getSparrowAtlas('weeb/petals', 'week6');
						treeLeaves.animation.addByPrefix('leaves', 'PETALS ALL', Std.int(24 * PlayState.songMultiplier), true);
						treeLeaves.animation.play('leaves');
						treeLeaves.scrollFactor.set(0.85, 0.85);
						swagBacks['treeLeaves'] = treeLeaves;
						toAdd.push(treeLeaves);

						var widShit = Std.int(bgSky.width * 6);

						bgSky.setGraphicSize(widShit);
						bgSchool.setGraphicSize(widShit);
						bgStreet.setGraphicSize(widShit);
						bgTrees.setGraphicSize(Std.int(widShit * 1.4));
						fgTrees.setGraphicSize(Std.int(widShit * 0.8));
						treeLeaves.setGraphicSize(widShit);

						fgTrees.updateHitbox();
						bgSky.updateHitbox();
						bgSchool.updateHitbox();
						bgStreet.updateHitbox();
						bgTrees.updateHitbox();
						treeLeaves.updateHitbox();

						if (FlxG.save.data.distractions)
						{
							var bgGirls = new BackgroundGirls(-100, 190);
							bgGirls.scrollFactor.set(0.9, 0.9);
							bgGirls.setGraphicSize(Std.int(bgGirls.width * CoolUtil.daPixelZoom));
							if (PlayState.SONG.songId == 'roses')
								bgGirls.getScared();
							bgGirls.updateHitbox();
							swagBacks['bgGirls'] = bgGirls;
							toAdd.push(bgGirls);
						}
					}
				case 'schoolEvil':
					{
						var waveEffectBG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 3, 2);
						var waveEffectFG = new FlxWaveEffect(FlxWaveMode.ALL, 2, -1, 5, 2);

						var posX = 400;
						var posY = 200;

						var bg:FlxSprite = new FlxSprite(posX, posY);
						bg.frames = Paths.getSparrowAtlas('weeb/animatedEvilSchool', 'week6');
						bg.animation.addByPrefix('idle', 'background 2', Std.int(PlayState.songMultiplier * 24));
						bg.animation.play('idle');
						bg.scrollFactor.set(0.8, 0.9);
						bg.scale.set(6, 6);
						swagBacks['bg'] = bg;
						toAdd.push(bg);
					}
				case 'tank':
					camZoom = 0.9;
					var tankSky:FlxSprite = new FlxSprite(-400, -400).loadGraphic(Paths.image('tankSky', 'week7'));
					tankSky.antialiasing = FlxG.save.data.antialiasing;
					tankSky.scrollFactor.set(0, 0);
					swagBacks['tankSky'] = tankSky;
					toAdd.push(tankSky);
					if (FlxG.save.data.distractions)
					{
						var tankClouds:FlxSprite = new FlxSprite(FlxG.random.int(-700, -100),
							FlxG.random.int(-20, 20)).loadGraphic(Paths.image('tankClouds', 'week7'));
						tankClouds.antialiasing = FlxG.save.data.antialiasing;
						tankClouds.scrollFactor.set(0.9, 0.9);
						swagBacks['tankClouds'] = tankClouds;
						toAdd.push(tankClouds);

						var tankMountains:FlxSprite = new FlxSprite(-300, -20).loadGraphic(Paths.image('tankMountains', 'week7'));
						tankMountains.antialiasing = FlxG.save.data.antialiasing;
						tankMountains.setGraphicSize(Std.int(1.2 * tankMountains.width));
						tankMountains.scrollFactor.set(0.2, 0.2);
						tankMountains.updateHitbox();

						swagBacks['tankMountains'] = tankMountains;
						toAdd.push(tankMountains);

						var tankBuildings:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('tankBuildings', 'week7'));

						tankBuildings.setGraphicSize(Std.int(1.1 * tankBuildings.width));
						tankBuildings.scrollFactor.set(0.3, 0.3);
						tankBuildings.antialiasing = FlxG.save.data.antialiasing;
						tankBuildings.updateHitbox();
						swagBacks['tankBuildings'] = tankBuildings;
						toAdd.push(tankBuildings);
					}

					var tankRuins:FlxSprite = new FlxSprite(-200, 0).loadGraphic(Paths.image('tankRuins', 'week7'));
					tankRuins.setGraphicSize(Std.int(1.1 * tankRuins.width));
					tankRuins.antialiasing = FlxG.save.data.antialiasing;
					tankRuins.scrollFactor.set(0.35, 0.35);
					tankRuins.updateHitbox();
					swagBacks['tankRuins'] = tankRuins;
					toAdd.push(tankRuins);

					if (FlxG.save.data.distractions)
					{
						var smokeLeft:FlxSprite = new FlxSprite(-200, -100);
						smokeLeft.antialiasing = FlxG.save.data.antialiasing;
						smokeLeft.scrollFactor.set(0.4, 0.4);
						smokeLeft.frames = Paths.getSparrowAtlas('smokeLeft', 'week7');
						smokeLeft.animation.addByPrefix('idle', 'SmokeBlurLeft instance ', Std.int(24 * PlayState.songMultiplier), true);
						smokeLeft.animation.play('idle');
						swagBacks['smokeLeft'] = smokeLeft;
						toAdd.push(smokeLeft);

						var smokeRight:FlxSprite = new FlxSprite(1100, -100);
						smokeRight.antialiasing = FlxG.save.data.antialiasing;
						smokeRight.scrollFactor.set(0.4, 0.4);
						smokeRight.frames = Paths.getSparrowAtlas('smokeRight', 'week7');
						smokeRight.animation.addByPrefix('idle', 'SmokeRight instance ', Std.int(24 * PlayState.songMultiplier), true);
						smokeRight.animation.play('idle');
						swagBacks['smokeRight'] = smokeRight;
						toAdd.push(smokeRight);

						var tankWatchTower:FlxSprite = new FlxSprite(0, 50);
						tankWatchTower.antialiasing = FlxG.save.data.antialiasing;
						tankWatchTower.scrollFactor.set(0.5, 0.5);
						tankWatchTower.frames = Paths.getSparrowAtlas('tankWatchtower', 'week7');
						tankWatchTower.animation.addByPrefix('idle', 'watchtower gradient color instance ', Std.int(24 * PlayState.songMultiplier));
						tankWatchTower.animation.play('idle');
						tankWatchTower.active = true;
						swagBacks['tankWatchTower'] = tankWatchTower;
						toAdd.push(tankWatchTower);
					}
					var tankGround:FlxSprite = new FlxSprite(300, 300);
					tankGround.scrollFactor.set(0.5, 0.5);
					tankGround.antialiasing = FlxG.save.data.antialiasing;
					tankGround.frames = Paths.getSparrowAtlas('tankRolling', 'week7');
					tankGround.animation.addByPrefix('idle', 'BG tank w lighting instance ', Std.int(24 * PlayState.songMultiplier), true);
					tankGround.animation.play('idle');
					swagBacks['tankGround'] = tankGround;
					toAdd.push(tankGround);

					var tankmanRun = new FlxTypedGroup<TankmenBG>();
					swagBacks['tankmanRun'] = tankmanRun;
					toAdd.push(tankmanRun);

					var tankField:FlxSprite = new FlxSprite(-420, -150).loadGraphic(Paths.image('tankGround', 'week7'));
					tankField.antialiasing = FlxG.save.data.antialiasing;
					tankField.setGraphicSize(Std.int(1.15 * tankField.width));
					tankField.updateHitbox();
					swagBacks['tankField'] = tankField;
					toAdd.push(tankField);

					if (PlayState.isStoryMode)
					{
						if (PlayState.SONG.songId == 'stress' && !FlxG.save.data.stressMP4)
						{
							var dummyGf:FlxSprite = new FlxSprite(200, 105);
							dummyGf.antialiasing = FlxG.save.data.antialiasing;
							dummyGf.frames = Paths.getSparrowAtlas('characters/gfTankmen', 'shared');
							dummyGf.animation.addByPrefix('idle', 'GF Dancing at Gunpoint', 24, false);
							dummyGf.animation.play('idle');
							swagBacks['dummyGf'] = dummyGf;
							layInFront[2].push(dummyGf);

							var gfCutscene:FlxSprite = new FlxSprite(200, 85);
							gfCutscene.antialiasing = FlxG.save.data.antialiasing;
							gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF', 'week7');
							gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
							gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
							gfCutscene.visible = false;
							swagBacks['gfCutscene'] = gfCutscene;
							layInFront[2].push(gfCutscene);

							var picoCutscene:FlxSprite = new FlxSprite(-552, -298);
							picoCutscene.antialiasing = FlxG.save.data.antialiasing;
							swagBacks['picoCutscene'] = picoCutscene;
							picoCutscene.frames = Paths.getTextureAtlas('cutscenes/stressPico', 'week7');
							picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
							picoCutscene.visible = false;

							toAdd.push(picoCutscene);

							var bfCutscene:FlxSprite = new FlxSprite(815, 500);
							bfCutscene.antialiasing = FlxG.save.data.antialiasing;
							bfCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND', 'shared');
							bfCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
							bfCutscene.animation.play('idle', true);
							swagBacks['bfCutscene'] = bfCutscene;
							layInFront[2].push(bfCutscene);
						}

						var tankman:FlxSprite = new FlxSprite();

						switch (PlayState.SONG.songId)
						{
							case 'ugh':
								tankman.setPosition(10, PlayState.dad.y + 110);
							case 'guns':
								tankman.setPosition(50, 230);
							case 'stress':
								tankman.setPosition(-77, 307);
						}

						tankman.frames = Paths.getSparrowAtlas('cutscenes/' + PlayState.SONG.songId, 'week7');
						tankman.antialiasing = FlxG.save.data.antialiasing;
						swagBacks['tankman'] = tankman;
						if (!FlxG.save.data.stressMP4)
						{
							layInFront[2].push(tankman);
						}
					}

					var foreGround0 = new FlxSprite(-500, 600);
					foreGround0.scrollFactor.set(1.7, 1.5);
					foreGround0.antialiasing = FlxG.save.data.antialiasing;
					foreGround0.frames = Paths.getSparrowAtlas('tank0', 'week7');
					foreGround0.animation.addByPrefix('idle', 'fg tankhead far right instance ', Std.int(24 * PlayState.songMultiplier));
					foreGround0.animation.play('idle');
					swagBacks['foreGround0'] = foreGround0;
					layInFront[2].push(foreGround0);

					if (FlxG.save.data.distractions)
					{
						var foreGround1 = new FlxSprite(-300, 750);
						foreGround1.scrollFactor.set(2, 0.2);
						foreGround1.antialiasing = FlxG.save.data.antialiasing;
						foreGround1.frames = Paths.getSparrowAtlas('tank1', 'week7');
						foreGround1.animation.addByPrefix('idle', 'fg tankhead 5 instance ', Std.int(24 * PlayState.songMultiplier));
						foreGround1.animation.play('idle');
						swagBacks['foreGround1'] = foreGround1;
						layInFront[2].push(foreGround1);
					}

					var foreGround2 = new FlxSprite(450, 940);
					foreGround2.scrollFactor.set(1.5, 1.5);
					foreGround2.antialiasing = FlxG.save.data.antialiasing;
					foreGround2.frames = Paths.getSparrowAtlas('tank2', 'week7');
					foreGround2.animation.addByPrefix('idle', 'foreground man 3 instance ', Std.int(24 * PlayState.songMultiplier));
					foreGround2.animation.play('idle');
					swagBacks['foreGround2'] = foreGround2;
					layInFront[2].push(foreGround2);

					if (FlxG.save.data.distractions)
					{
						var foreGround3 = new FlxSprite(1300, 900);
						foreGround3.scrollFactor.set(1.5, 1.5);
						foreGround3.antialiasing = FlxG.save.data.antialiasing;
						foreGround3.frames = Paths.getSparrowAtlas('tank4', 'week7');
						foreGround3.animation.addByPrefix('idle', 'fg tankman bobbin 3 instance ', Std.int(24 * PlayState.songMultiplier));
						foreGround3.animation.play('idle');
						swagBacks['foreGround3'] = foreGround3;
						layInFront[2].push(foreGround3);
					}

					var foreGround4 = new FlxSprite(1620, 710);
					foreGround4.scrollFactor.set(1.5, 1.5);
					foreGround4.antialiasing = FlxG.save.data.antialiasing;
					foreGround4.frames = Paths.getSparrowAtlas('tank5', 'week7');
					foreGround4.animation.addByPrefix('idle', 'fg tankhead far right instance ', Std.int(24 * PlayState.songMultiplier));
					foreGround4.animation.play('idle');
					swagBacks['foreGround4'] = foreGround4;
					layInFront[2].push(foreGround4);

					if (FlxG.save.data.distractions)
					{
						var foreGround5 = new FlxSprite(1400, 1290);
						foreGround5.scrollFactor.set(3.5, 2.5);
						foreGround5.antialiasing = FlxG.save.data.antialiasing;
						foreGround5.frames = Paths.getSparrowAtlas('tank3', 'week7');
						foreGround5.animation.addByPrefix('idle', 'fg tankhead 4 instance ', Std.int(24 * PlayState.songMultiplier));
						foreGround5.animation.play('idle');
						swagBacks['foreGround5'] = foreGround5;
						layInFront[2].push(foreGround5);
					}
				case 'void': // In case you want to do chart with videos.
					camZoom = 0.9;
					curStage = 'void';
					var black:FlxSprite = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
					black.scrollFactor.set(0, 0);
					toAdd.push(black);

				case 'stage':
					{
						camZoom = 0.9;
						curStage = 'stage';
						var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.9, 0.9);
						bg.active = false;
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
						stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
						stageFront.updateHitbox();
						stageFront.antialiasing = FlxG.save.data.antialiasing;
						stageFront.scrollFactor.set(0.9, 0.9);
						stageFront.active = false;
						swagBacks['stageFront'] = stageFront;
						toAdd.push(stageFront);

						if (FlxG.save.data.distractions)
						{
							var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
							stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
							stageCurtains.updateHitbox();
							stageCurtains.antialiasing = FlxG.save.data.antialiasing;
							stageCurtains.scrollFactor.set(1.3, 1.3);
							stageCurtains.active = false;

							swagBacks['stageCurtains'] = stageCurtains;
							toAdd.push(stageCurtains);
						}
					}

				default:
					{
						camZoom = 0.9;
						curStage = 'stage';
						var bg:FlxSprite = new FlxSprite(-600, -200).loadGraphic(Paths.image('stageback', 'shared'));
						bg.antialiasing = FlxG.save.data.antialiasing;
						bg.scrollFactor.set(0.9, 0.9);
						bg.active = false;
						swagBacks['bg'] = bg;
						toAdd.push(bg);

						var stageFront:FlxSprite = new FlxSprite(-650, 600).loadGraphic(Paths.image('stagefront', 'shared'));
						stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
						stageFront.updateHitbox();
						stageFront.antialiasing = FlxG.save.data.antialiasing;
						stageFront.scrollFactor.set(0.9, 0.9);
						stageFront.active = false;
						swagBacks['stageFront'] = stageFront;
						toAdd.push(stageFront);

						if (FlxG.save.data.distractions)
						{
							var stageCurtains:FlxSprite = new FlxSprite(-500, -300).loadGraphic(Paths.image('stagecurtains', 'shared'));
							stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
							stageCurtains.updateHitbox();
							stageCurtains.antialiasing = FlxG.save.data.antialiasing;
							stageCurtains.scrollFactor.set(1.3, 1.3);
							stageCurtains.active = false;

							swagBacks['stageCurtains'] = stageCurtains;
							toAdd.push(stageCurtains);
						}
					}
			}
		}
	}

	override public function update(elapsed:Float)
	{
		if (!FlxG.save.data.optimize && FlxG.save.data.background)
		{
			switch (curStage)
			{
				case 'philly':
					if (trainMoving)
					{
						trainFrameTiming += elapsed;

						if (trainFrameTiming >= 1 / 24)
						{
							updateTrainPos();
							trainFrameTiming = 0;
						}
					}
				// phillyCityLights.members[curLight].alpha -= (Conductor.crochet / 1000) * FlxG.elapsed;
				case 'tank':
					moveTank();
			}
		}
		super.update(elapsed);
	}

	override function stepHit()
	{
		super.stepHit();

		if (!PlayStateChangeables.Optimize)
		{
			var array = slowBacks[curStep];
			if (array != null && array.length > 0)
			{
				if (hideLastBG)
				{
					for (bg in swagBacks)
					{
						if (!array.contains(bg))
						{
							var tween = FlxTween.tween(bg, {alpha: 0}, tweenDuration, {
								onComplete: function(tween:FlxTween):Void
								{
									bg.visible = false;
								}
							});
						}
					}
					for (bg in array)
					{
						bg.visible = true;
						FlxTween.tween(bg, {alpha: 1}, tweenDuration);
					}
				}
				else
				{
					for (bg in array)
						bg.visible = !bg.visible;
				}
			}
		}
	}

	override function beatHit()
	{
		super.beatHit();

		if (FlxG.save.data.distractions && animatedBacks.length > 0)
		{
			for (bg in animatedBacks)
				bg.animation.play('idle', true);
		}

		if (!PlayStateChangeables.Optimize && FlxG.save.data.background)
		{
			switch (curStage)
			{
				case 'halloween':
					if (FlxG.random.bool(Conductor.bpm > 320 ? 100 : 10) && curBeat > lightningStrikeBeat + lightningOffset)
					{
						if (FlxG.save.data.distractions)
						{
							lightningStrikeShit();
						}
					}
				case 'school':
					if (FlxG.save.data.distractions)
					{
						swagBacks['bgGirls'].dance();
					}
				case 'limo':
					if (FlxG.save.data.distractions)
					{
						swagGroup['grpLimoDancers'].forEach(function(dancer:BackgroundDancer)
						{
							dancer.dance();
						});

						if (FlxG.random.bool(10) && fastCarCanDrive)
							fastCarDrive();
					}
				case "philly":
					if (FlxG.save.data.distractions)
					{
						if (!trainMoving)
							trainCooldown += 1;

						if (curBeat % 4 == 0)
						{
							var phillyCityLights = swagGroup['phillyCityLights'];
							phillyCityLights.forEach(function(light:FlxSprite)
							{
								light.visible = false;
							});

							curLight = FlxG.random.int(0, phillyCityLights.length - 1);

							phillyCityLights.members[curLight].visible = true;
							// phillyCityLights.members[curLight].alpha = 1;
						}
					}

					if (curBeat % 8 == 4 && FlxG.random.bool(Conductor.bpm > 320 ? 150 : 30) && !trainMoving && trainCooldown > 8)
					{
						if (FlxG.save.data.distractions)
						{
							trainCooldown = FlxG.random.int(-4, 0);
							trainStart();
						}
					}
			}
		}
	}

	// Variables and Functions for Stages
	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;
	var curLight:Int = 0;

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.soundRandom('thunder_', 1, 2, 'shared'));
		swagBacks['halloweenBG'].animation.play('lightning');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (PlayState.boyfriend != null)
		{
			PlayState.boyfriend.playAnim('scared', true);
			PlayState.gf.playAnim('scared', true);
		}
		else
		{
			GameplayCustomizeState.boyfriend.playAnim('scared', true);
			GameplayCustomizeState.gf.playAnim('scared', true);
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;
	var trainSound:FlxSound;

	function trainStart():Void
	{
		if (FlxG.save.data.distractions)
		{
			trainMoving = true;
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
	{
		if (FlxG.save.data.distractions)
		{
			if (trainSound.time >= 4700)
			{
				startedMoving = true;

				if (PlayState.gf != null)
					PlayState.gf.playAnim('hairBlow');
				else
					GameplayCustomizeState.gf.playAnim('hairBlow');
			}

			if (startedMoving)
			{
				var phillyTrain = swagBacks['phillyTrain'];
				phillyTrain.x -= 400;

				if (phillyTrain.x < -2000 && !trainFinishing)
				{
					phillyTrain.x = -1150;
					trainCars -= 1;

					if (trainCars <= 0)
						trainFinishing = true;
				}

				if (phillyTrain.x < -4000 && trainFinishing)
					trainReset();
			}
		}
	}

	function trainReset():Void
	{
		if (FlxG.save.data.distractions)
		{
			if (PlayState.gf != null)
				PlayState.gf.playAnim('hairFall');
			else
				GameplayCustomizeState.gf.playAnim('hairFall');

			swagBacks['phillyTrain'].x = FlxG.width + 200;
			trainMoving = false;
			// trainSound.stop();
			// trainSound.time = 0;
			trainCars = 8;
			trainFinishing = false;
			startedMoving = false;
		}
	}

	var fastCarCanDrive:Bool = true;

	function resetFastCar():Void
	{
		if (FlxG.save.data.distractions)
		{
			var fastCar = swagBacks['fastCar'];
			fastCar.x = -12600;
			fastCar.y = FlxG.random.int(140, 250);
			fastCar.velocity.x = 0;
			fastCar.visible = false;
			fastCarCanDrive = true;
		}
	}

	function fastCarDrive()
	{
		if (FlxG.save.data.distractions)
		{
			FlxG.sound.play(Paths.soundRandom('carPass', 0, 1, 'shared'), 0.7);

			swagBacks['fastCar'].visible = true;
			swagBacks['fastCar'].velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
			fastCarCanDrive = false;
			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				resetFastCar();
			});
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	function moveTank():Void
	{
		tankAngle += FlxG.elapsed * tankSpeed * PlayState.songMultiplier;
		// Worst fix I've ever done in my life. I hope this doesn't make lag stutters.
		if (!PlayState.instance.endingSong)
			PlayState.instance.createTween(swagBacks['tankGround'], {angle: tankAngle - 90 + 15}, 0.01, {type: FlxTweenType.ONESHOT});
		swagBacks['tankGround'].x = tankX + 1500 * FlxMath.fastCos(FlxAngle.asRadians(tankAngle + 180));
		swagBacks['tankGround'].y = 1300 + 1100 * FlxMath.fastSin(FlxAngle.asRadians(tankAngle + 180));
	}
}
