---- [ CLIENT KILLCAM HANDS FIX ] ----
-- SWEP.UseHands = true (the M9K-style weapon base convention used by
-- steezmodV1b's weapons) relies on the engine's native player-hands
-- attachment system, which is only reliably driven for the client's own
-- LocalPlayer(). Spectating someone else's UseHands weapon in first person
-- (exactly the killcam scenario) never gets hands attached by the engine --
-- only the gun itself renders.
--
-- History of what didn't work, kept here so this isn't re-attempted blind:
-- 1) Hooked PostDrawViewModel to manually draw hands -- confirmed via live
--    testing that hook never fires at all for a spectated (non-local)
--    player's viewmodel.
-- 2) Switched to PostDrawOpaqueRenderables + manual per-frame SetPos/
--    SetAngles/SetBoneMatrix (copying vm's bone transforms onto the hands
--    model bone-by-bone, matched by name). Position data was confirmed
--    correct (dist ~0-4 units from camera), but 0 of 43 bones ever matched
--    by name -- c_arms_citizen.mdl and this weapon's custom viewmodel
--    skeleton share no common bone names, so manual matrix copying can
--    never work here regardless of the render-visibility issue that was
--    also present.
--
-- Since UseHands weapons clearly DO show correctly-animated hands for the
-- local player normally, the engine has a working native way to attach
-- c_arms_citizen.mdl to this exact viewmodel's bones -- that's bonemerge
-- (EF_BONEMERGE), not manual name-matched matrix copying. Parenting the
-- hands model to the viewmodel with bonemerge lets the ENGINE handle bone
-- correspondence every frame the same way it already does for the local
-- player's own weapon, instead of Lua trying to replicate that logic badly.

if not CLIENT then return end

local handsEnt     = nil
local handsForVM    = nil  -- which viewmodel entity handsEnt is currently merged to
local debugAt       = 0

local function CleanupKillcamHands()
    if IsValid(handsEnt) then handsEnt:Remove() end
    handsEnt  = nil
    handsForVM = nil
end
hook.Add("KillcamReplayStopped", "KC_HandsFix_Cleanup", CleanupKillcamHands)

hook.Add("Think", "KC_HandsFix_Think", function()
    local doDebug = CurTime() > debugAt
    if doDebug then debugAt = CurTime() + 2 end

    local lp = LocalPlayer()
    if not IsValid(lp) or lp:GetObserverMode() ~= OBS_MODE_IN_EYE then
        CleanupKillcamHands()
        return
    end

    local target = lp:GetObserverTarget()
    if not IsValid(target) or not target:IsPlayer() or target == lp then
        CleanupKillcamHands()
        return
    end

    local weapon = target:GetActiveWeapon()
    if not IsValid(weapon) or not weapon.UseHands then
        CleanupKillcamHands()
        return
    end

    local vm = target:GetViewModel()
    if not IsValid(vm) then
        CleanupKillcamHands()
        return
    end

    -- Already merged to this exact viewmodel -- nothing to do, engine handles the rest
    if IsValid(handsEnt) and handsForVM == vm then return end

    -- Target/weapon/viewmodel changed since we last merged -- rebuild
    CleanupKillcamHands()

    local ok, info = pcall(player_manager.TranslatePlayerHands, target)
    if doDebug then
        print("[HandsFix DEBUG] Rebuilding: target=" .. target:Nick()
            .. " weapon=" .. weapon:GetClass()
            .. " TranslatePlayerHands ok=" .. tostring(ok) .. " model=" .. tostring(info and info.model))
    end
    if not ok or not info or not info.model then return end

    handsEnt = ClientsideModel(info.model, RENDERGROUP_OPAQUE)
    if not IsValid(handsEnt) then
        if doDebug then print("[HandsFix DEBUG] ClientsideModel creation failed") end
        return
    end

    handsEnt:SetSkin(info.skin or 0)
    if info.body then handsEnt:SetBodyGroups(info.body) end

    handsEnt:SetParent(vm)
    handsEnt:AddEffects(EF_BONEMERGE)
    handsEnt:AddEffects(EF_BONEMERGE_FASTCULL)
    handsEnt:SetNoDraw(false)

    handsForVM = vm

    if doDebug then
        print("[HandsFix DEBUG] handsEnt bonemerged to vm=" .. tostring(vm) .. " valid=" .. tostring(IsValid(handsEnt)))
    end
end)
