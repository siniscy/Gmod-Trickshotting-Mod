-- Drop Weapon — integrated into kc_project_0.6
-- Original addon by YuRaNnNzZZ
-- Merged client + server into one autorun file.
-- Death-drop is automatically disabled during sesh modes so it doesn't
-- conflict with the sesh loadout save/restore system.

-- ================================================================
--  CLIENT — Tool Menu
-- ================================================================
if CLIENT then
    hook.Add("PopulateToolMenu", "DropWeapon_ToolMenu", function()
        spawnmenu.AddToolMenuOption("Utilities", "Drop Weapon", "DropWeapon_Server", "Server", "", "", function(panel)
            panel:ClearControls()
            panel:CheckBox("#dropweapon_menu_sv_blacklist_adminbypass", "sv_dropweapon_blacklist_adminbypass")
            panel:AddControl("Label", { Text = "" })
            panel:CheckBox("#dropweapon_menu_sv_ondeath", "sv_dropweapon_ondeath")
            panel:CheckBox("#dropweapon_menu_sv_ondeath_activeonly", "sv_dropweapon_ondeath_activeonly")
        end)
    end)
    return
end

-- ================================================================
--  SERVER
-- ================================================================
local blacklist = {}
local cv_blacklist           = CreateConVar("sv_dropweapon_blacklist",           "weapon_fists,", { FCVAR_ARCHIVE, FCVAR_PROTECTED }, "Comma-separated weapon classnames blacklisted from dropping.")
local cv_blacklist_bypass    = CreateConVar("sv_dropweapon_blacklist_adminbypass","0",            { FCVAR_ARCHIVE }, "Can admins drop blacklisted weapons?")
local cv_dropondeath         = CreateConVar("sv_dropweapon_ondeath",             "0",            { FCVAR_ARCHIVE }, "Drop weapons on death?")
local cv_dropondeath_active  = CreateConVar("sv_dropweapon_ondeath_activeonly",  "1",            { FCVAR_ARCHIVE }, "Drop active weapon only on death? (requires ondeath enabled)")
local cv_enablecommand       = CreateConVar("sv_dropweapon_enablecommand",       "1",            { FCVAR_ARCHIVE }, "Allow +drop command?")

local function StringToTable(str, sep)
    local t = {}
    for _, v in pairs(string.Explode(sep, str)) do
        if #v > 0 then t[v] = true end
    end
    return t
end

cvars.AddChangeCallback("sv_dropweapon_blacklist", function(_, _, newval)
    blacklist = StringToTable(newval, ",")
end, "dropweapon_blacklist")
blacklist = StringToTable(cv_blacklist:GetString(), ",")

concommand.Add("sv_dropweapon_blacklist_add", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if #args < 1 or blacklist[args[1]] then return end
    blacklist[args[1]] = true
    local str = "" for k, v in pairs(blacklist) do if v then str = str .. k .. "," end end
    cv_blacklist:SetString(str)
end)

concommand.Add("sv_dropweapon_blacklist_remove", function(ply, _, args)
    if IsValid(ply) and not ply:IsAdmin() then return end
    if #args < 1 or not blacklist[args[1]] then return end
    blacklist[args[1]] = false
    local str = "" for k, v in pairs(blacklist) do if v then str = str .. k .. "," end end
    cv_blacklist:SetString(str)
end)

local function IsSeshMode()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sesh_war" or gm == "sesh_dm" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

local function DropWeapon(ply, wpn, forceblacklist)
    if not IsValid(wpn) then return end
    if (blacklist[wpn:GetClass()] or wpn.AdminOnly) and
       (forceblacklist or not ply:IsAdmin() or not cv_blacklist_bypass:GetBool()) then return end
    ply:DropWeapon(wpn)
end

concommand.Add("+drop", function(ply)
    if cv_enablecommand:GetBool() then DropWeapon(ply, ply:GetActiveWeapon()) end
end)
concommand.Add("-drop", function() end)

local function DropAllWeapons(ply)
    for _, wpn in pairs(ply:GetWeapons()) do DropWeapon(ply, wpn, true) end
end

hook.Add("DoPlayerDeath", "DropWeapon_DoPlayerDeath", function(ply)
    -- Never drop on death during sesh modes — loadout is saved and restored
    -- by the kc_project sesh weapon system instead.
    if IsSeshMode() then return end
    if not cv_dropondeath:GetBool() then return end
    if cv_dropondeath_active:GetBool() then
        DropWeapon(ply, ply:GetActiveWeapon(), true)
    else
        DropAllWeapons(ply)
    end
end)
