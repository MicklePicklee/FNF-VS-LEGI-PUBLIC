package states;

import flixel.FlxObject;
import flixel.addons.transition.FlxTransitionableState;
import states.editors.MasterEditorMenu;
import options.OptionsState;
import extras.ExtraMenuState;
import flixel.text.FlxText;
import util.AnimOffsetHelper;

typedef CharData =
{
	var pos:Array<Int>;
	var hoverOffsets:Array<Int>;
	var selectedOffsets:Array<Int>;
	var hoverFrames:Int;
	var selectedFrames:Int;
}

typedef MenuChar = {
    var sprite:FlxSprite;
    var offsets:AnimOffsetHelper;
    var path:String;
    var name:String;
}

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = 'DUrrr Eight....'; // This is also used for Discord RPC
	var menuSprites:Array<FlxSprite> = [];
    public static var curSelected:Int = 0;
	var menuOutlines:Array<FlxSprite> = [];
	var outlineTargetScales:Array<Float> = [];
    var shiftMult:Int = 1;
    var holdTime:Float = 0;

	var optionShit:Array<String> = [
		'story_mode',
		'freeplay',

		'awards',
		'credits',

		'options'
	];

	var camFollow:FlxObject;
	var storyModeSquare:FlxSprite;
	var freeplaySquare:FlxSprite;
	var extrasSquare:FlxSprite;
	var optionsSquare:FlxSprite;
	var creditsSquare:FlxSprite;

	var storyLegi:FlxSprite;
	var storyLegiOffsets:AnimOffsetHelper;

	var freeplayAd:FlxSprite;
	var freeplayAdOffsets:AnimOffsetHelper;

	var extrasMickle:FlxSprite;
	var extrasMickleOffsets:AnimOffsetHelper;

	var creditsPaper:FlxSprite;

	var optionsDoddle:FlxSprite;
	var optionsDoddleOffsets:AnimOffsetHelper;

	var bg:FlxSprite;

	override function create()
	{

		super.create();

		#if MODS_ALLOWED
		Mods.pushGlobalMods();
		#end
		Mods.loadTopMod();

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		FlxG.mouse.visible = true;

		persistentUpdate = persistentDraw = true;

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);		

		bg = new FlxSprite().loadGraphic(Paths.image('backGround'));
		bg.antialiasing = ClientPrefs.data.antialiasing;
		bg.scrollFactor.set(0, 0);
		bg.updateHitbox();
		bg.screenCenter();
		add(bg);

		storyModeSquare = createOutlinedSprite((FlxG.width / 25.6), (FlxG.height / 7.2), 'storyMode/bg', "Story Mode");
		freeplaySquare = createOutlinedSprite((FlxG.width - (FlxG.width / 25.6) - storyModeSquare.width), (FlxG.height / 7.2), 'freeplay/bg', "Freeplay");
		extrasSquare = createOutlinedSprite((FlxG.width / 4) - (200 / 2), (FlxG.height / 1.44), 'extras/bg', "Extras");
		optionsSquare = createOutlinedSprite(((FlxG.width / 2) - (extrasSquare.width / 2)), (FlxG.height / 1.44), 'credits/bg', "Credits");
		creditsSquare = createOutlinedSprite(((FlxG.width / (4 / 3)) - (extrasSquare.width / 2)), (FlxG.height / 1.44), 'options/bg', "Options");

		var characters:Array<MenuChar> = [
		    {sprite: storyLegi, offsets: storyLegiOffsets, path: 'storyMode/', name: 'legiSprites'},
		    {sprite: freeplayAd, offsets: freeplayAdOffsets, path: 'freeplay/', name: 'adSprites'},
		    {sprite: extrasMickle, offsets: extrasMickleOffsets, path: 'extras/', name: 'mickleSprites'},
		    {sprite: optionsDoddle, offsets: optionsDoddleOffsets, path: 'options/', name: 'doddleSprites'}
		];

		var charVars = [
		    { setSprite: (v) -> storyLegi = v, setOffsets: (v) -> storyLegiOffsets = v },
		    { setSprite: (v) -> freeplayAd = v, setOffsets: (v) -> freeplayAdOffsets = v },
		    { setSprite: (v) -> extrasMickle = v, setOffsets: (v) -> extrasMickleOffsets = v },
		    { setSprite: (v) -> optionsDoddle = v, setOffsets: (v) -> optionsDoddleOffsets = v }
		];

		for (i in 0...characters.length) {
			var char = characters[i];
			if (Paths.fileExists('images/mainMenu/' + char.path + char.name + '.json', TEXT)) {
				var rawJson:String = Paths.getTextFromFile('images/mainMenu/' + char.path + char.name + '.json');
				if (rawJson != null && rawJson.length > 0) {
					try {
						var charJSON:CharData = tjson.TJSON.parse(rawJson);
						
						var sprite = createCharacterSprite(charJSON.pos[0], charJSON.pos[1], char.path, char.name);
						var offsets = createOffsets(sprite, 
							[charJSON.hoverOffsets[0], charJSON.hoverOffsets[1]], 
							[charJSON.selectedOffsets[0], charJSON.selectedOffsets[1]], 
							charJSON.hoverFrames, 
							charJSON.selectedFrames);

						char.sprite = sprite;
						char.offsets = offsets;

						charVars[i].setSprite(sprite);
						charVars[i].setOffsets(offsets);

						add(sprite);
						playAnim(sprite, offsets, 'idle');
					}
					catch(e:haxe.Exception)
					{
						trace('[WARN] JSON for ' + char.name + ' might be broken, ignoring issue...\n${e.details()}');
					}
				}
 				else trace('[WARN] No JSON for ' + char.name +  ' detected.');
			}
		}

		creditsPaper = new FlxSprite(566, 520).loadGraphic(Paths.image('mainMenu/credits/paper'));
		creditsPaper.antialiasing = ClientPrefs.data.antialiasing;
		creditsPaper.scrollFactor.set(0, 0);
		creditsPaper.updateHitbox();
		add(creditsPaper);

		#if ACHIEVEMENTS_ALLOWED
		// Unlock the welcome achievement here; the prerequisite is literally to just access the main menu lmao
		Achievements.unlock('welcome');

		#if MODS_ALLOWED
		Achievements.reloadList();
		#end
		#end


		FlxG.camera.follow(camFollow, null, 9);
	}

	var selectedSomethin:Bool = false;

    var timeNotMoving:Float = 0;
	override function update(elapsed:Float)
	{
		var allowMouse:Bool = true;
        var prevSelected = curSelected;

		if (ClientPrefs.data.menuTheme != 'None')
		{
			if (FlxG.sound.music.volume < 0.8)
			{
				FlxG.sound.music.volume += 0.5 * elapsed;
				if (FreeplayState.vocals != null)
					FreeplayState.vocals.volume += 0.5 * elapsed;
			}
		}

		if (!selectedSomethin)
		{
			if (controls.UI_LEFT_P) {
			changeSelection(-shiftMult);
			holdTime = 0;
			}
			if (controls.UI_RIGHT_P) {
			    changeSelection(shiftMult);
			    holdTime = 0;
			}
			if (controls.UI_UP_P) {
				var diff = curSelected > 2 ? 2 : 1;
			    changeSelection(-shiftMult - diff);
			    holdTime = 0;
			}
			if (controls.UI_DOWN_P) {
				var diff = curSelected == 0 || curSelected == 4 ? 1 : 2;
			    changeSelection(shiftMult + diff);
			    holdTime = 0;
			}
			if (controls.UI_LEFT || controls.UI_RIGHT || controls.UI_UP || controls.UI_DOWN) {
			    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			    holdTime += elapsed;
			    allowMouse = false;
			    FlxG.mouse.visible = false;
			    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
			    if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) changeSelection((checkNewHold - checkLastHold) * (controls.UI_RIGHT ? shiftMult : -shiftMult));
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

			var index = -1;
			for (i in 0...outlineTargetScales.length)
			{
				if (outlineTargetScales[i] > 1.0)
				{
					index = i;
					break;
				}
			}

			switch(index)
			{
				case 0: // story mode
					fuck(storyLegi, storyLegiOffsets);
				case 1: // freeplay
					fuck(freeplayAd, freeplayAdOffsets);
				case 2: // extras
					fuck(extrasMickle, extrasMickleOffsets);
				case 3: // credits
					fuck(); // hehe it's funny cause it just says FUCK
				case 4: // options
					fuck(optionsDoddle, optionsDoddleOffsets);
				default:
					fuck();
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
				FlxG.mouse.visible = false;
			}
			if (controls.ACCEPT || (FlxG.mouse.justPressed && allowMouse))
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));
				selectedSomethin = true;
				FlxG.mouse.visible = false;
				outlineTargetScales[curSelected] = 1.1;
				updateSprites(elapsed);
				switch (optionShit[curSelected])
				{
					case 'story_mode':
						animate(storyLegi, storyLegiOffsets, 'selected', true, new StoryMenuState());
					case 'freeplay':
						animate(freeplayAd, freeplayAdOffsets, 'selected', true, new FreeplayState());
					case 'awards':
						animate(extrasMickle, extrasMickleOffsets, 'selected', true, new ExtraMenuState());
					case 'credits':
						MusicBeatState.switchState(new CreditsState());
					case 'options':
						animate(optionsDoddle, optionsDoddleOffsets, 'selected', true, new OptionsState());
        				OptionsState.onPlayState = false;
        				if (PlayState.SONG != null)
        				{
        				    PlayState.SONG.arrowSkin = null;
        				    PlayState.SONG.splashSkin = null;
        				    PlayState.stageUI = 'normal';
						}
					default:
						selectedSomethin = false;
				}
			}

			#if desktop
			if (controls.justPressed('debug_1'))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
				FlxG.mouse.visible = false;
			}
			#end

		}

		updateSprites(elapsed);
		super.update(elapsed);
	}
	
	function createCharacterSprite(x:Float, y:Float, path:String, fileName:String):FlxSprite {
		var sprite:FlxSprite = new FlxSprite(x, y);
		sprite.frames = Paths.getSparrowAtlas('mainMenu/' + path + fileName);
		sprite.antialiasing = ClientPrefs.data.antialiasing;
		sprite.animation.addByPrefix('idle', "idle", false);
		sprite.animation.addByPrefix('hovering', "hovering", 24, false);
		sprite.animation.addByPrefix('selected', "selected", 24, false);
		return sprite;
	}

	function createOffsets(sprite:FlxSprite, hoverOffsets:Array<Int>, selectOffset:Array<Int>, hoverFrames:Int, selectedFrames:Int):AnimOffsetHelper {
		var offsets = new AnimOffsetHelper();
		offsets.addOffset("hovering", hoverOffsets[0], hoverOffsets[1]);
		offsets.addOffset("selected", selectOffset[0], selectOffset[1]);
		var animFrames = [
			"hovering" => hoverFrames,
			"selected" => selectedFrames
		];
		for (name in animFrames.keys()) {
			var count = animFrames.get(name);
			var indices = [];
			for (i in 0...count) indices.push(count - 1 - i);
			sprite.animation.addByIndices('un' + name, name, indices, "", 24, false);
			var origOffset = offsets.animOffsets.get(name);
			
			if (origOffset != null) {
				offsets.addOffset('un' + name, origOffset[0], origOffset[1]);
			} else {
				offsets.addOffset('un' + name, 0, 0); 
			}
		}

		return offsets;
	}

	function createOutlinedSprite(x:Float, y:Float, fileName:String, ?label:String = null):FlxSprite {
		var sprite:FlxSprite = new FlxSprite(x, y).loadGraphic(Paths.image('mainMenu/' + fileName)); // kinda ass but we'll roll with it
		sprite.antialiasing = ClientPrefs.data.antialiasing;

		var outline:FlxSprite = new FlxSprite(x - 3, y - 3);
		outline.makeGraphic(Std.int(sprite.width) + 6, Std.int(sprite.height) + 6, FlxColor.WHITE);
		outline.scrollFactor.set();
		add(outline);

		add(sprite);
		sprite.updateHitbox();
		
		sprite.scrollFactor.set();

		menuSprites.push(sprite);
		menuOutlines.push(outline);
		outlineTargetScales.push(1);

		if (label != null) {
			var text:FlxText = new FlxText((x - (FlxG.width/2)+1), (y - FlxG.height/2) - 58, sprite.width, label);
			text.setFormat(Paths.font("vcr.ttf"), 42, FlxColor.WHITE, CENTER);
			add(text);
		}

		return sprite;
	}

	function playAnim(sprite:FlxSprite, offsets:AnimOffsetHelper, anim:String, ?force:Bool = false) {
		sprite.animation.play(anim, force);
		offsets.applyOffset(sprite, anim);
	}

	function fuck(character:FlxSprite = null, offset:AnimOffsetHelper = null)
	{
		var characters = [storyLegi, freeplayAd, extrasMickle, optionsDoddle];
		var offsets = [storyLegiOffsets, freeplayAdOffsets, extrasMickleOffsets, optionsDoddleOffsets];

		var characters = characters.filter(z -> z != character);
		var offsets = offsets.filter(z -> z != offset);

		for (i in 0...characters.length)
		{
			animate(characters[i], offsets[i], 'unhovering', false);
		}
		animate(character, offset, 'hovering', true);
	}

	function animate(sprite:FlxSprite, offsets:AnimOffsetHelper, anim:String, loop:Bool, nextState:MusicBeatState = null)
	{
		if (sprite != null && offsets != null)
		{
			if (sprite.animation.curAnim.name == anim && !sprite.animation.curAnim.finished) 
			{
				return;
			}

			if (anim == 'unhovering') 
				{
					if (sprite.animation.curAnim.name == 'hovering') 
					{
						playAnim(sprite, offsets, anim);
					}
				}
			else 
				{
					if (sprite.animation.curAnim == null || sprite.animation.curAnim.name != anim) 
					{
						playAnim(sprite, offsets, anim);
					}
				}

			if (loop)
			{
				if (sprite.animation.curAnim != null && sprite.animation.curAnim.name == anim && sprite.animation.curAnim.finished)
				{
					sprite.animation.curAnim.curFrame = sprite.animation.curAnim.frames.length - 1;
					sprite.animation.curAnim.paused = true;
				}
			}
			else 
			{
				if ((sprite.animation.curAnim.name == 'unhovering' && sprite.animation.curAnim.finished))
				{
					playAnim(sprite, offsets, 'idle');
				}
			}

			if (anim == 'selected')
			{
				var animLength = sprite.animation.curAnim.frames.length / sprite.animation.curAnim.frameRate;
				new flixel.util.FlxTimer().start(animLength, function(_) {
					MusicBeatState.switchState(nextState);
				});
			}
		}
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
        for (i in 0...menuSprites.length) {
            var sprite = menuSprites[i];
            var outline = menuOutlines[i];
            outline.scale.x += (outlineTargetScales[i] - outline.scale.x) * outlineSpeed * elapsed;
            outline.scale.y += (outlineTargetScales[i] - outline.scale.y) * outlineSpeed * elapsed;
        }

    }
}