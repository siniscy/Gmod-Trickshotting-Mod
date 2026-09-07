-- cl_ffa_npc_names.lua
-- Overrides GMinimap bot colors for sesh modes

if not CLIENT then return end

local function IsSeshFFA()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv and cv:GetString() == "sesh_dm"
end

-- Override GMinimap player color hook
hook.Add("GMinimap_GetPlayerColor", "SeshBot_MinimapColor", function(ply)
    if not IsSeshFFA() then return end
    if not ply:IsBot() then return end
    -- Return red for enemy bots
    return Color(255, 50, 50)
end)
