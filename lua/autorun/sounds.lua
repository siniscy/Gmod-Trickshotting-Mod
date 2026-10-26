-- Made by reha (@rehaiu old handle: @trenchd9g&@iuascript)! RIP PHANTOM REMORSE </3 #GMODTAKEOVER

-- The code below was just a test for cod-like spinning but it doesn't work. I've decided to keep it incase anyone tries to fix it!

--local function SetSwayScale()
	--plr = Entity(1)
	--ang = Angle(0, 100, 0)
	--ang0 = Angle(0, 0, 0)
	--getwep = plr:GetActiveWeapon()
	--if plr:KeyDown(IN_RIGHT) then
	--	getwep:SetAngles(ang)
	--end
	--if plr:KeyReleased(IN_RIGHT) then
	--	getwep:SetAngles(ang0)
	--end
--end

--hook.Add("PlayerPostThink", "CoDSpin", SetSwayScale )
for i, ply in ipairs( player.GetAll() ) do
	--ply:ChatPrint( "SteezMod v1.0b loaded! <@rehaiu>")
	ply:PrintMessage(HUD_PRINTTALK, "SteezMod v1b loaded! <@rehaiu>")
	--ply:PrintMessage(HUD_PRINTCENTER, "Standard User detected. Donate if you want to get access to the unique features.")
end



local icol = Color( 255, 255, 255, 255 ) 
if CLIENT then
	language.Add("cssc4", "C4")
	language.Add("m9k_ammo_explosion", "Poor Decision Making Skills")
	
end

game.AddAmmoType( {
	name = "cssc4",
	dmgtype = DMG_BULLET
})


if GetConVar("DebugM9K") == nil then
	CreateConVar("DebugM9K", "0", { FCVAR_REPLICATED, FCVAR_ARCHIVE }, "Debugging for some m9k stuff, turning it on won't change much.")
end

if GetConVar("M9KWeaponStrip") == nil then
	CreateConVar("M9KWeaponStrip", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Allow empty weapon stripping? 1 for true, 0 for false")
	print("Weapon Strip con var created")
end
	
if GetConVar("M9KDisablePenetration") == nil then
	CreateConVar("M9KDisablePenetration", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Disable Penetration and Ricochets? 1 for true, 0 for false")
	print("Penetration/ricochet con var created")
end
	
if GetConVar("M9KDynamicRecoil") == nil then
	CreateConVar("M9KDynamicRecoil", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Use Aim-modifying recoil? 1 for true, 0 for false")
	print("Recoil con var created")
end
	
if GetConVar("M9KAmmoDetonation") == nil then
	CreateConVar("M9KAmmoDetonation", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Enable detonatable M9K Ammo crates? 1 for true, 0 for false.")
	print("Ammo crate detonation con var created")
end

if GetConVar("M9KDamageMultiplier") == nil then
	CreateConVar("M9KDamageMultiplier", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Multiplier for M9K bullet damage.")
	print("Damage Multiplier con var created")
end

if GetConVar("M9KDefaultClip") == nil then
	CreateConVar("M9KDefaultClip", "-1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "How many clips will a weapon spawn with? Negative reverts to default values.")
	print("Default Clip con var created")
end
	
if GetConVar("M9KUniqueSlots") == nil then
	CreateConVar("M9KUniqueSlots", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Give M9K Weapons unique slots? 1 for true, 2 for false. A map change may be required.")
	print("Unique Slots con var created")
end
	
if !game.SinglePlayer() then

	if GetConVar("M9KClientGasDisable") == nil then
		CreateConVar("M9KClientGasDisable", "0", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Turn off gas effect for all clients? 1 for yes, 0 for no. ")
	end
	
	if SERVER then
	
		function ClientSideGasDisabler()
			timer.Create("ClientGasBroadcastTimer", 15, 0, 
				function() BroadcastLua("RunConsoleCommand(\"M9KGasEffect\", \"0\")") end )
		end
	
		if GetConVar("M9KClientGasDisable"):GetBool() then
			ClientSideGasDisabler()
		end

		function M9K_Svr_Gas_Change_Callback(cvar, previous, new)
			if tobool(new) == true then
				ClientSideGasDisabler()
				BroadcastLua("print(\"Gas effects disabled on this server!\")")
			elseif tobool(new) == false then
				BroadcastLua("print(\"Gas effects re-enabled on this server.\")")
				BroadcastLua("print(\"You may turn on M9KGasEffect if you wish.\")")
				if timer.Exists("ClientGasBroadcastTimer") then
					timer.Destroy("ClientGasBroadcastTimer")
				end
			end				
		end
		cvars.AddChangeCallback("M9KClientGasDisable", M9K_Svr_Gas_Change_Callback)
	
	end
	
	if CLIENT then
		if GetConVar("M9KGasEffect") == nil then
			CreateClientConVar("M9KGasEffect", "1", true, true)
			print("Client-side Gas Effect Con Var created")
		end		
	end

else
	if GetConVar("M9KGasEffect") == nil then
		CreateConVar("M9KGasEffect", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "Use gas effect when shooting? 1 for true, 0 for false")
		print("Gas effect con var created")
	end
end
	
--deprecated, but left for legacy purposes
if GetConVar("M9KUnified_CSS_vms") == nil then
	CreateConVar("M9KUnified_CSS_vms", "1", { FCVAR_REPLICATED, FCVAR_NOTIFY, FCVAR_ARCHIVE }, "deprecated, left for legacy purposes.")
end
sound.Add({
	name = 			"mw_swoosh",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/swing2.wav"
})
--MW2CR M9
sound.Add({
	name = 			"defaultpullout_1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/raise.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.Pull",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpn_h1_m9_ins_pull.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.Release",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpn_h1_m9_ins_release.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpn_h1_m9_shot_02.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.MagIn",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpfoly_beretta9mm_reload_clipin_v2.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.MagOut",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpfoly_beretta9mm_reload_clipout_v2.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.Chamber",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/wpfoly_beretta9mm_reload_chamber_v2.wav"
})
sound.Add({
	name = 			"TFA_MW2R_M9.Inspect2",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2CR/M9/inspect2.wav"
})

--MW2 INTERVENTON/CHEYTAC
sound.Add({
	name = 			"iw4.cheytac.fire",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/fire.wav"
})
--SILENCER SNIPER
sound.Add({
	name = 			"iw4.cheytac.fires",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/sniper.wav"
})
sound.Add({
	name = 			"iw4.cheytac.unlock",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/unlock.wav"
})
sound.Add({
	name = 			"iw4.cheytac.open",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/open.wav"
})
sound.Add({
	name = 			"iw4.cheytac.close",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/close.wav"
})
sound.Add({
	name = 			"iw4.cheytac.lock",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/lock.wav"
})
sound.Add({
	name = 			"iw4.cheytac.lift",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/lift.wav"
})
sound.Add({
	name = 			"iw4.cheytac.out",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/out.wav"
})
sound.Add({
	name = 			"iw4.cheytac.in",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/cheytac/in.wav"
})
-- BARRETT MW3
sound.Add({
	name = 			"MW3_m82_FIRE",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/m82/fire.wav"
})
sound.Add({
	name = 			"mw3_m82_RELOAD_1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/m82/lift.wav"
})
sound.Add({
	name = 			"mw3_m82_RELOAD_2",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/m82/magout.wav"
})
sound.Add({
	name = 			"mw3_m82_RELOAD_3",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/m82/magin.wav"
})
sound.Add({
	name = 			"mw3_m82_RELOAD_4",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/m82/bolt.wav"
})

---PAYDAY2
-- SHOTGUN
sound.Add({
	name = 			"locomotive12g.1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/pd2/loco/Locomotive12G Fire.wav"
})
sound.Add({
	name = 			"locomotive12g.pump",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/pd2/loco/Locomotive12G Pump.wav"
})
sound.Add({
	name = 			"locomotive12g.insert",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/pd2/loco/Locomotive12G Insert.wav"
})
sound.Add({
	name = 			"locomotive12g.deploy",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/pd2/loco/Locomotive12G Deploy.wav"
})

-- MW3 L96A1
sound.Add({
	name = 			"mw3_l96a1.1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/fire.wav"
})
sound.Add({
	name = 			"mw3_l96a1_RELOAD_1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/lift.wav"
})
sound.Add({
	name = 			"mw3_l96a1_RELOAD_2",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/open.wav"
})
sound.Add({
	name = 			"mw3_l96a1_RELOAD_3",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/magout.wav"
})
sound.Add({
	name = 			"mw3_l96a1_RELOAD_4",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/magin.wav"
})
sound.Add({
	name = 			"mw3_l96a1_RELOAD_5",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW3/l96/close.wav"
})

-- MW2 M4a1
sound.Add({
	name = 			"iw4.m4a1.1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/fire.wav"
})
sound.Add({
	name = 			"iw4.m4a1.lift",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/lift.wav"
})
sound.Add({
	name = 			"iw4.m4a1.out",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/out.wav"
})
sound.Add({
	name = 			"iw4.m4a1.in",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/in.wav"
})
sound.Add({
	name = 			"iw4.m4a1.hit",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/hit.wav"
})
sound.Add({
	name = 			"iw4.m4a1.chamber",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/MW2/m4/chamber.wav"
})


m9knpw = {}
table.insert(m9knpw, "m9k_davy_crockett_explo")
table.insert(m9knpw, "m9k_gdcwa_matador_90mm")
table.insert(m9knpw, "m9k_gdcwa_rpg_heat")
table.insert(m9knpw, "m9k_improvised_explosive")
table.insert(m9knpw, "m9k_launched_davycrockett")
table.insert(m9knpw, "m9k_launched_ex41")
table.insert(m9knpw, "m9k_launched_m79")
table.insert(m9knpw, "m9k_m202_rocket")
table.insert(m9knpw, "m9k_mad_c4")
table.insert(m9knpw, "m9k_milkor_nade")
table.insert(m9knpw, "m9k_nervegasnade")
table.insert(m9knpw, "m9k_nitro_vapor")
table.insert(m9knpw, "m9k_oribital_cannon")
table.insert(m9knpw, "m9k_poison_parent")
table.insert(m9knpw, "m9k_proxy")
table.insert(m9knpw, "m9k_released_poison")
table.insert(m9knpw, "m9k_sent_nuke_radiation")
table.insert(m9knpw, "m9k_thrown_harpoon")
table.insert(m9knpw, "m9k_thrown_knife")
table.insert(m9knpw, "m9k_thrown_m61")
table.insert(m9knpw, "m9k_thrown_nitrox")
table.insert(m9knpw, "m9k_thrown_spec_knife")
table.insert(m9knpw, "m9k_thrown_sticky_grenade")
table.insert(m9knpw, "bb_dod_bazooka_rocket")
table.insert(m9knpw, "bb_dod_panzershreck_rocket")
table.insert(m9knpw, "bb_garand_riflenade")
table.insert(m9knpw, "bb_k98_riflenade")
table.insert(m9knpw, "bb_planted_dod_tnt")
table.insert(m9knpw, "bb_thrownalliedfrag")
table.insert(m9knpw, "bb_thrownaxisfrag")
table.insert(m9knpw, "bb_thrownsmoke_axis")
table.insert(m9knpw, "bb_thrownaxisfrag")
table.insert(m9knpw, "bb_planted_alt_c4")
table.insert(m9knpw, "bb_planted_css_c4")
table.insert(m9knpw, "bb_throwncssfrag")
table.insert(m9knpw, "bb_throwncsssmoke")
table.insert(m9knpw, "m9k_ammo_40mm")
table.insert(m9knpw, "m9k_ammo_40mm_single")
table.insert(m9knpw, "m9k_ammo_357")
table.insert(m9knpw, "m9k_ammo_ar2")
table.insert(m9knpw, "m9k_ammo_buckshot")
table.insert(m9knpw, "m9k_ammo_c4")
table.insert(m9knpw, "m9k_ammo_frags")
table.insert(m9knpw, "m9k_ammo_ieds")
table.insert(m9knpw, "m9k_ammo_nervegas")
table.insert(m9knpw, "m9k_ammo_nuke")
table.insert(m9knpw, "m9k_ammo_pistol")
table.insert(m9knpw, "m9k_ammo_proxmines")
table.insert(m9knpw, "m9k_ammo_rockets")
table.insert(m9knpw, "m9k_ammo_smg")
table.insert(m9knpw, "m9k_ammo_sniper_rounds")
table.insert(m9knpw, "m9k_ammo_stickynades")
table.insert(m9knpw, "m9k_ammo_winchester")

function PocketM9KWeapons(ply, wep)

	if not IsValid(wep) then return end
	class = wep:GetClass()
	m9knopocket = false
	
	for k, v in pairs(m9knpw) do
		if v == class then
			m9knopocket = true
			break
		end
	end
	
	if m9knopocket then
		return false
	end
	
	
	
end
hook.Add("canPocket", "PocketM9KWeapons", PocketM9KWeapons )

m9kcss_autorun_mounted = true