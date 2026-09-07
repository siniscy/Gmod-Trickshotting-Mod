-- Handles killcam replay for NPCs and sesh bots (seq/cycle, no bones)

local KC_NPC_ReplayFrames = {}
local KC_NPC_Models       = {}
local KC_KillID           = nil
local KC_BotKillID        = nil

local function KC_Playing()
    return GetGlobalBool("Killcam_Playing", false)
end

local function IsSeshMode()
    local cv = GetConVar("codhud_selected_gamemode")
    if not cv then return false end
    local gm = cv:GetString()
    return gm == "sesh_dm" or gm == "sesh_war" or gm == "sesh_sd" or gm == "sesh_sd_set"
end

-- ================================================================
--  RELIABLE KILLCAM-ENDED DETECTION
--  hook.Run("KillcamReplayStopped") is called server-side in
--  sv_replayhandler.lua, but hook.Run only fires hooks in the realm
--  that calls it — it never reaches the client. So KC_ClientReplaying
--  was getting set true on frame receipt but never reliably cleared.
--  This poll watches Killcam_ServerTick (a networked int that resets
--  to 1 at the start of each killcam and counts up every tick while
--  playing) — if it stops advancing for a short window, the killcam
--  has ended and we clear the flag ourselves.
-- ================================================================
local lastTick, lastTickChangeTime = nil, 0
hook.Add("Think", "KC_ClientReplaying_Watchdog", function()
    if not _G.KC_ClientReplaying then return end
    local tick = GetGlobalInt("Killcam_ServerTick", 0)
    if tick ~= lastTick then
        lastTick = tick
        lastTickChangeTime = CurTime()
    elseif CurTime() - lastTickChangeTime > 0.5 then
        -- Tick hasn't advanced in 0.5s while we think we're replaying —
        -- the killcam has actually ended, clear the flag.
        _G.KC_ClientReplaying = false
    end
end)

-- Hide bot player entity immediately on death so wOS T-pose is invisible
-- (The ragdoll is handled server-side; clientside model handles killcam display)
hook.Add("PlayerDeath", "SeshBot_HideOnDeath", function(victim)
    if not victim:IsBot() then return end
    if not IsSeshMode() then return end
    victim:SetNoDraw(true)
end)

-- Hide ragdolls created from bot deaths in sesh mode
hook.Add("CreateEntityRagdoll", "SeshBot_HideBotRagdoll", function(owner, ragdoll)
    if not IsSeshMode() then return end
    if not IsValid(owner) or not owner:IsPlayer() or not owner:IsBot() then return end
    if IsValid(ragdoll) then
        ragdoll:SetNoDraw(true)
    end
end)

-- ================================================================
--  MODEL HELPER
-- ================================================================
local NPC_ModelMap = {
    npc_combine_s       = "models/combine_soldier.mdl",
    npc_metropolice     = "models/police.mdl",
    npc_zombie          = "models/zombie/classic.mdl",
    npc_fastzombie      = "models/zombie/fast.mdl",
    npc_headcrab        = "models/headcrabclassic.mdl",
    npc_headcrab_fast   = "models/headcrab.mdl",
    npc_antlion         = "models/antlion.mdl",
    npc_citizen         = "models/humans/group03/male_01.mdl",
}
local function GetModelForClass(class)
    return NPC_ModelMap[class] or "models/combine_soldier.mdl"
end

-- ================================================================
--  CLEANUP
-- ================================================================
local function CleanupModels()
    for _, mdl in pairs(KC_NPC_Models) do
        if IsValid(mdl) then mdl:Remove() end
    end
    KC_NPC_Models       = {}
    KC_NPC_ReplayFrames = {}
    KC_KillID           = nil
    KC_BotKillID        = nil
    _G.KC_ClientReplaying = false
end

-- ================================================================
--  NET: NPC Frames
-- ================================================================
net.Receive("Killcam - NPC Frames", function()
    local len       = net.ReadUInt(24)
    local data      = net.ReadData(len)
    local botKillID = net.ReadInt(32)

    KC_BotKillID = (botKillID and botKillID > 0) and botKillID or nil
    _G.KC_ClientReplaying = true
    print("[KC NPC Client] Received frames, kill is " ..
          (KC_BotKillID and ("BOT ID=" .. KC_BotKillID) or "NPC"))

    local raw = util.Decompress(data)
    if not raw then return end
    local parsed = util.JSONToTable(raw)
    if not parsed then return end

    KC_NPC_ReplayFrames = {}
    local npcCount = 0

    for frameIdx, frameNPCs in pairs(parsed) do
        local fi = tonumber(frameIdx)
        if not fi then continue end
        KC_NPC_ReplayFrames[fi] = {}
        for npcId, npcData in pairs(frameNPCs) do
            local id = tonumber(npcId)
            if not id then continue end
            npcCount = npcCount + 1
            if npcData.removed then
                KC_NPC_ReplayFrames[fi][id] = { removed = true }
            else
                KC_NPC_ReplayFrames[fi][id] = {
                    pos   = Vector(npcData.pos[1], npcData.pos[2], npcData.pos[3]),
                    ang   = Angle(npcData.ang[1], npcData.ang[2], npcData.ang[3]),
                    seq   = npcData.seq,
                    cycle = npcData.cycle,
                    class = npcData.class,
                    model = npcData.model,
                    kill  = npcData.kill,
                }
                if npcData.kill and not KC_BotKillID then
                    KC_KillID = id
                end
            end
        end
    end

    if KC_BotKillID then
        KC_KillID = KC_BotKillID
    end

    print("[KC NPC Client] Received " .. npcCount .. " NPC replay entries, kill ID=" ..
          tostring(KC_KillID) .. " bot ID=" .. tostring(KC_BotKillID))
end)

-- ================================================================
--  NET: Hitmarker
-- ================================================================
net.Receive("Killcam - Hitmarker", function()
    -- Use ForceHitmarker so it bypasses codhud_quickdisable_hud during killcam
    if _G.CoDHUD_ForceHitmarker then
        _G.CoDHUD_ForceHitmarker()
    else
        if CoDHUD_GetHUDType and CoDHUD then
            local hudType = CoDHUD_GetHUDType()
            local hud = hudType and CoDHUD[hudType]
            if hud and type(hud.hitmarkerTime) == "number" then
                hud.hitmarkerTime = CurTime() + 1
            end
        end
    end
    -- Hide clientside model and show kill NPC so it ragdolls (normal mode)
    if KC_KillID and not IsSeshMode() then
        local mdl = KC_NPC_Models[KC_KillID]
        if IsValid(mdl) then mdl:SetNoDraw(true) end
        -- Un-hide the kill NPC so its ragdoll is visible
        for _, ent in ipairs(ents.GetAll()) do
            if IsValid(ent) and ent:IsNPC() and ent.KC_WasHidden then
                if ent:EntIndex() == KC_KillID then
                    ent:SetNoDraw(false)
                    ent.KC_WasHidden = false
                end
            end
        end
    end
end)

-- Override KC_KillID when a live killcam NPC is spawned mid-killcam
local KC_KillcamNPCActive = false
local KC_KillcamNPCEntID  = nil

net.Receive("Killcam - KillcamNPCID", function()
    local id = net.ReadInt(16)
    KC_KillcamNPCActive = true
    KC_KillcamNPCEntID  = id
    if IsSeshMode() then
        -- In sesh mode the NPC IS the display — keep it visible
        print("[KC NPC Client] Live killcam NPC id=" .. tostring(id) .. " — sesh mode, staying visible")
    else
        -- In normal mode, hide it — clientside model handles animation until kill frame
        local ent = Entity(id)
        if IsValid(ent) then
            ent:SetNoDraw(true)
        end
        print("[KC NPC Client] Live killcam NPC id=" .. tostring(id) .. " — hidden until kill frame")
    end
end)

hook.Add("KillcamReplayStopped", "KC_KillcamNPC_Cleanup", function()
    KC_KillcamNPCActive = false
    KC_KillcamNPCEntID  = nil
end)

-- At kill frame: hide clientside model, show live NPC so it ragdolls
net.Receive("Killcam - KillcamNPCKilled", function()
    if IsSeshMode() then
        -- Sesh: NPC was always visible, just show hitmarker
        if _G.CoDHUD_ForceHitmarker then _G.CoDHUD_ForceHitmarker() end
    else
        -- Normal mode: hide clientside model, un-hide live NPC for ragdoll
        local mdl = KC_NPC_Models[KC_KillID]
        if IsValid(mdl) then mdl:SetNoDraw(true) end
        if KC_KillcamNPCEntID then
            local ent = Entity(KC_KillcamNPCEntID)
            if IsValid(ent) then ent:SetNoDraw(false) end
        end
        if _G.CoDHUD_ForceHitmarker then _G.CoDHUD_ForceHitmarker() end
    end
    print("[KC NPC Client] NPC killed — showing hitmarker")
end)

-- ================================================================
--  KILLCAM STARTED — hide world entities
-- ================================================================
hook.Add("KillcamReplayStarted", "KC_NPC_ClientInit", function()
    CleanupModels()
    _G.KC_ClientReplaying = true
    for _, ent in ipairs(ents.GetAll()) do
        if not IsValid(ent) then continue end
        if ent:IsNPC() then
            ent:SetNoDraw(true)
            ent.KC_WasHidden = true
        end
        if ent:IsPlayer() and ent:IsBot() then
            ent:SetNoDraw(true)
            ent.KC_WasHidden = true
        end
    end
end)

-- ================================================================
--  KILLCAM STOPPED — restore visibility
-- ================================================================
hook.Add("KillcamReplayStopped", "KC_NPC_ClientCleanup", function()
    CleanupModels()
    _G.KC_ClientReplaying = false
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.KC_WasHidden then
            -- Don't un-hide player bots — server will kick them shortly
            if ent:IsPlayer() and ent:IsBot() then continue end
            ent:SetNoDraw(false)
            ent.KC_WasHidden = false
        end
    end
end)

-- Clean up leftover clientside models at round start too
hook.Add("CoDHUD_RoundStart", "KC_NPC_RoundStartCleanup", function()
    CleanupModels()
end)

-- ================================================================
--  THINK — replay frames each tick
-- ================================================================
hook.Add("Think", "KC_NPC_ClientReplay", function()
    if not KC_Playing() then return end
    if not KC_KillID then return end
    if not KC_ServerTick then return end
    -- In sesh mode, always skip — live NPC/ragdoll handles display
    if IsSeshMode() then return end

    local frame = KC_ServerTick()
    if not KC_NPC_ReplayFrames[frame] then return end

    local data = KC_NPC_ReplayFrames[frame][KC_KillID]
    if not data or data.removed then return end

    -- Create clientside model if needed
    if not KC_NPC_Models[KC_KillID] or not IsValid(KC_NPC_Models[KC_KillID]) then
        local modelPath = data.model or GetModelForClass(data.class)
        local mdl = ClientsideModel(modelPath, RENDERGROUP_OPAQUE)
        if not IsValid(mdl) then return end
        mdl:SetNoDraw(false)
        mdl:SetSkin(0)
        KC_NPC_Models[KC_KillID] = mdl
    end

    local mdl = KC_NPC_Models[KC_KillID]
    if not IsValid(mdl) then return end

    mdl:SetPos(data.pos)
    mdl:SetAngles(data.ang)

    -- Seq/cycle replay for both NPCs and bots
    if data.seq then
        if mdl:GetSequence() ~= data.seq then
            mdl:ResetSequence(data.seq)
        end
        if data.cycle then mdl:SetCycle(data.cycle) end
        mdl:FrameAdvance(FrameTime())
        mdl:InvalidateBoneCache()
    end
end)