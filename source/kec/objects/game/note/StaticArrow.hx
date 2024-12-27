package kec.objects.game.note;

import kec.backend.lua.LuaClass;
import kec.util.NoteStyleHelper;

class StaticArrow extends FlxSprite
{
	#if FEATURE_LUAMODCHART
	public var luaObject:LuaReceptor;
	#end
	public var modifiedByLua:Bool = false;

	public var laneFollowsReceptor:Bool = true;
	public var bgLane:FlxSprite;

	public var downScroll:Bool = false;

	public var texture(default, set):String = null;

	public static var defaultPlayerSkin(default, never):String = 'noteskins/Arrows';
	public static var defaultCpuSkin(default, never):String = 'noteskins/Arrows';

	// Note Animation Suffixes.
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var lane:Int = 0;

	public var resetAnim:Float = 0;

	public var noteTypeCheck:String = 'normal';

	public var modAngle(default, set):Float = 0; // The angle set by modcharts
	public var localAngle(default, set):Float = 0;
	public var modAlpha(default, set):Float = 1.0;
	public var localAlpha(default, set):Float = 1.0;

	public var direction(default, set):Float;
	public var _cos:Float = 0;
	public var _sin:Float = 1;

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(xx:Float, yy:Float, ?data:Int, ?isPlayer:Bool)
	{
		x = xx;
		y = yy;
		lane = data;
		super(x, y);
		direction = 90;

		var skin:String = null;
		if (texture.length < 1)
		{
			skin = isPlayer ? Constants.noteskinSprite : Constants.cpuNoteskinSprite;
			if (skin == null || skin.length < 1)
				skin = isPlayer ? defaultPlayerSkin : defaultCpuSkin;
		}

		var customSkin:String = skin;
		if (Paths.fileExists('images/$customSkin.png'))
			skin = customSkin;

		texture = skin; // Load texture and anims
		updateHitbox();
		scrollFactor.set();
		playAnim('static');
	}

	public function reloadNote()
	{
		if (texture == null)
			texture = '';

		var lastAnim:String = null;
		if (animation.curAnim != null)
			lastAnim = animation.curAnim.name;

		if (PlayState.STYLE != null)
			noteTypeCheck = PlayState.STYLE.style.toLowerCase();
		switch (noteTypeCheck)
		{
			case 'pixel':
				loadGraphic(Constants.noteskinPixelSprite, true, 17, 17);
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purple', [4]);

				setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
				updateHitbox();
				antialiasing = false;

				animation.add('static', [lane]);
				animation.add('pressed', [4 + lane, 8 + lane], 12, false);
				animation.add('confirm', [12 + lane, 16 + lane], 12, false);

				for (j in 0...4)
					animation.add('dirCon' + j, [12 + j, 16 + j], 12, false);
			default:
				frames = Paths.getSparrowAtlas(texture);
				for (j in 0...4)
				{
					animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
					animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
				}

				var lowerDir:String = dataSuffix[lane].toLowerCase();

				animation.addByPrefix('static', 'arrow' + dataSuffix[lane]);
				animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
				animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

				antialiasing = FlxG.save.data.antialiasing;
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
		}

		if (lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function loadLane()
	{
		bgLane = new FlxSprite(0, 0).makeGraphic(Std.int(Note.swagWidth), 2160);
		bgLane.antialiasing = FlxG.save.data.antialiasing;
		bgLane.color = FlxColor.BLACK;
		bgLane.visible = true;
		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.x = x - 2;
		bgLane.y += -300;
		bgLane.updateHitbox();
	}

	override function update(elapsed:Float)
	{
		if (resetAnim > 0)
		{
			resetAnim -= elapsed;
			if (resetAnim <= 0)
			{
				localAngle = 0;
				playAnim('static');
				resetAnim = 0;
			}
		}
		super.update(elapsed);
	}

	public function playAnim(AnimName:String, ?force:Bool = false):Void
	{
		animation.play(AnimName, force);
		if (animation.curAnim != null)
		{
			centerOffsets();
			centerOrigin();
		}

		angle = localAngle + modAngle;
	}

	function set_localAngle(value:Float)
	{
		localAngle = value;
		angle = localAngle + modAngle;
		return value;
	}

	function set_modAngle(value:Float)
	{
		modAngle = value;
		angle = localAngle + modAngle;
		return value;
	}

	function set_localAlpha(value:Float)
	{
		localAlpha = value;
		alpha = localAlpha * modAlpha;
		return value;
	}

	function set_modAlpha(value:Float)
	{
		modAlpha = value;
		alpha = localAlpha * modAlpha;
		return value;
	}

	override function set_x(value:Float)
	{
		if (bgLane != null)
			if (laneFollowsReceptor)
				bgLane.x = value - 2;

		return super.set_x(value);
	}

	override function set_alpha(value:Float):Float
	{
		if (bgLane != null)
			bgLane.alpha = FlxG.save.data.laneTransparency * alpha;

		return super.set_alpha(value);
	}

	override function set_visible(value:Bool):Bool
	{
		if (bgLane != null)
			bgLane.visible = value;
		return super.set_visible(value);
	}

	override function destroy()
	{
		FlxDestroyUtil.destroy(bgLane);
		super.destroy();
	}

	function set_direction(value:Float)
	{
		if (value != direction)
		{
			direction = value;
			var d = value * Math.PI / 180;
			_cos = Math.cos(d);
			_sin = Math.sin(d);

			if (bgLane != null)
				bgLane.angle = value - 90;
		}
		return value;
	}
}
