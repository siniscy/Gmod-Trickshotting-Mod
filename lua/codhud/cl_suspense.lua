---- [ CLIENT AMBIANCE / SUSPENSE MUSIC ] ----

local MIN_DELAY = 15
local MAX_DELAY = 20

local cvar_enabled = CreateClientConVar("codhud_enable_suspense", "1", true, false)

local function CoDHUD_PlaySuspenseSting()
    if not cvar_enabled:GetBool() then return end

    if not CoDHUD[CoDHUD_GetHUDType()] 
        or not CoDHUD[CoDHUD_GetHUDType()].SuspenseTracks then return end

    local track = table.Random(CoDHUD[CoDHUD_GetHUDType()].SuspenseTracks)

    CoDHUD_PlayAnnouncerSound(track, true, 0.25)

    timer.Simple(60, function()
        CoDHUD_ScheduleNextSuspense()
    end)
end

function CoDHUD_ScheduleNextSuspense()
    timer.Remove("CoDHUD_SuspenseTimer")

    if not cvar_enabled:GetBool() then return end

    local nextDelay = math.random(MIN_DELAY, MAX_DELAY)

    timer.Create("CoDHUD_SuspenseTimer", nextDelay, 1, function()
        CoDHUD_PlaySuspenseSting()
    end)
end

cvars.AddChangeCallback("codhud_enable_suspense", function(name, old, new)
    if tobool(new) then
        CoDHUD_ScheduleNextSuspense()
    else
        timer.Remove("CoDHUD_SuspenseTimer")
    end
end)

hook.Add("InitPostEntity", "CoDHUD_StartSuspenseDirector", function()
    timer.Simple(30, function()
        CoDHUD_ScheduleNextSuspense()
    end)
end)

-- OPTIONAL: remove fade-out dependency (no longer needed)
hook.Add("PlayerDeath", "CoDHUD_StopSuspenseOnDeath", function(ply)
    -- intentionally empty (music system handles itself now)
end)

hook.Add("ShutDown", "CoDHUD_CleanUpSuspense", function()
    if IsValid(CoDHUD_CurrentMusic) then
        CoDHUD_CurrentMusic:Stop()
        CoDHUD_CurrentMusic = nil
    end
end)