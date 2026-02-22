local prepTime = 8
local prepStep = 0
local step = 0
local endStep = 0
local cutsceneName = "ppEvent"
wigglers = {'sky', 'mountains', 'backBuildings', 'clouds', 'buildings', 'wall', 'middleGround', 'foreGround'}

function onCreate()
    
    if difficultyName == 'Double Or Nothing' then
        cutsceneName = 'ppEvent-DON'
        step = 636
        endStep = 765
    else
        cutsceneName = 'ppEvent'
        step = 512
        endStep = 640
    end

    prepStep = step - prepTime
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

function onStepHit()
    if curStep == 1 then
        startVideo(cutsceneName, false, true, false, true)
        setObjectCamera('videoCutscene','hud') 
        setObjectOrder('videoCutscene', 0)
        setProperty('videoCutscene.alpha', 0)
        callMethod('videoCutscene.pause')
    elseif curStep == prepStep then
        if (shadersEnabled) then
            for i in pairs(wigglers) do 
                setSpriteShader(wigglers[i], 'stridentCrisisWavy')
		        setShaderFloat(wigglers[i], 'uWaveAmplitude', 0.01)
		        setShaderFloat(wigglers[i], 'uFrequency', 2)
		        setShaderFloat(wigglers[i], 'uSpeed', 2)
            end
        end
    elseif curStep == step then
        playing = true
        callMethod('videoCutscene.play')
        doTweenAlpha('a', 'videoCutscene', 1, 0.2, 'linear')
    elseif curStep == endStep then
        removeLuaSprite('videoCutscene', true)
        close()
    end
end

function onTweenCompleted(tag)
    if tag == 'a' and shadersEnabled then
        for i in pairs(wigglers) do removeSpriteShader(wigglers[i]) end
    end
end

