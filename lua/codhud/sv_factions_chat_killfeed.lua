---- [ SERVER FACTIONS, CHAT & KILLFEED ] ----
CoDHUD = CoDHUD or {}
CoDHUD.Factions = CoDHUD.Factions or {}

util.AddNetworkString("CoDHUD_ChatMessage")
util.AddNetworkString("CoDHUD_KillfeedMessage")
util.AddNetworkString("CoDHUD_PlayerChangeTeam")
util.AddNetworkString("CoDHUD_PlayerAutoBalanced")
util.AddNetworkString("CoDHUD_RestrictFactionsSync")

-- codhud_autofaction_limit / codhud_restrictfactions are created in sh_admin.lua (shared realm)

-- [[ 1. FACTION RELATED ]]
-- Faction Name Mapping
CoDHUD.Factions.validfactions = {
	["cod4"] = {
		["marines"]			= "Marine Force Recon",
		["sas"]				= "S.A.S.",
		["ussr"]			= "Spetsnaz",
		["arab"]			= "OpFor",
	},
	["waw"] = {
		["american"]		= "Marine Raiders",
		["soviet"]			= "Red Army",
		["german"]			= "Wehrmacht",
		["japan"]			= "Imperial Army",
	},
	["mw2"] = {
		["rangers"]			= "Army Rangers",
		["taskforce141"]	= "Task Force 141",
		["seals"]			= "Navy SEALs",
		["ussr"]			= "Spetsnaz",
		["arab"]			= "OpFor",
		["militia"]			= "Militia"
	},
	["bo1"] = {
		["op4"]			= "Op 40",
		["ops"]			= "Black Ops",
		["sog"]			= "SOG",
		["rus"]			= "Spetsnaz",
		["nva"]			= "NVA",
		["cub"]			= "Tropas",
	},
	["bo2"] = {
		["seals"]		= "Navy SEALs",
		["sdc"]			= "SDC",
		["fbi"]			= "F.B.I.",
		["pmc"]			= "Mercs",
		["isa"]			= "I.S.A.",
		["cd"]			= "Militia",
	},
	["mw3"] = {
		["sas"]				= "Special Air Service",
		["delta"]			= "Delta Force",
		["gign"]			= "GIGN",
		["innercircle"]		= "Inner Circle",
		["militia"]			= "Africa Militia",
		["ussr"]			= "Spetsnaz",
		["pmc"]				= "P.M.C."
	},
}

-- Phrase keys for the faction display names broadcast below -- kept
-- separate from CoDHUD.Factions[hudtype][id].name (set in games/*.lua),
-- since that field is read as a resolved display string in many other
-- client files (cl_settings.lua, cl_roundend.lua, cl_header_mw.lua, etc.)
-- and changing its meaning there is out of scope. cl_killfeed.lua's
-- CoDHUD_PlayerAutoBalanced receiver already calls language.GetPhrase() on
-- whatever string arrives as the faction name (line ~112) -- it was built
-- to take a phrase key, it just never got one before now, so every
-- faction name silently rendered as the English literal in every language.
local FACTION_NAME_KEYS = {
	cod4 = { marines = "CoD4_MPUI_MARINES", sas = "CoD4_MPUI_SAS", ussr = "CoD4_MPUI_SPETSNAZ", arab = "CoD4_MPUI_OPFOR" },
	waw  = { american = "WAW_MPUI_MARINE", soviet = "WAW_MPUI_RUSSIAN", german = "WAW_MPUI_GERMAN", japan = "WAW_MPUI_JAPANESE" },
	mw2  = { rangers = "MW2_MP_US_ARMY_NAME", taskforce141 = "MW2_MP_TASKFORCE_NAME", seals = "MW2_MP_SEALS_UDT_NAME", ussr = "MW2_MP_SPETSNAZ_NAME", arab = "MW2_MP_OPFOR_NAME", militia = "MW2_MP_MILITIA_NAME" },
	bo1  = { op4 = "BO1_MP_REBELS_NAME", ops = "BO1_MP_SPECOPS_NAME", sog = "BO1_MP_MARINE_NAME", rus = "BO1_MP_RUSSIAN_NAME", nva = "BO1_MP_NVA_NAME", cub = "BO1_MP_TROPAS_NAME" },
	bo2  = { seals = "BO2_MP_SEALS_NAME", sdc = "BO2_MP_PLA_NAME", fbi = "BO2_MP_FBI_NAME", pmc = "BO2_MP_PMC_NAME", isa = "BO2_MP_ISA_NAME", cd = "BO2_MP_CD_NAME" },
	mw3  = { sas = "MW3_MP_SAS", delta = "MW3_MP_DELTA_NAME", gign = "MW3_MP_GIGN", innercircle = "MW3_MP_INNERCIRCLE_NAME", militia = "MW3_MP_AFRICA_MILITIA_NAME", ussr = "MW3_MP_SPETSNAZ_NAME", pmc = "MW3_MP_PMC_NAME" },
}

function CoDHUD.Factions.GetFactionNameKey(hudtype, factionID)
	local t = FACTION_NAME_KEYS[hudtype]
	return (t and t[factionID]) or "MW2_MP_US_ARMY_NAME"
end

function CoDHUD.Factions.GetFactionName(factionID)
	local c = GetConVar("codhud_game")
	c = c and c:GetString() or "mw2"
	
    local factionTable = CoDHUD.Factions.validfactions[c]

    if not factionTable then
        factionTable = CoDHUD.Factions.validfactions["mw2"] -- fallback
    end

    return factionTable[factionID]
end

cvars.AddChangeCallback("codhud_game", function(convar, oldValue, newValue)
    print("[CoDHUD] Game changed from " .. oldValue .. " to " .. newValue)

	net.Start("CoDHUD_KillfeedMessage")
	net.WriteString("CoDHUD.System.RestrictType")
	net.WriteString("CoDHUD.Type." .. newValue)
	net.Broadcast()

    if not CoDHUD.Factions.validfactions[newValue] then
        newValue = "mw2"
    end

    local players = player.GetAll()

    if GetConVar("codhud_autobalance_on_roundstart"):GetBool() then
        CoDHUD.Factions.RebuildPool()

        local counts = {}
        table.Shuffle(players)

        for _, ply in ipairs(players) do
            -- Sesh bots' faction is exclusively owned by sv_ffa_bots.lua --
            -- never let this generic human-team-balancing pool touch them,
            -- or a bot can land on the player's own team and merge the
            -- scoreboard into one group.
            if IsValid(ply) and not ply:IsBot() then
                local faction = CoDHUD.Factions.PickFromPool(counts)

                counts[faction] = (counts[faction] or 0) + 1

                ply.CoDHUD_StoredFaction = faction
                ply:SetNW2String("CoDHUD_Faction", faction)

				local textstr = "MW2_GAME_CHANGEDTO"
				local factionName = CoDHUD.Factions.GetFactionNameKey(CoDHUD_GetHUDType(), faction)

				net.Start("CoDHUD_PlayerAutoBalanced")
				net.WriteString(textstr)
				net.WriteString(ply:Nick())
				net.WriteString(factionName)
				net.Broadcast()

                print("[CoDHUD] (Game Change) " .. ply:Nick() .. " -> " .. faction)
            end
        end
    else
        local factionTable = CoDHUD.Factions.validfactions[newValue]

        for _, ply in ipairs(players) do
            -- Same bot exclusion as the autobalance branch above.
            if IsValid(ply) and not ply:IsBot() then
                local faction = CoDHUD.Factions.PickBestFaction(factionTable)

                ply.CoDHUD_StoredFaction = faction
                ply:SetNW2String("CoDHUD_Faction", faction)

				local textstr = "MW2_GAME_CHANGEDTO"
				local factionName = CoDHUD.Factions.GetFactionNameKey(CoDHUD_GetHUDType(), faction)

				net.Start("CoDHUD_PlayerAutoBalanced")
				net.WriteString(textstr)
				net.WriteString(ply:Nick())
				net.WriteString(factionName)
				net.Broadcast()

                print("[CoDHUD] (Game Change) " .. ply:Nick() .. " -> " .. faction)
            end
        end
    end

    timer.Simple(0.1, function()
        for _, ply in ipairs(players) do
            if IsValid(ply) then
                ply:SetFrags(0)
                ply:SetDeaths(0)

                if ply:Alive() then
                    ply:KillSilent()
                end

                ply:Spawn()
            end
        end
    end)
end, "CoDHUD_GameChangeCallback")

concommand.Add("codhud_setfaction", function(ply, cmd, args)
    if not IsValid(ply) then return end
    
    local faction = args[1] and string.lower(args[1]) or nil

	if faction and CoDHUD.Factions.GetFactionName(faction) then
		-- manual selection overrides everything
	else
		local game = GetConVar("codhud_game"):GetString()
		local factionTable = CoDHUD.Factions.validfactions[game] or CoDHUD.Factions.validfactions["mw2"]

		faction = CoDHUD.Factions.PickBestFaction(factionTable)
	end
    
    -- Validate that it is a real faction
    if not CoDHUD.Factions.GetFactionName(faction) then faction = "rangers" end

    -- Store it in the player object so it survives through the session
    ply.CoDHUD_StoredFaction = faction
    
    -- Update the networked string so the HUD and Scoreboard see it
    ply:SetNW2String("CoDHUD_Faction", faction)
    
	local textstr = "MW2_GAME_CHANGEDTO"
	local factionName = CoDHUD.Factions.GetFactionNameKey(CoDHUD_GetHUDType(), faction)

	if factionName ~= "" then
		net.Start("CoDHUD_PlayerAutoBalanced")
		net.WriteString(textstr)
		net.WriteString(ply:Nick())
		net.WriteString(factionName)
		net.Broadcast()
	end
	
    print("[CoDHUD] Player " .. ply:Nick() .. " joined team " .. CoDHUD.Factions.GetFactionName(faction))
end)

function CoDHUD.Factions.CanPlayerChooseFaction(ply, faction)
    local mode = GetConVar("codhud_restrictfactions"):GetInt()

	if CoDHUD_RoundStarting or CoDHUD_RoundEnding then return false end

    -- 0 = cannot change
    if mode == 0 then
        return false
    end

    -- 1 = free
    if mode == 1 then
        return true
    end

    -- 2 = only from pool
    if mode == 2 then
        local pool = CoDHUD.Factions.ActivePool or {}
        return table.HasValue(pool, faction)
    end

    return true
end

function CoDHUD.Factions.GetFactionCounts()
    local counts = {}

    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) then
            local f = ply:GetNW2String("CoDHUD_Faction", "rangers")
            counts[f] = (counts[f] or 0) + 1
        end
    end

    return counts
end

function CoDHUD.Factions.BuildFactionPool(factionTable)
    local limit = GetConVar("codhud_autofaction_limit"):GetInt()
    local game = GetConVar("codhud_game"):GetString()

    local all = {}
    for k, _ in pairs(factionTable) do
        table.insert(all, k)
    end

    table.Shuffle(all)

    local pool = {}

    if limit <= 0 or limit >= #all then
        return all -- no restriction
    end

    for i = 1, limit do
        table.insert(pool, all[i])
    end

    return pool
end

function CoDHUD.Factions.RebuildPool()
    local game = GetConVar("codhud_game"):GetString()
	local factionTable = CoDHUD.Factions.validfactions[game] or CoDHUD.Factions.validfactions["mw2"]
    
    CoDHUD.Factions.ActivePool = CoDHUD.Factions.BuildFactionPool(factionTable)

    print("[CoDHUD] Active faction pool:")
    PrintTable(CoDHUD.Factions.ActivePool)
end

hook.Add("Initialize", "CoDHUD_InitPool", function()
    timer.Simple(0.1, function()
        CoDHUD.Factions.RebuildPool()
    end)
end)

function CoDHUD.Factions.IsTwoFactionMode()
    local pool = CoDHUD.Factions.ActivePool
    return pool and #pool == 2
end

function CoDHUD.Factions.GetTwoFactionMap()
    local pool = CoDHUD.Factions.ActivePool
    if not pool or #pool ~= 2 then return nil end

    return {
        [pool[1]] = 1,
        [pool[2]] = 2
    }
end

function CoDHUD.Factions.PickBestFaction(factionTable)
    local counts = CoDHUD.Factions.GetFactionCounts()

    local limit = GetConVar("codhud_autofaction_limit"):GetInt()

    local factions = {}
    for k, _ in pairs(factionTable) do
        table.insert(factions, k)
    end

    local activeFactionCount = 0
    for _, c in pairs(counts) do
        if c > 0 then activeFactionCount = activeFactionCount + 1 end
    end

    if limit > 0 and activeFactionCount < limit then
        return factions[math.random(#factions)]
    end

    local lowestCount = math.huge
    local best = {}

    for _, f in ipairs(factions) do
        local c = counts[f] or 0

        if c < lowestCount then
            lowestCount = c
            best = { f }
        elseif c == lowestCount then
            table.insert(best, f)
        end
    end

    return best[math.random(#best)]
end

function CoDHUD.Factions.PickFromPool(counts)
    local pool = CoDHUD.Factions.ActivePool
    if not pool or #pool == 0 then return "rangers" end

    -- Find empty factions first
    local empty = {}
    for _, f in ipairs(pool) do
        if not counts[f] or counts[f] == 0 then
            table.insert(empty, f)
        end
    end

    -- STEP 1: unique seeding
    if #empty > 0 then
        return empty[math.random(#empty)]
    end

    -- STEP 2: least populated
    local lowest = math.huge
    local best = {}

    for _, f in ipairs(pool) do
        local c = counts[f] or 0

        if c < lowest then
            lowest = c
            best = { f }
        elseif c == lowest then
            table.insert(best, f)
        end
    end

    return best[math.random(#best)]
end

function CoDHUD.Factions.PickBalancedFromPool(pool)
    local counts = CoDHUD.Factions.GetFactionCounts()

    local bestFaction
    local lowest = math.huge

    for _, faction in ipairs(pool) do
        local count = counts[faction] or 0
        if count < lowest then
            lowest = count
            bestFaction = faction
        end
    end

    return bestFaction
end

local function CoDHUD_GetJoinFaction()
    local game = GetConVar("codhud_game"):GetString()
    local factionTable = CoDHUD.Factions.validfactions[game] or CoDHUD.Factions.validfactions["mw2"]

    local pool = CoDHUD.Factions.ActivePool
    local limit = GetConVar("codhud_autofaction_limit"):GetInt()

    local counts = CoDHUD.Factions.GetFactionCounts()

    if pool and #pool > 0 then
        return CoDHUD.Factions.PickFromPool(counts)
    end

    local activeFactions = {}

    for f, _ in pairs(factionTable) do
        if (counts[f] or 0) > 0 then
            table.insert(activeFactions, f)
        end
    end

    -- If nobody is in any faction yet → fall back to all factions
    if #activeFactions == 0 then
        local all = {}
        for f, _ in pairs(factionTable) do
            table.insert(all, f)
        end
        return all[math.random(#all)]
    end

    local activeFactionCount = #activeFactions

    -- If only 1 faction is populated AND limit is 0 or >2 → random any faction
    if activeFactionCount == 1 and (limit == 0 or limit > 2) then
        local all = {}
        for f, _ in pairs(factionTable) do
            table.insert(all, f)
        end
        return all[math.random(#all)]
    end

    -- Otherwise: balance between active factions
    local lowest = math.huge
    local best = {}

    for _, f in ipairs(activeFactions) do
        local c = counts[f] or 0

        if c < lowest then
            lowest = c
            best = { f }
        elseif c == lowest then
            table.insert(best, f)
        end
    end

    return best[math.random(#best)]
end

local function CoDHUD_AssignFaction(ply)
    -- Sesh bots' faction is exclusively owned by sv_ffa_bots.lua (always the
    -- opposing team from the human) -- same exclusion already applied to
    -- every other generic faction-assignment path in this file. Without it,
    -- "player_activate" (which DOES fire for player.CreateNextBot() bots,
    -- not just real connecting clients) runs this on every fresh bot spawn
    -- with no CoDHUD_StoredFaction set yet, and CoDHUD_GetJoinFaction()'s
    -- generic pool-balancing pick can land a bot on the player's own
    -- faction -- the rare "we're both on rangers" bug. It's almost always
    -- invisible because SeshBot_FactionSync's Think hook (sv_ffa_bots.lua)
    -- catches and corrects it within under a second, which is why the
    -- console fills with "FactionSync correcting ... rangers -> ussr" --
    -- but occasionally the scoreboard renders in that window before the
    -- correction lands.
    if IsValid(ply) and ply:IsBot() then return end
    if ply.CoDHUD_StoredFaction then return end

    local faction = CoDHUD_GetJoinFaction()

    ply.CoDHUD_StoredFaction = faction
    ply:SetNW2String("CoDHUD_Faction", faction)
end

gameevent.Listen( "player_activate" )
hook.Add( "player_activate", "CoDHUD_JoinRoundSync", function(data)
	local id = data.userid				-- Same as Player:UserID() for the speaker
	local ply = Player(id)

    if not IsValid(ply) then return end

	-- print("CoDHUD DEBUG: Player " .. ply:Nick() .. " is in faction " .. ply:GetNW2String("CoDHUD_Faction", "rangers"))

	CoDHUD_AssignFaction(ply)

	-- print("Player " .. ply:Nick() .. " assigned to a new faction! (" .. ply:GetNW2String("CoDHUD_Faction", "rangers") .. ")")

    -- "player_activate" fires for player.CreateNextBot() bots too, not just
    -- real connecting clients (see the CoDHUD_AssignFaction comment above,
    -- which already excludes bots for exactly this reason). This block's
    -- own forced ply:Spawn() 0.1s later never got the same exclusion --
    -- traced via debug.traceback() to be the actual cause of "bots spawn
    -- stuck inside each other and die instantly": it re-spawns an
    -- already-alive bot fresh out of SpawnBot() (sv_ffa_bots.lua), undoing
    -- its position and re-triggering the engine's own spawn-point/kill
    -- logic on an entity that's already alive. Bots have no client to sync
    -- round state to anyway -- sv_ffa_bots.lua owns their entire spawn
    -- lifecycle.
    if ply:IsBot() then return end

    timer.Simple(0.1, function()

        -- print("[CoDHUD] Checking round sync for " .. ply:Nick())

        -- No active round
        if not CoDHUD_RoundEndTimeSV and not CoDHUD_RoundStarting then
            -- print("[CoDHUD] No active round.")
            return
        end

        local gamemode = GetConVar("codhud_selected_gamemode"):GetString()
        local maxtimer = GetConVar("codhud_time_limit"):GetFloat()

        local remaining = 0

        if CoDHUD_RoundStarting and CoDHUD_RoundStartTimer then
            remaining = math.max(0, math.ceil(CoDHUD_RoundStartTimer - CurTime()))
        end

        -- print("[CoDHUD] Syncing " .. ply:Nick())
        -- print("Remaining countdown: " .. remaining)
        -- print("Faction: " .. tostring(ply.CoDHUD_StoredFaction))
		
		-- if ply:Alive() then
			-- ply:KillSilent()
		-- end
		
		-- ply:SetFrags(0)
		-- ply:SetDeaths(0)

		ply:Spawn() -- Force a respawn, just in case

        if remaining > 0 then
            ply:Freeze(true)
        end

        net.Start("CoDHUD_RoundStart")
            net.WriteString(gamemode)
            net.WriteInt(remaining, 6)
            net.WriteInt(maxtimer, 32)
            net.WriteFloat(CoDHUD_RoundEndTimeSV or 0)
        net.Send(ply)

    end)
end)

hook.Add("PlayerDisconnected", "CoDHUD_ResetLateJoinFlag", function(ply)
    if IsValid(ply) then
        ply.CoDHUD_HasSyncedRound = nil
    end
end)

hook.Add("PlayerSelectSpawn", "CoDHUD_TwoFactionSpawns", function(ply)
    if not CoDHUD.Factions.IsTwoFactionMode() then return end

    local map = CoDHUD.Factions.GetTwoFactionMap()
    if not map then return end

    local faction = ply.CoDHUD_StoredFaction 
        or ply:GetNW2String("CoDHUD_Faction", "rangers")

    local teamID = map[faction]
    if not teamID then return end

    if teamID == 1 then
        local spawns = ents.FindByClass("info_player_counterterrorist")
        if #spawns > 0 then return table.Random(spawns) end

    elseif teamID == 2 then
        local spawns = ents.FindByClass("info_player_terrorist")
        if #spawns > 0 then return table.Random(spawns) end
    end
end)

local function SyncRestrictFactions()
    net.Start("CoDHUD_RestrictFactionsSync")
    net.WriteUInt(GetConVar("codhud_restrictfactions"):GetInt(), 2)
    net.Broadcast()
end

cvars.AddChangeCallback("codhud_restrictfactions", function()
    SyncRestrictFactions()
end)

hook.Add("PlayerInitialSpawn", "CoDHUD_SendRestrictFactions", function(ply)
    net.Start("CoDHUD_RestrictFactionsSync")
    net.WriteUInt(GetConVar("codhud_restrictfactions"):GetInt(), 2)
    net.Send(ply)
end)

-- [[ 2. CHAT INTERCEPTION ]]
hook.Add("PlayerSay", "CoDHUD_Chat_Interceptor", function(ply, text, teamOnly)
    if text == "" then return "" end

    -- Get faction ID and exact Name
    local factionID = ply:GetNW2String("CoDHUD_Faction", "rangers")
    local factionName = CoDHUD.Factions.GetFactionName(factionID) or "Army Rangers"

    -- Broadcast to relevant players via Net Message
    net.Start("CoDHUD_ChatMessage")
        net.WriteEntity(ply)
        net.WriteString(text)
        net.WriteBool(teamOnly)
        net.WriteString(factionName)
        
    if teamOnly then
        -- TEAM CHAT: Only send to players with the exact same faction
        local targets = {}
        for _, v in ipairs(player.GetAll()) do
            if v:GetNW2String("CoDHUD_Faction", "rangers") == factionID then
                table.insert(targets, v)
            end
        end
        net.Send(targets)
    else
        -- GLOBAL CHAT: Send to everyone
        net.Broadcast()
    end

    -- Suppress the default Garry's Mod chat so we don't get double messages
    -- return "" -- Unnecessary.
end)

-- [[ 3. KILLFEED ]]
-- Captures the damage type right before death so we know if it was a fall, blast, etc.
hook.Add("EntityTakeDamage", "CoDHUD_Killfeed_CaptureDamage", function(target, dmginfo)
    if target:IsPlayer() or target:IsNPC() then
        target.CoDHUD_LastDamageType = dmginfo:GetDamageType()
        
        -- Check for headshot
        if target:IsPlayer() and target:LastHitGroup() == HITGROUP_HEAD then
            target.CoDHUD_WasHeadshot = true
        else
            target.CoDHUD_WasHeadshot = false
        end
    end
end)