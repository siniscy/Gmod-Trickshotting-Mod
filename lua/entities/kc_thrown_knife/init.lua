AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")
include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/weapons/w_knife_t.mdl")
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetCollisionGroup(COLLISION_GROUP_PROJECTILE)

    local phys = self:GetPhysicsObject()
    if IsValid(phys) then
        phys:Wake()
        phys:SetMass(2)
    end

    self.KC_HasHit  = false
    self.KC_Damage  = 75
    self.KC_SpawnAt = CurTime()

    self:NextThink(CurTime())
end

function ENT:Think()
    -- Self-destruct after a while so missed throws don't litter the map.
    if CurTime() - self.KC_SpawnAt > 10 then
        self:Remove()
        return
    end
    self:NextThink(CurTime() + 1)
    return true
end

function ENT:PhysicsCollide(data, phys)
    if self.KC_HasHit then return end

    local hitEnt = data.HitEntity
    if not IsValid(hitEnt) then return end
    if not (hitEnt:IsPlayer() or hitEnt:IsNPC()) then return end
    if IsValid(self.Thrower) and hitEnt == self.Thrower then return end

    self.KC_HasHit = true

    local dmg = DamageInfo()
    dmg:SetDamage(self.KC_Damage)
    dmg:SetAttacker(IsValid(self.Thrower) and self.Thrower or self)
    dmg:SetInflictor(self)
    dmg:SetDamageType(DMG_SLASH)
    dmg:SetDamagePosition(self:GetPos())

    hitEnt:TakeDamageInfo(dmg)
    self:Remove()
end
