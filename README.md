## **Funkin' In The Alley**
hi no leake


**I am not responsible for maintaining HTML5 builds, as long as it builds sucessfully, it is not my problem. Feel free to fix it if it's broken yourself.**

### How to build from source

This is a not to in-depth guide to build the game and get your mod going or to contribute to the engine.
If you have read the normal building guide from the original engine, it most likely won't work here.
So I will now do a guide to build the game.


### Installing the needed things
1. Install the latest Haxe. Instead of using Haxe 4.1.5, as the original game used, we will update to Haxe 4.2.5 (4.3.0 might work, if you adjust things a bit.) (or the latest version).
You will first need to go to this link to download [Haxe](https://haxe.org/download/). Choose your platform and just do the normal download process.
2. Install HaxeFlixel. Once Haxe is installed, you can download HaxeFlixel. Open a Command Prompt (Windows is right click windows icon and hit command prompt or windows powershell).
3. You will need [Git](https://git-scm.com/downloads) 
As you did with Haxe, just install the setup and finish it.
4. I'm just gonna quickly add all the libraries you need to download by putting it in a prompt:
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
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel-tools setup
```
Once you have these installed, 
HaxeFlixel 4.11.0 breaks some shader shit or something so I went ahead and made it use a custom file that fixes the issue.
(FlxDrawQuadsItem or smth)
When it's finished, you will need to download these like you did with the libraries above.
```cmd
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git
haxelib git hxvm-luajit https://github.com/nebulazorua/hxvm-luajit
haxelib git faxe https://github.com/uhrobots/faxe
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
haxelib git hxCodec https://github.com/TheRealJake12/hxCodec.git
```
4. [Read the original FNF source code guide for Visual Studio just in case.](https://github.com/ninjamuffin99/Funkin)
Once it is installed you should be able to build your game.

**IF YOU ARE LAZY JUST USE THE EASYSETUP.BAT IN THE CODE!**

5. Run ```lime test windows``` or ```lime test windows -debug```. The version without the debugger is the release version that doesn't have all the debug stuff, As the debug version does.
It will take a while to build for both versions.

6. Play around with the code or consider contributing to the mod/engine!

![lime windows](https://user-images.githubusercontent.com/84357907/192084304-397d651c-8f11-4f42-9596-18dcabe79eaf.gif)

### Shoutouts

- 
- [TheRealJake_12](https://www.youtube.com/channel/UCYy-RfMjVx-1dYnmNQGB2sw) - KEC Creator

- [KadeDev](https://github.com/KadeDev) - OG Kade Engine Creator

- [PolybiusProxy](https://github.com/polybiusproxy) - The video support.

- [BoloVEVO](https://github.com/BoloVEVO) - Fixed my shit code and improved the chart editor. Made a ton of code improvements. Did the gameplay changers. (thanks!!!)

- Glowsoony - Pixel note splashes, revamped note splash code, hscript, the guy does a ton. (Thanks!)

- LunarCleint - Hscript code, like, all of it.

- [ShadowMario](https://github.com/ShadowMario) - The Memory Leak Fix. And A Few Other Things. (thanks)

- [TposeJank](https://github.com/tposejank) Epic friend that gave me ideas and helped :epicttrooll:

- [gaminbottomtext](https://github.com/gaminbottomtext) also epic fren that helped with notesplashes. He has disappeared.

- [AhmedxRNMD](https://twitter.com/AhmedxRNMD_) - Made the volume sounds.

- [discord server for this mod](https://discord.gg/PYqRwbD4es) thanks for joining if you do.
