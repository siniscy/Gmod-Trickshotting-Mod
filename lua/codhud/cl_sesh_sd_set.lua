---- [ GMOD SESH S&D SET — HOST BOT-PLACEMENT KEY (L) ] ----

-- GMod's RunConsoleCommand refuses to run "bind" (it's on the engine's
-- blocked-command list -- confirmed via console: "RunConsoleCommand:
-- Command is blocked! (bind)"), so binding L for the host isn't possible
-- that way. Instead, poll the raw key state every frame while this is the
-- active gamemode and fire the server command directly on the down-edge --
-- same end result ("press L to move the bot") without ever touching the
-- player's actual keybindings.
local wasDown = false

hook.Add("Think", "KC_SDSet_KeyPoll", function()
    local gmCV = GetConVar("codhud_selected_gamemode")
    if not gmCV or gmCV:GetString() ~= "sesh_sd_set" then
        wasDown = false
        return
    end

    -- Don't steal L while the player is typing in chat/console/a menu.
    if vgui.GetKeyboardFocus() ~= nil then
        wasDown = false
        return
    end

    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local realPlayers = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then realPlayers = realPlayers + 1 end
    end
    local isHost = lp:IsListenServerHost() or lp:IsAdmin() or realPlayers <= 1
    if not isHost then
        wasDown = false
        return
    end

    local down = input.IsKeyDown(KEY_L)
    if down and not wasDown then
        RunConsoleCommand("sesh_move_bot_to_crosshair")
    end
    wasDown = down
end)
