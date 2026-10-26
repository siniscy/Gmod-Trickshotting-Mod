-- Variables that are used on both client and server
SWEP.Gun = ("weapon_bo2_dsr50")					-- must be the name of your swep
SWEP.Category				= "Call Of Duty: Black Ops II"
SWEP.Author				= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions				= ""
SWEP.MuzzleAttachment			= "1" 	-- Should be "1" for CSS models or "muzzle" for hl2 models
SWEP.ShellEjectAttachment			= "2" 	-- Should be "2" for CSS models or "1" for hl2 models
SWEP.PrintName				= "DSR .50"		-- Weapon name (Shown on HUD)	
SWEP.Slot				= 1				-- Slot in the weapon selection menu
SWEP.SlotPos				= 3			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox			= false		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   		= 	false	-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= true		-- set false if you want no crosshair
SWEP.Weight				= 30			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "ar2"		-- how others view you carrying the weapon

SWEP.ViewModelFOV			= 65
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/v_bo2_dsr50.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/w_snip_awp.mdl"	-- Weapon world model
SWEP.Base				= "bo2_scoped_base"
SWEP.Spawnable				= true
SWEP.AdminSpawnable			= true
SWEP.FiresUnderwater = false

SWEP.Primary.Sound			= Sound("weapons/dsr50/fire.wav")		-- Script that calls the primary fire sound
SWEP.Primary.RPM			= 47			-- This is in Rounds Per Minute
SWEP.Primary.ClipSize			= 5		-- Size of a clip
SWEP.Primary.DefaultClip		= 63		-- Bullets you start with
SWEP.Primary.KickUp				= 1.2		-- Maximum up recoil (rise)
SWEP.Primary.KickDown			= 1.2		-- Maximum down recoil (skeet)
SWEP.Primary.KickHorizontal		= 1.2		-- Maximum up recoil (stock)
SWEP.Primary.Automatic			= false	-- Automatic = true; Semi Auto = false
SWEP.Primary.Ammo			= "357"
SWEP.Secondary.UseACOG			= false	
SWEP.Secondary.UseMilDot			= false		
SWEP.Secondary.UseSVD			= false	
SWEP.Secondary.UseParabolic		= true	
SWEP.Secondary.UseElcan			= false
SWEP.Secondary.UseGreenDuplex		= false
SWEP.Secondary.ScopeZoom			= 6
SWEP.BoltAction	=	true

SWEP.Secondary.IronFOV			= 65		-- How much you 'zoom' in. Less is more! 	

SWEP.data 				= {}				--The starting firemode
SWEP.data.ironsights			= 1

SWEP.ScopeScale 			= 1
SWEP.Primary.NumShots	= 1		-- How many bullets to shoot per trigger pull
SWEP.Primary.Damage		= 120	-- Base damage per bullet
SWEP.Primary.Spread		= .1	-- Define from-the-hip accuracy 1 is terrible, .0001 is exact)
SWEP.Primary.IronAccuracy = .0004 -- Ironsight accuracy, should be the same for shotguns

SWEP.CanBeSilenced		= false

-- Enter iron sight info and bone mod info below

	SWEP.IronSightsPos = Vector(-10.961, -11.2, 1.08)
	SWEP.IronSightsAng = Vector(0, 0, 0)
	SWEP.SightsPos = Vector(-10.961, -11.2, 1.08)
	SWEP.SightsAng = Vector(0, 0, 0)
	SWEP.RunSightsPos = Vector(-2.401, -4.401, 4.199)
	SWEP.RunSightsAng = Vector(-25.3, 30.799, -10.9)