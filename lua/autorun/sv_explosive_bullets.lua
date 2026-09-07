-- sv_explosive_bullets.lua
-- Explosive bullets for CoDHUD non-sesh gamemodes.
-- Enabled via "eb_enabled" convar (toggle in CoDHUD Quick Access menu).
-- Blast radius controlled by "eb" convar (0-300, default 25).
-- Automatically disabled during sesh_war / sesh_dm / sesh_sd.

if not SERVER then return end

local function IsSeshMode()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sesh_war" or gm == "sesh_dm" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

hook.Add("KeyPress", "CoDHUD_ExplosiveBullets", function(ply, key)
    if key ~= IN_ATTACK then return end
    if not GetConVar("eb_enabled"):GetBool() then return end
    if IsSeshMode() then return end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep.Base == "weapon_base" then return end
    if not wep:CanPrimaryAttack() then return end
    if CurTime() < wep:GetNextPrimaryFire() then return end

    local tr     = ply:GetEyeTrace()
    local radius = GetConVar("eb"):GetInt()
    if radius <= 0 then return end

    for _, ent in pairs(ents.FindInSphere(tr.HitPos, radius)) do
        if ent:IsNPC() then
            -- Use a damage info with zero force so the NPC dies in place
            -- without being launched — same subtle death as a normal weapon kill.
            local dmginfo = DamageInfo()
            dmginfo:SetDamage(ent:Health())
            dmginfo:SetAttacker(ply)
            dmginfo:SetInflictor(wep)
            dmginfo:SetDamageType(DMG_GENERIC)
            dmginfo:SetDamageForce(Vector(0, 0, 0))
            dmginfo:SetDamagePosition(ent:GetPos())
            ent:TakeDamageInfo(dmginfo)
        end
    end
end)