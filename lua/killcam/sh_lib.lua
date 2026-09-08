--[[
    Different stuff
]]

function Killcam.CopyTable(tbl)
    --return util.JSONToTable(util.TableToJSON(tbl)) -- Shitty way to copy vectors and angles

    if not tbl then return nil end
    
    local res = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            res[k] = Killcam.CopyTable(v) // recursion ho!
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

function KC_Playing()
    if GetGlobalBool("Killcam_Playing") then return true end
    -- Fallback: Killcam_Playing (a networked global) has been observed
    -- to consistently fail to reach a real remote client's killer-side
    -- connection on some rounds (confirmed via a raw diagnostic showing
    -- it never flipped true on that client for that round, even though
    -- it stayed true for 15+ seconds on the server/host) -- stuck
    -- greyscale + no killcam UI is the visible result. _G.KC_ClientReplaying
    -- (cl_npcreplay.lua) is a SEPARATE, independently-set flag that goes
    -- true the instant "Killcam - NPC Frames" arrives -- a message that,
    -- per the same logs, reliably arrives every round for the killer
    -- even when Killcam_Playing itself doesn't. Only ever true on
    -- CLIENT (nil on server), so this is safe to check unconditionally.
    if _G.KC_ClientReplaying then return true end
    return false
end

function KC_ServerTick()
    return GetGlobalInt("Killcam_ServerTick")
end

function KC_GetKiller()
    return GetGlobalEntity("Killcam_Killer")
end

function KC_isKiller(pl)
    return KC_GetKiller() and KC_GetKiller() == pl or false
end