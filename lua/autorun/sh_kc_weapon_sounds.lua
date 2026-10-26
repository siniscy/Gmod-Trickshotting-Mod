-- Sound scripts the bundled weapons play through their models' animation
-- events and SWEP.Primary.Sound. Each one lives in its original pack's own
-- autorun file, which this addon doesn't ship, so without these the guns
-- fire or reload silently. Copied verbatim from those packs.

-- Black Ops II Weapons Pack (bo2_autorun.lua): DSR-50 and KAP-40 reloads.
sound.Add({
	name = 			"Weapon_BO2_DSR.BoltBack",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/ballista/bolt_back.wav"
})
sound.Add({
	name = 			"Weapon_BO2_DSR.BoltForward",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/ballista/bolt_forward.wav"
})
sound.Add({
	name = 			"Weapon_BO2_DSR.Chamber",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/ballista/rechamber.wav"
})
sound.Add({
	name = 			"Weapon_BO2_DSR.Magin",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/ballista/magin.wav"
})
sound.Add({
	name = 			"Weapon_BO2_DSR.Magout",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/ballista/magout.wav"
})
sound.Add({
	name = 			"Weapon_BO2_Kap40.Magin",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/tac45/magin.wav"
})
sound.Add({
	name = 			"Weapon_BO2_Kap40.Magout",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/tac45/magout.wav"
})
sound.Add({
	name = 			"Weapon_BO2_Kap40.Slide",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/tac45/slide.wav"
})

-- reha's sweps (trenchd9g.lua): M21 Ghillie.
sound.Add({
	name = 			"iw3m21.1",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/reha_iw3/m21g/fire.wav"
})
sound.Add({
	name = 			"iw3m21.in",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/reha_iw3/m21g/in_tac.wav"
})
sound.Add({
	name = 			"iw3m21.lift",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/reha_iw3/m21g/lift.wav"
})
sound.Add({
	name = 			"iw3m21.out",
	channel = 		CHAN_USER_BASE+10,
	volume = 		1.0,
	sound = 			"weapons/reha_iw3/m21g/out.wav"
})

-- Wavy's CoD4 / WaW ports (wavy_iw3_weapons.lua, wavy_waw_sounds.lua):
-- MP5, Kar98k, Trench Gun.
sound.Add({
	name = 			"iw3.mp5.chamber",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/iw3/mp5/chamber.wav"
})
sound.Add({
	name = 			"iw3.mp5.fire",
	channel = 		CHAN_USER_BASE +10,
	volume = 		1.0,
	pitch = 		{ 95, 105 },
	sound = 			"weapons/iw3/mp5/fire.wav"
})
sound.Add({
	name = 			"iw3.mp5.in",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/iw3/mp5/in.wav"
})
sound.Add({
	name = 			"iw3.mp5.out",
	channel = 		CHAN_ITEM,
	volume = 		1.0,
	sound = 			"weapons/iw3/mp5/out.wav"
})
sound.Add({
	name = 			"TFA_WAW.KAR98K.FIRE",
	channel = 		CHAN_USER_BASE +10,
	volume = 		1.0,
	sound = 			"weapons/wavy_weapons/waw_kar98k/fire.wav"
})
sound.Add({
	name = 			"TFA_WAW.TRENCHGUN.FIRE",
	channel = 		CHAN_USER_BASE +10,
	volume = 		1.0,
	sound = 			"weapons/wavy_weapons/waw_shotgun/wpn_shtgun_st_f.wav"
})

-- Counter-Strike: Source scripts the smoke grenade uses. GMod ships the wav
-- files but only defines these names when CS:S is mounted, so fill them in
-- only when they're missing.
local CSS_FALLBACKS = {
	{ name = "Default.PullPin_Grenade", channel = CHAN_ITEM, volume = 1.0, level = 75, sound = "weapons/pinpull.wav" },
	{ name = "HEGrenade.Bounce", channel = CHAN_ITEM, volume = 0.6, level = 75, sound = "weapons/hegrenade/he_bounce-1.wav" },
	{ name = "BaseSmokeEffect.Sound", channel = CHAN_WEAPON, volume = 1.0, level = 85, sound = "weapons/smokegrenade/sg_explode.wav" },
}
for _, s in ipairs(CSS_FALLBACKS) do
	if not sound.GetProperties(s.name) then sound.Add(s) end
end

-- Call of Duty 4: Equipment (cod4_sounds.lua): knife and deploy. Those wavs
-- ship under sound/global/ in the pack, which its own script never pointed
-- at; this addon carries them at the paths below.
sound.Add(
{
    name = "COD.Deploy",
    channel = CHAN_WEAPON,
    volume = 1,
    soundlevel = 80,
    sound = {
    "weapons/cod4/global/d1.wav",
    "weapons/cod4/global/d2.wav",
    "weapons/cod4/global/d3.wav",
    "weapons/cod4/global/d4.wav"}
})
sound.Add(
{
    name = "COD_Knife.Stab",
    channel = CHAN_WEAPON,
    volume = 1,
    soundlevel = 80,
    sound = { "weapons/cod4/global/s1.wav", "weapons/cod4/global/s2.wav", "weapons/cod4/global/s3.wav"}
})
sound.Add(
{
    name = "COD_Knife_Swipe",
    channel = CHAN_WEAPON,
    volume = 1,
    soundlevel = 80,
    sound = { "weapons/cod4/global/kn1.wav", "weapons/cod4/global/kn2.wav", "weapons/cod4/global/kn3.wav"}
})
