---- [ CLIENT SCOREBOARD ] ----

CoDHUD_ScoreboardOpened = false

CoDHUD = CoDHUD or {}
CoDHUD.Scoreboard = CoDHUD.Scoreboard or {}

CoDHUD.Scoreboard.Scroll = 0
CoDHUD.Scoreboard.ContentHeight = 0
CoDHUD.Scoreboard.VisibleHeight = CoDHUD_S(800)

hook.Add("OnScreenSizeChanged", "MW2_Scoreboard_Resize", function()
    CoDHUD.Scoreboard.VisibleHeight = CoDHUD_S(800)
end)

hook.Add("DrawOverlay", "MW2_Scoreboard_Main", function()
    if not CoDHUD_ScoreboardOpened then return end
    if GetConVar("codhud_quickdisable_hud"):GetBool() then return end

    local cv = GetConVar("codhud_selected_gamemode")
    local gm = cv and cv:GetString() or ""
    local isFFA = gm == "sesh_dm" or gm == "dm"
    local hasGamemode = gm ~= "" and gm ~= "none"

    -- For FFA use a dedicated scoreboard that avoids faction grouping issues
    if hasGamemode and isFFA and GetConVar("codhud_enable_scoreboard"):GetBool() then
        local lp = LocalPlayer()
        if not IsValid(lp) then return end
        local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
        local scrW, scrH = ScrW(), ScrH()
        local sbMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10
        local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "cod4"
        local factions = CoDHUD.Factions and CoDHUD.Factions[hudType]

        -- Get player faction for header icon
        local myFaction = lp:GetNW2String("CoDHUD_Faction", "")
        local fData = factions and factions[myFaction]

        -- Build sorted player list
        local entries = {}
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) then
                table.insert(entries, p)
            end
        end
        table.sort(entries, function(a, b)
            local sa = math.max(0, a:Frags() * sbMul)
            local sb2 = math.max(0, b:Frags() * sbMul)
            if sa == sb2 then
                if a == lp then return true end
                if b == lp then return false end
                return a:Nick() < b:Nick()
            end
            return sa > sb2
        end)

        local barW = CoDHUD_S(1086)
        local barH = CoDHUD_S(38)
        local barX = (scrW / 2) - (barW / 2)
        local barRight = barX + barW
        local startY = CoDHUD_S(290)

        -- Header bar
        local MAT_GRADIENT_L = Material(hudType .. "/hud/line_horizontal_scoreboard.png", "mips smooth")
        local myFactionCol = fData and fData.color or Color(110, 110, 110)
        surface.SetDrawColor(myFactionCol.r, myFactionCol.g, myFactionCol.b, 150)
        surface.SetMaterial(MAT_GRADIENT_L)
        surface.DrawTexturedRect(0, CoDHUD_S(90), scrW, CoDHUD_S(50))
        surface.SetDrawColor(255, 255, 255, 150)
        surface.DrawTexturedRect(0, CoDHUD_S(84), scrW, CoDHUD_S(5))
        surface.DrawTexturedRect(0, CoDHUD_S(142), scrW, CoDHUD_S(5))

        -- Map name
        local mapFont = hudType == "cod4" and "CoD4_Scoreboard_Text" or "MW2_Scoreboard_Text"
        draw.SimpleTextOutlined(string.upper(game.GetMap()), mapFont, scrW/2, CoDHUD_S(98), Color(255,255,255), 1, 0, outlined and 1.5 or 0, Color(0,0,0))

        -- Faction icon
        if fData and fData.spawnIcon then
            surface.SetMaterial(Material(fData.spawnIcon, "smooth"))
            surface.SetDrawColor(255,255,255,255)
            surface.DrawTexturedRect(barX, startY + CoDHUD_S(-86), CoDHUD_S(77), CoDHUD_S(77))
        end

        -- Section header
        local sectionName = fData and language.GetPhrase(fData.short) or myFaction
        draw.SimpleTextOutlined(sectionName .. " (" .. #entries .. ")", mapFont, barX + CoDHUD_S(96), startY + CoDHUD_S(-44), Color(255,255,255), 0, 0, outlined and 1 or 0, Color(0,0,0))

        -- Column headers
        draw.SimpleTextOutlined("Deaths", mapFont, barRight - CoDHUD_S(10), startY - CoDHUD_S(35), Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0))
        draw.SimpleTextOutlined("Kills", mapFont, barRight - CoDHUD_S(225), startY - CoDHUD_S(35), Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0))
        draw.SimpleTextOutlined("Score", mapFont, barRight - CoDHUD_S(335), startY - CoDHUD_S(35), Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0))

        -- Draw player rows (includes bots since they are player entities)
        local MAT_ICON_DEAD = Material(hudType .. "/icons/hud_status_dead.png", "mips smooth")
        for i, p in ipairs(entries) do
            local rowY = startY + (i-1) * (barH + CoDHUD_S(2))
            local isMe = p == lp
            -- Use player's own faction data for color, fall back to local player's faction
            local pFac = p:GetNW2String("CoDHUD_Faction", "")
            local pFData = (factions and factions[pFac]) or fData
            local bgCol = pFData and pFData.color or Color(80, 80, 80)
            local tCol = isMe and Color(255, 200, 50) or Color(255, 255, 255)
            -- Use SeshFFA_Kills for individual score in sesh_dm, otherwise Frags
            local kills = (gm == "sesh_dm") and p:GetNWInt("SeshFFA_Kills", 0) or p:Frags()
            local pScore = math.max(0, kills * sbMul)

            surface.SetDrawColor(bgCol.r, bgCol.g, bgCol.b, 200)
            surface.DrawRect(barX, rowY, barW, barH)

            if not p:Alive() then
                surface.SetMaterial(MAT_ICON_DEAD)
                surface.SetDrawColor(255,255,255,255)
                local iconSz = barH * 0.8
                surface.DrawTexturedRect(barX + CoDHUD_S(75), rowY + (barH/2) - (iconSz/2), iconSz, iconSz)
            end

            draw.SimpleTextOutlined(p:Nick(), mapFont, barX + CoDHUD_S(110), rowY + barH/2, tCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0,0,0))
            draw.SimpleTextOutlined(tostring(p:Deaths()), mapFont, barRight - CoDHUD_S(10), rowY + barH/2, tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0,0,0))
            draw.SimpleTextOutlined(tostring(kills), mapFont, barRight - CoDHUD_S(225), rowY + barH/2, tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0,0,0))
            draw.SimpleTextOutlined(tostring(pScore), mapFont, barRight - CoDHUD_S(335), rowY + barH/2, tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0,0,0))

            -- Ping bars
            local ping = p:Ping()
            local barCount = ping >= 150 and 1 or ping >= 100 and 2 or ping >= 50 and 3 or 4
            local col2 = barCount == 1 and Color(255,60,60) or barCount == 2 and Color(255,140,0) or barCount == 3 and Color(180,255,80) or Color(0,255,0)
            local boxSize = CoDHUD_S(38)
            local pingX = barRight + CoDHUD_S(5)
            local pingY = rowY + barH/2 - boxSize/2
            surface.SetDrawColor(0,0,0,155)
            surface.DrawRect(pingX, pingY, boxSize, boxSize)
            local rodW = CoDHUD_S(6)
            local rodSpacing = CoDHUD_S(3)
            local startX2 = pingX + boxSize/2 - ((rodW*4 + rodSpacing*3)/2)
            for j = 1, 4 do
                local bh = (boxSize - CoDHUD_S(6)) * (j/4)
                if j <= barCount then
                    surface.SetDrawColor(col2.r, col2.g, col2.b, 255)
                    surface.DrawRect(startX2 + (j-1)*(rodW+rodSpacing), pingY + boxSize - bh - CoDHUD_S(3), rodW, bh)
                end
            end
        end

        local hudHooks2 = hook.GetTable()["HUDPaint"]
        if hudHooks2 and hudHooks2["MW2_DrawChat"] then hudHooks2["MW2_DrawChat"]() end
        return
    end

    if hasGamemode and GetConVar("codhud_enable_scoreboard"):GetBool() and CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].Scoreboard then
        local ok, err = pcall(CoDHUD[CoDHUD_GetHUDType()].Scoreboard)
        if not ok then
            _G.CoDHUD_LastScoreboardError = tostring(err)
        else
            _G.CoDHUD_LastScoreboardError = nil
        end
        return  -- always return — never show fake fallback scoreboard
    end

    local hudHooks = hook.GetTable()["HUDPaint"]
    if hudHooks and hudHooks["MW2_DrawChat"] then
        hudHooks["MW2_DrawChat"]()
    end
end)

hook.Add("ScoreboardShow", "MW2_Scoreboard_Open", function()
    if GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    CoDHUD_ScoreboardOpened = true

    local cv = GetConVar("codhud_selected_gamemode")
    print("[Scoreboard DEBUG] Opened. codhud_selected_gamemode convar " .. (cv and ("exists, value=\"" .. cv:GetString() .. "\"") or "DOES NOT EXIST client-side (bug not fixed)") .. " | codhud_enable_scoreboard=" .. tostring(GetConVar("codhud_enable_scoreboard"):GetBool()))

    return true
end)

hook.Add("ScoreboardHide", "MW2_Scoreboard_Close", function()
    if GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    CoDHUD_ScoreboardOpened = false
end)

hook.Add("PlayerBindPress", "MW2_Scoreboard_Scroll", function(ply, bind, pressed)
    if not CoDHUD_ScoreboardOpened then return end
    if not pressed then return end

    local sb = CoDHUD.Scoreboard
    local maxScroll = math.max(0, sb.ContentHeight - sb.VisibleHeight)

    if bind == "invnext" then
        sb.Scroll = sb.Scroll + 60
    elseif bind == "invprev" then
        sb.Scroll = sb.Scroll - 60
    else
        return
    end

    sb.Scroll = math.Clamp(sb.Scroll, 0, maxScroll)
    return true
end)

hook.Add("HUDShouldDraw", "MW2_Scoreboard_HideHUD", function(name)
    if GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if CoDHUD_ScoreboardOpened then
        if name == "CHudCrosshair" then return true end
        return false
    end
end)