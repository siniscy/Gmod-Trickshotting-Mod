-- codhud_crosshair.lua
-- The Call of Duty crosshair for each game the HUD supports (cod4, waw, mw2,
-- mw3, bo1, bo2), reproduced from the games themselves:
--
--   * Drawing is a port of the engine's own reticle code (CG_DrawReticleSides /
--     CG_CalcReticleSpread / CG_CalcReticleColor / CG_TransitionToAds from the
--     CoD4 and Black Ops decompilations -- the two are the same algorithm).
--     Everything is laid out in the engine's 640x480 virtual space, centred.
--   * The textures are the games' own reticle images (materials/codhud/crosshair).
--   * How far the lines sit and how they move comes from each game's real
--     weapon files (lua/codhud/cl_crosshair_data.lua): hip spread per stance,
--     how much each shot / movement / turning / jumping widens it and how fast
--     it settles, enemy-colour range, ADS shrink timing. The spread state
--     (aimSpreadScale) is simulated with the engine's PM_AdjustAimSpreadScale.
--   * Lines fade as they widen (down to cg_crosshairAlphaMin 0.5), shrink to
--     half and vanish when aiming down sights, hide while reloading, drawing a
--     weapon or meleeing, and turn the game's enemy/friendly colour over a
--     player within the weapon's enemyCrosshairRange.
--   * Grenades and equipment use the game's centre reticle (frag cross that
--     pulses while cooking; MW2/MW3 semtex, claymore, C4, insertion, knife).

if not CLIENT then return end

-- ================================================================
--  CONVARS
-- ================================================================
CreateClientConVar("codhud_crosshair",       "1",   true, false, "Draw the Call of Duty crosshair")
CreateClientConVar("cod4_crosshair_red",     "255", true, false, "Crosshair red (the games use white)")
CreateClientConVar("cod4_crosshair_green",   "255", true, false, "Crosshair green")
CreateClientConVar("cod4_crosshair_blue",    "255", true, false, "Crosshair blue")
CreateClientConVar("cod4_crosshair_alpha",   "255", true, false, "Crosshair alpha (cg_crosshairAlpha)")
CreateClientConVar("codhud_crosshair_fov",   "65",  true, false, "cg_fov the spread is mapped with (every one of these games defaults to 65)")
CreateClientConVar("codhud_crosshair_game",  "",    true, false, "Force one game's crosshair (cod4/waw/mw2/mw3/bo1/bo2); empty follows the HUD")

hook.Add("PopulateToolMenu", "CoD4CrosshairOptions", function()
    spawnmenu.AddToolMenuOption("Options", "Call of Duty 4: Modern Warfare", "cod4_crosshair", "Crosshair", "", "", function(panel)
        panel:CheckBox("Draw crosshair", "codhud_crosshair")
        panel:AddControl("Color", {
            Label = "Color",
            Red   = "cod4_crosshair_red",
            Green = "cod4_crosshair_green",
            Blue  = "cod4_crosshair_blue",
            Alpha = "cod4_crosshair_alpha"
        })
    end)
end)

-- ================================================================
--  PER-GAME STYLE
--  Colours are what the games actually show: CoD4/MW2 and WaW set them in
--  maps/mp/gametypes/_scoreboard.gsc / _teams.gsc, BO1 and MW3 use the
--  engine defaults (g_TeamColor_*). BO2 sets none in script and its engine
--  defaults aren't public; it inherits Black Ops' (same engine lineage).
--  Enemy colour needs cg_enemyNameFadeIn (250ms) of aiming first on the IW
--  engine; Black Ops colours immediately.
-- ================================================================
local STYLE = {
    cod4 = { set = "iw3", enemy = { 1, 0.45, 0.5 },    friend = { 0.6, 0.8, 0.6 },  enemyDelay = 0.25 },
    waw  = { set = "iw3", enemy = { 1, 0.315, 0.35 },  friend = { 0.4, 0.7, 0.4 },  enemyDelay = 0.25 },
    mw2  = { set = "iw4", enemy = { 1, 0.45, 0.5 },    friend = { 0.6, 0.8, 0.6 },  enemyDelay = 0.25 },
    mw3  = { set = "iw4", enemy = { 0.75, 0.25, 0.25 }, friend = { 0.4, 0.6, 0.85 }, enemyDelay = 0.25 },
    bo1  = { set = "iw3", enemy = { 1, 0.315, 0.35 },  friend = { 0.4, 0.7, 0.4 },  enemyDelay = 0 },
    bo2  = { set = "iw3", enemy = { 1, 0.315, 0.35 },  friend = { 0.4, 0.7, 0.4 },  enemyDelay = 0 },
}

local ALPHA_MIN        = 0.5    -- cg_crosshairAlphaMin
local MOVE_THRESHOLD   = 11     -- bg_aimSpreadMoveSpeedThreshold
local ADS_TIME         = 0.2    -- seconds for the weapon to come up to / down from the eye

local function GameKey()
    local forced = GetConVar("codhud_crosshair_game"):GetString()
    if STYLE[forced] then return forced end
    local g = CoDHUD_GetHUDType and CoDHUD_GetHUDType() or "mw2"
    return STYLE[g] and g or "mw2"
end

local matCache = {}
local function Mat(name)
    local m = matCache[name]
    if m == nil then
        m = Material("codhud/crosshair/" .. name .. ".png", "smooth")
        if m:IsError() then m = false end
        matCache[name] = m
    end
    return m or nil
end

-- ================================================================
--  WEAPON -> GAME WEAPON DATA
-- ================================================================
local IGNORE_TOKEN = {
    weapon = true, reha = true, notreha = true, dread = true, kc = true, nz = true, tfa = true, m9k = true,
    robotnik = true, cod = true, cw = true, arccw = true, fas2 = true, mw2cr = true,
    bo1 = true, bo2 = true, bo3 = true, mw2 = true, mw3 = true, cod4 = true, waw = true, iw3 = true, iw4 = true, iw5 = true,
}
local TAG = { "mw2cr", "bo1", "bo2", "bo3", "mw2", "mw3", "cod4", "waw", "iw3", "iw4", "iw5" }
local SUFFIXES = { "extclip", "silencer", "silenced", "akimbo", "scoped", "reflex", "eotech", "grip", "holo", "acog", "sil", "ext", "dw", "lh", "g" }

local function Norm(s) return (string.lower(s or "")):gsub("[^a-z0-9]", "") end

local function StripTags(tok)
    for _, t in ipairs(TAG) do
        if #tok > #t + 1 and tok:sub(1, #t) == t then tok = tok:sub(#t + 1) end
        if #tok > #t + 1 and tok:sub(-#t) == t then tok = tok:sub(1, -#t - 1) end
    end
    return tok
end

local function Candidates(wep)
    local out, seen = {}, {}
    local function add(c)
        c = Norm(c)
        if c ~= "" and not seen[c] then seen[c] = true out[#out + 1] = c end
    end
    local toks = {}
    for tok in string.gmatch(string.lower(wep:GetClass()), "[^_]+") do
        if not IGNORE_TOKEN[tok] then toks[#toks + 1] = StripTags(Norm(tok)) end
    end
    add(table.concat(toks, ""))
    for _, t in ipairs(toks) do add(t) end
    for word in string.gmatch(string.lower(wep.PrintName or ""), "[%w%-%.]+") do
        local w = Norm(word)
        if not IGNORE_TOKEN[w] then add(StripTags(w)) end
    end
    -- attachment / variant suffixes
    local n = #out
    for i = 1, n do
        for _, s in ipairs(SUFFIXES) do
            local c = out[i]
            if #c > #s + 2 and c:sub(-#s) == s then add(c:sub(1, -#s - 1)) end
        end
    end
    return out
end

local function FindByName(tbl, cands)
    for _, c in ipairs(cands) do
        if tbl[c] then return tbl[c], c end
    end
    -- "m21g" -> m21, "l96" -> l96a1
    local best, bestKey
    for _, c in ipairs(cands) do
        for k, v in pairs(tbl) do
            if #k >= 3 and #c > #k and c:sub(1, #k) == k and (not bestKey or #k > #bestKey) then best, bestKey = v, k end
        end
    end
    if best then return best, bestKey end
    for _, c in ipairs(cands) do
        if #c >= 3 then
            for k, v in pairs(tbl) do
                if #k > #c and k:sub(1, #c) == c and (not bestKey or #k < #bestKey) then best, bestKey = v, k end
            end
        end
    end
    return best, bestKey
end

local SNIPER = { "dsr", "ballista", "svu", "l96", "l115", "intervention", "cheytac", "barrett", "m82", "msr", "as50", "m40", "m21", "r700", "remington700", "wa2000", "dragunov", "psg1", "kar98", "springfield", "mosin", "type99", "ptrs", "awp", "scout", "sniper" }
local SHOTGUN = { "shotgun", "spas", "870", "ksg", "1887", "aa12", "striker", "m1014", "winchester", "trench", "olympia", "ithaca", "hs10", "s12", "saiga", "usas", "mcs", "ranger", "stakeout", "doublebarrel" }
local MG = { "m60", "rpd", "l86", "mg4", "aughbar", "lsat", "hamr", "qbb", "mk48", "pkm", "pecheneg", "mk46", "mg36", "m249", "saw", "rpk", "hk21", "stoner", "mg42", "30cal", "dp28", "type99lmg", "mg08" }
local SMG = { "mp5", "ump", "p90", "uzi", "mp7", "pdw", "vector", "msmc", "skorpion", "ppsh", "thompson", "mp40", "type100", "ak74u", "pp2000", "pp90", "mac11", "kiparis", "mpl", "spectre", "chicom", "peacekeeper", "mp9", "fmg9", "tmp", "smg" }

local function HasAny(n, list)
    for _, s in ipairs(list) do if string.find(n, s, 1, true) then return true end end
    return false
end

local function GuessClass(wep)
    local n = Norm(wep:GetClass() .. (wep.PrintName or ""))
    local ht = string.lower(wep.HoldType or (wep.GetHoldType and wep:GetHoldType()) or "")
    if wep.Scoped or (wep.Secondary and (tonumber(wep.Secondary.ScopeZoom) or 0) > 0) or HasAny(n, SNIPER) then return "sniper" end
    if ht == "shotgun" or (wep.Primary and (tonumber(wep.Primary.NumShots) or 1) > 1) or HasAny(n, SHOTGUN) then return "spread" end
    if HasAny(n, MG) then return "mg" end
    if ht == "pistol" or ht == "revolver" or ht == "duel" then return "pistol" end
    if ht == "smg" or HasAny(n, SMG) then return "smg" end
    return "rifle"
end

-- Equipment: which of the game's equipment reticles a weapon uses, in order of preference.
local EQUIP_RULES = {
    { pat = { "semtex" },                        try = { "semtex", "stickygrenade" } },
    { pat = { "sticky" },                        try = { "stickygrenade", "semtex" } },
    { pat = { "claymore" },                      try = { "claymore" } },
    { pat = { "betty", "bouncing" },             try = { "bouncingbetty", "c4" } },
    { pat = { "c4", "satchel", "shockcharge", "shock_charge" }, try = { "c4", "satchelcharge" } },
    { pat = { "throwingknife", "throwing_knife", "tknife", "hatchet" }, try = { "throwingknife" } },
    { pat = { "insertion", "flare" },            try = { "flare", "tacticalinsertion", "signalflare" } },
    { pat = { "scrambler", "jammer" },           try = { "scrambler" } },
    { pat = { "emp" },                           try = { "empgrenade", "concussiongrenade", "flashgrenade" }, nocook = true },
    { pat = { "smoke", "willy" },                try = { "smokegrenade", "m8whitesmoke", "willypete" }, nocook = true },
    { pat = { "flash", "stun", "concussion" },   try = { "flashgrenade", "concussiongrenade" }, nocook = true },
    { pat = { "molotov", "tabun", "gas" },       try = { "molotov", "tabungas" }, nocook = true },
    { pat = { "frag", "grenade", "nade" },       try = { "fraggrenade" } },
}

local function FindEquip(game, wep)
    local n = string.lower(wep:GetClass() .. " " .. (wep.PrintName or ""))
    for _, rule in ipairs(EQUIP_RULES) do
        if HasAny(n, rule.pat) then
            for _, key in ipairs(rule.try) do
                local e = game.equip[key]
                if e then return e, rule.nocook end
            end
            -- this game has no reticle for it: grenade-type things fall back to the cross
            local frag = game.equip.fraggrenade
            if rule.nocook and frag then return frag, true end
            return { img = "", cs = 0, cook = 0 }, true
        end
    end
    return nil
end

local resolveCache = {}   -- [game][class] = { kind = "gun"/"equip"/"none", w = data, ... }

local function Resolve(gameKey, wep)
    local data = CoDHUD_CrosshairData and CoDHUD_CrosshairData[gameKey]
    if not data or not IsValid(wep) then return nil end
    local class = wep:GetClass()
    resolveCache[gameKey] = resolveCache[gameKey] or {}
    local r = resolveCache[gameKey][class]
    if r then return r end

    local n = string.lower(class .. " " .. (wep.PrintName or ""))
    if string.find(n, "knife", 1, true) and not string.find(n, "throw", 1, true) and not string.find(n, "ballistic", 1, true) then
        r = { kind = "none" }   -- knives have no reticle in any of these games
    else
        local e, nocook = FindEquip(data, wep)
        if e then
            r = { kind = "equip", e = e, nocook = nocook }
        else
            local w = FindByName(data.weapons, Candidates(wep))
            if not w then
                local rep = data.reps[GuessClass(wep)] or data.reps.rifle
                w = data.weapons[rep]
            end
            r = { kind = w and "gun" or "none", w = w }
        end
    end
    resolveCache[gameKey][class] = r
    return r
end

-- ================================================================
--  HIDE STATES (AllowedToDrawCrosshair: raising/dropping, reloading, melee)
-- ================================================================
local BLOCK_ACTS = {}
for _, name in ipairs({
    "ACT_VM_RELOAD", "ACT_VM_RELOAD_SILENCED", "ACT_VM_RELOAD_DEPLOYED", "ACT_VM_RELOAD_EMPTY", "ACT_VM_RELOAD_IDLE",
    "ACT_SHOTGUN_RELOAD_START", "ACT_SHOTGUN_RELOAD_FINISH", "ACT_VM_RELOAD_INSERT", "ACT_VM_RELOAD_INSERT_PULL", "ACT_VM_RELOAD_END",
    "ACT_VM_DRAW", "ACT_VM_DRAW_SILENCED", "ACT_VM_DRAW_DEPLOYED", "ACT_VM_DRAW_EMPTY", "ACT_VM_HOLSTER", "ACT_VM_HOLSTER_EMPTY",
    "ACT_VM_HITCENTER", "ACT_VM_HITCENTER2", "ACT_VM_MISSCENTER", "ACT_VM_MISSCENTER2", "ACT_VM_SWINGHARD", "ACT_VM_SWINGMISS", "ACT_VM_SWINGHIT",
}) do
    local v = _G[name]
    if v then BLOCK_ACTS[v] = true end
end

local function ViewModelBlocks(vm)
    if not IsValid(vm) then return false end
    local act = vm:GetSequenceActivity(vm:GetSequence())
    return BLOCK_ACTS[act] == true and (vm:GetCycle() or 1) < 0.98
end

-- ================================================================
--  SPREAD SIMULATION (PM_AdjustAimSpreadScale / PM_Weapon_AddFiringAimSpreadScale)
-- ================================================================
local function NewState()
    return { aim = 0, posLerp = 0, toADS = false, lastAng = nil, shots = 0, target = nil, targetKind = nil, targetStart = 0 }
end

local live = NewState()
local replay = NewState()
local replaySession

local function AngleDiffAbs(a, b) return math.abs(math.AngleDifference(a, b)) end

-- in: onGround, crouched, standFrac (0 ducked .. 1 standing), moving, speed, maxSpeed, ang, shots, ads
local function UpdateState(st, w, inp, ft)
    -- weapon to/from the eye
    st.toADS = inp.ads
    local step = ft / ADS_TIME
    st.posLerp = inp.ads and math.min(1, st.posLerp + step) or math.max(0, st.posLerp - step)

    local increase, decrease = 0, 1
    local wpnScale = w.dec
    if wpnScale ~= 0 then
        if inp.onGround then
            if inp.crouched then wpnScale = wpnScale * w.ddec end
        else
            wpnScale = wpnScale * 0.5
        end
        decrease = wpnScale * ft
        if st.posLerp < 1 then
            local viewchange = 0
            if w.turn ~= 0 and st.lastAng and inp.ang and ft > 0 then
                viewchange = viewchange + (AngleDiffAbs(inp.ang.p, st.lastAng.p) + AngleDiffAbs(inp.ang.y, st.lastAng.y)) * 0.01 * w.turn / ft
            end
            if w.move ~= 0 and inp.moving and inp.speed > MOVE_THRESHOLD then
                viewchange = viewchange + w.move * inp.speed / math.max(inp.maxSpeed, 1)
            end
            if not inp.onGround then viewchange = viewchange + 2 * 0.01 * 128 end
            increase = viewchange * ft
        end
    end
    if increase > 0 then st.aim = st.aim + increase * 255 else st.aim = st.aim - decrease * 255 end
    st.lastAng = inp.ang and Angle(inp.ang.p, inp.ang.y, 0) or nil

    -- each shot from the hip widens it (PM_Weapon_AddFiringAimSpreadScale)
    if inp.shots > 0 and st.posLerp < 1 then st.aim = st.aim + inp.shots * w.fire * 255 end
    st.aim = math.Clamp(st.aim, 0, 255)
end

-- Shots fired by the local player (predicted, so they line up with the gun).
local pendingShots, lastShotT = 0, 0
hook.Add("EntityFireBullets", "CoDHUD_Crosshair_Shots", function(ent, data)
    if not IsFirstTimePredicted() then return end
    local lp = LocalPlayer()
    if ent ~= lp and not (IsValid(ent) and ent:IsWeapon() and ent:GetOwner() == lp) then return end
    local t = CurTime()
    if t - lastShotT < 0.005 then return end   -- one volley (shotgun pellets)
    lastShotT = t
    pendingShots = pendingShots + 1
end)

-- Fallback for weapons that only fire on the server: watch the clip.
local lastClip, lastClipWep = -1, nil
local function ClipShots(wep)
    if not IsValid(wep) then lastClip = -1 return 0 end
    local clip = wep:Clip1()
    local shots = 0
    if wep == lastClipWep and lastClip >= 0 and clip >= 0 and clip < lastClip and CurTime() - lastShotT > 0.1 then
        shots = 1
    end
    lastClip, lastClipWep = clip, wep
    return shots
end

-- ================================================================
--  TARGET COLOUR (CG_CalcCrosshairColor)
-- ================================================================
local TEAM_NONE = { [TEAM_UNASSIGNED or 1001] = true, [TEAM_SPECTATOR or 1002] = true, [TEAM_CONNECTING or 0] = true }

local function LiveTarget(ply, range)
    local tr = util.TraceLine({ start = ply:EyePos(), endpos = ply:EyePos() + ply:GetAimVector() * range, filter = ply, mask = MASK_SHOT })
    local e = tr.Entity
    if not IsValid(e) then return nil end
    if e:IsPlayer() then
        if not e:Alive() then return nil end
        local t = ply:Team()
        if t == e:Team() and not TEAM_NONE[t] then return "friend", e end
        return "enemy", e
    end
    if e:IsNPC() or (e.IsNextBot and e:IsNextBot()) then return "enemy", e end
    return nil
end

local function TargetColor(st, style, kind, key)
    local now = RealTime()
    if kind ~= st.targetKind or key ~= st.target then
        st.targetKind, st.target, st.targetStart = kind, key, now
    end
    if kind == "friend" then return style.friend end
    if kind == "enemy" and now - st.targetStart >= style.enemyDelay then return style.enemy end
    return nil
end

-- ================================================================
--  DRAWING
-- ================================================================
-- CG_DrawRotatedPic: (x, y) is the top-left of the unrotated rect in 640x480
-- virtual units, rotated about its centre; positive angles turn clockwise on
-- screen. surface.DrawTexturedRectRotated takes the centre and turns the other way.
local function DrawRotated(cx, cy, scale, x, y, size, angle)
    local px = cx + x * scale
    local py = cy + y * scale
    local s = size * scale
    surface.DrawTexturedRectRotated(px + s * 0.5, py + s * 0.5, s, s, -angle)
end

local function TanHalfFovY(curFov)
    local codFov = math.Clamp(GetConVar("codhud_crosshair_fov"):GetFloat(), 30, 160)
    local t = math.tan(math.rad(codFov * 0.5)) * 0.75
    -- a weapon zooming the view narrows it the same way CoD's ADS FOV does
    local desired = GetConVar("fov_desired"):GetFloat()
    if curFov and curFov > 1 and curFov < desired then
        t = t * math.tan(math.rad(curFov * 0.5)) / math.tan(math.rad(desired * 0.5))
    end
    return t
end

local function DrawSides(style, w, st, baseCol, curFov)
    local mat = Mat("reticle_side_small_" .. style.set)
    if not mat then return end

    -- CG_TransitionToAds
    local transScale = 1
    if st.posLerp > 0 then
        local frac = st.toADS and w.ain or w.aout
        local f = st.posLerp - (1 - frac)
        if f > 0 and frac > 0 then transScale = 1 - (f / frac) * 0.5 end
    end

    -- CG_CalcReticleColor
    local alpha = (baseCol.a / 255) * (1 - st.aim / 255)
    if alpha < ALPHA_MIN then alpha = ALPHA_MIN end
    if alpha < 0.01 then return end

    -- CG_CalcReticleSpread
    local size = w.sz * transScale
    local minS, maxS = st.minSpread or w.smin, st.maxSpread or w.smax
    local f = ((maxS - minS) * (st.aim / 255) + minS) * transScale
    local scaleV = math.tan(math.rad(f)) * 240 / TanHalfFovY(curFov)
    if scaleV < w.mo then scaleV = w.mo end
    local spread = scaleV - w.hp * size
    local texel = size / 8                -- CG_CalcReticleImageOffset

    local cx, cy, scale = ScrW() * 0.5, ScrH() * 0.5, ScrH() / 480
    surface.SetMaterial(mat)
    surface.SetDrawColor(baseCol.r, baseCol.g, baseCol.b, alpha * 255)
    DrawRotated(cx, cy, scale, -size * 0.5,                  -size - spread - texel,   size, 0)
    DrawRotated(cx, cy, scale, spread,                       -size * 0.5,              size, 90)
    DrawRotated(cx, cy, scale, -size * 0.5 - texel,          spread,                   size, 180)
    DrawRotated(cx, cy, scale, -size - spread - texel,       -size * 0.5 - texel,      size, 270)
end

local function DrawCenter(style, e, col, cookLeft)
    if not e or e.img == "" or (e.cs or 0) <= 0 then return end
    local mat = Mat(e.img .. "_" .. style.set) or Mat(e.img .. "_iw4") or Mat(e.img .. "_iw3")
    if not mat then return end
    local size = e.cs
    -- CG_DrawReticleCenter: a cooking frag's cross pulses with the fuse
    if cookLeft and cookLeft > 0 then size = size + (math.floor(cookLeft * 1000) % 1000) / 100 end
    local scale = ScrH() / 480
    local s = size * scale
    surface.SetMaterial(mat)
    surface.SetDrawColor(col.r, col.g, col.b, col.a)
    surface.DrawTexturedRect(ScrW() * 0.5 - s * 0.5, ScrH() * 0.5 - s * 0.5, s, s)
end

-- Stance -> CoD view height -> min/max spread (BG_GetSpreadForWeapon; no prone in GMod)
local function StanceSpread(w, standFrac)
    standFrac = math.Clamp(standFrac, 0, 1)
    return Lerp(standFrac, w.dmin, w.smin), Lerp(standFrac, w.dmax, w.smax)
end

local function BaseColor()
    return Color(GetConVar("cod4_crosshair_red"):GetInt(), GetConVar("cod4_crosshair_green"):GetInt(),
        GetConVar("cod4_crosshair_blue"):GetInt(), GetConVar("cod4_crosshair_alpha"):GetInt())
end

local function Tint(base, rgb)
    if not rgb then return base end
    return Color(rgb[1] * 255, rgb[2] * 255, rgb[3] * 255, base.a)
end

-- grenade cook tracking (fuse counts down from the moment the pin is pulled)
local cookStart
local function CookLeft(ply, e, nocook)
    if not e or e.cook ~= 1 or nocook then cookStart = nil return nil end
    if ply:KeyDown(IN_ATTACK) then
        cookStart = cookStart or CurTime()
        return math.max(0, (e.fuse or 3.5) - (CurTime() - cookStart))
    end
    cookStart = nil
    return nil
end

local function Sprinting(ply)
    return ply:KeyDown(IN_SPEED) and ply:GetVelocity():Length2D() > ply:GetWalkSpeed() * 0.6
end

local function WantsADS(ply, wep)
    if Sprinting(ply) or not ply:KeyDown(IN_ATTACK2) then return false end
    for _, fn in ipairs({ "GetIronsights", "GetIronSights" }) do
        if isfunction(wep[fn]) then
            local ok, v = pcall(wep[fn], wep)
            if ok and v then return true end
        end
    end
    return ply:GetFOV() < GetConVar("fov_desired"):GetFloat() - 2
end

-- ---------------------------------------------------------------- live
local function DrawLive(ply)
    if not ply:Alive() or ply:GetObserverMode() ~= OBS_MODE_NONE then return end
    local wep = ply:GetActiveWeapon()
    if not IsValid(wep) then return end
    local gameKey = GameKey()
    local style = STYLE[gameKey]
    local r = Resolve(gameKey, wep)
    if not r or r.kind == "none" then return end

    -- raising/dropping, reloading, melee
    local vm = ply:GetViewModel(0)
    if ViewModelBlocks(vm) then pendingShots = 0 return end
    if wep:GetNWBool("Reloading") and not Sprinting(ply) then pendingShots = 0 return end

    local base = BaseColor()
    if r.kind == "equip" then
        DrawCenter(style, r.e, base, CookLeft(ply, r.e, r.nocook))
        return
    end

    local w = r.w
    local ft = FrameTime()
    local eye = ply:EyePos().z - ply:GetPos().z
    local stand, duck = ply:GetViewOffset().z, ply:GetViewOffsetDucked().z
    local standFrac = stand > duck and (eye - duck) / (stand - duck) or 1
    local shots = pendingShots + ClipShots(wep)
    pendingShots = 0
    UpdateState(live, w, {
        onGround = ply:IsOnGround(), crouched = ply:Crouching(), standFrac = standFrac,
        moving = ply:KeyDown(IN_FORWARD) or ply:KeyDown(IN_BACK) or ply:KeyDown(IN_MOVELEFT) or ply:KeyDown(IN_MOVERIGHT),
        speed = ply:GetVelocity():Length2D(), maxSpeed = ply:GetWalkSpeed(),
        ang = ply:EyeAngles(), shots = shots, ads = WantsADS(ply, wep),
    }, ft)
    live.minSpread, live.maxSpread = StanceSpread(w, standFrac)

    -- fully aimed down sights: the gun's sights replace the crosshair
    if live.posLerp >= 1 then return end
    if wep.Scoped and ply:GetFOV() < 45 then return end

    local col = base
    if w.cc == 1 then
        local kind, ent = LiveTarget(ply, w.rng)
        col = Tint(base, TargetColor(live, style, kind, ent))
    end
    DrawSides(style, w, live, col, ply:GetFOV())
end

-- ---------------------------------------------------------------- killcam
local replayMaxFov, replayLastShots
local function DrawReplay(rs)
    if not rs.alive or rs.scoped or (rs.fov or 75) < 45 then return end
    local gameKey = GameKey()
    local style = STYLE[gameKey]
    if replaySession ~= rs.sessionId then
        replaySession = rs.sessionId
        replay = NewState()
        replayMaxFov, replayLastShots = rs.fov, rs.shots or 0
    end
    replayMaxFov = math.max(replayMaxFov or 0, rs.fov or 0)

    -- the killer's weapon by class (merged with its base so Scoped/HoldType/etc. are there)
    local class = rs.weaponClass or ""
    local r = resolveCache[gameKey] and resolveCache[gameKey][class]
    if not r then
        local full = class ~= "" and weapons.Get(class) or { PrintName = "" }
        full.GetClass = function() return class end
        full.IsValid = function() return true end
        r = Resolve(gameKey, full)
    end
    if not r or r.kind == "none" then return end
    if ViewModelBlocks(rs.vm) then return end

    local base = BaseColor()
    if r.kind == "equip" then
        DrawCenter(style, r.e, base, nil)
        return
    end

    local w = r.w
    local shots = math.max(0, (rs.shots or 0) - (replayLastShots or 0))
    replayLastShots = rs.shots or 0
    -- the replay's slow-mo also slows how fast the spread settles
    local ft = FrameTime() * (rs.rate or 1)
    UpdateState(replay, w, {
        onGround = rs.onGround, crouched = false, standFrac = 1,
        moving = (rs.speed or 0) > MOVE_THRESHOLD, speed = rs.speed or 0, maxSpeed = 190,
        ang = rs.angles, shots = shots, ads = (rs.fov or 75) < (replayMaxFov or 75) - 3,
    }, ft)
    replay.minSpread, replay.maxSpread = w.smin, w.smax
    if replay.posLerp >= 1 then return end

    local col = base
    if w.cc == 1 and rs.origin and rs.angles and Killcam.Replay.CrosshairTarget then
        local kind = Killcam.Replay.CrosshairTarget(rs.origin, rs.angles:Forward(), w.rng)
        col = Tint(base, TargetColor(replay, style, kind, kind))
    end
    DrawSides(style, w, replay, col, (rs.fov or 75) < (replayMaxFov or 75) and rs.fov or nil)
end

-- ================================================================
--  ENTRY POINTS
--  CoD4Crosshair_Draw is kept by name: cl_hud.lua calls it for the killcam.
-- ================================================================
function CoD4Crosshair_Draw(inKillcam)
    if not GetConVar("codhud_crosshair"):GetBool() then return end
    if not inKillcam then
        local qd = GetConVar("codhud_quickdisable_hud")
        if qd and qd:GetBool() then return end
    end
    if not GetConVar("cl_drawhud"):GetBool() then return end
    if not CoDHUD_CrosshairData then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local rs = inKillcam and Killcam and Killcam.Replay and Killcam.Replay.GetCrosshairState and Killcam.Replay.GetCrosshairState()
    if rs then
        DrawReplay(rs)
    elseif not inKillcam then
        DrawLive(ply)
    end
end
CoDHUD_DrawCrosshair = CoD4Crosshair_Draw

-- Normal gameplay only - killcam draw is handled by cl_hud.lua
hook.Add("HUDPaint", "CoD4Crosshair_Draw", function()
    if KC_Playing and KC_Playing() then return end
    CoD4Crosshair_Draw()
end)

-- Re-resolve weapons when the game changes (data is per game)
cvars.AddChangeCallback("codhud_crosshair_game", function() resolveCache = {} end, "CoDHUD_Crosshair")

-- ================================================================
--  HIDE GMod's default crosshair
-- ================================================================
hook.Add("HUDShouldDraw", "CoD4Crosshair_HideDefault", function(name)
    if name == "CHudCrosshair" then
        if GetConVar("codhud_crosshair"):GetBool() then return false end
    end
end)
