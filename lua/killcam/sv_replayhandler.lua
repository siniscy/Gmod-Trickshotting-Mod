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
        if recorder:TimeSinceKill() >= 0.75 then
            -- Back to full speed shortly after impact -- TimeRemaining()
            -- alone can't do this since it clamps at 0 and stays there
            -- forever after the kill, which is why slow-mo used to hold
            -- all the way through the reload.
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
    -- Set the Killcam_Playing flag BEFORE running OnKillcamReplayStart
    -- (which sends the killer a large compressed replay-data blob via
    -- Killcam.SendFrames). When a remote (non-host) client was the killer,
    -- that big blob and this small networked global were being sent to
    -- the same connection back-to-back, and the global update was
    -- consistently getting lost for that client -- it never once compared
    -- Killcam_Playing=true afterward, even though the listen-server host
    -- always saw it fine (their own GetGlobalBool never goes over the
    -- network at all, so it isn't affected by this ordering). Giving the
    -- small critical flag a head start in the send queue avoids that.
    st(1)
    SetGlobalBool("Killcam_Playing", true)
    local status = hook.Run("OnKillcamReplayStart", pl) or true
    if !status then
        SetGlobalBool("Killcam_Playing", false)
        return
    end
    hook.Run("KillcamReplayStarted")
end

function Killcam.StopPlaying()
    -- DIAGNOSTIC: the replay has a fixed frame count (Killcam.Frames) --
    -- if a reload is triggered late enough in the post-kill footage,
    -- its 1.6s grace window can still be running when the killcam just
    -- runs out of frames and ends outright, cutting the animation off
    -- with no chance for the spectator to ever see it (not even the
    -- brief flicker seen in other cases). This prints whether that's
    -- what happened, to tell it apart from an actual sequence fight.
    local killer = KC_GetKiller()
    if IsValid(killer) and killer.KC_Recorder and killer.KC_Recorder.KC_ReloadGraceUntil then
        local remaining = killer.KC_Recorder.KC_ReloadGraceUntil - CurTime()
        if remaining > 0 then
            print("[KC Reload VM DEBUG] Killcam ending with " .. string.format("%.2f", remaining) ..
                "s of reload grace still unconsumed -- animation was cut off by the replay running out of frames, not overwritten.")
        end
    end
    SetGlobalBool("Killcam_Playing", false)
    hook.Run("KillcamReplayStopped")
end

SetGlobalBool("Killcam_Playing", false)