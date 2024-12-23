package kec.backend.character;

/**
 * Load Character Data NOT The Spritesheet
 */
class CharacterData
{
	public var char:String;
	public var assets:Array<String> = [];
	public var startingAnim:String;
	public var animations:Array<AnimationData>;
	public var icon:String;
	public var charPos:Array<Float> = []; // offset the char position
	public var camPos:Array<Float> = []; // camera position
	public var holdLength:Float; // something something hold extender
	public var barColor:FlxColor;
	public var rgb:Array<Int>;
	public var colorType:String;
	public var flipX:Bool;
	public var flipY:Bool;
	public var scale:Float;
	public var antialiasing:Bool;
	public var atlasType:String;
	public var dances:Bool; // spookeez or gf type dancing
	public var trail:Bool; // spirit trail
	public var replacesGF:Bool;
	public var deadChar:String;
	public var flipAnims:Bool;
	public var isPlayer:Bool;
	public var isGF:Bool;

	public function new(char:String = 'bf', ?isPlayer:Bool = true, isGF:Bool = false)
	{
		this.char = char;
		switch (char)
		{
			default:
				loadFromJson(char, isPlayer, isGF);
		}
	}

	public function loadFromJson(char:String = 'bf', ?isPlayer:Bool = true, isGF:Bool = false)
	{
		var json = Paths.loadJSON('data/characters/$char');
		if (json == null)
		{
			if (isPlayer)
			{
				Debug.logWarn("Couldn't Find JSON For " + char + ". Loading Default Boyfriend.");
				json = Paths.loadJSON('data/characters/${Constants.defaultBF}');
			}
			else if (isGF)
			{
				Debug.logWarn("Couldn't Find JSON For " + char + ". Loading Default GF.");
				json = Paths.loadJSON('data/characters/${Constants.defaultGF}');
			}
			else
			{
				Debug.logWarn("Couldn't Find JSON For " + char + ". Loading Default Opponent.");
				json = Paths.loadJSON('data/characters/${Constants.defaultOP}');
			}
		}

		final data:Data = cast json;

		for (sheet in data.asset)
			assets.push(sheet);
		this.isPlayer = isPlayer;
		atlasType = data.AtlasType == null ? 'SparrowAtlas' : data.AtlasType;
		animations = data.animations; // not a better way to do this.

		replacesGF = data.replacesGF == null ? false : data.replacesGF;
		trail = data.hasTrail == null ? false : data.hasTrail;
		dances = data.isDancing == null ? false : data.isDancing;
		charPos = data.charPos == null ? [0, 0] : data.charPos;
		camPos = data.camPos == null ? [0, 0] : data.camPos;
		holdLength = data.holdLength == null ? 4 : data.holdLength;
		icon = data.healthicon == null ? char : data.healthicon;
		rgb = data.rgbArray == null ? [255, 0, 0] : data.rgbArray;
		deadChar = data.deadChar == null ? 'bf-dead' : data.deadChar;
		flipAnims = data.flipAnimations == null ? false : data.flipAnimations;
		flipX = data.flipX == null ? false : data.flipX;
		antialiasing = data.antialiasing == null ? FlxSprite.defaultAntialiasing : data.antialiasing;
		scale = data.scale == null ? 1 : data.scale;
		barColor = isPlayer ? 0xFF66FF33 : 0xFFFF0000;
		startingAnim = data.startingAnim == null ? 'idle' : data.startingAnim;
		if (data.barType == 'rgb')
			barColor = FlxColor.fromRGB(data.rgbArray[0], data.rgbArray[1], data.rgbArray[2]);
		else
			barColor = FlxColor.fromString(data.barColor);
		return this;
	}
}

typedef Data =
{
	var name:String;
	var asset:Array<String>;
	var startingAnim:String;

	var ?healthicon:String;
	var ?charPos:Array<Float>;
	var ?camPos:Array<Float>;
	var ?holdLength:Float;

	/**
	 * The color of this character's health bar (In HEX).
	 */
	var ?barColor:String;

	var rgbArray:Array<Int>; // Better way of doing the rgb stuff

	/**
	 * Whether we use HEX or RGB for coloring.
	 */
	var ?barType:String;

	var animations:Array<AnimationData>;

	/**
	 * Whether this character is flipped horizontally.
	 * @default false
	 */
	var ?flipX:Bool;

	/**
	 * The scale of this character.
	 * Pixel characters typically use 6.
	 * @default 1
	 */
	var ?scale:Float;

	/**
	 * Whether this character has antialiasing.
	 * @default true
	 */
	var ?antialiasing:Bool;

	/**
	 * What type of Atlas the character uses.
	 * @default SparrowAtlas
	 */
	var ?AtlasType:String;

	/**
	 * Whether this character uses a dancing idle instead of a regular idle.
	 * (ex. gf, spooky)
	 * @default false
	 */
	var ?isDancing:Bool;

	/**
	 * Whether this character has a trail behind them.
	 * @default false
	 */
	var ?hasTrail:Bool;

	/**
	 * Whether this character replaces gf if they are set as dad.
	 * @default false
	 */
	var ?replacesGF:Bool;

	var ?deadChar:String;
	var ?flipAnimations:Bool;
}
