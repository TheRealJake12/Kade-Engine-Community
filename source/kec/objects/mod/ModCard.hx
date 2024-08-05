package kec.objects.mod;

import kec.objects.CoolText;

class ModCard extends FlxSpriteGroup
{
    public var titleText:CoolText;
    public var card:FlxSprite;
    public var icon:FlxSprite; // find a way to use polymod icons 
    public var desc:CoolText;
    public var targY:Float = 0;
    public function new(x:Float,y:Float, id:Int, text:String, description:String)
    {
        super(x, y);
        this.targY = id;
		icon = new FlxSprite(x, y).loadGraphic(Paths.image('missingMod'));
		icon.setGraphicSize(75, 75);
		icon.updateHitbox();

		card = new FlxSprite(x + 375, icon.y + 45).makeGraphic(1, 1, FlxColor.BLACK);
		card.setGraphicSize(600, 100);
		card.alpha = 0.75;

		titleText = new CoolText(x + card.x - 445, card.y - 50, 24, 24, Paths.bitmapFont('fonts/vcr'));
		titleText.text = text;
		titleText.autoSize = true;
		titleText.antialiasing = true;
		titleText.updateHitbox();
		
		desc = new CoolText(titleText.x, titleText.y + 25, 16, 16, Paths.bitmapFont('fonts/vcr'));
		desc.text = description;
		desc.fieldWidth = 2400;
		desc.autoSize = false;
		desc.antialiasing = true;
		desc.updateHitbox();

        add(card);
		add(titleText);
        add(desc);
        add(icon);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);
		y = FlxMath.lerp(y, (targY * 140) + 120, CoolUtil.boundTo(elapsed * 12, 0, 1));
    }
}

