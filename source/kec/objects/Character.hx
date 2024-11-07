package kec.objects;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.util.FlxSort;
import kec.backend.PlayStateChangeables;
import kec.backend.chart.Song;
import kec.backend.chart.TimingStruct;
import kec.stages.TankmenBG;
import kec.backend.chart.ChartNote;
import kec.backend.chart.format.Section;
import kec.backend.character.CharacterData;
import kec.backend.character.AnimationData;

class Character extends KECSprite
{
	public var animInterrupt:Map<String, Bool>;
	public var animForces:Map<String, Bool>; // primarily for dead characters if you don't want it to be beat based.
	public var animNext:Map<String, String>;
	public var animDanced:Map<String, Bool>;
	public var debugMode:Bool = false;
	public var holdTimer:Float = 0;
	public var isAlt:Bool = false; // re-add alt idle support, but in a new way

	public var specialAnim = false;
	public var skipDance = false;
	public var altSuffix:String = '';
	public var animationNotes:Array<ChartNote> = [];
	public var data:CharacterData = null;

	public function new(x:Float, y:Float, ?character:String = "bf", ?isPlayer:Bool = false, ?isGF:Bool = false, ?debug:Bool = false)
	{
		super(x, y);

		animInterrupt = new Map<String, Bool>();
		animForces = new Map<String, Bool>();
		animNext = new Map<String, String>();
		animDanced = new Map<String, Bool>();
		this.debugMode = debug;

		switch (character)
		{
			case 'pico-speaker':
				parseDataFile('pico-speaker', isPlayer, isGF);
				skipDance = true;
				if (FlxG.save.data.quality)
					loadMappedAnims();
				playAnim("shoot1");
			default:
				parseDataFile(character, isPlayer, isGF);
		}
	}

	function parseDataFile(c:String, p:Bool, g:Bool)
	{
		if (FlxG.save.data.gen)
			Debug.logInfo('Generating character (${c}) from JSON data...');
		data = new CharacterData(c, p, g);
		var tex:FlxFramesCollection;
		var thingy:FlxAtlasFrames;

		frames = Paths.getMultiAtlas(data.assets);

		// Multi-atlas support which breaks everything

		if (frames != null)
			for (anim in data.animations)
			{
				final frameRate = anim.frameRate == null ? 24 : anim.frameRate;
				final looped = anim.looped == null ? false : anim.looped;
				final flipX = anim.flipX == null ? false : anim.flipX;
				final flipY = anim.flipY == null ? false : anim.flipY;

				if (anim.frameIndices != null && anim.frameIndices.length > 0)
					animation.addByIndices(anim.name, anim.prefix, anim.frameIndices, "", Std.int(frameRate * Conductor.rate), looped, flipX, flipY);
				else
					animation.addByPrefix(anim.name, anim.prefix, Std.int(frameRate * Conductor.rate), looped, flipX, flipY);

				offsets[anim.name] = anim.offsets == null ? [0, 0] : anim.offsets;
				animInterrupt[anim.name] = anim.interrupt == null ? true : anim.interrupt;
				animForces[anim.name] = anim.forceAnim == null ? true : anim.forceAnim;

				if (data.dances && anim.isDanced != null)
					animDanced[anim.name] = anim.isDanced;

				if (anim.nextAnim != null)
					animNext[anim.name] = anim.nextAnim;
			}
		flipX = data.flipX;

		if (data.isPlayer && data.flipAnims && frames != null)
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

		setGraphicSize(Std.int(width * data.scale));
		updateHitbox();
		antialiasing = data.antialiasing;

		playAnim(data.startingAnim);
	}

	override function update(elapsed:Float)
	{
		if (animation.curAnim != null && !debugMode)
		{
			if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished)
			{
				dance();
				animation.curAnim.finish();
			}
			if (data.isPlayer)
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
			else
			{
				if (animation.curAnim.name.startsWith('sing'))
					holdTimer += elapsed;

				if (holdTimer >= Conductor.stepCrochet * 0.0011 * data.holdLength * Conductor.rate)
				{
					dance();

					holdTimer = 0;
				}

				if (animation.curAnim.name.endsWith('miss') && animation.curAnim.finished && !debugMode)
					dance();

				if (animation.curAnim.name == 'firstDeath' && animation.curAnim.finished)
					playAnim('deathLoop');
			}

			switch (data.char)
			{
				case 'pico-speaker':
					while (animationNotes.length > 0 && Conductor.songPosition >= animationNotes[0].time)
					{
						var noteData:Int = 1;
						if (2 <= animationNotes[0].data)
							noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}
					if (animation.curAnim.finished)
						playAnim(animation.curAnim.name + 'Loop');
				default:
					var nextAnim = animNext.get(animation.curAnim.name);
					var forceDanced = animDanced.get(animation.curAnim.name);

					if (nextAnim != null && animation.curAnim.finished)
					{
						if (data.dances && forceDanced != null)
							danced = forceDanced;
						playAnim(nextAnim);
					}
			}
		}

		super.update(elapsed);
	}

	private var danced:Bool = false;

	/**
	 * FOR GF DANCING SHIT
	 */
	public function dance(forced:Bool = false)
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (animation.curAnim != null)
			{
				var canInterrupt = animInterrupt.get(animation.curAnim.name);

				if (canInterrupt)
				{
					if (isAlt)
						altSuffix = '-alt';
					if (data.dances)
					{
						danced = !danced;

						if (danced)
							playAnim('danceRight' + altSuffix);
						else
							playAnim('danceLeft' + altSuffix);
					}
					else
					{
						playAnim('idle' + altSuffix, forced);
					}
				}
			}
		}
	}

	override public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0, centerOffsets:Bool = false):Void
	{
		if (AnimName.endsWith('alt') && animation.getByName(AnimName) == null)
			AnimName = AnimName.split('-')[0];

		animation.play(AnimName, Force, Reversed, Frame);

		final daOffset = offsets.get(AnimName);
		if (offsets.exists(AnimName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

		if (data.char == 'gf')
		{
			if (AnimName == 'singLEFT')
				danced = true;
			else if (AnimName == 'singRIGHT')
				danced = false;

			if (AnimName == 'singUP' || AnimName == 'singDOWN')
				danced = !danced;
		}

		if (!centerOffsets)
			return;

		if (animation.curAnim == null)
			return;

		this.centerOffsets();
		centerOrigin();
	}

	public function loadMappedAnims():Void
	{
		if (!FlxG.save.data.background && !debugMode)
			return;
		final noteData:Array<Section> = Song.loadFromJson(PlayState.SONG.songId, 'picospeaker').notes;
		for (section in noteData)
		{
			for (i in 0...section.sectionNotes.length)
			{
				animationNotes.push(section.sectionNotes[i]);
			}
		}
		animationNotes.sort(Sort.sortChartNotes);
		TankmenBG.animationNotes = animationNotes;
	}

	public function addInterrupt(name:String, value:Bool = true)
	{
		animInterrupt[name] = value;
	}

	override function destroy()
	{
		data = null;
		super.destroy();
	}
}
