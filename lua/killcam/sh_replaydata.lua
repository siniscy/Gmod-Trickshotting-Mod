--[[
    Data processors
--]]

local Data = {}
local DefaultTypes = {}
local SidedTypes = {}

local function RegisterData(name, tbl)
    Data[name] = tbl
    if not tbl.dontstore then
        DefaultTypes[name] = true
    end
    if SERVER and tbl.serverside then
        SidedTypes[name] = true
    end
    if CLIENT and tbl.clientside then
        SidedTypes[name] = true
    end
end

function Killcam.CollectData(pl, cmd, types)
    local tbl = {}
    if types then
        for i = 1, #types do
            if Data[types[i]] then 
                tbl[types[i]] = Data[types[i]].Get(pl, cmd)
            end
        end
        return tbl
    end
    for typ,_ in pairs(DefaultTypes) do
       tbl[typ] = Data[typ].Get(pl, cmd)
    end
    return tbl
end

function Killcam.SetData(pl, cmd, data)
    if not data then return end
    for typ, val in pairs(data) do
        if not SidedTypes[typ] then continue end
        if Data[typ].onetime and pl.KILLCAM_StartDataInitiated then continue end
        Data[typ].Set(pl, cmd, val)
    end
    pl.KILLCAM_StartDataInitiated = true
end

if SERVER then
    util.AddNetworkString("Killcam - Frames")
    util.AddNetworkString("Killcam - NPC Frames")
    local function SendFramesToPly(pl)
        local tb = {}
        local frameCount = #pl.KC_Recorder.replay_frames
        for i = 1, frameCount do
            tb[i] = {}
            for typ, d in pairs(Data) do
                if d.clientside then
                    local frame = pl.KC_Recorder.replay_frames[i]
                    if frame then
                        tb[i][typ] = frame[typ]
                    end
                end
            end
        end
        local s = util.Compress(util.TableToJSON(tb))
        net.Start("Killcam - Frames")
            net.WriteUInt(#s, 24)
            net.WriteData(s, #s)
        net.Send(pl)
    end
    function Killcam.SendFrames(pl)
        assert(pl.KC_Recorder.kc_frames[1], "[Killcam] "..tostring(pl).." Player has no recorded frames to send!")
        for _,v in pairs(player.GetAll()) do
            if not v.KC_Recorder then continue end  -- skip bots
            v.KC_Recorder:SaveState()
            if pl == v then 
                pl.KC_Recorder:SetReplayFrames(pl)
                SendFramesToPly(pl)
                do
                    local npcData = {}
                    local killID = nil
                    for i, frame in pairs(pl.KC_Recorder.replay_frames) do
                        if frame and frame.kill then
                            killID = frame.kill
                            break
                        end
                    end
                    local botKillID = (KC_BotKillID_Server and KC_BotKillID_Server > 0) and KC_BotKillID_Server or -1
                    if pl.KC_Recorder.npc_frames then
                        for frameIdx, frameNPCs in pairs(pl.KC_Recorder.npc_frames) do
                            npcData[frameIdx] = {}
                            for npcId, data in pairs(frameNPCs) do
                                if not data.removed and not data.killed then
                                    npcData[frameIdx][tostring(npcId)] = {
                                        pos   = {data.pos.x, data.pos.y, data.pos.z},
                                        ang   = {data.ang.p, data.ang.y, data.ang.r},
                                        seq   = data.seq,
                                        cycle = data.cycle,
                                        class = data.class,
                                        model = data.model,
                                        kill  = (npcId == killID) or nil,
                                    }
                                else
                                    npcData[frameIdx][tostring(npcId)] = {removed = true}
                                end
                            end
                        end
                    end
                    local s = util.Compress(util.TableToJSON(npcData))
                    net.Start("Killcam - NPC Frames")
                        net.WriteUInt(#s, 24)
                        net.WriteData(s, #s)
                        net.WriteInt(botKillID, 32)
                    net.Send(pl)
                end
                continue 
            end
            v:StripWeapons()
            v:SetMoveType(MOVETYPE_OBSERVER)
            v:Spectate(OBS_MODE_IN_EYE)
            v:SpectateEntity(pl)
        end
    end
end

--[[
    Data to collect
]]

RegisterData("time", {
    serverside = true,
    clientside = true,
    Get = function() return CurTime() end,
    Set = function() end,
})

RegisterData("pos", {
    serverside = true,
    clientside = false,
    Get = function(pl, _) return pl:GetPos() end,
    Set = function(pl, _, pos)
        if pl.KILLCAM_StartDataInitiated then
            local distSqr = pos:DistToSqr(pl:GetPos())
            if distSqr > 40000 then
                -- The recorded position jumped a huge distance from the
                -- previous frame -- noclip flying, an admin teleport, a
                -- round-start/spawn reset, etc. happening during the
                -- ~10s recording window. Chasing that with SetVelocity
                -- (the normal smoothing path below) can't reproduce an
                -- instant teleport: it either drags the replay across the
                -- map over several seconds or slams into world geometry
                -- at absurd speed and gets stuck, which is why the killer
                -- sometimes ends up nowhere near where they should be
                -- during killcam. Snap instantly instead, matching the
                -- real teleport that produced this frame.
                pl:SetPos(pos)
                pl:SetVelocity(vector_origin)
            elseif distSqr > 25 then
                pl:SetVelocity((pos-pl:GetPos())*9)
            end
        else
            pl:SetPos(pos)
        end
    end
})

RegisterData("angle", {
    serverside = false,
    clientside = true,
    Get = function(pl, _) return pl:EyeAngles() end,
    Set = function(pl, cmd, angle)
        if pl.KILLCAM_StartDataInitiated then
            local ang = LerpAngle(FrameTime() / engine.ServerFrameTime() * 0.125, pl:EyeAngles(), angle)
            ang.r = 0
            cmd:SetViewAngles(ang)
        else
            cmd:SetViewAngles(angle)
        end
    end,
})

RegisterData("_pos", {
    dontstore = true,
    serverside = true,
    clientside = false,
    Get = function(pl, _) return pl:GetPos() end,
    Set = function(pl, _, pos) pl:SetPos(pos) end,
})

RegisterData("_angle", {
    dontstore = true,
    serverside = true,
    clientside = false,
    Get = function(pl, _) return pl:EyeAngles() end,
    Set = function(pl, _, angle) pl:SetEyeAngles(angle) end,
})

RegisterData("velocity", {
    serverside = true,
    clientside = false,
    Get = function(pl, _) return pl:GetAbsVelocity() end,
    Set = function(pl, _, velo) pl:SetLocalVelocity(velo) end,
})

RegisterData("buttons", {
    serverside = false,
    clientside = true,
    Get = function(pl, cmd) return cmd:GetButtons() end,
    Set = function(pl, cmd, btns) cmd:SetButtons(btns) end,
})

RegisterData("weapon", {
    serverside = true,
    clientside = false,
    Get = function(pl, cmd)
        local wep = pl:GetActiveWeapon()
        return IsValid(wep) and {wep:GetClass(), wep:Clip1(), wep:Clip2()} or false
    end,
    Set = function(pl, cmd, weptbl)
        if weptbl then
            if not pl:HasWeapon(weptbl[1]) then
                pl:Give(weptbl[1])
            end
            pl:SelectWeapon(weptbl[1])
            local wep = pl:GetActiveWeapon()
            if IsValid(wep) then
                -- If the recorded clip is higher than the PREVIOUS replayed
                -- frame's clip (same weapon), a reload happened at this
                -- point in the original recording -- trigger the reload
                -- animation so it's actually visible. Without this, only
                -- the raw clip number silently snapped between frames:
                -- "buttons" (which replays the IN_RELOAD keypress that
                -- would naturally trigger this) is clientside-only, so it
                -- only affects the killer's own local prediction -- every
                -- spectator watches the server's simulation, which never
                -- got told a reload was happening at all.
                local recorder = pl.KC_Recorder
                local tick = KC_ServerTick and KC_ServerTick()
                if recorder and tick and tick > 1 then
                    local prevFrame  = recorder.replay_frames[tick - 1]
                    local prevWeapon = prevFrame and prevFrame.weapon
                    if prevWeapon and prevWeapon[1] == weptbl[1] and weptbl[2] and prevWeapon[2] then
                        -- A genuine reload always tops the clip back up to
                        -- (at least) max capacity. Requiring just "clip went
                        -- up at all" was wrong -- a harmless +1 blip (clip
                        -- prediction/reconciliation noise between frames,
                        -- not an actual reload) was enough to fire the full
                        -- reload animation, which is why reloads appeared to
                        -- trigger at random moments during killcam that
                        -- didn't match anything the player actually did.
                        local maxClip1 = wep:GetMaxClip1()
                        if weptbl[2] > prevWeapon[2] and maxClip1 > 0 and weptbl[2] >= maxClip1 then
                            print("[ReloadFix DEBUG] Detected reload during replay: " .. pl:Nick()
                                .. " " .. weptbl[1] .. " clip " .. prevWeapon[2] .. " -> " .. weptbl[2]
                                .. " (tick " .. tick .. ") -- firing SendWeaponAnim(ACT_VM_RELOAD)")
                            wep:SendWeaponAnim(ACT_VM_RELOAD)
                        elseif weptbl[2] < prevWeapon[2] then
                            -- A shot was fired at this point in the original
                            -- recording. The natural replay path for this
                            -- (the "buttons" data type replaying IN_ATTACK)
                            -- is clientside-only prediction on a puppet that
                            -- isn't the local player's own weapon -- some
                            -- weapon bases (TFA Base, used by every weapon
                            -- in this addon) skip re-emitting a predicted
                            -- fire sound in that situation, which is why the
                            -- shot sound sometimes went silent during
                            -- killcam. Force it the same reliable, server-
                            -- side way the kill shot itself already does
                            -- (see the "shot" data type below) so every
                            -- shot is audible, not just the last one. Skip
                            -- the kill frame itself -- it already gets its
                            -- own DoAttackEvent() call from "shot", and
                            -- firing twice in the same tick would double up
                            -- the sound/muzzle flash.
                            local frame = recorder:GetFrame(tick)
                            if not (frame and frame.kill) then
                                pl:DoAttackEvent()
                            end
                        end
                    end
                end

                wep:SetClip1(weptbl[2])
                wep:SetClip2(weptbl[3])
            end
            return
        end
        pl:StripWeapons()
    end,
})

RegisterData("ammo", {
    onetime = true,
    serverside = true,
    clientside = false,
    Get = function(pl, _) return pl:GetAmmo() end,
    Set = function(pl, cmd, ammotbl)
        for id, amount in pairs(ammotbl) do
            pl:SetAmmo(id, amount)
        end
    end,
})

RegisterData("shot", {
    serverside = true,
    clientside = false,
    Get = function() return false end,
    Set = function(pl, cmd)
        if pl.KC_Recorder:GetFrame(KC_ServerTick()).kill then
            pl:DoAttackEvent()
        end
    end,
})