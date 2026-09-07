--[[
    killcam_codhud_integration.lua
    ===============================
    Place this file in:
        kc_project\lua\autorun\killcam_codhud_integration.lua
--]]

local function IsSD()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

-- Returns the score display multiplier based on HUD type and gamemode.
function CoDHUD_GetScoreMultiplier()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return 100 end
    local gm = cv:GetString()
    if gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set" then return 1 end

    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"

    if hudType == "cod4" or hudType == "waw" then
        if gm == "dm" or gm == "sesh_dm" then return 5 end
        return 10  -- TDM and all other modes
    else
        -- MW2, MW3, BO1
        if gm == "dm" or gm == "sesh_dm" then return 50 end
        return 100
    end
end

local FACTION_SIDES = {
    ["mw2"]  = { friendly = { "rangers", "taskforce141", "seals" },  enemy = { "ussr", "arab", "militia" } },
    ["cod4"] = { friendly = { "marines", "sas" },                    enemy = { "ussr", "arab" } },
    ["waw"]  = { friendly = { "american" },                          enemy = { "soviet", "german", "japan" } },
    ["bo1"]  = { friendly = { "op4", "ops", "sog" },                 enemy = { "rus", "nva", "cub" } },
    ["mw3"]  = { friendly = { "delta", "sas", "gign" },              enemy = { "innercircle", "militia", "ussr", "pmc" } },
    ["bo2"]  = { friendly = { "seals", "fbi", "isa" },               enemy = { "sdc", "pmc", "cd" } },
}

local function IsFriendlyFaction(faction)
    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    local sides   = FACTION_SIDES[hudType] or FACTION_SIDES["mw2"]
    for _, f in ipairs(sides.friendly) do
        if f == faction then return true end
    end
    return false
end

if SERVER then

    AddCSLuaFile("killcam/cl_npcreplay.lua")

    include("ffa/sv_ffa_bots.lua")

    -- ================================================================
    --  SINGLE KILLCAM ENTRY POINT
    --  Every mode routes through this so the killcam always plays for
    --  the player who actually got the winning kill (KC_PendingKiller),
    --  not whoever happens to be first in player.GetAll() (the host).
    -- ================================================================
    -- NOTE: this file can load BEFORE the killcam core creates the global
    -- Killcam table, so we must not assume it exists yet. Create it if
    -- missing, and only look up Killcam.StartPlaying at call time (by which
    -- point the core has definitely loaded).
    Killcam = Killcam or {}
    function Killcam.BeginFor(killer)
        if GetGlobalBool("Killcam_Playing") then return end
        if not IsValid(killer) or not killer:IsPlayer() or killer:IsBot() then
            print("[KC] BeginFor: no valid human killer")
            return
        end
        if not (killer.KC_Recorder and killer.KC_Ready) then
            print("[KC] BeginFor: killer not ready -- " .. tostring(killer))
            return
        end
        if not Killcam.StartPlaying then
            print("[KC] BeginFor: Killcam.StartPlaying missing (core not loaded?)")
            return
        end
        print("[KC] BeginFor: starting killcam for " .. killer:Nick())
        Killcam.StartPlaying(killer)
    end

    NPC_FactionScores      = NPC_FactionScores or {}
    NPC_FactionAssignments = NPC_FactionAssignments or {}
    NPC_LockedEnemyFaction = NPC_LockedEnemyFaction or nil
    SD_MatchScores         = SD_MatchScores  or {}
    SD_RoundActive         = SD_RoundActive  or false
    SD_RoundEnding         = SD_RoundEnding  or false
    SD_PlayerDead          = SD_PlayerDead   or false
    SD_SavedWeapons        = SD_SavedWeapons or {}
    _G.SD_SavedWeapons     = SD_SavedWeapons

    util.AddNetworkString("CoDHUD_NPC_FactionScore")
    util.AddNetworkString("CoDHUD_NPC_ResetScores")
    util.AddNetworkString("CoDHUD_SD_MatchScores")
    util.AddNetworkString("CoDHUD_SD_StopSuspense")

    local function SyncNPCScore(faction, score)
        net.Start("CoDHUD_NPC_FactionScore")
            net.WriteString(faction)
            net.WriteInt(score, 16)
        net.Broadcast()
    end

    local function SyncNPCReset()
        net.Start("CoDHUD_NPC_ResetScores")
        net.Broadcast()
        NPC_FactionScores      = {}
        NPC_FactionAssignments = {}
        NPC_LockedEnemyFaction = nil
    end

    local function SyncSDMatchScores()
        net.Start("CoDHUD_SD_MatchScores")
            net.WriteTable(SD_MatchScores)
        net.Broadcast()
    end

    local function StopSuspenseOnClients()
        net.Start("CoDHUD_SD_StopSuspense")
        net.Broadcast()
    end

    local function GetLockedEnemyFaction(ply)
        if NPC_LockedEnemyFaction then return NPC_LockedEnemyFaction end
        local hudType   = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
        local sides     = FACTION_SIDES[hudType] or FACTION_SIDES["mw2"]
        local myFaction = ply:GetNW2String("CoDHUD_Faction", "rangers")
        local pool      = IsFriendlyFaction(myFaction) and sides.enemy or sides.friendly
        NPC_LockedEnemyFaction = pool[math.random(#pool)]
        print("[KC] Enemy faction locked: " .. NPC_LockedEnemyFaction)
        return NPC_LockedEnemyFaction
    end

    local function AssignNPCFaction(npc)
        if not IsValid(npc) then return end
        local ply = nil
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then ply = p break end
        end
        local faction = "ussr"
        if ply then faction = GetLockedEnemyFaction(ply) end
        npc:SetNW2String("CoDHUD_Faction", faction)
        NPC_FactionAssignments[npc:EntIndex()] = faction
        NPC_FactionScores[faction] = NPC_FactionScores[faction] or 0
        SyncNPCScore(faction, NPC_FactionScores[faction])
        print("[KC] NPC " .. npc:GetClass() .. " -> " .. faction)
    end

    local function RemoveAllNPCs()
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() then ent:Remove() end
        end
        -- Clear assignments so stale entindices from removed NPCs
        -- don't trigger a false win condition next round.
        NPC_FactionAssignments = {}
        print("[KC SD] All NPCs removed.")
    end

    local function GetRandomSpawn()
        local spawns = ents.FindByClass("info_player_start")
        if #spawns == 0 then spawns = ents.FindByClass("info_player_terrorist") end
        if #spawns == 0 then spawns = ents.FindByClass("info_player_counterterrorist") end
        if #spawns > 0 then return spawns[math.random(#spawns)] end
        return nil
    end

    local function SavePlayerWeapons(p)
        if not IsValid(p) then return end
        local weps = {}
        for _, wep in ipairs(p:GetWeapons()) do
            if IsValid(wep) then
                table.insert(weps, wep:GetClass())
            end
        end
        -- SD_EndRound also calls this a few seconds AFTER the player already
        -- died (to snapshot their loadout for next round), by which point a
        -- dead, not-yet-respawned player can enumerate zero weapons. Never
        -- let that spurious empty read stomp a real loadout that was already
        -- saved at the moment of death (SeshBot_SaveLoadout / an earlier call
        -- here) -- that clobber is what dropped the player's guns on a round
        -- loss.
        if #weps == 0 and SD_SavedWeapons[p:UserID()] and #SD_SavedWeapons[p:UserID()] > 0 then
            return
        end
        SD_SavedWeapons[p:UserID()] = weps
        local activeWep = p:GetActiveWeapon()
        SD_SavedWeapons[p:UserID()].active = IsValid(activeWep) and activeWep:GetClass() or nil
        -- Also sync to PlayerLoadouts so SeshBot_LoadoutOverride can restore
        -- the correct weapons when the player spawns at the next round start.
        if _G.PlayerLoadouts then
            _G.PlayerLoadouts[p:UserID()] = {
                weapons = table.Copy(SD_SavedWeapons[p:UserID()]),
                active  = SD_SavedWeapons[p:UserID()].active,
            }
        end
    end

    local function RestorePlayerWeapons(p)
        if not IsValid(p) then return end
        -- For sesh modes, prefer PlayerLoadouts (kept in sync by SeshBot_SaveLoadout)
        -- so the loadout saved on death is used rather than the stale SD_SavedWeapons.
        local uid = p:UserID()
        local saved
        local gm = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""
        local isSesh = (gm == "sesh_sd" or gm == "sesh_sd_set" or gm == "sesh_war" or gm == "sesh_dm")
        if isSesh and _G.PlayerLoadouts and _G.PlayerLoadouts[uid] and _G.PlayerLoadouts[uid].weapons and #_G.PlayerLoadouts[uid].weapons > 0 then
            saved = _G.PlayerLoadouts[uid]
        else
            saved = SD_SavedWeapons[uid]
        end
        if not saved then return end
        p:StripWeapons()
        for _, wepClass in ipairs(saved.weapons or saved) do
            p:Give(wepClass)
        end
        if saved.active then
            p:SelectWeapon(saved.active)
        end
    end

    local function SpawnPlayerAtSpawn(p, freeze, giveWeapons)
        if not IsValid(p) then return end
        -- Preserve frags across the respawn. Plain "sd" shows round wins here;
        -- sesh_sd's tab scoreboard instead shows the human's cumulative match
        -- kill count (SeshSD_MatchKills) -- the round-win tally is a separate
        -- number shown only on the bottom-left bar (SeshTeam.roundsA/B).
        local gmNow = GetConVar("codhud_selected_gamemode"):GetString()
        local roundWins
        if (gmNow == "sesh_sd" or gmNow == "sesh_sd_set") and not p:IsBot() then
            roundWins = p:GetNW2Int("SeshSD_MatchKills", 0)
        else
            local fac = p:GetNW2String("CoDHUD_Faction", "")
            roundWins = (fac ~= "" and SD_MatchScores and SD_MatchScores[fac]) or 0
        end
        p:SetFrags(roundWins)
        -- Same deal for Deaths -- sesh_sd humans keep their cumulative match
        -- death count (SeshSD_MatchDeaths) instead of it zeroing every round.
        if (gmNow == "sesh_sd" or gmNow == "sesh_sd_set") and not p:IsBot() then
            p:SetDeaths(p:GetNW2Int("SeshSD_MatchDeaths", 0))
        else
            p:SetDeaths(0)
        end
        p:UnSpectate()
        p:Spawn()
        local sp = GetRandomSpawn()
        if IsValid(sp) then
            p:SetPos(sp:GetPos() + Vector(0, 0, 10))
            p:SetEyeAngles(sp:GetAngles())
        end
        if giveWeapons then RestorePlayerWeapons(p) end
        if freeze then p:Freeze(true) end
    end

    local SD_FixSpawnActive = false
    local SD_FixSpawnEnd    = 0
    local SD_FixSpawnPos    = nil
    local SD_FixSpawnAng    = nil

    hook.Add("KillcamReplayStopped", "CoDHUD_SD_FixPosition", function()
        if not IsSD() then return end
        local sp = GetRandomSpawn()
        if not IsValid(sp) then return end
        SD_FixSpawnPos = sp:GetPos() + Vector(0, 0, 10)
        SD_FixSpawnAng = sp:GetAngles()
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then p:Freeze(true) end
        end
        SD_FixSpawnActive = true
        SD_FixSpawnEnd    = CurTime() + 1.0
        timer.Simple(1.1, function()
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) then RestorePlayerWeapons(p) end
            end
        end)
    end)

    hook.Add("Think", "CoDHUD_SD_FixSpawnThink", function()
        if not SD_FixSpawnActive then return end
        if not IsSD() then SD_FixSpawnActive = false return end
        if CurTime() > SD_FixSpawnEnd then
            SD_FixSpawnActive = false
            return
        end
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and SD_FixSpawnPos then
                p:SetPos(SD_FixSpawnPos)
                p:SetEyeAngles(SD_FixSpawnAng)
                p:Freeze(true)
            end
        end
    end)

    hook.Add("PlayerSpawnedNPC", "CoDHUD_AssignNPCFaction", function(ply, npc)
        AssignNPCFaction(npc)
        if IsSD() then SD_RoundActive = true end
    end)

    hook.Add("OnNPCCreated", "CoDHUD_AssignNPCFaction_Fallback", function(npc)
        timer.Simple(0.2, function()
            if IsValid(npc) and npc:GetNW2String("CoDHUD_Faction", "") == "" then
                AssignNPCFaction(npc)
            end
        end)
    end)

    -- Keep bots on the same faction as the real player so FFA shows one list
    -- Freeze bots when they spawn during a round countdown so they can't
    -- move or shoot until the round actually starts.
    hook.Add("PlayerSpawn", "CoDHUD_FreezeBotOnCountdown", function(ply)
        if not ply:IsBot() then return end
        if not IsSD() then return end
        if not CoDHUD_RoundStarting then return end
        timer.Simple(0.15, function()
            if IsValid(ply) and CoDHUD_RoundStarting then
                ply:Freeze(true)
            end
        end)
    end)

    hook.Add("PlayerSpawn", "CoDHUD_BotFactionSync", function(ply)
        if not ply:IsBot() then return end
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            -- For sesh_sd/sesh_war, bots already have their own enemy faction
            -- set by sv_ffa_bots.lua -- don't overwrite it with the player's
            -- faction, or the scoreboard won't be able to divide teams.
            local gmCV = GetConVar("codhud_selected_gamemode")
            if gmCV then
                local gm = gmCV:GetString()
                if gm == "sesh_sd" or gm == "sesh_sd_set" or gm == "sesh_war" then return end
            end
            local playerFaction = "marines"
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then
                    local f = p:GetNW2String("CoDHUD_Faction", "")
                    if f ~= "" then playerFaction = f break end
                end
            end
            ply:SetNW2String("CoDHUD_Faction", playerFaction)
            -- Don't force team 0 on bots in FFA -- they need team 1 for minimap
        end)
    end)

    local KC_LastGame = ""
    hook.Add("Think", "CoDHUD_BotFactionOnGameChange", function()
        local cv = GetConVar("codhud_game")
        if not cv then return end
        local game = cv:GetString()
        if game == KC_LastGame then return end
        KC_LastGame = game
        -- For sesh_sd/sesh_war, bot factions are set by sv_ffa_bots -- skip.
        local gmCV = GetConVar("codhud_selected_gamemode")
        if gmCV then
            local gm = gmCV:GetString()
            if gm == "sesh_sd" or gm == "sesh_sd_set" or gm == "sesh_war" then return end
        end
        -- Game changed -- re-sync bot factions after a short delay
        timer.Simple(1, function()
            local playerFaction = nil
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then
                    local f = p:GetNW2String("CoDHUD_Faction", "")
                    if f ~= "" then playerFaction = f break end
                end
            end
            if not playerFaction then return end
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and p:IsBot() then
                    p:SetNW2String("CoDHUD_Faction", playerFaction)
                    -- Don't set team here -- FFA_NoTeams Think hook handles it
                end
            end
        end)
    end)

    -- In FFA, set real players to team 0 and bots to team 1 for minimap color
    hook.Add("Think", "CoDHUD_FFA_NoTeams", function()
        local cv = GetConVar("codhud_selected_gamemode")
        if not cv then return end
        local gm = cv:GetString()
        if gm ~= "sesh_dm" and gm ~= "dm" then return end
        for _, p in ipairs(player.GetAll()) do
            if not IsValid(p) then continue end
            if p:IsBot() then
                -- Bots on team 1 so minimap shows them as red/enemy
                if p:Team() ~= 1 then p:SetTeam(1) end
            else
                if p:Team() ~= 0 then p:SetTeam(0) end
            end
        end
    end)

    -- Allow damage between all players/bots in FFA using proper hook
    hook.Add("PlayerShouldTakeDamage", "CoDHUD_FFA_FriendlyFire", function(target, attacker)
        local cv = GetConVar("codhud_selected_gamemode")
        if not cv then return end
        local gm = cv:GetString()
        if gm ~= "sesh_dm" and gm ~= "dm" then return end
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if attacker == target then return end
        -- Return true = allow damage, XP and kill credit will work normally
        return true
    end)

    -- Waits for the killcam to finish, then calls the callback.
    -- First waits for killcam to START, then waits for it to END.
    -- Falls back after maxWait seconds in case something goes wrong.
    -- Exposed as a global so sv_roundend.lua can use it too.
    function WaitForKillcamThenRun(callback, maxWait)
        local called = false
        local function SafeCallback()
            if called then return end
            called = true
            timer.Simple(0.5, callback)
        end

        local function PollEnd(deadline)
            if not GetGlobalBool("Killcam_Playing") then
                SafeCallback()
            elseif CurTime() > deadline then
                print("[KC SD] Killcam end-wait timeout -- forcing round transition.")
                SafeCallback()
            else
                timer.Simple(0.5, function() PollEnd(deadline) end)
            end
        end

        local function PollStart(deadline)
            if GetGlobalBool("Killcam_Playing") then
                PollEnd(deadline)
            elseif CurTime() > deadline then
                print("[KC SD] Killcam start-wait timeout -- forcing round transition.")
                SafeCallback()
            else
                timer.Simple(0.5, function() PollStart(deadline) end)
            end
        end

        -- Start polling after 1s (gives killcam time to begin).
        -- SafeCallback ensures DoNextPhase only ever fires once.
        local deadline = CurTime() + (maxWait or 45)
        timer.Simple(1, function()
            PollStart(deadline)
        end)
    end

    -- Track the last SD round-ending killer so we know whether to show killcam
    local SD_LastKillerIsHuman = false

    local function SD_EndRound(playerWon, timedOut)
        if SD_RoundEnding then return end
        if not IsSD() then return end
        SD_RoundEnding = true
        SD_RoundActive = false

        local gm     = GetConVar("codhud_selected_gamemode"):GetString()
        local isSesh = (gm == "sesh_sd" or gm == "sesh_sd_set")

        local hudType       = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
        local sides         = FACTION_SIDES[hudType] or FACTION_SIDES["mw2"]
        local npcFaction    = NPC_LockedEnemyFaction or sides.enemy[1] or "ussr"
        local playerFaction = sides.friendly[1] or "rangers"

        if isSesh then
            -- Sesh bots never set NPC_LockedEnemyFaction (that's only used by the
            -- plain "sd" NPC mode) and their faction isn't guaranteed to be
            -- FACTION_SIDES.enemy[1] for every HUD (e.g. cod4/waw/bo1/mw3 bots
            -- use a different faction than that guess) -- read it directly off
            -- a real bot instead so scores/kills always land on the right side.
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and p:IsBot() then
                    local f = p:GetNW2String("CoDHUD_Faction", "")
                    if f ~= "" then npcFaction = f break end
                end
            end
        end

        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and not p:IsBot() then
                local f = p:GetNW2String("CoDHUD_Faction", "")
                if f ~= "" then
                    -- Validate the faction exists in FACTION_SIDES for this HUD
                    local valid = false
                    for _, sf in ipairs(sides.friendly) do
                        if sf == f then valid = true break end
                    end
                    if not valid then
                        for _, sf in ipairs(sides.enemy) do
                            if sf == f then valid = true break end
                        end
                    end
                    if valid then playerFaction = f break end
                end
            end
        end

        -- Sesh S&D: SeshTeam.roundsA/roundsB is the single source of truth for
        -- round wins (also used by the player-wins-the-round path in
        -- sv_ffa_bots.lua via SeshTeam.OnSndRoundEnd). Increment it here, once,
        -- immediately -- do NOT re-derive it later from SD_MatchScores, since
        -- the player-win path never touches SD_MatchScores and doing so wiped
        -- out the other team's already-recorded win/kills.
        if isSesh and _G.SeshTeam then
            local ST = _G.SeshTeam
            if playerWon then ST.roundsA = ST.roundsA + 1 else ST.roundsB = ST.roundsB + 1 end
            ST.BroadcastScores()
        end

        if playerWon then
            SD_MatchScores[playerFaction] = (SD_MatchScores[playerFaction] or 0) + 1
            print("[KC SD] Player wins round! " .. playerFaction .. ": " .. SD_MatchScores[playerFaction])
        else
            SD_MatchScores[npcFaction] = (SD_MatchScores[npcFaction] or 0) + 1
            print("[KC SD] NPC team wins round! " .. npcFaction .. ": " .. SD_MatchScores[npcFaction])
        end

        SyncSDMatchScores()
        StopSuspenseOnClients()

        local scoreLimit  = GetConVar("codhud_score_limit"):GetInt()
        if scoreLimit <= 0 then scoreLimit = 4 end

        local playerScore = SD_MatchScores[playerFaction] or 0
        local npcScore    = SD_MatchScores[npcFaction]    or 0
        local matchOver   = playerScore >= scoreLimit or npcScore >= scoreLimit

        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and p:Alive() then p:Freeze(true) end
        end

        -- Tab scoreboard credit: the bottom-left round-win bar reads
        -- SeshTeam.roundsA/B (set above) independently of this. The tab
        -- scoreboard's Frags column is a DIFFERENT number for sesh: humans
        -- show their cumulative match kill count (SeshSD_MatchKills, which
        -- SeshBot_ResetRound also restores from every round), bots show a
        -- per-round kill count that SeshBot_PlayerDeath/SeshBot_ResetRound
        -- already manage -- so leave bot Frags untouched here.
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then
                if isSesh and _G.SeshTeam then
                    if not p:IsBot() then
                        p:SetFrags(p:GetNW2Int("SeshSD_MatchKills", 0))
                    end
                else
                    p:SetFrags(SD_MatchScores[p:GetNW2String("CoDHUD_Faction", playerFaction)] or 0)
                end
            end
        end
        NPC_FactionScores[npcFaction] = npcScore
        SyncNPCScore(npcFaction, npcScore)

        local winFac  = playerWon and playerFaction or npcFaction
        local loseFac = playerWon and npcFaction or playerFaction

        -- For sesh_sd, use SeshTeam.roundsA/roundsB (the same single source
        -- of truth the live bottom-left bar reads) instead of SD_MatchScores
        -- here -- SD_MatchScores[playerFaction] is never incremented on the
        -- player-wins-the-round path (that path doesn't go through this
        -- function at all, see sv_ffa_bots.lua), so it stays stale/wrong
        -- whenever the bots win a round, which fed the wrong number into
        -- this round-end announcement popup.
        local winScore, loseScore
        if isSesh and _G.SeshTeam then
            local ST = _G.SeshTeam
            winScore  = playerWon and ST.roundsA or ST.roundsB
            loseScore = playerWon and ST.roundsB or ST.roundsA
        else
            winScore  = SD_MatchScores[winFac]  or 0
            loseScore = SD_MatchScores[loseFac] or 0
        end

        timer.Simple(0.5, function()
            net.Start("CoDHUD_RoundEnd")
                net.WriteString(winFac)
                net.WriteString(loseFac)
                net.WriteInt(winScore,  32)
                net.WriteInt(loseScore, 32)
            net.Broadcast()
        end)

        -- Only attempt killcam if round ended by a real human player's kill.
        -- - Player won (killed last NPC): always show killcam (human made the kill)
        -- - Enemy won by kill: only if a real human player died to another human
        -- - Time limit / bot kill / NPC kill: skip killcam, go straight to reset
        local doKillcam = not timedOut and (playerWon or SD_LastKillerIsHuman)
        SD_LastKillerIsHuman = false  -- reset for next round

        if doKillcam then
            timer.Simple(6, function()
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) then
                        SavePlayerWeapons(p)
                        if p:Alive() then
                            p:Freeze(false)
                            p:StripWeapons()
                            p:KillSilent()
                        end
                        p:Spectate(OBS_MODE_ROAMING)
                    end
                end

                timer.Simple(0.5, function()
                    Killcam.BeginFor(_G.KC_PendingKiller)
                end)
            end)
        end

        local function DoNextPhase()
            -- Guard: if we somehow fire twice, bail immediately
            if not SD_RoundEnding then return end
            SD_RoundEnding = false
            SD_PlayerDead  = false
            SD_RoundActive = false

            if isSesh and _G.SeshTeam then
                -- ST.roundsA/B were already incremented (once) right when the
                -- round ended above -- do not re-derive them from SD_MatchScores
                -- here, that was the source of the score-corruption bug where
                -- winning a round could wipe out the other side's prior win.
                local ST = _G.SeshTeam

                local lim       = GetConVar("sesh_sd_rounds"):GetInt()
                local maxRounds = GetConVar("sesh_sd_maxrounds"):GetInt()
                local totalRounds = ST.roundsA + ST.roundsB
                local matchDone = false

                if ST.roundsA >= lim and not ST.gameOver then
                    ST.gameOver = true
                    ST.BroadcastRoundResult("A")
                    matchDone = true
                elseif ST.roundsB >= lim and not ST.gameOver then
                    ST.gameOver = true
                    ST.BroadcastRoundResult("B")
                    matchDone = true
                elseif totalRounds >= maxRounds and not ST.gameOver then
                    ST.gameOver = true
                    local finalWinner = (ST.roundsA >= ST.roundsB) and "A" or "B"
                    ST.BroadcastRoundResult(finalWinner)
                    matchDone = true
                end

                if matchDone then
                    -- Match over: kick all bots then return to lobby
                    for _, p in ipairs(player.GetAll()) do
                        if IsValid(p) and p:IsBot() then
                            RunConsoleCommand("kickid", p:UserID())
                        end
                    end
                    timer.Simple(4, function()
                        SD_MatchScores = {}
                        SyncSDMatchScores()
                        SyncNPCReset()
                        RemoveAllNPCs()
                        ST.Reset()
                        -- Clear the cumulative match kill/death counters so the
                        -- next match starts fresh instead of carrying over --
                        -- sv_ffa_bots.lua's own match-over cleanup (the
                        -- player-wins-the-match path) already does this; this
                        -- is the same reset for the bot-wins-the-match path.
                        for _, p in ipairs(player.GetAll()) do
                            if IsValid(p) and not p:IsBot() then
                                p:SetNW2Int("SeshSD_MatchKills", 0)
                                p:SetNW2Int("SeshSD_MatchDeaths", 0)
                            end
                        end
                        for _, p in ipairs(player.GetAll()) do
                            SpawnPlayerAtSpawn(p, false, false)
                        end
                        print("[KC SD] Match over -- reset done.")

                        -- Let sv_lobby.lua know the match is over so it can
                        -- reopen the pre-game lobby for everyone.
                        hook.Run("KC_MatchEnded")
                    end)
                else
                    -- Next round: reset bots via SeshBot_ResetRound then
                    -- respawn and freeze the human player with a countdown.
                    -- Extend SeshBot_RoundResetTime to cover countdown +
                    -- the objective text animation (~4s) so bots stay frozen
                    -- until "Destroy A/B" finishes on the player's screen.
                    local matchtimer = GetConVar("codhud_matchstart_timer"):GetInt()
                    SeshBot_RoundResetTime = CurTime() + matchtimer + 5
                    if _G.SeshBot_ResetRound then
                        timer.Simple(3, function()
                            if _G.SeshBot_ResetRound then _G.SeshBot_ResetRound() end
                        end)
                    end

                    RemoveAllNPCs()
                    NPC_FactionScores[npcFaction] = 0
                    SyncNPCScore(npcFaction, 0)

                    local matchtimer = GetConVar("codhud_matchstart_timer"):GetInt()
                    local maxtimer   = GetConVar("codhud_time_limit"):GetFloat()

                    CoDHUD_RoundStarting   = true
                    CoDHUD_RoundStartTimer = CurTime() + matchtimer

                    if maxtimer > 0 then
                        CoDHUD_RoundEndTimeSV = CurTime() + (matchtimer + 1) + (maxtimer * 60)
                    else
                        CoDHUD_RoundEndTimeSV = nil
                    end

                    for _, p in ipairs(player.GetAll()) do
                        if IsValid(p) and not p:IsBot() then
                            SpawnPlayerAtSpawn(p, true, true)
                        end
                    end

                    net.Start("CoDHUD_RoundStart")
                        net.WriteString(gm)
                        net.WriteInt(matchtimer, 6)
                        net.WriteInt(maxtimer, 32)
                        net.WriteFloat(CoDHUD_RoundEndTimeSV or 0)
                    net.Broadcast()

                    timer.Create("CoDHUD_SD_RoundStartTime", matchtimer > 0 and matchtimer or 0.15, 1, function()
                        CoDHUD_RoundStarting   = false
                        CoDHUD_RoundStartTimer = nil
                        if IsSD() then SD_RoundActive = true end
                        for _, p in ipairs(player.GetAll()) do
                            if IsValid(p) and not p:IsBot() then
                                p:Freeze(false)
                                -- Tab scoreboard shows cumulative match kills for
                                -- sesh -- NOT the round-win count (that's the
                                -- separate bottom-left bar). Using roundsA here
                                -- overwrote a player's real kill total with a much
                                -- smaller number every round transition.
                                p:SetFrags(p:GetNW2Int("SeshSD_MatchKills", 0))
                            end
                        end
                    end)

                    print("[KC SD] Next round! Score: " .. playerFaction .. " " .. ST.roundsA .. " - " .. npcFaction .. " " .. ST.roundsB)
                end
            else
                -- Normal sd (NPC mode)
                RemoveAllNPCs()
                NPC_FactionScores[npcFaction] = 0
                SyncNPCScore(npcFaction, 0)

                if matchOver then
                    timer.Simple(4, function()
                        SD_MatchScores = {}
                        SyncSDMatchScores()
                        SyncNPCReset()
                        RemoveAllNPCs()
                        for _, p in ipairs(player.GetAll()) do
                            SpawnPlayerAtSpawn(p, false, false)
                        end
                        print("[KC SD] Match over -- reset done.")
                    end)
                else
                    local matchtimer = GetConVar("codhud_matchstart_timer"):GetInt()
                    local maxtimer   = GetConVar("codhud_time_limit"):GetFloat()

                    CoDHUD_RoundStarting   = true
                    CoDHUD_RoundStartTimer = CurTime() + matchtimer

                    if maxtimer > 0 then
                        CoDHUD_RoundEndTimeSV = CurTime() + (matchtimer + 1) + (maxtimer * 60)
                    else
                        CoDHUD_RoundEndTimeSV = nil
                    end

                    for _, p in ipairs(player.GetAll()) do
                        SpawnPlayerAtSpawn(p, true, true)
                    end

                    net.Start("CoDHUD_RoundStart")
                        net.WriteString(gm)
                        net.WriteInt(matchtimer, 6)
                        net.WriteInt(maxtimer, 32)
                        net.WriteFloat(CoDHUD_RoundEndTimeSV or 0)
                    net.Broadcast()

                    timer.Create("CoDHUD_SD_RoundStartTime", matchtimer > 0 and matchtimer or 0.15, 1, function()
                        CoDHUD_RoundStarting   = false
                        CoDHUD_RoundStartTimer = nil
                        if IsSD() then SD_RoundActive = true end
                        for _, p in ipairs(player.GetAll()) do
                            if IsValid(p) then
                                p:Freeze(false)
                                local fac = p:GetNW2String("CoDHUD_Faction", "")
                                if fac ~= "" and SD_MatchScores then
                                    p:SetFrags(SD_MatchScores[fac] or 0)
                                end
                            end
                        end
                    end)

                    print("[KC SD] Next round! Score: " .. playerFaction .. " " .. playerScore .. " - " .. npcFaction .. " " .. npcScore)
                end
            end
        end

        if timedOut or not doKillcam then
            -- No killcam -- wait 6s for round-end screen then reset
            timer.Simple(6, function()
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) then
                        SavePlayerWeapons(p)
                        if p:Alive() then
                            p:Freeze(false)
                            p:StripWeapons()
                            p:KillSilent()
                        end
                        p:Spectate(OBS_MODE_ROAMING)
                    end
                end
                timer.Simple(1, DoNextPhase)
            end)
        else
            WaitForKillcamThenRun(DoNextPhase, 45)
        end
    end
    -- Expose for sv_ffa_bots.lua to call when player dies in sesh_sd
    _G.SD_EndRound = SD_EndRound

    local SD_CheckThrottle = 0

    -- Set SD_RoundActive when the countdown ends, regardless of which code
    -- path started the round. This covers sv_roundend.lua, the menu start
    -- button, and any other path that uses CoDHUD_RoundStarting.
    local SD_WasRoundStarting = false
    hook.Add("Think", "CoDHUD_SD_RoundActiveTracker", function()
        if not IsSD() then return end
        local starting = CoDHUD_RoundStarting and true or false
        if SD_WasRoundStarting and not starting then
            -- Countdown just ended -- only activate if not mid-round-end
            if not SD_RoundEnding then
                SD_RoundActive = true
                print("[KC SD] Countdown ended - SD_RoundActive = true")
            end
        end
        SD_WasRoundStarting = starting
    end)

    hook.Add("Think", "CoDHUD_SD_TimeLimit", function()
        if not IsSD() then return end
        if not CoDHUD_RoundEndTimeSV then return end
        if CurTime() < CoDHUD_RoundEndTimeSV then return end
        if not _G.SD_TL_Printed then
            _G.SD_TL_Printed = true
            print("[KC SD TimeLimit] expired: SD_RoundActive=" .. tostring(SD_RoundActive) .. " SD_RoundEnding=" .. tostring(SD_RoundEnding))
        end
        if not SD_RoundActive then return end
        if SD_RoundEnding then return end
        _G.SD_TL_Printed = nil
        -- Time ran out in S&D -- enemy team wins this round
        print("[KC SD] Time limit reached - enemy wins round")
        SD_EndRound(false, true)
    end)

    hook.Add("Think", "CoDHUD_SD_RoundCheck", function()
        if not IsSD() then return end
        if not SD_RoundActive then return end
        if SD_RoundEnding then return end

        -- sesh_sd round-end is fully managed by sv_ffa_bots.lua's
        -- BotKillSetKill hook. Don't duplicate or conflict with it here.
        local gmCV = GetConVar("codhud_selected_gamemode")
        if gmCV and (gmCV:GetString() == "sesh_sd" or gmCV:GetString() == "sesh_sd_set") then return end

        local now = CurTime()
        if now < SD_CheckThrottle then return end
        SD_CheckThrottle = now + 0.5

        local hudType    = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
        local sides      = FACTION_SIDES[hudType] or FACTION_SIDES["mw2"]
        local npcFaction = NPC_LockedEnemyFaction or sides.enemy[1]

        -- Normal sd (NPC mode) only below this point.
        -- Check NPC enemies first so simultaneous kill+death gives player the win.
        if npcFaction then
            local total, alive = 0, 0
            for id, faction in pairs(NPC_FactionAssignments) do
                if faction == npcFaction then
                    total = total + 1
                    local npc = Entity(id)
                    if IsValid(npc) and npc:IsNPC() and npc:Health() > 0 then
                        alive = alive + 1
                    end
                end
            end
            if total > 0 and alive == 0 then
                SD_EndRound(true)
                return
            end
        end

        -- Check if the human player is dead (enemy wins)
        local ply = nil
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and not p:IsBot() then ply = p break end
        end
        if IsValid(ply) and not ply:Alive() then
            SD_EndRound(false)
        end
    end)

    -- Track in S&D whether the player was killed by a real human (for killcam).
    -- NPC kills and bot kills skip the killcam; only real players trigger it.
    hook.Add("PlayerDeath", "CoDHUD_SD_TrackKiller", function(victim, inflictor, attacker)
        if not IsSD() then return end
        if not SD_RoundActive then return end
        if IsValid(attacker) and attacker:IsPlayer() and not attacker:IsBot() then
            SD_LastKillerIsHuman = true
            _G.KC_PendingKiller  = attacker
        else
            SD_LastKillerIsHuman = false
        end
    end)

    hook.Add("PlayerDeathThink", "CoDHUD_SD_NoRespawn", function(ply)
        if not IsSD() then return end
        if SD_RoundActive or SD_RoundEnding then return false end
    end)

    hook.Add("PlayerDeath", "CoDHUD_NPCKillsPlayer", function(victim, inflictor, attacker)
        if not IsValid(attacker) or not attacker:IsNPC() then return end
        if IsSD() then return end
        local faction = attacker:GetNW2String("CoDHUD_Faction", "")
        if faction == "" then
            faction = NPC_FactionAssignments[attacker:EntIndex()] or NPC_LockedEnemyFaction or "ussr"
        end
        NPC_FactionScores[faction] = (NPC_FactionScores[faction] or 0) + 1
        SyncNPCScore(faction, NPC_FactionScores[faction])
        local scoreLimit = GetConVar("codhud_score_limit"):GetInt()
        if scoreLimit <= 0 then scoreLimit = 75 end
        if NPC_FactionScores[faction] >= scoreLimit then
            local playerFaction = IsValid(victim) and victim:GetNW2String("CoDHUD_Faction", "rangers") or "rangers"
            local playerScore   = 0
            for _, p in ipairs(player.GetAll()) do
                playerScore = playerScore + math.max(0, p:Frags())
            end
            if not RE_Triggered then
                net.Start("CoDHUD_RoundEnd")
                    net.WriteString(faction)
                    net.WriteString(playerFaction)
                    net.WriteInt(NPC_FactionScores[faction], 32)
                    net.WriteInt(playerScore, 32)
                net.Broadcast()
            end
        end
    end)

    -- Floater freeze: cod4/waw/bo1 only -- freeze the player in place the instant
    -- they get the final kill, including locking position mid-air every tick.
    local FLOATER_HUDS = { cod4 = true, waw = true, bo1 = true }
    local floaterPos = nil
    local floaterAng = nil
    local floaterActive = false
    local floaterPlayer = nil

    local function IsFloaterHUD()
        local cv = GetConVar("codhud_game")
        if cv and FLOATER_HUDS[cv:GetString()] then return true end
        if CoDHUD_GetHUDType and FLOATER_HUDS[CoDHUD_GetHUDType()] then return true end
        return false
    end

    -- Combined score for every human on a faction, plus that faction's NPC
    -- kills -- matches what sv_roundend.lua's round-end check already sums,
    -- so multiple humans on the same team (host + non-host) correctly
    -- combine toward the limit instead of only one player's own Frags().
    local function GetFactionTotal(faction)
        local total = 0
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and not p:IsBot() and p:GetNW2String("CoDHUD_Faction", "") == faction then
                total = total + math.max(0, p:Frags())
            end
        end
        if NPC_FactionScores and NPC_FactionScores[faction] then
            total = total + NPC_FactionScores[faction]
        end
        return total
    end

    local function IsRoundEndingKill(attacker, npc)
        if not IsFloaterHUD() then return false end
        if IsSD() then
            local npcFaction = NPC_LockedEnemyFaction
            if not npcFaction then return false end
            local alive = 0
            for id, faction in pairs(NPC_FactionAssignments) do
                if faction == npcFaction then
                    local ent = Entity(id)
                    if IsValid(ent) and ent:IsNPC() and ent:Health() > 0 and ent ~= npc then
                        alive = alive + 1
                    end
                end
            end
            return alive == 0
        else
            -- Non-SD: trigger on the final kill, using the ATTACKER'S FACTION
            -- combined total (not just the attacker's own Frags()) so kills
            -- split across multiple humans on the same team still trigger it.
            -- Hook ordering isn't guaranteed -- the total may be pre- or
            -- post-increment for this kill -- so check both scoreLimit and
            -- scoreLimit-1.
            local scoreLimit = GetConVar("codhud_score_limit"):GetInt()
            if scoreLimit <= 0 then scoreLimit = 75 end
            local faction = attacker:GetNW2String("CoDHUD_Faction", "")
            local teamTotal = GetFactionTotal(faction)
            return teamTotal == scoreLimit or teamTotal == scoreLimit - 1
        end
    end

    hook.Add("OnNPCKilled", "CoDHUD_FloaterFreeze", function(npc, attacker, inflictor)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        -- Sesh modes use PlayerDeath (bots are players), not OnNPCKilled --
        -- so this path only fires for real npc_* entities in normal modes.
        local gmCV = GetConVar("codhud_selected_gamemode")
        if gmCV then
            local gm = gmCV:GetString()
            if gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set" then return end
        end
        if not IsRoundEndingKill(attacker, npc) then return end
        timer.Simple(0.15, function()
            if not IsValid(attacker) then return end
            if GetGlobalBool("Killcam_Playing") then return end
            floaterPos    = attacker:GetPos()
            floaterAng    = attacker:EyeAngles()
            floaterActive = true
            floaterPlayer = attacker
            attacker:SetVelocity(-attacker:GetVelocity())
            attacker:Freeze(true)
            print("[KC] Floater freeze: " .. attacker:Nick())
        end)
    end)

    -- Lock only the attacker's position every tick while floater is active
    hook.Add("Think", "CoDHUD_FloaterThink", function()
        if not floaterActive then return end
        if GetGlobalBool("Killcam_Playing") then
            floaterActive = false
            floaterPos    = nil
            floaterAng    = nil
            floaterPlayer = nil
            -- Unfreeze real players once killcam starts
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then p:Freeze(false) end
            end
            return
        end
        local ply = floaterPlayer
        if IsValid(ply) and ply:Alive() and floaterPos then
            ply:SetPos(floaterPos)
            ply:SetVelocity(-ply:GetVelocity())
        end
    end)

    hook.Add("OnNPCKilled", "CoDHUD_NPCKillCountsAsScore", function(npc, attacker, inflictor)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        -- Remember who made this kill -- BeginFor uses it to run the killcam
        -- for the actual killer instead of the first player in player.GetAll().
        _G.KC_PendingKiller = attacker
        -- FFA bots handle their own frag counting in sv_ffa_bots.lua
        if not npc:GetNWBool("FFA_IsBot", false) then
            if not IsSD() then attacker:SetFrags(attacker:Frags() + 1) end
        end
        -- For FFA NPC bots, set the killcam ID
        if npc:GetNWBool("FFA_IsBot", false) then
            KC_BotKillID_Server = npc:EntIndex()
            hook.Run("CoDHUD_BotKillSetKill", npc, attacker)
        end
        if attacker.KC_Recorder then attacker.KC_Recorder:SetKill(npc) end
    end)

    -- Bot (CreateNextBot) kills -- mirrors OnNPCKilled for sesh_dm bots
    hook.Add("PlayerDeath", "CoDHUD_BotKillSetKill", function(victim, inflictor, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if attacker:IsBot() then return end
        if not IsValid(victim) or not victim:IsBot() then return end

        -- Remember who made this kill so BeginFor runs the killcam for the
        -- actual killer, not the first player in player.GetAll().
        _G.KC_PendingKiller = attacker

        victim.KC_IsKillcamTarget = true
        -- Only update kill ID if not locked (locked by sv_ffa_bots on winning kill)
        if not _G.SeshBot_KillcamIDLocked then
            KC_BotKillID_Server = victim:EntIndex()
        end
        if attacker.KC_Recorder then
            attacker.KC_Recorder:SetKill(victim)
        end
        timer.Simple(20, function()
            if IsValid(victim) then victim.KC_IsKillcamTarget = false end
        end)

        hook.Run("CoDHUD_BotKillSetKill", victim, attacker)
    end)

    -- intentionally empty -- locking handled in sv_ffa_bots SeshBot_StartKillcamPoll
    hook.Add("CoDHUD_BotKillSetKill", "CoDHUD_LockBotKillID", function() end)

    hook.Add("PlayerDeath", "CoDHUD_BotKillFloater", function(victim, inflictor, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if attacker:IsBot() then return end
        if not IsValid(victim) or not victim:IsBot() then return end
        if not IsFloaterHUD() then return end

        local gmCV2 = GetConVar("codhud_selected_gamemode")
        local gm = gmCV2 and gmCV2:GetString() or ""
        local isSesh = gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set"

        -- For sesh modes: defer one tick so CoDHUD_BotKillSetKill hook (which
        -- sets SeshBot_LastRoundEndVictim) has a chance to run first regardless
        -- of hook execution order.
        if isSesh then
            local victimRef   = victim
            local attackerRef = attacker
            timer.Simple(0, function()
                if not IsValid(attackerRef) then return end
                -- Only floater if this was the round-ending kill
                if _G.SeshBot_LastRoundEndVictim ~= victimRef then return end
                if GetGlobalBool("Killcam_Playing") then return end
                floaterPos    = attackerRef:GetPos()
                floaterAng    = attackerRef:EyeAngles()
                floaterActive = true
                floaterPlayer = attackerRef
                attackerRef:SetVelocity(-attackerRef:GetVelocity())
                attackerRef:Freeze(true)
                print("[KC] Floater freeze (sesh bot kill): " .. attackerRef:Nick())
            end)
            return
        end

        -- Normal (non-sesh) bot kills -- combined faction total, not just this attacker's own Frags()
        local scoreLimit = GetConVar("codhud_score_limit"):GetInt()
        if scoreLimit <= 0 then scoreLimit = 75 end
        local attackerFaction = attacker:GetNW2String("CoDHUD_Faction", "")
        if GetFactionTotal(attackerFaction) < scoreLimit then return end

        timer.Simple(0.15, function()
            if not IsValid(attacker) then return end
            if GetGlobalBool("Killcam_Playing") then return end
            floaterPos    = attacker:GetPos()
            floaterAng    = attacker:EyeAngles()
            floaterActive = true
            floaterPlayer = attacker
            attacker:SetVelocity(-attacker:GetVelocity())
            attacker:Freeze(true)
            print("[KC] Floater freeze (bot kill): " .. attacker:Nick())
        end)
    end)

    hook.Add("Think", "CoDHUD_NPCScore_RoundReset", function()
        if IsSD() then return end
        if CoDHUD_RoundStarting and not _G.KC_NPC_WasResetting then
            _G.KC_NPC_WasResetting = true
            SyncNPCReset()
        end
        if not CoDHUD_RoundStarting then
            _G.KC_NPC_WasResetting = false
        end
    end)

    -- Freeze all players until a gamemode is selected
    local KC_GamemodeSelected = false

    hook.Add("Think", "CoDHUD_GamemodeSelectFreeze", function()
        local cv = GetConVar("codhud_selected_gamemode")
        if not cv then return end
        local gm = cv:GetString()
        local hasGamemode = gm ~= "" and gm ~= "none"
        if hasGamemode and not KC_GamemodeSelected then
            KC_GamemodeSelected = true
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then p:Freeze(false) end
            end
        elseif not hasGamemode then
            KC_GamemodeSelected = false
            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) and not p:IsBot() then
                    p:Freeze(true)
                    p:SetVelocity(-p:GetVelocity())
                end
            end
        end
    end)

    hook.Add("PlayerSpawn", "CoDHUD_FreezeOnNoGamemode", function(ply)
        if ply:IsBot() then return end
        timer.Simple(0.1, function()
            if not IsValid(ply) then return end
            local cv = GetConVar("codhud_selected_gamemode")
            if not cv then return end
            local gm = cv:GetString()
            if gm == "" or gm == "none" then ply:Freeze(true) end
        end)
    end)

    hook.Add("EntityTakeDamage", "CoDHUD_BlockDamageNoGamemode", function(target, dmg)
        local cv = GetConVar("codhud_selected_gamemode")
        if not cv then return end
        local gm = cv:GetString()
        if gm == "" or gm == "none" then dmg:SetDamage(0) end
    end)

    local SESH_MODES_EARLY = { sesh_war = true, sesh_dm = true, sesh_sd = true, sesh_sd_set = true }
    local function IsSesh()
        local cv = GetConVar("codhud_selected_gamemode")
        return cv and SESH_MODES_EARLY[cv:GetString()] or false
    end

    -- Block all damage during the round countdown so frozen bots
    -- can't shoot the player before the round actually starts.
    hook.Add("EntityTakeDamage", "CoDHUD_BlockDamageCountdown", function(target, dmg)
        if not CoDHUD_RoundStarting then return end
        if not IsSesh() then return end
        if target:IsPlayer() then dmg:SetDamage(0) end
    end)

    -- No fall damage, no fall sound, no fall blood
    hook.Add("EntityTakeDamage", "KC_NoFallDamage", function(ply, dmgtype)
        if ply:IsPlayer() and dmgtype:IsFallDamage() then
            dmgtype:SetDamage(0)
        end
    end)

    hook.Add("OnPlayerHitGround", "KC_NoFallSound", function()
        return true
    end)

    -- ================================================================
    --  GMOD SESH MODE LOGIC
    --  sesh_war = Sesh TDM, sesh_dm = Sesh FFA, sesh_sd = Sesh S&D
    --  Rules: all weapons one-shot, explosives deal 0 damage
    -- ================================================================
    local SESH_MODES = { sesh_war = true, sesh_dm = true, sesh_sd = true, sesh_sd_set = true }

    local function IsSesh()
        local cv = GetConVar("codhud_selected_gamemode")
        return cv and SESH_MODES[cv:GetString()] or false
    end

    -- Make IsSesh globally available so scorebar/round logic can reuse base mode
    function CoDHUD_GetBaseSeshGamemode()
        local cv = GetConVar("codhud_selected_gamemode")
        if not cv then return nil end
        local gm = cv:GetString()
        if gm == "sesh_war" then return "war" end
        if gm == "sesh_dm"  then return "dm"  end
        if gm == "sesh_sd" or gm == "sesh_sd_set" then return "sd"  end
        return nil
    end

    hook.Add("EntityTakeDamage", "KC_SeshRules", function(target, dmg)
        if not IsSesh() then return end
        if not target:IsNPC() then return end

        local attacker = dmg:GetAttacker()
        if not IsValid(attacker) or not attacker:IsPlayer() then return end

        -- Block explosion damage
        if dmg:IsExplosionDamage() then
            dmg:SetDamage(0)
            return
        end

        -- Block explosive bullet addon:
        -- It calls TakeDamage directly with no DMG_BULLET flag and player as inflictor.
        -- Real weapon fire always has DMG_BULLET set.
        local inflictor = dmg:GetInflictor()
        local isBullet  = dmg:IsBulletDamage()
        if IsValid(inflictor) and inflictor == attacker and not isBullet then
            dmg:SetDamage(0)
            return
        end

        -- All legitimate weapons one-shot
        local maxHp = target:GetMaxHealth()
        if maxHp <= 0 then maxHp = 100 end
        dmg:SetDamage(maxHp + 1)
    end)

    local KC_NonSD_Queued = false
    hook.Add("Think", "CoDHUD_NonSD_KillcamTrigger", function()
        if IsSD() then KC_NonSD_Queued = false return end
        -- Skip sesh modes -- they handle their own killcam
        local gmCV = GetConVar("codhud_selected_gamemode")
        if gmCV then
            local gm = gmCV:GetString()
            if gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set" then KC_NonSD_Queued = false return end
        end
        if not CoDHUD_RoundEnding then KC_NonSD_Queued = false return end
        if KC_NonSD_Queued then return end
        if GetGlobalBool("Killcam_Playing") then return end
        KC_NonSD_Queued = true
        timer.Simple(6.5, function()
            Killcam.BeginFor(_G.KC_PendingKiller)
        end)
    end)

end

if CLIENT then

    include("killcam/cl_npcreplay.lua")

    KC_NPC_FactionScores = KC_NPC_FactionScores or {}
    KC_SD_MatchScores    = KC_SD_MatchScores    or {}

    net.Receive("CoDHUD_NPC_FactionScore", function()
        local faction = net.ReadString()
        local score   = net.ReadInt(16)
        KC_NPC_FactionScores[faction] = score
    end)

    net.Receive("CoDHUD_NPC_ResetScores", function()
        KC_NPC_FactionScores = {}
    end)

    net.Receive("CoDHUD_SD_MatchScores", function()
        KC_SD_MatchScores = net.ReadTable()
    end)

    net.Receive("CoDHUD_SD_StopSuspense", function()
        timer.Remove("CoDHUD_SuspenseTimer")
        if IsValid(CoDHUD_CurrentMusic) then
            CoDHUD_CurrentMusic:Stop()
            CoDHUD_CurrentMusic = nil
        end
    end)

    -- Ensure HUD is restored if killcam ends unexpectedly
    hook.Add("KillcamReplayStopped", "CoDHUD_HUDRestoreOnStop", function()
        if not hudWasDisabled then
            RunConsoleCommand("codhud_quickdisable_hud", "0")
        end
        killcamWasActive = false
    end)

    local function IsKillcamActive()
        return KC_Playing and KC_Playing() or false
    end

    local hudWasDisabled   = false
    local killcamWasActive = false

    hook.Add("Think", "CoDHUD_KillcamHUDToggle", function()
        local active = IsKillcamActive()
        if active and not killcamWasActive then
            killcamWasActive = true
            hudWasDisabled   = GetConVar("codhud_quickdisable_hud"):GetBool()
            RunConsoleCommand("codhud_quickdisable_hud", "1")

            local lp = LocalPlayer()
            local obsTarget = IsValid(lp) and lp:GetObserverTarget() or nil
            print("[Killcam DEBUG] Started for " .. (IsValid(lp) and lp:Nick() or "?")
                .. " | ObserverMode=" .. tostring(IsValid(lp) and lp:GetObserverMode())
                .. " | SpectateTarget=" .. (IsValid(obsTarget) and obsTarget:Nick() or "none")
                .. " | KC_Playing=" .. tostring(KC_Playing and KC_Playing())
                .. " | Killcam_Playing(global)=" .. tostring(GetGlobalBool("Killcam_Playing")))
        elseif not active and killcamWasActive then
            killcamWasActive = false
            RunConsoleCommand("codhud_quickdisable_hud", hudWasDisabled and "1" or "0")
            print("[Killcam DEBUG] Ended for " .. (IsValid(LocalPlayer()) and LocalPlayer():Nick() or "?"))
        end
    end)

    hook.Add("RenderScreenspaceEffects", "CoDHUD_KillcamNoGreyscale", function()
        if IsKillcamActive() then
            DrawColorModify({
                ["$pp_colour_addr"]       = 0,
                ["$pp_colour_addg"]       = 0,
                ["$pp_colour_addb"]       = 0,
                ["$pp_colour_brightness"] = 0,
                ["$pp_colour_contrast"]   = 1,
                ["$pp_colour_colour"]     = 1,
                ["$pp_colour_mulr"]       = 0,
                ["$pp_colour_mulg"]       = 0,
                ["$pp_colour_mulb"]       = 0,
            })
        end
    end)

end