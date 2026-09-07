---- [ CLIENT KILLFEED ] ----

-- ==========================================
-- CONFIGURATION & TINKERING
-- ==========================================
local CFG = {
    MAX_MESSAGES = 6,
    LIFETIME = 6,
}

local KillFeed = {}

-- [[ SUPPRESSION OF DEFAULT HUD ]]
hook.Add("HUDShouldDraw", "CoDHUD_Killfeed_HideDefault", function(name)
	if (not GetConVar("codhud_enable_killfeed"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if name == "CHudDeathNotice" then return false end
end)

hook.Add("DrawDeathNotice", "CoDHUD_Killfeed_ForceSuppression", function()
	if (not GetConVar("codhud_enable_killfeed"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    return false
end)

-- [[ NETWORKING ]]
hook.Add("AddDeathNotice", "CoDHUD_Killfeed_Core", function(attacker, team1, inflictor, victim, team2, flags)

    local ct = CurTime()

    local aEnt = IsValid(attacker) and attacker or nil
    local vEnt = IsValid(victim) and victim or nil
	local suicided = nil
	
	local isHeadshot = vEnt and vEnt.CoDHUD_WasHeadshot == true or false -- Doesn't work atm

    -- fallback: try resolving players by name (IMPORTANT)
    if !(aEnt) or isstring(aEnt) then
        aEnt = nil
        for _, ply in player.Iterator() do
            if ply:Nick() == attacker then
                aEnt = ply
                break
            end
        end
    end

    if !(vEnt) or isstring(vEnt) then
        vEnt = nil
        for _, ply in player.Iterator() do
            if ply:Nick() == victim then
                vEnt = ply
                break
            end
        end
    end

	if ( inflictor == "suicide" ) then
		attacker = ""
		suicided = true
	end

    table.insert(KillFeed, {
        type = "kill",

        attackerName = isstring(attacker) and attacker or (IsValid(aEnt) and aEnt:Nick() or "World"),
        victimName   = isstring(victim) and victim or (IsValid(vEnt) and vEnt:Nick() or "Unknown"),

        attackerEnt = aEnt,
        victimEnt = vEnt,

        weaponClass = suicided and "CoDHUD_MW2_Suicide" or inflictor,

        spawnTime = ct,
        dieTime = ct + CFG.LIFETIME,
		isHeadshot = isHeadshot
    })

    if #KillFeed > CFG.MAX_MESSAGES then
        table.remove(KillFeed, 1)
    end

end)

-- Meta Events
gameevent.Listen("player_connect")
hook.Add("player_connect", "CoDHUD_Feed_Join", function(data)
    table.insert(KillFeed, { 
		type = "meta", 
		msg = string.format( language.GetPhrase(CoDHUD[CoDHUD_GetHUDType()].TextStrings.connected or "MW2_MP_CONNECTED"), data.name ), 
		spawnTime = CurTime(), 
		dieTime = CurTime() + CFG.LIFETIME
	})
end)

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "CoDHUD_Feed_Leave", function(data)
    table.insert(KillFeed, {
		type = "meta",
		msg = string.format( language.GetPhrase(CoDHUD[CoDHUD_GetHUDType()].TextStrings.leftgame or "MW2_EXE_LEFTGAME"), data.name ),
		spawnTime = CurTime(),
		dieTime = CurTime() + CFG.LIFETIME
	})
end)

net.Receive("CoDHUD_PlayerAutoBalanced", function()
	local textstr = net.ReadString()
	local plrname = net.ReadString()
	local faction = net.ReadString()
	
	timer.Simple( 0.1, function()
		table.insert(KillFeed, {
			type = "meta",
			msg = string.format( language.GetPhrase(textstr), plrname, language.GetPhrase(faction) ),
			spawnTime = CurTime(),
			dieTime = CurTime() + CFG.LIFETIME
		})
	end)
end)

function CoDHUD_AddKillfeedMessage(textstr, textstr2, textstr3)
    timer.Simple(0.1, function()
        local msg = language.GetPhrase(textstr)
        local textstr2 = textstr2 and language.GetPhrase(textstr2) or ""
        local textstr3 = textstr3 and language.GetPhrase(textstr3) or ""

        if textstr2 ~= "" or textstr3 ~= "" then
            msg = string.format(msg, textstr2, textstr3)
        end

        table.insert( KillFeed, { type = "meta", msg = msg, spawnTime = CurTime(), dieTime = CurTime() + CFG.LIFETIME } )
    end)
end

net.Receive("CoDHUD_KillfeedMessage", function()
    local textstr = net.ReadString()
    local textstr2 = net.ReadString() or ""
    local textstr3 = net.ReadString() or ""
	
    CoDHUD_AddKillfeedMessage(textstr, textstr2, textstr3)
end)

-- timer.Create("CoDHUD_DebugKillfeedSpam", 2, 0, function()
    -- if not GetConVar("codhud_enable_killfeed"):GetBool() then return end

    -- local ct = CurTime()

    -- local testMessages = {
        -- "Player1 connected",
        -- "Player2 left the game",
        -- "TestUser joined",
        -- "Bot42 disconnected",
        -- "Debug message lol",
        -- "Something happened"
    -- }

    -- table.insert(KillFeed, {
        -- type = "meta",
        -- msg = table.Random(testMessages),
        -- spawnTime = ct,
        -- dieTime = ct + CFG.LIFETIME
    -- })
-- end)

-- [[ RENDERING ]]
hook.Add("HUDPaint", "CoDHUD_Killfeed_Draw", function()
    if (not GetConVar("codhud_enable_killfeed"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end

	if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].Killfeed then
		CoDHUD[CoDHUD_GetHUDType()].Killfeed(KillFeed, CFG)
	end
end)