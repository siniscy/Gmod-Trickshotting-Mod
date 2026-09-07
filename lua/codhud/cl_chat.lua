---- [ CLIENT CHAT ] ----

local chatHistory = {}
local MAX_MESSAGES = 4 
local MESSAGE_LIFETIME = 10 
local FADE_TIME = 1

-- Ratio for vertical positioning (45% down the screen)
local CHAT_INPUT_Y_RATIO = 0.45

local COL_WHITE = Color(255, 255, 255)
local COL_TEAM  = Color(85, 195, 190)
local MAT_GRAD  = Material("vgui/gradient-l")

-- Faction Color Definitions
local COL_FACTION_WEST = Color(100, 110, 120) -- rangers, taskforce141, seals
local COL_FACTION_EAST = Color(120, 110, 100) -- ussr, arab, militia

local isTyping = false
local chatType = "say"

-- [[ LOGIC: CLOSE CHAT ]]
local function CloseCoDHUDChat()
    if IsValid(CoDHUD_ChatEntry) then CoDHUD_ChatEntry:Remove() end
    isTyping = false
    gui.EnableScreenClicker(false)
    if not vgui.CursorVisible() then gui.HideGameUI() end
end

-- [[ LOGIC: OPEN CHAT ]]
local function OpenCoDHUDChat(isTeam)
    if isTyping then return end
    isTyping = true
    chatType = isTeam and "say_team" or "say"
    
    CoDHUD_ChatEntry = vgui.Create("DTextEntry")
    CoDHUD_ChatEntry:SetSize(1, 1) 
    CoDHUD_ChatEntry:SetPos(-10, -10)
    CoDHUD_ChatEntry:MakePopup()
    CoDHUD_ChatEntry:RequestFocus()
    
    -- Allow common command prefixes to be handled correctly
    CoDHUD_ChatEntry.OnKeyCodeTyped = function(self, code)
        if code == KEY_ESCAPE then
            CloseCoDHUDChat()
            return true 
        elseif code == KEY_ENTER then
            local txt = self:GetText()
            
            if txt and txt:Trim() ~= "" then
                -- This ensures that hooks like "OnPlayerChat" and "PlayerSay" 
                -- are triggered properly for commands like !help or /menu
                RunConsoleCommand(chatType, txt) 
            end
            
            CloseCoDHUDChat()
            return true
        end
    end

    -- Fix: Ensure clicking away or losing focus cleans up the UI properly
    CoDHUD_ChatEntry.OnFocusChanged = function(self, gained)
        if not gained then 
            timer.Simple(0, function() 
                if not IsValid(self) then return end
                CloseCoDHUDChat() 
            end) 
        end
    end
end

hook.Add("PlayerBindPress", "CoDHUD_Chat_BindPress", function(ply, bind, pressed)
	if (not GetConVar("codhud_enable_chat"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if not pressed then return end
    if bind == "messagemode" then OpenCoDHUDChat(false) return true
    elseif bind == "messagemode2" then OpenCoDHUDChat(true) return true end
end)

local function GetFactionColor(ply)
    if not IsValid(ply) then return COL_WHITE end

    local fac = ply:GetNW2String("CoDHUD_Faction", "rangers")
    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType()

    local factions = CoDHUD and CoDHUD.Factions
    local hudData  = factions and hudType and factions[hudType]
    local facData  = hudData and hudData[fac]

    return (facData and facData.killfeedcol) or COL_WHITE
end

-- [[ RENDERING ]]
hook.Add("HUDPaint", "CoDHUD_DrawChat", function()
    if (not GetConVar("codhud_enable_chat"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if not GetConVar("cl_drawhud"):GetBool() then return end
    local curTime = CurTime()
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

    -- We calculate these inside the hook using S(x) so they update instantly if resolution changes
    local chatInputY = ScrH() * CHAT_INPUT_Y_RATIO
    local lineHeight = CoDHUD_S(22)
    local marginX    = CoDHUD_S(25)

    -- 1. INPUT AREA
    if isTyping and IsValid(CoDHUD_ChatEntry) then
        local prompt      = (chatType == "say_team" and "say_team:" or "say:")
        local currentText = CoDHUD_ChatEntry:GetText()
        draw.SimpleText(prompt .. " " .. currentText, "MW2_ChatFont", marginX, chatInputY, Color(255, 255, 255, 225), 0, 0)

        if math.floor(CurTime() * 3) % 2 == 0 then
            surface.SetFont("MW2_ChatFont")
            local tw = surface.GetTextSize(prompt .. " " .. currentText)
            draw.SimpleText("_", "MW2_ChatFont", marginX + tw + 2, chatInputY, Color(255, 255, 255, 225), 0, 0)
        end
    end

    -- 2. MESSAGE HISTORY
    local currentY = chatInputY - lineHeight

    for i = #chatHistory, 1, -1 do
        local data = chatHistory[i]
        local timeActive = curTime - data.time
        local alpha = 0

        if isTyping then
            alpha = 225
        elseif timeActive <= MESSAGE_LIFETIME then
            alpha = 225
        elseif timeActive <= MESSAGE_LIFETIME + FADE_TIME then
            alpha = math.Clamp(225 - (((timeActive - MESSAGE_LIFETIME) / FADE_TIME) * 225), 0, 225)
        end

        if alpha > 0 then
            surface.SetFont("MW2_ChatFont")

            -- Determine Name Color based on Server Faction (NW2String)
            local nameCol = COL_WHITE
			
            if IsValid(data.ply) then
				nameCol = GetFactionColor(ply)
            end

            -- Prefix format: (Faction)Player:
            local prefix  = data.isTeam and ("(" .. data.faction .. ")") or ""
            local nameStr = prefix .. data.sender .. ": "
            
            local nw = surface.GetTextSize(nameStr)
            local mw = surface.GetTextSize(data.msg)
            local totalW  = nw + mw

            -- Draw Individual Background Gradient using S(60) for scaled padding
            surface.SetMaterial(MAT_GRAD)
            surface.SetDrawColor(0, 0, 0, math.Clamp(alpha - 45, 0, 180))
            surface.DrawTexturedRect(0, currentY, marginX + totalW + CoDHUD_S(60), lineHeight)

            -- Draw Text
            local bodyCol = data.isTeam and COL_TEAM or COL_WHITE
            draw.SimpleText(nameStr, "MW2_ChatFont", marginX,      currentY, Color(nameCol.r, nameCol.g, nameCol.b, alpha), 0, 0)
            draw.SimpleText(data.msg, "MW2_ChatFont", marginX + nw, currentY, Color(bodyCol.r, bodyCol.g, bodyCol.b, alpha), 0, 0)
            
            currentY = currentY - lineHeight
        end
    end
end)

-- [[ NETWORKING ]]
net.Receive("CoDHUD_ChatMessage", function()
    local ply = net.ReadEntity()
    local text = net.ReadString()
    local isTeam = net.ReadBool()
    local factionName = net.ReadString()

    if not IsValid(ply) then return end

    table.insert(chatHistory, {
        ply = ply,
        sender = ply:Nick(),
        faction = factionName,
        msg = text,
        isTeam = isTeam,
        time = CurTime()
    })

    if #chatHistory > MAX_MESSAGES then table.remove(chatHistory, 1) end
end)

hook.Add("HUDShouldDraw", "CoDHUD_HideDefaultChat", function(name)
    if (not GetConVar("codhud_enable_chat"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if name == "CHudChat" then return false end
end)