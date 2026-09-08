local hitTime = 0
net.Receive("Killcam - Hitmarker", function()
    hitTime = CurTime() + 0.1
end)

local sizeInitialized = false
local function InitSizes()
    Scalar.SetResolution("QHD")
    Scalar.RegisterFont("Killcam_HUD", 72, 12, {
        font = "Bank Gothic",
        extended = false,
        weight = 700,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_HUD_Timer", 60, 12, {
        font = "Conduit ITC",
        extended = false,
        weight = 700,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_Name", 48, 12, {
        font = "Conduit ITC",
        extended = false,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_Rank", 48, 12, {
        font = "Conduit ITC",
        extended = false,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_Title", 40, 12, {
        font = "Conduit ITC",
        extended = false,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterSize("UI_SCALE_KCHUD", 624, 124)
    sizeInitialized = true
end

-- Animated image support for killcam titles and icons.
-- GMod cannot read GIF files. Instead, extract frames as numbered PNGs.
--
-- OPTION A - Subfolder (recommended, keeps things organized):
--   materials/killcam/icons/myemblem/000.png
--   materials/killcam/icons/myemblem/001.png
--   materials/killcam/icons/myemblem/002.png
--   Set killcam_hud_icon to "myemblem" in kc_menu.
--
-- OPTION B - Numbered files in root (legacy):
--   materials/killcam/icons/myemblem_000.png
--   materials/killcam/icons/myemblem_001.png
--   Set killcam_hud_icon to "myemblem" in kc_menu.
--
-- For a static single image, just use myemblem.png as before.
-- Frame rate defaults to 15 fps.

local ANIM_CACHE = {}

local function LoadAnimated(root, name)
    local base = name:match("^(.-)%.%w+$") or name
    local key  = root .. base

    if ANIM_CACHE[key] then return ANIM_CACHE[key] end

    local frames     = {}
    local delays     = {}
    local totalDelay = 0

    local function loadFromFolder(folderPath)
        -- Try numbered: 000.png, 001.png ...
        local numbered = {}
        local i = 0
        while true do
            local path = string.format("%s%03d.png", folderPath, i)
            local mat = Material(path, "smooth noclamp")
            if mat:IsError() then break end
            numbered[#numbered + 1] = { mat = mat, delay = 1/15 }
            i = i + 1
            if i > 512 then break end
        end
        if #numbered > 0 then return numbered end

        -- Try ezgif style: frame_XX_delay-0.03s.png sorted by name
        local files = file.Find("materials/" .. folderPath .. "frame_*.png", "GAME", "nameasc")
        if not files or #files == 0 then return nil end
        local ezgif = {}
        for _, fname in ipairs(files) do
            local mat = Material(folderPath .. fname, "smooth noclamp")
            if not mat:IsError() then
                local delay = tonumber(fname:match("delay%-([%d%.]+)s")) or (1/15)
                ezgif[#ezgif + 1] = { mat = mat, delay = delay }
            end
        end
        return #ezgif > 0 and ezgif or nil
    end

    -- Try subfolder: root/base/
    local result = loadFromFolder(root .. base .. "/")

    -- Fallback: numbered files in root root/base_000.png
    if not result then
        local fallback = {}
        local i = 0
        while true do
            local path = string.format("%s%s_%03d.png", root, base, i)
            local mat = Material(path, "smooth noclamp")
            if mat:IsError() then break end
            fallback[#fallback + 1] = { mat = mat, delay = 1/15 }
            i = i + 1
            if i > 512 then break end
        end
        if #fallback > 0 then result = fallback end
    end

    -- Final fallback: single static PNG
    if not result or #result == 0 then
        local mat = Material(root .. base .. ".png", "smooth noclamp")
        local entry = { frames = { mat }, delays = { 1/15 }, fps = 15, count = 1, isAnimated = false, key = key }
        ANIM_CACHE[key] = entry
        return entry
    end

    for _, f in ipairs(result) do
        frames[#frames + 1] = f.mat
        delays[#delays + 1] = f.delay
        totalDelay = totalDelay + f.delay
    end

    local avgFps = #frames / math.max(totalDelay, 0.001)
    local entry = {
        frames    = frames,
        delays    = delays,
        count     = #frames,
        fps       = avgFps,
        isAnimated = #frames > 1,
        key       = key,
    }
    ANIM_CACHE[key] = entry
    return entry
end

-- Returns the current frame material for an animated handle.
-- Uses per-frame delay values extracted from ezgif filenames.
local function GetFrame(handle)
    if not handle or handle.count == 0 then return nil end
    if handle.count == 1 then return handle.frames[1] end

    -- Walk through delays to find which frame we're on
    local delays = handle.delays
    if not delays then
        -- Uniform fps fallback
        local idx = math.floor(CurTime() * handle.fps) % handle.count
        return handle.frames[idx + 1]
    end

    -- Calculate total cycle duration
    local totalDur = 0
    for _, d in ipairs(delays) do totalDur = totalDur + d end

    -- Position within current cycle
    local pos = CurTime() % totalDur
    local acc = 0
    for i, d in ipairs(delays) do
        acc = acc + d
        if pos < acc then return handle.frames[i] end
    end
    return handle.frames[handle.count]
end

-- Exposed globally (purely additive -- no behavior change here) so other
-- UI that wants to show a player's calling card/icon/rank (e.g. the lobby
-- roster in lua/codhud/cl_lobby.lua) can reuse the exact same animated-card
-- loading/frame-resolution logic instead of duplicating it.
_G.Killcam_LoadAnimated = LoadAnimated
_G.Killcam_GetFrame     = GetFrame

-- Draw a handle (static or animated) at the given rect
local function MatDraw(handle, x, y, w, h)
    local mat = GetFrame(handle)
    if not mat or mat:IsError() then return end
    surface.SetMaterial(mat)
    surface.SetDrawColor(color_white)
    surface.DrawTexturedRect(x, y, w, h)
end

local bars_color = Color(0, 0, 0, 200)

--// Constant Materials (always static PNGs)
local mat_hitmarker = Material("killcam/hitmarker.png",  "smooth")
local mat_topbar    = Material("killcam/bg_248x48.png",  "smooth")
local mat_bottombar = Material("killcam/bg_248x20.png",  "smooth")

--// Console Variables
local cvar_title = CreateClientConVar("killcam_hud_title", "mw2/abstract3", true, true, "Playercard's title image filename")
local cvar_icon = CreateClientConVar("killcam_hud_icon", "mw2/abrams", true, true, "Playercard's icon filename.")
local cvar_lvl_icon = CreateClientConVar("killcam_hud_lvl_icon", "001_rank_pvt1", true, true, "Playercard's level icon filename.")

local cvar_text = CreateClientConVar("killcam_hud_text", "Custom Text", true, true, "A playercard's title text")
local cvar_clantag = CreateClientConVar("killcam_hud_clantag", "ClanTag", true, true, "A playercard's clantag text")
local cvar_lvl = CreateClientConVar("killcam_hud_lvl", "1", true, true, "A player's level.", 1, Killcam.CFG.MaxLevel or 10000)

--// Preview Materials (shown in menu when not in killcam)
local mat_title_preview = LoadAnimated("killcam/titles/", cvar_title:GetString())
local mat_icon_preview  = LoadAnimated("killcam/icons/",  cvar_icon:GetString())
local mat_lvl_preview   = LoadAnimated("killcam/ranks/",  cvar_lvl_icon:GetString())

cvars.AddChangeCallback("killcam_hud_title", function(_, _, nv)
    mat_title_preview = LoadAnimated("killcam/titles/", nv)
end, "killcam_hud_title_Cb")

cvars.AddChangeCallback("killcam_hud_icon", function(_, _, nv)
    mat_icon_preview = LoadAnimated("killcam/icons/", nv)
end, "killcam_hud_icon_Cb")

cvars.AddChangeCallback("killcam_hud_lvl_icon", function(_, _, nv)
    mat_lvl_preview = LoadAnimated("killcam/ranks/", nv)
end, "killcam_hud_lvl_icon_Cb")

--// Last material values to prevent recreating
local title_lv = "mw2/abstract3"
local icon_lv  = "mw2/abrams"
local lvl_lv   = "001_rank_pvt1"

--// Live materials (updated from global killer data during killcam)
local mat_title = LoadAnimated("killcam/titles/", title_lv)
local mat_icon  = LoadAnimated("killcam/icons/",  icon_lv)
local mat_lvl   = LoadAnimated("killcam/ranks/",  lvl_lv)

--// Replay killer data getters
local function getTitle()
    return GetGlobalString("Killcam_Killer_Title", "mw2/abstract3")
end
local function getIcon()
    return GetGlobalString("Killcam_Killer_Icon", "mw2/abrams")
end
local function getLvlIcon()
    return GetGlobalString("Killcam_Killer_LvlIcon", "001_rank_pvt1")
end

local function getNick()
    return GetGlobalString("Killcam_Killer_Nick", "aboba")
end
local function getTitleText()
    return GetGlobalString("Killcam_Killer_TitleText", "aboba")
end
local function getClanTag()
    return GetGlobalString("Killcam_Killer_ClanTag", "aboba")
end
local function getLvl()
    return GetGlobalString("Killcam_Killer_Lvl", "0")
end

local time = 0
local function getTime()
    time = Lerp(FrameTime(), time, GetGlobalFloat("Killcam_TimeToKill"))
    time = GetGlobalFloat("Killcam_TimeToKill", 0)
    return string.format("0:%04.1f", time)
end

local function DrawPlayerCard(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    local top_h, bot_h = w * 0.23, w * 0.096

    surface.SetDrawColor(color_white)
--// Top
    surface.SetMaterial(mat_topbar)
    surface.DrawTexturedRect(x, y, w, top_h)
    
--// Bottom
    surface.SetMaterial(mat_bottombar)
    surface.DrawTexturedRect(x, y + top_h, w, bot_h)
    surface.SetDrawColor(color_white)

--// Title image (supports GIF animation)
    MatDraw(mat_title, x, y - w * 0.76 * 0.02, w * 0.76, w * 0.76 * 0.2)

--// Title text -- "Custom Text" is killcam_hud_text's unset default; treat
    -- that as "never customized" and draw nothing, same as the lobby roster.
    if str_title ~= "" and str_title ~= "Custom Text" then
        draw.SimpleTextOutlined(str_title, "Killcam_Title", x + w * 0.76 * 0.5, y - w * 0.76 * 0.02 + w * 0.76 * 0.2 * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, Color(0,0,0))
    end

--// Clantag text
    draw.SimpleTextOutlined(str_clantag, "Killcam_Title", x + w * 0.02, y + top_h +  bot_h * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 3, Color(0,0,0))
    
--// Icon (supports GIF animation)
    MatDraw(mat_icon, x + w - top_h, y, top_h, top_h)
    
--// Name
    draw.SimpleTextOutlined(str_nick, "Killcam_Name", x + w * 0.025, y + w * 0.22, Color(160,255,190), TEXT_ALIGN_LEFT, TEXT_ALIGN_BOTTOM, 3, Color(0, 0, 0))
    
--// Level
    draw.SimpleTextOutlined(str_lvl, "Killcam_Rank", x + w - w * 0.025, y + top_h +  bot_h * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))

    surface.SetFont("Killcam_Rank")
    local level_size = surface.GetTextSize(str_lvl)
    MatDraw(mat_lvl, x + w - w * 0.025 - level_size - bot_h, y + top_h, bot_h, bot_h)
end

local hide = {
    ["CHudHealth"] = true,
	["CHudBattery"] = true,
	["CHudAmmo"] = true,
	["CHudSecondaryAmmo"] = true,
}

hook.Add("HUDShouldDraw", "Killcam - Disable other HUDs", function(name)
    if (KC_Playing() or Killcam.menuOpened) and hide[name] then
        return false
    end
end)

hook.Add("HUDPaint", "aaaKillcamHUD", function()
    if not sizeInitialized then
        InitSizes()
    end
    if KC_Playing() or Killcam.menuOpened then
        draw.NoTexture()
        surface.SetDrawColor(bars_color)
        surface.DrawRect(0, 0, ScrW(), ScrH()*0.1)
        surface.DrawRect(0, ScrH()*0.86 + 1, ScrW(), ScrH()*0.14)

        if KC_Playing() then
            if getTitle() ~= title_lv then
                title_lv = getTitle()
                mat_title = LoadAnimated("killcam/titles/", title_lv)
            end
            if getIcon() ~= icon_lv then
                icon_lv = getIcon()
                mat_icon = LoadAnimated("killcam/icons/", icon_lv)
            end
            if getLvlIcon() ~= lvl_lv then
                lvl_lv = getLvlIcon()
                mat_lvl = LoadAnimated("killcam/ranks/", lvl_lv)
            end

            DrawPlayerCard((ScrW() - UI_SCALE_KCHUD) * 0.5, ScrH() * 0.835, UI_SCALE_KCHUD, mat_title, mat_icon, mat_lvl, getTitleText(), getClanTag(), getNick(), getLvl())

            -- Draw CoD4 crosshair during killcam.
            if CoD4Crosshair_Draw then
                CoD4Crosshair_Draw(true)
            end
        else
            DrawPlayerCard((ScrW() - UI_SCALE_KCHUD) * 0.5, ScrH() * 0.835, UI_SCALE_KCHUD, mat_title_preview, mat_icon_preview, mat_lvl_preview, cvar_text:GetString(), cvar_clantag:GetString(), LocalPlayer():Nick(), cvar_lvl:GetString())
        end

        surface.SetDrawColor(color_white)

        --// Top bar text
        draw.SimpleText(Killcam.LANG.hud_toptext, "Killcam_HUD", ScrW()*0.5+4, ScrH()*0.1 + 4 - ScrH()*0.04, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(Killcam.LANG.hud_toptext, "Killcam_HUD", ScrW()*0.5, ScrH()*0.1 - ScrH()*0.04, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(getTime(), "Killcam_HUD_Timer", ScrW()*0.5+4, ScrH()*0.1 + 4, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(getTime(), "Killcam_HUD_Timer", ScrW()*0.5, ScrH()*0.1 , Color(230,230,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        --// Hitmarker
        if CurTime() < hitTime then
            surface.SetDrawColor(color_white)
            surface.SetMaterial(mat_hitmarker)
            surface.DrawTexturedRect(ScrW() * 0.5 - ScrH() * 0.025, ScrH() * 0.5 - ScrH() * 0.025, ScrH() * 0.05, ScrH() * 0.05)
        end

        return false
    end
end)