import openfl.system.System;

#if windows
@:cppFileCode('#include <windows.h>\n#include <psapi.h>')
#end
class MemoryUtil
{
	// https://stackoverflow.com/questions/63166/how-to-determine-cpu-and-memory-consumption-from-inside-a-process
	// TODO: Adapt code for the other platforms. Wrote it for windows and html5 because they're the only ones I can test kek.
	#if windows
	@:functionCode('

		PROCESS_MEMORY_COUNTERS_EX pmc;
		if (GetProcessMemoryInfo(GetCurrentProcess(), (PROCESS_MEMORY_COUNTERS*)&pmc, sizeof(pmc))){
			
			int convertData = static_cast<int>(pmc.WorkingSetSize);
			return convertData;
		}
		else 
			return 0;
		')
	static function getWindowsMemory():Int
	{
		return 0;
	}
	#end

	#if html5
	static function getJSMemory():Int
	{
		return js.Syntax.code("window.performance.memory.usedJSHeapSize");
	}
	#end

	public static function getMemoryfromProcess():Int
	{
		#if windows
		return getWindowsMemory();
		#elseif html5
		return getJSMemory();
		#else
		return System.totalMemory;
		#end
	}
}
