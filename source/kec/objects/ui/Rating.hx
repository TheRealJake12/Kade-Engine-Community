package kec.objects.ui;

class Rating extends UIComponent
{
	private final ratings:Array<String> = ['shit', 'bad', 'good', 'sick', 'marv'];

	public function new()
	{
		super();
		frames = Paths.getSparrowAtlas('hud/${UIComponent.style.style.toLowerCase()}/${UIComponent.style.style.toLowerCase()}', 'shared');
		addAnims();
		alpha = 0;
		if (UIComponent.style.antialiasing == false)
			antialiasing = false;
	}

	public function loadRating(ratingName:String)
	{
		animation.play(ratingName);
		setGraphicSize(Std.int(frameWidth * UIComponent.style.scale * 0.7));
		updateHitbox();
		alpha = 1;
		velocity.x -= FlxG.random.int(0, 10);
		acceleration.y = 550;
		velocity.y -= FlxG.random.int(140, 175);
	}

	public function addAnims()
	{
		for (i in ratings)
		{
			animation.addByPrefix(i, i, 1, false);
		}
	}
}
