#if FEATURE_MODCORE
import polymod.backends.OpenFLBackend;
import polymod.backends.PolymodAssets.PolymodAssetType;
import polymod.format.ParseRules.LinesParseFormat;
import polymod.format.ParseRules.TextFileFormat;
import polymod.format.ParseRules;
import polymod.Polymod;
#end
#if FEATURE_FILESYSTEM
import sys.FileSystem;
#end
import flixel.FlxG;

/**
 * Okay now this is epic.
 */
class ModCore
{
	private static final MOD_DIR:String = 'mods';
	static final API_VERSION = "0.1.0";

	#if FEATURE_MODCORE
	private static final extensions:Map<String, PolymodAssetType> = [
		'mp3' => AUDIO_GENERIC,
		'ogg' => AUDIO_GENERIC,
		'png' => IMAGE,
		'xml' => TEXT,
		'txt' => TEXT,
		'ttf' => FONT,
		'otf' => FONT,
		'mp4' => VIDEO
	];

	public static var trackedMods:Array<ModMetadata> = [];
	#end

	public static function initialize():Void
	{
		#if FEATURE_MODCORE
		Debug.logInfo("Initializing ModCore...");
		loadMods(getMods());
		#else
		Debug.logInfo("ModCore not initialized; not supported on this platform.");
		#end
	}

	#if FEATURE_MODCORE
	public static function loadMods(folders:Array<String>):Void
	{
		Debug.logTrace('Attempting to load ${trackedMods.length} mods...');
		var loadedModlist:Array<ModMetadata> = Polymod.init({
			modRoot: MOD_DIR,
			dirs: folders,
			framework: CUSTOM,
			frameworkParams: buildFrameworkParams(),
			errorCallback: onPolymodError,
			parseRules: getParseRules(),
			extensionMap: extensions,
			customBackend: ModCoreBackend,
			ignoredFiles: Polymod.getDefaultIgnoreList()
		});

		if (loadedModlist == null)
			return;

		trace('Loading Successful, ${loadedModlist.length} / ${folders.length} new mods.');

		for (mod in loadedModlist)
			trace('Name: ${mod.title}, [${mod.id}]');
	}

	public static function getMods():Array<String>
	{
		trackedMods = [];

		var daList:Array<String> = [];

		trace('Searching for Mods...');
		if (!FileSystem.exists('mods'))
		{
			Debug.logTrace("Mods Folder Missing. Skipping.");
			return [];
		}

		for (i in Polymod.scan({modRoot: MOD_DIR, errorCallback: onPolymodError}))
		{
			if (i != null)
			{
				trackedMods.push(i);
				daList.push(i.id);
			}
		}

		if (daList != null && daList.length > 0)
			trace('Found ${daList.length} new mods.');

		return daList != null && daList.length > 0 ? daList : [];
	}

	public static function getParseRules():ParseRules
	{
		var output:ParseRules = ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
		output.addType("hx", TextFileFormat.PLAINTEXT);
		output.addType("lua", TextFileFormat.PLAINTEXT);
		return output != null ? output : null;
	}

	static inline function buildFrameworkParams():polymod.FrameworkParams
	{
		return {
			assetLibraryPaths: [
				"default" => "./shared", // ./preload
				"sm" => "./sm",
				"songs" => "./songs",
				"shared" => "./shared",
				"videos" => "./videos",
				"scripts" => "./scripts",
				"weeks" => "./",
			]
		}
	}

	static function onPolymodError(error:PolymodError):Void
	{
		// Perform an action based on the error code.
		switch (error.code)
		{
			case MISSING_ICON:

			default:
				// Log the message based on its severity.
				switch (error.severity)
				{
					case NOTICE:
						Debug.logInfo(error.message, null);
					case WARNING:
						Debug.logWarn(error.message, null);
					case ERROR:
						Debug.logError(error.message, null);
				}
		}
	}
	#end
}

#if FEATURE_MODCORE
class ModCoreBackend extends OpenFLBackend
{
	public function new()
	{
		super();
		// Debug.logTrace('Initialized custom asset loader backend.');
	}

	public override function clearCache()
	{
		Paths.runGC();
		super.clearCache();
		// Debug.logInfo('Custom asset cache has been cleared.');
	}

	public override function exists(id:String):Bool
	{
		// Debug.logTrace('Call to ModCoreBackend: exists($id)');
		return super.exists(id);
	}

	public override function getBytes(id:String):lime.utils.Bytes
	{
		// Debug.logTrace('Call to ModCoreBackend: getBytes($id)');
		return super.getBytes(id);
	}

	public override function getText(id:String):String
	{
		// Debug.logTrace('Call to ModCoreBackend: getText($id)');
		return super.getText(id);
	}

	public override function list(type:PolymodAssetType = null):Array<String>
	{
		// Debug.logTrace('Listing assets in custom asset cache ($type).');
		return super.list(type);
	}
}
#end
