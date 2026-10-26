--[[
    Killcam archive -- first-person recorder (runs on every client).

    The server knows where everyone was, but only your own client knows
    exactly what your screen showed: the final camera after every view
    hook, the viewmodel's real position (iron sights, sway, bob, recoil),
    the animation it was playing, the scope overlay, the hands, and the
    gun sounds you heard. This keeps a rolling archive of all of that so
    that, if you get the final kill, your killcam is your actual view --
    not a reconstruction.
]]

local A = Killcam.Archive

local MAX_RATE   = 90          -- samples per second, at most
local CAPACITY   = 3600        -- ring size (~40s at MAX_RATE)

local ring, head, count = {}, 0, 0
local events = {}              -- { t, k, ... } chronological
local boneMods = {}            -- [vm model] = { {bone, s, p, a}, ... }
local boneModsNext = {}
local muzzleAtt = {}           -- [weapon class] = attachment id/name

local cur = {}                 -- the frame being assembled
local lastSampleT = -1

-- Shots and gun sounds happen inside prediction, where CurTime() is the
-- predicted command time -- a different clock from the render time every
-- recorded frame is stamped with. Events wait here and get the time of the
-- first frame that shows them, so in the replay the flash, the sound and
-- the bullet line up with the fire animation on screen.
local unstamped = {}

local function Recording()
    if KC_Playing and KC_Playing() then return false end
    local lp = LocalPlayer()
    return IsValid(lp)
end

local function PushEvent(ev)
    events[#events + 1] = ev
    unstamped[#unstamped + 1] = ev
end

-- 1) Final view of the frame ------------------------------------------------
hook.Add("RenderScene", "KC_POV_View", function(origin, angles, fov)
    if #unstamped > 0 then
        local now = CurTime()
        for i = 1, #unstamped do unstamped[i].t = now end
        unstamped = {}
    end
    if not Recording() then cur.valid = false return end
    cur.valid  = true
    cur.t      = CurTime()
    cur.origin = Vector(origin)
    cur.angles = Angle(angles)
    cur.fov    = fov
    cur.vmDrawn = false
    cur.handsDrawn = false
    cur.overlay = nil
end)

-- 2) The viewmodel, exactly where and how it was drawn -------------------
local function CaptureBoneMods(vm, model)
    if (boneModsNext[model] or 0) > CurTime() then return end
    boneModsNext[model] = CurTime() + 0.5
    local list = {}
    for b = 0, (vm:GetBoneCount() or 0) - 1 do
        local s = vm:GetManipulateBoneScale(b)
        local p = vm:GetManipulateBonePosition(b)
        local a = vm:GetManipulateBoneAngles(b)
        if s and p and a and (s.x ~= 1 or s.y ~= 1 or s.z ~= 1 or not p:IsZero() or not a:IsZero()) then
            list[#list + 1] = { b,
                math.Round(s.x, 3), math.Round(s.y, 3), math.Round(s.z, 3),
                math.Round(p.x, 2), math.Round(p.y, 2), math.Round(p.z, 2),
                math.Round(a.p, 2), math.Round(a.y, 2), math.Round(a.r, 2) }
        end
    end
    boneMods[model] = list
end

local function Bodygroups(ent)
    local n = ent:GetNumBodyGroups() or 0
    if n <= 0 then return "" end
    local t = {}
    for i = 0, n - 1 do t[#t + 1] = string.format("%x", math.min(ent:GetBodygroup(i) or 0, 15)) end
    return table.concat(t)
end

hook.Add("PostDrawViewModel", "KC_POV_ViewModel", function(vm, ply, weapon)
    if not cur.valid or ply ~= LocalPlayer() then return end
    if vm ~= ply:GetViewModel(0) then return end
    local model = vm:GetModel()
    if not model or model == "" then return end
    cur.vmDrawn = true
    cur.vmModel = model
    cur.vmPos   = vm:GetPos()
    cur.vmAng   = vm:GetAngles()
    cur.vmSeq   = vm:GetSequence()
    cur.vmCyc   = vm:GetCycle()
    cur.vmSkin  = vm:GetSkin() or 0
    cur.vmBG    = Bodygroups(vm)
    local vs = render.GetViewSetup and render.GetViewSetup()
    cur.vmFov = (vs and (vs.fovviewmodel or vs.fov_viewmodel)) or (IsValid(weapon) and weapon.ViewModelFOV) or 62
    CaptureBoneMods(vm, model)
    if IsValid(weapon) then
        local class = weapon:GetClass()
        if muzzleAtt[class] == nil then
            local att = weapon.MuzzleAttachment
            muzzleAtt[class] = att ~= nil and tostring(att) or false
        end
    end
end)

hook.Add("PostDrawPlayerHands", "KC_POV_Hands", function(hands, vm, ply, weapon)
    if not cur.valid or ply ~= LocalPlayer() then return end
    cur.handsDrawn = true
    cur.handsModel = hands:GetModel()
    cur.handsSkin  = hands:GetSkin() or 0
    cur.handsBG    = Bodygroups(hands)
end)

-- 3) The weapon's own HUD (sniper scopes, ACOG reticles, ...) -------------
-- SWEP:DrawHUD only ever runs for your own weapon, so spectators never saw
-- a killer's scope before. While the active weapon's DrawHUD runs, the
-- surface.* calls it makes are recorded (resolution independent) and
-- replayed on every viewer's screen.
local SURF = { "SetDrawColor", "SetTexture", "SetMaterial", "DrawTexturedRect",
               "DrawRect", "DrawTexturedRectUV", "DrawTexturedRectRotated", "DrawOutlinedRect" }
local realSurf = {}
local ops

local function nx(x) return math.Round((x - ScrW() * 0.5) / ScrH(), 4) end
local function ny(y) return math.Round(y / ScrH(), 4) end
local function ns(v) return math.Round(v / ScrH(), 4) end

local recorders = {
    SetDrawColor = function(r, g, b, a)
        if istable(r) then r, g, b, a = r.r, r.g, r.b, r.a end
        ops[#ops + 1] = { "c", r or 255, g or 255, b or 255, a or 255 }
    end,
    SetTexture = function(id)
        ops[#ops + 1] = { "t", surface.GetTextureNameByID and surface.GetTextureNameByID(id) or "" }
    end,
    SetMaterial = function(mat)
        ops[#ops + 1] = { "m", mat and mat.GetName and mat:GetName() or "" }
    end,
    DrawTexturedRect = function(x, y, w, h)
        ops[#ops + 1] = { "r", nx(x), ny(y), ns(w), ns(h) }
    end,
    DrawRect = function(x, y, w, h)
        ops[#ops + 1] = { "R", nx(x), ny(y), ns(w), ns(h) }
    end,
    DrawOutlinedRect = function(x, y, w, h)
        ops[#ops + 1] = { "O", nx(x), ny(y), ns(w), ns(h) }
    end,
    DrawTexturedRectUV = function(x, y, w, h, u0, v0, u1, v1)
        ops[#ops + 1] = { "u", nx(x), ny(y), ns(w), ns(h), u0, v0, u1, v1 }
    end,
    DrawTexturedRectRotated = function(x, y, w, h, rot)
        ops[#ops + 1] = { "o", nx(x), ny(y), ns(w), ns(h), rot }
    end,
}

local function WrapDrawHUD(wep)
    if wep.KC_DrawHUDWrapped then return end
    local orig = wep.DrawHUD
    if not isfunction(orig) then return end
    wep.KC_DrawHUDWrapped = true
    wep.DrawHUD = function(self, ...)
        -- Our live weapon's HUD stays hidden while a killcam is on screen.
        if KC_Playing and KC_Playing() then return end
        if not cur.valid then return orig(self, ...) end
        ops = {}
        for _, name in ipairs(SURF) do
            local real = surface[name]
            realSurf[name] = real
            local rec = recorders[name]
            surface[name] = function(...)
                pcall(rec, ...)
                return real(...)
            end
        end
        local ok, err = pcall(orig, self, ...)
        for _, name in ipairs(SURF) do surface[name] = realSurf[name] end
        local captured = ops
        ops = nil
        -- Only keep frames that actually drew a textured overlay.
        local hasDraw = false
        for _, op in ipairs(captured) do
            if op[1] == "r" or op[1] == "u" or op[1] == "o" or op[1] == "R" then hasDraw = true break end
        end
        cur.overlay = hasDraw and util.TableToJSON(captured) or nil
        if not ok then ErrorNoHalt(err .. "\n") end
    end
end

hook.Add("Think", "KC_POV_WrapWeapon", function()
    local lp = LocalPlayer()
    if not IsValid(lp) then return end
    local wep = lp:GetActiveWeapon()
    if IsValid(wep) then WrapDrawHUD(wep) end
end)

-- 4) Close the frame and store it --------------------------------------------
hook.Add("PostRender", "KC_POV_Commit", function()
    if not cur.valid then return end
    cur.valid = false
    local t = cur.t
    if t - lastSampleT < 1 / MAX_RATE then return end
    if t < lastSampleT then
        -- Clock went backwards (map change / reconnect): start over.
        ring, head, count = {}, 0, 0
        events = {}
        unstamped = {}
    end
    lastSampleT = t

    local lp = LocalPlayer()
    local wep = lp:GetActiveWeapon()
    head = head % CAPACITY + 1
    count = math.min(count + 1, CAPACITY)
    local f = ring[head] or {}
    ring[head] = f

    f.t = t
    f.o = cur.origin
    f.a = cur.angles
    f.fov = cur.fov
    f.vd = cur.vmDrawn
    if cur.vmDrawn then
        local lpos, lang = WorldToLocal(cur.vmPos, cur.vmAng, cur.origin, cur.angles)
        f.vm, f.lp, f.la = cur.vmModel, lpos, lang
        f.vs, f.vc, f.vk, f.vb, f.vf = cur.vmSeq, cur.vmCyc, cur.vmSkin, cur.vmBG, cur.vmFov
    else
        f.vm, f.lp, f.la, f.vs, f.vc, f.vk, f.vb, f.vf = nil, nil, nil, nil, nil, nil, nil, nil
    end
    f.hd = cur.handsDrawn
    if cur.handsDrawn then
        f.hm, f.hk, f.hb = cur.handsModel, cur.handsSkin, cur.handsBG
    else
        f.hm, f.hk, f.hb = nil, nil, nil
    end
    f.ov = cur.overlay
    f.wc = IsValid(wep) and wep:GetClass() or ""
    f.al = lp:Alive()
    f.sp = lp:GetVelocity():Length2D()
    f.og = lp:IsOnGround()
end)

-- 5) What you heard and fired ---------------------------------------------------
local function IsMine(ent)
    local lp = LocalPlayer()
    if not IsValid(ent) or not IsValid(lp) then return false end
    if ent == lp then return true end
    if ent == lp:GetViewModel(0) then return true end
    if ent:IsWeapon() and ent:GetOwner() == lp then return true end
    return false
end

local lastSnd, lastSndT = nil, 0
local lastFireT
hook.Add("EntityEmitSound", "KC_POV_Sounds", function(data)
    if not Recording() then return end
    if not IsMine(data.Entity) then return end
    local name = data.SoundName or data.OriginalSoundName
    if not name or name == "" then return end
    local t = CurTime()
    if name == lastSnd and t - lastSndT < 0.03 then return end
    lastSnd, lastSndT = name, t
    PushEvent({
        t = t, k = "s", n = name, o = data.OriginalSoundName,
        v = data.Volume or 1, l = data.SoundLevel or 75, p = data.Pitch or 100,
        c = data.Channel or CHAN_AUTO,
    })
end)

hook.Add("EntityFireBullets", "KC_POV_Fire", function(ent, data)
    if not Recording() then return end
    if not IsFirstTimePredicted() then return end
    if not IsMine(ent) then return end
    -- Penetration / ricochet bullets are re-fired from the wall they hit;
    -- only shots leaving the gun count as a muzzle flash.
    local lp = LocalPlayer()
    if data and data.Src and data.Src:DistToSqr(lp:GetShootPos()) > 48 * 48 then return end
    -- (de-duplicated on the prediction clock; .t is re-stamped at render)
    local t = CurTime()
    if lastFireT and t - lastFireT < 0.01 then return end
    lastFireT = t
    PushEvent({ t = t, k = "f" })
end)

local nextTrim = 0
hook.Add("Think", "KC_POV_TrimEvents", function()
    if CurTime() < nextTrim then return end
    nextTrim = CurTime() + 2
    local cutoff = CurTime() - 45
    local first = 1
    while events[first] and events[first].t < cutoff do first = first + 1 end
    if first > 1 then
        local keep = {}
        for i = first, #events do keep[#keep + 1] = events[i] end
        events = keep
    end
end)

-- 6) Upload the requested window ----------------------------------------------
local function BuildPOV(t0, t1)
    local frames = {}
    for i = 1, count do
        local idx = (head - count + i - 1) % CAPACITY + 1
        local f = ring[idx]
        if f and f.t >= t0 and f.t <= t1 then frames[#frames + 1] = f end
    end
    if #frames < 2 then return { v = A.VERSION, empty = 1 } end
    if A.cv_debug:GetBool() then
        local drawn = 0
        for _, f in ipairs(frames) do if f.vd then drawn = drawn + 1 end end
        A.Debug(string.format("view recording: %d frames, viewmodel drawn in %d, weapon %s",
            #frames, drawn, tostring(frames[#frames].wc)))
    end

    local str = A.NewStrings()
    local base = frames[1].t
    local n = #frames
    local col = {}
    local function c(name) col[name] = col[name] or {} return col[name] end

    local prev
    for i, f in ipairs(frames) do
        c("tm")[i] = f.t - base
        c("ox")[i], c("oy")[i], c("oz")[i] = f.o.x, f.o.y, f.o.z
        c("ap")[i], c("ay")[i], c("ar")[i] = f.a.p, f.a.y, f.a.r
        c("fov")[i] = f.fov or 75
        local vd = f.vd and f.vm ~= nil
        c("vd")[i] = vd and 1 or 0
        local src = vd and f or prev or f
        if vd then prev = f end
        local lpos, lang = src.lp or vector_origin, src.la or angle_zero
        c("vm")[i] = str.Get(src.vm)
        c("lx")[i], c("ly")[i], c("lz")[i] = lpos.x, lpos.y, lpos.z
        c("la")[i], c("lb")[i], c("lc")[i] = lang.p, lang.y, lang.r
        c("vs")[i] = src.vs or 0
        c("vc")[i] = src.vc or 0
        c("vk")[i] = src.vk or 0
        c("vb")[i] = str.Get(src.vb)
        c("vf")[i] = src.vf or 62
        c("hd")[i] = f.hd and 1 or 0
        c("hm")[i] = str.Get(f.hm)
        c("hk")[i] = f.hk or 0
        c("hb")[i] = str.Get(f.hb)
        c("ov")[i] = str.Get(f.ov)
        c("wc")[i] = str.Get(f.wc)
        c("al")[i] = f.al and 1 or 0
        c("sp")[i] = f.sp or 0
        c("og")[i] = f.og and 1 or 0
    end

    local P = {
        v = A.VERSION, base = base, n = n,
        tm = A.Pack(col.tm, 1000),
        ox = A.Pack(col.ox, 16), oy = A.Pack(col.oy, 16), oz = A.Pack(col.oz, 16),
        ap = A.PackAngles(col.ap, 50), ay = A.PackAngles(col.ay, 50), ar = A.PackAngles(col.ar, 50),
        fov = A.Pack(col.fov, 10),
        vd = A.Pack(col.vd, 1), vm = A.Pack(col.vm, 1),
        lx = A.Pack(col.lx, 100), ly = A.Pack(col.ly, 100), lz = A.Pack(col.lz, 100),
        la = A.PackAngles(col.la, 50), lb = A.PackAngles(col.lb, 50), lc = A.PackAngles(col.lc, 50),
        vs = A.Pack(col.vs, 1), vc = A.Pack(col.vc, 1000), vk = A.Pack(col.vk, 1),
        vb = A.Pack(col.vb, 1), vf = A.Pack(col.vf, 10),
        hd = A.Pack(col.hd, 1), hm = A.Pack(col.hm, 1), hk = A.Pack(col.hk, 1), hb = A.Pack(col.hb, 1),
        ov = A.Pack(col.ov, 1), wc = A.Pack(col.wc, 1),
        al = A.Pack(col.al, 1), sp = A.Pack(col.sp, 1), og = A.Pack(col.og, 1),
        ev = {}, bm = {}, ma = {},
    }

    for _, ev in ipairs(events) do
        if ev.t >= t0 and ev.t <= t1 then
            local e = { t = math.floor((ev.t - base) * 1000 + 0.5), k = ev.k }
            if ev.k == "s" then
                e.n = str.Get(ev.n)
                e.o = ev.o and str.Get(ev.o) or nil
                e.v, e.l, e.p, e.c = math.Round(ev.v, 3), ev.l, ev.p, ev.c
            end
            P.ev[#P.ev + 1] = e
        end
    end

    local usedModels = {}
    for _, f in ipairs(frames) do if f.vm then usedModels[f.vm] = true end end
    for model in pairs(usedModels) do
        if boneMods[model] and #boneMods[model] > 0 then
            P.bm[#P.bm + 1] = { str.Get(model), boneMods[model] }
        end
    end
    local usedClasses = {}
    for _, f in ipairs(frames) do if f.wc and f.wc ~= "" then usedClasses[f.wc] = true end end
    for class in pairs(usedClasses) do
        if muzzleAtt[class] then P.ma[#P.ma + 1] = { str.Get(class), muzzleAtt[class] } end
    end

    P.str = str.list
    return P
end

net.Receive(A.NET_POVREQ, function()
    local id = net.ReadUInt(16)
    local t0 = net.ReadDouble()
    local t1 = net.ReadDouble()

    local P = BuildPOV(t0, t1)
    local blob = A.Compress(P) or ""
    local total = math.max(1, math.ceil(#blob / A.CHUNK_SIZE))
    A.Debug("uploading view recording: " .. #blob .. " bytes in " .. total .. " part(s)")
    for i = 1, total do
        local part = blob:sub((i - 1) * A.CHUNK_SIZE + 1, i * A.CHUNK_SIZE)
        timer.Simple((i - 1) * 0.05, function()
            net.Start(A.NET_POVUP)
                net.WriteUInt(id, 16)
                net.WriteUInt(i, 16)
                net.WriteUInt(total, 16)
                net.WriteUInt(#part, 32)
                net.WriteData(part, #part)
            net.SendToServer()
        end)
    end
end)
