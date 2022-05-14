# MP4 Cutscenes

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://github.com/TheRealJake12/Kade-Engine-1.7-Community/blob/master/docs/building.md)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.

### Step 1. Navigation


Go to Assets/Preload/Videos
Add your MP4 Cutscenes (THEY HAVE TO BE 1280x720p!!!)



### Step 2. Installing [hxCodec](https://lib.haxe.org/p/hxCodec/)

Open A Windows Powershell (Or Command Prompt Either Work).
Once Loaded, Paste ``haxelib install hxCodec 2.5.1 `` Into The Prompt And Let It Install. For MacOS And Linux, I Have No Idea Look [Here](https://github.com/polybiusproxy/hxCodec) For Building Process And Installation. You Have To Install hxCodec For The Engine To Build Regardless But Just In Case.

### Step 3. Playing Cutscenes At The Start Of Your Song.

Go To ``PlayState.hx`` And Type ``playCutscene`` And You Should Find It In The Create Function.
Make A Case Saying Your Song In Lowercase. It Should Look Like This:
```Haxe
switch (curSong.toLowerCase())
{
	case 'yoursong':
		playCutscene('yourcutscene');
	default:
		startCountdown();
}
```

For Adding Aditional Cutscenes For Different Songs, Just Copy The Case For The Cutscene And Rename It For Your Song And Cutscene.