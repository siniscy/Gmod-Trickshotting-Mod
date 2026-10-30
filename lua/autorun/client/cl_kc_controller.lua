---- [ BUILT-IN CONTROLLER SUPPORT ] ----
-- Plays the mod on an Xbox-style controller with the same layout the mod was
-- tuned on, with nothing to set up in Steam Input. The pad is read straight
-- from GMod's input system (input.IsButtonDown / input.GetAnalogValue), the
-- same way stick_sprint.lua and sh_cod4_knife_stick.lua already read L3/R3,
-- so no keyboard key is ever emulated (emulated keys made the cursor pop
-- mid-spin).
--
--   RT  fire                    LT  aim
--   A   jump                    B   crouch
--   X   reload (a tap)          Y   weapon switch (invprev)
--   LB  kc_equip (instaswap)    RB  loadpos
--   L3  sprint (CoD latch)      R3  knife (sh_cod4_knife_stick.lua)
--   Back (Select)  scoreboard (held)   Start  pause menu
--   D-pad up  weapon switch     D-pad right  reload
--   D-pad down  noclip          D-pad left  S&D Set bot placement (cl_sesh_sd_set.lua)
--   Left stick  move            Right stick  look
--
--   kc_controller 1/0              1 = controller, 0 = keyboard & mouse
--   kc_controller_look_speed       degrees per second at full right-stick push
--   kc_controller_look_curve       1 = linear, higher = finer aim near the centre
--   kc_controller_deadzone         inner deadzone of the look stick (0-1)
--   kc_controller_outer            stick push that already counts as full (0-1)
--   kc_controller_invert_y 1/0     invert look up/down
--   kc_controller_sprint_latch 1/0 a tap of L3 keeps sprinting until you stop or aim
--   kc_controller_measure          measures a spin made with any other setup and
--                                  copies its speed into kc_controller_look_speed
--   kc_controller_debug            prints the raw stick/trigger values for 5 seconds
--
-- Mouse and keyboard keep working while controller mode is on.

local cvMode       = CreateClientConVar("kc_controller", "0", true, false,
    "Input mode: 1 = controller (built-in layout), 0 = keyboard & mouse.")
local cvLookSpeed  = CreateClientConVar("kc_controller_look_speed", "400", true, false,
    "Controller look speed in degrees per second at full right-stick push.")
local cvLookCurve  = CreateClientConVar("kc_controller_look_curve", "1", true, false,
    "Controller look response curve: 1 = linear, higher = finer aim near the centre.")
local cvDeadzone   = CreateClientConVar("kc_controller_deadzone", "0.08", true, false,
    "Controller look stick inner deadzone (0-1).")
local cvOuter      = CreateClientConVar("kc_controller_outer", "0.845", true, false,
    "Controller look stick push that already counts as full deflection (0-1).")
local cvInvertY    = CreateClientConVar("kc_controller_invert_y", "0", true, false,
    "Invert controller look up/down.")
local cvLatch      = CreateClientConVar("kc_controller_sprint_latch", "1", true, false,
    "A tap of the left stick click keeps sprinting until forward movement stops or you aim.")
-- The player's own joystick cvars from before controller mode was switched on,
-- put back when it's switched off.
local cvRestore    = CreateClientConVar("kc_controller_restore", "", true, false,
    "Internal: joystick settings to put back when controller mode is switched off.")

KC_Controller = KC_Controller or {}

local PAD_FIRST = JOYSTICK_FIRST or 114
local PAD_LAST  = JOYSTICK_LAST or 161

function KC_Controller.IsOn()
    return cvMode:GetBool()
end

-- True for a key code that came from the pad while controller mode is on. The
-- pad's own GMod binds are blocked then (this file reads every button itself),
-- and other PlayerBindPress hooks use this to ignore those presses too.
function KC_Controller.BlocksBind(code)
    return cvMode:GetBool() and isnumber(code) and code >= PAD_FIRST and code <= PAD_LAST
end

-- [ JOYSTICK CVARS ] --
-- The pad is only polled with `joystick 1`. GMod's own stick handling is
-- switched off (every joy_advaxis* = 0) so the sticks only do what this file
-- says -- otherwise the engine would add its own look/move on top.
local JOY_CVARS = {
    joystick = "1",
    joy_advanced = "1",
    joy_advaxisx = "0", joy_advaxisy = "0", joy_advaxisz = "0",
    joy_advaxisr = "0", joy_advaxisu = "0", joy_advaxisv = "0",
}

local function ApplyJoyCvars()
    for name, val in pairs(JOY_CVARS) do
        RunConsoleCommand(name, val)
    end
    RunConsoleCommand("joyadvancedupdate")
end

local function SaveJoyCvars()
    local parts = {}
    for name in pairs(JOY_CVARS) do
        local cv = GetConVar(name)
        if cv then parts[#parts + 1] = name .. "=" .. cv:GetString() end
    end
    RunConsoleCommand("kc_controller_restore", table.concat(parts, ";"))
end

local function RestoreJoyCvars()
    local saved = cvRestore:GetString()
    if saved == "" then return end
    for pair in string.gmatch(saved, "[^;]+") do
        local name, val = string.match(pair, "^([%w_]+)=(.*)$")
        if name and JOY_CVARS[name] then RunConsoleCommand(name, val) end
    end
    RunConsoleCommand("joyadvancedupdate")
    RunConsoleCommand("kc_controller_restore", "")
end

local function CheckJoystickOn()
    timer.Simple(0.5, function()
        if not cvMode:GetBool() then return end
        local cv = GetConVar("joystick")
        if cv and not cv:GetBool() then
            chat.AddText(Color(255, 200, 0), "[Controller] ",
                color_white, "GMod's gamepad support is off. Type ", Color(255, 200, 0), "joystick 1",
                color_white, " in the console, then restart the game if the pad still does nothing.")
        end
    end)
end

cvars.AddChangeCallback("kc_controller", function(_, old, new)
    if tobool(new) == tobool(old) then return end
    if tobool(new) then
        SaveJoyCvars()
        ApplyJoyCvars()
        CheckJoystickOn()
        chat.AddText(Color(255, 200, 0), "[Controller] ", color_white, "Controller mode on.")
    else
        RestoreJoyCvars()
        chat.AddText(Color(255, 200, 0), "[Controller] ", color_white, "Keyboard & mouse mode on.")
    end
end, "KC_Controller_Mode")

-- Saved as on from last session: make sure GMod's stick handling is still off.
hook.Add("InitPostEntity", "KC_Controller_Init", function()
    if cvMode:GetBool() then
        ApplyJoyCvars()
        CheckJoystickOn()
    end
end)

-- [ READING THE PAD ] --
local function Axis(code)
    return math.Clamp((input.GetAnalogValue(code) or 0) / 32767, -1, 1)
end

local function Down(code)
    return input.IsButtonDown(code)
end

-- Look and buttons pause while a menu, chat or the console has the cursor,
-- the same as the mouse does.
local function InputBlocked()
    return not system.HasFocus() or gui.IsGameUIVisible() or gui.IsConsoleVisible()
        or vgui.CursorVisible() or vgui.GetKeyboardFocus() ~= nil
end

-- [ BUTTON -> COMMAND PRESSES ] --
-- Runs `bind` the way a key bound to it would: PlayerBindPress first (so
-- instaswap's invprev handling in cl_loadouts_switch.lua and the like still
-- see it), then the command itself if nothing took it.
local function PressBind(bind)
    local ply = LocalPlayer()
    if not IsValid(ply) then return end
    if hook.Run("PlayerBindPress", ply, bind, true, BUTTON_CODE_NONE or 0) then return end
    RunConsoleCommand(bind)
end

local reloadTap = false

-- Each entry fires on the press (and `release` on the release).
local PRESS_ACTIONS = {
    [KEY_XBUTTON_Y]              = function() PressBind("invprev") end,
    [KEY_XBUTTON_UP]             = function() PressBind("invprev") end,
    [KEY_XBUTTON_X]              = function() reloadTap = true end,
    [KEY_XBUTTON_RIGHT]          = function() reloadTap = true end,
    [KEY_XBUTTON_LEFT_SHOULDER]  = function() PressBind("kc_equip") end,
    [KEY_XBUTTON_RIGHT_SHOULDER] = function() PressBind("loadpos") end,
    [KEY_XBUTTON_DOWN]           = function() PressBind("noclip") end,
    [KEY_XBUTTON_START]          = function() gui.ActivateGameUI() end,
    [KEY_XBUTTON_BACK]           = { press = function() RunConsoleCommand("+showscores") end,
                                     release = function() RunConsoleCommand("-showscores") end },
}

local wasDown = {}

hook.Add("Think", "KC_Controller_Buttons", function()
    if not cvMode:GetBool() then
        if wasDown[KEY_XBUTTON_BACK] then RunConsoleCommand("-showscores") end
        wasDown = {}
        return
    end

    -- While a menu is up every button reads as released, so a held Select
    -- still lets go of the scoreboard.
    local blocked = InputBlocked()

    for code, action in pairs(PRESS_ACTIONS) do
        local down = not blocked and Down(code)
        if down ~= (wasDown[code] or false) then
            if istable(action) then
                local fn = down and action.press or action.release
                fn()
            elseif down then
                action()
            end
        end
        wasDown[code] = down
    end
end)

-- [ STICKS + HELD BUTTONS ] --
local lastMoveTime = SysTime()
local sprintLatched = false

-- Matches how the mouse slows in ADS: the weapon's / gamemode's
-- AdjustMouseSensitivity, plus Source's zoom scaling when the FOV is pulled in.
local function SensitivityScale(ply)
    local mul = hook.Run("AdjustMouseSensitivity", 1)
    if not isnumber(mul) or mul <= 0 then mul = 1 end

    local fovDesired = GetConVar("fov_desired")
    local def = fovDesired and fovDesired:GetFloat() or 75
    local fov = ply:GetFOV()
    if fov > 0 and fov < def - 0.5 then
        local ratio = GetConVar("zoom_sensitivity_ratio")
        mul = mul * (fov / def) * (ratio and ratio:GetFloat() or 1)
    end
    return mul
end

-- Right stick push (radial deadzone, outer edge, curve) -> look deflection.
local function LookStick()
    local x, y = Axis(ANALOG_JOY_U), Axis(ANALOG_JOY_R)
    local mag = math.sqrt(x * x + y * y)
    local inner = math.Clamp(cvDeadzone:GetFloat(), 0, 0.9)
    local outer = math.Clamp(cvOuter:GetFloat(), inner + 0.05, 1)
    if mag <= inner then return 0, 0 end

    local scaled = math.Clamp((mag - inner) / (outer - inner), 0, 1)
    scaled = scaled ^ math.max(cvLookCurve:GetFloat(), 0.1)
    return x / mag * scaled, y / mag * scaled
end

local function Threshold(name, default)
    local cv = GetConVar(name)
    return cv and cv:GetFloat() or default
end

hook.Add("CreateMove", "KC_Controller_Move", function(cmd)
    local now = SysTime()
    local dt = math.min(now - lastMoveTime, 0.1)
    lastMoveTime = now

    if not cvMode:GetBool() then sprintLatched = false return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    if InputBlocked() then
        sprintLatched = false
        return
    end

    -- Look. CreateMove also runs for GMod's in-between-tick mouse samples, so
    -- turning by speed * time-since-last-call keeps it smooth at any framerate.
    local lx, ly = LookStick()
    if lx ~= 0 or ly ~= 0 then
        local rate = cvLookSpeed:GetFloat() * SensitivityScale(ply) * dt
        local ang = cmd:GetViewAngles()
        local pitchDir = cvInvertY:GetBool() and -1 or 1
        ang.p = math.Clamp(ang.p + ly * rate * pitchDir, -89, 89)
        ang.y = math.NormalizeAngle(ang.y - lx * rate)
        cmd:SetViewAngles(ang)
    end

    -- Everything below only matters on real commands, not mouse samples.
    if cmd:CommandNumber() == 0 then return end

    -- Move the way GMod's own joystick movement does (the Steam layout used
    -- "Joystick Move" into joy_advaxisx/y): past a small threshold each axis
    -- asks for cl_forwardspeed/cl_sidespeed, which the player's max speed caps.
    local mx, my = Axis(ANALOG_JOY_X), Axis(ANALOG_JOY_Y)
    if math.abs(my) > Threshold("joy_forwardthreshold", 0.15) then
        cmd:SetForwardMove(cmd:GetForwardMove() - my * Threshold("cl_forwardspeed", 10000))
    end
    if math.abs(mx) > Threshold("joy_sidethreshold", 0.15) then
        cmd:SetSideMove(cmd:GetSideMove() + mx * Threshold("cl_sidespeed", 10000))
    end

    local buttons = cmd:GetButtons()
    if Down(KEY_XBUTTON_RTRIGGER) then buttons = bit.bor(buttons, IN_ATTACK) end
    if Down(KEY_XBUTTON_LTRIGGER) then buttons = bit.bor(buttons, IN_ATTACK2) end
    if Down(KEY_XBUTTON_A) then buttons = bit.bor(buttons, IN_JUMP) end
    if Down(KEY_XBUTTON_B) then buttons = bit.bor(buttons, IN_DUCK) end

    -- X / D-pad right were a mouse-wheel +reload: one tap, never a hold.
    if reloadTap then
        buttons = bit.bor(buttons, IN_RELOAD)
        reloadTap = false
    end

    -- Sprint on L3, CoD-style latch (same rules as stick_sprint.lua).
    local held = Down(KEY_XBUTTON_STICK1)
    if cmd:GetForwardMove() <= 0 or bit.band(buttons, IN_ATTACK2) ~= 0 then
        sprintLatched = false
    elseif held and cvLatch:GetBool() then
        sprintLatched = true
    end
    if held or sprintLatched then buttons = bit.bor(buttons, IN_SPEED) end

    cmd:SetButtons(buttons)
end)

-- With controller mode on, the pad's own GMod binds (JOY1, A_BUTTON, ...) do
-- nothing -- every button is handled above, so a leftover bind would double up.
hook.Add("PlayerBindPress", "KC_Controller_BlockPadBinds", function(_, _, _, code)
    if KC_Controller.BlocksBind(code) then return true end
end)

-- [ SPIN SPEED MEASURE ] --
-- Hold the look stick fully to one side (or spin any other way) with the setup
-- you want to copy -- e.g. a Steam Input layout -- and this times the turn and
-- copies it into kc_controller_look_speed.
local MEASURE_DELAY, MEASURE_TIME = 3, 2

concommand.Add("kc_controller_measure", function()
    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    chat.AddText(Color(255, 200, 0), "[Controller] ", color_white,
        "Push the look stick fully left or right and keep it there. Measuring in "
        .. MEASURE_DELAY .. " seconds...")

    timer.Simple(MEASURE_DELAY, function()
        if not IsValid(ply) then return end
        local total, lastYaw = 0, ply:EyeAngles().y
        local startTime = SysTime()

        hook.Add("Think", "KC_Controller_Measure", function()
            if not IsValid(ply) then hook.Remove("Think", "KC_Controller_Measure") return end
            local yaw = ply:EyeAngles().y
            total = total + math.abs(math.AngleDifference(yaw, lastYaw))
            lastYaw = yaw

            local elapsed = SysTime() - startTime
            if elapsed < MEASURE_TIME then return end
            hook.Remove("Think", "KC_Controller_Measure")

            local speed = math.Round(total / elapsed)
            if speed < 10 then
                chat.AddText(Color(255, 200, 0), "[Controller] ", color_white,
                    "Barely turned (" .. speed .. " deg/s) -- nothing saved. Try again.")
                return
            end
            RunConsoleCommand("kc_controller_look_speed", tostring(speed))
            print("[Controller] measured spin speed: " .. speed .. " deg/s")
            chat.AddText(Color(255, 200, 0), "[Controller] ", color_white,
                "Spin speed: " .. speed .. " degrees/second. Saved as the controller look speed.")
        end)
    end)
end)

-- Prints what GMod reads from the pad, to check sticks/triggers are wired
-- to the axes this file expects.
concommand.Add("kc_controller_debug", function()
    local endTime = SysTime() + 5
    timer.Create("KC_Controller_Debug", 0.25, 0, function()
        if SysTime() > endTime then timer.Remove("KC_Controller_Debug") return end
        print(string.format(
            "[Controller] move X %.2f Y %.2f | look U %.2f R %.2f | Z %.2f V %.2f | LT %s RT %s",
            Axis(ANALOG_JOY_X), Axis(ANALOG_JOY_Y), Axis(ANALOG_JOY_U), Axis(ANALOG_JOY_R),
            Axis(ANALOG_JOY_Z), Axis(ANALOG_JOY_V),
            tostring(Down(KEY_XBUTTON_LTRIGGER)), tostring(Down(KEY_XBUTTON_RTRIGGER))))
    end)
end)
