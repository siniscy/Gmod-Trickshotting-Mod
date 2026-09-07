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
	CoDHUD_MusicVolumeScale = GetConVar("snd_musicvolume"):GetFloat() or 1
	
    if isMusic then
        if not GetConVar("codhud_enable_music"):GetBool() then return end

        -- stop previous music immediately
        if IsValid(CoDHUD_CurrentMusic) then
            CoDHUD_CurrentMusic:Stop()
            CoDHUD_CurrentMusic = nil
        end

		sound.PlayFile("sound/" .. path, "noplay", function(chan, err)
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