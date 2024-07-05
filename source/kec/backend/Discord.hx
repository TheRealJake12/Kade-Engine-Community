package kec.backend;

#if FEATURE_DISCORD
import hxdiscord_rpc.Discord as RichPresence;
import hxdiscord_rpc.Types;
import openfl.Lib;
import sys.thread.Thread;

class Discord
{
	public static var initialized(default, null):Bool = false;

	public static function load():Void
	{
		if (initialized)
			return;

		var handlers:DiscordEventHandlers = DiscordEventHandlers.create();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		RichPresence.Initialize("898970552600002561", cpp.RawPointer.addressOf(handlers), 1, null);

		// Daemon Thread
		Thread.create(function()
		{
			while (true)
			{
				#if DISCORD_DISABLE_IO_THREAD
				RichPresence.UpdateConnection();
				#end
				RichPresence.RunCallbacks();

				// Wait 0.5 seconds until the next loop...
				Sys.sleep(0.5);
			}
		});

		Lib.application.onExit.add((exitCode:Int) -> RichPresence.Shutdown());

		initialized = true;
	}

	public static function changePresence(details:String, ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		var discordPresence:DiscordRichPresence = DiscordRichPresence.create();
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		discordPresence.details = details;

		if (state != null)
			discordPresence.state = state;

		discordPresence.largeImageKey = "icon";
		discordPresence.largeImageText = '${MainMenuState.kecVer}';
		discordPresence.smallImageKey = smallImageKey;
		// Obtained times are in milliseconds so they are divided so Discord can use it
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		RichPresence.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		final user:cpp.Star<DiscordUser> = cpp.ConstPointer.fromRaw(request).ptr;

		if (Std.parseInt(cast(user.discriminator, String)) != 0)
			Debug.logInfo('(Discord) Connected to User "${cast (user.username, String)}#${cast (user.discriminator, String)}"');
		else
			Debug.logInfo('(Discord) Connected to User "${cast (user.username, String)}"');

		Discord.changePresence('Just Started');
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		Debug.logInfo('(Discord) Disconnected ($errorCode: ${cast (message, String)})');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('(Discord) Error ($errorCode: ${cast (message, String)})');
		// spammed with """errors"""
	}
}
#end
