CoDHUD.RegisterHUD( "bo1", "#CoDHUD.Type.bo1", true )

local hudtype = "bo1"

CoDHUD = CoDHUD or {}
CoDHUD[hudtype] = CoDHUD[hudtype] or {}
CoDHUD.Factions = CoDHUD.Factions or {}
CoDHUD.Gamemodes = CoDHUD.Gamemodes or {}

local textype = {
	"hud/bo1/delete.wav",
}

-- [[ SPECIAL KILLFEED ICONS ]]
if CLIENT then
	killicon.Add("CoDHUD_BO1_Suicide", hudtype .. "/killfeed/death_suicide.png", Color(255, 255, 255, 0))
	killicon.Add("CoDHUD_BO1_Headshot", hudtype .. "/killfeed/death_headshot.png", Color(255, 255, 255, 0))
end

-- [[ SUSPENSE ]]
CoDHUD[hudtype].SuspenseTracks = {
	"music/bo1/underscores/arclight_underscore_lp_b.wav",
	"music/bo1/underscores/blackbird_underscore_lp_a.wav",
	"music/bo1/underscores/canyonrock_underscore_lp_a.wav",
	"music/bo1/underscores/chopperintro_underscore_a.wav",
	"music/bo1/underscores/commies_underscore_a.wav",
	"music/bo1/underscores/deviant_underscore_a.wav",
	"music/bo1/underscores/eagleclaw_underscore_a.wav",
	"music/bo1/underscores/eagleclaw_underscore_b.wav",
	"music/bo1/underscores/foe_underscore_a.wav",
	"music/bo1/underscores/pentagon_underscore_a.wav",
}

-- [[ FACTIONS ]]
CoDHUD.Factions[hudtype] = {
	["op4"] = {
		name = "BO1_MP_REBELS_NAME",
		short = "BO1_MPUI_REBELS_SHORT",
		voicepath = "op4/vox_op4_",
		spawntheme = "spawn/long/mp_spawn_01.wav",
		victorytheme = "results/victory/eagleclaw_win_a.wav",
		defeattheme = "results/loss/foe_loss_a.wav",
		spawnIcon = hudtype .. "/factions/faction_128_op40.png",
		scoreIcon = hudtype .. "/factions/faction_128_op40.png",
		color = Color(101, 152, 151),
		killfeedcol = Color(100, 110, 120),
		order = 1
	},
	["ops"] = {
		name = "BO1_MP_SPECOPS_NAME",
		short = "BO1_MPUI_SPECOPS_SHORT",
		voicepath = "ops/vox_ops_",
		spawntheme = "spawn/long/pentagon_start_a.wav",
		victorytheme = "results/victory/eagleclaw_win_a.wav",
		defeattheme = "results/loss/pentagon_sting_b.wav",
		spawnIcon = hudtype .. "/factions/faction_128_specops.png",
		scoreIcon = hudtype .. "/factions/faction_128_specops.png",
		color = Color(101, 152, 151),
		killfeedcol = Color(100, 110, 120),
		order = 2
	},
	["sog"] = {
		name = "BO1_MP_MARINE_NAME",
		short = "BO1_MPUI_MARINE_SHORT",
		voicepath = "sog/vox_sog_",
		spawntheme = "spawn/long/chopperintro_spawn_long_a.wav",
		victorytheme = "results/victory/eagleclaw_win_a.wav",
		defeattheme = "results/loss/foe_loss_a.wav",
		spawnIcon = hudtype .. "/factions/faction_128_marines.png",
		scoreIcon = hudtype .. "/factions/faction_128_marines.png",
		color = Color(101, 152, 151),
		killfeedcol = Color(100, 110, 120),
		order = 3
	},
	["rus"] = {
		name = "BO1_MP_RUSSIAN_NAME",
		short = "BO1_MPUI_RUSSIAN_SHORT",
		voicepath = "rus/vox_rus_",
		spawntheme = "spawn/long/commies_match_start_a.wav",
		victorytheme = "results/victory/pentagon_treyarch_sting.wav",
		defeattheme = "results/loss/commies_sting_b.wav",
		spawnIcon = hudtype .. "/factions/faction_128_spetsnaz.png",
		scoreIcon = hudtype .. "/factions/faction_128_spetsnaz.png",
		color = Color(175, 50, 50),
		killfeedcol = Color(120, 110, 100),
		order = 4
	},
	["nva"] = {
		name = "BO1_MP_NVA_NAME",
		short = "BO1_MPUI_NVA_SHORT",
		voicepath = "nva/vox_nva_",
		spawntheme = "spawn/long/invictus_spawn_long_a.wav",
		victorytheme = "results/victory/pentagon_treyarch_sting.wav",
		defeattheme = "results/loss/foe_loss_a.wav",
		spawnIcon = hudtype .. "/factions/faction_128_nva.png",
		scoreIcon = hudtype .. "/factions/faction_128_nva.png",
		color = Color(175, 50, 50),
		killfeedcol = Color(120, 110, 100),
		order = 5
	},
	["cub"] = {
		name = "BO1_MP_TROPAS_NAME",
		short = "BO1_MPUI_TROPAS_SHORT",
		voicepath = "cub/vox_cub_",
		spawntheme = "spawn/long/mus_virus_downhill_perc_mp.wav",
		victorytheme = "results/victory/pentagon_treyarch_sting.wav",
		defeattheme = "results/loss/albion_sting_a.wav",
		spawnIcon = hudtype .. "/factions/faction_128_tropas.png",
		scoreIcon = hudtype .. "/factions/faction_128_tropas.png",
		color = Color(175, 50, 50),
		killfeedcol = Color(120, 110, 100),
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
	winningmusic = "music/bo1/timers/eagleclaw_timer_a.wav",
	losingmusic = "music/bo1/timers/invictus_time_a.wav",
	drawmusic = "music/bo1/results/draw/pentagon_lose_a.wav",
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
	sound = "hud/ui_mp_countdown_v1.mp3",
	timings = {
		[30] = 2,
		[10] = 1
	}
}

local function GetFactionColor(ent)
    if not IsValid(ent) then return Color(255,255,255) end
    local faction = ent:GetNW2String("CoDHUD_Faction", "rangers")
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
	{ "CoDHUD.SeshMode.TDM", "sesh_war" },
	{ "CoDHUD.SeshMode.FFA", "sesh_dm" },
	{ "CoDHUD.SeshMode.SD", "sesh_sd" },
	{ "CoDHUD.SeshMode.SDSet", "sesh_sd_set" },
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
	local textCol   = Color(255, 255, 50, alpha)
	local shadowCol = Color(0, 0, 0, alpha * 0.8)
	local s_val     = tostring(val)
	local partPlus  = "+"
	surface.SetFont("BO1_Score_Plus")
	local wP  = surface.GetTextSize(partPlus)
	local gapPlus = CoDHUD_SX(0)
	surface.SetFont("BO1_Score_Main")
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
	runX = runX + DrawComponent(partPlus, "BO1_Score_Plus", runX, y) + gapPlus
	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = DrawComponent(char, "BO1_Score_Main", runX, y)
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
	surface.SetMaterial( Material( "bo1/settings/menu_mp_background_main2.png" ) )
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
            pri = "BO1_ChalHeader",
            sub = "BO1_ChalSub",
        },
    })
    surface.PlaySound("music/bo1/stings/mp_milestone_sting.wav")
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
			pri = "BO1_RS_O_Pri",
			sec = "BO1_RS_O_Sec",
			shd = "BO1_RS_O_Shd"
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
			pri = "BO1_RS_H_Pri",
			sec = "BO1_RS_H_Sec",
			shd = "BO1_RS_H_Shd"
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
			draw.SimpleTextOutlined( disp, "BO1_RS_Timer", tx, ty, Color(255,255,100), 1, 1, outlined and 1 or 0, Color(0,0,0) )
		cam.PopModelMatrix()
		draw.SimpleTextOutlined( "#BO1_MP_MATCH_STARTING_IN", "BO1_RS_S_Pri", tx, ty + syo, Color(255,255,255), 1, 1, outlined and 1 or 0, Color(0,0,0) )
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
            pri = "BO1_RE_Sc_Pri",
            sec = "BO1_RE_Sc_Sec",
            shd = "BO1_RE_Sc_Shd",
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
			pri = "BO1_RE_Re_Pri",
			sec = "BO1_RE_Re_Sec",
			shd = "BO1_RE_Re_Shd",
			sub = "BO1_ChalSub"
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
			pri = "BO1_RE_Li_Pri",
			sec = "BO1_RE_Li_Sec",
			shd = "BO1_RE_Li_Shd",
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
	draw.SimpleTextOutlined( string.format( language.GetPhrase("MW2_MP_MATCH_BONUS_IS"), tostring(re_match_bonus) ), "BO1_RE_Bonus", CoDHUD_SX(960), CoDHUD_SY(720), Color(240, 250, 110, iconAlpha), 1, 1, outlined and 1 or 0, Color(0,0,0, iconAlpha) )
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

local function xp( ... )
	local animtime = select(1, ...)
	local scoreTime = select(2, ...)
	local finalAlpha = select(3, ...)
	local scoreScale = select(4, ...)
	local currentPulseAlpha = select(5, ...)
	local scoreVal = select(6, ...)
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
	local cx, cy = ScrW() / 2, ScrH() / 2
	local drawAlpha = (currentPulseAlpha / 255) * finalAlpha
	local drawY     = cy - CoDHUD_SY(140)
	local mat = Matrix()
	mat:Translate(Vector(cx, drawY, 0))
	mat:Scale(Vector(scoreScale, scoreScale, 1))
	mat:Translate(Vector(-cx, -drawY, 0))
	cam.PushModelMatrix(mat)
		DrawSqueezedScore(scoreVal, cx, drawY, drawAlpha)
	cam.PopModelMatrix()
end
CoDHUD[hudtype].XP = xp

local function dmg_dir( ... )
	local attackers = select(1, ...)
	local ply = select(2, ...)
    local cx, cy = ScrW() / 2, ScrH() / 2
	local matDamage = Material(hudtype .. "/icons/hit_direction.png", "mips smooth")
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
	local matIcon = Material(hudtype .. "/hud/grenadeicon.png", "mips smooth")
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
        surface.SetFont("BO1_KillfeedFont")
		local aColBase = GetFactionColor(data.attackerEnt)
		local vColBase = GetFactionColor(data.victimEnt)
		local aCol = Color(aColBase.r, aColBase.g, aColBase.b, finalTxtAlpha)
		local vCol = Color(vColBase.r, vColBase.g, vColBase.b, finalTxtAlpha)
        if data.type == "kill" then
			local cls = data.isHeadshot and "CoDHUD_BO1_Headshot" or data.weaponClass
			local w, h = killicon.GetSize(cls)
			if not w or w <= 0 then w = ICON_BOX_W end
			if not h or h <= 0 then h = ICON_BOX_H end
			local gap = CoDHUD_S(10)
			if data.attackerName != "" then
				draw.SimpleText(data.attackerName, "BO1_KillfeedFont", x, currentY, aCol)
				local tw, _ = surface.GetTextSize(data.attackerName)
				x = x + tw
			end
			local iconY = currentY + (ICON_BOX_H - h) * 0.5
			local alpha = math.min(165 * fadeFactor, 255)
			local offsetY = CoDHUD_S(-15)
			if cls == "CoDHUD_BO1_Headshot" then offsetY = CoDHUD_S(-2) end
			killicon.Render(x + gap, iconY + (h * 0.33) + offsetY, cls, alpha, false, false)
			x = x + w + (gap * 2)
			draw.SimpleText(data.victimName, "BO1_KillfeedFont", x, currentY, vCol)
        else
            draw.SimpleText(data.msg, "BO1_KillfeedFont", x, currentY, Color(255, 255, 255, finalTxtAlpha))
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
	cam.PushModelMatrix(mat)
		surface.SetDrawColor(255, 0, 0, math.Clamp(alpha, 0, 50))
		surface.SetMaterial(Material(hudtype .. "/icons/hud_notification_medal_backing.png", "smooth"))
		surface.DrawTexturedRect(cx - iconSize, cy - (iconSize * 0.5), iconSize * 2, iconSize)
		draw.SimpleTextOutlined( language.GetPhrase(activeMedal.text), "BO1_MedalPrimary", cx, cy - CoDHUD_S(20), colWhite, 1, 1, outlined and 1.5 or 0, colBlack )
		if activeMedal.desc then
			local localizedDesc = language.GetPhrase(activeMedal.desc)
			if activeMedal.isSpecial then
				draw.SimpleTextOutlined( localizedDesc, "BO1_MedalDesc", cx, cy + CoDHUD_S(25), colWhite, 1, 1, outlined and 1 or 0, colBlack )
			else
				local descText   = localizedDesc
				local pointsText = " +" .. activeMedal.points
				local bracketClose = ""
				surface.SetFont("BO1_MedalPoints")
				local w2 = surface.GetTextSize(pointsText)
				surface.SetFont("BO1_MedalDesc")
				local w1 = surface.GetTextSize(descText)
				local totalW = w1 + w2 + surface.GetTextSize(bracketClose)
				local startX = cx - (totalW / 2)
				draw.SimpleTextOutlined( descText, "BO1_MedalDesc", startX, cy + CoDHUD_S(30), colWhite, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( pointsText, "BO1_MedalPoints", startX + w1, cy + CoDHUD_S(30), colYellow, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( bracketClose, "BO1_MedalDesc", startX + w1 + w2, cy + CoDHUD_S(30), colWhite, 0, 1, outlined and 1 or 0, colBlack )
			end
		else
			draw.SimpleTextOutlined( "+" .. activeMedal.points, "BO1_MedalDesc", cx, cy + CoDHUD_S(30), colYellow, 1, 1, outlined and 1 or 0, colBlack )
		end
	cam.PopModelMatrix()
end
CoDHUD[hudtype].Medals = medals
CoDHUD[hudtype].MedalsSound = "hud/bo1/repeatable.wav"
CoDHUD[hudtype].MedalsTable = {
	["headshot"] = { "BO1_MEDAL_HEAD_SHOT", "BO1_MEDAL_HEAD_SHOT_DESC" },
	["doublekill"] = { "BO1_MEDAL_DOUBLE_KILL", "BO1_MEDAL_DOUBLE_KILL_DESC" },
	["triplekill"] = { "BO1_MEDAL_TRIPLE_KILL", "BO1_MEDAL_TRIPLE_KILL_DESC" },
	["multikill"] = { "BO1_MEDAL_MULTI_KILL", "BO1_MEDAL_MULTI_KILL_DESC" },
	["longshot"] = { "BO1_MEDAL_LONG_SHOT", "BO1_MEDAL_LONG_SHOT_DESC" },
	["oneshot"] = { "BO1_MEDAL_ONE_SHOT_KILL", "BO1_MEDAL_ONE_SHOT_KILL_DESC" },
	["firstblood"] = { "BO1_MEDAL_FIRST_BLOOD", "BO1_MEDAL_FIRST_BLOOD_DESC" },
	["comeback"] = { "BO1_MEDAL_COMEBACK", "BO1_MEDAL_COMEBACK_DESC" },
	["payback"] = { "BO1_MEDAL_PAYBACK", "BO1_MEDAL_PAYBACK_DESC" },
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
	local MAT_BORDER       = Material(hudtype .. "/minimap/compass_map_border.png", "smooth")
	local MAT_MAP_BG       = Material("cod4/minimap/compass_map_default.png", "smooth")
	local MAT_PLAYER       = Material(hudtype .. "/minimap/compassping_player.png", "smooth")
	local MAT_FRIEND_HOLLOW = Material(hudtype .. "/minimap/compassping_green_hollow_mp.png", "smooth")
	local MAT_ENEMY_FIRING  = Material(hudtype .. "/minimap/compassping_enemyfiring.png", "smooth")
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
                -- Sesh modes: always show enemy bots on the minimap, no
                -- visibility/line-of-sight requirement.
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

local MAT_GRADIENT = Material("vgui/gradient-r")

local function scorebar(data)
	local CFG = {
		BAR_W = 512, BAR_H = 128, BAR_X_OFF = -64, BAR_Y_OFF = 0,
		ICON_SCALE = 1.15, ICON_X = 73.5, ICON_Y = -35.5,
		TIMER_X = 150, TIMER_Y = -64, TIMER_SHIFT_2DIG = 0, TIMER_SHIFT_3DIG = 0, TIMER_OUTLINE_W = 1.5,
		STATUS_X = 242.5, STATUS_Y = 2,
		SQUEEZE = 0, SQUEEZE_ONE = 0, SQUEEZE_ONE_BEFORE = 0,
	}
	local SCORES_CFG = {
		X = 177.5, Y = 87.5, GAP_OFFSET = 44,
		SQUEEZE = -2, SQUEEZE_ONE = -6, SQUEEZE_ONE_BEFORE = -12, OUTLINE_W = 1.5,
		SCORE_LIMIT = 75,
		HUD_X = 187.5, HUD_Y = 38, HUD_W_BASE = 0, HUD_W_MAX = 215, HUD_H = 43, HUD_H_LOWER = 31.5,
		SLANT_SIZE = 11, VERTICAL_GAP = 5, SHADOW_OFFSET = 2,
		BASE_X = 52, BASE_Y = 97, BASE_W = 384, BASE_H = 99,
	}
	local ARROW_CFG = {
		x = 140, y = 978, size = 24,
		color = Color(255, 255, 255),
		material = Material(hudtype .. "/hud/ui_arrow_right.png", "smooth noclamp"),
	}

    local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local currentFaction = ply:GetNW2String("CoDHUD_Faction", "")
    if currentFaction == "" then
        currentFaction = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
        if not CoDHUD.Factions[hudtype][currentFaction] then currentFaction = "rangers" end
        ply:SetNW2String("CoDHUD_Faction", currentFaction)
    end

    local scrW, scrH = ScrW(), ScrH()
    local barW, barH = CoDHUD_SX(CFG.BAR_W), CoDHUD_SY(CFG.BAR_H)
    local barX = CoDHUD_SX(CFG.BAR_X_OFF)
    local barY = scrH - CoDHUD_SY(CFG.BAR_Y_OFF) - barH

    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(Material(hudtype .. "/hud/hud_frame_faction_lines.png", "smooth"))
    surface.DrawTexturedRect(barX, barY, barW, barH)

	local factionData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][currentFaction]
	local factionMat = factionData and factionData.scoreIcon
	if not factionData then currentFaction = "rangers" factionData = CoDHUD.Factions[hudtype][currentFaction] end
	if factionMat then
		local iSize = math.Round(barH * CFG.ICON_SCALE)
		surface.SetDrawColor(255, 255, 255, 175)
		surface.SetMaterial(Material(hudtype .. "/hud/hud_faction_back_light.png", "smooth"))
		surface.DrawTexturedRect( barX + CoDHUD_SX(CFG.ICON_X * 0.75), barY + CoDHUD_SY(CFG.ICON_Y * 1.25), iSize * 1.25, iSize * 1.25)
		surface.SetMaterial(Material(factionMat, "smooth"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect( barX + CoDHUD_SX(CFG.ICON_X), barY + CoDHUD_SY(CFG.ICON_Y), iSize, iSize )
	end

    local timeStr = data.timeStr
    local mins = data.mins
    local xShift =
        (#tostring(mins) >= 3 and CoDHUD_SX(CFG.TIMER_SHIFT_3DIG)) or
        (#tostring(mins) >= 2 and CoDHUD_SX(CFG.TIMER_SHIFT_2DIG)) or 0
	local timecol = Color(225,225,255)
	if data.timeRaw > 30 and data.timeRaw < 60 then timecol = Color(218,136,43)
	elseif data.timeRaw < 30 then timecol = Color(255,100,100) end
	local shouldDrawTimer = data.timeRaw > 0.1 and (CoDHUD_MatchMaxTime <= 0 or data.timeRaw <= CoDHUD_MatchMaxTime)
	if shouldDrawTimer then
		DrawSqueezedText( timeStr, "BO1_Timer", barX + CoDHUD_SX(CFG.TIMER_X) + xShift, barY + CoDHUD_SY(CFG.TIMER_Y), timecol, CFG.SQUEEZE, CFG.SQUEEZE_ONE, 1, CFG.SQUEEZE_ONE_BEFORE, CoDHUD_SX(CFG.TIMER_OUTLINE_W) )
	end
	data.tiedCol = Color(110, 220, 120, 255)
	data.winningCol = Color(215, 110, 120, 255)
	data.losingCol = Color(230, 230, 110, 255)
    local statusStr = data.statusResolved and data.statusText or language.GetPhrase(data.statusText)
    local statusOut = data.statusOutline or (outlined and 1 or 0)
    draw.SimpleTextOutlined( statusStr, "BO1_Status", barX + CoDHUD_SX(CFG.STATUS_X), barY + CoDHUD_SY(CFG.STATUS_Y), data.statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, statusOut, Color(0,0,0) )

    local clientKills   = data.clientScore
    local topEnemyKills = data.enemyScore
    local S_CFG = SCORES_CFG

    local baseX  = CoDHUD_S(S_CFG.BASE_X)
    local baseY  = scrH - CoDHUD_S(S_CFG.BASE_Y)
    local baseW  = CoDHUD_S(S_CFG.BASE_W)
    local baseH  = CoDHUD_S(S_CFG.BASE_H)
    local hudX   = CoDHUD_S(S_CFG.HUD_X)
    local hudY   = scrH - CoDHUD_S(S_CFG.HUD_Y)
    local hudWBase = CoDHUD_S(S_CFG.HUD_W_BASE)
    local hudWMax  = CoDHUD_S(S_CFG.HUD_W_MAX)
    local hudH     = CoDHUD_S(S_CFG.HUD_H)
    local hudHLower = CoDHUD_S(S_CFG.HUD_H_LOWER)
    local vertGap  = CoDHUD_S(S_CFG.VERTICAL_GAP)

    local liveScoreLimit = S_CFG.SCORE_LIMIT
    local gmCV2 = GetConVar("codhud_selected_gamemode")
    if gmCV2 and gmCV2:GetString() == "sesh_dm" then
        -- Sesh FFA has its own hardwired limit, independent of codhud_score_limit
        liveScoreLimit = 30
    elseif gmCV2 and (gmCV2:GetString() == "sd" or gmCV2:GetString() == "sesh_sd" or gmCV2:GetString() == "sesh_sd_set") then
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

	-- Use gamemode-aware multiplier
	local scoreMultiplier = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100
	liveScoreLimit = liveScoreLimit * scoreMultiplier

    local maxAddedWidth = hudWMax - hudWBase
    local client_w = math.Round(hudWBase + math.Clamp(((clientKills * scoreMultiplier) / liveScoreLimit) * maxAddedWidth, 0, maxAddedWidth))
    local enemy_w  = math.Round(hudWBase + math.Clamp(((topEnemyKills * scoreMultiplier) / liveScoreLimit) * maxAddedWidth, 0, maxAddedWidth))

    local HUD_X = hudX
    local HUD_Y = hudY
    local top_y = HUD_Y - vertGap - hudH
    local white = Color(255,255,255,255)

    surface.SetDrawColor(255, 255, 255, 175)
    surface.SetMaterial(Material(hudtype .. "/hud/hud_frame_faction_fade.png", "smooth"))
    surface.DrawTexturedRect(baseX, baseY, baseW, baseH)

	surface.SetMaterial(MAT_GRADIENT)
	surface.SetDrawColor(Color(110, 180, 90))
	surface.DrawTexturedRect(hudX, top_y, client_w, hudH)

	surface.SetMaterial(MAT_GRADIENT)
	surface.SetDrawColor(Color(180, 55, 55))
	surface.DrawTexturedRect(hudX, hudY, enemy_w, hudHLower)

    surface.SetMaterial(ARROW_CFG.material)
    surface.SetDrawColor(ARROW_CFG.color)
    surface.DrawTexturedRectRotated(hudX + client_w, top_y, ARROW_CFG.size, ARROW_CFG.size, -90)
    surface.DrawTexturedRectRotated(hudX + enemy_w, hudY + hudHLower, ARROW_CFG.size, ARROW_CFG.size, 90)

    DrawSqueezedText(clientKills * scoreMultiplier,   "BO1_Font",  CoDHUD_SX(S_CFG.X) - CoDHUD_SX(2.5), ScrH() - CoDHUD_SY(S_CFG.Y), white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)
    DrawSqueezedText(topEnemyKills * scoreMultiplier, "BO1_Font2", CoDHUD_SX(S_CFG.X), ScrH() - CoDHUD_SY(S_CFG.Y) + CoDHUD_S(S_CFG.GAP_OFFSET), white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)
end
CoDHUD[hudtype].Scorebar = scorebar

local function scoreboard( ... )
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	local CFG = {
		BAR_W = 1086, BAR_H = 28, BAR_X_OFF = 0, BAR_Y_OFF = 235, BAR_ALPHA = 200,
		ROW_GAP = 8, TEAM_GAP = 90,
		ICON_SIZE = 96, ICON_X_OFF = -111, ICON_Y_OFF = -52.5,
		FAC_NAME_X = 0, FAC_NAME_Y = -44,
		STATS_HEADER_Y = -45,
		HEADER_Y_POS = 90, HEADER_H = 50, HEADER_ALPHA = 255,
		HEADER_ICON_SIZE = 86, HEADER_ICON_X = 140, HEADER_ENEMY_ICON_X = 340,
		MAP_Y_OFF = 98,
		TIMER_X_POS = 462.5, TIMER_Y_OFF = 18,
		SQUEEZE = 0, SQUEEZE_ONE = -0, SQUEEZE_ONE_BEFORE = -0,
		OFF_PING = 10, OFF_DEATHS = 120, OFF_RATIO = 240, OFF_ASSISTS = 360, OFF_KILLS = 480, OFF_SCORE = 600,
	}

	local MAT_GRADIENT_L = Material("vgui/gradient-l")
	local MAT_ICON_DEAD  = Material(hudtype .. "/icons/hud_status_dead.png", "mips smooth")
	local viewportTop    = CoDHUD_S(175)
	local viewportHeight = CoDHUD_S(800)
	local viewportBottom = viewportTop + viewportHeight

	local function SortLogic(a, b)
		local sbMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100
		local scoreA = math.max(0, a:Frags() * sbMul)
		local scoreB = math.max(0, b:Frags() * sbMul)
		if scoreA == scoreB then
			if a == LocalPlayer() then return true end
			if b == LocalPlayer() then return false end
			return a:Nick() < b:Nick()
		end
		return scoreA > scoreB
	end

	local function DrawPlayerRow(ply, lp, x, y, w, h, barRight, bgCol)
		surface.SetDrawColor(bgCol.r, bgCol.g, bgCol.b, CFG.BAR_ALPHA)
		surface.DrawRect(x, y, w, h)
		if ply:IsValid() and not ply:Alive() then
			surface.SetMaterial(MAT_ICON_DEAD)
			surface.SetDrawColor(255, 255, 255, 255)
			local iconSz = h * 0.8
			surface.DrawTexturedRect(x + CoDHUD_S(75), y + (h / 2) - (iconSz / 2), iconSz, iconSz)
		end
		local isMe = (ply == lp)
		local tCol = isMe and Color(255, 200, 50, 255) or Color(255, 255, 255, 255)
		local pScore = math.max(0, ply:Frags() * (CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100))
		local kills = ply:Frags()
		local deaths = ply:Deaths()
		local ratio = 0
		if kills > 0 then ratio = kills / (deaths > 1 and deaths or 1) end
		local kd = string.format("%.2f", ratio)
		draw.SimpleTextOutlined(ply:Nick(), "BO1_Scoreboard_Text", x + CoDHUD_S(110), y + (h / 2), tCol, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:Ping(), "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_PING),    y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(deaths,     "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_DEATHS),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(kd,         "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_RATIO),   y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:GetNWInt("Assists", 0), "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_ASSISTS), y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(kills,  "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_KILLS),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(pScore, "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_SCORE),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
	end

    local scrW, scrH = ScrW(), ScrH()
    local lp = LocalPlayer()

	local factions = {}
	for _, p in ipairs(player.GetAll()) do
		-- "rangers" was being used as the fallback for ANY player whose
		-- faction hasn't networked to this client yet (a brief window right
		-- after a bot spawns) -- since "rangers" also happens to be the
		-- default human faction, that visually merged a not-yet-synced bot
		-- into the player's own team on the scoreboard. Only guess for the
		-- local player (so you always see yourself immediately); for anyone
		-- else, skip them this frame rather than guess wrong -- their real
		-- faction shows up correctly within a tick or two.
		local fac = p:GetNW2String("CoDHUD_Faction", "")
		if fac == "" then
			if p == lp then
				fac = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
			else
				continue
			end
		end
		factions[fac] = factions[fac] or {}
		table.insert(factions[fac], p)
	end
	if CoDHUD.Sesh and CoDHUD.Sesh.FillEnemyGroup then CoDHUD.Sesh.FillEnemyGroup(factions) end

	local factionList = {}
	for fac, players in pairs(factions) do
		table.sort(players, SortLogic)
		table.insert(factionList, { key = fac, players = players, score = 0 })
	end

	local sbMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 100
	local gmSB = GetConVar("codhud_selected_gamemode")
	local isSeshSD_SB = gmSB and (gmSB:GetString() == "sesh_sd" or gmSB:GetString() == "sesh_sd_set")
	local myFacSB = lp:GetNW2String("CoDHUD_Faction", "")
	for _, f in ipairs(factionList) do
		if isSeshSD_SB and _G.KC_SD_SeshRoundsA ~= nil then
			f.score = (f.key == myFacSB) and (_G.KC_SD_SeshRoundsA or 0) or (_G.KC_SD_SeshRoundsB or 0)
		else
			local score = 0
			for _, p in ipairs(f.players) do
				score = score + math.max(0, p:Frags() * sbMul)
			end
			f.score = score
		end
	end

	table.sort(factionList, function(a, b) return a.score > b.score end)

	-- Move the local player's own team to the front (top) of the list,
	-- without changing the ordering of everyone else. Done as a plain
	-- array move (not a custom table.sort comparator) so there's no risk
	-- of an inconsistent comparator corrupting the list.
	local myFactionSort = lp:GetNW2String("CoDHUD_Faction", "")
	for i, f in ipairs(factionList) do
		if f.key == myFactionSort then
			if i > 1 then table.insert(factionList, 1, table.remove(factionList, i)) end
			break
		end
	end

    local barW = CoDHUD_S(CFG.BAR_W)
    local barH = CoDHUD_S(CFG.BAR_H)
    local barX = (scrW / 2) - (barW / 2) + CoDHUD_S(CFG.BAR_X_OFF)
    local barRight = barX + barW

	CoDHUD.Scoreboard.ContentHeight = 0
	for _, facData in ipairs(factionList) do
		local factionHeight = CoDHUD_S(CFG.ICON_SIZE) + (#facData.players * (barH + CoDHUD_S(CFG.ROW_GAP))) + CoDHUD_S(CFG.TEAM_GAP)
		CoDHUD.Scoreboard.ContentHeight = CoDHUD.Scoreboard.ContentHeight + factionHeight
	end
	CoDHUD.Scoreboard.ContentHeight = CoDHUD.Scoreboard.ContentHeight + CoDHUD_S(200)

	local sb = CoDHUD.Scoreboard
	local startY = CoDHUD_S(CFG.BAR_Y_OFF) - math.floor(sb.Scroll)
	local headerY = CoDHUD_S(CFG.BAR_Y_OFF) - CoDHUD_S(35) - CoDHUD.Scoreboard.Scroll

	render.SetScissorRect(0, viewportTop, ScrW(), viewportBottom, true)
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_PING"),   "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_PING),    headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_DEATHS"), "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_DEATHS),  headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_KDRATIO"),"BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_RATIO),   headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_ASSISTS"),"BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_ASSISTS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_KILLS"),  "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_KILLS),   headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("BO1_CGAME_SB_SCORE"),  "BO1_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_SCORE),   headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )

		for fi, facData in ipairs(factionList) do
			local players = facData.players
			local facKey = facData.key
			local score = facData.score or 0
			local fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][facKey] or {
				name = facKey, short = facKey, color = Color(120,120,120)
			}
			local sectionY = startY
			local iconPath = CoDHUD.Factions[hudtype][facKey].scoreIcon
			local mat = Material(iconPath, "smooth")
			surface.SetMaterial(mat)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(barX + CoDHUD_S(CFG.ICON_X_OFF), sectionY + CoDHUD_S(CFG.ICON_Y_OFF), CoDHUD_S(CFG.ICON_SIZE), CoDHUD_S(CFG.ICON_SIZE))
			DrawSqueezedText( score, "BO1_Scoreboard_Score", barX + CoDHUD_SX(CFG.FAC_NAME_X), sectionY + CoDHUD_S(CFG.FAC_NAME_Y) - CoDHUD_S(22), Color(255,255,255), CoDHUD_S(-2), CoDHUD_S(-6), 2, CoDHUD_S(-12), CoDHUD_SX(1) )
			surface.SetFont("BO1_Scoreboard_Score")
			local scorew, scoreh = surface.GetTextSize(score)
			draw.SimpleTextOutlined( language.GetPhrase(fData.short) .. " ( " .. #players .. " )", "BO1_Scoreboard_Text", barX + CoDHUD_S(CFG.FAC_NAME_X) + CoDHUD_S(scorew + 10), sectionY + CoDHUD_S(CFG.FAC_NAME_Y), Color(255,255,255), 0,0, outlined and 1 or 0, Color(0,0,0) )
			for i, ply in ipairs(players) do
				local rowY = sectionY + (i - 1) * (barH + CoDHUD_S(CFG.ROW_GAP))
				DrawPlayerRow(ply, lp, barX, rowY, barW, barH, barRight, fData.color)
			end
			local sectionHeight = CoDHUD_S(0) + (#players * (barH + CoDHUD_S(CFG.ROW_GAP)))
			startY = startY + sectionHeight + CoDHUD_S(CFG.TEAM_GAP)
		end
	render.SetScissorRect(0, 0, 0, 0, false)

    local totalSecs = math.floor(CurTime())
    local mins, secs = math.floor(totalSecs / 60), totalSecs % 60
    local timeStr = string.format("%d:%02d", mins, secs)
    DrawSqueezedText(timeStr, "BO1_Scoreboard_Timer", scrW - CoDHUD_S(CFG.TIMER_X_POS), CoDHUD_S(CFG.TIMER_Y_OFF), Color(255, 255, 255, 255), CFG.SQUEEZE, CFG.SQUEEZE_ONE, 1, CFG.SQUEEZE_ONE_BEFORE, outlined and 1.5 or 0)
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
	surface.SetFont("BO1_TargetName_Primary")
	local tw, th = surface.GetTextSize(displayName)
	tw, th = tw * finalScale, th * finalScale
	local drawX, drawY = screenData.x - (tw / 2), screenData.y - (th / 2)
	local matrix = Matrix()
	matrix:Translate(Vector(drawX, drawY, 0))
	matrix:Scale(Vector(finalScale, finalScale, 1))
	cam.PushModelMatrix(matrix)
		draw.SimpleText(displayName, "BO1_TargetName_Primary", 0, 0, Color(factionColor.r, factionColor.g, factionColor.b, alpha), 0, 0)
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
	draw.SimpleText(ply:Nick(), "BO1_VoiceFont", VOICE_X + ICON_SIZE + TEXT_X_OFFSET, drawY, Color(255, 255, 255), 0, 0)
	yOffset = yOffset + SPACING
end
CoDHUD[hudtype].VoiceChat = voice

local debugpicture = Material("debugref/bo1.png", "smooth")

local function weaponinfo(...)
	if debugpic then
		surface.SetMaterial(debugpicture)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	local MASK = select(1, ...)
	local ply = select(3, ...)

	local CFG = {
		BAR_W = 210, BAR_H = 210, BAR_X_OFF = 0, BAR_Y_OFF = -10,
		LINES_W = 295, LINES_H = 142.5, LINES_X_OFF = 131, LINES_Y_OFF = -20,
		GRENADE_X_OFF = 242.5, GRENADE_Y_OFF = 40, GRENADE_ICON_W = 40, GRENADE_ICON_H = 40,
		GRENADE_STACK_GAP = -4, GRENADE_MAX = 4, GRENADE_SHADES = { 255, 200, 175, 120 },
		RES_X = 200, RES_Y = 80,
		SQUEEZE = -6, SQUEEZE_ONE = -14, SQUEEZE_ONE_BEFORE = -10,
		WEP_NAME_X_OFF = 200, WEP_NAME_Y_OFF = 130, WEP_NAME_FADE = 2, WEP_NAME_SQ = -3, WEP_NAME_SQ1 = -8,
		STAT_FONT_SIZE = 28, STAT_LOW_PERC = 0.40, STAT_FLASH_SPD = 8, STAT_Y_OFF = 62,
		ALT_ICON_SIZE = 210, ALT_ICON_X = 256 + 5, ALT_ICON_Y = 256 - 64 + 5,
		ALT_TEXT_X = 170, ALT_TEXT_Y = 95, ALT_TEXT_SQ = 0, ALT_TEXT_SQ1 = 0,
		ALT_WICON_SIZE = 64 + 8, ALT_WICON_X = 256 - 64 + 10, ALT_WICON_Y = 128 + 5,
	}

	local MAT_FRAME  = Material(hudtype .. "/hud/hud_dpad_outer_frame.png", "smooth")
	local MAT_LINES  = Material(hudtype .. "/hud/hud_dpad_lines.png", "smooth")
	local MAT_FADE   = Material(hudtype .. "/hud/hud_dpad_lines_fade.png", "smooth")
	local MAT_DPAD_LEFT = Material(hudtype .. "/hud/hud_dpad_outer_frame_highlight_side.png", "smooth")
	local MAT_ALT = {
		["grenade"] = Material(hudtype .. "/icons/hud_40mmgrenade.png", "smooth mips"),
		["buckshot"] = Material(hudtype .. "/icons/hud_mk_generic.png", "smooth mips"),
		["flame"] = Material(hudtype .. "/icons/hud_flamethrower_dpad.png", "smooth mips")
	}
	local MAT_GRENADE = Material(hudtype .. "/hud/grenadeicon.png", "smooth")
	local MAT_COMPASS = Material(hudtype .. "/hud/hud_border_dpad_compass.png", "smooth")

	local cX = ScrW() - (CoDHUD_SX(CFG.BAR_W) * 0.5)
    local cY = ScrH() - (CoDHUD_SX(CFG.BAR_H) * 0.425)
    local size = CoDHUD_S(246)
    local yaw  = ply:EyeAngles().y
    local angle = -(yaw - 0)
    local halfFOV = 72.5
    local radius  = size * math.sqrt(2) / 2 + 2
    local steps   = 5
    render.SetStencilEnable(true)
    render.ClearStencil()
    render.SetStencilWriteMask(255)
    render.SetStencilTestMask(255)
    render.SetStencilReferenceValue(1)
    render.SetStencilCompareFunction(STENCIL_ALWAYS)
    render.SetStencilPassOperation(STENCIL_REPLACE)
    render.SetStencilFailOperation(STENCIL_KEEP)
    render.SetStencilZFailOperation(STENCIL_KEEP)
    render.OverrideColorWriteEnable(true, false)
    draw.NoTexture()
    surface.SetDrawColor(255, 255, 255, 255)
    for i = 0, steps - 1 do
        local a0 = math.rad(-halfFOV + (i / steps)       * MASK.FOV)
        local a1 = math.rad(-halfFOV + ((i + 1) / steps) * MASK.FOV)
        surface.DrawPoly({
            { x = cX, y = cY },
            { x = cX + math.sin(a0) * radius, y = cY - math.cos(a0) * radius },
            { x = cX + math.sin(a1) * radius, y = cY - math.cos(a1) * radius },
        })
    end
    render.OverrideColorWriteEnable(false, false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    surface.SetMaterial(MAT_COMPASS)
    surface.SetDrawColor(255, 255, 255, 165)
    surface.DrawTexturedRectRotated(cX, cY, size, size, angle)
    render.SetStencilEnable(false)

    local grenadeCount = math.Clamp(ply:GetAmmoCount("Grenade") or 0, 0, CFG.GRENADE_MAX)
    if grenadeCount > 0 then
        local barW = CoDHUD_SX(CFG.BAR_W)
        local barH = CoDHUD_SY(CFG.BAR_H)
        local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF) - barW
        local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH
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
    -- Equipment (kc_equip_knife, ported items flagged SWEP.KC_IsEquipment)
    -- keeps the name plate but never shows ammo/clip/reload text -- it has no
    -- meaningful ammo count to a player (single use, or non-clip based).
    local isEquipment = wep.KC_IsEquipment == true

    local clip    = wep:Clip1()
    local clip2   = wep:Clip2()
    local maxClip = wep:GetMaxClip1()
    local maxClip2 = wep:GetMaxClip2()
    local primType = wep:GetPrimaryAmmoType()
    local altType = wep:GetSecondaryAmmoType()
	local altAmmoName = game.GetAmmoName(altType)
    local primCount = ply:GetAmmoCount(primType)
	local altCount = ply:GetAmmoCount(altType)

    local barW = CoDHUD_SX(CFG.BAR_W)
    local barH = CoDHUD_SY(CFG.BAR_H)
    local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF) - barW
    local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH

    surface.SetMaterial(MAT_FRAME)
    surface.SetDrawColor(255, 255, 255)
    surface.DrawTexturedRect(barX, barY, barW, barH)

    local lineW = CoDHUD_SX(CFG.LINES_W)
    local lineH = CoDHUD_SY(CFG.LINES_H)
    local lineX = ScrW() - CoDHUD_SX(CFG.LINES_X_OFF) - lineW
    local lineY = ScrH() - CoDHUD_SY(CFG.LINES_Y_OFF) - lineH
    surface.SetDrawColor(255, 255, 255)
    surface.SetMaterial(MAT_LINES)
    surface.DrawTexturedRect(lineX + CoDHUD_SX(6), lineY + CoDHUD_SY(3), lineW, lineH)
    surface.SetMaterial(MAT_FADE)
    surface.DrawTexturedRect(lineX, lineY, lineW, lineH)

	local reloading =
	wep.IsReloading or reloadingM203
	or (wep.ARC9 and wep:GetReloading())
	or (wep.ArcCW and wep:GetReloading())
	or (wep.IsTFAWeapon and TFA.Enum.ReloadStatus[wep:GetStatus()])

	local glactive =
	wep.dt and (wep.dt.AltActive or wep.dt.M203Active)
	or (wep.ARC9 and wep:GetUBGL())

	if glactive then clip = clip2 maxClip = maxClip2 primCount = altCount end

	surface.SetFont("BO1_Res")
	local restext = " / " .. primCount
	local resw, resh = surface.GetTextSize(restext)
	surface.SetFont("BO1_Res_Large")
	local clipw, cliph = surface.GetTextSize(maxClip)
	surface.SetFont("BO1_Res")

	if not isEquipment and primType ~= -1 then
        local resCol = (primCount == 0 or primCount < maxClip) and Color(255, 120, 120, 255) or Color(255, 255, 255, 255)
		if maxClip > 0 then
			DrawSqueezedText(restext, "BO1_Res", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y), resCol, 0, 0, 2, 0)
		else
			surface.SetFont("BO1_Res_Large")
			local restext, resw = tostring(primCount), surface.GetTextSize(primCount)
			DrawSqueezedText(primCount, "BO1_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), resCol, 0, 0, 2)
			surface.SetFont("BO1_Res")
		end
    end

    local timeSinceSwitch = CurTime() - wepSwitchTime
    if timeSinceSwitch < CFG.WEP_NAME_FADE then
        local alpha = math.Clamp(1 - (timeSinceSwitch / CFG.WEP_NAME_FADE), 0, 1)
        local name  = language.GetPhrase(wep:GetPrintName() or wep:GetClass())
        draw.SimpleTextOutlined(name, "BO1_Wep_Name", ScrW() - CoDHUD_SX(CFG.WEP_NAME_X_OFF), ScrH() - CoDHUD_SY(CFG.WEP_NAME_Y_OFF), Color(255, 255, 255, 255 * alpha), 2, 0, outlined and 1.5 or 0, Color(0, 0, 0, 255 * alpha))
    end

	local altCache = (altType == primType or altType == game.GetAmmoID("Grenade") and maxClip2 > 0)

    if not isEquipment and altType ~= -1 then
		if altType ~= primType and altType ~= game.GetAmmoID("Grenade") then
			surface.SetFont("BO1_Ammo_Alt")
			local altLen = #tostring(altCount)
			local altw, alth = surface.GetTextSize(altCount)
			local altPad = (altw + (altLen * CFG.ALT_TEXT_SQ))
			surface.SetMaterial(MAT_DPAD_LEFT)
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(ScrW() - CoDHUD_SX(CFG.ALT_ICON_X), ScrH() - CoDHUD_SY(CFG.ALT_ICON_Y), CoDHUD_S(CFG.ALT_ICON_SIZE), CoDHUD_S(CFG.ALT_ICON_SIZE))
			local alticon = "grenade"
			if altAmmoName == "Buckshot" then alticon = "buckshot" end
			surface.SetMaterial(MAT_ALT[alticon])
			surface.SetDrawColor(255, 255, 255)
			surface.DrawTexturedRect(ScrW() - CoDHUD_SX(CFG.ALT_WICON_X), ScrH() - CoDHUD_SY(CFG.ALT_WICON_Y), CoDHUD_S(CFG.ALT_WICON_SIZE), CoDHUD_S(CFG.ALT_WICON_SIZE))
			local altCol = (altCount > 0) and Color(255, 255, 255, 255) or Color(255, 120, 120, 255)
			draw.RoundedBox( 4, ScrW() - CoDHUD_SX(CFG.ALT_TEXT_X+4) - altPad * 0.5, ScrH() - CoDHUD_SY(CFG.ALT_TEXT_Y), CoDHUD_S(8) + altPad, CoDHUD_S(alth), Color( 0, 0, 0, 200 ) )
			DrawSqueezedText(altCount, "BO1_Ammo_Alt", ScrW() - CoDHUD_SX(CFG.ALT_TEXT_X), ScrH() - CoDHUD_SY(CFG.ALT_TEXT_Y), altCol, CFG.ALT_TEXT_SQ, CFG.ALT_TEXT_SQ, 1, CoDHUD_S(999))
		elseif maxClip2 > 0 and clip2 >= 0 then
			local perc = clip2 / maxClip2
			local isLowClip = (perc <= CFG.STAT_LOW_PERC)
			local blink = 255 * math.abs(math.sin(RealTime() * 3))
			local col = Color(255, isLowClip and blink or 255, isLowClip and blink or 255)
			draw.RoundedBox( CoDHUD_S(14), ScrW() - CoDHUD_SX(CFG.RES_X+8) - resw - clipw, ScrH() - CoDHUD_SY(CFG.RES_Y), CoDHUD_S(4), CoDHUD_S(36), Color( 255, 255, 255, 24 ) )
			DrawSqueezedText(clip2, "BO1_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X) - resw, ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), col, 0, 0, 0)
		end
    end

    if not isEquipment and maxClip > 0 and clip >= 0 then
        local perc = clip / maxClip
        local isLowClip = (perc <= CFG.STAT_LOW_PERC)
		local blink = 255 * math.abs(math.sin(RealTime() * 3))
		local col = Color(255, isLowClip and blink or 255, isLowClip and blink or 255)
        DrawSqueezedText(clip, "BO1_Res_Large", ScrW() - CoDHUD_SX(CFG.RES_X+(altCache and 12 or 0)) - resw - (altCache and clipw or 0), ScrH() - CoDHUD_SY(CFG.RES_Y * 1.15), col, 0, 0, 0)
    end

    if not isEquipment and maxClip > 0 and clip >= 0 and not reloading then
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
            draw.SimpleTextOutlined(language.GetPhrase(statText), "BO1_Stat_Font", cx + CoDHUD_SX(2), cy + CoDHUD_SY(2), finalCol, 1, 1, 1.5, Color(0, 0, 0, finalCol.a * 0.8))
        end
    end
end
CoDHUD[hudtype].WeaponInfo = weaponinfo