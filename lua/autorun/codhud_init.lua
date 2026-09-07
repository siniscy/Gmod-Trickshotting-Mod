local files, _ = file.Find("codhud/*.lua", "LUA")

CoDHUD = CoDHUD or {}
CoDHUD.TypeRegistry = CoDHUD.TypeRegistry or {}

function CoDHUD.RegisterHUD(codename, displayname)
	if not codename or not displayname then return end

	CoDHUD.TypeRegistry[codename] = {
		codename = codename,
		name = displayname
	}
end

function CoDHUD_GetHUDType()
    local c = GetConVar("codhud_game")
    return c and c:GetString() or "mw2"
end

for _, f in ipairs(files) do
    local path = "codhud/" .. f

    if SERVER then
        -- Send every file to the client
        AddCSLuaFile(path)
    end

    -- Include depending on prefix (same behavior as autorun)
    if SERVER and f:StartWith("sv_") then
        include(path)
    elseif CLIENT and f:StartWith("cl_") then
        include(path)
    elseif f:StartWith("sh_") then
        include(path)
    end
end

local gamespath = "codhud/games/"
local files = file.Find(gamespath .. "*.lua", "LUA")

table.sort(files)

for _, f in ipairs(files) do
    local fullpath = gamespath .. f

    if SERVER then
        AddCSLuaFile(fullpath)
    end

    include(fullpath)
end