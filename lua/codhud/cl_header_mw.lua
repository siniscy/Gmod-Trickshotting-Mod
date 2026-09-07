---- [ CLIENT HEADER SYSTEM - MODERN WARFARE 1-3 ] ----

CoDHUD_Header_MW = {}
CoDHUD_Header_MW.__index = CoDHUD_Header_MW

CoDHUD_HeaderQueue = CoDHUD_HeaderQueue or {}
CoDHUD_HeaderQueue.Active = CoDHUD_HeaderQueue.Active or {}
CoDHUD_HeaderQueue.Queue = {}

local GLITCH = { "a", "¶", "Ð", "ق", "§", "ð", "œ", "ش", "Ф" }
local BO_SCRAMBLE = { "0", "1", "2", "3", "4", "5", "6", "7", "8", "9" }

-- =========================
-- Constructor
-- =========================
local function SafeLen(str)
    if not str then return 0 end

    local ok, len = pcall(utf8.len, str)
    if not ok or not len then
        return #str -- fallback to byte length
    end

    return len
end

function CoDHUD_Header_MW:New(cfg)
    local o = setmetatable({}, self)

	o.type = cfg.type or "mw"
	
    o.lines = string.Split(cfg.text or "", "\n")
	-- longest line drives timing
	o.longest = 0
	for _, line in ipairs(o.lines) do
		o.longest = math.max(o.longest, SafeLen(line))
	end
	
    o.subtext    = cfg.subtext or nil
    o.icon       = cfg.icon or nil

    o.color      = cfg.color or Color(255,255,255)
    o.subcolor   = cfg.subcolor or Color(255,255,255)

	o.subAlpha = 0
	o.alpha = 0
	o.fadeSpeed = cfg.fadeSpeed or 400

    o.x          = cfg.x or 960
    o.y          = cfg.y or 205

    o.fonts      = cfg.fonts or {
		pri = "MW2_RE_Sc_Pri",
		sec = "MW2_RE_Sc_Sec",
		shd = "MW2_RE_Sc_Shd"
	}

    o.writeSpeed = cfg.writeSpeed or 16
    o.holdTime   = cfg.holdTime or 2
    o.eraseTime  = cfg.eraseTime or 0.7

    o.phase      = "write"
    o.startTime  = CurTime()

    o.written    = 0
    o.nextWrite  = CurTime()

    o.eraseBlanks = {}
    o.nextErase   = 0
	o.eraseSoundPlayed = nil
	o.fadeOutStart = nil
	o.skipErase = cfg.skipErase or false
	o.multiple = cfg.multiple or false
	o.persist = cfg.persist or false
	o.align = cfg.align or "center"

	o.writeSounds = cfg.writeSounds or {
		"hud/cod_write.mp3"
	}

	if cfg.endTime then
		o.endTime = CurTime() + cfg.endTime
	else
		o.endTime = nil
	end

	o.iconPos   = cfg.iconPos or "below" -- "above" | "below"
	
	o.iconX		= cfg.iconX or cfg.x
	o.iconY		= cfg.iconY or cfg.y
	o.iconSize  = cfg.iconSize or 128
	o.iconGap   = cfg.iconGap or 16
    o.iconAlpha   = 0
	o.iconFadeInSpeed = cfg.iconFadeInSpeed or 400
	o.iconFadeOutSpeed = cfg.iconFadeOutSpeed or 400
	
	o.teams = cfg.teams or nil
	o.scoreY = cfg.scoreY or (cfg.y + 100)

	o.challengeDesc   = cfg.challengeDesc or nil
	o.challengePoints = cfg.challengePoints or nil
	o.isSpecial       = cfg.isSpecial or false
	o.scale = 1

	if o.type == "bo_challenge" then
		o.holdTime = cfg.holdTime or 1.25

		o.fadeInTime   = 0.2
		o.exitDuration = 0.125
		o.fadeOutStart = o.holdTime - o.exitDuration
	end

    return o
end

function CoDHUD_HeaderQueue.Push(cfg)
	cfg.groupId = cfg.groupId or (CurTime() .. "_" .. math.random(9999))

    table.insert(CoDHUD_HeaderQueue.Queue, cfg)
end

-- =========================
-- Helpers
-- =========================
local function utf8_sub(str, startChar, endChar)
    local ok, result = pcall(function()
        local chars = {}
        local i = 1

        for _, c in utf8.codes(str) do
            chars[i] = utf8.char(c)
            i = i + 1
        end

        endChar = endChar or #chars

        local out = {}
        for i = startChar, math.min(endChar, #chars) do
            out[#out+1] = chars[i]
        end

        return table.concat(out)
    end)

    if not ok then
        return string.sub(str, startChar, endChar)
    end

    return result
end

local function BlankStep(blanks, text, n)
    local len = SafeLen(text)
    local avail = {}

    for i = 1, len do
        local used = false
        for _, b in ipairs(blanks) do
            if b == i then used = true break end
        end
        if not used then table.insert(avail, i) end
    end

    for i = 1, math.min(n, #avail) do
        local idx = math.random(#avail)
        table.insert(blanks, avail[idx])
        table.remove(avail, idx)
    end
end

local function ApplyBlanks(text, blanks)
    local len = SafeLen(text)
    local chars = {}

    for i = 1, len do
        chars[i] = utf8_sub(text, i, i)
    end

    for _, b in ipairs(blanks) do
        if chars[b] then chars[b] = " " end
    end

    return table.concat(chars)
end

local function DrawCODText(text, fullText, pri, sec, shd, x, y, glow, align)
    surface.SetFont(pri)
    local fullW = surface.GetTextSize(fullText)

    local startX

	if align == "right" then
		startX = x - fullW
	elseif align == "left" then
		startX = x
	else
		startX = x - fullW / 2
	end

	draw.SimpleText(text, sec, startX + 4, y + 0, glow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, sec, startX - 4, y - 0, glow, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, shd, startX + 2, y + 1, Color(0,0,0,glow.a or 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	draw.SimpleText(text, pri, startX, y, Color(255,255,255,glow.a or 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
end

local function BuildBOText(realText, revealed)
    local len = SafeLen(realText)
    local out = {}

    for i = 1, len do
        if i <= revealed then
            out[#out + 1] = utf8_sub(realText, i, i)
        else
            out[#out + 1] = BO_SCRAMBLE[math.random(#BO_SCRAMBLE)]
        end
    end

    return table.concat(out)
end

local RE_MATS = {}
local function GetSpawnMat(id)
    if RE_MATS[id] then return RE_MATS[id] end
    if not CoDHUD.Factions[CoDHUD_GetHUDType()] or not CoDHUD.Factions[CoDHUD_GetHUDType()][id] then return nil end
    RE_MATS[id] = Material(CoDHUD.Factions[CoDHUD_GetHUDType()][id].spawnIcon, "smooth")
    return RE_MATS[id]
end

local function GetSafeColor(col)
    if not col then return Color(255, 255, 255, 255) end
    return Color(col.r or 255, col.g or 255, col.b or 255, col.a or 255)
end

-- =========================
-- Update
-- =========================
function CoDHUD_Header_MW:Update()
    local now = CurTime()

    local speed = self.iconFadeInSpeed or 400

	-- BLACK OPS CHALLENGE
	if self.type == "bo_challenge" then
		local age = CurTime() - self.startTime

		local fadeIn  = self.fadeInTime or 0.2
		local fadeOut = self.fadeOutStart or 1
		local exitDur = self.exitDuration or 0.125

		if age < fadeIn then
			local p = age / fadeIn

			self.alpha = p * 255
			self.scale = Lerp(p, 0.0, 1.1)

		elseif age > fadeOut then
			local p = (age - fadeOut) / exitDur

			self.alpha = math.Clamp((1 - p) * 255, 0, 255)
			self.scale = Lerp(p, 1.0, 0.0)
		else
			self.alpha = 255
			self.scale = 1
		end

		self.iconAlpha = self.alpha
		self.subAlpha  = self.alpha

		if age >= self.holdTime then
			self.phase = "done"
		end

		return
	end

    -- WRITE
	if self.phase == "write" then

		-- WORLD AT WAR / BLACK OPS
		if self.type == "waw" or self.type == "bo" then

			local interval = 1 / self.writeSpeed

			self.iconAlpha = math.min(255, self.iconAlpha + FrameTime() * speed)
			self.subAlpha  = math.min(255, self.subAlpha  + FrameTime() * speed)
			self.alpha     = self.type == "waw" and math.min(255, self.alpha + FrameTime() * self.fadeSpeed) or 255

			-- play one sound per character
			if now >= self.nextWrite and self.written < self.longest then
				self.written = self.written + 1
				self.nextWrite = now + interval

				local snd = self.writeSounds[math.random(#self.writeSounds)]
				surface.PlaySound(snd)
			end

			local finished = self.written >= self.longest

			if self.type == "waw" then
				finished = finished and self.alpha >= 255
			end

			if finished then
				self.phase = "hold"
				self.holdStart = now
			end

		-- MODERN WARFARE
		else
			local interval = 1 / self.writeSpeed

			self.iconAlpha = math.min(255, self.iconAlpha + FrameTime() * speed)
			self.subAlpha  = math.min(255, self.subAlpha  + FrameTime() * speed)

			if now >= self.nextWrite and self.written < self.longest then
				self.written = self.written + 1
				self.nextWrite = now + interval
				
				local snd = self.writeSounds[math.random(#self.writeSounds)]
				surface.PlaySound(snd)
			end

			if self.written >= self.longest then
				self.phase = "hold"
				self.holdStart = now
			end
		end
	end

    -- HOLD
	if self.phase == "hold" then
	
		self.iconAlpha = math.min(255, self.iconAlpha + FrameTime() * speed)
		self.subAlpha  = math.min(255, self.subAlpha  + FrameTime() * speed)
		
		if self.persist then
			if self.endTime and CurTime() >= self.endTime then
				self.phase = "done"
				self.iconAlpha = 0
				self.subAlpha = 0
				return
			end
			return
		end

		if now >= self.holdStart + self.holdTime then
			self.phase = "erase"
			self.nextErase = now
		end
	end

	-- ERASE
	if self.phase == "erase" then

		-- WORLD AT WAR / BLACK OPS
		if self.type == "waw" or self.type == "bo" then

			self.iconAlpha = math.max(0, self.iconAlpha - FrameTime() * self.iconFadeOutSpeed)
			self.subAlpha  = math.max(0, self.subAlpha  - FrameTime() * self.iconFadeOutSpeed)

			-- BO fades smoothly with the icon
			if self.type == "bo" then
				self.alpha = math.max(0, self.alpha - FrameTime() * self.fadeSpeed)

			-- WAW hard-cuts after icon fade
			elseif self.iconAlpha <= 0 then
				self.alpha = 0
			end

			if self.iconAlpha <= 0 and self.subAlpha <= 0 and self.alpha <= 0 then
				self.phase = "done"
			end

			return
		end

		-- MODERN WARFARE
		self.iconAlpha = math.max(0, self.iconAlpha - FrameTime() * self.iconFadeOutSpeed)
		self.subAlpha  = math.max(0, self.subAlpha  - FrameTime() * self.iconFadeOutSpeed)

		if self.skipErase then
			self.phase = "done"
			return
		end

		local step = self.eraseTime / math.max(1, math.ceil(self.longest / 2))

		if now >= self.nextErase then
			self.nextErase = now + step
			BlankStep(self.eraseBlanks, string.rep(" ", self.longest), 2)

			if not self.eraseSoundPlayed then
				surface.PlaySound("hud/cod_dissapear.mp3")
				self.eraseSoundPlayed = true
			end
		end

		if (#self.eraseBlanks >= self.longest) and (self.iconAlpha == 0) and (self.subAlpha == 0) then
			self.phase = "done"
		end

		if not self.fadeOutStart then
			self.fadeOutStart = now
		end
	end
end

-- =========================
-- Draw
-- =========================
function CoDHUD_Header_MW:Draw()
    if self.phase == "done" then return end
	
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

	if self.type == "bo_challenge" then
		local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

		local cx = self.x
		local cy = self.y

		local alpha = self.alpha or 255
		local scale = self.scale or 1

		local colWhite      = Color(255,255,255,alpha)
		local colBlack      = Color(0,0,0,alpha * 0.8)
		local colYellow     = Color(255,255,50,alpha)
		local colRedGlow    = Color(195,110,115,alpha * 0.5)

		local bgmat = Material(CoDHUD_GetHUDType() .. "/icons/hud_medal_burst.png", "smooth")
		local iconmat = Material(CoDHUD_GetHUDType() .. "/icons/menu_mp_lobby_aar_award_challenge.png", "smooth")

		local bgSize = CoDHUD_S(360)
		local iconSize = CoDHUD_S(240)

		local mat = Matrix()
		mat:Translate(Vector(cx, cy, 0))
		mat:Scale(Vector(scale, scale, 1))
		mat:Translate(Vector(-cx, -cy, 0))

		cam.PushModelMatrix(mat)

			-- BACKING
			surface.SetDrawColor(255,255,255,math.Clamp(alpha,0,125))
			surface.SetMaterial(bgmat)
			surface.DrawTexturedRect( cx - bgSize, cy - (bgSize * 0.5), bgSize * 2, bgSize )

			surface.SetDrawColor(255,255,255,math.Clamp(alpha,0,175))
			surface.SetMaterial(iconmat)
			surface.DrawTexturedRect( cx - (iconSize * 0.5), cy - (iconSize * 0.5), iconSize, iconSize )

			-- HEADER TEXT
			for i, line in ipairs(self.lines) do
				draw.SimpleTextOutlined( line, self.fonts.pri, cx, cy - CoDHUD_S(20) + ((i - 1) * CoDHUD_S(34)), colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, outlined and 1.5 or 0, colBlack )
			end

			-- SUBTEXT / DESC
			if self.subtext and self.subtext ~= "" then
				local col = Color(self.subcolor.r, self.subcolor.g, self.subcolor.b, self.subAlpha)
				local lines = string.Split(self.subtext, "\n")

				local align = self.align or "center"

				for i, line in ipairs(lines) do
					local y = cy + CoDHUD_S(5) + (i - 1) * CoDHUD_S(32)

					draw.SimpleTextOutlined( line, self.fonts.sub, cx, y, colWhite, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,col.a) )
				end
			end

			-- ICON
			if self.icon then
				local size = self.iconSize or 96

				surface.SetMaterial(self.icon)
				surface.SetDrawColor(255,255,255,alpha)

				surface.DrawTexturedRect( cx - (size / 2), cy - CoDHUD_S(120), size, size )
			end

		cam.PopModelMatrix()

		return
	end

	for i, line in ipairs(self.lines) do
		local display = ""

		if self.type == "waw" then
			display = line

		elseif self.type == "bo" then
			display = BuildBOText(line, self.written)

		elseif self.phase == "write" then
			display = utf8_sub(line, 0, self.written)

			local lineLen = SafeLen(line)

			if self.written < lineLen then
				display = display .. GLITCH[math.random(#GLITCH)]
			end

		elseif self.phase == "erase" then
			if self.type == "waw" then
				display = ""
			else
				local padded = line .. string.rep(" ", math.max(0, self.longest - SafeLen(line)))
				display = ApplyBlanks(padded, self.eraseBlanks)
			end
		else
			display = line
		end

		if display ~= "" then
			local y = self.y + ((i - 1) * CoDHUD_S(38))

			local useAlpha = (self.type == "waw" or self.type == "bo")

			local drawCol = Color( self.color.r, self.color.g, self.color.b, useAlpha and self.alpha or 255 )

			DrawCODText( display, line, self.fonts.pri, self.fonts.sec, self.fonts.shd, self.x, y, drawCol, self.align )
		end
	end

    -- SUBTEXT
	if self.subtext and self.subtext ~= "" and self.subAlpha > 0 then
		local col = Color(self.subcolor.r, self.subcolor.g, self.subcolor.b, self.subAlpha)
		local lines = string.Split(self.subtext, "\n")

		local align = self.align or "center"

		for i, line in ipairs(lines) do
			local y = self.y + CoDHUD_S(25) + (i - 1) * CoDHUD_S(24)

			draw.SimpleTextOutlined( line, self.fonts.sub, self.x, y, col, align == "right" and TEXT_ALIGN_RIGHT or align == "left" and TEXT_ALIGN_LEFT or TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP, outlined and 1 or 0, Color(0,0,0,col.a) )
		end
	end

    -- ICON
	if self.icon then
		local size = self.iconSize
		local yOffset = 999

		surface.SetFont(self.fonts.pri)
		local _, textH = surface.GetTextSize(self.lines[1] or "")
		textH = textH * #self.lines

		local padding = 10
		local size = self.iconSize

		local yOffset

		if self.iconPos == "above" then
			yOffset = -(textH * 0.5) - size - self.iconGap - padding
		else
			yOffset = (textH * 0.5) + self.iconGap + padding
		end

		surface.SetMaterial(self.icon)
		surface.SetDrawColor(255,255,255,self.iconAlpha)
		surface.DrawTexturedRect(self.iconX - (size/2), self.iconY, size, size)
	end
	
	-- TEAMS
	if self.teams then
		local count = #self.teams
		if count <= 0 then return end

		local lp = LocalPlayer()
		local localFac = lp:GetNW2String("CoDHUD_Faction", "rangers")

		local size = self.iconSize or 128
		local gap  = self.iconGap or 80

		-- 1. DO NOT trust upstream ordering → normalize safely
		local ordered = {}

		for _, t in ipairs(self.teams) do
			table.insert(ordered, t)
		end

		-- local faction always first (stable, non-destructive)
		table.sort(ordered, function(a, b)
			if a.fac == localFac then return true end
			if b.fac == localFac then return false end

			-- fallback: preserve score ordering if present
			return (a.score or 0) > (b.score or 0)
		end)

		-- 2. Stable spacing model (no runaway gaps)
		local step = size + gap

		-- slight compression only when needed (prevents overlap in 3+ teams)
		local compression = 1
		if count == 3 then
			compression = 0.9
		elseif count >= 4 then
			compression = 0.78
		end

		step = step * compression

		local totalW = (count - 1) * step

		-- 3. Render (strict horizontal chain, no drift)
		for i, t in ipairs(ordered) do
			local x = self.x + ((i - 1) * step - totalW / 2)
			local y = self.iconY or self.y

			local mat = GetSpawnMat(t.fac)
			if mat then
				surface.SetMaterial(mat)
				surface.SetDrawColor(255, 255, 255, self.iconAlpha or 255)
				surface.DrawTexturedRect(x - size/2, y, size, size)
			end

			local fd = CoDHUD.Factions[CoDHUD_GetHUDType()] and CoDHUD.Factions[CoDHUD_GetHUDType()][t.fac]

			local score = t.score or 0

			if fd then
				DrawCODText( tostring(score), tostring(score), self.fonts.pri, self.fonts.sec, self.fonts.shd, x, self.scoreY, GetSafeColor(fd.glow) )
			end
		end
	end

end

function CoDHUD_Header_MW:IsDone()
    if self.groupId then
        if CoDHUD_HeaderGroups[self.groupId] then
            return true
        end
    end

    return self.phase == "done"
end

function CoDHUD_HeaderQueue.IsBusy()
    if not CoDHUD_HeaderQueue.Active then return false end

    for _, h in ipairs(CoDHUD_HeaderQueue.Active) do
        if not h:IsDone() then
            return true
        end
    end

    return false
end

function CoDHUD_HeaderQueue.Think()

    -- spawn next queued header if allowed
	if #CoDHUD_HeaderQueue.Queue > 0 then
		local cfg = table.remove(CoDHUD_HeaderQueue.Queue, 1)
		local new = CoDHUD_Header_MW:New(cfg)

		if cfg.multiple then
			table.insert(CoDHUD_HeaderQueue.Active, new)
		else
			-- non-multiple blocks until done
			if #CoDHUD_HeaderQueue.Active == 0 then
				table.insert(CoDHUD_HeaderQueue.Active, new)
			else
				-- requeue if blocked
				table.insert(CoDHUD_HeaderQueue.Queue, 1, cfg)
			end
		end
	end

    -- update all active headers
    for i = #CoDHUD_HeaderQueue.Active, 1, -1 do
        local h = CoDHUD_HeaderQueue.Active[i]

        h:Update()

        if h:IsDone() then
            table.remove(CoDHUD_HeaderQueue.Active, i)
        end
    end
	
	local groups = {}

	for _, h in ipairs(CoDHUD_HeaderQueue.Active) do
		if h.groupId then
			groups[h.groupId] = groups[h.groupId] or {total = 0, done = 0}
			groups[h.groupId].total = groups[h.groupId].total + 1

			if h.phase == "done" then
				groups[h.groupId].done = groups[h.groupId].done + 1
			end
		end
	end

	for id, g in pairs(groups) do
		if g.total > 0 and g.total == g.done then
			CoDHUD_HeaderGroups[id] = true
		end
	end
end

hook.Add("Think", "CoDHUD_HeaderQueueThink", function()
    CoDHUD_HeaderQueue.Think()
end)

local function CoDHUD_ShouldHideHUD()
    if gui.IsGameUIVisible() then return true end
    if gui.IsConsoleVisible() then return true end
    if vgui.CursorVisible() then return true end
    if IsValid(ScoreBoard) then return true end -- fallback safety
    if CoDHUD_ScoreboardOpened then return true end -- fallback safety
    return false
end

hook.Add("DrawOverlay", "CoDHUD_Header_MW_Draw", function()
    if not GetConVar("cl_drawhud"):GetBool() then return end
	
	local hud = CoDHUD[CoDHUD_GetHUDType()]

	if hud and hud.MedalsBlockChallenges and _G.CoDHUD_MedalsActive then
		return
	end

    -- if _G.CoDHUD_MedalSystem and _G.CoDHUD_MedalSystem.IsBusy() then return end
	
    if CoDHUD_ShouldHideHUD() then return end

    if not CoDHUD_HeaderQueue.Active then return end

    for _, h in ipairs(CoDHUD_HeaderQueue.Active) do
        h:Draw()
    end
	
end)