---- [ EQUIPMENT FLAG FOR WEAPONS OTHER ADDONS ALSO SHIP ] ----
-- Some of our equipment lives at the same lua/weapons/<class>/ path as a
-- copy in another addon (Bouncing Betty in dread's mega pack, the MW3 smoke
-- in rehas-sweps-v1). GMod loads only one of the two files, and it's often
-- theirs -- which has no SWEP.KC_IsEquipment and sits on the stock base, so
-- the item showed up as a normal weapon (in the switch cycle, with a gun
-- HUD) instead of as equipment. Autorun runs before weapons register, so
-- this patches the table whichever copy got loaded.

local Overrides = {
    dread_tfa_waw_bbetty = { Base = "kc_bobs_gun_base" },
    reha_smokegrenadeiw5 = { Base = "kc_rehas_nade_base" },
}

hook.Add("PreRegisterSWEP", "KC_EquipmentOverrides", function(swep, class)
    local o = Overrides[class]
    if not o then return end
    -- Respect the <class>_allowed blacklist convar both copies check.
    if swep.Base == "bobs_blacklisted" then return end

    swep.KC_IsEquipment = true
    swep.Base = o.Base
end)
