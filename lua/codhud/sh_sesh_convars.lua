---- [ SESH TEAM SYSTEM CONVARS ] ----
-- Split out of sv_sesh_teams.lua into a shared ("sh_") file so these
-- actually get created in BOTH realms. codhud_init.lua's loader only
-- ever include()s "sv_"-prefixed files when SERVER is true -- an
-- "sv_" file being FCVAR_REPLICATED-flagged doesn't matter if the
-- client never executes CreateConVar for it in the first place.
-- Confirmed via a live diagnostic: sesh_sd_rounds read as nil on a
-- real remote client for a whole match (vs. correctly 3 on the
-- listen-server host, which only "worked" because it's the same
-- process as the server) -- the client-side round-bar fill code divides
-- by this value, so it never filled correctly for anyone but the host.
CreateConVar("sesh_war_limit",   "75",  FCVAR_ARCHIVE, "Kill limit for sesh TDM")
CreateConVar("sesh_sd_rounds",   "4",   {FCVAR_ARCHIVE, FCVAR_REPLICATED}, "Rounds needed to win sesh SND (first to X)")
CreateConVar("sesh_sd_maxrounds","7",   FCVAR_ARCHIVE, "Hard round cap for sesh SND — match ends after this many rounds regardless")

if SERVER then
    -- Hardwired -- a saved/drifted archive value must not be able to
    -- change the TDM win limit. Kept in this same file (not
    -- sv_sesh_teams.lua) so it can't run before the CreateConVar above
    -- it regardless of file load order.
    GetConVar("sesh_war_limit"):SetInt(75)

    -- Same protection for S&D's round-win target. A live match was
    -- observed ending at round 3 instead of 4 because this convar had
    -- drifted to "3" from earlier testing (FCVAR_ARCHIVE persists
    -- whatever it was last set to, across map changes and restarts,
    -- overriding the "4" in CreateConVar above). A first-time host
    -- should never have to manually run a console command just to get
    -- the mode's correct win condition -- hardwire it the same way.
    GetConVar("sesh_sd_rounds"):SetInt(4)

    -- Same drift bug, same fix, for the hard round cap. sesh_sd_maxrounds
    -- is also FCVAR_ARCHIVE, so a leftover "4" from earlier testing (e.g.
    -- someone temporarily lowering it to test the win condition above)
    -- persists across map changes/restarts and silently overrides the "7"
    -- in CreateConVar above. Since ST.OnSndRoundEnd treats totalRounds >=
    -- maxRounds as "match over, whoever has more rounds wins" -- with
    -- maxrounds stuck at 4 the match ends the moment 4 rounds have been
    -- PLAYED (e.g. a 2-2 split), instead of requiring a team to actually
    -- WIN sesh_sd_rounds (4) rounds. Hardwire it back to 7 every boot.
    GetConVar("sesh_sd_maxrounds"):SetInt(7)
end
