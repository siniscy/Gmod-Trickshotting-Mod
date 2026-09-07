---- [ SERVER MEDALS ] ----

if SERVER then
    -- Register all Network Strings
    util.AddNetworkString("CoDHUD_Medal_Headshot")
    util.AddNetworkString("CoDHUD_Medal_DoubleKill")
    util.AddNetworkString("CoDHUD_Medal_TripleKill")
    util.AddNetworkString("CoDHUD_Medal_MultiKill")
    util.AddNetworkString("CoDHUD_Medal_Longshot")
    util.AddNetworkString("CoDHUD_Medal_OneShot")
    util.AddNetworkString("CoDHUD_Medal_FirstBlood")
    util.AddNetworkString("CoDHUD_Medal_Comeback")
    util.AddNetworkString("CoDHUD_Medal_Payback")

    -- Track Headshots
    local function MarkHeadshot(ent, hitgroup, dmginfo)
        if not IsValid(ent) then return end
        if hitgroup == HITGROUP_HEAD then
            ent.WasHeadshotByMW2 = true
        end
    end
    hook.Add("ScaleNPCDamage", "CoDHUD_MarkHeadshotNPC", MarkHeadshot)
    hook.Add("ScalePlayerDamage", "CoDHUD_MarkHeadshotPlayer", MarkHeadshot)

    -- Capture damage data for One Shot Kill logic
    hook.Add("EntityTakeDamage", "CoDHUD_CaptureLastDamage", function(target, dmginfo)
        if not IsValid(target) then return end
        target.LastMW2DmgData = {
            health = target:Health(),
            damage = dmginfo:GetDamage(),
            isExplosion = dmginfo:IsExplosionDamage(),
            type = dmginfo:GetDamageType()
        }
    end)

    local function CoDHUD_CheckMedals(victim, attacker)
        if not IsValid(attacker) or not attacker:IsPlayer() or attacker == victim then return end

        -- 1. FIRST BLOOD (Only triggers on the first kill of the round/map)
        if not CoDHUD_FirstBloodOccurred then
            net.Start("CoDHUD_Medal_FirstBlood")
            net.Send(attacker)
            CoDHUD_FirstBloodOccurred = true
        end

        -- 2. PAYBACK (Revenge on the person who last killed you)
        if attacker.codhud_LastKiller == victim then
            net.Start("CoDHUD_Medal_Payback")
            net.Send(attacker)
            attacker.codhud_LastKiller = nil -- Revenge complete
        end

        -- 3. COMEBACK (Getting a kill after a death streak of 3+)
        attacker.codhud_DeathStreak = attacker.codhud_DeathStreak or 0
        if attacker.codhud_DeathStreak >= 3 then
            net.Start("CoDHUD_Medal_Comeback")
            net.Send(attacker)
        end
        attacker.codhud_DeathStreak = 0 -- Streak broken by getting a kill

        -- 4. HEADSHOT
        if victim.WasHeadshotByMW2 then
            net.Start("CoDHUD_Medal_Headshot")
            net.Send(attacker)
            victim.WasHeadshotByMW2 = false 
        end

        -- 5. LONGSHOT (Distance based)
        local dist = attacker:GetPos():Distance(victim:GetPos())
        if dist > 1200 then
            net.Start("CoDHUD_Medal_Longshot")
            net.Send(attacker)
        end

        -- 6. ONE SHOT KILL
        local dData = victim.LastMW2DmgData
        if dData then
            local maxHP = victim:GetMaxHealth()
            -- Check if one hit dealt >= Max Health and health was >= Max Health and wasn't melee (DMG_GENERIC only, DMG_CLUB, DMG_SLASH) or explosion
            if not dData.isExplosion and not (dData.type == 0 or bit.band(dData.type, DMG_CLUB+DMG_SLASH) ~= 0) and dData.damage >= maxHP and dData.health >= maxHP then
                net.Start("CoDHUD_Medal_OneShot")
                net.Send(attacker)
            end
            victim.LastMW2DmgData = nil 
        end

		-- 7. MULTI-KILLS (Delayed evaluation)
		local delay = 1.5
		attacker.codhud_KillCount = attacker.codhud_KillCount or 0

		-- Increment kills
		attacker.codhud_KillCount = attacker.codhud_KillCount + 1

		-- Unique timer name per player
		local timerName = "CoDHUD_MultiKillTimer_" .. attacker:EntIndex()

		-- Reset timer every kill
		timer.Remove(timerName)

		timer.Create(timerName, delay, 1, function()
			if not IsValid(attacker) then return end

			local count = attacker.codhud_KillCount or 0

			if count == 2 then
				net.Start("CoDHUD_Medal_DoubleKill")
				net.Send(attacker)

			elseif count == 3 then
				net.Start("CoDHUD_Medal_TripleKill")
				net.Send(attacker)

			elseif count >= 4 then
				net.Start("CoDHUD_Medal_MultiKill")
				net.Send(attacker)
			end

			-- Reset after evaluation
			attacker.codhud_KillCount = 0
		end)
    end

    -- Hook for Player Deaths
    hook.Add("PlayerDeath", "CoDHUD_Medal_PlayerDeath", function(victim, inflictor, attacker)
        -- Track death streak for the victim
        victim.codhud_DeathStreak = (victim.codhud_DeathStreak or 0) + 1
        
        -- Track who killed the victim for Payback logic
        if IsValid(attacker) and attacker:IsPlayer() and attacker ~= victim then
            victim.codhud_LastKiller = attacker
        end

        CoDHUD_CheckMedals(victim, attacker)
    end)

    -- Hook for NPC Deaths
    hook.Add("OnNPCKilled", "CoDHUD_Medal_NPCDeath", function(npc, attacker, inflictor)
        CoDHUD_CheckMedals(npc, attacker)
    end)
    
    -- Reset First Blood when the map is cleaned up or round resets
    hook.Add("PostCleanupMap", "CoDHUD_ResetFirstBlood", function()
        CoDHUD_FirstBloodOccurred = false
    end)
end