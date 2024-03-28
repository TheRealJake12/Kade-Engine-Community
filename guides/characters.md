# Custom Characters

## Requirements
1. Stupid brain haha funni jsons
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.



### Step 1. Navigation
If you are using mods instead of source code, go to ``YourMod/Shared/Images/Characters/``.
If you are using source code, go to ``Assets/Shared/Images/Characters``
add your characters image file and .XML in there

Because of Kade Engine 1.7 Making Health Icons Use The Week 7 Format, Or Psych Format. Whatever.
Make the icons in a ``300x150 px`` image. The Image must be a PNG. Put the Icons in ``YourMod/Shared/Images/icons``.
Note : If You Have Winning Icons, Make The Image 450x150. For Animated Icons, Make Sure You Have The `iconAnimated` Property Set To True In Your Character's JSON.
If You're Using Source, Go To ``Assets/Shared/Images/Icons`` Instead.
Name them what your character is called and make it ``icon-characternamehere``. ``(example: icon-garcello)``
Make A Folder Called `_append` in Your Mod's primary folder. Then create a system like this : `_append/shared/data/characterList.txt`.
Add your characters name.
### Step 2. The Code

Make A Folder Like This `YourMod/Shared/Data/Characters`
If using source code, Go to `Assets/Shared/Data/Characters`
Copy Daddy Dearest's JSON (`Shared/Data/Characters/Dad.json`)
Replace Everything Dad Related (ie Name, Asset, etc.) With Your Character Name.
It should look a little like this.
```json
{
  "name": "Your Character Name",
  "asset": ["characters/yourChar"],
  "barColor": "#AF66CE",
  "barType": "rgb",
  "rgbArray": [
    175, 
    102, 
    206
  ],
  "iconAnimated": false,
  "flipX":false,
  "flipAnimations":false,
  "deadChar": "",
  "startingAnim": "idle",
  "holdLength": 6.1,
  "camPos": [150, -100],
  "healthicon" : "face",
  "animations": [
    {
      "name": "idle",
      "prefix": "idle dance",
      "offsets": [0, 0]
    },
    {
      "name": "singUP",
      "prefix": "Sing Note UP",
      "offsets": [0, 0]
    },
    {
      "name": "singLEFT",
      "prefix": "Sing Note LEFT",
      "offsets": [0, 0]
    },
    {
      "name": "singRIGHT",
      "prefix": "Sing Note RIGHT",
      "offsets": [0, 0]
    },
    {
      "name": "singDOWN",
      "prefix": "Sing Note DOWN",
      "offsets": [0, 0]
    }
  ]
}
```

The barColor is what color the health bar is for your character when you have the option of Character Colored health bars on(default is red)
it is in hexColor Format so find what color it is in hex code and replace the barColor with that color.

If You Have `barType` set to `RGB`, then it will use RGB instead. Remove it for using hex colors.
Then Change The Numbers To Whatever RGB You Want.  

### Step 3. Alternate Animaitons

You Can Add Extra Animations By Simply Making Another Animation In The JSON. Its Pretty Easy.
```
for each animation to play on a alternate note. You can add the alternate notes in the chart editor.