#if !macro
import Paths;
import flixel.*;
import flixel.sound.FlxSound;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxPoint;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import tjson.TJSON as Json;
import flixel.input.keyboard.FlxKey;

#if android
import android.content.Context as AndroidContext;
import android.widget.Toast as AndroidToast;
import android.os.Environment as AndroidEnvironment;
import android.Permissions as AndroidPermissions;
import android.Settings as AndroidSettings;
import android.Tools as AndroidTools;
import android.os.BatteryManager as AndroidBatteryManager;
import android.os.Build as AndroidBuild;
import android.os.Build.VERSION as AndroidVersion;
#end
import mobile.SUtil;
#end

using StringTools;
