package;

import haxe.Exception;

import hscriptBase.*;
import hscriptBase.Expr;

import sys.FileSystem;
import sys.io.File;

typedef SScriptCall = {
    public var ?fileName(default, null):String;
    public var succeeded(default, null):Bool;
    public var calledFunction(default, null):String;
    public var returnValue(default, null):Dynamic;
    public var exceptions(default, null):Array<Exception>;
}

/**
    A simple class for haxe scripts.

    For creating a new script without a file, look at this example.
    ```haxe
    var script:String = "package; private final num:Int = 1; function traceNum() { trace(num); }";
    var sscript:SScript = new SScript().doString(script);
    sscript.call('traceNum', []); // 1
    ```

    If you want to create a new script with a file, look at this example.
    ```haxe
    var script:String = "script.hx";
    var sscript:SScript = new SScript(script);
    sscript.call('traceNum', []);
    ```
**/
@:access(hscriptBase.Interp)
class SScript
{
    /**
        Map of the all created scripts.

        When you create a new script, it will be set in this map, `global`.
    **/
    public static var global(default, null):Map<String, SScript> = new Map();

    /**
        Use this to access to interpreter's variables!
    **/
    public var variables(get, never):Map<String, Dynamic>;

    /**
        Main interpreter and executer. 
    **/
    public var interp(default, null):Interp;

    /**
        An unique parser for the script to parse strings.
    **/
    public var parser:Parser;

    /**
        The script to execute. Gets set automatically if you create a `new` SScript.
    **/
    public var script(default, null):String = "";

    /**
        This variable tells if this script is active or not.

        Set this to false if you do not want your script to get executed!
    **/
    public var active:Bool = true;

    /**
        This string tells you the path of your script file as a read-only string.
    **/
    public var scriptFile(default, null):String = "";

    /**
        If true, enables error traces from the functions.
    **/
    public var traces:Bool = true;

    /**
        If true, enables private access to everything in this script. 
    **/
    public var privateAccess:Bool = true;

    /**
        Package path of this script. Gets set automatically when you use `package`.
    **/
    public var packagePath(default, null):String = "";

    /**
        Creates a new haxe script that will be ready to use after executing.

        @param scriptPath The script path or the script itself.
        @param Preset If true, Sscript will set some useful variables to interp. 
        @param startExecute If true, script will execute itself. If false, it will not execute
        and functions in the script file won't be set to interpreter. 
    **/
    public function new(?scriptPath:String = "", ?preset:Bool = true, ?startExecute:Bool = true)
    {
        if (scriptPath != ""  && scriptPath != null && scriptPath.length > 0)
        {
            if (FileSystem.exists(scriptPath))
            {
                scriptFile = scriptPath;
                script = File.getContent(scriptPath);
            }
            else
                script = scriptPath;
        }

        interp = new Interp();
        interp.setScr(this);

        parser = new Parser();
        parser.script = this;
        parser.setIntrp(interp);
        interp.setPsr(parser);

        if (preset)
            this.preset();

        if (startExecute && scriptPath != "" && scriptPath != null)
            execute();

        if (FileSystem.exists(scriptPath))
            global.set(scriptFile, this);
        else if (script != null && script.length > 0)
            global.set(script, this);
    }

    /**
        Executes this script once.

        If this script does not have any variables set, executing won't do anything.
    **/
    public function execute():Void
    {
        if (interp == null || !active)
            return;

        var expr:Expr = parser.parseString(script, if (scriptFile != null && scriptFile.length > 0) scriptFile else "SScript");
	    interp.execute(expr);
    }
    
    /**
        Sets a variable to this script. 
        
        If `key` already exists it will be replaced.
        
        If you want to set a variable to multiple scripts check the `setOnscripts` function.
        @param key Variable name.
        @param obj The object to set. If the object is a macro class, function will be aborted.
        @return Returns this instance for chaining.
    **/
    public function set(key:String, obj:Dynamic):SScript
    {
        if (Tools.keys.contains(key))
            throw '$key is a keyword, set something else';
        else if (macro.Macro.macroClasses.contains(obj))
            throw '$key cannot be a Macro class';

        if (interp == null || !active)
        {
            if (traces)
            {
                if (interp == null) 
                    trace("This script is unusable!");
                else 
                    trace("This script is not active!");
            }

            return null;
        }

        interp.variables[key] = obj;
        return this;
    }

    /**
        This is a helper function to set classes easily.
        For example, if `cl` is `sys.io.File` it will be set as `File`.
        @param cl The class to set. It cannot be macro classes.
        @return this instance for chaining.
    **/
    public function setClass(cl:Class<Dynamic>):SScript
    {
        if (cl == null)
        {
            if (traces)
            {
                trace('Class cannot be null');
            }

            return null;
        }

        var clName:String = Type.getClassName(cl);
        if (clName.split('.').length > 1)
        {
            clName = clName.split('.')[clName.split('.').length - 1];
        }

        set(clName, cl);
        return this;
    }

    /**
        Sets a class to this script from a string.
        `cl` will be formatted, for example: `sys.io.File` -> `File`.
        @param cl The class to set. It cannot be macro classes.
        @return this instance for chaining.
    **/
    public function setClassString(cl:String):SScript
    {
        if (cl == null || cl.length < 1)
        {
            if (traces)
                trace('Class cannot be null');

            return null;
        }

        var cls:Class<Dynamic> = Type.resolveClass(cl);
        if (cl.split('.').length > 1)
        {
            cl = cl.split('.')[cl.split('.').length - 1];
        }

        if (cls != null)
            set(cl, cls);
        return this;
    }

    /**
        Returns the local variables in this script as a fresh map.
        
        Changing any value in returned map will not change the script in any way.
    **/
    public function locals():Map<String, Dynamic>
    {
        var newMap:Map<String, Dynamic> = new Map();
        for (i in interp.locals.keys())
        {
            var v:Dynamic = interp.locals[i];
            newMap[i] = v;
        }
        return newMap;
    }

    /**
        Unsets a variable from this script. 
        
        If a variable named `key` doesn't exist, unsetting won't do anything.
        @param key Variable name to unset.
        @return Returns this instance for chaining.
    **/
    public function unset(key:String):SScript
    {
        if (interp == null || !active || key == null || !interp.variables.exists(key))
            return null;

        interp.variables.remove(key);
        return this;
    }

    /**
        Gets a variable by name. 
        
        If a variable named as `key` does not exists return is null.
        @param key Variable name.
        @return The object got by name.
    **/
    public function get(key:String):Dynamic
    {
        if (interp == null || !active)
        {
            if (traces)
            {
                if (interp == null) 
                    trace("This script is unusable!");
                else 
                    trace("This script is not active!");
            }

            return null;
        }

        var locals = locals().copy();
        if (locals.exists(key))
            return locals[key];
        
        return if (exists(key)) interp.variables[key] else null;
    }

    /**
        Calls a function from the script file.

        `WARNING:` You MUST execute the script at least once to get the functions to script's interpreter.
        If you do not execute this script and `call` a function, script will ignore your call.
        
        @param func Function name in script file. 
        @param args Arguments for the `func`. If the function does not require arguments, leave it null.
        @return Returns an unique structure that contains called function, returned value etc.
     **/
    public function call(func:String, ?args:Array<Dynamic>):SScriptCall
    {
        var scriptFile:String = if (scriptFile != null && scriptFile.length > 0) scriptFile else "";
        var caller:SScriptCall = {fileName: scriptFile, exceptions: [], calledFunction: func, succeeded: false, returnValue: null};
        if (args == null)
            args = new Array();
        function pushException(e:String)
        {
            caller.exceptions.push(new Exception(e));
        }
        if (func == null)
        {
            if (traces)
                trace('Function name cannot be null for $scriptFile!');

            pushException('Function name cannot be null for $scriptFile!');
            return caller;
        }

        if (args == null)
        {
            if (traces)
                trace('Arguments cannot be null for $scriptFile!');

            pushException('Arguments cannot be null for $scriptFile!');
            return caller;
        }

        if (interp == null || !exists(func))
        { 
            if (traces)
            {
                if (interp == null) 
                {
                    trace('Interpreter is null!');
                    caller.exceptions.push(new Exception('Interpreter is null!'));
                }
                else 
                {    
                    trace('Function $func does not exist in $scriptFile.'); 
                    caller.exceptions.push(new Exception('Function $func does not exist in $scriptFile.'));
                }
            }
            return caller;
        }
        if (Type.typeof(get(func)) != TFunction)
        {
            if (traces)
                trace('$func is not a function');

            caller.exceptions.push(new Exception('$func is not a function'));
            return caller;
        }
        try 
        {
            var functionField:Dynamic = Reflect.callMethod(this, get(func), args);
            caller = {fileName: scriptFile, exceptions: [], calledFunction: func, succeeded: true, returnValue: functionField};
        }
        catch (e) caller.exceptions.push(e);
        
        return caller; 
    }

    /**
        Clears all of the keys assigned to this script.

        @return Returns this instance for chaining.
    **/
    public function clear():SScript
    {
        if (interp == null)
            return this;

        var importantThings:Array<String> = ['true', 'false', 'null', 'trace'];

        for (i in interp.variables.keys())
            if (!importantThings.contains(i))
                interp.variables.remove(i);

        return this;
    }

    /**
        Tells if the `key` exists in this script's interpreter.
        @param key The string to look for.
        @return Returns true if `key` is found in interpreter.
    **/
    public function exists(key:String):Bool
    {
        if (interp == null)
            return false;
        if (interp.locals.exists(key))
            return interp.locals.exists(key);
        
        return interp.variables.exists(key);
    }

    /**
        Sets some useful variables to interp to make easier using this script.
        Override this function to set your custom sets aswell.
    **/
    public function preset():Void
    {
        set('Math', Math);
        set('Std', Std);
        set('StringTools', StringTools);
        set('Sys', Sys);
        set('Date', Date);
        set('DateTools', DateTools);
        set('File', File);
        set('FileSystem', FileSystem);
        set('SScript', SScript);
    }

    /**
        Executes a string once instead of a script file.

        This does not change your `scriptFile` but it changes `script`.

        This function should be avoided whenever possible, when you do a string a lot variables remain unchanged.
        Always try to use a script file.
        @param string String you want to execute.
        @return Returns this instance for chaining.
    **/
    public function doString(string:String):SScript
    {
        if (!active || interp == null)
            return this;
        else if (string == null || string.length < 0)
            return this;

        var expr:Expr = parser.parseString(string, "SScript");
        interp.execute(expr);
        script = string;
        if (!global.exists(script))
            global.set(script, this);
        return this;
    }

	function get_variables():Map<String, Dynamic> 
    {
		return interp.variables;
	}

    function setPackagePath(p):String
    {
        return packagePath = p;
    }
}
