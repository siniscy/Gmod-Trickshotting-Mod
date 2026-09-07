---- [ CLIENT DAMAGE INDICATOR, AUDIO & VISUAL ] ----

if CLIENT then
    local matDamage = Material("icons/hit_direction.png", "mips smooth")
    local attackers = {}

-- [[ SUPPRESS DEFAULT GMOD DAMAGE INDICATOR ]]
    hook.Add("HUDShouldDraw", "CoDHUD_SuppressDefaultDamage", function(name)
        if name == "CHudDamageIndicator" then
            return false
        end
    end)
	
    -- SURGICAL FIX: We listen to the SERVER now. 
    -- This guarantees we get the correct NPC/Player entity every time.
    net.Receive("CoDHUD_Damage_Update", function()
        local ent = net.ReadEntity()
        if not IsValid(ent) then return end

        local ply = LocalPlayer()
        local curTime = CurTime()

        -- GWZ Stability Logic: Point far away in the direction of the threat
        -- This prevents the "jitter" when enemies are close.
        local incomingPos = ent:GetPos() + (ply:GetPos() - ent:GetPos()) * -33000

        -- Update existing indicator or create new one
        local found = false
        for _, v in ipairs(attackers) do
            if v.ent == ent then
                v.time = curTime + 4
                v.alpha = 255
                v.trackPos = incomingPos -- Update tracking spot
                found = true
                break
            end
        end

        if not found then
            table.insert(attackers, {
                ent = ent,
                trackPos = incomingPos,
                alpha = 255,
                time = curTime + 4
            })
        end
    end)

    hook.Add("HUDPaint", "CoDHUD_DrawDamageIndicators_Pro", function()
        local ply = LocalPlayer()
        if not IsValid(ply) or not ply:Alive() then 
            if #attackers > 0 then table.Empty(attackers) end
            return 
        end

		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].DamageDirection then
			CoDHUD[CoDHUD_GetHUDType()].DamageDirection(attackers, ply)
		end
    end)
end