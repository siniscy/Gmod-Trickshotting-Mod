-- sv_ffa_bots.lua
-- CreateNextBot AI players for sesh_dm (FFA), sesh_war (TDM), sesh_sd (S&D)
-- Bots only join when a sesh gamemode is selected, not on map load.

if not SERVER then return end

-- ================================================================
--  CONFIG
-- ================================================================

-- Vector:GetNormalized() on a zero-length (or extremely close to zero)
-- vector produces NaN components in GMod. Feeding a NaN angle/direction into
-- entity commands (SetEyeAngles, SetViewAngles, movement) is a well-known
-- hard engine crash, not a catchable Lua error -- and in tight, close-
-- quarters maps a bot ending up exactly on top of its target, or two bots'
-- separation forces exactly cancelling out a movement direction, are both
-- realistic ways to hit that zero-length case during normal play. Every
-- GetNormalized() in the bot AI below goes through this guard instead.
local function SafeNormalize(vec, fallback)
    if not vec or vec:Length() < 0.01 then
        return fallback or Vector(1, 0, 0)
    end
    return vec:GetNormalized()
end

local BOT_HEALTH = 50  -- sesh bots' health per life (players have 100)

local BOT_NAMES_POOL ={ "xAlps", "Boolmaster Flex", "reha", "Nythvn", "dread", "sage", "Silverr" }

-- TEMP DIAGNOSTIC for the Backlot hang investigation -- see the pathfinding
-- block below. Remove once the root cause is confirmed.
CreateConVar("kc_disable_bot_pathing", "0", FCVAR_ARCHIVE, "Diagnostic: disable navmesh pathing for sesh bots entirely (they'll just walk straight at their target).")

-- Per-mode bot count convars -- hardwired, no longer menu-adjustable.
CreateConVar("sesh_bot_count_sd",  "2", { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Number of bots in Sesh S&D (0-6)")
CreateConVar("sesh_bot_count_tdm", "6", { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Number of bots in Sesh TDM (0-6)")
CreateConVar("sesh_bot_count_ffa", "6", { FCVAR_ARCHIVE, FCVAR_REPLICATED }, "Number of bots in Sesh FFA (0-7)")

GetConVar("sesh_bot_count_sd"):SetInt(2)
GetConVar("sesh_bot_count_tdm"):SetInt(6)
GetConVar("sesh_bot_count_ffa"):SetInt(6)

-- Stable shuffled names picked once per server session.
-- Random on first call, then fixed for the server's lifetime.
local SessionBotNames = nil

-- Combine soldiers. These MUST be real player models (models/player/...):
-- they carry the shared player animation set (run_smg1, idle_shotgun,
-- aim/move pose parameters), so bots animate and hold weapons exactly like
-- any other player, live and in the killcam replay. The NPC versions
-- (models/combine_soldier.mdl, the bundled CoD4 OpFor models) only have NPC
-- animations and T-pose on a player.
local BOT_MODELS = {
    "models/player/combine_soldier.mdl",
    "models/player/combine_soldier_prisonguard.mdl",
    "models/player/combine_super_soldier.mdl",
}
for _, mdl in ipairs(BOT_MODELS) do util.PrecacheModel(mdl) end

-- Re-applies the bot's model (and its skin variant) -- Spawn() resets both.
local function ApplyBotLook(bot)
    if not bot.SeshBotModel then return end
    bot:SetModel(bot.SeshBotModel)
    bot:SetSkin(bot.SeshBotSkin or 0)
end

-- Opposite factions per HUD type (bots are always the enemy faction)
local HUD_FACTIONS = {
    mw2  = { player = "rangers",  bot = "ussr"    },
    mw3  = { player = "delta",    bot = "ussr"    },
    cod4 = { player = "marines",  bot = "arab"    },
    bo1  = { player = "sog",      bot = "nva"     },
    bo2  = { player = "seals",    bot = "sdc"     },
    waw  = { player = "american", bot = "german"  },
}

-- ================================================================
--  STATE
-- ================================================================
local FFA_Bots        = {}
local FFA_BotPaths    = {}
local FFA_PathUpdateT = {}
local FFA_SpawnGeneration = 0
local FFA_BotNav       = {} -- per-bot navigation / stuck-escalation state (see BOT AI — NAVIGATION)
local FFA_BotStrafeDir   = {}
local FFA_BotStrafeT     = {}
local FFA_BotReactionTarget = {}
local FFA_BotReactionUntil  = {}
local FFA_BotFireState      = {}
local FFA_BotFireStateUntil = {}
local FFA_BotAimAng   = {} -- bot's current (smoothed) eye angle, per bot
local FFA_BotAimLastT = {} -- CurTime() of that bot's last aim update, for frame-rate-independent smoothing
local FFA_BotAimError = {} -- small per-acquisition aim inaccuracy offset, per bot
local FFA_LastKillTarget = nil
local FFA_KillcamBot  = nil
local FFA_Active      = false
FFA_KillcamNPC      = nil
FFA_KillcamDeathPos = nil
FFA_KillcamDeathAng = nil
FFA_KillcamModel    = nil
SeshBot_Active        = false
local FFA_PlayerKills = {}
SeshBot_PlayerKills   = FFA_PlayerKills
local PlayerLoadouts  = {}
_G.PlayerLoadouts     = PlayerLoadouts  -- exposed for killcam_codhud_integration.lua sync

if SERVER then
    util.AddNetworkString("SeshBot_KillcamBotPos")
    util.AddNetworkString("SeshBot_HideKillcamBot")
end

local function GetGM()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv and cv:GetString() or ""
end

local function IsSeshMode()
    local gm = GetGM()
    return gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

local function IsFFA()  return GetGM() == "sesh_dm"  end
local function IsTDM()  return GetGM() == "sesh_war" end
-- "sesh_sd_set" is Gmod Sesh S&D Set -- the same S&D ruleset (round wins,
-- no explosive bullets, hitmarkers, scoring) but with exactly one bot that
-- never moves or fights back on its own. IsSD() covers both so every place
-- that already gates S&D-only behavior (round tracking, friendly-fire
-- blocking, instant-kill) picks it up for free; IsSDSet() is only for the
-- handful of places that need to know it's specifically the idle variant.
local function IsSD()    local gm = GetGM(); return gm == "sesh_sd" or gm == "sesh_sd_set" end
local function IsSDSet() return GetGM() == "sesh_sd_set" end

local function GetBotNames()
    local count
    if IsFFA() then
        local cv = GetConVar("sesh_bot_count_ffa")
        count = math.Clamp(cv and cv:GetInt() or 2, 0, 7)
    elseif IsTDM() then
        local cv = GetConVar("sesh_bot_count_tdm")
        count = math.Clamp(cv and cv:GetInt() or 2, 0, 6)
    elseif IsSDSet() then
        -- Gmod Sesh S&D Set is always exactly one idle bot, regardless of
        -- the shared sesh_bot_count_sd convar.
        count = 1
    else
        local cv = GetConVar("sesh_bot_count_sd")
        count = math.Clamp(cv and cv:GetInt() or 2, 0, 6)
    end
    count = math.min(count, #BOT_NAMES_POOL)

    -- Pick random order once per server session, then reuse every round
    if not SessionBotNames then
        local pool = table.Copy(BOT_NAMES_POOL)
        SessionBotNames = {}
        while #pool > 0 do
            local idx = math.random(#pool)
            table.insert(SessionBotNames, pool[idx])
            table.remove(pool, idx)
        end
    end

    local result = {}
    for i = 1, count do
        result[i] = SessionBotNames[i]
    end
    return result
end

local function GetScoreLimit()
    local cv = GetConVar("codhud_score_limit")
    local v = cv and cv:GetInt() or 75
    return v > 0 and v or 75
end

local function GetHUDType()
    local cv = GetConVar("codhud_game")
    return cv and cv:GetString() or "mw2"
end

-- Sesh FFA has its own hardwired kill limit, independent of codhud_score_limit
-- (which remains the TDM limit): 30 kills normally, 25 for the cod4 HUD.
local function GetFFALimit()
    return (GetHUDType() == "cod4") and 25 or 30
end
_G.CoDHUD_GetFFALimit = GetFFALimit

local function GetBotFaction()
    local factions = HUD_FACTIONS[GetHUDType()]
    return factions and factions.bot or "opfor"
end

local function GetPlayerFaction()
    local factions = HUD_FACTIONS[GetHUDType()]
    return factions and factions.player or "rangers"
end

-- ================================================================
--  FINAL KILL DISTANCE CALLOUT
--  Broadcasts a one-off "<killer> killed <victim> from X ft" line for the
--  single kill that actually ends the round (S&D) or the match (TDM/FFA).
--  Distance is a static snapshot taken at the moment of the kill -- the
--  shooter's position then (GetShootPos, hitscan so this IS effectively
--  where the bullet was fired from) to the victim's position when they died.
-- ================================================================
util.AddNetworkString("KC_FinalKillDistance")

local function BroadcastFinalKillDistance(attacker, victim)
    if not IsValid(attacker) or not IsValid(victim) then
        print("[KC] FinalKillDistance skipped -- invalid attacker/victim")
        return
    end
    local dist = attacker:GetShootPos():Distance(victim:GetPos())
    -- Source engine units are inches (1 unit = 1 inch) -- convert to real meters.
    local meters = math.Round(dist * 0.0254)
    print("[KC] FinalKillDistance: " .. attacker:Nick() .. " -> " .. victim:Nick() .. " (" .. meters .. " m)")
    net.Start("KC_FinalKillDistance")
        net.WriteEntity(attacker)
        net.WriteEntity(victim)
        net.WriteUInt(meters, 16)
    net.Broadcast()
end

-- ================================================================
--  NAVMESH
-- ================================================================
local navAreas = nil

local function CheckAndGenerateNav()
    local areas = navmesh.GetAllNavAreas()
    -- At InitPostEntity the map's saved .nav isn't loaded yet, which made
    -- every map load regenerate a navmesh it already had. Load it first.
    if (not areas or #areas == 0) and navmesh.Load then
        navmesh.Load()
        areas = navmesh.GetAllNavAreas()
    end
    if areas and #areas > 0 then
        navAreas = areas
        print("[Sesh Bots] Navmesh ready (" .. #areas .. " areas).")
    else
        print("[Sesh Bots] No navmesh. Generating...")
        navmesh.BeginGeneration()
        timer.Create("SeshBot_NavWait", 2, 0, function()
            if not navmesh.IsGenerating() then
                timer.Remove("SeshBot_NavWait")
                navAreas = navmesh.GetAllNavAreas()
                print("[Sesh Bots] Navmesh ready (" .. #navAreas .. " areas).")
            end
        end)
    end
end

-- The CoD map collision fix (coll_fix addon) builds its maps' navmesh in Lua
-- and can rebuild it mid-session (cod_nav_generate); re-read the areas then.
hook.Add("NavBuild_Done", "SeshBot_NavRebuilt", function()
    navAreas = navmesh.GetAllNavAreas()
    print("[Sesh Bots] Navmesh rebuilt (" .. #navAreas .. " areas).")
end)

-- Most maps used with Gmod Sesh only carry ONE actual info_player_* entity
-- (confirmed on the maps causing "everyone spawns in the same spot" -- see
-- [KC Debug][NavInfo] logs from testing: spawnEnts=1 even on a map with a
-- large, healthy 1654-area navmesh), since they were never built with a
-- multiplayer deathmatch in mind. Relying on that single entity means every
-- spawn AND every respawn keeps landing in the same square meter regardless
-- of how much usable floor space the nav mesh says actually exists. This
-- ignores map spawn entities entirely and picks a fresh random point
-- anywhere on the nav mesh instead, so the "only one spawn" limitation
-- never applies in the first place.
-- The engine loads the map's saved .nav again after InitPostEntity, which frees
-- the areas CheckAndGenerateNav read (the cached handles turn NULL); a rebuild
-- does the same. Calling a NULL area throws, and a throw inside a PlayerSpawn
-- hook aborts the gamemode's PlayerSpawn, which is what creates the player's
-- hands. Always pick areas through here. If nothing is loaded right now the old
-- list is kept, so the next call simply re-reads it.
local function RandomNavArea()
    if not navAreas or #navAreas == 0 then return nil end
    local area = navAreas[math.random(#navAreas)]
    if IsValid(area) then return area end
    local fresh = navmesh.GetAllNavAreas()
    if #fresh == 0 then return nil end
    navAreas = fresh
    return navAreas[math.random(#navAreas)]
end

local function GetRandomNavPoint()
    local area = RandomNavArea()
    if area then
        return area:GetRandomPoint() + Vector(0, 0, 10), Angle(0, math.random(0, 360), 0)
    end
    -- No navmesh yet (still generating, or generation failed) -- fall back
    -- to whatever map spawn entities exist rather than leaving the player
    -- at the world origin.
    return nil, nil
end

-- ================================================================
--  SPAWN POSITIONS
-- ================================================================
local function CollectSpawns()
    local spawns = {}
    for _, cls in ipairs({"info_player_start","info_player_deathmatch",
                          "info_player_counterterrorist","info_player_terrorist"}) do
        for _, e in ipairs(ents.FindByClass(cls)) do
            table.insert(spawns, e:GetPos())
        end
    end
    for i = #spawns, 2, -1 do
        local j = math.random(i)
        spawns[i], spawns[j] = spawns[j], spawns[i]
    end
    return spawns
end

local function GetSpawnFarFrom(existing, minDist)
    local spawns = CollectSpawns()
    if #spawns == 0 then
        -- No map spawn entities found at all -- without this, the offset
        -- below was measured from the world origin (0,0,0) instead of the
        -- player, which could drop a bot right on top of the host on any
        -- map whose origin happens to sit near where players actually are.
        local ang = math.random(0,360)
        local center = existing[1] or Vector(0, 0, 0)
        local pos = center + Vector(math.cos(math.rad(ang))*minDist, math.sin(math.rad(ang))*minDist, 64)
        local tr = util.TraceLine({
            start  = pos + Vector(0, 0, 256),
            endpos = pos - Vector(0, 0, 1024),
            mask   = MASK_SOLID_BRUSHONLY
        })
        if tr.Hit then pos = tr.HitPos + Vector(0, 0, 8) end
        return pos, Angle(0, math.random(0,360), 0)
    end
    for _, sp in ipairs(spawns) do
        local ok = true
        for _, ep in ipairs(existing) do
            if sp:Distance(ep) < minDist then ok = false break end
        end
        if ok then
            return sp + Vector(math.random(-80,80), math.random(-80,80), 0),
                   Angle(0, math.random(0,360), 0)
        end
    end
    -- Fallback: pick the spawn farthest from all existing positions
    local best, bestD = spawns[1], 0
    for _, sp in ipairs(spawns) do
        local minD = math.huge
        for _, ep in ipairs(existing) do
            local d = sp:Distance(ep)
            if d < minD then minD = d end
        end
        if minD > bestD then bestD = minD best = sp end
    end
    -- Guarantee minimum separation: if the best spawn is still too close,
    -- push it away from the nearest existing position by minDist.
    if bestD < minDist and #existing > 0 then
        local nearest, nearestD = existing[1], best:Distance(existing[1])
        for _, ep in ipairs(existing) do
            local d = best:Distance(ep)
            if d < nearestD then nearestD = d nearest = ep end
        end
        local dir = (best - nearest)
        if dir:Length() < 1 then
            -- Same position — pick a random direction
            local ang = math.random(0,360)
            dir = Vector(math.cos(math.rad(ang)), math.sin(math.rad(ang)), 0)
        else
            dir = dir:GetNormalized()
        end
        local pushed = nearest + dir * minDist
        -- Trace down from above to find solid ground at the pushed position
        local tr = util.TraceLine({
            start  = pushed + Vector(0, 0, 256),
            endpos = pushed - Vector(0, 0, 1024),
            mask   = MASK_SOLID_BRUSHONLY
        })
        if tr.Hit then
            best = tr.HitPos + Vector(0, 0, 8)
        else
            -- No ground found — fall back to the original best spawn
            best = spawns[1]
            for _, sp in ipairs(spawns) do
                local minD = math.huge
                for _, ep in ipairs(existing) do
                    local d = sp:Distance(ep)
                    if d < minD then minD = d end
                end
                if minD > best:Distance(existing[1] or sp) then best = sp end
            end
        end
    end
    return best, Angle(0, math.random(0,360), 0)
end

-- ================================================================
--  LOADOUT SAVE / RESTORE
-- ================================================================
local function SaveLoadout(ply)
    local weps = {}
    for _, w in ipairs(ply:GetWeapons()) do table.insert(weps, w:GetClass()) end
    -- Never let a spurious empty read (e.g. called again slightly after the
    -- player already died) overwrite a real loadout saved moments earlier.
    local existing = PlayerLoadouts[ply:UserID()]
    if #weps == 0 and existing and existing.weapons and #existing.weapons > 0 then
        print("[KC Loadout] SaveLoadout(" .. ply:Nick() .. ") skipped empty read, kept existing: " .. table.concat(existing.weapons, ", "))
        return
    end
    local active = IsValid(ply:GetActiveWeapon()) and ply:GetActiveWeapon():GetClass() or nil
    PlayerLoadouts[ply:UserID()] = {
        weapons = weps,
        active  = active,
    }
    print("[KC Loadout] SaveLoadout(" .. ply:Nick() .. "): " .. table.concat(weps, ", ") .. " (active=" .. tostring(active) .. ")")
    -- Also sync to SD_SavedWeapons so RestorePlayerWeapons in
    -- killcam_codhud_integration.lua uses the same up-to-date data.
    if _G.SD_SavedWeapons then
        _G.SD_SavedWeapons[ply:UserID()] = weps
        _G.SD_SavedWeapons[ply:UserID()].active = active
    end
end

local function RestoreLoadout(ply)
    local data = PlayerLoadouts[ply:UserID()]
    if not data then
        print("[KC Loadout] RestoreLoadout(" .. ply:Nick() .. "): no saved loadout")
        return
    end
    print("[KC Loadout] RestoreLoadout(" .. ply:Nick() .. "): " .. table.concat(data.weapons, ", ") .. " (active=" .. tostring(data.active) .. ")")
    ply:StripWeapons()
    for _, cls in ipairs(data.weapons) do ply:Give(cls) end
    if data.active then ply:SelectWeapon(data.active) end
end

-- Exposed so sv_roundend.lua can restore weapons after the round countdown ends
_G.SeshBot_RestoreLoadoutForPlayer = function(ply)
    RestoreLoadout(ply)
end

hook.Add("PlayerSpawn", "SeshBot_RestoreLoadout", function(ply)
    if not IsSeshMode() then return end
    if ply:IsBot() then
        ApplyBotLook(ply)
        -- Fresh life, fresh navigation: no stale path/stuck state from where it died.
        FFA_BotNav[ply] = nil
        if FFA_BotPaths[ply] then FFA_BotPaths[ply] = { waypoints = {}, currentWaypoint = 1 } end
        FFA_PathUpdateT[ply] = 0
        -- Re-assert the bot's faction the instant it spawns, on top of the
        -- 1-second SeshBot_FactionSync tick -- a generic, mode-unaware
        -- faction-assignment system elsewhere (round-start autobalance, HUD
        -- skin change) can otherwise briefly tag a bot with the player's own
        -- faction, merging both teams into one on the scoreboard and making
        -- the S&D round bar unable to find a distinct enemy score to show.
        ply:SetNW2String("CoDHUD_Faction", GetBotFaction())
        -- Half the normal 100 health, so bot-vs-bot fights end quicker.
        -- Next tick: the gamemode's own spawn code runs after this hook and
        -- would put it back to 100.
        timer.Simple(0, function()
            if not IsValid(ply) or not ply:Alive() then return end
            ply:SetMaxHealth(BOT_HEALTH)
            ply:SetHealth(BOT_HEALTH)
        end)
        return
    end

    -- Ignore the map's own (usually singular) spawn entity entirely and
    -- drop the human somewhere random on the nav mesh instead, every single
    -- spawn -- including every respawn after death, since this hook fires
    -- again each time. Delayed one tick: SetPos in the same tick as the
    -- engine's own default spawn placement doesn't reliably stick (same
    -- reasoning as SpawnBot()'s bot positioning below).
    local pos, ang = GetRandomNavPoint()
    if pos then
        timer.Simple(0, function()
            if not IsValid(ply) or not ply:Alive() then return end
            ply:SetPos(pos)
            ply:SetEyeAngles(ang)
        end)
    end
    -- Player weapon restore is handled in PlayerLoadout below
end)

-- PlayerSpawn hooks run BEFORE the gamemode's own PlayerSpawn, whose
-- PlayerSetModel would then put the bot back in the default (cl_playermodel)
-- model on any spawn this file doesn't re-apply the look after (e.g. the
-- round reset's p:Spawn()). Claiming PlayerSetModel for sesh bots stops that.
hook.Add("PlayerSetModel", "SeshBot_SetModel", function(ply)
    if not ply:IsBot() or not ply.SeshBotModel then return end
    if not IsSeshMode() then return end
    ApplyBotLook(ply)
    return true
end)

-- Main loadout hook — fires after PlayerSpawn.
-- Bots get random SMG or shotgun. Players get their saved loadout if they
-- have one, or nothing on first spawn (they pick their own weapons in-game).
-- NOTE: we intentionally do NOT gate on CoDHUD_RoundStarting for players —
-- RestorePlayerWeapons in SpawnPlayerAtSpawn needs this to fire correctly.
hook.Add("PlayerLoadout", "SeshBot_LoadoutOverride", function(ply)
    -- TEMP DIAGNOSTIC -- unconditional entry log, paired with the same kind
    -- of log at the top of KC_Loadouts_Give's closure in
    -- lua/codhud/sv_loadouts_give.lua, to compare which PlayerLoadout hooks
    -- actually get invoked (and in what order) for a real spawn.
    do
        local msg = string.format("[KC Class][ENTRY-FFA] SeshBot_LoadoutOverride invoked, ply=%s isBot=%s", tostring(ply), tostring(IsValid(ply) and ply:IsBot()))
        if _G.KC_ClassLog then _G.KC_ClassLog(msg) else print(msg) end
    end
    if not IsSeshMode() then return end

    -- A Create-a-Class pick (lua/codhud/sv_loadouts_give.lua) takes priority
    -- over this FFA saved-loadout restore for real players. This used to be
    -- enforced by registering that hook at HOOK_HIGH so it would always run
    -- first and short-circuit this one -- but HOOK_HIGH (and every other
    -- named hook-priority constant: HOOK_MONITOR_HIGH, HOOK_NORMAL, HOOK_LOW,
    -- HOOK_MONITOR_LOW) turned out to be nil in this environment, so the
    -- "priority" argument was silently being passed as nil the whole time
    -- and both hooks actually ran at the same (default) priority. Since this
    -- file's hook.Add call happened to register before sv_loadouts_give.lua's,
    -- this hook always won the race and swallowed every class pick before
    -- KC_Loadouts_Give ever got a chance to run. Checking the player's raw
    -- convar directly here (instead of relying on hook order at all) is
    -- immune to that ordering issue.
    if not ply:IsBot() then
        local kcMode = ply:GetInfo("kc_loadout_mode")
        if kcMode ~= "" and kcMode ~= "none" then
            local msg = string.format("[KC Class][FFA-skip] PlayerLoadout(%s): kc_loadout_mode=%q is active, letting KC_Loadouts_Give handle this spawn", ply:Nick(), kcMode)
            if _G.KC_ClassLog then _G.KC_ClassLog(msg) else print(msg) end
            return
        end
    end

    if ply:IsBot() then
        -- Skip during countdown — bots are armed by SeshBot_RevealAfterCountdown
        if CoDHUD_RoundStarting then return end
        ply:StripWeapons()
        local useSmg = math.random(2) == 1
        if useSmg then
            ply:Give("weapon_smg1")
            ply:GiveAmmo(256, "SMG1", true)
            ply:SelectWeapon("weapon_smg1")
        else
            ply:Give("weapon_shotgun")
            ply:GiveAmmo(32, "Buckshot", true)
            ply:SelectWeapon("weapon_shotgun")
        end
        return true
    end

    -- Real player: restore saved loadout if they have one
    -- TEMP DIAGNOSTIC -- this only runs when KC_Loadouts_Give (HOOK_HIGH,
    -- sv_loadouts_give.lua) returned nil, i.e. the player's class picked
    -- "None" or their class didn't resolve to any installed weapon. If
    -- you're seeing this print for a player who actually picked a class,
    -- the class system itself is the thing failing, not this fallback.
    local ffaFallbackMsg = string.format("[KC Class][FFA-fallback] PlayerLoadout(%s): KC class hook fell through, using FFA saved-loadout restore", ply:Nick())
    if _G.KC_ClassLog then _G.KC_ClassLog(ffaFallbackMsg) else print(ffaFallbackMsg) end
    local data = PlayerLoadouts[ply:UserID()]
    if not data or not data.weapons or #data.weapons == 0 then
        -- First spawn — give nothing, let them pick their own loadout
        print("[KC Loadout] PlayerLoadout(" .. ply:Nick() .. "): no saved loadout, giving nothing")
        ply:StripWeapons()
        return true
    end

    -- Restore saved loadout
    print("[KC Loadout] PlayerLoadout(" .. ply:Nick() .. "): restoring " .. table.concat(data.weapons, ", ") .. " (active=" .. tostring(data.active) .. ")")
    ply:StripWeapons()
    for _, cls in ipairs(data.weapons) do
        ply:Give(cls)
    end
    if data.active then ply:SelectWeapon(data.active) end
    return true
end)

hook.Add("PlayerDeath", "SeshBot_SaveLoadout", function(ply)
    if not IsSeshMode() then return end
    if ply:IsBot() then return end
    SaveLoadout(ply)
end)

-- ================================================================
--  REMOVE BOTS
-- ================================================================
local function RemoveAllBots()
    print("[Sesh Bots] All bots removed.")
    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) then bot:Kick("Kicked from server") end
    end
    FFA_Bots        = {}
    FFA_BotPaths    = {}
    FFA_PathUpdateT = {}
    FFA_BotNav          = {}
    FFA_BotStrafeDir    = {}
    FFA_BotStrafeT      = {}
    FFA_BotReactionTarget = {}
    FFA_BotReactionUntil  = {}
    FFA_BotFireState      = {}
    FFA_BotFireStateUntil = {}
    FFA_BotAimAng   = {}
    FFA_BotAimLastT = {}
    FFA_BotAimError = {}
    FFA_Active      = false
    FFA_KillcamBot  = nil
    FFA_LastKillTarget = nil
    FFA_PlayerKills = {}
    SeshBot_PlayerKills = FFA_PlayerKills
    _G.SeshBot_KillcamIDLocked = false
    _G.SeshBot_KillcamTriggered = false
                _G.SeshBot_LastRoundEndVictim = nil
    if IsValid(FFA_KillcamNPC) then FFA_KillcamNPC:Remove() end
    FFA_KillcamNPC      = nil
    FFA_KillcamDeathPos = nil
    FFA_KillcamDeathAng = nil
    FFA_KillcamModel    = nil
end

-- ================================================================
--  SPAWN BOT
-- ================================================================
local function SpawnBot(name, pos, ang)
    local bot = player.CreateNextBot(name)
    if not IsValid(bot) then
        print("[Sesh Bots] Failed to create: " .. name)
        return nil
    end

    local model = BOT_MODELS[ math.random(#BOT_MODELS) ]
    bot.SeshBotModel = model

    -- TDM/SD: bots are on team 2 (enemy). FFA: team 1.
    bot:SetTeam(IsFFA() and 1 or 2)
    bot:Spawn()
    bot:SetPos(pos)
    bot:SetEyeAngles(ang)
    bot:SetModel(model)
    -- Random skin variant (e.g. the orange-eyed shotgunner), kept for life.
    bot.SeshBotSkin = math.random(0, math.max(bot:SkinCount() - 1, 0))
    ApplyBotLook(bot)
    -- A freshly created bot's Frags isn't guaranteed to start at 0 (reused
    -- player slots can carry over a stale value), so force a clean start.
    bot:SetFrags(0)
    bot:SetDeaths(0)

    local useSmg = math.random(2) == 1
    if useSmg then
        bot:Give("weapon_smg1")
        bot:GiveAmmo(256, "SMG1", true)
        bot:SelectWeapon("weapon_smg1")
    else
        bot:Give("weapon_shotgun")
        bot:GiveAmmo(32, "Buckshot", true)
        bot:SelectWeapon("weapon_shotgun")
    end

    -- If spawning during the round countdown, disarm the bot and mark it
    -- as pending — it will be re-armed by SeshBot_RevealAfterCountdown.
    if CoDHUD_RoundStarting then
        bot:StripWeapons()
        bot.KC_PendingRoundStart = true
    end

    FFA_Bots[bot]        = { kills = 0 }
    FFA_BotPaths[bot]    = { waypoints = {}, currentWaypoint = 1 }
    FFA_PathUpdateT[bot] = 0

    -- Assign bot to ENEMY faction so CoDHUD scoreboard shows them on the right team
    bot:SetNW2String("CoDHUD_Faction", GetBotFaction())

    if Killcam and Killcam.RegisterBotForRecording then
        Killcam.RegisterBotForRecording(bot)
    end

    print("[Sesh Bots] Spawned: " .. name)
    return bot
end

local function GetNavSpawnFarFrom(existing, minDist, ply)
    -- CoD-style spawns (lua/codhud/sv_spawns.lua): never inside anyone,
    -- bots near their own team, far from the enemy team (everyone in FFA).
    if KC_Spawns and KC_Spawns.Enabled() then
        return KC_Spawns.Pick(ply, { team = (not IsValid(ply)) and GetBotFaction() or nil })
    end
    if not navAreas or #navAreas == 0 then
        return GetSpawnFarFrom(existing, minDist)
    end
    -- area:GetRandomPoint() instead of area:GetCenter() -- GetCenter() is a
    -- single fixed point per area, so repeatedly picking the same (or a
    -- small handful of) areas always lands on the exact same spot.
    -- GetRandomPoint() samples a fresh point inside the area every call, so
    -- spawns actually spread out across the mesh instead of clustering.
    local bestPos, bestAng, bestD = nil, nil, -1
    for attempt = 1, 30 do
        local area = RandomNavArea()
        if not area then break end
        local pos  = area:GetRandomPoint()
        local minD = math.huge
        for _, ep in ipairs(existing) do
            local d = pos:Distance(ep)
            if d < minD then minD = d end
        end
        if minD >= minDist then
            return pos + Vector(0, 0, 10), Angle(0, math.random(0, 360), 0)
        end
        if minD > bestD then
            bestD, bestPos, bestAng = minD, pos, Angle(0, math.random(0, 360), 0)
        end
    end
    if not bestPos then return GetSpawnFarFrom(existing, minDist) end
    return bestPos + Vector(0, 0, 10), bestAng
end

local function SpawnAllBots()
    if FFA_Active then return end
    if not IsSeshMode() then return end
    if _G.SeshBot_ShowingScoreboard then return end
    if not navAreas or #navAreas == 0 then
        print("[Sesh Bots] No navmesh yet — waiting.")
        -- The match can start while the navmesh is still being built (a map's
        -- first load): bring the bots in as soon as it's ready, for up to 2 minutes.
        if not timer.Exists("SeshBot_SpawnWhenNavReady") then
            timer.Create("SeshBot_SpawnWhenNavReady", 2, 60, function()
                if FFA_Active or not IsSeshMode() then
                    timer.Remove("SeshBot_SpawnWhenNavReady")
                elseif navAreas and #navAreas > 0 then
                    timer.Remove("SeshBot_SpawnWhenNavReady")
                    SpawnAllBots()
                end
            end)
        end
        return
    end

    RemoveAllBots()
    FFA_Active = true
    SeshBot_Active = true

    -- Reset team scores for new round
    if _G.SeshTeam then _G.SeshTeam.Reset() end

    -- Assign player to their faction
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then
            p:SetTeam(1)
            p:SetNW2String("CoDHUD_Faction", GetPlayerFaction())
        end
    end

    local names = GetBotNames()
    print("[Sesh Bots] Spawning " .. #names .. " bots for " .. GetGM())

    local existing = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and not ply:IsBot() then
            table.insert(existing, ply:GetPos())
        end
    end

    -- Spawn bots one at a time, staggered a fraction of a second apart,
    -- instead of all in the same server tick. All 6 bots' worth of
    -- PlayerSpawn/PlayerLoadout hooks -- this addon's AND every other
    -- installed weapon addon's -- firing in the exact same instant is a
    -- real, repeatable trigger for the game becoming unresponsive right as
    -- sesh mode starts (confirmed to happen even with this addon's own bot
    -- pathing disabled entirely, and on maps that were otherwise stable).
    -- Staggering keeps each tick's workload to one bot's worth, regardless
    -- of whose hook is actually expensive.
    local mySpawnGen = FFA_SpawnGeneration + 1
    FFA_SpawnGeneration = mySpawnGen

    -- DIAGNOSTIC: widened 0.15 -> 1.5 to test whether creating a new
    -- NextBot before the previous one finishes initializing on its own
    -- separate (much slower, ~10Hz) tick scheduler is what's re-triggering
    -- the previous bot's spawn/loadout cycle and killing it -- every test
    -- so far shows the previous bot dying at the exact moment the next one
    -- is created, regardless of where either one is positioned, which rules
    -- out spawn location as the cause entirely.
    for i, name in ipairs(names) do
        timer.Simple((i - 1) * 1.5, function()
            -- Bail if a newer SpawnAllBots call superseded this one (e.g. a
            -- fast round restart) or sesh mode ended mid-stagger.
            if FFA_SpawnGeneration ~= mySpawnGen then return end
            if not IsSeshMode() then return end

            local pos, ang
            if IsFFA() then
                pos, ang = GetNavSpawnFarFrom(existing, 600)
            else
                -- TDM/S&D: keep bots well clear of the host on the very
                -- first spawn of the match so round 1 doesn't drop one
                -- right next to the player for an instant death. Nav-based
                -- like FFA now, instead of the map's own spawn entities --
                -- most Gmod Sesh maps only have one such entity, so that
                -- path always funneled everyone to the same spot regardless
                -- of distance requested.
                pos, ang = GetNavSpawnFarFrom(existing, 1400)
            end
            local bot = SpawnBot(name, pos, ang)
            if IsValid(bot) then
                table.insert(existing, pos)
            end

            -- Re-broadcast team scores once the LAST bot is in, now that all
            -- bots have factions set, so KC_SD_MatchScores on the client has
            -- both faction keys from round 1.
            if i == #names and _G.SeshTeam then
                timer.Simple(0.2, function()
                    if _G.SeshTeam.BroadcastScores then _G.SeshTeam.BroadcastScores() end
                end)
            end
        end)
    end
end

-- ================================================================
--  ROUND START → SPAWN BOTS
-- ================================================================
local SeshBot_WasStarting = false
local SeshBot_DebugTimer = 0

hook.Add("Think", "SeshBot_WaitForRoundStart", function()
    if not IsSeshMode() then return end
    if FFA_Active then return end

    local starting = CoDHUD_RoundStarting and true or false

    if CurTime() > SeshBot_DebugTimer then
        SeshBot_DebugTimer = CurTime() + 2
        print("[Sesh Bots] WaitForRoundStart: RoundStarting=" .. tostring(CoDHUD_RoundStarting) .. " WasStarting=" .. tostring(SeshBot_WasStarting) .. " FFA_Active=" .. tostring(FFA_Active))
    end

    if SeshBot_WasStarting and not starting then
        SeshBot_WasStarting = false
        print("[Sesh Bots] Countdown ended — spawning bots")
        SpawnAllBots()
        return
    end

    SeshBot_WasStarting = starting
end)

hook.Add("CoDHUD_GamemodeChanged", "SeshBot_GamemodeChanged", function(gm)
    if gm ~= "sesh_dm" and gm ~= "sesh_war" and gm ~= "sesh_sd" and gm ~= "sesh_sd_set" then
        RemoveAllBots()
    end
end)

hook.Add("PlayerShouldTakeDamage", "SeshBot_BotDamage", function(target, attacker)
    if not IsFFA() then return end
    if not IsValid(attacker) then return end
    if attacker == target then return end
    return true
end)

-- In TDM/SD: block bot-vs-bot damage using EntityTakeDamage where GetAttacker() is reliable
hook.Add("EntityTakeDamage", "SeshBot_BlockFriendlyFire", function(target, dmginfo)
    if not IsTDM() and not IsSD() then return end
    if not FFA_Active then return end
    if not target:IsPlayer() or not target:IsBot() then return end
    if not FFA_Bots[target] then return end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or not attacker:IsBot() then return end
    -- Bot attacking another bot — block it
    dmginfo:SetDamage(0)
end)

hook.Add("EntityTakeDamage", "SeshBot_InstantKill", function(target, dmginfo)
    if not IsSeshMode() then return end
    if not FFA_Active then return end
    if not target:IsPlayer() or not target:IsBot() then return end
    if not FFA_Bots[target] then return end
    local attacker = dmginfo:GetAttacker()
    if not IsValid(attacker) or not attacker:IsPlayer() or attacker:IsBot() then return end
    dmginfo:SetDamage(target:Health() + 100)
end)

-- FFA bots correctly path toward the only human target and stay near it --
-- normal deathmatch behavior. With spawn positions now confirmed spread out
-- across the nav mesh (real combat/kills happen fine in testing), the
-- remaining "stuck inside each other" cases are bots that have had time to
-- converge on the player (or each other) before the last few in the spawn
-- batch join, physically overlapping -- which Source resolves by force-
-- killing the intruder (self-attributed death, no normal damage event).
-- Disabling solid player-vs-player collision during sesh mode lets them
-- overlap freely instead, the same trick most DM gamemodes use so players
-- don't block each other in doorways/chokepoints.
--
-- NOTE: this hook is only consulted for entities with SetCustomCollisionCheck
-- enabled, and nothing enables it -- so it never actually runs. Do NOT enable
-- it on bots to make them pass through each other: Source applies the same
-- rule to the shooter's bullet traces, so bots' bullets then pass straight
-- through other bots too (bot-vs-bot kills stop happening entirely).
hook.Add("ShouldCollide", "SeshBot_NoPlayerCollide", function(ent1, ent2)
    if not IsSeshMode() then return end
    if IsValid(ent1) and IsValid(ent2) and ent1:IsPlayer() and ent2:IsPlayer() then
        return false
    end
end)

-- ================================================================
--  NAVMESH / MAP LOAD
-- ================================================================
hook.Add("InitPostEntity", "SeshBot_MapLoad", function()
    FFA_KillcamBot      = nil
    FFA_LastKillTarget  = nil
    KC_BotKillID_Server = nil
    CheckAndGenerateNav()
end)

-- ================================================================
--  BOT AI — NAVIGATION
-- ================================================================
-- Why bots used to get stuck for good:
--   * Waypoints were nav area CENTERS. Walking center-to-center cuts
--     diagonally across corners and door frames, straight into walls.
--   * The BFS ignored distance and height, so it happily routed bots up
--     ledges no player can climb and through needlessly long detours, and
--     on bigger maps it hit its node cap and returned no path at all --
--     leaving the bot walking straight at its target through the wall.
--   * Waypoint arrival needed a 3D distance under 80 to the center, which
--     some areas (stairs, centers under props) can never satisfy.
--   * Unsticking was always the same 0.75s jump+strafe followed by the
--     exact same path back into the same wall, forever.
--
-- Now: A* (distance + climb/crouch costs, unclimbable connections
-- skipped, falls back to the closest reachable area), waypoints are the
-- doorway crossing points between consecutive areas (nav areas are convex,
-- so straight lines between crossings stay on walkable floor), arrival is
-- "entered the next area", local jump/crouch/steer around props, and a
-- stuck detector that escalates: back off -> route around the blocked
-- area -> wander somewhere else -> (last resort, never in sight of a
-- human) hop to a free spot on its path.
local NAV_CLIMB_LIMIT   = 58   -- tallest connection a player can get up (crouch-jump)
local NAV_DOOR_MARGIN   = 20   -- keep the 32-wide player hull off door frames
local MAX_ASTAR_VISITED = 3000
local NAV_CROUCH = NAV_MESH_CROUCH or 1
local NAV_JUMP   = NAV_MESH_JUMP   or 2
local NAV_AVOID  = NAV_MESH_AVOID  or 128

-- Plain bitmask test on the area's attribute flags.
local function HasNavAttr(area, flag)
    return bit.band(area:GetAttributes() or 0, flag) ~= 0
end

local cv_navDebug =CreateConVar("kc_bot_nav_debug", "0", FCVAR_NONE, "Print sesh bot navigation decisions (jumps, ducks, stuck escalation).")
local function NavDebug(bot, fmt, ...)
    if not cv_navDebug:GetBool() then return end
    print(string.format("[Sesh Bots][Nav] %s: " .. fmt, bot:Nick(), ...))
end

local function GetBotNav(bot)
    local nav = FFA_BotNav[bot]
    if not nav then
        nav = { avoid = {}, level = 0, side = (math.random(2) == 1) and 1 or -1 }
        FFA_BotNav[bot] = nav
    end
    return nav
end

local function HeapPush(h, f, v)
    local n = #h + 1
    h[n] = { f, v }
    while n > 1 do
        local p = math.floor(n / 2)
        if h[p][1] <= h[n][1] then break end
        h[p], h[n] = h[n], h[p]
        n = p
    end
end

local function HeapPop(h)
    local top = h[1]
    local last = table.remove(h)
    local size = #h
    if size > 0 then
        h[1] = last
        local n = 1
        while true do
            local l, r, m = n * 2, n * 2 + 1, n
            if l <= size and h[l][1] < h[m][1] then m = l end
            if r <= size and h[r][1] < h[m][1] then m = r end
            if m == n then break end
            h[m], h[n] = h[n], h[m]
            n = m
        end
    end
    return top[2]
end

-- Returns a list of areas from startArea toward goalArea. If the goal can't
-- be reached (or the search cap is hit), returns the path to the closest
-- area it could reach instead of nothing, so the bot still makes progress.
local function FindAreaPath(startArea, goalArea, avoid)
    if startArea == goalArea then return { startArea } end
    local now   = CurTime()
    local goalC = goalArea:GetCenter()
    local g, came, closed, open = { [startArea] = 0 }, { [startArea] = false }, {}, {}
    local best, bestH = startArea, startArea:GetCenter():Distance(goalC)
    HeapPush(open, bestH, startArea)

    local visited, found = 0, nil
    while #open > 0 do
        local cur = HeapPop(open)
        if not closed[cur] then
            closed[cur] = true
            if cur == goalArea then found = cur break end
            visited = visited + 1
            if visited > MAX_ASTAR_VISITED then break end
            local curC, curG = cur:GetCenter(), g[cur]
            for _, adj in ipairs(cur:GetAdjacentAreas()) do
                if not closed[adj] and not ((avoid[adj] or 0) > now) then
                    local rise = cur:ComputeAdjacentConnectionHeightChange(adj)
                    if rise <= NAV_CLIMB_LIMIT then
                        local adjC = adj:GetCenter()
                        local cost = curG + curC:Distance(adjC)
                        if rise > 20 then cost = cost + 100 end
                        if HasNavAttr(adj, NAV_CROUCH) then cost = cost + 50 end
                        if HasNavAttr(adj, NAV_AVOID) then cost = cost + 400 end
                        if adj:IsUnderwater() then cost = cost + 300 end
                        if g[adj] == nil or cost < g[adj] then
                            g[adj], came[adj] = cost, cur
                            local h = adjC:Distance(goalC)
                            if h < bestH then best, bestH = adj, h end
                            HeapPush(open, cost + h, adj)
                        end
                    end
                end
            end
        end
    end

    local tail = found or ((best ~= startArea) and best) or nil
    if not tail then return nil end
    local path, node = {}, tail
    while node do
        table.insert(path, 1, node)
        node = came[node]
    end
    return path
end

local function AreaRect(area)
    local a, b = area:GetCorner(0), area:GetCorner(2)
    return math.min(a.x, b.x), math.min(a.y, b.y), math.max(a.x, b.x), math.max(a.y, b.y)
end

-- Where to cross from area `from` into area `to`: on their shared edge, as
-- close to `prev` as the edge allows but at least NAV_DOOR_MARGIN from
-- either end of it, so the bot goes through the doorway, not its frame.
local function CrossingPoint(from, to, prev)
    local ax1, ay1, ax2, ay2 = AreaRect(from)
    local bx1, by1, bx2, by2 = AreaRect(to)
    local ox1, ox2 = math.max(ax1, bx1), math.min(ax2, bx2)
    local oy1, oy2 = math.max(ay1, by1), math.min(ay2, by2)
    local xr, yr = ox2 - ox1, oy2 - oy1
    local M = NAV_DOOR_MARGIN
    local x, y
    if xr > 1 and yr <= 8 then
        -- Shared edge runs along X
        y = (oy1 + oy2) * 0.5
        x = (xr > M * 2) and math.Clamp(prev.x, ox1 + M, ox2 - M) or (ox1 + ox2) * 0.5
    elseif yr > 1 and xr <= 8 then
        -- Shared edge runs along Y
        x = (ox1 + ox2) * 0.5
        y = (yr > M * 2) and math.Clamp(prev.y, oy1 + M, oy2 - M) or (oy1 + oy2) * 0.5
    else
        -- Stacked/diagonal/odd connection: nearest point of the next area
        return to:GetClosestPointOnArea(prev) or to:GetCenter()
    end
    local p = Vector(x, y, 0)
    p.z = math.max(from:GetZ(p), to:GetZ(p))
    return p
end

local function BuildBotPath(startArea, goalArea, startPos, avoid)
    local areas = FindAreaPath(startArea, goalArea, avoid)
    if not areas or #areas < 2 then return nil end
    local wps, index, rises = {}, {}, {}
    local prev = startPos
    for i = 2, #areas do
        local p = CrossingPoint(areas[i - 1], areas[i], prev)
        wps[i - 1] = p
        index[areas[i]] = i - 1
        rises[i - 1] = areas[i - 1]:ComputeAdjacentConnectionHeightChange(areas[i])
        prev = p
    end
    table.remove(areas, 1)
    -- areas[i] is the area entered through waypoint wps[i]
    return { waypoints = wps, areas = areas, index = index, rises = rises, currentWaypoint = 1,
             reachesGoal = areas[#areas] == goalArea }
end

local function NotPlayer(ent) return not ent:IsPlayer() end

-- Is a slab of the player hull (zMin..zMax above the feet) blocked within
-- `dist` units in direction `dir`? Other players are ignored -- bots don't
-- collide with each other and simply wait out a human in the way.
local function HullBlocked(from, dir, dist, zMin, zMax)
    local tr = util.TraceHull({
        start  = from,
        endpos = from + dir * dist,
        mins   = Vector(-15, -15, zMin),
        maxs   = Vector(15, 15, zMax),
        mask   = MASK_PLAYERSOLID,
        filter = NotPlayer,
    })
    return tr.Hit
end

local function SpotIsFree(pos)
    local tr = util.TraceHull({
        start = pos, endpos = pos,
        mins = Vector(-16, -16, 0), maxs = Vector(16, 16, 72),
        mask = MASK_PLAYERSOLID,
    })
    return not tr.Hit
end

local function AnyHumanSees(pos)
    for _, p in ipairs(player.GetHumans()) do
        if p:Alive() then
            local tr = util.TraceLine({ start = p:EyePos(), endpos = pos + Vector(0, 0, 40), mask = MASK_VISIBLE })
            if not tr.Hit then return true end
        end
    end
    return false
end

-- Last resort for a bot that's been wedged for several seconds and nothing
-- else freed: move it to a free spot a little further along its path (or a
-- neighbouring area). Only ever done when no human can see the bot or the
-- destination, so nobody watches it pop.
local function RescueTeleport(bot, pd)
    local botPos = bot:GetPos()
    if AnyHumanSees(botPos) then return false end
    local cands = {}
    if pd and pd.areas then
        for i = (pd.currentWaypoint or 1), math.min((pd.currentWaypoint or 1) + 3, #pd.areas) do
            cands[#cands + 1] = pd.areas[i]
        end
    end
    local here = navmesh.GetNearestNavArea(botPos)
    if here then
        for _, a in ipairs(here:GetAdjacentAreas()) do cands[#cands + 1] = a end
        cands[#cands + 1] = here
    end
    for _, area in ipairs(cands) do
        if IsValid(area) then
            -- A little above the floor so sloped ground doesn't count as
            -- "occupied"; the bot just drops the last few units.
            local spot = area:GetCenter() + Vector(0, 0, 20)
            if spot:DistToSqr(botPos) > 32 * 32 and SpotIsFree(spot) and not AnyHumanSees(spot) then
                bot:SetPos(spot)
                bot:SetVelocity(-bot:GetVelocity())
                return true
            end
        end
    end
    return false
end

-- A random area a few hops away, for a bot to wander to when its route
-- keeps failing (gets it out of whatever pocket it's trapped in).
local function PickWanderArea(fromArea, avoid)
    if not fromArea then return nil end
    local now = CurTime()
    local cur = fromArea
    local hops = math.random(3, 6)
    for _ = 1, hops do
        local opts = {}
        for _, adj in ipairs(cur:GetAdjacentAreas()) do
            if not ((avoid[adj] or 0) > now) and cur:ComputeAdjacentConnectionHeightChange(adj) <= NAV_CLIMB_LIMIT then
                opts[#opts + 1] = adj
            end
        end
        if #opts == 0 then break end
        cur = opts[math.random(#opts)]
    end
    return (cur ~= fromArea) and cur or nil
end

hook.Add("StartCommand", "SeshBot_AI", function(bot, cmd)
    if not FFA_Bots[bot] then return end
    if not IsSeshMode() then return end
    if GetGlobalBool("CoDHUD_RoundStarting", false) then
        cmd:ClearMovement() cmd:ClearButtons() return
    end
    if IsValid(FFA_KillcamBot) and bot == FFA_KillcamBot then
        cmd:ClearMovement() cmd:ClearButtons() return
    end

    -- Gmod Sesh S&D Set: the bot is a stationary dummy -- no aiming, no
    -- firing, no pathing/movement of any kind. It only relocates when the
    -- host runs sesh_move_bot_to_crosshair (bound to L), which teleports it
    -- directly rather than moving it via this command loop.
    if IsSDSet() then
        cmd:ClearMovement() cmd:ClearButtons() return
    end
    if not bot:Alive() then
        cmd:ClearMovement() cmd:ClearButtons() return
    end
    -- The engine hands bots a command that already holds IN_DUCK, so they
    -- crouch-walked everywhere at a third of normal speed (constantly
    -- tripping the stuck detector). Every button below is set explicitly.
    cmd:ClearButtons()

    -- ── Unlimited ammo with realistic reloads ──────────────────────────────
    local wep = bot:GetActiveWeapon()
    if IsValid(wep) then
        local clip    = wep:Clip1()
        local maxClip = wep:GetMaxClip1()
        local primType = wep:GetPrimaryAmmoType()
        -- If out of clip ammo, give reserve ammo so the bot reloads naturally
        if clip == 0 and maxClip > 0 then
            bot:GiveAmmo(maxClip * 4, primType, true)
            cmd:SetButtons(IN_RELOAD)
            cmd:SetForwardMove(0) cmd:SetSideMove(0)
            return
        end
        -- Keep reserve topped up so the bot never runs dry
        if primType >= 0 and bot:GetAmmoCount(primType) < maxClip * 2 then
            bot:GiveAmmo(maxClip * 4, primType, true)
        end
    end

    -- ── Target selection ──────────────────────────────────────────────────
    local target, bestDist = nil, math.huge
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and ply ~= bot and ply:Alive() and not ply:IsBot() then
            local d = bot:GetPos():Distance(ply:GetPos())
            if d < bestDist then bestDist = d target = ply end
        end
    end
    if IsFFA() then
        for otherBot, _ in pairs(FFA_Bots) do
            if IsValid(otherBot) and otherBot ~= bot and otherBot:Alive() then
                local d = bot:GetPos():Distance(otherBot:GetPos())
                if d < bestDist then bestDist = d target = otherBot end
            end
        end
    end

    if not IsValid(target) then cmd:ClearMovement() return end

    local botPos    = bot:GetPos()
    local targetPos = target:GetPos()
    local dist      = botPos:Distance(targetPos)

    -- ── Bot separation: steer away from other bots that are too close ─────
    local separationForce = Vector(0, 0, 0)
    local SEP_RADIUS = 120  -- units — bots this close push each other away
    for otherBot, _ in pairs(FFA_Bots) do
        if IsValid(otherBot) and otherBot ~= bot and otherBot:Alive() then
            local away = botPos - otherBot:GetPos()
            local d    = away:Length()
            if d < SEP_RADIUS and d > 0 then
                separationForce = separationForce + away:GetNormalized() * ((SEP_RADIUS - d) / SEP_RADIUS)
            end
        end
    end

    -- ── Aim and shoot ─────────────────────────────────────────────────────
    -- NextBot pseudo-clients don't turn to face cmd:SetViewAngles the way a
    -- real player's prediction code would -- their actual EyeAngles (which
    -- both the visible model facing AND the weapon's fire direction are
    -- based on) has to be pushed directly, or the bot keeps whatever angle
    -- it spawned/last faced while still being allowed to pull the trigger.
    -- That's why bots looked and fired in a single fixed direction before.
    --
    -- Per request, bots used to snap to face a target instantly and track it
    -- with pixel-perfect precision every tick (only the trigger itself was
    -- gated below) -- that read as an aimbot regardless of the fire delay,
    -- since the bot was always already looking dead at you the moment it
    -- could shoot. Now the aim itself turns toward the target at a limited,
    -- frame-rate-independent rate instead of snapping, and carries a small
    -- per-acquisition inaccuracy offset instead of lining up exactly on the
    -- target's origin.
    local dir = SafeNormalize(targetPos - botPos, bot:GetForward())
    local desiredAng = dir:Angle()

    if FFA_BotReactionTarget[bot] ~= target then
        -- Re-roll the aim error only when the bot (re)acquires a target, not
        -- every tick -- a per-tick random offset would look like screen
        -- shake, not human imprecision.
        FFA_BotAimError[bot] = Angle(math.Rand(-5, 5), math.Rand(-5, 5), 0)
    end
    desiredAng = desiredAng + (FFA_BotAimError[bot] or angle_zero)

    local now = CurTime()
    local dt  = math.Clamp(now - (FFA_BotAimLastT[bot] or now), 0, 0.5)
    FFA_BotAimLastT[bot] = now

    local curAng = FFA_BotAimAng[bot] or desiredAng
    -- Exponential turn smoothing (frame-rate independent): lower AIM_TURN_RATE
    -- = slower, more human turn onto target. Was an instant snap.
    local AIM_TURN_RATE = 4.5
    local turnFrac = 1 - math.exp(-AIM_TURN_RATE * dt)
    curAng = LerpAngle(turnFrac, curAng, desiredAng)
    FFA_BotAimAng[bot] = curAng

    cmd:SetViewAngles(curAng)
    bot:SetEyeAngles(curAng)
    -- Movement math further below (moveDir:Dot(ang:Forward()/:Right())) is
    -- written against a local named "ang" -- keep it aliased to the bot's
    -- actual (now-smoothed) current facing instead of the instant target
    -- direction, so strafing still reads as relative to where the bot is
    -- really looking.
    local ang = curAng

    -- Reaction delay: bots used to be able to shoot the instant they got
    -- line of sight, with zero delay and 100% uptime -- effectively an
    -- aimbot. Widened (was 0.25-0.6s) per follow-up request for a slower,
    -- less locked-on feel on top of the aim smoothing above.
    if FFA_BotReactionTarget[bot] ~= target then
        FFA_BotReactionTarget[bot] = target
        FFA_BotReactionUntil[bot]  = CurTime() + math.Rand(0.5, 1.1)
    end
    local canFire = CurTime() >= (FFA_BotReactionUntil[bot] or 0)

    if canFire and dist < 1500 then
        local tr = util.TraceLine({
            start  = bot:GetShootPos(),
            endpos = target:GetShootPos(),
            filter = { bot },
        })
        if tr.Entity == target or (tr.Fraction > 0.9 and dist < 800) then
            -- Burst-fire cadence instead of holding the trigger down for the
            -- whole engagement -- alternate short firing windows with short
            -- pauses so they don't melt the player in one continuous stream.
            if CurTime() > (FFA_BotFireStateUntil[bot] or 0) then
                FFA_BotFireState[bot] = not FFA_BotFireState[bot]
                if FFA_BotFireState[bot] then
                    FFA_BotFireStateUntil[bot] = CurTime() + math.Rand(0.25, 0.55) -- burst length
                else
                    FFA_BotFireStateUntil[bot] = CurTime() + math.Rand(0.25, 0.5) -- pause length
                end
            end
            if FFA_BotFireState[bot] then
                cmd:SetButtons(IN_ATTACK)
            end
        end
    end

    -- ── Navigation state ──────────────────────────────────────────────────
    local now = CurTime()
    local nav = GetBotNav(bot)
    -- After any gap in AI ticks (dead, frozen for a countdown or killcam,
    -- standing still to reload) restart the stuck clock rather than count
    -- the gap as being stuck.
    if now - (nav.lastT or 0) > 0.5 then
        nav.anchor, nav.anchorT, nav.level = botPos, now, 0
    end
    nav.lastT = now

    local STOP_DIST = 150
    if nav.wanderUntil and now >= nav.wanderUntil then
        nav.wanderUntil, nav.wanderPos = nil, nil
    end
    local wandering = nav.wanderPos ~= nil
    local pd = FFA_BotPaths[bot]
    local curArea = navmesh.GetNavArea(botPos + Vector(0, 0, 8), 80)

    -- ── Stuck detection (escalating) ──────────────────────────────────────
    -- "Stuck" = hasn't got 96+ units away from where it was 1.25s ago while
    -- trying to travel. Each repeat while still inside that circle
    -- escalates: back off and hop -> treat the area it can't get into as
    -- blocked and route around it -> wander to a different spot -> (only
    -- out of every human's sight) hop to a free spot further along.
    local closeCombat = (dist < STOP_DIST + 60) and not wandering
    if closeCombat or nav.holding or not nav.anchor or botPos:DistToSqr(nav.anchor) > 96 * 96 then
        nav.anchor, nav.anchorT, nav.level = botPos, now, 0
    elseif now - nav.anchorT > 1.25 then
        nav.anchorT = now
        nav.level   = nav.level + 1
        nav.side    = -nav.side
        FFA_PathUpdateT[bot] = 0  -- force an immediate repath below
        if nav.level == 1 then
            nav.backoffUntil = now + 0.6
        elseif nav.level == 2 then
            local blocked = pd and pd.areas and pd.areas[pd.currentWaypoint]
            if blocked then nav.avoid[blocked] = now + 15 end
            nav.backoffUntil = now + 0.5
        elseif nav.level >= 5 and RescueTeleport(bot, pd) then
            print("[Sesh Bots] " .. bot:Nick() .. " was wedged -- moved it to a free spot nearby")
            botPos = bot:GetPos()
            nav.anchor, nav.anchorT, nav.level = botPos, now, 0
            nav.wanderUntil, nav.wanderPos, wandering = nil, nil, false
        else
            -- Wander somewhere else for a bit (and keep doing so between
            -- rescue attempts while a human can see it).
            local wa = PickWanderArea(curArea or navmesh.GetNearestNavArea(botPos), nav.avoid)
            if wa then
                nav.wanderPos, nav.wanderUntil = wa:GetCenter(), now + 4
                wandering = true
            end
            nav.backoffUntil = now + 0.4
        end
        NavDebug(bot, "stuck, escalation level %d at %s (wandering=%s waypoint=%s/%s area=%s)",
            nav.level, tostring(botPos), tostring(wandering), tostring(pd and pd.currentWaypoint),
            tostring(pd and pd.waypoints and #pd.waypoints), tostring(curArea and curArea:GetID()))
    end

    -- ── Pathfinding ───────────────────────────────────────────────────────
    if now > (FFA_PathUpdateT[bot] or 0) then
        FFA_PathUpdateT[bot] = now + 0.5

        local goalPos = nav.wanderPos
        if not goalPos then
            -- Small random offset so bots don't all path to the exact same
            -- spot and merge into one pile
            goalPos = targetPos + Vector(math.random(-80, 80), math.random(-80, 80), 0)
        end

        -- TEMP DIAGNOSTIC: kc_disable_bot_pathing 1 skips navmesh queries
        -- entirely so we can isolate whether navmesh/pathing itself is what's
        -- freezing the game on a map.
        if navAreas and #navAreas > 0 and not GetConVar("kc_disable_bot_pathing"):GetBool() then
            local sa = curArea or navmesh.GetNearestNavArea(botPos)
            local ga = navmesh.GetNearestNavArea(goalPos)
            if sa and ga then
                FFA_BotPaths[bot] = BuildBotPath(sa, ga, botPos, nav.avoid)
                    or { waypoints = {}, currentWaypoint = 1 }
                pd = FFA_BotPaths[bot]
            end
        end
    end

    -- ── Follow the path ───────────────────────────────────────────────────
    local nextWp
    if pd and pd.waypoints and pd.currentWaypoint <= #pd.waypoints then
        -- Already inside a later area of the path (overshot, got pushed,
        -- fell)? Skip straight to the crossing after it.
        local idx = curArea and pd.index and pd.index[curArea]
        if idx and idx >= pd.currentWaypoint then pd.currentWaypoint = idx + 1 end
        nextWp = pd.waypoints[pd.currentWaypoint]
        if nextWp and math.abs(nextWp.x - botPos.x) < 24 and math.abs(nextWp.y - botPos.y) < 24
           and math.abs(nextWp.z - botPos.z) < 72 then
            pd.currentWaypoint = pd.currentWaypoint + 1
            nextWp = pd.waypoints[pd.currentWaypoint]
        end
    end

    -- Past the last crossing: head for the goal itself. If the goal isn't
    -- reachable at all (the path only got as close as it could), hold
    -- position at the end of it instead of grinding into the wall between.
    local aimPoint = nextWp or nav.wanderPos or targetPos
    nav.holding = false
    if not nextWp and not wandering and pd and pd.reachesGoal == false and pd.areas and #pd.areas > 0 then
        aimPoint = pd.areas[#pd.areas]:GetCenter()
        if math.abs(aimPoint.x - botPos.x) < 40 and math.abs(aimPoint.y - botPos.y) < 40 then
            nav.holding = true
        end
    end

    local flatDir = SafeNormalize(Vector(dir.x, dir.y, 0), bot:GetForward())
    local moveDir = SafeNormalize(Vector(aimPoint.x - botPos.x, aimPoint.y - botPos.y, 0), flatDir)

    -- Blend separation force into movement direction. The sum can land on
    -- (or extremely near) exactly zero if the separation push happens to be
    -- opposite and equal to moveDir -- SafeNormalize falls back to the
    -- pre-blend moveDir rather than ever normalizing a zero vector.
    -- Only the sideways part of the push is used, capped: a clump of bots
    -- can produce a push several times stronger than their own movement,
    -- and its backward part would cancel forward progress entirely (bots
    -- "stuck" in the open); sideways it spreads them out instead.
    separationForce.z = 0
    separationForce = separationForce - moveDir * separationForce:Dot(moveDir)
    if separationForce:Length() > 0.5 then
        separationForce = separationForce:GetNormalized() * 0.5
    end
    if separationForce:Length() > 0 then
        moveDir = SafeNormalize(moveDir + separationForce, moveDir)
    end

    -- ── Local obstacle handling ───────────────────────────────────────────
    local extraButtons = 0
    local onGround = bot:IsOnGround()
    -- tuck = crouch-jump (only for getting up onto something; a plain hop
    -- that lands still crouched shows as a slow crouch-walk afterwards)
    local function Jump(tuck, why)
        if onGround and now - (nav.jumpT or 0) > 0.5 then
            nav.jumpT, nav.tuck = now, tuck
            extraButtons = bit.bor(extraButtons, IN_JUMP)
            NavDebug(bot, "jump (%s)", why)
        end
    end
    local function Rotated(v, deg)
        local a = v:Angle()
        a.p, a.y = 0, a.y + deg
        return a:Forward()
    end

    -- Nav mesh hints: areas flagged "jump" by the mesh, and climbing up a
    -- ledge to the next crossing. (Crouching is NOT taken from the mesh's
    -- crouch flag: on auto-generated meshes it reads as set on open ground,
    -- which had bots crouch-walking everywhere. They crouch only when the
    -- head-high probe below actually finds a low ceiling.)
    if curArea and HasNavAttr(curArea, NAV_JUMP) then Jump(true, "nav jump area") end
    -- Only a real ledge between the two areas (not stairs or a ramp, whose
    -- crossings also rise but are walked up) needs a jump.
    local rise = nextWp and pd.rises and pd.rises[pd.currentWaypoint] or 0
    if rise > 22 and nextWp.z - botPos.z > 22
       and math.abs(nextWp.x - botPos.x) < 64 and math.abs(nextWp.y - botPos.y) < 64 then
        Jump(true, "ledge " .. math.Round(rise))
    end

    -- Something the nav mesh doesn't know about (a prop, a crate, a closed
    -- door) is in the way: only checked when the bot is actually failing to
    -- move the way it wants, so stairs and slopes don't trigger it.
    local vel = bot:GetVelocity()
    if onGround and (vel.x * moveDir.x + vel.y * moveDir.y) < 60 and not nav.holding and not closeCombat then
        nav.slowT = nav.slowT or now
    else
        nav.slowT = nil
    end
    if nav.detourUntil and now < nav.detourUntil then
        moveDir = nav.detourDir
    elseif nav.slowT and now - nav.slowT > 0.15 then
        local low  = HullBlocked(botPos, moveDir, 32, 20, 40)
        local high = HullBlocked(botPos, moveDir, 32, 44, 70)
        if low and not high then
            Jump(true, "knee-high obstacle")   -- hop up over it
        elseif high and not low then
            nav.duckUntil = now + 0.8           -- head-high: crouch under it
            NavDebug(bot, "duck (head-high obstacle)")
        elseif low and high then
            -- Wall-like: steer around it, trying the side it last
            -- succeeded on first so it doesn't flip-flop.
            for _, deg in ipairs({ 45, 90, 135 }) do
                local found = false
                for _, s in ipairs({ nav.side, -nav.side }) do
                    local d = Rotated(moveDir, deg * s)
                    if not HullBlocked(botPos, d, 48, 20, 70) then
                        nav.detourDir, nav.detourUntil, nav.side = d, now + 0.7, s
                        moveDir, found = d, true
                        break
                    end
                end
                if found then break end
            end
            NavDebug(bot, "wall ahead -> %s", nav.detourUntil and nav.detourUntil > now and "detour" or "no way around")
        else
            NavDebug(bot, "slow but nothing ahead")
        end
    end

    -- Tuck legs on the way up a climbing jump (crouch-jump reaches higher
    -- ledges) but let go once falling so it lands standing; and crouch
    -- under low ceilings.
    local tucking = nav.tuck and not onGround and vel.z > 0 and nav.jumpT and now - nav.jumpT < 0.6
    if tucking or (nav.duckUntil and now < nav.duckUntil) then
        extraButtons = bit.bor(extraButtons, IN_DUCK)
    end

    -- ── Movement ──────────────────────────────────────────────────────────
    -- Movement is relative to yaw only: with pitch included, a bot aiming
    -- up/down at its target used to crawl because Forward() had a big Z part.
    local flatAng = Angle(0, ang.y, 0)
    if nav.backoffUntil and now < nav.backoffUntil then
        -- Stuck: back away diagonally and hop instead of pushing forward
        -- into whatever is blocking it.
        local back = Rotated(-moveDir, 45 * nav.side)
        Jump(false, "backing off")
        cmd:SetForwardMove(200 * back:Dot(flatAng:Forward()))
        cmd:SetSideMove(200 * back:Dot(flatAng:Right()))
    elseif (dist < STOP_DIST and not wandering and separationForce:Length() < 0.1) or nav.holding then
        -- Stop closing in if already very close (prevents merging), but keep
        -- a light strafe going instead of a hard stop so bots stay moving/
        -- alive-looking rather than freezing in place next to their target.
        if now > (FFA_BotStrafeT[bot] or 0) then
            FFA_BotStrafeT[bot]   = now + math.random(15, 30) / 10
            FFA_BotStrafeDir[bot] = (math.random(2) == 1) and 1 or -1
        end
        cmd:SetForwardMove(0)
        cmd:SetSideMove(100 * (FFA_BotStrafeDir[bot] or 1))
    else
        cmd:SetForwardMove(200 * moveDir:Dot(flatAng:Forward()))
        cmd:SetSideMove(200 * moveDir:Dot(flatAng:Right()))
    end
    if extraButtons ~= 0 then
        cmd:SetButtons(bit.bor(cmd:GetButtons(), extraButtons))
    end
end)

-- Hide ragdolls created from bot deaths in sesh mode so they don't clutter killcam
hook.Add("CreateEntityRagdoll", "SeshBot_HideBotRagdoll", function(owner, ragdoll)
    if not IsSeshMode() then return end
    if not IsValid(owner) or not owner:IsPlayer() or not owner:IsBot() then return end
    if not FFA_Bots[owner] then return end
    if IsValid(ragdoll) then
        ragdoll:SetNoDraw(true)
    end
end)

-- ================================================================
--  KILL TRACKING
-- ================================================================
local function FFA_AddKill(attacker)
    if not IsValid(attacker) then return end
    local uid = attacker:UserID()
    FFA_PlayerKills[uid] = (FFA_PlayerKills[uid] or 0) + 1
    attacker:SetNWInt("SeshFFA_Kills", FFA_PlayerKills[uid])
    -- Cumulative match kills — persists across rounds, only reset on full match reset
    local matchKills = attacker:GetNW2Int("SeshSD_MatchKills", 0) + 1
    attacker:SetNW2Int("SeshSD_MatchKills", matchKills)
    -- Sesh S&D's tab scoreboard shows the running match kill total, not the
    -- per-round FFA_PlayerKills count (that resets every round via
    -- SeshBot_ResetRound) -- setting Frags to the per-round value here was
    -- overwriting the correct cumulative total on every single kill, which
    -- is why kills looked like they weren't updating/kept resetting.
    if IsSD() then
        attacker:SetFrags(matchKills)
    else
        attacker:SetFrags(FFA_PlayerKills[uid])
    end
end

-- FFA: a BOT reaching the kill limit (by killing other bots OR the human)
-- was previously never checked at all -- only a human reaching the limit
-- could ever end an FFA match, so bots racking up kills on each other or on
-- you just... never won. Mirrors the human-wins path in
-- SeshBot_StartKillcamPoll further down, but there's no natural "kill of
-- the human" to hang a killcam on when the winning kill was bot-vs-bot, so
-- this skips straight to the round-end screen instead of playing one.
local function CheckFFABotWin(attacker, victim)
    if not IsFFA() then return end
    if not IsValid(attacker) or not attacker:IsBot() then return end
    if _G.SeshBot_KillcamTriggered then return end -- match is already ending

    local uid = attacker:UserID()
    local kills = FFA_PlayerKills[uid] or 0
    if kills < GetFFALimit() then return end

    print("[Sesh Bots] FFA bot win: " .. attacker:Nick() .. " reached " .. kills .. " kills")
    _G.SeshBot_KillcamTriggered = true
    FFA_KillcamBot = nil
    _G.SeshBot_LastRoundEndVictim = nil

    BroadcastFinalKillDistance(attacker, victim)

    -- Freeze everyone immediately so no more kills happen while the
    -- round-end screen is coming up.
    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) then
            bot:Freeze(true)
            bot:StripWeapons()
        end
    end
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then p:Freeze(true) end
    end

    -- Tell each human directly that the bot's faction won. CoDHUD_DoRoundEnd's
    -- own FFA branch is built (and only ever exercised so far) around a
    -- human winning, so rather than trust its untested "loss" branch, this
    -- sends a small, self-contained, definitely-correct version of the same
    -- net message.
    local botFaction    = GetBotFaction()
    local playerFaction = GetPlayerFaction()
    timer.Simple(0.5, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) and not ply:IsBot() then
                net.Start("CoDHUD_RoundEnd")
                    net.WriteString(botFaction)
                    net.WriteString(playerFaction)
                    net.WriteInt(kills, 32)
                    net.WriteInt(FFA_PlayerKills[ply:UserID()] or 0, 32)
                net.Send(ply)
            end
        end
        if _G.CoDHUD_SendFFALeaderboard then _G.CoDHUD_SendFFALeaderboard() end
    end)

    -- Final killcam of the bot's winning kill (it may even be bot-vs-bot),
    -- seen through the winning bot's eyes, then the usual match-over
    -- cleanup. Without bot killcams, just leave the round-end/leaderboard
    -- screen up long enough to read.
    if Killcam.CanBeKiller and Killcam.CanBeKiller(attacker) and WaitForKillcamThenRun then
        local botKiller = attacker
        Killcam.PrepareKillcam(botKiller)
        timer.Simple(12, function() Killcam.BeginFor(botKiller) end)
        WaitForKillcamThenRun(function()
            timer.Simple(5, SeshMatchOverCleanup)
        end, 60)
    else
        timer.Simple(14, SeshMatchOverCleanup)
    end
end

-- Bot died
hook.Add("PlayerDeath", "SeshBot_BotDeath", function(victim, inflictor, attacker)
    if not IsSeshMode() then return end
    if not FFA_Bots[victim] then return end
    victim:SetNoDraw(true)
    if IsValid(FFA_KillcamBot) and victim == FFA_KillcamBot then return end
    if not IsValid(attacker) or attacker == victim then return end

    FFA_AddKill(attacker)
    CheckFFABotWin(attacker, victim)

    -- TDM: player killed a bot → player team scores
    if IsTDM() and not attacker:IsBot() and _G.SeshTeam then
        _G.SeshTeam.OnPlayerKilledBot(attacker)
    end

    -- In S&D, bots don't respawn mid-round — once dead, stay dead
    if IsSD() then return end

    timer.Simple(3, function()
        if not IsSeshMode() or not FFA_Active then return end
        if _G.SeshBot_KillcamTriggered then return end
        if GetGlobalBool("Killcam_Playing") then return end
        if not IsValid(victim) then return end
        local existing = {}
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then table.insert(existing, ply:GetPos()) end
        end
        local pos, ang = GetNavSpawnFarFrom(existing, 900, victim)
        victim:Spawn()
        victim:SetPos(pos)
        victim:SetEyeAngles(ang)
        ApplyBotLook(victim)
        victim:Give("weapon_smg1")
        victim:Give("weapon_shotgun")
        if math.random(2) == 1 then
            victim:SelectWeapon("weapon_smg1")
            victim:GiveAmmo(256, "SMG1", true)
        else
            victim:StripWeapon("weapon_smg1")
            victim:GiveAmmo(32, "Buckshot", true)
            victim:SelectWeapon("weapon_shotgun")
        end
        victim:SetNW2String("CoDHUD_Faction", GetBotFaction())
    end)
end)

-- Real player died
hook.Add("PlayerDeath", "SeshBot_PlayerDeath", function(victim, inflictor, attacker)
    if not IsSeshMode() then return end
    if FFA_Bots[victim] then return end
    if not IsValid(attacker) or attacker == victim then return end
    if not attacker:IsPlayer() then return end

    -- FFA: any kill counts
    if IsFFA() then
        FFA_AddKill(attacker)
        CheckFFABotWin(attacker, victim)
    end

    -- TDM: bot killed the player → bot team scores
    if IsTDM() and attacker:IsBot() and _G.SeshTeam then
        local wasGameOver = _G.SeshTeam.gameOver
        _G.SeshTeam.OnBotKilledPlayer(victim)
        -- Only the actual match-ending kill gets the distance callout, not
        -- every routine kill throughout the match.
        if _G.SeshTeam.gameOver and not wasGameOver then
            BroadcastFinalKillDistance(attacker, victim)

            -- The bots just won the TDM match outright (kill limit reached).
            -- This case previously did nothing further -- no bot kick, no
            -- lobby reopen -- leaving bots running around indefinitely with
            -- the match stuck in a "won" state. Wait for this death's
            -- killcam to finish, then a few seconds more, then run the same
            -- match-over cleanup the player-wins path already uses.
            -- Final killcam of the bot's winning kill (through the bot's
            -- eyes, like CoD), on the same timing as the player-wins path.
            local botKiller = attacker
            if Killcam.PrepareKillcam then Killcam.PrepareKillcam(botKiller) end
            timer.Simple(12, function()
                if Killcam.BeginFor then Killcam.BeginFor(botKiller) end
            end)
            if WaitForKillcamThenRun then
                WaitForKillcamThenRun(function()
                    timer.Simple(5, SeshMatchOverCleanup)
                end, 60)
            else
                timer.Simple(15, SeshMatchOverCleanup)
            end
        end
    end

    -- SD/TDM: track each bot's OWN kill count for the tab scoreboard.
    -- IMPORTANT: this must SET an absolute value, not add to attacker:Frags().
    -- GMod's base gamemode already auto-adds a frag to the attacker on any
    -- player-vs-player kill natively, independent of this hook. Reading
    -- Frags() and adding +1 on top of that native increment is what was
    -- making every bot kill count as 2 -- the human-kill path avoids this
    -- exact trap by also setting an absolute value (SeshSD_MatchKills)
    -- rather than adding to Frags(). Track the bot's own kill count
    -- separately (FFA_Bots[attacker].kills, untouched by native scoring)
    -- and set Frags from that instead.
    --
    -- TDM previously had NO per-bot kill tracking at all -- only the team
    -- total (ST.scoreB) was tracked, and BroadcastScores() worked around
    -- that by dumping the whole team's score onto whichever bot happened to
    -- be first in player.GetAll() and zeroing everyone else, purely so the
    -- scoreboard's per-faction SUM of Frags() came out right. That's why
    -- every TDM kill looked like it was credited to one single bot instead
    -- of whoever actually got it. Now that each bot's Frags is its own real
    -- count, the faction sum is correct on its own and that hack is removed
    -- (see sv_sesh_teams.lua).
    if (IsSD() or IsTDM()) and attacker:IsBot() and FFA_Bots[attacker] then
        FFA_Bots[attacker].kills = (FFA_Bots[attacker].kills or 0) + 1
        attacker:SetFrags(FFA_Bots[attacker].kills)
    end

    -- SD: track the human's cumulative match deaths, mirroring
    -- SeshSD_MatchKills, so the tab scoreboard's Deaths column also
    -- persists across rounds instead of getting zeroed at every respawn.
    if IsSD() then
        local matchDeaths = victim:GetNW2Int("SeshSD_MatchDeaths", 0) + 1
        victim:SetNW2Int("SeshSD_MatchDeaths", matchDeaths)
    end

    -- SD: player dying means enemy team wins the round.
    -- Use a short delay so the death is fully registered before we end it.
    if IsSD() and _G.SD_RoundActive and not _G.SD_RoundEnding then
        -- The human's death is always the round-ending kill in SD.
        BroadcastFinalKillDistance(attacker, victim)
        timer.Simple(0.3, function()
            if _G.SD_EndRound then
                _G.SD_EndRound(false, false)
            end
        end)
    end
end)

hook.Add("PlayerDeath", "SeshBot_CorrectFrags", function(victim, inflictor, attacker)
    if not IsFFA() then return end
    if not IsValid(attacker) or attacker == victim then return end
    if not attacker:IsPlayer() then return end
    local uid = attacker:UserID()
    timer.Simple(0, function()
        if IsValid(attacker) then
            attacker:SetFrags(FFA_PlayerKills[uid] or 0)
        end
    end)
end)

-- ================================================================
--  KILLCAM POLL STATE (declared here, ahead of SeshMatchOverCleanup below,
--  so that function's FFA_PollState reset closes over these same locals
--  instead of silently creating/writing a global of the same name).
-- ================================================================
local FFA_PollState = nil
local FFA_PollTimer = 0
local FFA_PollTimeout = 0

-- ================================================================
--  MATCH OVER CLEANUP (shared by every "match just ended" path: the
--  player getting the match-winning kill, and the bots getting it too --
--  e.g. TDM's kill-limit reached by the bot team) -- kicks bots, wipes
--  match state, and hands off to sv_lobby.lua to reopen the pre-game
--  lobby. Nothing here re-spawns bots; that only happens again once the
--  host presses Start Game in the lobby.
-- ================================================================
function SeshMatchOverCleanup()
    _G.SeshBot_ShowingScoreboard = false
    FFA_SDWinCounted = false

    for uid, _ in pairs(FFA_PlayerKills) do FFA_PlayerKills[uid] = 0 end
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then
            p:SetFrags(0)
            p:SetDeaths(0)
            p:SetNWInt("SeshFFA_Kills", 0)
            p:SetNW2Int("SeshSD_MatchKills", 0)
            p:SetNW2Int("SeshSD_MatchDeaths", 0)
        end
    end

    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) then bot:Kick("Kicked from server") end
    end
    if IsValid(FFA_KillcamBot) then FFA_KillcamBot:Kick("Kicked from server") end

    FFA_Bots            = {}
    FFA_BotPaths        = {}
    FFA_PathUpdateT     = {}
    FFA_BotNav          = {}
    FFA_KillcamBot      = nil
    FFA_LastKillTarget  = nil
    FFA_PollState       = nil
    FFA_Active          = false
    SeshBot_Active      = false
    KC_BotKillID_Server = nil
    _G.SeshBot_KillcamIDLocked  = false
    _G.SeshBot_KillcamTriggered = false
    _G.SeshBot_LastRoundEndVictim = nil
    SeshBot_PlayerKills = FFA_PlayerKills

    -- Full reset of match scores/rounds for the next match
    if _G.SeshTeam then _G.SeshTeam.Reset() end

    -- Let sv_lobby.lua know the match is over so it can reopen
    -- the pre-game lobby for everyone.
    hook.Run("KC_MatchEnded")
end

-- ================================================================
--  KILLCAM POLL
-- ================================================================
hook.Add("Think", "SeshBot_KillcamPoll", function()
    if not IsSeshMode() then return end
    if not FFA_PollState then return end
    if CurTime() < FFA_PollTimer then return end
    FFA_PollTimer = CurTime() + 0.2

    if CurTime() > FFA_PollTimeout then
        print("[Sesh Bots] Killcam poll timed out — kicking kill target")
        if IsValid(FFA_KillcamBot) then FFA_KillcamBot:Kick("Kicked from server") end
        FFA_KillcamBot      = nil
        FFA_LastKillTarget  = nil
        FFA_PollState       = nil
        KC_BotKillID_Server = nil
        return
    end

    local playing = GetGlobalBool("Killcam_Playing", false)

    if FFA_PollState == "start" then
        print("[Sesh Bots] PollKillcamStart: Killcam_Playing=" .. tostring(playing))
        if playing then
            FFA_PollState = "end"
            print("[Sesh Bots] Killcam started — waiting for end")
        end
    elseif FFA_PollState == "end" then
        print("[Sesh Bots] PollKillcamEnd: Killcam_Playing=" .. tostring(playing))
        if not playing then
            print("[Sesh Bots] Killcam stopped — resetting and respawning")
            FFA_PollState = nil

            if IsValid(FFA_KillcamNPC) then
                FFA_KillcamNPC:Remove()
                FFA_KillcamNPC = nil
            end

            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then
                    p:Freeze(false)
                    -- Save loadout now before DoReset calls p:Spawn() and wipes weapons
                    if IsSD() then SaveLoadout(p) end
                end
            end

            -- Determine if this is the final round of the match (or a non-SD mode,
            -- where every round-ending kill IS the match end).
            local isFinalRound = true
            if IsSD() and _G.SeshTeam then
                _G.SeshTeam.OnSndRoundEnd("A", FFA_SDWinCounted)
                FFA_SDWinCounted = false
                isFinalRound = _G.SeshTeam.gameOver
            end

            if isFinalRound then
                -- MATCH OVER: extra time after killcam, then kick bots and reset everything
                timer.Simple(10, SeshMatchOverCleanup)
            else
                -- ROUND OVER, MATCH CONTINUES (SD only): soft reset.
                -- Don't kick bots — respawn remaining bots away from the player
                -- for the next round. _G.SeshTeam.OnSndRoundEnd already scheduled
                -- _G.SeshBot_ResetRound() in 3 seconds.
                FFA_KillcamBot      = nil
                FFA_LastKillTarget  = nil
                FFA_PollState       = nil
                KC_BotKillID_Server = nil
                _G.SeshBot_KillcamIDLocked  = false
                _G.SeshBot_KillcamTriggered = false
                _G.SeshBot_LastRoundEndVictim = nil
                _G.SeshBot_ShowingScoreboard = false

                -- Hide/freeze bots immediately so they aren't visible at their
                -- old/default positions during the gap before DoReset (+0.5s)
                -- and SeshBot_ResetRound (+3s) reposition them away from the player.
                SeshBot_RoundResetTime = CurTime() + 3.5
                for bot, _ in pairs(FFA_Bots) do
                    if IsValid(bot) then
                        bot:SetNoDraw(true)
                        bot:SetNotSolid(true)
                        bot:Freeze(true)
                        bot.KC_PendingRoundStart = true
                    end
                end

                -- Reset the per-round bot-kill tracker only. Frags() shows
                -- each human's CUMULATIVE match kill total for the whole SD
                -- match (SeshSD_MatchKills, kept in sync by FFA_AddKill) --
                -- it must NOT be zeroed here. It previously was, which wiped
                -- everyone's Kills/Score columns on the tab scoreboard back
                -- to 0 at every round transition (only recovering once each
                -- player got their next kill and FFA_AddKill re-synced it).
                for uid, _ in pairs(FFA_PlayerKills) do FFA_PlayerKills[uid] = 0 end
                SeshBot_PlayerKills = FFA_PlayerKills
            end
        end
    end
end)

hook.Add("CoDHUD_BotKillSetKill", "SeshBot_StartKillcamPoll", function(victim, attacker)
    if not IsSeshMode() then return end
    if not FFA_Bots[victim] then return end
    if not IsValid(attacker) or attacker:IsBot() then return end
    if IsValid(FFA_KillcamBot) then return end
    if _G.SeshBot_KillcamTriggered then return end

    local uid = attacker:UserID()
    local kills = FFA_PlayerKills[uid] or 0

    if IsSD() then
        -- S&D: round ends when ALL enemy bots are dead, not at a score limit
        local allDead = true
        for bot, _ in pairs(FFA_Bots) do
            if IsValid(bot) and bot:Alive() and bot ~= victim then
                allDead = false
                break
            end
        end
        print("[Sesh Bots] BotKillSetKill (SD): " .. attacker:Nick() .. " kills=" .. kills .. " allDead=" .. tostring(allDead))
        if not allDead then return end
    else
        local scoreLimit, effectiveKills
        if IsFFA() then
            -- FFA: no teams, each player must personally reach the limit
            scoreLimit     = GetFFALimit()
            effectiveKills = kills
        else
            -- TDM: round must end on the TEAM's combined total, not whichever
            -- single player happens to be the latest scorer's personal count --
            -- otherwise kills split across host + teammates can sail past the
            -- limit (visible on the scoreboard as "full") while no individual
            -- player's own count ever reaches it, and the round never ends.
            scoreLimit     = GetScoreLimit()
            effectiveKills = (_G.SeshTeam and _G.SeshTeam.scoreA) or kills
        end
        print("[Sesh Bots] BotKillSetKill: " .. attacker:Nick() .. " personalKills=" .. kills .. " effectiveKills=" .. effectiveKills .. " limit=" .. scoreLimit)
        if effectiveKills < scoreLimit then return end
    end

    -- This is the round-ending (S&D) or match-ending (TDM/FFA) kill.
    BroadcastFinalKillDistance(attacker, victim)

    -- Snapshot the winner's loadout RIGHT NOW, while they're still alive and
    -- definitely holding what they just won the round with. The old code
    -- only saved this ~12s later, after the killcam had already played in
    -- full (SeshBot_KillcamPoll's "end" state) -- a long window during which
    -- the player's weapons could read back empty/stale (e.g. mid-killcam
    -- state), and SaveLoadout's own empty-read guard would then silently
    -- keep whatever older loadout was saved instead, which is why the
    -- correct weapons sometimes didn't come back for the next round.
    if IsSD() then SaveLoadout(attacker) end

    _G.SeshBot_KillcamTriggered = true
    FFA_KillcamBot = victim

    -- Expose for floater detection in killcam_codhud_integration.lua
    _G.SeshBot_LastRoundEndVictim = victim

    victim:SetNoDraw(true)
    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) then
            bot:Freeze(true)
            bot:SetNoDraw(true)
            bot:StripWeapons()
        end
    end

    FFA_KillcamDeathPos = victim:GetPos()
    FFA_KillcamDeathAng = victim:GetAngles()
    FFA_KillcamModel    = victim.SeshBotModel or victim:GetModel() or BOT_MODELS[1]
    KC_BotKillID_Server = nil
    _G.SeshBot_KillcamIDLocked = true

    local winnerNick  = attacker:Nick()
    local winnerScore = kills
    local loserScore  = 0

    -- For S&D, display the match round score (e.g. "1-0") instead of
    -- per-round kill counts. Player team always wins this round (allDead).
    if IsSD() and _G.SeshTeam then
        -- Count the round win right now, so the scorebar fills the moment
        -- the round ends (like CoD, and like a bot-team win already does);
        -- SeshBot_KillcamPoll does the rest once the killcam is over.
        local ST = _G.SeshTeam
        ST.roundsA = ST.roundsA + 1
        ST.BroadcastScores()
        FFA_SDWinCounted = true
        winnerScore = ST.roundsA
        loserScore  = ST.roundsB
    elseif IsTDM() and _G.SeshTeam then
        -- Show the team's combined total, not just the final scorer's personal count
        winnerScore = _G.SeshTeam.scoreA
        loserScore  = _G.SeshTeam.scoreB
    end

    attacker:SetFrags(winnerScore)
    if _G.CoDHUD_ResetRoundEnd then _G.CoDHUD_ResetRoundEnd() end
    _G.SeshBot_ShowingScoreboard = true
    if _G.CoDHUD_DoRoundEnd then
        local playerFaction = GetPlayerFaction()
        local botFaction    = GetBotFaction()
        -- Pass raw kill count — sv_roundend.lua multiplies by sbMul internally for display
        _G.CoDHUD_DoRoundEnd(playerFaction, botFaction, winnerScore, loserScore)
    end

    -- Remember the winner so BeginFor runs the killcam for the player who
    -- actually got the winning kill, not the first player in player.GetAll()
    -- (which on a listen server is always the host).
    _G.KC_PendingKiller = attacker
    if Killcam.PrepareKillcam then Killcam.PrepareKillcam(attacker) end

    timer.Simple(12, function()
        Killcam.BeginFor(_G.KC_PendingKiller)
    end)

    FFA_PollState   = "start"
    FFA_PollTimer   = CurTime() + 12
    FFA_PollTimeout = CurTime() + 60
end)

-- ================================================================
--  SOFT ROUND RESET (SD only) — called by ST.OnSndRoundEnd when the
--  match isn't over yet. Respawns existing bots away from the player
--  for the next round, without kicking anyone.
-- ================================================================
_G.SeshBot_ResetRound = function()
    if not IsSeshMode() or not IsSD() then return end
    if not FFA_Active then return end

    print("[Sesh Bots] SeshBot_ResetRound: respawning bots for next SD round")

    local existing = {}
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then
            table.insert(existing, p:GetPos())
        end
    end

    for bot, data in pairs(FFA_Bots) do
        if IsValid(bot) then
            local pos, ang = GetNavSpawnFarFrom(existing, 1400, bot)
            bot:Spawn()
            bot:SetPos(pos)
            bot:SetEyeAngles(ang)
            ApplyBotLook(bot)
            -- Keep hidden/frozen/invulnerable until the round countdown ends
            bot:SetNoDraw(true)
            bot:SetNotSolid(true)
            bot:Freeze(true)
            bot:StripWeapons()  -- no weapons during countdown — re-given on reveal
            bot.KC_PendingRoundStart = true
            bot:SetNW2String("CoDHUD_Faction", GetBotFaction())
            -- NOTE: bot kills (data.kills / Frags) are intentionally NOT reset
            -- here anymore -- kills should keep accumulating for the whole
            -- match, the same way the human's SeshSD_MatchKills already does,
            -- only clearing on a full match reset (see the two match-over
            -- cleanup blocks that zero FFA_Bots[bot].kills instead).
            table.insert(existing, pos)
        end
    end

    -- Reset round-local state
    FFA_KillcamBot      = nil
    FFA_LastKillTarget  = nil
    KC_BotKillID_Server = nil
    _G.SeshBot_KillcamIDLocked  = false
    _G.SeshBot_KillcamTriggered = false
                _G.SeshBot_LastRoundEndVictim = nil

    -- Restore Frags() to cumulative match kills so the tab scoreboard
    -- shows the running total across all rounds, not the per-round count.
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then
            local matchKills = p:GetNW2Int("SeshSD_MatchKills", 0)
            p:SetFrags(matchKills)
        end
    end

    -- Re-broadcast scores so the bottom-left scorebar refreshes with the
    -- updated round count once the soft reset is complete
    if _G.SeshTeam then
        timer.Simple(0.5, function()
            if _G.SeshTeam then _G.SeshTeam.BroadcastScores() end
        end)
    end
end

-- Keep bots hidden/frozen/notsolid while pending round start (DoReset's
-- p:Spawn() on bot entities resets these flags, so re-enforce every tick),
-- then reveal once the round countdown ends AND the soft-reset gap has passed.
SeshBot_RoundResetTime = SeshBot_RoundResetTime or 0
hook.Add("Think", "SeshBot_RevealAfterCountdown", function()
    if not IsSeshMode() or not IsSD() then return end
    local stillResetting = CurTime() < (SeshBot_RoundResetTime or 0)
    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) and bot.KC_PendingRoundStart then
            if CoDHUD_RoundStarting or stillResetting then
                -- Still counting down / waiting for reposition — keep hidden
                bot:SetNoDraw(true)
                bot:SetNotSolid(true)
                bot:Freeze(true)
            else
                -- Countdown ended and reposition has happened — reveal
                bot:SetNoDraw(false)
                bot:SetNotSolid(false)
                bot:Freeze(false)
                -- Re-arm with a random weapon for this round
                bot:StripWeapons()
                local useSmg = math.random(2) == 1
                if useSmg then
                    bot:Give("weapon_smg1")
                    bot:GiveAmmo(256, "SMG1", true)
                    bot:SelectWeapon("weapon_smg1")
                else
                    bot:Give("weapon_shotgun")
                    bot:GiveAmmo(32, "Buckshot", true)
                    bot:SelectWeapon("weapon_shotgun")
                end
                bot.KC_PendingRoundStart = nil
            end
        end
    end
end)

-- ================================================================
--  FACTION SYNC (keep bots on enemy faction)
-- ================================================================
local FFA_FactionTimer = 0
hook.Add("Think", "SeshBot_FactionSync", function()
    if not IsSeshMode() then return end
    if CurTime() < FFA_FactionTimer then return end
    FFA_FactionTimer = CurTime() + 0.25

    local botFaction = GetBotFaction()
    -- Networked to every client so the faction scoreboard can always show the
    -- enemy team's spot (cl_sesh_factions.lua), even before any bot's own
    -- faction has reached them.
    SetGlobal2String("KC_SeshBotFaction", botFaction)
    for bot, _ in pairs(FFA_Bots) do
        if IsValid(bot) then
            -- Log any actual mismatch this loop corrects -- if the team-merge
            -- bug is a real, persistent server-side value (not just a one-off
            -- networking race), this will keep firing every tick instead of
            -- silently resolving, which tells us this loop isn't the fix.
            local current = bot:GetNW2String("CoDHUD_Faction", "")
            if current ~= botFaction then
                print("[Sesh Bots] FactionSync correcting " .. bot:Nick() .. ": \"" .. current .. "\" -> \"" .. botFaction .. "\"")
            end
            bot:SetNW2String("CoDHUD_Faction", botFaction)
        end
    end
end)

-- ================================================================
--  ROUND START / END
-- ================================================================
hook.Add("CoDHUD_RoundEnd", "SeshBot_RoundEnd", function()
    if not IsSeshMode() then return end
    RemoveAllBots()
end)

hook.Add("CoDHUD_RoundStart", "SeshBot_RoundStart", function()
    if not IsSeshMode() then return end
    timer.Simple(1, SpawnAllBots)
end)

-- ================================================================
--  GMOD SESH S&D SET — HOST MOVES THE IDLE BOT TO CROSSHAIR
-- ================================================================
-- Mirrors the IsHostOrAdmin() fallback used in cl_lobby.lua/sh_admin.lua/
-- sv_roundstart.lua (listen-server host, or admin, or the sole real human
-- connected) so this command is never blocked by an admin mod's per-map
-- state on a solo/testing server.
local function IsHostOrAdminSV(ply)
    if not IsValid(ply) then return false end
    if ply:IsListenServerHost() or ply:IsAdmin() then return true end
    local realPlayers = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then realPlayers = realPlayers + 1 end
    end
    return realPlayers <= 1
end

-- Bound to L client-side (see cl_sesh_sd_set.lua) while Gmod Sesh S&D Set
-- is the active mode. The bot never moves on its own in this mode, so this
-- is the only way it repositions -- a direct teleport to wherever the host
-- is aiming, not a walk/path.
concommand.Add("sesh_move_bot_to_crosshair", function(ply)
    if not IsValid(ply) then return end
    if not IsHostOrAdminSV(ply) then return end
    if not IsSDSet() or not FFA_Active then return end

    local bot
    for b in pairs(FFA_Bots) do bot = b break end
    if not IsValid(bot) then return end

    local startPos = ply:GetShootPos()
    local tr = util.TraceLine({
        start  = startPos,
        endpos = startPos + ply:GetAimVector() * 8192,
        filter = ply,
        mask   = MASK_SOLID,
    })

    local pos = tr.HitPos + tr.HitNormal * 4
    bot:SetPos(pos)
    bot:SetVelocity(vector_origin)

    local faceDir = SafeNormalize(ply:GetPos() - pos, Vector(0, 0, 1))
    bot:SetEyeAngles(faceDir:Angle())

    print("[Sesh Bots] " .. ply:Nick() .. " moved the S&D Set bot to crosshair.")
end)

-- Diagnostic: dump what the server thinks every player's/bot's faction is
-- right now, plus what GetBotFaction()/GetPlayerFaction() currently resolve
-- to. Run this in the server console while the team-merge bug is happening
-- to tell whether it's a server-side assignment problem or something purely
-- on the client's rendering/networking side.
concommand.Add("sesh_debug_factions", function()
    print("[Sesh Debug] HUD type = " .. tostring(GetHUDType()) ..
          "  GetBotFaction() = " .. tostring(GetBotFaction()) ..
          "  GetPlayerFaction() = " .. tostring(GetPlayerFaction()) ..
          "  gamemode = " .. tostring(GetGM()))
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            print(string.format("[Sesh Debug]  %-20s IsBot=%-5s Faction=%q  InFFA_Bots=%s",
                p:Nick(), tostring(p:IsBot()), p:GetNW2String("CoDHUD_Faction", ""), tostring(FFA_Bots[p] ~= nil)))
        end
    end
end)

print("[Sesh Bots] sv_ffa_bots.lua loaded.")