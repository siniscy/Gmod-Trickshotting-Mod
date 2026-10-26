-- killcam_codhud_integration.lua may load first (alphabetically before this
-- file) and already populate Killcam.BeginFor -- an unconditional {} here
-- would silently wipe that out, leaving BeginFor nil at call time.
Killcam = Killcam or {}
AddCSLuaFile("killcam_cfg.lua")
include("killcam_cfg.lua")

AddCSLuaFile("killcam_lang.lua")
include("killcam_lang.lua")

-- Shared files first (the archive codec/timeline everything else uses),
-- then the realm-specific ones.
local path = "killcam/"
local files = file.Find(path .. "*.lua", "LUA")
table.sort(files)

for _, f in ipairs(files) do
    if f:sub(1, 3) == "sh_" then
        AddCSLuaFile(path .. f)
        include(path .. f)
    end
end

for _, f in ipairs(files) do
    local typ = f:sub(1, 3)
    if typ == "sv_" then
        if SERVER then include(path .. f) end
    elseif typ == "cl_" then
        if SERVER then
            AddCSLuaFile(path .. f)
        else
            include(path .. f)
        end
    end
end
