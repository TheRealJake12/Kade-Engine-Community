package mobile;

import lime.system.System as LimeSystem;
import haxe.Exception;
import lime.app.Application;

/**
 * A storage class for mobile.
 * @author Mihai Alexandru (M.A. Jigsaw)
 */
class SUtil
{
	#if sys
	public static function getStorageDirectory():String
	{
		var daPath:String = '';
		#if android
		daPath = AndroidBuild.VERSION.SDK_INT > 30 ? AndroidContext.getObbDir() : AndroidContext.getExternalFilesDir()
		daPath = haxe.io.Path.addTrailingSlash(daPath);
		#elseif ios
		daPath = LimeSystem.documentsDirectory;
		#else
        daPath = Sys.getCwd();
        #end

		return daPath;
	}

	public static function mkDirs(directory:String):Void
	{
		var total:String = '';
		if (directory.substr(0, 1) == '/')
			total = '/';

		var parts:Array<String> = directory.split('/');
		if (parts.length > 0 && parts[0].indexOf(':') > -1)
			parts.shift();

		for (part in parts)
		{
			if (part != '.' && part != '')
			{
				if (total != '' && total != '/')
					total += '/';

				total += part;

				try
				{
					if (!FileSystem.exists(total))
						FileSystem.createDirectory(total);
				}
				catch (e:Exception)
					trace('Error while creating folder. (${e.message}');
			}
		}
	}

	public static function saveContent(fileName:String = 'file', fileExtension:String = '.json',
			fileData:String = 'You forgor to add somethin\' in yo code :3'):Void
	{
		try
		{
			if (!FileSystem.exists('saves'))
				FileSystem.createDirectory('saves');

			File.saveContent('saves/' + fileName + fileExtension, fileData);
			Application.current.window.alert(fileName + " file has been saved.", "Success!");
		}
		catch (e:Exception)
			trace('File couldn\'t be saved. (${e.message})');
	}

	#if android
	public static function doPermissionsShit():Void
	{
		if (!AndroidPermissions.getGrantedPermissions().contains('android.permission.READ_EXTERNAL_STORAGE')
			&& !AndroidPermissions.getGrantedPermissions().contains('android.permission.WRITE_EXTERNAL_STORAGE'))
		{
			AndroidPermissions.requestPermission('READ_EXTERNAL_STORAGE');
			AndroidPermissions.requestPermission('WRITE_EXTERNAL_STORAGE');
			Application.current.window.alert('If you accepted the permissions you are all good!' + '\nIf you didn\'t then expect a crash' + '\nPress Ok to see what happens',
				'Notice!');
			if (!AndroidEnvironment.isExternalStorageManager())
				AndroidSettings.requestSetting('MANAGE_APP_ALL_FILES_ACCESS_PERMISSION');
		}
		else
		{
			try
			{
				if (!FileSystem.exists(SUtil.getStorageDirectory()))
					FileSystem.createDirectory(SUtil.getStorageDirectory());
			}
			catch (e:Dynamic)
			{
				Application.current.window.alert('Please create folder to\n' + SUtil.getStorageDirectory(true) + '\nPress OK to close the game', 'Error!');
				LimeSystem.exit(1);
			}
		}
    }
	#end

    public static function readDirectory(directory:String):Array<String>
        {
            #if desktop
            return FileSystem.readDirectory(directory);
            #else
            var dirsWithNoLibrary = Assets.list().filter(folder -> folder.startsWith(directory));
            var dirsWithLibrary:Array<String> = [];
            for(dir in dirsWithNoLibrary)
            {
                @:privateAccess
                for(library in lime.utils.Assets.libraries.keys())
                {
                    if(Assets.exists('$library:$dir') && library != 'default' && (!dirsWithLibrary.contains('$library:$dir') || !dirsWithLibrary.contains(dir)))
                        dirsWithLibrary.push('$library:$dir');
                    else if(Assets.exists(dir) && !dirsWithLibrary.contains(dir))
                            dirsWithLibrary.push(dir);
                }
            }
            return dirsWithLibrary;
            #end
        }
	#end
}