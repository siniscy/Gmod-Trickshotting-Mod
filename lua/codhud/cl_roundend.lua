---- [ CLIENT ROUND END ] ----

-- ============================================================
--  Config
-- ============================================================
local CFG = {
    DURATION         = 15.0,
    BW_FADE_TIME     = 1.0,
    MUSIC_DELAY      = 0.0,
    VOICE_DELAY      = 3.0,
	POINTS_DELAY     = 4.0,
	SCOREBOARD_DELAY = 6.0,
    BONUS_X          = 960,
    BONUS_Y          = 720,
    ICON_FADE_TIME   = 1.0,
}

-- ============================================================
--  Match Bonus
-- ============================================================
local function CalcMatchBonus(kills)
    kills = math.Clamp(kills, 0, 75)
    if kills == 0 then return math.random(100, 130) end
    local base = math.floor(100 + (kills / 75) ^ 2 * 2400)
    return math.Clamp(base + math.random(-50, 100), 100, 2500)
end

local function IsSD()
    local cv = GetConVar("codhud_selected_gamemode")
    return cv and cv:GetString() == "sd"
end

local function IsFFA()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "dm" or gm == "sesh_dm"
end

-- ============================================================
--  State
-- ============================================================
local re_active      = false
local re_lock_time   = 0
local re_bw          = 0

_G.CoDHUD_IsRoundEnding = _G.CoDHUD_IsRoundEnding or false

local re_match_bonus = 0

ws_result = ""
ws_limit  = ""

local re_result_glow = Color(255, 255, 255)
local re_mvlock      = false
local re_locked_ang  = nil

-- FFA leaderboard state
local ffa_entries    = nil  -- table of {name, score, isPlayer}

-- ============================================================
--  Helper
-- ============================================================
local function IsKillcamActive()
    return KC_Playing and KC_Playing() or false
end

-- ============================================================
--  Cleanup
-- ============================================================
local function RE_End()
    re_active     = false
    re_mvlock     = false
    re_locked_ang = nil
    re_bw         = 0
    ffa_entries   = nil
    if _G.CoDHUD_ResetScore then _G.CoDHUD_ResetScore() end
    RunConsoleCommand("-showscores")
    timer.Remove("MW2_RE_Music")
    timer.Remove("MW2_RE_Voice")
    timer.Remove("MW2_RE_Board")
    timer.Remove("MW2_RE_Done")
	timer.Remove("CoDHUD_SuspenseTimer")
	_G.CoDHUD_IsRoundEnding = false
end

-- ============================================================
--  FFA Results net receive
-- ============================================================
net.Receive("CoDHUD_FFA_Results", function()
    local count = net.ReadUInt(4)
    ffa_entries = {}
    for i = 1, count do
        ffa_entries[i] = {
            name     = net.ReadString(),
            score    = net.ReadInt(32),
            isPlayer = net.ReadBool(),
        }
    end
end)

-- ============================================================
--  Net receive
-- ============================================================
net.Receive("CoDHUD_RoundEnd", function()
    local winnerFac = net.ReadString()
    local loserFac  = net.ReadString()
    local winnerSc  = net.ReadInt(32)
    local loserSc   = net.ReadInt(32)

	timer.Remove("CoDHUD_SuspenseTimer")

	local hud       = CoDHUD[CoDHUD_GetHUDType()]
	local voicefile = hud and hud.VoiceCallouts or {}
	local str       = CoDHUD[CoDHUD_GetHUDType()].TextStrings

	if _G.CoDHUD_MedalSystem then _G.CoDHUD_MedalSystem.Clear() end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local localFac = ply:GetNW2String("CoDHUD_Faction", "rangers")
    if localFac == "" then localFac = cookie.GetString("CoDHUD_SelectedFaction", "rangers") end

    local kills     = math.max(0, ply:Frags())
    local fdata     = CoDHUD.Factions[CoDHUD_GetHUDType()] and CoDHUD.Factions[CoDHUD_GetHUDType()][localFac]
    local isVictory = (localFac == winnerFac)
    local hasTwo    = (loserFac ~= "" and CoDHUD.Factions[CoDHUD_GetHUDType()] and CoDHUD.Factions[CoDHUD_GetHUDType()][loserFac] ~= nil)

    local now = CurTime()

    re_active      = true
    re_lock_time   = now
    re_bw          = 0
    re_winner      = winnerFac
    re_loser       = loserFac
    re_has_two     = hasTwo
    re_match_bonus = CalcMatchBonus(kills)
    re_mvlock      = true
    re_locked_ang  = nil

	_G.CoDHUD_IsRoundEnding = true

	local teamsMap   = {}

	local gmStr = GetConVar("codhud_selected_gamemode"):GetString()
	local isSesh = (gmStr == "sesh_war" or gmStr == "sesh_sd" or gmStr == "sesh_sd_set")

	-- NOTE: scores here are kept RAW (not multiplied) -- CoDHUD[HUDType].RoundEnd
	-- (re_teams, in each games/*.lua file) applies CoDHUD_GetScoreMultiplier()
	-- itself once these teams are handed to it. Multiplying here too was double-
	-- applying the display multiplier (e.g. TDM's x100 twice), which is why 75
	-- kills was showing as 750,000 instead of 7,500 on the victory screen.
	if isSesh then
		-- For sesh modes use the scores passed directly — already correct kill counts
		if winnerFac ~= "" then
			teamsMap[winnerFac] = { fac = winnerFac, score = winnerSc }
		end
		if loserFac ~= "" then
			teamsMap[loserFac] = { fac = loserFac, score = loserSc }
		end
	else
		for _, p in ipairs(player.GetAll()) do
			local fac = p:GetNW2String("CoDHUD_Faction", "rangers")
			if fac ~= "" then
				teamsMap[fac] = teamsMap[fac] or { fac = fac, score = 0 }
				teamsMap[fac].score = teamsMap[fac].score + math.max(0, p:Frags())
			end
		end

		if KC_NPC_FactionScores then
			for fac, score in pairs(KC_NPC_FactionScores) do
				teamsMap[fac] = teamsMap[fac] or { fac = fac, score = 0 }
				teamsMap[fac].score = teamsMap[fac].score + score
			end
		end
	end

	local teams = {}
	for _, t in pairs(teamsMap) do
		table.insert(teams, t)
	end

	table.sort(teams, function(a, b)
		return (a.score or 0) > (b.score or 0)
	end)

	-- Sesh modes always send an explicit, unambiguous winnerFac -- there is
	-- no such thing as a drawn round/match here (S&D always has a winning
	-- side, TDM/FFA only ever end when someone reaches the limit). Comparing
	-- cumulative round-win/score tallies for a "draw" was wrong for these
	-- modes: e.g. winning a round to tie the match tally 1-1 made this treat
	-- that as a draw even though winnerFac clearly named the round's winner.
	local isDraw = false
	if not isSesh then
		if #teams <= 1 then
			if teams[1] and teams[1].score == 0 then isDraw = true end
		else
			if teams[1].score == teams[2].score then isDraw = true end
		end
	end

	if isDraw or winnerFac == "" then
		ws_result      = str.re.draw or "MW2_MP_DRAW"
		re_result_glow = Color(255, 255, 255)
	elseif isVictory then
		ws_result      = str.re.win or "MW2_MP_VICTORY"
		re_result_glow = Color(0, 220, 80)
	else
		ws_result      = str.re.lose or "MW2_MP_DEFEAT"
		re_result_glow = Color(220, 60, 60)
	end

	ws_result = language.GetPhrase(ws_result)

	local timeLeft = (CoDHUD_RoundEndTime or 0) - CurTime()
	if (CoDHUD_MatchMaxTime > 0) and timeLeft <= 0.1 then
		ws_limit = language.GetPhrase(str.re.result.time or "MW2_MP_TIME_LIMIT_REACHED")
	else
		ws_limit = language.GetPhrase(str.re.result.score or "MW2_MP_SCORE_LIMIT_REACHED")
	end

	timer.Simple(0.1, function() CoDHUD_RoundEndTime = 0 end)

	-- Only call the HUD's team-based RoundEnd if NOT FFA
	if not IsFFA() then
		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].RoundEnd then
			CoDHUD[CoDHUD_GetHUDType()].RoundEnd(teams, ws_result, ws_limit, re_result_glow, CFG)
		end
	end

	timer.Simple(CFG.MUSIC_DELAY, function()
		local theme
		if isDraw then
			theme = voicefile.drawmusic
		else
			theme = "music/" .. CoDHUD_GetHUDType() .. "/" .. (isVictory and fdata.victorytheme or fdata.defeattheme)
		end
		if GetConVar("codhud_enable_music"):GetBool() and theme then
			CoDHUD_PlayAnnouncerSound(theme, true, nil, true)
		end
	end)

	timer.Simple(CFG.VOICE_DELAY, function()
		local voiceline
		if isDraw then
			voiceline = voicefile.missiondraw
		else
			voiceline = isVictory and voicefile.missionwin or voicefile.missionlose
		end
		local sound = CoDHUD_GetAnnouncerSound(voiceline or nil)
		if sound then CoDHUD_PlayAnnouncerSound(sound, false) end
	end)

    timer.Create("MW2_RE_Board", CFG.SCOREBOARD_DELAY, 1, function()
        if re_active and not IsKillcamActive() and not IsSD() then
            RunConsoleCommand("+showscores")
        end
    end)

    timer.Create("MW2_RE_Done", CFG.DURATION, 1, RE_End)

	timer.Simple(CFG.POINTS_DELAY, function()
		if _G.CoDHUD_ResetScore then _G.CoDHUD_ResetScore() end
		timer.Simple(0.05, function()
			if _G.CoDHUD_AddScore then
				local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
				local bonus = re_match_bonus
				-- cod4 and waw xp() divides incoming value by 10 before display
				-- so we pre-divide to match what the "Match Bonus: X" text shows
				if hudType == "cod4" or hudType == "waw" then
					bonus = math.max(1, math.Round(bonus * 0.1))
				end
				_G.CoDHUD_AddScore(bonus)
			end
		end)
	end)
end)

-- ============================================================
--  FFA Leaderboard Draw
-- ============================================================
local function DrawGlowText(text, font, x, y, textCol, glowCol, alignH, alignV)
    for r = 1, 8 do
        local a = math.floor(glowCol.a * math.max(0, 1 - (r / 9)))
        local gc = Color(glowCol.r, glowCol.g, glowCol.b, a)
        for _, o in ipairs({ {-r,0},{r,0},{0,-r},{0,r},{-r,-r},{r,-r},{-r,r},{r,r} }) do
            draw.SimpleText(text, font, x + o[1], y + o[2], gc, alignH, alignV)
        end
    end
    draw.SimpleText(text, font, x, y, textCol, alignH, alignV)
end

local function DrawFFALeaderboard()
    if not ffa_entries or #ffa_entries == 0 then return end

    local cx    = ScrW() / 2
    local baseY = ScrH() * 0.22
    local lineH = CoDHUD_SY(68)
    local white = Color(255, 255, 255, 255)
    local gBlue = Color(80, 140, 255, 60)

    DrawGlowText(ws_result, "MW2_ChalHeader_Pri", cx, baseY, white, gBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    DrawGlowText(ws_limit, "MW2_RS_S_Pri", cx, baseY + CoDHUD_SY(55), white, gBlue, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)

    for i, entry in ipairs(ffa_entries) do
        local y     = baseY + CoDHUD_SY(120) + (i - 1) * lineH
        local label = ({"1st.", "2nd.", "3rd."})[i] or (i .. ".")
        local glow  = (i == 1) and Color(60, 220, 100, 60) or gBlue
        DrawGlowText(label .. " " .. entry.name, "MW2_RS_S_Pri", cx, y, white, glow, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    local bonusY = baseY + CoDHUD_SY(120) + #ffa_entries * lineH + CoDHUD_SY(20)
    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    local displayBonus = re_match_bonus
    if hudType == "cod4" or hudType == "waw" then
        displayBonus = math.max(1, math.Round(re_match_bonus * 0.1))
    end
    draw.SimpleText(string.format(language.GetPhrase("MW2_MP_MATCH_BONUS_IS"), displayBonus), "MW2_RS_S_Pri", cx, bonusY, white, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end

-- ============================================================
--  Think
-- ============================================================
hook.Add("Think", "MW2_RE_Think", function()
    if not re_active then return end
    local now = CurTime()
    re_bw = math.Clamp((now - re_lock_time) / CFG.BW_FADE_TIME, 0, 1)
end)

-- ============================================================
--  CreateMove
-- ============================================================
hook.Add("CreateMove", "MW2_RE_Input", function(cmd)
    if not re_mvlock then return end

    if IsKillcamActive() then
        re_mvlock     = false
        re_locked_ang = nil
        return
    end

    cmd:ClearMovement()
    cmd:RemoveKey(IN_ATTACK)
	cmd:RemoveKey(IN_ATTACK2)
	cmd:RemoveKey(IN_RELOAD)
	cmd:RemoveKey(IN_USE)
	cmd:RemoveKey(IN_JUMP)
	cmd:RemoveKey(IN_DUCK)
	cmd:RemoveKey(IN_SPEED)
	cmd:RemoveKey(IN_WALK)

    if CurTime() >= re_lock_time + 1.3 then
        if not re_locked_ang then re_locked_ang = cmd:GetViewAngles() end
        cmd:SetViewAngles(re_locked_ang)
    end
end)

-- ============================================================
--  HUDShouldDraw — allow killcam HUD during killcam
-- ============================================================
hook.Add("HUDShouldDraw", "MW2_RE_HUD", function(name)
    if not re_active then return end
    if IsKillcamActive() then return end
    if name == "CHudChat" or name == "CHudVoiceSteam" then return end
    return false
end)

-- ============================================================
--  RenderScreenspaceEffects — no greyscale during killcam
-- ============================================================
hook.Add("RenderScreenspaceEffects", "MW2_RE_BW", function()
    if not re_active or re_bw <= 0 then return end
    if IsKillcamActive() then return end
    DrawColorModify({
        ["$pp_colour_addr"]       = 0, ["$pp_colour_addg"]       = 0, ["$pp_colour_addb"] = 0,
        ["$pp_colour_brightness"] = 0, ["$pp_colour_contrast"]   = 1,
        ["$pp_colour_colour"]     = 1 - re_bw,
        ["$pp_colour_mulr"]       = 0, ["$pp_colour_mulg"]       = 0, ["$pp_colour_mulb"] = 0,
    })
end)

-- ============================================================
--  DrawOverlay
-- ============================================================
hook.Add("DrawOverlay", "MW2_RE_Draw", function()
    if not re_active then return end
    if not IsValid(LocalPlayer()) then return end

    -- FFA: draw leaderboard instead of HUD's team-based round end
    if IsFFA() then
        if not IsKillcamActive() then
            DrawFFALeaderboard()
        end
        return
    end

	if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].RoundEndBonus then
		CoDHUD[CoDHUD_GetHUDType()].RoundEndBonus(re_lock_time, re_match_bonus)
	end
end)