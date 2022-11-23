#if FEATURE_LUAMODCHART
import flixel.FlxG;
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import flixel.util.FlxAxes;
import flixel.FlxSprite;
import lime.app.Application;
import openfl.Lib;
#if FEATURE_FILESYSTEM
import sys.io.File;
import sys.FileSystem;
#end
import flash.display.BitmapData;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxCamera;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import haxe.DynamicAccess;

// completely yoinked from andromeda (thats what you get for stealing my callback inputs you fuckers /j)

typedef LuaProperty =
{
	var defaultValue:Any;
	var getter:(State, Any) -> Int;
	var setter:State->Int;
}

class LuaStorage
{
	public static var ListOfCameras:Array<LuaCamera> = [];
	public static var objectProperties:Map<String, Map<String, LuaProperty>> = [];
	public static var objects:Map<String, LuaClass> = [];
}

class LuaClass
{
	public var properties:Map<String, LuaProperty> = [];
	public var methods:Map<String, cpp.Callable<StatePointer->Int>> = [];
	public var className:String = "BaseClass";

	private static var state:State;

	public var addToGlobal:Bool = true;

	public function Register(l:State)
	{
		Lua.newtable(l);
		state = l;
		LuaStorage.objectProperties[className] = this.properties;

		var classIdx = Lua.gettop(l);
		Lua.pushvalue(l, classIdx);
		if (addToGlobal)
			Lua.setglobal(l, className);

		for (k in methods.keys())
		{
			Lua.pushcfunction(l, methods[k]);
			Lua.setfield(l, classIdx, k);
		}

		LuaL.newmetatable(l, className + "Metatable");
		var mtIdx = Lua.gettop(l);
		Lua.pushstring(l, "__index");
		Lua.pushcfunction(l, cpp.Callable.fromStaticFunction(index));
		Lua.settable(l, mtIdx);

		Lua.pushstring(l, "__newindex");
		Lua.pushcfunction(l, cpp.Callable.fromStaticFunction(newindex));
		Lua.settable(l, mtIdx);

		for (k in properties.keys())
		{
			Lua.pushstring(l, k + "PropertyData");
			Convert.toLua(l, properties[k].defaultValue);
			Lua.settable(l, mtIdx);
		}
		Lua.pushstring(l, "_CLASSNAME");
		Lua.pushstring(l, className);
		Lua.settable(l, mtIdx);

		Lua.pushstring(l, "__metatable");
		Lua.pushstring(l, "This metatable is locked.");
		Lua.settable(l, mtIdx);

		Lua.setmetatable(l, classIdx);
	};

	public static function index(l:StatePointer):Int
	{
		var l = state;
		var index = Lua.tostring(l, -1);
		if (Lua.getmetatable(l, -2) != 0)
		{
			var mtIdx = Lua.gettop(l);
			Lua.pushstring(l, index + "PropertyData");
			Lua.rawget(l, mtIdx);
			var data:Any = Convert.fromLua(l, -1);
			if (data != null)
			{
				Lua.pushstring(l, "_CLASSNAME");
				Lua.rawget(l, mtIdx);
				var clName = Lua.tostring(l, -1);
				if (LuaStorage.objectProperties[clName] != null && LuaStorage.objectProperties[clName][index] != null)
				{
					return LuaStorage.objectProperties[clName][index].getter(l, data);
				}
			};
		}
		else
		{
			// TODO: throw an error!
		};
		return 0;
	}

	public static function newindex(l:StatePointer):Int
	{
		var l = state;
		var index = Lua.tostring(l, 2);
		if (Lua.getmetatable(l, 1) != 0)
		{
			var mtIdx = Lua.gettop(l);
			Lua.pushstring(l, index + "PropertyData");
			Lua.rawget(l, mtIdx);
			var data:Any = Convert.fromLua(l, -1);
			if (data != null)
			{
				Lua.pushstring(l, "_CLASSNAME");
				Lua.rawget(l, mtIdx);
				var clName = Lua.tostring(l, -1);
				if (LuaStorage.objectProperties[clName] != null && LuaStorage.objectProperties[clName][index] != null)
				{
					Lua.pop(l, 2);
					return LuaStorage.objectProperties[clName][index].setter(l);
				}
			};
		}
		else
		{
			// TODO: throw an error!
		};
		return 0;
	}

	public static function SetProperty(l:State, tableIndex:Int, key:String, value:Any)
	{
		Lua.pushstring(l, key + "PropertyData");
		Convert.toLua(l, value);
		Lua.settable(l, tableIndex);

		Lua.pop(l, 2);
	}

	public static function DefaultSetter(l:State)
	{
		var key = Lua.tostring(l, 2);

		Lua.pushstring(l, key + "PropertyData");
		Lua.pushvalue(l, 3);
		Lua.settable(l, 4);

		Lua.pop(l, 2);
	};

	public function new()
	{
	}
}

class LuaNote extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public var note:Note;

	public function new(connectedNote:Note, index:Int)
	{
		super();
		className = "note_" + index;

		note = connectedNote;

		properties = [
			"alpha" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.alpha);
					return 1;
				},
				setter: SetNumProperty
			},

			"angle" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.angle);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
					{
						LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
						return 0;
					}

					var angle = Lua.tonumber(l, 3);
					connectedNote.modAngle = angle;

					LuaClass.DefaultSetter(l);
					return 0;
				}
			},

			"strumTime" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.strumTime);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					// mf you can't modify this shit
					return 0;
				}
			},

			"data" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.noteData);
					return 1;
				},
				setter: SetNumProperty
			},
			"isDead" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushboolean(l, !connectedNote.alive);
					return 1;
				},
				setter: SetNumProperty
			},

			"mustPress" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushboolean(l, connectedNote.mustPress);
					return 1;
				},
				setter: SetNumProperty
			},

			"beat" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.beat);
					return 1;
				},
				setter: SetNumProperty
			},

			"isSustain" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushboolean(l, connectedNote.isSustainNote);
					return 1;
				},
				setter: SetNumProperty
			},

			"isParent" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushboolean(l, connectedNote.isParent);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "isParent is read-only.");
					return 0;
				}
			},

			"getParent" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushstring(l, "note_" + connectedNote.parent.luaID);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "getParent is read-only.");
					return 0;
				}
			},

			"yNoteOff" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.noteYOff);
					return 1;
				},
				setter: SetNumProperty
			},

			"getChildren" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.newtable(l);

					for (i in 0...connectedNote.children.length)
					{
						var note = connectedNote.children[i];
						Lua.pushstring(l, note.LuaNote.className);
						Lua.rawseti(l, -2, i);
					}

					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "getChildren is read-only.");
					return 0;
				}
			},

			"getSpotInline" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.spotInLine);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "spot in line is read-only.");
					return 0;
				}
			},

			"x" => {
				defaultValue: connectedNote.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				}
			},

			"tweenAlpha" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAlphaC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAlpha is read-only.");
					return 0;
				}
			},

			"tweenAngle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAngleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAngle is read-only.");
					return 0;
				}
			},

			"y" => {
				defaultValue: connectedNote.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedNote.y);
					return 1;
				},
				setter: SetNumProperty
			}

		];
	}

	private static function findNote(time:Float, data:Int)
	{
		for (i in PlayState.instance.notes)
		{
			if (i.strumTime == time && i.noteData == data)
			{
				return i;
			}
		}
		return null;
	}

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "strumTime");
		var time = Lua.tonumber(state, -1);
		Lua.getfield(state, 1, "data");
		var data = Lua.tonumber(state, -1);

		var note = findNote(time, Math.floor(data));

		if (note == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find note " + time + ")");
			return 0;
		}

		PlayState.instance.createTween(note, {x: xp, y: yp}, time, {ease: ModchartState.getFlxEaseByString(ease)});
		return 0;
	}

	private static function tweenAngle(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var nangle = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "strumTime");
		var time = Lua.tonumber(state, -1);
		Lua.getfield(state, 1, "data");
		var data = Lua.tonumber(state, -1);

		var note = findNote(time, Math.floor(data));

		if (note == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find note " + time + ")");
			return 0;
		}

		PlayState.instance.createTween(note, {modAngle: nangle}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAlpha(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var nalpha = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "strumTime");
		var time = Lua.tonumber(state, -1);
		Lua.getfield(state, 1, "data");
		var data = Lua.tonumber(state, -1);

		var note = findNote(time, Math.floor(data));

		if (note == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find note " + time + ")");
			return 0;
		}
		PlayState.instance.createTween(note, {alpha: nalpha}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
	private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
	private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		note.modifiedByLua = true;
		Reflect.setProperty(note, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
	}
}

class LuaReceptor extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public var sprite:StaticArrow;

	var defaultY = 0.0;
	var defaultX = 0.0;
	var defaultAngle = 0.0;
	var defaultScaleX = 0.0;
	var defaultScaleY = 0.0;
	var defaultDirection = 0.0;
	var defaultScrollType = false;

	public static var receptorTween:FlxTween;

	public function new(connectedSprite:StaticArrow, name:String)
	{
		super();
		defaultY = connectedSprite.y;
		defaultX = connectedSprite.x;
		defaultAngle = connectedSprite.modAngle;
		defaultScaleX = connectedSprite.scale.x;
		defaultScaleY = connectedSprite.scale.y;
		defaultDirection = connectedSprite.direction;
		defaultScrollType = connectedSprite.downScroll;

		sprite = connectedSprite;

		connectedSprite.luaObject = this;

		className = name;

		properties = [
			"alpha" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.alpha);
					return 1;
				},
				setter: SetNumProperty
			},

			"id" => {
				defaultValue: name,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushstring(l, name);
					return 1;
				},
				setter: SetNumProperty
			},

			"angle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.angle);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
					{
						LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
						return 0;
					}

					var angle = Lua.tonumber(l, 3);
					connectedSprite.modAngle = angle;

					LuaClass.DefaultSetter(l);
					return 0;
				}
			},

			"x" => {
				defaultValue: connectedSprite.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"y" => {
				defaultValue: connectedSprite.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.y);
					return 1;
				},
				setter: SetNumProperty
			},

			"direction" => {
				defaultValue: 90,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.direction);
					return 1;
				},
				setter: SetNumProperty
			},

			"defaultDirection" => {
				defaultValue: 90,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultDirection);
					return 1;
				},
				setter: SetNumProperty
			},

			"downScroll" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushboolean(l, connectedSprite.downScroll);
					return 1;
				},
				setter: SetNumProperty
			},

			"defaultAngle" => {
				defaultValue: defaultAngle,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultAngle);
					return 1;
				},
				setter: SetNumProperty
			},

			"defaultX" => {
				defaultValue: defaultX,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultX);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				}
			},

			"tweenAlpha" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAlphaC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAlpha is read-only.");
					return 0;
				}
			},

			"scaleX" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.scale.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"scaleY" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.scale.y);
					return 1;
				},
				setter: SetNumProperty
			},

			"defaultScaleX" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultScaleX);
					return 1;
				},
				setter: SetNumProperty
			},

			"defaultScaleY" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultScaleY);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenAngle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAngleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAngle is read-only.");
					return 0;
				}
			},

			"tweenScale" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenScaleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenScale is read-only.");
					return 0;
				}
			},

			"tweenDirection" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenDirectionC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenDirection is read-only.");
					return 0;
				}
			},

			"defaultY" => {
				defaultValue: defaultY,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, defaultY);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					return 0;
				}
			}

		];
	}

	private static function findReceptor(index:Int)
	{
		for (i in 0...PlayState.strumLineNotes.length)
		{
			if (index == i)
			{
				return PlayState.strumLineNotes.members[i];
			}
		}
		return null;
	}

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "id");
		var index = Std.parseInt(Lua.tostring(state, -1).split('_')[1]);

		var receptor = findReceptor(index);

		var luaObject = receptor.luaObject;

		if (receptor == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find receptor " + index + ")");
			return 0;
		}
		if (yp == receptor.y)
		{
			receptorTween = PlayState.instance.createTween(receptor, {x: xp}, time, {
				ease: ModchartState.getFlxEaseByString(ease),
				onUpdate: function(tw)
				{
					luaObject.defaultX = receptor.x;
				},
				onComplete: function(twn:FlxTween)
				{
					receptorTween = null;
				}
			});
		}
		else
			receptorTween = PlayState.instance.createTween(receptor, {x: xp, y: yp}, time, {
				ease: ModchartState.getFlxEaseByString(ease),
				onUpdate: function(tw)
				{
					luaObject.defaultX = receptor.x;
					luaObject.defaultY = receptor.y;
				},
				onComplete: function(twn:FlxTween)
				{
					receptorTween = null;
				}
			});

		return 0;
	}

	private static function tweenAngle(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var nangle = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Std.parseInt(Lua.tostring(state, -1).split('_')[1]);

		var receptor = findReceptor(index);

		if (receptor == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find receptor " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(receptor, {modAngle: nangle}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenDirection(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var direction = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Std.parseInt(Lua.tostring(state, -1).split('_')[1]);

		var receptor = findReceptor(index);

		var luaObject = receptor.luaObject;

		if (receptor == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find receptor " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(receptor, {direction: direction}, time, {
			ease: ModchartState.getFlxEaseByString(ease),
			onUpdate: function(tw)
			{
				luaObject.defaultDirection = receptor.direction;
			}
		});

		return 0;
	}

	private static function tweenAlpha(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var nalpha = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Std.parseInt(Lua.tostring(state, -1).split('_')[1]);

		var receptor = findReceptor(index);

		if (receptor == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find receptor " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(receptor, {alpha: nalpha}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenScale(l:StatePointer):Int
	{
		var nscaleX = LuaL.checknumber(state, 2);
		var nscaleY = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "id");
		var index = Std.parseInt(Lua.tostring(state, -1).split('_')[1]);

		var receptor = findReceptor(index);

		var luaObject = receptor.luaObject;

		if (receptor == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find receptor " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(receptor.scale, {x: nscaleX, y: nscaleY}, time, {
			ease: ModchartState.getFlxEaseByString(ease),
			onUpdate: function(twn)
			{
				luaObject.defaultScaleX = receptor.scale.x;
				luaObject.defaultScaleY = receptor.scale.y;
			}
		});

		return 0;
	}

	private static var tweenScaleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenScale);
	private static var tweenDirectionC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenDirection);
	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
	private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
	private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}

		sprite.modifiedByLua = true;

		Reflect.setProperty(sprite, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
		trace("Registered " + className);
	}
}

class LuaCamera extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public var cam:FlxCamera;

	public function new(connectedCamera:FlxCamera, name:String)
	{
		super();
		cam = connectedCamera;

		className = name;

		properties = [
			"alpha" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCamera.alpha);
					return 1;
				},
				setter: SetNumProperty
			},

			"angle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCamera.angle);
					return 1;
				},
				setter: SetNumProperty
			},

			"zoom" => {
				defaultValue: connectedCamera.zoom,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCamera.zoom);
					return 1;
				},
				setter: SetNumProperty
			},

			"x" => {
				defaultValue: connectedCamera.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCamera.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"y" => {
				defaultValue: connectedCamera.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCamera.y);
					return 1;
				},
				setter: SetNumProperty
			},

			"id" => {
				defaultValue: className,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushstring(l, className);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenZoom" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenZoomC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenZoom is read-only.");
					return 0;
				}
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				}
			},

			"tweenAlpha" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAlphaC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAlpha is read-only.");
					return 0;
				}
			},

			"tweenAngle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAngleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAngle is read-only.");
					return 0;
				}
			},
			"shake" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, shakeC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "Shake is read-only.");
					return 0;
				}
			}
		];

		LuaStorage.ListOfCameras.push(this);
	}

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		Reflect.setProperty(cam, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	private static function tweenZoom(l:StatePointer):Int
	{
		// 1 = self
		// 2 = zoom
		// 3 = time
		var nzoom = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var camera:FlxCamera = null;

		for (i in LuaStorage.ListOfCameras)
		{
			if (i.className == index)
			{
				camera = i.cam;
			}
		}

		if (camera == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find camera " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(camera, {zoom: nzoom}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static var tweenZoomC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenZoom);

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var camera:FlxCamera = null;

		for (i in LuaStorage.ListOfCameras)
		{
			if (i.className == index)
				camera = i.cam;
		}

		if (camera == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find camera " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(camera, {x: xp, y: yp}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAngle(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var nangle = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var camera:FlxCamera = null;

		for (i in LuaStorage.ListOfCameras)
		{
			if (i.className == index)
				camera = i.cam;
		}

		if (camera == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find camera " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(camera, {modAngle: nangle}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAlpha(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var nalpha = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var camera:FlxCamera = null;

		for (i in LuaStorage.ListOfCameras)
		{
			if (i.className == index)
				camera = i.cam;
		}

		if (camera == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find camera " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(camera, {alpha: nalpha}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function shake(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var namp = LuaL.checknumber(state, 2);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var camera:FlxCamera = null;

		for (i in LuaStorage.ListOfCameras)
		{
			if (i.className == index)
				camera = i.cam;
		}

		if (camera == null)
		{
			LuaL.error(state, "Failure to shake (couldn't find camera " + index + ")");
			return 0;
		}

		camera.shake(namp);

		return 0;
	}

	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
	private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
	private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);
	private static var shakeC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(shake);

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
		trace("Registered " + className);
	}
}

class LuaCharacter extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public var char:Character;
	public var isPlayer:Bool = false;

	public static var ListOfCharacters:Array<LuaCharacter> = [];

	public function new(connectedCharacter:Character, name:String)
	{
		super();
		className = name;

		char = connectedCharacter;

		isPlayer = char.isPlayer;

		properties = [
			"alpha" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCharacter.alpha);
					return 1;
				},
				setter: SetNumProperty
			},

			"angle" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCharacter.angle);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
					{
						LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
						return 0;
					}

					var angle = Lua.tonumber(l, 3);
					connectedCharacter.angle = angle;

					LuaClass.DefaultSetter(l);
					return 0;
				}
			},

			"x" => {
				defaultValue: connectedCharacter.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCharacter.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				}
			},

			"id" => {
				defaultValue: name,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushstring(l, name);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenAlpha" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAlphaC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAlpha is read-only.");
					return 0;
				}
			},

			"tweenAngle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAngleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAngle is read-only.");
					return 0;
				}
			},

			"changeCharacter" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, changeCharacterC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "changeCharacter is read-only.");
					return 0;
				}
			},

			"playAnim" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, playAnimC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "playAnim is read-only.");
					return 0;
				}
			},

			"y" => {
				defaultValue: connectedCharacter.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedCharacter.y);
					return 1;
				},
				setter: SetNumProperty
			}

		];

		ListOfCharacters.push(this);
	}

	private static function findNote(time:Float, data:Int)
	{
		for (i in PlayState.instance.notes)
		{
			if (i.strumTime == time && i.noteData == data)
			{
				return i;
			}
		}
		return null;
	}

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var char:Character = null;

		for (i in ListOfCharacters)
		{
			if (i.className == index)
				char = i.char;
		}

		if (char == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find character " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(char, {x: xp, y: yp}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAngle(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var nangle = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var char:Character = null;

		for (i in ListOfCharacters)
		{
			if (i.className == index)
				char = i.char;
		}

		if (char == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find character " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(char, {angle: nangle}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAlpha(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var nalpha = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var char:Character = null;

		for (i in ListOfCharacters)
		{
			if (i.className == index)
				char = i.char;
		}

		if (char == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find character " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(char, {alpha: nalpha}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function changeCharacter(l:StatePointer):Int
	{
		// 1 = self
		// 2 = newName
		// 3 = x
		// 4 = y
		var newName = LuaL.checkstring(state, 2);
		var x = LuaL.checknumber(state, 3);
		var y = LuaL.checknumber(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var char:Character = null;
		var property:LuaCharacter = null;

		for (i in ListOfCharacters)
		{
			if (i.className == index)
			{
				char = i.char;
				property = i;
			}
		}

		trace("fuck " + char);

		if (char == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find character " + index + ")");
			return 0;
		}

		PlayState.instance.remove(char);

		PlayState.dad = new Character(x, y, newName, char.isPlayer);

		property.char = PlayState.dad;

		PlayState.instance.add(PlayState.dad);

		return 0;
	}

	private static function playAnim(l:StatePointer):Int
	{
		// 1 = self
		// 2 = animation
		var anim = LuaL.checkstring(state, 2);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var char:Character = null;

		for (i in ListOfCharacters)
		{
			if (i.className == index)
			{
				char = i.char;
			}
		}

		if (char == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find character " + index + ")");
			return 0;
		}

		char.playAnim(anim);

		return 0;
	}

	private static var playAnimC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(playAnim);
	private static var changeCharacterC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(changeCharacter);
	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
	private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
	private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		Reflect.setProperty(char, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
	}
}

class LuaSprite extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public var sprite:FlxSprite;

	public static var ListOfSprites:Array<LuaSprite> = [];

	public function new(connectedSprite:FlxSprite, name:String)
	{
		super();
		className = name;

		properties = [
			"alpha" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.alpha);
					return 1;
				},
				setter: SetNumProperty
			},

			"angle" => {
				defaultValue: 1,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.angle);
					return 1;
				},
				setter: function(l:State):Int
				{
					// 1 = self
					// 2 = key
					// 3 = value
					// 4 = metatable
					if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
					{
						LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
						return 0;
					}

					var angle = Lua.tonumber(l, 3);
					connectedSprite.angle = angle;

					LuaClass.DefaultSetter(l);
					return 0;
				}
			},

			"x" => {
				defaultValue: connectedSprite.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				}
			},

			"id" => {
				defaultValue: name,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushstring(l, name);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenAlpha" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAlphaC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAlpha is read-only.");
					return 0;
				}
			},

			"tweenAngle" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenAngleC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenAngle is read-only.");
					return 0;
				}
			},

			"destroy" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, destroyC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "destroy is read-only.");
					return 0;
				}
			},

			"y" => {
				defaultValue: connectedSprite.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, connectedSprite.y);
					return 1;
				},
				setter: SetNumProperty
			}

		];

		ListOfSprites.push(this);
	}

	private static function findNote(time:Float, data:Int)
	{
		for (i in PlayState.instance.notes)
		{
			if (i.strumTime == time && i.noteData == data)
			{
				return i;
			}
		}
		return null;
	}

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var sprite:FlxSprite = null;

		for (i in ListOfSprites)
		{
			if (i.className == index)
				sprite = i.sprite;
		}

		if (sprite == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find sprite " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(sprite, {x: xp, y: yp}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAngle(l:StatePointer):Int
	{
		// 1 = self
		// 2 = angle
		// 3 = time
		var nangle = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var sprite:FlxSprite = null;

		for (i in ListOfSprites)
		{
			if (i.className == index)
				sprite = i.sprite;
		}

		if (sprite == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find sprite " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(sprite, {angle: nangle}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function tweenAlpha(l:StatePointer):Int
	{
		// 1 = self
		// 2 = alpha
		// 3 = time
		var nalpha = LuaL.checknumber(state, 2);
		var time = LuaL.checknumber(state, 3);
		var ease = LuaL.checkstring(state, 4);

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var sprite:FlxSprite = null;

		for (i in ListOfSprites)
		{
			if (i.className == index)
				sprite = i.sprite;
		}

		if (sprite == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find sprite " + index + ")");
			return 0;
		}

		PlayState.instance.createTween(sprite, {alpha: nalpha}, time, {ease: ModchartState.getFlxEaseByString(ease)});

		return 0;
	}

	private static function destroy(l:StatePointer):Int
	{
		// 1 = self

		Lua.getfield(state, 1, "id");
		var index = Lua.tostring(state, -1);

		var sprite:FlxSprite = null;

		for (i in ListOfSprites)
		{
			if (i.className == index)
				sprite = i.sprite;
		}

		if (sprite == null)
		{
			LuaL.error(state, "Failure to tween (couldn't find sprite " + index + ")");
			return 0;
		}

		PlayState.instance.remove(sprite);
		sprite.destroy();

		return 0;
	}

	private static var destroyC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(destroy);
	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);
	private static var tweenAngleC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAngle);
	private static var tweenAlphaC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenAlpha);

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		Reflect.setProperty(sprite, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
	}
}

class LuaWindow extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		Reflect.setProperty(Application.current.window, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	public function new()
	{
		super();
		className = "window";

		properties = [
			"x" => {
				defaultValue: Application.current.window.x,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Application.current.window.x);
					return 1;
				},
				setter: SetNumProperty
			},

			"y" => {
				defaultValue: Application.current.window.y,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Application.current.window.y);
					return 1;
				},
				setter: SetNumProperty
			},

			"width" => {
				defaultValue: Application.current.window.width,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Application.current.window.width);
					return 1;
				},
				setter: SetNumProperty
			},

			"height" => {
				defaultValue: Application.current.window.height,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Application.current.window.height);
					return 1;
				},
				setter: SetNumProperty
			},

			"tweenPos" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, tweenPosC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "tweenPos is read-only.");
					return 0;
				},
			},

			"boundsWidth" => { // TODO: turn into a table w/ bounds.x and bounds.y
				defaultValue: Lib.application.window.display.bounds.width,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Lib.application.window.display.bounds.width);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "boundsWidth is read-only.");
					return 0;
				}
			},
			"boundsHeight" => { // TODO: turn into a table w/ bounds.x and bounds.y
				defaultValue: Lib.application.window.display.bounds.height,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, Lib.application.window.display.bounds.height);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "boundsHeight is read-only.");
					return 0;
				}
			}
		];
	}

	private static function tweenPos(l:StatePointer):Int
	{
		// 1 = self
		// 2 = x
		// 3 = y
		// 4 = time
		var xp = LuaL.checknumber(state, 2);
		var yp = LuaL.checknumber(state, 3);
		var time = LuaL.checknumber(state, 4);
		var ease = LuaL.checkstring(state, 5);

		PlayState.instance.createTween(Application.current.window, {x: xp, y: yp}, time, {
			ease: ModchartState.getFlxEaseByString(ease)
		});

		return 0;
	}

	private static var tweenPosC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(tweenPos);

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
	}
}

class LuaGame extends LuaClass
{ // again, stolen from andromeda but improved a lot for better thinking interoperability (I made that up)
	private static var state:State;

	public function new()
	{
		super();
		className = "Game";

		properties = [

			"health" => {
				defaultValue: PlayState.instance.health,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, PlayState.instance.health);
					return 1;
				},
				setter: function(l:State):Int
				{
					PlayState.instance.health = Lua.tonumber(l, 3);
					return 0;
				},
			},

			"accuracy" => {
				defaultValue: PlayState.instance.accuracy,
				getter: function(l:State, data:Any):Int
				{
					Lua.pushnumber(l, PlayState.instance.accuracy);
					return 1;
				},
				setter: SetNumProperty
			},
			"changeStage" => {
				defaultValue: 0,
				getter: function(l:State, data:Any)
				{
					Lua.pushcfunction(l, changeStageC);
					return 1;
				},
				setter: function(l:State)
				{
					LuaL.error(l, "changeStage is read-only.");
					return 0;
				},
			}
		];
	}

	private static function changeStage(l:StatePointer):Int
	{
		// 1 = self
		// 2 = stage
		var stageName = LuaL.checkstring(state, 2);

		for (i in PlayState.Stage.toAdd)
		{
			PlayState.instance.remove(i);
		}

		PlayState.Stage = new Stage(stageName);

		for (i in PlayState.Stage.toAdd)
		{
			PlayState.instance.add(i);
		}

		return 0;
	}

	private static var changeStageC:cpp.Callable<StatePointer->Int> = cpp.Callable.fromStaticFunction(changeStage);

	private function SetNumProperty(l:State)
	{
		// 1 = self
		// 2 = key
		// 3 = value
		// 4 = metatable
		if (Lua.type(l, 3) != Lua.LUA_TNUMBER)
		{
			LuaL.error(l, "invalid argument #3 (number expected, got " + Lua.typename(l, Lua.type(l, 3)) + ")");
			return 0;
		}
		Reflect.setProperty(Application.current.window, Lua.tostring(l, 2), Lua.tonumber(l, 3));
		return 0;
	}

	override function Register(l:State)
	{
		state = l;
		super.Register(l);
	}
}
#end
