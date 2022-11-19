package cpp;

import cpp.ConstCharStar;
import cpp.Native;
import cpp.UInt64;

#if cpp
#if linux
@:headerCode("#include <stdio.h>")
#end
#end
class CPPLinux
{
	#if cpp
	#if linux
	@:functionCode('
		FILE *meminfo = fopen("/proc/meminfo", "r");

    	if(meminfo == NULL)
			return -1;

    	char line[256];
    	while(fgets(line, sizeof(line), meminfo))
    	{
        	int ram;
        	if(sscanf(line, "MemTotal: %d kB", &ram) == 1)
        	{
            	fclose(meminfo);
            	return (ram / 1024);
        	}
    	}

    	fclose(meminfo);
    	return -1;
	')
	public static function obtainRAM():UInt64
	{
		return 0;
	}
	#end
	#end
}
