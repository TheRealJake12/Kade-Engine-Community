# Optimization

## Requirements
1. The Simple Ability To Copy Code.
Not Required If You Are Using Modcore.


### Step 1. Characters

Go to Assets/Shared/Characters

Remove all of the character files you dont need (Mom, Pico, Spookeez, etc.)
The Code Shouldnt matter but Keep the BF, GF, And The Dad in your Character Files

Go To Assets/Preload/Images/Icons

Delete the icons you won't need (Senpai, Monster, Tankman, etc.)
Keep the blank face icon and the sm icon (If you wish to keep StepMania support)

Go To Assets/Preload/Data/characterList.txt

Delete the characters that you won't use.(Spirit, Pico-Speaker, Mom-car, etc.)


### Step 2. Charts

Go To Assets/Preload/Data/Songs

Delete the charts you won't use. I reccomend keeping the week 1 songs for placeholders.

Keep one if you dont have the charts set for being used.

### Step 3. Song Files

Go To Assets/Songs

Delete All Songs You Won't Use. I Recommend Keeping Week 1 Songs As Placeholders.


### Step 4. Export Files

The Files will still be there in the export folder so you gonna wanna delete bin. Then Recompile your game.

### Step 5. Code Things.

States : Add
```Haxe
Paths.clearStoredMemory();
Paths.clearUnusedMemory();
```
at the top of the create function for your state.

and
```Haxe
Paths.clearUnusedMemory();
```
at the bottom. This makes memory management better.

General : Don't use 4k images for everything. This makes VRAM and RAM usage go obserdly high. Try downscaling and compressing images. 
