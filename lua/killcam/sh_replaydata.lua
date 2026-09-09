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

-- 14th attempt: a host log proved the server-side reload state
-- (KC_ReloadActive, forced sequence/cycle) was behaving correctly on a
-- round the spectator still never saw show at all -- no "shot cancelled"
-- print, no "mid-reload...forcing back" fight, the animation was still
-- actively held when the replay ran out of frames, exactly like a round
-- that DID display correctly for the same spectator. That rules out
-- logic entirely: this is the same networked-delivery-gap problem
-- already fixed once this session for Killcam_Playing/Killcam_Killer --
-- a piece of server-authoritative state that's supposed to replicate to
-- every client identically, but has been observed to silently fail to
-- reach a genuine remote client's connection on some rounds while never
-- failing for the listen-server host (whose own reads never go over the
-- network at all). The fix there was the same: stop trusting the flaky
-- channel and add a small, dedicated, explicitly-sent net message
-- instead. Doing the same here for the viewmodel's reload sequence,
-- rather than relying on it reaching the spectator as part of normal
-- entity baseline replication.
if SERVER then
    util.AddNetworkString("KC_ReloadVMState")
end

local function KC_BroadcastReloadState(pl, active, seq, startTime)
    net.Start("KC_ReloadVMState")
        net.WriteEntity(pl)
        net.WriteBool(active)
        if active then
            net.WriteUInt(seq, 16)
            net.WriteFloat(startTime)
        end
    net.Broadcast()
end

if CLIENT then
    _G.KC_ReloadNetState = _G.KC_ReloadNetState or {}
    net.Receive("KC_ReloadVMState", function()
        local pl     = net.ReadEntity()
        local active = net.ReadBool()
        if not IsValid(pl) then return end
        if active then
            _G.KC_ReloadNetState[pl] = {
                seq       = net.ReadUInt(16),
                startTime = net.ReadFloat(),
            }
        else
            _G.KC_ReloadNetState[pl] = nil
        end
    end)

    -- Applied purely client-side, independent of the viewmodel entity's
    -- own networked sequence/cycle -- only for whoever we're actually
    -- SPECTATING (the killer's own client already handles its own view
    -- normally and shouldn't be touched here).
    hook.Add("Think", "KC_ReloadVM_NetForce", function()
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        for pl, data in pairs(_G.KC_ReloadNetState) do
            if not IsValid(pl) then
                _G.KC_ReloadNetState[pl] = nil
                continue
            end
            if pl == lp then continue end
            local target = lp:GetObserverTarget()
            if target ~= pl then continue end
            local vm = pl:GetViewModel()
            if not IsValid(vm) then continue end
            if vm:GetSequence() ~= data.seq then
                vm:ResetSequence(data.seq)
            end
            local dur     = vm:SequenceDuration(data.seq)
            local elapsed = CurTime() - data.startTime
            -- Defensive only -- net messages are reliable, so the server
            -- should always send an explicit "stop" (see the three call
            -- sites in this file), but expire client-side too well past
            -- the real duration so a missed message can't leave this
            -- forcing a sequence forever.
            if dur and dur > 0 and elapsed > dur + 1 then
                _G.KC_ReloadNetState[pl] = nil
                continue
            end
            local cyc = (dur and dur > 0) and math.Clamp(elapsed / dur, 0, 1) or 0
            vm:SetCycle(cyc)
            vm:SetPlaybackRate(1)
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
        -- Confirmed by testing: disabling the Lerp entirely fixes the
        -- weird camera swing during a NAC (a shotgun reload cancelled
        -- into a weapon switch) but makes normal trickshot camera motion
        -- look choppy -- the Lerp itself is wanted, it just needs to get
        -- out of the way specifically during a weapon switch. Detect a
        -- real weapon-class change in the RECORDED data (same signal
        -- "weapon"'s own edge detection above already uses) and snap
        -- straight to the recorded angle for a short window starting
        -- there, instead of just the one tick the switch happens on --
        -- the switch's own view movement can span a few ticks, and
        -- letting Lerp resume partway through it would reintroduce the
        -- same visible swing.
        local recorder = pl.KC_Recorder
        local tick = KC_ServerTick and KC_ServerTick()
        if recorder and tick and tick > 1 then
            local prevFrame = recorder.replay_frames[tick - 1]
            local curFrame  = recorder.replay_frames[tick]
            local prevWeapon = prevFrame and prevFrame.weapon
            local curWeapon  = curFrame and curFrame.weapon
            if prevWeapon and curWeapon and prevWeapon[1] ~= curWeapon[1] then
                recorder.KC_AngleSnapUntil = CurTime() + 0.3
            end
        end
        local snapping = recorder and recorder.KC_AngleSnapUntil and CurTime() < recorder.KC_AngleSnapUntil

        if pl.KILLCAM_StartDataInitiated and not snapping then
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
                            --
                            -- 12th attempt: 5th attempt called the weapon's
                            -- own Reload() here, on the theory that it
                            -- would handle whatever sound/animation/state
                            -- TFA Base needs internally. That call is almost
                            -- certainly what caused the 11th attempt's
                            -- symptom to REVERSE instead of resolve: the
                            -- pre-kill reload (which had several seconds to
                            -- breathe before the kill) lost the sequence
                            -- fight again, while the kill reload (killcam
                            -- ended almost immediately after) didn't --
                            -- exactly the pattern you'd see if Reload()
                            -- schedules TFA Base's own internal reload
                            -- completion on a timer (independent of
                            -- Think(), so suppressing Think() above never
                            -- touched it) that fires a couple seconds
                            -- later and stomps the sequence/clip once the
                            -- REAL reload "finishes" server-side. We
                            -- already manually drive the sequence, cycle,
                            -- and clip ourselves below for the whole grace
                            -- window -- TFA Base's own reload lifecycle
                            -- was never actually needed and is now removed
                            -- entirely so there's nothing left to fire late.
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
                                    -- 10th attempt: a ONE-TIME ResetSequence
                                    -- call wasn't enough -- confirmed the
                                    -- sequence still flips to "fire" right
                                    -- after even with shot-detection fully
                                    -- blocked during this same window (9th
                                    -- attempt), proving something OTHER
                                    -- than our own DoAttackEvent() call was
                                    -- reverting it -- almost certainly TFA
                                    -- Base's own per-tick weapon logic
                                    -- recalculating "the correct sequence"
                                    -- from internal state we never set.
                                    -- Remember the target sequence so the
                                    -- clip-hold block below can keep
                                    -- RE-FORCING it every tick for the
                                    -- whole grace window instead of once.
                                    recorder.KC_ReloadVMSeq       = seq
                                    recorder.KC_ReloadSeqDuration = vm:SequenceDuration(seq)
                                    -- No timer -- the reload display stays
                                    -- active until it either finishes
                                    -- playing its own real duration or a
                                    -- genuine shot cancels it (see below),
                                    -- same as it would for real gunplay.
                                    recorder.KC_ReloadActive = true
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
                            recorder.KC_ReloadStartTime = CurTime()
                            -- 14th attempt: broadcast this explicitly
                            -- (see top-of-file comment) instead of relying
                            -- solely on the viewmodel entity's own
                            -- networked sequence reaching every client.
                            if recorder.KC_ReloadActive then
                                KC_BroadcastReloadState(pl, true, recorder.KC_ReloadVMSeq, recorder.KC_ReloadStartTime)
                            end
                            -- 11th attempt: suppress the weapon's own
                            -- Think() while a reload display is active, so
                            -- nothing else recalculates "the correct
                            -- sequence" out from under our own forcing.
                            -- The 13th attempt (sv_main.lua stripping real
                            -- attack/reload input server-side before
                            -- replaying it) turned out to be the actual
                            -- fix for the sequence fight, so this may not
                            -- even be load-bearing anymore, but it's cheap
                            -- and harmless to keep as a second layer.
                            -- Restored once the reload display ends (see
                            -- below), not on any fixed timer.
                            if isfunction(wep.Think) and not recorder.KC_ReloadOrigThink then
                                recorder.KC_ReloadOrigThink = wep.Think
                                recorder.KC_ReloadThinkWep  = wep
                                wep.Think = function() end
                            end
                            print("[KC Reload] FIRED (IN_RELOAD edge) for " .. pl:Nick() .. " weapon=" .. tostring(weptbl[1]))
                        end
                        -- Keep re-forcing the reload sequence EVERY TICK
                        -- while a reload display is active -- no fixed
                        -- timer. It ends itself two ways: naturally, once
                        -- elapsed time reaches the sequence's own real
                        -- duration (it finished playing), or early, the
                        -- instant a genuine shot is detected below (a real
                        -- shot legitimately cancels an in-progress reload,
                        -- same as it would for a real player -- and a
                        -- later reload press still starts a fresh one
                        -- normally).
                        if recorder.KC_ReloadActive and recorder.KC_ReloadVMSeq then
                            local vmForce = pl:GetViewModel()
                            if IsValid(vmForce) then
                                local dur = recorder.KC_ReloadSeqDuration
                                local elapsed = CurTime() - (recorder.KC_ReloadStartTime or CurTime())
                                local cyc = (dur and dur > 0) and math.Clamp(elapsed / dur, 0, 1) or 0
                                if vmForce:GetSequence() ~= recorder.KC_ReloadVMSeq then
                                    -- DIAGNOSTIC: proves something else is
                                    -- still actively overwriting the
                                    -- sequence while the reload is active
                                    -- (a real ongoing fight), as opposed to
                                    -- it finishing naturally or the replay
                                    -- running out of frames (see
                                    -- Killcam.StopPlaying's own diagnostic
                                    -- for that case).
                                    print("[KC Reload VM DEBUG] mid-reload sequence was " .. tostring(vmForce:GetSequence()) ..
                                        " (" .. tostring(vmForce:GetSequenceName(vmForce:GetSequence())) ..
                                        "), forcing back to " .. tostring(recorder.KC_ReloadVMSeq) ..
                                        " (" .. tostring(vmForce:GetSequenceName(recorder.KC_ReloadVMSeq)) .. ")")
                                    vmForce:ResetSequence(recorder.KC_ReloadVMSeq)
                                end
                                vmForce:SetCycle(cyc)
                                vmForce:SetPlaybackRate(1)
                                if dur and dur > 0 and elapsed >= dur then
                                    -- Finished playing naturally -- stop
                                    -- holding it, real clip/sequence data
                                    -- resumes on its own from here.
                                    recorder.KC_ReloadActive = false
                                    KC_BroadcastReloadState(pl, false)
                                end
                            end
                        end
                        if not recorder.KC_ReloadActive and recorder.KC_ReloadOrigThink and IsValid(recorder.KC_ReloadThinkWep) then
                            -- Reload display ended (naturally or cancelled
                            -- by a shot) -- restore the weapon's real
                            -- Think() so normal weapon logic resumes.
                            recorder.KC_ReloadThinkWep.Think = recorder.KC_ReloadOrigThink
                            recorder.KC_ReloadOrigThink = nil
                            recorder.KC_ReloadThinkWep  = nil
                        end
                        local isAttacking = curButtons and bit.band(curButtons, IN_ATTACK) ~= 0
                        -- Noisy Clip1() recording (the same source noise
                        -- that made reload fire 3x for 2 real reloads --
                        -- see above) also double-counts shots: a bounce
                        -- like 4->5->4 recorded across consecutive ticks
                        -- reads as TWO decreases for one real trigger
                        -- pull, firing DoAttackEvent()/ForceGunSoundAuto
                        -- twice and visibly "double firing" for the
                        -- spectator. Track the lowest clip value we've
                        -- already fired for and require a genuinely NEW,
                        -- lower value before firing again -- a bounce back
                        -- up to the old value then down again no longer
                        -- re-triggers. Reset the tracker whenever the clip
                        -- goes back up (a real reload finishing), so the
                        -- next real shot after a reload still counts.
                        if weptbl[2] > prevWeapon[2] then
                            recorder.KC_LastFiredClip = nil
                        end
                        -- A live host log caught a reload getting
                        -- cancelled after existing for exactly "0.00s" --
                        -- the reload edge and a detected "shot" landed a
                        -- single tick apart, right at the kill. The kill
                        -- shot's own clip decrease never updates
                        -- KC_LastFiredClip (it fires through the separate,
                        -- unconditional "shot" data type below, which has
                        -- no reason to touch it), so ordinary post-kill
                        -- clip-recording noise -- the exact same jitter
                        -- already proven to misfire reload detection 3x
                        -- for 2 real reloads -- reads as a brand new real
                        -- shot and wipes out a reload before it existed
                        -- for even one visible tick. A real player cannot
                        -- physically fire within a couple ticks of
                        -- pressing reload, so while a reload is freshly
                        -- active, require a tiny minimum age before
                        -- treating a detected clip-decrease as a real
                        -- shot at all -- this is a noise filter, not a
                        -- display-length timer: it never blocks a genuine
                        -- shot landing any meaningful time after the
                        -- reload started, only the same-instant recording
                        -- jitter right at the reload's own trigger tick.
                        local reloadTooFresh = recorder.KC_ReloadActive
                            and (CurTime() - (recorder.KC_ReloadStartTime or 0)) <= 0.1
                        if reloadTooFresh then
                            print("[KC Reload] IGNORED a clip-decrease " ..
                                string.format("%.3f", CurTime() - (recorder.KC_ReloadStartTime or 0)) ..
                                "s into an active reload for " .. pl:Nick() ..
                                " -- too close to the reload's own start to be a real shot, treating as recording noise")
                        end
                        if not reloadTooFresh and weptbl[2] < prevWeapon[2] and isAttacking
                            and (not recorder.KC_LastFiredClip or weptbl[2] < recorder.KC_LastFiredClip) then
                            recorder.KC_LastFiredClip = weptbl[2]
                            -- A real shot cancels any in-progress reload
                            -- display, the same as it would for a real
                            -- player -- release the clip hold and let the
                            -- fire animation take over uncontested. A
                            -- later reload press still starts a brand new
                            -- reload display normally.
                            if recorder.KC_ReloadActive then
                                -- DIAGNOSTIC: distinguishes a legitimate
                                -- cancel (a real recorded shot landed while
                                -- a reload was displaying, correct per
                                -- design) from a still-buggy premature cut
                                -- -- if this NEVER prints for a reload that
                                -- still looked instantly cancelled, nothing
                                -- here is what's cutting it short.
                                print("[KC Reload] shot cancelled in-progress reload for " .. pl:Nick() ..
                                    " at tick=" .. tostring(tick) .. " (was " ..
                                    string.format("%.2f", CurTime() - (recorder.KC_ReloadStartTime or CurTime())) ..
                                    "s into the reload)")
                                KC_BroadcastReloadState(pl, false)
                            end
                            recorder.KC_ReloadActive = false
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
                            -- The kill frame gets its OWN unconditional
                            -- DoAttackEvent()+ForceGunSoundAuto() call from
                            -- the "shot" data type below (runs every kill).
                            -- This comment already said to skip both here
                            -- on the kill frame, but
                            -- the code only ever skipped DoAttackEvent() --
                            -- ForceGunSoundAuto() ran unconditionally right
                            -- after, so every kill played the gunshot sound
                            -- twice. Skip both together.
                            local frame = recorder:GetFrame(tick)
                            if not (frame and frame.kill) then
                                pl:DoAttackEvent()
                                -- DoAttackEvent() triggers TFA Base's own
                                -- recoil kick (ViewPunch) on the killer's
                                -- real eye angles -- a live disturbance our
                                -- "angle" Lerp above has no idea happened,
                                -- so it fights to slowly recover FROM that
                                -- kicked angle back toward the pre-recorded
                                -- target, instead of the shot's normal
                                -- snappy recoil recovery. Snap for a brief
                                -- window after every shot, not just weapon
                                -- switches, so the Lerp doesn't inherit it.
                                recorder.KC_AngleSnapUntil = CurTime() + 0.3
                                ForceGunSoundAuto(wep)
                            end
                        end
                    end
                end

                if recorder and recorder.KC_ReloadActive then
                    -- Reload display still active -- keep showing the
                    -- pre-reload (low/empty) clip instead of the recorded
                    -- value, so the reload animation has time to actually
                    -- play before the clip visibly refills. See the
                    -- reload-trigger block above.
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
            -- The kill shot cancels an in-progress reload display just
            -- like any other shot ("weapon"'s own shot detection above
            -- already does this) -- without clearing KC_ReloadActive
            -- here too, a reload still playing at the exact kill tick
            -- left the flag set after this fired the kill's own fire
            -- animation, so the very next tick's per-tick reassertion
            -- (which only looks at KC_ReloadActive, not at whether a
            -- kill just happened) snapped the sequence straight back to
            -- "reload" -- making the pre-kill reload look like it never
            -- got cancelled, and confusing it with any genuinely new
            -- reload trigger shortly after.
            local recorder = pl.KC_Recorder
            if recorder and recorder.KC_ReloadActive then
                recorder.KC_ReloadActive = false
                KC_BroadcastReloadState(pl, false)
            end
            pl:DoAttackEvent()
            -- Same recoil-kick concern as "weapon"'s own DoAttackEvent()
            -- call above -- snap the camera through the kill shot's kick
            -- instead of letting the "angle" Lerp fight to recover from it.
            if recorder then
                recorder.KC_AngleSnapUntil = CurTime() + 0.3
            end
            ForceGunSoundAuto(pl:GetActiveWeapon())
        end
    end,
})