# Custom Characters

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://therealjake12.github.io/Kade-Engine-Community/building)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.



### Step 1. Navigation

Go to ``Assets/Shared/Characters``
add your characters image file and .XML in there
create a character offsets file my making a new txt file and renaming it. then add Offsets ``(example: garcelloOffsets.txt)``
Add 
```txt
idle 0 0
singUP 0 0
singRIGHT 0 0
singLEFT 0 0
singDOWN 0 0
```
to the file.
Because of Kade Engine 1.7 Making Health Icons Use The Week 7 Format, Or Psych Format. Whichever you prefer.
Make the icons in a ``300x150 px`` image. The Image must be a PNG. Put the Icons in ``Assets/Preload/Images/icons``.
Name them what your character is called and make it ``icon-characternamehere``. ``(example: icon-garcello)``
now go to ``Assets/Preload/Data/characterList.txt``
Open the file and at the bottom of the list, add your characters name.

Go to your `source` folder, then open ``Character.hx.``
If your character will have special animations, I'll get to that later.
go to the ``switch (curcharacter)`` thing

### Step 2. The code hardcoding

If your character has standard 4 Directions and Idle Animations, Copy the Dad's Code.
If your character is a Alt skin for BF, Copy his Code.
This is an Example:
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

The barColor is what color the health bar is for your character when you have the option of Character Colored health bars on(default is red)
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

### Extra

If your character has an animation that will play in the middle of a song and it cuts off, Go to ``case 'custom character':`` inside of ``Character.hx``.
Make a case for your character and the animation that will play. Now it *should* not cut off on beat.
