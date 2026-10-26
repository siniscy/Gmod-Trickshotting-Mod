--[[
    Shared helpers used across the addon (HUD, announcer, crosshair, round
    flow). The killcam itself lives in sh_archive / sv_archive / sv_main /
    cl_povrecord / cl_replay.
]]

function Killcam.CopyTable(tbl)
    if not tbl then return nil end

    local res = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            res[k] = Killcam.CopyTable(v)
        elseif type(v) == "Vector" then
            res[k] = Vector(v.x, v.y, v.z)
        elseif type(v) == "Angle" then
            res[k] = Angle(v.p, v.y, v.r)
        else
            res[k] = v
        end
    end

    return res
end

-- Is a killcam on screen?
--   Server: the replay is running for everyone (the round flow waits on this).
--   Client: this client is showing the replay (or holding the black screen
--           while its copy of the recording finishes downloading).
function KC_Playing()
    if CLIENT then
        return Killcam.Replay ~= nil and Killcam.Replay.IsActive() or false
    end
    return GetGlobalBool("Killcam_Playing")
end

function KC_GetKiller()
    return GetGlobalEntity("Killcam_Killer")
end

function KC_isKiller(pl)
    return IsValid(pl) and KC_GetKiller() == pl
end

-- Legacy: the old killcam stepped a networked tick counter. Kept so any
-- external caller doesn't error.
function KC_ServerTick()
    return 0
end
