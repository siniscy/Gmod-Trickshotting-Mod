-- codhud_crosshair.lua
-- CoD4-style crosshair for kc_project_0.6.
-- Place in lua/autorun/ - loads automatically, no init changes needed.

if not CLIENT then return end

-- ================================================================
--  CONVARS
-- ================================================================
CreateClientConVar("cod4_crosshair_red",   "255", true, true, "Crosshair red")
CreateClientConVar("cod4_crosshair_green", "255", true, true, "Crosshair green")
CreateClientConVar("cod4_crosshair_blue",  "255", true, true, "Crosshair blue")
CreateClientConVar("cod4_crosshair_alpha", "255", true, true, "Crosshair alpha")
CreateClientConVar("codhud_crosshair",     "1",   true, true, "Enable CoD4 crosshair")

hook.Add("PopulateToolMenu", "CoD4CrosshairOptions", function()
    spawnmenu.AddToolMenuOption("Options", "Call of Duty 4: Modern Warfare", "cod4_crosshair", "Crosshair", "", "", function(panel)
        panel:AddControl("Color", {
            Label = "Color",
            Red   = "cod4_crosshair_red",
            Green = "cod4_crosshair_green",
            Blue  = "cod4_crosshair_blue",
            Alpha = "cod4_crosshair_alpha"
        })
    end)
end)

-- ================================================================
--  MATERIAL
-- ================================================================
local MAT_CROSSHAIR = Material("cod4/vgui/side_small")

-- ================================================================
--  SPREAD MODEL
-- ================================================================
local spreadFrac = 0
local lastAmmo   = -1

local DECAY_STILL = 3.0
local DECAY_MOVE  = 1.0
local SHOT_ADD    = 0.35

hook.Add("Think", "CoD4Crosshair_Think", function()
    if not GetConVar("codhud_crosshair"):GetBool() then return end
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then lastAmmo = -1 return end

    local clip = wep:Clip1()
    if lastAmmo ~= -1 and clip >= 0 and clip < lastAmmo then
        spreadFrac = math.Clamp(spreadFrac + SHOT_ADD, 0, 1)
    end
    lastAmmo = clip >= 0 and clip or lastAmmo
end)

-- ================================================================
--  DRAW FUNCTION - called from HUDPaint for normal gameplay,
--  and from cl_hud.lua's killcam HUDPaint hook for killcam.
-- ================================================================
function CoD4Crosshair_Draw(inKillcam)
    if not GetConVar("codhud_crosshair"):GetBool() then return end
    -- codhud_quickdisable_hud is true during killcam, but we still want
    -- the crosshair, so only check it outside killcam.
    if not inKillcam then
        if GetConVar("codhud_quickdisable_hud") and GetConVar("codhud_quickdisable_hud"):GetBool() then return end
    end
    if not GetConVar("cl_drawhud"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if not ply:Alive() then return end
    if ply:GetFOV() < 45 then return end

    local ft    = FrameTime()
    local vel2d = ply:GetVelocity():Length2D()
    local isAir = not ply:IsOnGround()

    if isAir then
        spreadFrac = math.min(spreadFrac + DECAY_MOVE * ft, 1)
    elseif vel2d > 10 then
        spreadFrac = Lerp(ft * 4, spreadFrac, math.Clamp(vel2d / 250, 0, 1))
    else
        spreadFrac = math.max(spreadFrac - DECAY_STILL * ft, 0)
    end

    local dist = spreadFrac * 20 + 60
    local r = GetConVar("cod4_crosshair_red"):GetInt()
    local g = GetConVar("cod4_crosshair_green"):GetInt()
    local b = GetConVar("cod4_crosshair_blue"):GetInt()
    local a = GetConVar("cod4_crosshair_alpha"):GetInt()

    surface.SetMaterial(MAT_CROSSHAIR)
    surface.SetDrawColor(r, g, b, a)

    local cx, cy = ScrW() / 2, ScrH() / 2
    surface.DrawTexturedRectRotated(cx - dist, cy, 12, 12, 90)
    surface.DrawTexturedRectRotated(cx + dist, cy, 12, 12, -90)
    surface.DrawTexturedRectRotated(cx, cy - dist, 12, 12, 0)
    surface.DrawTexturedRectRotated(cx, cy + dist, 12, 12, 180)
end

-- Normal gameplay only - killcam draw is handled by cl_hud.lua
hook.Add("HUDPaint", "CoD4Crosshair_Draw", function()
    if KC_Playing and KC_Playing() then return end  -- skip during killcam
    CoD4Crosshair_Draw()
end)

-- ================================================================
--  HIDE GMod's default crosshair
-- ================================================================
hook.Add("HUDShouldDraw", "CoD4Crosshair_HideDefault", function(name)
    if name == "CHudCrosshair" then
        if GetConVar("codhud_crosshair"):GetBool() then return false end
    end
end)