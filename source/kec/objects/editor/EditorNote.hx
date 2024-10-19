package kec.objects.editor;

import kec.backend.util.NoteStyleHelper;
import kec.objects.note.Note;

/**
 * Note Used For The Chart Editor. Simplified For Recycling.
 */
class EditorNote extends FlxSprite
{
	public var time:Float;
	public var data:Int;
	public var rawData:Int;
	public var isPlayer(get, never):Bool;
	public var holdLength:Float;
	public var type(default, set):String;
	public var texture(default, set):String;
	public var hitsoundsEditor:Bool;
	public var quantNote:Bool = true;
	public var originColor:Int;
	public var beat:Float;
	public var selected:Bool = false;

	public static final PURP_NOTE:Int = 0;
	public static final GREEN_NOTE:Int = 2;
	public static final BLUE_NOTE:Int = 1;
	public static final RED_NOTE:Int = 3;
	public static final quantityColor:Array<Int> = [RED_NOTE, 2, BLUE_NOTE, 2, PURP_NOTE, 2, GREEN_NOTE, 2];
	public static final arrowAngles:Array<Int> = [180, 90, 270, 0];

	public var modAngle:Float = 0; // The angle set by modcharts
	public var localAngle:Float = 0; // The angle to be edited inside Note.hx
	public var originAngle:Float = 0; // The angle the OG note of the sus note had (?)
	public var noteCharterObject:FlxSprite;

	private function set_texture(v:String)
	{
		if (texture != v)
		{
			reloadTexture(v);
			texture = v;
		}
		return v;
	}

	private function set_type(v:String)
	{
		if (type != v)
		{
			switch (v.toLowerCase())
			{
				case 'hurt':
					hitsoundsEditor = false;
					if (Paths.fileExists('images/notetypes/hurt_'
						+ NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin]
						+ '.png'))
						texture = 'notetypes/hurt_' + NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin];
					else
						texture = "notetypes/hurt_Arrows";
					quantNote = true;
				case 'mustpress':
					set_type('Must Press'); // backwards compatabilty for charts before the KEC1 format.
				case 'must press':
					hitsoundsEditor = true;
					if (Paths.fileExists('images/notetypes/mustpress_'
						+ NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin]
						+ '.png'))
						texture = 'notetypes/mustpress_' + NoteStyleHelper.noteskinArray[isPlayer ? FlxG.save.data.noteskin : FlxG.save.data.cpuNoteskin];
					else
						texture = "notetypes/mustpress_Arrows";
					quantNote = true;
				case 'gf':
					hitsoundsEditor = true;
					quantNote = true;
					texture = '';
				case 'poison':
					hitsoundsEditor = false;
					texture = "notetypes/poison_Arrows";
					quantNote = true;
				case 'invis':
					hitsoundsEditor = false;
					texture = "notetypes/invis_Arrows";
					quantNote = true;
				case 'speed':
					hitsoundsEditor = false;
					texture = "notetypes/speed_Arrows";
					quantNote = true;
				default:
					hitsoundsEditor = true;
					quantNote = true;
					texture = '';
			}
			type = v;
		}
		return v;
	}

	function get_isPlayer():Bool
	{
		return rawData > 3;
	}

	public function new()
	{
		super();
		texture = '';
		visible = true;
		active = false;
	}

	public function setup(t:Float, d:Int, l:Float, type:String, b:Float)
	{
		this.time = t;
		this.rawData = d;
		this.data = Std.int(d % 4);
		this.holdLength = l;
		this.type = type;
		this.beat = b;
		selected = false;
		noteCharterObject = null;
		angle = modAngle = localAngle = 0;

		visible = true;
		active = false;

		var animToPlay:String = '';
		animToPlay = Constants.noteColors[data] + 'Scroll';
		originColor = data;

		if (FlxG.save.data.stepMania && quantNote)
		{
			var col:Int = 0;

			var beatRow = Math.round(b * 48);
			// STOLEN ETTERNA CODE (IN 2002)

			if (beatRow % (192 / 4) == 0)
				col = quantityColor[0];
			else if (beatRow % (192 / 8) == 0)
				col = quantityColor[2];
			else if (beatRow % (192 / 12) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 16) == 0)
				col = quantityColor[6];
			else if (beatRow % (192 / 24) == 0)
				col = quantityColor[4];
			else if (beatRow % (192 / 32) == 0)
				col = quantityColor[4];

			originColor = col;

			localAngle -= arrowAngles[col];
			localAngle += arrowAngles[data];
			originAngle = localAngle;
			animToPlay = Constants.noteColors[col] + 'Scroll';
		}
		animation.play(animToPlay);
		angle = modAngle + localAngle;
	}

	public function reloadTexture(tex:String = '')
	{
		if (tex == null)
			tex = '';

		var skin:String = tex;

		if (tex.length < 1)
		{
			skin = isPlayer ? Constants.noteskinSprite : Constants.cpuNoteskinSprite;
			if (skin == null || skin.length < 1)
				skin = isPlayer ? Note.defaultPlayerSkin : Note.defaultCpuSkin;
		}

		var animName:String = null;
		if (animation.curAnim != null)
			animName = animation.curAnim.name;

		var skinPostfix:String = '';
		var customSkin:String = skin + skinPostfix;
		var path:String = '';

		if (Paths.fileExists('images/' + customSkin + '.png'))
			skin = customSkin;
		else
			skinPostfix = '';

		frames = Paths.getSparrowAtlas(skin);
		loadNoteAnims();

		if (animName != null)
			animation.play(animName, true);

		updateHitbox();
	}

	function loadNoteAnims()
	{
		for (i in 0...4)
			animation.addByPrefix(Constants.noteColors[i] + 'Scroll', Constants.noteColors[i] + ' alone'); // Normal notes
		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	override function kill()
	{
		super.kill();
	}
}
