---- [ SESH TEAM SYSTEM — TDM (sesh_war) & SND (sesh_sd) ] ----
-- Handles: team score tracking, round tracking, win conditions, net broadcasts
-- Player is always Team A (friendly), all bots are Team B (enemy)

-- ConVars live in sh_sesh_convars.lua now -- this addon's loader
-- (codhud_init.lua) only ever include()s "sv_"-prefixed files when
-- SERVER is true, so moving the CreateConVar calls above this guard
-- (a fix tried first) did nothing: the client never executes this
-- file's Lua at all, guard or no guard. A real shared ("sh_") file is
-- required so both realms actually run the CreateConVar calls.

if not SERVER then return end

util.AddNetworkString("Sesh_TeamScores")   -- sends scoreA, scoreB, limitA, limitB to all
util.AddNetworkString("Sesh_RoundResult")  -- sends winner string + round counts to all

-- State
_G.SeshTeam = _G.SeshTeam or {}
local ST = _G.SeshTeam

function ST.Reset()
    ST.scoreA      = 0   -- player team score
    ST.scoreB      = 0   -- bot team score
    ST.roundsA     = 0   -- snd rounds won by player team
    ST.roundsB     = 0   -- snd rounds won by bot team
    ST.roundActive = false
    ST.gameOver    = false
    ST.BroadcastScores()
end

function ST.BroadcastScores()
    local gm = GetConVar("codhud_selected_gamemode"):GetString()
    local limitA, limitB
    if gm == "sesh_war" then
        local lim = GetConVar("sesh_war_limit"):GetInt()
        limitA, limitB = lim, lim
        -- Neither bots' nor real players' Frags() are touched here anymore.
        -- sv_ffa_bots.lua now maintains each bot's own individual kill count
        -- (FFA_Bots[bot].kills, mirroring what S&D already did) exactly the
        -- same way it already maintains each human's personal kill count via
        -- FFA_AddKill(). Summing Frags() across a faction (which every
        -- scoreboard/skin already does) then naturally produces the correct
        -- team total on its own. This used to instead dump the WHOLE team
        -- score onto a single arbitrary bot and zero the rest, purely to
        -- make that same sum come out right -- which meant every kill in the
        -- tab scoreboard looked like it was credited to one bot no matter
        -- who actually got it.
    elseif gm == "sesh_sd" or gm == "sesh_sd_set" then
        local lim = GetConVar("sesh_sd_rounds"):GetInt()
        limitA, limitB = lim, lim
        -- For sesh_sd the scorebar reads KC_SD_SeshRoundsA/B from the net
        -- message below — we do NOT set p:Frags() here because that would
        -- show round wins as kill counts in the killfeed and HUD kill display.
    else
        limitA, limitB = 0, 0
    end
    net.Start("Sesh_TeamScores")
        net.WriteInt(ST.scoreA,  16)
        net.WriteInt(ST.scoreB,  16)
        net.WriteInt(limitA,     16)
        net.WriteInt(limitB,     16)
        net.WriteInt(ST.roundsA, 8)
        net.WriteInt(ST.roundsB, 8)
    net.Broadcast()
end

-- Called by sv_ffa_bots when a player kills a bot (TDM: player team scores)
function ST.OnPlayerKilledBot(attacker)
    local gm = GetConVar("codhud_selected_gamemode"):GetString()
    if gm == "sesh_war" then
        ST.scoreA = ST.scoreA + 1
        ST.BroadcastScores()
        local lim = GetConVar("sesh_war_limit"):GetInt()
        if ST.scoreA >= lim and not ST.gameOver then
            ST.gameOver = true
            ST.BroadcastRoundResult("A")
        end
    end
end

-- Called by sv_ffa_bots when a bot kills the player (TDM: bot team scores)
function ST.OnBotKilledPlayer(victim)
    local gm = GetConVar("codhud_selected_gamemode"):GetString()
    if gm == "sesh_war" then
        ST.scoreB = ST.scoreB + 1
        ST.BroadcastScores()
        local lim = GetConVar("sesh_war_limit"):GetInt()
        if ST.scoreB >= lim and not ST.gameOver then
            ST.gameOver = true
            ST.BroadcastRoundResult("B")
        end
    end
end

-- Called by sv_sesh_sd for round end
function ST.OnSndRoundEnd(winner, alreadyCounted)
    -- winner = "A" (player team) or "B" (bot team). alreadyCounted: the win
    -- was added to the score the moment the round ended (so the scorebar
    -- updates right away, like CoD), only the rest happens here.
    if not alreadyCounted then
        if winner == "A" then ST.roundsA = ST.roundsA + 1
        else ST.roundsB = ST.roundsB + 1 end
    end
    local lim     = GetConVar("sesh_sd_rounds"):GetInt()
    local maxRounds = GetConVar("sesh_sd_maxrounds"):GetInt()
    local totalRounds = ST.roundsA + ST.roundsB
    ST.BroadcastScores()

    local matchDone = false
    if ST.roundsA >= lim and not ST.gameOver then
        ST.gameOver = true
        ST.BroadcastRoundResult("A")
        matchDone = true
    elseif ST.roundsB >= lim and not ST.gameOver then
        ST.gameOver = true
        ST.BroadcastRoundResult("B")
        matchDone = true
    elseif totalRounds >= maxRounds and not ST.gameOver then
        -- Hard cap: end match, whoever has more rounds wins
        ST.gameOver = true
        local finalWinner = (ST.roundsA >= ST.roundsB) and "A" or "B"
        ST.BroadcastRoundResult(finalWinner)
        matchDone = true
    end

    if not matchDone then
        -- next round
        timer.Simple(3, function()
            if _G.SeshBot_ResetRound then _G.SeshBot_ResetRound() end
        end)
    end
end

function ST.BroadcastRoundResult(winner)
    net.Start("Sesh_RoundResult")
        net.WriteString(winner)      -- "A" or "B"
        net.WriteInt(ST.roundsA, 8)
        net.WriteInt(ST.roundsB, 8)
    net.Broadcast()
end

ST.Reset()