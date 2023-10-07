/*
 * Copyright (C)2008-2017 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxescript;

import haxe.ds.*;
import haxe.PosInfos;
import haxescript.Expr;
import haxe.Constraints;
import tea.SScript;

using StringTools;

private enum Stop {
	SBreak;
	SContinue;
	SReturn;
}

@:keepSub
@:access(haxescript.Tools)
@:access(tea.SScript)
class Interp {

	#if haxe3
	var variables : Map<String,Dynamic>;
	public var dynamicFuncs: Map<String, Bool> = new Map();
	var locals : Map<String,{ r : Dynamic , ?isFinal : Bool , ?t:CType , ?dynamicFunc : Bool }>;
	var binops : Map<String, Expr -> Expr -> Dynamic >;
	#else
	public var variables : Hash<Dynamic>;
	var locals : Hash<{ r : Dynamic }>;
	var binops : Hash< Expr -> Expr -> Dynamic >;
	#end

	var depth : Int;
	var inTry : Bool;
	var declared : Array<{ n : String, old : { r : Dynamic , ?isFinal : Bool , ?t:CType, ?dynamicFunc : Bool } }>;
	var returnValue : Dynamic;

	var typecheck : Bool = true;

	var usingStringTools : Bool = false;

	var specialObject : {obj:Dynamic , ?includeFunctions:Bool , ?exclusions:Array<String>} = {obj : null , includeFunctions: null , exclusions: null };

	var script : SScript;

	#if hscriptPos
	var curExpr : Expr;
	#end

	public inline function setScr(s)
	{
		return script = s;
	}

	var resumeError:Bool;

	public function new() {
		#if haxe3
		locals = new Map();
		#else
		locals = new Hash();
		#end
		declared = new Array();
		resetVariables();
		initOps();
	}

	private function resetVariables(){
		#if haxe3
		variables = new Map<String,Dynamic>();
		#else
		variables = new Hash();
		#end

		variables.set("null",null);
		variables.set("true",true);
		variables.set("false",false);
		variables.set("trace", Reflect.makeVarArgs(function(el) {
			var inf = posInfos();
			var v = el.shift();
			if( el.length > 0 ) inf.customParams = el;
			if (inf == null)
				#if sys
				Sys.println("SScript: " + Std.string(v));
				#else
				haxe.Log.trace("SScript: " + Std.string(v));
				#end
			else 
				haxe.Log.trace(Std.string(v), inf);
		}));
		variables.set("Bool", Bool);
		variables.set("Int", Int);
		variables.set("Float", Float);
		variables.set("String", String);
		variables.set("Dynamic", Dynamic);
		variables.set("Array", Array);
	}

	public function posInfos(): PosInfos {
		#if hscriptPos
			if (curExpr != null)
				return cast { fileName : curExpr.origin, lineNumber : curExpr.line };
		#end
		return null;
	}

	var inFunc : Bool = false;

	function initOps() {
		var me = this;
		#if haxe3
		binops = new Map();
		#else
		binops = new Hash();
		#end
		binops.set("+",function(e1,e2) return me.expr(e1) + me.expr(e2));
		binops.set("-",function(e1,e2) return me.expr(e1) - me.expr(e2));
		binops.set("*",function(e1,e2) return me.expr(e1) * me.expr(e2));
		binops.set("/",function(e1,e2) return me.expr(e1) / me.expr(e2));
		binops.set("%",function(e1,e2) return me.expr(e1) % me.expr(e2));
		binops.set("&",function(e1,e2) return me.expr(e1) & me.expr(e2));
		binops.set("|",function(e1,e2) return me.expr(e1) | me.expr(e2));
		binops.set("^",function(e1,e2) return me.expr(e1) ^ me.expr(e2));
		binops.set("<<",function(e1,e2) return me.expr(e1) << me.expr(e2));
		binops.set(">>",function(e1,e2) return me.expr(e1) >> me.expr(e2));
		binops.set(">>>",function(e1,e2) return me.expr(e1) >>> me.expr(e2));
		binops.set("==",function(e1,e2) return me.expr(e1) == me.expr(e2));
		binops.set("!=",function(e1,e2) return me.expr(e1) != me.expr(e2));
		binops.set(">=",function(e1,e2) return me.expr(e1) >= me.expr(e2));
		binops.set("<=",function(e1,e2) return me.expr(e1) <= me.expr(e2));
		binops.set(">",function(e1,e2) return me.expr(e1) > me.expr(e2));
		binops.set("<",function(e1,e2) return me.expr(e1) < me.expr(e2));
		binops.set("||",function(e1,e2) return me.expr(e1) == true || me.expr(e2) == true);
		binops.set("&&",function(e1,e2) return me.expr(e1) == true && me.expr(e2) == true);
		binops.set("=",assign);
		#if hscriptPos binops.set("is",checkIs); #end
		binops.set("...",function(e1,e2) return new InterpIterator(me, e1, e2));
		assignOp("+=",function(v1:Dynamic,v2:Dynamic) return v1 + v2);
		assignOp("-=",function(v1:Float,v2:Float) return v1 - v2);
		assignOp("*=",function(v1:Float,v2:Float) return v1 * v2);
		assignOp("/=",function(v1:Float,v2:Float) return v1 / v2);
		assignOp("%=",function(v1:Float,v2:Float) return v1 % v2);
		assignOp("&=",function(v1,v2) return v1 & v2);
		assignOp("|=",function(v1,v2) return v1 | v2);
		assignOp("^=",function(v1,v2) return v1 ^ v2);
		assignOp("<<=",function(v1,v2) return v1 << v2);
		assignOp(">>=",function(v1,v2) return v1 >> v2);
		assignOp(">>>=",function(v1,v2) return v1 >>> v2);
	}

	#if hscriptPos
	function checkIs(e1,e2) : Bool
	{
		var me = this;

		if( e1 == null )
			return false;
		if( e2 == null )
			return false;
		var expr1:Dynamic = me.expr(e1);
		var expr2:Dynamic = me.expr(e2);
		if( expr1 == null )
			return false;
		if( expr2 == null )
			return false;

		switch Tools.expr(e2)
		{
			case EIdent("Class",_):
				return Std.isOfType(expr1, Class);
			case EIdent("Map",_):
				return Std.isOfType(expr1, IMap);
			case _:
		}

		return Std.isOfType(expr1, expr2);
	}
	#end

	function coalesce(e1,e2) : Dynamic
	{
		var me = this;
		var e1=me.expr(e1);
		var e2=me.expr(e2);
		return e1 == null ? e2:e1;
	}

	function coalesce2(e1,e2) : Dynamic{
		var me = this;
		var expr1=e1;
		var expr2=e2;
		var e1=me.expr(e1);
		return if (e1==null) assign(expr1,expr2) else e1;
	}

	function setVar( name : String, v : Dynamic ) {
		var ftype:String = Tools.getType(variables.get(name));
		var stype:String = Tools.getType(v);
		var cl=variables.get(ftype);
		var clN=Tools.getType(v,true);

		if(typecheck)
		if(!Tools.compatibleWithEachOther(ftype, stype)&&ftype!=stype&&ftype!='Anon'&&!Tools.compatibleWithEachOtherObjects(cl,clN))error(EUnmatchingType(ftype, stype, name));
		variables.set(name, v);
	}

	function assign( e1 : Expr, e2 : Expr ) : Dynamic {
		var v = expr(e2);
		switch( Tools.expr(e1) ) {
		case EIdent(id,f):
			if(locals.get(id)!=null&&locals.get(id).isFinal)
				return error(EInvalidFinal(id));
			var l = locals.get(id);
			if( l == null )
			{
				if(!variables.exists(id))
					error(EUnknownVariable(id));
				if(Type.typeof(variables.get(id))==TFunction&&!dynamicFuncs.exists(id))
					error(EFunctionAssign(id));
				setVar(id,v);
			}
			else {
				var t=l.t;
				if(t!=null)
				{
					var ftype:String = Tools.ctToType(l.t);
					var stype:String = Tools.getType(v);
					var cl=variables.get(ftype);
					
					var clN=Tools.getType(v,true);
					if(typecheck)
					if(!Tools.compatibleWithEachOther(ftype, stype)&&ftype!=stype&&ftype!='Anon'&&!Tools.compatibleWithEachOtherObjects(cl,clN))error(EUnmatchingType(ftype, stype, id));
				}
				if(Type.typeof(l.r)==TFunction&&l.dynamicFunc!=null&&!l.dynamicFunc)
					error(EFunctionAssign(id));
				l.r = v;
			}
		case EField(e,f):
			v = set(expr(e),f,v);
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				setMapValue(arr, index, v);
			}
			else {
				arr[index] = v;
			}

		default:
			error(EInvalidOp("="));
		}
		return v;
	}

	function assignOp( op, fop : Dynamic -> Dynamic -> Dynamic ) {
		var me = this;
		binops.set(op,function(e1,e2) return me.evalAssignOp(op,fop,e1,e2));
	}

	function evalAssignOp(op,fop,e1,e2) : Dynamic {
		var v;
		switch( Tools.expr(e1) ) {
		case EIdent(id):
			var l = locals.get(id);
			v = fop(expr(e1),expr(e2));
			if( l == null )
				setVar(id,v)
			else
				l.r = v;
		case EField(e,f):
			var obj = expr(e);
			v = fop(get(obj,f),expr(e2));
			v = set(obj,f,v);
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				v = fop(getMapValue(arr, index), expr(e2));
				setMapValue(arr, index, v);
			}
			else {
				v = fop(arr[index],expr(e2));
				arr[index] = v;
			}
		default:
			return error(EInvalidOp(op));
		}
		return v;
	}

	function increment( e : Expr, prefix : Bool, delta : Int ) : Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch(e) {
		case EIdent(id):
			var l = locals.get(id);
			var v : Dynamic = (l == null) ? resolve(id) : l.r;
			if( prefix ) {
				v += delta;
				if( l == null ) setVar(id,v) else l.r = v;
			} else
				if( l == null ) setVar(id,v + delta) else l.r = v + delta;
			return v;
		case EField(e,f):
			var obj = expr(e);
			var v : Dynamic = get(obj,f);
			if( prefix ) {
				v += delta;
				set(obj,f,v);
			} else
				set(obj,f,v + delta);
			return v;
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				var v = getMapValue(arr, index);
				if (prefix) {
					v += delta;
					setMapValue(arr, index, v);
				}
				else {
					setMapValue(arr, index, v + delta);
				}
				return v;
			}
			else {
				var v = arr[index];
				if( prefix ) {
					v += delta;
					arr[index] = v;
				} else
					arr[index] = v + delta;
				return v;
			}
		default:
			return error(EInvalidOp((delta > 0)?"++":"--"));
		}
	}

	public function execute( expr : Expr ) : Dynamic {
		depth = 0;
		#if haxe3
		locals = new Map();
		#else
		locals = new Hash();
		#end
		declared = new Array();
		var r = exprReturn(expr);
		switch Tools.expr(expr){
			case EBlock(e):
				var imports:Int = 0;
				var pack:Int = 0;
				for(i in e){
					switch Tools.expr(i)
					{
						case EPackage(_):
							if(e.indexOf(i)>0)
								error(ECustom('Unexpected package'));
							else if(pack > 1)
								error(ECustom('Multiple packages has been declared'));
							pack++;
						case EImport(_,_,_):
							if(e.indexOf(i)>imports + pack)
								error(ECustom('Unexpected import'));
							imports++;
						case _:
					}
				}
				if(pack > 1)
					error(ECustom('Multiple packages has been declared'));
			case _:
		}
		return r;
	}

	function exprReturn(e) : Dynamic {
		try {
			return expr(e);
		} catch( e : Stop ) {
			switch( e ) {
			case SBreak: throw "Invalid break";
			case SContinue: throw "Invalid continue";
			case SReturn:
				var v = returnValue;
				returnValue = null;
				return v;
			}
		}
		return null;
	}

	function duplicate<T>( h : #if haxe3 Map < String, T > #else Hash<T> #end ) {
		#if haxe3
		var h2 = new Map();
		#else
		var h2 = new Hash();
		#end
		for( k in h.keys() )
			h2.set(k,h.get(k));
		return h2;
	}

	function restore( old : Int ) {
		while( declared.length > old ) {
			var d = declared.pop();
			locals.set(d.n,d.old);
		}
	}

	inline function error(e : #if hscriptPos ErrorDef #else Error #end, rethrow=false ) : Dynamic {
		if (resumeError)return null;
		#if hscriptPos var e = new Error(e, curExpr.pmin, curExpr.pmax, curExpr.origin, curExpr.line); #end
		if( rethrow ) this.rethrow(e) else throw e;
		return null;
	}

	inline function rethrow( e : Dynamic ) {
		#if hl
		hl.Api.rethrow(e);
		#else
		throw e;
		#end
	}

	function resolve( id : String ) : Dynamic {
		var l = locals.get(id);
		if( l != null )
			return l.r;
		var v = variables.get(id);
		if( specialObject != null && specialObject.obj != null )
		{
			var field = Reflect.getProperty(specialObject.obj,id);
			if( field != null && (specialObject.includeFunctions || Type.typeof(field) != TFunction) && (specialObject.exclusions == null || !specialObject.exclusions.contains(id)) )
				return field;
		}		
		if( v==null && !variables.exists(id) )
			error(EUnknownVariable(id));
		return v;
	}

	public function expr( e : Expr ) : Dynamic {
		#if hscriptPos
		curExpr = e;
		var e = e.e;
		#end
		switch( e ) {
		case EConst(c):
			switch( c ) {
			case CInt(v): return v;
			case CFloat(f): return f;
			case CString(s): return s;
			#if !haxe3
			case CInt32(v): return v;
			#end
			}
		case EIdent(id):
			return resolve(id);
		case EVar(n,t,e,g):
			if(t!=null&&e!=null)
			{
				var e = expr(e);
				var ftype:String = Tools.ctToType(t);
				var stype:String = Tools.getType(e);
				var cl=variables.get(ftype);
				var clN=Tools.getType(e,true);

				if(typecheck)
				if(!Tools.compatibleWithEachOther(ftype, stype)&&ftype!=stype&&ftype!='Anon'&&!Tools.compatibleWithEachOtherObjects(cl,clN)){error(EUnmatchingType(ftype, stype, n));}
			}

			var expr1 : Dynamic = e == null ? null : expr(e);
			var name = null;
			var isMap = t != null && e != null && (switch t {
				case CTPath(path,_):
					if( path.length == 1 && isMap(path[0])) 
					{
						name = path[0];
						true;
					}
					else false;
				case _: false;
			}) && (switch Tools.expr(e) {
				case EArrayDecl(e): 
					if( e.length < 1 ) true;
					else false;
				case _: false;
			});

			if( isMap ) 
				switch name {
					case "IntMap": expr1 = new IntMap<Dynamic>();
					case "StringMap": expr1 = new StringMap<Dynamic>();
					case "Map" | "ObjectMap": expr1 = new ObjectMap<Dynamic, Dynamic>();
					case _: 
				};

			declared.push({ n : n, old : locals.get(n) });
			locals.set(n,{ r : expr1 , isFinal : false, t: t});
			return null;
		case EFinal(n,t,e):
			if(t!=null&&e!=null)
			{
				var e = expr(e);
				var ftype:String = Tools.ctToType(t);
				var stype:String = Tools.getType(e);
				var cl=variables.get(ftype);
				var clN=Tools.getType(e,true);

				if(typecheck)
				if(!Tools.compatibleWithEachOther(ftype, stype)&&ftype!=stype&&ftype!='Anon'&&!Tools.compatibleWithEachOtherObjects(cl,clN))error(EUnmatchingType(ftype, stype, n));
			}

			declared.push({ n : n, old : locals.get(n) });
			locals.set(n,{ r : (e == null)?null:expr(e) , isFinal : true});
			return null;
		case EParent(e):
			return expr(e);
		case EBlock(exprs):
			var old = declared.length;
			var v = null;
			for( e in exprs ) {
				v = expr(e);
			}
			restore(old);
			return v;
		case EField(e,f):
			return get(expr(e),f);
		case ESwitchBinop(p, e1, e2):
			var parent = expr(p);
			var e1 = expr(e1), e2 = expr(e2);
			if( parent == e1 )
				return e1;
			else if( parent == e2 )
				return e2;
			return null;
		case EBinop(op,e1,e2):
			var fop = binops.get(op);
			if( fop == null ) error(EInvalidOp(op));
			return fop(e1,e2);
		case EUnop(op,prefix,e):
			switch(op) {
			case "!":
				return expr(e) != true;
			case "-":
				return -expr(e);
			case "++":
				return increment(e,prefix,1);
			case "--":
				return increment(e,prefix,-1);
			case "~":
				#if (neko && !haxe3)
				return haxe.Int32.complement(expr(e));
				#else
				return ~expr(e);
				#end
			default:
				error(EInvalidOp(op));
			}
		case ECall(e,params):
			var id = switch(#if hscriptPos e.e #else e #end){
				case EIdent(v,i):
					v;
				default: null;
			}

			var args = new Array();
			for( p in params )
				args.push(expr(p));

			switch( Tools.expr(e) ) {
			case EField(e,f):
				var obj = expr(e);
				if( obj == null ) error(EInvalidAccess(f));
				return fcall(obj,f,args);
			default:
				return call(null,expr(e),args);
			}
		case EIf(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else if( e2 == null ) null else expr(e2);
		case EWhile(econd,e):
			whileLoop(econd,e);
			return null;
		case EDoWhile(econd,e):
			doWhileLoop(econd,e);
			return null;
		case EFor(v,it,e):
			forLoop(v,it,e);
			return null;
		case EBreak:
			throw SBreak;
		case EContinue:
			throw SContinue;
		case EReturn(e):
			returnValue = e == null ? null : expr(e);
			throw SReturn;
		case EImportStar(pkg):
			pkg = pkg.trim();
			var c = Type.resolveClass(pkg);
			if( c != null )
			{
				var fields = Reflect.fields(c);
				for( field in fields )
				{
					var f = Reflect.getProperty(c,field);
					if(f != null)
						variables.set(field,f);
				}
			}
			else 
			{
				var map = Tools.allClassesAvailable;
				var cl = new Map<String, Class<Dynamic>>();
				for( i => k in map )
				{
					var length = pkg.split('.');
					var length2 = i.split('.');
					
					if( length.length == length2.length )
						continue;
					if( length.length + 1 != length2.length )
						continue;

					var hasSamePkg = true;
					for( i in 0...length.length )
					{
						if (length[i] != length2[i])
						{
							hasSamePkg = false;
							break;
						}
					}
					if( hasSamePkg )
						cl[length2[length2.length - 1]] = k;
				}

				for( i => k in cl )
					variables[i] = k;
			}

			return null;
		case EImport( e, c , _ ):
			if( c != null && e != null )
				variables.set( c , e );

			return null;
		case EUsing( e, c ):
			var stringTools = c == 'StringTools' && e == StringTools;

			if( c != null && e != null )
				variables.set( c , e );
			if( stringTools )
				usingStringTools = true;

			return null;
		case EPackage(p):
			if( p == null )
				error(EUnexpected(p));

			if( p!=p.toLowerCase() )
				error(ECustom('Package path cannot have capital letters'));
			return null;
		case EFunction(params,fexpr,name,_,d):
			var capturedLocals = duplicate(locals);
			var me = this;
			var hasOpt = false, minParams = 0;
			for( p in params )
				if( p.opt )
					hasOpt = true;
				else
					minParams++;
			var f = function(args:Array<Dynamic>) 
			{			
				if( ( (args == null) ? 0 : args.length ) != params.length ) {
					if( args.length < minParams ) {
						var str = "Invalid number of parameters. Got " + args.length + ", required " + minParams;
						if( name != null ) str += " for function '" + name+"'";
						error(ECustom(str));
					}
					// make sure mandatory args are forced
					var args2 = [];
					var extraParams = args.length - minParams;
					var pos = 0;
					for( p in params )
						if( p.opt ) {
							if( extraParams > 0 ) {
								args2.push(args[pos++]);
								extraParams--;
							} else
								args2.push(null);
						} else
							args2.push(args[pos++]);
					args = args2;
				}
				var old = me.locals, depth = me.depth;
				me.depth++;
				me.locals = me.duplicate(capturedLocals);
				for( i in 0...params.length )
					me.locals.set(params[i].name,{ r : args[i] });
				var r = null;
				var oldDecl = declared.length;
				if( inTry )
					try {
						r = me.exprReturn(fexpr);
					} catch( e : Dynamic ) {
						me.locals = old;
						me.depth = depth;
						#if neko
						neko.Lib.rethrow(e);
						#else
						throw e;
						#end
					}
				else{
					r = me.exprReturn(fexpr);
				}
				restore(oldDecl);
				me.locals = old;
				me.depth = depth;
				return r;
			};
			var f = Reflect.makeVarArgs(f);
			if( name != null ) {
				if( depth == 0 ) {
					// global function
					variables.set(name, f);
				} else {
					// function-in-function is a local function
					declared.push( { n : name, old : locals.get(name) } );
					var ref = { r : f };
					locals.set(name, ref);
					capturedLocals.set(name, ref); // allow self-recursion
				}
			}
			if(d!=null&&d.v)
			{
				dynamicFuncs.set(name,true);
				if(locals.exists(name))
					locals[name].dynamicFunc=true;
			}
			return f;
		case EArrayDecl(arr):
			if (arr.length > 0 && Tools.expr(arr[0]).match(EBinop("=>", _))) {
				var isAllString:Bool = true;
				var isAllInt:Bool = true;
				var isAllObject:Bool = true;
				var isAllEnum:Bool = true;
				var keys:Array<Dynamic> = [];
				var values:Array<Dynamic> = [];
				for (e in arr) {
					switch(Tools.expr(e)) {
						case EBinop("=>", eKey, eValue): {
							var key:Dynamic = expr(eKey);
							var value:Dynamic = expr(eValue);
							isAllString = isAllString && (key is String);
							isAllInt = isAllInt && (key is Int);
							isAllObject = isAllObject && Reflect.isObject(key);
							isAllEnum = isAllEnum && Reflect.isEnumValue(key);
							keys.push(key);
							values.push(value);
						}
						default: throw("=> expected");
					}
				}
				var map:Dynamic = {
					if (isAllInt) new haxe.ds.IntMap<Dynamic>();
					else if (isAllString) new haxe.ds.StringMap<Dynamic>();
					else if (isAllEnum) new haxe.ds.EnumValueMap<Dynamic, Dynamic>();
					else if (isAllObject) new haxe.ds.ObjectMap<Dynamic, Dynamic>();
					else new Map<Dynamic, Dynamic>();
				}
				for (n in 0...keys.length) {
					setMapValue(map, keys[n], values[n]);
				}
				return map;
			}
			else {
				var a = new Array();
				for ( e in arr ) {
					a.push(expr(e));
				}
				return a;
			}
		case EArray(e, index):
			var arr:Dynamic = expr(e);
			var index:Dynamic = expr(index);
			if (isMap(arr)) {
				return getMapValue(arr, index);
			}
			else {
				return arr[index];
			}
		case ENew(cl,params):
			var a = new Array();
			for( e in params )
				a.push(expr(e));
			return cnew(cl,a);
		case EThrow(e):
			throw expr(e);
		case ETry(e,n,_,ecatch):
			var old = declared.length;
			var oldTry = inTry;
			try {
				inTry = true;
				var v : Dynamic = expr(e);
				restore(old);
				inTry = oldTry;
				return v;
			} catch( err : Stop ) {
				inTry = oldTry;
				throw err;
			} catch( err : Dynamic ) {
				// restore vars
				restore(old);
				inTry = oldTry;
				// declare 'v'
				declared.push({ n : n, old : locals.get(n) });
				locals.set(n,{ r : err });
				var v : Dynamic = expr(ecatch);
				restore(old);
				return v;
			}
		case EObject(fl):
			var o = {};
			for( f in fl )
				set(o,f.name,expr(f.e));
			return o;
		case ECoalesce(e1,e2,assign):
			return if (assign) coalesce2(e1,e2) else coalesce(e1,e2);
		case ESafeNavigator(e1, f):
			var e = expr(e1);
			if( e == null )
			 	return null;

			return get(e,f);
		case ETernary(econd,e1,e2):
			return if( expr(econd) == true ) expr(e1) else expr(e2);
		case ESwitch(e, cases, def):
			var val : Dynamic = expr(e);
			var match = false;
			for( c in cases ) {
				for( v in c.values )
				{
					if( ( !Type.enumEq(Tools.expr(v),EIdent("_",false)) && expr(v) == val ) && ( c.ifExpr == null || expr(c.ifExpr) == true ) ) {
						match = true;
						break;
					}
				}
				if( match ) {
					val = expr(c.expr);
					break;
				}
			}
			if( !match )
				val = def == null ? null : expr(def);
			return val;
		case EMeta(n, _, e):
			var e = expr(e);
			return e;
		case ECheckType(e,_):
			return expr(e);
		}
		return null;
	}

	function doWhileLoop(econd,e) {
		var old = declared.length;
		do {
			try {
				expr(e);
			} catch( err : Stop ) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		while( expr(econd) == true );
		restore(old);
	}

	function whileLoop(econd,e) {
		var old = declared.length;
		while( expr(econd) == true ) {
			try {
				expr(e);
			} catch( err : Stop ) {
				switch(err) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		restore(old);
	}

	function makeIterator( v : Dynamic ) : Iterator<Dynamic> {
		#if ((flash && !flash9) || (php && !php7 && haxe_ver < '4.0.0'))
		if ( v.iterator != null ) v = v.iterator();
		#else
		if ( v.iterator != null ) try v = v.iterator() catch( e : Dynamic ) {};
		#end
		if( v.hasNext == null || v.next == null ) error(EInvalidIterator(v));
		return cast v;
	}

	function forLoop(n,it,e) {
		var old = declared.length;
		declared.push({ n : n, old : locals.get(n) });
		var it = makeIterator(expr(it));
		while( it.hasNext() ) {
			locals.set(n,{ r : it.next() });
			try {
				expr(e);
			} catch( err : Stop ) {
				switch( err ) {
				case SContinue:
				case SBreak: break;
				case SReturn: throw err;
				}
			}
		}
		restore(old);
	}

	static inline function isMap(o:Dynamic):Bool {
		var classes:Array<Dynamic> = ["Map", "StringMap", "IntMap", "ObjectMap", "HashMap", "EnumValueMap", "WeakMap"];
		if (classes.contains(o))
			return true;

		return Std.isOfType(o, IMap);
	}

	inline function getMapValue(map:Dynamic, key:Dynamic):Dynamic {
		return cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).get(key);
	}

	inline function setMapValue(map:Dynamic, key:Dynamic, value:Dynamic):Void {
		cast(map, haxe.Constraints.IMap<Dynamic, Dynamic>).set(key, value);
	}

	function get( o : Dynamic, f : String ) : Dynamic {
		if ( o == null ) error(EInvalidAccess(f));
		return {
			var func = StringFunctionTools.getStringToolsFunction(f);
			if( Std.isOfType(o,String) && usingStringTools && func != null )
				return func;
			#if php
				// https://github.com/HaxeFoundation/haxe/issues/4915
				try {
					Reflect.getProperty(o, f);
				} catch (e:Dynamic) {
					Reflect.field(o, f);
				}
			#else
				return Reflect.getProperty(o,f);
			#end
		}
	}

	function set( o : Dynamic, f : String, v : Dynamic ) : Dynamic {
		if( o == null ) error(EInvalidAccess(f));
		/*if( Type.typeof(v) != TFunction ) Reflect.setField(o,f,v); // NEVER USE setField !!
		else*/Reflect.setProperty(o,f,v);
		return v;
	}

	function fcall( o : Dynamic, f : String, args : Array<Dynamic>) : Dynamic {
		var func = stringToolsFunction(o,f,args);
		if( func != null )
			return func;

		return call(o, get(o, f), args);
	}

	function call( o : Dynamic, f : Dynamic, args : Array<Dynamic>) : Dynamic {
		return Reflect.callMethod(o,f,args);
	}

	function cnew( cl : String, args : Array<Dynamic> ) : Dynamic {
		var c : Dynamic = try resolve(cl) catch(e) null;
		if( c == null ) c = Type.resolveClass(cl);
		if( c == null ) error(EInvalidAccess(cl));

		return Type.createInstance(c,args);
	}

	function stringToolsFunction( o : Dynamic , f : String , args : Array<Dynamic> ) : Dynamic {
		var func = StringFunctionTools.getStringToolsFunction(f);
		if( Std.isOfType(o,String) && usingStringTools && func != null )
		{
			if( args == null || args.length == 0 )
				return Reflect.callMethod(StringTools,func,[o]);
			else if( args.length == 1 )
				return Reflect.callMethod(StringTools,func,[o,args[0]]);
			else 
			{
				var array = [o];
				for( i in 0...args.length )
					array.push(Std.string(args[i]));

				return Reflect.callMethod(StringTools,func,array);
			}
		} 

		return null;
	}
}
