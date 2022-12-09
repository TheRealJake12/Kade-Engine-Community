package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import Section.SwagSection;
import flixel.util.FlxSort;
import stages.TankmenBG;

using StringTools;

class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var animInterrupt:Map<String, Bool>;
	public var animNext:Map<String, String>;
	public var animDanced:Map<String, Bool>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = 'bf';
	public var barColor:FlxColor;

	public var holdTimer:Float = 0;

	public var replacesGF:Bool;
	public var hasTrail:Bool;
	public var isDancing:Bool;
	public var holdLength:Float;
	public var charPos:Array<Int>;
	public var camPos:Array<Int>;
	public var camFollow:Array<Int>;

	public static var animationNotes:Array<Note> = [];

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false)
	{
		super(x, y);

		barColor = isPlayer ? 0xFF66FF33 : 0xFFFF0000;
		animOffsets = new Map<String, Array<Dynamic>>();
		animInterrupt = new Map<String, Bool>();
		animNext = new Map<String, String>();
		animDanced = new Map<String, Bool>();
		curCharacter = character;
		this.isPlayer = isPlayer;

		switch (character){
			default:
			parseDataFile();
		}
		

		if (isPlayer && frames != null)
		{
			flipX = !flipX;

			// Doesn't flip for BF, since his are already in the right place???
			if (!curCharacter.startsWith('bf'))
			{
				// var animArray
				var oldRight = animation.getByName('singRIGHT').frames;
				animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
				animation.getByName('singLEFT').frames = oldRight;

				// IF THEY HAVE MISS ANIMATIONS??
				if (animation.getByName('singRIGHTmiss') != null)
				{
					var oldMiss = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldMiss;
				}
			}
		}
	}

	function parseDataFile()
	{
		Debug.logInfo('Generating character (${curCharacter}) from JSON data...');

		// Load the data from JSON and cast it to a struct we can easily read.
		var jsonData = Paths.loadJSON('characters/${curCharacter}');
		if (jsonData == null)
		{
			Debug.logError('Failed to parse JSON data for character ${curCharacter}. Loading default characters...');
			if (FlxG.fullscreen)
				FlxG.fullscreen = !FlxG.fullscreen;
			if (isPlayer)
			{
				Debug.logError('Failed to parse JSON data for character  ${curCharacter}. Loading default boyfriend...');
				jsonData = Paths.loadJSON('characters/bf');
			}
			else if (replacesGF)
			{
				Debug.logError('Failed to parse JSON data for character  ${curCharacter}. Loading default boyfriend...');
				jsonData = Paths.loadJSON('characters/gf');
			}
			else
			{
				Debug.logError('Failed to parse JSON data for character  ${curCharacter}. Loading default boyfriend...');
				jsonData = Paths.loadJSON('characters/dad');
			}
		}

		var data:CharacterData = cast jsonData;

		if (!FlxG.save.data.optimize)
		{
			var tex:FlxFramesCollection;

			if (data.AtlasType == 'PackerAtlas')
				tex = Paths.getPackerAtlas(data.asset, 'shared');
			else if (data.AtlasType == 'TextureAtlas')
				tex = Paths.getTextureAtlas(data.asset, 'shared');
			else if (data.AtlasType == 'JsonAtlas')
				tex = Paths.getJSONAtlas(data.asset, 'shared');
			else
				tex = Paths.getSparrowAtlas(data.asset, 'shared');

			frames = tex;
			if (frames != null)
				for (anim in data.animations)
				{
					var frameRate = anim.frameRate == null ? 24 : anim.frameRate;
					var looped = anim.looped == null ? false : anim.looped;
					var flipX = anim.flipX == null ? false : anim.flipX;
					var flipY = anim.flipY == null ? false : anim.flipY;

					if (anim.frameIndices != null)
					{
						animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", Std.int(frameRate * PlayState.songMultiplier), looped, flipX,
							flipY);
					}
					else
					{
						animation.addByPrefix(anim.name, anim.prefix, Std.int(frameRate * PlayState.songMultiplier), looped, flipX, flipY);
					}

					animOffsets[anim.name] = anim.offsets == null ? [0, 0] : anim.offsets;
					animInterrupt[anim.name] = anim.interrupt == null ? true : anim.interrupt;

					if (data.isDancing && anim.isDanced != null)
						animDanced[anim.name] = anim.isDanced;

					if (anim.nextAnim != null)
						animNext[anim.name] = anim.nextAnim;
				}

			this.replacesGF = data.replacesGF == null ? false : data.replacesGF;
			this.hasTrail = data.hasTrail == null ? false : data.hasTrail;
			this.isDancing = data.isDancing == null ? false : data.isDancing;
			this.charPos = data.charPos == null ? [0, 0] : data.charPos;
			this.camPos = data.camPos == null ? [0, 0] : data.camPos;
			this.camFollow = data.camFollow == null ? [0, 0] : data.camFollow;
			this.holdLength = data.holdLength == null ? 4 : data.holdLength;

			flipX = data.flipX == null ? false : data.flipX;

			if (data.scale != null)
			{
				setGraphicSize(Std.int(width * data.scale));
				updateHitbox();
			}

			antialiasing = data.antialiasing == null ? FlxG.save.data.antialiasing : data.antialiasing;

			playAnim(data.startingAnim);
		}

		barColor = FlxColor.fromString(data.barColor);
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null)
		{
			if (!isPlayer)
			{
				if (!PlayStateChangeables.opponentMode)
				{
					if (animation.curAnim.name.startsWith('sing'))
					{
						holdTimer += elapsed;
					}

					if (holdTimer >= Conductor.stepCrochet * 0.0011 * holdLength * PlayState.songMultiplier)
					{
						dance();

						holdTimer = 0;
					}
				}
				else
				{
					if (animation.curAnim.name.startsWith('sing'))
						holdTimer += elapsed;
					else
						holdTimer = 0;

					if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
						dance();

					if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
						playAnim('deathLoop');
				}
			}

			if (!debugMode)
			{
				var nextAnim = animNext.get(animation.curAnim.name);
				var forceDanced = animDanced.get(animation.curAnim.name);

				if (nextAnim != null && animation.curAnim.finished)
				{
					if (isDancing && forceDanced != null)
						danced = forceDanced;
					playAnim(nextAnim);
				}
			}

			switch (curCharacter)
			{
				case 'pico-speaker':
					if (animationNotes.length > 0 && Conductor.songPosition >= animationNotes[0].strumTime)
					{
						var noteData:Int = 1;
						if (2 <= animationNotes[0].noteData)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false, altAnim:Bool = false)
	{
		if (!debugMode)
		{
			if (!FlxG.save.data.optimize)
			{

				if (curCharacter != 'pico-speaker'){
					if (animation.curAnim != null)
					{
						var canInterrupt = animInterrupt.get(animation.curAnim.name);

						if (canInterrupt)
						{
							if (isDancing)
							{
								danced = !danced;

								if (altAnim
									&& animation.getByName('danceRight-alt') != null
									&& animation.getByName('danceLeft-alt') != null)
								{
									if (danced)
										playAnim('danceRight-alt');
									else
										playAnim('danceLeft-alt');
								}
								else
								{
									if (danced)
										playAnim('danceRight');
									else
										playAnim('danceLeft');
								}
							}
							else
							{
								if (altAnim && animation.getByName('idle-alt') != null)
									playAnim('idle-alt', forced);
								else
									playAnim('idle', forced);
							}
						}
					}
				}
			}
		}
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (!FlxG.save.data.optimize)
		{
			if (AnimName.endsWith('alt') && animation.getByName(AnimName) == null)
			{
				#if debug
				FlxG.log.warn(['Such alt animation doesnt exist: ' + AnimName]);
				#end
				AnimName = AnimName.split('-')[0];
			}

			animation.play(AnimName, Force, Reversed, Frame);

			var daOffset = animOffsets.get(AnimName);
			if (animOffsets.exists(AnimName))
			{
				offset.set(daOffset[0], daOffset[1]);
			}
			else
				offset.set(0, 0);

			if (curCharacter == 'gf')
			{
				if (AnimName == 'singLEFT')
				{
					danced = true;
				}
				else if (AnimName == 'singRIGHT')
				{
					danced = false;
				}

				if (AnimName == 'singUP' || AnimName == 'singDOWN')
				{
					danced = !danced;
				}
			}
		}
	}

	public static function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson(PlayState.SONG.songId, 'picospeaker').notes;
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = (songNotes[0] - FlxG.save.data.offset - PlayState.SONG.offset) / PlayState.songMultiplier;
				if (daStrumTime < 0)
					daStrumTime = 0;

				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var oldNote:Note;

				if (PlayState.instance.unspawnNotes.length > 0)
					oldNote = PlayState.instance.unspawnNotes[Std.int(PlayState.instance.unspawnNotes.length - 1)];
				else
					oldNote = null;
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, false, songNotes[4]);

				animationNotes.push(swagNote);
			}
		}
		TankmenBG.animationNotes = animationNotes;
		animationNotes.sort(sortAnims);
	}

	static function sortAnims(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}

typedef CharacterData =
{
	var name:String;
	var asset:String;
	var startingAnim:String;

	var ?charPos:Array<Int>;
	var ?camPos:Array<Int>;
	var ?camFollow:Array<Int>;
	var ?holdLength:Float;

	/**
	 * The color of this character's health bar.
	 */
	var barColor:String;

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
	var ?scale:Int;

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
}

typedef AnimationData =
{
	var name:String;
	var prefix:String;
	var ?offsets:Array<Int>;

	/**
	 * Whether this animation is looped.
	 * @default false
	 */
	var ?looped:Bool;

	var ?flipX:Bool;
	var ?flipY:Bool;

	/**
	 * The frame rate of this animation.
	 		* @default 24
	 */
	var ?frameRate:Int;

	var ?frameIndices:Array<Int>;

	/**
	 * Whether this animation can be interrupted by the dance function.
	 * @default true
	 */
	var ?interrupt:Bool;

	/**
	 * The animation that this animation will go to after it is finished.
	 */
	var ?nextAnim:String;

	/**
	 * Whether this animation sets danced to true or false.
	 * Only works for characters with isDancing enabled.
	 */
	var ?isDanced:Bool;
}
