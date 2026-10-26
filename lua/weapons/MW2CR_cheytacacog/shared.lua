-- Variables that are used on both client and server
SWEP.Gun = ("reha_codonline_cheytac2")					-- must be the name of your swep
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "bobs_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Category				= "[4]RIFLES/SNIPERS"
SWEP.Author				= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions				= ""
SWEP.MuzzleAttachment			= "2" 	-- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment			= "2" 	-- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName				= "[MW2] Intervention (ACOG)"		-- Weapon name (Shown on HUD)	
SWEP.Slot				= 3				-- Slot in the weapon selection menu
SWEP.SlotPos				= 52			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox			= false		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   		= 	false	-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= false		-- set false if you want no crosshair
SWEP.Weight				= 50			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "ar2"		-- how others view you carrying the weapon

SWEP.ViewModelFOV			= 65
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/MW2/cheytac/attach/acog/c_iw4_intervention.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/MW2/cheytac/attach/acog/c_iw4_intervention.mdl"	-- Weapon world model
SWEP.Base				= "rehas_gun_base_v2"
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true
SWEP.FiresUnderwater = false
SWEP.UseHands = true

SWEP.Primary.Sound			= Sound("iw4.cheytac.fire")		-- script that calls the primary fire sound
SWEP.Primary.RPM				= 50		-- This is in Rounds Per Minute
SWEP.Primary.ClipSize			= 5		-- Size of a clip
SWEP.Primary.DefaultClip			= 45	-- Bullets you start with
SWEP.Primary.KickUp			= 1				-- Maximum up recoil (rise)
SWEP.Primary.KickDown			= 0.8			-- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal			= 0.3		-- Maximum up recoil (stock)
SWEP.Primary.Automatic			= false		-- Automatic/Semi Auto
SWEP.Primary.Ammo			= "SniperPenetratedRound"

SWEP.Secondary.IronFOV			= 70		-- How much you 'zoom' in. Less is more! 	

SWEP.data 				= {}				--The starting firemode
SWEP.data.ironsights			= 1

SWEP.Primary.NumShots	= 1		--how many bullets to shoot per trigger pull
SWEP.Primary.Damage		= 135	--base damage per bullet
SWEP.Primary.Spread		= .08	--define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.IronAccuracy = 0.0 -- ironsight accuracy, should be the same for shotguns


SWEP.SelectiveFire		= false

-- enter iron sight info and bone mod info below
SWEP.IronSightsPos = Vector(-3.779, -3.895, 1.011)
SWEP.IronSightsAng = Vector( 0, 0, 0 )
SWEP.SightsPos = Vector(-3.779, -3.895, 1.011)
SWEP.SightsAng = Vector( 0, 0, 0 )
SWEP.RunSightsPos = Vector(0, 0, 0)
SWEP.RunSightsAng = Vector(0, 0, 0)


if GetConVar("M9KDefaultClip") == nil then
	print("M9KDefaultClip is missing! You may have hit the lua limit!")
else
	if GetConVar("M9KDefaultClip"):GetInt() != -1 then
		SWEP.Primary.DefaultClip = SWEP.Primary.ClipSize * GetConVar("M9KDefaultClip"):GetInt()
	end
end



if GetConVar("M9KUniqueSlots") != nil then
	if not (GetConVar("M9KUniqueSlots"):GetBool()) then 
		SWEP.SlotPos = 2
	end
end

if GetConVar("get_sleightofhand"):GetInt() == 1 then
	SWEP.SoH = 1
end

if GetConVar("get_reversereload"):GetInt() == 1 then
	SWEP.ReverseRel = 1
end