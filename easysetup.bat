@echo off
title KEC Setup - Start
echo Make sure Haxe 4.2.5 or 4.3.4 and HaxeFlixel is installed.
echo Press any key to install required libraries.
pause >nul
title KEC Setup - Installing libraries
echo Installing haxelib libraries...
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-tools
haxelib install flixel-addons
haxelib install hxcpp-debug-server
haxelib install hxvlc
haxelib install hscript
haxelib install flixel-text-input
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel-tools setup
title KEC Setup - User action required
cls
echo Make sure you have git installed. You can download it here: https://git-scm.com/downloads
echo Press any key to install the git libraries.
pause >nul
title KEC Setup - Installing libraries
haxelib git polymod https://github.com/swordcube/scriptless-polymod.git
haxelib git tjson https://github.com/EliteMasterEric/TJSON.git
haxelib git hscript-improved https://github.com/FNF-CNE-Devs/hscript-improved.git
haxelib git haxeui-core https://github.com/haxeui/haxeui-core.git --skip-dependencies
haxelib git haxeui-flixel https://github.com/haxeui/haxeui-flixel.git --skip-dependencies
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git
haxelib git hxdiscord_rpc https://github.com/MAJigsaw77/hxdiscord_rpc.git
cls

title KEC Setup - User action required
set /p menu="Would you like to install Visual Studio Community and components? (Necessary to compile/ 5.5GB) [Y/N]"
       if %menu%==Y goto InstallVSCommunity
       if %menu%==y goto InstallVSCommunity
       if %menu%==N goto SkipVSCommunity
       if %menu%==n goto SkipVSCommunity
       cls


:SkipVSCommunity
cls
title KEC Setup - Success
echo Setup successful. Press any key to exit.
pause >nul
exit

cls
gotoInstallVSCommunity

:InstallVSCommunity
title KEC Setup - Installing Visual Studio Community
curl -# -O https://download.visualstudio.microsoft.com/download/pr/3105fcfe-e771-41d6-9a1c-fc971e7d03a7/8eb13958dc429a6e6f7e0d6704d43a55f18d02a253608351b6bf6723ffdaf24e/vs_Community.exe
vs_Community.exe --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 --add Microsoft.VisualStudio.Component.Windows10SDK.19041 -p
del vs_Community.exe
goto SkipVSCommunity
