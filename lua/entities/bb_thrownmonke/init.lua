AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )
include('shared.lua')

function ENT:Initialize()

	self.Owner = self.Entity.Owner
	self.Entity:SetModel("models/weapons/rehaa/bo4/w_monkeybomb.mdl") 
	
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	self.Entity:DrawShadow( false )
	self.Entity:SetCollisionGroup( COLLISION_GROUP_WEAPON )
	
	local phys = self.Entity:GetPhysicsObject()
	if (phys:IsValid()) then
	phys:Wake()
	phys:SetMass(6.5)
	end

	self.timeleft = CurTime() + 4 -- HOW LONG BEFORE EXPLOSION
	self:Think()
end

 function ENT:Think()
	
	if self.timeleft < CurTime() then
		self:Explosion()	
	end

	self.Entity:NextThink( CurTime() )
	return true
end

function ENT:Explosion()

	pos = self.Entity:GetPos()
	
	local gas = EffectData()
		gas:SetOrigin(pos)
		gas:SetEntity(self.Owner) //i dunno, just use it!
	util.Effect("m9k_no_smoke", gas)
	
	self.Entity:EmitSound("BaseSmokeEffect.Sound")

	self.Entity:Remove()
end

/*---------------------------------------------------------
OnTakeDamage
---------------------------------------------------------*/
function ENT:OnTakeDamage( dmginfo )
end


/*---------------------------------------------------------
Use
---------------------------------------------------------*/
function ENT:Use( activator, caller, type, value )
end


/*---------------------------------------------------------
StartTouch
---------------------------------------------------------*/
function ENT:StartTouch( entity )
end


/*---------------------------------------------------------
EndTouch
---------------------------------------------------------*/
function ENT:EndTouch( entity )
end


/*---------------------------------------------------------
Touch
---------------------------------------------------------*/
function ENT:Touch( entity )
end