---- [ CLIENT: LOADOUT CONVARS ] ----
-- Per-player class selection + Custom-class weapon picks. Uses the exact
-- same archived+userinfo convar pattern the killcam card customization
-- already relies on (killcam_hud_text etc, see cl_hud.lua) -- the server
-- reads these straight off ply:GetInfo() (sv_loadouts_give.lua), so there's
-- no separate save/network system, and FCVAR_ARCHIVE means the selection
-- survives both round changes and game restarts with zero extra code.

-- New players start on the Modern Warfare 2 preset (Intervention + PP2000)
-- so they spawn with a gun; "none" left them with only their equipment.
CreateClientConVar("kc_loadout_mode", "default_4", true, true,
    "Selected class: a default_N id, 'custom', or 'none' (manual pickup, no class given)")

-- Defaults must be weapons this addon ships, or Custom spawns empty-handed.
CreateClientConVar("kc_custom_primary", "mw2cr_cheytac", true, true, "Custom class: primary weapon classname")
CreateClientConVar("kc_custom_secondary", "reha_mw2pp2000", true, true, "Custom class: secondary weapon classname")
CreateClientConVar("kc_custom_equipment", "kc_equip_knife", true, true, "Custom class: equipment weapon classname")

-- "No Class" gives no weapons (you pick them up in the match) but can still carry one equipment item.
-- Empty means none.
CreateClientConVar("kc_noclass_equipment", "", true, true, "No Class: optional equipment weapon classname (empty = none)")

-- TEMP DIAGNOSTIC -- remove once "class picks don't survive to round start" is
-- confirmed fixed. Logs every change to these convars regardless of source
-- (class menu click, autoexec, another script) so a pick that silently gets
-- reset before round start shows up here instead of only being noticed once
-- the server-side print (sv_loadouts_give.lua) already shows the wrong value.
for _, cv in ipairs({ "kc_loadout_mode", "kc_custom_primary", "kc_custom_secondary", "kc_custom_equipment" }) do
    cvars.AddChangeCallback(cv, function(name, old, new)
        print(string.format("[KC Class][cvar] %s: %q -> %q", name, old, new))
    end, "KC_Loadouts_DebugCvar_" .. cv)
end
