package kec.backend.lua;

// this file is for modchart things, this is to declutter playstate.hx
// Lua
#if FEATURE_LUAMODCHART
import kec.backend.lua.LuaClass.LuaGame;
import kec.backend.lua.LuaClass.LuaWindow;
import kec.backend.lua.LuaClass.LuaSprite;
import kec.backend.lua.LuaClass.LuaCamera;
import kec.backend.lua.LuaClass.LuaReceptor;
import kec.backend.lua.LuaClass.LuaNote;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import openfl.geom.Matrix;
import openfl.display.BitmapData;
import lime.app.Application;
import llua.Convert;
import llua.Lua;
import llua.State;
import llua.LuaL;
import openfl.Lib;
import openfl.utils.Assets as OpenFlAssets;
#if FEATURE_FILESYSTEM
import sys.io.File;
#end
import kec.objects.Character;

class ModchartState
{
	public static var lua:State = null;

	public static var shownNotes:Array<LuaNote> = [];

	function callLua(func_name:String, args:Array<Dynamic>, ?type:String):Dynamic
	{
		var result:Any = null;

		Lua.getglobal(lua, func_name);

		for (arg in args)
		{
			Convert.toLua(lua, arg);
		}

		result = Lua.pcall(lua, args.length, 1, 0);
		var p = Lua.tostring(lua, result);
		var e = getLuaErrorMessage(lua);

		Lua.tostring(lua, -1);

		if (e != null)
		{
			if (e != "attempt to call a nil value")
			{
				trace(StringTools.replace(e, "c++", "haxe function"));
			}
		}
		if (result == null)
		{
			return null;
		}
		else
		{
			return convert(result, type);
		}
	}

	static function toLua(l:State, val:Any):Bool
	{
		switch (Type.typeof(val))
		{
			case Type.ValueType.TNull:
				Lua.pushnil(l);
			case Type.ValueType.TBool:
				Lua.pushboolean(l, val);
			case Type.ValueType.TInt:
				Lua.pushinteger(l, cast(val, Int));
			case Type.ValueType.TFloat:
				Lua.pushnumber(l, val);
			case Type.ValueType.TClass(String):
				Lua.pushstring(l, cast(val, String));
			case Type.ValueType.TClass(Array):
				Convert.arrayToLua(l, val);
			case Type.ValueType.TObject:
				objectToLua(l, val);
			default:
				trace("haxe value not supported - " + val + " which is a type of " + Type.typeof(val));
				return false;
		}

		return true;
	}

	static function objectToLua(l:State, res:Any)
	{
		var FUCK = 0;
		for (n in Reflect.fields(res))
		{
			trace(Type.typeof(n).getName());
			FUCK++;
		}

		Lua.createtable(l, FUCK, 0); // TODONE: I did it

		for (n in Reflect.fields(res))
		{
			if (!Reflect.isObject(n))
				continue;
			Lua.pushstring(l, n);
			toLua(l, Reflect.field(res, n));
			Lua.settable(l, -3);
		}
	}

	function getType(l, type):Any
	{
		return switch Lua.type(l, type)
		{
			case t if (t == Lua.LUA_TNIL): null;
			case t if (t == Lua.LUA_TNUMBER): Lua.tonumber(l, type);
			case t if (t == Lua.LUA_TSTRING): (Lua.tostring(l, type) : String);
			case t if (t == Lua.LUA_TBOOLEAN): Lua.toboolean(l, type);
			case t: throw 'you don goofed up. lua type error ($t)';
		}
	}

	function getReturnValues(l)
	{
		var lua_v:Int;
		var v:Any = null;
		while ((lua_v = Lua.gettop(l)) != 0)
		{
			var type:String = getType(l, lua_v);
			v = convert(lua_v, type);
			Lua.pop(l, 1);
		}
		return v;
	}

	private function convert(v:Any, type:String):Dynamic
	{ // I didn't write this lol
		if (Std.isOfType(v, String) && type != null)
		{
			var v:String = v;
			if (type.substr(0, 4) == 'array')
			{
				if (type.substr(4) == 'float')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Float> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseFloat(vars));
					}

					return array2;
				}
				else if (type.substr(4) == 'int')
				{
					var array:Array<String> = v.split(',');
					var array2:Array<Int> = new Array();

					for (vars in array)
					{
						array2.push(Std.parseInt(vars));
					}

					return array2;
				}
				else
				{
					var array:Array<String> = v.split(',');
					return array;
				}
			}
			else if (type == 'float')
			{
				return Std.parseFloat(v);
			}
			else if (type == 'int')
			{
				return Std.parseInt(v);
			}
			else if (type == 'bool')
			{
				if (v == 'true')
				{
					return true;
				}
				else
				{
					return false;
				}
			}
			else
			{
				return v;
			}
		}
		else
		{
			return v;
		}
	}

	function getLuaErrorMessage(l)
	{
		var v:String = Lua.tostring(l, -1);
		Lua.pop(l, 1);
		return v;
	}

	public function setVar(var_name:String, object:Dynamic)
	{
		// trace('setting variable ' + var_name + ' to ' + object);

		Lua.pushnumber(lua, object);
		Lua.setglobal(lua, var_name);
	}

	public function getVar(var_name:String, type:String):Dynamic
	{
		var result:Any = null;

		// trace('getting variable ' + var_name + ' with a type of ' + type);

		Lua.getglobal(lua, var_name);
		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null)
		{
			return null;
		}
		else
		{
			var result = convert(result, type);
			// trace(var_name + ' result: ' + result);
			return result;
		}
	}

	function getActorByName(id:String):Dynamic
	{
		// pre defined names
		switch (id)
		{
			case 'boyfriend':
				@:privateAccess
				return PlayState.instance.boyfriend;
			case 'girlfriend':
				@:privateAccess
				return PlayState.instance.gf;
			case 'dad':
				@:privateAccess
				return PlayState.instance.dad;
		}
		// lua objects or what ever
		if (luaSprites.get(id) == null)
		{
			if (Std.parseInt(id) == null)
				return Reflect.getProperty(PlayState.instance, id);
			return PlayState.strumLineNotes.members[Std.parseInt(id)];
		}
		return luaSprites.get(id);
	}

	function getPropertyByName(leClass:String, id:String)
	{
		return Reflect.field(Type.resolveClass(leClass), id);
	}

	function setPropertyByName(leClass:String, id:String, value:Dynamic)
	{
		return Reflect.setProperty(Type.resolveClass(leClass), id, value);
	}

	public static var luaSprites:Map<String, FlxSprite> = [];

	function changeDadCharacter(id:String)
	{
		var olddadx = PlayState.instance.dad.x;
		var olddady = PlayState.instance.dad.y;
		PlayState.instance.removeObject(PlayState.instance.dad);
		PlayState.instance.dad = new Character(olddadx, olddady, id);
		PlayState.instance.addObject(PlayState.instance.dad);
		PlayState.instance.iconP2.changeIcon(id);
	}

	function changeBoyfriendCharacter(id:String)
	{
		var oldboyfriendx = PlayState.instance.boyfriend.x;
		var oldboyfriendy = PlayState.instance.boyfriend.y;
		PlayState.instance.removeObject(PlayState.instance.boyfriend);
		PlayState.instance.boyfriend = new Character(oldboyfriendx, oldboyfriendy, id);
		PlayState.instance.addObject(PlayState.instance.boyfriend);
		PlayState.instance.iconP1.changeIcon(id);
	}

	function makeAnimatedLuaSprite(spritePath:String, names:Array<String>, prefixes:Array<String>, startAnim:String, id:String)
	{
		#if FEATURE_FILESYSTEM
		// TODO: Make this use OpenFlAssets.
		var data:BitmapData = BitmapData.fromFile(Sys.getCwd() + "assets/data/songs/" + PlayState.SONG.songId + '/' + spritePath + ".png");

		var sprite:FlxSprite = new FlxSprite(0, 0);

		sprite.frames = FlxAtlasFrames.fromSparrow(FlxGraphic.fromBitmapData(data),
			Sys.getCwd() + "assets/data/songs/" + PlayState.SONG.songId + "/" + spritePath + ".xml");

		trace(sprite.frames.frames.length);

		for (p in 0...names.length)
		{
			var i = names[p];
			var ii = prefixes[p];
			sprite.animation.addByPrefix(i, ii, 24, false);
		}

		luaSprites.set(id, sprite);

		PlayState.instance.addObject(sprite);

		sprite.animation.play(startAnim);
		return id;
		#end
	}

	function makeLuaSprite(spritePath:String, toBeCalled:String, drawBehind:Bool)
	{
		#if FEATURE_FILESYSTEM
		// pre lowercasing the song name (makeLuaSprite)
		var songLowercase = StringTools.replace(PlayState.SONG.songId, " ", "-").toLowerCase();
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}

		var path = Sys.getCwd() + "assets/data/songs/" + PlayState.SONG.songId + '/';

		#if FEATURE_STEPMANIA
		if (PlayState.isSM)
			path = PlayState.pathToSm + "/";
		#end

		var data:BitmapData = BitmapData.fromFile(path + spritePath + ".png");

		var sprite:FlxSprite = new FlxSprite(0, 0);
		var imgWidth:Float = FlxG.width / data.width;
		var imgHeight:Float = FlxG.height / data.height;
		var scale:Float = imgWidth <= imgHeight ? imgWidth : imgHeight;

		// Cap the scale at x1
		if (scale > 1)
			scale = 1;

		sprite.makeGraphic(Std.int(data.width * scale), Std.int(data.width * scale), FlxColor.TRANSPARENT);

		var data2:BitmapData = sprite.pixels.clone();
		var matrix:Matrix = new Matrix();
		matrix.identity();
		matrix.scale(scale, scale);
		data2.fillRect(data2.rect, FlxColor.TRANSPARENT);
		data2.draw(data, matrix, null, null, null, true);
		sprite.pixels = data2;

		luaSprites.set(toBeCalled, sprite);
		// and I quote:
		// shitty layering but it works!
		@:privateAccess
		{
			if (drawBehind)
			{
				PlayState.instance.removeObject(PlayState.instance.gf);
				PlayState.instance.removeObject(PlayState.instance.boyfriend);
				PlayState.instance.removeObject(PlayState.instance.dad);
			}
			PlayState.instance.addObject(sprite);
			if (drawBehind)
			{
				PlayState.instance.addObject(PlayState.instance.gf);
				PlayState.instance.addObject(PlayState.instance.boyfriend);
				PlayState.instance.addObject(PlayState.instance.dad);
			}
		}
		new LuaSprite(sprite, toBeCalled).Register(lua);
		#end

		return toBeCalled;
	}

	public function die()
	{
		Lua.close(lua);
		lua = null;
	}

	// LUA SHIT

	public function new()
	{
		shownNotes = [];
		trace('opening a lua state (because we are cool :))');
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		trace("Lua version: " + Lua.version());
		trace("LuaJIT version: " + Lua.versionJIT());
		Lua.init_callbacks(lua);

		// pre lowercasing the song name (new)
		var songLowercase = StringTools.replace(PlayState.SONG.songId, " ", "-").toLowerCase();
		switch (songLowercase)
		{
			case 'dad-battle':
				songLowercase = 'dadbattle';
			case 'philly-nice':
				songLowercase = 'philly';
			case 'm.i.l.f':
				songLowercase = 'milf';
		}

		var path = Paths.lua('songs/${PlayState.SONG.songId}/modchart');
		#if FEATURE_STEPMANIA
		if (PlayState.isSM)
			path = PlayState.pathToSm + "/modchart.lua";
		#end

		var result = LuaL.dofile(lua, path); // execute le file

		if (result != 0)
		{
			Application.current.window.alert("LUA COMPILE ERROR:\n" + Lua.tostring(lua, result), "Kade Engine Modcharts");
			FlxG.log.warn(["LUA COMPILE ERROR:\n" + Lua.tostring(lua, result)]);
			MusicBeatState.switchState(new FreeplayState());
			lua = null;
			return;
		}

		// get some fukin globals up in here bois

		setVar("difficulty", PlayState.storyDifficulty);
		setVar("isStoryMode", PlayState.isStoryMode);
		setVar("bpm", Conductor.bpm);
		setVar("scrollspeed", FlxG.save.data.scrollSpeed != 1 ? FlxG.save.data.scrollSpeed : PlayState.SONG.speed);
		setVar("fpsCap", FlxG.save.data.fpsCap);
		setVar("flashing", FlxG.save.data.flashing);
		setVar("distractions", FlxG.save.data.distractions);
		setVar("colour", FlxG.save.data.colour);
		setVar("downscroll", FlxG.save.data.downscroll);
		setVar("middlescroll", FlxG.save.data.middleScroll);
		setVar("rate", PlayState.songMultiplier); // Kinda XD since you can modify this through Lua and break the game.

		setVar("curStep", 0);
		setVar("curBeat", 0);
		setVar("crochet", Conductor.stepCrochet);

		setVar("hudZoom", PlayState.instance.zoomForHUDTweens);
		setVar("cameraZoom", PlayState.instance.zoomForTweens);

		setVar("cameraAngle", FlxG.camera.angle);
		setVar("camHudAngle", PlayState.instance.camHUD.angle);

		setVar("followXOffset", 0);
		setVar("followYOffset", 0);

		setVar("strumLine1Visible", true);
		setVar("strumLine2Visible", true);

		setVar("screenWidth", FlxG.width);
		setVar("screenHeight", FlxG.height);
		setVar("windowWidth", FlxG.width);
		setVar("windowHeight", FlxG.height);
		setVar("hudWidth", PlayState.instance.camHUD.width);
		setVar("hudHeight", PlayState.instance.camHUD.height);

		setVar("mustHit", false);

		setVar("strumLineY", PlayState.instance.strumLine.y);

		Lua_helper.add_callback(lua, "precache", function(asset:String, type:String, ?library:String)
		{
			PlayState.instance.precacheThing(asset, type, library);
		});

		// callbacks

		Lua_helper.add_callback(lua, "getProperty", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = null;
				coverMeInPiss = Reflect.getProperty(PlayState, killMe[0]);

				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				Debug.logTrace("getProp");
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			}
			Debug.logTrace("getProp");
			return Reflect.getProperty(PlayState.instance, variable);
		});
		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = null;
				coverMeInPiss = Reflect.getProperty(PlayState.instance, killMe[0]);

				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(PlayState.instance, variable, value);
		});
		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(PlayState, obj), FlxTypedGroup))
			{
				return Reflect.getProperty(Reflect.getProperty(PlayState, obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(PlayState.instance, obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == Type.ValueType.TInt)
				{
					return leArray[variable];
				}
				return Reflect.getProperty(leArray, variable);
			}
			Debug.logTrace("Object #" + index + " from group: " + obj + " doesn't exist!");
			return null;
		});
		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(PlayState.instance, obj), FlxTypedGroup))
			{
				return Reflect.setProperty(Reflect.getProperty(PlayState.instance, obj).members[index], variable, value);
			}

			var leArray:Dynamic = Reflect.getProperty(PlayState.instance, obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == Type.ValueType.TInt)
				{
					return leArray[variable] = value;
				}
				return Reflect.setProperty(leArray, variable, value);
			}
		});
		Lua_helper.add_callback(lua, "makeSprite", makeLuaSprite);

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool)
		{
			cameraFromString(camera).flash(CoolUtil.colorFromString(color), duration, null, forced);
		});

		Lua_helper.add_callback(lua, "hideHUD", function(hidden:Bool)
		{
			hideTheHUD(hidden);
		});

		// sprites

		Lua_helper.add_callback(lua, "setStrumlineY", function(y:Float)
		{
			PlayState.instance.strumLine.y = y;
		});

		Lua_helper.add_callback(lua, "getNotes", function(y:Float)
		{
			Lua.newtable(lua);

			for (i in 0...PlayState.instance.notes.members.length)
			{
				var note = PlayState.instance.notes.members[i];
				Lua.pushstring(lua, note.LuaNote.className);
				Lua.rawseti(lua, -2, i);
			}
		});

		Lua_helper.add_callback(lua, "setCamZoom", function(zoomAmount:Float)
		{
			PlayState.instance.zoomForTweens = zoomAmount;
		});

		Lua_helper.add_callback(lua, "setHudZoom", function(zoomAmount:Float)
		{
			PlayState.instance.camHUD.zoom = zoomAmount;
		});

		Lua_helper.add_callback(lua, "getHudX", function()
		{
			return PlayState.instance.camHUD.x;
		});

		Lua_helper.add_callback(lua, "getHudY", function()
		{
			return PlayState.instance.camHUD.y;
		});

		Lua_helper.add_callback(lua, "getNotes", function(y:Float)
		{
			Lua.newtable(lua);

			for (i in 0...PlayState.instance.notes.members.length)
			{
				var note = PlayState.instance.notes.members[i];
				Lua.pushstring(lua, note.LuaNote.className);
				Lua.rawseti(lua, -2, i);
			}
		});

		Lua_helper.add_callback(lua, "setScrollSpeed", function(value:Float)
		{
			PlayState.instance.scrollSpeed = value;
		});

		Lua_helper.add_callback(lua, "changeScrollSpeed", function(mult:Float, time:Float, ?ease:String)
		{
			PlayState.instance.changeScrollSpeed(mult, time, getFlxEaseByString(ease));
		});

		for (i in 0...PlayState.strumLineNotes.length)
		{
			var member = PlayState.strumLineNotes.members[i];
			new LuaReceptor(member, "receptor_" + i).Register(lua);
		}

		new LuaGame().Register(lua);

		new LuaWindow().Register(lua);
	}

	public function executeState(name, args:Array<Dynamic>)
	{
		return Lua.tostring(lua, callLua(name, args));
	}

	public static function createModchartState():ModchartState
	{
		return new ModchartState();
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud':
				return PlayState.instance.camHUD;
			case 'camGame' | 'game':
				return PlayState.instance.camGame;
			case 'overlayCam' | 'overlay':
				return PlayState.instance.overlayCam;
		}
		return PlayState.instance.camGame;
	}

	public function hideTheHUD(hide:Bool)
	{
		return PlayState.instance.hideHUD(hide);
	}

	public static function getFlxEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}
		return FlxEase.linear;
	}
}
#end
