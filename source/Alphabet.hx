package;

import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import openfl.Lib;

using StringTools;

/**
 * Loosley based on FlxTypeText lolol
 */
class Alphabet extends FlxSpriteGroup
{
	public var delay:Float = 0.05;
	public var paused:Bool = false;

	// for menu shit
	public var targetY:Float = 0;
	public var isMenuItem:Bool = false;

	public var text:String = "";

	var _finalText:String = "";
	var _curText:String = "";

	public var widthOfWords:Float = FlxG.width;

	var yMulti:Float = 1;

	// custom shit
	// amp, backslash, question mark, apostrophy, comma, angry faic, period
	var lastSprite:AlphaCharacter;
	var xPosResetted:Bool = false;
	var lastWasSpace:Bool = false;

	var listOAlphabets:List<AlphaCharacter> = new List<AlphaCharacter>();

	var splitWords:Array<String> = [];

	var isBold:Bool = false;

	var pastX:Float = 0;
	var pastY:Float = 0;

	// ThatGuy: Variables here to be used later
	var xScale:Float;
	var yScale:Float;

	// ThatGuy: Added 2 more variables, xScale and yScale for resizing text
	public function new(x:Float, y:Float, text:String = "", ?bold:Bool = false, typed:Bool = false, shouldMove:Bool = false, xScale:Float = 1,
			yScale:Float = 1)
	{
		pastX = x;
		pastY = y;

		// ThatGuy: Have to assign these variables
		this.xScale = xScale;
		this.yScale = yScale;

		super(x, y);

		_finalText = text;
		this.text = text;
		isBold = bold;

		if (text != "")
		{
			if (typed)
			{
				startTypedText();
			}
			else
			{
				addText();
			}
		}
	}

	public function reType(text, xScale:Float = 1, yScale:Float = 1)
	{
		for (i in listOAlphabets)
			remove(i);
		_finalText = text;
		this.text = text;

		lastSprite = null;

		updateHitbox();

		listOAlphabets.clear();
		x = pastX;
		y = pastY;

		this.xScale = xScale;
		this.yScale = yScale;

		addText();
	}

	var consecutiveSpaces:Int = 0;

	public function addText()
	{
		doSplitWords();

		var xPos:Float = 0;
		for (character in splitWords)
		{
			// if (character.fastCodeAt() == " ")
			// {
			// }

			var spaceChar:Bool = (character == " " || (isBold && character == "_"));

			if (spaceChar)
			{
				consecutiveSpaces++;
			}

			var isNumber:Bool = AlphaCharacter.numbers.indexOf(character) != -1;

			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(character) != -1;
			var isLetter:Bool = AlphaCharacter.alphabet.indexOf(character.toLowerCase()) != -1;
			if ((isLetter || isNumber || isSymbol) && (!isBold || !spaceChar)) // if (AlphaCharacter.alphabet.contains(character.toLowerCase()))
			{
				if (lastSprite != null)
				{
					// ThatGuy: This is the line that fixes the spacing error when the x position of this class's objects was anything other than 0
					xPos = lastSprite.x - pastX + lastSprite.width;
				}

				if (consecutiveSpaces > 0)
				{
					xPos += 40 * consecutiveSpaces;
				}
				consecutiveSpaces = 0;

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 0);

				// ThatGuy: These are the lines that change the individual scaling of each character
				letter.scale.set(xScale, yScale);
				letter.updateHitbox();

				listOAlphabets.add(letter);

				if (isBold)
				{
					if (isLetter)
						letter.createBold(character);
					else if (isNumber)
						letter.createBoldNumber(character);
					else if (isSymbol)
						letter.createBoldSymbol(character);
				}
				else
				{
					if (isNumber)
					{
						letter.createNumber(character);
					}
					else if (isSymbol)
					{
						letter.createSymbol(character);
					}
					else if (isLetter)
					{
						letter.createLetter(character);
					}
				}

				add(letter);

				lastSprite = letter;
			}

			// loopNum += 1;
		}
	}

	function doSplitWords():Void
	{
		splitWords = _finalText.split("");
	}

	public var personTalking:String = 'gf';

	// ThatGuy: THIS FUNCTION ISNT CHANGED! Because i dont use it lol
	public function startTypedText():Void
	{
		_finalText = text;
		doSplitWords();

		// trace(arrayShit);

		var loopNum:Int = 0;

		var xPos:Float = 0;
		var curRow:Int = 0;

		new FlxTimer().start(0.05, function(tmr:FlxTimer)
		{
			// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));
			if (_finalText.fastCodeAt(loopNum) == "\n".code)
			{
				yMulti += 1;
				xPosResetted = true;
				xPos = 0;
				curRow += 1;
			}

			var spaceChar:Bool = (splitWords[loopNum] == " " || (isBold && splitWords[loopNum] == "_"));

			if (spaceChar)
			{
				consecutiveSpaces++;
			}

			#if (haxe >= "4.0.0")
			var isNumber:Bool = AlphaCharacter.numbers.contains(splitWords[loopNum]);
			var isSymbol:Bool = AlphaCharacter.symbols.contains(splitWords[loopNum]);
			var isLetter:Bool = AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase());
			#else
			var isNumber:Bool = AlphaCharacter.numbers.indexOf(splitWords[loopNum]) != -1;
			var isSymbol:Bool = AlphaCharacter.symbols.indexOf(splitWords[loopNum]) != -1;
			var isLetter:Bool = AlphaCharacter.alphabet.indexOf(splitWords[loopNum].toLowerCase()) != -1;
			#end

			if ((isLetter || isNumber || isSymbol) && (!isBold || !spaceChar))
				// if (AlphaCharacter.alphabet.contains(splitWords[loopNum].toLowerCase()) || isNumber || isSymbol)

			{
				if (lastSprite != null && !xPosResetted)
				{
					lastSprite.updateHitbox();
					xPos += lastSprite.width + 3;
					// if (isBold)
					// xPos -= 80;
				}
				else
				{
					xPosResetted = false;
				}

				if (consecutiveSpaces > 0)
				{
					xPos += 20 * consecutiveSpaces;
				}
				consecutiveSpaces = 0;
				// trace(_finalText.fastCodeAt(loopNum) + " " + _finalText.charAt(loopNum));

				// var letter:AlphaCharacter = new AlphaCharacter(30 * loopNum, 0);
				var letter:AlphaCharacter = new AlphaCharacter(xPos, 55 * yMulti);
				listOAlphabets.add(letter);
				letter.row = curRow;
				if (isBold)
				{
					if (isLetter)
						letter.createBold(splitWords[loopNum]);
					else if (isSymbol)
						letter.createBoldSymbol(splitWords[loopNum]);
					else if (isNumber)
						letter.createBoldNumber(splitWords[loopNum]);
				}
				else
				{
					if (isNumber)
					{
						letter.createNumber(splitWords[loopNum]);
					}
					else if (isSymbol)
					{
						letter.createSymbol(splitWords[loopNum]);
					}
					else
					{
						letter.createLetter(splitWords[loopNum]);
					}

					letter.x += 90;
				}

				if (FlxG.random.bool(40))
				{
					var daSound:String = "GF_";
					FlxG.sound.play(Paths.soundRandom(daSound, 1, 4));
				}

				add(letter);

				lastSprite = letter;
			}

			loopNum += 1;

			tmr.time = FlxG.random.float(0.04, 0.09);
		}, splitWords.length);
	}

	override function update(elapsed:Float)
	{
		if (isMenuItem)
		{
			var scaledY = FlxMath.remapToRange(targetY, 0, 1, 0, 1.3);

			y = FlxMath.lerp(y, (scaledY * 120) + (FlxG.height * 0.48), 0.30);
			x = FlxMath.lerp(x, (targetY * 20) + 90, 0.30);
		}

		super.update(elapsed);
	}

	// ThatGuy: Ooga booga function for resizing text, with the option of wanting it to have the same midPoint
	// Side note: Do not, EVER, do updateHitbox() unless you are retyping the whole thing. Don't know why, but the position gets retarded if you do that
	public function resizeText(xScale:Float, yScale:Float, xStaysCentered:Bool = true, yStaysCentered:Bool = false):Void
	{
		var oldMidpoint:FlxPoint = this.getMidpoint();
		reType(text, xScale, yScale);
		if (!(xStaysCentered && yStaysCentered))
		{
			if (xStaysCentered)
			{
				// I can just use this juicy new function i made
				moveTextToMidpoint(new FlxPoint(oldMidpoint.x, getMidpoint().y));
			}
			if (yStaysCentered)
			{
				moveTextToMidpoint(new FlxPoint(getMidpoint().x, oldMidpoint.y));
			}
		}
		else
		{
			moveTextToMidpoint(new FlxPoint(oldMidpoint.x, oldMidpoint.y));
		}
	}

	// ThatGuy: Function used to keep text centered on one point instead of manually having to come up with offsets for each sentence
	public function moveTextToMidpoint(midpoint:FlxPoint):Void
	{
		/*
			e.g. You want your midpoint at (100, 100)
			and your text is 200 wide, 50 tall
			then, x = 100 - 200/2, y = 100 - 50/2
		 */
		this.x = midpoint.x - this.width / 2;
		this.y = midpoint.y - this.height / 2;
	}
}

class AlphaCharacter extends FlxSprite
{
	public static var alphabet:String = "abcdefghijklmnopqrstuvwxyz";

	public static var numbers:String = "1234567890";

	public static var symbols:String = "|~#$%()*+-:;<=>@[]^_.,'!? び";

	public var row:Int = 0;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		var tex = Paths.getSparrowAtlas('alphabet');

		frames = tex;
		if (FlxG.save.data.antialiasing)
		{
			antialiasing = true;
		}
	}

	public function createBold(letter:String)
	{
		animation.addByPrefix(letter, letter.toUpperCase() + " bold", 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createBoldSymbol(letter:String)
	{
		switch (letter)
		{
			case '.':
				animation.addByPrefix(letter, 'PERIOD bold', 24);
			case "'":
				animation.addByPrefix(letter, 'APOSTRAPHIE bold', 24);
			case "?":
				animation.addByPrefix(letter, 'QUESTION MARK bold', 24);
			case "!":
				animation.addByPrefix(letter, 'EXCLAMATION POINT bold', 24);
			case "(":
				animation.addByPrefix(letter, 'bold (', 24);
			case ")":
				animation.addByPrefix(letter, 'bold )', 24);
			case "び":
				animation.addByPrefix(letter, 'BI_JPN bold', 24);
			case ":":
				animation.addByPrefix(letter, letter, 24);
				y += 15;
				x += 2;
			case ' ':
				animation.addByPrefix(letter, 'space', 24);
			default:
				animation.addByPrefix(letter, 'bold ' + letter, 24);
		}
		animation.play(letter);
		updateHitbox();
		switch (letter)
		{
			case "'":
				y -= 20;
			case '-':
				// x -= 35 - (90 * (1.0 - textSize));
				y += 20;
			case '(':
				x -= 65;
				y -= 5;
				offset.x = -58;
			case ')':
				x -= 20;
				y -= 5;
				offset.x = 12;
			case '.':
				y += 45;
				x += 5;
				offset.x += 3;
		}
	}

	public function createBoldNumber(letter:String):Void
	{
		animation.addByPrefix(letter, "bold" + letter, 24);
		animation.play(letter);
		updateHitbox();
	}

	public function createLetter(letter:String):Void
	{
		var letterCase:String = "lowercase";
		if (letter.toLowerCase() != letter)
		{
			letterCase = 'capital';
		}

		animation.addByPrefix(letter, letter + " " + letterCase, 24);
		animation.play(letter);
		updateHitbox();

		FlxG.log.add('the row' + row);

		y = (110 - height);
		y += row * 60;
	}

	public function createNumber(letter:String):Void
	{
		animation.addByPrefix(letter, letter, 24);
		animation.play(letter);

		updateHitbox();

		y = (110 - height);
		y += row * 60;
	}

	public function createSymbol(letter:String)
	{
		switch (letter)
		{
			case '#':
				animation.addByPrefix(letter, 'hashtag', 24);
			case '.':
				animation.addByPrefix(letter, 'period', 24);
			case "'":
				animation.addByPrefix(letter, 'apostraphie', 24);
				y -= 50;
			case "?":
				animation.addByPrefix(letter, 'question mark', 24);
			case "!":
				animation.addByPrefix(letter, 'exclamation point', 24);
			case ",":
				animation.addByPrefix(letter, 'comma', 24);
			case "び":
				animation.addByPrefix(letter, 'BI_JPN', 24);
			case ' ':
				animation.addByPrefix(letter, 'space', 24);
			default:
				animation.addByPrefix(letter, letter, 24);
		}
		animation.play(letter);
		updateHitbox();
	}
}
