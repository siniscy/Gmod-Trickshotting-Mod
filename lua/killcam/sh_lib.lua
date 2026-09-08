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
    if KC_GetKiller() == pl then return true end
    -- Fallback for the same networking gap KC_Playing() already works
    -- around: Killcam_Killer (a networked global entity) is set in the
    -- exact same server call as Killcam_Playing (OnKillcamReplayStart),
    -- and is subject to the identical delivery delay/loss to a given
    -- client -- confirmed via logs showing Killcam_Playing(global)=false
    -- still printing at the moment KC_Playing() already reads true.
    -- cl_main.lua's StartCommand hook uses KC_isKiller(pl) to decide
    -- whether THIS client should apply the recorded replay data
    -- (position/angle/weapon) to its own view during killcam -- if this
    -- read false while Killcam_Killer was still in flight, the killer's
    -- own camera never got the replayed angles (looked frozen facing
    -- one direction) and the server's forced reload animation fought
    -- against normal, unsuppressed client prediction (reload not
    -- visibly showing). _G.KC_ClientReplaying is only ever true on the
    -- actual killer's own client (only the killer receives "Killcam -
    -- NPC Frames"), so if it's set and pl is us, we ARE the killer
    -- regardless of whether Killcam_Killer itself has arrived yet.
    if CLIENT and pl == LocalPlayer() and _G.KC_ClientReplaying then return true end
    return false
end