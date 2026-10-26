-- Translations for "ROUND WINNING KILL" by language code
local hud_toptext_translations = {
    ["en"]    = "ROUND WINNING KILL",
    ["de"]    = "RUNDENGEWINNENDER ABSCHUSS",
    ["fr"]    = "ÉLIMINATION DE VICTOIRE",
    ["es-es"] = "BAJA DECISIVA DE LA RONDA",
    ["it"]    = "UCCISONE DELLA VITTORIA DEL ROUND",
    ["pt"]    = "ABATE DECISIVO",
    ["ru"]    = "ПОБЕДНЫЙ УБИЙСТВО",
    ["pl"]    = "ZABÓJSTWO RUNDOWE",
    ["nl"]    = "RONDE WINNENDE KILL",
    ["tr"]    = "TURU KAZANDIRAN KILL",
    -- GMod's actual language codes are lowercase ("zh-cn"/"zh-tw", matching
    -- how es-es/sv-se are written) -- "zh-CN"/"zh-TW" never matched, so
    -- Chinese always silently fell back to the English string, same class
    -- of bug found and fixed for Spanish above.
    ["zh-cn"] = "决胜击",
    ["zh-tw"] = "致勝擊殺",
    ["ja"]    = "ラウンド勝利キル",
    ["ko"]    = "라운드 결정타",
    ["fi"]    = "KIERROKSEN RATKAISEVA TAPPO",
    ["sv"]    = "RUND AVGÖRANDE KILL",
    ["da"]    = "RUNDEAFGØRENDE KILL",
    ["no"]    = "RUNDEVINNENDE DREP",
    ["cs"]    = "VÍTĚZNÁ ZABITÍ KOLA",
    ["hu"]    = "KÖR DÖNTŐ ÖLÉS",
    ["ro"]    = "UCIDERE CÂȘTIGĂTOARE",
    ["uk"]    = "ПЕРЕМОЖНЕ ВБИВСТВО",
    ["th"]    = "การฆ่าที่ชนะรอบ",
    -- Arabic is right-to-left and its letterforms join cursively, but
    -- Source's text renderer draws characters left-to-right as isolated
    -- glyphs with no shaping/reordering -- the translation below is
    -- correct, but it won't visually flow or join like real Arabic
    -- in-game. That's an engine limitation, not a translation issue.
    ["ar"]    = "القتلة الحاسمة للجولة",
}

-- Translations for "FINAL KILLCAM" (TDM/FFA final kill)
local hud_gamewinning_translations = {
    ["en"]    = "FINAL KILLCAM",
    ["de"]    = "SPIELGEWINNENDER ABSCHUSS",
    ["fr"]    = "ÉLIMINATION GAGNANTE",
    ["es-es"] = "BAJA FINAL",
    ["it"]    = "UCCISONE DELLA VITTORIA",
    ["pt"]    = "ABATE VENCEDOR DO JOGO",
    ["ru"]    = "ПОБЕДНЫЙ УБИЙСТВО В ИГРЕ",
    ["pl"]    = "ZABÓJSTWO WYGRYWAJĄCE GRĘ",
    ["nl"]    = "SPEL WINNENDE KILL",
    ["tr"]    = "OYUN KAZANDIRAN KILL",
    ["zh-cn"] = "决胜击",
    ["zh-tw"] = "遊戲致勝擊殺",
    ["ja"]    = "ゲーム勝利キル",
    ["ko"]    = "게임 결정타",
    ["fi"]    = "PELIN RATKAISEVA TAPPO",
    ["sv"]    = "SPELSTYRANDE KILL",
    ["da"]    = "SPILAFGØRENDE KILL",
    ["no"]    = "SPILLVINNENDE DREP",
    ["cs"]    = "VÍTĚZNÁ ZABITÍ HRY",
    ["hu"]    = "JÁTÉK DÖNTŐ ÖLÉS",
    ["ro"]    = "UCIDERE CÂȘTIGĂTOARE A JOCULUI",
    ["uk"]    = "ПЕРЕМОЖНЕ ВБИВСТВО У ГРІ",
    ["th"]    = "การฆ่าที่ชนะเกม",
    ["ar"]    = "الضربة القاضية",
}

-- gmod_language's Spanish (Spain) value hasn't reliably come back as the
-- "es-es" this file and cl_hud.lua's font-family switch both key off of --
-- some clients report a bare "es" instead, which matched neither the
-- translation table nor the fr/de/it/es-es font check, so Spain silently
-- fell back to English text AND the English (BankGothic) font. Normalize
-- casing/underscores and alias "es" to "es-es" here so both places land on
-- the right language either way.
--
-- GMod's hidden "Pirate" joke language is actually gmod_language="en-PT"
-- (confirmed via console -- not "pirate" as the name might suggest), and is
-- repurposed here to serve real Arabic content instead of pirate-speak
-- (per request), so it's aliased straight to "ar" and shares that
-- translation and the font-fallback handling below.
local LANG_ALIASES = { es = "es-es", ["en-pt"] = "ar" }
function Killcam_NormalizeLang(lang)
    lang = string.lower(lang or "en"):gsub("_", "-")
    return LANG_ALIASES[lang] or lang
end

-- Real Black Ops 2 Japanese localization strings -- distinct wording from
-- the generic "ja" entries above (which other games' killcam text also
-- reads), so this is intentionally a separate table rather than an edit to
-- hud_toptext_translations/hud_gamewinning_translations, to avoid changing
-- Japanese text for any HUD type other than BO2.
local BO2_JA_ROUND_ENDING = "ラウンド終了時キルカメラ" -- S&D / sesh_sd / sesh_sd_set
-- Full-size ア (not the small ァ of standard ファイナル) so it matches the
-- other glyphs' width, weight and height, per request.
local BO2_JA_GAME_WINNING = "フアイナルキルカメラ"     -- TDM/FFA / sesh_war / sesh_dm

-- Real BO2 footage reads "ROUND ENDING KILLCAM" for S&D-style modes, not the
-- generic "ROUND WINNING KILL" every other HUD type's English string uses
-- (hud_toptext_translations["en"] above) -- per request, kept BO2-only the
-- same way the Japanese override above is. "FINAL KILLCAM" (game-winning,
-- hud_gamewinning_translations["en"]) is already correct for BO2 and is left
-- untouched.
local BO2_EN_ROUND_ENDING = "ROUND ENDING KILLCAM"

-- Use a metatable so hud_toptext is always read dynamically
Killcam.LANG = setmetatable({}, {
    __index = function(t, k)
        if k == "hud_toptext" then
            local lang = Killcam_NormalizeLang(GetConVar("gmod_language") and GetConVar("gmod_language"):GetString())
            local gm = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or "war"
            local isBO2 = CoDHUD_GetHUDType and CoDHUD_GetHUDType() == "bo2"
            -- BO1 still always shows "FINAL KILL" in English -- no gamemode
            -- distinction, and the English wording itself is unchanged, per
            -- the original request. But per a later request, non-English
            -- languages now get the same translated strings MW2 (and every
            -- other non-BO2 HUD) uses instead of silently staying in
            -- English -- hud_gamewinning_translations is the "FINAL
            -- KILLCAM"-family table, the closest existing match to BO1's own
            -- "FINAL KILL" wording, so that's reused here rather than adding
            -- a whole separate BO1-specific translation table.
            if CoDHUD_GetHUDType and CoDHUD_GetHUDType() == "bo1" then
                if lang == "en" then return "FINAL KILL" end
                return hud_gamewinning_translations[lang] or "FINAL KILL"
            end
            -- TDM and FFA (including sesh variants) are match-based, so use "Game Winning Kill"
            if gm == "war" or gm == "dm" or gm == "sesh_war" or gm == "sesh_dm" then
                if isBO2 and lang == "ja" then return BO2_JA_GAME_WINNING end
                return hud_gamewinning_translations[lang] or hud_gamewinning_translations["en"]
            end
            -- S&D and all other modes use "Round Winning Kill"
            if isBO2 and lang == "ja" then return BO2_JA_ROUND_ENDING end
            if isBO2 and lang == "en" then return BO2_EN_ROUND_ENDING end
            return hud_toptext_translations[lang] or hud_toptext_translations["en"]
        end
        return rawget(t, k)
    end
})

Killcam.LANG.menu_title             = "Garry's Mod Killcam Customisation By Scripts&Maps"
Killcam.LANG.menu_titles_label      = "Titles"
Killcam.LANG.menu_icons_label       = "Emblems"
Killcam.LANG.menu_ranks_label       = "Prestiges"
Killcam.LANG.menu_entry_title_label = "Title text:"
Killcam.LANG.menu_entry_clantag_label = "Clan Tag:"
Killcam.LANG.menu_entry_level_label = "Level:"
Killcam.LANG["Modern Warfare 2/"]   = "Modern Warfare 2"
Killcam.LANG["Modern Warfare 3/"]   = "Modern Warfare 3"
Killcam.LANG["Black Ops 1/"]        = "Black Ops 1"
Killcam.LANG["Black Ops 2/"]        = "Black Ops 2"
Killcam.LANG["Black Ops 3/"]        = "Black Ops 3"
Killcam.LANG["Call Of Duty Ghosts"] = "Call Of Duty Ghosts"
Killcam.LANG["World War 2"]         = "World War 2"
Killcam.LANG["Miscellaneous"]       = "Miscellaneous"
Killcam.LANG["Prestige Logos"]      = "Prestige Logos"