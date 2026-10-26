---- [ GOD MODE — SESH S&D SET ONLY ] ----
-- Host-controlled toggle (same lobby/settings checkbox pattern as Fast Last).
-- While it is on AND the current gamemode is sesh_sd_set, the host and every
-- REAL player on the host's team are invulnerable. Bots never get it, and
-- neither does anyone on the other team. In any other gamemode it does nothing.
--
-- The client side hides the low-health blood/defocus overlay and mutes the
-- low-health breathing/heartbeat sounds for players who have it (cl_lowhealth.lua
-- reads the KC_GodMode networked bool set here).

if not SERVER then return end

CreateConVar("kc_godmode_enabled", "0", FCVAR_ARCHIVE,
    "God mode for the host and real players on the host's team (never bots). Only active in Sesh S&D Set.")

local ONLY_MODE = "sesh_sd_set"

local function GodModeActive()
    if not GetConVar("kc_godmode_enabled"):GetBool() then return false end
    local gm = GetConVar("codhud_selected_gamemode")
    return gm ~= nil and gm:GetString() == ONLY_MODE
end

local function GetHost()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsListenServerHost() then return p end
    end
    return nil
end

-- The host always qualifies; other real players qualify when they share the
-- host's faction (same NW2 key Fast Last uses to find "the host's team").
local function QualifiesForGod(ply, host)
    if not IsValid(ply) or ply:IsBot() or not IsValid(host) then return false end
    if ply == host then return true end

    local hostFaction = host:GetNW2String("CoDHUD_Faction", "")
    return hostFaction ~= "" and ply:GetNW2String("CoDHUD_Faction", "") == hostFaction
end

-- Brings one player in line with the current setting. Only ever takes back
-- god mode that THIS file gave (KC_GodGiven), so it can't undo an admin's own.
local function SyncPlayer(ply, active, host)
    if not IsValid(ply) then return end

    local want = active and QualifiesForGod(ply, host)

    if want then
        if ply:Alive() and not ply:HasGodMode() then
            ply:GodEnable()
            ply.KC_GodGiven = true
        end
    elseif ply.KC_GodGiven then
        ply:GodDisable()
        ply.KC_GodGiven = nil
    end

    if ply:GetNWBool("KC_GodMode", false) ~= want then
        ply:SetNWBool("KC_GodMode", want)
    end
end

local function SyncAll()
    local active = GodModeActive()
    local host = GetHost()
    for _, ply in ipairs(player.GetAll()) do
        SyncPlayer(ply, active, host)
    end
end

-- Re-checked several times a second, so someone switching teams mid-match gains
-- or loses it almost immediately.
local nextSync = 0
hook.Add("Think", "KC_GodMode_Sync", function()
    if CurTime() < nextSync then return end
    nextSync = CurTime() + 0.25
    SyncAll()
end)

-- Respawns can clear the flag, so re-apply right away instead of waiting for the next sync tick.
hook.Add("PlayerSpawn", "KC_GodMode_Spawn", function(ply)
    timer.Simple(0, function()
        if IsValid(ply) then SyncPlayer(ply, GodModeActive(), GetHost()) end
    end)
end)

-- Tell the host right away if they turn it on in a mode where it won't do anything.
cvars.AddChangeCallback("kc_godmode_enabled", function(_, _, new)
    if tonumber(new) ~= 1 then return end
    local gm = GetConVar("codhud_selected_gamemode")
    if gm and gm:GetString() ~= ONLY_MODE then
        PrintMessage(HUD_PRINTTALK, "[God Mode] Only works in Sesh S&D Set -- it will do nothing in the current gamemode.")
    end
end, "KC_GodMode_Notice")
