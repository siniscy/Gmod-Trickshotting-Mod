CoDHUD.RegisterHUD( "bo2", "#CoDHUD.Type.bo2", true )

local hudtype = "bo2"

CoDHUD = CoDHUD or {}
CoDHUD[hudtype] = CoDHUD[hudtype] or {}
CoDHUD.Factions = CoDHUD.Factions or {}
CoDHUD.Gamemodes = CoDHUD.Gamemodes or {}

local textype = {
	"hud/bo2/cp_fill.LN65.pc.snd.mp3",
}

-- [[ SPECIAL KILLFEED ICONS ]]
if CLIENT then
	killicon.Add("CoDHUD_BO2_Suicide", hudtype .. "/killfeed/death_suicide.png", Color(255, 255, 255, 0))
	killicon.Add("CoDHUD_BO2_Headshot", hudtype .. "/killfeed/death_headshot.png", Color(255, 255, 255, 0))
end

-- [[ SUSPENSE ]]
CoDHUD[hudtype].SuspenseTracks = {
	"music/bo2/underscores/2m01_myanmar_squirreljump_v1_mp_loop.SL65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_5m01_no_vox_no_sitar.SN65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_5m05_no_vox.SN65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_14m04_no_orch.SN65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_14m06a_no_orch.SN65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_14m09a_master.SN65.pc.snd.mp3",
	"music/bo2/underscores/mus_mp_underscore_14m09b_no_strings.SN65.pc.snd.mp3",
}

-- [[ FACTIONS ]]
CoDHUD.Factions[hudtype] = {
	["seals"] = {
		name = "BO2_MP_SEALS_NAME",
		short = "BO2_MPUI_SEALS_SHORT",
		voicepath = "st6/vox_st6_",
		spawntheme = "spawn/mus_mp_spawn_00.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_00_short.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_seals.vtf",
		scoreIcon = hudtype .. "/factions/faction_seals.vtf",
		color = Color(116, 158, 182),
		killfeedcol = Color(116, 158, 182),
		glow = Color(116, 158, 182),
		order = 1
	},
	["sdc"] = {
		name = "BO2_MP_PLA_NAME",
		short = "BO2_MPUI_PLA_SHORT",
		voicepath = "pla/vox_pla_",
		spawntheme = "spawn/mus_mp_spawn_03.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_03_short.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_pla.vtf",
		scoreIcon = hudtype .. "/factions/faction_pla.vtf",
		color = Color(167, 14, 16),
		killfeedcol = Color(167, 14, 16),
		glow = Color(167, 14, 16),
		order = 2
	},
	["fbi"] = {
		name = "BO2_MP_FBI_NAME",
		short = "BO2_MPUI_FBI_SHORT",
		voicepath = "fbi/vox_fbi_",
		spawntheme = "spawn/mus_mp_spawn_06.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_06_short.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_fbi.vtf",
		scoreIcon = hudtype .. "/factions/faction_fbi.vtf",
		color = Color(16, 208, 221),
		killfeedcol = Color(16, 208, 221),
		glow = Color(16, 208, 221),
		order = 3
	},
	["pmc"] = {
		name = "BO2_MP_PMC_NAME",
		short = "BO2_MPUI_PMC_SHORT",
		voicepath = "pmc/vox_pmc_",
		spawntheme = "spawn/mus_mp_spawn_02.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_02_short.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_pmc.vtf",
		scoreIcon = hudtype .. "/factions/faction_pmc.vtf",
		color = Color(252, 163, 11),
		killfeedcol = Color(252, 163, 11),
		glow = Color(252, 163, 11),
		order = 4
	},
	["isa"] = {
		name = "BO2_MP_ISA_NAME",
		short = "BO2_MPUI_ISA_SHORT",
		voicepath = "isa/vox_isa_",
		spawntheme = "spawn/mus_mp_spawn_cia_20sec.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_cia_10sec.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_isa.vtf",
		scoreIcon = hudtype .. "/factions/faction_isa.vtf",
		color = Color(84, 149, 115),
		killfeedcol = Color(84, 149, 115),
		glow = Color(84, 149, 115),
		order = 5
	},
	["cd"] = {
		name = "BO2_MP_CD_NAME",
		short = "BO2_MPUI_CD_SHORT",
		voicepath = "cia/vox_cda_",
		spawntheme = "spawn/mus_mp_spawn_05.SN65.pc.snd.mp3",
		victorytheme = "spawn/mus_mp_spawn_05_short.SN65.pc.snd.mp3",
		defeattheme = "loss/mus_loss_00.SN65.pc.snd.mp3",
		spawnIcon = hudtype .. "/factions/faction_cd.vtf",
		scoreIcon = hudtype .. "/factions/faction_cd.vtf",
		color = Color(239, 237, 134),
		killfeedcol = Color(239, 237, 134),
		glow = Color(239, 237, 134),
		order = 6
	},
}

-- [[ TEXT STRINGS & VOICE CALLOUTS ]]
CoDHUD[hudtype].TextStrings = {
	connected = "MW2_MP_CONNECTED",
	disconnected = "MW2_MP_DISCONNECTED",
	leftgame = "MW2_EXE_LEFTGAME",
	re = {
		draw = "MW2_MP_DRAW",
		win = "MW2_MP_VICTORY",
		lose = "MW2_MP_DEFEAT",
		result = {
			score = "MW2_MP_SCORE_LIMIT_REACHED",
			time = "MW2_MP_TIME_LIMIT_REACHED"
		}
	},
	scorebar = {
		tied = "BO1_MENU_TIED_CAPS",
		winning = "BO1_MENU_WINNING_CAPS",
		losing = "BO1_MENU_LOSING_CAPS"
	},
}

CoDHUD[hudtype].VoiceCallouts = {
	winningmusic = "music/bo2/timers/mus_mp_timer_00.SN65.pc.snd.mp3",
	losingmusic = "music/bo2/timers/mus_mp_timer_01.SN65.pc.snd.mp3",
	drawmusic = "music/bo2/draw/mus_draw_00.SN65.pc.snd.mp3",
	winningfight = "winning",
	losingfight = "losing",
	lowtime = "timesup",
	leadtaken = "lead_taken",
	leadlost = "lead_lost",
	missionwin = "mission_success",
	missionlose = "mission_fail",
	missiondraw = "draw",
}

CoDHUD[hudtype].Timer = {
	sound = "hud/bo2/timer_00.LN65.pc.snd.mp3",
	timings = {
		[30] = 2,
		[10] = 1
	}
}

local function GetFactionColor(ent)
    if not IsValid(ent) then return Color(255,255,255) end
    local faction = ent:GetNW2String("CoDHUD_Faction", "seals")
    if CoDHUD.Factions[hudtype][faction] and CoDHUD.Factions[hudtype][faction].killfeedcol then
		return CoDHUD.Factions[hudtype][faction].killfeedcol
	end
    return Color(255,255,255)
end

-- [[ GAMEMODES ]]
CoDHUD.Gamemodes[hudtype] = {
	{ "#MW2_MPUI_WAR", "war" },
	{ "#MW2_MPUI_DEATHMATCH", "dm" },
	{ "#MW2_MPUI_SEARCH_AND_DESTROY", "sd" },
	{ "Gmod Sesh TDM", "sesh_war" },
	{ "Gmod Sesh FFA", "sesh_dm" },
	{ "Gmod Sesh S&D", "sesh_sd" },
	{ "Gmod Sesh S&D Set", "sesh_sd_set" },
}

CoDHUD.Gamemodes[hudtype].Names = {
    war = "MW2_MPUI_WAR",
    dm  = "MW2_MPUI_DEATHMATCH",
}

CoDHUD.Gamemodes[hudtype].Hints = {
    ["war"]      = "BO1_OBJECTIVES_TDM_HINT",
    ["dm"]       = "BO1_OBJECTIVES_DM_HINT",
    ["sd"]       = "BO1_OBJECTIVES_SD_ATTACKER_HINT",
    ["sesh_war"] = "BO1_OBJECTIVES_TDM_HINT",
    ["sesh_dm"]  = "BO1_OBJECTIVES_DM_HINT",
    ["sesh_sd"]  = "BO1_OBJECTIVES_SD_ATTACKER_HINT",
    ["sesh_sd_set"] = "BO1_OBJECTIVES_SD_ATTACKER_HINT",
}

CoDHUD.Gamemodes[hudtype].Callouts = {
    ["war"]      = "tdm_start",
    ["dm"]       = "ffa_start",
    ["sd"]       = "sd_start",
    ["sesh_war"] = "tdm_start",
    ["sesh_dm"]  = "ffa_start",
    ["sesh_sd"]  = "sd_start",
    ["sesh_sd_set"] = "sd_start",
}

CoDHUD.Gamemodes[hudtype].Boosts = {
    ["war"]      = "generic_boost",
    ["dm"]       = "generic_boost",
    ["sd"]       = "destroy_start",
    ["sesh_war"] = "generic_boost",
    ["sesh_dm"]  = "generic_boost",
    ["sesh_sd"]  = "destroy_start",
    ["sesh_sd_set"] = "destroy_start",
}

-- [[ HELPERS ]]
local function DrawSqueezedScore(val, x, y, alpha)
	local textCol   = Color(255, 255, 255, alpha)
	local shadowCol = Color(0, 0, 0, alpha * 0.8)
	local s_val     = tostring(val)
	local partPlus  = "+"
	surface.SetFont("BO2_Score_Plus")
	local wP  = surface.GetTextSize(partPlus)
	local gapPlus = CoDHUD_SX(0)
	surface.SetFont("BO2_Score_Main")
	local totalW = wP + gapPlus
	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = surface.GetTextSize(char)
		totalW = totalW + w
	end
	local curX = x - (totalW / 2)
	local function DrawComponent(txt, font, px, py)
		draw.SimpleTextOutlined(txt, font, px, py, textCol, 0, 1, 0, shadowCol)
		surface.SetFont(font)
		local w = surface.GetTextSize(txt)
		return w
	end
	local runX = curX
	runX = runX + DrawComponent(partPlus, "BO2_Score_Plus", runX, y) + gapPlus
	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = DrawComponent(char, "BO2_Score_Main", runX, y)
		if i < #s_val then runX = runX + w end
	end
end

local function DrawSqueezedText(text, font, x, y, color, squeeze, squeezeOne, align, squeezeOneBefore, outlineW, outlineCol)
    local str = tostring(text)
    surface.SetFont(font)
    local totalW = 0
    for i = 1, #str do
        local char     = str:sub(i, i)
        local nextChar = str:sub(i + 1, i + 1)
        local w = surface.GetTextSize(char)
        totalW = totalW + w
        if i < #str then
            local gap = (char == "1") and squeezeOne or (nextChar == "1" and squeezeOneBefore or squeeze)
            totalW = totalW + gap
        end
    end
    local runX = (align == 1) and (x - totalW/2) or (align == 2 and x or x - totalW)
    for i = 1, #str do
        local char     = str:sub(i, i)
        local nextChar = str:sub(i + 1, i + 1)
        local o        = outlineW or 0
        local outlineCol = outlineCol or Color(0, 0, 0, color.a)
		draw.SimpleTextOutlined( char, font, runX, y, color, 0, 0, o, outlineCol )
        local w = surface.GetTextSize(char)
        if i < #str then
            local gap = (char == "1") and squeezeOne or (nextChar == "1" and squeezeOneBefore or squeeze)
            runX = runX + w + gap
        end
    end
end

-- [[ HUD ELEMENTS ]]
CoDHUD[hudtype].MedalsBlockChallenges = true

local function settingsmenu( ... )
	local w = select(1, ...)
	local h = select(2, ...)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial( Material( "bo2/settings/menu_mp_soldiers.png" ) )
	surface.DrawTexturedRect(0, 0, w, h)
end
CoDHUD[hudtype].SettingsMenu = settingsmenu

local function challengecomplete( ... )
    local header = select(1, ...)
    local level = select(2, ...)
    local sub = select(3, ...)
	local subval = select(4, ...)
    local align = select(5, ...)
	local function ResolvePrefix(prefix, text)
		if not prefix or prefix == "" then return text end
		if string.find(text, " ") then return language.GetPhrase(text) end
		if subval then
			return string.format( language.GetPhrase(prefix .. text), subval )
		else
			return language.GetPhrase(prefix .. text)
		end
	end
    CoDHUD_HeaderQueue.Push({
		type = "bo_challenge",
        text = CoDHUD_ChallengeTitle(header, level),
        subtext = (sub and sub ~= "") and ResolvePrefix("MW2_CHALLENGE_", sub) or nil,
        x = CoDHUD_SX(960),
        y = CoDHUD_SY(125),
		holdTime = 2.5,
        color = Color(0,0,0),
        fonts = {
            pri = "BO2_ChalHeader",
            sub = "BO2_ChalSub",
        },
    })
    surface.PlaySound("hud/bo2/award.SN65.pc.snd.mp3")
end
CoDHUD[hudtype].ChallengeComplete = challengecomplete

local function rs_obj( ... )
	local text = select(1, ...)
	CoDHUD_HeaderQueue.Push({
		type = "bo",
		writeSounds = textype,
		writeSpeed = 8,
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(170),
		color = Color(0, 0, 0),
		fonts = {
			pri = "BO2_RS_O_Pri",
			sec = "BO2_RS_O_Sec",
			shd = "BO2_RS_O_Shd"
		}
	})
end
CoDHUD[hudtype].RoundStartObjective = rs_obj

local function rs_title( ... )
	local text = select(1, ...)
	local glow = select(2, ...)
	local logo = select(3, ...)
	CoDHUD_HeaderQueue.Push({
		type = "bo",
		writeSounds = textype,
		writeSpeed = 8,
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(50),
		color = Color(0,0,0),
		iconY = CoDHUD_SY(80),
		iconSize = CoDHUD_S(134),
		fonts = {
			pri = "BO2_RS_H_Pri",
			sec = "BO2_RS_H_Sec",
			shd = "BO2_RS_H_Shd"
		},
		icon = logo
	})
end
CoDHUD[hudtype].RoundStart = rs_title

local function rs_timer( ... )
	local disp = select(1, ...)
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local tx  = CoDHUD_SX(960)
    local ty  = ScrH() * 0.5
    local syo = CoDHUD_SY(-85)
	if disp ~= rs_last_dig then
		rs_last_dig  = disp
		rs_dig_scale = 1.8
	end
	rs_dig_scale = math.Approach(rs_dig_scale, 1, FrameTime() * 6)
	if disp > 0 then
		local tMat = Matrix()
		tMat:Translate(Vector(tx, ty, 0))
		tMat:Scale(Vector(rs_dig_scale, rs_dig_scale, 1))
		tMat:Translate(Vector(-tx, -ty, 0))
		cam.PushModelMatrix(tMat)
			draw.SimpleTextOutlined( disp, "BO2_RS_Timer", tx, ty, Color(255,255,100), 1, 1, outlined and 1 or 0, Color(0,0,0) )
		cam.PopModelMatrix()
		draw.SimpleTextOutlined( "#BO1_MP_MATCH_STARTING_IN", "BO2_RS_S_Pri", tx, ty + syo, Color(255,255,255), 1, 1, outlined and 1 or 0, Color(0,0,0) )
	end
end
CoDHUD[hudtype].RoundStartTimer = rs_timer

local function re_teams( ... )
    local teams = select(1, ...)
    local ws_result = select(2, ...)
    local ws_limit = select(3, ...)
    local re_result_glow = select(4, ...)
    local CFG = select(5, ...)

    local multiplier = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100

    local scaledTeams = {}
    for k, v in ipairs(teams) do
        scaledTeams[k] = {
            fac = v.fac,
            score = (v.score or 0) * multiplier
        }
    end

    CoDHUD_HeaderQueue.Push({
		type = "bo",
        teams = scaledTeams,
		writeSounds = textype,
		writeSpeed = 8,
        x = CoDHUD_SX(960),
        y = CoDHUD_SY(400),
        multiple = true,
        persist = true,
        endTime = CFG.SCOREBOARD_DELAY,
        iconSize = CoDHUD_S(184),
        iconGap  = CoDHUD_S(80),
        scoreY = CoDHUD_SY(620),
        fonts = {
            pri = "BO2_RE_Sc_Pri",
            sec = "BO2_RE_Sc_Sec",
            shd = "BO2_RE_Sc_Shd",
        }
    })

	CoDHUD_HeaderQueue.Push({
		type = "bo",
		text = ws_result,
		writeSounds = textype,
		writeSpeed = 8,
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(240),
		color = re_result_glow,
		multiple = true,
		skipErase = true,
		persist = true,
		endTime = CFG.SCOREBOARD_DELAY,
		fonts = {
			pri = "BO2_RE_Re_Pri",
			sec = "BO2_RE_Re_Sec",
			shd = "BO2_RE_Re_Shd",
			sub = "BO2_ChalSub"
		}
	})

	CoDHUD_HeaderQueue.Push({
		type = "bo",
		text = ws_limit,
		writeSounds = textype,
		writeSpeed = 8,
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(330),
		color = Color(135, 135, 180),
		multiple = true,
		skipErase = true,
		persist = true,
		endTime = CFG.SCOREBOARD_DELAY,
		fonts = {
			pri = "BO2_RE_Li_Pri",
			sec = "BO2_RE_Li_Sec",
			shd = "BO2_RE_Li_Shd",
		}
	})
end
CoDHUD[hudtype].RoundEnd = re_teams

local function re_bonus( ... )
	local re_lock_time = select(1, ...)
	local re_match_bonus = select(2, ...)
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local el = CurTime() - re_lock_time
    if el < 0 then return end
    if el >= 6.0 then return end
    local iconAlpha = math.floor(math.Clamp(el / 1.0, 0, 1) * 255)

	-- Real BO2 draws "Match Bonus:" in white and the number + "XP" in
	-- its gold accent colour, not the whole line in one flat colour.
	local phrase = language.GetPhrase("MW2_MP_MATCH_BONUS_IS")
	local prefix, suffix = phrase:match("^(.-)%%s(.*)$")
	prefix = prefix or phrase
	suffix = suffix or ""
	local valueTxt = tostring(re_match_bonus) .. " XP" .. suffix

	local whiteCol  = Color(255, 255, 255, iconAlpha)
	local goldCol   = Color(255, 199, 0, iconAlpha)
	local shadowCol = Color(0, 0, 0, iconAlpha)
	local y = CoDHUD_SY(720)

	surface.SetFont("BO2_RE_Bonus")
	local pw = surface.GetTextSize(prefix)
	local vw = surface.GetTextSize(valueTxt)
	local startX = ScrW() * 0.5 - (pw + vw) / 2

	draw.SimpleTextOutlined( prefix, "BO2_RE_Bonus", startX, y, whiteCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, outlined and 1 or 0, shadowCol )
	draw.SimpleTextOutlined( valueTxt, "BO2_RE_Bonus", startX + pw, y, goldCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, outlined and 1 or 0, shadowCol )
end
CoDHUD[hudtype].RoundEndBonus = re_bonus

local function hitmarker( ... )
	local hitTime = select(1, ...)
	local ct = CurTime()
	local cx, cy = ScrW() / 2, ScrH() / 2
	local matHit = Material(hudtype .. "/icons/damage_feedback.png", "mips smooth")
	local fade = math.Clamp((hitTime - ct) / 0.9, 0, 1) * 255
	surface.SetMaterial(matHit)
	surface.SetDrawColor(255, 255, 255, fade)
	local size = 36
	surface.DrawTexturedRect(cx - (size / 2), cy - (size / 2), size, size)
end
CoDHUD[hudtype].Hitmarker = hitmarker

-- Ported from the original mini_dm_gamemode addon -- the simplified
-- rewrite that was here dropped the animated background flash chip
-- entirely (intro white flash -> fade to a soft lavender chip -> hold
-- -> exit fade) and drew bare floating text in a different screen
-- position instead. Score values themselves are untouched either way.
local function xp( ... )
	local animtime          = select(1, ...)
	local scoreTime         = select(2, ...)
	local finalAlpha        = select(3, ...)
	local scoreScale        = select(4, ...)
	local currentPulseAlpha = select(5, ...)
	local scoreVal          = select(6, ...)

	local cx, cy = ScrW() / 2, ScrH() / 2
	local drawX  = cx + CoDHUD_SY(90)
	local drawY  = cy - CoDHUD_SY(90)

	-- BO2 TIMINGS
	local bgIntroTime   = 0.13
	local textDelay     = 0.01
	local textIntroTime = 0.03

	local holdStart = bgIntroTime + textDelay + textIntroTime

	-- sync with existing fade system
	local remaining = math.max(scoreTime - CurTime(), 0)
	local fadeFrac = math.Clamp(remaining / 0.3, 0, 1)
	local isExiting = remaining <= 0.3

	-- VISUAL STATE
	local bgAlpha     = 0
	local bgColorLerp = 0
	local textAlpha   = 0

	-- INTRO: WHITE BG FLASH
	if animtime <= bgIntroTime then
		local p = math.Clamp(animtime / bgIntroTime, 0, 1)
		bgAlpha = Lerp(p, 255, 110)
		bgColorLerp = p
	-- TEXT INTRO
	elseif animtime <= holdStart then
		bgAlpha = 110
		bgColorLerp = 1
		local p = math.Clamp( (animtime - (bgIntroTime + textDelay)) / textIntroTime, 0, 1 )
		textAlpha = Lerp(p, 0, 255)
	-- HOLD
	elseif not isExiting then
		bgAlpha = 110
		bgColorLerp = 1
		textAlpha = 255
	-- EXIT
	else
		textAlpha = 0
		bgColorLerp = 0
		bgAlpha = 255 * fadeFrac
	end

	-- COLORS
	local flashColor = Color(175, 175, 225)
	local drawBgCol = Color(
		Lerp(bgColorLerp, 255, flashColor.r),
		Lerp(bgColorLerp, 255, flashColor.g),
		Lerp(bgColorLerp, 255, flashColor.b),
		bgAlpha * (finalAlpha / 255)
	)
	local drawTextAlpha = textAlpha * (currentPulseAlpha / 255) * (finalAlpha / 255)

	-- SIZE
	surface.SetFont("BO2_Score_Main")
	local txt = "+" .. tostring(scoreVal)
	local tw, th = surface.GetTextSize(txt)
	local padX = CoDHUD_SX(12)
	local padY = CoDHUD_SY(12)
	local bw = tw + padX * 2
	local bh = th + padY * 2

	-- BACKING
	surface.SetMaterial( Material( hudtype .. "/hud/fade_team.vmt" ) )
	surface.SetDrawColor(drawBgCol)
	surface.DrawTexturedRect( drawX - bw * 1, drawY - bh * 1, bw * 2, bh * 2 )

	-- TEXT
	DrawSqueezedScore( scoreVal, drawX, drawY, drawTextAlpha )
end
CoDHUD[hudtype].XP = xp

local function dmg_dir( ... )
	local attackers = select(1, ...)
	local ply = select(2, ...)
    local cx, cy = ScrW() / 2, ScrH() / 2
	local matDamage = Material(hudtype .. "/icons/hitdirection")
	for i = #attackers, 1, -1 do
		local v = attackers[i]
		if CurTime() > v.time - 1 then
			v.alpha = math.Approach(v.alpha, 0, FrameTime() * 400)
			if v.alpha <= 0 then table.remove(attackers, i) continue end
		end
		local targetWorldPos = v.trackPos
		if IsValid(v.ent) then
			targetWorldPos = v.ent:GetPos() + (ply:GetPos() - v.ent:GetPos()) * -33000
		end
		local localPos = ply:WorldToLocal(targetWorldPos)
		local dirVecX = localPos.x
		local dirVecY = -localPos.y
		local screenAngleRad = math.atan2(dirVecX, dirVecY)
		local orbitRadius = 280
		local px = cx + math.cos(screenAngleRad) * orbitRadius
		local py = cy - math.sin(screenAngleRad) * orbitRadius
		local rotation = math.deg(screenAngleRad) + 270
		surface.SetMaterial(matDamage)
		surface.SetDrawColor(255, 255, 255, v.alpha)
		surface.DrawTexturedRectRotated(px, py, 180, 90, rotation)
	end
end
CoDHUD[hudtype].DamageDirection = dmg_dir

local function grenade_dir( ... )
	local showIcon = select(1, ...)
	local nearEnts = select(2, ...)
	local ply = select(3, ...)
    local cx, cy = ScrW() / 2, ScrH() / 2
	local matIcon = Material(hudtype .. "/icons/grenadeicon.png", "mips smooth")
	local matPointer = Material(hudtype .. "/icons/grenadepointer.png", "mips smooth")
    for _, ent in ipairs(nearEnts) do
        if not CoDHUD_IsGrenade(ent) then continue end
        local localPos = ply:WorldToLocal(ent:GetPos())
        local dirVecX = localPos.x
        local dirVecY = -localPos.y
        local screenAngleRad = math.atan2(dirVecX, dirVecY)
        local screenAngleDeg = math.deg(screenAngleRad)
        local ringRadius = 150
        local px = cx + math.cos(screenAngleRad) * ringRadius
        local py = cy - math.sin(screenAngleRad) * ringRadius
        local pointerRadius = ringRadius + 40
        local ptrX = cx + math.cos(screenAngleRad) * pointerRadius
        local ptrY = cy - math.sin(screenAngleRad) * pointerRadius
        surface.SetDrawColor(255, 255, 255, 255)
        if matPointer and not matPointer:IsError() then
            surface.SetMaterial(matPointer)
            surface.DrawTexturedRectRotated(ptrX, ptrY, 70, 35, screenAngleDeg + 270)
        end
        if showIcon then
            if matIcon and not matIcon:IsError() then
                surface.SetMaterial(matIcon)
                surface.DrawTexturedRectRotated(px, py, 50, 50, 0)
            end
        end
    end
end
CoDHUD[hudtype].GrenadeIndicator = grenade_dir

local function killfeed( ... )
	local KillFeed = select(1, ...)
    ANIM_TIME = 0.25
    ANIM_RISE = 15
    local cx, cy = ScrW() / 2, ScrH() / 2
	local ct = CurTime()
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local xPos = CoDHUD_S(10)
    local yPos = CoDHUD_S(260)
    local spacing = CoDHUD_S(36)
    local iconW = CoDHUD_S(32)
    local iconH = CoDHUD_S(32)
    local baseY = ScrH() - yPos
    for i = #KillFeed, 1, -1 do
        local data = KillFeed[i]
        local age = ct - data.spawnTime
        local timeLeft = data.dieTime - ct
		local ICON_BOX_W = iconW
		local ICON_BOX_H = iconH
        if timeLeft <= 0 then table.remove(KillFeed, i) continue end
        local animProgress = math.Clamp(age / ANIM_TIME, 0, 1)
        local fadeFactor = 1
        if age < ANIM_TIME then fadeFactor = animProgress
        elseif timeLeft < 1 then fadeFactor = math.Clamp(timeLeft, 0, 1) end
        local yOffset = (1 - animProgress) * CoDHUD_S(ANIM_RISE)
		local currentY = baseY - ((#KillFeed - i) * spacing) + yOffset
        local x = xPos
        local finalTxtAlpha = 155 * fadeFactor
        surface.SetFont("BO2_KillfeedFont")
		local aColBase = GetFactionColor(data.attackerEnt)
		local vColBase = GetFactionColor(data.victimEnt)
		local aCol = Color(aColBase.r, aColBase.g, aColBase.b, finalTxtAlpha)
		local vCol = Color(vColBase.r, vColBase.g, vColBase.b, finalTxtAlpha)
        if data.type == "kill" then
			local cls = data.isHeadshot and "CoDHUD_BO2_Headshot" or data.weaponClass
			local w, h = killicon.GetSize(cls)
			if not w or w <= 0 then w = ICON_BOX_W end
			if not h or h <= 0 then h = ICON_BOX_H end
			local gap = CoDHUD_S(10)
			if data.attackerName != "" then
				draw.SimpleText(data.attackerName, "BO2_KillfeedFont", x, currentY, aCol)
				local tw, _ = surface.GetTextSize(data.attackerName)
				x = x + tw
			end
			local iconY = currentY + (ICON_BOX_H - h) * 0.5
			local alpha = math.min(165 * fadeFactor, 255)
			local offsetY = CoDHUD_S(-15)
			if cls == "CoDHUD_BO2_Headshot" then offsetY = CoDHUD_S(-2) end
			killicon.Render(x + gap, iconY + (h * 0.33) + offsetY, cls, alpha, false, false)
			x = x + w + (gap * 2)
			draw.SimpleText(data.victimName, "BO2_KillfeedFont", x, currentY, vCol)
        else
            draw.SimpleText(data.msg, "BO2_KillfeedFont", x, currentY, Color(255, 255, 255, finalTxtAlpha))
        end
    end
end
CoDHUD[hudtype].Killfeed = killfeed

local function medals( ... )
	local speedMul = select(1, ...)
	local activeMedal = select(2, ...)
	local age = (CurTime() - activeMedal.start) / speedMul
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local MEDAL_DURATION = 1.25
    local FADE_IN_TIME   = 0.2
    local EXIT_DURATION  = 0.125
    local FADE_OUT_START = MEDAL_DURATION - EXIT_DURATION
    local COL_POINTS = Color(255, 255, 50)
    local MEDAL_CFG = { X_OFFSET = 0, Y_OFFSET = -0 }
	if age > MEDAL_DURATION then return true end
	local alpha = 255
	local scale = 1
	if age < FADE_IN_TIME then
		local progress = age / FADE_IN_TIME
		alpha = progress * 255
		scale = Lerp(progress, 3.0, 1.0)
	elseif age > FADE_OUT_START then
		local progress = (age - FADE_OUT_START) / EXIT_DURATION
		alpha = math.Clamp((1 - progress) * 255, 0, 255)
		scale = Lerp(progress, 1.0, 1.0)
	end
	local cx = (ScrW() / 2) + CoDHUD_S(MEDAL_CFG.X_OFFSET)
	local cy = (ScrH() * 0.1) + CoDHUD_S(MEDAL_CFG.Y_OFFSET)
	local colWhite  = Color(255, 255, 255, alpha)
	local colBlack  = Color(0, 0, 0, alpha * 0.8)
	local colYellow = Color(COL_POINTS.r, COL_POINTS.g, COL_POINTS.b, alpha)
	local iconSize = CoDHUD_S(320)
	local mat = Matrix()
	mat:Translate(Vector(cx, cy, 0))
	mat:Scale(Vector(scale, scale, 1))
	mat:Translate(Vector(-cx, -cy, 0))
	-- The medal icon PNGs (hud_medals_headshot.png etc.) already exist in
	-- materials/bo2/medals/ but MedalsTable never pointed to them and the
	-- backing glow referenced a file that doesn't exist anywhere in the
	-- addon (hud_notification_medal_backing.png) -- that's the "purple and
	-- black missing texture" look. Backing now uses the real medal-glow
	-- asset, and the actual per-medal icon is drawn above the title.
	local medalData = CoDHUD[hudtype].MedalsTable[activeMedal.id]
	local iconPath = (medalData and medalData[3]) or "bo2/medals/hud_medals_default.png"
	local iconSizeSm = CoDHUD_S(56)
	cam.PushModelMatrix(mat)
		surface.SetDrawColor(255, 255, 255, math.Clamp(alpha, 0, 60))
		surface.SetMaterial(Material(hudtype .. "/hud/fade_score.vmt"))
		surface.DrawTexturedRect(cx - iconSize, cy - (iconSize * 0.5), iconSize * 2, iconSize)
		surface.SetDrawColor(255, 255, 255, alpha)
		surface.SetMaterial(Material(iconPath, "smooth"))
		surface.DrawTexturedRect(cx - (iconSizeSm * 0.5), cy - CoDHUD_S(85), iconSizeSm, iconSizeSm)
		draw.SimpleTextOutlined( language.GetPhrase(activeMedal.text), "BO2_MedalPrimary", cx, cy - CoDHUD_S(20), colWhite, 1, 1, outlined and 1.5 or 0, colBlack )
		if activeMedal.desc then
			local localizedDesc = language.GetPhrase(activeMedal.desc)
			if activeMedal.isSpecial then
				draw.SimpleTextOutlined( localizedDesc, "BO2_MedalDesc", cx, cy + CoDHUD_S(25), colWhite, 1, 1, outlined and 1 or 0, colBlack )
			else
				local descText   = localizedDesc
				local pointsText = " +" .. activeMedal.points
				local bracketClose = ""
				surface.SetFont("BO2_MedalPoints")
				local w2 = surface.GetTextSize(pointsText)
				surface.SetFont("BO2_MedalDesc")
				local w1 = surface.GetTextSize(descText)
				local totalW = w1 + w2 + surface.GetTextSize(bracketClose)
				local startX = cx - (totalW / 2)
				draw.SimpleTextOutlined( descText, "BO2_MedalDesc", startX, cy + CoDHUD_S(30), colWhite, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( pointsText, "BO2_MedalPoints", startX + w1, cy + CoDHUD_S(30), colYellow, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( bracketClose, "BO2_MedalDesc", startX + w1 + w2, cy + CoDHUD_S(30), colWhite, 0, 1, outlined and 1 or 0, colBlack )
			end
		else
			draw.SimpleTextOutlined( "+" .. activeMedal.points, "BO2_MedalDesc", cx, cy + CoDHUD_S(30), colYellow, 1, 1, outlined and 1 or 0, colBlack )
		end
	cam.PopModelMatrix()
end
CoDHUD[hudtype].Medals = medals
CoDHUD[hudtype].MedalsSound = "hud/bo2/metal_3.SN65.pc.snd.mp3"
CoDHUD[hudtype].MedalsTable = {
	["headshot"] = { "BO2_MEDAL_HEADSHOT", nil, "bo2/medals/hud_medals_headshot.png" },
	["doublekill"] = { "BO2_MEDAL_MULTIKILL_2", nil, "bo2/medals/hud_medals_doublekill.png" },
	["triplekill"] = { "BO2_MEDAL_MULTIKILL_3", nil, "bo2/medals/hud_medals_triplekill.png" },
	["multikill"] = { "BO2_MEDAL_MULTIKILL_4", nil, "bo2/medals/hud_medals_quadkill.png" },
	["longshot"] = { "BO2_MEDAL_LONGSHOT_KILL", nil, "bo2/medals/hud_medals_longshot.png" },
	["oneshot"] = { "BO2_MEDAL_KILL_ENEMY_ONE_BULLET", nil, "bo2/medals/hud_medals_oneshot_onekill.png" },
	["firstblood"] = { "BO2_MEDAL_FIRST_KILL", nil, "bo2/medals/hud_medals_firstblood.png" },
	["comeback"] = { "BO2_MEDAL_COMEBACK_FROM_DEATHSTREAK", nil, "bo2/medals/hud_medals_comeback.png" },
	["payback"] = { "BO2_MEDAL_REVENGE_KILL", nil, "bo2/medals/hud_medals_revenge.png" },
}

local function minimap( ... )
	local ply = select(1, ...)
	local MAP_CFG = {
		X = 12, Y = 16, W = 224, H = 224,
		ALPHA_BORDER = 255, ALPHA_MAP_BG = 120, ALPHA_PLAYER = 255,
		ALPHA_STATIC_S = 100, ALPHA_MOVING_S = 255,
		SIZE_PLAYER = 42, SIZE_FRIENDLY = 42, SIZE_ENEMY = 42,
		SCAN_SPEED = 48, FADE_TIME = 0.7, FADE_TIME_VIS = 1.3,
		EDGE_PADDING = 0,
	}
	local MAT_BORDER       = Material(hudtype .. "/minimap/compass_map_background.png", "smooth")
	local MAT_MAP_BG       = Material("cod4/minimap/compass_map_default.png", "smooth")
	local MAT_PLAYER       = Material(hudtype .. "/minimap/compassping_player.png", "smooth")
	local MAT_COMPASS      = Material(hudtype .. "/minimap/compass_mp_hud.png", "smooth noclamp")
	local MAT_FRIEND_HOLLOW = Material(hudtype .. "/minimap/compassping_green_hollow_mp.png", "smooth")
	local MAT_ENEMY_FIRING  = Material(hudtype .. "/minimap/compassping_dog.png", "smooth")
    local x, y = CoDHUD_SX(MAP_CFG.X), CoDHUD_SY(MAP_CFG.Y)
    local w, h = CoDHUD_S(MAP_CFG.W), CoDHUD_S(MAP_CFG.H)
    local centerX, centerY = x + (w / 2), y + (h / 2)
	local radar = CoDHUD_GetRadar()
    surface.SetMaterial(MAT_BORDER)
    surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_BORDER)
    surface.DrawTexturedRect(x, y, w, h)
    render.ClearStencil()
    render.SetStencilEnable(true)
    render.SetStencilWriteMask(1)
    render.SetStencilTestMask(1)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    surface.SetMaterial(MAT_BORDER)
    surface.SetDrawColor(255, 255, 255, 255)
    surface.DrawTexturedRect(x, y, w, h)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
		if radar then
			radar:SetDimensions(x + CoDHUD_S(2), y + CoDHUD_S(2), w - CoDHUD_S(4), h - CoDHUD_S(4))
			radar.origin = ply:GetPos()
			radar.rotation = Angle(0, ply:EyeAngles().y, 0)
			radar.ratio = 10
			radar:UpdateLayout()
			radar:Draw()
		else
			surface.SetMaterial(MAT_MAP_BG)
			surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_MAP_BG)
			surface.DrawTexturedRect(x + CoDHUD_S(2), y + CoDHUD_S(2), w - CoDHUD_S(4), h - CoDHUD_S(4))
		end
    render.SetStencilEnable(false)

	-- Scrolling compass strip beneath the map
	local compassYaw = (ply:EyeAngles().y + 90) % 360
	local compassU = 1 - (compassYaw / 360)
	local compassH = h * 0.15
	local compassScale = 0.5
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(x, y + h, w, compassH)
	surface.SetMaterial(MAT_BORDER)
	surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRect(x, y + h, w, compassH)
	surface.SetMaterial(MAT_COMPASS)
	surface.SetDrawColor(255, 255, 255)
	local compassUEnd = compassU + compassScale
	if compassUEnd <= 1 then
		surface.DrawTexturedRectUV(x, y + h, w, compassH, compassU, 0, compassUEnd, 1)
	else
		local overflow = compassUEnd - 1
		local split = (1 - compassU) / compassScale
		surface.DrawTexturedRectUV( x, y + h, w * split, compassH, compassU, 0, 1, 1 )
		surface.DrawTexturedRectUV( x + (w * split), y + h, w * (1 - split), compassH, 0, 0, overflow, 1 )
	end

    local pSize = CoDHUD_S(MAP_CFG.SIZE_PLAYER)
    local fSize = CoDHUD_S(MAP_CFG.SIZE_FRIENDLY)
    local eSize = CoDHUD_S(MAP_CFG.SIZE_ENEMY)
    local localFaction = ply:GetNW2String("CoDHUD_Faction", "")
    local targets = ents.FindByClass("npc_*")
    table.Add(targets, player.GetAll())
    for _, ent in ipairs(targets) do
        if not IsValid(ent) or ent == ply then continue end
        -- Skip entities the server has hidden (NoDraw) — e.g. bots waiting
        -- out the round-start countdown — and the killcam stand-in NPC.
        if ent:GetNoDraw() then continue end
        if ent:GetNW2Bool("IsKillcamNPC", false) then continue end
        local isAlive = (ent:IsPlayer() and ent:Alive()) or (ent:IsNPC() and ent:Health() > 0)
        local targetFaction = ent:GetNW2String("CoDHUD_Faction", "")
        local isFriendly = (localFaction ~= "" and targetFaction == localFaction)
        local gmCV = GetConVar("codhud_selected_gamemode")
        if isFriendly and gmCV and gmCV:GetString() == "sesh_dm" then
            if ent:IsPlayer() and ent:IsBot() then isFriendly = false end
        end
        local entIdx = ent:EntIndex()
        local isVisibleToTeam = false
        if not isFriendly then
            for _, observer in ipairs(player.GetAll()) do
                local obsFaction = observer:GetNW2String("CoDHUD_Faction", "")
                local isObserverFriendly = (localFaction ~= "" and obsFaction == localFaction)
                if observer == ply or (isObserverFriendly and observer:Alive()) then
                    local dirToEnt = (ent:WorldSpaceCenter() - observer:EyePos()):GetNormalized()
                    local dot = observer:GetAimVector():Dot(dirToEnt)
                    local fovRad = math.rad((observer:IsPlayer() and observer:GetFOV() or 90) / 2)
                    if dot > math.cos(fovRad) then
                        local tr = util.TraceLine({ start = observer:EyePos(), endpos = ent:WorldSpaceCenter(), filter = {observer, ent}, mask = MASK_SHOT })
                        if not tr.Hit then isVisibleToTeam = true break end
                    end
                end
            end
            if isVisibleToTeam and isAlive then
                CoDHUD_VisCache[entIdx] = CurTime() + MAP_CFG.FADE_TIME_VIS
            end
        end
        local visAlpha = 0
        if CoDHUD_VisCache[entIdx] then
            local timeLeft = CoDHUD_VisCache[entIdx] - CurTime()
            if timeLeft > 0 then visAlpha = math.Clamp(timeLeft / MAP_CFG.FADE_TIME_VIS, 0, 1) * 255
            else CoDHUD_VisCache[entIdx] = nil end
        end
        local alpha = 255
        local gmCV2 = GetConVar("codhud_selected_gamemode")
        local isSeshMode = gmCV2 and (gmCV2:GetString() == "sesh_dm" or gmCV2:GetString() == "sesh_war" or gmCV2:GetString() == "sesh_sd" or gmCV2:GetString() == "sesh_sd_set")
        if not isFriendly then
            if isSeshMode then
                alpha = 255
            else
                alpha = visAlpha
            end
        end
        if CoDHUD_DeathCache[entIdx] then
                local timeSinceDeath = CurTime() - CoDHUD_DeathCache[entIdx]
                if timeSinceDeath > MAP_CFG.FADE_TIME then continue end
                alpha = math.min(alpha, 255 * (1 - (timeSinceDeath / MAP_CFG.FADE_TIME)))
        else
            CoDHUD_DeathCache[entIdx] = nil
        end
        if alpha <= 0 then continue end
		local targetX, targetY
		if radar then
			local pos = ent:GetPos()
			local delta = pos - ply:EyePos()
			local yaw = ply:EyeAngles().y
			local rad = math.rad(yaw + 180)
			local cos, sin = math.cos(rad), math.sin(rad)
			local x2 = delta.y * cos - delta.x * sin
			local y2 = delta.y * sin + delta.x * cos
			x2 = x2 / radar.ratio
			y2 = y2 / radar.ratio
			local boundsX = (w / 2) - MAP_CFG.EDGE_PADDING
			local boundsY = (h / 2) - MAP_CFG.EDGE_PADDING
			if math.abs(x2) > boundsX or math.abs(y2) > boundsY then
				local scaleX = boundsX / math.max(0.0001, math.abs(x2))
				local scaleY = boundsY / math.max(0.0001, math.abs(y2))
				local scale = math.min(scaleX, scaleY)
				x2 = x2 * scale y2 = y2 * scale
			end
			targetX = centerX + x2 targetY = centerY + y2
		else
			local relPos = ent:GetPos() - ply:GetPos()
			local dist = relPos:Length() / 8
			local posAngle = relPos:Angle()
			posAngle.y = posAngle.y - ply:EyeAngles().y + 90
			local rad = math.rad(posAngle.y)
			local offsetX = math.cos(rad) * dist
			local offsetY = -math.sin(rad) * dist
			local boundsX = (w / 2) - MAP_CFG.EDGE_PADDING
			local boundsY = (h / 2) - MAP_CFG.EDGE_PADDING
			if math.abs(offsetX) > boundsX or math.abs(offsetY) > boundsY then
				local scaleX = boundsX / math.max(0.0001, math.abs(offsetX))
				local scaleY = boundsY / math.max(0.0001, math.abs(offsetY))
				local scale = math.min(scaleX, scaleY)
				offsetX = offsetX * scale offsetY = offsetY * scale
			end
			targetX = centerX + offsetX targetY = centerY + offsetY
		end
        if isFriendly then
            local rotation = ent:EyeAngles().y - ply:EyeAngles().y
            surface.SetMaterial(MAT_FRIEND_HOLLOW)
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.DrawTexturedRectRotated(targetX, targetY, fSize, fSize, rotation)
        else
            surface.SetMaterial(MAT_ENEMY_FIRING)
            surface.SetDrawColor(255, 255, 255, alpha)
            surface.DrawTexturedRect(targetX - (eSize / 2), targetY - (eSize / 2), eSize, eSize)
        end
    end
    surface.SetMaterial(MAT_PLAYER)
    surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_PLAYER)
    surface.DrawTexturedRect(centerX - (pSize / 2), centerY - (pSize / 2), pSize, pSize)
end
CoDHUD[hudtype].Minimap = minimap

local function scorebar(data)
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	local CFG = {
		BAR_W = 441.6, BAR_H = 220.8, BAR_X_OFF = 8, BAR_Y_OFF = -32,
		ICON_SCALE = 0.7, ICON_X = 58, ICON_Y = 44,
		TIMER_X = 46, TIMER_Y = 44,
		STATUS_X = 121, STATUS_Y = 44,
	}
	local SCORES_CFG = {
		X = 212.5, Y = 117.5, GAP_OFFSET = 63,
		SCORE_LIMIT = 75,
		HUD_X = 187.5, HUD_Y = 38, HUD_W_BASE = 0, HUD_W_MAX = 215, HUD_H = 43, HUD_H_LOWER = 31.5,
		VERTICAL_GAP = 5,
		BASE_X = 52, BASE_Y = 97, BASE_W = 384, BASE_H = 99,
	}

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local currentFaction = ply:GetNW2String("CoDHUD_Faction", "")
    if currentFaction == "" then
        currentFaction = cookie.GetString("CoDHUD_SelectedFaction", "seals")
        if not CoDHUD.Factions[hudtype][currentFaction] then currentFaction = "seals" end
        ply:SetNW2String("CoDHUD_Faction", currentFaction)
    end

    local scrW, scrH = ScrW(), ScrH()

    local barW, barH = CoDHUD_SX(CFG.BAR_W), CoDHUD_SY(CFG.BAR_H)
    local barX = CoDHUD_SX(CFG.BAR_X_OFF)
    local barY = scrH - CoDHUD_SY(CFG.BAR_Y_OFF) - barH

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(Material(hudtype .. "/hud/background_score.vmt"))
	surface.DrawTexturedRect(barX, barY, barW, barH)

	local factionData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][currentFaction]
	local factionMat = factionData and factionData.scoreIcon
	if not factionData then currentFaction = "seals" factionData = CoDHUD.Factions[hudtype][currentFaction] end

	if factionMat then
		local iSize = math.Round(barH * CFG.ICON_SCALE)
		local fdg = factionData.glow or Color(255,255,255)
		surface.SetDrawColor(fdg.r, fdg.g, fdg.b, 255 * 0.25)
		surface.SetMaterial(Material(hudtype .. "/hud/fade_team.vmt"))
		surface.DrawTexturedRect( barX + CoDHUD_SX(CFG.ICON_X * 0.75), barY + CoDHUD_SY(CFG.ICON_Y * 1.25), iSize * 1.25, iSize * 1.25)
		surface.SetMaterial(Material(factionMat, "smooth"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect( barX + CoDHUD_SX(CFG.ICON_X), barY + CoDHUD_SY(CFG.ICON_Y), iSize, iSize )
	end

    local clientKills   = data.clientScore
    local topEnemyKills = data.enemyScore
    local S_CFG = SCORES_CFG

    local liveScoreLimit = S_CFG.SCORE_LIMIT
    local gmCV2 = GetConVar("codhud_selected_gamemode")
    if gmCV2 and gmCV2:GetString() == "sesh_dm" then
        liveScoreLimit = 30
    elseif gmCV2 and (gmCV2:GetString() == "sesh_sd" or gmCV2:GetString() == "sesh_sd_set") then
        -- Sesh S&D wins on rounds ("first to X"), tracked by sesh_sd_rounds,
        -- not codhud_score_limit (that convar is the FFA/TDM kill limit and
        -- defaults to 75, which made the bar need 75 round wins to fill).
        local cv_rounds = GetConVar("sesh_sd_rounds")
        if cv_rounds then
            local val = cv_rounds:GetInt()
            if val > 0 then liveScoreLimit = val end
        end
    else
        local cv_limit = GetConVar("codhud_score_limit")
        if cv_limit then
            local val = cv_limit:GetInt()
            if val > 0 then liveScoreLimit = val end
        end
    end

	local scoreMultiplier = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100
	liveScoreLimit = liveScoreLimit * scoreMultiplier

    local white = Color(255,255,255,255)
    draw.SimpleTextOutlined( clientKills * scoreMultiplier, "BO2_Font", CoDHUD_SX(S_CFG.X), ScrH() - CoDHUD_SY(S_CFG.Y), white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,white.a * 0.25) )
    draw.SimpleTextOutlined( topEnemyKills * scoreMultiplier, "BO2_Font2", CoDHUD_SX(S_CFG.X) - CoDHUD_SX(5), ScrH() - CoDHUD_SY(S_CFG.Y) + CoDHUD_S(S_CFG.GAP_OFFSET), white, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,white.a * 0.25) )

    local timeStr = data.timeStr
    local mins = data.mins
	local timecol = Color(255,255,255)
	if data.timeRaw > 30 and data.timeRaw < 60 then timecol = Color(218,136,43)
	elseif data.timeRaw < 30 then timecol = Color(255,100,100) end
	timecol = Color(timecol.r, timecol.g, timecol.b, 200)
	local shouldDrawTimer = data.timeRaw > 0.1 and (CoDHUD_MatchMaxTime <= 0 or data.timeRaw <= CoDHUD_MatchMaxTime)
	if shouldDrawTimer then
		draw.SimpleTextOutlined( timeStr, "BO2_Timer", barX + CoDHUD_SX(CFG.TIMER_X), barY + CoDHUD_SY(CFG.TIMER_Y), timecol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,timecol.a * 0.25) )
	end

	local statusStr = data.statusResolved and data.statusText or language.GetPhrase(data.statusText)
	local textcol = Color(255,255,255,200)
	local gmStr = gmCV2 and gmCV2:GetString() or ""
	local isScoreLimitMode = (gmStr == "war" or gmStr == "sesh_war" or gmStr == "dm" or gmStr == "sesh_dm")
	local alt = isScoreLimitMode and (math.floor(CurTime() / 10) % 2 == 1)
	if alt then
		statusStr = string.format( language.GetPhrase("BO2_MPUI_X_POINTS_TO_WIN_CAPS"), liveScoreLimit )
	end
    draw.SimpleTextOutlined( statusStr, "BO2_Status", barX + CoDHUD_SX(CFG.STATUS_X), barY + CoDHUD_SY(CFG.STATUS_Y), textcol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,textcol.a * 0.25) )
end
CoDHUD[hudtype].Scorebar = scorebar

local function scoreboard( ... )
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	local CFG = {
		BAR_W = 1012.5, BAR_H = 40, BAR_X_OFF = 142, BAR_Y_OFF = 252, BAR_ALPHA = 100,
		ROW_GAP = 0, TEAM_GAP = 30,
		ICON_SIZE = 192, ICON_X_OFF = -240, ICON_Y_OFF = -32,
		SCORE_NAME_X = -278, SCORE_NAME_Y = 12.5,
		FAC_NAME_X = -278, FAC_NAME_Y = 53,
		HEADER_Y_POS = 90, HEADER_H = 50, HEADER_ALPHA = 255,
		TIMER_X_POS = 10, TIMER_Y_OFF = 150,
		MAPNAME_X_POS = 125, MAPNAME_Y_OFF = 150,
		OFF_PING = 10, OFF_ASSISTS = 100, OFF_RATIO = 200, OFF_DEATHS = 300, OFF_KILLS = 400, OFF_SCORE = 500,
	}

	local MAT_BOXFG = Material(hudtype .. "/hud/menu_mp_map_frame.png", "mips smooth")
	local MAT_BOXOVERLAY = Material(hudtype .. "/hud/fade_score.vmt")
	local MAT_ICON_DEAD  = Material(hudtype .. "/icons/hud_status_dead.png", "mips smooth")

	local viewportTop    = CoDHUD_S(0)
	local viewportHeight = ScrH()
	local viewportBottom = viewportTop + viewportHeight

	local scoreMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100

	local function SortLogic(a, b)
		local scoreA = math.max(0, a:Frags())
		local scoreB = math.max(0, b:Frags())
		if scoreA == scoreB then
			if a == LocalPlayer() then return true end
			if b == LocalPlayer() then return false end
			return a:Nick() < b:Nick()
		end
		return scoreA > scoreB
	end

	local function TruncateText(text, font, maxWidth)
		surface.SetFont(font)
		if surface.GetTextSize(text) <= maxWidth then return text end
		local ellipsis = "..."
		local ellipsisWidth = surface.GetTextSize(ellipsis)
		local truncated = text
		while #truncated > 0 do
			truncated = string.sub(truncated, 1, #truncated - 1)
			local w = surface.GetTextSize(truncated)
			if w + ellipsisWidth <= maxWidth then return truncated .. ellipsis end
		end
		return ellipsis
	end

	local function DrawPlayerRow(ply, lp, x, y, w, h, barRight, bgCol)
		if ply:IsValid() and not ply:Alive() then
			surface.SetMaterial(MAT_ICON_DEAD)
			surface.SetDrawColor(255, 255, 255, 255)
			local iconSz = h * 0.8
			surface.DrawTexturedRect(x - CoDHUD_S(32), y + (h / 2) - (iconSz / 2), iconSz, iconSz)
		end
		local isMe = (ply == lp)
		if isMe then
			surface.SetDrawColor(255, 140, 40, 255)
			surface.DrawOutlinedRect(x - CoDHUD_S(4), y - CoDHUD_S(2), w + CoDHUD_S(6), h + CoDHUD_S(4), 3)
		end
		local tCol = Color(255, 255, 255, 255)
		local pScore = math.max(0, ply:Frags() * scoreMul)
		local kills = ply:Frags()
		local deaths = ply:Deaths()
		local ratio = 0
		if kills > 0 then ratio = kills / (deaths > 1 and deaths or 1) end
		local kd = string.format("%.2f", ratio)

		surface.SetDrawColor(bgCol.r, bgCol.g, bgCol.b, CFG.BAR_ALPHA)
		surface.DrawRect(barRight - CoDHUD_SX(CFG.OFF_ASSISTS) - CoDHUD_SX(50), y, CoDHUD_S(100), h)
		surface.DrawRect(barRight - CoDHUD_SX(CFG.OFF_DEATHS) - CoDHUD_SX(50), y, CoDHUD_S(100), h)
		surface.DrawRect(barRight - CoDHUD_SX(CFG.OFF_SCORE) - CoDHUD_SX(50), y, CoDHUD_S(100), h)

		local maxNameWidth = CoDHUD_SX(375)
		local playerName = TruncateText( ply:Nick(), "BO2_Scoreboard_Text", maxNameWidth )
		draw.SimpleTextOutlined( playerName, "BO2_Scoreboard_Text", x + CoDHUD_S(80), y + (h / 2), tCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0) )

		draw.SimpleTextOutlined(ply:Ping(), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_PING),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(deaths, "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_DEATHS),  y + (h / 2), tCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(kd, "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_RATIO),  y + (h / 2), tCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:GetNWInt("Assists", 0), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_ASSISTS), y + (h / 2), tCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(kills, "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_KILLS),   y + (h / 2), tCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(pScore, "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_SCORE),   y + (h / 2), tCol, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
	end

    local scrW, scrH = ScrW(), ScrH()
    local lp = LocalPlayer()

	-- CoDHUD_ActiveGamemodeCL is never actually set anywhere in the addon --
	-- it's always nil. Read the real, live source of truth instead (same
	-- convar every other HUD's scoreboard/scorebar already uses).
	local gmCL = GetConVar("codhud_selected_gamemode") and GetConVar("codhud_selected_gamemode"):GetString() or ""

	local groups = {}
	if gmCL == "dm" or gmCL == "sesh_dm" then
		local allPlayers = player.GetAll()
		table.sort(allPlayers, SortLogic)
		groups = { { key = "dm", players = allPlayers, score = 0 } }
	else
		local factions = {}
		for _, p in ipairs(player.GetAll()) do
			-- "seals" was being used as the fallback for ANY player whose
			-- faction hasn't networked to this client yet (a brief window
			-- right after a bot spawns) -- since "seals" also happens to be
			-- the real human faction, that visually merged a not-yet-synced
			-- bot into the player's own team on the scoreboard. Only guess
			-- for the local player (so you always see yourself immediately);
			-- for anyone else, skip them this frame rather than guess wrong
			-- -- their real faction shows up correctly within a tick or two.
			local fac = p:GetNW2String("CoDHUD_Faction", "")
			if fac == "" then
				if p == lp then
					fac = cookie.GetString("CoDHUD_SelectedFaction", "seals")
				else
					continue
				end
			end
			factions[fac] = factions[fac] or {}
			table.insert(factions[fac], p)
		end
		for fac, players in pairs(factions) do
			table.sort(players, SortLogic)
			table.insert(groups, { key = fac, players = players, score = 0 })
		end
	end

	local gmSB = GetConVar("codhud_selected_gamemode")
	local isSeshSD_SB = gmSB and (gmSB:GetString() == "sesh_sd" or gmSB:GetString() == "sesh_sd_set")
	local myFacSB = lp:GetNW2String("CoDHUD_Faction", "")
	for _, g in ipairs(groups) do
		if isSeshSD_SB and _G.KC_SD_SeshRoundsA ~= nil then
			g.score = (g.key == myFacSB) and (_G.KC_SD_SeshRoundsA or 0) or (_G.KC_SD_SeshRoundsB or 0)
		else
			local score = 0
			for _, p in ipairs(g.players) do
				score = score + math.max(0, p:Frags())
			end
			g.score = score
		end
	end

	table.sort(groups, function(a, b) return a.score > b.score end)

	-- Move the local player's own team to the front (top) of the list,
	-- without changing the ordering of everyone else. Done as a plain
	-- array move (not a custom table.sort comparator) so there's no risk
	-- of an inconsistent comparator corrupting the list.
	local myFaction = lp:GetNW2String("CoDHUD_Faction", "")
	for i, g in ipairs(groups) do
		if g.key == myFaction then
			if i > 1 then table.insert(groups, 1, table.remove(groups, i)) end
			break
		end
	end

    local barW = CoDHUD_S(CFG.BAR_W)
    local barH = CoDHUD_S(CFG.BAR_H)
    local barX = (scrW / 2) - (barW / 2) + CoDHUD_S(CFG.BAR_X_OFF)
    local barRight = barX + barW

	CoDHUD.Scoreboard.ContentHeight = 0
	for _, facData in ipairs(groups) do
		local visualPlayers = math.max(#facData.players, 2)
		local factionHeight = (visualPlayers * (barH + CoDHUD_S(CFG.ROW_GAP))) + CoDHUD_S(CFG.TEAM_GAP)
		CoDHUD.Scoreboard.ContentHeight = CoDHUD.Scoreboard.ContentHeight + factionHeight
	end
	CoDHUD.Scoreboard.ContentHeight = CoDHUD.Scoreboard.ContentHeight + CoDHUD_S(200)

	local sb = CoDHUD.Scoreboard
	local startY = CoDHUD_S(CFG.BAR_Y_OFF) - math.floor(sb.Scroll)
	local headerY = CoDHUD_S(CFG.BAR_Y_OFF) - CoDHUD_S(50) - CoDHUD.Scoreboard.Scroll

	local headerPaddingX = CoDHUD_S(24)
	local headerH = CoDHUD_S(45)
	local headerX = barX - headerPaddingX
	local headerW = (barRight - headerX)
	headerX = headerX - CoDHUD_S(260)
	headerW = headerW + CoDHUD_S(260)

	surface.SetDrawColor(0, 0, 0, 220)
	surface.DrawRect( headerX, headerY - CoDHUD_S(5), headerW, headerH )
	surface.SetMaterial(MAT_BOXFG)
	surface.SetDrawColor(255,255,255)
	surface.DrawTexturedRect( headerX, headerY - CoDHUD_S(5), headerW, headerH )

	local totalSecs = math.floor(CurTime())
	local mins, secs = math.floor(totalSecs / 60), totalSecs % 60
	local timeStr = string.format("%d:%02d", mins, secs)
	draw.SimpleTextOutlined( timeStr, "BO2_Scoreboard_Timer", headerX + CoDHUD_S(CFG.TIMER_X_POS), headerY, Color(255,255,255), TEXT_ALIGN_LEFT, 0, outlined and 1 or 0, Color(0,0,0) )

	local gm = gmCL
	local gmname = language.GetPhrase(CoDHUD.Gamemodes[hudtype].Names[gm] or gm)
	draw.SimpleTextOutlined( gmname .. " - " .. string.upper(game.GetMap()), "BO2_Scoreboard_Text2", headerX + CoDHUD_SX(CFG.MAPNAME_X_POS), headerY, Color(255,255,255), TEXT_ALIGN_LEFT, 0, outlined and 1 or 0, Color(0,0,0) )

	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_PING"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_PING) + CoDHUD_SX(4), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_DEATHS"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_DEATHS), headerY, Color(255,255,255), TEXT_ALIGN_CENTER, 0, outlined and 1 or 0, Color(0,0,0) )
	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_KDRATIO"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_RATIO), headerY, Color(255,255,255), TEXT_ALIGN_CENTER, 0, outlined and 1 or 0, Color(0,0,0) )
	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_ASSISTS"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_ASSISTS), headerY, Color(255,255,255), TEXT_ALIGN_CENTER, 0, outlined and 1 or 0, Color(0,0,0) )
	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_KILLS"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_KILLS), headerY, Color(255,255,255), TEXT_ALIGN_CENTER, 0, outlined and 1 or 0, Color(0,0,0) )
	draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_SCORE"), "BO2_Scoreboard_Text", barRight - CoDHUD_SX(CFG.OFF_SCORE), headerY, Color(255,255,255), TEXT_ALIGN_CENTER, 0, outlined and 1 or 0, Color(0,0,0) )

	render.SetScissorRect(0, viewportTop, ScrW(), viewportBottom, true)
		for fi, facData in ipairs(groups) do
			local players = facData.players
			local leader = players[1]
			local leaderScore = players[1] and (players[1]:Frags() * scoreMul) or 0
			local facKey = facData.key
			local score = facData.score or 0
			local fData

			if facKey == "dm" then
				fData = { name = "DM", short = "DM", color = Color(200, 200, 200), glow = Color(255, 255, 255) }
			else
				fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][facKey] or { name = facKey, short = facKey, color = Color(120,120,120), glow = Color(255,255,255) }
			end

			local sectionY = startY
			local playerCount = #players
			local visualPlayers = math.max(playerCount, 2)

			local factionRectX = barX - CoDHUD_S(24)
			local factionRectY = sectionY - CoDHUD_S(3)
			local factionRectW = barW + CoDHUD_S(24)
			local factionRectH = (visualPlayers * (barH + CoDHUD_S(CFG.ROW_GAP))) + CoDHUD_S(6)
			factionRectX = factionRectX - CoDHUD_S(260)
			factionRectW = factionRectW + CoDHUD_S(260)

			surface.SetDrawColor(0, 0, 0, 210)
			surface.DrawRect( factionRectX, factionRectY, factionRectW, factionRectH )
			surface.SetMaterial(MAT_BOXFG)
			surface.SetDrawColor(255,255,255)
			surface.DrawTexturedRect( factionRectX, factionRectY, factionRectW, factionRectH )

			local iconSize = CoDHUD_S(CFG.ICON_SIZE)
			local iconX = barX + CoDHUD_S(CFG.ICON_X_OFF)
			local iconY = sectionY + CoDHUD_S(CFG.ICON_Y_OFF)

			if facKey ~= "dm" then
				local iconPath = fData and fData.scoreIcon
				if iconPath then
					local mat = Material(iconPath, "smooth")
					surface.SetMaterial(mat)
					surface.SetDrawColor(255,255,255,255)
					surface.DrawTexturedRect(iconX, iconY, iconSize, iconSize)
				end
			end

			surface.SetMaterial(MAT_BOXOVERLAY)
			surface.SetDrawColor(fData.glow)
			surface.DrawTexturedRect( factionRectX, factionRectY + CoDHUD_SY(3), iconSize * 1.4, factionRectH )

			draw.SimpleTextOutlined( leaderScore, "BO2_Scoreboard_Score", barX + CoDHUD_SX(CFG.SCORE_NAME_X), sectionY + CoDHUD_S(CFG.SCORE_NAME_Y) - CoDHUD_S(22), Color(255,255,255), TEXT_ALIGN_LEFT, 0, outlined and 1 or 0, Color(0,0,0) )

			local facname
			if facKey == "dm" then
				facname = IsValid(leader) and leader:Nick() or "Unknown"
				draw.SimpleTextOutlined( facname, "BO2_Scoreboard_Text", barX + CoDHUD_S(CFG.FAC_NAME_X), sectionY + CoDHUD_S(CFG.FAC_NAME_Y), fData.glow, 0,0, outlined and 1 or 0, Color(0,0,0) )
			else
				facname = fData.short .. "_CAPS"
				draw.SimpleTextOutlined( language.GetPhrase(facname), "BO2_Scoreboard_Text", barX + CoDHUD_S(CFG.FAC_NAME_X), sectionY + CoDHUD_S(CFG.FAC_NAME_Y), fData.glow, 0,0, outlined and 1 or 0, Color(0,0,0) )
			end

			for i, ply in ipairs(players) do
				local rowY = sectionY + (i - 1) * (barH + CoDHUD_S(CFG.ROW_GAP))
				DrawPlayerRow(ply, lp, barX, rowY, barW, barH, barRight, fData.color)
			end

			local sectionHeight = (visualPlayers * (barH + CoDHUD_S(CFG.ROW_GAP)))
			startY = startY + sectionHeight + CoDHUD_S(CFG.TEAM_GAP)
		end
	render.SetScissorRect(0, 0, 0, 0, false)
end
CoDHUD[hudtype].Scoreboard = scoreboard

local function deathicon( ... )
	local m = select(1, ...)
	local elapsed = select(2, ...)
    local MAT_DEAD_ICON = Material(hudtype .. "/icons/headicon_dead.png", "smooth")
	local screenData = m.pos:ToScreen()
	if screenData.visible then
		local currentAlpha = 185
		if elapsed > (3.7 - 1.0) then currentAlpha = Lerp((elapsed - (3.7 - 1.0)) / 1.0, 185, 0) end
		local dist = LocalPlayer():GetPos():Distance(m.pos)
		local scale = math.Clamp(1 - (dist / 2500), 0.5, 1)
		local scaledSize = 76 * scale
		surface.SetMaterial(MAT_DEAD_ICON)
		surface.SetDrawColor(255, 255, 255, currentAlpha)
		surface.DrawTexturedRect(screenData.x - (scaledSize/2), screenData.y - (scaledSize/2), scaledSize, scaledSize)
	end
end
CoDHUD[hudtype].DeathIcon = deathicon

local function friendorfoe( ... )
	local displayName = select(1, ...)
	local finalScale = select(2, ...)
	local screenData = select(3, ...)
	local isFriendly = select(4, ...)
	local alpha = select(5, ...)
	local ENEMY_COLOR    = Color(210, 30, 50)
    local FRIENDLY_COLOR = Color(60, 200, 60)
	local factionColor = isFriendly and FRIENDLY_COLOR or ENEMY_COLOR
	surface.SetFont("BO2_TargetName_Primary")
	local tw, th = surface.GetTextSize(displayName)
	tw, th = tw * finalScale, th * finalScale
	local drawX, drawY = screenData.x - (tw / 2), screenData.y - (th / 2)
	local matrix = Matrix()
	matrix:Translate(Vector(drawX, drawY, 0))
	matrix:Scale(Vector(finalScale, finalScale, 1))
	cam.PushModelMatrix(matrix)
		draw.SimpleText(displayName, "BO2_TargetName_Primary", 0, 0, Color(factionColor.r, factionColor.g, factionColor.b, alpha), 0, 0)
	cam.PopModelMatrix()
end
CoDHUD[hudtype].IFF = friendorfoe

local ICON_ON  = Material(hudtype .. "/icons/voice_on.png", "noclamp smooth")
local ICON_DIM = Material(hudtype .. "/icons/voice_on_dim.png", "noclamp smooth")

local function voice( ... )
	local yOffset = select(1, ...)
	local ply = select(2, ...)
	local VOICE_X = 22
	local VOICE_Y_START = ScrH() * 0.30
	local SPACING = 28
	local ICON_SIZE = 36
	local TEXT_X_OFFSET = 2
	local drawY = VOICE_Y_START + yOffset
	local isSpeaking = ply:VoiceVolume() > 0.05
	local icon = isSpeaking and ICON_ON or ICON_DIM
	surface.SetMaterial(icon)
	surface.SetDrawColor(255, 255, 255, 255)
	surface.DrawTexturedRect(VOICE_X, drawY, ICON_SIZE, ICON_SIZE)
	draw.SimpleText(ply:Nick(), "BO2_VoiceFont", VOICE_X + ICON_SIZE + TEXT_X_OFFSET, drawY, Color(255, 255, 255), 0, 0)
	yOffset = yOffset + SPACING
end
CoDHUD[hudtype].VoiceChat = voice

local debugpicture = Material("debugref/bo2_3.png", "smooth")

local function weaponinfo(...)
	if debugpic then
		surface.SetMaterial(debugpicture)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	local MASK = select(1, ...)
	local ply = select(3, ...)

	local CFG = {
		BAR_W = 441.6, BAR_H = 220.8, BAR_X_OFF = 446.6, BAR_Y_OFF = -32,
		GRENADE_X_OFF = 140, GRENADE_Y_OFF = 50, GRENADE_ICON_W = 40, GRENADE_ICON_H = 40,
		GRENADE_STACK_GAP = -4, GRENADE_MAX = 4, GRENADE_SHADES = { 255, 200, 175, 120 },
		RES_X = 80, RES_Y = 102.5,
		WEP_NAME_X_OFF = 55, WEP_NAME_Y_OFF = 145,
		STAT_FLASH_SPD = 8, STAT_Y_OFF = 62, STAT_LOW_PERC = 0.40,
		ALT_TEXT_X = 320 - 56, ALT_TEXT_Y = 42, ALT_TEXT_SQ = 0,
		ALT_WICON_SIZE = 48, ALT_WICON_X = 320, ALT_WICON_Y = 56,
	}

	local MAT_FRAME = Material(hudtype .. "/hud/background_weaponinfo.vmt")
	local MAT_ALT = {
		["grenade"] = Material(hudtype .. "/icons/hud_obit_grenade_launcher_attach.png", "smooth mips"),
		["buckshot"] = Material("mw2/hud/dpad_underbarrel_shotgun.png", "smooth mips"),
	}
	local MAT_GRENADE = Material(hudtype .. "/icons/grenadeicon.png", "smooth")

    local barW, barH = CoDHUD_SX(CFG.BAR_W), CoDHUD_SY(CFG.BAR_H)
    local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF)
    local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH

    surface.SetMaterial(MAT_FRAME)
    surface.SetDrawColor(255, 255, 255)
	surface.DrawTexturedRect(barX, barY, barW, barH)

    local grenadeCount = math.Clamp(ply:GetAmmoCount("Grenade") or 0, 0, CFG.GRENADE_MAX)
    if grenadeCount > 0 then
        local iW = CoDHUD_S(CFG.GRENADE_ICON_W)
        local iH = CoDHUD_S(CFG.GRENADE_ICON_H)
        local stackGap = CoDHUD_S(CFG.GRENADE_STACK_GAP)
        local anchorX = ScrW() - CoDHUD_SX(CFG.GRENADE_X_OFF)
        local anchorY = ScrH() - CoDHUD_SY(CFG.GRENADE_Y_OFF)
        surface.SetMaterial(MAT_GRENADE)
        for i = (CFG.GRENADE_MAX - 1), 0, -1 do
            if i < grenadeCount then
                local colorIndex = i + 1
                local shade = CFG.GRENADE_SHADES[colorIndex] or CFG.GRENADE_SHADES[#CFG.GRENADE_SHADES]
                surface.SetDrawColor(shade, shade, shade, 255)
                local xPos = anchorX - (i * stackGap)
                local yPos = anchorY
                surface.DrawTexturedRect(xPos, yPos, iW, iH)
            end
        end
    end

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep ~= lastWep then lastWep = wep wepSwitchTime = CurTime() end

    local clip    = wep:Clip1()
    local clip2   = wep:Clip2()
    local maxClip = wep:GetMaxClip1()
    local maxClip2 = wep:GetMaxClip2()
    local primType = wep:GetPrimaryAmmoType()
    local altType = wep:GetSecondaryAmmoType()
	local altAmmoName = game.GetAmmoName(altType)
    local primCount = ply:GetAmmoCount(primType)
	local altCount = ply:GetAmmoCount(altType)

	local reloading =
	wep.IsReloading or reloadingM203
	or (wep.ARC9 and wep:GetReloading())
	or (wep.ArcCW and wep:GetReloading())
	or (wep.IsTFAWeapon and TFA.Enum.ReloadStatus[wep:GetStatus()])

	local glactive =
	wep.dt and (wep.dt.AltActive or wep.dt.M203Active)
	or (wep.ARC9 and wep:GetUBGL())

	if glactive then clip = clip2 maxClip = maxClip2 primCount = altCount end

	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	surface.SetFont("BO2_Res")
	local restext = " / " .. primCount
	local resw, resh = surface.GetTextSize(restext)
	surface.SetFont("BO2_Res_Large")
	local clipw, cliph = surface.GetTextSize(maxClip)
	surface.SetFont("BO2_Res")

	if primType ~= -1 then
        local resCol = (primCount == 0 or primCount < maxClip) and Color(255, 120, 120, 255) or Color(255, 255, 255, 255)
		if maxClip > 0 then
			draw.SimpleTextOutlined(restext, "BO2_Res", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y), resCol, 0, 0, outlined and 1 or 0, Color(0, 0, 0))
		else
			surface.SetFont("BO2_Res_Large")
			local restext, resw = tostring(primCount), surface.GetTextSize(primCount)
			draw.SimpleTextOutlined(primCount, "BO2_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), resCol, 0, 0, outlined and 1 or 0, Color(0, 0, 0))
			surface.SetFont("BO2_Res")
		end
    end

	surface.SetFont("BO2_Wep_Name")
	local name  = CoDHUD_UpperText(language.GetPhrase(wep:GetPrintName() or wep:GetClass()))
	local namew, nameh = surface.GetTextSize(name)
	draw.RoundedBox( 4, ScrW() - CoDHUD_SX(CFG.WEP_NAME_X_OFF+2) - namew, ScrH() - CoDHUD_SY(CFG.WEP_NAME_Y_OFF), namew + CoDHUD_S(11), nameh, Color( 255, 255, 255, 100 ) )
	draw.SimpleTextOutlined(name, "BO2_Wep_Name", ScrW() - CoDHUD_SX(CFG.WEP_NAME_X_OFF), ScrH() - CoDHUD_SY(CFG.WEP_NAME_Y_OFF), Color(0, 0, 0, 175), 2, 0, 1, Color(0, 0, 0, 10))

	local altCache = (altType == primType or altType == game.GetAmmoID("Grenade") and maxClip2 > 0)

    if altType ~= -1 then
		if altType ~= primType and altType ~= game.GetAmmoID("Grenade") then
			surface.SetFont("BO2_Ammo_Alt")
			local altAdd = altCount + math.max(clip2, 0)
			local altLen = #tostring(altAdd)
			local altw, alth = surface.GetTextSize(altAdd)
			local altPad = (altw + (altLen * CFG.ALT_TEXT_SQ))
			local alticon = "grenade"
			if altAmmoName == "Buckshot" then alticon = "buckshot" end
			surface.SetMaterial(MAT_ALT[alticon])
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(ScrW() - CoDHUD_SX(CFG.ALT_WICON_X), ScrH() - CoDHUD_SY(CFG.ALT_WICON_Y), CoDHUD_S(CFG.ALT_WICON_SIZE), CoDHUD_S(CFG.ALT_WICON_SIZE))
			local altCol = (altCount > 0) and Color(255, 255, 255, 255) or Color(255, 120, 120, 255)
			draw.RoundedBox( 4, ScrW() - CoDHUD_SX(CFG.ALT_TEXT_X+2), ScrH() - CoDHUD_SY(CFG.ALT_TEXT_Y), CoDHUD_S(10) + altPad, alth, Color( 0, 0, 0, 200 ) )
			DrawSqueezedText(altAdd, "BO2_Ammo_Alt", ScrW() - CoDHUD_SX(CFG.ALT_TEXT_X), ScrH() - CoDHUD_SY(CFG.ALT_TEXT_Y), altCol, CFG.ALT_TEXT_SQ, CFG.ALT_TEXT_SQ, 2, 0)
		elseif maxClip2 > 0 and clip2 >= 0 then
			local perc = clip2 / maxClip2
			local isLowClip = (perc <= CFG.STAT_LOW_PERC)
			local blink = 255 * math.abs(math.sin(RealTime() * 3))
			local col = Color(255, isLowClip and blink or 255, isLowClip and blink or 255)
			draw.SimpleTextOutlined(clip2, "BO2_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), col, 2, 0, outlined and 1 or 0, Color(0, 0, 0))
		end
    end

    if maxClip > 0 and clip >= 0 then
        local perc = clip / maxClip
        local isLowClip = (perc <= CFG.STAT_LOW_PERC)
		local blink = 255 * math.abs(math.sin(RealTime() * 3))
		local col = Color(255, isLowClip and blink or 255, isLowClip and blink or 255)
        DrawSqueezedText(clip, "BO2_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X+(altCache and 12 or 0)) - resw - (altCache and clipw or 0), ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), col, 0, 0, 0)
    end

    if maxClip > 0 and clip >= 0 and not reloading then
        local perc = clip / maxClip
        local statText = ""
        local statCol = Color(255, 255, 255)
        local isNoAmmo = false
        local isLowAmmo = false
        local isReloadText = false
        if clip == 0 and primCount == 0 then statText = "#MW2_WEAPON_NO_AMMO" isNoAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and primCount == 0 then statText = "#MW2_PLATFORM_LOW_AMMO_NO_RELOAD" statCol = Color(255, 230, 0) isLowAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and primCount > 0 then statText = "#MW2_PLATFORM_RELOAD" isReloadText = true end
        if statText ~= "" then
            local cx = ScrW() / 2
            local cy = (ScrH() / 2) + CoDHUD_SY(CFG.STAT_Y_OFF)
            local sine = (math.sin(CurTime() * CFG.STAT_FLASH_SPD) + 1) / 2
            local finalCol = table.Copy(statCol)
            if isNoAmmo then
                local glow = 225 + (sine * 30)
                finalCol = Color(glow, 40, 40, glow)
            elseif isLowAmmo or isReloadText then
                finalCol.a = 100 + (sine * 155)
            end
            draw.SimpleTextOutlined(language.GetPhrase(statText), "BO2_Stat_Font", cx + CoDHUD_SX(2), cy + CoDHUD_SY(2), finalCol, 1, 1, 1.5, Color(0, 0, 0, finalCol.a * 0.8))
        end
    end
end
CoDHUD[hudtype].WeaponInfo = weaponinfo
