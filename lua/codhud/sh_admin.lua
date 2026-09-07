---- [ SHARED CONVARS & FRIENDLY FIRE ] ----

CreateConVar("codhud_score_limit", "75", {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets the score limit for the HUD, measured in kills.")

-- Hardwired -- a saved/drifted archive value must not be able to change the score limit.
-- Only SERVER needs to force this; the REPLICATED flag pushes the corrected value to clients.
if SERVER then
    GetConVar("codhud_score_limit"):SetInt(75)
end

CreateConVar("codhud_time_limit", "10", {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets the match time limit, measured in minutes.")
CreateConVar("codhud_matchstart_timer", "10", {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Sets the match start timer.")
CreateConVar("codhud_friendly_fire", "0", {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "If 0, players on the same faction cannot damage each other.")

-- The following were previously created only in "sv_" files under lua/codhud/, which that
-- folder's loader (lua/autorun/codhud_init.lua) only includes on SERVER. A client-only-realm
-- convar with FCVAR_REPLICATED does NOT get a value pushed to it if the client never created
-- a local copy of that convar name -- GetConVar() returns nil for every non-host client,
-- permanently, not just briefly. Moved here (a shared "sh_" file, included on both realms)
-- so every client actually has a local convar object for the replicated value to land in.
-- This was the root cause of non-host scoreboard/XP-popup breakage and console errors.
CreateConVar( "codhud_selected_gamemode", "war", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Which gamemode to start the round on." )
CreateConVar( "codhud_autobalance_on_roundstart", "0", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "If enabled, rebalances all factions at the start of each round." )
CreateConVar("codhud_autofaction_limit", "2", { FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED }, "Max number of active factions before enforcing auto-balance.")
CreateConVar("codhud_restrictfactions", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Restrict when players can change factions: 0 = disabled, 1 = free, 2 = pool only")
CreateConVar("codhud_enable_roundend", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Enable or disable the MW2 round end screen.")
CreateConVar("codhud_enable_roundend_startnext", "1", {FCVAR_ARCHIVE, FCVAR_NOTIFY, FCVAR_REPLICATED}, "Immediately starts a new 'Round' once the current one ends.")

if SERVER then
    hook.Add("PlayerShouldTakeDamage", "CoDHUD_FactionFriendlyFire", function(victim, attacker)
        if GetConVar("codhud_friendly_fire"):GetBool() then return end
        if not IsValid(attacker) or not attacker:IsPlayer() then return end
        if victim == attacker then return end

        if victim:GetNW2String("CoDHUD_Faction", "rangers") == attacker:GetNW2String("CoDHUD_Faction", "rangers") then
            return false
        end
    end)
end

CreateConVar("codhud_game", "mw2", {FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY}, "Which CoD game factions and UI should utilize.")

-- Mirrors sv_roundstart.lua's IsHostOrAdmin() -- the listen-server host
-- should always be able to use game-setup controls (HUD/game type, timers,
-- fast-last) on every map, regardless of a separate admin mod's per-map
-- IsAdmin() state. Third fallback: sole real human connected counts as
-- host too, so this never depends on IsListenServerHost()/IsAdmin()
-- actually succeeding.
local function IsHostOrAdmin(ply)
    if not IsValid(ply) then return false end
    if ply:IsListenServerHost() or ply:IsAdmin() then return true end
    local realPlayers = 0
    for _, p in ipairs(player.GetAll()) do
        if IsValid(p) and not p:IsBot() then realPlayers = realPlayers + 1 end
    end
    return realPlayers <= 1
end

if SERVER then
	util.AddNetworkString("CoDHUD_SetGame")

	net.Receive("CoDHUD_SetGame", function(len, ply)
		if not IsHostOrAdmin(ply) then return end

		local game = net.ReadString()

		if CoDHUD_RoundStarting or CoDHUD_RoundEnding then
			print("[CoDHUD] Blocked game change!")
			net.Start("CoDHUD_KillfeedMessage")
			net.WriteString("CoDHUD.System.RestrictType.NotNow")
			net.Send(ply)
			return
		end

		RunConsoleCommand("codhud_game", game)
	end)
end

if SERVER then
    util.AddNetworkString("CoDHUD_SetConVar")

    local editableConVars = {
        codhud_enable_roundend = true,
        codhud_enable_roundend_startnext = true,
        codhud_friendly_fire = true,
        codhud_score_limit = true,
        codhud_time_limit = true,
        codhud_matchstart_timer = true,
        codhud_autobalance_on_roundstart = true,
        codhud_restrictfactions = true,
        codhud_selected_gamemode = true,
        codhud_autofaction_limit = true,
        kc_fastlast_enabled = true
    }

    net.Receive("CoDHUD_SetConVar", function(_, ply)
        if not IsHostOrAdmin(ply) then return end

        local cvar = net.ReadString()
        local value = net.ReadString()

        if not editableConVars[cvar] then return end

        local cv = GetConVar(cvar)
        if not cv then return end

		-- local valtext = cv:GetBool() and "CoDHUD.System.Disabled" or "CoDHUD.System.Enabled"

		net.Start("CoDHUD_KillfeedMessage")
			net.WriteString("CoDHUD.System.CVChanged")
			net.WriteString(cvar)
			net.WriteString(value)
		net.Broadcast()
		
        RunConsoleCommand(cvar, value)
    end)
end

function CoDHUD_SetServerConVar(cvar, value)
    net.Start("CoDHUD_SetConVar")
        net.WriteString(cvar)
        net.WriteString(tostring(value))
    net.SendToServer()
end