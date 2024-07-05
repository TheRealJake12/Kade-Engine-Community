package kec.backend.modding;

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

	public static var modsToLoad:Array<String> = [];
	#end

	public static function initialize():Void
	{
		#if FEATURE_MODCORE
		Debug.logInfo("Initializing ModCore...");
		initPolymod();
		Polymod.loadOnlyMods(getAllMods());
		#else
		Debug.logInfo("ModCore not initialized; not supported on this platform.");
		#end
	}

	#if FEATURE_MODCORE
	public static function initPolymod()
	{
		Polymod.init({
			// Root directory for all mods.
			modRoot: MOD_DIR,
			// The directories for one or more mods to load.
			dirs: [],
			// Framework being used to load assets. We're using a CUSTOM one which extends the OpenFL one.
			framework: Framework.CUSTOM,
			// Call this function any time an error occurs.
			errorCallback: onPolymodError,
			// Enforce semantic version patterns for each mod.
			// modVersions: null,
			// A map telling Polymod what the asset type is for unfamiliar file extensions.
			// extensionMap: [],

			frameworkParams: buildFrameworkParams(),

			// Use a custom backend so we can get a picture of what's going on,
			// or even override behavior ourselves.
			customBackend: ModCoreBackend,

			// List of filenames to ignore in mods. Use the default list to ignore the metadata file, etc.
			ignoredFiles: Polymod.getDefaultIgnoreList(),

			// Parsing rules for various data formats.
			parseRules: getParseRules(),
			#if html5
			customFilesystem: polymod.fs.MemoryFileSystem
			#end
		});
	}

	public static function getAllMods():Array<String>
	{
		var daList:Array<String> = [];

		#if FEATURE_FILESYSTEM
		if (!FileSystem.exists('mods'))
		{
			Debug.logTrace("Mods Folder Missing. Skipping.");
			return [];
		}
		#end

		for (i in Polymod.scan({modRoot: MOD_DIR, errorCallback: onPolymodError}))
		{
			if (i != null)
			{
				daList.push(i.id);
			}
		}
		modsToLoad = daList;
		return daList != null && daList.length > 0 ? daList : [];
	}

	public static function getParseRules():ParseRules
	{
		var output:ParseRules = ParseRules.getDefault();
		output.addType("txt", TextFileFormat.LINES);
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
