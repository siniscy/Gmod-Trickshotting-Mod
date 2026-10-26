-- Variables that are used on both client and server
SWEP.Gun = ("reha_smokegrenadeiw5") -- must be the name of your swep but NO CAPITALS!
if (GetConVar(SWEP.Gun.."_allowed")) != nil then
	if not (GetConVar(SWEP.Gun.."_allowed"):GetBool()) then SWEP.Base = "bobs_blacklisted" SWEP.PrintName = SWEP.Gun return end
end
SWEP.Category				= "reha's sweps v1 隷波"
SWEP.Author				= ""
SWEP.Contact				= ""
SWEP.Purpose				= ""
SWEP.Instructions				= ""
SWEP.PrintName				= "Care Package (CSS Hands)"		-- Weapon name (Shown on HUD)

-- The flag the whole loadout system keys off of: cl_loadouts_switch.lua
-- excludes any weapon carrying this from invnext/invprev cycling and is the
-- only thing kc_equip's quick-switch will select.
SWEP.KC_IsEquipment = true

SWEP.Slot				= 4				-- Slot in the weapon selection menu
SWEP.SlotPos				= 38			-- Position in the slot
SWEP.DrawAmmo				= true		-- Should draw the default HL2 ammo counter
SWEP.DrawWeaponInfoBox			= false		-- Should draw the weapon info box
SWEP.BounceWeaponIcon   		= 	false	-- Should the weapon icon bounce?
SWEP.DrawCrosshair			= false		-- set false if you want no crosshair
SWEP.Weight				= 2			-- rank relative ot other weapons. bigger is better
SWEP.AutoSwitchTo			= true		-- Auto switch to if we pick it up
SWEP.AutoSwitchFrom			= true		-- Auto switch from if you pick up a better weapon
SWEP.HoldType 				= "grenade"		-- how others view you carrying the weapon
-- normal melee melee2 fist knife smg ar2 pistol rpg physgun grenade shotgun crossbow slam passive 
-- you're mostly going to use ar2, smg, shotgun or pistol. rpg and ar2 make for good sniper rifles

SWEP.ViewModelFOV			= 70
SWEP.ViewModelFlip			= false
SWEP.ViewModel				= "models/weapons/iw5/v_eq_smokegrenade.mdl"	-- Weapon view model
SWEP.WorldModel				= "models/weapons/iw5/w_eq_smokegrenade.mdl"	-- Weapon world model
SWEP.ShowWorldModel			= true
SWEP.Base				= "kc_rehas_nade_base"
SWEP.Spawnable				= true
SWEP.UseHands = false
SWEP.AdminSpawnable			= true

SWEP.Primary.RPM				= 30		-- This is in Rounds Per Minute
SWEP.Primary.ClipSize			= 1		-- Size of a clip
SWEP.Primary.DefaultClip		= 1		-- Bullets you start with
SWEP.Primary.Automatic			= false		-- Automatic = true; Semi Auto = false
SWEP.Primary.Ammo			= "Grenade"				
-- pistol, 357, smg1, ar2, buckshot, slam, SniperPenetratedRound, AirboatGun
-- Pistol, buckshot, and slam always ricochet. Use AirboatGun for a metal peircing shotgun slug

SWEP.Primary.Round 			= ("bb_throwncsssmoke")	--NAME OF ENTITY GOES HERE

-- enter bone mod and other custom stuff below. Irons aren't used for grenades


if GetConVar("M9KUniqueSlots") != nil then
	if not (GetConVar("M9KUniqueSlots"):GetBool()) then 
		SWEP.SlotPos = 2
	end
end