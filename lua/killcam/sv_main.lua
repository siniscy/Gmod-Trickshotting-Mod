--[[
    Killcam -- server side of the final killcam.

    Flow (mirrors Call of Duty's archive killcam):

      PrepareFor(killer)   the round-ending kill just happened. Find it in
                           the archive and wait until the footage after it
                           has been recorded.
      (settle)             cut [kill - pretime, kill + posttime] out of the
                           archive (extended if the killer is mid-reload),
                           send it to every client, and ask the killer's
                           client for its first-person view of that window.
      (collect)            relay the killer's view to everyone.
      (distribute)         wait until every client has decoded both parts.
      BeginFor(killer)     start playback on every client at the same moment.
                           Killcam_Playing stays true for exactly as long as
                           the replay runs, so the round flow
                           (WaitForKillcamThenRun etc.) keeps working as before.

    The live game is never touched: nobody is respawned, moved, forced to
    spectate or re-simulated.
]]

local A = Killcam.Archive
local S_ = A.S

util.AddNetworkString(A.NET_BLOB)
util.AddNetworkString(A.NET_NOPOV)
util.AddNetworkString(A.NET_ACK)
util.AddNetworkString(A.NET_START)
util.AddNetworkString(A.NET_STOP)
util.AddNetworkString(A.NET_POVREQ)
util.AddNetworkString(A.NET_POVUP)

-- Still used by other files (sv_hitmarker.lua sends these, cl_hud.lua and
-- cl_hitmarker.lua receive them).
util.AddNetworkString("Killcam - Hitmarker")
util.AddNetworkString("CoDHUD_HitNotification")
util.AddNetworkString("KC_HitNotification")

SetGlobalBool("Killcam_Playing", false)

local Session = nil
local nextId = 0

local function Log(...)
    print("[KC]", ...)
end

local function Now() return CurTime() end

local function KillerName(ent)
    if not IsValid(ent) then return "?" end
    return ent:IsPlayer() and ent:Nick() or ent:GetClass()
end

-- Latency of what the killer was looking at ------------------------------
-- A client renders other entities `lerp` seconds in the past and its
-- clock runs roughly one round trip behind the server's processing of its
-- input. Lag compensation makes hits register against exactly that view,
-- so the replay shows the world shifted by the same amount -- the target
-- is under the crosshair when the shot goes off, just like on the
-- killer's screen. (CoD's killcam does the same with psoffsettime.)
local function ClientLerp(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return 0 end
    local interp = ply:GetInfoNum("cl_interp", 0.1)
    local ratio  = ply:GetInfoNum("cl_interp_ratio", 2)
    local rate   = ply:GetInfoNum("cl_updaterate", 30)
    local maxRate = GetConVar("sv_maxupdaterate")
    if maxRate then rate = math.min(rate, maxRate:GetFloat()) end
    local minRatio = GetConVar("sv_client_min_interp_ratio")
    local maxRatio = GetConVar("sv_client_max_interp_ratio")
    if minRatio and maxRatio and minRatio:GetFloat() >= 0 then
        ratio = math.Clamp(ratio, minRatio:GetFloat(), math.max(minRatio:GetFloat(), maxRatio:GetFloat()))
    end
    rate = math.max(rate, 1)
    return math.Clamp(math.max(interp, ratio / rate), 0, 0.5)
end

local function ClientShift(ply)
    if not IsValid(ply) or not ply:IsPlayer() or ply:IsBot() then return 0 end
    if ply:IsListenServerHost() then return 0 end
    return math.Clamp(ply:Ping() / 1000, 0, 0.5)
end

-- Sending -------------------------------------------------------------------
-- Large blobs go out one chunk per tick so a big recording never floods a
-- remote client's reliable channel.
local sendQueue = {}

local function QueueBlob(targets, id, kind, blob)
    local total = math.max(1, math.ceil(#blob / A.CHUNK_SIZE))
    for i = 1, total do
        sendQueue[#sendQueue + 1] = {
            targets = targets, id = id, kind = kind, i = i, total = total,
            data = blob:sub((i - 1) * A.CHUNK_SIZE + 1, i * A.CHUNK_SIZE),
        }
    end
end

local function PumpSendQueue()
    local item = table.remove(sendQueue, 1)
    if not item then return end
    local targets = {}
    for _, p in ipairs(item.targets) do
        if IsValid(p) then targets[#targets + 1] = p end
    end
    if #targets == 0 then return end
    net.Start(A.NET_BLOB)
        net.WriteUInt(item.id, 16)
        net.WriteUInt(item.kind, 4)
        net.WriteUInt(item.i, 16)
        net.WriteUInt(item.total, 16)
        net.WriteUInt(#item.data, 32)
        net.WriteData(item.data, #item.data)
    net.Send(targets)
end

-- Building the world recording ---------------------------------------------
local function R3(v) return math.floor(v * 10 + 0.5) / 10 end
local function VecOut(v) return { R3(v.x), R3(v.y), R3(v.z) } end

local EVENT_STRINGS = { n = true, tn = true, o = true }

local function ConvertEvent(ev, base, str)
    local out = { t = math.floor((ev.t - base) * 1000 + 0.5) }
    for k, v in pairs(ev) do
        if k ~= "t" then
            local tv = type(v)
            if tv == "Vector" then
                out[k] = VecOut(v)
            elseif tv == "Angle" then
                out[k] = { R3(v.p), R3(v.y), R3(v.r) }
            elseif tv == "string" then
                out[k] = EVENT_STRINGS[k] and str.Get(v) or v
            elseif tv == "number" then
                out[k] = (v % 1 == 0) and v or math.floor(v * 1000 + 0.5) / 1000
            elseif tv == "boolean" then
                out[k] = v and 1 or 0
            end
        end
    end
    return out
end

local function Bodygroups(ent)
    local n = ent:GetNumBodyGroups() or 0
    if n <= 0 then return "" end
    local t = {}
    for i = 0, n - 1 do t[#t + 1] = string.format("%x", math.min(ent:GetBodygroup(i) or 0, 15)) end
    return table.concat(t)
end

local function BuildWorld(sess)
    local killer = sess.killer
    local margin = 0.6
    local frames = A.FramesBetween(sess.t0 - sess.worldLagEst - margin, sess.t1 + 0.15)
    if #frames < 4 then
        Log("archive has no frames for this window")
        return nil
    end

    local base = frames[1].t
    local str = A.NewStrings()

    -- World entities at ~30Hz (the client interpolates between samples;
    -- CoD's own archive ran at the 20Hz server rate).
    local step = math.max(1, math.Round((1 / 30) / engine.TickInterval()))
    local pick = {}
    for i = 1, #frames, step do pick[#pick + 1] = frames[i] end
    if pick[#pick] ~= frames[#frames] then pick[#pick + 1] = frames[#frames] end

    local tms = {}
    for i, f in ipairs(pick) do tms[i] = f.t - base end

    local seen, order = {}, {}
    for _, f in ipairs(pick) do
        for key in pairs(f.e) do
            if not seen[key] then
                seen[key] = true
                order[#order + 1] = key
            end
        end
    end

    local npose = #A.POSES
    local entsOut = {}
    for _, key in ipairs(order) do
        local meta = A.Meta[key] or {}
        local fl, xs, ys, zs = {}, {}, {}, {}
        local eps, eys, rps, rys, rrs = {}, {}, {}, {}, {}
        local seqs, cycs, mds, wms = {}, {}, {}, {}
        local poses = {}
        for p = 1, npose do poses[p] = {} end

        local last
        for _, f in ipairs(pick) do
            if f.e[key] then last = f.e[key] break end
        end

        for i, f in ipairs(pick) do
            local s = f.e[key]
            local present = s ~= nil
            if s then last = s else s = last end
            fl[i] = present and s[S_.FLAGS] or 0
            xs[i], ys[i], zs[i] = s[S_.X], s[S_.Y], s[S_.Z]
            eps[i], eys[i] = s[S_.EP], s[S_.EY]
            rps[i], rys[i], rrs[i] = s[S_.RP], s[S_.RY], s[S_.RR]
            seqs[i], cycs[i] = s[S_.SEQ], s[S_.CYC]
            mds[i] = str.Get(s[S_.MODEL])
            wms[i] = str.Get(s[S_.WMODEL])
            for p = 1, npose do poses[p][i] = s[S_.POSE0 + p - 1] or 0 end
        end

        local poOut = {}
        for p = 1, npose do
            local any = false
            for i = 1, #poses[p] do
                if math.abs(poses[p][i]) > 0.001 then any = true break end
            end
            if any then poOut[#poOut + 1] = { p, A.Pack(poses[p], 100) } end
        end

        local e = {
            k = key, kd = meta.kind or 3, c = str.Get(meta.class or ""), i = meta.index or 0,
            b = meta.isBot and 1 or 0, nm = meta.name,
            f = A.Pack(fl, 1),
            x = A.Pack(xs, 8), y = A.Pack(ys, 8), z = A.Pack(zs, 8),
            ep = A.PackAngles(eps, 20), ey = A.PackAngles(eys, 20),
            rp = A.PackAngles(rps, 20), ry = A.PackAngles(rys, 20), rr = A.PackAngles(rrs, 20),
            sq = A.Pack(seqs, 1), cy = A.Pack(cycs, 1000),
            md = A.Pack(mds, 1), wm = A.Pack(wms, 1),
            po = poOut,
        }

        local live = meta.ent
        if IsValid(live) then
            e.sk = live:GetSkin() or 0
            e.bg = Bodygroups(live)
            if live:IsPlayer() then
                local col = live:GetPlayerColor()
                if col then e.col = { R3(col.x), R3(col.y), R3(col.z) } end
                e.tm = live:Team()   -- lets the replayed crosshair tell friend from enemy
            end
        end
        entsOut[#entsOut + 1] = e
    end

    -- The killer's own state at full tick rate: used as their view if
    -- their client's first-person recording can't be had.
    local sp
    if sess.killerKey then
        local kt, kx, ky, kz, kvh, kep, key_, kvm, kvs, kvc, kwc, kfl = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
        local kva, kvr = {}, {}
        local n = 0
        for _, f in ipairs(frames) do
            local s = f.e[sess.killerKey]
            if s then
                n = n + 1
                kt[n] = f.t - base
                kx[n], ky[n], kz[n] = s[S_.X], s[S_.Y], s[S_.Z]
                kvh[n] = s[S_.VH]
                kep[n], key_[n] = s[S_.EP], s[S_.EY]
                kvm[n] = str.Get(s[S_.VMMODEL])
                kvs[n], kvc[n] = s[S_.VMSEQ], s[S_.VMCYC]
                kva[n] = (s[S_.VMANIMT] or 0) > 0 and (s[S_.VMANIMT] - base) or 0
                kvr[n] = s[S_.VMRATE] or 1
                kwc[n] = str.Get(s[S_.WCLASS])
                kfl[n] = s[S_.FLAGS]
            end
        end
        if n > 1 then
            sp = {
                tm = A.Pack(kt, 1000),
                x = A.Pack(kx, 16), y = A.Pack(ky, 16), z = A.Pack(kz, 16), vh = A.Pack(kvh, 16),
                ep = A.PackAngles(kep, 50), ey = A.PackAngles(key_, 50),
                vm = A.Pack(kvm, 1), vs = A.Pack(kvs, 1), vc = A.Pack(kvc, 1000),
                va = A.Pack(kva, 1000), vr = A.Pack(kvr, 100),
                wc = A.Pack(kwc, 1), f = A.Pack(kfl, 1),
            }
        end
    end

    local evOut = {}
    local e0, e1 = base - 0.1, sess.t1 + 0.6
    for _, ev in ipairs(A.Events) do
        if ev.t >= e0 and ev.t <= e1 then
            evOut[#evOut + 1] = ConvertEvent(ev, base, str)
        end
    end

    local W = {
        v = A.VERSION, id = sess.id,
        base = base, t0 = sess.t0, t1 = sess.t1, kt = sess.killT,
        killer = sess.killerKey, victim = sess.victimKey,
        lerp = sess.lerp, shift = sess.shiftEst,
        prof = sess.prof, hud = sess.hud,
        fov = (IsValid(killer) and killer:IsPlayer() and not killer:IsBot()) and killer:GetInfoNum("fov_desired", 75) or 75,
        tm = A.Pack(tms, 1000),
        ents = entsOut, sp = sp, ev = evOut,
        str = str.list,
    }
    return W
end

-- Window / reload extension ------------------------------------------------
local function ComputeWindow(sess)
    local pre  = A.cv_pre:GetFloat()
    local post = A.cv_post:GetFloat()
    local ext  = A.cv_ext:GetFloat()
    local kt   = sess.killT

    sess.t0 = kt - pre
    local t1 = kt + post

    -- If the killer reloads after the kill, keep rolling until the clip is
    -- back up (or the extension runs out) so the reload isn't cut off.
    local frames = A.FramesBetween(kt, kt + post + ext)
    local prevClip, prevClass, refillT
    local clipAtCut
    for _, f in ipairs(frames) do
        local s = f.e[sess.killerKey]
        if s then
            local clip, class = s[S_.CLIP], s[S_.WCLASS]
            if prevClip and class == prevClass and clip > prevClip and not refillT then
                refillT = f.t
            end
            if f.t <= kt + post then clipAtCut = clip end
            prevClip, prevClass = clip, class
        end
    end
    if refillT and refillT > t1 - 0.4 then
        t1 = math.Clamp(refillT + 0.4, kt + post, kt + post + ext)
    elseif not refillT and clipAtCut == 0 then
        t1 = kt + post + ext
    end
    sess.t1 = math.min(t1, Now() - 0.05)
end

-- Session state machine ----------------------------------------------------
local function Fail(sess, why)
    Log("killcam unavailable: " .. tostring(why))
    sess.state = "failed"
end

local function Viewers()
    local out = {}
    for _, p in ipairs(player.GetHumans()) do
        if IsValid(p) then out[#out + 1] = p end
    end
    return out
end

local function Settle(sess)
    ComputeWindow(sess)

    local killer = sess.killer
    sess.lerp = ClientLerp(killer)
    sess.shiftEst = ClientShift(killer)
    sess.worldLagEst = sess.lerp + sess.shiftEst
    sess.hud = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    sess.prof = A.SlowmoProfileFor(sess.hud, sess.killT)
    local _, dur = A.BuildTimeMap(sess.prof, sess.t0, sess.t1)
    sess.duration = dur

    local W = BuildWorld(sess)
    if not W then return Fail(sess, "no archived footage") end
    local blob, raw = A.Compress(W)
    if not blob then return Fail(sess, "could not encode footage") end
    A.Debug(string.format("world recording: %d entities, %d events, %d bytes json -> %d bytes, window %.2fs (%.2fs real)",
        #W.ents, #W.ev, raw or 0, #blob, sess.t1 - sess.t0, dur))

    sess.viewers = Viewers()
    sess.acks = {}
    QueueBlob(sess.viewers, sess.id, A.BLOB_WORLD, blob)

    -- Ask the killer's client for its own first-person recording.
    sess.pov = nil
    sess.povParts = {}
    -- Humans send their own first-person recording; bots and AI have no
    -- client, so their view is rebuilt from the server archive.
    sess.wantPov = IsValid(killer) and killer:IsPlayer() and not killer:IsBot()
    if sess.wantPov then
        net.Start(A.NET_POVREQ)
            net.WriteUInt(sess.id, 16)
            net.WriteDouble(sess.t0 - sess.worldLagEst - 1.0)
            net.WriteDouble(sess.t1 + 0.6)
        net.Send(killer)
    end
    sess.collectStart = Now()
    sess.state = "collect"
end

local function Collect(sess)
    local done = sess.pov ~= nil
    local timedOut = Now() - sess.collectStart > 4
    if not done and sess.wantPov and IsValid(sess.killer) and not timedOut then return end

    if sess.pov then
        QueueBlob(sess.viewers, sess.id, A.BLOB_POV, sess.pov)
        A.Debug("killer view recording: " .. #sess.pov .. " bytes")
    else
        if sess.wantPov then Log("killer view recording did not arrive -- using the server's view of the killer") end
        net.Start(A.NET_NOPOV)
            net.WriteUInt(sess.id, 16)
        net.Send(sess.viewers)
    end
    sess.distStart = Now()
    sess.state = "distribute"
end

local function Distribute(sess)
    local all = true
    for _, p in ipairs(sess.viewers) do
        if IsValid(p) and not sess.acks[p] then all = false break end
    end
    if all or Now() - sess.distStart > 6 then
        if not all then Log("not every client finished downloading the killcam; starting anyway") end
        sess.state = "ready"
    end
end

local function Start(sess)
    local killer = sess.killer
    SetGlobalEntity("Killcam_Killer", IsValid(killer) and killer or NULL)
    if IsValid(killer) then
        hook.Run("OnKillcamReplayStart", killer)
    end
    -- Freeze the round timer for the killcam; it resets when the next
    -- round begins, so the match can't time out mid-replay.
    CoDHUD_RoundEndTimeSV = nil

    sess.startTime = Now() + 0.15
    sess.endTime = sess.startTime + sess.duration
    net.Start(A.NET_START)
        net.WriteUInt(sess.id, 16)
        net.WriteDouble(sess.startTime)
        net.WriteDouble(sess.duration)
    net.Broadcast()

    SetGlobalBool("Killcam_Playing", true)
    sess.state = "playing"
    Log(string.format("final killcam: %s, %.1fs", KillerName(killer), sess.duration))
    hook.Run("KillcamReplayStarted")
end

local function Stop(sess)
    if sess then sess.state = "done" end
    net.Start(A.NET_STOP)
        net.WriteUInt(sess and sess.id or 0, 16)
    net.Broadcast()
    SetGlobalBool("Killcam_Playing", false)
    SetGlobalEntity("Killcam_Killer", NULL)
    hook.Run("KillcamReplayStopped")
end

-- When there's nothing to show, still pulse Killcam_Playing so the round
-- flow (which waits for a killcam to start and then end) moves on promptly.
local function PulseNoKillcam()
    SetGlobalBool("Killcam_Playing", true)
    timer.Simple(0.3, function()
        SetGlobalBool("Killcam_Playing", false)
        hook.Run("KillcamReplayStopped")
    end)
end

hook.Add("Think", "KC_Session", function()
    PumpSendQueue()

    local sess = Session
    if not sess then return end
    local st = sess.state

    if st == "wait" then
        if not sess.mark then
            sess.mark = A.FindKill(sess.killer, _G.SeshBot_LastRoundEndVictim)
            if not sess.mark then
                if Now() - sess.created > 2 then
                    Fail(sess, "no recorded kill for " .. KillerName(sess.killer))
                end
                return
            end
            sess.killT = sess.mark.t
            sess.killerKey = sess.mark.akey
            sess.victimKey = sess.mark.vkey
        end
        local ready = Now() >= sess.killT + A.cv_post:GetFloat() + A.cv_ext:GetFloat() + 0.05
        local hurry = sess.beginRequested and Now() >= sess.killT + A.cv_post:GetFloat() + 0.05
        if ready or hurry then Settle(sess) end
    elseif st == "collect" then
        Collect(sess)
    elseif st == "distribute" then
        Distribute(sess)
    elseif st == "ready" then
        if sess.beginRequested then Start(sess) end
    elseif st == "playing" then
        if Now() >= sess.endTime + 0.05 then Stop(sess) end
    elseif st == "failed" then
        if sess.beginRequested and not sess.pulsed then
            sess.pulsed = true
            PulseNoKillcam()
        end
    end
end)

-- Net receivers --------------------------------------------------------------
net.Receive(A.NET_POVUP, function(_, ply)
    local id = net.ReadUInt(16)
    local i = net.ReadUInt(16)
    local total = net.ReadUInt(16)
    local len = net.ReadUInt(32)
    local sess = Session
    if not sess or sess.id ~= id or ply ~= sess.killer or sess.state ~= "collect" then return end
    if len > A.CHUNK_SIZE * 2 or total > 64 or i < 1 or i > total then return end
    sess.povParts[i] = net.ReadData(len)
    for j = 1, total do
        if not sess.povParts[j] then return end
    end
    sess.pov = table.concat(sess.povParts, "", 1, total)
end)

net.Receive(A.NET_ACK, function(_, ply)
    local id = net.ReadUInt(16)
    local sess = Session
    if sess and sess.id == id then sess.acks[ply] = true end
end)

-- Public API ------------------------------------------------------------------
Killcam = Killcam or {}

-- Start preparing the killcam for this killer's most recent kill. Safe to
-- call more than once; call it the moment the round-ending kill is known
-- so the footage is already on every client when BeginFor runs.
function Killcam.PrepareFor(killer)
    if not IsValid(killer) then return nil end
    if not (killer:IsPlayer() or killer:IsNPC() or (killer.IsNextBot and killer:IsNextBot())) then return nil end
    local cur = Session
    if cur and cur.killer == killer and (cur.state ~= "done" and cur.state ~= "failed") then
        return cur
    end
    if cur and cur.state == "playing" then return nil end
    nextId = nextId % 60000 + 1
    Session = {
        id = nextId, killer = killer, state = "wait", created = Now(),
        acks = {}, viewers = {},
    }
    -- Resolve the kill on the next Think: when this is called from inside a
    -- PlayerDeath hook, the archive's own PlayerDeath hook may not have
    -- logged the kill yet.
    return Session
end

-- Play the final killcam for this killer.
function Killcam.StartPlaying(killer)
    if GetGlobalBool("Killcam_Playing") then return end
    local sess = Session
    if not (sess and sess.killer == killer and sess.state ~= "done" and sess.state ~= "failed") then
        sess = Killcam.PrepareFor(killer)
    end
    if not sess then
        PulseNoKillcam()
        return
    end
    sess.beginRequested = true
    if sess.state == "failed" and not sess.pulsed then
        sess.pulsed = true
        PulseNoKillcam()
    end
end

function Killcam.StopPlaying()
    local sess = Session
    if sess and sess.state == "playing" then
        Stop(sess)
    elseif GetGlobalBool("Killcam_Playing") then
        Stop(nil)
    end
end

function Killcam.IsPreparing(killer)
    local sess = Session
    return sess ~= nil and sess.killer == killer and sess.state ~= "done" and sess.state ~= "failed"
end

-- Debug / testing: replay your own (or the given player's) last kill.
local function CanUseDebug(ply)
    return not IsValid(ply) or ply:IsListenServerHost() or ply:IsSuperAdmin()
end

concommand.Add("kc_play", function(ply)
    if not CanUseDebug(ply) then return end
    local target = IsValid(ply) and ply or player.GetHumans()[1]
    if not IsValid(target) then return end
    Killcam.PrepareFor(target)
    Killcam.StartPlaying(target)
end)

concommand.Add("kc_stop", function(ply)
    if not CanUseDebug(ply) then return end
    Killcam.StopPlaying()
end)
