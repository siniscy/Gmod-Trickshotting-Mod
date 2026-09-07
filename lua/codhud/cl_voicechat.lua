---- [ CLIENT VOICECHAT ] ----

local activeSpeakers = {}

hook.Add("PlayerStartVoice", "CoDHUD_VoiceStart", function(ply)
    activeSpeakers[ply] = true
end)

hook.Add("PlayerEndVoice", "CoDHUD_VoiceEnd", function(ply)
    activeSpeakers[ply] = nil
end)

hook.Add("HUDPaint", "CoDHUD_DrawVoiceChat", function()
	if (not GetConVar("codhud_enable_chat"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    local yOffset = 0

    for ply, _ in pairs(activeSpeakers) do
        if not IsValid(ply) then 
            activeSpeakers[ply] = nil 
            continue 
        end

		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].VoiceChat then
			CoDHUD[CoDHUD_GetHUDType()].VoiceChat(yOffset, ply)
		end
    end
end)

timer.Create("CoDHUD_VoiceKiller", 1, 0, function()
    if IsValid(g_VoicePanelList) then
        g_VoicePanelList:SetVisible(false)
        g_VoicePanelList:SetAlpha(0)
    end
end)

hook.Add("HUDShouldDraw", "CoDHUD_HideVoiceHUD", function(name)
	if (not GetConVar("codhud_enable_chat"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if name == "CHudVoiceStatus" then return false end
end)