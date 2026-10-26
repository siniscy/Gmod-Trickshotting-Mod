---- [ SERVER: WALLBANG EVERYTHING ] ----
-- Makes every bullet from an ELIGIBLE shooter keep travelling through world
-- geometry and props instead of stopping at the first surface. Works on any
-- map with no per-map setup.
--
-- How it works: GMod calls the EntityFireBullets hook for every bullet any
-- weapon fires, before the engine traces it. We don't touch the original
-- shot at all -- the engine still does its own spread/tracer/damage exactly
-- as normal, and any hit markers/blood/effects a weapon's own bullet.Callback
-- adds still fire untouched (we wrap it, not replace it). Once that original
-- bullet's trace stops (a wall, a prop, or a player it just damaged), we
-- continue it ourselves with plain util.TraceLine/TraceHull calls -- NOT
-- another attacker:FireBullets() -- stepping just past each impact point and
-- re-tracing the remaining distance, up to a safety cap. Only when one of
-- those continuation traces actually lands on a player or NPC do we apply
-- damage, via a manually-built DamageInfo (which still goes through the
-- normal EntityTakeDamage pipeline, so existing friendly-fire/instant-kill
-- hooks apply exactly as they would to a normal hit) and the weapon's own
-- hit callback for hitmarker/blood/sound feedback.
--
-- This replaced an earlier version that called a real attacker:FireBullets()
-- for every continuation segment -- a full re-run of the engine's own bullet
-- pipeline (spread calc, tracer networking to every client, re-dispatching
-- every OTHER EntityFireBullets hook) for each of up to 4 penetrations per
-- shot. A plain trace has none of that cost; the engine's normal pipeline
-- only ever runs once per shot now, for the original bullet.
--
-- Who's eligible (per request -- this is what's different from the first
-- attempt, which applied to every human and could opt bots in too):
--   Team modes (war/sesh_war/sd/sesh_sd/sesh_sd_set): only the listen-server
--   host and any other REAL player on the host's own team.
--   FFA modes (dm/sesh_dm) and anything else non-team: the host and any
--   other real player -- there's no team to restrict to.
--   Bots: NEVER, in any mode, no exception/opt-in convar. The first attempt
--   was fully disabled after it made sesh modes hang -- the prime suspect
--   was every one of 6+ simultaneously-firing bots each recursively
--   re-tracing up to kc_wallbang_max_penetrations more bullets, compounding
--   the per-shot cost by however many bots were shooting at once. Making
--   the exclusion absolute (not just off-by-default) instead of "all
--   humans" keeps that multiplier from ever existing at all -- in the
--   normal single-host setup this addon is built around, that leaves at
--   most a small handful of eligible shooters, not 6+.
if not SERVER then return end

CreateConVar("kc_wallbang_everything", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY },
    "If enabled, eligible players' bullets penetrate world geometry and props completely instead of stopping at the first surface. See sv_wallbang_everything.lua for who's eligible.")
-- Every wall/prop/player a bullet tunnels through here is one plain trace,
-- not a re-run of the engine's own bullet pipeline (see the header above),
-- so this cap can be generous without the per-penetration cost that made 4
-- necessary in the old FireBullets-based version -- 64 is effectively
-- "everything" for any real map (very few sightlines stack anywhere near
-- that many solid surfaces in a straight line) while still keeping a hard
-- ceiling against a genuinely pathological, degenerate-geometry case
-- (near-zero-distance hits) looping unboundedly.
CreateConVar("kc_wallbang_max_penetrations", "64", { FCVAR_ARCHIVE },
    "Safety cap on how many surfaces a single bullet can tunnel through before it stops for good.")

local TEAM_MODES = { war = true, sesh_war = true, sd = true, sesh_sd = true, sesh_sd_set = true }

local function GetHostPlayer()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsListenServerHost() then return p end
    end
    return nil
end

-- Bots are excluded unconditionally, before any of the host/team logic
-- below even runs -- see the file header for why this is absolute now
-- instead of an opt-in convar like the first attempt had.
local function CanWallbang(ent)
    if not IsValid(ent) or not ent:IsPlayer() or ent:IsBot() then return false end

    local host = GetHostPlayer()
    if not IsValid(host) then return false end
    if ent == host then return true end

    local gm = GetConVar("codhud_selected_gamemode"):GetString()
    if TEAM_MODES[gm] then
        return ent:Team() == host:Team()
    end
    return true -- FFA/other non-team modes: any other real player also qualifies
end

-- Applies wallbang damage to whatever a continuation trace actually landed
-- on, and gives the weapon's own callback a chance to run its normal hit
-- feedback (hitmarker sound, blood/headshot effects, etc.) for this segment
-- exactly as it would for a direct, unobstructed hit.
local function WallbangDamage(attacker, inflictor, victim, tr, dir, damage, force, weaponCallback)
    local dmginfo = DamageInfo()
    dmginfo:SetDamage(damage)
    dmginfo:SetAttacker(attacker)
    dmginfo:SetInflictor(IsValid(inflictor) and inflictor or attacker)
    dmginfo:SetDamageType(DMG_BULLET)
    dmginfo:SetDamagePosition(tr.HitPos)
    dmginfo:SetDamageForce(dir * force)
    victim:TakeDamageInfo(dmginfo) -- still fires EntityTakeDamage normally
    if weaponCallback then weaponCallback(attacker, tr, damage) end
end

-- Continues a bullet's path past an impact point using plain traces instead
-- of re-firing a real shot. Each iteration is one penetration: a wall, a
-- prop, or a player/NPC that gets damaged (via WallbangDamage) and then
-- still gets tunneled through, same as the world does, up to penetrationsLeft.
local function ContinueWallbang(attacker, inflictor, dir, startPos, damage, force, hullSize, remainingDistance, penetrationsLeft, weaponCallback)
    if not IsValid(attacker) then return end

    local pos       = startPos
    local remaining = remainingDistance
    local pen       = penetrationsLeft
    local alreadyHit = { [attacker] = true }

    while pen > 0 and remaining > 1 do
        local traceParams = {
            start  = pos,
            endpos = pos + dir * remaining,
            filter = function(e) return not alreadyHit[e] end,
            mask   = MASK_SHOT,
        }

        local tr
        if hullSize and hullSize > 0 then
            traceParams.mins = Vector(-hullSize, -hullSize, -hullSize)
            traceParams.maxs = Vector(hullSize, hullSize, hullSize)
            tr = util.TraceHull(traceParams)
        else
            tr = util.TraceLine(traceParams)
        end

        if not tr.Hit then break end

        local traveled = pos:Distance(tr.HitPos)
        remaining = remaining - traveled - 1
        pen = pen - 1

        if IsValid(tr.Entity) then
            -- game.GetWorld() is ONE shared entity representing every brush
            -- on the whole map -- marking it "already hit" like a normal
            -- prop/player would make the filter ignore ALL remaining world
            -- geometry for the rest of this loop (one trace would then fly
            -- through every further wall in a single pass), so each wall
            -- still costs its own penetration only if world is never added
            -- here. Stepping 1 unit past the exact hit point already clears
            -- that specific wall's surface, so it still blocks correctly on
            -- the next iteration for the NEXT wall.
            if not tr.Entity:IsWorld() then
                alreadyHit[tr.Entity] = true
            end
            if (tr.Entity:IsPlayer() or tr.Entity:IsNPC()) and tr.Entity:Health() > 0 then
                WallbangDamage(attacker, inflictor, tr.Entity, tr, dir, damage, force, weaponCallback)
            end
        end

        pos = tr.HitPos + dir * 1
    end
end

hook.Add("EntityFireBullets", "KC_WallbangEverything", function(ent, bullet)
    if not GetConVar("kc_wallbang_everything"):GetBool() then return end
    if not CanWallbang(ent) then return end

    local weaponCallback = bullet.Callback
    local dir       = bullet.Dir or ent:GetAimVector()
    local damage    = bullet.Damage or 1
    local force     = bullet.Force or 1
    local distance  = bullet.Distance or 56756 -- engine's own FireBullets default
    local hullSize  = bullet.HullSize or 0
    local attacker  = IsValid(bullet.Attacker) and bullet.Attacker or ent
    local inflictor = bullet.Inflictor
    local maxPen    = GetConVar("kc_wallbang_max_penetrations"):GetInt()

    bullet.Callback = function(att, tr, dmg)
        if weaponCallback then weaponCallback(att, tr, dmg) end
        if not tr.Hit then return end

        -- Use the trace's OWN start/hit points rather than the original Dir --
        -- this pellet may have taken a randomized path through bullet.Spread,
        -- and tunneling has to continue along the path it actually took.
        local actualDir = (tr.HitPos - tr.StartPos)
        if actualDir:Length() < 1 then actualDir = dir else actualDir:Normalize() end

        local traveled  = tr.StartPos:Distance(tr.HitPos)
        local nextStart = tr.HitPos + actualDir * 1
        ContinueWallbang(attacker, inflictor, actualDir, nextStart, damage, force, hullSize,
            distance - traveled - 1, maxPen, weaponCallback)
    end

    return true
end)
