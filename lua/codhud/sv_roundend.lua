---- [ SERVER ROUND END ] ----

local RE_Triggered     = false
local RE_ThinkThrottle = 0

-- codhud_enable_roundend / codhud_enable_roundend_startnext are created in sh_admin.lua (shared realm)

util.AddNetworkString("CoDHUD_FFA_Results")

CoDHUD_RoundEnding = false
CoDHUD_RoundEndTimeSV = nil

-- Builds and broadcasts the FFA top-3 leaderboard from current p:Frags()/
-- NPC_FactionScores. Exposed globally (not just used from CoDHUD_DoRoundEnd
-- below) so sv_ffa_bots.lua can also send it when a BOT reaches the FFA
-- kill limit -- a case that previously never triggered any round-end at all.
function CoDHUD_SendFFALeaderboard()
    -- Build sorted list: players first, then NPC factions
    local entries = {}
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) then
            table.insert(entries, { name = p:Nick(), score = math.max(0, p:Frags()), isPlayer = true, uid = p:UserID() })
        end
    end
    -- Add NPC faction scores
    if NPC_FactionScores then
        for faction, score in pairs(NPC_FactionScores) do
            if score > 0 then
                table.insert(entries, { name = faction, score = score, isPlayer = false, uid = 0 })
            end
        end
    end
    -- With several low-kill bots often tied on score in FFA, a comparator
    -- that only handles a.score > b.score leaves ties in whatever order
    -- table.sort's algorithm happens to leave them -- valid, but not
    -- deterministic, so which tied bot lands in 3rd looked "wrong"/
    -- arbitrary. Break ties by UserID so the result is always the same for
    -- the same match state.
    table.sort(entries, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.uid < b.uid
    end)
    -- Send top 3
    local top = {}
    for i = 1, math.min(3, #entries) do
        top[i] = entries[i]
    end
    net.Start("CoDHUD_FFA_Results")
        net.WriteUInt(#top, 4)
        for _, entry in ipairs(top) do
            net.WriteString(entry.name)
            net.WriteInt(entry.score, 32)
            net.WriteBool(entry.isPlayer)
        end
    net.Broadcast()
end

local function CoDHUD_DoRoundEnd(winnerFaction, loserFaction, winnerScore, loserScore)
    if RE_Triggered then return end
	RE_Triggered = true

    -- For sesh modes, delay the scoreboard so it appears after killcam ends naturally
    local gmCV = GetConVar("codhud_selected_gamemode")
    local isSesh = gmCV and (gmCV:GetString() == "sesh_dm" or gmCV:GetString() == "sesh_war" or gmCV:GetString() == "sesh_sd" or gmCV:GetString() == "sesh_sd_set")
    local delay = isSesh and 0.5 or 0.05

	timer.Simple( delay, function()
		-- For FFA, send personalized win/lose to each player
		local gmCV = GetConVar("codhud_selected_gamemode")
		local isFFA = gmCV and (gmCV:GetString() == "dm" or gmCV:GetString() == "sesh_dm")

		if isFFA then
			-- Send win/lose individually so each player gets correct result
			for _, ply in ipairs(player.GetAll()) do
				if not IsValid(ply) or ply:IsBot() then continue end
				local myFaction = ply:GetNW2String("CoDHUD_Faction", "rangers")
				local didWin = (myFaction == winnerFaction)
				net.Start("CoDHUD_RoundEnd")
					net.WriteString(didWin and myFaction or (loserFaction or myFaction))
					net.WriteString(didWin and (loserFaction or myFaction) or myFaction)
					net.WriteInt(winnerScore or 0, 32)
					net.WriteInt(loserScore or 0, 32)
				net.Send(ply)
			end
		else
			net.Start("CoDHUD_RoundEnd")
				net.WriteString(winnerFaction or "")
				net.WriteString(loserFaction or "")
				net.WriteInt(winnerScore or 0, 32)
				net.WriteInt(loserScore or 0, 32)
			net.Broadcast()
		end

		-- For FFA, send sorted player+NPC leaderboard
		local gmCV = GetConVar("codhud_selected_gamemode")
		if gmCV and (gmCV:GetString() == "dm" or gmCV:GetString() == "sesh_dm") then
			_G.CoDHUD_SendFFALeaderboard()
		end

		CoDHUD_RoundEnding = true

		for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                if ply:Alive() then
                    ply:Freeze(true)
                end
            end
        end
	end)
	
    -- Calculate the approximate center of the map
    local spawns = ents.FindByClass("info_player_start")
    table.Add(spawns, ents.FindByClass("info_player_terrorist"))
    table.Add(spawns, ents.FindByClass("info_player_counterterrorist"))
    if #spawns == 0 then
        for _, p in ipairs(player.GetAll()) do
            table.insert(spawns, p)
        end
    end

    local mapCenter = Vector(0, 0, 0)
    if #spawns > 0 then
        for _, spawn in ipairs(spawns) do
            mapCenter = mapCenter + spawn:GetPos()
        end
        mapCenter = mapCenter / #spawns
    end

    -- Delay the kill and camera placement by 6 seconds
    timer.Simple(6, function()
        for _, ply in ipairs(player.GetAll()) do
            if IsValid(ply) then
                if ply:Alive() then
					ply:Freeze(false)
                    ply:StripWeapons()
                    ply:KillSilent()
                end
                
                ply:Spectate(OBS_MODE_ROAMING)
                
                if #spawns > 0 then
                    local randEnt = spawns[math.random(1, #spawns)]
                    if IsValid(randEnt) then
                        local targetPos = randEnt:GetPos() + Vector(0, 0, 800)
                        local tr = util.TraceLine({
                            start = randEnt:GetPos(),
                            endpos = targetPos,
                            mask = MASK_SOLID_BRUSHONLY
                        })
                        local finalPos = tr.HitPos - Vector(0, 0, 64)
                        ply:SetPos(finalPos)
                        -- GetNormalized() on a zero/near-zero vector produces
                        -- NaN -- with few/no map spawn points this can fall
                        -- back to using player positions as "spawns" (above),
                        -- making mapCenter and finalPos coincide. A NaN angle
                        -- into SetEyeAngles is a hard engine crash.
                        local toCenter = mapCenter - finalPos
                        local dir = toCenter:Length() < 0.01 and Vector(1, 0, 0) or toCenter:GetNormalized()
                        ply:SetEyeAngles(dir:Angle())
                    end
                end
            end
        end
    end)
		
	CoDHUD_RoundEndTimeSV = nil

    -- Wait for the killcam to fully finish before resetting the round.
    -- WaitForKillcamThenRun is defined in killcam_codhud_integration.lua.
    -- Falls back to a direct timer if the function isn't available yet.
    local function DoReset()
        -- For sesh modes, once the MATCH itself is over (not just a mid-match
        -- S&D round), never auto-start another round here -- this function
        -- used to always restart play the instant codhud_enable_roundend_
        -- startnext was true, completely ignoring the "return to lobby, wait
        -- for host to press Start Game" flow that sv_ffa_bots.lua's match-
        -- over cleanup (hook.Run("KC_MatchEnded")) sets up in parallel. That
        -- race is why bots kept respawning immediately even though the
        -- lobby screen had already reopened. sesh_dm (FFA) has no concept of
        -- a mid-match round -- every win ends the match. sesh_sd/sesh_war
        -- both track this via SeshTeam.gameOver.
        local gmSelected = GetConVar("codhud_selected_gamemode"):GetString()
        local seshMatchOver = isSesh and (gmSelected == "sesh_dm" or (_G.SeshTeam and _G.SeshTeam.gameOver))

        if seshMatchOver then
            RE_Triggered = false
            CoDHUD_RoundEnding = false
            return
        end

        if GetConVar("codhud_enable_roundend_startnext"):GetBool() then
            local gamemode   = GetConVar("codhud_selected_gamemode"):GetString()
            local matchtimer = GetConVar("codhud_matchstart_timer"):GetInt()
            local maxtimer   = GetConVar("codhud_time_limit"):GetFloat()

            CoDHUD_FirstBloodOccurred = false

            CoDHUD_RoundStarting = true
            CoDHUD_RoundStartTimer = CurTime() + matchtimer

            timer.Remove("CoDHUD_RoundStartTime")

            if maxtimer > 0 then
                CoDHUD_RoundEndTimeSV = CurTime() + (matchtimer + 1) + (maxtimer * 60)
            end

            for _, p in ipairs(player.GetAll()) do
                if IsValid(p) then
                    p:SetFrags(0)
                    p:SetDeaths(0)
                    p:Spawn()
                    p:Freeze(true)
                end
            end

            net.Start("CoDHUD_RoundStart")
                net.WriteString(gamemode)
                net.WriteInt(matchtimer, 6)
                net.WriteInt(maxtimer, 32)
                net.WriteFloat(CoDHUD_RoundEndTimeSV or 0)
            net.Broadcast()

            timer.Create("CoDHUD_RoundStartTime", matchtimer, 1, function()
                CoDHUD_RoundStarting = false
                CoDHUD_RoundStartTimer = nil
                -- For S&D modes, mark the round as active now that the
                -- countdown has ended and players are free to engage.
                local gm = GetConVar("codhud_selected_gamemode"):GetString()
                if gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set" then
                    SD_RoundActive = true
                    print("[KC SD] CoDHUD_RoundStartTime fired - SD_RoundActive set TRUE, gm=" .. gm)
                end
                for _, p in ipairs(player.GetAll()) do
                    if IsValid(p) then
                        p:Freeze(false)
                        -- For sesh modes restore player weapons after countdown
                        if isSesh and not p:IsBot() and _G.SeshBot_RestoreLoadoutForPlayer then
                            _G.SeshBot_RestoreLoadoutForPlayer(p)
                        end
                    end
                end
            end)
        else
            for _, ply in ipairs(player.GetAll()) do
                if IsValid(ply) then
                    ply:SetFrags(0)
                    ply:UnSpectate()
                    ply:Spawn()
                end
            end
        end
        RE_Triggered = false
        CoDHUD_RoundEnding = false
    end

    if isSesh then
        -- For sesh mode: wait for killcam to finish then reset.
        -- Use WaitForKillcamThenRun if available, otherwise poll manually.
        if WaitForKillcamThenRun then
            WaitForKillcamThenRun(DoReset, 60)
        else
            -- Fallback: poll for killcam end then reset
            local function PollSeshKillcam()
                if GetGlobalBool("Killcam_Playing") then
                    timer.Simple(0.5, PollSeshKillcam)
                else
                    timer.Simple(1, DoReset)
                end
            end
            -- Wait at least 13 seconds (12s killcam delay + 1s buffer) before polling
            timer.Simple(13, PollSeshKillcam)
        end
    elseif WaitForKillcamThenRun then
        WaitForKillcamThenRun(DoReset, 45)
    else
        timer.Simple(8, DoReset)
    end
end

-- Expose globally so sesh bots can trigger round end after killcam
_G.CoDHUD_DoRoundEnd = CoDHUD_DoRoundEnd
_G.CoDHUD_ResetRoundEnd = function() RE_Triggered = false end

hook.Add("Think", "CoDHUD_RoundEnd_ScoreCheck", function()
	if not GetConVar("codhud_enable_roundend"):GetBool() then return end
	-- S&D and Sesh modes all handle their own round end — skip to avoid double firing
	local gmCV = GetConVar("codhud_selected_gamemode")
	if gmCV then
		local gm = gmCV:GetString()
		if gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set" or gm == "sesh_dm" or gm == "sesh_war" then return end
	end

    if RE_Triggered then return end

    local now = CurTime()
    if now < RE_ThinkThrottle then return end
    RE_ThinkThrottle = now + 0.5

    local limitCV = GetConVar("codhud_score_limit")
    if not limitCV then return end

    local scoreLimit = limitCV:GetInt()
    if scoreLimit <= 0 then
        scoreLimit = 75
    end

    local isFFA = gmCV and (gmCV:GetString() == "dm" or gmCV:GetString() == "sesh_dm")
    local factionScores = {}

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if isFFA then
            local gmStr = gmCV and gmCV:GetString() or ""
            if gmStr == "sesh_dm" and ply:IsBot() then continue end
            local score
            if gmStr == "sesh_dm" and SeshBot_PlayerKills then
                score = math.max(0, SeshBot_PlayerKills[ply:UserID()] or 0)
            else
                score = math.max(0, ply:Frags())
            end
            local key = ply:Nick()
            factionScores[key] = score
        else
            -- Skip bots in non-FFA faction totals
            if ply:IsBot() then continue end
            local faction = ply:GetNW2String("CoDHUD_Faction", "")
            if faction == "" then faction = "rangers" end
            local score = math.max(0, ply:Frags())
            factionScores[faction] = (factionScores[faction] or 0) + score
        end
    end

    -- Also add NPC faction scores for non-FFA
    if not isFFA and NPC_FactionScores then
        for faction, score in pairs(NPC_FactionScores) do
            factionScores[faction] = (factionScores[faction] or 0) + score
        end
    end

    local winnerFaction = nil
    local winnerScore = 0

    for faction, score in pairs(factionScores) do
        if score >= scoreLimit then
            winnerFaction = faction
            winnerScore = score
            break
        end
    end

    if not winnerFaction then return end

    local loserFaction = ""
    local loserScore = 0

    for faction, score in pairs(factionScores) do
        if faction ~= winnerFaction and score > loserScore then
            loserFaction = faction
            loserScore = score
        end
    end

    CoDHUD_DoRoundEnd(winnerFaction, loserFaction, winnerScore, loserScore)
end)

hook.Add("Think", "CoDHUD_RoundEnd_TimeLimit", function()
    if not GetConVar("codhud_enable_roundend"):GetBool() then return end
    -- S&D and all Sesh modes handle their own round/match end (via SD_EndRound
    -- or SeshTeam's kill-limit checks in sv_ffa_bots.lua) -- skip here.
    -- sesh_war/sesh_dm were previously missing from this list, so whenever
    -- codhud_time_limit elapsed mid-match (independent of anyone actually
    -- reaching the kill limit), this fired a full generic round-end that
    -- reset SeshTeam's score/round state out from under the sesh match.
    local gmCV = GetConVar("codhud_selected_gamemode")
    if gmCV then
        local gm = gmCV:GetString()
        if gm == "sd" or gm == "sesh_sd" or gm == "sesh_sd_set" or gm == "sesh_war" or gm == "sesh_dm" then return end
    end
    if RE_Triggered then return end
	if not CoDHUD_RoundEndTimeSV then return end
	if CurTime() < CoDHUD_RoundEndTimeSV then return end

    local isFFA2 = gmCV and (gmCV:GetString() == "dm" or gmCV:GetString() == "sesh_dm")
    local factionScores = {}

    for _, ply in ipairs(player.GetAll()) do
        if not IsValid(ply) then continue end
        if isFFA2 then
            local score = math.max(0, ply:Frags())
            local key = ply:IsBot() and ("bot_" .. ply:Nick()) or ply:Nick()
            factionScores[key] = score
        else
            if ply:IsBot() then continue end
            local faction = ply:GetNW2String("CoDHUD_Faction", "rangers")
            local score   = math.max(0, ply:Frags())
            factionScores[faction] = (factionScores[faction] or 0) + score
        end
    end

    local winnerFaction, winnerScore = nil, -1

    for faction, score in pairs(factionScores) do
        if score > winnerScore then
            winnerFaction = faction
            winnerScore = score
        end
    end

    local loserFaction, loserScore = "", 0

    for faction, score in pairs(factionScores) do
        if faction ~= winnerFaction then
            loserFaction = faction
            loserScore = score
            break
        end
    end

    CoDHUD_DoRoundEnd(winnerFaction, loserFaction, winnerScore, loserScore)
end)

hook.Add("PlayerDeathThink", "CoDHUD_RE_PreventRespawn", function(ply)
    if RE_Triggered then return false end
end)