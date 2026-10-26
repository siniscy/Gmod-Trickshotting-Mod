---- [ SERVER: THIRD-PERSON WEAPON HOLD FIX (GENERIC) ] ----
-- Other players are seen holding some weapons wrong (floating away from
-- the hands, wrong grip) while stock HL2 weapons always look correct.
-- The difference is SWEP.HoldType: it picks which ACT_HL2MP_IDLE_*
-- animation set + hand attachment the carrying player's THIRD-PERSON
-- model uses. Every stock HL2 weapon declares a real, recognized
-- holdtype. A custom SWEP that never sets one, or sets a made-up string
-- the engine doesn't recognize, falls back to a generic single-hand grip
-- that doesn't match a two-handed weapon's geometry -- the dangling,
-- off-axis look.
--
-- This can't be fixed perfectly for an arbitrary unknown SWEP -- the
-- correct fix is per-weapon (matching its actual model/animation rig),
-- which needs that weapon's own code. What this does instead is a safety
-- net: only weapons whose declared holdtype ISN'T one of the engine's
-- recognized set get corrected, guessed from their class/printname via
-- simple keyword matching, defaulting to "ar2" (a generic two-handed
-- rifle grip) when nothing matches -- better than the broken fallback in
-- every case, even if not always the exact right grip. Any weapon that
-- already declares a valid holdtype (all stock HL2 weapons included) is
-- left completely untouched.
--
-- Set server-side (not client-side) because HoldType is a networked
-- weapon field the engine replicates to every client authoritatively --
-- a client-side override would just get stomped by the next network
-- update instead of actually fixing what other clients see.
if not SERVER then return end

local VALID_HOLDTYPES = {
    ["ar2"] = true, ["crossbow"] = true, ["fist"] = true, ["grenade"] = true,
    ["knife"] = true, ["magic"] = true, ["melee"] = true, ["melee2"] = true,
    ["normal"] = true, ["passive"] = true, ["physgun"] = true, ["pistol"] = true,
    ["revolver"] = true, ["rpg"] = true, ["shotgun"] = true, ["slam"] = true,
    ["smg"] = true, ["camera"] = true, ["duel"] = true, ["civilian"] = true,
}

-- Order matters: checked top to bottom, first match wins.
local GUESS_RULES = {
    { "rpg", "launcher", "bazooka", "panzerschreck" },
    { "crossbow" },
    { "revolver", "magnum", "deagle" },
    { "pistol", "glock", "usp", "beretta", "colt1911", "fiveseven", "p226", "makarov" },
    { "shotgun", "spas", "remington", "m870", "aa12", "saiga" },
    { "smg", "mp5", "mp7", "mp9", "mac10", "mac11", "ump", "vector", "p90", "bizon" },
    { "knife", "machete", "karambit", "bayonet" },
    { "grenade" },
    { "crowbar", "bat", "axe", "hammer", "melee", "stunstick" },
}
local GUESS_HOLDTYPE = {
    "rpg", "crossbow", "revolver", "pistol", "shotgun", "smg", "knife", "grenade", "melee",
}

local function GuessHoldType(wep)
    local haystack = (wep:GetClass() .. " " .. (wep.PrintName or "")):lower()
    for i, keywords in ipairs(GUESS_RULES) do
        for _, kw in ipairs(keywords) do
            if haystack:find(kw, 1, true) then
                return GUESS_HOLDTYPE[i]
            end
        end
    end
    -- No keyword matched -- default to a generic two-handed rifle grip.
    -- Most unrecognized custom weapons (rifles, snipers, LMGs) are closer
    -- to this than to any one-handed pose.
    return "ar2"
end

-- Re-checked every Think rather than fixed once and cached: some weapon
-- bases re-apply their own (invalid) SWEP.HoldType on every Deploy(), which
-- would silently undo a one-time fix next time the weapon is holstered and
-- drawn again. GetHoldType() is cheap, and once corrected the guessed value
-- is itself always in VALID_HOLDTYPES, so this is a no-op write every tick
-- after the first -- it only ever touches the network var when something is
-- actually still invalid.
hook.Add("Think", "KC_ThirdpersonHoldtypeFix", function()
    for _, ply in pairs(player.GetAll()) do
        local wep = ply:GetActiveWeapon()
        if not IsValid(wep) then continue end
        if VALID_HOLDTYPES[wep:GetHoldType()] then continue end
        wep:SetHoldType(GuessHoldType(wep))
    end
end)
