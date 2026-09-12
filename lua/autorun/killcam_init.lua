--if true then return end
-- killcam_codhud_integration.lua may load first (alphabetically before this
-- file) and already populate Killcam.BeginFor -- an unconditional {} here
-- would silently wipe that out, leaving BeginFor nil at call time.
Killcam = Killcam or {}
AddCSLuaFile("killcam_cfg.lua")
include("killcam_cfg.lua")

AddCSLuaFile("killcam_lang.lua")
include("killcam_lang.lua")

if SERVER then
    Killcam.Frames = math.ceil((Killcam.CFG.RecordingTime or 10) * GetConVar("sv_maxcmdrate"):GetInt() + 0.5)
    -- Stop playback slightly before the buffer's actual end, so killcam
    -- wraps up a bit sooner instead of always running the full recorded window.
    Killcam.EndEarlyFrames = math.ceil(2 * GetConVar("sv_maxcmdrate"):GetInt())
end

local path = "killcam/"
for _, f in pairs(file.Find(path.."*", "LUA")) do
    local typ = f:sub(1,2)
    if typ == "cl" then
        AddCSLuaFile(path .. f)
        if CLIENT then
            include(path .. f)
        end
    elseif typ == "sv" then
        include(path .. f)
    elseif typ == "sh" then
        AddCSLuaFile(path .. f)
        include(path .. f)
    end
end