util.AddNetworkString("Killcam - Frames")
util.AddNetworkString("Killcam - Hitmarker")
util.AddNetworkString("Killcam - KillcamNPCID")
util.AddNetworkString("Killcam - KillcamNPCKilled")
util.AddNetworkString("CoDHUD_HitNotification")
util.AddNetworkString("KC_HitNotification")

hook.Add("StartCommand", "Killcam - Main handler", function(pl, cmd)
    if not pl.KC_Ready then return end
    if not KC_Playing() then
        if not pl.KC_Recorder then
            pl.KC_Recorder = Killcam.NewRecorder()
            pl.KC_Recorder:Attach(pl)
            print("Recorder object created for player ", pl)
        end
        pl.KILLCAM_StartDataInitiated = false
        pl.KC_Recorder:CaptureFrame(cmd)
    elseif pl.KC_Recorder and KC_isKiller(pl) then
        -- 13th attempt at the reload/fire-getting-stomped problem: the
        -- "buttons" data type (sh_replaydata.lua) calls cmd:SetButtons()
        -- on the CLIENT side (cl_main.lua's own PlayFrame call) so the
        -- killer's own client re-sends the ORIGINAL recorded IN_ATTACK/
        -- IN_RELOAD bits as this tick's real outgoing input -- a
        -- StartCommand modification isn't just local prediction, it's
        -- what actually gets transmitted. That means the SERVER receives
        -- genuine attack/reload input during replay, and the engine's
        -- native weapon system (CheckReload, ItemPostFrame -- and TFA
        -- Base's own logic, which checks owner:KeyDown(IN_ATTACK/
        -- IN_RELOAD) directly, independent of anything in this addon)
        -- reacts and fires/reloads the weapon FOR REAL, overwriting
        -- whatever sequence "weapon"'s Set() just forced -- explaining
        -- why neither suppressing wep.Think() (11th attempt) nor
        -- removing our own wep:Reload() call (12th attempt) ever fully
        -- stopped it: neither touches the engine's own reaction to
        -- genuine button input. Strip attack/reload from the SERVER's
        -- copy of cmd before replaying it, so the native weapon system
        -- never sees a real press during replay -- all visible
        -- reload/fire animation, sound, and clip state is driven purely
        -- by "weapon"'s own manual forcing (which already reads the
        -- recorded buttons directly from replay_frames, not from cmd).
        -- The killer's own client-side prediction (cl_main.lua) is left
        -- untouched, since that's local-only and not what the spectator
        -- watches.
        cmd:RemoveKey(IN_ATTACK)
        cmd:RemoveKey(IN_ATTACK2)
        cmd:RemoveKey(IN_RELOAD)
        pl.KC_Recorder:PlayFrame(cmd)
        return true
    end
end)

hook.Add("OnNPCKilled", "Killcam - Register kill", function(npc, attacker)
    if attacker:IsPlayer() and not KC_Playing() then
        attacker.KC_Recorder:SetKill(npc)
        --npc:Remove()
    end
end)

hook.Add("EntityTakeDamage", "Killcam - Show hit", function(target, dmg)
    if not KC_Playing() then return end
    local atk = dmg:GetAttacker()
    if not IsValid(atk) or not atk:IsPlayer() then return end
    if not KC_isKiller(atk) then return end
    -- Fire hitmarker for NPC kills AND bot player kills
    if target:IsNPC() or (target:IsPlayer() and target:IsBot()) then
        net.Start("Killcam - Hitmarker")
        net.Broadcast()
    end
end)

hook.Add("OnKillcamReplayStart", "Killcam - Start playing", function(pl)
    -- Used to also require "not KC_Playing()" here, back when
    -- Killcam.StartPlaying set Killcam_Playing=true AFTER running this
    -- hook. It now sets that flag first (see sv_replayhandler.lua), so
    -- KC_Playing() always reads true by the time this runs -- the real
    -- re-entrancy guard is Killcam.BeginFor's own check before StartPlaying
    -- is ever called.
    if pl.KC_Recorder then
        SetGlobalEntity("Killcam_Killer", pl)
        Killcam.SendFrames(pl)
        Killcam.LoadNPCData(pl)
        -- Freeze the round timer the moment a killcam starts.
        -- The timer resets fresh when the next round begins, so stopping
        -- it here prevents the round/match from ending mid-killcam.
        CoDHUD_RoundEndTimeSV = nil
    else
        return false
    end
end)

hook.Add("KillcamReplayStopped", "Killcam - Restore state", function()
    game.SetTimeScale(1)
    for _, v in pairs(player.GetAll()) do
        if not KC_isKiller(v) then
            -- Don't respawn sesh bots — they get kicked by sv_ffa_bots poll
            if v:IsBot() and SeshBot_Active then continue end
            v:Spectate(OBS_MODE_NONE)
            v:UnSpectate()
            v:Spawn()
        end
        SetGlobalEntity("Killcam_Killer", nil)
        if v.KC_Recorder then
            v.KC_Recorder:RestoreState()
        end
    end
end)

hook.Add("Initialize", "Killcam - Concommands", function()
    concommand.Add("kc_play", Killcam.StartPlaying)
    concommand.Add("kc_stop", Killcam.StopPlaying)
end)

net.Receive("Killcam - Frames", function(_, pl)
    pl.KC_Ready = true
end)