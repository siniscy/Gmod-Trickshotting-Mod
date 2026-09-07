---- [ SERVER HITMARKER & XP ] ----

util.AddNetworkString("CoDHUD_HitNotification")

local function IsSeshMode()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

hook.Add("PostEntityTakeDamage", "MW2_Server_Hitmarker_Logic", function(target, dmginfo, took)
    local attacker = dmginfo:GetAttacker()

    if not (took and IsValid(attacker) and attacker:IsPlayer() and attacker ~= target) then return end
    if not (target:IsNPC() or target:IsPlayer() or target:IsNextBot()) then return end

    -- Attacker must be a real human
    if attacker:IsBot() then return end

    local isKill = IsValid(target) and (
        (target:IsPlayer() and target:Health() <= 0) or
        (target:IsNPC() and target:Health() <= 0)
    )

    -- SESH MODE: real human hitting a bot → send KC_HitNotification
    if IsSeshMode() then
        if target:IsPlayer() and target:IsBot() then
            net.Start("KC_HitNotification")
                net.WriteBool(isKill)
            net.Send(attacker)
        end
        return
    end

    -- NORMAL MODE: NPC or player hit → CoDHUD_HitNotification (handles XP display)
    -- Also send KC_HitNotification so hitmarker shows during killcam
    if not target:IsPlayer() and not target:IsNPC() then return end
    if target:IsPlayer() and target:IsBot() then return end
    if target:IsPlayer() and target:GetNWBool("FFA_IsBot", false) then return end

    if _G.CoDHUD_GiveXP then
        _G.CoDHUD_GiveXP(attacker, isKill and 100 or 10)
    end

    -- Primary notification (shows XP popup via base CoDHUD)
    net.Start("CoDHUD_HitNotification")
        net.WriteBool(isKill)
        net.WriteInt(isKill and 100 or 10, 32)
    net.Send(attacker)

    -- Secondary: also send KC_HitNotification so hitmarker works during killcam
    net.Start("KC_HitNotification")
        net.WriteBool(isKill)
    net.Send(attacker)
end)