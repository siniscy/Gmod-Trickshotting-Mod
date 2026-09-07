---- [ SERVER PRE-GAME LOBBY ] ----
-- A "Private Match"-style lobby that's active on every fresh map load and
-- reopens after each sesh match ends, gating players behind a freeze +
-- damage block until an admin picks a gamemode and presses Start Game.
--
-- Deliberately kept separate from the existing CoDHUD_GamemodeSelectFreeze /
-- CoDHUD_FreezeOnNoGamemode / CoDHUD_BlockDamageNoGamemode hooks in
-- killcam_codhud_integration.lua -- this is new, independent state
-- (KC_Lobby_Active) rather than piggybacking on codhud_selected_gamemode's
-- archived value, so it can't interact with that already-delicate system.

util.AddNetworkString("KC_Lobby_State")
util.AddNetworkString("KC_Lobby_Roster")

-- Starts true on every map load/script reload, so a fresh map always opens
-- in the lobby rather than dropping straight into gameplay.
_G.KC_Lobby_Active = true

local function BuildRoster()
    local roster = {}
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            table.insert(roster, {
                nick     = ply:Nick(),
                isBot    = ply:IsBot(),
                isAdmin  = ply:IsAdmin(),
                clantag  = ply:IsBot() and "" or ply:GetInfo("killcam_hud_clantag"),
                lvl      = ply:IsBot() and "" or ply:GetInfo("killcam_hud_lvl"),
                lvlIcon  = ply:IsBot() and "" or ply:GetInfo("killcam_hud_lvl_icon"),
                title    = ply:IsBot() and "" or ply:GetInfo("killcam_hud_title"),
                icon     = ply:IsBot() and "" or ply:GetInfo("killcam_hud_icon"),
                text     = ply:IsBot() and "" or ply:GetInfo("killcam_hud_text"),
            })
        end
    end
    return roster
end

function KC_Lobby_BroadcastRoster(target)
    net.Start("KC_Lobby_Roster")
        net.WriteTable(BuildRoster())
    if target then
        net.Send(target)
    else
        net.Broadcast()
    end
end

local function BroadcastState(target)
    net.Start("KC_Lobby_State")
        net.WriteBool(KC_Lobby_Active)
    if target then
        net.Send(target)
    else
        net.Broadcast()
    end
end

-- Exposed globally: sv_roundstart.lua calls this (false) when the host
-- starts a round, and the KC_MatchEnded hook below calls this (true) once
-- a sesh match concludes.
function KC_Lobby_SetActive(active)
    KC_Lobby_Active = active and true or false
    BroadcastState()
    if KC_Lobby_Active then
        KC_Lobby_BroadcastRoster()
    end
end

-- Re-sync the roster periodically so kc_menu card edits (clantag/lvl/icon),
-- which have no change-notification hook of their own, show up for
-- everyone within a couple seconds without needing to touch cl_ui_menu.lua.
timer.Create("KC_Lobby_RosterPoll", 2, 0, function()
    if KC_Lobby_Active then
        KC_Lobby_BroadcastRoster()
    end
end)

hook.Add("PlayerInitialSpawn", "KC_Lobby_SendStateToNewPlayer", function(ply)
    timer.Simple(0.1, function()
        if not IsValid(ply) then return end
        BroadcastState(ply)
        KC_Lobby_BroadcastRoster(ply)
    end)
end)

hook.Add("PlayerDisconnected", "KC_Lobby_RosterOnDisconnect", function()
    if not KC_Lobby_Active then return end
    -- The disconnecting player is still in player.GetAll() during this
    -- hook on some GMod versions, so defer one tick before rebuilding.
    timer.Simple(0, function()
        if KC_Lobby_Active then KC_Lobby_BroadcastRoster() end
    end)
end)

-- ================================================================
--  FREEZE / DAMAGE BLOCK WHILE THE LOBBY IS ACTIVE
-- ================================================================
hook.Add("Think", "KC_Lobby_Freeze", function()
    if not KC_Lobby_Active then return end
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) and not ply:IsBot() and not ply:IsFrozen() then
            ply:Freeze(true)
        end
    end
end)

hook.Add("PlayerSpawn", "KC_Lobby_FreezeOnSpawn", function(ply)
    if ply:IsBot() then return end
    if not KC_Lobby_Active then return end
    timer.Simple(0.1, function()
        if IsValid(ply) and KC_Lobby_Active then ply:Freeze(true) end
    end)
end)

hook.Add("EntityTakeDamage", "KC_Lobby_BlockDamage", function(target, dmg)
    if not KC_Lobby_Active then return end
    dmg:SetDamage(0)
end)

-- ================================================================
--  REOPEN AFTER A SESH MATCH ENDS
-- ================================================================
hook.Add("KC_MatchEnded", "KC_Lobby_Reopen", function()
    KC_Lobby_SetActive(true)
end)

print("[KC Lobby] sv_lobby.lua loaded.")
