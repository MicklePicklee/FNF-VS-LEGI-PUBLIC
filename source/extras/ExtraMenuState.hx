package extras;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import lime.app.Application;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import flixel.text.FlxText;
import flixel.input.FlxPointer;
import lime.ui.Window;

class ExtraMenuState extends MusicBeatState
{
    // this is honestly an extremely nasty script, please bear with and behold.
    // is a lil less nasty than usual because this is a trimmed down version - you will understand why later. 
    // the art of bodging is a real beauty.

    public static var psychEngineVersion:String = '1.0';
    public static var curSelected:Int = 0;

    var optionShit:Array<String>;
    var camFollow:FlxObject;
    var menuSprites:Array<FlxSprite> = [];
    var menuOutlines:Array<FlxSprite> = [];
    var menuTexts:Array<FlxText> = [];
    var outlineTargetScales:Array<Float> = [];
    var bg:FlxSprite;
    var imgSize:Int;
    var _drawDistance:Int = 2;
    var _lastVisibles:Array<Int> = [];
    var columnsPerRow:Int = 2;
    var holdTime:Float = 0;
    var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;
    var spacingX:Float;
    var spacingY:Float;
    var startX:Float;
    var gridWidth:Float;
    var rows:Int;

    function createOutlinedSprite(x:Float, y:Float, fileName:String, ?label:String = null):FlxSprite {
        var sprite:FlxSprite = new FlxSprite(x, y);
        sprite.loadGraphic(Paths.image('extraMenu/' + fileName));
        sprite.antialiasing = ClientPrefs.data.antialiasing;
        if (sprite.width > 0) {
            sprite.scale.set(imgSize / sprite.width, imgSize / sprite.width);
        }
        sprite.updateHitbox();
        sprite.scrollFactor.set();

        var outline:FlxSprite = new FlxSprite(sprite.x - 3, sprite.y - 3);
        outline.makeGraphic(Std.int(sprite.width) + 6, Std.int(sprite.height) + 6, FlxColor.WHITE);
        outline.antialiasing = ClientPrefs.data.antialiasing;
        outline.scrollFactor.set();

        add(outline);
        add(sprite);

        menuSprites.push(sprite);
        menuOutlines.push(outline);
        outlineTargetScales.push(1);

        if (label != null) {
            var text:FlxText = new FlxText(sprite.x, sprite.y + sprite.height + 35, sprite.width, label);
            text.setFormat(Paths.font("vcr.ttf"), 70, FlxColor.WHITE, CENTER);
            text.scrollFactor.set();
            text.antialiasing = ClientPrefs.data.antialiasing;
            add(text);
            menuTexts.push(text);
        }
        return sprite;
    }

    override function create()
    {
        FlxG.mouse.visible = false;

        bg = new FlxSprite().loadGraphic(Paths.image('backGround'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, 0);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

        var menuLabels = [];
        optionShit = ['fanart'];
        menuLabels = ['Fanart'];
        optionShit.push('awards');
        menuLabels.push('Awards');

        imgSize = 500;
        var startY = FlxG.height / 2 - imgSize / 2;
        spacingX = imgSize + 40;
        spacingY = imgSize + 40;
        rows = Math.ceil(optionShit.length / columnsPerRow);
        gridWidth = columnsPerRow * imgSize + (columnsPerRow - 1) * 40;
        var gridHeight = rows * imgSize + (rows - 1) * 40;
        var totalWidth = optionShit.length * imgSize + (optionShit.length - 1) * 40;
        startX = FlxG.width / 2 - totalWidth / 2;

        for (i in 0...optionShit.length) {
            var col = i % columnsPerRow;
            var row = Math.floor(i / columnsPerRow);
            var x = startX + i * (imgSize + 40);
            var y = startY;
            var sprite = createOutlinedSprite(x, y, optionShit[i], menuLabels[i]);
        }

		FlxG.camera.follow(camFollow, null, 0.15);

        // hopefully this is good??

        super.create();
    }

    var selectedSomethin:Bool = false;

    var timeNotMoving:Float = 0;
    override function update(elapsed:Float)
    {
        if (ClientPrefs.data.menuTheme != 'None') {
            if (FlxG.sound.music.volume < 0.8) {
                FlxG.sound.music.volume += 0.5 * elapsed;
                if (states.FreeplayState.vocals != null)
                    states.FreeplayState.vocals.volume += 0.5 * elapsed;
            }
        }

        var prevSelected = curSelected;

        selectedSomethin = false;
        var allowMouse:Bool = true;

        if (!selectedSomethin) {
            if (FlxG.mouse.wheel != 0) changeSelection(columnsPerRow * -FlxG.mouse.wheel * shiftMult);

            if (controls.UI_LEFT_P) {
                changeSelection(-shiftMult);
                holdTime = 0;
            }
            if (controls.UI_RIGHT_P) {
                changeSelection(shiftMult);
                holdTime = 0;
            }
            if (controls.UI_LEFT || controls.UI_RIGHT || controls.UI_UP || controls.UI_DOWN) {
                var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                holdTime += elapsed;
                allowMouse = false;
                FlxG.mouse.visible = false;
                var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
                if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
                    changeSelection((checkNewHold - checkLastHold) * (controls.UI_RIGHT ? shiftMult : -shiftMult));
                }
            }

            if (allowMouse && ((FlxG.mouse.deltaScreenX != 0 && FlxG.mouse.deltaScreenY != 0) || FlxG.mouse.justPressed))
            {
				var selectedItem:FlxSprite = null;
            	allowMouse = false;
            	FlxG.mouse.visible = true;
                timeNotMoving = 0;

                for (i in 0...menuSprites.length)
                {
                    menuSprites[i].visible = true;
                    menuOutlines[i].visible = true;
                    selectedItem = menuSprites[i];
                    var outline = menuOutlines[i];
                    var speed = 10;
                    if (FlxG.mouse.overlaps(menuSprites[i]))
                    {
                        curSelected = i;
			            if (prevSelected != curSelected || outlineTargetScales[i] < 1.1) changeSelection();
                        outlineTargetScales[i] = 1.1;
						allowMouse = true;
                    }
                    else outlineTargetScales[i] = 1.0;
                }

            } else {
                timeNotMoving += elapsed;
                if(timeNotMoving > 2) FlxG.mouse.visible = false;
            }
            if (controls.BACK) {
                selectedSomethin = true;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new states.MainMenuState());
            }

            if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse)) {
				outlineTargetScales[curSelected] = 1.1;
				updateSprites(elapsed);
                FlxG.sound.play(Paths.sound('confirmMenu'));
                selectedSomethin = true;
                switch (optionShit[curSelected])
                {
                    case 'awards':
                        MusicBeatState.switchState(new AchievementsMenuState());
                    case 'fanart':
                        MusicBeatState.switchState(new GalleryState());
                }
            }

            #if desktop
            if (controls.justPressed('debug_1'))
            {
                {
                    selectedSomethin = true;
                    MusicBeatState.switchState(new states.editors.MasterEditorMenu());
                }
            }
            #end
        }
        updateSprites(elapsed);
        super.update(elapsed);
    }

    function changeSelection(change:Int = 0) {
        FlxG.sound.play(Paths.sound('scrollMenu'), 0.4); 
        var newSelected = FlxMath.wrap(curSelected + change, 0, menuSprites.length-1);
        for (i in 0...menuSprites.length)
        {
            outlineTargetScales[i] = i == newSelected ? 1.1 : 1.0;
        }
        if (newSelected != curSelected) curSelected = newSelected;
    }

    function updateSprites(elapsed:Float = 0.0)
    {
        var speed = 25;
        var outlineSpeed = 10;
        var curRow = Std.int(curSelected / columnsPerRow);
        var targetY = (FlxG.height / 2 - imgSize / 2) - menuSprites[curSelected].y;
        for (i in 0...menuSprites.length) {
            var sprite = menuSprites[i];
            var outline = menuOutlines[i];
            sprite.color = curSelected == i ? FlxColor.WHITE : FlxColor.GRAY;
            sprite.y += targetY * speed * elapsed;
            outline.y += targetY * speed * elapsed;
            outline.scale.x += (outlineTargetScales[i] - outline.scale.x) * outlineSpeed * elapsed;
            outline.scale.y += (outlineTargetScales[i] - outline.scale.y) * outlineSpeed * elapsed;
        }

    }

}