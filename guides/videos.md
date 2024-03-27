# Video Cutscenes

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://therealjake12.github.io/Kade-Engine-Community/building)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.

## This Does Not Work With ModCore.

### Step 1. Navigation


Go to ``Assets/Videos``
Add your Video Cutscenes
They Can Be Any Format Of Videos.
The Ones Tested And Working Are The Following:
`MP4, WEBM, MOV, MKV`


### Step 2. Installing [hxvlc](https://github.com/MAJigsaw77/hxvlc.git)

Open A Windows Powershell (Or Command Prompt, Either Will Work).
Once Loaded, Paste ```haxelib git hxvlc https://github.com/MAJigsaw77/hxvlc.git``` Into The Prompt And Let It Install. 
For Linux, You're Going To Need To Install Some Libraries. Run These Commands Into The Terminal.
```
sudo apt-get install libvlc-dev
sudo apt-get install libvlccore-dev
sudo apt-get install vlc
```
For Building Process And Installation. You Have To Install hxCodec For The Engine To Build Regardless But Just In Case.

### Step 3. Playing Cutscenes At The Start Of Your Song.

Go To ``PlayState.hx`` And Type ``playCutscene`` And You Should Find It In The Create Function.
Make A Case Saying Your Song In Lowercase. It Should Look Like This:
```Haxe
switch (SONG.songId.toLowerCase())
{
	case 'yoursong':
		playCutscene('yourcutscene.mp4');
	default:
		startCountdown();
}
```

For Adding Aditional Cutscenes For Different Songs, Just Copy The Case For The Cutscene And Rename It For Your Song And Cutscene.
