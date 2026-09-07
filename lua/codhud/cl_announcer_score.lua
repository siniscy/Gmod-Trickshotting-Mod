---- [ CLIENT ANNOUNCER CALLOUTS ] ----

local LastScoreState = "tied"
local NearEndTriggered = false
local MusicTriggered = false
CoDHUD_HadAbove60 = CoDHUD_HadAbove60 or false
CoDHUD_HadAbove30 = CoDHUD_HadAbove30 or false
CoDHUD_LowTimeTriggered = CoDHUD_LowTimeTriggered or false
CoDHUD_TimerLastPlay = CoDHUD_TimerLastPlay or 0
CoDHUD_ActiveTimerTier = CoDHUD_ActiveTimerTier or nil

local function IsSD()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv and cv:GetString() == "sd"
end

local function CoDHUD_GetFactionScores(ply)
    local lpFaction = ply:GetNW2String("CoDHUD_Faction", "")
    if lpFaction == "" then
        lpFaction = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
    end

    local factionScores = {}

    for _, p in ipairs(player.GetAll()) do
        local faction = p:GetNW2String("CoDHUD_Faction", "")
        if faction == "" then
            faction = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
        end

        local score = math.max(0, p:Frags())
        factionScores[faction] = (factionScores[faction] or 0) + score
    end

    local myScore = factionScores[lpFaction] or 0

    local bestEnemyScore = 0
    for faction, score in pairs(factionScores) do
        if faction ~= lpFaction and score > bestEnemyScore then
            bestEnemyScore = score
        end
    end

    return myScore, bestEnemyScore, lpFaction
end

hook.Add("Think", "CoDHUD_Announcer_Score_Think", function()
    if IsSD() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local hudType = CoDHUD_GetHUDType()
    if not CoDHUD or not hudType or not CoDHUD[hudType] then return end

    local voicefile = CoDHUD[hudType].VoiceCallouts
    if not voicefile then return end

    local currentFaction = ply:GetNW2String("CoDHUD_Faction", "")
    if currentFaction == "" then
        currentFaction = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
    end

    if not CoDHUD.Factions[CoDHUD_GetHUDType()] or not CoDHUD.Factions[CoDHUD_GetHUDType()][currentFaction] then return end

    local myScore, bestEnemyScore = CoDHUD_GetFactionScores(ply)

    -- Reset logic for new rounds
    if myScore == 0 and bestEnemyScore == 0 then
        LastScoreState = "tied"
        NearEndTriggered = false
        MusicTriggered = false
        return
    end

    local limit
    local gmCV3 = GetConVar("codhud_selected_gamemode")
    if gmCV3 and gmCV3:GetString() == "sesh_dm" then
        -- Sesh FFA has its own hardwired limit, independent of codhud_score_limit
        limit = (hudType == "cod4") and 25 or 30
    else
        limit = GetConVar("codhud_score_limit"):GetInt()
        if not limit or limit <= 0 then limit = 75 end
    end

    -- Music only (no voice announcer for score state or near end)
    if not MusicTriggered then
        if (limit - myScore) <= (limit * 0.25) and myScore > 0 then
            MusicTriggered = true
            CoDHUD_PlayAnnouncerSound(voicefile.winningmusic, true)
        elseif (limit - bestEnemyScore) <= (limit * 0.25) and bestEnemyScore > 0 then
            MusicTriggered = true
            CoDHUD_PlayAnnouncerSound(voicefile.losingmusic, true)
        end
    end

    -- Track score state for reset purposes only (no voice lines)
    local currentState = "tied"
    if myScore > bestEnemyScore then
        currentState = "winning"
    elseif myScore < bestEnemyScore then
        currentState = "losing"
    end
    LastScoreState = currentState
end)

hook.Add("Think", "CoDHUD_Announcer_Time_Think", function()
    if IsSD() then return end
    if _G.CoDHUD_IsRoundEnding then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    local hudType = CoDHUD_GetHUDType()
    if not CoDHUD or not hudType or not CoDHUD[hudType] then return end

    local voicefile = CoDHUD[hudType].VoiceCallouts
    if not voicefile then return end

    local timeLeft = (CoDHUD_RoundEndTime or 0) - CurTime()
    local matchTime = CoDHUD_MatchMaxTime or 0
    local timeAnnouncersEnabled = (matchTime > 0)
    local has60Callout = (matchTime > 60)

    if not timeAnnouncersEnabled then return end

    -- 60 second threshold: music only, no voice
    if has60Callout and timeLeft >= 60 then
        CoDHUD_HadAbove60 = true
    end

    if has60Callout and CoDHUD_HadAbove60 and timeLeft < 60 then
        CoDHUD_HadAbove60 = false
        timer.Remove("CoDHUD_SuspenseTimer")

        local myScore, bestEnemyScore = CoDHUD_GetFactionScores(ply)

        if not MusicTriggered then
            if myScore > bestEnemyScore then
                if voicefile.winningmusic then
                    MusicTriggered = true
                    CoDHUD_PlayAnnouncerSound(voicefile.winningmusic, true)
                end
            else
                if voicefile.losingmusic then
                    MusicTriggered = true
                    CoDHUD_PlayAnnouncerSound(voicefile.losingmusic, true)
                end
            end
        end
        -- No voice line played (removed winningfight/losingfight callout)
    end

    -- 30 second threshold: no voice
    if timeLeft >= 30 then
        CoDHUD_HadAbove30 = true
        CoDHUD_LowTimeTriggered = false
    end

    if CoDHUD_HadAbove30 and timeLeft < 30 and not CoDHUD_LowTimeTriggered then
        CoDHUD_LowTimeTriggered = true
        CoDHUD_HadAbove30 = false
        timer.Remove("CoDHUD_SuspenseTimer")
        -- No voice line played (removed lowtime callout)
    end
end)

hook.Add("Think", "CoDHUD_Timer_Tick", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local hudtype = CoDHUD_GetHUDType()
    local timerData = CoDHUD[hudtype] and CoDHUD[hudtype].Timer
    if not timerData or not timerData.sound then return end

    local timeLeft = (CoDHUD_RoundEndTime or 0) - CurTime()
    if timeLeft <= 0 then return end

    local now = CurTime()

    local activeThreshold = nil
    local activeInterval = nil

    for threshold, interval in pairs(timerData.timings or {}) do
        if timeLeft <= threshold then
            if not activeThreshold or threshold < activeThreshold then
                activeThreshold = threshold
                activeInterval = interval
            end
        end
    end

    if not activeThreshold then return end

    if CoDHUD_ActiveTimerTier ~= activeThreshold then
        CoDHUD_ActiveTimerTier = activeThreshold
        CoDHUD_TimerLastPlay = 0
    end

    if (now - CoDHUD_TimerLastPlay) >= activeInterval then
        CoDHUD_TimerLastPlay = now
        surface.PlaySound(timerData.sound)
    end
end)
