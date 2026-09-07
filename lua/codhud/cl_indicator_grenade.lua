---- [ CLIENT GRENADE INDICATOR ] ----

CoDHUD = CoDHUD or {}

CreateClientConVar("codhud_enable_grenadeindicator", "1", true, false, "Enable CoD HUD grenade indicator")

CoDHUD.GrenadeList = {
    ["npc_grenade_frag"] = true,
    ["cw_grenade_frag"] = true,
    ["m9k_released_frag"] = true,
}

function CoDHUD_IsGrenade(ent)
    if not IsValid(ent) then return false end
    local class = ent:GetClass()
    if ent.ArcCWProjectile or ent.ARC9Projectile then return true end
    if CoDHUD.GrenadeList[class] then return true end
    if bit.band(ent:GetFlags(), FL_GRENADE) > 0 then return true end
    return false
end

hook.Add("HUDPaint", "CoDHUD_Grenade_Indicator", function()
    if not GetConVar("codhud_enable_grenadeindicator"):GetBool() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) or not ply:Alive() then return end

    local scrW, scrH = ScrW(), ScrH()
    local cx, cy = scrW / 2, scrH / 2
    local curTime = CurTime()

    -- 0.6s Flash Logic
    local showIcon = math.fmod(curTime, 0.6) < 0.4
    local nearEnts = ents.FindInSphere(ply:GetPos(), 250) 

	if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].GrenadeIndicator then
		CoDHUD[CoDHUD_GetHUDType()].GrenadeIndicator(showIcon, nearEnts, ply)
	end
end)