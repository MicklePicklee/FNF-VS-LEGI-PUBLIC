package states;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.sound.FlxSound;
import states.TitleState;

class GoofyState extends MusicBeatState
{
    public static var leftState:Bool = false;
    var goofySprite:FlxSprite;
    var goofySound:FlxSound;

    override function create()
    {
        super.create();

        goofySprite = new FlxSprite().loadGraphic(Paths.image('goofy_image'));
        goofySprite.screenCenter();
        add(goofySprite);

        goofySound = FlxG.sound.play(Paths.sound('goofy_audio'), 1, false, null, true, function()
        {
            transitionToTitle();
        });
    }

    function transitionToTitle()
    {
        leftState = true;
        FlxTransitionableState.skipNextTransIn = true;
        FlxTransitionableState.skipNextTransOut = true;
        MusicBeatState.switchState(new TitleState());
    }

    override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE && !leftState)
        {
            if (goofySound != null) goofySound.stop();
            transitionToTitle();
        }

        super.update(elapsed);
    }
}
