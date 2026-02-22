local tweenedHud = {
    'timeBar',
    'timeBarBG',
    'healthBar',
    'healthBarBG',
    'iconP1',
    'iconP2',
    'timeTxt',
    'scoreTxt'
}

local ogAlpha

function onSongStart()
    ogAlpha = getPropertyFromGroup('strumLineNotes', 0, 'alpha');
end

function onEvent(name, value1, value2)
    if lowQuality then return end -- HUD should only hide w/ cutscenes
    if name == 'Fade HUD' then 
        for i, specHud in ipairs(tweenedHud) do 
            doTweenAlpha('tween' .. i, specHud, tonumber(value2), tonumber(value1), 'linear') 
        end
        for i = 0,3 do
            setPropertyFromGroup('strumLineNotes', i, 'alpha', (getPropertyFromGroup('strumLineNotes', i, 'alpha') == 0) and ogAlpha or 0);
        end
        setProperty('showRating', not getProperty('showRating'));
        setProperty('showComboNum', not getProperty('showComboNum'));
    end
end