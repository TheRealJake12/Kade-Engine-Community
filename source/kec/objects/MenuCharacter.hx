package kec.objects;

typedef MenuCharData =
{
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var confirm_anim:String;
	var flipped:Bool;
	var ?frameRate:Int;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;

	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf')
	{
		if (character == null)
			character = '';
		if (character == this.character)
			return;

		this.character = character;
		antialiasing = FlxG.save.data.antialiasing;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();

		hasConfirmAnimation = false;
		switch (character)
		{
			case '':
				visible = false;
				dontPlayAnim = true;
			default:
				var jsonPath:String = 'menuCharacters/' + character;

				var charJson:MenuCharData = cast Paths.loadJSON(jsonPath);
				var frameRate = charJson.frameRate == null ? 24 : charJson.frameRate;

				frames = Paths.getSparrowAtlas('menuCharacters/' + charJson.image);
				animation.addByPrefix('idle', charJson.idle_anim, frameRate);

				var confirmAnim:String = charJson.confirm_anim;
				if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charJson.idle_anim)
				{
					animation.addByPrefix('confirm', confirmAnim, frameRate, false);
					if (animation.getByName('confirm') != null) // check for invalid animation
						hasConfirmAnimation = true;
				}

				flipX = (charJson.flipped == true);

				if (charJson.scale != 1)
				{
					scale.set(charJson.scale, charJson.scale);
					updateHitbox();
				}
				offset.set(charJson.position[0], charJson.position[1]);
				animation.play('idle');
		}
	}
}
