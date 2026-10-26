-- Card shown on the killcam HUD.
--
-- Real players show the card they set up in kc_menu. Bots and AI have no
-- settings of their own, so they get a card built from the installed card
-- art -- a title and emblem from the current game's set, plus a rank -- picked
-- from their name, so the same bot always shows the same card.

local GAME_FOLDER = {
    mw2 = "Modern Warfare 2", mw3 = "Modern Warfare 3",
    bo1 = "Black Ops 1", bo2 = "Black Ops 2",
    cod4 = "Modern Warfare 2", waw = "Modern Warfare 2",
}

local listCache = {}
local function Images(root, folder)
    local key = root .. folder
    if listCache[key] then return listCache[key] end
    local out = {}
    local files = file.Find("materials/" .. root .. folder .. "/*.png", "GAME", "nameasc") or {}
    for _, f in ipairs(files) do out[#out + 1] = folder .. "/" .. f:gsub("%.png$", "") end
    listCache[key] = out
    return out
end

local rankCache
local function Ranks()
    if rankCache then return rankCache end
    rankCache = {}
    for _, f in ipairs(file.Find("materials/killcam/ranks/*.png", "GAME", "nameasc") or {}) do
        rankCache[#rankCache + 1] = f:gsub("%.png$", "")
    end
    return rankCache
end

local function Pick(list, seed, fallback)
    if #list == 0 then return fallback end
    return list[(seed % #list) + 1]
end

local function DisplayName(pl)
    if pl:IsPlayer() then return pl:Nick() end
    local npcs = list.Get("NPC")
    local info = npcs and npcs[pl:GetClass()]
    return (info and info.Name) or pl.PrintName or pl:GetClass()
end

local function BotCard(pl)
    local name = DisplayName(pl)
    local seed = tonumber(util.CRC(name)) or 0
    local hud = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    local folder = GAME_FOLDER[hud] or "Modern Warfare 2"

    local titles = Images("killcam/titles/", folder)
    if #titles == 0 then titles = Images("killcam/titles/", "Modern Warfare 2") end
    local icons = Images("killcam/icons/", folder)
    if #icons == 0 then icons = Images("killcam/icons/", "Modern Warfare 2") end

    local level = 10 + (seed % 60)
    local ranks = Ranks()
    -- Rank insignia roughly track the level (the first entries are the
    -- enlisted ranks in order).
    local rank = ranks[math.Clamp(level, 1, math.max(#ranks, 1))] or "001_rank_pvt1"

    return {
        title   = Pick(titles, seed, "mw2/abstract3"),
        icon    = Pick(icons, math.floor(seed / 7), "mw2/abrams"),
        lvlIcon = rank,
        text    = "",
        clantag = pl:IsPlayer() and "BOT" or "",
        lvl     = tostring(level),
        nick    = name,
    }
end

hook.Add("OnKillcamReplayStart", "Killcam - Sync killer info", function(pl)
    local card
    if pl:IsPlayer() and not pl:IsBot() then
        card = {
            title   = pl:GetInfo("killcam_hud_title"),
            icon    = pl:GetInfo("killcam_hud_icon"),
            lvlIcon = pl:GetInfo("killcam_hud_lvl_icon"),
            text    = pl:GetInfo("killcam_hud_text"),
            clantag = pl:GetInfo("killcam_hud_clantag"),
            lvl     = pl:GetInfo("killcam_hud_lvl"),
            nick    = pl:Nick(),
        }
    else
        card = BotCard(pl)
    end

    SetGlobalString("Killcam_Killer_Title", card.title or "")
    SetGlobalString("Killcam_Killer_Icon", card.icon or "")
    SetGlobalString("Killcam_Killer_LvlIcon", card.lvlIcon or "")
    SetGlobalString("Killcam_Killer_TitleText", card.text or "")
    SetGlobalString("Killcam_Killer_ClanTag", card.clantag or "")
    SetGlobalString("Killcam_Killer_Lvl", card.lvl or "1")
    SetGlobalString("Killcam_Killer_Nick", card.nick or "")
end)
