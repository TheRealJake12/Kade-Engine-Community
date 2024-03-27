# Creating A Custom Week

## Requirements
1. The ability to compile Kade Engine Community from the source code. All information related to building Kade Engine Communiuty is listed [here.](https://therealjake12.github.io/Kade-Engine-Community/building)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.

**This Does Work With ModCore.**

---
### Step 1. Navigation
Navigate To `Assets/Shared/Data/Weeks`

### Step 2. Creating The JSON

Copy-Paste The Vanilla's Week1.json, Then Change/Rename It To Whatever.
You Should See Something Like This.

```json
{
    "songs": [
        "bopeebo",
        "fresh",
        "dadbattle"
    ],
    "characters": [
        "dad",
        "bf",
        "gf"
    ],
    "weekName": "Daddy Dearest"
}
```

### Step 3. Editing The JSON

Change The Properties Of The JSON. It's Fairly Straightforward.
You Can Change The `characters' to just `"characters": ["", "", ""]` To Make It Have 0 Characters On Screen.

```json
{
    "songs": [
        "song1",
        "song2",
        "song3"
    ],
    "characters": [
        "",
        "",
        ""
    ],
    "weekName": ""
}
```

### Step 4. Week Names

In `assets/shared/data`, there should be a .txt file called `weekNames`. Creating a new line in that file, just enter a string that represents what you want the week to be called.

Example

```
Tutorial
Daddy Dearest
Spooky Month
PICO
MOMMY MUST MURDER
RED SNOW
Hating Simulator ft. Moawling
TANKMAN
```

  Now, compile the game, and if all goes correctly, the Story Mode menu shouldn't crash your game. If you make your way to the bottom of the list, there's your custom week! Except... its displaying as a HaxeFlixel Logo?
  
### Step 5. Graphics
  
Displaying a week icon for your custom week is as simple as dropping a .png into `assets/shared/images/storymenu`. Rename the file to `week7.png`, `week8.png`, etc.

Example

![frrf](https://user-images.githubusercontent.com/68293280/118160164-cdab6d00-b3d2-11eb-9b29-a940eaf45025.png)

![weeks2](https://user-images.githubusercontent.com/55949451/122635129-763fa180-d0e2-11eb-841e-3456e74a50ba.png) \* *for this screenshot I removed tankman from weekCharacters as it would crash because I don't have a tankman character added*
### Conclusion

If you followed all of the steps correctly, you have successfully created a new week in the Story Mode.
