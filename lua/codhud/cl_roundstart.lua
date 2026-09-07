---- [ CLIENT ROUND START ] ----

local CFG = {
    HEADER_X         = 960,
    HEADER_Y         = 150,
    HEADER_WRITE     = 2.1,
    HEADER_ERASE     = 0.7,

    ICON_X    = 896,
    ICON_Y    = 180,
    ICON_SIZE = 134,
    ICON_FADE = 1.0,

    TIMER_X          = 960,
    TIMER_Y          = 540,
    STATIC_Y_OFFSET  = -85,

    OBJ_X         = 960,
    OBJ_Y         = 205,
    OBJ_WRITE     = 2.1,
    OBJ_HANG      = 3.0,
    OBJ_ERASE     = 0.7,
}

local OBJ_GLOW           = Color(0, 220, 80)
local COUNTDOWN_DURATION = 5

local rs_active      = false
local rs_movement_locked = false
local rs_phase       = "idle"
local rs_seq_start   = 0
local rs_phase_start = 0

local rs_short      = ""
local rs_glow       = Color(255, 255, 255)
local rs_icon_mat   = nil
local rs_icon_alpha = 0

local rs_remaining = 0
local rs_last_dig  = -1
local rs_dig_scale = 1.0

local rs_bw         = 0
local rs_boost_done = false
local rs_locked_ang = nil
local rs_gamemode	= "war"

local rs_header = nil
local rs_objective = nil

-- Pending round start data (stored while killcam is active, played after)
local rs_pending_gamemode  = nil
local rs_pending_timestart = nil

CoDHUD_RoundEndTime = 0
CoDHUD_MatchMaxTime = 0

local sb_open = false

hook.Add("ScoreboardShow", "CoDHUD_RS_SBShow", function() sb_open = true  end)
hook.Add("ScoreboardHide", "CoDHUD_RS_SBHide", function() sb_open = false end)

local function DrawSqueezedText(text, font, x, y, color, squeeze, squeezeOne, align, squeezeOneBefore, outlineW)
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
        local outlineCol = Color(0, 0, 0, color.a)

		draw.SimpleTextOutlined( char, font, runX, y, color, 0, 1, o, outlineCol )

        local w = surface.GetTextSize(char)
        if i < #str then
            local gap = (char == "1") and squeezeOne or (nextChar == "1" and squeezeOneBefore or squeeze)
            runX = runX + w + gap
        end
    end
end

local function CoDHUD_RS_Start(gamemode, timestart)
    local lp = LocalPlayer()
    if not IsValid(lp) then return end

    local hudType  = CoDHUD_GetHUDType()
    local factions = CoDHUD.Factions[hudType]
    if not factions then return end

    -- Use the player's actual faction. Fall back to the first faction in the
    -- table only if the player's faction isn't registered for this HUD type.
    local fkey = lp:GetNW2String("CoDHUD_Faction", "")
    if fkey == "" or not factions[fkey] then
        -- Try FACTION_SIDES friendly list first so we never land on an enemy faction
        local sides = FACTION_SIDES and FACTION_SIDES[hudType]
        if sides then
            for _, f in ipairs(sides.friendly) do
                if factions[f] then fkey = f break end
            end
        end
        -- Final fallback: any faction in the table
        if fkey == "" or not factions[fkey] then
            for k, _ in pairs(factions) do fkey = k break end
        end
    end
    local fdata = factions[fkey]
    if not fdata then return end

	local matchtimestart = timestart

	if _G.CoDHUD_MedalSystem then _G.CoDHUD_MedalSystem.Clear() end

	-- prevent suspense music from interfering with spawn theme
	timer.Remove("CoDHUD_SuspenseTimer")

    rs_active      = true
    rs_movement_locked = true
    rs_phase       = "faction"
    rs_seq_start   = CurTime()
    rs_phase_start = CurTime()
    rs_boost_done  = false
	rs_gamemode    = gamemode

    -- Lock and explicitly reset angle pitch/roll upon respawn
    rs_locked_ang = lp:EyeAngles()
    rs_locked_ang.p = 0
    rs_locked_ang.r = 0

    rs_short      = fdata.spawntheme
    rs_glow       = fdata.glow
    rs_icon_mat   = Material(fdata.spawnIcon, "smooth")
    rs_icon_alpha = 0

    rs_remaining = matchtimestart
    rs_last_dig  = -1
    rs_dig_scale = 1.0

    rs_bw = 1

	if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].RoundStart then
		CoDHUD[CoDHUD_GetHUDType()].RoundStart(fdata.name, rs_glow, rs_icon_mat)
	end

	timer.Simple( 0.1, function()
		if GetConVar("codhud_enable_music"):GetBool() and fdata.spawntheme then
			CoDHUD_PlayAnnouncerSound( "music/" .. CoDHUD_GetHUDType() .. "/" .. fdata.spawntheme, true, nil, true )
		end
		
		local sound = CoDHUD_GetAnnouncerSound({ CoDHUD.Gamemodes[CoDHUD_GetHUDType()].Callouts[gamemode] or "team_deathmtch" })
		if sound then CoDHUD_PlayAnnouncerSound(sound, false) end
	end)
end

local function CoDHUD_RS_End()
    rs_active     = false
    rs_movement_locked = false
    rs_phase      = "idle"
    rs_locked_ang = nil
end

-- When killcam ends, play any pending round start that was suppressed
hook.Add("KillcamReplayStopped", "CoDHUD_RS_FlushPending", function()
    if rs_pending_gamemode then
        local gm = rs_pending_gamemode
        local ts = rs_pending_timestart
        rs_pending_gamemode  = nil
        rs_pending_timestart = nil
        timer.Simple(0.5, function()
            CoDHUD_RS_Start(gm, ts)
        end)
    end
end)

hook.Add("Think", "CoDHUD_RS_Think", function()
    if not rs_active then return end

    local now = CurTime()

	if rs_header then
		rs_header:Update()
	end

	if rs_objective then
		rs_objective:Update()
	end

    if rs_phase == "faction" then
		local elapsed = now - rs_seq_start
		local exact_time_left = math.max(0, rs_remaining - elapsed)

        if exact_time_left > 3 then
            rs_bw = 1
        elseif exact_time_left > 0 then
            rs_bw = exact_time_left / 3
        else
            rs_bw = 0
        end

        if exact_time_left <= 0 then
            rs_phase       = "erase_faction"
            rs_phase_start = now
            rs_movement_locked = false
        end

    elseif rs_phase == "erase_faction" then
        local erase_t = math.max(0.01, CFG.HEADER_ERASE)
        local elapsed = now - rs_phase_start

        if not rs_boost_done then
            rs_boost_done = true
			timer.Simple( 0.1, function()
				local sound = CoDHUD_GetAnnouncerSound({ CoDHUD.Gamemodes[CoDHUD_GetHUDType()].Boosts[rs_gamemode] or CoDHUD.Gamemodes[CoDHUD_GetHUDType()].Boosts["war"] })
				if sound then CoDHUD_PlayAnnouncerSound(sound, false) end
			end)
        end

        if elapsed >= erase_t then
            rs_phase       = "objective"
            rs_phase_start = now

			if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].ChallengeComplete then
				CoDHUD[CoDHUD_GetHUDType()].RoundStartObjective(CoDHUD.Gamemodes[CoDHUD_GetHUDType()].Hints[rs_gamemode] or CoDHUD.Gamemodes[CoDHUD_GetHUDType()].Hints["war"])
			end
        end

	elseif rs_phase == "objective" then
		if rs_objective and rs_objective:IsDone() then
			CoDHUD_RS_End()
		end
	end
end)

hook.Add("HUDPaint", "CoDHUD_RS_Draw", function()
    if not rs_active then return end
    if sb_open then return end
    if not IsValid(LocalPlayer()) then return end
    -- Don't draw countdown during killcam
    if KC_Playing and KC_Playing() then return end
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()

    if rs_phase == "faction" then
        local elapsed = CurTime() - rs_seq_start
		local disp = math.max(0, math.ceil(rs_remaining - elapsed))

		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].RoundStartTimer then
			CoDHUD[CoDHUD_GetHUDType()].RoundStartTimer(disp)
		end
    end
end)

hook.Add("RenderScreenspaceEffects", "CoDHUD_RS_BW", function()
    if not rs_active then return end
    if sb_open then return end
    -- Don't apply BW during killcam (killcam has its own color effect)
    if KC_Playing and KC_Playing() then return end
    if rs_bw <= 0 then return end

    DrawColorModify({
        ["$pp_colour_addr"]       = 0,
        ["$pp_colour_addg"]       = 0,
        ["$pp_colour_addb"]       = 0,
        ["$pp_colour_brightness"] = 0,
        ["$pp_colour_contrast"]   = 1,
        ["$pp_colour_colour"]     = 1 - rs_bw,
        ["$pp_colour_mulr"]       = 0,
        ["$pp_colour_mulg"]       = 0,
        ["$pp_colour_mulb"]       = 0,
    })
end)

net.Receive("CoDHUD_RoundStart", function()
    local gamemode  = net.ReadString()
    local timestart = net.ReadInt(6)
    local maxtimer  = net.ReadInt(32)

    CoDHUD_RoundEndTime = net.ReadFloat()

	if maxtimer > 0 then
		CoDHUD_MatchMaxTime = maxtimer * 60
	end

    timer.Simple(0, function()
        -- If killcam is playing, store the round start for after killcam ends
        if KC_Playing and KC_Playing() then
            rs_pending_gamemode  = gamemode
            rs_pending_timestart = timestart
            return
        end
        CoDHUD_RS_Start(gamemode, timestart)
    end)
end)

net.Receive("CoDHUD_SyncFactionPool", function()
    CoDHUD.Factions.ActivePool = net.ReadTable()
end)