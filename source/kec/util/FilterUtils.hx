package kec.util;

import openfl.filters.ColorMatrixFilter;
import openfl.filters.BitmapFilter;
import haxe.ds.StringMap;

class FilterUtils
{
	// Mapping filter names to their corresponding matrices
	public static var filterMap:StringMap<Array<Float>> = new StringMap();

	public static function setColorBlindess(num:Int)
	{
		if (num == 0)
		{
			FlxG.game.setFilters([]);
			return;
		}

		FlxG.game.setFilters([getFilterByName(Constants.colorFilters[num])]);
	}

	public static function initializeFilters()
	{
		// Populate the map with filter configurations
		filterMap.set("Deuteranopia", [
			 0.43, 0.72, -0.15, 0, 0,
			 0.34, 0.57,  0.09, 0, 0,
			-0.02, 0.03,     1, 0, 0,
			    0,    0,     0, 1, 0,
		]);

		filterMap.set("Protanopia", [
			0.20,  0.99, -0.19, 0, 0,
			0.16,  0.79,  0.04, 0, 0,
			0.01, -0.01,     1, 0, 0,
			   0,     0,     0, 1, 0,
		]);

		filterMap.set("Tritanopia", [
			0.97, 0.11, -0.08, 0, 0,
			0.02, 0.82,  0.16, 0, 0,
			0.06, 0.88,  0.18, 0, 0,
			   0,    0,     0, 1, 0,
		]);
	}

	// Function to get a BitmapFilter from a filter name
	public static function getFilterByName(filterName:String):BitmapFilter
	{
		if (filterMap.exists(filterName))
		{
			// Retrieve the matrix and create a ColorMatrixFilter
			var matrix = filterMap.get(filterName);
			return new ColorMatrixFilter(matrix);
		}
		else
			throw "No filter has been applied : " + filterName;
	}
}
