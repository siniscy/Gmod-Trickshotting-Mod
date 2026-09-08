local statedata = {"_pos","_angle", "weapon", "ammo"}

function Killcam.NewRecorder()

local recObj = {frames = {}, kc_frames = {}, replay_frames = {}, plys_frames = {}, state = {}, KillSaved = true, SaveTimeout = 0}

function recObj:Attach(pl)
    self.pl = pl
end

function recObj:GetFrame(id)
    return self.frames[id]
end

function recObj:GetCurrentFrame()
    return self:GetFrame(Killcam.Frames)
end

function recObj:CaptureFrame(cmd)
    if self.pl:Alive() then
        self.frames[Killcam.Frames] = Killcam.CollectData(self.pl, cmd)
        self:PerformKillCamSave()
    else
        self.frames[Killcam.Frames].dead = true
    end
    for i = 1, Killcam.Frames - 1 do
        self.frames[i] = self.frames[i + 1]
    end
end

function recObj:SetKill(npc)
    self:GetCurrentFrame().kill = npc:EntIndex()
    -- How long recording keeps running AFTER the kill before the buffer is
    -- frozen for replay -- this is the hard ceiling on how much "after the
    -- kill" footage killcam can ever show (the recorded buffer is a fixed
    -- ~10s window total; whatever isn't spent after the kill is spent
    -- rewound before it). 1s wasn't enough for a reload's animation/sound
    -- to finish recording at all, so playback always ran out of buffer and
    -- ended mid-reload -- which is what actually cut the killcam short,
    -- not anything about round/match transitions. 3s comfortably covers a
    -- normal reload. (A timer-based reload grace window used to also need
    -- extra runway here, but that mechanism is gone -- see sh_replaydata.lua
    -- -- so 3s no longer needs to cover a full reload animation, just
    -- normal post-kill footage.)
    self.SaveTimeout = CurTime() + 3
    self.KillSaved = false
end

function recObj:PerformKillCamSave()
    if !self.KillSaved and CurTime() > self.SaveTimeout then
        self.KillSaved = true
        self:SaveFrames()
        Killcam.SaveNPCData(self.pl)
    end
end

function recObj:TimeRemaining()
    if not self.killframeID then return 0 end
    local killFrame = self.replay_frames[self.killframeID]
    local curFrame  = self.replay_frames[KC_ServerTick()]
    if not killFrame or not curFrame then return 0 end
    return math.Clamp(killFrame.time - curFrame.time, 0, 100)
end

-- TimeRemaining() clamps at 0 and stays there for every frame at or after
-- the kill, so it can't tell the difference between "just hit the shot"
-- and "several seconds into the post-kill footage" -- which is why the
-- slow-mo triggered by TimeRemaining() < 0.5 used to hold all the way
-- through the reload instead of just the moment of impact. This is the
-- unclamped mirror of it: 0 up to the kill, then counts UP afterward.
function recObj:TimeSinceKill()
    if not self.killframeID then return 0 end
    local killFrame = self.replay_frames[self.killframeID]
    local curFrame  = self.replay_frames[KC_ServerTick()]
    if not killFrame or not curFrame then return 0 end
    return math.max(0, curFrame.time - killFrame.time)
end

function recObj:SetReplayFrames(pl_killer)
    if self.pl == pl_killer then 
        self.replay_frames = Killcam.CopyTable(self.kc_frames) 
        for i = 1, #self.replay_frames do
            if self.replay_frames[i].kill then
                self.killframeID = i
            end
        end
        -- Override the angle on frame 1 to match the kill frame angle,
        -- so the player starts facing the right direction instead of
        -- whatever direction they were facing 10 seconds ago.
        if self.killframeID and self.replay_frames[self.killframeID] then
            local killAngle = self.replay_frames[self.killframeID].angle
            if killAngle then
                self.replay_frames[1].angle = killAngle
            end
        end
        return
    end
    self.replay_frames = Killcam.CopyTable(pl_killer.KC_Recorder.plys_frames[self.pl:EntIndex()])
end

function recObj:SaveFrames()
    self.kc_frames = Killcam.CopyTable(self.frames)
    for _,v in pairs(player.GetAll()) do
        if v.KC_Recorder then
            self.plys_frames[v:EntIndex()] = Killcam.CopyTable(v.KC_Recorder.frames)
        end
    end
end

function recObj:SaveState()
    self.state = Killcam.CollectData(self.pl, nil, statedata)
end

function recObj:RestoreState()
    Killcam.SetData(self.pl, nil, self.state)
    self.pl:SetLocalVelocity(Vector())
end

function recObj:PlayFrame(cmd)
    if self.replay_frames.dead then return end
    if SERVER and !self.pl:Alive() then
        self.pl:Spawn()
    end
    for i = KC_ServerTick(), #self.replay_frames do
        if self.replay_frames[i].kill then
            self.killframeID = i
        end
    end
    Killcam.SetData(self.pl, cmd, self.replay_frames[KC_ServerTick()])
end

    return recObj
end