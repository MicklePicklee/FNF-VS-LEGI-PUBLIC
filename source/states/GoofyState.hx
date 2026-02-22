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

        // Show your image (replace 'goofy_image' with your image asset name, no extension)
        goofySprite = new FlxSprite().loadGraphic(Paths.image('goofy_image'));
        goofySprite.screenCenter();
        add(goofySprite);

        // Play your sound (replace 'goofy_audio' with your audio asset name, no extension)
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
        if (leftState)
        {
            super.update(elapsed);
            return;
        }

        // Optional: Allow skipping with ENTER/ESCAPE
        if (FlxG.keys.justPressed.ENTER || FlxG.keys.justPressed.ESCAPE)
        {
            if (goofySound != null) goofySound.stop();
            transitionToTitle();
        }

        super.update(elapsed);
    }
}
