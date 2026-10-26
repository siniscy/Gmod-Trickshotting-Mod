---- [ KC EQUIPMENT: COMBAT KNIFE ] ----
-- Placeholder "equipment" item for the loadout system -- a single throwing
-- knife per life, entirely custom (not from any of the installed weapon
-- packs), so the class menu / equip-isolation system has something real to
-- test end-to-end. Swap or add to this later via KC_Loadouts.BuiltinEquipment
-- (sh_loadouts_data.lua) or by flagging any other SWEP with KC_IsEquipment.

SWEP.Base       = "weapon_base"
SWEP.PrintName  = "Combat Knife"
SWEP.Author     = "KC Project"
SWEP.Category   = "KC Loadouts"

SWEP.Spawnable      = false
SWEP.AdminSpawnable = false

-- The flag the whole loadout system keys off of: cl_loadouts_switch.lua
-- excludes any weapon carrying this from invnext/invprev cycling and is the
-- only thing kc_equip's quick-switch will select.
SWEP.KC_IsEquipment = true

SWEP.ViewModel  = "models/weapons/v_knife_t.mdl"
SWEP.WorldModel = "models/weapons/w_knife_t.mdl"
SWEP.UseHands   = true
SWEP.HoldType   = "knife"

SWEP.Slot    = 4
SWEP.SlotPos = 0

SWEP.DrawAmmo       = false
SWEP.DrawCrosshair  = true

SWEP.Primary.ClipSize      = -1
SWEP.Primary.DefaultClip   = -1
SWEP.Primary.Automatic     = false
SWEP.Primary.Ammo          = "none"

SWEP.Secondary.ClipSize    = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic   = false
SWEP.Secondary.Ammo        = "none"

function SWEP:Deploy()
    -- One throw per life -- a fresh weapon instance (KC_Thrown starts nil)
    -- is Given again at the next spawn, so this naturally resets each round
    -- without any extra bookkeeping.
    self.KC_Thrown = false
    return true
end

function SWEP:PrimaryAttack()
    if self.KC_Thrown then return end

    local owner = self:GetOwner()
    if not IsValid(owner) then return end

    self:SetNextPrimaryFire(CurTime() + 1)
    self.KC_Thrown = true

    if SERVER then
        local knife = ents.Create("kc_thrown_knife")
        if IsValid(knife) then
            knife:SetPos(owner:GetShootPos() + owner:GetAimVector() * 18)
            knife:SetAngles(owner:EyeAngles())
            knife.Thrower = owner
            knife:Spawn()

            local phys = knife:GetPhysicsObject()
            if IsValid(phys) then
                phys:SetVelocity(owner:GetAimVector() * 3000)
            end
        end

        -- Empty holster after the throw completes -- the equipment slot
        -- simply has nothing in it again until the next spawn re-Gives it.
        timer.Simple(0.3, function()
            if IsValid(owner) then
                owner:StripWeapon(self:GetClass())
            end
        end)
    end

    self:SendWeaponAnim(ACT_VM_THROW)
    owner:ViewPunch(Angle(-3, 0, 0))
end

function SWEP:SecondaryAttack() end
function SWEP:Reload() end
