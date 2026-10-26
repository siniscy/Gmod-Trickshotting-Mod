---- [ SHARED: LOADOUT / CLASS DATA ] ----
-- Weapon pool + default class presets for the CoD-style class system
-- (Primary / Secondary / Equipment). Edit WeaponPool / DefaultClasses /
-- BuiltinEquipment below to add, remove, or re-curate weapons -- nothing
-- else in the loadout system needs to change.
--
-- Loaded in both realms (sh_ prefix, see codhud_init.lua's loader): the
-- server needs the classnames to Give(), the client needs the pool to
-- populate the class-menu weapon pickers.

KC_Loadouts = KC_Loadouts or {}

-- Curated Primary/Secondary pool, grouped for the class-menu picker.
-- classname must match an installed SWEP's folder/ClassName exactly --
-- entries whose weapon isn't actually installed are silently skipped
-- wherever this pool is consumed (see BuildFullWeaponPool below).
KC_Loadouts.WeaponPool = {
    { classname = "dread_m4",              name = "M4A1 (MW19)",           group = "Rifles/Snipers" },
    { classname = "dread_mp5",              name = "MP5 (MW19)",            group = "Rifles/Snipers" },
    { classname = "dread_kar98",             name = "Kar98k (WAW)",          group = "Rifles/Snipers" },
    { classname = "dread_barr",              name = "Barrett (MW3)",         group = "Rifles/Snipers" },

    { classname = "dread_1911",              name = "1911 (MW19)",           group = "Pistols" },
    { classname = "reha_de50taciw4",         name = "Desert Eagle Tac Knife", group = "Pistols" },

    { classname = "reha_interiw4",           name = "Intervention HBS",      group = "Reha's Snipers" },
    { classname = "reha_m21giw3",            name = "M21 Ghillie",           group = "Reha's Snipers" },
    { classname = "reha_msrv2iw5",           name = "MSR v2",                group = "Reha's Snipers" },

    { classname = "reha_strikeriw4",         name = "Striker",               group = "Reha's Shotguns" },
    { classname = "reha_spas12gripiw4",      name = "SPAS-12 w/ Grip",       group = "Reha's Shotguns" },
}

-- Equipment pool -- kept separate from the Primary/Secondary pool above and
-- from the weapon-switch cycle entirely (see cl_loadouts_switch.lua). Any
-- SWEP flagged SWEP.KC_IsEquipment = true is auto-discovered too, via
-- BuildEquipmentPool below, so equipment added later just works.
KC_Loadouts.BuiltinEquipment = {
    { classname = "kc_equip_knife", name = "Combat Knife" },
}

-- Fixed presets -- not player-editable, identical for every player.
-- "custom" and "none" are handled separately (cl_loadouts_convars.lua /
-- sv_loadouts_give.lua / cl_class_menu.lua); this table only holds the
-- developer-authored ones.
KC_Loadouts.DefaultClasses = {
    {
        id = "default_1", name = "Black Ops 2",
        primary = "weapon_bo2_dsr50", secondary = "weapon_bo2_kap40", equipment = "kc_bo2_shock_charge",
    },
    {
        id = "default_2", name = "Modern Warfare 3",
        primary = "mw3_m82", secondary = "notreha_spas12grip", equipment = "reha_smokegrenadeiw5",
    },
    {
        id = "default_3", name = "Black Ops 1",
        primary = "reha_bo1l96", secondary = "reha_bo1stakegrip",
    },
    {
        id = "default_4", name = "Modern Warfare 2",
        primary = "mw2cr_cheytac", secondary = "reha_mw2pp2000",
    },
    {
        id = "default_5", name = "World at War",
        primary = "dread_nz_waw_kar98k", secondary = "dread_nz_waw_trenchgun", equipment = "dread_tfa_waw_bbetty",
    },
    {
        id = "default_6", name = "Modern Warfare 1",
        primary = "reha_m21giw3", secondary = "dread_nz_mw_mp5", equipment = "cod_claymore",
    },
}

-- True if classname is either in the curated pool or is some other
-- installed, non-equipment SWEP -- used server-side to validate a player's
-- saved Custom-class picks before Give()'ing them (their convar could be
-- stale/tampered, or reference a weapon that's since been uninstalled).
function KC_Loadouts.IsKnownPrimary(classname)
    if not classname or classname == "" then return false end
    local tbl = weapons.Get(classname)
    return tbl ~= nil and not tbl.KC_IsEquipment
end

-- Scans every installed SWEP for SWEP.KC_IsEquipment, so any equipment SWEP
-- dropped into lua/weapons/ later shows up in the Custom-class equipment
-- picker automatically -- no edits needed here.
function KC_Loadouts.BuildEquipmentPool()
    local seen, out = {}, {}

    for _, e in ipairs(KC_Loadouts.BuiltinEquipment) do
        if weapons.Get(e.classname) then
            seen[e.classname] = true
            table.insert(out, e)
        end
    end

    for _, tbl in ipairs(weapons.GetList()) do
        local cn = tbl.ClassName
        if cn and tbl.KC_IsEquipment and not seen[cn] then
            seen[cn] = true
            table.insert(out, { classname = cn, name = tbl.PrintName or cn })
        end
    end

    return out
end

-- Heuristic exclusion list for the "everything else installed" scan below --
-- abstract weapon bases, tools, and other non-gun entities that show up in
-- weapons.GetList() but were never meant to be a class's Primary/Secondary.
local EXCLUDE_CLASSNAMES = {
    gmod_tool = true, gmod_camera = true,
    weapon_physgun = true, weapon_physcannon = true,
    weapon_slam = true, weapon_ttt_base = true,
}

local function IsExcludedBase(cn)
    return cn:find("_base", 1, true) ~= nil or cn:find("blacklisted", 1, true) ~= nil
end

-- Scans every installed SWEP not already in WeaponPool and not flagged as
-- equipment/base/tool, so weapon packs added after this file was written
-- still show up as pickable "Custom" weapons.
function KC_Loadouts.BuildFullWeaponPool()
    local seen, out = {}, {}

    for _, w in ipairs(KC_Loadouts.WeaponPool) do
        if weapons.Get(w.classname) then
            seen[w.classname] = true
            table.insert(out, w)
        end
    end

    for _, tbl in ipairs(weapons.GetList()) do
        local cn = tbl.ClassName
        if cn and not seen[cn] and not tbl.KC_IsEquipment
            and not EXCLUDE_CLASSNAMES[cn] and not IsExcludedBase(cn) then
            seen[cn] = true
            table.insert(out, { classname = cn, name = tbl.PrintName or cn, group = "Other Installed Weapons" })
        end
    end

    return out
end
