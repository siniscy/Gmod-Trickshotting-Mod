---- [ CLIENT PRE-GAME LOBBY ] ----
-- Full-screen "Private Match"-style lobby, styled after a real CoD private
-- match screen: title top-left, a vertical menu on the left (Start Game /
-- Game Setup / Callsign / Barracks / Invite), the player roster top-right,
-- and a map/gamemode readout bottom-left. Admin-only items (Start Game,
-- Game Setup) render dimmed and inert for non-admins instead of a separate
-- image/layout. Built with stock Derma to match cl_settings.lua's existing
-- convention -- xpgui (lua/xpgui/vgui/*.lua) is reserved for kc_menu.

KC_Lobby_ActiveCL = KC_Lobby_ActiveCL or false
local KC_Lobby_Roster = {}
local KC_Lobby_Frame = nil

local COL_TITLE     = Color(255, 255, 255, 255)
local COL_ACTIVE    = Color(255, 255, 255, 255)
local COL_ACTIVE_HL = Color(120, 190, 255, 255)
local COL_INERT     = Color(110, 110, 115, 255)
local COL_DIVIDER   = Color(70, 70, 75, 255)
local COL_PANEL     = Color(15, 16, 19, 210)
local COL_ROW       = Color(45, 45, 45, 200)
local COL_ROW_BOT   = Color(70, 45, 45, 200)

surface.CreateFont("KC_Lobby_ClanTag", {
    font   = "Roboto",
    size   = 36,
    weight = 700,
})

-- The killcam HUD's own card-title font (Killcam_Title, cl_hud.lua) is sized
-- for a full-screen killcam overlay via the Scalar system -- far too large
-- for this compact roster card, so this is a dedicated small equivalent
-- just for drawing killcam_hud_text over the card here.
surface.CreateFont("KC_Lobby_CardText", {
    font   = "Roboto",
    size   = 30,
    weight = 800,
})

surface.CreateFont("KC_Lobby_Name", {
    font   = "Roboto",
    size   = 28,
    weight = 700,
})

-- Abstract grey/light-blue backing, built from stock GMod gradient materials
-- (vgui/gradient-l is already used elsewhere in this addon, e.g. cl_chat.lua)
-- rather than a custom texture asset.
local MAT_GRAD_D = Material("vgui/gradient-d")
local MAT_GRAD_U = Material("vgui/gradient-u")

-- User-supplied backing image, expected at:
-- garrysmod/addons/kc_project_0.75/materials/kc_lobby/gmodback.jpeg
-- Falls back to the procedural gradient below if that file isn't present.
local MAT_BG_IMAGE = Material("kc_lobby/gmodback.jpeg", "noclamp smooth")

local function PaintAbstractBackground(sw, sh)
    if not MAT_BG_IMAGE:IsError() then
        surface.SetMaterial(MAT_BG_IMAGE)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(0, 0, sw, sh)

        -- One flat, uniform tint over the whole image -- matched to the same
        -- dark navy the roster/panel boxes use (COL_PANEL) -- rather than
        -- layered vignette gradients, which made different parts of the
        -- screen read as different shades of black next to the panels.
        surface.SetDrawColor(14, 16, 20, 200)
        surface.DrawRect(0, 0, sw, sh)
        return
    end

    draw.RoundedBox(0, 0, 0, sw, sh, Color(38, 42, 48, 255))

    surface.SetMaterial(MAT_GRAD_D)
    surface.SetDrawColor(90, 140, 190, 130)
    surface.DrawTexturedRect(0, 0, sw, sh * 0.55)

    surface.SetMaterial(MAT_GRAD_U)
    surface.SetDrawColor(60, 70, 85, 150)
    surface.DrawTexturedRect(0, sh * 0.45, sw, sh * 0.55)

    surface.SetDrawColor(120, 170, 210, 25)
    surface.DrawRect(sw * 0.25, 0, sw * 0.2, sh)
    surface.DrawRect(sw * 0.62, 0, sw * 0.14, sh)
end

-- Calling-card materials use the exact same loader the killcam HUD itself
-- uses (lua/killcam/cl_hud.lua's LoadAnimated/GetFrame, exposed globally as
-- Killcam_LoadAnimated/Killcam_GetFrame) -- so animated cards/icons/rank
-- icons (subfolder frame sequences or ezgif-style exports) play here
-- exactly like they do in the real killcam HUD, with no duplicated logic.
-- Root paths: "killcam/titles/<name>", "killcam/icons/<name>", "killcam/ranks/<name>".
local CARD_HANDLE_CACHE = {}
local function GetCardHandle(root, name)
    if not name or name == "" then return nil end
    if not Killcam_LoadAnimated then return nil end
    local key = root .. name
    if not CARD_HANDLE_CACHE[key] then
        CARD_HANDLE_CACHE[key] = Killcam_LoadAnimated(root, name)
    end
    return CARD_HANDLE_CACHE[key]
end

-- Resolves an animated/static handle to its current frame material, or nil.
local function GetCardFrame(handle)
    if not handle or not Killcam_GetFrame then return nil end
    local mat = Killcam_GetFrame(handle)
    if not mat or mat:IsError() then return nil end
    return mat
end

local function GetGamemodeChoices()
    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    return (CoDHUD.Gamemodes and CoDHUD.Gamemodes[hudType]) or {}
end

-- A text-only clickable menu item matching the reference's flat sidebar look.
local function CreateMenuItem(parent, text, enabled, onClick)
    local btn = vgui.Create("DButton", parent)
    btn:SetText("")
    btn:SetTall(34)
    btn.hovered = false
    btn.enabled = enabled

    btn.Paint = function(self, w, h)
        local col = COL_INERT
        if enabled then
            col = self.hovered and COL_ACTIVE_HL or COL_ACTIVE
        end
        draw.SimpleText(text, "DermaLarge", 0, h / 2, col, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    btn.OnCursorEntered = function(self) self.hovered = true end
    btn.OnCursorExited  = function(self) self.hovered = false end

    if enabled and onClick then
        btn.DoClick = onClick
    else
        btn.DoClick = function() end
    end

    return btn
end

local function CreateDivider(parent)
    local div = vgui.Create("DPanel", parent)
    div:SetTall(1)
    div:Dock(TOP)
    div:DockMargin(0, 10, 40, 10)
    div.Paint = function(self, w, h)
        surface.SetDrawColor(COL_DIVIDER)
        surface.DrawRect(0, 0, w, h)
    end
    return div
end

local CARD_W, CARD_H = 260, 80
local ICON_SIZE       = 80
local ICON_GAP        = 24
local RANK_SIZE       = 60

local function CreateRosterRow(parent, entry)
    local row = vgui.Create("DPanel", parent)
    row:Dock(TOP)
    row:DockMargin(0, 0, 0, 4)
    row:SetTall(entry.isBot and 60 or 144)

    if entry.isBot then
        row.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, COL_ROW_BOT)
        end
        local nameLbl = vgui.Create("DLabel", row)
        nameLbl:Dock(FILL)
        nameLbl:DockMargin(10, 0, 10, 0)
        nameLbl:SetFont("DermaDefaultBold")
        nameLbl:SetTextColor(Color(255, 255, 255))
        nameLbl:SetText(entry.nick)
        nameLbl:SetContentAlignment(4)
        return row
    end

    local titleHandle = GetCardHandle("killcam/titles/", entry.title)
    local iconHandle  = GetCardHandle("killcam/icons/", entry.icon)
    local rankHandle  = GetCardHandle("killcam/ranks/", entry.lvlIcon)

    -- Layout (matches the reference): title card and emblem side by side
    -- with a gap on the top line, rank icon + level right-aligned on that
    -- same line, and the player's name/clan tag on the line underneath.
    row.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, COL_ROW)

        local cardX, cardY = 12, 12
        local titleMat = GetCardFrame(titleHandle)
        if titleMat then
            surface.SetMaterial(titleMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(cardX, cardY, CARD_W, CARD_H)
        else
            surface.SetDrawColor(55, 55, 58, 255)
            surface.DrawRect(cardX, cardY, CARD_W, CARD_H)
        end
        -- killcam_hud_text drawn centered over the card, same as the real
        -- killcam HUD's card (cl_hud.lua's DrawPlayerCard), just at a size
        -- that fits this compact row instead of a full killcam overlay.
        -- "Custom Text" is the convar's unset default (cl_hud.lua:206) --
        -- treat that as "never customized" and show nothing, rather than
        -- literally displaying the placeholder text.
        if entry.text ~= "" and entry.text ~= "Custom Text" then
            draw.SimpleTextOutlined(entry.text, "KC_Lobby_CardText", cardX + CARD_W / 2, cardY + CARD_H / 2,
                Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0))
        end

        local iconX, iconY = cardX + CARD_W + ICON_GAP, cardY + (CARD_H - ICON_SIZE) / 2
        local iconMat = GetCardFrame(iconHandle)
        if iconMat then
            surface.SetMaterial(iconMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(iconX, iconY, ICON_SIZE, ICON_SIZE)
        end

        local rankX, rankY = w - RANK_SIZE - 120, cardY + (CARD_H - RANK_SIZE) / 2
        local rankMat = GetCardFrame(rankHandle)
        if rankMat then
            surface.SetMaterial(rankMat)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(rankX, rankY, RANK_SIZE, RANK_SIZE)
        end
        if entry.lvl ~= "" then
            draw.SimpleText(entry.lvl, "KC_Lobby_ClanTag", rankX + RANK_SIZE + 16, cardY + CARD_H / 2, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end
    end

    local nameLbl = vgui.Create("DLabel", row)
    nameLbl:SetPos(12, 12 + CARD_H + 8)
    nameLbl:SetSize(520, 40)
    nameLbl:SetFont("KC_Lobby_Name")
    nameLbl:SetTextColor(entry.isAdmin and Color(255, 200, 60) or Color(255, 255, 255))
    nameLbl:SetText(entry.nick .. (entry.isAdmin and "  [HOST]" or ""))

    -- Clan tag sits beside the emblem on the top line (matching the
    -- reference), not down with the name -- positioned right after where
    -- the icon is drawn in Paint above (cardX + CARD_W + ICON_GAP + ICON_SIZE).
    local tagLbl = vgui.Create("DLabel", row)
    tagLbl:SetPos(12 + CARD_W + ICON_GAP + ICON_SIZE + 24, 12)
    tagLbl:SetSize(230, CARD_H)
    tagLbl:SetFont("KC_Lobby_ClanTag")
    tagLbl:SetTextColor(Color(220, 220, 220))
    tagLbl:SetContentAlignment(4)
    tagLbl:SetText(entry.clantag)

    return row
end

local function RefreshRoster(scroll)
    if not IsValid(scroll) then return end
    scroll:Clear()
    for _, entry in ipairs(KC_Lobby_Roster) do
        CreateRosterRow(scroll, entry)
    end
end

local function OpenLobby()
    if IsValid(KC_Lobby_Frame) then KC_Lobby_Frame:Remove() end

    local w, h = ScrW(), ScrH()
    local lp = LocalPlayer()
    -- Listen-server host always gets host controls (regardless of whatever
    -- an admin mod thinks IsAdmin() should be for this particular map), plus
    -- anyone IsAdmin() flags, matching sv_roundstart.lua's IsHostOrAdmin().
    -- Third fallback: if you're the only real human connected (solo testing
    -- with bots, which is how this addon gets played in practice), there's
    -- no one else it could possibly be -- treat that as host too, so this
    -- never depends on IsListenServerHost()/IsAdmin() actually succeeding.
    local realPlayers = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then realPlayers = realPlayers + 1 end
    end
    local isHost = IsValid(lp) and (lp:IsListenServerHost() or lp:IsAdmin() or realPlayers <= 1)
    print(string.format("[KC Lobby] isHost=%s  IsListenServerHost=%s  IsAdmin=%s  realPlayers=%d",
        tostring(isHost),
        tostring(IsValid(lp) and lp:IsListenServerHost()),
        tostring(IsValid(lp) and lp:IsAdmin()),
        realPlayers))

    local frame = vgui.Create("DFrame")
    frame:SetSize(w, h)
    frame:SetPos(0, 0)
    frame:SetTitle("")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    frame.Paint = function(self, sw, sh)
        PaintAbstractBackground(sw, sh)
        draw.SimpleText(language.GetPhrase("CoDHUD.Lobby.PrivateMatch"), "DermaLarge", 60, 50, COL_TITLE, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        -- Killcam preview lives on the 2D HUDPaint layer, which always
        -- renders BELOW any open VGUI panel -- this full-screen lobby frame
        -- was blocking it out completely. Paint it here instead, after our
        -- own background but before the sidebar/roster/mapbox child panels
        -- (which paint on top of us automatically). Gated on
        -- Killcam.menuOpened -- only show it when kc_menu is actually open
        -- (e.g. via the "Edit Card" button, or typed manually), not just
        -- because the lobby itself is open.
        if Killcam.menuOpened and KC_DrawKillcamPreviewOverlay then KC_DrawKillcamPreviewOverlay() end
    end
    KC_Lobby_Frame = frame

    -- Confirmed via the print above: this can read false with
    -- realPlayers=0 -- meaning player.GetAll() didn't even see YOU yet,
    -- not that you're genuinely not the host. That happens when the lobby
    -- opens right at map load/connect, before this client's own
    -- entity/roster state has settled -- a timing race, not a real
    -- permissions answer. Since isHost is only computed once and baked
    -- into the buttons below, a bad early read used to stay wrong for the
    -- whole lobby session. Retry a few times shortly after and rebuild if
    -- a fresh read now disagrees and would actually grant host controls.
    if not isHost then
        for _, delay in ipairs({0.5, 1.5, 3}) do
            timer.Simple(delay, function()
                if not IsValid(KC_Lobby_Frame) or KC_Lobby_Frame ~= frame then return end
                if not KC_Lobby_ActiveCL then return end
                local lp2 = LocalPlayer()
                local realPlayers2 = 0
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) and not p:IsBot() then realPlayers2 = realPlayers2 + 1 end
                end
                local isHostNow = IsValid(lp2) and (lp2:IsListenServerHost() or lp2:IsAdmin() or realPlayers2 <= 1)
                if isHostNow then
                    print("[KC Lobby] isHost flipped false -> true on retry, rebuilding lobby")
                    OpenLobby()
                end
            end)
        end
    end

    -- ── Left sidebar menu ────────────────────────────────────────────────
    local sidebar = vgui.Create("DPanel", frame)
    sidebar:SetPos(60, 120)
    sidebar:SetSize(360, 380)
    sidebar.Paint = nil

    local gameSetupPanel -- forward decl, built below, toggled by the menu item

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.StartGame"), isHost, function()
        net.Start("CoDHUD_StartRound")
        net.SendToServer()
    end):Dock(TOP)

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.GameSetup"), isHost, function()
        if IsValid(gameSetupPanel) then
            gameSetupPanel:SetVisible(not gameSetupPanel:IsVisible())
        end
    end):Dock(TOP)

    CreateDivider(sidebar)

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.Classes"), true, function()
        RunConsoleCommand("kc_classmenu")
    end):Dock(TOP)

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.Callsign"), true, function()
        RunConsoleCommand("kc_menu")
    end):Dock(TOP)

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.Barracks"), false):Dock(TOP)

    CreateDivider(sidebar)

    -- gui.OpenURL genuinely activates the real Steam overlay (the wiki is
    -- explicit that it's the actual overlay browser, not an in-game fake) --
    -- it's the only Lua-reachable call in GMod that pops the real overlay at
    -- all. Steam itself forces one confirmation click before it opens
    -- (a platform-level safety gate with no Lua-side bypass), then the real
    -- overlay opens on this friends page -- the native Friends dock icon at
    -- the bottom of that overlay is one click from there.
    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.Invite"), true, function()
        local connectStr = "connect " .. game.GetIPAddress()
        SetClipboardText(connectStr)
        gui.OpenURL("https://steamcommunity.com/my/friends/")
    end):Dock(TOP)

    CreateDivider(sidebar)

    CreateMenuItem(sidebar, language.GetPhrase("CoDHUD.Lobby.Disconnect"), true, function()
        Derma_Query(language.GetPhrase("CoDHUD.Lobby.DisconnectConfirm"), language.GetPhrase("CoDHUD.Lobby.DisconnectTitle"),
            language.GetPhrase("CoDHUD.Lobby.Yes"), function() RunConsoleCommand("disconnect") end,
            language.GetPhrase("CoDHUD.Lobby.No"))
    end):Dock(TOP)

    -- ── Inline Game Setup panel (host only, toggled via the menu item) ───
    if isHost then
        gameSetupPanel = vgui.Create("DPanel", frame)
        gameSetupPanel:SetPos(460, 130)
        gameSetupPanel:SetSize(360, 336)
        gameSetupPanel:SetVisible(false)
        gameSetupPanel.Paint = function(self, pw, ph)
            draw.RoundedBox(2, 0, 0, pw, ph, COL_PANEL)
        end

        local function SectionLabel(y, text)
            local lbl = vgui.Create("DLabel", gameSetupPanel)
            lbl:SetPos(15, y)
            lbl:SetSize(330, 20)
            lbl:SetFont("DermaDefaultBold")
            lbl:SetText(text)
            lbl:SetTextColor(Color(200, 200, 200))
            return lbl
        end

        SectionLabel(12, language.GetPhrase("CoDHUD.Lobby.Gamemode"))

        local combo = vgui.Create("DComboBox", gameSetupPanel)
        combo:SetPos(15, 40)
        combo:SetSize(330, 26)

        local choices = GetGamemodeChoices()
        local current = GetConVar("codhud_selected_gamemode"):GetString()
        for _, choice in ipairs(choices) do
            combo:AddChoice(language.GetPhrase(choice[1]), choice[2])
            if choice[2] == current then
                combo:SetValue(language.GetPhrase(choice[1]))
            end
        end

        combo.OnSelect = function(_, _, text, value)
            net.Start("CoDHUD_SetGamemode")
                net.WriteString(value)
            net.SendToServer()
        end

        -- HUD select (which CoD game's look/factions to use)
        SectionLabel(76, language.GetPhrase("CoDHUD.Lobby.HUD"))

        local hudCombo = vgui.Create("DComboBox", gameSetupPanel)
        hudCombo:SetPos(15, 104)
        hudCombo:SetSize(330, 26)

        -- NOTE: CoDHUD.GetHUDList() (cl_settings.lua) returns an empty table
        -- immediately and populates that SAME table reference 0.25s later via
        -- timer.Simple -- that only works for a table captured once at file-
        -- load time (as cl_settings.lua itself does). Calling it fresh here
        -- always reads it back before the 0.25s delay fires, so it comes back
        -- empty every time. Read CoDHUD.TypeRegistry directly instead -- by
        -- the time a player can actually open this lobby, every game file in
        -- codhud/games/ has already registered itself via CoDHUD.RegisterHUD.
        local hudChoices = {}
        for _, hud in pairs(CoDHUD.TypeRegistry or {}) do
            table.insert(hudChoices, { hud.name, hud.codename })
        end
        table.sort(hudChoices, function(a, b) return a[1] < b[1] end)

        local currentHUD = GetConVar("codhud_game"):GetString()
        for _, choice in ipairs(hudChoices) do
            -- hud.name is a "#CoDHUD.Type.xxx" phrase key -- DComboBox
            -- doesn't auto-translate "#"-prefixed choice text the way
            -- DLabel/DButton do, so without this it showed the raw
            -- "#CoDHUD.Type.mw2" key instead of "Modern Warfare 2". The
            -- gamemode combo just above already does this correctly.
            local hudName = language.GetPhrase(choice[1])
            hudCombo:AddChoice(hudName, choice[2])
            if choice[2] == currentHUD then
                hudCombo:SetValue(hudName)
            end
        end

        hudCombo.OnSelect = function(_, _, text, value)
            net.Start("CoDHUD_SetGame")
                net.WriteString(value)
            net.SendToServer()
        end

        -- Pregame (match start) timer
        local timerLbl = SectionLabel(140, language.GetPhrase("CoDHUD.Lobby.PregameTimer"))

        local timerSlider = vgui.Create("DNumSlider", gameSetupPanel)
        timerSlider:SetPos(10, 158)
        timerSlider:SetSize(340, 32)
        timerSlider:SetText("")
        timerSlider:SetMin(0)
        timerSlider:SetMax(15)
        timerSlider:SetDecimals(0)
        local timerCV = GetConVar("codhud_matchstart_timer")
        if timerCV then timerSlider:SetValue(timerCV:GetFloat()) end

        local lastSentTimer = nil
        timerSlider.OnValueChanged = function(_, val)
            val = math.Round(val)
            timer.Create("KC_Lobby_TimerCommit", 0.05, 1, function()
                if lastSentTimer == val then return end
                lastSentTimer = val
                CoDHUD_SetServerConVar("codhud_matchstart_timer", tostring(val))
            end)
        end

        -- Fast Last (testing convenience toggle)
        local fastLast = vgui.Create("DCheckBoxLabel", gameSetupPanel)
        fastLast:SetPos(15, 198)
        fastLast:SetText(language.GetPhrase("CoDHUD.Lobby.FastLast"))
        fastLast:SizeToContents()
        local fastLastCV = GetConVar("kc_fastlast_enabled")
        if fastLastCV then fastLast:SetValue(fastLastCV:GetBool() and 1 or 0) end
        fastLast.OnChange = function(_, val)
            CoDHUD_SetServerConVar("kc_fastlast_enabled", val and "1" or "0")
        end

        -- Time Limit toggle -- codhud_time_limit is a minutes value where 0
        -- means "no time limit"; this just flips it between 0 (off) and
        -- whatever it was last set to (on), so it reads as a simple on/off
        -- switch instead of making the host manage a raw number.
        local timeLimitCV = GetConVar("codhud_time_limit")
        local lastNonZeroTimeLimit = (timeLimitCV and timeLimitCV:GetFloat() > 0) and timeLimitCV:GetFloat() or 10

        local timeLimitToggle = vgui.Create("DCheckBoxLabel", gameSetupPanel)
        timeLimitToggle:SetPos(15, 226)
        timeLimitToggle:SetText(language.GetPhrase("CoDHUD.Lobby.ShowTimeLimit"))
        timeLimitToggle:SizeToContents()
        timeLimitToggle:SetValue((timeLimitCV and timeLimitCV:GetFloat() > 0) and 1 or 0)
        timeLimitToggle.OnChange = function(_, val)
            if val then
                CoDHUD_SetServerConVar("codhud_time_limit", tostring(lastNonZeroTimeLimit))
            else
                if timeLimitCV and timeLimitCV:GetFloat() > 0 then
                    lastNonZeroTimeLimit = timeLimitCV:GetFloat()
                end
                CoDHUD_SetServerConVar("codhud_time_limit", "0")
            end
        end

        -- God Mode (host's team only, never bots) -- only does anything in Sesh S&D Set,
        -- so the disclaimer sits right under the checkbox.
        local function PhraseOr(key, fallback)
            local p = language.GetPhrase(key)
            return (p == key) and fallback or p
        end

        local godMode = vgui.Create("DCheckBoxLabel", gameSetupPanel)
        godMode:SetPos(15, 254)
        godMode:SetText(PhraseOr("CoDHUD.Lobby.GodMode", "God Mode (host's team only, no bots)"))
        godMode:SizeToContents()
        local godModeCV = GetConVar("kc_godmode_enabled")
        if godModeCV then godMode:SetValue(godModeCV:GetBool() and 1 or 0) end
        godMode.OnChange = function(_, val)
            CoDHUD_SetServerConVar("kc_godmode_enabled", val and "1" or "0")
        end

        local godNote = vgui.Create("DLabel", gameSetupPanel)
        godNote:SetPos(36, 276)
        godNote:SetSize(310, 44)
        godNote:SetFont("DermaDefault")
        godNote:SetTextColor(Color(230, 170, 80))
        godNote:SetWrap(true)
        godNote:SetText(PhraseOr("CoDHUD.Lobby.GodModeNote", "Only works in Sesh S&D Set. It does nothing in any other gamemode."))
    end

    -- ── Top-right: player roster ─────────────────────────────────────────
    local rosterW = 920
    local rosterPanel = vgui.Create("DPanel", frame)
    rosterPanel:SetPos(w - rosterW - 40, 40)
    rosterPanel:SetSize(rosterW, 640)
    rosterPanel.Paint = nil -- transparent -- only the per-player row boxes below keep a background

    local recLbl = vgui.Create("DLabel", rosterPanel)
    recLbl:Dock(TOP)
    recLbl:SetTall(40)
    recLbl:DockMargin(14, 8, 14, 0)
    recLbl:SetFont("KC_Lobby_CardText")
    recLbl:SetTextColor(Color(190, 190, 190))
    recLbl:SetText(string.format(language.GetPhrase("CoDHUD.Lobby.RecommendedMaxPlayers"), tostring(game.MaxPlayers())))

    local scroll = vgui.Create("DScrollPanel", rosterPanel)
    scroll:Dock(FILL)
    scroll:DockMargin(8, 4, 8, 8)
    RefreshRoster(scroll)
    frame.RosterScroll = scroll

    -- ── Bottom-left: map / gamemode readout ──────────────────────────────
    -- GMod's own main-menu map list uses this exact material convention for
    -- every stock and properly-packaged addon map ("vgui/maps/menu_thumb_
    -- <mapname>"), which is far more reliably present than an engine-
    -- generated level screenshot. Falls back to a plain dark box if a
    -- particular map genuinely has no thumbnail asset.
    local mapThumb = Material("vgui/maps/menu_thumb_" .. game.GetMap())
    if mapThumb:IsError() then mapThumb = nil end

    local mapBox = vgui.Create("DPanel", frame)
    mapBox:SetPos(60, h - 190)
    mapBox:SetSize(220, 130)
    mapBox.Paint = function(self, pw, ph)
        if mapThumb then
            surface.SetMaterial(mapThumb)
            surface.SetDrawColor(255, 255, 255, 255)
            surface.DrawTexturedRect(0, 0, pw, ph)
        else
            draw.RoundedBox(0, 0, 0, pw, ph, Color(8, 8, 8, 255))
        end

        -- Dark strip behind the text so it stays readable over any thumbnail
        surface.SetDrawColor(0, 0, 0, 180)
        surface.DrawRect(0, ph - 40, pw, 40)
        draw.SimpleText(string.upper(game.GetMap()), "DermaDefaultBold", 10, ph - 34, Color(255, 255, 255))
        local gmCV = GetConVar("codhud_selected_gamemode")
        local gmName = gmCV and gmCV:GetString() or ""
        draw.SimpleText(gmName, "DermaDefault", 10, ph - 16, Color(190, 190, 190))
    end
end

local function CloseLobby()
    if IsValid(KC_Lobby_Frame) then
        KC_Lobby_Frame:Remove()
    end
    KC_Lobby_Frame = nil
end

net.Receive("KC_Lobby_State", function()
    KC_Lobby_ActiveCL = net.ReadBool()
    if KC_Lobby_ActiveCL then
        -- The lobby's fullscreen popup steals keyboard focus the instant it
        -- opens. If the player happened to be holding the scoreboard bind
        -- (Tab) right when the match ended, the engine's key-up never
        -- reaches the game (VGUI has focus instead), so ScoreboardHide never
        -- fires and CoDHUD_ScoreboardOpened gets stuck true -- the tab
        -- scoreboard then keeps rendering on top of the lobby indefinitely.
        -- Force it closed here regardless of how it got stuck.
        CoDHUD_ScoreboardOpened = false
        OpenLobby()
    else
        CloseLobby()
    end
end)

net.Receive("KC_Lobby_Roster", function()
    KC_Lobby_Roster = net.ReadTable()
    if IsValid(KC_Lobby_Frame) then
        RefreshRoster(KC_Lobby_Frame.RosterScroll)
    end
end)
