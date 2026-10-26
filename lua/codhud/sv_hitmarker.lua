---- [ SERVER HITMARKER & XP ] ----

util.AddNetworkString("CoDHUD_HitNotification")

local function IsSeshMode()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

local function Owner(ent)
    if IsValid(ent) and ent:IsWeapon() and IsValid(ent:GetOwner()) then return ent:GetOwner() end
    return ent
end

-- Every hit a real player lands on anything that can fight back -- other
-- players (friends or bots), NPCs, nextbots -- gives that player a
-- hitmarker, host and non-host alike. (The killcam replays these same hits
-- from its own recording, so they show there too.)
hook.Add("PostEntityTakeDamage", "MW2_Server_Hitmarker_Logic", function(target, dmginfo, took)
    local attacker = Owner(dmginfo:GetAttacker())

    if not (took and IsValid(attacker) and attacker:IsPlayer() and attacker ~= target) then return end
    if not IsValid(target) then return end
    local isBot = target.IsNextBot and target:IsNextBot()
    if not (target:IsNPC() or target:IsPlayer() or isBot) then return end

    -- Bots have no screen to show a hitmarker on.
    if attacker:IsBot() then return end

    local isKill = target:Health() <= 0

    if IsSeshMode() then
        -- Sesh: the client turns this into the hitmarker (+ kill XP popup).
        net.Start("KC_HitNotification")
            net.WriteBool(isKill)
        net.Send(attacker)
        return
    end

    -- Normal modes: hitmarker + XP popup.
    net.Start("CoDHUD_HitNotification")
        net.WriteBool(isKill)
        net.WriteInt(isKill and 100 or 10, 32)
    net.Send(attacker)
end)
