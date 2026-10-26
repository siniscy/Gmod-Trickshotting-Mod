CoDHUD.RegisterHUD( "mw2", "#CoDHUD.Type.mw2", true )

local hudtype = "mw2"

CoDHUD = CoDHUD or {}
CoDHUD[hudtype] = CoDHUD[hudtype] or {}
CoDHUD.Factions = CoDHUD.Factions or {}
CoDHUD.Gamemodes = CoDHUD.Gamemodes or {}

-- [[ SPECIAL KILLFEED ICONS ]]
if CLIENT then
	killicon.Add("CoDHUD_MW2_Suicide", hudtype .. "/killfeed/death_suicide.png", Color(255, 255, 255, 0))
	killicon.Add("CoDHUD_MW2_Headshot", hudtype .. "/killfeed/death_headshot.png", Color(255, 255, 255, 0))
end

-- [[ SUSPENSE ]]
CoDHUD[hudtype].SuspenseTracks = {
    "music/mw2/ambient/hz_mp_suspense_arcadia_panic_LR.mp3",
    "music/mw2/ambient/hz_mp_suspense_clfhang_sat_bust_LR.mp3",
    "music/mw2/ambient/hz_mp_suspense_contg_stlth_short_LR.mp3",
    "music/mw2/ambient/hz_mp_suspense_gulag_intro_LR.mp3",
    "music/mw2/ambient/hz_mp_suspense_gulag_liftoff_LR.mp3",
    "music/mw2/ambient/hz_mp_suspense_state_basement_LR.mp3"
}

-- [[ FACTIONS ]]
CoDHUD.Factions[hudtype] = {
	["rangers"] = {
		name = "MW2_MP_US_ARMY_NAME",
		short = "MW2_MP_US_ARMY_SHORT_NAME",
		voicepath = "us/mp/us_1mc_",
		spawntheme = "us/hz_mp_usspawn_1.mp3",
		victorytheme = "us/hz_mp_usvictory_1.mp3",
		defeattheme = "us/hz_mp_usdefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_rangers.png",
		scoreIcon = hudtype .. "/factions/faction_128_rangers_fade.png",
		color = Color(100, 105, 80),
		killfeedcol = Color(100, 110, 120),
		glow = Color(240, 230, 190),
		order = 1
	},
	["taskforce141"] = {
		name = "MW2_MP_TASKFORCE_NAME",
		short = "MW2_MP_TASKFORCE_SHORT_NAME",
		voicepath = "uk/mp/uk_1mc_",
		spawntheme = "uk/hz_mp_ukspawn_1.mp3",
		victorytheme = "uk/hz_mp_ukvictory_1.mp3",
		defeattheme = "uk/hz_mp_ukdefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_taskforce141.png",
		scoreIcon = hudtype .. "/factions/faction_128_taskforce141_fade.png",
		color = Color(70, 80, 80),
		killfeedcol = Color(100, 110, 120),
		glow = Color(225, 225, 255),
		order = 2
	},
	["seals"] = {
		name = "MW2_MP_SEALS_UDT_NAME",
		short = "MW2_MP_SEALS_UDT_SHORT_NAME",
		voicepath = "ns/mp/ns_1mc_",
		spawntheme = "ns/hz_mp_nsspawn_1.mp3",
		victorytheme = "ns/hz_mp_nsvictory_1.mp3",
		defeattheme = "ns/hz_mp_nsdefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_seals.png",
		scoreIcon = hudtype .. "/factions/faction_128_seals_fade.png",
		color = Color(65, 90, 130),
		killfeedcol = Color(100, 110, 120),
		glow = Color(170, 170, 185),
		order = 3
	},
	["ussr"] = {
		name = "MW2_MP_SPETSNAZ_NAME",
		short = "MW2_MPUI_SPETSNAZ_SHORT",
		voicepath = "ru/mp/ru_1mc_",
		spawntheme = "ru/hz_mp_ruspawn_1.mp3",
		victorytheme = "ru/hz_mp_ruvictory_1.mp3",
		defeattheme = "ru/hz_mp_rudefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_ussr.png",
		scoreIcon = hudtype .. "/factions/faction_128_ussr_fade.png",
		color = Color(105, 40, 45),
		killfeedcol = Color(120, 110, 100),
		glow = Color(185, 140, 120),
		order = 4
	},
	["arab"] = {
		name = "MW2_MP_OPFOR_NAME",
		short = "MW2_MPUI_OPFOR_SHORT",
		voicepath = "ab/mp/ab_1mc_",
		spawntheme = "ab/hz_mp_abspawn_1.mp3",
		victorytheme = "ab/hz_mp_abvictory_1.mp3",
		defeattheme = "ab/hz_mp_abdefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_arab.png",
		scoreIcon = hudtype .. "/factions/faction_128_arab_fade.png",
		color = Color(105, 60, 45),
		killfeedcol = Color(120, 110, 100),
		glow = Color(220, 180, 150),
		order = 5
	},
	["militia"] = {
		name = "MW2_MP_MILITIA_NAME",
		short = "MW2_MP_MILITIA_SHORT_NAME",
		voicepath = "pg/mp/pg_1mc_",
		spawntheme = "pg/hz_mp_pgspawn_1.mp3",
		victorytheme = "pg/hz_mp_pgvictory_1.mp3",
		defeattheme = "pg/hz_mp_pgdefeat_1.mp3",
		spawnIcon = hudtype .. "/factions/faction_128_militia.png",
		scoreIcon = hudtype .. "/factions/faction_128_militia_fade.png",
		color = Color(100, 10, 15),
		killfeedcol = Color(120, 110, 100),
		glow = Color(150, 85, 85),
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
		tied = "MW2_MPUI_TIED_CAPS",
		winning = "MW2_MPUI_WINNING_CAPS",
		losing = "MW2_MPUI_LOSING_CAPS"
	},
}

CoDHUD[hudtype].VoiceCallouts = {
	winningmusic = "music/mw2/hz_mp_opfor_victory.mp3",
	losingmusic = "music/mw2/hz_mp_time_out_losing.mp3",
	drawmusic = "music/mw2/hz_mp_defeat_01.mp3",

	winningfight = "winning",
	losingfight = "losing",
	lowtime = "timesup",
	
	leadtaken = "lead_taken",
	leadlost = "lead_lost",
	leadtied = "tied",
	
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
    ["war"]      = "MW2_MP_OBJ_WAR_HINT",
    ["dm"]       = "MW2_MP_OBJ_DM_HINT",
    ["sd"]       = "MW2_OBJECTIVES_SD_ATTACKER_HINT",
    ["sesh_war"] = "MW2_MP_OBJ_WAR_HINT",
    ["sesh_dm"]  = "MW2_MP_OBJ_DM_HINT",
    ["sesh_sd"]  = "MW2_OBJECTIVES_SD_ATTACKER_HINT",
    ["sesh_sd_set"] = "MW2_OBJECTIVES_SD_ATTACKER_HINT",
}

CoDHUD.Gamemodes[hudtype].Callouts = {
    ["war"]      = "team_deathmtch",
    ["dm"]       = "freeforall",
    ["sd"]       = "searchdestroy",
    ["sesh_war"] = "team_deathmtch",
    ["sesh_dm"]  = "freeforall",
    ["sesh_sd"]  = "searchdestroy",
    ["sesh_sd_set"] = "searchdestroy",
}

CoDHUD.Gamemodes[hudtype].Boosts = {
    ["war"]      = "boost",
    ["dm"]       = "boost",
    ["sd"]       = "objs_destroy",
    ["sesh_war"] = "boost",
    ["sesh_dm"]  = "boost",
    ["sesh_sd"]  = "objs_destroy",
    ["sesh_sd_set"] = "objs_destroy",
}

-- [[ HELPERS ]]
local function DrawSqueezedScore(val, x, y, alpha)
	local textCol   = Color(255, 255, 50, alpha)
	local shadowCol = Color(0, 0, 0, alpha * 0.8)
	local s_val     = tostring(val)
	local partPlus  = "+"

	surface.SetFont("MW2_Score_Plus")
	local wP  = surface.GetTextSize(partPlus)
	local gapPlus = CoDHUD_SX(-6)

	surface.SetFont("MW2_Score_Main")

	local totalW = wP + gapPlus
	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = surface.GetTextSize(char)
		totalW = totalW + w
		if i < #s_val then
			local gap = (char == "1") and CoDHUD_SX(-11) or CoDHUD_SX(-5)
			totalW = totalW + gap
		end
	end

	local curX = x - (totalW / 2)

	local function DrawComponent(txt, font, px, py)
		draw.SimpleTextOutlined(txt, font, px, py, textCol, 0, 1, 0, shadowCol)
		surface.SetFont(font)
		local w = surface.GetTextSize(txt)
		return w
	end

	local runX = curX
	runX = runX + DrawComponent(partPlus, "MW2_Score_Plus", runX, y) + gapPlus

	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = DrawComponent(char, "MW2_Score_Main", runX, y)
		if i < #s_val then
			local gap = (char == "1") and CoDHUD_SX(-11) or CoDHUD_SX(-5)
			runX = runX + w + gap
		end
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
	draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))
	surface.SetDrawColor(255, 255, 255, 125)
	surface.SetMaterial( Material( "mw2/settings/menu_anim" ) )
	surface.DrawTexturedRect(0, 0, w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial( Material( "mw2/settings/menu_bg" ) )
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
        text = CoDHUD_ChallengeTitle(header, level),
        subtext = (sub and sub ~= "") and ResolvePrefix("MW2_CHALLENGE_", sub) or nil,
        x = CoDHUD_SX(960),
        y = CoDHUD_SY(205),
        color = Color(0,220,80),
        fonts = {
            pri = "MW2_ChalHeader_Pri",
            sec = "MW2_ChalHeader_Sec",
            shd = "MW2_ChalHeader_Shd",
            sub = "MW2_ChalSub"
        },
		align = align or nil
    })
    surface.PlaySound("hud/mp_challengecomplete_metal_2.mp3")
end
CoDHUD[hudtype].ChallengeComplete = challengecomplete

local function rs_obj( ... )
	local text = select(1, ...)
	CoDHUD_HeaderQueue.Push({
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(205),
		color = Color(0, 220, 80),
		fonts = {
			pri = "MW2_RS_O_Pri",
			sec = "MW2_RS_O_Sec",
			shd = "MW2_RS_O_Shd"
		}
	})
end
CoDHUD[hudtype].RoundStartObjective = rs_obj

local function rs_title( ... )
	local text = select(1, ...)
	local glow = select(2, ...)
	local logo = select(3, ...)
	CoDHUD_HeaderQueue.Push({
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(150),
		color = glow,
		iconY = CoDHUD_SY(180),
		iconSize = CoDHUD_S(134),
		fonts = {
			pri = "MW2_RS_H_Pri",
			sec = "MW2_RS_H_Sec",
			shd = "MW2_RS_H_Shd"
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
			draw.SimpleTextOutlined( disp, "MW2_RS_Timer", tx, ty, Color(255,255,100), 1, 1, outlined and 1 or 0, Color(0,0,0) )
		cam.PopModelMatrix()
		draw.SimpleTextOutlined( "#MW2_MP_MATCH_STARTING_IN", "MW2_RS_S_Pri", tx, ty + syo, Color(255,255,255), 1, 1, outlined and 1 or 0, Color(0,0,0) )
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
        teams = scaledTeams,
        x = CoDHUD_SX(960),
        y = CoDHUD_SY(400),
        multiple = true,
        persist = true,
        endTime = CFG.SCOREBOARD_DELAY,
        iconSize = CoDHUD_S(184),
        iconGap  = CoDHUD_S(80),
        scoreY = CoDHUD_SY(620),
        fonts = {
            pri = "MW2_RE_Sc_Pri",
            sec = "MW2_RE_Sc_Sec",
            shd = "MW2_RE_Sc_Shd",
        }
    })

	CoDHUD_HeaderQueue.Push({
		text = ws_result,
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(240),
		color = re_result_glow,
		multiple = true,
		skipErase = true,
		persist = true,
		endTime = CFG.SCOREBOARD_DELAY,
		fonts = {
			pri = "MW2_RE_Re_Pri",
			sec = "MW2_RE_Re_Sec",
			shd = "MW2_RE_Re_Shd",
			sub = "MW2_ChalSub"
		}
	})

	CoDHUD_HeaderQueue.Push({
		text = ws_limit,
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(330),
		color = Color(135, 135, 180),
		multiple = true,
		skipErase = true,
		persist = true,
		endTime = CFG.SCOREBOARD_DELAY,
		fonts = {
			pri = "MW2_RE_Li_Pri",
			sec = "MW2_RE_Li_Sec",
			shd = "MW2_RE_Li_Shd",
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
	draw.SimpleTextOutlined( string.format( language.GetPhrase("MW2_MP_MATCH_BONUS_IS"), tostring(re_match_bonus) ), "MW2_RE_Bonus", CoDHUD_SX(960), CoDHUD_SY(720), Color(240, 250, 110, iconAlpha), 1, 1, outlined and 1 or 0, Color(0,0,0, iconAlpha) )
end
CoDHUD[hudtype].RoundEndBonus = re_bonus

local function hitmarker( ... )
	local hitTime = select(1, ...)
	local ct = CurTime()
	local cx, cy = ScrW() / 2, ScrH() / 2
	local matHit = Material(hudtype .. "/icons/hitmarker.png", "mips smooth")
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
	local matIcon = Material(hudtype .. "/icons/grenadeicon_white.png", "mips smooth")
	local matPointer = Material(hudtype .. "/icons/grenadepointer_white.png", "mips smooth")
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
    local yPos = CoDHUD_S(210)
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
        if timeLeft <= 0 then
            table.remove(KillFeed, i)
            continue
        end
        local animProgress = math.Clamp(age / ANIM_TIME, 0, 1)
        local fadeFactor = 1
        if age < ANIM_TIME then
            fadeFactor = animProgress
        elseif timeLeft < 1 then
            fadeFactor = math.Clamp(timeLeft, 0, 1)
        end
        local yOffset = (1 - animProgress) * CoDHUD_S(ANIM_RISE)
		local currentY = baseY - ((#KillFeed - i) * spacing) + yOffset
        local x = xPos
        local finalTxtAlpha = 155 * fadeFactor
        surface.SetFont("MW2_KillfeedFont")
		local attackerEnt = data.attackerEnt
		local victimEnt = data.victimEnt
		local aColBase = GetFactionColor(attackerEnt)
		local vColBase = GetFactionColor(victimEnt)
		local aCol = Color(aColBase.r, aColBase.g, aColBase.b, finalTxtAlpha)
		local vCol = Color(vColBase.r, vColBase.g, vColBase.b, finalTxtAlpha)
        if data.type == "kill" then
			local ICON_BOX_W = iconW
			local ICON_BOX_H = iconH
			local cls = data.isHeadshot and "CoDHUD_MW2_Headshot" or data.weaponClass
			local w, h = killicon.GetSize(cls)
			if not w or w <= 0 then w = ICON_BOX_W end
			if not h or h <= 0 then h = ICON_BOX_H end
			local gap = CoDHUD_S(10)
			if data.attackerName != "" then
				draw.SimpleText(data.attackerName, "MW2_KillfeedFont", x, currentY, aCol)
				local tw, _ = surface.GetTextSize(data.attackerName)
				x = x + tw
			end
			local iconY = currentY + (ICON_BOX_H - h) * 0.5
			local alpha = math.min(165 * fadeFactor, 255)
			local offsetX = CoDHUD_S(0)
			local offsetY = CoDHUD_S(-15)
			if cls == "CoDHUD_MW2_Headshot" then
				offsetY = CoDHUD_S(-2)
			end
			killicon.Render(x + gap + offsetX, iconY + (h * 0.33) + offsetY, cls, alpha, false, false)
			x = x + w + (gap * 2)
			draw.SimpleText(data.victimName, "MW2_KillfeedFont", x, currentY, vCol)
        else
            draw.SimpleText(data.msg, "MW2_KillfeedFont", x, currentY, Color(255, 255, 255, finalTxtAlpha))
        end
    end
end
CoDHUD[hudtype].Killfeed = killfeed

local function medals( ... )
	local speedMul = select(1, ...)
	local activeMedal = select(2, ...)
	local age = (CurTime() - activeMedal.start) / speedMul
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local cx, cy = ScrW() / 2, ScrH() / 2
    local MEDAL_DURATION = 1.25
    local FADE_IN_TIME   = 0.125
    local EXIT_DURATION  = 0.125
    local FADE_OUT_START = MEDAL_DURATION - EXIT_DURATION
    local COL_POINTS = Color(255, 255, 50)
    local MEDAL_CFG = {
        X_OFFSET = 0,
        Y_OFFSET = -250,
    }
	if age > MEDAL_DURATION then return true end
	local alpha = 255
	local scale = 1
	if age < FADE_IN_TIME then
		local progress = age / FADE_IN_TIME
		alpha = progress * 255
		scale = Lerp(progress, 3.5, 1.0)
	elseif age > FADE_OUT_START then
		local progress = (age - FADE_OUT_START) / EXIT_DURATION
		alpha = math.Clamp((1 - progress) * 255, 0, 255)
		scale = Lerp(progress, 1.0, 3.0)
	end
	local cx = (ScrW() / 2) + CoDHUD_S(MEDAL_CFG.X_OFFSET)
	local cy = (ScrH() / 2) + CoDHUD_S(MEDAL_CFG.Y_OFFSET)
	local colWhite      = Color(255, 255, 255, alpha)
	local colBlack      = Color(0, 0, 0, alpha * 0.8)
	local colYellow     = Color(COL_POINTS.r, COL_POINTS.g, COL_POINTS.b, alpha)
	local colRedGlow    = Color(195, 110, 115, alpha * 0.5)
	local colRedOutline = Color(180, 0, 0, alpha * 0.8)
	local mat = Matrix()
	mat:Translate(Vector(cx, cy, 0))
	mat:Scale(Vector(scale, scale, 1))
	mat:Translate(Vector(-cx, -cy, 0))
	cam.PushModelMatrix(mat)
		if activeMedal.hasIcon then
			surface.SetDrawColor(255, 255, 255, alpha)
			surface.SetMaterial(Material(hudtype .. "/icons/crosshair_red.png", "smooth"))
			surface.DrawTexturedRect(cx - CoDHUD_S(60), cy - CoDHUD_S(120), CoDHUD_S(120), CoDHUD_S(120))
		end
		local localizedText = language.GetPhrase(activeMedal.text)
		draw.SimpleTextOutlined( localizedText, "MW2_MedalGlow", cx, cy, Color(0,0,0,0), 1, 1, 0.75, colRedGlow )
		draw.SimpleTextOutlined( localizedText, "MW2_MedalPrimary", cx, cy, colWhite, 1, 1, 0, colRedOutline )
		if activeMedal.desc then
			local localizedDesc = language.GetPhrase(activeMedal.desc)
			if activeMedal.isSpecial then
				draw.SimpleTextOutlined( localizedDesc, "MW2_MedalDesc", cx, cy + CoDHUD_S(35), colWhite, 1, 1, outlined and 1 or 0, colBlack )
			else
				local descText     = localizedDesc .. " ("
				local pointsText   = "+" .. activeMedal.points
				local bracketClose = ")"
				surface.SetFont("MW2_MedalDesc")
				local w1 = surface.GetTextSize(descText)
				local w2 = surface.GetTextSize(pointsText)
				local totalW = w1 + w2 + surface.GetTextSize(bracketClose)
				local startX = cx - (totalW / 2)
				draw.SimpleTextOutlined( descText, "MW2_MedalDesc", startX, cy + CoDHUD_S(35), colWhite, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( pointsText, "MW2_MedalDesc", startX + w1, cy + CoDHUD_S(35), colYellow, 0, 1, outlined and 1 or 0, colBlack )
				draw.SimpleTextOutlined( bracketClose, "MW2_MedalDesc", startX + w1 + w2, cy + CoDHUD_S(35), colWhite, 0, 1, outlined and 1 or 0, colBlack )
			end
		else
			draw.SimpleTextOutlined( "+" .. activeMedal.points, "MW2_MedalDesc", cx, cy + CoDHUD_S(35), colYellow, 1, 1, outlined and 1 or 0, colBlack )
		end
	cam.PopModelMatrix()
end
CoDHUD[hudtype].Medals = medals
CoDHUD[hudtype].MedalsSound = "hud/hud_medal.mp3"
CoDHUD[hudtype].MedalsTable = {
	["headshot"] = { "MW2_SPLASHES_HEADSHOT" },
	["doublekill"] = { "MW2_SPLASHES_DOUBLEKILL" },
	["triplekill"] = { "MW2_SPLASHES_TRIPLEKILL" },
	["multikill"] = { "MW2_SPLASHES_MULTIKILL" },
	["longshot"] = { "MW2_SPLASHES_LONGSHOT", "MW2_SPLASHES_LONGSHOT_DESC" },
	["oneshot"] = { "MW2_SPLASHES_ONE_SHOT_KILL", "MW2_SPLASHES_ONE_SHOT_KILL_DESC" },
	["firstblood"] = { "MW2_SPLASHES_FIRSTBLOOD", "MW2_SPLASHES_FIRSTBLOOD_DESC" },
	["comeback"] = { "MW2_SPLASHES_COMEBACK", "MW2_SPLASHES_COMEBACK_DESC" },
	["payback"] = { "MW2_SPLASHES_REVENGE", "MW2_SPLASHES_REVENGE_DESC" },
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
	local MAT_BORDER       = Material(hudtype .. "/minimap/minimap_background.png", "smooth")
	local MAT_MAP_BG       = Material(hudtype .. "/minimap/compass_map_default.png", "smooth")
	local MAT_PLAYER       = Material(hudtype .. "/minimap/compassping_player.png", "smooth")
	local MAT_STATIC_SCAN  = Material(hudtype .. "/minimap/minimap_scanlines.png", "smooth")
	local MAT_MOVING_SCAN  = Material(hudtype .. "/minimap/scanlines.png", "smooth")
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
			radar:SetDimensions(x, y, w, h)
			radar.origin = ply:GetPos()
			radar.rotation = Angle(0, ply:EyeAngles().y, 0)
			radar.ratio = 10
			radar:UpdateLayout()
			radar:Draw()
		else
			surface.SetMaterial(MAT_MAP_BG)
			surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_MAP_BG)
			surface.DrawTexturedRect(x, y, w, h)
		end
        surface.SetMaterial(MAT_STATIC_SCAN)
        surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_STATIC_S)
        surface.DrawTexturedRect(x, y, w, h)
        surface.SetMaterial(MAT_MOVING_SCAN)
        surface.SetDrawColor(255, 255, 255, MAP_CFG.ALPHA_MOVING_S)
        local moveOffset = (CurTime() * MAP_CFG.SCAN_SPEED) % h
        surface.DrawTexturedRect(x, y - moveOffset, w, h)
        surface.DrawTexturedRect(x, y - moveOffset + h, w, h)
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
        -- In sesh modes, bots always appear as enemies on minimap
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
                        local tr = util.TraceLine({
                            start = observer:EyePos(),
                            endpos = ent:WorldSpaceCenter(),
                            filter = {observer, ent},
                            mask = MASK_SHOT
                        })
                        if not tr.Hit then
                            isVisibleToTeam = true
                            break
                        end
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
            if timeLeft > 0 then
                visAlpha = math.Clamp(timeLeft / MAP_CFG.FADE_TIME_VIS, 0, 1) * 255
            else
                CoDHUD_VisCache[entIdx] = nil
            end
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
        if not isAlive then
            if isFriendly then
                continue
            else
                if not CoDHUD_DeathCache[entIdx] then
                    CoDHUD_DeathCache[entIdx] = CurTime()
                end
                local timeSinceDeath = CurTime() - CoDHUD_DeathCache[entIdx]
                if timeSinceDeath > MAP_CFG.FADE_TIME then continue end
                alpha = math.min(alpha, 255 * (1 - (timeSinceDeath / MAP_CFG.FADE_TIME)))
            end
        else
            CoDHUD_DeathCache[entIdx] = nil
        end
        if alpha <= 0 then continue end
		local targetX, targetY
		if radar then
			local pos = ent:GetPos()
			local origin = ply:EyePos()
			local delta = pos - origin
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
				x2 = x2 * scale
				y2 = y2 * scale
			end
			targetX = centerX + x2
			targetY = centerY + y2
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
				offsetX = offsetX * scale
				offsetY = offsetY * scale
			end
			targetX = centerX + offsetX
			targetY = centerY + offsetY
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
		BAR_W = 776, BAR_H = 96, BAR_X_OFF = 0, BAR_Y_OFF = 44,
		ICON_SCALE = 1.28, ICON_X = 12, ICON_Y = 8,
		TIMER_X = 86, TIMER_Y = -32, TIMER_SHIFT_2DIG = -10, TIMER_SHIFT_3DIG = -12, TIMER_OUTLINE_W = 1.5,
		STATUS_X = 150, STATUS_Y = 5,
		SQUEEZE = -2, SQUEEZE_ONE = -6, SQUEEZE_ONE_BEFORE = -4,
	}

	local SCORES_CFG = {
		X = 162, Y = 974, GAP_OFFSET = 32,
		SQUEEZE = -4, SQUEEZE_ONE = -10, SQUEEZE_ONE_BEFORE = -10, OUTLINE_W = 1.5,
		SCORE_LIMIT = 75,
		HUD_X = 200, HUD_Y = 1015, HUD_W_BASE = 14, HUD_W_MAX = 282, HUD_H = 10,
		SLANT_SIZE = 11, VERTICAL_GAP = 10, SHADOW_OFFSET = 2,
		BASE_X = 190, BASE_Y = 1012, BASE_W = 298, BASE_H = 11, BASE_SLANT = 10, BASE_GAP = 4,
		CAP_W = 3, CAP_H_OFFSET = 2, CAP_SLANT = 10, CAP_COLOR = Color(255, 255, 255, 155),
		SLANT_W = 7, SLANT_H_OFFSET = 0.4, SLANT_SEP_W = 1, SLANT_Y_OFFSET_TOP = 0,
		SLANT_COLOR = Color(255, 255, 255, 220),
	}

	local ARROW_CFG = {
		x = 140, y = 978, w = 27, h = 31, outline = 4,
		color = Color(140, 220, 140, 255),
		outlineColor = Color(0, 0, 0, 255),
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

    surface.SetMaterial(Material(hudtype .. "/hud/hud_scorebar.png", "smooth"))
    surface.SetDrawColor(255, 255, 255, 155)
    surface.DrawTexturedRect(barX, barY, barW, barH)

	local factionData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][currentFaction]
	local factionMat = factionData and factionData.scoreIcon
	if not factionData then
		currentFaction = "rangers"
		factionData = CoDHUD.Factions[hudtype][currentFaction]
	end
	if factionMat then
		local iSize = math.Round(barH * CFG.ICON_SCALE)
		surface.SetMaterial(Material(factionMat, "smooth"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(barX + CoDHUD_SX(CFG.ICON_X), barY + CoDHUD_SY(CFG.ICON_Y), iSize, iSize)
	end

    local timeStr = data.timeStr
    local mins = data.mins
    local xShift =
        (#tostring(mins) >= 3 and CoDHUD_SX(CFG.TIMER_SHIFT_3DIG)) or
        (#tostring(mins) >= 2 and CoDHUD_SX(CFG.TIMER_SHIFT_2DIG)) or 0
	local timecol = Color(255,255,255)
	if data.timeRaw > 30 and data.timeRaw < 60 then timecol = Color(218,136,43)
	elseif data.timeRaw < 30 then timecol = Color(255,100,100) end
	local shouldDrawTimer = data.timeRaw > 0.1 and (CoDHUD_MatchMaxTime <= 0 or data.timeRaw <= CoDHUD_MatchMaxTime)
	if shouldDrawTimer then
		DrawSqueezedText( timeStr, "MW2_Timer", barX + CoDHUD_SX(CFG.TIMER_X) + xShift, barY + CoDHUD_SY(CFG.TIMER_Y), timecol, CFG.SQUEEZE, CFG.SQUEEZE_ONE, 1, CFG.SQUEEZE_ONE_BEFORE, CoDHUD_SX(CFG.TIMER_OUTLINE_W) )
	end
	data.tiedCol = Color(110, 220, 120, 255)
	data.winningCol = Color(215, 110, 120, 255)
	data.losingCol = Color(230, 230, 110, 255)
    local statusStr = data.statusResolved and data.statusText or language.GetPhrase(data.statusText)
    local statusOut = data.statusOutline or (outlined and 1 or 0)
    draw.SimpleTextOutlined( statusStr, "MW2_Status", barX + CoDHUD_SX(CFG.STATUS_X), barY + CoDHUD_SY(CFG.STATUS_Y), data.statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP, statusOut, Color(0,0,0) )

    local clientKills   = data.clientScore
    local topEnemyKills = data.enemyScore
    local S_CFG = SCORES_CFG

    local baseX     = CoDHUD_S(S_CFG.BASE_X)
    local baseY_raw = scrH - CoDHUD_S(1080 - S_CFG.BASE_Y)
    local baseW     = CoDHUD_S(S_CFG.BASE_W)
    local baseH     = CoDHUD_S(S_CFG.BASE_H)
    local baseSlant = CoDHUD_S(S_CFG.BASE_SLANT)
    local baseGap   = CoDHUD_S(S_CFG.BASE_GAP)
    local capW      = CoDHUD_S(S_CFG.CAP_W)
    local capSlant  = CoDHUD_S(S_CFG.CAP_SLANT)
    local capHOff   = CoDHUD_S(S_CFG.CAP_H_OFFSET)
    local hudX      = CoDHUD_S(S_CFG.HUD_X)
    local hudY_raw  = scrH - CoDHUD_S(1080 - S_CFG.HUD_Y)
    local hudWBase  = CoDHUD_S(S_CFG.HUD_W_BASE)
    local hudWMax   = CoDHUD_S(S_CFG.HUD_W_MAX)
    local hudH      = CoDHUD_S(S_CFG.HUD_H)
    local slantSize = CoDHUD_S(S_CFG.SLANT_SIZE)
    local vertGap   = CoDHUD_S(S_CFG.VERTICAL_GAP)
    local shadowOff = CoDHUD_S(S_CFG.SHADOW_OFFSET)
    local slantW    = CoDHUD_S(S_CFG.SLANT_W)
    local slantHOff = CoDHUD_S(S_CFG.SLANT_H_OFFSET)
    local slantSepW = CoDHUD_S(S_CFG.SLANT_SEP_W)
    local BASE_X = baseX
    local BASE_Y = baseY_raw
    local BASE_W = baseW
    local BASE_H = baseH
    local BASE_SLANT = baseSlant
    local top_y_base = BASE_Y - baseGap - BASE_H

    surface.SetMaterial(MAT_GRADIENT)
    surface.SetDrawColor(0, 0, 0, 175)
    surface.DrawTexturedRect(BASE_X, BASE_Y, BASE_W, BASE_H)
    draw.NoTexture()
    surface.SetDrawColor(0, 0, 0, 175)
    surface.DrawPoly({
        { x = BASE_X + BASE_W,              y = BASE_Y },
        { x = BASE_X + BASE_W + BASE_SLANT, y = BASE_Y },
        { x = BASE_X + BASE_W,              y = BASE_Y + BASE_H },
    })
    surface.SetMaterial(MAT_GRADIENT)
    surface.SetDrawColor(0, 0, 0, 175)
    surface.DrawTexturedRect(BASE_X, top_y_base, BASE_W, BASE_H)
    draw.NoTexture()
    surface.SetDrawColor(0, 0, 0, 175)
    surface.DrawPoly({
        { x = BASE_X + BASE_W,              y = top_y_base },
        { x = BASE_X + BASE_W + BASE_SLANT, y = top_y_base + BASE_H },
        { x = BASE_X + BASE_W,              y = top_y_base + BASE_H },
    })
    surface.SetDrawColor(S_CFG.CAP_COLOR)
    surface.DrawPoly({
        { x = BASE_X + BASE_W,                  y = top_y_base - (capHOff / 2) },
        { x = BASE_X + BASE_W + capW,            y = top_y_base - (capHOff / 2) },
        { x = BASE_X + BASE_W + capSlant + capW, y = top_y_base + BASE_H + (capHOff / 2) },
        { x = BASE_X + BASE_W + capSlant,        y = top_y_base + BASE_H + (capHOff / 2) },
    })
    surface.DrawPoly({
        { x = BASE_X + BASE_W + capSlant,        y = BASE_Y - (capHOff / 2) },
        { x = BASE_X + BASE_W + capSlant + capW, y = BASE_Y - (capHOff / 2) },
        { x = BASE_X + BASE_W + capW,            y = BASE_Y + BASE_H + (capHOff / 2) },
        { x = BASE_X + BASE_W,                  y = BASE_Y + BASE_H + (capHOff / 2) },
    })

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
    local HUD_Y = hudY_raw
    local top_y = HUD_Y - vertGap - hudH
    local white = Color(255,255,255,255)

	surface.SetMaterial(MAT_GRADIENT)
	surface.SetDrawColor(Color(0, 0, 0, 100))
	surface.DrawTexturedRect(HUD_X + shadowOff, top_y + shadowOff, client_w, hudH)
	surface.DrawTexturedRect(HUD_X + shadowOff, HUD_Y + shadowOff, enemy_w, hudH)
	draw.NoTexture()
	surface.SetDrawColor(Color(0, 0, 0, 100))
	surface.DrawPoly({
		{ x = HUD_X + client_w + shadowOff,             y = top_y + shadowOff },
		{ x = HUD_X + client_w + slantSize + shadowOff, y = top_y + hudH + shadowOff },
		{ x = HUD_X + client_w + shadowOff,             y = top_y + hudH + shadowOff },
	})
	surface.DrawPoly({
		{ x = HUD_X + enemy_w + shadowOff,             y = HUD_Y + shadowOff },
		{ x = HUD_X + enemy_w + slantSize + shadowOff, y = HUD_Y + shadowOff },
		{ x = HUD_X + enemy_w + shadowOff,             y = HUD_Y + hudH + shadowOff },
	})
	surface.SetMaterial(MAT_GRADIENT)
	surface.SetDrawColor(Color(110, 180, 90))
	surface.DrawTexturedRect(HUD_X, top_y, client_w, hudH)
	draw.NoTexture()
	surface.SetDrawColor(Color(110, 180, 90))
	surface.DrawPoly({
		{ x = HUD_X + client_w,             y = top_y },
		{ x = HUD_X + client_w + slantSize, y = top_y + hudH },
		{ x = HUD_X + client_w,             y = top_y + hudH },
	})
	surface.SetMaterial(MAT_GRADIENT)
	surface.SetDrawColor(Color(180, 55, 55))
	surface.DrawTexturedRect(HUD_X, HUD_Y, enemy_w, hudH)
	draw.NoTexture()
	surface.SetDrawColor(Color(180, 55, 55))
	surface.DrawPoly({
		{ x = HUD_X + enemy_w,             y = HUD_Y },
		{ x = HUD_X + enemy_w + slantSize, y = HUD_Y },
		{ x = HUD_X + enemy_w,             y = HUD_Y + hudH },
	})
	local tx1, ty1 = HUD_X + client_w, top_y
	local tx2, ty2 = HUD_X + client_w + slantSize, top_y + hudH
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawPoly({
		{ x = tx1 - slantSepW, y = ty1 },
		{ x = tx1,             y = ty1 },
		{ x = tx2,             y = ty2 },
		{ x = tx2 - slantSepW, y = ty2 },
	})
	surface.SetDrawColor(S_CFG.SLANT_COLOR)
	surface.DrawPoly({
		{ x = tx1,           y = ty1 - (slantHOff / 2) },
		{ x = tx1 + slantW,  y = ty1 - (slantHOff / 2) },
		{ x = tx2 + slantW,  y = ty2 + (slantHOff / 2) },
		{ x = tx2,           y = ty2 + (slantHOff / 2) },
	})
	local bx1, by1 = HUD_X + enemy_w + slantSize, HUD_Y
	local bx2, by2 = HUD_X + enemy_w, HUD_Y + hudH
	surface.SetDrawColor(0, 0, 0, 255)
	surface.DrawPoly({
		{ x = bx1,             y = by1 },
		{ x = bx1 + slantSepW, y = by1 },
		{ x = bx2 + slantSepW, y = by2 },
		{ x = bx2,             y = by2 },
	})
	surface.SetDrawColor(S_CFG.SLANT_COLOR)
	surface.DrawPoly({
		{ x = bx1 + slantSepW,          y = by1 - (slantHOff / 2) },
		{ x = bx1 + slantSepW + slantW, y = by1 - (slantHOff / 2) },
		{ x = bx2 + slantSepW + slantW, y = by2 + (slantHOff / 2) },
		{ x = bx2 + slantSepW,          y = by2 + (slantHOff / 2) },
	})

    DrawSqueezedText(clientKills * scoreMultiplier,   "MW2_Font", CoDHUD_S(S_CFG.X), HUD_Y - CoDHUD_S(41), white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)
    DrawSqueezedText(topEnemyKills * scoreMultiplier, "MW2_Font", CoDHUD_S(S_CFG.X), HUD_Y - CoDHUD_S(41) + CoDHUD_S(S_CFG.GAP_OFFSET), white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)

    local ax = CoDHUD_S(ARROW_CFG.x)
    local ay = scrH - CoDHUD_S(1080 - ARROW_CFG.y)
    local aw = CoDHUD_S(ARROW_CFG.w)
    local ah = CoDHUD_S(ARROW_CFG.h)
    local ao = CoDHUD_S(ARROW_CFG.outline)
    surface.SetMaterial(ARROW_CFG.material)
    surface.SetDrawColor(ARROW_CFG.outlineColor)
    surface.DrawTexturedRectUV(ax - ao, ay - ao, aw + (ao * 2), ah + (ao * 2), 0, 0, 1, 1)
    surface.SetDrawColor(ARROW_CFG.color)
    surface.DrawTexturedRectUV(ax, ay, aw, ah, 0, 0, 1, 1)
end
CoDHUD[hudtype].Scorebar = scorebar

local function scoreboard( ... )
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	local CFG = {
		BAR_W = 1086, BAR_H = 38, BAR_X_OFF = 0, BAR_Y_OFF = 290, BAR_ALPHA = 200,
		ROW_GAP = 2, TEAM_GAP = 120,
		ICON_SIZE = 77, ICON_X_OFF = 0, ICON_Y_OFF = -86,
		FAC_NAME_X = 96, FAC_NAME_Y = -44,
		STATS_HEADER_Y = -45,
		HEADER_Y_POS = 90, HEADER_H = 50, HEADER_ALPHA = 255,
		HEADER_ICON_SIZE = 86, HEADER_ICON_X = 140, HEADER_ENEMY_ICON_X = 340,
		MAP_Y_OFF = 98,
		PING_BOX_SIZE = 38, PING_BOX_ALPHA = 155, PING_X_OFF = 5, PING_BAR_W = 6, PING_BAR_SPACING = 3,
		TIMER_X_POS = 245, TIMER_Y_OFF = 98,
		SQUEEZE = -2, SQUEEZE_ONE = -6, SQUEEZE_ONE_BEFORE = -4, TIMER_OUTLINE_W = 2,
		OFF_DEATHS = 10, OFF_ASSISTS = 120, OFF_KILLS = 225, OFF_SCORE = 335,
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
		draw.SimpleTextOutlined(ply:Nick(), "MW2_Scoreboard_Text", x + CoDHUD_S(110), y + (h / 2), tCol, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:Deaths(), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_DEATHS),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:GetNWInt("Assists", 0), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_ASSISTS), y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:Frags(), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_KILLS),   y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(pScore, "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_SCORE),   y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		local ping = ply:Ping()
		local barCount = 4
		local col = Color(0, 255, 0, 255)
		if ping >= 150 then barCount = 1 col = Color(255, 60, 60, 255)
		elseif ping >= 100 then barCount = 2 col = Color(255, 140, 0, 255)
		elseif ping >= 50 then barCount = 3 col = Color(180, 255, 80, 255)
		else barCount = 4 col = Color(0, 255, 0, 255) end
		local boxSize = CoDHUD_S(CFG.PING_BOX_SIZE)
		local pingX = barRight + CoDHUD_S(CFG.PING_X_OFF)
		local pingY = y + (h / 2) - (boxSize / 2)
		surface.SetDrawColor(0, 0, 0, CFG.PING_BOX_ALPHA)
		surface.DrawRect(pingX, pingY, boxSize, boxSize)
		local rodW = CoDHUD_S(CFG.PING_BAR_W)
		local rodSpacing = CoDHUD_S(CFG.PING_BAR_SPACING)
		local totalRodsWidth = (rodW * 4) + (rodSpacing * 3)
		local startX = pingX + (boxSize / 2) - (totalRodsWidth / 2)
		for i = 1, 4 do
			local bh = (boxSize - CoDHUD_S(6)) * (i / 4)
			if i <= barCount then
				surface.SetDrawColor(col.r, col.g, col.b, col.a)
				surface.DrawRect( startX + ((i - 1) * (rodW + rodSpacing)), pingY + (boxSize - bh - CoDHUD_S(3)), rodW, bh )
			end
		end
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
			-- Sesh S&D: this header/strip must show ROUND WINS, not cumulative
			-- kills -- p:Frags() holds each player's match kill total (a
			-- different stat, shown per-row in the Kills column). Mirrors the
			-- same faction<->rounds mapping cl_scorebar.lua uses for the
			-- bottom bar so both stay consistent.
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
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_DEATHS"), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_DEATHS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_ASSISTS"), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_ASSISTS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_KILLS"), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_KILLS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_SCORE"), "MW2_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_SCORE), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		for fi, facData in ipairs(factionList) do
			local players = facData.players
			local facKey = facData.key
			local fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][facKey] or {
				name = facKey, short = facKey, color = Color(120,120,120)
			}
			local sectionY = startY
			local iconPath = CoDHUD.Factions[hudtype][facKey].spawnIcon
			local mat = Material(iconPath, "smooth")
			surface.SetMaterial(mat)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(barX + CoDHUD_S(CFG.ICON_X_OFF), sectionY + CoDHUD_S(CFG.ICON_Y_OFF), CoDHUD_S(CFG.ICON_SIZE), CoDHUD_S(CFG.ICON_SIZE))
			draw.SimpleTextOutlined( language.GetPhrase(fData.short) .. " (" .. #players .. ")", "MW2_Scoreboard_Text", barX + CoDHUD_S(CFG.FAC_NAME_X), sectionY + CoDHUD_S(CFG.FAC_NAME_Y), Color(255,255,255), 0,0, outlined and 1 or 0, Color(0,0,0) )
			for i, ply in ipairs(players) do
				local rowY = sectionY + (i - 1) * (barH + CoDHUD_S(CFG.ROW_GAP))
				DrawPlayerRow(ply, lp, barX, rowY, barW, barH, barRight, fData.color)
			end
			local sectionHeight = CoDHUD_S(0) + (#players * (barH + CoDHUD_S(CFG.ROW_GAP)))
			startY = startY + sectionHeight + CoDHUD_S(CFG.TEAM_GAP)
		end
	render.SetScissorRect(0, 0, 0, 0, false)

    surface.SetDrawColor(110, 110, 110, CFG.HEADER_ALPHA)
    surface.SetMaterial(MAT_GRADIENT_L)
    surface.DrawTexturedRect(0, CoDHUD_S(CFG.HEADER_Y_POS), scrW, CoDHUD_S(CFG.HEADER_H))
    local mapName = string.upper(game.GetMap())
	draw.SimpleTextOutlined( mapName, "MW2_Scoreboard_Timer", scrW/2, CoDHUD_S(CFG.MAP_Y_OFF), Color(255, 255, 255), 1, 0, outlined and 1.5 or 0, Color(0,0,0) )
    local totalSecs = math.floor(CurTime())
    local mins, secs = math.floor(totalSecs / 60), totalSecs % 60
    local timeStr = string.format("%d:%02d", mins, secs)
    DrawSqueezedText(timeStr, "MW2_Scoreboard_Timer", scrW - CoDHUD_S(CFG.TIMER_X_POS), CoDHUD_S(CFG.TIMER_Y_OFF), Color(255, 255, 255, 255), CFG.SQUEEZE, CFG.SQUEEZE_ONE, 0, CFG.SQUEEZE_ONE_BEFORE, outlined and 1.5 or 0)

	local lp = LocalPlayer()
	local myFaction = lp:GetNW2String("CoDHUD_Faction", "rangers")
	if myFaction == "" then myFaction = "rangers" end
	table.sort(factionList, function(a, b)
		if a.key == myFaction then return true end
		if b.key == myFaction then return false end
		return a.score > b.score
	end)

	local stripX = CoDHUD_S(20)
	local stripY = CoDHUD_S(CFG.HEADER_Y_POS) + (CoDHUD_S(CFG.HEADER_H) / 2) - (CoDHUD_S(CFG.HEADER_ICON_SIZE) / 2)
	local iconSize = CoDHUD_S(CFG.HEADER_ICON_SIZE)
	local textOffset = CoDHUD_S(8)
	local x = stripX
	surface.SetFont("MW2_Scoreboard_Text")
	for _, fac in ipairs(factionList) do
		local key = fac.key
		local score = fac.score or 0
		local fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][key] or { short = key, color = Color(150,150,150) }
		local iconPath = hudtype .. "/factions/faction_128_" .. key .. ".png"
		local mat = Material(iconPath, "smooth")
		if mat:IsError() then mat = Material(hudtype .. "/vgui/hud/icon_error") end
		local label = score
		local textW, textH = surface.GetTextSize(label)
		surface.SetMaterial(mat)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawTexturedRect(x, stripY, iconSize, iconSize)
		draw.SimpleTextOutlined( label, "MW2_Scoreboard_Text", x + iconSize + textOffset, stripY + iconSize / 2, Color(255,255,255), 0, 1, outlined and 1 or 0, Color(0,0,0) )
		x = x + iconSize + textW + CoDHUD_S(25)
	end
end
CoDHUD[hudtype].Scoreboard = scoreboard

local function deathicon( ... )
	local m = select(1, ...)
	local elapsed = select(2, ...)
    local MAT_DEAD_ICON = Material(hudtype .. "/icons/headicon_dead.png", "smooth")
	local screenData = m.pos:ToScreen()
	if screenData.visible then
		local currentAlpha = 185
		if elapsed > (3.7 - 1.0) then
			currentAlpha = Lerp((elapsed - (3.7 - 1.0)) / 1.0, 185, 0)
		end
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
	surface.SetFont("MW2_TargetName_Primary")
	local tw, th = surface.GetTextSize(displayName)
	tw, th = tw * finalScale, th * finalScale
	local drawX, drawY = screenData.x - (tw / 2), screenData.y - (th / 2)
	local matrix = Matrix()
	matrix:Translate(Vector(drawX, drawY, 0))
	matrix:Scale(Vector(finalScale, finalScale, 1))
	cam.PushModelMatrix(matrix)
		draw.SimpleText(displayName, "MW2_TargetName_Primary", 0, 0, Color(factionColor.r, factionColor.g, factionColor.b, alpha), 0, 0)
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
	draw.SimpleText(ply:Nick(), "MW2_VoiceFont", VOICE_X + ICON_SIZE + TEXT_X_OFFSET, drawY, Color(255, 255, 255), 0, 0)
	yOffset = yOffset + SPACING
end
CoDHUD[hudtype].VoiceChat = voice

local function weaponinfo(...)
	local MASK = select(1, ...)
	local CFG = select(2, ...)
	local ply = select(3, ...)

	local AMMO = {
		["default"] = { mat = "mw2/hud/ammo_counter_bullet_mp.png",      w = 3,  h = 20, gap = 1, y_off = 1, x_start = -1, dim = 75 },
		["357"]     = { mat = "mw2/hud/ammo_counter_riflebullet_mp.png", w = 4,  h = 14, gap = 1, y_off = 1, x_start = 0, dim = 75 },
		["rifle"]   = { mat = "mw2/hud/ammo_counter_riflebullet_mp.png", w = 4,  h = 14, gap = 1, y_off = 1, x_start = 0, dim = 75 },
		["rocket"]  = { mat = "mw2/hud/ammo_counter_rocket_mp.png",      w = 12, h = 24, gap = 1, y_off = -1, x_start = 5, dim = 75 },
		["sniper"]  = { mat = "mw2/hud/ammo_counter_rocket_mp.png",      w = 8,  h = 20, gap = 1, y_off = 0, x_start = 2, dim = 75 },
		["shotgun"] = { mat = "mw2/hud/ammo_counter_rocket_mp.png",      w = 12, h = 20, gap = -1, y_off = 0, x_start = 3, dim = 75 },
		["pistol"]  = { mat = "mw2/hud/ammo_counter_bullet_mp.png",      w = 4,  h = 14, gap = 1, y_off = 2, x_start = 0, dim = 75 },
		["belt"]    = { row_size = 20, row_gap = 0, mat = "mw2/hud/ammo_counter_beltbullet_mp.png", w = 7, h = 5, gap = 0, y_off = -5, x_start = 0, dim = 75 },
	}
	local AMMO_MAP = {
		["357"] = "default", ["ar2"] = "default", ["xbowbolt"] = "sniper",
		["xbowbolthl1"] = "sniper", ["sniperround"] = "sniper", ["sniperpenetratedround"] = "sniper",
		["pistol"] = "default", ["smg1"] = "default", ["buckshot"] = "shotgun",
		["buckshothl1"] = "shotgun", ["rpg_round"] = "rocket", ["smg1_grenade"] = "rocket",
		["mp5_grenade"] = "rocket", ["rpg_rocket"] = "rocket", ["ar2altfire"] = "rocket",
		["slam"] = "rocket", ["gaussenergy"] = "belt", ["ti_sniper"] = "sniper",
	}
	local MAT_BAR = Material(hudtype .. "/hud/hud_weaponbar.png", "smooth")
	local MAT_ALT = {
		["grenade"] = Material(hudtype .. "/hud/dpad_40mm_grenade.png", "smooth mips"),
		["buckshot"] = Material("mw2/hud/dpad_underbarrel_shotgun.png", "smooth mips")
	}
	local MAT_GRENADE = Material(hudtype .. "/hud/hud_us_grenade.png", "smooth")
	local MAT_AMMO = {}
	for key, data in pairs(AMMO) do MAT_AMMO[key] = Material(data.mat, "smooth") end
	local MAT_COMPASS_SHADOW  = Material(hudtype .. "/hud/compass_letters_shadow.png", "smooth")
	local MAT_COMPASS_LETTERS = Material(hudtype .. "/hud/compass_letters.png", "smooth")

	local function GetAmmoConfig(wep, alt)
		if not IsValid(wep) then return AMMO["default"] end
		local ammoName = string.lower(game.GetAmmoName(alt and wep:GetSecondaryAmmoType() or wep:GetPrimaryAmmoType()) or "")
		if (alt and wep:GetMaxClip2() or wep:GetMaxClip1()) > 50 then return AMMO["belt"] end
		return AMMO[AMMO_MAP[ammoName]] or AMMO["default"]
	end
	local function GetAmmoKey(ammoCfg)
		for key, data in pairs(AMMO) do
			if data == ammoCfg then return key end
		end
		return "default"
	end

    local cX   = ScrW() - CoDHUD_S(104)
    local cY   = ScrH() - CoDHUD_S(82)
    local size = CoDHUD_S(274)
    local yaw  = ply:EyeAngles().y
    local angle = -(yaw - 0)
    local halfFOV = MASK.FOV / 2.2
    local fadeDeg = MASK.FADE_DEG
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
            { x = cX,                         y = cY },
            { x = cX + math.sin(a0) * radius, y = cY - math.cos(a0) * radius },
            { x = cX + math.sin(a1) * radius, y = cY - math.cos(a1) * radius },
        })
    end
    render.OverrideColorWriteEnable(false, false)
    render.SetStencilCompareFunction(STENCIL_EQUAL)
    render.SetStencilPassOperation(STENCIL_KEEP)
    surface.SetMaterial(MAT_COMPASS_SHADOW)
    surface.SetDrawColor(0, 0, 0, 255)
    surface.DrawTexturedRectRotated(cX, cY, size, size, angle)
    surface.SetMaterial(MAT_COMPASS_LETTERS)
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
        local anchorX = (barX + barW) + CoDHUD_SX(CFG.GRENADE_X_OFF)
        local anchorY = (barY + barH) + CoDHUD_SY(CFG.GRENADE_Y_OFF)
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
    local reserve = ply:GetAmmoCount(primType)
    local barW = CoDHUD_SX(CFG.BAR_W)
    local barH = CoDHUD_SY(CFG.BAR_H)
    local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF) - barW
    local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH
    surface.SetMaterial(MAT_BAR)
    surface.SetDrawColor(255, 255, 255, 125)
    surface.DrawTexturedRect(barX, barY, barW, barH)
    if not isEquipment and primType ~= -1 then
        local resCol = (reserve == 0 or reserve < maxClip) and Color(255, 120, 120, 255) or Color(255, 255, 255, 255)
        if reserve >= 1000 then
            DrawSqueezedText(reserve, "MW2_Res_4D", barX + barW + CoDHUD_SX(CFG.RES4_X), barY + CoDHUD_SY(CFG.RES4_Y), resCol, CoDHUD_S(-6), CoDHUD_S(-12), 1)
        elseif reserve >= 100 then
            DrawSqueezedText(reserve, "MW2_Res_3D", barX + barW + CoDHUD_SX(CFG.RES3_X), barY + CoDHUD_SY(CFG.RES3_Y), resCol, CoDHUD_S(-4), CoDHUD_S(-12), 1)
        else
            DrawSqueezedText(reserve, "MW2_Res", barX + barW + CoDHUD_SX(CFG.RES_X), barY + CoDHUD_SY(CFG.RES_Y), resCol, CoDHUD_S(-6), CoDHUD_S(-16), 1)
        end
    end
    local timeSinceSwitch = CurTime() - wepSwitchTime
    if timeSinceSwitch < CFG.WEP_NAME_FADE then
        local alpha = math.Clamp(1 - (timeSinceSwitch / CFG.WEP_NAME_FADE), 0, 1)
        local name  = language.GetPhrase(wep:GetPrintName() or wep:GetClass()):upper()
        draw.SimpleTextOutlined(name, "MW2_Wep_Name", barX + barW + CoDHUD_SX(CFG.WEP_NAME_X_OFF), barY + CoDHUD_SY(CFG.WEP_NAME_Y_OFF), Color(255, 255, 255, 255 * alpha), 2, 0, outlined and 1.5 or 0, Color(0, 0, 0, 255 * alpha))
    end
    if not isEquipment and maxClip > 0 and clip >= 0 then
        local perc = clip / maxClip
        local isLowClip = (perc <= CFG.STAT_LOW_PERC)
        local reloadSine = isLowClip and ((math.sin(CurTime() * CFG.BULLET_RELOAD_SPD) + 1) / 2) or 0
        local ammoCfg = GetAmmoConfig(wep)
        local ammoKey = GetAmmoKey(ammoCfg)
        local iW = CoDHUD_S(ammoCfg.w)
        local iH = CoDHUD_S(ammoCfg.h)
        local iGap = CoDHUD_S(ammoCfg.gap)
        local iYOff = CoDHUD_SY(77+iH*-0.5-ammoCfg.y_off)
        local iXStart = CoDHUD_SX(-291-iW+ammoCfg.x_start)
        surface.SetMaterial(MAT_AMMO[ammoKey])
        local isBelt = (ammoCfg.row_size ~= nil)
        local rowSize = isBelt and ammoCfg.row_size or math.max(maxClip, clip)
        local rowGap = isBelt and CoDHUD_S(ammoCfg.row_gap) or 0
        for i = 0, math.max(maxClip, clip) - 1 do
            local isSpent = (i >= clip)
            local shade = isSpent and ammoCfg.dim or 255
            local r, g, b
            if not isSpent and isLowClip then
                r = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_R))
                g = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_G))
                b = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_B))
            else r = shade g = shade b = shade end
            surface.SetDrawColor(r, g, b, CFG.BULLET_ALPHA)
            local col = i % rowSize
            local row = math.floor(i / rowSize)
            local xPos = barX + barW + iXStart - (col * (iW + iGap))
            local yPos = barY + iYOff - (row * (iH + rowGap))
            surface.DrawTexturedRect(xPos, yPos, iW, iH)
        end
    end
	if not isEquipment and maxClip2 > 0 and clip2 >= 0
		and altType ~= -1
		and altType ~= primType
		and altType ~= game.GetAmmoID("Grenade") then
		local perc = clip2 / maxClip2
		local isLowClip = (perc <= CFG.STAT_LOW_PERC)
		local reloadSine = isLowClip and ((math.sin(CurTime() * CFG.BULLET_RELOAD_SPD) + 1) / 2) or 0
		local ammoCfg = GetAmmoConfig(wep, true)
		local ammoKey = GetAmmoKey(ammoCfg)
		local iW = CoDHUD_S(ammoCfg.w)
		local iH = CoDHUD_S(ammoCfg.h)
		local iGap = CoDHUD_S(ammoCfg.gap)
		local iYOff = CoDHUD_SY(92+iH*0.5-ammoCfg.y_off)
		local iXStart = CoDHUD_SX(-291-iW+ammoCfg.x_start)
		surface.SetMaterial(MAT_AMMO[ammoKey])
		local isBelt = (ammoCfg.row_size ~= nil)
		local rowSize = isBelt and ammoCfg.row_size or math.max(maxClip2, clip2)
		local rowGap = isBelt and CoDHUD_S(ammoCfg.row_gap) or 0
		for i = 0, math.max(maxClip2, clip2) - 1 do
			local isSpent = (i >= clip2)
			local shade = isSpent and ammoCfg.dim or 255
			local r, g, b
			if not isSpent and isLowClip then
				r = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_R))
				g = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_G))
				b = math.floor(Lerp(reloadSine, shade, CFG.BULLET_RELOAD_B))
			else r = shade g = shade b = shade end
			surface.SetDrawColor(r, g, b, CFG.BULLET_ALPHA)
			local col = i % rowSize
			local row = math.floor(i / rowSize)
			local xPos = barX + barW + iXStart - (col * (iW + iGap))
			local yPos = barY + iYOff + (row * (iH + rowGap))
			surface.DrawTexturedRect(xPos, yPos, iW, iH)
		end
	end
	local reloading =
	wep.IsReloading or reloadingM203
	or (wep.ARC9 and wep:GetReloading())
	or (wep.ArcCW and wep:GetReloading())
	or (wep.IsTFAWeapon and TFA.Enum.ReloadStatus[wep:GetStatus()])
	local glactive =
	wep.dt and (wep.dt.AltActive or wep.dt.M203Active)
	or (wep.ARC9 and wep:GetUBGL())
	if glactive then clip = clip2 maxClip = maxClip2 end
    if not isEquipment and altType ~= -1 and altType ~= primType and altType ~= game.GetAmmoID("Grenade") then
		local altCount = ply:GetAmmoCount(altType)
		local alticon = "grenade"
		if altAmmoName == "Buckshot" then alticon = "buckshot" end
		surface.SetMaterial(MAT_ALT[alticon])
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect(barX + barW + CoDHUD_SX(CFG.ALT_ICON_X), barY + CoDHUD_SY(CFG.ALT_ICON_Y), CoDHUD_S(CFG.ALT_ICON_SIZE), CoDHUD_S(CFG.ALT_ICON_SIZE))
		local altCol = (altCount > 0) and Color(255, 255, 255, 255) or Color(255, 120, 120, 255)
		DrawSqueezedText(altCount, "MW2_Ammo_Alt", barX + barW + CoDHUD_SX(CFG.ALT_TEXT_X), barY + CoDHUD_SY(CFG.ALT_TEXT_Y), altCol, CFG.ALT_TEXT_SQ, CFG.ALT_TEXT_SQ1, 1)
    end
    if not isEquipment and maxClip > 0 and clip >= 0 and not reloading then
        local perc = clip / maxClip
        local statText = ""
        local statCol = Color(255, 255, 255)
        local isNoAmmo = false
        local isLowAmmo = false
        local isReloadText = false
        if clip == 0 and reserve == 0 then statText = "#MW2_WEAPON_NO_AMMO" isNoAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and reserve == 0 then statText = "#MW2_PLATFORM_LOW_AMMO_NO_RELOAD" statCol = Color(255, 230, 0) isLowAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and reserve > 0 then statText = "#MW2_PLATFORM_RELOAD" isReloadText = true end
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
            draw.SimpleTextOutlined(language.GetPhrase(statText), "MW2_Stat_Font", cx + CoDHUD_SX(2), cy + CoDHUD_SY(2), finalCol, 1, 1, 1.5, Color(0, 0, 0, finalCol.a * 0.8))
        end
    end
end
CoDHUD[hudtype].WeaponInfo = weaponinfo