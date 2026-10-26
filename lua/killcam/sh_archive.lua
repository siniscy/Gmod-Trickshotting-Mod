--[[
    Killcam archive -- shared definitions.

    How the killcam works now (the same model Call of Duty uses):

      * The server keeps a rolling archive of the whole match -- every
        player, bot, NPC and projectile, every tick -- plus the events that
        happened (bullets with their real impact points, sounds, hits,
        deaths). See sv_archive.lua.
      * Every human client also keeps a rolling archive of its OWN first
        person view: the exact camera, the viewmodel's position/animation
        (iron sights, sway, recoil), the scope overlay, the gun sounds it
        heard. See cl_povrecord.lua.
      * When a final killcam is needed, the server cuts the window around
        the kill out of its archive, asks the killer's client for the
        matching slice of its view archive, and sends both to everyone.
      * Each client then plays that recording back locally (cl_replay.lua).
        Nothing in the live game is moved, respawned, re-simulated or faked
        -- the killcam is purely a replay of what actually happened.

    This file holds the bits both sides need: tunables, the compact
    number codec used on the wire, and the slow-motion timeline.
]]

Killcam = Killcam or {}
Killcam.Archive = Killcam.Archive or {}
local A = Killcam.Archive

A.VERSION = 1

-- Net message names.
A.NET_BLOB    = "KC_Arc_Blob"     -- server -> client : chunk of a recording
A.NET_NOPOV   = "KC_Arc_NoPOV"    -- server -> client : killer view will not arrive
A.NET_ACK     = "KC_Arc_Ack"      -- client -> server : recording decoded and ready
A.NET_START   = "KC_Arc_Start"    -- server -> client : begin playback at time T
A.NET_STOP    = "KC_Arc_Stop"     -- server -> client : playback is over
A.NET_POVREQ  = "KC_Arc_POVReq"   -- server -> killer : send me your view for [t0,t1]
A.NET_POVUP   = "KC_Arc_POVUp"    -- killer -> server : chunk of that view archive

A.BLOB_WORLD = 1
A.BLOB_POV   = 2

A.CHUNK_SIZE = 48000

-- Pose parameters captured for every animated entity. Values are stored in
-- the pose parameter's own units (degrees / -1..1), and replayed only onto
-- models that actually have that parameter.
A.POSES = {
    "move_x", "move_y", "move_yaw", "aim_pitch", "aim_yaw",
    "head_pitch", "head_yaw", "body_yaw", "spine_yaw",
}

-- Per-sample flag bits for archived entities.
A.F_PRESENT = 1
A.F_ALIVE   = 2
A.F_CROUCH  = 4
A.F_GROUND  = 8

-- Tunables. Replicated so clients can show them in the console, but only
-- the server's values are ever used (they travel inside each recording).
local FL = bit.bor(FCVAR_ARCHIVE, FCVAR_REPLICATED)
A.cv_pre     = CreateConVar("kc_replay_pretime", "5", FL, "Seconds of footage shown before the final kill (CoD4 final killcam: 5).", 1, 12)
A.cv_post    = CreateConVar("kc_replay_posttime", "3", FL, "Seconds of footage shown after the final kill.", 0.5, 6)
A.cv_ext     = CreateConVar("kc_replay_reloadext", "2", FL, "Extra seconds allowed after posttime so a reload started after the kill can finish on camera.", 0, 4)
A.cv_slowmo  = CreateConVar("kc_replay_slowmo", "-1", FL, "Killcam slow-mo at the kill: 0 = off, anything else = on for every game (-1 and 1 are the same).", -1, 1)
A.cv_smSpeed = CreateConVar("kc_replay_slowmo_speed", "0.15", FL, "Playback speed at the slowest point of the killcam slow-mo (MW2: 0.25). Lower = slower.", 0.05, 1)
A.cv_smHold  = CreateConVar("kc_replay_slowmo_hold", "0.4", FL, "Game-time seconds the slow-mo stays at its slowest after the kill (MW2: 0.5).", 0, 2)
A.cv_buffer  = CreateConVar("kc_replay_buffer", "25", FL, "Seconds of match history the archive keeps.", 12, 60)
A.cv_debug   = CreateConVar("kc_replay_debug", "0", FL, "Print killcam archive diagnostics.", 0, 1)
A.cv_bots    = CreateConVar("kc_killcam_bots", "1", FL, "Show the final killcam when a bot or AI gets the winning kill (seen through their eyes, like CoD).", 0, 1)

-- Can this entity be the killer a final killcam is shown for?
function A.CanBeKiller(ent)
    if not IsValid(ent) then return false end
    if ent:IsPlayer() and not ent:IsBot() then return true end
    if not A.cv_bots:GetBool() then return false end
    return ent:IsPlayer() or ent:IsNPC() or (ent.IsNextBot and ent:IsNextBot()) or false
end

function A.Debug(...)
    if A.cv_debug:GetBool() then
        print("[KC Archive]", ...)
    end
end

--[[------------------------------------------------------------------------
    Number codec

    Everything on the wire is arrays of small integers: each value is
    quantised (value * scale, rounded) and then delta-coded against the
    previous one. Angles are unwrapped first, so a 359 -> 1 degree turn is a
    +2 delta (and the decoded sequence never jumps, which also makes it safe
    to interpolate). The arrays go through JSON + LZMA, which squeezes
    long runs of small deltas extremely well.
--------------------------------------------------------------------------]]

local floor = math.floor

local function q(v, scale)
    return floor(v * scale + 0.5)
end

-- values: plain array of numbers. Returns delta array.
function A.Pack(values, scale)
    local out, prev = {}, 0
    for i = 1, #values do
        local qi = q(values[i] or 0, scale)
        out[i] = qi - prev
        prev = qi
    end
    return out
end

-- Like Pack, but unwraps angles (degrees) first.
function A.PackAngles(values, scale)
    local out, prevQ = {}, 0
    local unwrapped, prevRaw = 0, nil
    for i = 1, #values do
        local raw = values[i] or 0
        if prevRaw == nil then
            unwrapped = raw
        else
            unwrapped = unwrapped + math.NormalizeAngle(raw - prevRaw)
        end
        prevRaw = raw
        local qi = q(unwrapped, scale)
        out[i] = qi - prevQ
        prevQ = qi
    end
    return out
end

function A.Unpack(deltas, scale)
    local out, acc = {}, 0
    if not deltas then return out end
    local inv = 1 / scale
    for i = 1, #deltas do
        acc = acc + (deltas[i] or 0)
        out[i] = acc * inv
    end
    return out
end

-- String table helper used while building a recording.
function A.NewStrings()
    local list, index = {}, {}
    return {
        list = list,
        Get = function(s)
            if s == nil or s == "" then return 0 end
            s = tostring(s)
            local i = index[s]
            if not i then
                i = #list + 1
                list[i] = s
                index[s] = i
            end
            return i
        end,
    }
end

function A.Compress(tbl)
    local json = util.TableToJSON(tbl)
    if not json then return nil end
    return util.Compress(json), #json
end

function A.Decompress(blob)
    if not blob or blob == "" then return nil end
    local json = util.Decompress(blob)
    if not json then return nil end
    return util.JSONToTable(json)
end

--[[------------------------------------------------------------------------
    Slow-motion timeline

    "tau" is recording time (seconds, server clock). Playback maps real
    time to tau through Rate(tau). The profile is chosen by the server and
    sent with the recording so every viewer runs the identical timeline.

    MW2's final killcam (maps/mp/gametypes/_killcam.gsc doFinalKillCamFX):
        setSlowMotion(1.0, 0.25, 1.0)  -- ease into 0.25x over the last
                                          second before the kill
        wait 0.5                       -- hold
        setSlowMotion(0.25, 1, 1.0)    -- ease back out
    MW3 / BO1 / BO2 use the same effect. (Real CoD4 / WaW final killcams
    play at normal speed, but here every game gets the slow-mo.)
--------------------------------------------------------------------------]]

function A.SlowmoProfileFor(hudType, killTau)
    -- Every game's killcam slows down at the kill (CoD4/WaW included, by
    -- request); only kc_replay_slowmo 0 turns it off.
    if A.cv_slowmo:GetInt() == 0 then return nil end
    -- Slowed further per request (was 0.2x held for 0.15s, which played
    -- out in under a second of real time and read as too fast). Defaults
    -- give ~6.7s of real-time slow-mo around the kill instead of ~4s.
    return {
        kill   = killTau,
        slow   = A.cv_smSpeed:GetFloat(),  -- slowest playback rate
        easeIn = 1.0,    -- tau seconds spent easing down before the kill
        hold   = A.cv_smHold:GetFloat(),   -- tau seconds held at full slow-mo after the kill
        easeOut= 0.8,    -- tau seconds spent easing back to 1x
    }
end

function A.Rate(prof, tau)
    if not prof then return 1 end
    local k = prof.kill
    local a = k - prof.easeIn
    local b = k + prof.hold
    local c = b + prof.easeOut
    if tau <= a or tau >= c then return 1 end
    if tau < k then
        return Lerp((tau - a) / prof.easeIn, 1, prof.slow)
    elseif tau <= b then
        return prof.slow
    end
    return Lerp((tau - b) / prof.easeOut, prof.slow, 1)
end

-- Builds a lookup from real playback seconds -> tau, plus total real length.
function A.BuildTimeMap(prof, tauStart, tauEnd)
    local reals, taus = { 0 }, { tauStart }
    if not prof then
        reals[2], taus[2] = tauEnd - tauStart, tauEnd
        return { reals = reals, taus = taus }, tauEnd - tauStart
    end
    local step = 0.004
    local real, tau = 0, tauStart
    while tau < tauEnd do
        local s = math.min(step, tauEnd - tau)
        real = real + s / A.Rate(prof, tau + s * 0.5)
        tau = tau + s
        reals[#reals + 1] = real
        taus[#taus + 1] = tau
    end
    return { reals = reals, taus = taus }, real
end

function A.RealToTau(map, real)
    local reals, taus = map.reals, map.taus
    local n = #reals
    if real <= 0 then return taus[1] end
    if real >= reals[n] then return taus[n] end
    local lo, hi = 1, n
    while hi - lo > 1 do
        local mid = floor((lo + hi) / 2)
        if reals[mid] <= real then lo = mid else hi = mid end
    end
    local span = reals[hi] - reals[lo]
    local f = span > 0 and (real - reals[lo]) / span or 0
    return taus[lo] + (taus[hi] - taus[lo]) * f
end
