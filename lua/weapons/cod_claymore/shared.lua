AddCSLuaFile("shared.lua")
AddCSLuaFile("cl_init.lua")

SWEP.Category  		= "Kat's Cod 4 Sweps" 

if CLIENT then
	SWEP.Author			= "KatBug"
	SWEP.Instructions	= input.LookupBinding("+attack")..": Plant Claymore\nHold "..input.LookupBinding("+attack").." to hold Claymore up\nSecondary: Lower Claymore if raised"
	SWEP.Contact		= ""
	SWEP.Purpose		= ""
	
end
SWEP.PrintName = "Claymore"

-- The flag the whole loadout system keys off of: cl_loadouts_switch.lua
-- excludes any weapon carrying this from invnext/invprev cycling and is the
-- only thing kc_equip's quick-switch will select.
SWEP.KC_IsEquipment = true

SWEP.Slot			= 4
SWEP.SlotPos		= 4					
SWEP.ViewModelFOV	= 70
SWEP.ViewModelFlip	= false
SWEP.ViewModel		= "models/cod4/weapons/Claymore/v_cod4_claymore.mdl"
SWEP.WorldModel		= "models/cod4/weapons/Claymore/w_cod4_claymore.mdl"

SWEP.HoldType 		= "slam"

SWEP.Primary.Automatic		= false
SWEP.Primary.Ammo = "cod4_m18_claymore"
SWEP.Primary.ClipSize	= -1
SWEP.Primary.DefaultClip	= 2

SWEP.Secondary.ClipSize		= -1
SWEP.Secondary.DefaultClip	= -1
SWEP.Secondary.Automatic	= false
SWEP.Secondary.Ammo			= "none"

SWEP.Spawnable			= true
SWEP.AdminSpawnable		= false

SWEP.COD4 = true

SWEP.ArmBgroup = 1

SWEP.Cod4Menu = true

local Particle = {
	["npc_antlionguard"] = "blood_impact_antlion_01",
	["npc_antlionguardian"] = "blood_impact_green_01",
	["npc_antlion"] = "blood_impact_antlion_01",
	["npc_antlion_worker"] = "blood_impact_antlion_worker",
	["npc_zombie"] = "blood_impact_zombie_01",
	["npc_zombine"] = "blood_impact_zombie_01",
	["npc_poisonzombie"] = "blood_impact_zombie_01",
	["npc_fastzombie_torso"] = "blood_impact_zombie_01",
	["npc_zombie_torso"] = "blood_impact_zombie_01",
	["npc_fastzombie"] = "blood_impact_zombie_01",
	["npc_headcrab"] = "blood_impact_green_01",
	["npc_headcrab_black"] = "blood_impact_green_01",
	["npc_headcrab_fast"] = "blood_impact_green_01",
	["npc_vortigaunt"] = "blood_impact_zombie_01"}
	
for k, v in pairs(Particle) do
	PrecacheParticleSystem(v)
end


function SWEP:ResetVar()
	self.Weapon:SetRun(false)
	self.Weapon:SetRaised(false)

	self.Weapon:SetWeaponBehave(COD_WEAPON_IDLE)
	self.Weapon:SetCantPlantMsg(CurTime())
	self.Weapon:SetNextAct(CurTime())
	self.Weapon:SetRunLoopDelay(CurTime())
end



function SWEP:SetupDataTables() 
	self.Weapon:NetworkVar( "Bool", 0, "Raised" )
	self.Weapon:NetworkVar( "Bool", 1, "Run" )

	self.Weapon:NetworkVar( "Int", 0, "WeaponBehave" )
	self.Weapon:NetworkVar("Int", 1, "CantPlantMsg")
	self.Weapon:NetworkVar("Int", 2, "NextAct")
	self.Weapon:NetworkVar("Int", 3, "RunLoopDelay")
end

function SWEP:Initialize()
	self:SetWeaponHoldType( self.HoldType )
	self:SetupDataTables()
	self:ResetVar()
end

function SWEP:Deploy()
	self:ResetVar()
	Vm = self.Owner:GetViewModel()
	self.Weapon:SendWeaponAnim(ACT_VM_DEPLOY)
	self.AnimDuration = Vm:SequenceDuration()
	self.Weapon:SetNextPrimaryFire(CurTime() + self.AnimDuration)
	self.Weapon:SetNextSecondaryFire(CurTime() + self.AnimDuration)
	self:SetNextAction(CurTime() + Vm:SequenceDuration())
	Vm:SetPlaybackRate(1)

	Vm:SetBodygroup( 1, self.Owner:GetNetworkedInt( "HandRig") )

	

	return true
end





function SWEP:Precache()
end



function SWEP:PrimaryAttack()
	if self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) <= 0 then return end
	if self.Weapon:GetWeaponBehave() != COD_WEAPON_IDLE then return end 
	if self:IsRunning() then return end
	if IsFirstTimePredicted() and self:CanNextAction() then		
		if self:CanPlant() then 
			self.Weapon:SendWeaponAnim(ACT_VM_PULLBACK_HIGH)
			self:SetNextAction(CurTime() + 0.2)
			self.Weapon:SetRaised(true)
		else
			self.Weapon:SetCantPlantMsg(CurTime() + 3)
		end
	end
end



function SWEP:SecondaryAttack()
	if self.Weapon:GetRaised() then
		self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
		self.Weapon:SetRaised(false)
	end
end




function SWEP:Reload()
	
end




function SWEP:Think()
	if !self:IsRunning() and self.Owner:KeyDown(IN_SPEED) and self.Owner:GetVelocity():Length() > self.Owner:GetWalkSpeed() and self:CanNextAction() and !self.Weapon:GetRaised() then
		if self.IntRunDelay then
			
			self.Weapon:SetRunLoopDelay(CurTime() + 1)
			self.IntRunDelay = false
			self.Weapon:SendWeaponAnim(ACT_VM_SPRINT_ENTER)
		end
		
		self:SetRunning(true)
		self:SetNextPrimaryFire(CurTime() + 0.5)
		
		if self.Weapon:GetRunLoopDelay() then
			self.Weapon:SendWeaponAnim(ACT_VM_SPRINT_IDLE)
		end

	elseif self:IsRunning() and !self.Owner:KeyDown(IN_SPEED) or self:IsRunning() and self.Owner:GetVelocity():Length() <= self.Owner:GetWalkSpeed() and !self.Weapon:GetRaised() then
		self:SetRunning(false)
		self.IntRunDelay = true
		self:SetNextPrimaryFire(CurTime() + 0.5)
		self.Weapon:SendWeaponAnim(ACT_VM_SPRINT_LEAVE)
	end

	if self:GetNextAction() <= CurTime() then
		
		if !self.Owner:KeyDown(IN_ATTACK) and self.Weapon:GetRaised() and IsFirstTimePredicted() then
			if self:CanPlant() then
				self.Weapon:SendWeaponAnim(ACT_VM_PULLBACK)
				self.Weapon:SetRaised(false)
				self:SetNextAction(CurTime() + 2)
				self.Weapon:EmitSound("COD4_Claymore.Plant")
				self.Owner:SetAnimation( PLAYER_ATTACK1 )
				if SERVER then
					self:PlantClaymore()
					self.Owner:SetAmmo(self.Owner:GetAmmoCount(self.Weapon:GetPrimaryAmmoType()) - 1,self.Weapon:GetPrimaryAmmoType())
				end
			else
				self.Weapon:SetCantPlantMsg(CurTime() + 3)
				self.Weapon:SendWeaponAnim(ACT_VM_IDLE)
				self.Weapon:SetRaised(false)
			end
		end 
		
		
	end
	


end




--[[---------------------------------------------------------
   Name: SWEP:Holster( weapon_to_swap_to )
   Desc: This is based off of Spy's Holster code so some credit
   needs to go to him for this one
-----------------------------------------------------------]]
function SWEP:Holster( wep )
	Vm = self.Owner:GetViewModel()
	if self == wep then
		return
	end
	
	if self.Weapon:GetWeaponBehave() == COD_WEAPON_HOLSTER_END then
		self.Weapon:SetWeaponBehave(COD_WEAPON_IDLE)
		
		return true
	end

	if self.Weapon:GetWeaponBehave() == COD_WEAPON_IDLE or self.Weapon:GetWeaponBehave() == COD_Weapon_Idle_M203 then
		if IsValid(wep) then
			self.Swap = wep:GetClass()
			
			self.Weapon:SetWeaponBehave(COD_WEAPON_HOLSTER_START)
			if self.Weapon:GetWeaponBehave() == COD_WEAPON_HOLSTER_START then
				timer.Simple(.45, function() 
					if IsValid(self) and IsValid(self.Owner) and self.Owner:Alive() then
						self.Weapon:SetWeaponBehave(COD_WEAPON_HOLSTER_END)
						Vm:SetBodygroup( 1, 0)
						self.Owner:ConCommand("use " .. self.Swap)
						
					end
					
				end)
			end
		end
		
		self:PlayHolster()
	end

	return false
end


function SWEP:CanNextAction()
	return self.Weapon:GetNextAct() <= CurTime()
end

function SWEP:GetNextAction()
	return self.Weapon:GetNextAct()
end

function SWEP:SetNextAction(time)
	return self.Weapon:SetNextAct(time)
end



function SWEP:SetRunning(Bool)
	self.Weapon:SetRun(Bool)
	if Bool then -- things will happen if Bool is true

	else -- things will happen if bool is false
	end
end

function SWEP:IsRunning()
	if self.Weapon:GetRun() then
		return self.Weapon:GetRun()
	end
	return false
end

function SWEP:CanPlant()
	local GroundDetect={}
	GroundDetect.start=self.Owner:GetShootPos() 
	GroundDetect.endpos=GroundDetect.start-Vector(0,0,75) 
	GroundDetect.filter= function( ent ) if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return false end end
	local res=util.TraceLine(GroundDetect)

	if(res.Fraction<1) then	
		return true
	end
	

	return false
end

function SWEP:PlantClaymore()
	local GroundDetect={}
	GroundDetect.start=self.Owner:GetShootPos() 
	GroundDetect.endpos=GroundDetect.start-Vector(0,0,75) 
	GroundDetect.filter= function( ent ) if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() then return false end end
	local res=util.TraceLine(GroundDetect)

	local ent = ents.Create("cod4_planted_claymore")
		ent:SetPos(res.HitPos + Vector(0,0,2))
		ent:SetAngles(Angle(0,self.Owner:EyeAngles().yaw - 90,0))
		ent:Spawn()
		ent:SetOwner(self.Owner)
					
end

-- A nice little function to condense the main knife functions in. 
function SWEP:DoKnife()
	if !self:CanNextAction() then return end 
	Ctrace = util.TraceLine( { 
	start = self.Owner:GetShootPos(),
	endpos = self.Owner:GetShootPos() + self.Owner:EyeAngles():Forward() * 100,
	filter = {self.Owner}
	} )
		
		-- 45 or lower
	if IsValid(Ctrace.Entity) then
		if Ctrace.Entity:IsPlayer() or Ctrace.Entity:IsNPC() then

			if Ctrace.Entity:GetPos():Distance( self.Owner:GetPos()) <= 52 then
				self.Weapon:SendWeaponAnim( ACT_VM_SWINGMISS )
					
				timer.Simple(0.2, function()
					if !IsValid(self) then return end
					self:DoKnifeDamage(Ctrace.Entity, Ctrace.HitPos, Ctrace.HitNormal:Angle(), Ctrace.MatType )
				end)
					
				self.Owner:ViewPunch(Angle(0,-15,0))

				timer.Simple(0.8, function()
					if !IsValid(self) then return end
					self:DoKnifeRecover()
				end)

				self:SetNextAction(CurTime() + 1.5)
	
			else
				self.Weapon:SendWeaponAnim( ACT_VM_SWINGHARD )
					
				timer.Simple(0.1, function()
					if !IsValid(self) then return end
					self:DoKnifeDamage(Ctrace.Entity, Ctrace.HitPos, Ctrace.HitNormal:Angle(), Ctrace.MatType )
				end)

				self.Owner:ViewPunch(Angle(10,0,0))
				self.Owner:SetVelocity(self.Owner:GetAngles( ):Forward() * 500)


				timer.Simple(0.8, function()
					if !IsValid(self) then return end
					self:DoKnifeRecover()
				end)

				self:SetNextAction(CurTime() + 1.5)
			end

		end
	else

		self.Owner:ViewPunch(Angle(0,-15,0))
		self.Weapon:SendWeaponAnim( ACT_VM_SWINGMISS )
		timer.Simple(0.8, function()
			if !IsValid(self) then return end
			self:DoKnifeRecover()
		end)
		self:SetNextAction(CurTime() + 1.5)
	end
	self.Owner:DoAnimationEvent(ACT_GMOD_GESTURE_MELEE_SHOVE_2HAND)
	-- When you call an animation event server side in sp you can see it clientside
	-- This is not the case in mp so you need to tell the client that it should play the animation
	-- So the player can see themself doing it though a camera ect.
	-- that is exactly what this umsg does
	-- its main function is located in cod_4_settings_cl_menu.lua
	if SERVER and !game.SinglePlayer() then
		umsg.Start("worldknife", self.Owner)
		umsg.End()
	end

end
-- Function that handels the knife damage
function SWEP:DoKnifeDamage(ent, pos, ang, mat)
	if SERVER then
		dmg = DamageInfo()
		dmg:SetDamageType(DMG_SLASH)
		dmg:SetDamage(500)
		dmg:SetAttacker(self.Owner)
		dmg:SetInflictor(self.Owner.KnifeEnt)
		dmg:SetDamageForce(self.Owner:EyeAngles():Forward() * 150)
		ent:TakeDamageInfo(dmg)
	end
	
	if IsValid(ent) then
		ent:EmitSound("COD_Knife.Stab")
	end

	if mat == MAT_FLESH or mat == MAT_ANTLION or mat == MAT_ALIENFLESH or mat == MAT_BLOODYFLESH then
		cl = Particle[ent:GetClass()]
		ParticleEffect((cl or "blood_impact_red_01"), pos, ang, ent)
	end
end

function SWEP:DoKnifeRecover()
if !IsFirstTimePredicted() or !game.SinglePlayer then return end
	Vm = self.Owner:GetViewModel()
	if self.Weapon:GetWeaponBehave() == COD_Weapon_Idle_M203 then
		self.Weapon:SendWeaponAnim(ACT_VM_FIDGET)
		Vm:SetSequence(Vm:LookupSequence("deploy_fast_m203"))
	else
		self.Weapon:SendWeaponAnim(ACT_VM_FIDGET)
		Vm:SetSequence(Vm:LookupSequence("deploy_fast"))
	end
end

function SWEP:DoNade()
	if self:IsRunning() then return end
		self.Owner:SetNetworkedString( "LastWep", self.Weapon:GetClass())
		
		if self.Owner:GetNetworkedInt("EQ") == 1 and self.Owner:GetAmmoCount("cod4_m67") > 0 then
        	self.Owner:SetAmmo(self.Owner:GetAmmoCount("cod4_m67") - 1 ,"cod4_m67")
        	self.Owner:Give("cod_m67")
        	self.Owner:SelectWeapon("cod_m67")
    	elseif self.Owner:GetNetworkedInt("EQ") == 2 and self.Owner:GetAmmoCount("cod4_flashbang") > 0 then
    		self.Owner:SetAmmo(self.Owner:GetAmmoCount("cod4_flashbang") - 1 ,"cod4_flashbang")
    		self.Owner:Give("cod_m84_flash")
    		self.Owner:SelectWeapon("cod_m84_flash")
    	elseif self.Owner:GetNetworkedInt("EQ") == 3 and self.Owner:GetAmmoCount("cod4_m18") > 0 then
    		self.Owner:SetAmmo(self.Owner:GetAmmoCount("cod4_m18") - 1 ,"cod4_m18")
        	self.Owner:Give("cod_m18")
        	self.Owner:SelectWeapon("cod_m18")
    	elseif self.Owner:GetNetworkedInt("EQ") == 4 and self.Owner:GetAmmoCount("cod4_concussion") > 0 then
    		self.Owner:SetAmmo(self.Owner:GetAmmoCount("cod4_concussion") - 1 ,"cod4_concussion")
    		self.Owner:Give("cod_m84_concu")
        	self.Owner:SelectWeapon("cod_m84_concu")

    	end
end

function SWEP:PlayHolster()
	self.Weapon:SendWeaponAnim(ACT_VM_HOLSTER)
end