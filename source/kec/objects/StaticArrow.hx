package kec.objects;

import kec.backend.lua.LuaClass;
import kec.backend.util.NoteStyleHelper;

class StaticArrow extends FlxSprite
{
	#if FEATURE_LUAMODCHART
	public var luaObject:LuaReceptor;
	#end
	public var modifiedByLua:Bool = false;
	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside here

	public var laneFollowsReceptor:Bool = true;
	public var bgLane:FlxSprite;

	public var direction:Float = 90;

	public var downScroll:Bool = false;

	public var texture(default, set):String = null;

	public static var defaultPlayerSkin(default, never):String = 'noteskins/Arrows';
	public static var defaultCpuSkin(default, never):String = 'noteskins/Arrows';

	// Note Animation Suffixes.
	private var dataSuffix:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT'];
	private var dataColor:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var player:Int;
	private var noteData:Int = 0;

	public var resetAnim:Float = 0;

	public var noteTypeCheck:String = 'normal';

	private function set_texture(value:String):String
	{
		if (texture != value)
		{
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function new(xx:Float, yy:Float, ?player:Int, ?data:Int)
	{
		x = xx;
		y = yy;
		this.player = player;
		noteData = data;
		super(x, y);

		var skin:String = null;
		if (texture.length < 1)
		{
			if (player == 0)
				skin = PlayState.cpuNoteskinSprite;
			else
				skin = PlayState.noteskinSprite;
			if (skin == null || skin.length < 1)
				skin = player == 0 ? defaultPlayerSkin : defaultCpuSkin;
		}

		var customSkin:String = skin;
		if (Paths.fileExists('images/$customSkin.png', IMAGE))
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

		if (PlayState.SONG != null)
			noteTypeCheck = PlayState.STYLE.style.toLowerCase();
		switch (noteTypeCheck)
		{
			case 'pixel':
				loadGraphic(PlayState.noteskinPixelSprite, true, 17, 17);
				animation.add('green', [6]);
				animation.add('red', [7]);
				animation.add('blue', [5]);
				animation.add('purple', [4]);

				setGraphicSize(Std.int(width * CoolUtil.daPixelZoom));
				updateHitbox();
				antialiasing = false;

				animation.add('static', [noteData]);
				animation.add('pressed', [4 + noteData, 8 + noteData], 12, false);
				animation.add('confirm', [12 + noteData, 16 + noteData], 12, false);

				for (j in 0...4)
				{
					animation.add('dirCon' + j, [12 + j, 16 + j], 12, false);
				}
			default:
				frames = Paths.getSparrowAtlas(texture);
				for (j in 0...4)
				{
					animation.addByPrefix(dataColor[j], 'arrow' + dataSuffix[j]);
					animation.addByPrefix('dirCon' + j, dataSuffix[j].toLowerCase() + ' confirm', 24, false);
				}

				var lowerDir:String = dataSuffix[noteData].toLowerCase();

				animation.addByPrefix('static', 'arrow' + dataSuffix[noteData]);
				animation.addByPrefix('pressed', lowerDir + ' press', 24, false);
				animation.addByPrefix('confirm', lowerDir + ' confirm', 24, false);

				antialiasing = FlxG.save.data.antialiasing;
				setGraphicSize(Std.int(width * 0.7));
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
		if (!modifiedByLua)
			angle = localAngle + modAngle;
		else
			angle = modAngle;
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
		bgLane.angle = direction - 90;
		if (laneFollowsReceptor)
			bgLane.x = (x - 2) - (bgLane.angle * 0.5);

		bgLane.alpha = FlxG.save.data.laneTransparency * alpha;
		bgLane.visible = visible;
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
}
