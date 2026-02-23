local prepTime = 8
local cloudTime = 3
local step = 0
local endStep = 0
local cutsceneName = "ppEvent"
wigglers = {'sky', 'mountains', 'backBuildings', 'clouds', 'buildings', 'wall', 'middleGround', 'foreGround'}

function onCreate()
    
    if difficultyName == 'Double Or Nothing' then
        cutsceneName = 'ppEvent-DON'
        step = 636
        endStep = 765
        cloudTime = 5
    else
        cutsceneName = 'ppEvent'
        step = 512
        endStep = 640
        cloudTime = 3
    end

    makeFlxAnimateSprite('cloud', -2800, -2800, 'stages/park/events/clouds')
    addAnimationBySymbolIndices('cloud', 'in', 'Clouding', {0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23}, 24, false)
    addAnimationBySymbolIndices('cloud', 'out', 'Clouding', {24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,43,44,45,46,47}, 24,false)
    setObjectCamera('cloud', 'hud')
    setObjectOrder('cloud', 2)
    setProperty('cloud.visible', false)
    addLuaSprite('cloud', false);

    makeLuaSprite('white', '', 0, 0)
	makeGraphic('white', 1, 1, 'FFFFFF   0')
    scaleObject('white', screenWidth, screenHeight)
    addLuaSprite('white', false);
    setObjectCamera('white', 'hud')
    setProperty('white.alpha', 0)
    setObjectOrder('white', 1)
end

function onUpdatePost(elapsed)
    if (shadersEnabled) then
        for i in pairs(wigglers) do setShaderFloat(wigglers[i], 'uTime', os.clock()) end
    end
end

function onCreatePost()
    if (shadersEnabled) then
        initLuaShader('stridentCrisisWavy')
    end
end

function onResume()
    if getProperty('videoCutscene') == nil or not playing then return end
    callMethod('videoCutscene.resume')
end

function onPause()
    if getProperty('videoCutscene') == nil or not playing then return end
    callMethod('videoCutscene.pause')
end

function onSongStart()
    startVideo(cutsceneName, false, true, false, true)
    setObjectCamera('videoCutscene','hud') 
    setObjectOrder('videoCutscene', 0)
    callMethod('videoCutscene.pause')
end


function onStepHit()
    if curStep == step-prepTime then
        if (shadersEnabled) then
            for i in pairs(wigglers) do 
                setSpriteShader(wigglers[i], 'stridentCrisisWavy')
		        setShaderFloat(wigglers[i], 'uWaveAmplitude', 0.01)
		        setShaderFloat(wigglers[i], 'uFrequency', 2)
		        setShaderFloat(wigglers[i], 'uSpeed', 2)
            end
        end
    elseif curStep == step-cloudTime then
        setProperty('cloud.visible', true)
        playAnim('cloud', 'in', true)
        runTimer('fadeIn', 0.4)
    elseif curStep == step then
        playing = true
        callMethod('videoCutscene.play')
        playAnim('cloud', 'out', true)
        runTimer('fadeOut', 0.4)
    elseif curStep == endStep then
        removeLuaSprite('videoCutscene', true)
        close()
    end
end

function onTweenCompleted(tag)
    if tag == 'fadeOut' and shadersEnabled then
        for i in pairs(wigglers) do removeSpriteShader(wigglers[i]) end
        removeLuaSprite('white', true)
        removeLuaSprite('cloud', true)
    end
end

function onTimerCompleted(tag, loops, loopsLeft)
    if tag == 'fadeIn' then
        doTweenAlpha('fadeIn', 'white', 1, 0.2, 'easeInOutQuad')
    elseif tag == 'fadeOut' then
        doTweenAlpha('fadeOut', 'white', 0, 0.5, 'easeInOutQuad')
    end
end

