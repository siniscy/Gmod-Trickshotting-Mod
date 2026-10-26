-- Minimal support code the "cod_claymore" equipment (from the CoD4 Equipment
-- addon) depends on. That addon is a large interlinked framework; this pulls
-- in only the pieces the claymore weapon and its planted-mine entity actually
-- reach, trimmed down from lua/autorun/cod4_sh.lua and lua/weapons/cod4_base.

-- Ammo type backing the claymore's clip (cod4_sh.lua).
game.AddAmmoType({
	name = "cod4_m18_claymore",
	dmgtype = DMG_BULLET,
	force = 2000,
	plydmg = 0,
	npcdmg = 0
})

-- Weapon-behave state constants read by cod_claymore/shared.lua (from cod4_base/shared.lua).
COD_WEAPON_IDLE = 0
COD_WEAPON_HOLSTER = 1
COD_WEAPON_HOLSTER_START = 2
COD_WEAPON_HOLSTER_END = 3

-- cod_claymore/cl_init.lua indexes an equip-icon table by the player's "EQ"
-- networked int and errors if it's unset (defaults to 0, an invalid index),
-- and shared.lua reads "HandRig" for a bodygroup on Deploy. The full CoD4
-- pack sets both in a PlayerInitialSpawn hook alongside unrelated kill-credit
-- entities we don't need, so this is a trimmed equivalent.
hook.Add("PlayerInitialSpawn", "KC_COD4ClaymoreSupport_PlayerInit", function(ply)
	ply:SetNetworkedInt("EQ", 1)
	ply:SetNetworkedInt("HandRig", 0)
end)

-- No DTVar shim here. cod4_planted_claymore only calls self:DTVar inside
-- SetupDataTables, where GMod already provides it per-entity. A shim on the
-- Entity metatable shadows that per-entity function for EVERY entity, so
-- NetworkVar() got nil back and every NetworkVar getter/setter errored
-- (CoD4 AT4/C4/claymore knife, all TFA weapons).

-- Claymore plant/arm/click sounds (from cod4_misc_sounds.lua).
sound.Add({
	name = "COD4_Claymore.Raise",
	channel = CHAN_WEAPON,
	volume = 1,
	soundlevel = 50,
	sound = ")weapons/cod4/claymore/raise.wav"
})
sound.Add({
	name = "COD4_Claymore.Plant",
	channel = CHAN_AUTO,
	volume = 1,
	soundlevel = 50,
	sound = ")weapons/cod4/claymore/plant.wav"
})
sound.Add({
	name = "COD4_Claymore.Click",
	channel = CHAN_AUTO,
	volume = 1,
	soundlevel = 50,
	sound = ")weapons/cod4/claymore/click.wav"
})
