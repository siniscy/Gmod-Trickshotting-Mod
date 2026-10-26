---- [ CLIENT: SESH SCOREBOARD ENEMY TEAM ] ----
-- In the Sesh team modes (TDM, S&D, S&D Set) every bot is on the enemy team, so
-- that team always deserves a spot on the faction scoreboard -- even while it
-- has no visible players yet (bots not spawned, or a bot's faction not yet
-- networked to this client). Each HUD's scoreboard (codhud/games/*.lua) calls
-- CoDHUD.Sesh.FillEnemyGroup(factions) right after it groups players by faction.
--
-- The scoreboards skip any non-local player whose faction hasn't arrived yet
-- (guessing merged a fresh bot into the player's own team once), which is why a
-- bot could go missing entirely. Here, such a bot is placed on the enemy team
-- instead, which is always right in these modes.

CoDHUD = CoDHUD or {}
CoDHUD.Sesh = CoDHUD.Sesh or {}

local TEAM_MODES = { sesh_war = true, sesh_sd = true, sesh_sd_set = true }

function CoDHUD.Sesh.IsTeamMode()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv ~= nil and TEAM_MODES[cv:GetString()] == true
end

-- The bots' faction: networked by the server (sv_ffa_bots.lua's SeshBot_FactionSync),
-- else read off any bot whose own faction has already synced.
function CoDHUD.Sesh.GetEnemyFaction()
    local f = GetGlobal2String("KC_SeshBotFaction", "")
    if f ~= "" then return f end

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsBot() then
            local pf = p:GetNW2String("CoDHUD_Faction", "")
            if pf ~= "" then return pf end
        end
    end
    return nil
end

-- `factions` is the scoreboard's { [factionKey] = { players... } } table.
-- Guarantees the enemy faction has an entry (possibly empty) and that no bot is
-- left out just because its faction hasn't reached this client yet.
function CoDHUD.Sesh.FillEnemyGroup(factions)
    if not CoDHUD.Sesh.IsTeamMode() then return end

    local enemy = CoDHUD.Sesh.GetEnemyFaction()
    if not enemy then return end

    local group = factions[enemy]
    if not group then
        group = {}
        factions[enemy] = group
    end

    local seen = {}
    for _, p in ipairs(group) do seen[p] = true end

    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsBot() and not seen[p] and p:GetNW2String("CoDHUD_Faction", "") == "" then
            table.insert(group, p)
        end
    end
end
