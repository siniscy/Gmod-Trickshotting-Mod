---- [ FAST LAST — TESTING TOOL ] ----
-- Lets the round's first kill happen normally, then immediately jumps the
-- scorer's kill count to one below the limit, so the SECOND kill ends the
-- match. Gives you one real kill (HUD/hitmarker/killfeed) before skipping
-- straight to round-end/killcam testing.
--
-- Supported modes only: war (normal TDM), sesh_war (Sesh TDM). Sesh FFA
-- (sesh_dm) intentionally does NOT support Fast Last.
--
-- Only applies to the listen-server host's own team -- kills by anyone else
-- (other human players, bots) are ignored entirely; Fast Last just keeps
-- waiting for the host's team to score.
--
-- NOTE: for sesh_war, the value that actually ends the round is each
-- player's PERSONAL kill count (SeshBot_PlayerKills, from sv_ffa_bots.lua)
-- checked against codhud_score_limit -- NOT SeshTeam.scoreA / sesh_war_limit.
-- SeshTeam.scoreA is kept in sync alongside it purely so the scorebar
-- doesn't show a stale number.

if not SERVER then return end

CreateConVar("kc_fastlast_enabled", "0", FCVAR_ARCHIVE, "Testing: after the round's first kill (by the host's team), jump the score to one kill from the limit so the next kill ends the round.")

local SUPPORTED_MODES = { war = true, sesh_war = true }

local armed       = false  -- waiting for this round's first kill
local wasStarting = false  -- tracks CoDHUD_RoundStarting true->false transitions
local hostWarned  = false  -- debug: only warn once per arm cycle if no host found
local modeWarnAt  = 0      -- debug: throttle for "enabled but unsupported mode" spam

local function GetHostPlayer()
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and p:IsListenServerHost() then return p end
    end
    return nil
end

local function GetLimit()
    local cv = GetConVar("codhud_score_limit")
    local v = cv and cv:GetInt() or 75
    return v > 0 and v or 75
end

local function ApplyToScorer(gm, scorer)
    local target = GetLimit() - 1

    if gm == "sesh_war" then
        local uid = scorer:UserID()
        if _G.SeshBot_PlayerKills then _G.SeshBot_PlayerKills[uid] = target end
        scorer:SetNWInt("SeshFFA_Kills", target)
        scorer:SetFrags(target)

        if _G.SeshTeam then
            _G.SeshTeam.scoreA = target
            if _G.SeshTeam.BroadcastScores then _G.SeshTeam.BroadcastScores() end
        end
    else -- "war"
        scorer:SetFrags(target)
    end

    print("[FastLast] " .. gm .. ": " .. scorer:Nick() .. " (host's team) jumped to " .. target .. " (next kill ends the round)")
    armed = false
end

-- Returns the host-team human who has a personal kill this round, if any.
local function FindHostTeamScorer(gm, host)
    local hostFaction = host:GetNW2String("CoDHUD_Faction", "")

    if gm == "war" then
        for _, p in ipairs(player.GetAll()) do
            if IsValid(p) and not p:IsBot()
                and p:GetNW2String("CoDHUD_Faction", "") == hostFaction
                and p:Frags() > 0 then
                return p
            end
        end
        return nil
    end

    -- sesh_war
    if not _G.SeshBot_PlayerKills then return nil end
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() and p:GetNW2String("CoDHUD_Faction", "") == hostFaction then
            local kills = _G.SeshBot_PlayerKills[p:UserID()] or 0
            if kills > 0 then return p end
        end
    end
    return nil
end

hook.Add("Think", "KC_FastLast_Watch", function()
    if not GetConVar("kc_fastlast_enabled"):GetBool() then wasStarting = false return end

    local gm = GetConVar("codhud_selected_gamemode"):GetString()
    if not SUPPORTED_MODES[gm] then
        wasStarting = false
        if CurTime() > modeWarnAt then
            modeWarnAt = CurTime() + 5
            print("[FastLast DEBUG] Enabled, but current mode \"" .. tostring(gm) .. "\" is not supported (only war/sesh_war) -- not watching")
        end
        return
    end

    -- Detect the round going live (countdown just ended) -- arm for this round's first kill
    local starting = CoDHUD_RoundStarting and true or false
    if wasStarting and not starting then
        armed      = true
        hostWarned = false
        print("[FastLast DEBUG] Round went live (mode=" .. gm .. ") -- armed, watching for host's team's first kill")
    end
    wasStarting = starting

    if not armed or starting then return end

    local host = GetHostPlayer()
    if not IsValid(host) then
        if not hostWarned then
            hostWarned = true
            print("[FastLast DEBUG] Armed, but no listen-server host found (IsListenServerHost() false for everyone) -- cannot determine host's team")
        end
        return
    end

    local scorer = FindHostTeamScorer(gm, host)
    if scorer then
        ApplyToScorer(gm, scorer)
    end
end)
