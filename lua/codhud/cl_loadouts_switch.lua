---- [ CLIENT: WEAPON SWITCH ISOLATION ] ----
-- Makes the equipment slot its own isolated category: invnext/invprev never
-- lands on it, and a separate quick-switch command jumps straight to it.
--
-- GMod's own TTT gamemode solves this exact problem (a weapon category that
-- invnext/invprev must never cross into, plus a direct quick-switch to a
-- specific slot) via PlayerBindPress + input.SelectWeapon -- see
-- gamemodes/terrortown/gamemode/cl_wepswitch.lua (ttt_equipswitch) and
-- cl_keys.lua. This mirrors that approach instead of fighting the engine's
-- own invnext/invprev logic or relying on SWEP:CanBeSelected (which several
-- of the installed weapon bases already override for their own purposes).

-- [ BO2-STYLE INSTASWAP ] -- reproduces the classic CoD "quickswitch" bug:
-- invnext/invprev to a weapon, divert into equipment while it's still
-- mid-draw, then invnext/invprev again to snap straight to that weapon
-- fully-drawn instead of playing its draw animation out. GMod's SWEP system
-- never actually blocks switching (that's purely a cosmetic animation), so
-- this is really just tracking the input sequence and, where possible,
-- forcing the interrupted weapon's "still drawing" state to end early.
CreateClientConVar("kc_instaswap_draw_window", "0.6", true, false,
    "Instaswap: fallback seconds a weapon counts as 'mid-draw' after switching to it, for bases that don't expose their own draw timer.")
CreateClientConVar("kc_instaswap_confirm_window", "1.0", true, false,
    "Instaswap: seconds after diverting to equipment mid-draw that invnext/invprev still confirms the instaswap instead of doing a normal cycle.")

local function IsEquipment(wep)
    return IsValid(wep) and wep.KC_IsEquipment == true
end

-- GetWeapons() isn't guaranteed to be a clean numeric array (same caveat
-- TTT's WSWITCH:UpdateWeaponCache documents) -- copy through pairs() into a
-- fresh list, skipping the equipment slot entirely.
local function GetCyclableWeapons(ply)
    local out = {}
    for _, wep in pairs(ply:GetWeapons()) do
        if IsValid(wep) and not IsEquipment(wep) then
            table.insert(out, wep)
        end
    end

    table.sort(out, function(a, b)
        if a.Slot ~= b.Slot then return (a.Slot or 0) < (b.Slot or 0) end
        return (a.SlotPos or 0) < (b.SlotPos or 0)
    end)

    return out
end

-- Instaswap state -- the weapon our last invnext/invprev press switched TO,
-- and (once the player diverts into equipment mid-draw) the pending target
-- to confirm on the next invnext/invprev press.
local lastCycleTarget = nil
local lastCycleTime   = 0
local pendingInsta    = nil
local pendingInstaSet = 0

-- True while `wep` is still playing its draw-in animation. For
-- bo2_gun_base/bo2_scoped_base (lua/weapons/bo2_gun_base/shared.lua's
-- SWEP:Deploy/IronSight/Reload) this reads their own ResetSights timer --
-- but that field also doubles as their post-reload pose-reset timer, and it
-- only gets cleared out by that weapon's own Think (IronSight) while it's
-- the active weapon. Holster it mid-draw/mid-reload and it's never cleared,
-- so a *stale* ResetSights from before this switch can still be sitting
-- there (usually already in the past) and would otherwise make this report
-- "not drawing" immediately, even on an instant switch. Only trust it when
-- it was actually (re)armed at or after switchedAt; every other installed
-- weapon base doesn't expose anything equivalent, so those -- and stale
-- timers -- fall back to a flat window (kc_instaswap_draw_window).
local function IsStillDrawing(wep, switchedAt)
    if not IsValid(wep) then return false end
    if wep.ResetSights and wep.ResetSights > switchedAt then
        return CurTime() < wep.ResetSights
    end
    return CurTime() - switchedAt < GetConVar("kc_instaswap_draw_window"):GetFloat()
end

CreateClientConVar("kc_instaswap_force_window", "0.35", true, false,
    "Instaswap: seconds to keep fighting a weapon base's own Think logic if it tries to re-assert its draw animation after we've forced idle. Only matters for weapon bases we don't have source for (bo2_gun_base/bo2_scoped_base never need this).")

-- Snaps `wep`'s viewmodel to its idle sequence, clearing the ported BO2
-- bases' own mid-draw timer along the way. `hardReset` forces the cycle/
-- playback rate back to frame 0 (used for the first application); repeat
-- calls during the force window only re-assert the sequence if something
-- else already changed it away from idle, so a naturally-playing idle
-- animation doesn't get frozen at frame 0 by being reset every tick.
local function ApplyIdlePose(wep, hardReset)
    if not IsValid(wep) then return end
    wep.ResetSights = nil

    local owner = wep:GetOwner()
    local vm = IsValid(owner) and owner:GetViewModel()
    if not IsValid(vm) then return end

    local idleSeq = vm:LookupSequence(wep.Silenced and "idle_silenced" or "idle")
    if not idleSeq or idleSeq < 0 then idleSeq = vm:LookupSequence("idle") end
    if not idleSeq or idleSeq < 0 then return end

    if hardReset or vm:GetSequence() ~= idleSeq then
        vm:SendViewModelMatchingSequence(idleSeq)
        vm:SetCycle(0)
        vm:SetPlaybackRate(1)
    end
end

-- Forces `wep` to look fully drawn right now. Precise (one-shot, no fighting
-- needed) for bo2_gun_base/bo2_scoped_base since ApplyIdlePose already
-- clears the exact timer (ResetSights) those bases check. For every other
-- installed weapon base -- source we don't have, so we don't know if/how
-- they'd reassert their own draw pose on a later tick -- this also fights
-- back for a short window (kc_instaswap_force_window) so a competing
-- Think() doesn't silently undo the skip a frame later.
local function SkipDrawAnim(wep)
    if not IsValid(wep) then return end
    ApplyIdlePose(wep, true)

    local hookName = "KC_InstaSwap_ForceIdle_" .. tostring(wep)
    local endTime = CurTime() + GetConVar("kc_instaswap_force_window"):GetFloat()

    hook.Add("Think", hookName, function()
        local owner = wep:GetOwner()
        if not IsValid(wep) or CurTime() > endTime or not IsValid(owner) or owner:GetActiveWeapon() ~= wep then
            hook.Remove("Think", hookName)
            return
        end
        ApplyIdlePose(wep, false)
    end)
end

local function CycleWeapon(ply, dir)
    -- Instaswap confirm: we diverted into equipment mid-draw (armed in
    -- kc_equip below), and this invnext/invprev press landed inside the
    -- confirm window -- snap straight to the interrupted weapon instead of
    -- doing a normal cycle. Deliberately NOT also requiring
    -- IsEquipment(ply:GetActiveWeapon()) here: on a fast gamepad press the
    -- equipment SelectWeapon from kc_equip hasn't been predicted/replicated
    -- back to GetActiveWeapon() yet by the time this fires, so that check
    -- would silently miss exactly the fast presses instaswap exists for.
    if pendingInsta and IsValid(pendingInsta)
        and CurTime() - pendingInstaSet < GetConVar("kc_instaswap_confirm_window"):GetFloat() then
        print("[KC InstaSwap] confirmed -> " .. pendingInsta:GetClass())
        input.SelectWeapon(pendingInsta)
        SkipDrawAnim(pendingInsta)
        pendingInsta = nil
        return
    end
    pendingInsta = nil

    local list = GetCyclableWeapons(ply)
    if #list == 0 then return end

    local active = ply:GetActiveWeapon()
    local idx = 1
    for i, wep in ipairs(list) do
        if wep == active then
            idx = i
            break
        end
    end

    idx = idx + dir
    if idx > #list then idx = 1 end
    if idx < 1 then idx = #list end

    local target = list[idx]
    input.SelectWeapon(target)
    lastCycleTarget = target
    lastCycleTime    = CurTime()
end

hook.Add("PlayerBindPress", "KC_Loadouts_WeaponSwitch", function(ply, bind, pressed, code)
    if not pressed then return end
    if not IsValid(ply) then return end
    -- Controller mode reads the pad itself (cl_kc_controller.lua); ignore its GMod binds.
    if KC_Controller and KC_Controller.BlocksBind(code) then return end

    if bind == "invnext" then
        CycleWeapon(ply, 1)
        return true
    elseif bind == "invprev" then
        CycleWeapon(ply, -1)
        return true
    end
end)

-- Dedicated equipment quick-switch. Bind a controller button to this
-- yourself (console: bind <button> kc_equip) -- it jumps straight to the
-- equipment weapon via input.SelectWeapon, completely bypassing
-- invnext/invprev, so it can never collide with normal weapon cycling.
--
-- Gamepad players are reminded to bind L_SHOULDER to this (see the
-- one-time console hint below) since that's the button CoD-style instaswap
-- naturally lives on -- addons can't set the bind for them (see below).
concommand.Add("kc_equip", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    -- Arm the instaswap: if our last invnext/invprev press is still within
    -- its draw window, remember it so the *next* invnext/invprev (while
    -- equipment is out) snaps straight to it instead of playing its draw
    -- animation out. Deliberately NOT requiring
    -- ply:GetActiveWeapon() == lastCycleTarget here: on a fast gamepad press
    -- (the whole point of instaswap) the weapon-select from that cycle
    -- press hasn't been predicted/replicated back to GetActiveWeapon() yet
    -- when this fires, so that check would fail every genuinely-fast
    -- attempt. IsStillDrawing on lastCycleTarget itself (via its own
    -- ResetSights timer where available, else the flat window) is what
    -- actually gates this now.
    if lastCycleTarget and IsValid(lastCycleTarget)
        and IsStillDrawing(lastCycleTarget, lastCycleTime) then
        pendingInsta    = lastCycleTarget
        pendingInstaSet = CurTime()
        print("[KC InstaSwap] armed -> " .. pendingInsta:GetClass())
    else
        pendingInsta = nil
    end

    for _, wep in pairs(ply:GetWeapons()) do
        if IsEquipment(wep) then
            input.SelectWeapon(wep)
            return
        end
    end
end)

-- [ GAMEPAD DEFAULT BIND ] -- L_SHOULDER is GMod's default bumper button
-- name for controllers. `bind` is on the engine's RunConsoleCommand
-- blocklist (https://wiki.facepunch.com/gmod/Blocked_ConCommands) --
-- addons are not allowed to silently rebind a player's keys, so this has to
-- be a one-time console reminder instead of an automatic bind.
CreateClientConVar("kc_instaswap_gamepad_hint_shown", "0", true, false,
    "Internal: whether the one-time L_SHOULDER gamepad bind reminder has already been printed.")

if not GetConVar("kc_instaswap_gamepad_hint_shown"):GetBool() then
    print("[KC InstaSwap] Gamepad tip: open console and run  bind L_SHOULDER kc_equip  to put instaswap on your left bumper.")
    RunConsoleCommand("kc_instaswap_gamepad_hint_shown", "1")
end
