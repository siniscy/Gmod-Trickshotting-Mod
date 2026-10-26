---- [ CLIENT: CREATE A CLASS MENU ] ----
-- CoD-style "Create a Class" screen, opened from the lobby sidebar above
-- Callsign (see cl_lobby.lua). Pick one of the fixed default classes, build
-- a "Custom" class (Primary/Secondary/Equipment, freely re-pickable), or opt
-- out entirely with "No Class" -- manual pickup, exactly like before this
-- system existed. Selection lives in the kc_loadout_* client convars
-- (cl_loadouts_convars.lua) -- archived + userinfo, so it just persists,
-- same pattern the killcam card customization menu (kc_menu) already uses.
--
-- Built with stock Derma to match cl_lobby.lua/cl_settings.lua's existing
-- convention -- xpgui is reserved for kc_menu.

local COL_PANEL   = Color(15, 16, 19, 235)
local COL_ROW     = Color(40, 40, 44, 220)
local COL_ROW_HL  = Color(60, 90, 130, 220)
local COL_ROW_SEL = Color(70, 130, 190, 230)
local COL_TEXT    = Color(230, 230, 230)
local COL_SUBTEXT = Color(170, 170, 170)
local COL_SLOT    = Color(28, 30, 34, 230)

local KC_ClassMenu_Frame = nil

local function GetWeaponDisplayName(classname)
    if not classname or classname == "" then return "-- None --" end
    local tbl = weapons.Get(classname)
    return (tbl and tbl.PrintName) or classname
end

-- Mid-match instant swap: kc_apply_loadout_now (sv_loadouts_give.lua) reads
-- the just-changed kc_loadout_mode/kc_custom_* convars straight off
-- ply:GetInfo() server-side. Those are userinfo convars (cl_loadouts_convars.lua)
-- so the new value needs a moment to actually reach the server -- firing the
-- concommand in the same tick as the SetString() risks the server reading it
-- before that sync lands and re-applying the OLD selection instead.
local function ApplyLoadoutSoon()
    timer.Simple(0.1, function()
        RunConsoleCommand("kc_apply_loadout_now")
    end)
end

-- Per-player overrides of a PRESET class's Primary/Secondary/Equipment, per
-- request ("option to change preset classes but also have a reset to
-- default"). One archived+userinfo convar per class per slot, named off the
-- class's own id -- same pattern as kc_custom_primary/secondary/equipment
-- (cl_loadouts_convars.lua), just one set per preset instead of one shared
-- set. Empty string means "no override, use the class's hardcoded default"
-- -- sv_loadouts_give.lua's GetSelectedLoadout reads these the same way.
-- Created lazily (idempotent -- GMod no-ops a repeat CreateClientConVar for
-- an existing name) instead of in cl_loadouts_convars.lua, since that file
-- loads alphabetically BEFORE sh_loadouts_data.lua and KC_Loadouts.DefaultClasses
-- wouldn't exist yet.
local function EnsureOverrideConvars()
    for _, c in ipairs(KC_Loadouts.DefaultClasses) do
        for _, slot in ipairs({ "primary", "secondary", "equipment" }) do
            local name = "kc_override_" .. c.id .. "_" .. slot
            if not ConVarExists(name) then
                CreateClientConVar(name, "", true, true,
                    "Per-player override for " .. c.name .. "'s " .. slot .. " -- empty means use the hardcoded default.")
            end
        end
    end
end

local function GetOverrideConVar(classId, slot)
    return GetConVar("kc_override_" .. classId .. "_" .. slot)
end

local function BuildRosterList()
    local list = {}
    -- No Class (manual pickup) is the default, so it's listed first.
    table.insert(list, { id = "none", name = language.GetPhrase("CoDHUD.ClassMenu.NoClass") })
    for _, c in ipairs(KC_Loadouts.DefaultClasses) do
        table.insert(list, { id = c.id, name = c.name, class = c })
    end
    table.insert(list, { id = "custom", name = language.GetPhrase("CoDHUD.ClassMenu.Custom") })
    return list
end

-- A small popup listing every weapon in `pool`, grouped by .group, that
-- immediately fires onSelect(classname) and closes on click. With allowNone, a
-- "-- None --" entry at the top fires onSelect("") to clear the slot.
local function OpenWeaponPicker(title, pool, currentClassname, onSelect, allowNone)
    local pf = vgui.Create("DFrame")
    pf:SetSize(420, 520)
    pf:Center()
    pf:SetTitle(title)
    pf:MakePopup()
    pf.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, COL_PANEL)
    end

    local scroll = vgui.Create("DScrollPanel", pf)
    scroll:Dock(FILL)
    scroll:DockMargin(6, 6, 6, 6)

    if allowNone then
        local noneBtn = vgui.Create("DButton", scroll)
        noneBtn:Dock(TOP)
        noneBtn:DockMargin(0, 0, 0, 2)
        noneBtn:SetTall(30)
        noneBtn:SetText("")

        local noneSelected = (not currentClassname or currentClassname == "")
        noneBtn.Paint = function(self, bw, bh)
            local col = noneSelected and COL_ROW_SEL or (self:IsHovered() and COL_ROW_HL or COL_ROW)
            draw.RoundedBox(0, 0, 0, bw, bh, col)
            draw.SimpleText("-- None --", "DermaDefault", 10, bh / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        noneBtn.DoClick = function()
            onSelect("")
            pf:Close()
        end
    end

    local groups, order = {}, {}
    for _, w in ipairs(pool) do
        local g = w.group or "Weapons"
        if not groups[g] then
            groups[g] = {}
            table.insert(order, g)
        end
        table.insert(groups[g], w)
    end

    for _, g in ipairs(order) do
        local lbl = vgui.Create("DLabel", scroll)
        lbl:Dock(TOP)
        lbl:DockMargin(4, 8, 4, 2)
        lbl:SetFont("DermaDefaultBold")
        lbl:SetTextColor(COL_SUBTEXT)
        lbl:SetText(string.upper(g))

        for _, w in ipairs(groups[g]) do
            local btn = vgui.Create("DButton", scroll)
            btn:Dock(TOP)
            btn:DockMargin(0, 0, 0, 2)
            btn:SetTall(30)
            btn:SetText("")

            local selected = (w.classname == currentClassname)
            btn.Paint = function(self, bw, bh)
                local col = selected and COL_ROW_SEL or (self:IsHovered() and COL_ROW_HL or COL_ROW)
                draw.RoundedBox(0, 0, 0, bw, bh, col)
                draw.SimpleText(w.name, "DermaDefault", 10, bh / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end
            btn.DoClick = function()
                onSelect(w.classname)
                pf:Close()
            end
        end
    end

    return pf
end

-- One Primary/Secondary/Equipment row. Read-only for default classes;
-- clickable (opens OpenWeaponPicker) for Custom.
local function MakeSlotRow(parent, label, classnameGetter, isEditable, onPick)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:SetTall(64)
    row:DockMargin(0, 8, 0, 0)
    row.Paint = function(self, w, h)
        draw.RoundedBox(2, 0, 0, w, h, COL_SLOT)
    end

    local lbl = vgui.Create("DLabel", row)
    lbl:SetPos(14, 6)
    lbl:SetSize(300, 18)
    lbl:SetFont("DermaDefaultBold")
    lbl:SetTextColor(COL_SUBTEXT)
    lbl:SetText(string.upper(label))

    local val = vgui.Create("DLabel", row)
    val:SetPos(14, 26)
    val:SetSize(400, 26)
    val:SetFont("DermaLarge")
    val:SetTextColor(COL_TEXT)
    val:SetText(GetWeaponDisplayName(classnameGetter()))

    if isEditable and onPick then
        local editBtn = vgui.Create("DButton", row)
        editBtn:SetText(language.GetPhrase("CoDHUD.ClassMenu.Change"))
        editBtn:SetSize(90, 28)
        editBtn:SetPos(row:GetWide() - 100, 18)
        row.PerformLayout = function(self, w, h)
            editBtn:SetPos(w - 100, 18)
        end
        editBtn.DoClick = function()
            onPick(function(cn) val:SetText(GetWeaponDisplayName(cn)) end)
        end
    end

    return row
end

-- Current value for one slot, whichever source is active for this entry:
-- Custom's own convar, a preset's per-player override (if set), or -- for a
-- preset with no override -- the class's hardcoded default.
local function GetSlotValue(entry, isCustom, slot)
    if isCustom then
        return GetConVar("kc_custom_" .. slot):GetString()
    end
    local override = GetOverrideConVar(entry.id, slot):GetString()
    if override ~= "" then return override end
    return entry.class[slot]
end

local function RefreshDetail(detail, entry)
    detail:Clear()

    local isCustom = entry.id == "custom"
    local isNone   = entry.id == "none"
    local isPreset = not isCustom and not isNone

    local title = vgui.Create("DLabel", detail)
    title:Dock(TOP)
    title:SetTall(36)
    title:SetFont("DermaLarge")
    title:SetTextColor(COL_TEXT)
    title:SetText(entry.name)

    if isPreset then
        local resetBtn = vgui.Create("DButton", detail)
        resetBtn:Dock(TOP)
        resetBtn:DockMargin(0, 4, 0, 0)
        resetBtn:SetTall(28)
        resetBtn:SetWide(160)
        resetBtn:SetText(language.GetPhrase("CoDHUD.ClassMenu.ResetToDefault"))
        resetBtn.DoClick = function()
            for _, slot in ipairs({ "primary", "secondary", "equipment" }) do
                GetOverrideConVar(entry.id, slot):SetString("")
            end
            ApplyLoadoutSoon()
            RefreshDetail(detail, entry)
        end
    end

    if isNone then
        local info = vgui.Create("DLabel", detail)
        info:Dock(TOP)
        info:SetTall(80)
        info:DockMargin(0, 10, 0, 0)
        info:SetFont("DermaDefault")
        info:SetTextColor(COL_SUBTEXT)
        info:SetText(language.GetPhrase("CoDHUD.ClassMenu.NoClassInfo"))
        info:SetWrap(true)
        info:SetAutoStretchVertical(true)

        -- No Class still gets an optional equipment item (any equipment, or
        -- "-- None --"); weapons stay manual pickup.
        MakeSlotRow(detail, language.GetPhrase("CoDHUD.ClassMenu.Equipment"),
            function() return GetConVar("kc_noclass_equipment"):GetString() end,
            true, function(setDisplay)
                local cv = GetConVar("kc_noclass_equipment")
                OpenWeaponPicker(language.GetPhrase("CoDHUD.ClassMenu.Equipment"), KC_Loadouts.BuildEquipmentPool(),
                    cv:GetString(), function(cn)
                        cv:SetString(cn)
                        setDisplay(cn)
                        ApplyLoadoutSoon()
                    end, true)
            end)
        return
    end

    local isEditable = isCustom or isPreset

    MakeSlotRow(detail, language.GetPhrase("CoDHUD.ClassMenu.Primary"),
        function() return GetSlotValue(entry, isCustom, "primary") end,
        isEditable, function(setDisplay)
            local cv = isCustom and GetConVar("kc_custom_primary") or GetOverrideConVar(entry.id, "primary")
            OpenWeaponPicker(language.GetPhrase("CoDHUD.ClassMenu.Primary"), KC_Loadouts.BuildFullWeaponPool(),
                cv:GetString(), function(cn)
                    cv:SetString(cn)
                    setDisplay(cn)
                    ApplyLoadoutSoon()
                end)
        end)

    MakeSlotRow(detail, language.GetPhrase("CoDHUD.ClassMenu.Secondary"),
        function() return GetSlotValue(entry, isCustom, "secondary") end,
        isEditable, function(setDisplay)
            local cv = isCustom and GetConVar("kc_custom_secondary") or GetOverrideConVar(entry.id, "secondary")
            OpenWeaponPicker(language.GetPhrase("CoDHUD.ClassMenu.Secondary"), KC_Loadouts.BuildFullWeaponPool(),
                cv:GetString(), function(cn)
                    cv:SetString(cn)
                    setDisplay(cn)
                    ApplyLoadoutSoon()
                end)
        end)

    MakeSlotRow(detail, language.GetPhrase("CoDHUD.ClassMenu.Equipment"),
        function() return GetSlotValue(entry, isCustom, "equipment") end,
        isEditable, function(setDisplay)
            local cv = isCustom and GetConVar("kc_custom_equipment") or GetOverrideConVar(entry.id, "equipment")
            OpenWeaponPicker(language.GetPhrase("CoDHUD.ClassMenu.Equipment"), KC_Loadouts.BuildEquipmentPool(),
                cv:GetString(), function(cn)
                    cv:SetString(cn)
                    setDisplay(cn)
                    ApplyLoadoutSoon()
                end)
        end)
end

local function OpenClassMenu()
    if IsValid(KC_ClassMenu_Frame) then KC_ClassMenu_Frame:Remove() end

    EnsureOverrideConvars()

    local w = math.min(ScrW() * 0.6, 900)
    local h = math.min(ScrH() * 0.7, 620)

    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:Center()
    frame:SetTitle(language.GetPhrase("CoDHUD.Lobby.Classes"))
    frame:MakePopup()
    frame.Paint = function(self, pw, ph)
        draw.RoundedBox(2, 0, 0, pw, ph, COL_PANEL)
    end
    KC_ClassMenu_Frame = frame

    -- TEMP DIAGNOSTIC -- what the client currently has saved the moment the
    -- menu is opened, so a stale/reset convar shows up even before you touch
    -- anything.
    print(string.format("[KC Class] ClassMenu opened: mode=%q primary=%q secondary=%q equipment=%q",
        GetConVar("kc_loadout_mode"):GetString(), GetConVar("kc_custom_primary"):GetString(),
        GetConVar("kc_custom_secondary"):GetString(), GetConVar("kc_custom_equipment"):GetString()))

    local roster = BuildRosterList()

    local list = vgui.Create("DPanel", frame)
    list:Dock(LEFT)
    list:SetWide(220)
    list:DockMargin(10, 30, 0, 10)
    list.Paint = nil

    local detail = vgui.Create("DPanel", frame)
    detail:Dock(FILL)
    detail:DockMargin(20, 30, 10, 10)
    detail.Paint = nil

    local currentMode = GetConVar("kc_loadout_mode"):GetString()
    local rowButtons = {}

    local function SelectEntry(entry, persist)
        for _, b in ipairs(rowButtons) do b.selected = (b.entryId == entry.id) end
        if persist then
            GetConVar("kc_loadout_mode"):SetString(entry.id)
            -- TEMP DIAGNOSTIC -- confirms the click actually reached the
            -- convar (readback, not just the value we tried to set).
            print(string.format("[KC Class] ClassMenu: persisted kc_loadout_mode=%q (readback=%q)",
                entry.id, GetConVar("kc_loadout_mode"):GetString()))
            -- Instant mid-match swap -- if you're alive, don't make picking a
            -- class here wait for your next spawn like the lobby version does.
            ApplyLoadoutSoon()
        end
        RefreshDetail(detail, entry)
    end

    local foundCurrent = false
    for _, entry in ipairs(roster) do
        local btn = vgui.Create("DButton", list)
        btn:Dock(TOP)
        btn:SetTall(36)
        btn:DockMargin(0, 0, 0, 2)
        btn:SetText("")
        btn.entryId = entry.id
        btn.selected = (entry.id == currentMode)
        btn.Paint = function(self, bw, bh)
            local col = self.selected and COL_ROW_SEL or (self:IsHovered() and COL_ROW_HL or COL_ROW)
            draw.RoundedBox(0, 0, 0, bw, bh, col)
            draw.SimpleText(entry.name, "DermaDefaultBold", 12, bh / 2, COL_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
        btn.DoClick = function() SelectEntry(entry, true) end
        table.insert(rowButtons, btn)

        if entry.id == currentMode then
            foundCurrent = true
            RefreshDetail(detail, entry)
        end
    end

    -- Saved mode no longer exists (e.g. a default class id was renamed/
    -- removed since the player last picked it) -- fall back to Custom
    -- instead of leaving the detail panel blank.
    if not foundCurrent then
        for _, entry in ipairs(roster) do
            if entry.id == "custom" then
                SelectEntry(entry, false)
                break
            end
        end
    end
end

concommand.Add("kc_classmenu", OpenClassMenu)

-- "K" opens this same screen mid-match (not just the lobby sidebar button),
-- so players can change classes for their next spawn without returning to
-- the lobby. Reuses OpenClassMenu() directly -- same KC_Loadouts.DefaultClasses
-- data and same kc_loadout_mode/kc_custom_* convars as the lobby's version,
-- so there's no separate menu that could drift out of sync with it.
local function ToggleClassMenu()
    if IsValid(KC_ClassMenu_Frame) then
        KC_ClassMenu_Frame:Remove()
        return
    end
    OpenClassMenu()
end

local KC_ClassMenuKeyWasDown = false
hook.Add("Think", "KC_ClassMenu_KeyBind", function()
    local down = input.IsKeyDown(KEY_K)
    if down and not KC_ClassMenuKeyWasDown then
        -- Don't hijack "k" while it's being typed into chat, the console, a
        -- weapon-picker search box, or any other focused text entry.
        local focus = vgui.GetKeyboardFocus()
        if not IsValid(focus) and not gui.IsConsoleVisible() then
            ToggleClassMenu()
        end
    end
    KC_ClassMenuKeyWasDown = down
end)
