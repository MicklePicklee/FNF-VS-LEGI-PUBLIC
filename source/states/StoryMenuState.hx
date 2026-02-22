package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import flixel.group.FlxGroup;
import flixel.graphics.FlxGraphic;

import objects.MenuItem;


import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;
import util.AnimOffsetHelper;

class StoryMenuState extends MusicBeatState
{
	public static var weekCompleted:Map<String, Bool> = new Map<String, Bool>();

	var scoreText:FlxText;
	var starting:FlxText;
	private static var lastDifficultyName:String = '';
	var curDifficulty:Int = 1;

	var txtWeekTitle:FlxText;
	var bgSprite:FlxSprite;
	var bgSpriteTransition:FlxSprite; // Add this line

	private static var curWeek:Int = 0;






	var grpLocks:FlxTypedGroup<FlxSprite>;

	var difficultySelectors:FlxGroup;
	var sprDifficulty:FlxSprite;
	var leftArrow:FlxSprite;
	// var leftArrow2:FlxSprite;
	var rightArrow:FlxSprite;
	// var rightArrow2:FlxSprite;

	var loadedWeeks:Array<WeekData> = [];

	var leftArrowOffsets:AnimOffsetHelper;
	var rightArrowOffsets:AnimOffsetHelper;

	var bgFadeTween:FlxTween = null;

	override function create()
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		PlayState.isStoryMode = true;
		WeekData.reloadWeekFiles(true);
		if(curWeek >= WeekData.weeksList.length) curWeek = 0;
		persistentUpdate = true;
		persistentDraw = true;

		scoreText = new FlxText(10, 10, 0, Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]), 36);
		scoreText.setFormat("VCR OSD Mono", 32);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;

		var rankText:FlxText = new FlxText(0, 10);
		rankText.text = 'RANK: GREAT';
		rankText.setFormat(Paths.font("vcr.ttf"), 32);
		rankText.size = scoreText.size;
		rankText.screenCenter(X);

		var ui_tex = Paths.getSparrowAtlas('storyMenu/arrow');

		bgSprite = new FlxSprite(0, 56);
		bgSpriteTransition = new FlxSprite(0, 56); 
		bgSpriteTransition.alpha = 0;
		add(bgSprite);
		add(bgSpriteTransition); 

		grpLocks = new FlxTypedGroup<FlxSprite>();
		add(grpLocks);

		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var num:Int = 0;
		for (i in 0...WeekData.weeksList.length)
		{
			var weekFile:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var isLocked:Bool = weekIsLocked(WeekData.weeksList[i]);
			if(!isLocked || !weekFile.hiddenUntilUnlocked)
			{
				loadedWeeks.push(weekFile);
				WeekData.setDirectoryFromWeek(weekFile);
				

				// weekThing.updateHitbox();

				// Needs an offset thingie
				if (isLocked)
				{
					var lock:FlxSprite = new FlxSprite(10);
					lock.antialiasing = ClientPrefs.data.antialiasing;
					lock.frames = ui_tex;
					lock.animation.addByPrefix('lock', 'lock');
					lock.animation.play('lock');
					lock.ID = i;
					grpLocks.add(lock);
				}
				num++;
			}
		}

		WeekData.setDirectoryFromWeek(loadedWeeks[0]);


		difficultySelectors = new FlxGroup();
		add(difficultySelectors);

		sprDifficulty = new FlxSprite(0, 590);
		sprDifficulty.x = (FlxG.width / 2) - (sprDifficulty.width / 2);
		sprDifficulty.antialiasing = ClientPrefs.data.antialiasing;

		leftArrow = new FlxSprite(sprDifficulty.x - sprDifficulty.width - 165, 615);
		leftArrow.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow.frames = ui_tex;
		leftArrow.animation.addByPrefix('idle', "idle");
		leftArrow.animation.addByPrefix('press', "press", 24, false);
		leftArrow.animation.play('idle');
		leftArrow.scale.x *= -1;
		difficultySelectors.add(leftArrow);

		rightArrow = new FlxSprite(sprDifficulty.x + sprDifficulty.width + 115, leftArrow.y);
		rightArrow.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow.frames = ui_tex;
		rightArrow.animation.addByPrefix('idle', 'idle');
		rightArrow.animation.addByPrefix('press', "press", 24, false);
		rightArrow.animation.play('idle');
		difficultySelectors.add(rightArrow);
		difficultySelectors.add(sprDifficulty);

		leftArrowOffsets = new AnimOffsetHelper();
		leftArrowOffsets.addOffset('idle', 0, 0);   
		leftArrowOffsets.addOffset('press', 0, -5);

		rightArrowOffsets = new AnimOffsetHelper();
		rightArrowOffsets.addOffset('idle', 0, 0); 
		rightArrowOffsets.addOffset('press', 0, -5);



		/* leftArrow2 = new FlxSprite(15,325);
		leftArrow2.antialiasing = ClientPrefs.data.antialiasing;
		leftArrow2.frames = ui_tex;
		leftArrow2.animation.addByPrefix('idle', "arrow left");
		leftArrow2.animation.addByPrefix('press', "arrow push left");
		leftArrow2.animation.play('idle');*/

		Difficulty.resetList();
		if(lastDifficultyName == '')
		{
			lastDifficultyName = Difficulty.getDefault();
		}
		curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

		/* rightArrow2 = new FlxSprite(leftArrow2.x + 1200, leftArrow2.y);
		rightArrow2.antialiasing = ClientPrefs.data.antialiasing;
		rightArrow2.frames = ui_tex;
		rightArrow2.animation.addByPrefix('idle', 'arrow right');
		rightArrow2.animation.addByPrefix('press', "arrow push right", 24, false);
		rightArrow2.animation.play('idle');*/



		// add(bgSprite);




		// add(rankText);
		add(scoreText);
		add(txtWeekTitle);

		changeWeek();
		changeDifficulty();

		/* add(leftArrow2);
		add(rightArrow2); */

		super.create();
	}

	override function closeSubState() {
		persistentUpdate = true;
		changeWeek();
		super.closeSubState();
	}

	override function update(elapsed:Float)
	{
		// scoreText.setFormat(Paths.font("vcr.ttf"), 32);
		if(intendedScore != lerpScore)
		{
			lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 30)));
			if(Math.abs(intendedScore - lerpScore) < 10) lerpScore = intendedScore;
	
			scoreText.text = Language.getPhrase('week_score', 'WEEK SCORE: {1}', [lerpScore]);
		}

		// FlxG.watch.addQuick('font', scoreText.font);

		if (!movedBack && !selectedWeek)
		{
			/*if (controls.UI_LEFT_P)
			{
				changeWeek(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}


			if (controls.UI_RIGHT_P)
			{
				changeWeek(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}*/

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				changeWeek(-FlxG.mouse.wheel);
				changeDifficulty();
			}

			if (controls.UI_RIGHT) {
				rightArrow.animation.play('press', false);
				rightArrowOffsets.applyOffset(rightArrow, 'press');
			} else {
				rightArrow.animation.play('idle');
				rightArrowOffsets.applyOffset(rightArrow, 'idle');
			}

			if (controls.UI_LEFT) {
				leftArrow.animation.play('press', false);
				leftArrowOffsets.applyOffset(leftArrow, 'press');
			} else {
				leftArrow.animation.play('idle');
				leftArrowOffsets.applyOffset(leftArrow, 'idle');
			}


			/* if (controls.UI_RIGHT)
				 rightArrow2.animation.play('press');
			else
				rightArrow2.animation.play('idle');

			if (controls.UI_LEFT)
				leftArrow2.animation.play('press');
			else
				leftArrow2.animation.play('idle');*/

			if (controls.UI_RIGHT_P)
				changeDifficulty(1);
			else if (controls.UI_LEFT_P)
				changeDifficulty(-1);

			if(FlxG.keys.justPressed.CONTROL)
			{
				persistentUpdate = false;
				openSubState(new GameplayChangersSubstate());
			}
			else if(controls.RESET)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState('', curDifficulty, '', curWeek));
				//FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			else if (controls.ACCEPT)
			{
				selectWeek();
			}
		}

		if (controls.BACK && !movedBack && !selectedWeek)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			MusicBeatState.switchState(new MainMenuState());
		}

		super.update(elapsed);

		grpLocks.forEach(function(lock:FlxSprite)
		{
			lock.y = 100;
			lock.visible = (lock.y > FlxG.height / 2);
		});
	}

	var movedBack:Bool = false;
	var selectedWeek:Bool = false;
	var stopspamming:Bool = false;

	function selectWeek()
	{
		if (!weekIsLocked(loadedWeeks[curWeek].fileName))
		{
			// We can't use Dynamic Array .copy() because that crashes HTML5, here's a workaround.
			var songArray:Array<String> = [];
			var leWeek:Array<Dynamic> = loadedWeeks[curWeek].songs;
			for (i in 0...leWeek.length) {
				songArray.push(leWeek[i][0]);
			}

			// Nevermind that's stupid lmao
			try
			{
				PlayState.storyPlaylist = songArray;
				PlayState.isStoryMode = true;
				selectedWeek = true;
	
				var diffic = Difficulty.getFilePath(curDifficulty);
				if(diffic == null) diffic = '';
	
				PlayState.storyDifficulty = curDifficulty;
	
				PlayState.SONG = Song.loadFromJson(PlayState.storyPlaylist[0].toLowerCase() + diffic, PlayState.storyPlaylist[0].toLowerCase());
				PlayState.campaignScore = 0;
				PlayState.campaignMisses = 0;
			}
			catch(e:Dynamic)
			{
				trace('ERROR! $e');
				return;
			}
			
			if (stopspamming == false)
			{
				FlxG.sound.play(Paths.sound('confirmMenu'));

				
				stopspamming = true;
			}

			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				LoadingState.loadAndSwitchState(new PlayState(), true);
				FreeplayState.destroyFreeplayVocals();
			});
			
			#if (MODS_ALLOWED && DISCORD_ALLOWED)
			DiscordClient.loadModRPC();
			#end
		}
		else FlxG.sound.play(Paths.sound('cancelMenu'));
	}

	var tweenDifficulty:FlxTween;
	function changeDifficulty(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = Difficulty.list.length-1;
		if (curDifficulty >= Difficulty.list.length)
			curDifficulty = 0;

		WeekData.setDirectoryFromWeek(loadedWeeks[curWeek]);

		var diff:String = Difficulty.getString(curDifficulty);
		var newFrames = Paths.getSparrowAtlas('menudifficulties/' + Paths.formatToSongPath(diff));
		//trace(Mods.currentModDirectory + ', menudifficulties/' + Paths.formatToSongPath(diff));

		if (sprDifficulty.frames != newFrames)
		{
			sprDifficulty.frames = newFrames;
			sprDifficulty.animation.addByPrefix('initiate', "anim", false);
			sprDifficulty.x = (FlxG.width / 2) - (sprDifficulty.width / 2);
			var offsetY:Int = 590;
			if (Difficulty.getString(curDifficulty, false).toLowerCase() == "double or nothing" || Difficulty.getString(curDifficulty, false).toLowerCase() == "double-or-nothing")
			{
				sprDifficulty.x += 4;
				offsetY -= 5;
			}
			sprDifficulty.y = offsetY;
			sprDifficulty.alpha = 0;
			sprDifficulty.animation.play('initiate');

			if(tweenDifficulty != null) tweenDifficulty.cancel();
			tweenDifficulty = FlxTween.tween(sprDifficulty, {y: offsetY, alpha: 1}, 0.07, {onComplete: function(twn:FlxTween)
			{
				tweenDifficulty = null;
			}});
		}
		lastDifficultyName = diff;

		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end

		updateBackground();
	}

	var lerpScore:Int = 49324858;
	var intendedScore:Int = 0;

	function changeWeek(change:Int = 0):Void
	{
		curWeek += change;

		if (curWeek >= loadedWeeks.length)
			curWeek = 0;
		if (curWeek < 0)
			curWeek = loadedWeeks.length - 1;

		var leWeek:WeekData = loadedWeeks[curWeek];
		WeekData.setDirectoryFromWeek(leWeek);

		var leName:String = leWeek.storyName;
		txtWeekTitle.text = leName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);

		var bullShit:Int = 0;

		var unlocked:Bool = !weekIsLocked(leWeek.fileName);
		

		updateBackground();

		PlayState.storyWeek = curWeek;

		Difficulty.loadFromWeek();
		difficultySelectors.visible = unlocked;

		if(Difficulty.list.contains(Difficulty.getDefault()))
			curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(Difficulty.getDefault())));
		else
			curDifficulty = 0;

		var newPos:Int = Difficulty.list.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
		updateText();
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!weekCompleted.exists(leWeek.weekBefore) || !weekCompleted.get(leWeek.weekBefore)));
	}

	function updateText()
	{

		var leWeek:WeekData = loadedWeeks[curWeek];
		var stringThing:Array<String> = [];
		for (i in 0...leWeek.songs.length) {
			stringThing.push(leWeek.songs[i][0]);
		}



		#if !switch
		intendedScore = Highscore.getWeekScore(loadedWeeks[curWeek].fileName, curDifficulty);
		#end
	}

	function updateBackground():Void
	{
	    var leWeek:WeekData = loadedWeeks[curWeek];
	    var assetName:String = leWeek.weekBackground;
	    var diffName = Difficulty.getString(curDifficulty, false).toLowerCase();
	    var newAsset:String = null;
	    bgSprite.visible = true;
	    if (assetName != null && assetName.length > 0) {
	        if (diffName == "double or nothing" || diffName == "double-or-nothing") {
	            assetName += "-double-or-nothing";
	        }
	        newAsset = 'menubackgrounds/menu_' + assetName;
	    } else {
	        bgSprite.visible = false;
	        bgSpriteTransition.visible = false;
	        return;
	    }

	    var newGraphic = Paths.image(newAsset);

	    // If a fade is in progress, finish it instantly
    if (bgFadeTween != null) {
        bgFadeTween.cancel();
        bgFadeTween = null;
        bgSpriteTransition.alpha = 1;
        // Complete the previous tween's logic
        bgSprite.loadGraphic(bgSpriteTransition.graphic);
        bgSpriteTransition.visible = false;
        bgSpriteTransition.alpha = 0;
    }

    if (bgSprite.graphic != null && bgSprite.graphic != newGraphic) {
        bgSpriteTransition.loadGraphic(newGraphic);
        bgSpriteTransition.alpha = 0;
        bgSpriteTransition.visible = true;
        // Fade in the new image
        bgFadeTween = FlxTween.tween(bgSpriteTransition, {alpha: 1}, 0.2, {
            onComplete: function(_) {
                bgSprite.loadGraphic(newGraphic);
                bgSpriteTransition.visible = false;
                bgSpriteTransition.alpha = 0;
                bgFadeTween = null;
            }
        });
    } else if (bgSprite.graphic == null || bgSprite.graphic != newGraphic) {
        bgSprite.loadGraphic(newGraphic);
        bgSpriteTransition.visible = false;
        bgSpriteTransition.alpha = 0;
    }
	}
}
