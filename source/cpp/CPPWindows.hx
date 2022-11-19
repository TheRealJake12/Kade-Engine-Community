package cpp;

#if cpp
#if windows
@:buildXml('
    <target id="haxe">
        <lib name="dwmapi.lib" if="windows" />
    </target>
    ')
@:headerCode('
    #include <Windows.h>
    #include <cstdio>
    #include <iostream>
    #include <tchar.h>
    #include <dwmapi.h>
    #include <winuser.h>
    ')
#end
#end
class CPPWindows
{
	#if cpp
	#if windows
	@:functionCode('
        int darkMode = mode;
        HWND window = GetActiveWindow();
        if (S_OK != DwmSetWindowAttribute(window, 19, &darkMode, sizeof(darkMode))) {
            DwmSetWindowAttribute(window, 20, &darkMode, sizeof(darkMode));
        }
        UpdateWindow(window);
    ')
	public static function _setWindowColorMode(mode:Int) {}

	public static function setWindowColorMode(mode:WindowColorMode)
	{
		var darkMode:Int = cast(mode, Int);

		if (darkMode > 1 || darkMode < 0)
		{
			trace("WindowColorMode Not Found...");

			return;
		}

		_setWindowColorMode(darkMode);
	}

	@:functionCode('
	HWND window = GetActiveWindow();
	SetWindowLong(window, GWL_EXSTYLE, GetWindowLong(window, GWL_EXSTYLE) ^ WS_EX_LAYERED);
	')
	@:noCompletion
	public static function _setWindowLayered() {}

	@:functionCode('
        HWND window = GetActiveWindow();

		float a = alpha;

		if (alpha > 1) {
			a = 1;
		} 
		if (alpha < 0) {
			a = 0;
		}

       	SetLayeredWindowAttributes(window, 0, (255 * (a * 100)) / 100, LWA_ALPHA);

    ')
	/**
	 * Set Whole Window's Opacity
	 * ! MAKE SURE TO CALL _setWindowLayered(); BEFORE RUNNING THIS
	 * @param alpha 
	 */
	public static function setWindowAlpha(alpha:Float)
	{
		return alpha;
	}

	@:functionCode("
		unsigned long long allocatedRAM = 0;
		GetPhysicallyInstalledSystemMemory(&allocatedRAM);
		return (allocatedRAM / 1024);
	")
	public static function obtainRAM():UInt64
	{
		return 0;
	}

	// ! https://github.com/brightfyregit/Indie-Cross-Public/blob/master/source/SpecsDetector.hx#L87-L102
	public static function messageBox(msg:ConstCharStar = null, title:ConstCharStar = null, ?handler:Null<Int->Void>)
	{
		var msgID:Int = untyped MessageBox(null, msg, title, untyped __cpp__("MB_ICONERROR | MB_OK"));

		if (handler != null)
			handler(msgID);

		return true;
	}
	#end
	#end
}

#if windows
@:enum abstract WindowColorMode(Int)
{
	var DARK:WindowColorMode = 1;
	var LIGHT:WindowColorMode = 0;
}
#end
