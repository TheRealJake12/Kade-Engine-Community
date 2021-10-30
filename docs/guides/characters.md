# Custom Characters

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://github.com/TheRealJake12/Kade-Engine-1.7-Community/blob/master/docs/building.md)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.



### Step 1. Navigation

Go to Assets/Shared/Characters
add your characters image file and .XML in there
create a character offsets file my making a new txt file and renaming it. then add Offsets (example: garcelloOffsets.txt)
Because of the 1.7 LUA thing we gotta do some extra work to the health icons
make sure the image is 300x150px and draw the icons, put them in Assets/Preload/Images/icons. IT HAS TO BE A PNG!!!
Name them what your character is called and make it icon-characternamehere. (example: icon-garcello)
now go to Assets/Preload/Data/characterList.txt
simpley add you character to the list. done



Go to your source folder, then open Character.hx.
If your character will have special animations, ill get to that later.
go to the switch (curcharacter) thing

### Step 2. The code hardcoding

You will find a lot of Case Statements, if you character is a enemy character (dad, mom, etc.)

If your character will only have the idle animations and the note animations, just copy the dads but replace the dad with your character name
Example:
```haxe
case 'characterhere':
// your character code here
tex = Paths.getSparrowAtlas('characterhere', 'shared', true);
frames = tex;
animation.addByPrefix('idle', 'characterhere idle dance', 24, false);
animation.addByPrefix('singUP', 'characterhere Sing Note UP', 24, false);
animation.addByPrefix('singRIGHT', 'characterhere Sing Note RIGHT', 24, false);
animation.addByPrefix('singDOWN', 'characterhere Sing Note DOWN', 24, false);
animation.addByPrefix('singLEFT', 'characterhere Sing Note LEFT', 24, false);

loadOffsetFile(curCharacter);
barColor = 0xFFaf66ce;
```
There is Offsets as I mentioned earlier, and make each animation 0 0 for testing and mess with them to your liking
Example:
```haxe
idle 0 0
singUP 0 0
singRIGHT 0 0
singLEFT 0 0
singDOWN 0 0
```

the barColor is what color the health bar is for your character when you have the option of Character Colored health bars on(default is red)
it is in hexColor Format so find what color it is in hex code and replace the barColor with that color.


### Step 3. Alternate Animaitons

If your character has different animations to be played when singing
go to the case for your character, and add
```haxe

animation.addByPrefix('singUP-alt', 'characterhere Sing Note UP', 24, false);
animation.addByPrefix('singRIGHT-alt', 'characterhere Sing Note RIGHT', 24, false);
animation.addByPrefix('singLEFT-alt', 'characterhere Sing Note LEFT', 24, false);
animation.addByPrefix('singDOWN-alt', 'characterhere Sing Note DOWN', 24, false);
```
for any animation that is alternate, remember to replace the characterhere with your own character name in the XML
the Offsets apply to the alt animations, just add
```haxe
singUP-alt 0 0
singRIGHT-alt 0 0
singLEFT-alt 0 0
singDOWN-alt 0 0
```
for each animation to play on a alternate note. You can add the alternate notes in the chart editor.


