-- Lerped Viewmodels — integrated into kc_project_0.6
-- Original addon v2 by YuRaNnNzZZ (11/11/17)
-- Defaults set to sensitivity=1 and strength=1 for kc_project.

if SERVER then return end

-- Default values: 1 and 1 (original defaults were 7 and 5)
local lerpSensitivity = CreateClientConVar("lerpedvm_sensitivity", "1", true, false, "Controls the sensitivity of viewmodel lerp (how much mouse movement triggers it)"):GetFloat()
local lerpStrength    = CreateClientConVar("lerpedvm_strength",    "1", true, false, "Controls the strength of viewmodel lerp (how long it takes to reach destination)"):GetFloat()

cvars.AddChangeCallback("lerpedvm_sensitivity", function(_, _, new)
    lerpSensitivity = tonumber(new) or 1
end, "lerpedvm_sensitivity")

cvars.AddChangeCallback("lerpedvm_strength", function(_, _, new)
    lerpStrength = tonumber(new) or 1
end, "lerpedvm_strength")

local function EnableLerpedVM(vm)
    local oldAng = vm:GetAngles()
    local angDiff = Angle(0, 0, 0)
    vm.IsLerped = true
    function vm:CalcAbsolutePosition(pos, ang)
        if game.SinglePlayer() then
            ang = self:GetOwner():EyeAngles()
        end
        angDiff = LerpAngle(FrameTime() * lerpStrength, angDiff, ang - oldAng)
        oldAng = ang
        return pos, ang - angDiff * lerpSensitivity
    end
end

hook.Add("CalcViewModelView", "LerpedVM", function(wep, vm)
    if not vm.IsLerped then
        EnableLerpedVM(vm)
    end
end)
