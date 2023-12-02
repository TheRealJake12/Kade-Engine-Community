This is a not to in-depth guide to build the game and get your mod going or to contribute to the engine
If you have read the normal building guide from the original engine, it most likely won't work here.
So I will now do a guide to build the game.


### Installing the needed things
1. Install the latest Haxe. Instead of using Haxe 4.1.5, as the original game used, we will update to Haxe 4.3.3 (or the latest version)
You will first need to go to this link to download [Haxe](https://haxe.org/download/) Choose your platform and just do the normal download proccess.
2. Install HaxeFlixel. Once Haxe is installed, you can download HaxeFlixel. Open a Command Prompt (Windows is right click windows icon and hit command prompt or windows powershell).
3. You will need [Git](https://git-scm.com/downloads) 
As you did with Haxe, just install the setup and finish it.
4. I'm just gonna quickly add all the libraries you need to download by putting it in a prompt
```cmd
haxelib install lime
haxelib install openfl
haxelib install flixel
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install hscript
haxelib install flixel-addons
haxelib install actuate
haxelib install hxcpp-debug-server
haxelib install polymod 1.7.0
haxelib install tjson
haxelib install SScript
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel-tools setup
```
When its finished, you will need to download these like you did with the Libraries above.
```cmd
haxelib git linc_luajit https://github.com/superpowers04/linc_luajit
haxelib git faxe https://github.com/uhrobots/faxe
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc.git
```

3.5 (Optional) If you're on Linux, you may be missing some libraries required to compile properly. Run these commands to fix some issues commonly reported.
```
sudo apt install build-essential
sudo apt install luajit
```

You need to install libvlc for hxCodec to work on Linux.
```
sudo apt-get install libvlc-dev libvlccore-dev 
```
4. [Read the original FNF source code guide for Visual Studio](https://github.com/ninjamuffin99/Funkin.git)
Once it is installed you should be able to build your game.

5. Run ```lime test windows``` or ```lime test windows -debug```. No debug is the release version that doenst have all the debug stuff, As the debug does.
It will take a while to build for both versions.

![lime windows](https://user-images.githubusercontent.com/84357907/192084304-397d651c-8f11-4f42-9596-18dcabe79eaf.gif)
