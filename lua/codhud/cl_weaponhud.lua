---- [ CLIENT WEAPON HUD ] ----

-- [[ COMPASS CFG ]]
local MASK = {
    FOV      = 152,
    FADE_DEG = 10,
}

-- [[ WEAPON HUD CFG ]]
local CFG = {
    -- Base Bar
    BAR_W       = 776,
    BAR_H       = 122,
    BAR_X_OFF   = 2,
    BAR_Y_OFF   = 48,

    -- Grenades
    GRENADE_X_OFF     = -230,
    GRENADE_Y_OFF     = -24,
    GRENADE_ICON_W    = 40,
    GRENADE_ICON_H    = 40,
    GRENADE_STACK_GAP = 8,
    GRENADE_MAX       = 4,
    GRENADE_SHADES    = { 255, 200, 175, 120 },

    -- Reserve Ammo (1-2 digit: 0-99)
    RES_SIZE    = 64,
    RES_X       = -244,
    RES_Y       = 32,

    -- Reserve Ammo (3 digit: 100-999)
    RES3_SIZE   = 48,
    RES3_X      = -244,
    RES3_Y      = 48,

    -- Reserve Ammo (4 digit: 1000+)
    RES4_SIZE   = 38,
    RES4_X      = -243,
    RES4_Y      = 52,

    -- Text kerning
    SQUEEZE            = -6,
    SQUEEZE_ONE        = -14,
    SQUEEZE_ONE_BEFORE = -10,

    -- Weapon Name
    WEP_NAME_SIZE  = 38,
    WEP_NAME_X_OFF = -206,
    WEP_NAME_Y_OFF = 12,
    WEP_NAME_FADE  = 2,
    WEP_NAME_SQ    = -3,
    WEP_NAME_SQ1   = -8,

    -- Status Indicator
    STAT_FONT_SIZE = 28,
    STAT_LOW_PERC  = 0.40,
    STAT_FLASH_SPD = 8,
    STAT_Y_OFF     = 62,

    -- Bullet Icons
    BULLET_ALPHA      = 155,
    BULLET_RELOAD_R   = 180,
    BULLET_RELOAD_G   = 60,
    BULLET_RELOAD_B   = 60,
    BULLET_RELOAD_SPD = 6,

    -- Alt Ammo (Underbarrel / Secondary)
    ALT_ICON_SIZE  = 78,
    ALT_ICON_X     = -140,
    ALT_ICON_Y     = 64,
    ALT_TEXT_X     = -80,
    ALT_TEXT_Y     = 92,
    ALT_FONT_SIZE  = 36,
    ALT_TEXT_SQ    = -3,
    ALT_TEXT_SQ1   = -7,
}

local function GetAmmoConfig(wep)
    if not IsValid(wep) then return AMMO["default"] end
    if wep:GetMaxClip1() >= 100 then return AMMO["belt"] end
    local ammoName = string.lower(game.GetAmmoName(wep:GetPrimaryAmmoType()) or "")
    return AMMO[AMMO_MAP[ammoName]] or AMMO["default"]
end

local function GetAmmoKey(ammoCfg)
    for key, data in pairs(AMMO) do
        if data == ammoCfg then return key end
    end
    return "default"
end

-- [[ HUD HIDING ]]
local HIDE = { ["CHudAmmo"] = true, ["CHudSecondaryAmmo"] = true, ["CHudHealth"] = true, ["CHudBattery"] = true }
hook.Add("HUDShouldDraw", "MW2_HideDefaultHUD", function(name)
	if (not GetConVar("codhud_enable_weaponinfo"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
	
    if HIDE[name] then return false end
end)

-- [[ SQUEEZED TEXT DRAW ]]
local function DrawSqueezedText(text, font, x, y, color, squeeze, squeezeOne, align, squeezeOneBefore)
    local str = tostring(text)
    surface.SetFont(font)
    squeeze          = squeeze          or CFG.SQUEEZE
    squeezeOne       = squeezeOne       or CFG.SQUEEZE_ONE
    squeezeOneBefore = squeezeOneBefore or CFG.SQUEEZE_ONE_BEFORE

    local totalW = 0
    for i = 1, #str do
        local char     = str:sub(i, i)
        local nextChar = str:sub(i + 1, i + 1)
        local w = surface.GetTextSize(char)
        totalW = totalW + w
        if i < #str then
            local gap
            if char == "1" then gap = squeezeOne
            elseif nextChar == "1" then gap = squeezeOneBefore
            else gap = squeeze end
            totalW = totalW + gap
        end
    end

    local runX
    if align == 1 then runX = x - (totalW / 2)
    elseif align == 2 then runX = x
    else runX = x - totalW end

    for i = 1, #str do
        local char     = str:sub(i, i)
        local nextChar = str:sub(i + 1, i + 1)
		draw.SimpleTextOutlined(char, font, runX, y, color, 0, 0, 1.5, Color(0,0,0, color.a * 0.8))
        local w = surface.GetTextSize(char)
        if i < #str then
            local gap
            if char == "1" then gap = squeezeOne
            elseif nextChar == "1" then gap = squeezeOneBefore
            else gap = squeeze end
            runX = runX + w + gap
        end
    end
end

-- [[ WEAPON SWITCH TRACKING ]]
local lastWep       = nil
local wepSwitchTime = 0

-- [[ MAIN MERGED DRAW HOOK ]]
hook.Add("HUDPaint", "MW2_MergedHUD", function()
	if (not GetConVar("codhud_enable_weaponinfo"):GetBool()) or GetConVar("codhud_quickdisable_hud"):GetBool() then return end
	if not GetConVar("cl_drawhud"):GetBool() then return end
	local outlined = GetConVar("codhud_enable_outlinedtext"):GetBool()
	
    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local scrW, scrH = ScrW(), ScrH()
	if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].WeaponInfo then
		CoDHUD[CoDHUD_GetHUDType()].WeaponInfo(MASK, CFG, ply)
	end
end)