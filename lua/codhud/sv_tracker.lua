---- [ SERVER DAMAGE, STAT AND HITMARKER TRACKER ] ----

util.AddNetworkString("CoDHUD_Damage_Update")
util.AddNetworkString("CoDHUD_Hitmarker")
util.AddNetworkString("CoDHUD_RequestFactionChange")

-- We use PostEntityTakeDamage to ensure we only track real, confirmed damage
hook.Add("PostEntityTakeDamage", "CoDHUD_Server_Track_Attacker", function(target, dmginfo, took)
    if not IsValid(target) or not target:IsPlayer() or not took then return end
    if dmginfo:GetDamage() <= 0 then return end
    
    -- Filter out fall damage
    if dmginfo:IsFallDamage() then return end

    local attacker = dmginfo:GetAttacker()
    local inflictor = dmginfo:GetInflictor()

    -- LOGIC: Prioritize the Inflictor (Rocket/Grenade) if it exists and isn't a generic weapon.
    -- If it's a standard gun, track the Attacker (NPC/Player).
    local entToSend = attacker

    if IsValid(inflictor) and inflictor ~= attacker and inflictor ~= target then
        -- If it's a grenade or rocket, track THAT object, not the guy who threw it
        if not inflictor:IsWeapon() then
            entToSend = inflictor
        end
    end

    -- If the attacker is the world or invalid, don't send anything
    if not IsValid(entToSend) or entToSend == target then return end

    net.Start("CoDHUD_Damage_Update")
        net.WriteEntity(entToSend)
    net.Send(target)
end)

net.Receive("CoDHUD_RequestFactionChange", function(len, ply)
    if not IsValid(ply) then return end

    local faction = net.ReadString() or ""
    local hudType = CoDHUD_GetHUDType()

    if not CoDHUD.Factions[hudType] or not CoDHUD.Factions[hudType][faction] then
        return
    end

	if not CoDHUD.Factions.CanPlayerChooseFaction(ply, faction) then
		print("[CoDHUD] Blocked faction change for", ply:Nick(), "->", faction)
		net.Start("CoDHUD_KillfeedMessage")
		net.WriteString("CoDHUD.System.Faction.NotNow")
		net.Send(ply)
		return
	end

    -- store faction
	ply.CoDHUD_StoredFaction = faction
	ply:SetNW2String("CoDHUD_Faction", faction)

    -- reset SCORE CONTRIBUTION (important distinction)
    -- Option A: reset frags
    ply:SetFrags(0)
    -- ply:SetDeaths(0)

    -- force death + respawn
    if ply:Alive() then
        ply:KillSilent()
    end

    timer.Simple(0.1, function()
        if IsValid(ply) then
            ply:Spawn()
        end
    end)
	
	print("[CoDHUD] " .. ply:Nick() .. " changed teams to " .. CoDHUD.Factions.GetFactionName(faction))
	
	local textstr = "MW2_GAME_CHANGEDTO"
	local factionName = CoDHUD.Factions[CoDHUD_GetHUDType()][faction].name

	net.Start("CoDHUD_PlayerAutoBalanced")
	net.WriteString(textstr)
	net.WriteString(ply:Nick())
	net.WriteString(factionName)
	net.Broadcast()
end)