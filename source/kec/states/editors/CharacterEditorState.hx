package kec.states.editors;

import haxe.ui.components.Slider;
import kec.substates.MusicBeatSubstate;
import kec.objects.ui.HealthIcon;
import haxe.ui.components.CheckBox;
import haxe.ui.focus.FocusManager;
import haxe.ui.backend.flixel.UIState;
import flixel.graphics.frames.FlxAtlasFrames;
import haxe.ui.components.Button;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.VBox;
import kec.backend.character.AnimationData;
import kec.backend.character.CharacterData;
import kec.backend.character.CharacterData.Data;
import kec.objects.Character;
import kec.objects.editor.TextLine;
import kec.stages.Stage;
import kec.objects.Bar;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;
import flixel.system.debug.interaction.tools.Pointer.GraphicCursorCross;
import flixel.graphics.FlxGraphic;

@:build(haxe.ui.ComponentBuilder.build("assets/shared/data/editors/character.xml"))
class CharacterEditorState extends UIState
{
	private var stage:Stage = null; // Stage.
	private var char:Character = null; // Character To Edit.
	private var charToDrag:FlxSprite = null; // Character To Drag Around (Char / Ghost)
	private var charString:String = 'bf';
	private var follow:FlxObject = null;
	private var cam:FlxCamera = null;
	private var camGame:FlxCamera = null;
	private var camZoom:Float = 1.0;
	private var offsetText:FlxTypedGroup<TextLine> = null;
	private var animList:Array<AnimationData> = [];
	private var curAnim:AnimationData;
	private var curAnimSelected:Int = 0;
	private var colorBar:Bar = null;
	private var icon:HealthIcon = null;
	private var frameCount:TextLine = null;
	private var ghost:FlxSprite;
	private var ghostAlpha:Float = 0.5;
	private var camPos:FlxSprite;

	// MOUSE FUNCTIONS !! STOLEN FROM FlxExtendedMouseSprite !!
	private var _dragOffsetX:Int = 0;
	private var _dragOffsetY:Int = 0;

	// ETC
	var _file:FileReference;

	// HAXEUI
	private var editorUI:VBox;
	

	public function new(char:String = 'bf')
	{
		super();
		this.charString = char;
	}

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();
		setStage('stage');
		char = new Character(400, 450, charString, false, false, true);
		setProperties();
		charToDrag = char;

		ghost = new FlxSprite(400, 450);
		ghost.visible = false;
		add(ghost);
		add(char);

		follow = new FlxObject(char.getMidpoint().x, char.getMidpoint().y, 1, 1);
		follow.active = false;
		add(follow);

		camGame = FlxG.camera;
		camGame.scroll.set();
		camGame.target = null;
		camGame.follow(follow, LOCKON, 1);
		cam = new FlxCamera();
		cam.bgColor.alpha = 0;
		FlxG.cameras.add(cam, false);

		camPos = new FlxSprite(char.getMidpoint().x + char.data.camPos[0], char.getMidpoint().y + char.data.camPos[1]).makeGraphic(25, 25, FlxColor.WHITE);
		camPos.active = false;
		add(camPos);

		setBar();

		offsetText = new FlxTypedGroup<TextLine>();
		offsetText.camera = cam;
		add(offsetText);
		reloadTexts();
		switchAnim();

		super.create();
		editorUI.camera = cam;
		setupHUI();
		frameCount = new TextLine();
		frameCount.reuse(450, 100, 20);
		frameCount.screenCenter(X);
		frameCount.camera = cam;
		updateFrameText('Frames | ${char.animation.curAnim.curFrame} | ${char.animation.curAnim.numFrames - 1}');
		add(frameCount);

		subStates.push(new kec.substates.editors.CharacterEditorHelpText());
	}

	override function update(elapsed:Float)
	{
		final camKeys = [
			FlxG.keys.pressed.J,
			FlxG.keys.pressed.K,
			FlxG.keys.pressed.I,
			FlxG.keys.pressed.L,
		];
		final offsetKeys = [
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.DOWN,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.RIGHT,
		];
		var txt = 'fard';
		if (FocusManager.instance.focus == null)
		{
			if (camKeys.contains(true))
			{
				var addToCam:Float = 500 * elapsed;
				if (FlxG.keys.pressed.CONTROL)
					addToCam *= 4;
				follow.x += ((camKeys[3] ? addToCam : 0) - (camKeys[0] ? addToCam : 0));
				follow.y += ((camKeys[1] ? addToCam : 0) - (camKeys[2] ? addToCam : 0));
			}

			if (offsetKeys.contains(true))
			{
				var offsetAdd:Int = 1;
				if (FlxG.keys.pressed.CONTROL)
					offsetAdd *= 10;
				changeOffset(((offsetKeys[0] ? offsetAdd : 0) - (offsetKeys[3] ? offsetAdd : 0)),
					((offsetKeys[2] ? offsetAdd : 0) - (offsetKeys[1] ? offsetAdd : 0)));
			}

			if (FlxG.keys.justPressed.Q)
				camZoom -= 0.05;
			else if (FlxG.keys.justPressed.E)
				camZoom += 0.05;

			if (FlxG.keys.justPressed.W)
				switchAnim(-1);
			if (FlxG.keys.justPressed.S)
				switchAnim(1);

			if (FlxG.keys.justPressed.ENTER)
				setCharacter(charToLoad.text);
			if (FlxG.keys.justPressed.ALT)
			{
				if (charToDrag == char)
					charToDrag = ghost;
				else
					charToDrag = char;
			}
			if (FlxG.mouse.overlaps(charToDrag))
			{
				if (FlxG.mouse.justPressed)
				{
					_dragOffsetX = Math.floor(FlxG.mouse.screenX + charToDrag.scrollFactor.x * (FlxG.mouse.x - FlxG.mouse.screenX) - charToDrag.x);
					_dragOffsetY = Math.floor(FlxG.mouse.screenY + charToDrag.scrollFactor.y * (FlxG.mouse.y - FlxG.mouse.screenY) - charToDrag.y);
				}

				if (FlxG.mouse.pressed)
					updateDrag();
			}

			if (controls.BACK)
				MusicBeatState.switchState(new SelectEditorsState());

			if (FlxG.keys.justPressed.F1)
				openSubState(subStates[0]);
		}
		if (char.animation != null)
		{
			if (FlxG.keys.justPressed.SPACE && FocusManager.instance.focus == null)
				char.playAnim(curAnim.name, true);
			var frames = -1;
			var length = -1;
			if (char.animation.curAnim != null)
			{
				frames = char.animation.curAnim.curFrame;
				length = char.animation.curAnim.numFrames - 1;
			}

			if (length >= 0)
			{
				if ((FlxG.keys.justPressed.Z || FlxG.keys.justPressed.X) && FocusManager.instance.focus == null)
				{
					var isLeft = false;
					if (FlxG.keys.justPressed.Z)
						isLeft = true;
					char.animation.pause();
					frames = FlxMath.wrap(frames + Std.int(isLeft ? -1 : 1), 0, length);
				}
				char.animation.curAnim.curFrame = frames;
				txt = "Frames | " + frames + " | " + length;
			}
		}
		if (txt != frameCount.text)
			updateFrameText(txt);

		final lerpVal:Float = CoolUtil.boundTo(1 - (elapsed * 15), 0, 1);
		camGame.zoom = FlxMath.lerp(camZoom, camGame.zoom, lerpVal);

		super.update(elapsed);
	}

	private function setStage(newStage:String)
	{
		stage = new Stage(newStage);
		Paths.setCurrentLevel(stage.stageDir);
		stage.initStageProperties();
		stage.loadStageData(newStage);
		camZoom = stage.camZoom;

		if (!stage.doesExist)
		{
			Debug.logTrace('Stage Does Not Exist For $newStage. Loading Default Stage.');
			stage.loadStageData('stage');
			stage.initStageProperties();
		}
		stage.inEditor = true;

		for (i in stage.toAdd)
			add(i);

		for (array in stage.layInFront)
			for (bg in array)
				add(bg);
	}

	private function setCharacter(newChar:String)
	{
		if (charString == newChar)
			return;
		animList.resize(0);
		remove(char);
		char = new Character(500, 450, newChar, false, false, true);
		add(char);
		charString = newChar;
		setProperties();

		reloadTexts();
		switchAnim(0);
		setIcon(char.data.icon, char.data.iconAnimated);
		camPos.setPosition(char.getMidpoint().x + char.data.camPos[0], char.getMidpoint().y + char.data.camPos[1]);
	}

	private function setProperties()
	{
		animList = char.data.animations;
		curAnim = animList[0];
		curAnimSelected = 0;
		charToDrag = char;

		charToLoad.text = char.data.char;
		charAssets.text = char.data.assets[0];
		charScale.pos = char.data.scale;
		charIcon.text = char.data.icon;
		charFlipX.selected = char.data.flipX;
		charFlipAnims.selected = char.data.flipAnims;
		charIconAnimated.selected = char.data.iconAnimated;
		camPosX.pos = char.data.camPos[0];
		camPosY.pos = char.data.camPos[1];
		charAntiAlias.selected = char.data.antialiasing;
		charDances.selected = char.data.dances;
		charGF.selected = char.data.replacesGF;
		animLength.pos = char.data.holdLength;
		charToLoad.text = char.data.char;
		charAssets.text = char.data.assets[0];
		charScale.pos = char.data.scale;
		charIcon.text = char.data.icon;
		charFlipX.selected = char.data.flipX;
		charFlipAnims.selected = char.data.flipAnims;
		charIconAnimated.selected = char.data.iconAnimated;
		charStartAnim.text = char.data.startingAnim;
		charTrail.selected = char.data.trail;
	}

	private function setIcon(newIcon:String, animated:Bool)
	{
		icon.changeIcon(newIcon, animated);
		char.data.icon = newIcon;
	}

	private function setBar()
	{
		colorBar = new Bar(650, 625, 'healthBar', 'shared', null, 2, 2);
		colorBar.setColors(char.data.barColor, char.data.barColor);
		colorBar.camera = cam;
		add(colorBar);

		icon = new HealthIcon(char.data.char, char.data.iconAnimated, false);
		icon.setPosition(625, colorBar.y - 75);
		icon.camera = cam;
		add(icon);
	}

	private function setColors()
	{
		final red:Int = Std.int(charRed.pos);
		final green:Int = Std.int(charGreen.pos);
		final blue:Int = Std.int(charBlue.pos);
		colorBar.setColors(FlxColor.fromRGB(red, green, blue), FlxColor.fromRGB(red, green, blue));
	}

	private function setFlipX()
	{
		char.data.flipX = charFlipX.selected;
		char.flipX = charFlipX.selected;
		char.playAnim(curAnim.name);
	}

	private function setGhost()
	{
		ghost.loadGraphic(char.graphic);
		ghost.frames.frames = char.frames.frames;
		ghost.animation.copyFrom(char.animation);
		setGhostFrame();
	}

	private function setAntiAliasing()
	{
		char.data.antialiasing = charAntiAlias.selected;
		char.antialiasing = char.data.antialiasing;
	}

	// seperated because we don't need to load the graphic EVERY time.

	private function setGhostFrame()
	{
		ghost.flipX = char.flipX;
		ghost.visible = true;
		ghost.scale.set(char.scale.x, char.scale.y);
		ghost.updateHitbox();
		ghost.offset.set(char.offset.x, char.offset.y);
		ghost.animation.play(char.animation.curAnim.name, true, false, char.animation.curAnim.curFrame);
		ghost.animation.pause();
		ghost.colorTransform.color = 0xffffffff;
		ghost.colorTransform.alphaMultiplier = ghostAlpha;
	}

	private function setFlipAnims()
	{
		char.data.flipAnims = charFlipAnims.selected;

		final oldOffset:Array<Int> = char.animOffsets['singRIGHT'];
		final newOffset:Array<Int> = char.animOffsets['singLEFT'];
		final oldRight = char.animation.getByName('singRIGHT').frames;
		char.animation.getByName('singRIGHT').frames = char.animation.getByName('singLEFT').frames;
		char.animation.getByName('singLEFT').frames = oldRight;
		// IF THEY HAVE MISS ANIMATIONS??
		if (char.animation.getByName('singRIGHTmiss') != null)
		{
			final oldMiss = char.animation.getByName('singRIGHTmiss').frames;
			char.animation.getByName('singRIGHTmiss').frames = char.animation.getByName('singLEFTmiss').frames;
			char.animation.getByName('singLEFTmiss').frames = oldMiss;

			final oldMissOffset:Array<Int> = char.animOffsets['singRIGHTmiss'];
			final newMissOffset:Array<Int> = char.animOffsets['singLEFTmiss'];

			char.animOffsets['singRIGHTmiss'] = newMissOffset;
			char.animOffsets['singLEFTmiss'] = oldMissOffset;

			for (i in animList)
			{
				if (i.name == 'singRIGHTmiss')
					i.offsets = newMissOffset;
				else if (i.name == 'singLEFTmiss')
					i.offsets = oldMissOffset;
			}
		}
		char.animOffsets['singRIGHT'] = newOffset;
		char.animOffsets['singLEFT'] = oldOffset;
		for (i in animList)
		{
			if (i.name == 'singRIGHT')
				i.offsets = newOffset;
			else if (i.name == 'singLEFT')
				i.offsets = oldOffset;
		}

		reloadTexts();
		switchAnim();
	}

	private function reloadTexts()
	{
		offsetText.forEachAlive(function(s:TextLine)
		{
			s.kill();
		});
		for (i => anim in animList)
		{
			var text:TextLine = offsetText.recycle(TextLine);
			text.reuse(950, 20 + (25 * i), 20);
			text.text = '${anim.name} (${anim.offsets[0]} ${anim.offsets[1]})';
			text.ID = i;
		}
	}

	private function switchAnim(whar:Int = 0)
	{
		curAnimSelected += whar;

		if (curAnimSelected >= animList.length)
			curAnimSelected = 0;
		if (curAnimSelected < 0)
			curAnimSelected = animList.length - 1;

		curAnim = animList[curAnimSelected];

		offsetText.members[curAnimSelected].color = FlxColor.CYAN;
		if (char.animation.exists(curAnim.name))
			char.playAnim(curAnim.name);

		offsetText.forEachAlive(function(t:TextLine)
		{
			t.color = FlxColor.WHITE;
			if (t.ID == curAnimSelected)
				t.color = FlxColor.CYAN;
		});

		updateAnimText();
	}

	private function updateFrameText(t:String)
	{
		frameCount.text = t;
		frameCount.updateHitbox();
		frameCount.screenCenter(X);
	}

	private function changeOffset(x:Int, y:Int)
	{
		char.animOffsets[curAnim.name] = curAnim.offsets = [curAnim.offsets[0] + x, curAnim.offsets[1] + y];
		offsetText.members[curAnimSelected].text = '${curAnim.name} (${curAnim.offsets[0]} ${curAnim.offsets[1]})';
		char.playAnim(curAnim.name);
	}

	// MOUSE DRAG !!
	function updateDrag()
	{
		charToDrag.setPosition(Math.floor(FlxG.mouse.screenX + charToDrag.scrollFactor.x * (FlxG.mouse.x - FlxG.mouse.screenX)) - _dragOffsetX,
			Math.floor(FlxG.mouse.screenY + charToDrag.scrollFactor.y * (FlxG.mouse.y - FlxG.mouse.screenY)) - _dragOffsetY);
		camPos.setPosition(char.getMidpoint().x + char.data.camPos[0], char.getMidpoint().y + char.data.camPos[1]);	
	}

	// HAXEUI

	function setupHUI()
	{
		charReload.onClick = _ -> this.setCharacter(charToLoad.text);
		charFrames.onClick = _ -> this.updateCharFrames();
		charScale.onChange = _ -> this.updateScale();
		charDead.onChange = _ -> char.data.deadChar = charDead.text;
		animAdd.onClick = _ -> this.addAnim();
		animUpdate.onClick = _ -> this.updateAnim();
		animDelete.onClick = _ -> this.removeAnim();
		saveChar.onClick = _ -> this.saveToFile();
		editorDrag.onClick = _ -> editorUI.draggable = !editorUI.draggable;
		charRed.onChange = _ -> this.setColors();
		charGreen.onChange = _ -> this.setColors();
		charBlue.onChange = _ -> this.setColors();
		charIcon.onChange = _ -> this.setIcon(charIcon.text, charIconAnimated.selected);
		charFlipX.onClick = _ -> this.setFlipX();
		charFlipAnims.onClick = _ -> this.setFlipAnims();
		editorGhost.onClick = _ -> this.setGhost();
		editorGhostUpdate.onClick = _ -> this.setGhostFrame();
		editorGhostSetPos.onClick = _ -> ghost.setPosition(char.x, char.y);
		charIconAnimated.onChange = _ -> this.setIcon(charIcon.text, charIconAnimated.selected);
		charAntiAlias.onClick = _ -> this.setAntiAliasing();
		charDances.onClick = _ -> char.data.dances = charDances.selected;
		charGF.onClick = _ -> char.data.replacesGF = charGF.selected;
		charTrail.onClick = _ -> char.data.trail = charTrail.selected;
		charStartAnim.onChange = _ -> char.data.startingAnim = charStartAnim.text;
		charIconAnimName.onChange = _ ->
		{
			try
			{
				icon.playAnimation(charIconAnimName.text);
			}
		};

		editorAlpha.onChange = _ ->
		{
			this.ghostAlpha = editorAlpha.pos / 100;
			ghost.alpha = this.ghostAlpha;
		};
		charGetColor.onClick = function(e)
		{
			if (FlxG.save.data.gpuRender)
				return;
			// crashes with it on due to getColor32 or whatever
			final col:FlxColor = FlxColor.fromInt(CoolUtil.dominantColor(icon));
			char.data.rgb = [col.red, col.green, col.blue];
			charRed.pos = col.red;
			charGreen.pos = col.green;
			charBlue.pos = col.blue;
		}

		camPosX.onChange = _ ->
		{
			char.data.camPos[0] = Std.int(camPosX.pos);
			camPos.setPosition(char.getMidpoint().x + char.data.camPos[0], char.getMidpoint().y + char.data.camPos[1]);
		};

		camPosY.onChange = _ ->
		{
			char.data.camPos[1] = Std.int(camPosY.pos);
			camPos.setPosition(char.getMidpoint().x + char.data.camPos[0], char.getMidpoint().y + char.data.camPos[1]);
		};
	}

	function updateAnimText()
	{
		charToLoad.text = char.data.char;
		charAssets.text = char.data.assets[0];
		charIcon.text = char.data.icon;
		charRed.pos = char.data.rgb[0];
		charGreen.pos = char.data.rgb[1];
		charBlue.pos = char.data.rgb[2];
		animName.text = curAnim.name;
		animFPS.pos = curAnim.frameRate == null ? 24 : curAnim.frameRate;
		animPrefix.text = curAnim.prefix;
		animIndices.text = Std.string(curAnim.frameIndices);
		animNextAnim.text = curAnim.nextAnim;
		animLooped.selected = curAnim.looped;
		animIgnoreIdle.selected = curAnim.interrupt;
	}

	function updateScale()
	{
		char.data.scale = charScale.pos;
		char.scale.set(char.data.scale, char.data.scale);
		char.updateHitbox();
		char.playAnim(char.animation.curAnim.name, true);
	}

	function updateCharFrames()
	{
		final lastAnim:String = char.animation.curAnim.name;
		final anims:Array<AnimationData> = char.data.animations.copy();
		char.frames = Paths.getMultiAtlas(charAssets.text.split(', '));
		for (anim in anims)
		{
			final animName:String = '' + anim.name;
			final animPrefix:String = '' + anim.prefix;
			final animFps:Int = anim.frameRate;
			final animLoop:Bool = !!anim.looped; // Bruh
			final animIndices:Array<Int> = anim.frameIndices;
			addAnimation(animName, animPrefix, animFps, animLoop, animIndices);
		}
		char.playAnim(lastAnim, true);
	}

	function addAnimation(anim:String, name:String, fps:Float, loop:Bool, indices:Array<Int>)
	{
		if (indices != null && indices.length > 0)
			char.animation.addByIndices(anim, name, indices, "", fps, loop);
		else
			char.animation.addByPrefix(anim, name, fps, loop);

		if (!char.animation.exists(anim))
		{
			Debug.logTrace('$anim DOES NOT EXIST');
			char.animOffsets[anim] = [0, 0];
		}
	}

	function addAnim()
	{
		if (char.animation.exists(animName.text))
			return;
		final indices:Array<String> = animIndices.text.split(',');
		var newIndices:Array<Int> = [];
		if (indices.length > 1)
		{
			for (i in indices)
				newIndices.push(Std.parseInt(i));
		}
		final newAnim:AnimationData = {
			name: animName.text,
			prefix: animPrefix.text,
			offsets: [0, 0],
			frameIndices: newIndices,
			looped: animLooped.selected,
			frameRate: 24,
			interrupt: animIgnoreIdle.selected,
			nextAnim: '',
			isDanced: false
		};
		char.data.animations.push(newAnim);
		animList = char.data.animations;
		addAnimation(newAnim.name, newAnim.prefix, newAnim.frameRate, newAnim.looped, newAnim.frameIndices);
		reloadTexts();
		switchAnim();
		updateAnimText();
	}

	function updateAnim()
	{
		if (!char.animation.exists(animName.text))
			return;
		final indices:Array<String> = animIndices.text.split(',');
		var newIndices:Array<Int> = [];
		if (indices.length > 1)
		{
			for (i in indices)
				newIndices.push(Std.parseInt(i));
		}
		curAnim = char.data.animations[curAnimSelected];
		curAnim.name = animName.text;
		curAnim.frameRate = animFPS.pos == 0 ? 24 : Std.int(animFPS.pos);
		curAnim.prefix = animPrefix.text;
		curAnim.frameIndices = newIndices;
		curAnim.looped = animLooped.selected;
		char.animation.remove(animName.text);
		addAnimation(curAnim.name, curAnim.prefix, curAnim.frameRate, curAnim.looped, newIndices);
		reloadTexts();
		switchAnim();
	}

	function removeAnim()
	{
		if (!animList.toString().contains(animName.text))
			return;
		// wack bullshit	
		final name = animList[curAnimSelected].name;
		animList.remove(curAnim);
		char.data.animations = animList;
		curAnimSelected = 0;
		reloadTexts();
		switchAnim(0);
		char.animation.remove(name);
	}

	function saveToFile()
	{
		final newChar:Data = {
			name: charToLoad.text,
			asset: charAssets.text.split(', '),
			healthicon: charIcon.text,
			iconAnimated: charIconAnimated.selected,
			startingAnim: charStartAnim.text,
			rgbArray: char.data.rgb,
			barType: "rgb",
			animations: char.data.animations,
			scale: charScale.pos,
			flipX: charFlipX.selected,
			flipAnimations: charFlipAnims.selected,
			deadChar: charDead.text,
			antialiasing: char.data.antialiasing,
			replacesGF: charGF.selected,
			isDancing: charDances.selected,
			holdLength: animLength.pos,
			hasTrail: charTrail.selected,
			camPos: [Std.int(camPosX.pos), Std.int(camPosY.pos)]
		};

		final json:String = haxe.Json.stringify(newChar, null, " ");
		if ((json != null) && (json.length > 0))
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(json.trim(), charToLoad.text + ".json");
		}
	}

	/**
	 * Called when the save file dialog is completed.
	 */
	function onSaveComplete(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	/**
	 * Called when the save file dialog is cancelled.
	 */
	function onSaveCancel(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	function onSaveError(_):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}
}
