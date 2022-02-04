## Kade Engine Community
![Kade Engine logo](assets/preload/images/KadeEngineLogoOld.png)

Hey you!
Thanks for visiting this Repo!
This Version of kade Engine is 1.7.1 Pre-Release without the modsupport
The goal of this Repo is to make it community focused. If theres a feature (no modsupport oh my god) just submit a pull request and someone will take a look at it.


![Performance Tab](art/readme/perf.png)

Ultra New Performance Tab includes all the already existing Performance Options but in their own catagory!



![Pause Options](art/readme/optionsbutton.png)

A Options Menu Button to change Keybinds if they arent correct, swap scroll directions, and Turn on Optimization!
this was easy add


![Middlescroll](art/readme/upmiddle.png)

A easier way added in than Kade 1.8. With Fixed Middlescroll for Both Downscroll and Upscroll
Little harder to get used to but the options explain it
![Middlescroll](art/readme/downmiddle.png)

![Better Documented!](art/readme/deez.png)

A goal I want is this to be well documented so if someone doesn't understand something, they can look in docs!

### How To Build From Source

This is a not to in-depth guide to build the game and get your mod going or to contribute to the engine
If you have read the normal building guide from the original engine, it most likely won't work here.
So I will now do a guide to build the game.


### Installing the needed things
1. Install the latest Haxe. Instead of using Haxe 4.1.5, as the original game used, we will update to Haxe 4.2.4 (or the latest version)
You will first need to go to this link to download [Haxe](https://haxe.org/download/) Choose your platform and just do the normal download proccess.
2. Install HaxeFlixel. Once Haxe is installed, you can download HaxeFlixel. Open a Command Prompt (Windows is right click windows icon and hit command prompt or windows powershell) Once its open, run ```haxelib install flixel``` and Flixel will install.
3. Im just gonna quickly add all the librarys you need to download by putting it in a prompt
```
haxelib install lime 7.9.0
haxelib install openfl
haxelib install flixel 4.10.0
haxelib install flixel-tools
haxelib install flixel-ui
haxelib install hscript
haxelib install flixel-addons
haxelib install actuate
haxelib install hxcpp-debug-server
haxelib run lime setup
haxelib run lime setup flixel
haxelib run flixel-tools setup
```
Once you have these installed, you will need [Git](https://git-scm.com/downloads) 
As you did with Haxe, just install the setup and finish it.
HaxeFlixel 4.11.0 Breaks some camera shit or something so lets just use 4.10.0 for now.
When its finished, you will need to download these like you did with the Libraries above.
```
haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit.git
haxelib git hxvm-luajit https://github.com/nebulazorua/hxvm-luajit
haxelib git faxe https://github.com/uhrobots/faxe
haxelib git polymod https://github.com/MasterEric/polymod.git
haxelib git discord_rpc https://github.com/Aidan63/linc_discord-rpc
```
For adding WEBM support, you will need this library but I removed it because WEBM is a piece of shit and is broken
```
haxelib git extension-webm https://github.com/KadeDev/extension-webm
lime rebuild extension-webm windows
```
replace windows with whatever your device is.

4. [Read the original FNF source code guide for Visual Studio](https://github.com/ninjamuffin99/Funkin.git)
Once it is installed you should be able to build your game.

5. Run ```Lime test windows``` or ```Lime test windows -debug```. No debug is the release version that doenst have all the debug stuff, As the debug does.
It will take a while to build for both versions.

6. Play Around with the code and make your mod or consider Contributing to the Engine!

### Shoutouts

- [TheRealJake_12](https://www.youtube.com/channel/UCYy-RfMjVx-1dYnmNQGB2sw) - THE GUY THAT DOES ALL THE WORK

- [KadeDev](https://github.com/KadeDev) - The Original Guy who created Kade Engine

- [Wafles](https://gamebanana.com/mods/330278) The Step Mania Noteskin I used (sorry for stealing lol ._.)

- [HD Note Creators] - I forgor who made them so correct me if you know ( ͡° ͜ʖ ͡°) )

- [TposeJank](https://github.com/tposejank) Epic friend that gave me ideas and helped :epicttrooll:

- [gaminbottomtext](https://github.com/gaminbottomtext) also epic fren that helped with notesplashes :letrollisfefe:

- [discord server for this project](https://discord.gg/G2jJ8RfWtm) thanks for joining if you do.

IF YOU USE THIS SHITTY PROJECT FOR YOUR MOD PLEASE CREDIT ME ON GAMEBANANA!!!!
