---- [ SERVER: WALLBANG EVERYTHING ] ----
-- Makes every bullet, from every weapon and every shooter (players, bots,
-- NPCs), keep travelling through world geometry and props instead of
-- stopping at the first surface. Works on any map with no per-map setup.
--
-- How it works: GMod calls the EntityFireBullets hook for every bullet any
-- weapon fires, before the engine traces it. We don't touch the original
-- shot at all -- the engine still does its own spread/tracer/damage exactly
-- as normal, and any hit markers/blood/effects a weapon's own bullet.Callback
-- adds still fire untouched (we wrap it, not replace it). We only add one
-- thing: once that original bullet's trace stops (at a wall, a prop, or a
-- player it just damaged), we fire a brand new bullet starting just past
-- that impact point, travelling in the same real direction, for the
-- remaining distance. That new bullet is a completely normal FireBullets
-- call too, so if IT also hits something, the same wrapping makes it thread
-- through again, and again, up to a safety cap.
if not SERVER then return end

-- TEMPORARILY DISABLED ENTIRELY (crash/hang investigation in sesh modes) --
-- bypasses this whole file regardless of any saved kc_wallbang_everything
-- convar value, so it can't matter whether that got archived to a config
-- file at "1" from before. Delete this line to bring the feature back.
if true then return end

CreateConVar("kc_wallbang_everything", "1", { FCVAR_ARCHIVE, FCVAR_NOTIFY },
    "If enabled, bullets penetrate world geometry and props completely instead of stopping at the first surface.")
CreateConVar("kc_wallbang_max_penetrations", "4", { FCVAR_ARCHIVE },
    "Safety cap on how many surfaces a single bullet can tunnel through before it stops for good.")
-- Sesh modes can have 6+ bots all firing at once. Every wallbang bullet that
-- hits something can recursively re-fire up to kc_wallbang_max_penetrations
-- MORE bullets (each a full server-authoritative trace), so applying this to
-- every bot's every shot multiplies the per-shot cost by however many bots
-- are shooting simultaneously. That compounding load, not map geometry or
-- bot pathing (both already ruled out), is the most likely cause of the
-- game becoming unresponsive a few seconds into active combat in sesh
-- modes. Defaulting bots out of it keeps the feature for human players
-- (the actual ask) while removing that multiplier. Set to 1 to re-enable
-- for bots too once this is confirmed stable.
CreateConVar("kc_wallbang_bots", "0", { FCVAR_ARCHIVE },
    "If enabled, bots' own bullets also get wallbang penetration (in addition to players'). Off by default -- see comment above.")

-- weaponCallback is the ORIGINAL shooting weapon's own bullet.Callback (if it
-- had one) -- e.g. TFA Base weapons use this for their own hitmarker sound,
-- blood/headshot effects, damage-type overrides, etc. We call it on every
-- single penetration segment, not just the first impact, so a wallbang kill
-- that only actually lands on the 2nd or 3rd wall still gets the exact same
-- weapon-specific hit feedback as a normal, unobstructed hit would have.
local function FireContinuation(attacker, inflictor, ammoType, dir, startPos, damage, force, hullSize, remainingDistance, penetrationsLeft, ignoreEnt, weaponCallback)
    if not IsValid(attacker) then return end
    if remainingDistance <= 1 or penetrationsLeft <= 0 then return end

    local bullet         = {}
    bullet.KC_Continuation = true -- tells our own hook below to leave this one alone
    bullet.Num            = 1
    bullet.Src            = startPos
    bullet.Dir            = dir
    bullet.Spread         = vector_origin
    bullet.Tracer         = 0
    bullet.Force          = force
    bullet.Damage         = damage
    bullet.AmmoType       = ammoType
    bullet.Distance       = remainingDistance
    bullet.HullSize       = hullSize
    bullet.Attacker       = attacker
    bullet.Inflictor      = IsValid(inflictor) and inflictor or nil
    bullet.IgnoreEntity   = ignoreEnt

    bullet.Callback = function(att, tr, dmg)
        if weaponCallback then weaponCallback(att, tr, dmg) end
        if not tr.Hit then return end
        local actualDir = (tr.HitPos - tr.StartPos)
        if actualDir:Length() < 1 then actualDir = dir else actualDir:Normalize() end
        local traveled = tr.StartPos:Distance(tr.HitPos)
        local nextStart = tr.HitPos + actualDir * 1
        FireContinuation(attacker, inflictor, ammoType, actualDir, nextStart, damage, force, hullSize,
            remainingDistance - traveled - 1, penetrationsLeft - 1, tr.Entity, weaponCallback)
    end

    attacker:FireBullets(bullet)
end

hook.Add("EntityFireBullets", "KC_WallbangEverything", function(ent, bullet)
    if not GetConVar("kc_wallbang_everything"):GetBool() then return end
    if not IsValid(ent) then return end
    if bullet.KC_Continuation then return end -- our own continuation shots skip re-wrapping
    if ent:IsPlayer() and ent:IsBot() and not GetConVar("kc_wallbang_bots"):GetBool() then return end

    local weaponCallback = bullet.Callback
    local dir       = bullet.Dir or ent:GetAimVector()
    local damage    = bullet.Damage or 1
    local force     = bullet.Force or 1
    local distance  = bullet.Distance or 56756 -- engine's own FireBullets default
    local ammoType  = bullet.AmmoType or ""
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
        FireContinuation(attacker, inflictor, ammoType, actualDir, nextStart, damage, force, hullSize,
            distance - traveled - 1, maxPen, tr.Entity, weaponCallback)
    end

    return true
end)
