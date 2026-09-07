---- [ CLIENT: FINAL KILL DISTANCE CALLOUT ] ----
-- Sesh modes only (server only ever broadcasts this on the kill that ends
-- the round or the match). Drawn as its own line just under the normal
-- killfeed -- the normal killfeed's own draw code is untouched.

-- Safety cap only -- normally this gets cleared the instant the killcam
-- actually starts (see the DrawOverlay hook below), not by timing out.
local LIFETIME = 25

-- Every HUD game file's killfeed uses xPos = CoDHUD_S(10) and
-- spacing = CoDHUD_S(36); only the base bottom-offset and font differ.
local YOFFSET_BY_HUD = {
    mw2 = 210, mw3 = 210, cod4 = 210, waw = 210,
    bo1 = 260, bo2 = 260,
}
local FONT_BY_HUD = {
    mw2 = "MW2_KillfeedFont", mw3 = "MW2_KillfeedFont",
    cod4 = "MW2_KillfeedFont", waw = "MW2_KillfeedFont",
    bo1 = "BO1_KillfeedFont", bo2 = "BO2_KillfeedFont",
}

local pending = nil -- { text = "...", spawnTime = n, dieTime = n }

net.Receive("KC_FinalKillDistance", function()
    local attacker = net.ReadEntity()
    local victim    = net.ReadEntity()
    local meters    = net.ReadUInt(16)

    local lp = LocalPlayer()
    local attackerName = IsValid(attacker) and attacker:Nick() or "Someone"
    local victimName    = IsValid(victim) and victim:Nick() or "someone"

    -- Everyone sees the real shooter's name, except the shooter themselves
    -- sees "You" -- matches how CoD's own killfeed personalizes this line.
    local verb = (IsValid(attacker) and attacker == lp) and "You killed" or (attackerName .. " killed")

    print("[KC] FinalKillDistance received: " .. attackerName .. " -> " .. victimName .. " (" .. meters .. " m)")

    pending = {
        text      = string.format("%s %s from %d m", verb, victimName, meters),
        spawnTime = CurTime(),
        dieTime   = CurTime() + LIFETIME,
    }
end)

-- Drawn on DrawOverlay (not HUDPaint) because the tab/round-end scoreboard
-- paints its own full-screen backdrop on DrawOverlay too, which always
-- renders after HUDPaint -- on HUDPaint this text was getting silently
-- covered by that backdrop the moment the scoreboard appeared, well before
-- its own timer ran out. HOOK_MONITOR_LOW makes this run after every other
-- DrawOverlay hook (the scoreboard included) so it always ends up on top.
hook.Add("DrawOverlay", "KC_FinalKillDistance_Draw", function()
    if not pending then return end
    if not GetConVar("codhud_enable_killfeed"):GetBool() or GetConVar("codhud_quickdisable_hud"):GetBool() then return end

    -- Disappear the instant the killcam actually starts playing, rather
    -- than on a fixed timer that has to guess how long the pre-killcam
    -- delay/scoreboard phase will last.
    if GetGlobalBool("Killcam_Playing", false) then
        pending = nil
        return
    end

    local ct = CurTime()
    if ct > pending.dieTime then
        pending = nil
        return
    end

    local hudType = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    local baseYOffset = YOFFSET_BY_HUD[hudType] or 210
    local font         = FONT_BY_HUD[hudType] or "MW2_KillfeedFont"

    local xPos    = CoDHUD_S(10)
    local spacing = CoDHUD_S(36)
    local y       = ScrH() - CoDHUD_S(baseYOffset) + spacing

    local age       = ct - pending.spawnTime
    local timeLeft  = pending.dieTime - ct
    local fade = 1
    if age < 0.25 then
        fade = math.Clamp(age / 0.25, 0, 1)
    elseif timeLeft < 1 then
        fade = math.Clamp(timeLeft, 0, 1)
    end

    draw.SimpleText(pending.text, font, xPos, y, Color(255, 210, 90, 255 * fade))
end, HOOK_MONITOR_LOW)
