local hitTime = 0
function Killcam.HUDHitmarker()
    hitTime = CurTime() + 0.1
end
net.Receive("Killcam - Hitmarker", function()
    hitTime = CurTime() + 0.1
end)

-- French/German/Italian/Spanish use Poster Gothic ATF Medium for the
-- killcam title and timer; everything else keeps BankGothic Md BT.
-- Note: Spanish (Spain)'s gmod_language code is "es-es", not "es" -- matches
-- resource/localization/es-es/. Killcam_NormalizeLang (killcam_lang.lua,
-- loaded first) also aliases a bare "es" to "es-es", since some clients
-- report that instead, which used to fall through to the English font here.
--
-- MW2 Arabic: resource/fonts/18_khebrat_musamim_bold.ttf (registers as
-- "18 Khebrat Musamim", confirmed via System.Drawing.Text.PrivateFontCollection)
-- instead of the BankGothic+extended-fallback substitution every other
-- non-BO2 game's Arabic still uses. Originally gated to hudtype == "mw2"
-- only, per request -- per a later request, BO1 now shares MW2's whole
-- non-English font selection (this Arabic font included), so BO1 was added
-- to the gate here too instead of getting its own separate copy of this
-- logic.
local function GetKillcamTitleFontFamily()
    local lang = Killcam_NormalizeLang(GetConVar("gmod_language") and GetConVar("gmod_language"):GetString())
    local hudtype = CoDHUD_GetHUDType and CoDHUD_GetHUDType()
    if lang == "ar" and (hudtype == "mw2" or hudtype == "bo1") then
        return "18 Khebrat Musamim"
    end
    if lang == "fr" or lang == "de" or lang == "it" or lang == "es-es" then
        return "Poster Gothic ATF Medium"
    end
    return "BankGothic Md BT"
end

-- Neither font above has CJK or Arabic glyphs, so that text was falling
-- back to a mismatched system font mid-string ("mixing fonts"). GMod's
-- FontData needs "extended" set to actually allow that fallback to draw a
-- consistent set of glyphs instead of partially-missing ones. GMod's
-- Chinese codes are "zh-cn"/"zh-tw" (lowercase, matching es-es/sv-se's
-- convention). Arabic ("ar") gets the same treatment for the same reason --
-- note this only fixes missing glyphs, not Arabic's right-to-left
-- shaping/joining, which Source's text renderer doesn't support at all.
local function IsKillcamLangNeedsExtendedFont()
    local lang = Killcam_NormalizeLang(GetConVar("gmod_language") and GetConVar("gmod_language"):GetString())
    return lang == "zh-cn" or lang == "zh-tw" or lang == "ar"
end

local sizeInitialized = false
local function InitSizes()
    Scalar.SetResolution("QHD")
    -- "Bank Gothic Medium" isn't the font's actual registered family name --
    -- resource/fonts/bankgthd.ttf registers as "BankGothic Md BT" ("Md" =
    -- Medium), the same name already used successfully elsewhere in this
    -- addon (e.g. MW2_Score_Main in cl_a_gameloader_helpers.lua).
    local killcamTitleFont = GetKillcamTitleFontFamily()
    local killcamTitleExtended = IsKillcamLangNeedsExtendedFont()
    -- Measured 27px rendered at size 74 -- scaled linearly to hit the
    -- target 32px (74 * 32/27), same correction method as Killcam_HUD_BO2
    -- above.
    Scalar.RegisterFont("Killcam_HUD", 88, 12, {
        font = killcamTitleFont,
        extended = killcamTitleExtended,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    -- Measured 26px rendered at size 71 -- scaled linearly to hit the
    -- target 32px (71 * 32/26).
    Scalar.RegisterFont("Killcam_HUD_Timer", 87, 12, {
        font = killcamTitleFont,
        extended = killcamTitleExtended,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    -- BO2's killcam top text ("FINAL KILLCAM"/"ROUND ENDING KILLCAM") uses
    -- AgencyFB -- the same font already used for every other BO2 HUD
    -- element in this addon (cl_a_gameloader_helpers.lua) and the font
    -- Black Ops 2's real HUD actually uses. resource/fonts/AgencyFB-Bold.ttf
    -- registers as family "AgencyFB" (confirmed, no space).
    -- Size 80 confirmed against the player's own in-game reference
    -- screenshot -- a since-superseded comment here previously derived 123
    -- from an off-engine "F" glyph measurement, which turned out to render
    -- larger than the player actually wanted; reverted back to 80.
    -- weight 400, not 700 -- resource/fonts/AgencyFB-Bold.ttf is already the
    -- Bold face, so a 700 weight on top of it was synthetically double-bolding
    -- the glyphs (too thick per live comparison). Every other AgencyFB
    -- registration in this addon (cl_a_gameloader_helpers.lua) already uses
    -- 400 for the same reason -- this just brings BO2's killcam title in line.
    Scalar.RegisterFont("Killcam_HUD_BO2", 80, 12, {
        font = "AgencyFB",
        weight = 400,
        shadow = false,
        antialias = true,
    })
    -- AgencyFB has no Japanese glyphs, so lines like "ラウンド終了時キル
    -- カメラ" were falling back to a substituted system CJK font -- weight
    -- tuning on that fallback (400, 200, 100) never got thin enough since
    -- it's still just guessing at whatever weights the substituted font
    -- happens to expose. NotoSansJP-VariableFont_wght.ttf instead bakes
    -- named-instance families directly into the file (confirmed via
    -- System.Drawing.Text.PrivateFontCollection: "Noto Sans JP Thin",
    -- "Light", "Medium", etc. all register as real, separate family names)
    -- so this addresses the actual Thin weight by name instead of hoping a
    -- numeric weight lands close. Only used for the Japanese line at the
    -- draw site below, so the English "FINAL KILLCAM"/"ROUND WINNING KILL"
    -- text keeps its AgencyFB look and size untouched.
    -- Scaled down along with Killcam_HUD_BO2's revert from 123 back to 80
    -- (same 80/123 ratio applied here: 119 * (80/123) ≈ 77) so Japanese stays
    -- proportionally in sync with the English title instead of suddenly
    -- rendering much larger than it. Nudge this number directly (not by a
    -- ratio) if a live comparison shows it's off, same as every other size
    -- in this file was tuned.
    Scalar.RegisterFont("Killcam_HUD_BO2_JP", 77, 12, {
        font = "Noto Sans JP Thin",
        weight = 100,
        shadow = false,
        antialias = true,
    })
    -- BO2 Arabic: no dedicated font anymore -- shares MW2's Arabic font
    -- ("18 Khebrat Musamim", resource/fonts/18_khebrat_musamim_bold.ttf)
    -- instead of AgencyFB's missing-glyph fallback. Same BO2 size (80, 12)
    -- as Killcam_HUD_BO2 -- MW2's Killcam_HUD is a differently-sized/tuned
    -- registered font, so this reuses the font FAMILY, not that object.
    -- weight lowered from 700 -- but this TTF's own filename says "_bold"
    -- and PrivateFontCollection shows only one embedded family (no separate
    -- Light/Regular named instances like the Noto Sans JP variable font
    -- had), so it's very likely a single fixed-weight outline with no
    -- lighter version baked in. If this still renders just as thick, the
    -- weight parameter isn't the lever -- a genuinely lighter-weight Arabic
    -- font file would be needed instead.
    Scalar.RegisterFont("Killcam_HUD_BO2_AR", 80, 12, {
        font = "18 Khebrat Musamim",
        weight = 300,
        shadow = false,
        antialias = true,
    })
    -- BO1's killcam title/timer -- BankGothicCMdBT Medium in English
    -- (resource/fonts/BankGothicCMdBT-Medium.ttf, confirmed via
    -- System.Drawing.Text.PrivateFontCollection as its own family "BankGothicCMdBT Medium",
    -- separate from bankgthd.ttf's "BankGothic Md BT" used above), per request.
    -- Reference image measured the title text at 32px and the timer at 23px,
    -- the same targets Killcam_HUD/Killcam_HUD_Timer were already tuned to,
    -- so this starts from those same registered sizes -- nudge directly if a
    -- live comparison shows this particular cut renders at a different size.
    --
    -- Per a later request, non-English languages now use the SAME
    -- font-family switch MW2 uses (killcamTitleFont/killcamTitleExtended,
    -- computed once above) instead of always being forced onto
    -- BankGothicCMdBT Medium -- e.g. fr/de/it/es-es get Poster Gothic ATF
    -- Medium, Arabic gets "18 Khebrat Musamim" (see GetKillcamTitleFontFamily
    -- above, now gated to mw2 OR bo1), and zh-cn/zh-tw/ar get the "extended"
    -- fallback so their glyphs actually render instead of going missing.
    -- killcamTitleFont already IS "BankGothicCMdBT Medium"'s sibling default
    -- ("BankGothic Md BT") for English/unlisted languages, not this exact
    -- family -- BO1's own font file is kept as its English-only default so
    -- the existing English look/size is untouched, and only swaps to
    -- killcamTitleFont for languages that fork away from it.
    local bo1TitleFont = (killcamTitleFont == "BankGothic Md BT") and "BankGothicCMdBT Medium" or killcamTitleFont
    Scalar.RegisterFont("Killcam_HUD_BO1", 88, 12, {
        font = bo1TitleFont,
        extended = killcamTitleExtended,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_HUD_BO1_Timer", 87, 12, {
        font = bo1TitleFont,
        extended = killcamTitleExtended,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    -- MW3's killcam title/timer -- BankGothic Bold
    -- (resource/fonts/BankGothic Bold.ttf, confirmed via
    -- System.Drawing.Text.PrivateFontCollection as its own family "BankGothic",
    -- separate from both bankgthd.ttf's "BankGothic Md BT" and
    -- BankGothicCMdBT-Medium.ttf's "BankGothicCMdBT Medium" above), per
    -- request. No dedicated title/timer position reference was given for
    -- MW3 (unlike BO1's), so this matches MW2's own positioning and the
    -- same 32px/23px size targets as every other Killcam_HUD variant --
    -- same registered sizes as Killcam_HUD/Killcam_HUD_Timer, just this
    -- font family (a quarter-size pass was tried and reverted -- too small).
    Scalar.RegisterFont("Killcam_HUD_MW3", 88, 12, {
        font = "BankGothic",
        weight = 700,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_HUD_MW3_Timer", 87, 12, {
        font = "BankGothic",
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
    -- MW3's clantag -- bigger than the shared Killcam_Title above, per
    -- request. Same family/weight, just larger.
    Scalar.RegisterFont("Killcam_Title_MW3", 50, 12, {
        font = "Conduit ITC",
        extended = false,
        weight = 500,
        shadow = false,
        antialias = true,
    })
    -- BO2 variants of the player-card fonts (name, title text, clantag --
    -- clantag shares Killcam_Title with the title text) -- MW2 and every
    -- other HUD type keep the Conduit ITC fonts above untouched.
    -- weight 400, not 700 -- same double-bold issue as Killcam_HUD_BO2 above
    -- (AgencyFB-Bold.ttf is already the Bold face).
    Scalar.RegisterFont("Killcam_Name_BO2", 48, 12, {
        font = "AgencyFB",
        weight = 400,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_Title_BO2", 40, 12, {
        font = "AgencyFB",
        weight = 400,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterFont("Killcam_Rank_BO2", 48, 12, {
        font = "AgencyFB",
        weight = 400,
        shadow = false,
        antialias = true,
    })
    Scalar.RegisterSize("UI_SCALE_KCHUD", 624, 124)
    sizeInitialized = true
end

-- Re-register the killcam title/timer fonts if the player switches
-- language in-game, so the fr/de/it swap applies without needing a
-- restart.
cvars.AddChangeCallback("gmod_language", function()
    if sizeInitialized then
        InitSizes()
    end
end, "Killcam_LanguageFontCb")

-- Same, but for switching CoDHUD game type -- GetKillcamTitleFontFamily's
-- MW2-only Arabic check reads CoDHUD_GetHUDType() live each call, but the
-- registered font object itself only updates when InitSizes() re-runs, so
-- switching from mw2 to another game (or back) without also toggling
-- gmod_language would otherwise leave the previous game's font applied.
cvars.AddChangeCallback("codhud_game", function()
    if sizeInitialized then
        InitSizes()
    end
end, "Killcam_HUDTypeFontCb")

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

-- BO2's top/bottom letterbox bars and title-text placement, per an exact
-- pixel reference image -- fixed pixel values (not resolution-proportional
-- like MW2's ScrH()*0.1/0.14 bars below) so they match that reference
-- regardless of screen height. MW2 is untouched.
local BO2_TOP_BAR_H      = 178
local BO2_BOTTOM_BAR_H   = 178
local BO2_TITLE_TEXT_GAP = 11 -- title text sits this far above the top bar's own bottom edge (was 15, moved down 4px per live comparison against real BO2 footage)

-- BO1's top/bottom letterbox bars, per an exact pixel reference image
-- (1280x720 canvas: top bar spans rows 0-168, bottom bar spans rows
-- 555-719) -- same "fixed pixel value, not resolution-proportional"
-- approach as BO2 above.
local BO1_TOP_BAR_H      = 169
local BO1_BOTTOM_BAR_H   = 165
local BO1_BARS_ALPHA     = 153 -- 60% opacity, per request
local bars_color_bo1     = Color(0, 0, 0, BO1_BARS_ALPHA)
-- Title/timer text sit this far above the top bar's own bottom edge, per
-- the same reference image (title text's own bottom edge measured at row
-- 119, timer's at row 162 -- both distances below measured against
-- BO1_TOP_BAR_H's row 169).
local BO1_TITLE_TEXT_GAP = 50
local BO1_TIMER_GAP      = 7
-- Non-English BO1 timers (Poster Gothic ATF Medium / "18 Khebrat Musamim" /
-- the extended CJK fallback -- see GetKillcamTitleFontFamily in this file)
-- sit on a smaller (now negative) gap than English's BankGothicCMdBT
-- Medium, per request, to push them further down toward the top bar's own
-- bottom edge -- title text is untouched, only the timer moves. First pass
-- (2) wasn't far enough down per follow-up request; a negative gap here
-- pulls the timer's bottom edge below topBarH, i.e. past the bar's own
-- bottom edge. Nudge this directly (more negative = further down) if a live
-- comparison shows it still needs to move further.
local BO1_TIMER_GAP_NONEN = -6
local BO1_TEXT_ALPHA     = 153 -- 60% opacity, per request -- matches BO1_BARS_ALPHA
-- Card package moved up a few more px per request -- was titleH * 0.41.
local BO1_CARD_Y_NUDGE   = -10

-- MW3 uses MW2's own top/bottom bars directly (duplicated, not a separate
-- fixed-pixel pair like BO2/BO1 -- its own bars measured noticeably smaller
-- than MW2's, so this reuses MW2_TOP_BAR_FRAC/MW2_BOTTOM_BAR_FRAC below
-- instead of retuning a second set of constants), per request.

-- MW3 keeps a card backing like MW2 does (unlike BO1/BO2, which have none)
-- -- its own art (materials/killcam/bg_mw3_card.png, cropped from the
-- reference "MW3 back bar.png"'s 360x61 box), resized to match MW2's own
-- backing footprint per request -- see DrawPlayerCardMW3 below.
-- Card's top edge sits this far above the bottom bar's own top edge
-- (negative = above). Measured against MW3's own (now-unused) bottom bar;
-- kept as the starting offset now that the anchor is MW2's bottom bar
-- instead -- nudge directly if a live comparison shows it's off.
local MW3_CARD_TOP_OFFSET = -23
-- Name/clantag color -- per the earlier reference image's own measured
-- fill color. Reverted back to this after a brief white pass.
local MW3_GOLD = Color(255, 211, 105)

-- MW2's top/bottom bars and player-card position, tuned against a
-- side-by-side screenshot comparison with real MW2 footage (both captures
-- cropped to the same height, so vertical position/size is directly
-- comparable). The old 0.1/0.14 fractions were noticeably shorter than
-- real MW2's bars top and bottom. First pass from that comparison -- the
-- card itself (name/title/emblem/clantag) is NOT resized, only
-- repositioned, same as the real HUD's title graphic overlapping up into
-- the bottom bar's top edge. Refine further if a live in-game comparison
-- shows it's off.
-- Fractions expressed against the 1440p (QHD) design resolution used
-- elsewhere in this file for pixel-precise tuning (Scalar.SetResolution
-- "QHD" in InitSizes), so a live-comparison pixel nudge (e.g. "+30px")
-- converts to +30/1440 here and lands as 30 real px at that resolution.
local MW2_TOP_BAR_FRAC     = 0.18707 -- was 0.18638, +1px (1/1440) -- top bar extends 1px further down
local MW2_BOTTOM_BAR_FRAC  = 0.21181 -- was 0.21667, -7px (7/1440) -- bottom bar pulled back down 7px
local MW2_CARD_Y_FRAC      = 0.76319 -- was 0.75833, +7px (7/1440) -- moved back down with the bottom bar so the card keeps the same overlap gap above its top edge (0.025 * ScrH) as before

-- Title text/timer offsets from their formula-computed position, per live
-- comparison. Also expressed at the 1440p design resolution -- scaled by
-- ScrH()/1440 at draw time, same axis Scalar uses for UI_SCALE_KCHUD --
-- so they stay put proportionally at other resolutions.
local MW2_TOPTEXT_OFFSET_X   = 0   -- title text horizontally centered (was 48, moved right -- reverted so both rows are centered)
local MW2_TOPTEXT_OFFSET_Y   = 10  -- title text moved down
local MW2_TOPTEXT_WIDTH_TRIM = 2   -- title text squeezed this many px narrower (height untouched)
local MW2_TIMER_OFFSET_X     = 0   -- timer horizontally centered (was 18, moved right -- reverted so both rows are centered)
local MW2_TIMER_OFFSET_Y     = 6   -- timer moved down

-- Horizontal stretch on BO2's top-bar title text (e.g. the Japanese
-- "ラウンド終了時キルカメラ") -- real BO2 footage renders this noticeably
-- wider than a plain 1:1 draw of the same string. Starting point; tune via
-- live comparison the same way the MW2 offsets above were walked in.
local BO2_TOPTEXT_SCALE_X = 1.4
-- Vertical stretch on the same title text, per request -- taller both up
-- and down from its own baseline/center, independent of the horizontal
-- stretch above. (1.15 -> 1.35, "more" per follow-up request.)
local BO2_TOPTEXT_SCALE_Y = 1.35

--// Constant Materials (always static PNGs)
local mat_hitmarker = Material("killcam/hitmarker.png",  "smooth")
local mat_topbar    = Material("killcam/bg_248x48.png",  "smooth")
local mat_bottombar = Material("killcam/bg_248x20.png",  "smooth")
-- MW3's own card backing, cropped directly out of the reference "MW3 back
-- bar.png" (the 360x61 box region, 460-820 x/584-645 y on its 1280x720
-- canvas) -- flat art, so a plain static Material is enough, no MatDraw/
-- animation support needed.
local mat_mw3_card  = Material("killcam/bg_mw3_card.png", "smooth")

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

local function getTime()
    local time = Killcam.Replay and Killcam.Replay.GetTimeToKill() or 0
    return string.format("0:%04.1f", time)
end

local function DrawPlayerCardMW2(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
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

-- BO2's card has no bg_ backing at all -- name, clantag, emblem, prestige
-- icon, and level are all drawn directly on top of the title graphic
-- itself, not in separate bar rows below it like MW2. Layout (per
-- reference screenshot): name at the top of the title with the clantag
-- directly beneath it, the emblem to the LEFT of the name, and the
-- prestige icon centered horizontally, lower than the name, with the
-- level number spaced a little to the prestige icon's right.
local function DrawPlayerCardBO2(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    -- Height multiplier bumped 0.2 -> 0.22 -> 0.24 (title graphic stretched
    -- taller each time, width unchanged) per request/follow-up request.
    -- titleY below pins the TOP edge to the bottom bar's top edge, so the
    -- extra height grows downward, not up into the gameplay footage. Every
    -- other measurement in this function (emblem, name/clantag Y, prestige
    -- icon, level number) is already expressed as a fraction of
    -- titleW/titleH, so they all follow this stretch automatically.
    local titleW, titleH = w * 0.76, w * 0.76 * 0.24
    -- Pin the title's top edge to the bottom black bar's own top edge
    -- (see DrawKillcamOverlay's surface.DrawRect(0, ScrH()-BO2_BOTTOM_BAR_H, ...))
    -- so it never bleeds up into the visible gameplay footage above it --
    -- MW2 gets away with floating above that line because its striped
    -- bg_ backing visually covers the gap; BO2 has nothing behind it.
    -- Name/clantag/emblem/prestige below are all positioned relative to
    -- titleY, so pinning this one line keeps the whole card (title,
    -- emblem, name, clantag) tied to the top of the bottom bar together.
    --
    -- BO2 has no full-width backing bars to fill the gap the way MW2's
    -- bg_ textures do (MW2's title+icon combo already spans the whole
    -- centered box edge-to-edge). Here titleW is only 76% of the box `w`
    -- that DrawKillcamOverlay already centered on screen, so left-anchoring
    -- it at plain `x` left the whole visible package (title, emblem, name,
    -- clantag, prestige, rank) sitting left of true center with dead space
    -- on the right. Shift the whole block right by half that leftover
    -- margin so it's centered as a unit within the same box position.
    local titleX, titleY = x + (w - titleW) * 0.5, math.max(y, ScrH() - BO2_BOTTOM_BAR_H) + 6

    surface.SetDrawColor(color_white)
--// Title image (supports GIF animation)
    MatDraw(mat_title, titleX, titleY, titleW, titleH)

--// Emblem -- to the left of the name, vertically centered on the title
    local emblemSize = titleH * 0.5
    local emblemX, emblemY = titleX + titleW * 0.02, titleY + titleH * 0.5 - emblemSize * 0.5
    MatDraw(mat_icon, emblemX, emblemY, emblemSize, emblemSize)

--// Name (white, AgencyFB) -- top of the title, right of the emblem
    local nameX, nameY = emblemX + emblemSize + titleW * 0.02, titleY + titleH * 0.06
    draw.SimpleTextOutlined(str_nick, "Killcam_Name_BO2", nameX, nameY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, Color(0,0,0))

--// Clantag -- beneath the name, with extra clearance so it doesn't
    -- overlap the name's own rendered height
    draw.SimpleTextOutlined(str_clantag, "Killcam_Title_BO2", nameX, titleY + titleH * 0.52, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, Color(0,0,0))

--// Prestige icon -- lower than the name, centered horizontally
    local lvlIconSize = titleH * 0.4
    local lvlIconX, lvlIconY = titleX + titleW * 0.5 - lvlIconSize * 0.5, titleY + titleH * 0.55
    MatDraw(mat_lvl, lvlIconX, lvlIconY, lvlIconSize, lvlIconSize)

--// Level number (AgencyFB) -- spaced out to the right of the prestige icon
    draw.SimpleTextOutlined(str_lvl, "Killcam_Rank_BO2", lvlIconX + lvlIconSize + titleW * 0.02, lvlIconY + lvlIconSize * 0.5, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
end

-- BO1's card, like BO2's, has no bg_ backing bars -- the title graphic
-- itself (materials/killcam/titles/Black Ops 1/*.png, native 287x62) is the
-- whole visible backing. Layout per reference image (1280x720 canvas, card
-- box measured at 484-794 x, 582-648 y -- 310x66, centered on screen):
-- a near-full-height emblem on the left, name at the top right of it, and
-- clantag/level/rank-icon sharing a row beneath the name -- level number
-- first, THEN the rank icon to its right (opposite order from BO2, which
-- centers the prestige icon before the level number).
local function DrawPlayerCardBO1(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    -- 66/310 from the reference box measurement -- close to the title
    -- graphic's own native 62/287 aspect, but DrawTexturedRect stretches
    -- either way (BO2 does the same: titleW*0.2 vs its own asset's 64/256).
    local titleW, titleH = w * 0.76, w * 0.76 * 0.213
    local titleX = x + (w - titleW) * 0.5
    -- Bottom bar's own top edge, same anchor BO2 uses, plus the offset
    -- measured in the reference (the box sits 27px into the 66px-tall
    -- reference box below the bar's top edge, ~0.41 * titleH).
    local titleY = math.max(y, ScrH() - BO1_BOTTOM_BAR_H) + titleH * 0.41 + BO1_CARD_Y_NUDGE

    surface.SetDrawColor(color_white)
--// Title image (supports GIF animation) -- doubles as the card's only backing
    MatDraw(mat_title, titleX, titleY, titleW, titleH)

--// Emblem -- near-full card height on the left (per reference), not half
    -- height like BO2's.
    local emblemSize = titleH * 0.88
    local emblemX, emblemY = titleX + titleW * 0.02, titleY + (titleH - emblemSize) * 0.5
    MatDraw(mat_icon, emblemX, emblemY, emblemSize, emblemSize)

--// Name -- top row, right of the emblem
    local nameX = emblemX + emblemSize + titleW * 0.02
    draw.SimpleTextOutlined(str_nick, "Killcam_Name", nameX, titleY + titleH * 0.31, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 3, Color(0,0,0))

--// Clantag, level, and rank icon share a row beneath the name
    local rowY = titleY + titleH * 0.71
    draw.SimpleTextOutlined(str_clantag, "Killcam_Title", nameX, rowY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 3, Color(0,0,0))

    local lvlX = titleX + titleW * 0.455
    draw.SimpleTextOutlined(str_lvl, "Killcam_Rank", lvlX, rowY, color_white, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))

--// Rank icon -- measured off the level text's own rendered width so it
    -- stays flush next to the number regardless of digit count, same
    -- technique DrawPlayerCardMW2 already uses for its own icon placement.
    surface.SetFont("Killcam_Rank")
    local lvlW = surface.GetTextSize(str_lvl)
    local iconSize = titleH * 0.33
    MatDraw(mat_lvl, lvlX + lvlW + titleW * 0.015, rowY - iconSize * 0.5, iconSize, iconSize)
end

-- MW3 keeps a card backing like MW2, but its own art (mat_mw3_card, cropped
-- from the reference "MW3 back bar.png") instead of MW2's striped bg_ bars,
-- drawn behind everything else. Resized to match MW2's own backing
-- footprint (full card width, MW2's combined top_h+bot_h height) per
-- request. Layout re-derived from a real MW3 killcam screenshot (not the
-- earlier hand-drawn mockup) after that mockup's own proportions, stretched
-- into this much taller box, scattered everything: emblem spans the card's
-- FULL height but is sized off titleW (not titleH) so it stays a sane
-- width instead of ballooning with the height; the title graphic sits
-- upper-right of the emblem with a small gap; name sits below it; clantag
-- top-right; and the rank icon + level number sit bottom-right, pinned a
-- small margin above the card's own bottom edge (not vertically floating
-- mid-card like the previous pass).
-- Whole package (backing + everything drawn on it) scaled to these
-- fractions of MW2's own backing size -- width back to full (1.0) per
-- request, height compressed slightly. Every measurement below is a
-- fraction of titleW/titleH, so scaling those two scales everything else
-- with them automatically.
local MW3_CARD_SCALE_X = 1.0
local MW3_CARD_SCALE_Y = 0.75

local function DrawPlayerCardMW3(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    -- MW2's own backing size: full box width, top_h+bot_h tall (see
    -- DrawPlayerCardMW2's top_h/bot_h above: w*0.23 + w*0.096) -- then
    -- scaled and re-centered horizontally in that same original span.
    local titleW, titleH = w * MW3_CARD_SCALE_X, w * (0.23 + 0.096) * MW3_CARD_SCALE_Y
    local titleX = x + (w - titleW) * 0.5
    local titleY = math.max(y, ScrH() - ScrH()*MW2_BOTTOM_BAR_FRAC) + MW3_CARD_TOP_OFFSET

--// Card backing -- the actual reference art, stretched to titleW x titleH
    surface.SetDrawColor(color_white)
    surface.SetMaterial(mat_mw3_card)
    surface.DrawTexturedRect(titleX, titleY, titleW, titleH)

--// Emblem -- flush left, sized off titleW (not titleH) so it doesn't
    -- balloon into a huge square just because the backing is tall -- made
    -- vertically smaller than the card's full height per request, centered
    -- in the gap this leaves.
    local emblemW = titleW * 0.15
    local emblemH = titleH * 0.8
    local emblemY = titleY + (titleH - emblemH) * 0.5
    MatDraw(mat_icon, titleX, emblemY, emblemW, emblemH)

--// Title image (supports GIF animation), with the custom title-text cvar
    -- overlaid centered on it -- same "Custom Text" unset-default skip as
    -- DrawPlayerCardMW2. Bigger (including a bit taller still, per request)
    -- and closer to the emblem. The overlay text itself stays plain white
    -- regardless of the name/clantag color below -- it's drawn on top of
    -- the title image, not part of the name/clantag treatment.
    local imgX, imgY = titleX + emblemW + titleW * 0.012, titleY + titleH * 0.05
    local imgW, imgH = titleW * 0.66, titleH * 0.62
    surface.SetDrawColor(color_white)
    MatDraw(mat_title, imgX, imgY, imgW, imgH)
    if str_title ~= "" and str_title ~= "Custom Text" then
        draw.SimpleTextOutlined(str_title, "Killcam_Title", imgX + imgW * 0.5, imgY + imgH * 0.5, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 3, Color(0,0,0))
    end

--// Name -- beneath the title image, nudged right of its left edge (per
    -- request). Same gold as the clantag (MW3_GOLD).
    draw.SimpleTextOutlined(str_nick, "Killcam_Name", imgX + titleW * 0.02, titleY + titleH * 0.58, MW3_GOLD, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, 3, Color(0,0,0))

--// Clantag -- top right of the card, bigger font (Killcam_Title_MW3) and
    -- vertically centered on the title image's own row instead of pinned
    -- to the card's top edge.
    local rightEdgeX = titleX + titleW - titleW * 0.02
    draw.SimpleTextOutlined(str_clantag, "Killcam_Title_MW3", rightEdgeX, imgY + imgH * 0.5, MW3_GOLD, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 3, Color(0,0,0))

--// Rank icon then level number (white) -- bottom right, pinned a small
    -- margin above the card's own bottom edge. Level number right-aligned
    -- to the card's own right edge (same technique DrawPlayerCardMW2 uses),
    -- with the icon measured off to its left by the number's own rendered
    -- width so it stays flush regardless of digit count.
    local iconSize = titleH * 0.28
    local bottomMargin = titleH * 0.08
    local iconY = titleY + titleH - iconSize - bottomMargin
    draw.SimpleTextOutlined(str_lvl, "Killcam_Rank", rightEdgeX, iconY + iconSize * 0.5, color_white, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, 2, Color(0,0,0))
    surface.SetFont("Killcam_Rank")
    local lvlW = surface.GetTextSize(str_lvl)
    MatDraw(mat_lvl, rightEdgeX - lvlW - titleW * 0.015 - iconSize, iconY, iconSize, iconSize)
end

local function DrawPlayerCard(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    local hudtype = CoDHUD_GetHUDType()
    if hudtype == "bo2" then
        DrawPlayerCardBO2(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    elseif hudtype == "bo1" then
        DrawPlayerCardBO1(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    elseif hudtype == "mw3" then
        DrawPlayerCardMW3(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    else
        DrawPlayerCardMW2(x, y, w, mat_title, mat_icon, mat_lvl, str_title, str_clantag, str_nick, str_lvl)
    end
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

local function DrawKillcamOverlay()
    -- BO2 and BO1 use fixed pixel bar heights (see BO2_TOP_BAR_H/
    -- BO1_TOP_BAR_H above). MW3 duplicates MW2's own proportional bars
    -- directly (per request -- its own bars measured noticeably smaller),
    -- so it falls through to the same "else" branch as MW2 (and every
    -- other remaining HUD type) below.
    local hudtype = CoDHUD_GetHUDType()
    local isBO2Overlay = hudtype == "bo2"
    local isBO1Overlay = hudtype == "bo1"
    local isMW3Overlay = hudtype == "mw3"

    local topBarH, bottomBarH, bottomBarY, curBarsColor
    if isBO2Overlay then
        topBarH, bottomBarH = BO2_TOP_BAR_H, BO2_BOTTOM_BAR_H
        bottomBarY = ScrH() - bottomBarH
        curBarsColor = bars_color
    elseif isBO1Overlay then
        topBarH, bottomBarH = BO1_TOP_BAR_H, BO1_BOTTOM_BAR_H
        bottomBarY = ScrH() - bottomBarH
        curBarsColor = bars_color_bo1
    else
        topBarH, bottomBarH = ScrH()*MW2_TOP_BAR_FRAC, ScrH()*MW2_BOTTOM_BAR_FRAC
        bottomBarY = ScrH() - bottomBarH + 1
        curBarsColor = bars_color
    end

    draw.NoTexture()
    surface.SetDrawColor(curBarsColor)
    surface.DrawRect(0, 0, ScrW(), topBarH)
    surface.DrawRect(0, bottomBarY, ScrW(), bottomBarH)

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

        DrawPlayerCard((ScrW() - UI_SCALE_KCHUD) * 0.5, ScrH() * MW2_CARD_Y_FRAC, UI_SCALE_KCHUD, mat_title, mat_icon, mat_lvl, getTitleText(), getClanTag(), getNick(), getLvl())

        -- Draw CoD4 crosshair during killcam.
        if CoD4Crosshair_Draw then
            CoD4Crosshair_Draw(true)
        end
    else
        DrawPlayerCard((ScrW() - UI_SCALE_KCHUD) * 0.5, ScrH() * MW2_CARD_Y_FRAC, UI_SCALE_KCHUD, mat_title_preview, mat_icon_preview, mat_lvl_preview, cvar_text:GetString(), cvar_clantag:GetString(), LocalPlayer():Nick(), cvar_lvl:GetString())
    end

    surface.SetDrawColor(color_white)

    --// Top bar text -- BO2 uses AgencyFB (Killcam_HUD_BO2) instead of
    -- BankGothic/Poster Gothic, and has no countdown timer at all. The
    -- timer's own logic (getTime()) keeps running either way -- just not
    -- drawn for BO2 -- so nothing else that reads it needs to change.
    -- Japanese swaps to Killcam_HUD_BO2_JP (Noto Sans JP Thin) and Arabic
    -- swaps to Killcam_HUD_BO2_AR (Zahir Arabic), both instead of
    -- AgencyFB's missing-glyph system-font fallback. Keyed off the actual
    -- gmod_language (not IsAsciiText -- that caught every non-Latin
    -- language, not just Japanese, and would've misrouted Arabic/Chinese/
    -- Korean players onto the Japanese font).
    local topTextFont
    if isBO2Overlay then
        local topTextLang = Killcam_NormalizeLang(GetConVar("gmod_language") and GetConVar("gmod_language"):GetString())
        if topTextLang == "ja" then
            topTextFont = "Killcam_HUD_BO2_JP"
        elseif topTextLang == "ar" then
            topTextFont = "Killcam_HUD_BO2_AR"
        else
            topTextFont = "Killcam_HUD_BO2"
        end
    elseif isBO1Overlay then
        topTextFont = "Killcam_HUD_BO1"
    elseif isMW3Overlay then
        topTextFont = "Killcam_HUD_MW3"
    else
        topTextFont = "Killcam_HUD"
    end
    -- Timer's own font -- MW3 uses its own BankGothic-family timer font
    -- (Killcam_HUD_MW3_Timer) instead of the shared Killcam_HUD_Timer every
    -- other non-BO1/BO2 HUD type uses; BO1/BO2 draw their timers separately
    -- below and don't read this.
    local timerFont = isMW3Overlay and "Killcam_HUD_MW3_Timer" or "Killcam_HUD_Timer"
    -- BO2: sit BO2_TITLE_TEXT_GAP px above the top bar's own bottom edge
    -- (topBarH, fixed at BO2_TOP_BAR_H) -- a fixed pixel offset, not
    -- proportional to screen height.
    -- BO1: same fixed-pixel-offset approach, its own measured gap.
    -- MW2: timer stays flush with the top bar's own bottom edge (topBarH,
    -- unchanged). The title text's own gap above the timer's top edge is a
    -- coded constant, NOT a 1:1 px mapping to the real rendered gap (font
    -- metrics padding) -- it's been walked in via live comparison: +5
    -- coded rendered as a 32px real gap; -15 got it to 12px real; +11 got
    -- it to 16px real; +7 (another 4px up, timer untouched) gets it to
    -- 20px real, the current target.
    local topTextY
    if isBO2Overlay then
        topTextY = topBarH - BO2_TITLE_TEXT_GAP
    elseif isBO1Overlay then
        topTextY = topBarH - BO1_TITLE_TEXT_GAP
    else
        topTextY = topBarH - draw.GetFontHeight(timerFont) + 7
    end

    if isBO2Overlay then
        local tx, ty = ScrW()*0.5, topTextY
        -- Pivot the vertical scale on the text's own vertical CENTER, not the
        -- TEXT_ALIGN_BOTTOM anchor (ty) the actual draw call below uses --
        -- scaling around the bottom anchor would only grow the text upward;
        -- this makes it grow both up and down evenly, per request.
        local pivotY = ty - draw.GetFontHeight(topTextFont) * 0.5
        local mat = Matrix()
        mat:Translate(Vector(tx, pivotY, 0))
        mat:Scale(Vector(BO2_TOPTEXT_SCALE_X, BO2_TOPTEXT_SCALE_Y, 1))
        mat:Translate(Vector(-tx, -pivotY, 0))
        cam.PushModelMatrix(mat)
            -- No black shadow copy, full opacity, per request.
            draw.SimpleText(Killcam.LANG.hud_toptext, topTextFont, tx, ty, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        cam.PopModelMatrix()
    elseif isBO1Overlay then
        -- Title ("FINAL KILL" -- see killcam_lang.lua's hud_toptext override
        -- for hudtype == "bo1") and timer, both at BO1_TEXT_ALPHA (60%
        -- opacity per request) instead of the fully-opaque text every other
        -- HUD type uses -- shadow copy included, so it reads as genuinely
        -- translucent text rather than solid text behind a faint halo.
        local tx, ty = ScrW()*0.5, topTextY
        draw.SimpleText(Killcam.LANG.hud_toptext, topTextFont, tx+4, ty + 4, Color(0, 0, 0, BO1_TEXT_ALPHA), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(Killcam.LANG.hud_toptext, topTextFont, tx, ty, Color(255, 255, 255, BO1_TEXT_ALPHA), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)

        -- Non-English languages get pushed closer to the top bar's bottom
        -- edge than English's own measured/tuned gap, per request.
        local bo1KcLang = Killcam_NormalizeLang(GetConVar("gmod_language") and GetConVar("gmod_language"):GetString())
        local bo1TimerGap = (bo1KcLang == "en") and BO1_TIMER_GAP or BO1_TIMER_GAP_NONEN
        local timerY = topBarH - bo1TimerGap
        draw.SimpleText(getTime(), "Killcam_HUD_BO1_Timer", tx+4, timerY + 4, Color(0, 0, 0, BO1_TEXT_ALPHA), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(getTime(), "Killcam_HUD_BO1_Timer", tx, timerY, Color(230, 230, 230, BO1_TEXT_ALPHA), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    else
        local kchudScale = ScrH() / 1440

        -- Title text: offset from center per live comparison, and squeezed
        -- MW2_TOPTEXT_WIDTH_TRIM px narrower with the height left alone --
        -- GMod's text draw has no separate width/letter-spacing knob, so a
        -- local model-matrix scale (X only) is the only way to trim width
        -- without also shrinking the already-tuned 32px height.
        local titleX = ScrW()*0.5 + MW2_TOPTEXT_OFFSET_X * kchudScale
        local titleY = topTextY + MW2_TOPTEXT_OFFSET_Y * kchudScale
        surface.SetFont(topTextFont)
        local titleW = surface.GetTextSize(Killcam.LANG.hud_toptext)
        local titleScaleX = titleW > 0 and (titleW - MW2_TOPTEXT_WIDTH_TRIM * kchudScale) / titleW or 1

        local mat = Matrix()
        mat:Translate(Vector(titleX, titleY, 0))
        mat:Scale(Vector(titleScaleX, 1, 1))
        mat:Translate(Vector(-titleX, -titleY, 0))
        cam.PushModelMatrix(mat)
            draw.SimpleText(Killcam.LANG.hud_toptext, topTextFont, titleX+4, titleY + 4, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
            draw.SimpleText(Killcam.LANG.hud_toptext, topTextFont, titleX, titleY, color_white, TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        cam.PopModelMatrix()

        -- Timer: still flush with the top bar's own bottom edge (topBarH)
        -- before this offset, then nudged per live comparison.
        local timerX = ScrW()*0.5 + MW2_TIMER_OFFSET_X * kchudScale
        local timerY = topBarH + MW2_TIMER_OFFSET_Y * kchudScale
        draw.SimpleText(getTime(), timerFont, timerX+4, timerY + 4, Color(0,0,0), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
        draw.SimpleText(getTime(), timerFont, timerX, timerY, Color(230,230,230), TEXT_ALIGN_CENTER, TEXT_ALIGN_BOTTOM)
    end

    --// Hitmarker
    if CurTime() < hitTime then
        surface.SetDrawColor(color_white)
        surface.SetMaterial(mat_hitmarker)
        surface.DrawTexturedRect(ScrW() * 0.5 - ScrH() * 0.025, ScrH() * 0.5 - ScrH() * 0.025, ScrH() * 0.05, ScrH() * 0.05)
    end
end

-- Exposed so other VGUI panels (e.g. the pre-game lobby, cl_lobby.lua) can
-- paint this same preview into their own Paint() -- a plain HUDPaint hook
-- can't reach them because VGUI panels always render on top of HUDPaint,
-- so a full-screen frame like the lobby otherwise blocks this out entirely.
function KC_DrawKillcamPreviewOverlay()
    if not sizeInitialized then
        InitSizes()
    end
    DrawKillcamOverlay()
end

hook.Add("HUDPaint", "aaaKillcamHUD", function()
    if not sizeInitialized then
        InitSizes()
    end
    if KC_Playing() or Killcam.menuOpened then
        DrawKillcamOverlay()
        return false
    end
end)