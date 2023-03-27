package macro;

import haxe.macro.Compiler;
import haxe.macro.ComplexTypeTools;
import haxe.macro.Context;
import haxe.macro.ExprTools;
import haxe.macro.MacroStringTools;
import haxe.macro.Printer;
import haxe.macro.TypeTools;
import haxe.macro.TypedExprTools;

class Macro
{
    public static var macroClasses:Array<Class<Dynamic>> = [
        Compiler, Context, MacroStringTools, Printer, ComplexTypeTools, 
        TypedExprTools, ExprTools, TypeTools,
    ];

    macro public static function turnDCEOff() 
    {
        var defines = Context.getDefines();
        if (defines.exists('dce') && defines['dce'] != 'no')
        {
            Sys.println('Dead Code Elimination (DCE) is ${defines['dce']}, meaning it can cause minor issues with SScript.');
            Sys.println('Turning off DCE is not mandatory but it is strongly recommended.');
        }
        return macro null;    
    }
}
