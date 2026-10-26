AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

function ENT:Initialize()
	self:SetModel("models/cod4/weapons/Claymore/cod4_claymore_planted.mdl") 
	self:PhysicsInit(SOLID_VPHYSICS)
	self:SetMoveType(MOVETYPE_NONE)
	self:SetSolid(SOLID_VPHYSICS)
	self:SetCollisionGroup(COLLISION_GROUP_NONE)
	local phys = self:GetPhysicsObject()

	if phys and phys:IsValid() then
		phys:Wake()
	end
	self:SetAngles(self:GetAngles() + Angle(0,90,0))

	timer.Simple(1, function()
		if IsValid(self) then 
			self.dt.Armed = true
		end
	end)

	self.det = false
end

function ENT:Use(activator, caller)
	return false
end

function ENT:OnRemove()
	
end 


function ENT:Think()
	if self.dt.Armed and !self.dt.Activated then
		local TrData = {}
		local Ent = self
		local mins = Ent:OBBMins()
		local maxs = Ent:OBBMaxs()
		local startpos = Ent:GetPos() + Vector(0,0,5)
		local dir = Ent:GetForward( )
		local len = 150

		local TrData = util.TraceHull( {
			start = startpos,
			endpos = startpos + dir * len,
			maxs = maxs,
			mins = mins,
			filter = function( ent ) if ent:GetClass() == "prop_physics" then return true end  if ent == self:GetOwner() then return false end if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return true end if ent == Ent then return false end  end
		} )

		
		
		if ( TrData.Fraction<1 and !TrData.Entity:IsWorld() and TrData.Entity:GetClass() != "prop_physics" ) then
			 self:EmitSound("COD4_Claymore.Click")
			 timer.Simple(0.5,function()
			 	if IsValid(self) then
			 		self:Explode()
			 	end
			end)
			self.dt.Armed = false
			self.dt.Activated = true	
		end
	end
end

function ENT:Explode(  )
	if !self.det then
		self:SetNetworkedBool( "Det", true )
		local Ents = ents.FindInCone( self:GetPos(), self:GetForward( ), 320, 10 )

		for k, v in pairs(Ents) do 
			CalcBlastDamage(v, self, self.Owner)
		end
		self:EmitSound("global/exp"..math.random(1,3)..".wav", 90, math.random(95, 105))
		util.ScreenShake( self:GetPos(), 10, 1, 1, 400 )
		
		ef = EffectData()
		ef:SetOrigin(self:GetPos())
		ef:SetMagnitude(0)
		util.Effect("Explosion", ef)

		local effectdata = EffectData()
    	effectdata:SetOrigin(self:GetPos())
    	effectdata:SetMagnitude(3)
   		util.Effect("cod4_ambient_smoke", effectdata)

		SafeRemoveEntityDelayed(self, 0.2)
		self.det = true
		self:SetNetworkedBool( "Det", true )
	end
end

function ENT:OnTakeDamage(dmginfo)
	if  !self.dt.Activated and !self.Det then
		local temp = dmginfo:GetAttacker( )
		timer.Simple(0.05,function() self:OnDMGEXP(temp) end)
		self.Det = true
	end
end


function ENT:OnDMGEXP(ent)
	
	self:SetNetworkedBool( "Det", true )
	local Ents = ents.FindInCone( self:GetPos(), self:GetForward( ), 320, 10 )

	for k, v in pairs(Ents) do 
		CalcBlastDamage(v, self, ent)
	end
	self:EmitSound("global/exp"..math.random(1,3)..".wav", 90, math.random(95, 105))
	util.ScreenShake( self:GetPos(), 10, 1, 1, 400 )
		
	ef = EffectData()
	ef:SetOrigin(self:GetPos())
	ef:SetMagnitude(0)
	util.Effect("Explosion", ef)

	SafeRemoveEntityDelayed(self, 0.2)
	self.det = true

end

function CalcBlastDamage(ent, center, attacker)
	local damage = 200
	local force = 500
	
	local GroundDetect={}
	GroundDetect.start= center:GetPos() + Vector(0,0,10)
	GroundDetect.endpos=ent:GetPos() 
	GroundDetect.filter= function(ENTS) if ENTS:GetClass() == "prop_physics" then return true end if ENTS == ent or ENTS  == center or ENTS:IsNPC() or ENTS:IsPlayer() then return false end  end 
	local res=util.TraceLine(GroundDetect)
	
	if ( !res.Hit and !res.Entity:IsWorld() and ent:GetClass() != "prop_physics" ) then
		
		if ent:GetPos():Distance(center:GetPos()) < 100 then
			damage = 200
			force = 500
		elseif ent:GetPos():Distance(center:GetPos()) < 200 then
			damage = 100
			force = 300
		elseif ent:GetPos():Distance(center:GetPos()) < 250 then
		 	damage = 50
		 	force = 200
		else 
			damage = 20
			force = 50
		end


		local dmg = DamageInfo()
		dmg:SetDamageType(DMG_BLAST)
		dmg:SetDamage(damage)
		dmg:SetAttacker(attacker)
		dmg:SetInflictor(center)
		dmg:SetDamageForce(ent:GetForward() - Vector(force,force,force))
		ent:TakeDamageInfo(dmg)
	end

end

function ENT:PickUp()
	self:GetOwner():SetAmmo(self:GetOwner():GetAmmoCount("cod4_m18_claymore") + 1,"cod4_m18_claymore")
	self:Remove()
end