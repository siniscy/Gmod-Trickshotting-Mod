CoDHUD.RegisterHUD( "waw", "#CoDHUD.Type.waw", true )

local hudtype = "waw"

CoDHUD = CoDHUD or {}
CoDHUD[hudtype] = CoDHUD[hudtype] or {}
CoDHUD.Factions = CoDHUD.Factions or {}
CoDHUD.Gamemodes = CoDHUD.Gamemodes or {}

local textype = {
	"hud/waw/type_00.wav",
	"hud/waw/type_01.wav",
	"hud/waw/type_02.wav",
	"hud/waw/type_03.wav",
	"hud/waw/type_04.wav",
	"hud/waw/type_05.wav",
}

-- [[ SPECIAL KILLFEED ICONS ]]
if CLIENT then
	killicon.Add("CoDHUD_WaW_Suicide", hudtype .. "/killfeed/death_suicide.png", Color(255, 255, 255, 0))
	killicon.Add("CoDHUD_WaW_Headshot", hudtype .. "/killfeed/death_headshot.png", Color(255, 255, 255, 0))
end

-- [[ SUSPENSE ]]
CoDHUD[hudtype].SuspenseTracks = {
    "music/waw/mp_suspense_00.wav",
    "music/waw/mp_suspense_01.wav",
    "music/waw/mp_suspense_02.wav",
}

-- [[ FACTIONS ]]
CoDHUD.Factions[hudtype] = {
	["american"] = {
		name = "WAW_MPUI_MARINE",
		short = "WAW_MPUI_MARINE_SHORT",
		voicepath = "us/us_1mc_",
		spawntheme = "spawn/ja_spawn_airfield.wav",
		victorytheme = "global/mx_victory_am.wav",
		defeattheme = "mp_defeat.wav",
		spawnIcon = hudtype .. "/factions/faction_128_american.png",
		scoreIcon = hudtype .. "/factions/faction_128_american.png",
		color = Color(255*0.5, 255*0.5, 255*0.5),
		killfeedcol = Color(255*0.5, 255*0.5, 255*0.5),
		glow = Color(255*0.5, 255*0.5, 255*0.5),
		scoremat = hudtype .. "/hud/scorebar_usmc.png",
		order = 1
	},
	["soviet"] = {
		name = "WAW_MPUI_RUSSIAN",
		short = "WAW_MPUI_RUSSIAN_SHORT",
		voicepath = "ru/ru_1mc_",
		spawntheme = "spawn/ru_spawn_light.wav",
		victorytheme = "global/mx_victory_rs.wav",
		defeattheme = "mp_defeat.wav",
		spawnIcon = hudtype .. "/factions/faction_128_soviet.png",
		scoreIcon = hudtype .. "/factions/faction_128_soviet.png",
		color = Color(255*0.52, 255*0.28, 255*0.28),
		killfeedcol = Color(255*0.52, 255*0.28, 255*0.28),
		glow = Color(255*0.52, 255*0.28, 255*0.28),
		scoremat = hudtype .. "/hud/scorebar_ussr.png",
		order = 2
	},
	["german"] = {
		name = "WAW_MPUI_GERMAN",
		short = "WAW_MPUI_GERMAN_SHORT",
		voicepath = "ge/ge_1mc_",
		spawntheme = "spawn/ru_spawn_tension.wav",
		victorytheme = "global/mp_victory_german.wav",
		defeattheme = "mp_defeat.wav",
		spawnIcon = hudtype .. "/factions/faction_128_german.png",
		scoreIcon = hudtype .. "/factions/faction_128_german.png",
		color = Color(255*0.65, 255*0.57, 255*0.41),
		killfeedcol = Color(255*0.65, 255*0.57, 255*0.41),
		glow = Color(255*0.65, 255*0.57, 255*0.41),
		scoremat = hudtype .. "/hud/scorebar_german.png",
		order = 3
	},
	["japan"] = {
		name = "WAW_MPUI_JAPANESE",
		short = "WAW_MPUI_JAPANESE_SHORT",
		voicepath = "jp/jp_1mc_",
		spawntheme = "spawn/ja_spawn_jungle.wav",
		victorytheme = "global/mx_victory_jp.wav",
		defeattheme = "mp_defeat.wav",
		spawnIcon = hudtype .. "/factions/faction_128_japan.png",
		scoreIcon = hudtype .. "/factions/faction_128_japan.png",
		color = Color(255*0.52, 255*0.28, 255*0.28),
		killfeedcol = Color(255*0.52, 255*0.28, 255*0.28),
		glow = Color(255*0.52, 255*0.28, 255*0.28),
		scoremat = hudtype .. "/hud/scorebar_japan.png",
		order = 4
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
	usewav = true,
	winningmusic = "music/waw/campaign/mx_match_ending_jp.wav",
	losingmusic = "music/waw/campaign/mx_match_ending_jp.wav",
	drawmusic = "music/waw/mp_defeat.wav",
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
	sound = "hud/waw/timer_00.wav",
	timings = {
		[30] = 2,
		[10] = 1
	}
}

local function GetFactionColor(ent)
    if not IsValid(ent) then return Color(255,255,255) end
    local faction = ent:GetNW2String("CoDHUD_Faction", "american")
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
    ["war"]      = "tdm_boost",
    ["dm"]       = "ffa_boost",
    ["sd"]       = "obj_destroy",
    ["sesh_war"] = "tdm_boost",
    ["sesh_dm"]  = "ffa_boost",
    ["sesh_sd"]  = "obj_destroy",
    ["sesh_sd_set"] = "obj_destroy",
}

-- [[ HELPERS ]]
local function DrawSqueezedScore(val, x, y, alpha)
	local textCol   = Color(255, 255, 50, alpha)
	local shadowCol = Color(0, 0, 0, alpha * 0.8)
	local s_val     = tostring(val)
	local partPlus  = "+"
	surface.SetFont("WaW_Score_Plus")
	local wP  = surface.GetTextSize(partPlus)
	local gapPlus = CoDHUD_SX(-0)
	surface.SetFont("WaW_Score_Main")
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
	runX = runX + DrawComponent(partPlus, "WaW_Score_Plus", runX, y) + gapPlus
	for i = 1, #s_val do
		local char = s_val:sub(i, i)
		local w    = DrawComponent(char, "WaW_Score_Main", runX, y)
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
CoDHUD[hudtype].MedalsBlockChallenges = false

local function settingsmenu( ... )
	local w = select(1, ...)
	local h = select(2, ...)
	draw.RoundedBox(0, 0, 0, w, h, Color(50,50,50))
	surface.SetDrawColor(255, 255, 255, 125)
	surface.SetMaterial( Material( "cod4/settings/menu_anim" ) )
	surface.DrawTexturedRect(0, 0, w, h)
	surface.SetDrawColor(255, 255, 255)
	surface.SetMaterial( Material( "waw/settings/menu_background_mp_tank.png" ) )
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
		type = "waw",
		writeSounds = textype,
        text = language.GetPhrase("CoD4_MP_CHALLENGE_COMPLETED") .. "\n" .. CoDHUD_ChallengeTitle(header, level),
        x = CoDHUD_SX(960),
        y = CoDHUD_SY(205),
        color = Color(0,0,0),
		holdTime = 4,
        fonts = {
            pri = "WaW_ChalHeader_Pri",
            sec = "WaW_ChalHeader_Sec",
            shd = "WaW_ChalHeader_Shd"
        },
		align = align or nil
    })
    surface.PlaySound("music/waw/achievement/mp_achievement.wav")
end
CoDHUD[hudtype].ChallengeComplete = challengecomplete

local function rs_obj( ... )
	local text = select(1, ...)
	CoDHUD_HeaderQueue.Push({
		type = "waw",
		writeSounds = textype,
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(205),
		color = Color(0,0,0),
		holdTime = 4,
		fonts = { pri = "WaW_RS_O_Pri", sec = "WaW_RS_O_Sec", shd = "WaW_RS_O_Shd" }
	})
end
CoDHUD[hudtype].RoundStartObjective = rs_obj

local function rs_title( ... )
	local text = select(1, ...)
	local glow = select(2, ...)
	local logo = select(3, ...)
	CoDHUD_HeaderQueue.Push({
		type = "waw",
		writeSounds = textype,
		text = language.GetPhrase(text),
		x = CoDHUD_SX(960),
		y = CoDHUD_SY(100),
		color = Color(0,0,0),
		holdTime = 4,
		iconY = CoDHUD_SY(135),
		iconSize = CoDHUD_S(134),
		fonts = { pri = "WaW_RS_H_Pri", sec = "WaW_RS_H_Sec", shd = "WaW_RS_H_Shd" },
		icon = logo
	})
end
CoDHUD[hudtype].RoundStart = rs_title

local function rs_timer( ... )
	local disp = select(1, ...)
	local disptext = disp
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local tx  = CoDHUD_SX(960)
    local ty  = ScrH() * 0.5
    local syo = CoDHUD_SY(-50)
	if disp ~= rs_last_dig then rs_last_dig = disp rs_dig_scale = 1.9 end
	rs_dig_scale = math.Approach(rs_dig_scale, 1, FrameTime() * 6)
	if disp > 0 then
		local tMat = Matrix()
		tMat:Translate(Vector(tx, ty, 0))
		tMat:Scale(Vector(rs_dig_scale, rs_dig_scale, 1))
		tMat:Translate(Vector(-tx, -ty, 0))
		cam.PushModelMatrix(tMat)
			draw.SimpleTextOutlined( disptext, "WaW_RS_Timer", tx, ty, Color(255,255,100), 1, 1, outlined and 1 or 0, Color(0,0,0) )
		cam.PopModelMatrix()
		draw.SimpleTextOutlined( "#MW2_MP_MATCH_STARTING_IN", "WaW_RS_S_Pri", tx, ty + syo, Color(255,255,255), 1, 1, outlined and 1 or 0, Color(0,0,0) )
	end
end
CoDHUD[hudtype].RoundStartTimer = rs_timer

local function re_teams( ... )
    local teams = select(1, ...)
    local ws_result = select(2, ...)
    local ws_limit = select(3, ...)
    local re_result_glow = select(4, ...)
    local CFG = select(5, ...)

    local multiplier = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10

    local scaledTeams = {}
    for k, v in ipairs(teams) do
        scaledTeams[k] = {
            fac = v.fac,
            score = (v.score or 0) * multiplier
        }
    end

    CoDHUD_HeaderQueue.Push({
		type = "waw",
		writeSounds = textype,
        teams = scaledTeams,
        x = CoDHUD_SX(960), y = CoDHUD_SY(400),
        multiple = true, persist = true, endTime = CFG.SCOREBOARD_DELAY,
        iconSize = CoDHUD_S(184), iconGap = CoDHUD_S(80), scoreY = CoDHUD_SY(620),
        fonts = { pri = "WaW_RE_Sc_Pri", sec = "WaW_RE_Sc_Sec", shd = "WaW_RE_Sc_Shd" }
    })
	CoDHUD_HeaderQueue.Push({
		type = "waw", writeSounds = textype,
		text = ws_result, x = CoDHUD_SX(960), y = CoDHUD_SY(240), color = re_result_glow,
		multiple = true, skipErase = true, persist = true, endTime = CFG.SCOREBOARD_DELAY,
		fonts = { pri = "WaW_RE_Re_Pri", sec = "WaW_RE_Re_Sec", shd = "WaW_RE_Re_Shd" }
	})
	CoDHUD_HeaderQueue.Push({
		type = "waw", writeSounds = textype,
		text = ws_limit, x = CoDHUD_SX(960), y = CoDHUD_SY(330), color = Color(0,0,0),
		multiple = true, skipErase = true, persist = true, endTime = CFG.SCOREBOARD_DELAY,
		fonts = { pri = "WaW_RE_Li_Pri", sec = "WaW_RE_Li_Sec", shd = "WaW_RE_Li_Shd" }
	})
end
CoDHUD[hudtype].RoundEnd = re_teams

local function re_bonus( ... )
	local re_lock_time = select(1, ...)
	local re_match_bonus = math.Round(select(2, ...) * 0.1)
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
    local el = CurTime() - re_lock_time
    if el < 0 then return end
    if el >= 6.0 then return end
    local iconAlpha = math.floor(math.Clamp(el / 1.0, 0, 1) * 255)
	draw.SimpleTextOutlined( string.format( language.GetPhrase("MW2_MP_MATCH_BONUS_IS"), tostring(re_match_bonus) ), "WaW_RE_Bonus", CoDHUD_SX(960), CoDHUD_SY(720), Color(255, 255, 255, iconAlpha), 1, 1, outlined and 1 or 0, Color(0,0,0, iconAlpha) )
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
	local scoreVal = select(6, ...) -- no * 0.1: XP values from cl_hitmarker are already correct

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
		if IsValid(v.ent) then targetWorldPos = v.ent:GetPos() + (ply:GetPos() - v.ent:GetPos()) * -33000 end
		local localPos = ply:WorldToLocal(targetWorldPos)
		local screenAngleRad = math.atan2(localPos.x, -localPos.y)
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
        local screenAngleRad = math.atan2(localPos.x, -localPos.y)
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
        if timeLeft <= 0 then table.remove(KillFeed, i) continue end
        local animProgress = math.Clamp(age / ANIM_TIME, 0, 1)
        local fadeFactor = 1
        if age < ANIM_TIME then fadeFactor = animProgress
        elseif timeLeft < 1 then fadeFactor = math.Clamp(timeLeft, 0, 1) end
        local yOffset = (1 - animProgress) * CoDHUD_S(ANIM_RISE)
		local currentY = baseY - ((#KillFeed - i) * spacing) + yOffset
        local x = xPos
        local finalTxtAlpha = 155 * fadeFactor
        surface.SetFont("MW2_KillfeedFont")
		local aColBase = GetFactionColor(data.attackerEnt)
		local vColBase = GetFactionColor(data.victimEnt)
		local aCol = Color(aColBase.r, aColBase.g, aColBase.b, finalTxtAlpha)
		local vCol = Color(vColBase.r, vColBase.g, vColBase.b, finalTxtAlpha)
        if data.type == "kill" then
			local cls = data.isHeadshot and "CoDHUD_WaW_Headshot" or data.weaponClass
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
			local offsetY = CoDHUD_S(-15)
			if cls == "CoDHUD_MW2_Headshot" then offsetY = CoDHUD_S(-2) end
			killicon.Render(x + gap, iconY + (h * 0.33) + offsetY, cls, alpha, false, false)
			x = x + w + (gap * 2)
			draw.SimpleText(data.victimName, "MW2_KillfeedFont", x, currentY, vCol)
        else
            draw.SimpleText(data.msg, "MW2_KillfeedFont", x, currentY, Color(255, 255, 255, finalTxtAlpha))
        end
    end
end
CoDHUD[hudtype].Killfeed = killfeed

CoDHUD[hudtype].Medals = nil
CoDHUD[hudtype].MedalsSound = nil

local function minimap( ... )
	local ply = select(1, ...)
	local MAP_CFG = {
		X = 12, Y = 38, W = 232, H = 232,
		ALPHA_BORDER = 255, ALPHA_MAP_BG = 120, ALPHA_PLAYER = 255,
		ALPHA_STATIC_S = 100, ALPHA_MOVING_S = 255,
		SIZE_PLAYER = 42, SIZE_FRIENDLY = 42, SIZE_ENEMY = 42,
		SCAN_SPEED = 48, FADE_TIME = 0.7, FADE_TIME_VIS = 1.3,
		EDGE_PADDING = 0,
	}
	local MAT_BORDER       = Material(hudtype .. "/minimap/minimap_background.png", "smooth")
	local MAT_MAP_BG       = Material(hudtype .. "/minimap/compass_map_default.png", "smooth")
	local MAT_PLAYER       = Material(hudtype .. "/minimap/compassping_player.png", "smooth")
	local MAT_COMPASS      = Material(hudtype .. "/minimap/minimap_tickertape_256x16.png", "smooth noclamp")
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
    render.SetStencilEnable(false)
	local yaw = (ply:EyeAngles().y + 90) % 360
	local u = 1 - (yaw / 360)
	local compassH = h * 0.1
	local scale = 0.5
	surface.SetDrawColor(0, 0, 0, 200)
	surface.DrawRect(x, y - CoDHUD_S(26), w, compassH)
	surface.SetMaterial(MAT_COMPASS)
	surface.SetDrawColor(255, 255, 255)
	local uEnd = u + scale
	if uEnd <= 1 then
		surface.DrawTexturedRectUV(x, y - CoDHUD_S(26), w, compassH, u, 0, uEnd, 1)
	else
		local overflow = uEnd - 1
		local split = (1 - u) / scale
		surface.DrawTexturedRectUV( x, y - CoDHUD_S(26), w * split, compassH, u, 0, 1, 1 )
		surface.DrawTexturedRectUV( x + (w * split), y - CoDHUD_S(26), w * (1 - split), compassH, 0, 0, overflow, 1 )
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
            if isVisibleToTeam and isAlive then CoDHUD_VisCache[entIdx] = CurTime() + MAP_CFG.FADE_TIME_VIS end
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
        if not isAlive then
            if isFriendly then continue
            else
                if not CoDHUD_DeathCache[entIdx] then CoDHUD_DeathCache[entIdx] = CurTime() end
                local timeSinceDeath = CurTime() - CoDHUD_DeathCache[entIdx]
                if timeSinceDeath > MAP_CFG.FADE_TIME then continue end
                alpha = math.min(alpha, 255 * (1 - (timeSinceDeath / MAP_CFG.FADE_TIME)))
            end
        else CoDHUD_DeathCache[entIdx] = nil end
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
			x2 = x2 / radar.ratio y2 = y2 / radar.ratio
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

-- local debugpic = true
local debugpicture = Material("debugref/waw.png", "smooth")

local function scorebar(data)
	local CFG = {
		BAR_W = 282.5, BAR_H = 96, BAR_X_OFF = 10, BAR_Y_OFF = 27,
		ICON_SCALE = 0.825, ICON_X = 10, ICON_Y = 7,
		TIMER_X = 367.5, TIMER_Y = 43, TIMER_SHIFT_2DIG = -0, TIMER_SHIFT_3DIG = -0, TIMER_OUTLINE_W = 1.5,
		STATUS_X = 960, STATUS_Y = 0,
		SQUEEZE = -2, SQUEEZE_ONE = -6, SQUEEZE_ONE_BEFORE = -4,
	}
	local SCORES_CFG = {
		X = 122, Y = 51.5, GAP_OFFSET = 42,
		SQUEEZE = -0, SQUEEZE_ONE = -0, SQUEEZE_ONE_BEFORE = -0, OUTLINE_W = 1.5,
		SCORE_LIMIT = 75,
		HUD_X = 200, HUD_Y = 1015, HUD_W_BASE = 0, HUD_W_MAX = 180, HUD_H = 10,
		SLANT_SIZE = 11, VERTICAL_GAP = 10, SHADOW_OFFSET = 2,
		BASE_X = 112, BASE_Y = 1008, BASE_W = 180, BASE_H = 22.5, BASE_SLANT = 10, BASE_GAP = 18,
		CAP_W = 3, CAP_H_OFFSET = 2, CAP_SLANT = 10, CAP_COLOR = Color(255, 255, 255, 155),
		SLANT_W = 7, SLANT_H_OFFSET = 0.4, SLANT_SEP_W = 1, SLANT_Y_OFFSET_TOP = 0,
		SLANT_COLOR = Color(255, 255, 255, 220),
	}
	local ARROW_CFG = {
		x = 296.5, y = 959, w = 21, h = 42, outline = 4,
		color = Color(255,255,255,155), outlineColor = Color(0,0,0,155),
		material = Material(hudtype .. "/icons/dpad_arrow_right.png", "smooth noclamp"),
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

	local losing = data.statusLosing
	local losingoffset = CoDHUD_S(0)
	local losingarrowoffset = CoDHUD_S(0)
	local bgmat = Material(hudtype .. "/hud/scorebar_backdrop.png", "smooth")
	if losing then losingarrowoffset = CoDHUD_SY(40) end
    surface.SetMaterial(bgmat)
    surface.SetDrawColor(255, 255, 255, 155)
    surface.DrawTexturedRect(barX, barY, barW, barH)

	local factionData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][currentFaction]
	local factionMat = factionData and factionData.scoreIcon
	if not factionData then currentFaction = "rangers" factionData = CoDHUD.Factions[hudtype][currentFaction] end
	if factionMat then
		local iSize = math.Round(barH * CFG.ICON_SCALE)
		surface.SetMaterial(Material(factionMat, "smooth"))
		surface.SetDrawColor(255, 255, 255, 255)
		surface.DrawTexturedRect( barX + CoDHUD_SX(CFG.ICON_X), barY + CoDHUD_SY(CFG.ICON_Y), iSize, iSize )
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
		DrawSqueezedText( timeStr, "WaW_Timer", barX + CoDHUD_SX(CFG.TIMER_X) + xShift, barY + CoDHUD_SY(CFG.TIMER_Y), timecol, CFG.SQUEEZE, CFG.SQUEEZE_ONE, 2, CFG.SQUEEZE_ONE_BEFORE, CoDHUD_SX(CFG.TIMER_OUTLINE_W) )
	end
	data.tiedCol = Color(110, 220, 120, 255)
	data.winningCol = Color(215, 110, 120, 255)
	data.losingCol = Color(230, 230, 110, 255)

    local clientKills   = data.clientScore
    local topEnemyKills = data.enemyScore
    local S_CFG = SCORES_CFG

    local baseX     = CoDHUD_S(S_CFG.BASE_X)
    local baseY_raw = scrH - CoDHUD_S(1080 - S_CFG.BASE_Y)
    local baseW     = CoDHUD_S(S_CFG.BASE_W)
    local baseH     = CoDHUD_S(S_CFG.BASE_H)
    local baseSlant = CoDHUD_S(S_CFG.BASE_SLANT)
    local baseGap   = CoDHUD_S(S_CFG.BASE_GAP)
    local hudX      = CoDHUD_S(S_CFG.HUD_X)
    local hudY_raw  = scrH - CoDHUD_S(1080 - S_CFG.HUD_Y)
    local hudWBase  = CoDHUD_S(S_CFG.HUD_W_BASE)
    local hudWMax   = CoDHUD_S(S_CFG.HUD_W_MAX)
    local hudH      = CoDHUD_S(S_CFG.HUD_H)
    local BASE_X = baseX
    local BASE_Y = baseY_raw
    local BASE_W = baseW
    local BASE_H = baseH
    local BASE_SLANT = baseSlant
    local top_y_base = BASE_Y - baseGap - BASE_H

	local friendlybary = BASE_Y - baseGap - BASE_H
	local enemybary = BASE_Y
	if losing then friendlybary = BASE_Y enemybary = BASE_Y - baseGap - BASE_H end

    draw.NoTexture()
	surface.SetMaterial(Material(hudtype .. "/hud/scorebar_bar.png", "mips smooth"))
    surface.SetDrawColor(200,200,200,200)
    surface.DrawTexturedRect(BASE_X, top_y_base, BASE_W, BASE_H)
    surface.DrawTexturedRect(BASE_X, BASE_Y, BASE_W, BASE_H)

    local liveScoreLimit = S_CFG.SCORE_LIMIT
    local gmCV2 = GetConVar("codhud_selected_gamemode")
    if gmCV2 and gmCV2:GetString() == "sesh_dm" then
        -- Sesh FFA has its own hardwired limit, independent of codhud_score_limit
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

	-- Use gamemode-aware multiplier (1 for S&D, 10 for everything else)
	local scoreMultiplier = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10
	liveScoreLimit = liveScoreLimit * scoreMultiplier

    local maxAddedWidth = hudWMax - hudWBase
    local client_w = math.Round(hudWBase + math.Clamp(((clientKills * scoreMultiplier) / liveScoreLimit) * maxAddedWidth, 0, maxAddedWidth))
    local enemy_w  = math.Round(hudWBase + math.Clamp(((topEnemyKills * scoreMultiplier) / liveScoreLimit) * maxAddedWidth, 0, maxAddedWidth))

    local HUD_X = hudX
    local HUD_Y = hudY_raw
    local white = Color(255,255,255,255)

	local defaultbar = Material(hudtype .. "/hud/scorebar_bar.png", "mips smooth")
	local friendlybar = defaultbar
	local enemybar = defaultbar
	if currentFaction and CoDHUD.Factions[hudtype][currentFaction] then
		friendlybar = Material(CoDHUD.Factions[hudtype][currentFaction].scoremat, "mips smooth")
	end
	surface.SetMaterial(friendlybar)
	surface.SetDrawColor(Color(255,255,255))
	surface.DrawTexturedRect(BASE_X, friendlybary, client_w, BASE_H)

	local enemyFaction = data.enemyFaction
	if enemyFaction and CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][enemyFaction] and CoDHUD.Factions[hudtype][enemyFaction].scoremat then
		enemybar = Material(CoDHUD.Factions[hudtype][enemyFaction].scoremat, "mips smooth")
	else
		enemybar = defaultbar
	end
	surface.SetMaterial(enemybar)
	surface.SetDrawColor(Color(255,255,255))
	surface.DrawTexturedRect(BASE_X, enemybary, enemy_w, BASE_H)

	local cky = HUD_Y - CoDHUD_S(S_CFG.Y) + losingoffset
	local eky = HUD_Y - CoDHUD_S(S_CFG.Y) + CoDHUD_S(S_CFG.GAP_OFFSET) + losingoffset
	if losing then
		eky = HUD_Y - CoDHUD_S(S_CFG.Y) + losingoffset
		cky = HUD_Y - CoDHUD_S(S_CFG.Y) + CoDHUD_S(S_CFG.GAP_OFFSET) + losingoffset
	end

    DrawSqueezedText(clientKills * scoreMultiplier,   "WaW_Font", CoDHUD_S(S_CFG.X), cky, white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)
    DrawSqueezedText(topEnemyKills * scoreMultiplier, "WaW_Font", CoDHUD_S(S_CFG.X), eky, white, S_CFG.SQUEEZE, S_CFG.SQUEEZE_ONE, 2, S_CFG.SQUEEZE_ONE_BEFORE, S_CFG.OUTLINE_W)

    local ax = CoDHUD_S(ARROW_CFG.x)
    local ay = scrH - CoDHUD_S(1080 - ARROW_CFG.y)
    local aw = CoDHUD_S(ARROW_CFG.w)
    local ah = CoDHUD_S(ARROW_CFG.h)
    surface.SetMaterial(ARROW_CFG.material)
    surface.SetDrawColor(ARROW_CFG.color)
	surface.DrawTexturedRect(ax, ay + losingarrowoffset, aw, ah)
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
		HEADER_Y_POS = 90, HEADER_H = 50, HEADER_ALPHA = 150,
		HEADER_ICON_SIZE = 86, HEADER_ICON_X = 140, HEADER_ENEMY_ICON_X = 340,
		MAP_Y_OFF = 98,
		PING_BOX_SIZE = 38, PING_BOX_ALPHA = 155, PING_X_OFF = 5, PING_BAR_W = 6, PING_BAR_SPACING = 3,
		TIMER_X_POS = 375, TIMER_Y_OFF = 98,
		SQUEEZE = -2, SQUEEZE_ONE = -6, SQUEEZE_ONE_BEFORE = -4, TIMER_OUTLINE_W = 2,
		OFF_DEATHS = 10, OFF_ASSISTS = 120, OFF_KILLS = 225, OFF_SCORE = 335,
	}

	local MAT_GRADIENT_L = Material(hudtype .. "/hud/line_horizontal_scoreboard.png", "mips smooth")
	local MAT_ICON_DEAD  = Material(hudtype .. "/icons/hud_status_dead.png", "mips smooth")
	local viewportTop    = CoDHUD_S(175)
	local viewportHeight = CoDHUD_S(800)
	local viewportBottom = viewportTop + viewportHeight

	local function SortLogic(a, b)
		local sbMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10
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
		local pScore = math.max(0, ply:Frags() * (CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10))
		draw.SimpleTextOutlined(ply:Nick(), "WaW_Scoreboard_Text", x + CoDHUD_S(110), y + (h / 2), tCol, TEXT_ALIGN_LEFT,  TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:Deaths(), "WaW_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_DEATHS),  y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:GetNWInt("Assists", 0), "WaW_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_ASSISTS), y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(ply:Frags(), "WaW_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_KILLS),   y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
		draw.SimpleTextOutlined(pScore, "WaW_Scoreboard_Text", barRight - CoDHUD_S(CFG.OFF_SCORE),   y + (h / 2), tCol, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER, outlined and 1 or 0, Color(0, 0, 0))
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

	local factionList = {}
	for fac, players in pairs(factions) do
		table.sort(players, SortLogic)
		table.insert(factionList, { key = fac, players = players, score = 0 })
	end

	local sbMul = CoDHUD_GetScoreMultiplier and CoDHUD_GetScoreMultiplier() or 10
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
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_DEATHS"), "WaW_Scoreboard_Headers", barRight - CoDHUD_S(CFG.OFF_DEATHS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_ASSISTS"), "WaW_Scoreboard_Headers", barRight - CoDHUD_S(CFG.OFF_ASSISTS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_KILLS"), "WaW_Scoreboard_Headers", barRight - CoDHUD_S(CFG.OFF_KILLS), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		draw.SimpleTextOutlined( language.GetPhrase("MW2_CGAME_SB_SCORE"), "WaW_Scoreboard_Headers", barRight - CoDHUD_S(CFG.OFF_SCORE), headerY, Color(255,255,255), TEXT_ALIGN_RIGHT, 0, outlined and 1 or 0, Color(0,0,0) )
		for fi, facData in ipairs(factionList) do
			local players = facData.players
			local facKey = facData.key
			local fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][facKey] or { name = facKey, short = facKey, color = Color(120,120,120) }
			local sectionY = startY
			local iconPath = CoDHUD.Factions[hudtype][facKey].spawnIcon
			local mat = Material(iconPath, "smooth")
			surface.SetMaterial(mat)
			surface.SetDrawColor(255,255,255,255)
			surface.DrawTexturedRect(barX + CoDHUD_S(CFG.ICON_X_OFF), sectionY + CoDHUD_S(CFG.ICON_Y_OFF), CoDHUD_S(CFG.ICON_SIZE), CoDHUD_S(CFG.ICON_SIZE))
			draw.SimpleTextOutlined( language.GetPhrase(fData.short) .. " (" .. #players .. ")", "WaW_Scoreboard_Text", barX + CoDHUD_S(CFG.FAC_NAME_X), sectionY + CoDHUD_S(CFG.FAC_NAME_Y), Color(255,255,255), 0,0, outlined and 1 or 0, Color(0,0,0) )
			for i, ply in ipairs(players) do
				local rowY = sectionY + (i - 1) * (barH + CoDHUD_S(CFG.ROW_GAP))
				DrawPlayerRow(ply, lp, barX, rowY, barW, barH, barRight, fData.color)
			end
			local sectionHeight = CoDHUD_S(0) + (#players * (barH + CoDHUD_S(CFG.ROW_GAP)))
			startY = startY + sectionHeight + CoDHUD_S(CFG.TEAM_GAP)
		end
	render.SetScissorRect(0, 0, 0, 0, false)

	local myFaction = lp:GetNW2String("CoDHUD_Faction", "rangers")
	if myFaction == "" then myFaction = "rangers" end
	local myFactionCol = CoDHUD.Factions[hudtype][myFaction].color
    surface.SetMaterial(MAT_GRADIENT_L)
    surface.SetDrawColor(255, 255, 255, CFG.HEADER_ALPHA)
    surface.DrawTexturedRect(0, CoDHUD_S(CFG.HEADER_Y_POS) - CoDHUD_S(6), scrW, CoDHUD_S(CFG.HEADER_H * 0.1))
    surface.DrawTexturedRect(0, CoDHUD_S(CFG.HEADER_Y_POS) + CoDHUD_S(CFG.HEADER_H) + CoDHUD_S(2), scrW, CoDHUD_S(CFG.HEADER_H * 0.1))
    local mapName = string.upper(game.GetMap())
	draw.SimpleTextOutlined( mapName, "WaW_Scoreboard_Text", scrW/2, CoDHUD_S(CFG.MAP_Y_OFF), Color(255, 255, 255), 1, 0, outlined and 1.5 or 0, Color(0,0,0) )
    local totalSecs = math.floor(CurTime())
    local mins, secs = math.floor(totalSecs / 60), totalSecs % 60
    local timeStr = string.format("%d:%02d", mins, secs)
    DrawSqueezedText(timeStr, "WaW_Timer", scrW - CoDHUD_S(CFG.TIMER_X_POS), CoDHUD_S(CFG.TIMER_Y_OFF), Color(255, 255, 255, 255), CFG.SQUEEZE, CFG.SQUEEZE_ONE, 2, CFG.SQUEEZE_ONE_BEFORE, outlined and 1.5 or 0)

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
	surface.SetFont("WaW_Scoreboard_Text")
	for _, fac in ipairs(factionList) do
		local key = fac.key
		local score = fac.score or 0
		local fData = CoDHUD.Factions[hudtype] and CoDHUD.Factions[hudtype][key] or { short = key, color = Color(150,150,150) }
		local iconPath = CoDHUD.Factions[hudtype][key].spawnIcon
		local mat = Material(iconPath, "smooth")
		if mat:IsError() then mat = Material(hudtype .. "/vgui/hud/icon_error") end
		local label = score
		local textW, textH = surface.GetTextSize(label)
		surface.SetMaterial(mat)
		surface.SetDrawColor(255,255,255,255)
		surface.DrawTexturedRect(x, stripY, iconSize, iconSize)
		draw.SimpleTextOutlined( label, "WaW_Scoreboard_Text", x + iconSize + textOffset, stripY + iconSize / 2, Color(255,255,255), 0, 1, outlined and 1 or 0, Color(0,0,0) )
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
	if debugpic then
		surface.SetMaterial(debugpicture)
		surface.SetDrawColor(255, 255, 255, 100)
		surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
	end

	local MASK = select(1, ...)
	local ply = select(3, ...)

	local CFG = {
		BAR_W = 776, BAR_H = 122, BAR_X_OFF = 2, BAR_Y_OFF = 48,
		GRENADE_X_OFF = 90, GRENADE_Y_OFF = 115, GRENADE_ICON_W = 54, GRENADE_ICON_H = 54,
		RES_X = -61, RES_Y = 106,
		RES3_X = -66, RES3_Y = 106,
		RES4_X = -71, RES4_Y = 106,
		WEP_NAME_X_OFF = -160, WEP_NAME_Y_OFF = 74, WEP_NAME_FADE = 2, WEP_NAME_SQ = -3, WEP_NAME_SQ1 = -8,
		STAT_FONT_SIZE = 28, STAT_LOW_PERC = 0.40, STAT_FLASH_SPD = 8, STAT_Y_OFF = 62,
		BULLET_ALPHA = 255, BULLET_RELOAD_R = 180, BULLET_RELOAD_G = 60, BULLET_RELOAD_B = 60, BULLET_RELOAD_SPD = 6,
		ALT_ICON_SIZE = 64, ALT_ICON_X = 762, ALT_ICON_Y = 960,
		ALT_TEXT_X = 808, ALT_TEXT_Y = 993.5, ALT_FONT_SIZE = 36, ALT_TEXT_SQ = -2.5, ALT_TEXT_SQ1 = -2.5,
	}

	local AMMO = {
		["default"] = { row_size = 50, row_gap = 0, mat = "cod4/hud/ammo_counter_bullet.png",          w = 3,  h = 14,   gap = 0, y_off = 117.5, x_start = -80,  dim = 75 },
		["rocket"]  = { row_size = 20, row_gap = 0, mat = "cod4/hud/ammo_counter_rocket.png",          w = 48, h = 24,   gap = 0, y_off = 112.5, x_start = -125, dim = 75 },
		["sniper"]  = { row_size = 20, row_gap = 0, mat = "cod4/hud/ammo_counter_riflebullet.png",     w = 32, h = 8,    gap = 5, y_off = 122,   x_start = -105, dim = 75 },
		["shotgun"] = { row_size = 25, row_gap = 0, mat = "cod4/hud/ammo_counter_shotgunshell.png",    w = 25, h = 12.5, gap = 5, y_off = 118,   x_start = -100, dim = 75 },
		["belt"]    = { row_size = 25, row_gap = 0, mat = "cod4/hud/ammo_counter_beltbullet.png",      w = 7,  h = 2.5,  gap = 0, y_off = 126.5, x_start = -80,  dim = 75 },
	}
	local AMMO_MAP = {
		["357"] = "default", ["ar2"] = "default", ["xbowbolt"] = "sniper",
		["xbowbolthl1"] = "sniper", ["sniperround"] = "sniper", ["sniperpenetratedround"] = "sniper",
		["pistol"] = "default", ["smg1"] = "default", ["buckshot"] = "shotgun",
		["buckshothl1"] = "shotgun", ["rpg_round"] = "rocket", ["smg1_grenade"] = "rocket",
		["mp5_grenade"] = "rocket", ["rpg_rocket"] = "rocket", ["ar2altfire"] = "rocket",
		["slam"] = "rocket", ["gaussenergy"] = "belt", ["ti_sniper"] = "sniper",
	}
	local MAT_ALT = {
		["grenade"] = Material(hudtype .. "/hud/hud_grenade_launcher_dpad.png", "smooth mips"),
		["buckshot"] = Material("mw2/hud/dpad_underbarrel_shotgun.png", "smooth mips")
	}
	local MAT_GRENADE = Material(hudtype .. "/hud/hud_us_grenade.png", "smooth")
	local MAT_AMMO = {}
	for key, data in pairs(AMMO) do MAT_AMMO[key] = Material(data.mat, "smooth") end

	local function GetAmmoConfig(wep, alt)
		if not IsValid(wep) then return AMMO["default"] end
		local ammoName = string.lower(game.GetAmmoName(alt and wep:GetSecondaryAmmoType() or wep:GetPrimaryAmmoType()) or "")
		if (alt and wep:GetMaxClip2() or wep:GetMaxClip1()) > 50 then return AMMO["belt"] end
		return AMMO[AMMO_MAP[ammoName]] or AMMO["default"]
	end
	local function GetAmmoKey(ammoCfg)
		for key, data in pairs(AMMO) do if data == ammoCfg then return key end end
		return "default"
	end

    local grenadeCount = ply:GetAmmoCount("Grenade") or 0
	local barW = CoDHUD_SX(CFG.BAR_W)
	local barH = CoDHUD_SY(CFG.BAR_H)
	local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF) - barW
	local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH
	local iW = CoDHUD_S(CFG.GRENADE_ICON_W)
	local iH = CoDHUD_S(CFG.GRENADE_ICON_H)
	local anchorX = ScrW() - CoDHUD_SX(CFG.GRENADE_X_OFF)
	local anchorY = ScrH() - CoDHUD_SY(CFG.GRENADE_Y_OFF)
	surface.SetMaterial(MAT_GRENADE)
	surface.SetDrawColor(255,255,255)
	surface.DrawTexturedRect(anchorX, anchorY, iW, iH)
	local textcol = Color(255,100,100)
    if grenadeCount > 0 then
		textcol = Color(255,255,255)
		if grenadeCount > 9 then grenadeCount = "9+" end
    end
	DrawSqueezedText(grenadeCount, "WaW_Res_3D", anchorX + (iH * 0.9), anchorY + (iW * 0.4), textcol, 0, 0, 2)

    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    if wep ~= lastWep then lastWep = wep wepSwitchTime = CurTime() end

    local clip    = wep:Clip1()
    local clip2   = wep:Clip2()
    local maxClip = wep:GetMaxClip1()
    local maxClip2 = wep:GetMaxClip2()
    local primType = wep:GetPrimaryAmmoType()
    local altType = wep:GetSecondaryAmmoType()
    local reserve = ply:GetAmmoCount(wep:GetPrimaryAmmoType())

    local barW = CoDHUD_SX(CFG.BAR_W)
    local barH = CoDHUD_SY(CFG.BAR_H)
    local barX = ScrW() - CoDHUD_SX(CFG.BAR_X_OFF) - barW
    local barY = ScrH() - CoDHUD_SY(CFG.BAR_Y_OFF) - barH

    if clip >= 0 then
        local resCol = (reserve == 0 or reserve < maxClip) and Color(255, 120, 120, 255) or Color(255, 255, 255, 255)
        if reserve >= 1000 then DrawSqueezedText(reserve, "WaW_Res_3D", barX + barW + CoDHUD_SX(CFG.RES4_X), barY + CoDHUD_SY(CFG.RES4_Y), resCol, CoDHUD_S(-2.5), CoDHUD_S(-2.5), 2)
        elseif reserve >= 100 then DrawSqueezedText(reserve, "WaW_Res_3D", barX + barW + CoDHUD_SX(CFG.RES3_X), barY + CoDHUD_SY(CFG.RES3_Y), resCol, CoDHUD_S(-2.5), CoDHUD_S(-2.5), 2)
        else DrawSqueezedText(reserve, "WaW_Res_3D", barX + barW + CoDHUD_SX(CFG.RES_X), barY + CoDHUD_SY(CFG.RES_Y), resCol, CoDHUD_S(0), CoDHUD_S(0), 2) end
    end

    local timeSinceSwitch = CurTime() - wepSwitchTime
    if timeSinceSwitch < CFG.WEP_NAME_FADE then
        local alpha = math.Clamp(1 - (timeSinceSwitch / CFG.WEP_NAME_FADE), 0, 1)
        local name  = language.GetPhrase(wep:GetPrintName() or wep:GetClass())
        draw.SimpleTextOutlined(name, "WaW_Wep_Name", barX + barW + CoDHUD_SX(CFG.WEP_NAME_X_OFF), barY + CoDHUD_SY(CFG.WEP_NAME_Y_OFF), Color(255, 255, 255, 255 * alpha), 2, 0, outlined and 1.5 or 0, Color(0, 0, 0, 255 * alpha))
    end

    if clip >= 0 and maxClip > 0 then
        local perc = clip / maxClip
        local isLowClip = (perc <= CFG.STAT_LOW_PERC)
        local reloadSine = isLowClip and ((math.sin(CurTime() * CFG.BULLET_RELOAD_SPD) + 1) / 2) or 0
        local ammoCfg = GetAmmoConfig(wep)
        local ammoKey = GetAmmoKey(ammoCfg)
        local iW = CoDHUD_S(ammoCfg.w) local iH = CoDHUD_S(ammoCfg.h)
        local iGap = CoDHUD_S(ammoCfg.gap)
        local iYOff = CoDHUD_SY(ammoCfg.y_off)
        local iXStart = CoDHUD_SX(ammoCfg.x_start)
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
            local yPos = barY + iYOff - iH * (maxClip2 > 0 and 0.5 or 0) - (row * (iH + rowGap))
            surface.DrawTexturedRect(xPos, yPos, iW, iH)
        end
    end

    -- Only draw secondary ammo row when there is a genuine underbarrel/secondary
    -- with its own clip (altType must exist, differ from primary, and not be a grenade)
    if clip2 >= 0 and maxClip2 > 0
        and altType ~= -1
        and altType ~= primType
        and altType ~= game.GetAmmoID("Grenade") then
        local perc = clip2 / maxClip2
        local isLowClip = (perc <= CFG.STAT_LOW_PERC)
        local reloadSine = isLowClip and ((math.sin(CurTime() * CFG.BULLET_RELOAD_SPD) + 1) / 2) or 0
        local ammoCfg = GetAmmoConfig(wep, true)
        local ammoKey = GetAmmoKey(ammoCfg)
        local iW = CoDHUD_S(ammoCfg.w) local iH = CoDHUD_S(ammoCfg.h)
        local iGap = CoDHUD_S(ammoCfg.gap)
        local iYOff = CoDHUD_SY(ammoCfg.y_off)
        local iXStart = CoDHUD_SX(ammoCfg.x_start)
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
            local yPos = barY + iYOff + iH * 0.5 + (row * (iH + rowGap))
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

	local altAmmoName = game.GetAmmoName(altType)
    if altType ~= -1 and altType ~= primType and altType ~= game.GetAmmoID("Grenade") then
        local altCount = ply:GetAmmoCount(altType)
		local alticon = "grenade"
		if altAmmoName == "Buckshot" then alticon = "buckshot" end
		surface.SetMaterial(MAT_ALT[alticon])
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawTexturedRect(CoDHUD_SX(CFG.ALT_ICON_X), CoDHUD_SY(CFG.ALT_ICON_Y), CoDHUD_S(CFG.ALT_ICON_SIZE), CoDHUD_S(CFG.ALT_ICON_SIZE))
        local altCol = (altCount > 0) and Color(255, 255, 255, 255) or Color(255, 120, 120, 255)
        DrawSqueezedText(altCount, "WaW_Ammo_Alt", CoDHUD_SX(CFG.ALT_TEXT_X), CoDHUD_SY(CFG.ALT_TEXT_Y), altCol, CFG.ALT_TEXT_SQ, CFG.ALT_TEXT_SQ1, 2)
    end

    if clip >= 0 and maxClip > 0 and not reloading then
        local perc = clip / maxClip
        local statText = ""
        local statCol = Color(255, 255, 255)
        local isNoAmmo = false local isLowAmmo = false local isReloadText = false
        if clip == 0 and reserve == 0 then statText = "#MW2_WEAPON_NO_AMMO" isNoAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and reserve == 0 then statText = "#MW2_PLATFORM_LOW_AMMO_NO_RELOAD" statCol = Color(255, 230, 0) isLowAmmo = true
        elseif perc <= CFG.STAT_LOW_PERC and reserve > 0 then statText = "#MW2_PLATFORM_RELOAD" isReloadText = true end
        if statText ~= "" then
            local cx = ScrW() / 2
            local cy = (ScrH() / 2) + CoDHUD_SY(CFG.STAT_Y_OFF)
            local sine = (math.sin(CurTime() * CFG.STAT_FLASH_SPD) + 1) / 2
            local finalCol = table.Copy(statCol)
            if isNoAmmo then local glow = 225 + (sine * 30) finalCol = Color(glow, 40, 40, glow)
            elseif isLowAmmo or isReloadText then finalCol.a = 100 + (sine * 155) end
            draw.SimpleTextOutlined(language.GetPhrase(statText), "WaW_Stat_Font", cx + CoDHUD_SX(2), cy + CoDHUD_SY(2), finalCol, 1, 1, 1.5, Color(0, 0, 0, finalCol.a * 0.8))
        end
    end
end
CoDHUD[hudtype].WeaponInfo = weaponinfo