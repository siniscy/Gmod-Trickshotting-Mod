---- [ CoD4 EQUIPMENT KNIFE ON THE RIGHT STICK CLICK ] ----
-- Kat's "Call of Duty 4: Equipment" pack only binds its knife through the
-- spawn-menu Numpad binder, which can't capture a controller button. This
-- reads the right stick click (R3) straight from the gamepad -- the same way
-- stick_sprint.lua reads L3 -- and runs the pack's own DoKnife, so the knife
-- (and switching weapons mid-swing) behaves exactly like the keyboard bind.
--   kc_cod4_knife_stick 1/0   turn it on or off

if SERVER then
    concommand.Add("kc_cod4_knife", function(ply)
        if not IsValid(ply) or not ply:Alive() then return end
        local wep = ply:GetActiveWeapon()
        if IsValid(wep) and wep.COD4 and wep.DoKnife then
            wep:DoKnife()
        end
    end)
    return
end

local cvEnable = CreateClientConVar("kc_cod4_knife_stick", "1", true, false,
    "Knife with the right stick click (CoD4 Equipment weapons).")

local wasDown = false

hook.Add("Think", "KC_COD4KnifeStick", function()
    -- Don't fire while typing in chat/console/a menu.
    local down = cvEnable:GetBool()
        and vgui.GetKeyboardFocus() == nil
        and input.IsButtonDown(KEY_XBUTTON_STICK2)

    if down and not wasDown then
        RunConsoleCommand("kc_cod4_knife")
    end
    wasDown = down
end)
