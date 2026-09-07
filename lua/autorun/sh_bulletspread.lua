-- sh_bulletspread.lua
-- Global bullet spread multiplier.
-- FCVAR_REPLICATED requires the convar to be created on both server and client,
-- so this file lives in lua/autorun/ (shared) rather than server/ or client/.
-- Set sv_spread_multiplier to values < 1 to tighten spread, > 1 to widen it.

CreateConVar(
    "sv_spread_multiplier",
    "1",
    FCVAR_ARCHIVE + FCVAR_REPLICATED,
    "Global bullet spread multiplier (1 = default, 0 = no spread)"
)

hook.Add("EntityFireBullets", "GlobalSpreadModifier", function(ent, data)
    local mult = GetConVar("sv_spread_multiplier"):GetFloat()
    if mult == 1 then return end  -- skip when default to avoid unnecessary work
    data.Spread = Vector(
        data.Spread.x * mult,
        data.Spread.y * mult,
        data.Spread.z * mult
    )
    return true, data
end)
