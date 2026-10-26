-- Convars read unconditionally (no nil-guard) by copied-in preset-class weapon
-- code, e.g. MW2CR_cheytac/shared.lua calling GetConVar("get_sleightofhand"):GetInt().
-- Without these the weapon errors out on load once its source addon is gone.

CreateConVar("get_sleightofhand", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Enable Sleight Of Hand.", 0, 1)
CreateConVar("get_reversereload", 0, {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Enable Reverse Reload.", 0, 1)
