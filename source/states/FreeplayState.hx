package states;

import backend.WeekData;
import backend.Highscore;
import backend.Song;

import objects.MusicPlayer;

import options.GameplayChangersSubstate;
import substates.ResetScoreSubState;

import flixel.math.FlxMath;
import flixel.util.FlxDestroyUtil;

import openfl.utils.Assets;

import haxe.Json;

import util.AnimOffsetHelper;

class FreeplayState extends MusicBeatState
{
    var songs:Array<SongMetadata> = [];
    var songOutlines:Array<FlxSprite> = [];

    var selector:FlxText;
    private static var curSelected:Int = 0;
    var lerpSelected:Float = 0;
    var curDifficulty:Int = -1;
    private static var lastDifficultyName:String = Difficulty.getDefault();

    var scoreBG:FlxSprite;
    var scoreText:FlxText;
    var diffText:FlxText;
    var lerpScore:Int = 0;
    var lerpRating:Float = 0;
    var intendedScore:Int = 0;
    var intendedRating:Float = 0;
    var songImageSize:Int = 450;

    private var grpSongs:FlxTypedGroup<FlxSprite>;
    private var curPlaying:Bool = false;

    var bg:FlxSprite;
    var intendedColor:Int;

    var missingTextBG:FlxSprite;
    var missingText:FlxText;

    var bottomString:String;
    var bottomText:FlxText;
    var bottomBG:FlxSprite;

    var leftArrow:FlxSprite;
    var rightArrow:FlxSprite;

    var player:MusicPlayer;

    var ui_tex = Paths.getSparrowAtlas('storyMenu/arrow');

    var displayScales:Array<Float> = [];

    var leftArrowOffsets:AnimOffsetHelper;
    var rightArrowOffsets:AnimOffsetHelper;

    static var dimColor:Int = FlxColor.fromRGB(126, 126, 126);

    var vcrFont = Paths.font("vcr.ttf");

    override function create()
    {
        persistentUpdate = true;
        PlayState.isStoryMode = false;
        WeekData.reloadWeekFiles(false);

        #if DISCORD_ALLOWED
        DiscordClient.changePresence("In the Menus", null);
        #end

        if(WeekData.weeksList.length < 1)
        {
            FlxTransitionableState.skipNextTransIn = true;
            persistentUpdate = false;
            MusicBeatState.switchState(new states.ErrorState("NO WEEKS ADDED FOR FREEPLAY\n\nPress ACCEPT to go to the Week Editor Menu.\nPress BACK to return to Main Menu.",
                function() MusicBeatState.switchState(new states.editors.WeekEditorState()),
                function() MusicBeatState.switchState(new states.MainMenuState())));
            return;
        }

        for (i in 0...WeekData.weeksList.length)
        {
            if(weekIsLocked(WeekData.weeksList[i])) continue;

            var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);

            var firstDiffIndex = 0;
            if (Reflect.hasField(leWeek, "difficulties")) {
                var diffs = Std.string(Reflect.field(leWeek, "difficulties")).split(",");
                if (diffs.length > 0) {
                    var firstDiff = StringTools.trim(diffs[0]);
                    firstDiffIndex = Std.int(Math.max(0, Difficulty.list.indexOf(firstDiff)));
                }
            }

            WeekData.setDirectoryFromWeek(leWeek);
            for (song in leWeek.songs)
            {
                var colors:Array<Int> = song[2];
                if(colors == null || colors.length < 3)
                {
                    colors = [146, 113, 253];
                }
                addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]), firstDiffIndex);
            }
        }
        Mods.loadTopMod();

        leftArrow = new FlxSprite(FlxG.width * 0.1, FlxG.height/2);		
        leftArrow.antialiasing = ClientPrefs.data.antialiasing;
        leftArrow.frames = ui_tex;
        leftArrow.animation.addByPrefix('idle', "idle");
        leftArrow.animation.addByPrefix('press', "press", 24, false);
        leftArrow.animation.play('idle');
        leftArrow.scale.x *= -1;

        rightArrow = new FlxSprite(FlxG.width * 0.9, FlxG.height/2);
        rightArrow.antialiasing = ClientPrefs.data.antialiasing;
        rightArrow.frames = ui_tex;
        rightArrow.animation.addByPrefix('idle', 'idle');
        rightArrow.animation.addByPrefix('press', "press", 24, false);
        rightArrow.animation.play('idle');

        leftArrowOffsets = new AnimOffsetHelper();
        leftArrowOffsets.addOffset('idle', 0, 0);   
        leftArrowOffsets.addOffset('press', 0, -5);

        rightArrowOffsets = new AnimOffsetHelper();
        rightArrowOffsets.addOffset('idle', 0, 0); 
        rightArrowOffsets.addOffset('press', 0, -5);

        bg = new FlxSprite().loadGraphic(Paths.image('backGround'));
        bg.antialiasing = ClientPrefs.data.antialiasing;
        bg.scrollFactor.set(0, 0);
        bg.updateHitbox();
        bg.screenCenter();
        add(bg);

        grpSongs = new FlxTypedGroup<FlxSprite>();

        for (i in 0...songs.length)
        {
            var songImage:FlxSprite = new FlxSprite().loadGraphic(Paths.image('songs/' + songs[i].songName.toLowerCase()));
            displayScales.push(i == curSelected ? 1 : 0.6);
            songImage.scale.set(songImageSize/songImage.width * displayScales[i], songImageSize/songImage.width * displayScales[i]);
            songImage.updateHitbox();
            songImage.antialiasing = ClientPrefs.data.antialiasing;

            var outline:FlxSprite = new FlxSprite(songImage.x - 3, songImage.y - 3);
            outline.makeGraphic(Std.int(songImage.width * songImage.scale.x) + 6, 
                                Std.int(songImage.height * songImage.scale.y) + 6, 
                                FlxColor.WHITE);
            outline.antialiasing = ClientPrefs.data.antialiasing;
            outline.visible = songImage.visible = songImage.active = false;

            songOutlines.push(outline);
            add(outline);
            grpSongs.add(songImage);

            Mods.currentModDirectory = songs[i].folder;
        }

        for (outline in songOutlines) add(outline);
        add(grpSongs);

        WeekData.setDirectoryFromWeek();

        scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
        scoreText.setFormat(vcrFont, 32, FlxColor.WHITE, RIGHT);

        scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
        scoreBG.alpha = 0.6;
        add(scoreBG);

        diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
        diffText.font = scoreText.font;
        add(diffText);

        add(scoreText);

        missingTextBG = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        missingTextBG.alpha = 0.6;
        missingTextBG.visible = false;
        add(missingTextBG);
        
        missingText = new FlxText(50, 0, FlxG.width - 100, '', 24);
        missingText.setFormat(vcrFont, 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
        missingText.scrollFactor.set();
        missingText.visible = false;
        add(missingText);

        if(curSelected >= songs.length) curSelected = 0;
        bg.color = songs[curSelected].color;
        intendedColor = bg.color;
        lerpSelected = curSelected;

        curDifficulty = Math.round(Math.max(0, Difficulty.defaultList.indexOf(lastDifficultyName)));

        bottomBG = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
        bottomBG.alpha = 0.6;
        add(bottomBG);

        var leText:String = Language.getPhrase("freeplay_tip", "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.");
        bottomString = leText;
        var size:Int = 16;
        bottomText = new FlxText(bottomBG.x, bottomBG.y + 4, FlxG.width, leText, size);
        bottomText.setFormat(vcrFont, size, FlxColor.WHITE, CENTER);
        bottomText.scrollFactor.set();
        add(bottomText);
        
        player = new MusicPlayer(this);
        add(player);
        
        changeSelection();
        updateTexts();

        add(leftArrow);
        add(rightArrow);

        super.create();
    }

    override function closeSubState()
    {
        changeSelection(0, false);
        persistentUpdate = true;
        super.closeSubState();
    }

    public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int, defaultDifficultyIndex:Int = 0)
    {
        songs.push(new SongMetadata(songName, weekNum, songCharacter, color, defaultDifficultyIndex));
    }

    function weekIsLocked(name:String):Bool
    {
        var leWeek:WeekData = WeekData.weeksLoaded.get(name);
        return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
    }

    var instPlaying:Int = -1;
    public static var vocals:FlxSound = null;
    public static var opponentVocals:FlxSound = null;
    var holdTime:Float = 0;

    var stopMusicPlay:Bool = false;
    override function update(elapsed:Float)
    {
        if(WeekData.weeksList.length < 1) return;

        if (ClientPrefs.data.menuTheme != "None" && FlxG.sound.music.volume < 0.7)
            FlxG.sound.music.volume += 0.5 * elapsed;

        lerpScore = Math.floor(FlxMath.lerp(intendedScore, lerpScore, Math.exp(-elapsed * 24)));
        lerpRating = FlxMath.lerp(intendedRating, lerpRating, Math.exp(-elapsed * 12));

        if (Math.abs(lerpScore - intendedScore) <= 10)
            lerpScore = intendedScore;
        if (Math.abs(lerpRating - intendedRating) <= 0.01)
            lerpRating = intendedRating;

        var ratingSplit:Array<String> = Std.string(CoolUtil.floorDecimal(lerpRating * 100, 2)).split('.');
        if(ratingSplit.length < 2) ratingSplit.push('');
        while(ratingSplit[1].length < 2) ratingSplit[1] += '0';

        var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

        if (!player.playingMusic)
        {
            scoreText.text = Language.getPhrase('personal_best', 'PERSONAL BEST: {1} ({2}%)', [lerpScore, ratingSplit.join('.')]);
            positionHighscore();

            if(songs.length > 1)
            {
                if(FlxG.keys.justPressed.HOME)
                {
                    curSelected = 0;
                    changeSelection();
                    holdTime = 0;	
                }
                else if(FlxG.keys.justPressed.END)
                {
                    curSelected = songs.length - 1;
                    changeSelection();
                    holdTime = 0;	
                }
                if (controls.UI_LEFT)
                {
                    leftArrow.animation.play('press', false);
                    leftArrowOffsets.applyOffset(leftArrow, 'press');
                }
                else
                {
                    leftArrow.animation.play('idle');
                    leftArrowOffsets.applyOffset(leftArrow, 'idle');
                }
                if (controls.UI_RIGHT)
                {
                    rightArrow.animation.play('press', false);
                    rightArrowOffsets.applyOffset(rightArrow, 'press');
                }
                else
                {
                    rightArrow.animation.play('idle');
                    rightArrowOffsets.applyOffset(rightArrow, 'idle');
                }
                if (controls.UI_LEFT_P)
                {
                    changeSelection(-shiftMult);
                    holdTime = 0;
                }
                if (controls.UI_RIGHT_P)
                {
                    changeSelection(shiftMult);
                    holdTime = 0;
                }
                if(controls.UI_LEFT || controls.UI_RIGHT)
                {
                    var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
                    holdTime += elapsed;
                    var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
                    if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
                        changeSelection((checkNewHold - checkLastHold) * (controls.UI_RIGHT ? shiftMult : -shiftMult));
                }
            }

            if (controls.UI_DOWN_P)
            {
                changeDiff(-1);
                _updateSongLastDifficulty();
            }
            else if (controls.UI_UP_P)
            {
                changeDiff(1);
                _updateSongLastDifficulty();
            }
        }

        if (controls.BACK)
        {
            if (player.playingMusic)
            {
                FlxG.sound.music.stop();
                destroyFreeplayVocals();
                FlxG.sound.music.volume = 0;
                instPlaying = -1;

                player.playingMusic = false;
                player.switchPlayMusic();
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuTheme)));
                if (ClientPrefs.data.menuTheme == 'None')
                    FlxG.sound.volume = 0;
                else
                    FlxTween.tween(FlxG.sound.music, {volume: 1}, 1);
            }
            else 
            {
                persistentUpdate = false;
                FlxG.sound.play(Paths.sound('cancelMenu'));
                MusicBeatState.switchState(new MainMenuState());
            }
        }

        if(FlxG.keys.justPressed.CONTROL && !player.playingMusic)
        {
            persistentUpdate = false;
            openSubState(new GameplayChangersSubstate());
        }
        else if(FlxG.keys.justPressed.SPACE)
        {
            var bodge:Bool = (curDifficulty < 1);
            if(instPlaying != curSelected && !player.playingMusic)
            {
                destroyFreeplayVocals();
                FlxG.sound.music.volume = 0;

                Mods.currentModDirectory = songs[curSelected].folder;
                var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
                Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
                if (PlayState.SONG.needsVoices)
                {
                    vocals = new FlxSound();
                    try
                    {
                        var playerVocals:String = getVocalFromCharacter(PlayState.SONG.player1);
                        var loadedVocals = Paths.voices(PlayState.SONG.song, (playerVocals != null && playerVocals.length > 0) ? playerVocals : 'Player', true, bodge);
                        if(loadedVocals == null) loadedVocals = Paths.voices(PlayState.SONG.song, null, true, bodge);
                        
                        if(loadedVocals != null && loadedVocals.length > 0)
                        {
                            vocals.loadEmbedded(loadedVocals);
                            FlxG.sound.list.add(vocals);
                            vocals.persist = vocals.looped = true;
                            vocals.volume = 0.8;
                            vocals.play();
                            vocals.pause();
                        }
                        else vocals = FlxDestroyUtil.destroy(vocals);
                    }
                    catch(e:Dynamic)
                    {
                        vocals = FlxDestroyUtil.destroy(vocals);
                    }
                    
                    opponentVocals = new FlxSound();
                    try
                    {
                        var oppVocals:String = getVocalFromCharacter(PlayState.SONG.player2);
                        var loadedVocals = Paths.voices(PlayState.SONG.song, (oppVocals != null && oppVocals.length > 0) ? oppVocals : 'Opponent', true, bodge);
                        
                        if(loadedVocals != null && loadedVocals.length > 0)
                        {
                            opponentVocals.loadEmbedded(loadedVocals);
                            FlxG.sound.list.add(opponentVocals);
                            opponentVocals.persist = opponentVocals.looped = true;
                            opponentVocals.volume = 0.8;
                            opponentVocals.play();
                            opponentVocals.pause();
                        }
                        else opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
                    }
                    catch(e:Dynamic)
                    {
                        opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
                    }
                }

                FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song, true, bodge), 0.8);
                FlxG.sound.music.pause();
                instPlaying = curSelected;

                player.playingMusic = true;
                player.curTime = 0;
                player.switchPlayMusic();
                player.pauseOrResume(true);
            }
            else if (instPlaying == curSelected && player.playingMusic)
            {
                player.pauseOrResume(!player.playing);
            }
        }
        else if (controls.ACCEPT && !player.playingMusic)
        {
            persistentUpdate = false;
            var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
            var poop:String = Highscore.formatSong(songLowercase, curDifficulty);

            try
            {
                Song.loadFromJson(poop, songLowercase);
                PlayState.isStoryMode = false;
                PlayState.storyDifficulty = curDifficulty;

                trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
            }
            catch(e:haxe.Exception)
            {
                trace('ERROR! ${e.message}');

                var errorStr:String = e.message;
                if(errorStr.contains('There is no TEXT asset with an ID of')) errorStr = 'Missing file: ' + errorStr.substring(errorStr.indexOf(songLowercase), errorStr.length-1);
                else errorStr += '\n\n' + e.stack;

                missingText.text = 'ERROR WHILE LOADING CHART:\n$errorStr';
                missingText.screenCenter(Y);
                missingText.visible = true;
                missingTextBG.visible = true;
                FlxG.sound.play(Paths.sound('cancelMenu'));

                updateTexts(elapsed);
                super.update(elapsed);
                return;
            }

            @:privateAccess
            if(PlayState._lastLoadedModDirectory != Mods.currentModDirectory)
            {
                trace('CHANGED MOD DIRECTORY, RELOADING STUFF');
                Paths.freeGraphicsFromMemory();
            }
            LoadingState.prepareToSong();
            LoadingState.loadAndSwitchState(new PlayState());
            #if !SHOW_LOADING_SCREEN FlxG.sound.music.stop(); #end
            stopMusicPlay = true;

            destroyFreeplayVocals();
            #if (MODS_ALLOWED && DISCORD_ALLOWED)
            DiscordClient.loadModRPC();
            #end
        }
        else if(controls.RESET && !player.playingMusic)
        {
            persistentUpdate = false;
            openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
            FlxG.sound.play(Paths.sound('scrollMenu'));
        }

        updateTexts(elapsed);
        super.update(elapsed);
    }
    
    function getVocalFromCharacter(char:String)
    {
        try
        {
            var path:String = Paths.getPath('characters/$char.json', TEXT);
            #if MODS_ALLOWED
            var character:Dynamic = Json.parse(File.getContent(path));
            #else
            var character:Dynamic = Json.parse(Assets.getText(path));
            #end
            return character.vocals_file;
        }
        catch (e:Dynamic) {}
        return null;
    }

    public static function destroyFreeplayVocals() {
        if(vocals != null) vocals.stop();
        vocals = FlxDestroyUtil.destroy(vocals);

        if(opponentVocals != null) opponentVocals.stop();
        opponentVocals = FlxDestroyUtil.destroy(opponentVocals);
    }

    function changeDiff(change:Int = 0)
    {
        if (player.playingMusic)
            return;

        curDifficulty = FlxMath.wrap(curDifficulty + change, 0, Difficulty.list.length-1);
        #if !switch
        intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
        intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
        #end

        lastDifficultyName = Difficulty.getString(curDifficulty, false);
        var displayDiff:String = Difficulty.getString(curDifficulty);
        if (Difficulty.list.length > 1)
            diffText.text = '< ' + displayDiff.toUpperCase() + ' >';
        else
            diffText.text = displayDiff.toUpperCase();

        positionHighscore();
        missingText.visible = false;
        missingTextBG.visible = false;
    }

    function changeSelection(change:Int = 0, playSound:Bool = true)
    {
        if (player.playingMusic)
            return;

        curSelected = FlxMath.wrap(curSelected + change, 0, songs.length - 1);
        curDifficulty = songs[curSelected].defaultDifficultyIndex;
        if (playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

        Mods.currentModDirectory = songs[curSelected].folder;
        PlayState.storyWeek = songs[curSelected].week;
        Difficulty.loadFromWeek();

        changeDiff(0);
        _updateSongLastDifficulty();
    }

    inline private function _updateSongLastDifficulty()
        songs[curSelected].lastDifficulty = Difficulty.getString(curDifficulty, false);

    private function positionHighscore()
    {
        scoreText.x = FlxG.width - scoreText.width - 6;
        scoreBG.scale.x = FlxG.width - scoreText.x + 6;
        scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
        diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
        diffText.x -= diffText.width / 2;
    }

    var _drawDistance:Int = 4;
    var _lastVisibles:Array<Int> = [];
    public function updateTexts(elapsed:Float = 0.0)
    {
        lerpSelected = FlxMath.lerp(curSelected, lerpSelected, Math.exp(-elapsed * 9.6));
        for (i in _lastVisibles)
        {
            if (grpSongs.members[i] != null) {
                grpSongs.members[i].visible = grpSongs.members[i].active = false;
                if (songOutlines[i] != null) songOutlines[i].visible = false;
            }
        }
        _lastVisibles = [];

        var min:Int = Std.int(Math.max(0, Math.floor(lerpSelected - _drawDistance)));
        var max:Int = Std.int(Math.min(songs.length, Math.ceil(lerpSelected + _drawDistance + 1)));
        var roundedLerp:Int = Math.round(lerpSelected);
        for (i in min...max)
        {
            var item:FlxSprite = grpSongs.members[i];
            var outline:FlxSprite = songOutlines[i];
            if (item == null || outline == null) continue;

            var offset:Float = i - lerpSelected;
            var targetScale:Float = (i == roundedLerp) ? 1 : 0.6;

            var prevScale = displayScales[i];
            displayScales[i] = FlxMath.lerp(targetScale, displayScales[i], Math.exp(-elapsed * 16));
            if (prevScale != displayScales[i])
                item.setGraphicSize(Std.int(songImageSize * displayScales[i]), Std.int(songImageSize * displayScales[i]));

            item.visible = item.active = true;
            item.color = (i == roundedLerp) ? FlxColor.WHITE : dimColor;
            item.updateHitbox();
            item.x = FlxG.width/2 - item.width/2 + offset * (songImageSize * 1.2);
            item.y = FlxG.height/2 - item.height/2;

            outline.visible = true;

            var thickness:Int = 6;
            var imgW:Int = Std.int(item.width);
            var imgH:Int = Std.int(item.height);

            var outlineW:Int = imgW + thickness;
            var outlineH:Int = imgH + thickness;

            if (outline.width != outlineW || outline.height != outlineH)
                outline.makeGraphic(outlineW, outlineH, FlxColor.WHITE);
            outline.x = item.x - thickness / 2;
            outline.y = item.y - thickness / 2;
            outline.alpha = item.alpha;

            _lastVisibles.push(i);
        }
    }

    override function destroy():Void
    {
        super.destroy();

        FlxG.autoPause = ClientPrefs.data.autoPause;
        if (!FlxG.sound.music.playing && !stopMusicPlay)
        {
            if (ClientPrefs.data.menuTheme == 'None')
                FlxG.sound.music.volume = 0;
            else
                FlxG.sound.playMusic(Paths.music(Paths.formatToSongPath(ClientPrefs.data.menuTheme)), 0);
        }
    }	
}

class SongMetadata
{
    public var songName:String = "";
    public var week:Int = 0;
    public var songCharacter:String = "";
    public var color:Int = -7179779;
    public var folder:String = "";
    public var lastDifficulty:String = null;
    public var defaultDifficultyIndex:Int = 0;

    public function new(song:String, week:Int, songCharacter:String, color:Int, defaultDifficultyIndex:Int = 0)
    {
        this.songName = song;
        this.week = week;
        this.songCharacter = songCharacter;
        this.color = color;
        this.folder = Mods.currentModDirectory;
        if(this.folder == null) this.folder = '';
        this.defaultDifficultyIndex = defaultDifficultyIndex;
    }
}