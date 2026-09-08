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

-- 7th attempt at the killer's-reload-invisible-to-spectator problem.
-- cl_killcam_hands.lua's own history (a separate, earlier fix for hands
-- not appearing on a spectated player's viewmodel) recorded something
-- critical: PreDrawViewModel/PostDrawViewModel hooks were CONFIRMED via
-- live testing to never fire at all for a spectated (non-local) player's
-- viewmodel. That means an OBS_MODE_IN_EYE spectator's rendering of
-- someone else's viewmodel bypasses the normal Lua hook pipeline
-- entirely -- it's driven by the raw entity's NETWORKED sequence/cycle,
-- computed server-side, not anything a client-side Lua call can
-- influence for a third party. That explains every previous attempt:
-- SendWeaponAnim on the WEAPON entity (not the viewmodel) never touched
-- what's actually networked for the viewmodel's pose; a CLIENT-side
-- ResetSequence on the viewmodel (6th attempt) was the right entity but
-- the wrong realm -- purely local/cosmetic, never networked to anyone.
-- This is the first attempt at the right entity AND the right realm:
-- SERVER-side ResetSequence directly on the killer's actual viewmodel
-- entity, so it becomes part of that entity's normal networked baseline
-- like any other server-driven animation change.

-- CLIENT-side diagnostic for whoever is SPECTATING during killcam: prints
-- whenever the sequence of the killer's viewmodel (as seen on THIS
-- client) changes. Compared against the server's own
-- "[KC Reload VM DEBUG]" print for the same moment, this tells us
-- whether the server's ResetSequence call is even reaching the
-- spectator's client at all (sequence number matches what the server
-- set) or never arrives (sequence stays frozen on whatever it was) --
-- a networking problem vs. a pure rendering problem are very different
-- fixes.
if CLIENT then
    local lastSeq, lastVM
    hook.Add("Think", "KC_ReloadVM_SpectatorWatch", function()
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        local target = lp:GetObserverTarget()
        if not IsValid(target) or not target:IsPlayer() or target == lp then
            lastSeq, lastVM = nil, nil
            return
        end
        local vm = target:GetViewModel()
        if not IsValid(vm) then
            lastSeq, lastVM = nil, nil
            return
        end
        local seq = vm:GetSequence()
        if vm ~= lastVM or seq ~= lastSeq then
            lastVM, lastSeq = vm, seq
            print("[KC Reload VM SPECTATOR] watching " .. target:Nick() .. "'s viewmodel " .. tostring(vm:GetModel()) ..
                " -- sequence changed to " .. tostring(seq) .. " (" .. tostring(vm:GetSequenceName(seq)) .. ")")
        end
    end)
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

-- EXPERIMENTAL: force the weapon's raw fire sound on CHAN_AUTO, which the
-- engine guarantees a free channel for rather than making it compete for a
-- shared one -- so it can't get cut off by (or cut off) anything else
-- playing at the same time. This is purely additive alongside whatever
-- DoAttackEvent() already does internally (TFA Base's own channel choice
-- is opaque to us) -- if a weapon has no ordinary Primary.Sound to find,
-- this silently does nothing and nothing changes.
local function ForceGunSoundAuto(wep)
    if not IsValid(wep) or not wep.Primary then return end
    local snd = wep.Primary.Sound
    if istable(snd) then snd = snd[1] end
    if isstring(snd) and snd ~= "" then
        wep:EmitSound(snd, 75, 100, 1, CHAN_AUTO)
    end
end

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
                -- Detect a reload from the recorded INPUT (see below) and
                -- trigger the animation server-side so it's actually
                -- visible. Without this, only the raw clip number silently
                -- snapped between frames: "buttons" (which replays the
                -- IN_RELOAD keypress that would naturally trigger this) is
                -- clientside-only, so it only affects the killer's own
                -- local prediction -- every spectator watches the server's
                -- simulation, which never got told a reload was happening
                -- at all.
                local recorder = pl.KC_Recorder
                local tick = KC_ServerTick and KC_ServerTick()
                if recorder and tick and tick > 1 then
                    local prevFrame  = recorder.replay_frames[tick - 1]
                    local curFrame   = recorder.replay_frames[tick]
                    local prevWeapon = prevFrame and prevFrame.weapon
                    if prevWeapon and prevWeapon[1] == weptbl[1] and weptbl[2] and prevWeapon[2] then
                        -- 3rd attempt: every clip-delta heuristic (any
                        -- increase, then "must reach max clip", then that
                        -- same check plus a cooldown) still misfired --
                        -- TFA Base's own Clip1() reporting is genuinely
                        -- noisy at the RECORDING source (a single real
                        -- reload can be recorded as e.g. 4->5->4->5),
                        -- not just during replay, so no clip-value
                        -- threshold can ever be reliable. Use the actual
                        -- recorded input instead: "buttons" already
                        -- captures cmd:GetButtons() every recorded tick
                        -- (a raw input flag, not a derived/predicted game
                        -- value -- nothing for TFA Base to jitter). Fire
                        -- once on the rising edge of IN_RELOAD in the
                        -- recording -- the exact tick the player actually
                        -- pressed reload.
                        local prevButtons = prevFrame and prevFrame.buttons
                        local curButtons  = curFrame and curFrame.buttons
                        local wasReloading = prevButtons and bit.band(prevButtons, IN_RELOAD) ~= 0
                        local isReloading  = curButtons and bit.band(curButtons, IN_RELOAD) ~= 0
                        if isReloading and not wasReloading then
                            -- 4th attempt: SendWeaponAnim(ACT_VM_RELOAD) on
                            -- the weapon confirmed FIRING every time
                            -- (server-side log proof), yet a spectator
                            -- watching via OBS_MODE_IN_EYE still never saw
                            -- it -- only the killer did (almost certainly
                            -- via their OWN TFA Base client prediction
                            -- reacting to the replayed IN_RELOAD button
                            -- press, unrelated to this call, and useless to
                            -- a third-party spectator). Trying
                            -- SendWeaponAnim directly on the viewmodel
                            -- entity CRASHED outright -- SendWeaponAnim
                            -- isn't a valid method there, it's weapon-only.
                            -- Call the weapon's own Reload() instead --
                            -- the actual function the engine calls when a
                            -- real player presses R, which handles
                            -- whatever sound/animation/state TFA Base
                            -- needs internally, rather than us guessing at
                            -- which low-level call replicates correctly.
                            if isfunction(wep.Reload) then
                                wep:Reload()
                            end
                            -- 8th attempt: the recorded clip can read as
                            -- already full on the SAME tick IN_RELOAD is
                            -- first pressed (recording granularity --
                            -- the real reload takes ~2s to visually
                            -- complete, but if the live clip-refill event
                            -- landed inside one recorded tick, that's all
                            -- the recording ever captured). wep:SetClip1
                            -- below runs unconditionally every tick and
                            -- would then jump the clip to full THIS SAME
                            -- TICK the reload just started -- if TFA Base
                            -- checks "is the clip already full" to decide
                            -- a reload is done, an instantly-full clip
                            -- would cancel the animation almost
                            -- immediately, independent of shot detection
                            -- entirely. Hold the clip at its pre-reload
                            -- value for a grace period so the animation
                            -- has time to actually play before the clip
                            -- visibly refills.
                            recorder.KC_ReloadGraceUntil = CurTime() + 1.6
                            recorder.KC_ReloadHoldClip1  = prevWeapon[2]
                            recorder.KC_ReloadHoldClip2  = prevWeapon[3]
                            -- 7th attempt: SERVER-side ResetSequence
                            -- directly on the killer's actual viewmodel
                            -- entity (see the top-of-file comment) --
                            -- becomes part of that entity's normal
                            -- networked baseline, which is what an
                            -- OBS_MODE_IN_EYE spectator's viewmodel
                            -- rendering actually reads from.
                            local vm = pl:GetViewModel()
                            if IsValid(vm) then
                                local seq = vm:SelectWeightedSequence(ACT_VM_RELOAD)
                                if seq and seq >= 0 then
                                    vm:ResetSequence(seq)
                                    vm:SetCycle(0)
                                    vm:SetPlaybackRate(1)
                                end
                                -- DIAGNOSTIC: if this weapon's viewmodel
                                -- model never had a sequence tagged with
                                -- the standard ACT_VM_RELOAD activity in
                                -- the first place (common for custom TFA
                                -- Base content, which often looks up
                                -- reload animations by exact sequence name
                                -- internally instead of the activity
                                -- system), SelectWeightedSequence returns
                                -- -1 and nothing built on it could ever
                                -- have worked, regardless of entity/realm.
                                print("[KC Reload VM DEBUG] model=" .. tostring(vm:GetModel()) ..
                                    " ACT_VM_RELOAD seq=" .. tostring(seq) ..
                                    " seqCount=" .. tostring(vm:GetSequenceCount()) ..
                                    " currentSeq=" .. tostring(vm:GetSequence()) ..
                                    " currentSeqName=" .. tostring(vm:GetSequenceName(vm:GetSequence())))
                            end
                            print("[KC Reload] FIRED (IN_RELOAD edge) for " .. pl:Nick() .. " weapon=" .. tostring(weptbl[1]))
                        end
                        local isAttacking = curButtons and bit.band(curButtons, IN_ATTACK) ~= 0
                        if weptbl[2] < prevWeapon[2] and isAttacking then
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
                            --
                            -- Used to fire on ANY clip decrease alone --
                            -- same class of noisy-clip-value bug already
                            -- fixed for reload detection. Confirmed via a
                            -- live [KC Reload VM SPECTATOR] log: a reload's
                            -- sequence correctly reached the spectator's
                            -- client, then got overwritten by a "fire"
                            -- sequence change within a tick or two --
                            -- clip-read noise right as the clip resets to
                            -- max was enough to look like a "decrease" on
                            -- some later tick, false-triggering a shot that
                            -- cut the reload animation short before it
                            -- could visibly play. Now also requires
                            -- IN_ATTACK actually held this tick -- still
                            -- catches every real shot of an automatic
                            -- weapon (IN_ATTACK stays held the whole
                            -- burst, so this isn't a rising-edge check),
                            -- but a clip blip with no attack input behind
                            -- it can no longer fire this.
                            local frame = recorder:GetFrame(tick)
                            if not (frame and frame.kill) then
                                pl:DoAttackEvent()
                            end
                            ForceGunSoundAuto(wep)
                        end
                    end
                end

                if recorder and recorder.KC_ReloadGraceUntil and CurTime() < recorder.KC_ReloadGraceUntil then
                    -- Still inside the reload's grace window -- keep
                    -- showing the pre-reload (low/empty) clip instead of
                    -- the recorded value, so the reload animation has
                    -- time to actually play before the clip visibly
                    -- refills. See the reload-trigger block above.
                    wep:SetClip1(recorder.KC_ReloadHoldClip1)
                    wep:SetClip2(recorder.KC_ReloadHoldClip2)
                else
                    wep:SetClip1(weptbl[2])
                    wep:SetClip2(weptbl[3])
                end
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
            ForceGunSoundAuto(pl:GetActiveWeapon())
        end
    end,
})