-- Translations for "ROUND WINNING KILL" by language code
local hud_toptext_translations = {
    ["en"]    = "ROUND WINNING KILL",
    ["de"]    = "RUNDENENTSCHEIDENDER KILL",
    ["fr"]    = "ÉLIMINATION DÉCISIVE",
    ["es"]    = "ELIMINACIÓN GANADORA",
    ["it"]    = "UCCISIONE VINCENTE",
    ["pt"]    = "ABATE DECISIVO",
    ["ru"]    = "ПОБЕДНЫЙ УБИЙСТВО",
    ["pl"]    = "ZABÓJSTWO RUNDOWE",
    ["nl"]    = "RONDE WINNENDE KILL",
    ["tr"]    = "TURU KAZANDIRAN KILL",
    ["zh-CN"] = "制胜击杀",
    ["zh-TW"] = "致勝擊殺",
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
}

-- Translations for "FINAL KILLCAM" (TDM/FFA final kill)
local hud_gamewinning_translations = {
    ["en"]    = "FINAL KILLCAM",
    ["de"]    = "SPIELENTSCHEIDENDER KILL",
    ["fr"]    = "ÉLIMINATION GAGNANTE",
    ["es"]    = "ELIMINACIÓN GANADORA DEL JUEGO",
    ["it"]    = "UCCISIONE VINCENTE DEL GIOCO",
    ["pt"]    = "ABATE VENCEDOR DO JOGO",
    ["ru"]    = "ПОБЕДНЫЙ УБИЙСТВО В ИГРЕ",
    ["pl"]    = "ZABÓJSTWO WYGRYWAJĄCE GRĘ",
    ["nl"]    = "SPEL WINNENDE KILL",
    ["tr"]    = "OYUN KAZANDIRAN KILL",
    ["zh-CN"] = "游戏制胜击杀",
    ["zh-TW"] = "遊戲致勝擊殺",
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
}

-- Use a metatable so hud_toptext is always read dynamically
Killcam.LANG = setmetatable({}, {
    __index = function(t, k)
        if k == "hud_toptext" then
            local lang = GetConVar("gmod_language") and GetConVar("gmod_language"):GetString() or "en"
            local gm = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or "war"
            -- TDM and FFA (including sesh variants) are match-based, so use "Game Winning Kill"
            if gm == "war" or gm == "dm" or gm == "sesh_war" or gm == "sesh_dm" then
                return hud_gamewinning_translations[lang] or hud_gamewinning_translations["en"]
            end
            -- S&D and all other modes use "Round Winning Kill"
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