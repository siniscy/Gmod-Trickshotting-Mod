---- [ CLIENT SCOREBAR ] ----

-- Populate KC_SD_MatchScores from the sesh team system's round counts.
-- We store the raw round counts and re-key by faction at draw time,
-- so a blank/missing faction at net receive time doesn't lose the score.
KC_SD_MatchScores    = KC_SD_MatchScores    or {}
KC_SD_SeshRoundsA    = KC_SD_SeshRoundsA    or 0   -- player team rounds won
KC_SD_SeshRoundsB    = KC_SD_SeshRoundsB    or 0   -- bot team rounds won

net.Receive("Sesh_TeamScores", function()
    local scoreA  = net.ReadInt(16)
    local scoreB  = net.ReadInt(16)
    local limitA  = net.ReadInt(16)
    local limitB  = net.ReadInt(16)
    local roundsA = net.ReadInt(8)
    local roundsB = net.ReadInt(8)

    -- Store raw values — faction mapping happens at draw time
    KC_SD_SeshRoundsA = roundsA
    KC_SD_SeshRoundsB = roundsB
end)

local function IsSD()
    local cv = GetConVar("codhud_selected_gamemode")
    local gm = cv and cv:GetString() or ""
    return gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

local wasShowingMode = false  -- debug: only print on the false->true transition, not every frame

local function GetScorebarData()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local str  = CoDHUD[CoDHUD_GetHUDType()].TextStrings
    local data = {}

    -- RAW TIME
    local remaining = math.max(0, CoDHUD_RoundEndTime - CurTime())
    data.timeRaw   = remaining
    data.timeAlive = remaining > 0

    -- Hide timer if convar says so — pass 0 so shouldDrawTimer in game files returns false
    if GetConVar("codhud_hide_timer"):GetBool() then
        data.timeRaw = 0
    end

    -- DISPLAY TIME
	local mins     = math.floor(remaining / 60)
	local secs     = math.floor(remaining % 60)
	local baseTime = string.format("%d:%02d", mins, secs)
	if remaining < 30 and remaining > 0 then
		local tenths = math.floor((remaining % 1) * 10)
		data.timeStr = string.format("%s.%d", baseTime, tenths)
	else
		data.timeStr = baseTime
	end
	data.mins = mins

	-- BUILD FACTION SCORE TABLE
	local factionScores = {}

	if IsSD() and KC_SD_SeshRoundsA then
		-- For sesh_sd: build the faction→score map live using current NW2 factions,
		-- so it's always correct regardless of what faction was set at net-receive time.
		local gm2 = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""
		if gm2 == "sesh_sd" or gm2 == "sesh_sd_set" then
			local myFac = ply:GetNW2String("CoDHUD_Faction", "")
			local botFac = nil
			for _, p in ipairs(player.GetAll()) do
				if IsValid(p) and p:IsBot() then
					local f = p:GetNW2String("CoDHUD_Faction", "")
					if f ~= "" and f ~= myFac then botFac = f break end
				end
			end
			-- Build directly from raw round counts — ignore KC_NPC_FactionScores
			-- entirely for sesh_sd (it belongs to normal sd NPC mode only).
			factionScores = {}
			if myFac ~= "" then factionScores[myFac] = KC_SD_SeshRoundsA end
			if botFac then factionScores[botFac] = KC_SD_SeshRoundsB end
		else
			-- Normal sd: use KC_SD_MatchScores + NPC faction scores
			for faction, score in pairs(KC_SD_MatchScores) do
				factionScores[faction] = score
			end
			local myFacN = ply:GetNW2String("CoDHUD_Faction", "")
			if myFacN ~= "" then factionScores[myFacN] = factionScores[myFacN] or 0 end
			if KC_NPC_FactionScores then
				for faction, _ in pairs(KC_NPC_FactionScores) do
					factionScores[faction] = factionScores[faction] or (KC_SD_MatchScores[faction] or 0)
				end
			end
		end
	else
		local gm = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""
		local isFFA = gm == "dm" or gm == "sesh_dm"
		if isFFA then
			local myFaction = ply:GetNW2String("CoDHUD_Faction", "")
			local function getKills(p)
				if gm == "sesh_dm" then return math.max(0, p:GetNWInt("SeshFFA_Kills", 0)) end
				return math.max(0, p:Frags())
			end
			factionScores[myFaction] = getKills(ply)
			local topScore = 0
			for _, p in ipairs(player.GetAll()) do
				if IsValid(p) and p ~= ply then
					local score = getKills(p)
					if score > topScore then topScore = score end
				end
			end
			local enemyKey = "__ffa_enemy__"
			factionScores[enemyKey] = topScore
		else
			-- Non-SD: read player frags
			for _, p in ipairs(player.GetAll()) do
				local f = p:GetNW2String("CoDHUD_Faction", "")
				if f ~= "" then
					factionScores[f] = (factionScores[f] or 0) + math.max(0, p:Frags())
				end
			end
			-- Inject NPC faction scores
			if KC_NPC_FactionScores then
				for faction, score in pairs(KC_NPC_FactionScores) do
					factionScores[faction] = (factionScores[faction] or 0) + score
				end
			end
		end
	end

	-- SORT
	local sortedFactions = {}
	for faction, score in pairs(factionScores) do
		table.insert(sortedFactions, { faction = faction, score = score })
	end
	table.sort(sortedFactions, function(a, b) return a.score > b.score end)

	local myFaction  = ply:GetNW2String("CoDHUD_Faction", "")
	local gm2 = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""
	local isFFA2 = gm2 == "dm" or gm2 == "sesh_dm"
	-- For sesh_dm read individual kills directly
	if gm2 == "sesh_dm" then
		data.clientScore = math.max(0, ply:GetNWInt("SeshFFA_Kills", 0))
	else
		data.clientScore = factionScores[myFaction] or 0
	end

	local enemyFactionData = nil
	if isFFA2 then
		-- For FFA, enemy score is the kill leader (stored under __ffa_enemy__)
		data.enemyScore   = factionScores["__ffa_enemy__"] or 0
		data.enemyFaction = myFaction  -- use same faction so scorebar doesn't crash
	else
		for _, v in ipairs(sortedFactions) do
			if v.faction ~= myFaction then
				enemyFactionData = v
				break
			end
		end
		data.enemyScore   = enemyFactionData and enemyFactionData.score or 0
		data.enemyFaction = enemyFactionData and enemyFactionData.faction or nil
	end

    -- STATUS
    local COL_WINNING = Color(110, 220, 120, 255)
    local COL_LOSING  = Color(215, 110, 120, 255)
    local COL_TIE     = Color(230, 230, 110, 255)
    local COL_GAMEMODE = Color(255, 153, 51, 255)  -- #ff9933

    data.statusText   = str.scorebar.tied or "MW2_MPUI_TIED_CAPS"
    data.statusCol    = COL_TIE
    data.statusLosing = false

    if data.clientScore > data.enemyScore then
        data.statusText   = str.scorebar.winning or "MW2_MPUI_WINNING_CAPS"
        data.statusCol    = COL_WINNING
        data.statusLosing = false
    elseif data.clientScore < data.enemyScore then
        data.statusText   = str.scorebar.losing or "MW2_MPUI_LOSING_CAPS"
        data.statusCol    = COL_LOSING
        data.statusLosing = true
    end

    -- Every 30 seconds, flip to show the gamemode name for 5 seconds.
    -- Uses RealTime() (starts at 0 each map load) so the cycle is predictable.
    -- Cycle: 0-25s = status text, 25-30s = gamemode name
    local cycle    = RealTime() % 30
    local showMode = cycle >= 25

    if showMode then
        -- Find the display name for the current gamemode
        local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
        local gmKey   = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""

        -- Override display names — correct naming and full caps
        local GM_DISPLAY = {
            ["war"]      = "TEAM DEATHMATCH",
            ["dm"]       = "FREE FOR ALL",
            ["sd"]       = "SEARCH AND DESTROY",
            ["sesh_war"] = "GMOD SESH TDM",
            ["sesh_dm"]  = "GMOD SESH FFA",
            ["sesh_sd"]  = "GMOD SESH S&D",
            ["sesh_sd_set"] = "GMOD SESH S&D SET",
        }

        local gmName = GM_DISPLAY[gmKey]
        if not gmName then
            -- Fallback: look up from gamemodes table and uppercase it
            if CoDHUD.Gamemodes and CoDHUD.Gamemodes[hudType] then
                for _, entry in ipairs(CoDHUD.Gamemodes[hudType]) do
                    if entry[2] == gmKey then
                        gmName = string.upper(language.GetPhrase(entry[1]) or entry[1])
                        break
                    end
                end
            end
            gmName = gmName or string.upper(gmKey)
        end

        data.statusText     = gmName
        data.statusResolved = true
        data.statusCol      = COL_GAMEMODE
        data.statusOutline  = 1

        if not wasShowingMode then
            print("[Scorebar DEBUG] Gamemode name cycle shown: gmKey=\"" .. gmKey .. "\" resolved=\"" .. tostring(gmName) .. "\"" .. (gmKey == "" and " -- EMPTY, convar not readable client-side (bug not fixed)" or ""))
        end
    end
    wasShowingMode = showMode

    return data
end

hook.Add("HUDPaint", "CoDHUD_Scorebar", function()
    if (not GetConVar("codhud_enable_scorebar"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    if not GetConVar("cl_drawhud"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].Scorebar then
        local data = GetScorebarData()
        if data then
            CoDHUD[CoDHUD_GetHUDType()].Scorebar(data)
        end
    end
end)