--[[
    Killcam archive -- server recorder.

    Every server tick, a snapshot of every animated thing in the match is
    written into a ring buffer: players (humans and bots), NPCs, nextbots
    and projectiles/scripted entities. Alongside it, the archive logs what
    happened: every bullet with its real start/impact point, every sound
    an archived entity made, every hit, every death (with the force that
    caused it) and server-side effects.

    Nothing here changes the game -- it only watches. The killcam is cut
    out of this archive afterwards (see sv_main.lua).
]]

local A = Killcam.Archive

-- Sample layout (array indices) -----------------------------------------
local S_FLAGS, S_X, S_Y, S_Z = 1, 2, 3, 4
local S_EP, S_EY             = 5, 6        -- eye angles
local S_RP, S_RY, S_RR       = 7, 8, 9     -- render (body) angles
local S_SEQ, S_CYC           = 10, 11
local S_WMODEL               = 12          -- active weapon world model (string)
local S_CLIP                 = 13          -- active weapon clip, -1 if none
local S_MODEL                = 14          -- entity model (string)
local S_VH                   = 15          -- eye height above origin
local S_VMMODEL, S_VMSEQ, S_VMCYC = 16, 17, 18   -- server viewmodel (players)
local S_WCLASS               = 19          -- active weapon class (string)
local S_VMANIMT, S_VMRATE     = 20, 21      -- server viewmodel: when its sequence started, rate
local S_POSE0                = 22          -- first pose parameter
local NPOSES                 = #A.POSES

A.S = {
    FLAGS = S_FLAGS, X = S_X, Y = S_Y, Z = S_Z, EP = S_EP, EY = S_EY,
    RP = S_RP, RY = S_RY, RR = S_RR, SEQ = S_SEQ, CYC = S_CYC,
    WMODEL = S_WMODEL, CLIP = S_CLIP, MODEL = S_MODEL, VH = S_VH,
    VMMODEL = S_VMMODEL, VMSEQ = S_VMSEQ, VMCYC = S_VMCYC, WCLASS = S_WCLASS,
    VMANIMT = S_VMANIMT, VMRATE = S_VMRATE, POSE0 = S_POSE0,
}

-- Archive state ---------------------------------------------------------
A.Ring      = A.Ring or {}      -- [slot] = { t = time, e = { [key] = sample } }
A.RingHead  = A.RingHead or 0
A.RingSize  = 0
A.Meta      = A.Meta or {}      -- [key] = static info about an archived entity
A.Events    = A.Events or {}    -- chronological list of { t, kind, ... }
A.Kills     = A.Kills or {}     -- chronological list of kill markers
A.Tracked   = A.Tracked or {}   -- non-player entities being archived

local function RingCapacity()
    return math.ceil(A.cv_buffer:GetFloat() / engine.TickInterval()) + 16
end

-- Stable identity for an entity for its whole lifetime (entity indices get
-- reused when bots are kicked/re-added, creation IDs never are).
local function Key(ent)
    return ent:GetCreationID()
end
A.Key = Key

-- Pose parameter read-back units --------------------------------------------
-- Source's server CBaseAnimating::GetPoseParameter returns the value in the
-- parameter's own range, but this is verified at runtime once (and
-- converted if this build reports normalised 0..1 values instead), so the
-- replay always receives real units.
local POSE_NORMALISED = false
local function DetectPoseUnits()
    local ok = pcall(function()
        local probe = ents.Create("prop_dynamic")
        if not IsValid(probe) then return end
        probe:SetModel("models/player/kleiner.mdl")
        probe:Spawn()
        local id = probe:LookupPoseParameter("aim_pitch")
        if id and id >= 0 then
            local lo, hi = probe:GetPoseParameterRange(id)
            local want = (lo + hi) * 0.5 + (hi - lo) * 0.25
            probe:SetPoseParameter("aim_pitch", want)
            local got = probe:GetPoseParameter("aim_pitch")
            if math.abs(got - want) > 0.5 and got >= 0 and got <= 1 then
                POSE_NORMALISED = true
            end
            A.Debug("pose units probe: wanted " .. want .. " got " .. got .. " normalised=" .. tostring(POSE_NORMALISED))
        end
        probe:Remove()
    end)
    if not ok then POSE_NORMALISED = false end
end
hook.Add("InitPostEntity", "KC_Archive_PoseProbe", DetectPoseUnits)

local poseIdCache = {}  -- [model][name] = id or false
local function ReadPose(ent, name, model)
    local cache = poseIdCache[model]
    if not cache then
        cache = {}
        poseIdCache[model] = cache
    end
    local id = cache[name]
    if id == nil then
        id = ent:LookupPoseParameter(name)
        if not id or id < 0 then id = false end
        cache[name] = id
    end
    if not id then return 0 end
    local v = ent:GetPoseParameter(name)
    if POSE_NORMALISED then
        local lo, hi = ent:GetPoseParameterRange(id)
        if lo and hi then v = lo + v * (hi - lo) end
    end
    return v
end

-- Which non-player entities get archived ---------------------------------
local PROJECTILE_CLASSES = {
    npc_grenade_frag = true, grenade_ar2 = true, rpg_missile = true,
    crossbow_bolt = true, prop_combine_ball = true, npc_satchel = true,
    npc_tripmine = true, grenade_helicopter = true, npc_grenade_bugbait = true,
}

local function ShouldTrack(ent)
    if not IsValid(ent) or ent:IsPlayer() or ent:IsWeapon() then return false end
    -- Scripted entities can opt out. The map collision fix (coll_mesh) spawns hundreds of invisible
    -- ones; archiving them every tick made ~20 MB/s of garbage and long GC freezes on turbine.
    if ent.KC_NoArchive then return false end
    if ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) then return true end
    local class = ent:GetClass()
    -- Hands / viewmodels / anything parented follow another entity and are
    -- not things the killcam should draw on their own.
    if class == "gmod_hands" or class == "viewmodel" or class == "predicted_viewmodel" then return false end
    if IsValid(ent:GetParent()) then return false end
    if PROJECTILE_CLASSES[class] then return true end
    -- Thrown knives, claymores, smoke grenades, etc. from this addon and
    -- every other scripted-entity weapon pack.
    if ent:IsScripted() and ent:GetModel() and ent:GetModel() ~= "" then return true end
    return false
end

hook.Add("OnEntityCreated", "KC_Archive_Track", function(ent)
    -- Class/model aren't always final on the creation tick.
    timer.Simple(0, function()
        if ShouldTrack(ent) then A.Tracked[ent] = true end
    end)
end)

hook.Add("EntityRemoved", "KC_Archive_Untrack", function(ent)
    A.Tracked[ent] = nil
end)

-- Catch anything that existed before this file loaded (map NPCs, a Lua
-- refresh mid-match).
local function SweepTracked()
    for _, ent in ipairs(ents.GetAll()) do
        if not A.Tracked[ent] and ShouldTrack(ent) then A.Tracked[ent] = true end
    end
end
hook.Add("InitPostEntity", "KC_Archive_Sweep", SweepTracked)
timer.Create("KC_Archive_Sweep", 5, 0, SweepTracked)

-- Static info about an entity, refreshed whenever it's sampled -----------
local function Kind(ent)
    if ent:IsPlayer() then return 1 end
    if ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) then return 2 end
    return 3
end

local function TouchMeta(ent, key, now)
    local m = A.Meta[key]
    if not m then
        m = { kind = Kind(ent), class = ent:GetClass(), index = ent:EntIndex() }
        if ent:IsPlayer() then
            m.isBot = ent:IsBot()
            m.name  = ent:Nick()
        end
        A.Meta[key] = m
    end
    m.last = now
    m.ent  = ent
    return m
end

-- Snapshot ------------------------------------------------------------------
local vector_zero = Vector(0, 0, 0)

-- Is this (alive) bot hidden from the match right now?
-- Sesh S&D keeps respawned bots NoDraw + frozen until the round countdown
-- ends (KC_PendingRoundStart); those mustn't be drawn in a killcam that
-- reaches back into that period. The round-ending kill ALSO hides every
-- bot (the live game freezes behind the scoreboard) -- that's not an
-- absence, so the killcam keeps showing them where they stood. Reading
-- plain NoDraw made every bot vanish from the replay at the final kill.
local function BotHidden(ent)
    if ent.KC_PendingRoundStart then return true end
    return ent:GetNoDraw() and not _G.SeshBot_KillcamTriggered
end

-- A freshly spawned bot sits in its bind pose until its first animation
-- update, and its animation is only remembered while it's on screen.
hook.Add("PlayerSpawn", "KC_Archive_ForgetAnim", function(ply)
    ply.KC_ArcSeq, ply.KC_ArcCyc = nil, nil
end)

local function WriteSample(s, ent, isPlayer)
    local pos = ent:GetPos()
    local flags = A.F_PRESENT
    local alive
    local seq, cyc = ent:GetSequence() or 0, ent:GetCycle() or 0
    if isPlayer then
        alive = ent:Alive() and ent:GetObserverMode() == OBS_MODE_NONE
        if ent:IsBot() then
            if alive and BotHidden(ent) then alive = false end
            -- Sequence 0 is the bind pose (T-pose): a bot shows it for the
            -- first tick(s) after Spawn(), before its first animation
            -- update -- skip those. A bot that was already on screen and
            -- drops to it (frozen / stripped at match end) keeps its last
            -- real animation instead of vanishing from the replay.
            if alive and seq == 0 then
                if ent.KC_ArcSeq then
                    seq, cyc = ent.KC_ArcSeq, ent.KC_ArcCyc
                else
                    alive = false
                end
            end
            if alive then
                ent.KC_ArcSeq, ent.KC_ArcCyc = seq, cyc
            else
                ent.KC_ArcSeq, ent.KC_ArcCyc = nil, nil
            end
        end
        if ent:Crouching() then flags = flags + A.F_CROUCH end
    elseif ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) then
        alive = ent:Health() > 0
    else
        -- Projectiles / scripted entities: only drawn if they were visible.
        alive = not ent:GetNoDraw() and ent:GetColor().a > 0
    end
    if alive then flags = flags + A.F_ALIVE end
    if ent:IsOnGround() then flags = flags + A.F_GROUND end

    s[S_FLAGS] = flags
    s[S_X], s[S_Y], s[S_Z] = pos.x, pos.y, pos.z

    local eye = ent:EyeAngles()
    s[S_EP], s[S_EY] = eye.p, eye.y
    local ang = ent:GetAngles()
    s[S_RP], s[S_RY], s[S_RR] = ang.p, ang.y, ang.r

    s[S_SEQ] = seq
    s[S_CYC] = cyc

    local model = ent:GetModel() or ""
    s[S_MODEL] = model

    local wep = (isPlayer or ent:IsNPC()) and ent:GetActiveWeapon() or nil
    if IsValid(wep) then
        s[S_WMODEL] = wep:GetModel() or ""
        s[S_WCLASS] = wep:GetClass()
        s[S_CLIP]   = wep:Clip1() or -1
    else
        s[S_WMODEL] = ""
        s[S_WCLASS] = ""
        s[S_CLIP]   = -1
    end

    if isPlayer then
        s[S_VH] = ent:EyePos().z - pos.z
        local vm = ent:GetViewModel(0)
        if IsValid(vm) then
            local seq = vm:GetSequence() or 0
            s[S_VMMODEL] = vm:GetModel() or ""
            s[S_VMSEQ]   = seq
            s[S_VMCYC]   = vm:GetCycle() or 0
            -- The server never advances a viewmodel's cycle itself (clients
            -- animate it from the time the sequence was started), so keep
            -- that start time and rate: the replay derives the frame from
            -- them when it has to show a view from server data (bots).
            local animT = vm.GetAnimTime and vm:GetAnimTime() or 0
            if animT <= 0 then
                if ent.KC_ArcVMSeq ~= seq then
                    ent.KC_ArcVMSeq = seq
                    ent.KC_ArcVMStart = CurTime()
                end
                animT = ent.KC_ArcVMStart or CurTime()
            end
            s[S_VMANIMT] = animT
            s[S_VMRATE]  = vm:GetPlaybackRate() or 1
        else
            s[S_VMMODEL], s[S_VMSEQ], s[S_VMCYC] = "", 0, 0
            s[S_VMANIMT], s[S_VMRATE] = 0, 1
        end
    else
        -- NPCs: eye height so the replay can look through their eyes.
        s[S_VH] = (ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot())) and (ent:EyePos().z - pos.z) or 0
        s[S_VMMODEL], s[S_VMSEQ], s[S_VMCYC] = "", 0, 0
        s[S_VMANIMT], s[S_VMRATE] = 0, 1
    end

    if model ~= "" then
        for i = 1, NPOSES do
            s[S_POSE0 + i - 1] = ReadPose(ent, A.POSES[i], model)
        end
    else
        for i = 1, NPOSES do s[S_POSE0 + i - 1] = 0 end
    end
end

local lastTrim = 0

local function Snapshot()
    local cap = RingCapacity()
    A.RingSize = cap
    local now = CurTime()

    local head = A.RingHead % cap + 1
    A.RingHead = head
    local prev = A.Ring[head]
    local frame = { t = now, e = {} }
    A.Ring[head] = frame
    local reuse = prev and prev.e or nil

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local key = Key(ply)
            TouchMeta(ply, key, now)
            local s = reuse and reuse[key] or {}
            WriteSample(s, ply, true)
            frame.e[key] = s
        end
    end

    for ent in pairs(A.Tracked) do
        if IsValid(ent) then
            local key = Key(ent)
            TouchMeta(ent, key, now)
            local s = reuse and reuse[key] or {}
            WriteSample(s, ent, false)
            frame.e[key] = s
        else
            A.Tracked[ent] = nil
        end
    end

    -- Once a second, drop events/kills/meta that fell out of the window.
    if now - lastTrim > 1 then
        lastTrim = now
        local cutoff = now - A.cv_buffer:GetFloat() - 1
        local function trim(list)
            local first = 1
            while list[first] and list[first].t < cutoff do first = first + 1 end
            if first > 1 then
                local n = #list
                for i = first, n do list[i - first + 1] = list[i] end
                for i = n - first + 2, n do list[i] = nil end
            end
        end
        trim(A.Events)
        trim(A.Kills)
        for key, m in pairs(A.Meta) do
            if (m.last or 0) < cutoff then A.Meta[key] = nil end
        end
    end
end

hook.Add("Tick", "KC_Archive_Snapshot", Snapshot)

-- Returns archived frames with t in [t0, t1], oldest first.
function A.FramesBetween(t0, t1)
    local out = {}
    local cap = A.RingSize
    if cap <= 0 then return out end
    local head = A.RingHead
    for i = 1, cap do
        local slot = (head + i - 1) % cap + 1   -- oldest first
        local f = A.Ring[slot]
        if f and f.t >= t0 and f.t <= t1 then
            out[#out + 1] = f
        end
    end
    table.sort(out, function(a, b) return a.t < b.t end)
    return out
end

-- Events --------------------------------------------------------------------
local function Push(ev)
    A.Events[#A.Events + 1] = ev
end
A.PushEvent = Push

local function OwnerOf(ent)
    if not IsValid(ent) then return nil end
    if ent:IsWeapon() then
        local o = ent:GetOwner()
        if IsValid(o) then return o end
    end
    return ent
end

local function KeyOrZero(ent)
    if IsValid(ent) then return Key(ent) end
    return 0
end

-- Bullets: one event per bullet, with the real trace the server used.
hook.Add("PostEntityFireBullets", "KC_Archive_Bullets", function(ent, data)
    local shooter = OwnerOf(ent)
    if not IsValid(shooter) then return end
    local tr = data and data.Trace
    if not tr then return end
    local hitEnt = tr.Entity
    local now = CurTime()
    local skey = Key(shooter)
    -- First bullet of a volley (a shotgun's pellets arrive together)
    -- drives the muzzle flash.
    local volley = not (A._lastShotKey == skey and A._lastShotT == now)
    A._lastShotKey, A._lastShotT = skey, now
    Push({
        t = now, k = "b", s = skey,
        a = tr.StartPos, b = tr.HitPos, n = tr.HitNormal,
        sp = tr.SurfaceProps or 0, mt = tr.MatType or 0,
        hw = tr.HitWorld and 1 or 0, hs = tr.HitSky and 1 or 0,
        he = (IsValid(hitEnt) and not hitEnt:IsWorld()) and Key(hitEnt) or 0,
        hb = tr.HitBox or 0,
        tr = (data.Tracer or 1) > 0 and 1 or 0,
        tn = data.TracerName or "",
        v = volley and 1 or 0,
    })
end)

-- Sounds made by (or on) archived entities, plus positional world sounds.
hook.Add("EntityEmitSound", "KC_Archive_Sounds", function(data)
    local ent = data.Entity
    local owner = OwnerOf(ent)
    local key = 0
    if IsValid(owner) and not owner:IsWorld() then
        if owner:IsPlayer() or A.Tracked[owner] then
            key = Key(owner)
        else
            return
        end
    elseif not data.Pos then
        return
    end
    Push({
        t = CurTime(), k = "s", e = key,
        n = data.SoundName or data.OriginalSoundName or "",
        o = data.OriginalSoundName,
        v = data.Volume or 1, l = data.SoundLevel or 75, p = data.Pitch or 100,
        c = data.Channel or CHAN_AUTO,
        pos = (key == 0) and data.Pos or nil,
        w = IsValid(ent) and ent:IsWeapon() and 1 or 0,
    })
end)

-- Hits (for hitmarkers) and the last damage each entity took (for the
-- direction its ragdoll should be thrown).
hook.Add("PostEntityTakeDamage", "KC_Archive_Damage", function(target, dmg, took)
    if not took or not IsValid(target) then return end
    local atk = OwnerOf(dmg:GetAttacker())
    target.KC_ArcLastDmg = {
        t = CurTime(),
        f = dmg:GetDamageForce(),
        p = dmg:GetDamagePosition(),
        bullet = dmg:IsBulletDamage(),
    }
    if not IsValid(atk) or atk == target then return end
    if not (target:IsPlayer() or target:IsNPC() or (target.IsNextBot and target:IsNextBot())) then return end
    Push({
        t = CurTime(), k = "h",
        a = Key(atk), v = Key(target),
        d = math.floor(dmg:GetDamage() + 0.5),
        x = target:Health() <= 0 and 1 or 0,
    })
end)

local function RecordDeath(victim, attacker)
    if not IsValid(victim) then return end
    local atk = OwnerOf(attacker)
    local ld = victim.KC_ArcLastDmg
    local fresh = ld and (CurTime() - ld.t) < 0.5
    local now = CurTime()
    Push({
        t = now, k = "d",
        v = Key(victim), a = KeyOrZero(atk),
        f = fresh and ld.f or vector_zero,
        p = fresh and ld.p or victim:WorldSpaceCenter(),
        vel = victim:GetVelocity(),
    })
    -- Humans, bots and AI can all be the killer a killcam is shown for.
    local canKill = IsValid(atk) and (atk:IsPlayer() or atk:IsNPC() or (atk.IsNextBot and atk:IsNextBot()))
    if canKill and atk ~= victim then
        A.Kills[#A.Kills + 1] = {
            t = now, attacker = atk, akey = Key(atk),
            victim = victim, vkey = Key(victim),
        }
    end
end

hook.Add("PlayerDeath", "KC_Archive_PlayerDeath", function(victim, inflictor, attacker)
    RecordDeath(victim, attacker)
end)

hook.Add("OnNPCKilled", "KC_Archive_NPCDeath", function(npc, attacker, inflictor)
    RecordDeath(npc, attacker)
end)

-- Silent deaths (KillSilent at round end) are not kills, but the body
-- should still disappear from the replay rather than freeze in place.
hook.Add("PlayerSilentDeath", "KC_Archive_SilentDeath", function(ply)
    Push({ t = CurTime(), k = "q", v = Key(ply) })
end)

-- Server-side effects (explosions, ricochet sparks, ...). util.Effect has no
-- hook, so it's wrapped once. The original is always called unchanged.
if not A.WrappedEffect then
    A.WrappedEffect = true
    local realEffect = util.Effect
    util.Effect = function(name, ed, allowOverride, filter)
        if ed and name then
            local ok = pcall(function()
                local ent = ed:GetEntity()
                local ekey = 0
                if IsValid(ent) and not ent:IsWorld() then
                    local owner = OwnerOf(ent)
                    if IsValid(owner) and (owner:IsPlayer() or A.Tracked[owner]) then
                        ekey = Key(owner)
                    end
                end
                Push({
                    t = CurTime(), k = "e", n = name,
                    o = ed:GetOrigin(), s = ed:GetStart(), nr = ed:GetNormal(),
                    an = ed:GetAngles(), sc = ed:GetScale(), mg = ed:GetMagnitude(),
                    ra = ed:GetRadius(), fl = ed:GetFlags(), cl = ed:GetColor(),
                    at = ed:GetAttachment(), sp = ed:GetSurfaceProp(),
                    dt = ed:GetDamageType(), hb = ed:GetHitBox(),
                    e = ekey, we = (IsValid(ent) and ent:IsWeapon()) and 1 or 0,
                })
            end)
        end
        return realEffect(name, ed, allowOverride, filter)
    end
end

-- Server-side particle systems (ParticleEffect / ParticleEffectAttach).
if not A.WrappedParticles then
    A.WrappedParticles = true
    local realPE = ParticleEffect
    ParticleEffect = function(name, pos, ang, parent, ...)
        pcall(Push, { t = CurTime(), k = "p", n = name, o = pos, an = ang })
        return realPE(name, pos, ang, parent, ...)
    end
end

-- Legacy API kept for sv_ffa_bots.lua: every player is archived already.
function Killcam.RegisterBotForRecording() end
function Killcam.UnregisterBot() end

-- Finds the kill the killcam should show for this killer.
function A.FindKill(killer, preferVictim)
    local best
    for i = #A.Kills, 1, -1 do
        local k = A.Kills[i]
        if k.attacker == killer then
            if IsValid(preferVictim) and k.victim == preferVictim then return k end
            best = best or k
        end
    end
    return best
end
