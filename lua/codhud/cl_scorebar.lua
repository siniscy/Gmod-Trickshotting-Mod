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

-- Exposed globally (not just local) so other systems -- e.g. the ported
-- Advanced HUD's health/armor slots repurposed as team-score readouts --
-- can reuse this exact score computation (round wins for S&D, kills
-- everywhere else) instead of duplicating it.
function CoDHUD_GetScorebarData()
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
			--
			-- botFac above is ONLY used to pick the enemy bar's faction-specific
			-- texture/icon (each game HUD falls back to a generic bar if the key
			-- doesn't resolve to a real faction, see e.g. waw.lua's enemybar
			-- lookup). It must NOT gate whether the enemy's round-win NUMBER
			-- shows at all: a reported bug had the bottom-left round-win bar
			-- stuck at 0 for the team that just won a round (right after a
			-- round loss, the round-end freeze/killcam/spectate state can leave
			-- no bot passing this scan for a frame or more) even though the tab
			-- scoreboard -- which doesn't require finding a live bot to attach
			-- KC_SD_SeshRoundsB to -- showed the correct count the whole time.
			-- Always key the enemy's score in, using a synthetic fallback key
			-- when no live bot is found, so it's never silently dropped from
			-- factionScores (and this fix lives here, in the single shared
			-- CoDHUD_GetScorebarData(), so every per-game HUD file that reads
			-- data.clientScore/data.enemyScore gets it, not just one HUD).
			factionScores = {}
			if myFac ~= "" then factionScores[myFac] = KC_SD_SeshRoundsA end
			factionScores[botFac or "__sd_enemy__"] = KC_SD_SeshRoundsB
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

	-- Diagnostic for a reported non-host-only S&D scorebar fill bug --
	-- print the raw inputs feeding the bar fill whenever any of them
	-- change, so a mismatch between what two clients compute can be
	-- compared directly instead of guessing from a single screenshot.
	if IsSD() then
		local cv_rounds = GetConVar("sesh_sd_rounds")
		local sig = table.concat({
			tostring(myFaction), tostring(data.enemyFaction),
			tostring(KC_SD_SeshRoundsA), tostring(KC_SD_SeshRoundsB),
			tostring(data.clientScore), tostring(data.enemyScore),
			tostring(cv_rounds and cv_rounds:GetInt()),
		}, "|")
		if sig ~= CoDHUD_SDBarLastSig then
			CoDHUD_SDBarLastSig = sig
			print("[SD Bar RAW] myFaction=" .. tostring(myFaction) ..
				" enemyFaction=" .. tostring(data.enemyFaction) ..
				" SeshRoundsA=" .. tostring(KC_SD_SeshRoundsA) ..
				" SeshRoundsB=" .. tostring(KC_SD_SeshRoundsB) ..
				" clientScore=" .. tostring(data.clientScore) ..
				" enemyScore=" .. tostring(data.enemyScore) ..
				" sesh_sd_rounds=" .. tostring(cv_rounds and cv_rounds:GetInt()) ..
				" on " .. (IsValid(ply) and ply:Nick() or "?"))
		end
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

        -- Override display names — correct naming and full caps. Phrase
        -- keys live in codhud_system.properties as CoDHUD.ScorebarGM.<key>.
        local GM_DISPLAY_KEYS = {
            ["war"]      = "CoDHUD.ScorebarGM.war",
            ["dm"]       = "CoDHUD.ScorebarGM.dm",
            ["sd"]       = "CoDHUD.ScorebarGM.sd",
            ["sesh_war"] = "CoDHUD.ScorebarGM.sesh_war",
            ["sesh_dm"]  = "CoDHUD.ScorebarGM.sesh_dm",
            ["sesh_sd"]  = "CoDHUD.ScorebarGM.sesh_sd",
            ["sesh_sd_set"] = "CoDHUD.ScorebarGM.sesh_sd_set",
        }

        local gmName = GM_DISPLAY_KEYS[gmKey] and language.GetPhrase(GM_DISPLAY_KEYS[gmKey])
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
        local data = CoDHUD_GetScorebarData()
        if data then
            CoDHUD[CoDHUD_GetHUDType()].Scorebar(data)
        end
    end
end)