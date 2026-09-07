---- [ CLIENT HITMARKER ] ----

if CLIENT then
    local hitAlpha, hitTime = 0, 0
    local scoreVal, scoreAlpha, scoreTime, scoreStart = 0, 0, 0, 0
    local scoreScale = 1
    local currentPulseAlpha = 255

    local pendingLongshot = false
    local pendingLongshotTime = 0

    _G.CoDHUD_AddScore = function(amount)
        local gmCV = GetConVar("codhud_selected_gamemode")
        print("[AddScore] +" .. tostring(amount) .. " hudType=" .. tostring(CoDHUD_GetHUDType and CoDHUD_GetHUDType()) .. " gm=" .. tostring(gmCV and gmCV:GetString()))
        local ct = CurTime()
        if ct >= scoreTime then
            scoreVal = amount
        else
            scoreVal = scoreVal + amount
        end
        scoreAlpha = 255
        scoreTime  = ct + 1.5
        scoreStart = ct
    end

    _G.CoDHUD_ResetScore = function()
        scoreVal   = 0
        scoreAlpha = 0
        scoreTime  = 0
        scoreStart = 0
    end

    _G.CoDHUD_ForceHitmarker = function()
        hitAlpha = 255
        hitTime  = CurTime() + 1.5
        _G.CoDHUD_KillcamHitmarker = true
    end

    local function IsSeshMode()
        local gm = GetConVar("codhud_selected_gamemode")
        if not gm then return false end
        local s = gm:GetString()
        return s == "sesh_dm" or s == "sesh_war" or s == "sesh_sd" or s == "sesh_sd_set"
    end

    local function GetKillXP()
        local gm      = GetConVar("codhud_selected_gamemode"):GetString()
        local hudType = CoDHUD_GetHUDType()

        if gm == "sesh_war" then gm = "war" end
        if gm == "sesh_dm"  then gm = "dm"  end
        if gm == "sesh_sd" or gm == "sesh_sd_set" then gm = "sd"  end

        -- cod4 and waw use flat XP per kill — no longshot bonus
        local isCodFlat = (hudType == "cod4" or hudType == "waw")
        local isLongshot = (not isCodFlat) and pendingLongshot and (CurTime() - pendingLongshotTime) < 0.5
        pendingLongshot = false

        if hudType == "mw2" or hudType == "mw3" or hudType == "bo1" or hudType == "bo2" then
            if gm == "war" then return isLongshot and 150 or 100
            elseif gm == "dm" then return isLongshot and 100 or 50
            elseif gm == "sd" then return isLongshot and 550 or 500
            else return isLongshot and 150 or 100 end
        elseif hudType == "cod4" then
            if gm == "war" then return 10
            elseif gm == "dm" then return 5
            elseif gm == "sd" then return 50
            else return 10 end
        elseif hudType == "waw" then
            if gm == "war" then return 10
            elseif gm == "dm" then return 5
            elseif gm == "sd" then return 50
            else return 10 end
        else
            return isLongshot and 150 or 100
        end
    end

    local function DoHitmarker(isKill, playSnd)
        hitAlpha = 255
        hitTime  = CurTime() + 1.5
        if playSnd and GetConVar("codhud_enable_hitmarker"):GetBool() and not GetConVar("codhud_quickdisable_hud"):GetBool() then
            LocalPlayer():EmitSound("hud/hitmarker.mp3", 100, 100, 1, CHAN_AUTO)
        end
        if isKill then
            _G.CoDHUD_AddScore(GetKillXP())
        end
    end

    -- Normal modes: base CoDHUD server sends this, handle it here
    -- Sesh modes: sv_hitmarker.lua skips these, KC_HitNotification handles it instead
    net.Receive("CoDHUD_HitNotification", function()
        local isKill = net.ReadBool()
        net.ReadInt(32)
        local sesh = IsSeshMode()
        local gmCV1 = GetConVar("codhud_selected_gamemode")
        print("[HM CLIENT] CoDHUD_HitNotification received isKill=" .. tostring(isKill) .. " isSesh=" .. tostring(sesh) .. " gm=" .. tostring(gmCV1 and gmCV1:GetString()))
        if sesh then return end
        DoHitmarker(isKill, true)
    end)

    -- KC_HitNotification: fires for sesh bot hits, AND for normal mode NPC/player hits during killcam
    net.Receive("KC_HitNotification", function()
        local isKill = net.ReadBool()
        local gmCV2 = GetConVar("codhud_selected_gamemode")
        print("[HM CLIENT] KC_HitNotification received isKill=" .. tostring(isKill) .. " gm=" .. tostring(gmCV2 and gmCV2:GetString()))
        if KC_Playing and KC_Playing() then
            -- During killcam in sesh mode: force hitmarker + XP
            -- Normal mode: KillcamNPCKilled handles the hitmarker, skip here to avoid double flash
            if IsSeshMode() then
                if _G.CoDHUD_ForceHitmarker then _G.CoDHUD_ForceHitmarker() end
                if _G.CoDHUD_AddScore then _G.CoDHUD_AddScore(GetKillXP()) end
            end
        else
            -- Outside killcam: only fire for sesh mode
            if IsSeshMode() then
                DoHitmarker(isKill, true)
            end
        end
    end)

    net.Receive("CoDHUD_Medal_Longshot", function()
        local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
        if hudType == "cod4" or hudType == "waw" then return end
        pendingLongshot = true
        pendingLongshotTime = CurTime()
    end)

    -- Block TFA Base's hitmarker in sesh modes — it fires on every hit
    -- for every player, causing shared hitmarkers and wrong XP.
    -- InitPostEntity fires after ALL addons are done loading on the client.
    hook.Add("InitPostEntity", "CoDHUD_BlockTFAHitmarker", function()
        -- Block TFA's net receiver in sesh modes
        local orig_tfahitmarker = net.Receivers["tfahitmarker"]
        if orig_tfahitmarker then
            net.Receive("tfahitmarker", function(len, ply)
                if IsSeshMode() then return end
                orig_tfahitmarker(len, ply)
            end)
        end

        -- Block TFA's HUDPaint draw in sesh modes
        local orig_tfaDraw = hook.GetTable()["HUDPaint"] and hook.GetTable()["HUDPaint"]["tfaDrawHitmarker"]
        if orig_tfaDraw then
            hook.Add("HUDPaint", "tfaDrawHitmarker", function()
                if IsSeshMode() then return end
                orig_tfaDraw()
            end)
        end

        -- Block steezmodv1b's imHDN_createHitNumber net receiver in sesh modes.
        -- This fires on every hit for every player and registers a new CHitMarker
        -- HUDPaint hook each time, drawing a crosshair hitmarker for all hits.
        local orig_imhdn = net.Receivers["imhdn_createhitnumber"]
        if orig_imhdn then
            net.Receive("imhdn_createhitnumber", function(len, ply)
                if IsSeshMode() then
                    -- Still need to consume the net data or it'll corrupt
                    net.ReadFloat()
                    net.ReadUInt(32)
                    return
                end
                orig_imhdn(len, ply)
            end)
        end

        -- Fix cl_killmedals.lua hardcoded XP values in sesh mode.
        -- Medal receivers call CoDHUD_AddScore(50) hardcoded regardless of gamemode.
        -- Also suppress headshot and longshot bonuses for cod4/waw in ALL modes.
        --
        -- IMPORTANT: net.Receive(name, fn) REPLACES whatever was previously in
        -- net.Receivers[name]. If cl_killmedals.lua registers its receiver
        -- AFTER we wrap it, our wrapper is silently destroyed and the raw
        -- hardcoded XP goes through uncontested. A single retry isn't reliable
        -- because we don't know exactly when cl_killmedals.lua loads relative
        -- to us. So we keep re-wrapping for the first several seconds via
        -- Think, always grabbing whatever is currently in net.Receivers[name]
        -- and wrapping it again — this guarantees we're always the outermost
        -- layer regardless of load order.
        local FLAT_XP_HUDS = { cod4 = true, waw = true }
        -- These medals stay enabled for flat-XP HUDs (cod4/waw) — they still
        -- add their bonus XP on top of the kill XP. Everything else (headshot,
        -- longshot, firstblood, oneshot, comeback, payback) is suppressed.
        local KEEP_BONUS_MEDALS = {
            codhud_medal_doublekill = true,
            codhud_medal_triplekill = true,
            codhud_medal_multikill  = true,
        }
        -- These medals have their score suppressed on ALL HUD types.
        local SUPPRESS_ALL_HUDS = {
            codhud_medal_headshot = true,
        }

        local medalNets = {
            "codhud_medal_headshot",
            "codhud_medal_doublekill",
            "codhud_medal_triplekill",
            "codhud_medal_multikill",
            "codhud_medal_longshot",
            "codhud_medal_oneshot",
            "codhud_medal_firstblood",
            "codhud_medal_comeback",
            "codhud_medal_payback",
        }

        -- Track which function we last wrapped per net name, so we can tell
        -- whether someone re-registered a NEW receiver since our last wrap
        -- (in which case 'orig' inside our closure would be the wrong one).
        local wrappedFn = {}

        local function MakeWrapper(name, orig)
            return function(len, ply)
                local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
                local isFlatHUD = FLAT_XP_HUDS[hudType]

                -- Fully suppress specific medals on ALL HUD types —
                -- no score, no animation, no killfeed entry.
                if SUPPRESS_ALL_HUDS[name] then
                    return
                end

                -- cod4/waw already get full XP from GetKillXP() on every kill
                -- (via KC_HitNotification / CoDHUD_HitNotification). Most medal
                -- bonuses on top of that would be double-counting, so suppress
                -- them — except doublekill/triplekill/multikill, which stay on.
                if isFlatHUD and not KEEP_BONUS_MEDALS[name] then
                    print("[MedalIntercept] SUPPRESSING " .. name .. " for hudType=" .. hudType)
                    local realAddScore = _G.CoDHUD_AddScore
                    _G.CoDHUD_AddScore = function(amt) end
                    orig(len, ply)
                    _G.CoDHUD_AddScore = realAddScore
                    return
                end

                if IsSeshMode() then
                    local realAddScore = _G.CoDHUD_AddScore
                    local seshKillXP = 50
                    print("[MedalIntercept] " .. name .. " sesh substitute -> " .. seshKillXP)
                    _G.CoDHUD_AddScore = function(amt)
                        if realAddScore then realAddScore(seshKillXP) end
                    end
                    orig(len, ply)
                    _G.CoDHUD_AddScore = realAddScore
                    return
                end
                orig(len, ply)
            end
        end

        local function InterceptMedalNets()
            for _, name in ipairs(medalNets) do
                local current = net.Receivers[name]
                -- Only re-wrap if this isn't already OUR wrapper — i.e. someone
                -- else (cl_killmedals.lua re-registering, or a refresh) put a
                -- new function in net.Receivers[name] since we last wrapped it.
                if current and current ~= wrappedFn[name] then
                    local wrapper = MakeWrapper(name, current)
                    wrappedFn[name] = wrapper
                    net.Receive(name, wrapper)
                end
            end
        end

        -- Re-check repeatedly for the first 15 seconds after map load to
        -- catch cl_killmedals.lua however late it registers, then stop.
        InterceptMedalNets()
        local medalInterceptElapsed = 0
        hook.Add("Think", "CoDHUD_MedalInterceptPoll", function()
            medalInterceptElapsed = medalInterceptElapsed + FrameTime()
            InterceptMedalNets()
            if medalInterceptElapsed > 15 then
                hook.Remove("Think", "CoDHUD_MedalInterceptPoll")
            end
        end)

        hook.Remove("InitPostEntity", "CoDHUD_BlockTFAHitmarker")
    end)

    -- [[ HUD PAINT HOOK ]]
    hook.Add("HUDPaint", "CoDHUD_DrawHitmarkerSystem", function()
        local ct = CurTime()

        if _G.CoDHUD_KillcamHitmarker and ct >= hitTime then
            _G.CoDHUD_KillcamHitmarker = false
        end

        local allowDraw = GetConVar("codhud_enable_hitmarker"):GetBool() and
                          (not GetConVar("codhud_quickdisable_hud"):GetBool() or _G.CoDHUD_KillcamHitmarker)
        if ct < hitTime and allowDraw then
            local hudType = CoDHUD_GetHUDType()
            if CoDHUD[hudType] and CoDHUD[hudType].Hitmarker then
                CoDHUD[hudType].Hitmarker(hitTime)
            else
                local sw, sh = ScrW(), ScrH()
                local cx, cy = sw * 0.5, sh * 0.5
                local size, gap = 10, 4
                local alpha = math.Clamp(255 * ((hitTime - ct) / 1.5), 0, 255)
                surface.SetDrawColor(255, 50, 50, alpha)
                surface.DrawLine(cx - gap, cy - gap, cx - gap - size, cy - gap - size)
                surface.DrawLine(cx + gap, cy - gap, cx + gap + size, cy - gap - size)
                surface.DrawLine(cx - gap, cy + gap, cx - gap - size, cy + gap + size)
                surface.DrawLine(cx + gap, cy + gap, cx + gap + size, cy + gap + size)
            end
        end
    end)

    hook.Add("DrawOverlay", "CoDHUD_KillcamHitmarkerOverlay", function()
        if not _G.CoDHUD_KillcamHitmarker then return end
        local ct = CurTime()
        if ct >= hitTime then
            _G.CoDHUD_KillcamHitmarker = false
            return
        end
        local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType()
        if hudType and CoDHUD and CoDHUD[hudType] and CoDHUD[hudType].Hitmarker then
            CoDHUD[hudType].Hitmarker(hitTime)
        end
    end)

    hook.Add("DrawOverlay", "CoDHUD_DrawXPSystem", function()
        local ct = CurTime()
        if ct < scoreTime then
            if GetConVar("codhud_enable_xp"):GetBool() and not GetConVar("codhud_quickdisable_hud"):GetBool() then
                local animTime = ct - scoreStart
                if animTime < 0.1 then
                    local frac = animTime / 0.2
                    scoreScale        = Lerp(frac, 1, 2.7)
                    currentPulseAlpha = Lerp(frac, 255, 120)
                elseif animTime < 0.3 then
                    local frac = (animTime - 0.2) / 0.2
                    scoreScale        = Lerp(frac, 2.7, 1.0)
                    currentPulseAlpha = Lerp(frac, 120, 255)
                else
                    scoreScale        = 1
                    currentPulseAlpha = 255
                end
                local finalAlpha = scoreAlpha
                if scoreTime - ct < 0.3 then
                    scoreAlpha = math.Approach(scoreAlpha, 0, FrameTime() * 800)
                    finalAlpha = scoreAlpha
                end
                if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].XP then
                    CoDHUD[CoDHUD_GetHUDType()].XP(animTime, scoreTime, finalAlpha, scoreScale, currentPulseAlpha, scoreVal)
                end
            end
        else
            scoreVal = 0
        end
    end)
end