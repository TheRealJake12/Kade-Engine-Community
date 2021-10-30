# MP4 Cutscenes

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://github.com/TheRealJake12/Kade-Engine-1.7-Community/blob/master/docs/building.md)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.




### Step 1. Navigation


Go to Assets/Videos
Add your MP4 Cutscenes (THEY HAVE TO BE 1280x720p!!!)



### Step 2. What Cutscene goes where


If your cutscene plays at the beginning of a week, go to StoryMenuState.hx 
Hit CTRL + F and type if (curWeek == 14 && !isCutscene)
That Line is the statement that decides if a video plays once the week starts.
You can add multiple Cutscenes if nessacary. (idk if theres a limit lol)
For the most part the code is already in place I just changed some things so it wouldn't break anything.
Change the 14 to whatever week (0 == tutorial or the very first week, 1 == week1 etc.)
For adding multiple cutscenes, just copy this and replace the else with the lines below
```haxe
else if (curWeek == 1 && !isCutscene) // change the 1 to whatever week you are using
	new FlxTimer().start(1, function(tmr:FlxTimer)// the timer lets it kinda load. load == optimization for lowend user as myself
		{
			{
				video.playMP4(Paths.video('yourcutscene'));
				video.finishCallback = function()
			    {
					LoadingState.loadAndSwitchState(new PlayState());
				}
		isCutscene = true;
	}
});
else //remember to add a if then the rest of the code for multi cutscenes for different weeks!
			{
				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (isCutscene)
						video.onVLCComplete();

					LoadingState.loadAndSwitchState(new PlayState(), true);
				});
			}
```


For Having cutscenes play after specific songs, go to PlayState.hx.
Press CTRL + F and type if (curSong == 'yoursonghere' && !isCutscene)
As with the StoryMenuState code, if you want another cutscene, just make an else if statement and copy the already existing playstate code for the else if.

WARNING!!!

Only Play After the Second Song of the week!
If it hasn't been tested but if you have a cutscene in the storymenu and the playstate for the same week, it breaks stuff from current testing.


### Step 3. If I documented this poorly



Make a Fork and a Pull Request to maybe fix it!