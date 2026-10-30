---- [ SPAWN UNSTICK ] ----
-- Every time a player or bot spawns, checks that their hull is actually free.
-- If they came in inside a wall, a prop, map collision or another player, they
-- are moved to the nearest free spot with ground under it.
--
-- KC_Spawns' safety net (codhud/sv_spawns.lua) only re-places people who land
-- on another player and is off with kc_spawn_enabled 0; this covers walls and
-- props too and runs whichever spawn code placed them.
--
--   kc_spawn_unstick 1/0   on by default

if not SERVER then return end

local cv_enabled = CreateConVar("kc_spawn_unstick", "1", FCVAR_ARCHIVE,
    "Move players and bots out of walls, props and other players when they spawn.", 0, 1)

local MAX_RADIUS = 256       -- furthest a player is ever moved sideways
local GROUND_GAP = 96        -- a spot needs ground within this far below it
local LIFT       = Vector(0, 0, 2) -- tests start just off the floor so standing on it isn't "inside" it

-- Dropped weapons and debris don't block a player, so they don't count.
local PASS_GROUPS = {
    [COLLISION_GROUP_DEBRIS] = true,
    [COLLISION_GROUP_DEBRIS_TRIGGER] = true,
    [COLLISION_GROUP_WEAPON] = true,
    [COLLISION_GROUP_IN_VEHICLE] = true,
    [COLLISION_GROUP_WORLD] = true,
}

local function Filter(ply)
    return function(ent)
        if ent == ply then return false end
        if not IsValid(ent) then return true end   -- the world
        if ent:IsWeapon() or PASS_GROUPS[ent:GetCollisionGroup()] then return false end
        return true
    end
end

local function Hull(ply)
    if ply:Crouching() then return ply:GetHullDuck() end
    return ply:GetHull()
end

local function Blocked(pos, mins, maxs, filter)
    local tr = util.TraceHull({
        start = pos + LIFT, endpos = pos + LIFT, mins = mins, maxs = maxs,
        mask = MASK_PLAYERSOLID, filter = filter,
    })
    return tr.StartSolid or tr.Hit
end

-- Free spot -> the floor under it, or nil if there's no floor close enough.
local function Ground(pos, mins, maxs, filter)
    local tr = util.TraceHull({
        start = pos + LIFT, endpos = pos - Vector(0, 0, GROUND_GAP), mins = mins, maxs = maxs,
        mask = MASK_PLAYERSOLID, filter = filter,
    })
    if tr.StartSolid or not tr.Hit then return nil end
    return tr.HitPos
end

-- Offsets to try, nearest first: rings around the spawn, a little higher each
-- time so a player sunk into a floor or a ramp comes out on top of it.
local OFFSETS = {}
do
    for _, z in ipairs({ 0, 16, 36, 72 }) do
        if z > 0 then OFFSETS[#OFFSETS + 1] = Vector(0, 0, z) end
        for r = 16, MAX_RADIUS, 16 do
            local steps = r <= 64 and 8 or 16
            for i = 0, steps - 1 do
                local a = math.rad(i * 360 / steps)
                OFFSETS[#OFFSETS + 1] = Vector(math.cos(a) * r, math.sin(a) * r, z)
            end
        end
    end
    table.sort(OFFSETS, function(a, b) return a:LengthSqr() < b:LengthSqr() end)
end

-- Nearest free spot to `origin`. Spots with no wall between them and the
-- spawn come first, so nobody gets popped through a wall into a closed room.
local function FindFree(origin, mins, maxs, filter)
    local centre = Vector(0, 0, (mins.z + maxs.z) * 0.5)
    local behindWall

    for _, off in ipairs(OFFSETS) do
        local pos = origin + off
        if util.IsInWorld(pos) and not Blocked(pos, mins, maxs, filter) then
            local floor = Ground(pos, mins, maxs, filter)
            if floor then
                local los = util.TraceLine({
                    start = origin + centre, endpos = floor + centre,
                    mask = MASK_PLAYERSOLID_BRUSHONLY,
                })
                if los.StartSolid or not los.Hit then return floor end
                behindWall = behindWall or floor
            end
        end
    end

    if behindWall then return behindWall end

    -- Nothing near: the closest navmesh area is always somewhere walkable.
    if navmesh and navmesh.GetNearestNavArea then
        local area = navmesh.GetNearestNavArea(origin, false, 2048, false, true)
        if IsValid(area) then
            local pos = area:GetCenter()
            if not Blocked(pos, mins, maxs, filter) then return pos end
        end
    end

    return nil
end

local function Unstick(ply)
    if not cv_enabled:GetBool() then return end
    if not IsValid(ply) or not ply:Alive() or ply:InVehicle() then return end
    if ply:GetMoveType() == MOVETYPE_NOCLIP then return end

    local mins, maxs = Hull(ply)
    local filter = Filter(ply)
    local origin = ply:GetPos()
    if not Blocked(origin, mins, maxs, filter) then return end

    local pos = FindFree(origin, mins, maxs, filter)
    if pos then
        ply:SetPos(pos)
        ply:SetLocalVelocity(vector_origin)
    elseif KC_Spawns and KC_Spawns.Place then
        KC_Spawns.Place(ply)
    end
end

-- Checked twice: once right after the spawn code's own SetPos, and again a
-- moment later after anything that re-places people (bot spawning, KC_Spawns'
-- safety net, a round-start freeze) has run.
hook.Add("PlayerSpawn", "KC_SpawnUnstick", function(ply)
    timer.Simple(0.1, function() Unstick(ply) end)
    timer.Simple(0.5, function() Unstick(ply) end)
end)
