---- [ SERVER: LOADOUT WEAPON GIVING ] ----
-- Hooks PlayerLoadout -- fired by every ply:Spawn(), including
-- sv_roundstart.lua's round-start spawns -- to give the player's selected
-- class's Primary/Secondary/Equipment instead of the gamemode default.
--
-- Returning true from a PlayerLoadout hook stops the gamemode's own
-- PlayerLoadout from also running (standard hook.Call behavior: the first
-- non-nil return short-circuits the gamemode function), so when a class is
-- active the default sandbox loadout never fires. When the player's
-- selected mode is "none" (or their saved data doesn't resolve to anything
-- givable) this returns nil/false instead, so the gamemode's default
-- loadout runs exactly like it always has -- that's the "play normally"
-- mode requested alongside the class system.
--
-- IMPORTANT: lua/ffa/sv_ffa_bots.lua ALSO hooks PlayerLoadout (Sesh mode's
-- own manual-loadout save/restore, "SeshBot_LoadoutOverride") and, for a
-- real player with nothing saved yet, unconditionally StripWeapons()+returns
-- true. hook.Call only runs hooks tied for priority in pairs()'s (undefined)
-- table order and stops at the first non-nil return, so without an explicit
-- priority that hook could silently run before this one and eat every class
-- pick. HOOK_HIGH makes this one always go first; the ply:IsBot() bail below
-- leaves Sesh mode's own bot arming (SMG/shotgun) completely untouched.

-- TEMP DIAGNOSTIC -- writes every [KC Class] line to garrysmod/data/kc_class_debug.log
-- (in addition to print()), because the in-game console can drop/scroll past
-- lines during the print burst at round start and copy-paste has been losing
-- exactly the lines we need. This file is lossless -- read it directly
-- instead of relying on console scrollback. Exposed globally so
-- lua/ffa/sv_ffa_bots.lua's fallback print can log into the same file/timeline.
local LOG_PATH = "kc_class_debug.log"
if not file.Exists(LOG_PATH, "DATA") then file.Write(LOG_PATH, "") end
local function KC_Log(msg)
    print(msg)
    file.Append(LOG_PATH, os.date("%H:%M:%S") .. " " .. msg .. "\n")
end
_G.KC_ClassLog = KC_Log

local function GetDefaultClass(id)
    for _, c in ipairs(KC_Loadouts.DefaultClasses) do
        if c.id == id then return c end
    end
    return nil
end

-- Reads the player's saved selection off their (userinfo) client convars --
-- see cl_loadouts_convars.lua for why no separate net/save system is needed.
local function GetSelectedLoadout(ply)
    local mode = ply:GetInfo("kc_loadout_mode")

    if mode == "" or mode == "none" then
        return nil
    end

    if mode == "custom" then
        local rawPrimary   = ply:GetInfo("kc_custom_primary")
        local rawSecondary = ply:GetInfo("kc_custom_secondary")
        local rawEquipment = ply:GetInfo("kc_custom_equipment")

        local primary, secondary, equipment = rawPrimary, rawSecondary, rawEquipment

        if not KC_Loadouts.IsKnownPrimary(primary) then primary = nil end
        if not KC_Loadouts.IsKnownPrimary(secondary) then secondary = nil end
        if equipment == "" or not weapons.Get(equipment) then equipment = nil end

        -- TEMP DIAGNOSTIC -- shows the raw userinfo value the server actually
        -- received for each custom pick BEFORE validation, so a value that
        -- got wiped by IsKnownPrimary (e.g. stale/uninstalled classname, or
        -- the convar never having synced from the client yet) is visible
        -- instead of just silently falling through as "nil".
        KC_Log(string.format(
            "[KC Class] GetSelectedLoadout(%s) custom: primary raw=%q kept=%s | secondary raw=%q kept=%s | equipment raw=%q kept=%s",
            ply:Nick(),
            rawPrimary, tostring(primary ~= nil),
            rawSecondary, tostring(secondary ~= nil),
            rawEquipment, tostring(equipment ~= nil)))

        return { primary = primary, secondary = secondary, equipment = equipment }
    end

    local base = GetDefaultClass(mode)
    if not base then return nil end

    -- Per-player override of a preset class's Primary/Secondary/Equipment
    -- (cl_class_menu.lua's "Change"/"Reset to Default" on a preset row) --
    -- kc_override_<id>_<slot> userinfo convars, empty means "no override,
    -- use the hardcoded default" exactly like Custom's convars above. Build
    -- a NEW table rather than mutating `base` -- that's the single shared
    -- KC_Loadouts.DefaultClasses entry every player reads, not a per-player copy.
    local rawPrimary   = ply:GetInfo("kc_override_" .. mode .. "_primary")
    local rawSecondary = ply:GetInfo("kc_override_" .. mode .. "_secondary")
    local rawEquipment = ply:GetInfo("kc_override_" .. mode .. "_equipment")

    local primary = base.primary
    if rawPrimary ~= "" and KC_Loadouts.IsKnownPrimary(rawPrimary) then primary = rawPrimary end

    local secondary = base.secondary
    if rawSecondary ~= "" and KC_Loadouts.IsKnownPrimary(rawSecondary) then secondary = rawSecondary end

    local equipment = base.equipment
    if rawEquipment ~= "" and weapons.Get(rawEquipment) then equipment = rawEquipment end

    return { primary = primary, secondary = secondary, equipment = equipment }
end

-- Gives the weapon plus a handful of reserve reloads, sized off whatever
-- clip size/ammo type that specific SWEP itself declares -- keeps this
-- generic across every installed weapon base instead of hardcoding ammo
-- types per gun.
local function GiveWeaponWithAmmo(ply, classname)
    local swep = weapons.Get(classname)
    if not swep then return end

    ply:Give(classname)

    local function GiveReserve(bucket)
        local ammoType = bucket and bucket.Ammo
        if not ammoType or ammoType == "" or ammoType == "none" then return end

        local clip = (bucket.ClipSize and bucket.ClipSize > 0) and bucket.ClipSize or 30
        ply:GiveAmmo(clip * 4, ammoType, true)
    end

    GiveReserve(swep.Primary)
    GiveReserve(swep.Secondary)
end

-- Strips and re-gives ply's currently-selected class right now -- shared by
-- the PlayerLoadout hook (spawn-time), the PlayerSpawn force-apply fallback,
-- and kc_apply_loadout_now (mid-match instant class switch from "K", see
-- cl_class_menu.lua). Returns true if a class was actually applied.
local function KC_GiveLoadoutNow(ply, class)
    -- A real class replaces everything, including any No Class equipment given earlier.
    ply.KC_NoClassEquipment = nil

    local havePrimary   = class.primary and weapons.Get(class.primary)
    local haveSecondary = class.secondary and weapons.Get(class.secondary)
    local haveEquipment = class.equipment and weapons.Get(class.equipment)

    -- Nothing in this class actually resolves to an installed weapon --
    -- leave the player alone rather than stripping them down to nothing.
    if not havePrimary and not haveSecondary and not haveEquipment then
        return false
    end

    ply:StripWeapons()
    ply:RemoveAllAmmo()

    if havePrimary then GiveWeaponWithAmmo(ply, class.primary) end
    if haveSecondary then GiveWeaponWithAmmo(ply, class.secondary) end
    if haveEquipment then ply:Give(class.equipment) end

    if havePrimary then
        ply:SelectWeapon(class.primary)
    elseif haveSecondary then
        ply:SelectWeapon(class.secondary)
    end

    return true
end

-- "No Class" (kc_loadout_mode "none"/"") hands out no weapons -- the player picks
-- them up in the match -- but can still carry one optional equipment item,
-- kc_noclass_equipment (empty = none). Nothing is stripped: this only Give()s that
-- one item, and takes back the previous one if the pick changed mid-match.
local function KC_IsNoClass(ply)
    local mode = ply:GetInfo("kc_loadout_mode")
    return mode == "" or mode == "none"
end

local function KC_ApplyNoClassEquipment(ply)
    local equipment = ply:GetInfo("kc_noclass_equipment")
    if equipment == "" or not weapons.Get(equipment) then equipment = nil end

    local previous = ply.KC_NoClassEquipment
    if previous and previous ~= equipment and ply:HasWeapon(previous) then
        ply:StripWeapon(previous)
    end
    ply.KC_NoClassEquipment = equipment

    if equipment and not ply:HasWeapon(equipment) then
        ply:Give(equipment)
    end

    KC_Log(string.format("[KC Class][no-class] %s: equipment=%s", ply:Nick(), tostring(equipment)))
end

-- TEMP DIAGNOSTIC -- the actual hook body was moved into this named function
-- and wrapped in pcall below (see hook.Add at the bottom of this file). If
-- this function throws (e.g. KC_Loadouts not defined yet, a nil field), the
-- previous unwrapped version would silently abort mid-function with nothing
-- printed and fall through to the next PlayerLoadout hook -- pcall now
-- catches that and prints the real error + traceback instead.
local function KC_PlayerLoadoutHandler(ply)
    if not IsValid(ply) or ply:IsBot() then return end

    local mode = ply:GetInfo("kc_loadout_mode")
    local class = GetSelectedLoadout(ply)

    -- TEMP DIAGNOSTIC -- remove once loadout giving is confirmed working.
    -- Prefixed "[KC Class]" (not "[KC Loadout]") so it's never confused with
    -- lua/ffa/sv_ffa_bots.lua's own unrelated "[KC Loadout]" prints.
    local gamemode = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or "?"
    KC_Log(string.format("[KC Class] PlayerLoadout(%s, uid=%d, gamemode=%q): mode=%q primary=%s secondary=%s equipment=%s",
        ply:Nick(), ply:UserID(), gamemode, mode,
        tostring(class and class.primary), tostring(class and class.secondary), tostring(class and class.equipment)))

    if not class then
        KC_Log(string.format("[KC Class] PlayerLoadout(%s): no class selected (mode=%q) -- falling through to gamemode default / other PlayerLoadout hooks", ply:Nick(), mode))
        return
    end

    local havePrimary   = class.primary and weapons.Get(class.primary)
    local haveSecondary = class.secondary and weapons.Get(class.secondary)
    local haveEquipment = class.equipment and weapons.Get(class.equipment)

    KC_Log(string.format("[KC Class] resolves: primary=%s secondary=%s equipment=%s",
        tostring(havePrimary ~= nil and havePrimary ~= false), tostring(haveSecondary ~= nil and haveSecondary ~= false), tostring(haveEquipment ~= nil and haveEquipment ~= false)))

    return KC_GiveLoadoutNow(ply, class)
end

hook.Add("PlayerLoadout", "KC_Loadouts_Give", function(ply)
    -- TEMP DIAGNOSTIC -- absolutely unconditional, nothing before this can
    -- skip it. If this never shows up for a real spawn even though the hook
    -- is confirmed registered, hook.Run() itself is not reaching this
    -- closure -- something outside this file is intercepting/short-
    -- circuiting PlayerLoadout before iteration gets here.
    KC_Log(string.format("[KC Class][ENTRY] KC_Loadouts_Give invoked, ply=%s", tostring(ply)))
    local ok, result = pcall(KC_PlayerLoadoutHandler, ply)
    if not ok then
        KC_Log("[KC Class][ERROR] KC_Loadouts_Give threw an error -- this is why weapons weren't given: " .. tostring(result))
        KC_Log(debug.traceback())
        return
    end
    return result
end, HOOK_MONITOR_HIGH)

-- Belt-and-suspenders fix -- some OTHER installed addon's own PlayerLoadout
-- hook ("ewa_spawnnoweapons" or "CinematicCameraSpawnAndEquip", neither of
-- which live in this addon -- see lua/ffa and lua/codhud, they're not here)
-- is winning the PlayerLoadout hook race ahead of KC_Loadouts_Give and
-- returning non-nil, which stops hook.Run before our hook ever gets called
-- at all (confirmed: KC_Loadouts_Give's own unconditional entry log never
-- fires for a real spawn, even at HOOK_MONITOR_HIGH -- the named hook-
-- priority globals are all nil in this environment, see the "hook priority
-- constants" log above, so priority ordering can't be trusted here). Instead
-- of fighting that hook race, force-apply the class loadout one tick after
-- PlayerSpawn -- by then every other addon's PlayerLoadout hook has already
-- run and done whatever it was going to do, so this always gets the final
-- word for a player with an active class pick.
hook.Add("PlayerSpawn", "KC_Loadouts_ForceApply", function(ply)
    if not IsValid(ply) or ply:IsBot() then return end
    timer.Simple(0, function()
        if not IsValid(ply) then return end
        local ok, err = pcall(function()
            local class = GetSelectedLoadout(ply)
            if not class then
                -- A fresh spawn starts with no weapons, so forget what was given last life.
                ply.KC_NoClassEquipment = nil
                if KC_IsNoClass(ply) then KC_ApplyNoClassEquipment(ply) end
                return
            end

            KC_Log(string.format(
                "[KC Class][force-apply] PlayerSpawn+0 forcing class for %s: primary=%s secondary=%s equipment=%s",
                ply:Nick(), tostring(class.primary and weapons.Get(class.primary) ~= nil),
                tostring(class.secondary and weapons.Get(class.secondary) ~= nil), tostring(class.equipment and weapons.Get(class.equipment) ~= nil)))

            KC_GiveLoadoutNow(ply, class)
        end)
        if not ok then
            KC_Log("[KC Class][ERROR] KC_Loadouts_ForceApply threw: " .. tostring(err))
        end
    end)
end)

-- Mid-match instant class switch -- cl_class_menu.lua runs this right after
-- persisting kc_loadout_mode (picking a roster class) or a Custom slot pick,
-- so the swap happens the moment you click instead of waiting for your next
-- spawn. Trusts ply:GetInfo() exactly like PlayerLoadout/PlayerSpawn above
-- already do -- no new trust boundary, just triggered on demand instead of
-- only at spawn. Does nothing if the player has nothing alive to swap into
-- (dead/spectating) or their current selection is "none"/unresolved, same as
-- the spawn-time paths.
concommand.Add("kc_apply_loadout_now", function(ply)
    if not IsValid(ply) or ply:IsBot() or not ply:Alive() then return end

    local class = GetSelectedLoadout(ply)
    if not class then
        if KC_IsNoClass(ply) then KC_ApplyNoClassEquipment(ply) end
        return
    end

    local applied = KC_GiveLoadoutNow(ply, class)
    KC_Log(string.format("[KC Class][instant] kc_apply_loadout_now(%s): mode=%q primary=%s secondary=%s equipment=%s applied=%s",
        ply:Nick(), ply:GetInfo("kc_loadout_mode"),
        tostring(class.primary and weapons.Get(class.primary) ~= nil),
        tostring(class.secondary and weapons.Get(class.secondary) ~= nil),
        tostring(class.equipment and weapons.Get(class.equipment) ~= nil),
        tostring(applied)))
end)

-- TEMP DIAGNOSTIC -- proves this file actually loaded and the hook actually
-- registered (prints once, at file-load time, not per-spawn). If this line
-- never shows up in console at map start, sv_loadouts_give.lua itself is
-- failing to load/run -- check for a Lua error earlier in the log instead of
-- chasing the loadout logic.
do
    local names = {}
    local tbl = hook.GetTable().PlayerLoadout or {}
    for name in pairs(tbl) do table.insert(names, tostring(name)) end
    KC_Log("[KC Class][debug] sv_loadouts_give.lua loaded. PlayerLoadout hooks registered: " .. table.concat(names, ", "))
    KC_Log(string.format("[KC Class][debug] hook priority constants: MONITOR_HIGH=%s HIGH=%s NORMAL=%s LOW=%s MONITOR_LOW=%s",
        tostring(HOOK_MONITOR_HIGH), tostring(HOOK_HIGH), tostring(HOOK_NORMAL), tostring(HOOK_LOW), tostring(HOOK_MONITOR_LOW)))
end

-- TEMP DIAGNOSTIC -- run "kc_debug_loadout" in console (as the player, or
-- "kc_debug_loadout <name>" as host/console) to check what the class system
-- currently resolves to WITHOUT needing to start a round. Also re-confirms
-- the hook is registered at the moment you run it, in case something removes
-- it later (hook.Remove elsewhere, a gamemode reload, etc).
concommand.Add("kc_debug_loadout", function(ply, cmd, args)
    local target = IsValid(ply) and ply or nil
    if args[1] then
        for _, p in ipairs(player.GetAll()) do
            if p:Nick() == args[1] or tostring(p:UserID()) == args[1] then target = p end
        end
    end

    local names = {}
    local tbl = hook.GetTable().PlayerLoadout or {}
    for name in pairs(tbl) do table.insert(names, tostring(name)) end
    KC_Log("[KC Class][debug] PlayerLoadout hooks currently registered: " .. table.concat(names, ", "))

    if not IsValid(target) then
        KC_Log("[KC Class][debug] no target player (run as a player, or pass a nick/userid)")
        return
    end

    local mode = target:GetInfo("kc_loadout_mode")
    KC_Log(string.format("[KC Class][debug] %s: kc_loadout_mode=%q", target:Nick(), mode))
    local class = GetSelectedLoadout(target)
    if not class then
        KC_Log(string.format("[KC Class][debug] %s: GetSelectedLoadout returned nil", target:Nick()))
        return
    end
    KC_Log(string.format("[KC Class][debug] %s: resolved primary=%s(%s) secondary=%s(%s) equipment=%s(%s)",
        target:Nick(),
        tostring(class.primary), tostring(class.primary and weapons.Get(class.primary) ~= nil),
        tostring(class.secondary), tostring(class.secondary and weapons.Get(class.secondary) ~= nil),
        tostring(class.equipment), tostring(class.equipment and weapons.Get(class.equipment) ~= nil)))
end)
