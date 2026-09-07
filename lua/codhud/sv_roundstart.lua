---- [ SERVER ROUND START ] ----

util.AddNetworkString("CoDHUD_StartRound")
util.AddNetworkString("CoDHUD_RoundStart")
util.AddNetworkString("CoDHUD_SetGamemode")
util.AddNetworkString("CoDHUD_SetAutoFaction")
util.AddNetworkString("CoDHUD_RestrictFactionChange")
util.AddNetworkString("CoDHUD_SyncFactionPool")

-- codhud_selected_gamemode / codhud_autobalance_on_roundstart are created in sh_admin.lua
-- (shared realm) -- they must exist client-side too or non-host clients never receive the
-- replicated value at all (GetConVar returns nil for them, permanently, not just briefly).

CoDHUD_RoundStarting = false
CoDHUD_RoundStartTimer = nil

-- The listen-server host should always be able to pick a gamemode and start
-- a match, on every map, regardless of whether a separate admin mod happens
-- to have flagged them as IsAdmin() for that particular map/session --
-- IsListenServerHost() is tied purely to being the player who launched the
-- server, not any admin mod's own (possibly per-map) permission state.
-- Third fallback: if you're the only real human connected (solo testing
-- with bots), there's no one else it could possibly be -- treat that as
-- host too, so this never depends on IsListenServerHost()/IsAdmin()
-- actually succeeding. Mirrors cl_lobby.lua's isHost check.
local function IsHostOrAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsListenServerHost() or ply:IsAdmin() then return true end
    local realPlayers = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then realPlayers = realPlayers + 1 end
    end
    return realPlayers <= 1
end

net.Receive("CoDHUD_SetGamemode", function(len, ply)
    if not IsHostOrAdmin(ply) then return end

    local gm = net.ReadString()

    RunConsoleCommand("codhud_selected_gamemode", gm)
end)

net.Receive("CoDHUD_SetAutoFaction", function(len, ply)
    if not IsValid(ply) or not ply:IsAdmin() then return end

    local val = net.ReadString()

    RunConsoleCommand("codhud_autofaction_limit", val)
end)

net.Receive("CoDHUD_StartRound", function(len, ply)
    if not IsHostOrAdmin(ply) then return end

	if CoDHUD_RoundEnding then return end

	-- Close the pre-game lobby (sv_lobby.lua) now that the host is starting a round.
	if KC_Lobby_SetActive then KC_Lobby_SetActive(false) end

    local gamemode = GetConVar("codhud_selected_gamemode"):GetString()
    local matchtimer = GetConVar("codhud_matchstart_timer"):GetInt()
    local maxtimer = GetConVar("codhud_time_limit"):GetFloat()

	if maxtimer > 0 then
		CoDHUD_RoundEndTimeSV = CurTime() + (matchtimer + 1) + (maxtimer * 60)
	else
		CoDHUD_RoundEndTimeSV = nil
	end
	
	CoDHUD_FirstBloodOccurred = false

	CoDHUD_RoundStarting = true
	CoDHUD_RoundStartTimer = CurTime() + matchtimer

	timer.Remove("CoDHUD_RoundStartTime")
	
	if GetConVar("codhud_autobalance_on_roundstart"):GetBool() then
		CoDHUD.Factions.RebuildPool()
		
		net.Start("CoDHUD_SyncFactionPool")
		net.WriteTable(CoDHUD.Factions.ActivePool or {})
		net.Broadcast()
		
		local players = player.GetAll()
		table.Shuffle(players)

		local counts = {}

		for _, ply in ipairs(players) do
			-- Sesh bots' faction is exclusively owned by sv_ffa_bots.lua (always
			-- the opposing team from the human) -- this generic human-team-
			-- balancing pool must never touch them, or a bot can land on the
			-- same faction as the player, merging the scoreboard into one team.
			if IsValid(ply) and not ply:IsBot() then
				local faction = CoDHUD.Factions.PickFromPool(counts)

				counts[faction] = (counts[faction] or 0) + 1

				ply.CoDHUD_StoredFaction = faction
				ply:SetNW2String("CoDHUD_Faction", faction)

				print("[CoDHUD] (Round Start) " .. ply:Nick() .. " -> " .. faction)
			end
		end
		
		timer.Simple( 0.1, function()
			for _, p in ipairs(player.GetAll()) do
				p:SetFrags(0)
				p:SetDeaths(0)
				p:Spawn()
				p:Freeze(true)
			end

			net.Start("CoDHUD_RoundStart")
				net.WriteString(gamemode)
				net.WriteInt(matchtimer, 6)
				net.WriteInt(maxtimer, 32)
				net.WriteFloat(CoDHUD_RoundEndTimeSV or 0) -- NEW
			net.Broadcast()
		end)

		timer.Create("CoDHUD_RoundStartTime", matchtimer > 0 and matchtimer or 0.15, 1, function()

			CoDHUD_RoundStarting = false
			CoDHUD_RoundStartTimer = nil

			for _, p in ipairs(player.GetAll()) do
				if IsValid(p) then
					p:Freeze(false)
				end
			end
		end)

		return
	end

    for _, p in ipairs(player.GetAll()) do
        p:SetFrags(0)
        p:SetDeaths(0)
        p:Spawn()
		p:Freeze(true)
    end

	timer.Create("CoDHUD_RoundStartTime", matchtimer, 1, function()

		CoDHUD_RoundStarting = false
		CoDHUD_RoundStartTimer = nil

		for _, p in ipairs(player.GetAll()) do
			if IsValid(p) then
				p:Freeze(false)
			end
		end
	end)

	net.Start("CoDHUD_RoundStart")
		net.WriteString(gamemode)
		net.WriteInt(matchtimer, 6)
		net.WriteInt(maxtimer, 32)
		net.WriteFloat(CoDHUD_RoundEndTimeSV or 0) -- NEW
	net.Broadcast()
end)