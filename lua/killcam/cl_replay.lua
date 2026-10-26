--[[
    Killcam -- client playback.

    Plays a recording cut from the archive (see sh_archive.lua for the big
    picture). Everything you see during the killcam is rebuilt from that
    recording on your own machine:

      * the camera is the killer's real first-person view, frame by frame
      * their viewmodel replays the animation, iron-sight position, sway and
        recoil they actually had, with muzzle flashes on their shots
      * every other player / bot / NPC / projectile is drawn where it really
        was, animating the way it really did, holding what it really held
      * bullets fly to where they really hit, sounds play where they were
        made, hitmarkers fire on the real hits, and victims fall as physics
        ragdolls thrown by the real killing blow
      * the scope overlay is the killer's own

    The live entities are only hidden while the replay is on screen.
]]

local A = Killcam.Archive
local R = Killcam.Replay or {}
Killcam.Replay = R

local incoming = {}     -- [id] = { [kind] = { parts = {}, total = n } }
local loaded   = {}     -- [id] = { world = W, pov = P | false | nil, acked = bool }
local scene    = nil    -- the replay currently loading/playing
local own      = setmetatable({}, { __mode = "k" })   -- entities this file created

R.own = own

-- Entities this file created. Marked on the entity itself as well: the
-- engine can hand hooks a different Lua wrapper for the same entity, which
-- a table keyed by entity would miss.
local function MarkOwned(ent)
    own[ent] = true
    ent.KC_ReplayOwned = true
end

local function IsOwned(ent)
    return IsValid(ent) and (own[ent] or ent.KC_ReplayOwned) or false
end

------------------------------------------------------------------------------
--  Small helpers
------------------------------------------------------------------------------
local Unpack = A.Unpack

local function Seek(times, t, hint)
    local n = #times
    if n == 0 then return 1, 1, 0, 1 end
    if t <= times[1] then return 1, math.min(2, n), 0, 1 end
    if t >= times[n] then return n, n, 0, n end
    local i = hint or 1
    if i < 1 then i = 1 end
    if i >= n then i = n - 1 end
    if times[i] > t then
        while i > 1 and times[i] > t do i = i - 1 end
    else
        while i < n - 1 and times[i + 1] <= t do i = i + 1 end
    end
    local a, b = times[i], times[i + 1]
    local f = (b > a) and (t - a) / (b - a) or 0
    return i, i + 1, math.Clamp(f, 0, 1), i
end

local function L(f, a, b) return a + (b - a) * f end

local function LerpCycle(f, c0, c1)
    local d = c1 - c0
    if d < -0.5 then d = d + 1 end
    if d < 0 then return c1 end
    local c = c0 + d * f
    if c >= 1 then c = c - 1 end
    return c
end

-- seq/cycle at fraction f between two samples
local function SeqCycle(f, s0, c0, s1, c1)
    if s0 == s1 then return s0, LerpCycle(f, c0, c1) end
    -- A new sequence began somewhere between the samples.
    return s1, c1 * f
end

local function Str(list, idx)
    if not idx or idx <= 0 then return "" end
    return list[idx] or ""
end

local function V(t) return t and Vector(t[1], t[2], t[3]) or Vector() end

local soundCache = {}
local function ResolveSound(name)
    if not name or name == "" then return nil end
    local cached = soundCache[name]
    if cached ~= nil then return cached or nil end
    local out = name
    if not string.find(name, "[/\\%.]") then
        local props = sound.GetProperties(name)
        if props and props.sound then
            local s = props.sound
            if istable(s) then s = s[1] end
            out = s or name
        end
    end
    soundCache[name] = out
    return out
end

local matCache = {}
local function Mat(name)
    local m = matCache[name]
    if not m then
        m = Material(name)
        matCache[name] = m
    end
    return m
end

------------------------------------------------------------------------------
--  Decoding
------------------------------------------------------------------------------
local function DecodeWorld(W)
    local base = W.base
    local str = W.str or {}
    local wt = Unpack(W.tm, 1000)
    for i = 1, #wt do wt[i] = base + wt[i] end

    local ents = {}
    for _, e in ipairs(W.ents or {}) do
        local o = {
            key = e.k, kind = e.kd, class = Str(str, e.c), index = e.i or 0,
            isBot = e.b == 1, name = e.nm, skin = e.sk or 0, bg = e.bg or "", team = e.tm,
            col = e.col and Vector(e.col[1], e.col[2], e.col[3]) or nil,
            f = Unpack(e.f, 1),
            x = Unpack(e.x, 8), y = Unpack(e.y, 8), z = Unpack(e.z, 8),
            ep = Unpack(e.ep, 20), ey = Unpack(e.ey, 20),
            rp = Unpack(e.rp, 20), ry = Unpack(e.ry, 20), rr = Unpack(e.rr, 20),
            sq = Unpack(e.sq, 1), cy = Unpack(e.cy, 1000),
            md = Unpack(e.md, 1), wm = Unpack(e.wm, 1),
            poses = {},
        }
        for _, p in ipairs(e.po or {}) do
            local name = A.POSES[p[1]]
            if name then o.poses[name] = Unpack(p[2], 100) end
        end
        ents[#ents + 1] = o
    end

    local sp
    if W.sp then
        local s = W.sp
        sp = {
            t = Unpack(s.tm, 1000),
            x = Unpack(s.x, 16), y = Unpack(s.y, 16), z = Unpack(s.z, 16), vh = Unpack(s.vh, 16),
            ep = Unpack(s.ep, 50), ey = Unpack(s.ey, 50),
            vm = Unpack(s.vm, 1), vs = Unpack(s.vs, 1), vc = Unpack(s.vc, 1000),
            wc = Unpack(s.wc, 1), f = Unpack(s.f, 1),
            va = Unpack(s.va, 1000), vr = Unpack(s.vr, 100),
        }
        for i = 1, #sp.t do sp.t[i] = base + sp.t[i] end
    end

    local evs = {}
    for _, ev in ipairs(W.ev or {}) do
        ev.t = base + (ev.t or 0) / 1000
        -- Name fields arrive as string-table indices; vectors (a bullet's
        -- hit normal is also "n", an effect's origin is also "o") stay as-is.
        if isnumber(ev.n) then ev.n = Str(str, ev.n) end
        if isnumber(ev.tn) then ev.tn = Str(str, ev.tn) end
        if isnumber(ev.o) then ev.o = Str(str, ev.o) end
        evs[#evs + 1] = ev
    end

    return {
        W = W, base = base, str = str, wt = wt, ents = ents, sp = sp, ev = evs,
        t0 = W.t0, t1 = W.t1, kt = W.kt, killer = W.killer, victim = W.victim,
        lerp = W.lerp or 0, shift = W.shift or 0, prof = W.prof, hud = W.hud,
        fov = (W.fov and W.fov >= 20 and W.fov <= 170) and W.fov or 75,
    }
end

local function DecodePOV(P)
    if not P or P.empty or not P.tm then return nil end
    local base = P.base
    local str = P.str or {}
    local o = {
        str = str,
        t = Unpack(P.tm, 1000),
        ox = Unpack(P.ox, 16), oy = Unpack(P.oy, 16), oz = Unpack(P.oz, 16),
        ap = Unpack(P.ap, 50), ay = Unpack(P.ay, 50), ar = Unpack(P.ar, 50),
        fov = Unpack(P.fov, 10),
        vd = Unpack(P.vd, 1), vm = Unpack(P.vm, 1),
        lx = Unpack(P.lx, 100), ly = Unpack(P.ly, 100), lz = Unpack(P.lz, 100),
        la = Unpack(P.la, 50), lb = Unpack(P.lb, 50), lc = Unpack(P.lc, 50),
        vs = Unpack(P.vs, 1), vc = Unpack(P.vc, 1000), vk = Unpack(P.vk, 1),
        vb = Unpack(P.vb, 1), vf = Unpack(P.vf, 10),
        hd = Unpack(P.hd, 1), hm = Unpack(P.hm, 1), hk = Unpack(P.hk, 1), hb = Unpack(P.hb, 1),
        ov = Unpack(P.ov, 1), wc = Unpack(P.wc, 1),
        al = Unpack(P.al, 1), sp = Unpack(P.sp, 1), og = Unpack(P.og, 1),
        ev = {}, boneMods = {}, muzzle = {},
    }
    for i = 1, #o.t do o.t[i] = base + o.t[i] end
    for _, ev in ipairs(P.ev or {}) do
        ev.t = base + (ev.t or 0) / 1000
        if ev.n then ev.n = Str(str, ev.n) end
        if ev.o then ev.o = Str(str, ev.o) end
        o.ev[#o.ev + 1] = ev
    end
    for _, bm in ipairs(P.bm or {}) do o.boneMods[Str(str, bm[1])] = bm[2] end
    for _, ma in ipairs(P.ma or {}) do o.muzzle[Str(str, ma[1])] = ma[2] end
    if #o.t < 2 then return nil end
    return o
end

------------------------------------------------------------------------------
--  Timeline + event list
------------------------------------------------------------------------------
-- Measures the offset between the server clock and the killer's recorded
-- frames from their real shots: the server logged when each bullet was
-- processed, the killer's client logged the first frame that showed each
-- shot. Every server/client pairing is tried as a candidate offset and the
-- one that lines up the most shots wins -- matching only the shot nearest a
-- ping estimate could pick the neighbouring shot of an automatic weapon and
-- put every flash, sound and bullet a whole shot out of step with the gun.
-- Falls back to the ping estimate.
local function MeasureShift(sc)
    local est = sc.shift
    if not sc.pov then return est end
    local lo, hi = sc.kt - 2.5, sc.kt + 0.5
    local serverShots = {}
    for _, ev in ipairs(sc.ev) do
        if ev.k == "b" and ev.s == sc.killer and ev.v == 1 and ev.t >= lo and ev.t <= hi then
            serverShots[#serverShots + 1] = ev.t
        end
    end
    local clientShots = {}
    for _, ev in ipairs(sc.pov.ev) do
        if ev.k == "f" and ev.t + est >= lo - 1 and ev.t + est <= hi + 1 then clientShots[#clientShots + 1] = ev.t end
    end
    if #serverShots == 0 or #clientShots == 0 then return est end

    -- Matching tolerance: a shot can land anywhere inside one recorded frame.
    local P = sc.pov.t
    local dts = {}
    for i = 2, #P do dts[#dts + 1] = P[i] - P[i - 1] end
    table.sort(dts)
    local frameDt = dts[math.max(1, math.floor(#dts / 2))] or 0.016
    local tol = math.Clamp(frameDt * 1.5, 0.02, 0.05)

    local function Score(d)
        local n, resid = 0, {}
        for _, s in ipairs(serverShots) do
            local bestR
            for _, c in ipairs(clientShots) do
                local r = s - c - d
                if math.abs(r) <= tol and (not bestR or math.abs(r) < math.abs(bestR)) then bestR = r end
            end
            if bestR then n = n + 1 resid[#resid + 1] = bestR end
        end
        return n, resid
    end

    local best, bestN, bestErr, bestResid
    for _, s in ipairs(serverShots) do
        for _, c in ipairs(clientShots) do
            local d = s - c
            if d >= -0.15 and d <= 1.0 then
                local n, resid = Score(d)
                local err = math.abs(d - est)
                if not bestN or n > bestN or (n == bestN and err < bestErr) then
                    best, bestN, bestErr, bestResid = d, n, err, resid
                end
            end
        end
    end
    if not best then return est end
    -- Refine with the median of the matched shots' residuals.
    table.sort(bestResid)
    local refined = best + (bestResid[math.max(1, math.ceil(#bestResid / 2))] or 0)
    A.Debug(string.format("clock offset measured from %d/%d shots: %.3fs (estimate %.3fs, tolerance %.3fs)",
        bestN, #serverShots, refined, est, tol))
    return refined
end

local function BuildTimeline(sc)
    sc.shift = MeasureShift(sc)
    sc.worldLag = sc.shift + sc.lerp

    local list = {}
    local function add(at, ev, axis)
        list[#list + 1] = { at = at, ev = ev, axis = axis }
    end

    -- Sounds the killer's client heard from its own gun/body.
    local clientSounds = {}
    if sc.pov then
        for _, ev in ipairs(sc.pov.ev) do
            local at = ev.t + sc.shift
            if ev.k == "s" then
                add(at, ev, "pov")
                clientSounds[#clientSounds + 1] = ev
            elseif ev.k == "f" then
                add(at, ev, "pov")
                sc.hasClientFire = true
            end
        end
    end

    for _, ev in ipairs(sc.ev) do
        local mine = (ev.k == "b" and ev.s == sc.killer)
            or (ev.k == "h" and ev.a == sc.killer)
            or (ev.k == "s" and ev.e == sc.killer)
            or (ev.k == "e" and ev.e == sc.killer)
        if mine then
            local skip = false
            if ev.k == "s" and sc.pov then
                for _, cs in ipairs(clientSounds) do
                    if (cs.n == ev.n or (cs.o and cs.o == ev.o)) and math.abs(cs.t + sc.shift - ev.t) < 0.35 then
                        skip = true
                        break
                    end
                end
            end
            if ev.k == "e" and ev.we == 1 then skip = true end   -- weapon muzzle effects: drawn on the viewmodel
            if not skip then add(ev.t, ev, "killer") end
        else
            add(ev.t + sc.worldLag, ev, "world")
        end
    end

    -- Every kill the killer makes on camera gets its hitmarker (and "+XP"),
    -- the final kill above all. Deaths are always logged, but a hit can be
    -- missing from the recording; give such a kill its hitmarker anyway.
    local killHits = {}
    for _, ev in ipairs(sc.ev) do
        if ev.k == "h" and ev.a == sc.killer and ev.x == 1 then killHits[#killHits + 1] = ev end
    end
    local function HasKillHit(victim, t)
        for _, h in ipairs(killHits) do
            if h.v == victim and math.abs(h.t - t) < 0.5 then return true end
        end
        return false
    end
    local function AddKillHit(victim, t)
        local h = { k = "h", t = t, a = sc.killer, v = victim, x = 1 }
        killHits[#killHits + 1] = h
        add(t, h, "killer")
        A.Debug(string.format("  kill at %.3f had no logged hit -- adding its hitmarker", t))
    end
    for _, ev in ipairs(sc.ev) do
        if ev.k == "d" and ev.a == sc.killer and ev.v ~= sc.killer and not HasKillHit(ev.v, ev.t) then
            AddKillHit(ev.v, ev.t)
        end
    end
    if sc.kt and sc.victim and not HasKillHit(sc.victim, sc.kt) then
        AddKillHit(sc.victim, sc.kt)
    end
    if A.cv_debug:GetBool() then
        local n = 0
        for _, item in ipairs(list) do
            if item.ev.k == "h" and item.axis == "killer" then n = n + 1 end
        end
        A.Debug(string.format("killer hits on camera: %d (%d kills)", n, #killHits))
    end

    table.sort(list, function(a, b) return a.at < b.at end)
    sc.events = list
    sc.evCursor = 1
    -- Events from before the window opens don't fire.
    while sc.events[sc.evCursor] and sc.events[sc.evCursor].at < sc.t0 do
        sc.evCursor = sc.evCursor + 1
    end

    sc.map, sc.realLen = A.BuildTimeMap(sc.prof, sc.t0, sc.t1)
end

------------------------------------------------------------------------------
--  Live-entity hiding
------------------------------------------------------------------------------
local hidden = {}
local noDraw = function() end

local function ShouldHide(ent)
    if not IsValid(ent) or IsOwned(ent) then return false end
    if ent:IsPlayer() then return false end -- handled by PrePlayerDraw
    if ent:IsNPC() or ent:IsWeapon() then return true end
    if ent.IsNextBot and ent:IsNextBot() then return true end
    if ent:IsRagdoll() then return true end
    local class = ent:GetClass()
    if class == "prop_ragdoll" or class == "class C_ClientRagdoll" or class == "class C_HL2MPRagdoll" then return true end
    -- Every player (bots included) owns a hands entity and viewmodels; a
    -- bot's ones can show up in the world, so they go too.
    if class == "gmod_hands" or class == "viewmodel" or class == "predicted_viewmodel" then return true end
    if scene and scene.hideIndex and scene.hideIndex[ent:EntIndex()] == class then return true end
    return false
end

local function Hide(ent)
    if hidden[ent] ~= nil then return end
    hidden[ent] = { ro = ent.RenderOverride }
    ent.RenderOverride = noDraw
end

local function HideLive()
    for _, ent in ipairs(ents.GetAll()) do
        if ShouldHide(ent) then Hide(ent) end
    end
    for _, ply in ipairs(player.GetAll()) do
        local rag = ply:GetRagdollEntity()
        if IsValid(rag) then Hide(rag) end
    end
end

local function RestoreLive()
    for ent, data in pairs(hidden) do
        if IsValid(ent) and ent.RenderOverride == noDraw then
            ent.RenderOverride = data.ro
        end
    end
    hidden = {}
end

hook.Add("OnEntityCreated", "KC_Replay_HideNew", function(ent)
    if not scene or scene.state ~= "playing" then return end
    timer.Simple(0, function()
        if scene and scene.state == "playing" and ShouldHide(ent) then Hide(ent) end
    end)
end)

hook.Add("CreateClientsideRagdoll", "KC_Replay_HideRagdolls", function(owner, rag)
    if not scene or scene.state ~= "playing" then return end
    if IsOwned(owner) or IsOwned(rag) then return end
    if IsValid(rag) then Hide(rag) end
end)

hook.Add("PrePlayerDraw", "KC_Replay_HidePlayers", function(ply)
    if scene and scene.state == "playing" then return true end
end)

hook.Add("PreDrawViewModel", "KC_Replay_HideViewModel", function()
    if scene and scene.state == "playing" then return true end
end)

hook.Add("PreDrawPlayerHands", "KC_Replay_HideHands", function()
    if scene and scene.state == "playing" then return true end
end)

-- Our own live weapon's HUD (scope, crosshair) must not draw over the
-- replay -- the killer's recorded one is drawn instead.
hook.Add("HUDShouldDraw", "KC_Replay_HideWeaponHUD", function(name)
    if scene and (name == "CHudWeapon" or name == "CHudCrosshair" or name == "CHudWeaponSelection") then
        return false
    end
end)

------------------------------------------------------------------------------
--  Replay actors (other players, bots, NPCs, projectiles)
------------------------------------------------------------------------------
local function MakeModel(path)
    if not path or path == "" or not string.find(path, "%.mdl$") then return nil end
    local mdl = ClientsideModel(path, RENDERGROUP_OPAQUE)
    if not IsValid(mdl) then return nil end
    MarkOwned(mdl)
    mdl:SetNoDraw(true)
    return mdl
end

local function RemoveActor(a)
    if IsValid(a.wmdl) then a.wmdl:Remove() end
    if IsValid(a.mdl) then a.mdl:Remove() end
    a.wmdl, a.mdl = nil, nil
end

local function SetupModel(a, path)
    if a.modelPath == path and IsValid(a.mdl) then return end
    RemoveActor(a)
    a.modelPath = path
    a.wmodelPath = nil
    local mdl = MakeModel(path)
    if not mdl then return end
    a.mdl = mdl
    local d = a.data
    mdl:SetSkin(d.skin or 0)
    if d.bg and d.bg ~= "" then mdl:SetBodyGroups(d.bg) end
    if d.col then
        local col = d.col
        mdl.GetPlayerColor = function() return col end
    end
    -- Which recorded pose parameters this model actually has.
    a.poseNames = {}
    for name, values in pairs(d.poses) do
        if mdl:LookupPoseParameter(name) >= 0 then a.poseNames[#a.poseNames + 1] = name end
    end
end

local function SetupWeapon(a, path)
    if a.wmodelPath == path then return end
    a.wmodelPath = path
    if IsValid(a.wmdl) then a.wmdl:Remove() end
    a.wmdl = nil
    if not IsValid(a.mdl) then return end
    local w = MakeModel(path)
    if not w then return end
    w:SetParent(a.mdl)
    w:AddEffects(EF_BONEMERGE)
    w:AddEffects(EF_BONEMERGE_FASTCULL)
    a.wmdl = w
end

local function UpdateActor(sc, a, wtime)
    local d = a.data
    local i0, i1, f, hint = Seek(sc.wt, wtime, a.hint)
    a.hint = hint

    local flags = d.f[i0] or 0
    local present = bit.band(flags, A.F_PRESENT) ~= 0
    local alive = bit.band(flags, A.F_ALIVE) ~= 0
    -- Respawn / first appearance: don't slide in from the last position.
    local f1 = d.f[i1] or 0
    if bit.band(f1, A.F_PRESENT) == 0 or bit.band(f1, A.F_ALIVE) == 0 then f = 0 end

    local visible = present and alive and not a.deadNow
    if a.deadNow and alive and a.deathAt and wtime > a.deathAt + 0.5 then
        -- Came back (respawned) inside the window.
        a.deadNow = false
        visible = present
    end

    local path = Str(sc.str, d.md[i0])
    if visible then SetupModel(a, path) end
    local mdl = a.mdl
    if not IsValid(mdl) then return end

    if not visible then
        mdl:SetNoDraw(true)
        if IsValid(a.wmdl) then a.wmdl:SetNoDraw(true) end
        return
    end

    local pos = Vector(L(f, d.x[i0], d.x[i1]), L(f, d.y[i0], d.y[i1]), L(f, d.z[i0], d.z[i1]))
    local ang = Angle(L(f, d.rp[i0], d.rp[i1]), L(f, d.ry[i0], d.ry[i1]), L(f, d.rr[i0], d.rr[i1]))
    if a.data.kind == 1 then ang.p, ang.r = 0, 0 end
    mdl:SetPos(pos)
    mdl:SetAngles(ang)
    a.pos = pos
    a.vel = (Vector(d.x[i1], d.y[i1], d.z[i1]) - Vector(d.x[i0], d.y[i0], d.z[i0])) / math.max((sc.wt[i1] or 0) - (sc.wt[i0] or 0), 0.01)

    local seq, cyc = SeqCycle(f, d.sq[i0], d.cy[i0], d.sq[i1], d.cy[i1])
    if mdl:GetSequence() ~= seq then mdl:SetSequence(seq) end
    mdl:SetCycle(cyc)
    for _, name in ipairs(a.poseNames or {}) do
        local vals = d.poses[name]
        mdl:SetPoseParameter(name, L(f, vals[i0] or 0, vals[i1] or 0))
    end
    mdl:InvalidateBoneCache()
    mdl:SetNoDraw(false)

    if d.kind ~= 3 then
        -- Keep the last gun when weapons get stripped at match end, like
        -- CoD's frozen end-of-game snapshot.
        local wpath = Str(sc.str, d.wm[i0])
        if wpath ~= "" then SetupWeapon(a, wpath) end
        if IsValid(a.wmdl) then a.wmdl:SetNoDraw(false) end
    end
end

-- Muzzle position of an actor's weapon (for tracers / flashes).
local function ActorMuzzle(a)
    local w = a and a.wmdl
    if IsValid(w) then
        w:SetupBones()
        local id = w:LookupAttachment("muzzle")
        if not id or id <= 0 then id = 1 end
        local att = w:GetAttachment(id)
        if att then return att.Pos end
    end
    if a and a.pos then return a.pos + Vector(0, 0, a.data.kind == 1 and 56 or 40) end
    return nil
end

local RAGDOLL_FORCE_MAX = 9000
local DEATH_SEQS = { "death_01", "death_02", "death_03", "death_04" }

-- A model with no ragdoll physics: leave a copy of the body where it died,
-- playing a death animation if the model has one, instead of letting the
-- victim vanish from the replay.
local function LeaveCorpse(sc, a)
    local mdl = a.mdl
    local corpse = MakeModel(mdl:GetModel())
    if not corpse then return end
    sc.ragdolls[#sc.ragdolls + 1] = corpse
    corpse:SetPos(mdl:GetPos())
    corpse:SetAngles(mdl:GetAngles())
    corpse:SetSkin(mdl:GetSkin() or 0)
    if a.data.bg and a.data.bg ~= "" then corpse:SetBodyGroups(a.data.bg) end
    if a.data.col then
        local col = a.data.col
        corpse.GetPlayerColor = function() return col end
    end
    local seq = corpse:LookupSequence(DEATH_SEQS[math.random(#DEATH_SEQS)])
    if not seq or seq <= 0 then
        for _, name in ipairs(DEATH_SEQS) do
            seq = corpse:LookupSequence(name)
            if seq and seq > 0 then break end
        end
    end
    if seq and seq > 0 then
        corpse:SetSequence(seq)
        corpse:SetCycle(0)
        sc.corpses[#sc.corpses + 1] = {
            ent = corpse, start = sc.lastWorldTime or 0,
            dur = math.max(corpse:SequenceDuration(seq) or 1, 0.1),
        }
    else
        -- No death animation either: hold the pose it was shot in.
        corpse:SetSequence(mdl:GetSequence())
        corpse:SetCycle(mdl:GetCycle())
    end
    corpse:SetNoDraw(false)
    corpse:DrawShadow(true)
end

local function Ragdollize(sc, a, ev)
    if a.deadNow then return end
    a.deadNow = true
    a.deathAt = sc.lastWorldTime
    local mdl = a.mdl
    -- The archive can already show the body as dead a tick before the death
    -- event's timestamp (kills are processed inside the shooter's usercmd,
    -- on that player's clock), so the model may have been hidden a frame
    -- early. It still holds the last pose it was shown in -- use that.
    if not IsValid(mdl) or not a.pos then return end

    -- Build the ragdoll in the exact pose the body was in when the shot
    -- landed: every physics bone is placed from the animated model's bones.
    mdl:SetupBones()
    local ok, rag = pcall(ClientsideRagdoll, mdl:GetModel())
    mdl:SetNoDraw(true)
    if IsValid(a.wmdl) then a.wmdl:SetNoDraw(true) end
    A.Debug("  ragdoll ok=" .. tostring(ok) .. " rag=" .. tostring(rag) .. " phys=" .. tostring(ok and IsValid(rag) and rag:GetPhysicsObjectCount()))
    if ok and IsValid(rag) and rag:GetPhysicsObjectCount() == 0 then
        rag:Remove()
        ok = false
    end
    if not ok or not IsValid(rag) then
        LeaveCorpse(sc, a)
        return
    end

    MarkOwned(rag)
    sc.ragdolls[#sc.ragdolls + 1] = rag
    rag:SetSkin(mdl:GetSkin() or 0)
    if a.data.bg and a.data.bg ~= "" then rag:SetBodyGroups(a.data.bg) end
    if a.data.col then
        local col = a.data.col
        rag.GetPlayerColor = function() return col end
    end
    rag:SetNoDraw(false)
    rag:DrawShadow(true)

    local vel = ev.vel and V(ev.vel) or (a.vel or Vector())
    local force = V(ev.f)
    if force:Length() > RAGDOLL_FORCE_MAX then force = force:GetNormalized() * RAGDOLL_FORCE_MAX end
    local hitPos = ev.p and V(ev.p) or nil
    -- Many weapon bases send no damage force at all; push the body away
    -- from whoever shot it so it still reacts to the hit.
    if force:LengthSqr() < 1 then
        local from
        if ev.a == sc.killer and sc.view.origin then
            from = sc.view.origin
        else
            local atk = sc.actorsByKey[ev.a]
            from = atk and atk.pos and atk.pos + Vector(0, 0, 60)
        end
        if from then
            local to = hitPos or (a.pos + Vector(0, 0, 40))
            local dir = to - from
            if dir:LengthSqr() > 1 then force = dir:GetNormalized() * 6000 end
        end
    end

    local nearest, nearestD
    for i = 0, rag:GetPhysicsObjectCount() - 1 do
        local phys = rag:GetPhysicsObjectNum(i)
        local bone = rag:TranslatePhysBoneToBone(i)
        local m = bone and bone >= 0 and mdl:GetBoneMatrix(bone)
        if IsValid(phys) then
            if m then
                phys:SetPos(m:GetTranslation())
                phys:SetAngles(m:GetAngles())
            end
            phys:Wake()
            phys:SetVelocity(vel)
            if hitPos then
                local dd = phys:GetPos():DistToSqr(hitPos)
                if not nearestD or dd < nearestD then nearest, nearestD = phys, dd end
            end
        end
    end
    if IsValid(nearest) and force:LengthSqr() > 1 then
        nearest:ApplyForceOffset(force, hitPos)
    end
    local p0 = rag:GetPhysicsObjectNum(0)
    A.Debug("  ragdoll placed: body at " .. tostring(mdl:GetPos()) .. " root phys at " .. tostring(IsValid(p0) and p0:GetPos())
        .. " nodraw=" .. tostring(rag:GetNoDraw()) .. " override=" .. tostring(rag.RenderOverride ~= nil)
        .. " class=" .. rag:GetClass() .. " force=" .. tostring(force))
end

------------------------------------------------------------------------------
--  The killer's view
------------------------------------------------------------------------------
local vmCache = {}   -- [model] = clientside viewmodel
local handsEnt, handsModelPath

local function GetVM(sc, path)
    if not path or path == "" then return nil end
    local vm = vmCache[path]
    if IsValid(vm) then return vm end
    vm = MakeModel(path)
    if not vm then return nil end
    vmCache[path] = vm
    local mods = sc.pov and sc.pov.boneMods[path]
    if mods then
        for _, m in ipairs(mods) do
            local b = m[1]
            vm:ManipulateBoneScale(b, Vector(m[2], m[3], m[4]))
            vm:ManipulateBonePosition(b, Vector(m[5], m[6], m[7]))
            vm:ManipulateBoneAngles(b, Angle(m[8], m[9], m[10]))
        end
    end
    return vm
end

local function GetHands(path, parent)
    if not path or path == "" then return nil end
    if handsModelPath ~= path or not IsValid(handsEnt) then
        if IsValid(handsEnt) then handsEnt:Remove() end
        handsEnt = MakeModel(path)
        handsModelPath = path
        if not handsEnt then return nil end
        handsEnt:AddEffects(EF_BONEMERGE)
        handsEnt:AddEffects(EF_BONEMERGE_FASTCULL)
    end
    if handsEnt:GetParent() ~= parent then handsEnt:SetParent(parent) end
    return handsEnt
end

local function ClearViewModels()
    for _, vm in pairs(vmCache) do if IsValid(vm) then vm:Remove() end end
    vmCache = {}
    if IsValid(handsEnt) then handsEnt:Remove() end
    handsEnt, handsModelPath = nil, nil
end

-- Hands for a model when only the server's view of the killer exists.
local function FallbackHands(sc)
    if sc.fallbackHands ~= nil then return sc.fallbackHands end
    sc.fallbackHands = false
    local killer = sc.actorsByKey[sc.killer]
    local model = killer and Str(sc.str, killer.data.md[1])
    if model and model ~= "" then
        local name = player_manager.TranslateToPlayerModelName(model)
        local info = name and player_manager.TranslatePlayerHands(name)
        if info and info.model then sc.fallbackHands = info end
    end
    return sc.fallbackHands
end

local function ComputeViewFromPOV(sc, s, view)
    local P = sc.pov
    local c = s - sc.shift
    local i0, i1, f, hint = Seek(P.t, c, sc.povHint)
    sc.povHint = hint
    view.origin = Vector(L(f, P.ox[i0], P.ox[i1]), L(f, P.oy[i0], P.oy[i1]), L(f, P.oz[i0], P.oz[i1]))
    view.angles = Angle(L(f, P.ap[i0], P.ap[i1]), L(f, P.ay[i0], P.ay[i1]), L(f, P.ar[i0], P.ar[i1]))
    view.fov = L(f, P.fov[i0], P.fov[i1])

    local near = f < 0.5 and i0 or i1
    view.vmVisible = P.vd[near] == 1 and P.al[near] == 1
    view.vmPath = Str(P.str, P.vm[near])
    if P.vm[i0] == P.vm[i1] and P.vd[i0] == 1 and P.vd[i1] == 1 then
        view.vmLocalPos = Vector(L(f, P.lx[i0], P.lx[i1]), L(f, P.ly[i0], P.ly[i1]), L(f, P.lz[i0], P.lz[i1]))
        view.vmLocalAng = Angle(L(f, P.la[i0], P.la[i1]), L(f, P.lb[i0], P.lb[i1]), L(f, P.lc[i0], P.lc[i1]))
        view.vmSeq, view.vmCyc = SeqCycle(f, P.vs[i0], P.vc[i0], P.vs[i1], P.vc[i1])
    else
        view.vmLocalPos = Vector(P.lx[near], P.ly[near], P.lz[near])
        view.vmLocalAng = Angle(P.la[near], P.lb[near], P.lc[near])
        view.vmSeq, view.vmCyc = P.vs[near], P.vc[near]
    end
    view.vmSkin = P.vk[near]
    view.vmBG = Str(P.str, P.vb[near])
    view.vmFov = L(f, P.vf[i0], P.vf[i1])
    view.handsVisible = P.hd[near] == 1
    view.handsPath = Str(P.str, P.hm[near])
    view.handsSkin = P.hk[near]
    view.handsBG = Str(P.str, P.hb[near])
    view.weaponClass = Str(P.str, P.wc[near])

    local back = f < 1 and i0 or i1   -- overlay that was on screen at this moment
    view.overlay = P.ov[back]
    view.alive = P.al[near] == 1
    view.speed = L(f, P.sp[i0], P.sp[i1])
    view.onGround = P.og[near] == 1
end

local function ComputeViewFromServer(sc, s, view)
    local sp = sc.sp
    local i0, i1, f, hint = Seek(sp.t, s, sc.spHint)
    sc.spHint = hint
    view.origin = Vector(L(f, sp.x[i0], sp.x[i1]), L(f, sp.y[i0], sp.y[i1]), L(f, sp.z[i0], sp.z[i1]) + L(f, sp.vh[i0], sp.vh[i1]))
    view.angles = Angle(L(f, sp.ep[i0], sp.ep[i1]), L(f, sp.ey[i0], sp.ey[i1]), 0)
    view.fov = sc.fov
    local near = f < 0.5 and i0 or i1
    local flags = sp.f[near] or 0
    view.alive = bit.band(flags, A.F_ALIVE) ~= 0
    view.onGround = bit.band(flags, A.F_GROUND) ~= 0
    view.vmPath = Str(sc.str, sp.vm[near])
    -- Weapons get stripped at match end; keep showing the last gun.
    if view.vmPath == "" and view.alive and sc.lastVmPath then
        view.vmPath = sc.lastVmPath
    elseif view.vmPath ~= "" then
        sc.lastVmPath = view.vmPath
    end
    view.vmVisible = view.alive and view.vmPath ~= ""
    view.vmLocalPos = Vector()
    view.vmLocalAng = Angle()
    view.vmSeq, view.vmCyc = SeqCycle(f, sp.vs[i0], sp.vc[i0], sp.vs[i1], sp.vc[i1])
    -- The server never advances viewmodel cycles; animate from when the
    -- sequence was started instead (done per frame once the model exists).
    local va = sp.va[near]
    view.vmAnimT = (va and va ~= 0) and (sc.base + va) or nil
    view.vmRate = sp.vr[near] or 1
    view.vmTime = s
    view.vmSkin = 0
    view.vmBG = ""
    view.weaponClass = Str(sc.str, sp.wc[near])
    if view.weaponClass == "" and sc.lastWeaponClass then
        view.weaponClass = sc.lastWeaponClass
    elseif view.weaponClass ~= "" then
        sc.lastWeaponClass = view.weaponClass
    end
    local stored = weapons.GetStored(view.weaponClass)
    -- Engine (HL2) weapons use viewmodel_fov 54; Lua weapons say their own.
    view.vmFov = (stored and stored.ViewModelFOV) or 54
    -- c_ models are drawn with the player's hands bonemerged onto them.
    local wantsHands = (stored and stored.UseHands) or string.find(view.vmPath, "/c_", 1, true) ~= nil
    local hands = wantsHands and FallbackHands(sc) or nil
    view.handsVisible = hands ~= nil and hands ~= false
    view.handsPath = hands and hands.model or ""
    view.handsSkin = hands and hands.skin or 0
    view.handsBG = hands and hands.body or ""
    view.overlay = 0
    local dt = math.max(sp.t[i1] - sp.t[i0], 0.01)
    view.speed = Vector(sp.x[i1] - sp.x[i0], sp.y[i1] - sp.y[i0], 0):Length() / dt
end

------------------------------------------------------------------------------
--  Effects, sounds, hitmarkers
------------------------------------------------------------------------------
-- (Material() returns two values; parenthesised so the last entry doesn't
-- spill its load time into the table.)
local MUZZLE_MATS = {
    (Material("effects/muzzleflash1")), (Material("effects/muzzleflash2")),
    (Material("effects/muzzleflash3")), (Material("effects/muzzleflash4")),
}

-- Playback speed the sounds should run at right now (follows the slow-mo
-- all the way down, like CoD's slowed killcam audio).
local function PlayRate(sc)
    return math.Clamp(sc.rate or 1, 0.1, 1)
end

-- Slowed sound --------------------------------------------------------------
-- Engine sounds take one pitch when they start, so a gunshot fired as the
-- slow-mo eases in would keep running at the speed it began with. The
-- killer's sounds and every gunshot are instead played through BASS
-- channels whose playback rate is re-set every frame from the slow-mo rate
-- -- they slow down and speed back up together with the picture. Channels
-- are opened while the recording loads so each one starts on its exact
-- frame; anything that couldn't be opened falls back to a pitched EmitSound.
local SOUND_PREFIX = "^[%*%#%@%>%<%^%)%(%}%$%!%?%&%~%`%+%%]+"

local function SoundFilePath(name)
    local s = ResolveSound(name)
    if not s then return nil end
    s = string.gsub(s, "\\", "/")
    s = string.gsub(s, SOUND_PREFIX, "")
    if not string.find(s, "%.%w+$") then return nil end
    return "sound/" .. s
end

local function PreloadSound(sc, ev, positional)
    local path = SoundFilePath(ev.n) or SoundFilePath(ev.o)
    if not path then return end
    sound.PlayFile(path, positional and "3d noplay noblock" or "noplay noblock", function(ch)
        if not IsValid(ch) then return end
        if sc.released then ch:Stop() return end
        sc.channels[#sc.channels + 1] = ch
        ev.kcChan = ch
    end)
end

local function StartChannel(sc, ev, pos)
    local ch = ev.kcChan
    if not IsValid(ch) or ev.kcStarted then return false end
    ev.kcStarted = true
    local base = math.Clamp((ev.p or 100) / 100, 0.2, 2.5)
    ch:SetVolume(math.Clamp(ev.v or 1, 0, 1))
    if pos then
        ch:SetPos(pos)
        local far = math.Clamp(2 ^ (((ev.l or 75) - 60) / 6) * 100, 400, 20000)
        ch:Set3DFadeDistance(math.min(200, far * 0.25), far)
    end
    ch:SetPlaybackRate(base * PlayRate(sc))
    ch:Play()
    sc.liveChannels[#sc.liveChannels + 1] = { ch = ch, base = base }
    return true
end

local function UpdateChannels(sc)
    local live = sc.liveChannels
    if not live or #live == 0 then return end
    local r = PlayRate(sc)
    for i = #live, 1, -1 do
        local l = live[i]
        if not IsValid(l.ch) or l.ch:GetState() == GMOD_CHANNEL_STOPPED then
            table.remove(live, i)
        else
            l.ch:SetPlaybackRate(l.base * r)
        end
    end
end

-- Stops and frees every channel a scene opened (it ended, or a newer
-- recording replaced it before it played).
local function ReleaseSounds(sc)
    if not sc or sc.released then return end
    sc.released = true
    for _, ch in ipairs(sc.channels or {}) do
        if IsValid(ch) then ch:Stop() end
    end
    sc.channels, sc.liveChannels = {}, {}
end

-- Open the slowed-sound channels while everyone is still loading: the
-- killer's sounds and every gunshot heard in the replay.
local function PreloadSceneSounds(sc)
    sc.channels, sc.liveChannels = {}, {}
    for _, item in ipairs(sc.events) do
        local ev = item.ev
        if ev.k == "s" and item.at >= sc.t0 and item.at <= sc.t1 then
            if item.axis ~= "world" then
                PreloadSound(sc, ev, false)
            elseif ev.w == 1 then
                PreloadSound(sc, ev, true)
            end
        end
    end
end

local function PlayPOVSound(sc, ev)
    if StartChannel(sc, ev, nil) then return end
    local name = ResolveSound(ev.n) or ResolveSound(ev.o)
    if not name then return end
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    pcall(lp.EmitSound, lp, name, ev.l or 75, math.Clamp((ev.p or 100) * PlayRate(sc), 10, 255), ev.v or 1, ev.c or CHAN_AUTO)
end

local function PlayWorldSound(sc, ev, pos)
    if not pos then return end
    if StartChannel(sc, ev, pos) then return end
    local name = ResolveSound(ev.n) or ResolveSound(ev.o)
    if not name then return end
    pcall(EmitSound, name, pos, 0, CHAN_AUTO, ev.v or 1, ev.l or 75, 0, math.Clamp((ev.p or 100) * PlayRate(sc), 10, 255))
end

local function ViewMuzzleWorldPos(sc)
    local view = sc.view
    local vm = view.vmEnt
    if IsValid(vm) and view.vmVisible then
        vm:SetupBones()
        local id = sc.muzzleAttId or 1
        local att = vm:GetAttachment(id)
        if att then
            -- The viewmodel is drawn with its own FOV; move its muzzle into
            -- world-FOV space (same correction the engine applies).
            local lpos = WorldToLocal(att.Pos, angle_zero, view.origin, view.angles)
            local k = math.tan(math.rad(view.fov * 0.5)) / math.tan(math.rad((view.vmFov or 62) * 0.5))
            if lpos.x > 0.1 then
                lpos.y = lpos.y * k
                lpos.z = lpos.z * k
            end
            return LocalToWorld(lpos, angle_zero, view.origin, view.angles)
        end
    end
    return view.origin + view.angles:Forward() * 16 - view.angles:Up() * 4 + view.angles:Right() * 4
end

local function FlashViewMuzzle(sc)
    sc.shots = (sc.shots or 0) + 1   -- the replayed crosshair's spread reacts to each shot
    sc.vmFlashUntil = RealTime() + 0.045
    sc.vmFlashMat = MUZZLE_MATS[math.random(#MUZZLE_MATS)]
    sc.vmFlashRoll = math.random(0, 359)
    local view = sc.view
    if view and view.origin then
        local dl = DynamicLight(LocalPlayer():EntIndex() + 4096)
        if dl then
            dl.pos = view.origin + view.angles:Forward() * 40
            dl.r, dl.g, dl.b = 255, 190, 110
            dl.brightness = 2
            dl.Decay = 2500
            dl.Size = 220
            dl.DieTime = CurTime() + 0.06
        end
    end
end

local worldFlashes = {}

local function FlashWorldMuzzle(pos)
    if not pos then return end
    worldFlashes[#worldFlashes + 1] = {
        pos = pos, untilT = RealTime() + 0.05,
        mat = MUZZLE_MATS[math.random(#MUZZLE_MATS)], size = math.random(14, 20),
    }
    local dl = DynamicLight(math.random(8192, 16000))
    if dl then
        dl.pos = pos
        dl.r, dl.g, dl.b = 255, 190, 110
        dl.brightness = 1.5
        dl.Decay = 2500
        dl.Size = 160
        dl.DieTime = CurTime() + 0.05
    end
end

local FLESH = { [MAT_FLESH] = true, [MAT_BLOODYFLESH] = true, [MAT_ALIENFLESH] = true, [MAT_ANTLION] = true }

-- Tracers run on the recording's clock (not the engine's real-time tracer
-- effect), so they leave the muzzle on the same frame as the flash and the
-- shot sound and slow down with the slow-mo. The impact fires when the
-- tracer gets there.
local TRACER_SPEED = 12000      -- units per second of recording time
local TRACER_LEN   = 220
local TRACER_MAT   = Material("effects/spark")
local TRACER_COL   = Color(255, 225, 170)

local function DoImpact(sc, ev)
    if ev.hs == 1 then return end
    local from, to = V(ev.a), V(ev.b)
    local ed = EffectData()
    ed:SetOrigin(to)
    ed:SetStart(from)
    ed:SetNormal(V(ev.n))
    if ev.he ~= 0 or FLESH[ev.mt] then
        ed:SetFlags(3)
        ed:SetColor(0)
        ed:SetScale(6)
        pcall(util.Effect, "BloodImpact", ed)
    else
        ed:SetSurfaceProp(ev.sp or 0)
        ed:SetDamageType(DMG_BULLET)
        ed:SetHitBox(ev.hb or 0)
        ed:SetEntity(game.GetWorld())
        pcall(util.Effect, "Impact", ed)
    end
end

local function UpdateTracers(sc, s)
    local list = sc.tracers
    if not list or #list == 0 then return end
    for i = #list, 1, -1 do
        local tr = list[i]
        local head = (s - tr.t0) * TRACER_SPEED
        tr.head = math.min(head, tr.dist)
        tr.tail = math.Clamp(head - TRACER_LEN, 0, tr.dist)
        if head >= tr.dist and not tr.hit then
            tr.hit = true
            DoImpact(sc, tr.ev)
        end
        if tr.tail >= tr.dist then table.remove(list, i) end
    end
end

local function DoBullet(sc, ev, axis, at)
    local from = V(ev.a)
    local to = V(ev.b)
    local isKiller = axis == "killer"

    -- Is this bullet leaving the shooter's gun, or a penetration/ricochet
    -- continuing from a wall?
    local shooter = sc.actorsByKey[ev.s]
    local fromGun
    if isKiller then
        fromGun = sc.view.origin == nil or from:DistToSqr(sc.view.origin) < 64 * 64
    else
        fromGun = not (shooter and shooter.pos) or from:DistToSqr(shooter.pos) < 96 * 96
    end

    if ev.v == 1 and fromGun then
        if isKiller then
            if not sc.hasClientFire then FlashViewMuzzle(sc) end
        else
            FlashWorldMuzzle(ActorMuzzle(shooter))
        end
    end

    if ev.tr == 1 then
        local start = from
        if fromGun then
            start = isKiller and ViewMuzzleWorldPos(sc) or (ActorMuzzle(shooter) or from)
        end
        local dist = start:Distance(to)
        if dist > 1 then
            sc.tracers[#sc.tracers + 1] = {
                a = start, dir = (to - start):GetNormalized(), dist = dist,
                t0 = at or sc.s or 0, head = 0, tail = 0, ev = ev,
            }
            return   -- impact fires when the tracer arrives (UpdateTracers)
        end
    end
    DoImpact(sc, ev)
end

local function DoHit(sc, ev)
    if _G.CoDHUD_ForceHitmarker then
        _G.CoDHUD_ForceHitmarker()
    elseif Killcam.HUDHitmarker then
        Killcam.HUDHitmarker()
    end
    local cv = GetConVar("codhud_enable_hitmarker")
    if not cv or cv:GetBool() then
        surface.PlaySound("hud/hitmarker.mp3")
    end
    if ev.x == 1 and _G.CoDHUD_AddScore and _G.CoDHUD_GetKillXP then
        -- The killer's "+XP" popup for each kill on camera, as they saw it
        -- (display only -- nothing is awarded).
        pcall(function() _G.CoDHUD_AddScore(_G.CoDHUD_GetKillXP()) end)
    end
end

local function DoEffect(sc, ev)
    local ed = EffectData()
    if ev.o then ed:SetOrigin(V(ev.o)) end
    if ev.s then ed:SetStart(V(ev.s)) end
    if ev.nr then ed:SetNormal(V(ev.nr)) end
    if ev.an then ed:SetAngles(Angle(ev.an[1], ev.an[2], ev.an[3])) end
    ed:SetScale(ev.sc or 1)
    ed:SetMagnitude(ev.mg or 1)
    ed:SetRadius(ev.ra or 0)
    ed:SetFlags(ev.fl or 0)
    ed:SetColor(ev.cl or 0)
    ed:SetAttachment(ev.at or 0)
    ed:SetSurfaceProp(ev.sp or 0)
    ed:SetDamageType(ev.dt or 0)
    ed:SetHitBox(ev.hb or 0)
    if ev.e and ev.e ~= 0 then
        if ev.we == 1 then return end
        local actor = sc.actorsByKey[ev.e]
        if not (actor and IsValid(actor.mdl)) then return end
        ed:SetEntity(actor.mdl)
    end
    pcall(util.Effect, ev.n, ed)
end

local function FireEvent(sc, item)
    local ev, axis = item.ev, item.axis
    local k = ev.k
    if axis == "pov" then
        if k == "s" then PlayPOVSound(sc, ev)
        elseif k == "f" then FlashViewMuzzle(sc) end
        return
    end
    if k == "b" then
        DoBullet(sc, ev, axis, item.at)
    elseif k == "s" then
        if axis == "killer" then
            PlayPOVSound(sc, ev)
        else
            local pos
            if ev.e and ev.e ~= 0 then
                local a = sc.actorsByKey[ev.e]
                if a and a.pos then pos = a.pos + Vector(0, 0, a.data.kind == 1 and 40 or 10) end
            elseif ev.pos then
                pos = V(ev.pos)
            end
            PlayWorldSound(sc, ev, pos)
        end
    elseif k == "h" then
        if axis == "killer" then DoHit(sc, ev) end
    elseif k == "d" then
        local a = sc.actorsByKey[ev.v]
        if a and ev.v ~= sc.killer then Ragdollize(sc, a, ev) end
    elseif k == "q" then
        local a = sc.actorsByKey[ev.v]
        if a then a.deadNow = true a.deathAt = sc.lastWorldTime end
    elseif k == "e" then
        DoEffect(sc, ev)
    elseif k == "p" then
        if ev.n and ev.o then
            pcall(ParticleEffect, ev.n, V(ev.o), ev.an and Angle(ev.an[1], ev.an[2], ev.an[3]) or angle_zero)
        end
    end
end

------------------------------------------------------------------------------
--  Scene lifecycle
------------------------------------------------------------------------------
local stashedCalcView

local function StashCalcView()
    stashedCalcView = {}
    local all = hook.GetTable().CalcView
    if not all then return end
    for name, fn in pairs(all) do
        if name ~= "KC_Replay_View" then
            stashedCalcView[name] = fn
        end
    end
    for name in pairs(stashedCalcView) do hook.Remove("CalcView", name) end
end

local function RestoreCalcView()
    if not stashedCalcView then return end
    for name, fn in pairs(stashedCalcView) do
        if not isentity(name) or IsValid(name) then hook.Add("CalcView", name, fn) end
    end
    stashedCalcView = nil
end

local function BuildScene(id)
    local entry = loaded[id]
    local sc = DecodeWorld(entry.world)
    sc.id = id
    sc.pov = entry.pov and DecodePOV(entry.pov) or nil
    sc.actors = {}
    sc.actorsByKey = {}
    sc.hideIndex = {}
    sc.ragdolls = {}
    sc.corpses = {}
    sc.tracers = {}
    for _, d in ipairs(sc.ents) do
        local a = { data = d }
        sc.actorsByKey[d.key] = a
        if d.key ~= sc.killer then sc.actors[#sc.actors + 1] = a end
        if d.kind == 3 and d.index and d.index > 0 then sc.hideIndex[d.index] = d.class end
    end
    BuildTimeline(sc)
    PreloadSceneSounds(sc)
    sc.view = {}
    return sc
end

local function EndScene()
    local sc = scene
    if not sc then return end
    scene = nil
    ReleaseSounds(sc)
    if sc.state == "playing" then
        for _, a in ipairs(sc.actors or {}) do RemoveActor(a) end
        for _, rag in ipairs(sc.ragdolls or {}) do if IsValid(rag) then rag:Remove() end end
        ClearViewModels()
        RestoreLive()
        RestoreCalcView()
        worldFlashes = {}
        sc.tracers = {}
    end
    hook.Run("KillcamReplayStopped")
end

local function BeginScene(id, startTime, duration, realStart)
    local entry = loaded[id]
    if scene and scene.id ~= id then EndScene() end

    if not entry or not entry.scene then
        -- Recording not here yet: hold a black screen until it is (or
        -- until the server ends the killcam).
        scene = { id = id, state = "loading", startTime = startTime, duration = duration, realStart = realStart }
        return
    end

    local sc = entry.scene
    sc.state = "playing"
    sc.startTime = startTime
    sc.duration = duration
    -- Smooth local clock, anchored to the moment the start message arrived
    -- (see NET_START) rather than to CurTime(): a client clock running
    -- ahead of the server's used to make the replay "join late" and skip
    -- its opening events -- the kill's hitmarker among them.
    sc.realStart = realStart
    scene = sc

    -- Joining late (recording finished downloading after the start): skip
    -- what already played instead of firing it all in one burst.
    local already = RealTime() - sc.realStart
    if already > 0.1 then
        local sNow = A.RealToTau(sc.map, already)
        while sc.events[sc.evCursor] and sc.events[sc.evCursor].at < sNow - 0.05 do
            sc.evCursor = sc.evCursor + 1
        end
    end

    HideLive()
    StashCalcView()
    hook.Run("KillcamReplayStarted")
    A.Debug(string.format("playing killcam %d: %.2fs window, %.2fs real, view=%s, shift=%.3f lag=%.3f",
        id, sc.t1 - sc.t0, sc.realLen, sc.pov and "client" or "server", sc.shift, sc.worldLag))
end

local function TryFinishLoad(id)
    local entry = loaded[id]
    if not entry or entry.scene or not entry.world or entry.pov == nil then return end
    if A.cv_debug:GetBool() then
        -- Raw recording, for offline inspection (data/kc_replay_last_*.json).
        pcall(file.Write, "kc_replay_last_world.json", util.TableToJSON(entry.world) or "")
        if entry.pov then pcall(file.Write, "kc_replay_last_pov.json", util.TableToJSON(entry.pov) or "") end
    end
    local ok, sc = pcall(BuildScene, id)
    if not ok then
        ErrorNoHalt("[KC] killcam decode failed: " .. tostring(sc) .. "\n")
        return
    end
    entry.scene = sc
    if not entry.acked then
        entry.acked = true
        net.Start(A.NET_ACK)
            net.WriteUInt(id, 16)
        net.SendToServer()
    end
    -- Started while we were still downloading: join in progress.
    if scene and scene.id == id and scene.state == "loading" then
        BeginScene(id, scene.startTime, scene.duration, scene.realStart)
    end
end

------------------------------------------------------------------------------
--  Networking
------------------------------------------------------------------------------
net.Receive(A.NET_BLOB, function()
    local id = net.ReadUInt(16)
    local kind = net.ReadUInt(4)
    local i = net.ReadUInt(16)
    local total = net.ReadUInt(16)
    local len = net.ReadUInt(32)
    local data = net.ReadData(len)

    -- Only the newest recording matters.
    for oldId in pairs(incoming) do if oldId ~= id then incoming[oldId] = nil end end
    for oldId, entry in pairs(loaded) do
        if oldId ~= id and not (scene and scene.id == oldId) then
            ReleaseSounds(entry.scene)
            loaded[oldId] = nil
        end
    end

    incoming[id] = incoming[id] or {}
    local slot = incoming[id][kind] or { parts = {}, total = total }
    incoming[id][kind] = slot
    slot.parts[i] = data
    for j = 1, total do
        if not slot.parts[j] then return end
    end
    local blob = table.concat(slot.parts, "", 1, total)
    incoming[id][kind] = nil

    local tbl = A.Decompress(blob)
    loaded[id] = loaded[id] or {}
    if kind == A.BLOB_WORLD then
        if not tbl then ErrorNoHalt("[KC] killcam world recording corrupt\n") return end
        loaded[id].world = tbl
    elseif kind == A.BLOB_POV then
        loaded[id].pov = tbl or false
    end
    TryFinishLoad(id)
end)

net.Receive(A.NET_NOPOV, function()
    local id = net.ReadUInt(16)
    loaded[id] = loaded[id] or {}
    loaded[id].pov = false
    TryFinishLoad(id)
end)

net.Receive(A.NET_START, function()
    local id = net.ReadUInt(16)
    local startTime = net.ReadDouble()
    local duration = net.ReadDouble()
    -- The server starts everyone a moment after sending this. Honour that
    -- lead only within reason: clocks that disagree must never make the
    -- replay start seconds early or late.
    local lead = math.Clamp(startTime - CurTime(), 0, 0.5)
    BeginScene(id, startTime, duration, RealTime() + lead)
end)

net.Receive(A.NET_STOP, function()
    EndScene()
end)

------------------------------------------------------------------------------
--  Per-frame playback
------------------------------------------------------------------------------
hook.Add("Think", "KC_Replay_Tick", function()
    local sc = scene
    if not sc then return end

    if sc.state == "loading" then
        if CurTime() > sc.startTime + (sc.duration or 0) + 1 then EndScene() end
        return
    end

    local real = RealTime() - sc.realStart
    if real >= sc.realLen then
        EndScene()
        return
    end
    real = math.max(real, 0)
    local s = A.RealToTau(sc.map, real)
    sc.s = s
    sc.rate = A.Rate(sc.prof, s)
    local wtime = s - sc.worldLag
    sc.lastWorldTime = wtime

    -- Killer's view
    local view = sc.view
    if sc.pov then
        ComputeViewFromPOV(sc, s, view)
    elseif sc.sp then
        ComputeViewFromServer(sc, s, view)
    end

    -- Viewmodel entity for this frame
    local vm = view.vmVisible and GetVM(sc, view.vmPath) or nil
    for path, other in pairs(vmCache) do
        if IsValid(other) and other ~= vm then other:SetNoDraw(true) end
    end
    view.vmEnt = vm
    if IsValid(vm) and view.origin then
        local pos, ang = LocalToWorld(view.vmLocalPos, view.vmLocalAng, view.origin, view.angles)
        vm:SetPos(pos)
        vm:SetAngles(ang)
        if vm:GetSequence() ~= view.vmSeq then vm:SetSequence(view.vmSeq or 0) end
        local cyc = view.vmCyc or 0
        if view.vmAnimT and not sc.pov then
            local dur = vm:SequenceDuration(view.vmSeq or 0)
            if dur and dur > 0 then
                local c = (view.vmTime - view.vmAnimT) * (view.vmRate or 1) / dur
                local info = vm:GetSequenceInfo(view.vmSeq or 0)
                local loops = info and info.flags and bit.band(info.flags, 1) ~= 0
                if loops then c = c % 1 else c = math.Clamp(c, 0, 1) end
                cyc = c
            end
        end
        vm:SetCycle(cyc)
        vm:SetSkin(view.vmSkin or 0)
        if view.vmBG and view.vmBG ~= "" and vm.KC_BG ~= view.vmBG then
            vm:SetBodyGroups(view.vmBG)
            vm.KC_BG = view.vmBG
        end
        vm:InvalidateBoneCache()
        -- Muzzle attachment for this weapon
        if sc.muzzleFor ~= view.vmPath then
            sc.muzzleFor = view.vmPath
            local id
            local attName = sc.pov and sc.pov.muzzle[view.weaponClass or ""]
            if attName then id = tonumber(attName) or vm:LookupAttachment(attName) end
            if not id or id <= 0 then id = vm:LookupAttachment("muzzle") end
            if not id or id <= 0 then id = vm:LookupAttachment("1") end
            if not id or id <= 0 then id = 1 end
            sc.muzzleAttId = id
        end
        local hands = view.handsVisible and GetHands(view.handsPath, vm) or nil
        if IsValid(hands) then
            hands:SetSkin(view.handsSkin or 0)
            if view.handsBG and view.handsBG ~= "" and hands.KC_BG ~= view.handsBG then
                hands:SetBodyGroups(view.handsBG)
                hands.KC_BG = view.handsBG
            end
        end
        view.handsEnt = hands
    else
        view.handsEnt = nil
    end

    -- Events that are due. These run before the actors are moved on, so a
    -- death turns the body into a ragdoll from the pose it was last seen in
    -- (the archive's next sample already has it dead and would hide it).
    local list = sc.events
    local cursor = sc.evCursor
    while list[cursor] and list[cursor].at <= s do
        FireEvent(sc, list[cursor])
        cursor = cursor + 1
    end
    sc.evCursor = cursor
    UpdateTracers(sc, s)
    UpdateChannels(sc)

    -- Everyone else
    for _, a in ipairs(sc.actors) do
        UpdateActor(sc, a, wtime)
    end
    for _, c in ipairs(sc.corpses) do
        if IsValid(c.ent) then
            c.ent:SetCycle(math.Clamp((wtime - c.start) / c.dur, 0, 1))
            c.ent:InvalidateBoneCache()
        end
    end
end)

hook.Add("CalcView", "KC_Replay_View", function(ply, origin, angles, fov)
    local sc = scene
    if not sc or sc.state ~= "playing" or not sc.view.origin then return end
    return {
        origin = sc.view.origin,
        angles = sc.view.angles,
        fov = sc.view.fov,
        drawviewer = false,
    }
end)

hook.Add("ShouldDrawLocalPlayer", "KC_Replay_NoLocalPlayer", function()
    if scene and scene.state == "playing" then return false end
end)

hook.Add("InputMouseApply", "KC_Replay_NoMouse", function(cmd)
    if scene then
        cmd:SetMouseX(0)
        cmd:SetMouseY(0)
        return true
    end
end)

-- Other shooters' muzzle flashes: world space, so drawn with the world's
-- translucent pass.
hook.Add("PostDrawTranslucentRenderables", "KC_Replay_DrawWorldFlashes", function(depth, sky, sky3d)
    local sc = scene
    if not sc or sc.state ~= "playing" or depth or sky or sky3d then return end
    local view = sc.view
    if not view.origin then return end
    if EyePos():DistToSqr(view.origin) > 4 then return end   -- not the main view (RT / mirror)
    if sc.tracers and #sc.tracers > 0 then
        render.SetMaterial(TRACER_MAT)
        for _, tr in ipairs(sc.tracers) do
            if tr.head > tr.tail + 1 then
                render.DrawBeam(tr.a + tr.dir * tr.tail, tr.a + tr.dir * tr.head, 3, 0, 1, TRACER_COL)
            end
        end
    end
    if #worldFlashes == 0 then return end
    local now = RealTime()
    local keep = {}
    for _, fl in ipairs(worldFlashes) do
        if fl.untilT > now then
            render.SetMaterial(fl.mat)
            render.DrawSprite(fl.pos, fl.size, fl.size, color_white)
            keep[#keep + 1] = fl
        end
    end
    worldFlashes = keep
end)

-- Viewmodel pass: drawn after the whole 3D frame (world, translucents,
-- effects), on a cleared depth buffer and with every render state it relies
-- on set explicitly -- like the engine's own viewmodel pass, it sits on top
-- of the world and can never clip into it. It used to be drawn from inside
-- the translucent pass and inherited whatever blend / depth-write state was
-- left there, which could render the gun see-through.
hook.Add("PostDrawEffects", "KC_Replay_DrawViewModel", function()
    local sc = scene
    if not sc or sc.state ~= "playing" then return end
    local view = sc.view
    if not view.origin then return end
    local vm = view.vmEnt
    if not IsValid(vm) then return end
    local now = RealTime()
    cam.Start3D(view.origin, view.angles, view.vmFov or 62, 0, 0, ScrW(), ScrH(), 1, 2000)
        render.ClearDepth()
        render.SetBlend(1)
        render.SetColorModulation(1, 1, 1)
        render.OverrideDepthEnable(false, false)   -- drop any override left by other hooks
        vm:SetupBones()
        vm:DrawModel()
        local hands = view.handsEnt
        if IsValid(hands) then hands:DrawModel() end
        if sc.vmFlashUntil and now < sc.vmFlashUntil then
            local att = vm:GetAttachment(sc.muzzleAttId or 1)
            if att then
                render.SetMaterial(sc.vmFlashMat)
                local p = att.Pos + att.Ang:Forward() * 1.5
                render.DrawSprite(p, 9, 9, color_white)
                render.DrawQuadEasy(p + att.Ang:Forward() * 3, view.angles:Forward() * -1, 7, 14, color_white, sc.vmFlashRoll or 0)
            end
        end
    cam.End3D()
end)

-- The killer's scope overlay (and anything else their weapon drew on the
-- HUD), plus the fade-in. Drawn before HUDPaint so the killcam bars and
-- card always sit on top, as in CoD.
local overlayCache = {}

local function DrawOverlayOps(json)
    local ops = overlayCache[json]
    if ops == nil then
        ops = util.JSONToTable(json) or false
        overlayCache[json] = ops
    end
    if not ops then return end
    local W, H = ScrW(), ScrH()
    local function X(x) return x * H + W * 0.5 end
    local function Y(y) return y * H end
    local function S(v) return v * H end
    for _, op in ipairs(ops) do
        local k = op[1]
        if k == "c" then
            surface.SetDrawColor(op[2], op[3], op[4], op[5])
        elseif k == "t" then
            if op[2] and op[2] ~= "" then surface.SetTexture(surface.GetTextureID(op[2])) end
        elseif k == "m" then
            if op[2] and op[2] ~= "" then surface.SetMaterial(Mat(op[2])) end
        elseif k == "r" then
            surface.DrawTexturedRect(X(op[2]), Y(op[3]), S(op[4]), S(op[5]))
        elseif k == "R" then
            surface.DrawRect(X(op[2]), Y(op[3]), S(op[4]), S(op[5]))
        elseif k == "O" then
            surface.DrawOutlinedRect(X(op[2]), Y(op[3]), S(op[4]), S(op[5]))
        elseif k == "u" then
            surface.DrawTexturedRectUV(X(op[2]), Y(op[3]), S(op[4]), S(op[5]), op[6], op[7], op[8], op[9])
        elseif k == "o" then
            surface.DrawTexturedRectRotated(X(op[2]), Y(op[3]), S(op[4]), S(op[5]), op[6])
        end
    end
end

hook.Add("HUDPaintBackground", "KC_Replay_Overlay", function()
    local sc = scene
    if not sc then return end
    if sc.state == "loading" then
        surface.SetDrawColor(0, 0, 0, 255)
        surface.DrawRect(0, 0, ScrW(), ScrH())
        return
    end
    local view = sc.view
    if sc.pov and view.overlay and view.overlay > 0 then
        local json = sc.pov.str[view.overlay]
        if json then DrawOverlayOps(json) end
    end
    local real = RealTime() - sc.realStart
    local fade = 1 - math.Clamp(real / 0.3, 0, 1)
    if fade > 0 then
        surface.SetDrawColor(0, 0, 0, 255 * fade)
        surface.DrawRect(0, 0, ScrW(), ScrH())
    end
end)

------------------------------------------------------------------------------
--  Public API (used by the HUD, crosshair and KC_Playing)
------------------------------------------------------------------------------
function R.IsActive()
    return scene ~= nil
end

function R.IsPlaying()
    return scene ~= nil and scene.state == "playing"
end

-- Seconds until the kill (the killcam HUD's countdown).
function R.GetTimeToKill()
    local sc = scene
    if not sc or sc.state ~= "playing" or not sc.s then return 0 end
    return math.Clamp(sc.kt - sc.s, 0, 100)
end

-- What the CoD crosshair should react to: the killer's state, not ours.
function R.GetCrosshairState()
    local sc = scene
    if not sc or sc.state ~= "playing" then return nil end
    local v = sc.view
    return {
        alive = v.alive ~= false,
        fov = v.fov or 75,
        speed = v.speed or 0,
        onGround = v.onGround ~= false,
        scoped = v.overlay ~= nil and v.overlay > 0,
        -- for the per-game CoD crosshair simulation (spread, weapon, hide states)
        weaponClass = v.weaponClass,
        angles = v.angles,
        shots = sc.shots or 0,
        vm = v.vmVisible and v.vmEnt or nil,
        sessionId = sc.id,
        rate = sc.rate or 1,
        origin = v.origin,
    }
end

-- What the killer's crosshair is over in the replay: "enemy", "friend" or
-- nil. The replay's actors are clientside models (no collision), so the aim
-- ray is tested against each visible body's bounding box.
local TEAM_NONE = { [TEAM_UNASSIGNED or 1001] = true, [TEAM_SPECTATOR or 1002] = true, [TEAM_CONNECTING or 0] = true }
function R.CrosshairTarget(origin, dir, range)
    local sc = scene
    if not sc or sc.state ~= "playing" or not origin then return nil end
    local killer = sc.actorsByKey[sc.killer]
    local myTeam = killer and killer.data.team
    local best, bestD
    for _, a in ipairs(sc.actors) do
        local mdl = a.mdl
        if a.data.kind ~= 3 and IsValid(mdl) and not mdl:GetNoDraw() then
            local hit = util.IntersectRayWithOBB(origin, dir * range, mdl:GetPos(), mdl:GetAngles(), mdl:OBBMins(), mdl:OBBMaxs())
            if hit then
                local d = hit:DistToSqr(origin)
                if not bestD or d < bestD then best, bestD = a, d end
            end
        end
    end
    if not best then return nil end
    local t = best.data.team
    if myTeam and t and myTeam == t and not TEAM_NONE[t] then return "friend" end
    return "enemy"
end

-- If the map changes or the client reloads Lua mid-killcam.
hook.Add("ShutDown", "KC_Replay_Shutdown", EndScene)
