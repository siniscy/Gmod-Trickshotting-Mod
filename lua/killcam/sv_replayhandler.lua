local function gt()
    return GetGlobalInt("Killcam_ServerTick")
end
local function st(t)
    SetGlobalInt("Killcam_ServerTick", t)
end
st(1)

hook.Add("Think", "Killcam - Frame Handling", function()
    if KC_Playing() and IsValid(KC_GetKiller()) and KC_GetKiller().KC_Recorder then
        local recorder = KC_GetKiller().KC_Recorder
        SetGlobalFloat("Killcam_TimeToKill", recorder:TimeRemaining() or 0)
        if recorder:TimeSinceKill() >= 2 then
            -- Back to full speed once the reload/aftermath footage has had
            -- its 2 seconds -- TimeRemaining() alone can't do this since it
            -- clamps at 0 and stays there forever after the kill, which is
            -- why slow-mo used to hold all the way through the reload.
            game.SetTimeScale(1)
        elseif recorder:TimeRemaining() < 0.5 then
            game.SetTimeScale(0.3)
        else
            game.SetTimeScale(1)
        end
        Killcam.PlayNPCData()
        if gt() < Killcam.Frames then
            st(gt() + 1)
        else
            Killcam.StopPlaying()
        end
    else
        if Killcam.CaptureNPCData then
            Killcam.CaptureNPCData()
        end
    end
end)

function Killcam.StartPlaying(pl)
    local status = hook.Run("OnKillcamReplayStart", pl) or true
    if !status then return end
    st(1)
    SetGlobalBool("Killcam_Playing", true)
    hook.Run("KillcamReplayStarted")
end

function Killcam.StopPlaying()
    SetGlobalBool("Killcam_Playing", false)
    hook.Run("KillcamReplayStopped")
end

SetGlobalBool("Killcam_Playing", false)