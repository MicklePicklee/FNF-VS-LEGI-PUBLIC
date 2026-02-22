local startCheck = false
local don = false

function onStartCountdown()
  if not startCheck and not don and isStoryMode and not seenCutscene then
  runTimer('startVid', 0.1)
  return Function_Stop;
  end
end

function onCreate()
  don = difficultyName == 'Double Or Nothing'
end

function onTimerCompleted(tag)
  if tag == 'startVid' then
    startCheck = true
    startVideo('intro',true)
  end
end