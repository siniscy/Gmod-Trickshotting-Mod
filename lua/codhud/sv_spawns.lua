--[[
    Spawn selection (CoD-style).

      * Nobody ever spawns inside another player: every spot must fit a full
        player hull with nothing in it.
      * Enemies spawn far apart: spots are scored by their distance from the
        nearest living enemy (players, bots and AI on another faction --
        everyone in FFA), and spots an enemy can see are penalised.
      * Teammates spawn together: in team modes, spots near living teammates
        score higher (close, but never on top of each other).
      * Spots handed out in the last few seconds count as taken, so a whole
        team spawning at once spreads out instead of stacking.

    KC_Spawns.Pick(ply, opts) returns pos, ang. Every spawn path in the mod
    uses it, and a safety net re-places anyone who still ends up spawning
    overlapped or right next to an enemy.
]]

KC_Spawns = KC_Spawns or {}
local S = KC_Spawns

local cv_enabled  = CreateConVar("kc_spawn_enabled", "1", FCVAR_ARCHIVE, "Use CoD-style spawn selection (no spawning inside players, teammates together, enemies far away).", 0, 1)
local cv_enemyMin = CreateConVar("kc_spawn_enemy_min", "1200", FCVAR_ARCHIVE, "Preferred minimum distance (units) between a spawn and the nearest living enemy.", 200, 10000)
local cv_mateMax  = CreateConVar("kc_spawn_mate_range", "500", FCVAR_ARCHIVE, "Teammates prefer to spawn within this distance (units) of a living teammate.", 100, 5000)

local HULL_MINS = Vector(-16, -16, 0)
local HULL_MAXS = Vector(16, 16, 72)
local MATE_MIN  = 70          -- never closer than this to anyone
local RECENT_T  = 4           -- seconds a handed-out spot stays "taken"

local recent = {}             -- { pos, team, t }

-- Teams --------------------------------------------------------------------
local function GameMode()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv and cv:GetString() or ""
end

function S.IsFFA()
    local gm = GameMode()
    return gm == "dm" or gm == "sesh_dm"
end

function S.TeamOf(ent)
    if not IsValid(ent) then return nil end
    local f = ent:GetNW2String("CoDHUD_Faction", "")
    if f ~= "" then return f end
    if ent:IsPlayer() then return "team" .. ent:Team() end
    if ent:IsNPC() then return "npc" end
    return nil
end

local function Combatants(except)
    local out = {}
    for _, p in ipairs(player.GetAll()) do
        if p ~= except and IsValid(p) and p:Alive() and p:GetObserverMode() == OBS_MODE_NONE then
            out[#out + 1] = p
        end
    end
    for _, e in ipairs(ents.GetAll()) do
        if e ~= except and IsValid(e) and (e:IsNPC() or (e.IsNextBot and e:IsNextBot())) and e:Health() > 0 then
            out[#out + 1] = e
        end
    end
    return out
end

-- Candidate spots --------------------------------------------------------------
local SPAWN_CLASSES = {
    "info_player_start", "info_player_deathmatch", "info_player_combine",
    "info_player_rebel", "info_player_counterterrorist", "info_player_terrorist",
    "info_player_allies", "info_player_axis", "info_player_teamspawn",
}

local mapSpawns, mapSpawnsT = nil, 0
local function MapSpawns()
    if mapSpawns and CurTime() - mapSpawnsT < 30 then return mapSpawns end
    mapSpawns, mapSpawnsT = {}, CurTime()
    for _, cls in ipairs(SPAWN_CLASSES) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            mapSpawns[#mapSpawns + 1] = { pos = e:GetPos(), ang = e:GetAngles() }
        end
    end
    return mapSpawns
end

local navAreas, navT = nil, 0
local function NavAreas()
    if navAreas and CurTime() - navT < 30 then return navAreas end
    navAreas, navT = {}, CurTime()
    if not navmesh or not navmesh.IsLoaded or not navmesh.IsLoaded() then return navAreas end
    for _, a in ipairs(navmesh.GetAllNavAreas()) do
        if IsValid(a) and not a:IsUnderwater() and a:GetSizeX() >= 32 and a:GetSizeY() >= 32 then
            navAreas[#navAreas + 1] = a
        end
    end
    return navAreas
end

local function MapCenter()
    local sp = MapSpawns()
    if #sp == 0 then return Vector(0, 0, 0) end
    local c = Vector(0, 0, 0)
    for _, s in ipairs(sp) do c = c + s.pos end
    return c / #sp
end

-- Drops a point onto the floor and checks a standing player fits there
-- without touching the world or anybody else.
local function Settle(pos, ignore)
    local down = util.TraceLine({
        start = pos + Vector(0, 0, 48), endpos = pos - Vector(0, 0, 256),
        mask = MASK_PLAYERSOLID_BRUSHONLY,
    })
    if not down.Hit or down.StartSolid then return nil end
    local p = down.HitPos + Vector(0, 0, 2)
    local hull = util.TraceHull({
        start = p, endpos = p, mins = HULL_MINS, maxs = HULL_MAXS,
        mask = MASK_PLAYERSOLID, filter = ignore,
    })
    if hull.Hit or hull.StartSolid then return nil end
    return p
end

local function Candidates()
    local list = {}
    for _, s in ipairs(MapSpawns()) do
        list[#list + 1] = { pos = s.pos, ang = s.ang }
        -- A few spots around each spawn point, so several players can use it.
        for i = 1, 3 do
            local a = math.rad(math.random(0, 359))
            local r = math.random(60, 140)
            list[#list + 1] = { pos = s.pos + Vector(math.cos(a) * r, math.sin(a) * r, 0), ang = s.ang }
        end
    end
    local areas = NavAreas()
    if #areas > 0 then
        for _ = 1, 48 do
            local area = areas[math.random(#areas)]
            list[#list + 1] = { pos = area:GetRandomPoint() }
        end
    end
    return list
end

-- Scoring ------------------------------------------------------------------------
local function Sees(viewer, pos)
    local tr = util.TraceLine({
        start = viewer:EyePos(), endpos = pos + Vector(0, 0, 60),
        mask = MASK_VISIBLE, filter = viewer,
    })
    return not tr.Hit
end

local function Score(pos, myTeam, ffa, people, enemyMin, mateRange)
    local dEnemy, dMate = math.huge, math.huge
    local seen = 0
    for _, e in ipairs(people) do
        local d = pos:Distance(e:GetPos())
        if d < MATE_MIN then return nil end
        local mate = not ffa and myTeam ~= nil and S.TeamOf(e) == myTeam
        if mate then
            dMate = math.min(dMate, d)
        else
            dEnemy = math.min(dEnemy, d)
            if d < 4000 and Sees(e, pos) then seen = seen + 1 end
        end
    end
    for _, r in ipairs(recent) do
        local d = pos:Distance(r.pos)
        if d < MATE_MIN then return nil end
        if not ffa and myTeam ~= nil and r.team == myTeam then
            dMate = math.min(dMate, d)
        else
            dEnemy = math.min(dEnemy, d)
        end
    end

    local score = math.min(dEnemy, 4000)
    if dEnemy < enemyMin then score = score - 3000 end
    score = score - seen * 1500
    if not ffa and dMate < math.huge then
        -- Close to the team, but not shoulder to shoulder.
        if dMate <= mateRange then
            score = score + 2500 - dMate
        else
            score = score + math.max(0, 1500 - (dMate - mateRange))
        end
    end
    return score
end

-- Public -------------------------------------------------------------------------
function S.Enabled()
    return cv_enabled:GetBool()
end

-- ply may be nil (choosing a spot before the entity exists); then opts.team
-- says which side it will be on.
function S.Pick(ply, opts)
    opts = opts or {}
    local now = CurTime()
    for i = #recent, 1, -1 do
        if now - recent[i].t > RECENT_T then table.remove(recent, i) end
    end

    local myTeam = opts.team or S.TeamOf(ply)
    local ffa = opts.ffa
    if ffa == nil then ffa = S.IsFFA() end
    local people = Combatants(ply)
    local enemyMin = opts.enemyMin or cv_enemyMin:GetFloat()
    local mateRange = cv_mateMax:GetFloat()

    local best, bestScore, bestAng
    for _, c in ipairs(Candidates()) do
        local p = Settle(c.pos, ply)
        if p then
            local sc = Score(p, myTeam, ffa, people, enemyMin, mateRange)
            if sc and (not bestScore or sc > bestScore) then
                best, bestScore, bestAng = p, sc, c.ang
            end
        end
    end

    if not best then
        -- Every candidate was blocked: spiral out from a map spawn (or the
        -- player) until a free spot turns up.
        local origin = (MapSpawns()[1] and MapSpawns()[1].pos) or (IsValid(ply) and ply:GetPos()) or Vector(0, 0, 0)
        for ring = 1, 12 do
            for step = 0, 11 do
                local a = math.rad(step * 30)
                local p = Settle(origin + Vector(math.cos(a), math.sin(a), 0) * ring * 48, ply)
                if p and Score(p, myTeam, ffa, people, enemyMin, mateRange) then best = p break end
            end
            if best then break end
        end
        best = best or origin
    end

    if not bestAng then
        local toCenter = MapCenter() - best
        toCenter.z = 0
        bestAng = toCenter:LengthSqr() > 1 and toCenter:Angle() or Angle(0, math.random(0, 359), 0)
    end
    bestAng = Angle(0, bestAng.y, 0)

    recent[#recent + 1] = { pos = best, team = myTeam, t = now }
    return best, bestAng
end

-- Places a player at a picked spot.
function S.Place(ply)
    if not IsValid(ply) then return end
    local pos, ang = S.Pick(ply)
    ply:SetPos(pos)
    ply:SetEyeAngles(ang)
    ply:SetLocalVelocity(vector_origin)
end

-- Is this spot unacceptable for this player right now?
function S.IsBad(ply, pos)
    local hull = util.TraceHull({
        start = pos + Vector(0, 0, 2), endpos = pos + Vector(0, 0, 2),
        mins = HULL_MINS, maxs = HULL_MAXS, mask = MASK_PLAYERSOLID, filter = ply,
    })
    if hull.Hit and IsValid(hull.Entity) and (hull.Entity:IsPlayer() or hull.Entity:IsNPC()) then return true end
    local myTeam = S.TeamOf(ply)
    local ffa = S.IsFFA()
    local minEnemy = cv_enemyMin:GetFloat() * 0.4
    for _, e in ipairs(Combatants(ply)) do
        local d = pos:Distance(e:GetPos())
        if d < MATE_MIN then return true end
        local mate = not ffa and myTeam ~= nil and S.TeamOf(e) == myTeam
        if not mate and d < minEnemy then return true end
    end
    return false
end

-- Safety net: whatever code spawned someone, fix it if they landed inside
-- another player or right next to an enemy. Runs a tick later so the
-- spawning code's own SetPos has already happened.
hook.Add("PlayerSpawn", "KC_Spawns_SafetyNet", function(ply)
    if not cv_enabled:GetBool() then return end
    timer.Simple(0, function()
        if not IsValid(ply) or not ply:Alive() then return end
        if GetGlobalBool("Killcam_Playing") then return end
        if ply.KC_SpawnPlacedT and CurTime() - ply.KC_SpawnPlacedT < 0.5 then return end
        if S.IsBad(ply, ply:GetPos()) then
            S.Place(ply)
            ply.KC_SpawnPlacedT = CurTime()
        end
    end)
end)
