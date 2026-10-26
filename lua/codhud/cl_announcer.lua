---- [ CLIENT ANNOUNCER & MUSIC ] ----

-- Queue system
CoDHUD_AnnouncerQueue = CoDHUD_AnnouncerQueue or {}
CoDHUD_AnnouncerPlaying = CoDHUD_AnnouncerPlaying or false
CoDHUD_AnnouncerNextTime = CoDHUD_AnnouncerNextTime or 0

-- Cache
CoDHUD_AnnouncerCache = CoDHUD_AnnouncerCache or {}

-- Music check
CoDHUD_CurrentMusic = CoDHUD_CurrentMusic or nil
CoDHUD_MusicVolumeScale = CoDHUD_MusicVolumeScale or 1

local ANNOUNCER_COOLDOWN = 1 -- small gap between lines

-- Killcam should be quiet -- nothing here (suspense stings, round-end
-- victory/defeat music+voice, timer callouts, etc.) checks whether a
-- killcam is playing before starting, so ambient music that happens to
-- roll on its random 15-20s timer, or round-end music that starts the
-- instant the round ends (killcam itself only starts ~6s later), bleeds
-- into the killcam. Two parts: block anything NEW from starting while a
-- killcam is playing (checked in CoDHUD_PlayAnnouncerSound below, the one
-- function everything already routes through), and stop whatever's
-- already playing the moment a killcam begins.
--
-- hook.Run("KillcamReplayStarted"/"Stopped") is server-side only (see
-- lua/killcam/cl_npcreplay.lua's comment -- hook.Run never crosses the
-- network, so client-side listeners for those two hook names never fire)
-- so this polls KC_Playing() directly instead, the same reliable pattern
-- killcam_codhud_integration.lua's CoDHUD_KillcamHUDToggle already uses.
local KC_AnnouncerWasKillcamActive = false
hook.Add("Think", "CoDHUD_Announcer_KillcamSilence", function()
    local active = KC_Playing and KC_Playing() or false
    if active and not KC_AnnouncerWasKillcamActive then
        if IsValid(CoDHUD_CurrentMusic) then
            CoDHUD_CurrentMusic:Stop()
            CoDHUD_CurrentMusic = nil
        end
        CoDHUD_AnnouncerQueue = {}
    end
    KC_AnnouncerWasKillcamActive = active
end)

local function CoDHUD_ProcessAnnouncerQueue()
    if CoDHUD_AnnouncerPlaying then return end
    if #CoDHUD_AnnouncerQueue == 0 then return end

    if CurTime() < CoDHUD_AnnouncerNextTime then return end

    local entry = table.remove(CoDHUD_AnnouncerQueue, 1)
    if not entry then return end

    CoDHUD_AnnouncerPlaying = true

    surface.PlaySound(entry.path)

    -- estimate duration
    local duration = SoundDuration(entry.path) or 2

    timer.Simple(duration, function()
        CoDHUD_AnnouncerPlaying = false
        CoDHUD_AnnouncerNextTime = CurTime() + ANNOUNCER_COOLDOWN
    end)
end

hook.Add("Think", "CoDHUD_AnnouncerQueue_Think", CoDHUD_ProcessAnnouncerQueue)

-- Helper to play sounds with toggle checks
function CoDHUD_PlayAnnouncerSound(path, isMusic, volume)
	if KC_Playing and KC_Playing() then return end
	CoDHUD_MusicVolumeScale = GetConVar("snd_musicvolume"):GetFloat() or 1

    if isMusic then
        if not GetConVar("codhud_enable_music"):GetBool() then return end

        -- stop previous music immediately
        if IsValid(CoDHUD_CurrentMusic) then
            CoDHUD_CurrentMusic:Stop()
            CoDHUD_CurrentMusic = nil
        end

		sound.PlayFile("sound/" .. path, "noplay", function(chan, err)
			-- sound.PlayFile loads async -- a killcam can start in the gap
			-- between the call above passing its KC_Playing() check and this
			-- callback actually firing, which would otherwise let it start
			-- playing into a killcam anyway. Re-check right before playing.
			if KC_Playing and KC_Playing() then
				if IsValid(chan) then chan:Stop() end
				return
			end
			if IsValid(chan) then
				CoDHUD_CurrentMusic = chan

				-- apply global attenuation for ambience/music separation
				local vol = 1
				if isMusic then
					vol = volume or CoDHUD_MusicVolumeScale or 1
				end

				chan:SetVolume(vol)
				chan:Play()
			end
		end)

        return
    else
        if not GetConVar("codhud_enable_announcer"):GetBool() then return end
    end

    table.insert(CoDHUD_AnnouncerQueue, {
        path = path
    })
end

-- Resolve announcer sound with language + suffix fallback
function CoDHUD_GetAnnouncerSound(keys)
    if isstring(keys) then
        keys = { keys }
    end

    local ply = LocalPlayer()
    if not IsValid(ply) then return nil end

    local faction = ply:GetNW2String("CoDHUD_Faction", "")
    if faction == "" then
        faction = cookie.GetString("CoDHUD_SelectedFaction", "rangers")
    end

    if not CoDHUD.Factions[CoDHUD_GetHUDType()] or not CoDHUD.Factions[CoDHUD_GetHUDType()][faction] then
        return nil
    end

	local voice = CoDHUD.Factions[CoDHUD_GetHUDType()][faction].voicepath
    local lang = GetConVar("gmod_language"):GetString() or "en"

	local forceEnglish = GetConVar("codhud_enable_announcer_english"):GetBool()

	if forceEnglish then
		lang = "en"
	end

	local function tryLang(l)
		for _, key in ipairs(keys) do

			local filesuffix = ""

			if CoDHUD[CoDHUD_GetHUDType()].VoiceCallouts
			and CoDHUD[CoDHUD_GetHUDType()].VoiceCallouts.suffix then
				filesuffix = CoDHUD[CoDHUD_GetHUDType()].VoiceCallouts.suffix
			end

			local baseDir = "sound/announcer/" .. CoDHUD_GetHUDType() .. "/" .. l .. "/"
			local voicePath = CoDHUD.Factions[CoDHUD_GetHUDType()][faction].voicepath
			local cacheKey = CoDHUD_GetHUDType() .. "|" .. faction .. "|" .. l .. "|" .. key

			-- build cache once
			if not CoDHUD_AnnouncerCache[cacheKey] then
				local voicePath = CoDHUD.Factions[CoDHUD_GetHUDType()][faction].voicepath

				local folder = "announcer/" .. CoDHUD_GetHUDType() .. "/" .. l .. "/" .. string.GetPathFromFilename(voicePath)
				local prefix = string.GetFileFromFilename(voicePath) .. key

				local files = file.Find("sound/" .. folder .. "*.wav", "GAME")
				local candidates = {}

				for _, filename in ipairs(files) do
					local lower = string.lower(filename)

					if string.StartWith(lower, string.lower(prefix)) then
						table.insert(candidates, folder .. filename)
					end
				end

				-- fallback exact file
				local exactPath = "announcer/" .. CoDHUD_GetHUDType() .. "/" .. l .. "/" .. voicePath .. key .. filesuffix .. ".wav"

				if file.Exists("sound/" .. exactPath, "GAME") then
					table.insert(candidates, exactPath)
				end

				CoDHUD_AnnouncerCache[cacheKey] = candidates
			end

			local candidates = CoDHUD_AnnouncerCache[cacheKey]

			if candidates and #candidates > 0 then
				return candidates[math.random(#candidates)]
			end
		end

		return nil
	end

	return tryLang(lang) or tryLang("en")
end