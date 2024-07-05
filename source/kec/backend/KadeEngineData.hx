package kec.backend;

import lime.app.Application;
import openfl.Lib;

class KadeEngineData
{
	public static function initSave()
	{
		if (FlxG.save.data.weekUnlocked == null)
			FlxG.save.data.weekUnlocked = 7;

		if (FlxG.save.data.newInput == null)
			FlxG.save.data.newInput = true;

		if (FlxG.save.data.downscroll == null)
			FlxG.save.data.downscroll = false;

		if (FlxG.save.data.antialiasing == null)
			FlxG.save.data.antialiasing = true;

		if (FlxG.save.data.missSounds == null)
			FlxG.save.data.missSounds = true;

		if (FlxG.save.data.accuracyDisplay == null)
			FlxG.save.data.accuracyDisplay = true;

		if (FlxG.save.data.offset == null)
			FlxG.save.data.offset = 0;

		if (FlxG.save.data.songPosition == null)
			FlxG.save.data.songPosition = false;

		if (FlxG.save.data.fps == null)
			FlxG.save.data.fps = true;

		if (FlxG.save.data.changedHitX == null)
			FlxG.save.data.changedHitX = FlxG.width * 0.55 - 135;

		if (FlxG.save.data.changedHitY == null)
			FlxG.save.data.changedHitY = FlxG.height / 2 - 50;

		if (FlxG.save.data.fpsCap == null)
			FlxG.save.data.fpsCap = 60;

		if (FlxG.save.data.scrollSpeed == null)
			FlxG.save.data.scrollSpeed = 1;

		if (FlxG.save.data.npsDisplay == null)
			FlxG.save.data.npsDisplay = false;

		if (FlxG.save.data.frames == null)
			FlxG.save.data.frames = 10;

		if (FlxG.save.data.accuracyMod == null)
			FlxG.save.data.accuracyMod = 1;

		if (FlxG.save.data.watermark == null)
			FlxG.save.data.watermark = true;

		if (FlxG.save.data.ghost == null)
			FlxG.save.data.ghost = true;

		if (FlxG.save.data.quality == null)
			FlxG.save.data.quality = true;

		if (FlxG.save.data.colour == null)
			FlxG.save.data.colour = true;

		if (FlxG.save.data.stepMania == null)
			FlxG.save.data.stepMania = false;

		if (FlxG.save.data.flashing == null)
			FlxG.save.data.flashing = true;

		if (FlxG.save.data.resetButton == null)
			FlxG.save.data.resetButton = false;

		if (FlxG.save.data.InstantRespawn == null)
			FlxG.save.data.InstantRespawn = false;

		if (FlxG.save.data.botplay == null)
			FlxG.save.data.botplay = false;

		if (FlxG.save.data.cpuStrums == null)
			FlxG.save.data.cpuStrums = false;

		if (FlxG.save.data.smoothHealthbar == null)
			FlxG.save.data.smoothHealthbar = true;

		if (FlxG.save.data.camzoom == null)
			FlxG.save.data.camzoom = true;

		if (FlxG.save.data.scoreScreen == null)
			FlxG.save.data.scoreScreen = false;

		if (FlxG.save.data.inputShow == null)
			FlxG.save.data.inputShow = false;

		if (FlxG.save.data.optimize == null)
			FlxG.save.data.optimize = false;

		if (FlxG.save.data.cacheImages == null)
			FlxG.save.data.cacheImages = false;

		if (FlxG.save.data.healthBar == null)
			FlxG.save.data.healthBar = true;

		if (FlxG.save.data.popup == null)
			FlxG.save.data.popup = true;

		if (FlxG.save.data.middleScroll == null)
			FlxG.save.data.middleScroll = false;

		if (FlxG.save.data.editorBG == null)
			FlxG.save.data.editor = false;

		if (FlxG.save.data.noteskin == null)
			FlxG.save.data.noteskin = 0;

		if (FlxG.save.data.rotateSprites == null)
			FlxG.save.data.rotateSprites = true;

		if (FlxG.save.data.notesplash == null)
			FlxG.save.data.notesplash = 0;

		if (FlxG.save.data.zoom == null)
			FlxG.save.data.zoom = 1;

		if (FlxG.save.data.shitMs == null)
			FlxG.save.data.shitMs = 100.0;

		if (FlxG.save.data.badMs == null)
			FlxG.save.data.badMs = 95.0;

		if (FlxG.save.data.goodMs == null)
			FlxG.save.data.goodMs = 75.0;

		if (FlxG.save.data.sickMs == null)
			FlxG.save.data.sickMs = 35.0;

		if (FlxG.save.data.marvMs == null)
			FlxG.save.data.marvMs = 20.0;

		// custom shit

		if (FlxG.save.data.mem == null)
			FlxG.save.data.mem = false;

		if (FlxG.save.data.gen == null)
			FlxG.save.data.gen = true;

		if (FlxG.save.data.notesplashes == null)
			FlxG.save.data.notesplashes = true;

		if (FlxG.save.data.cpuSplash == null)
			FlxG.save.data.cpuSplash = true;

		if (FlxG.save.data.cpuNoteskin == null)
			FlxG.save.data.cpuNoteskin = 0;

		if (FlxG.save.data.cacheSounds == null)
			FlxG.save.data.cacheSounds = false;

		if (FlxG.save.data.unload == null)
			FlxG.save.data.unload = true;

		if (FlxG.save.data.oldcharter == null)
			FlxG.save.data.oldcharter = false;

		if (FlxG.save.data.motion == null)
			FlxG.save.data.motion = false;

		if (FlxG.save.data.gpuRender == null)
			FlxG.save.data.gpuRender = false;

		if (FlxG.save.data.fpsmark == null)
			FlxG.save.data.fpsmark = false;

		if (FlxG.save.data.borderless == null)
			FlxG.save.data.borderless = false;

		if (FlxG.save.data.resolution == null)
			FlxG.save.data.resolution = 5;

		if (FlxG.save.data.alpha == null)
			FlxG.save.data.alpha = 0.6;

		if (FlxG.save.data.alphaSplash == null)
			FlxG.save.data.alphaSplash = 0.6;

		if (FlxG.save.data.laneTransparency == null)
			FlxG.save.data.laneTransparency = 0;

		// credits to bolovevo. real chad

		if (FlxG.save.data.hgain == null)
			FlxG.save.data.hgain = 1;

		if (FlxG.save.data.hloss == null)
			FlxG.save.data.hloss = 1;

		if (FlxG.save.data.hdrain == null)
			FlxG.save.data.hdrain = false;

		if (FlxG.save.data.sustains == null)
			FlxG.save.data.sustains = true;

		if (FlxG.save.data.noMisses == null)
			FlxG.save.data.noMisses = false;

		if (FlxG.save.data.modcharts == null)
			FlxG.save.data.modcharts = true;

		if (FlxG.save.data.practice == null)
			FlxG.save.data.practice = false;

		if (FlxG.save.data.opponent == null)
			FlxG.save.data.opponent = false;

		if (FlxG.save.data.mirror == null)
			FlxG.save.data.mirror = false;

		if (FlxG.save.data.background == null)
			FlxG.save.data.background = true;

		if (FlxG.save.data.hitSound == null)
			FlxG.save.data.hitSound = 0;

		if (FlxG.save.data.hitVolume == null)
			FlxG.save.data.hitVolume = 0.5;

		if (FlxG.save.data.strumHit == null)
			FlxG.save.data.strumHit = true;

		if (FlxG.save.data.autoPause == null)
			FlxG.save.data.autoPause = false;

		if (FlxG.save.data.showState == null)
			FlxG.save.data.showState = false;

		if (FlxG.save.data.saveReplays == null)
			FlxG.save.data.saveReplays = true;

		if (FlxG.save.data.glDebug == null)
			FlxG.save.data.glDebug = false;

		if (FlxG.save.data.loadMods == null)
			FlxG.save.data.loadMods = true;

		if (FlxG.save.data.autoSaving == null)
			FlxG.save.data.autoSaving = true;

		if (FlxG.save.data.shaders == null)
			FlxG.save.data.shaders = false;

		if (FlxG.save.data.showRating == null)
			FlxG.save.data.showRating = true;

		if (FlxG.save.data.showNum == null)
			FlxG.save.data.showNum = true;

		if (FlxG.save.data.showMs == null)
			FlxG.save.data.showMs = true;

		if (FlxG.save.data.volume != null)
		{
			FlxG.sound.volume = FlxG.save.data.volume;
		}
		if (FlxG.save.data.mute != null)
		{
			FlxG.sound.muted = FlxG.save.data.mute;
		}

		if (FlxG.save.data.noteCamera == null)
			FlxG.save.data.noteCamera = false;

		if (FlxG.save.data.moveEditor == null)
			FlxG.save.data.moveEditor = true;

		if (FlxG.save.data.editorPos == null)
			FlxG.save.data.editorPos = [0, 420];

		if (FlxG.save.data.showHelp == null)
			FlxG.save.data.showHelp = true;

		if (FlxG.save.data.chart_metronome == null)
			FlxG.save.data.chart_metronome = false;

		if (FlxG.save.data.playHitsounds == null)
			FlxG.save.data.playHitsounds = false;

		if (FlxG.save.data.playHitsoundsE == null)
			FlxG.save.data.playHitsoundsE = false;

		if (FlxG.save.data.developer == null)
			FlxG.save.data.developer = false;

		if (FlxG.save.data.maxRatings == null)
			FlxG.save.data.maxRatings = 4;

		FlxSprite.defaultAntialiasing = FlxG.save.data.antialiasing;
		FlxObject.defaultMoves = false;
		PlayerSettings.player1.controls.loadKeyBinds();

		Main.watermarks = FlxG.save.data.watermark;
	}
}
