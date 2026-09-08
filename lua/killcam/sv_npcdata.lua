local npcs = {}
local origNPCFrames = {}
local replayNPCFrames = {}
local NPCRagdolls = {}

-- Global set by killcam_codhud_integration when a bot is killed in sesh modes
KC_BotKillID_Server = nil

function Killcam.SaveNPCData(attacker)
    attacker.KC_Recorder.npc_frames = Killcam.CopyTable(origNPCFrames)
end

function Killcam.LoadNPCData(pl)
    replayNPCFrames = Killcam.CopyTable(pl.KC_Recorder.npc_frames)
end

function Killcam.CaptureNPCData()
    for _, npc in pairs(npcs) do
        if !IsValid(npc) then
            npcs[_] = nil
            continue
        end
        -- Record real NPCs and registered bots
        if not npc:IsNPC() and not npc.KC_RecordAsNPC then continue end
        if not npc.RecordID then
            npc.RecordID = npc:EntIndex()
        end
        if origNPCFrames[Killcam.Frames - 1] and origNPCFrames[Killcam.Frames - 1][npc.RecordID] and
        origNPCFrames[Killcam.Frames - 1][npc.RecordID].removed then
            origNPCFrames[Killcam.Frames][npc.RecordID] = {removed = true}
            continue
        end
        origNPCFrames[Killcam.Frames] = origNPCFrames[Killcam.Frames] or {}

        local frameData = {
            class = npc:IsNPC() and npc:GetClass() or npc:GetModel(),
            pos   = npc:GetPos(),
            ang   = npc:GetAngles(),
            seq   = npc:GetSequence(),
            cycle = npc:GetCycle(),
            model = (not npc:IsNPC()) and (npc.SeshBotModel or npc:GetModel()) or nil,
            isBot = (not npc:IsNPC()) and true or nil,
        }

        origNPCFrames[Killcam.Frames][npc.RecordID] = frameData
    end
    for i = 1, Killcam.Frames - 1 do
        origNPCFrames[i] = origNPCFrames[i + 1]
    end
end

-- Register a CreateNextBot bot for NPC-style killcam recording (sesh modes)
function Killcam.RegisterBotForRecording(ent)
    if not IsValid(ent) then return end
    if not ent:IsNPC() and not (ent:IsPlayer() and ent:IsBot()) then return end
    ent.KC_RecordAsNPC = true
    ent.RecordID = ent:EntIndex()
    npcs[ent:EntIndex()] = ent
    local name = ent:IsNPC() and ent:GetClass() or ent:Nick()
    print("[KC] Registered for recording: " .. name)
end

function Killcam.UnregisterBot(ent)
    if not IsValid(ent) then return end
    npcs[ent:EntIndex()] = nil
end

local function CheckNPC(npc, id)
    return IsValid(npc) and npc.RecordID
end

function Killcam.PlayNPCData()
    local frame = KC_ServerTick()
    if #replayNPCFrames == 0 or not replayNPCFrames[frame] then return end
    for id, data in pairs(replayNPCFrames[frame]) do
        -- Skip the live killcam NPC — it's handled by its own timer
        local liveNPC = npcs[id] or Entity(id)
        if IsValid(liveNPC) and liveNPC.IsKillcamNPC then continue end
        if data.removed then
            local npc = npcs[id] or Entity(id)
            if IsValid(npc) then npc:Remove() end
            if replayNPCFrames[frame + 1] and replayNPCFrames[frame + 1][id] then
                replayNPCFrames[frame + 1][id].removed = true
            end
            continue
        end
        if data.killed and replayNPCFrames[frame + 1] and replayNPCFrames[frame + 1][id] then
            replayNPCFrames[frame+1][id].killed = true
            continue
        end
        local npc = npcs[id] or Entity(id)
        if !npcs[id] and !CheckNPC(npc, id) then
            -- Skip if class is a player model path (not a valid NPC entity class)
            if data.class and data.class:find("models/", 1, true) then continue end
            npcs[id] = ents.Create(data.class)
            npc = npcs[id]
            npc:SetPos(data.pos)
            npc:Spawn()
            npc.RecordID = id
            npc:MoveStart()
        end
        if !IsValid(npc) then continue end
        if npc:GetPos():DistToSqr(data.pos) > 3600 then
            npc:SetPos(data.pos)
        end
        npc:SetAngles(data.ang)

        local pl = KC_GetKiller()
        if not IsValid(pl) then continue end

        local rfKill = pl.KC_Recorder and pl.KC_Recorder.replay_frames and
                       pl.KC_Recorder.replay_frames[frame] and
                       pl.KC_Recorder.replay_frames[frame].kill

        if rfKill and rfKill == id then
            -- In sesh mode, the live NPC timer handles the kill — skip here
            if _G.SeshBot_KillcamTriggered then continue end
            -- Fire hitmarker
            net.Start("Killcam - Hitmarker")
            net.Broadcast()
            -- TakeDamageInfo causes ragdoll for NPC
            npc.KC_CanBeDamaged = true
            local d = DamageInfo()
            d:SetAttacker(pl)
            d:SetDamageType(DMG_BULLET)
            d:SetDamage(npc:Health() + 100)
            -- GetNormalized() on a zero-length vector produces NaN -- if the
            -- replay NPC's position and the killer's current position ever
            -- coincide (very possible for a close-range kill, exactly the
            -- kind a tight CQB map produces), a NaN velocity here is a hard
            -- engine crash, not a catchable Lua error.
            local kickDir = npc:GetPos() - pl:GetPos()
            if kickDir:Length() < 0.01 then kickDir = Vector(0, 0, 1) end
            npc:SetVelocity(kickDir:GetNormalized() * 10)
            npc:TakeDamageInfo(d)
            if replayNPCFrames[frame + 1] and replayNPCFrames[frame + 1][id] then
                replayNPCFrames[frame + 1][id].killed = true
            end
        end
    end
end

hook.Add("OnEntityCreated", "Killcam - Register NPC", function(ent)
    if ent:IsNPC() then
        ent.RecordID = ent:EntIndex()
        npcs[ent:EntIndex()] = ent
    end
end)

-- Track ragdolls created from killcam NPC deaths so they can be cleaned up
hook.Add("CreateEntityRagdoll", "Killcam - TrackNPCRagdolls", function(owner, ragdoll)
    if IsValid(owner) and owner:IsNPC() then
        NPCRagdolls[#NPCRagdolls + 1] = ragdoll
    end
end)

hook.Add("KillcamReplayStopped", "Killcam - Remove replay NPCs", function()
    origNPCFrames   = {}
    replayNPCFrames = {}
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.KC_WasHidden then
            ent:SetNoDraw(false)
            ent:SetNotSolid(false)
            ent.KC_WasHidden = false
        end
    end
end)

hook.Add("OnKillcamReplayStart", "Killcam - Get rid of NPC ragdolls", function(pl)
    for i = 1, #NPCRagdolls do
        local ent = NPCRagdolls[i]
        if IsValid(ent) and ent:IsRagdoll() then ent:Remove() end
    end
    NPCRagdolls = {}

    local killID = nil
    if pl and pl.KC_Recorder and pl.KC_Recorder.replay_frames then
        for _, frame in pairs(pl.KC_Recorder.replay_frames) do
            if frame and frame.kill then killID = frame.kill break end
        end
    end

    local botKillID = KC_BotKillID_Server
    print("[KC NPC] OnKillcamReplayStart: KC_BotKillID_Server=" .. tostring(botKillID))

    -- Sesh mode: spawn a frozen NPC stand-in at the kill position for killcam
    if FFA_KillcamDeathPos and _G.SeshBot_KillcamTriggered then
        local npc = ents.Create("npc_combine_s")
        if IsValid(npc) then
            npc:SetPos(FFA_KillcamDeathPos + Vector(0, 0, 2))
            npc:SetAngles(FFA_KillcamDeathAng or Angle(0, 0, 0))
            npc:SetKeyValue("additionalequipment", "weapon_smg1")
            npc:Spawn()
            npc:Activate()

            -- Completely disable AI without marking the NPC as dead
            -- (NPC_STATE_DEAD causes an immediate death/ragdoll transition
            -- on many NPC classes, which was killing the bot instantly).
            npc:SetSchedule(SCHED_NONE)
            npc:SetMoveType(MOVETYPE_NONE)
            npc:CapabilitiesClear()
            npc:SetCollisionGroup(COLLISION_GROUP_WEAPON) -- ignore player bullets until kill frame
            npc:Fire("SetRelationship", "player D_LI 0", 0)
            npc:SetHealth(500)
            npc.IsKillcamNPC = true
            npc:SetNW2Bool("IsKillcamNPC", true)
            npc.KC_CanBeDamaged = true

            local npcRef = npc
            local plRef  = pl
            FFA_KillcamNPC = npc
            print("[KC NPC] Live killcam NPC spawned id=" .. npc:EntIndex())

            -- Tell client the NPC ID so it can sync kill with hitmarker
            net.Start("Killcam - KillcamNPCID")
                net.WriteInt(npc:EntIndex(), 16)
            net.Broadcast()

            timer.Simple(0, function()
                if not IsValid(npcRef) or not IsValid(plRef) then return end
                local killframeID = plRef.KC_Recorder and plRef.KC_Recorder.killframeID or (Killcam.Frames - 5)
                local startTick = KC_ServerTick()
                local ticksToWait = killframeID - 1  -- killframeID is 1-indexed
                print("[KC NPC] Will kill NPC at killframeID=" .. tostring(killframeID) .. " startTick=" .. tostring(startTick) .. " ticksToWait=" .. tostring(ticksToWait))

                hook.Add("Think", "KC_KillNPCAtFrame", function()
                    if not KC_Playing() then
                        hook.Remove("Think", "KC_KillNPCAtFrame")
                        if IsValid(npcRef) then npcRef:Remove() end
                        return
                    end
                    local elapsed = KC_ServerTick() - startTick
                    if elapsed >= ticksToWait then
                        hook.Remove("Think", "KC_KillNPCAtFrame")
                        if not IsValid(npcRef) then return end
                        -- Notify client first: hitmarker + hide clientside model
                        -- (send before TakeDamageInfo in case the death animation
                        -- throws due to missing ACT_DIESIMPLE on the model)
                        if IsValid(plRef) then
                            -- Omit the killer (plRef) -- they already got their
                            -- own live KC_HitNotification (and XP) the instant
                            -- they made the kill, via sv_hitmarker.lua. The
                            -- killer isn't watching their own killcam replay
                            -- (KC_Playing() reads false on their client), so
                            -- broadcasting this to them too made their client
                            -- take the "not in killcam" branch again and award
                            -- the same kill's XP a second time (e.g. the
                            -- duplicate "+500" for an S&D kill).
                            net.Start("KC_HitNotification")
                                net.WriteBool(true)
                            net.SendOmit(plRef)
                            net.Start("Killcam - KillcamNPCKilled")
                            net.Broadcast()
                        end
                        -- Re-enable movement and normal collision so ragdoll works
                        npcRef:SetMoveType(MOVETYPE_STEP)
                        npcRef:SetCollisionGroup(COLLISION_GROUP_NONE)
                        -- Kill with damage so it ragdolls naturally
                        local ok, err = pcall(function()
                            local dmg = DamageInfo()
                            dmg:SetDamage(9999)
                            dmg:SetDamageType(DMG_BULLET)
                            dmg:SetDamageForce(Vector(0, 0, -100))
                            dmg:SetAttacker(game.GetWorld())
                            dmg:SetInflictor(game.GetWorld())
                            npcRef:TakeDamageInfo(dmg)
                        end)
                        if not ok then
                            print("[KC NPC] TakeDamageInfo error (non-fatal): " .. tostring(err))
                            -- Fallback: force ragdoll directly if damage call failed
                            if IsValid(npcRef) then
                                npcRef:SetHealth(0)
                                npcRef:Remove()
                            end
                        end
                        print("[KC NPC] NPC killed at tick=" .. KC_ServerTick() .. " killframe=" .. killframeID)
                    end
                end)
            end)
        end
        FFA_KillcamDeathPos = nil
        FFA_KillcamDeathAng = nil
        FFA_KillcamModel    = nil
    end

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            if ent:IsNPC() then
                -- Don't hide the live killcam NPC
                if ent.IsKillcamNPC then continue end
                if ent:EntIndex() ~= killID then
                    ent:SetNoDraw(true)
                    ent:SetNotSolid(true)
                    ent.KC_WasHidden = true
                end
            elseif ent:IsPlayer() and ent:IsBot() and ent.KC_RecordAsNPC then
                -- In sesh mode with live NPC, hide all bots (live NPC is the stand-in)
                -- In normal mode, hide all bots that aren't the kill target
                if _G.SeshBot_KillcamTriggered or not botKillID or ent:EntIndex() ~= botKillID then
                    ent:SetNoDraw(true)
                    ent:SetNotSolid(true)
                    ent.KC_WasHidden = true
                end
            elseif ent:GetClass() == "prop_ragdoll" then
                local owner = ent:GetOwner()
                if IsValid(owner) and owner:IsBot() then
                    ent:SetNoDraw(true)
                    ent.KC_WasHidden = true
                end
            end
        end
    end
end)

hook.Add("CreateEntityRagdoll", "Killcam - Get NPC ragdoll", function(owner, ent)
    if owner:IsNPC() then
        NPCRagdolls[#NPCRagdolls + 1] = ent
    end
    -- Hide bot ragdolls immediately — we use a citizen NPC for killcam display
    if owner:IsPlayer() and owner:IsBot() and _G.SeshBot_KillcamTriggered then
        ent:SetNoDraw(true)
        ent.KC_WasHidden = true
    end
end)

hook.Add("EntityRemoved", "Killcam - Remove removed NPCs", function(ent)
    if not KC_Playing() and ent:IsNPC() and ent:Health() > 0 and origNPCFrames[Killcam.Frames] then
        origNPCFrames[Killcam.Frames][ent.RecordID] = origNPCFrames[Killcam.Frames][ent.RecordID] or {}
        origNPCFrames[Killcam.Frames][ent.RecordID].removed = true
        npcs[ent.RecordID] = nil
    end
end)

hook.Add("EntityTakeDamage", "Killcam - Handle NPCs damage", function(ent, dmginfo)
    if KC_Playing() and ent:IsNPC() and not ent.KC_CanBeDamaged and not ent.IsKillcamNPC then
        return true
    end
end)

-- Remove all NPCs and killcam ragdolls when killcam ends or round starts
local KC_SpawnedRagdolls = KC_SpawnedRagdolls or {}

hook.Add("CreateEntityRagdoll", "Killcam - TrackKillcamRagdolls", function(owner, ent)
    if IsValid(owner) and owner.IsKillcamNPC then
        KC_SpawnedRagdolls[#KC_SpawnedRagdolls + 1] = ent
    end
end)

local function CleanupAllNPCs()
    timer.Remove("KC_KillcamNPCRemove")
    hook.Remove("Think", "KC_KillNPCAtFrame")
    -- Remove tracked killcam ragdolls
    for _, ent in ipairs(KC_SpawnedRagdolls) do
        if IsValid(ent) then ent:Remove() end
    end
    KC_SpawnedRagdolls = {}
    -- Remove any IsKillcamNPC entities
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) then
            if ent.IsKillcamNPC or ent:GetNW2Bool("IsKillcamNPC", false) then
                ent:Remove()
            end
        end
    end
    -- Clear global reference
    if IsValid(_G.FFA_KillcamNPC) then
        _G.FFA_KillcamNPC:Remove()
    end
    _G.FFA_KillcamNPC = nil
    -- Unhide any KC_WasHidden entities
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent.KC_WasHidden then
            ent:SetNoDraw(false)
            ent:SetNotSolid(false)
            ent.KC_WasHidden = nil
        end
    end
    NPCRagdolls = {}
end

hook.Add("KillcamReplayStopped", "Killcam - CleanupNPCsAfterKillcam", function()
    timer.Simple(0.5, CleanupAllNPCs)
end)

hook.Add("CoDHUD_RoundStart", "Killcam - CleanupNPCsOnRoundStart", function()
    CleanupAllNPCs()
    -- Remove ALL prop_ragdolls on round start (accumulated from previous rounds)
    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
            ent:Remove()
        end
    end
    for i = 1, #NPCRagdolls do
        local ent = NPCRagdolls[i]
        if IsValid(ent) then ent:Remove() end
    end
    NPCRagdolls = {}
end)