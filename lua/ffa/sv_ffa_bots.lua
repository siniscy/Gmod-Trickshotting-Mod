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

local BOT_NAMES_POOL = { "xAlps", "Boolmaster Flex", "reha", "Nythvn", "dread", "sage", "Silverr" }

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

local BOT_MODELS = {
    "models/player/kleiner.mdl",
    "models/player/mossman.mdl",
    "models/player/magnusson.mdl",
    "models/player/alyx.mdl",
    "models/player/barney.mdl",
    "models/player/eli.mdl",
}

-- Opposite factions per HUD type (bots are always the enemy faction)
local HUD_FACTIONS = {
    mw2  = { player = "rangers",  bot = "ussr"    },
    mw3  = { player = "delta",    bot = "ussr"    },
    cod4 = { player = "marines",  bot = "arab"    },
    bo1  = { player = "sog",      bot = "nva"     },
    waw  = { player = "american", bot = "german"  },
}

-- ================================================================
--  STATE
-- ================================================================
local FFA_Bots        = {}
local FFA_BotPaths    = {}
local FFA_PathUpdateT = {}
local FFA_SpawnGeneration = 0
local FFA_BotStuckPos    = {}
local FFA_BotStuckTime   = {}
local FFA_BotUnstickUntil = {}
local FFA_BotOrbitDir    = {}
local FFA_BotStrafeDir   = {}
local FFA_BotStrafeT     = {}
local FFA_BotReactionTarget = {}
local FFA_BotReactionUntil  = {}
local FFA_BotFireState      = {}
local FFA_BotFireStateUntil = {}
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
        if ply.SeshBotModel then ply:SetModel(ply.SeshBotModel) end
        -- Re-assert the bot's faction the instant it spawns, on top of the
        -- 1-second SeshBot_FactionSync tick -- a generic, mode-unaware
        -- faction-assignment system elsewhere (round-start autobalance, HUD
        -- skin change) can otherwise briefly tag a bot with the player's own
        -- faction, merging both teams into one on the scoreboard and making
        -- the S&D round bar unable to find a distinct enemy score to show.
        ply:SetNW2String("CoDHUD_Faction", GetBotFaction())
        return
    end
    -- Player weapon restore is handled in PlayerLoadout below
end)

-- Main loadout hook — fires after PlayerSpawn.
-- Bots get random SMG or shotgun. Players get their saved loadout if they
-- have one, or nothing on first spawn (they pick their own weapons in-game).
-- NOTE: we intentionally do NOT gate on CoDHUD_RoundStarting for players —
-- RestorePlayerWeapons in SpawnPlayerAtSpawn needs this to fire correctly.
hook.Add("PlayerLoadout", "SeshBot_LoadoutOverride", function(ply)
    if not IsSeshMode() then return end

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
    FFA_BotStuckPos     = {}
    FFA_BotStuckTime    = {}
    FFA_BotUnstickUntil = {}
    FFA_BotOrbitDir     = {}
    FFA_BotStrafeDir    = {}
    FFA_BotStrafeT      = {}
    FFA_BotReactionTarget = {}
    FFA_BotReactionUntil  = {}
    FFA_BotFireState      = {}
    FFA_BotFireStateUntil = {}
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

local function GetNavSpawnFarFrom(existing, minDist)
    if not navAreas or #navAreas == 0 then
        return GetSpawnFarFrom(existing, minDist)
    end
    for attempt = 1, 30 do
        local area = navAreas[math.random(#navAreas)]
        local pos  = area:GetCenter()
        local ok   = true
        for _, ep in ipairs(existing) do
            if pos:Distance(ep) < minDist then ok = false break end
        end
        if ok then
            return pos + Vector(0, 0, 10), Angle(0, math.random(0, 360), 0)
        end
    end
    local best, bestD = navAreas[1]:GetCenter(), 0
    for _, area in ipairs(navAreas) do
        local pos  = area:GetCenter()
        local minD = math.huge
        for _, ep in ipairs(existing) do
            local d = pos:Distance(ep)
            if d < minD then minD = d end
        end
        if minD > bestD then bestD = minD best = pos end
    end
    return best + Vector(0, 0, 10), Angle(0, math.random(0, 360), 0)
end

local function SpawnAllBots()
    if FFA_Active then return end
    if not IsSeshMode() then return end
    if _G.SeshBot_ShowingScoreboard then return end
    if not navAreas or #navAreas == 0 then
        print("[Sesh Bots] No navmesh yet — waiting.")
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

    for i, name in ipairs(names) do
        timer.Simple((i - 1) * 0.15, function()
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
                -- right next to the player for an instant death.
                pos, ang = GetSpawnFarFrom(existing, 1400)
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
--  BOT AI — BFS PATHFINDING
-- ================================================================
-- Standard BFS: an O(1) dequeue via a head index (never shifting the array),
-- and parent pointers reconstructed into a path only once, at the end,
-- instead of cloning the entire path-so-far for every neighbor of every
-- node visited. The old version's per-neighbor full-path copy made a single
-- call blow up to O(V^2)-O(V^3) on a large/poorly-connected navmesh (long
-- corridors, or a target that's briefly unreachable) -- run per bot every
-- 0.5s, synchronously on the main thread, that was long enough to freeze
-- the whole game ("stopped responding") rather than throw a catchable error.
-- MAX_VISITED is a hard safety cap so even a pathological navmesh can't
-- make a single call run unbounded.
local MAX_BFS_VISITED = 2000

local function BFSPath(startArea, goalArea)
    if startArea == goalArea then return {goalArea} end

    local queue    = { startArea }
    local head     = 1
    local cameFrom = { [startArea] = false }
    local visitedCount = 1

    while head <= #queue do
        local cur = queue[head]
        head = head + 1

        for _, adj in ipairs(cur:GetAdjacentAreas()) do
            if cameFrom[adj] == nil then
                cameFrom[adj] = cur
                if adj == goalArea then
                    -- Reconstruct the path by walking parent pointers back to start
                    local path = { adj }
                    local node = cur
                    while node do
                        table.insert(path, 1, node)
                        node = cameFrom[node]
                    end
                    return path
                end
                visitedCount = visitedCount + 1
                if visitedCount > MAX_BFS_VISITED then
                    return nil -- safety cap hit -- give up this cycle, try again next update
                end
                table.insert(queue, adj)
            end
        end
    end
    return nil
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
    local dir = SafeNormalize(targetPos - botPos, bot:GetForward())
    local ang = dir:Angle()
    cmd:SetViewAngles(ang)
    bot:SetEyeAngles(ang)

    -- Reaction delay: bots used to be able to shoot the instant they got
    -- line of sight, with zero delay and 100% uptime -- effectively an
    -- aimbot. They still snap to face a target immediately (unchanged, per
    -- request), but now can't actually pull the trigger until a short
    -- randomized delay after acquiring (or re-acquiring, if they lost sight
    -- of it) this specific target has passed.
    if FFA_BotReactionTarget[bot] ~= target then
        FFA_BotReactionTarget[bot] = target
        FFA_BotReactionUntil[bot]  = CurTime() + math.Rand(0.25, 0.6)
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

    -- ── Stuck detection ─────────────────────────────────────────────────────
    -- Bots only ever move in a straight line toward their next waypoint/
    -- target with no obstacle avoidance, so they can walk face-first into a
    -- wall or corner and just stand there pushing forward forever. Track
    -- whether the bot has actually displaced over time; if it hasn't, force
    -- a fresh path and jump/strafe free for a moment.
    local lastPos = FFA_BotStuckPos[bot]
    if not lastPos or botPos:Distance(lastPos) > 40 then
        FFA_BotStuckPos[bot]  = botPos
        FFA_BotStuckTime[bot] = CurTime()
    elseif CurTime() - (FFA_BotStuckTime[bot] or CurTime()) > 1 then
        -- Hasn't moved 40+ units in over a second — consider it stuck
        FFA_BotUnstickUntil[bot] = CurTime() + 0.75
        FFA_BotOrbitDir[bot]     = (math.random(2) == 1) and 250 or -250
        FFA_PathUpdateT[bot]     = 0  -- force an immediate repath below
        FFA_BotStuckTime[bot]    = CurTime()
    end

    -- ── Pathfinding — update more frequently so bots feel more alive ──────
    if CurTime() > (FFA_PathUpdateT[bot] or 0) then
        FFA_PathUpdateT[bot] = CurTime() + 0.5  -- was 1.5s, now 0.5s

        -- Add a small random offset to the target position so bots don't
        -- all path to the exact same spot and merge into one pile
        local offset = Vector(
            math.random(-80, 80),
            math.random(-80, 80),
            0
        )
        local goalPos = targetPos + offset

        -- TEMP DIAGNOSTIC: kc_disable_bot_pathing 1 skips navmesh queries
        -- entirely (no GetNearestNavArea/GetAdjacentAreas/BFS at all) so we
        -- can isolate whether navmesh/pathing itself is what's freezing the
        -- game on this map, independent of how the BFS is implemented.
        if navAreas and #navAreas > 0 and not GetConVar("kc_disable_bot_pathing"):GetBool() then
            local sa = navmesh.GetNearestNavArea(botPos)
            local ga = navmesh.GetNearestNavArea(goalPos)
            if sa and ga then
                local path = BFSPath(sa, ga)
                if path and #path > 1 then
                    local wps = {}
                    for _, area in ipairs(path) do table.insert(wps, area:GetCenter()) end
                    FFA_BotPaths[bot] = { waypoints = wps, currentWaypoint = 2 }
                end
            end
        end
    end

    -- ── Movement ──────────────────────────────────────────────────────────
    local pd = FFA_BotPaths[bot]
    local moveDir = Vector(0, 0, 0)

    if pd and pd.waypoints and #pd.waypoints >= pd.currentWaypoint then
        local wp = pd.waypoints[pd.currentWaypoint]
        if botPos:Distance(wp) < 80 then
            pd.currentWaypoint = pd.currentWaypoint + 1
        end
        if pd.currentWaypoint <= #pd.waypoints then
            wp = pd.waypoints[pd.currentWaypoint]
            moveDir = SafeNormalize(wp - botPos, dir)
        else
            -- Reached end of path — head directly at target
            moveDir = dir
        end
    else
        -- No path — head directly at target so bots never stand idle
        moveDir = dir
    end

    -- Blend separation force into movement direction. The sum can land on
    -- (or extremely near) exactly zero if the separation push happens to be
    -- opposite and equal to moveDir -- SafeNormalize falls back to the
    -- pre-blend moveDir rather than ever normalizing a zero vector.
    if separationForce:Length() > 0 then
        moveDir = SafeNormalize(moveDir + separationForce * 0.6, moveDir)
    end

    if FFA_BotUnstickUntil[bot] and CurTime() < FFA_BotUnstickUntil[bot] then
        -- Stuck against geometry — jump and strafe sideways to break free
        -- instead of continuing to push forward into whatever is blocking it.
        cmd:SetButtons(bit.bor(cmd:GetButtons(), IN_JUMP))
        cmd:SetForwardMove(150)
        cmd:SetSideMove(FFA_BotOrbitDir[bot] or 250)
    else
        -- Stop closing in if already very close (prevents merging), but keep
        -- a light strafe going instead of a hard stop so bots stay moving/
        -- alive-looking rather than freezing in place next to their target.
        local STOP_DIST = 150
        if dist < STOP_DIST and separationForce:Length() < 0.1 then
            if CurTime() > (FFA_BotStrafeT[bot] or 0) then
                FFA_BotStrafeT[bot]   = CurTime() + math.random(15, 30) / 10
                FFA_BotStrafeDir[bot] = (math.random(2) == 1) and 1 or -1
            end
            cmd:SetForwardMove(0)
            cmd:SetSideMove(100 * (FFA_BotStrafeDir[bot] or 1))
        else
            cmd:SetForwardMove(200 * moveDir:Dot(ang:Forward()))
            cmd:SetSideMove(200 * moveDir:Dot(ang:Right()))
        end
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

    -- No kill-of-the-human to hang a killcam on (this may have been a
    -- bot-vs-bot kill) -- just leave the round-end/leaderboard screen up
    -- long enough to read, then clean up like every other match-over path.
    timer.Simple(14, SeshMatchOverCleanup)
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
        local pos, ang = GetSpawnFarFrom(existing, 900)
        victim:Spawn()
        victim:SetPos(pos)
        victim:SetEyeAngles(ang)
        if victim.SeshBotModel then victim:SetModel(victim.SeshBotModel) end
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
                _G.SeshTeam.OnSndRoundEnd("A")
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
    FFA_KillcamModel    = victim.SeshBotModel or victim:GetModel() or "models/player/kleiner.mdl"
    KC_BotKillID_Server = nil
    _G.SeshBot_KillcamIDLocked = true

    local winnerNick  = attacker:Nick()
    local winnerScore = kills
    local loserScore  = 0

    -- For S&D, display the match round score (e.g. "1-0") instead of
    -- per-round kill counts. Player team always wins this round (allDead).
    if IsSD() and _G.SeshTeam then
        local ST = _G.SeshTeam
        winnerScore = ST.roundsA + 1
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
            local pos, ang = GetSpawnFarFrom(existing, 1400)
            bot:Spawn()
            bot:SetPos(pos)
            bot:SetEyeAngles(ang)
            if bot.SeshBotModel then bot:SetModel(bot.SeshBotModel) end
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