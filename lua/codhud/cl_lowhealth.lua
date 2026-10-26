---- [ CLIENT LOW HEALTH AUDIO & VISUALS ] ----

-- Configuration
local flashDuration = 3.1
local overlayFadeDuration = 4.5  -- how long the blood screen takes to fade out after a hit

-- State Variables
local lastHealth = 100
local flashEndTime = 0
local lastHitTime = -math.huge
local lastHitOverlayPeak = 0

-- Materials
local MAT_BLOOD_DEFOCUS = Material("mw2/lowhealth/blood_defocus_color.png")
local MAT_BLOOD_OVERLAY = Material("mw2/lowhealth/blood_overlay_lowhp.png")

hook.Add("HUDPaint", "LowHealth_BloodHUD_Dynamic", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    -- God Mode (sv_godmode.lua): no blood or defocus on screen. Also clear any
    -- leftover state so an old hit can't reappear when God Mode is turned off.
    if ply:GetNWBool("KC_GodMode", false) then
        lastHealth = ply:Health()
        flashEndTime = 0
        lastHitTime = -math.huge
        lastHitOverlayPeak = 0
        return
    end

    local hp = ply:Health()
    local curTime = CurTime()

    -- 1. Damage Detection
    if hp <= 0 then
        flashEndTime = curTime
    elseif hp < lastHealth then
        flashEndTime = curTime + flashDuration
        lastHitTime = curTime
        -- Remember how strong the overlay should be right at this hit, so
        -- it has a peak to fade down from instead of just sitting at it.
        lastHitOverlayPeak = math.Clamp((100 - hp) * (255 / 90), 0, 255)
    end
    lastHealth = hp

    -----------------------------------------
    -- 2. DEFOCUS CALCULATION (The one you wanted fixed)
    -----------------------------------------
    -- This creates the "Passive" alpha that scales with health (0 at 100hp, 200 at 10hp)
    local passiveDefocus = math.Clamp((100 - hp) * (200 / 90), 0, 200)

    local finalDefocusAlpha = passiveDefocus

    -- If we are in the 1-second damage window, Lerp from 255 down to the passive value
    if curTime < flashEndTime then
        local fraction = (flashEndTime - curTime) / flashDuration
        finalDefocusAlpha = Lerp(fraction, passiveDefocus, 255)
    end

    -----------------------------------------
    -- 3. OVERLAY CALCULATION
    -----------------------------------------
    -- Was previously a static function of current health, so a single hit
    -- that dropped your HP left the blood overlay stuck on screen at that
    -- level forever (until death, since nothing without regen ever raised
    -- HP back up). Now it fades out over overlayFadeDuration seconds after
    -- the last hit instead, re-peaking on every new hit.
    local finalOverlayAlpha = 0
    local sinceHit = curTime - lastHitTime
    if sinceHit < overlayFadeDuration then
        finalOverlayAlpha = lastHitOverlayPeak * (1 - (sinceHit / overlayFadeDuration))
    end

    -----------------------------------------
    -- 4. DRAWING
    -----------------------------------------
    -- Draw Defocus
    if finalDefocusAlpha > 0 then
        surface.SetDrawColor(255, 255, 255, finalDefocusAlpha)
        surface.SetMaterial(MAT_BLOOD_DEFOCUS)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end

    -- Draw Overlay
    if finalOverlayAlpha > 0 then
        surface.SetDrawColor(255, 255, 255, finalOverlayAlpha)
        surface.SetMaterial(MAT_BLOOD_OVERLAY)
        surface.DrawTexturedRect(0, 0, ScrW(), ScrH())
    end
end)

-- doody
local health_threshold = CreateConVar("lowhealtheffect_health", "30", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "health threshold for low health effect")
local time_limit = CreateConVar("lowhealtheffect_time", "10", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "seconds before stopping sounds if health doesn't recover")
local breathing_gender = CreateConVar("lowhealtheffect_gender", "male", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "breathing sound gender")
local enable_heartbeat = CreateConVar("lowhealtheffect_heartbeat", "1", {FCVAR_ARCHIVE, FCVAR_USERINFO}, "enable heartbeat sound")

local breath_male = {
    "lowhealth/male_hurt1.wav",
    "lowhealth/male_hurt2.wav",
    "lowhealth/male_hurt3.wav",
    "lowhealth/male_hurt4.wav",
    "lowhealth/male_hurt5.wav",
    "lowhealth/male_hurt6.wav",
    "lowhealth/male_hurt7.wav"
}

local recover_male = {
    "lowhealth/male_recover1.wav",
    "lowhealth/male_recover2.wav",
    "lowhealth/male_recover3.wav"
}

local heartbeat_sound = "lowhealth/heartbeat.wav"

local last_breath_sound = nil
local last_heartbeat_sound = nil
local playing = false
local health_dropped_time = 0
local low_health = false
local waiting_for_recover = false
local recovering = false
local queued_recover_timer = nil
local breathing_paused_for_water = false
local recover_deferred_for_water = false

local function PlaySoundFile(path, channel)
    if not path then return end
    LocalPlayer():EmitSound(path, 75, 100, 1, channel or CHAN_AUTO)
end

local function StopSoundFile(path)
    if not path then return end
    LocalPlayer():StopSound(path)
end

local function PlayRandom(tbl)
    if not tbl or #tbl == 0 then return end
    local path = tbl[math.random(#tbl)]
    PlaySoundFile(path)
    return path
end

-- Stops any breathing/heartbeat that is playing and forgets all low-health
-- audio state. Used while God Mode is on (sv_godmode.lua), so nothing keeps
-- playing and no "recover" breath fires when God Mode is turned off.
local function ResetLowHealthAudio()
    playing = false
    health_dropped_time = 0
    low_health = false
    waiting_for_recover = false
    recovering = false
    breathing_paused_for_water = false
    recover_deferred_for_water = false
    if last_breath_sound then StopSoundFile(last_breath_sound) last_breath_sound = nil end
    if last_heartbeat_sound then StopSoundFile(last_heartbeat_sound) last_heartbeat_sound = nil end
    if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end
    if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end
    if queued_recover_timer then timer.Remove(queued_recover_timer) queued_recover_timer = nil end
end

hook.Add("Think", "LowHealthEffect_Think", function()
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then
        -- player is DEAD
        if playing or waiting_for_recover or recovering then
            playing = false
            health_dropped_time = 0
            low_health = false
            waiting_for_recover = false
            recovering = false
            breathing_paused_for_water = false
            recover_deferred_for_water = false
            if last_breath_sound then StopSoundFile(last_breath_sound) end
            if last_heartbeat_sound then StopSoundFile(last_heartbeat_sound) end
            if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end
            if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end
            if queued_recover_timer then timer.Remove(queued_recover_timer) queued_recover_timer = nil end
        end
        return
    end

    -- God Mode: no low-health breathing, heartbeat or recovery sounds.
    if ply:GetNWBool("KC_GodMode", false) then
        ResetLowHealthAudio()
        return
    end

    local hp = ply:Health()
    local threshold = health_threshold:GetInt()
    local in_water = ply:WaterLevel() >= 3

    if in_water and not breathing_paused_for_water then
        breathing_paused_for_water = true
        if last_breath_sound then StopSoundFile(last_breath_sound) end
        if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end

        if queued_recover_timer then
            timer.Remove(queued_recover_timer)
            queued_recover_timer = nil
            recover_deferred_for_water = true
        end

        if low_health and not waiting_for_recover and not recovering and not timer.Exists("LowHealthEffect_HeartbeatTimer") then
            timer.Create("LowHealthEffect_HeartbeatTimer", 1.5, 0, function()
                local ply = LocalPlayer()
                if not IsValid(ply) or not ply:Alive() or ply:WaterLevel() < 3 or ply:Health() > threshold or waiting_for_recover or recovering then
                    timer.Remove("LowHealthEffect_HeartbeatTimer")
                    return
                end
                if enable_heartbeat:GetBool() then
                    last_heartbeat_sound = heartbeat_sound
                    PlaySoundFile(heartbeat_sound)
                end
            end)
        end
    elseif not in_water and breathing_paused_for_water then
        breathing_paused_for_water = false
        if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end

        if recover_deferred_for_water then
            recover_deferred_for_water = false
            local wait = 1.5
            recovering = true
            waiting_for_recover = true
            queued_recover_timer = "LowHealthEffect_Recovery_" .. tostring(math.random(1000000,9999999))
            timer.Create(queued_recover_timer, wait, 1, function()
                if not waiting_for_recover then return end
                local gender = breathing_gender:GetString()
                local recover_tbl = (gender == "female") and recover_female or recover_male
                PlayRandom(recover_tbl)
                waiting_for_recover = false
                recovering = false
                queued_recover_timer = nil
            end)
        elseif low_health and not waiting_for_recover and not recovering and (playing == false or not timer.Exists("LowHealthEffect_Timer")) then
            playing = true
            timer.Create("LowHealthEffect_Timer", 1.5, 0, function()
                local ply = LocalPlayer()
                if not IsValid(ply) or not ply:Alive() or ply:Health() > threshold
                    or (health_dropped_time > 0 and (CurTime() - health_dropped_time > time_limit:GetFloat()))
                    or ply:WaterLevel() >= 3 then
                    timer.Remove("LowHealthEffect_Timer")
                    return
                end
                local gender = breathing_gender:GetString()
                local breath_tbl = (gender == "female") and breath_female or breath_male
                last_breath_sound = PlayRandom(breath_tbl)
                if enable_heartbeat:GetBool() then
                    last_heartbeat_sound = heartbeat_sound
                    PlaySoundFile(heartbeat_sound)
                end
            end)
        end
    end

    if hp > 0 and hp <= threshold then
        if not low_health then
            low_health = true
            health_dropped_time = CurTime()
            playing = false
            waiting_for_recover = false
            recovering = false
        end
    else
        if low_health then
            low_health = false
            playing = false
            health_dropped_time = 0
            waiting_for_recover = true
            recovering = true
            local wait = 1.5

            if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end
            if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end
            if queued_recover_timer then timer.Remove(queued_recover_timer) end

            if breathing_paused_for_water then
                recover_deferred_for_water = true
            else
                queued_recover_timer = "LowHealthEffect_Recovery_" .. tostring(math.random(1000000,9999999))
                timer.Create(queued_recover_timer, wait, 1, function()
                    if not waiting_for_recover then return end
                    local gender = breathing_gender:GetString()
                    local recover_tbl = (gender == "female") and recover_female or recover_male
                    PlayRandom(recover_tbl)
                    waiting_for_recover = false
                    recovering = false
                    queued_recover_timer = nil
                end)
            end
        end

        if last_heartbeat_sound then StopSoundFile(last_heartbeat_sound) end
        return
    end

    if waiting_for_recover or recovering then return end

    if health_dropped_time > 0 and (CurTime() - health_dropped_time > time_limit:GetFloat()) then
        if playing then
            playing = false
            if last_breath_sound then StopSoundFile(last_breath_sound) end
            if last_heartbeat_sound then StopSoundFile(last_heartbeat_sound) end
            if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end
            if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end
        end
        return
    end

    if breathing_paused_for_water then return end

    if not playing or not timer.Exists("LowHealthEffect_Timer") then
        playing = true
        timer.Create("LowHealthEffect_Timer", 1.5, 0, function()
            local ply = LocalPlayer()
            if not IsValid(ply) or not ply:Alive() or ply:Health() > threshold
                or (health_dropped_time > 0 and (CurTime() - health_dropped_time > time_limit:GetFloat()))
                or ply:WaterLevel() >= 3 then
                timer.Remove("LowHealthEffect_Timer")
                return
            end
            local gender = breathing_gender:GetString()
            local breath_tbl = (gender == "female") and breath_female or breath_male
            last_breath_sound = PlayRandom(breath_tbl)
            if enable_heartbeat:GetBool() then
                last_heartbeat_sound = heartbeat_sound
                PlaySoundFile(heartbeat_sound)
            end
        end)
    end
end)

hook.Add("ShutDown", "LowHealthEffect_Cleanup", function()
    if timer.Exists("LowHealthEffect_Timer") then timer.Remove("LowHealthEffect_Timer") end
    if timer.Exists("LowHealthEffect_HeartbeatTimer") then timer.Remove("LowHealthEffect_HeartbeatTimer") end
    if queued_recover_timer then timer.Remove(queued_recover_timer) queued_recover_timer = nil end
    if last_breath_sound then StopSoundFile(last_breath_sound) end
    if last_heartbeat_sound then StopSoundFile(last_heartbeat_sound) end
end)