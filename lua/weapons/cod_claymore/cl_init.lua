
include('shared.lua')
local SS = (ScrH()/900)
local Cod4EquipmentAmmoTable = {}
local CplantAlpha = 0
Cod4EquipmentAmmoTable[1] = { AmmoType = "cod4_m67", HudIcon = "frag"}
Cod4EquipmentAmmoTable[2] = { AmmoType = "cod4_flashbang", HudIcon = "flash"}
Cod4EquipmentAmmoTable[3] = { AmmoType = "cod4_m18", HudIcon = "smoke"}
Cod4EquipmentAmmoTable[4] = { AmmoType = "cod4_concussion", HudIcon = "stun"}

	
SWEP.DrawAmmo			= false					
SWEP.DrawCrosshair		= false					
SWEP.DrawWeaponInfoBox	= true					
SWEP.BounceWeaponIcon   = false					
SWEP.SwayScale          = 0
SWEP.BobScale           = 0

SWEP.RenderGroup 		= RENDERGROUP_OPAQUE


SWEP.WepSelectIcon		= surface.GetTextureID( "VGUI/entities/cod_claymore" )


SWEP.SpeechBubbleLid	= surface.GetTextureID( "gui/speech_lid" )


function SWEP:Cod4GetHudEquipIcon()
return Cod4EquipmentAmmoTable[self.Owner:GetNetworkedInt("EQ")].HudIcon
end

function SWEP:Cod4GetEquipAmmoType()
    return Cod4EquipmentAmmoTable[self.Owner:GetNetworkedInt("EQ")].AmmoType
end

function SWEP:DrawHUD()

    surface.SetDrawColor(255,255,255,255)
    surface.SetMaterial( Material( "hud/"..self:Cod4GetHudEquipIcon()..".png", "noclamp" ) )
    surface.DrawTexturedRect(1200*SS,800*SS,85,85)
    surface.SetTexture(0)
    local eqammount = math.Clamp(self.Owner:GetAmmoCount(self:Cod4GetEquipAmmoType()),0,99)
    draw.SimpleText(eqammount,"cod4DescriptTitle",1210*SS,850*SS,Color(255,255,255,255),100,100)

    if self.Weapon:GetCantPlantMsg() > CurTime() then
        CplantAlpha = 255 * math.sin(CurTime() * 7)
   else
        CplantAlpha = math.Clamp(CplantAlpha - 10,0,255)
   end

    draw.SimpleText("Can't Plant A Claymore Here","cod4DescriptTitle",650*SS,500*SS,Color(255,255,255,CplantAlpha),100,100)
    
end

local VmPos, VmAng = Vector(0,0,0), Angle(0,0,0)
local WantedPos, WantedAng = Vector(0,0,0), Angle(0,0,0)
local VmMovementPos, VmMovementAng = Vector(0, 0, 0), Angle(0,0,0)
local LastVmMovementPos, LastVmMovementAng = Vector(0,0,0), Angle(0,0,0)
local SmoothMovePos, SmoothMoveAng = Vector(0,0,0), Angle(0,0,0)
local VelPos, VelAng = Vector(0,0,0), Angle(0,0,0)
local LastVelPos, LastVelAng = Vector(0,0,0), Angle(0,0,0)
local SetPos, SetAng = Vector(0,0,0), Angle(0,0,0)
local SwayAngle, LastSwayAngle = Angle(0,0,0), Angle(0,0,0)
local AddSwayPos, AddSwayAng = Vector(0, 0, 0), Angle(0,0,0)
local IdlePos, IdleAng = Vector(0,0,0), Angle(0,0,0)
local TiltPos, TiltAng = Vector(0,0,0), Angle(0,0,0)
local SwayDir = Angle(0,0,0)
local FMPos, FMAng = Vector(0,0,0), Angle(0,0,0)
local IronTiltPos, IronTiltAng = Vector(0,0,0), Angle(0,0,0)
local DownOfViewPos, DownOfViewAng = Vector(0,0,0), Angle(0,0,0)
local DownOfViewPMul, DownOfViewAMul = Vector(1,1,1), Angle(1,1,1)
 
local CrouchPos = Vector(0,0,0)
 
local VmMovementMul = 1
local StepTime = 0
local StepSmooth = 0
local StepRate = 0.75
local SwayMul = 1
local StepCycleDiv = 0
local SwaySmooth = 0
local VmSmooth = 0
local DownOfView = 0
local ZAngleAffect = 0
local CrouchValue = 0
local SwayDist = 0
 
local LastRun = false
local RunMoveTime = 0
local LastIron = false
local IronMoveTime = 0
 
local LastVel = Vector(0,0,0)
 
local FireModAnim = 0
local IronsightAnim = 0
local SmoothIronsightAnim = 0
local LastIronsightAnim = 0
local DownOfView = 0
local ModelFlipMul = 1
 
SWEP.FireModAnimTime = nil
SWEP.IronsightAnimTime = nil
function SWEP:GetViewModelPosition( pos, ang )
 
     
       

        
      
            local vel = self.Owner:GetVelocity()
            local Speed = vel:Length()
            self.Owner:GetViewModel():SetNoDraw(false)
           
                    
                    SetPos = Vector(0,0,0)
                    SetAng = Angle(0,0,0)
                    
                     
            VmSmooth = 0.25 / 3
            SwayMul = 1
            VmMovementMul = GetConVarNumber("Cod4WeaponBobMul")
            IdleForce = 1
            SwaySmooth = 10
            StepCycleDiv = 35
            DirVelForce = 1
            DownOfViewPMul = Vector(1,-3,1)
            DownOfViewAMul = Angle(1,1,-10)


           
            SwayDir = self.Owner:GetAimVector():Angle()
            SwayDist = LastSwayAngle - SwayDir
            LastSwayAngle = SwayDir
            ModelFlipMul = 1
     
            if self.ViewModelFlip then
                    ModelFlipMul = -1
            end
     
            local EyeAng = self.Owner:GetAimVector():Angle()
           
            SideVel = ang:Right():DotProduct(vel) 
            ForwardVel = ang:Forward():DotProduct(vel)
            UpVel = ang:Up():DotProduct(vel)
           
            LastVelPos = VelPos
            LastVelAng = VelAng
           
     
             if IsFirstTimePredicted() or game.SinglePlayer() then
           
            if !self.dt.Ironsight then
                IdleCalc = CurTime() * 1.2
                       
                IdlePos.x = math.cos(IdleCalc / 2) * math.sin(IdleCalc) / (-30 * IdleForce) 
                IdlePos.y = math.cos(IdleCalc / 1.5) * math.sin(IdleCalc * 2) / (15 * IdleForce)
                IdlePos.z = math.cos(IdleCalc) * math.sin(IdleCalc * 2) / (20 * IdleForce) 
                IdleAng.r = math.cos(IdleCalc / 2) * math.sin(IdleCalc * 2) / (-10 * IdleForce)
                IdleAng.p = math.cos(IdleCalc / 2.5) * math.sin(IdleCalc * 3.5) / (10 * IdleForce)
                IdleAng.y = math.cos(IdleCalc / 2.5) * math.sin(IdleCalc * 3) / (5 * IdleForce)
            end
                
           
            SwayAngle = LerpAngle(FrameTime() * SwaySmooth, SwayAngle, SwayDist)
           
            SwayAngle.y = math.Clamp(SwayAngle.y, -5, 5)
           
          
            AddSwayPos.x = SwayAngle.y * (-0.07 * SwayMul) * ModelFlipMul
            AddSwayPos.y = SwayAngle.p * (0.025 * SwayMul)
            AddSwayPos.z = SwayAngle.p * -0.020 * SwayMul 
                   
            AddSwayAng.p = SwayAngle.p * (0.1 * SwayMul)
            AddSwayAng.y = SwayAngle.y * (-0.1 * SwayMul) * ModelFlipMul
            AddSwayAng.r = SwayAngle.r * (-0.1 * SwayMul) + SwayAngle.y * (0.1 * SwayMul) * ModelFlipMul
          
           
            if self.Owner:IsOnGround() and !self:IsRunning() then
     
                MaxedSpeed = math.Clamp(Speed, 0, 450)
                   
                StepSmooth = StepSmooth * StepRate + MaxedSpeed / StepCycleDiv
                StepTime = StepTime + StepSmooth * FrameTime()
                   
                
                           
                LastVmMovementPos = VmMovementPos
                LastVmMovementAng = VmMovementAng
     
                           
                if !self.dt.Ironsight then         
                    VmMovementPos.x = ((math.cos(StepTime / 6) * StepSmooth) / 25 * (math.sin(StepTime / 6) * StepSmooth) / 35) * VmMovementMul
                    VmMovementPos.y = ((math.cos(StepTime / 6) * StepSmooth) / 35 * (math.sin(StepTime / 6) * StepSmooth) / 40) * VmMovementMul
                    VmMovementPos.z = ((math.cos(StepTime / 3) * StepSmooth) / 35 * (math.sin(StepTime / 3) * StepSmooth) / 30) * VmMovementMul
                               
                    VmMovementAng.p = ((math.cos(StepTime / 3) * StepSmooth) / -20 * (math.sin(StepTime / 3) * StepSmooth) / 23) * VmMovementMul
                    VmMovementAng.y = ((math.cos(StepTime / 6) * StepSmooth) / -20 * (math.sin(StepTime / 6) * StepSmooth) / -20) * VmMovementMul
                    VmMovementAng.r = ((math.cos(StepTime / 6) * StepSmooth) / -20 * (math.sin(StepTime / 6) * StepSmooth) / -20) * VmMovementMul
                else
                    VmMovementPos.x = ((math.cos(StepTime / 6) * StepSmooth) / 25 * (math.sin(StepTime / 6) * StepSmooth) / 200) * VmMovementMul
                    VmMovementPos.y = ((math.cos(StepTime / 6) * StepSmooth) / 35 * (math.sin(StepTime / 6) * StepSmooth) / 100) * VmMovementMul
                    VmMovementPos.z = ((math.cos(StepTime / 3) * StepSmooth) / 35 * (math.sin(StepTime / 3) * StepSmooth) / 100) * VmMovementMul
                               
                    VmMovementAng.p = ((math.cos(StepTime / 3) * StepSmooth) / -20 * (math.sin(StepTime / 3) * StepSmooth) / 60) * VmMovementMul
                    VmMovementAng.y = ((math.cos(StepTime / 6) * StepSmooth) / -20 * (math.sin(StepTime / 6) * StepSmooth) / 40) * VmMovementMul
                    VmMovementAng.r = ((math.cos(StepTime / 6) * StepSmooth) / -20 * (math.sin(StepTime / 6) * StepSmooth) / 30) * VmMovementMul
                end
                    
                         
           
                SmoothMovePos = LerpVector(FrameTime() * 10, LastVmMovementPos, VmMovementPos)
                SmoothMoveAng = LerpAngle(FrameTime() * 10, LastVmMovementAng, VmMovementAng)
            end
           end

       
        SetPos = SetPos + VmMovementPos
        SetAng = SetAng + VmMovementAng
       
        WantedPos = LerpVector(FrameTime() / VmSmooth, WantedPos, SetPos)
        WantedAng = LerpAngle(FrameTime() / VmSmooth, WantedAng, SetAng)
       
        WantedPos = WantedPos + AddSwayPos
        WantedAng = WantedAng + AddSwayAng
       
        
       
        ang = ang * 1
       
        ang:RotateAroundAxis(ang:Right(), VmAng.p)
        ang:RotateAroundAxis(ang:Up(), VmAng.y)
        ang:RotateAroundAxis(ang:Forward(), VmAng.r)   
       
        Right = ang:Right()
        Up = ang:Up()
        Forward = ang:Forward()
 
        VmPos.x = WantedPos.x + IdlePos.x + VelPos.x + CrouchPos.x + FMPos.x + IronTiltPos.x + DownOfViewPos.x
        VmPos.y = WantedPos.y + IdlePos.y + VelPos.y + CrouchPos.y + FMPos.y + IronTiltPos.y + DownOfViewPos.y
        VmPos.z = WantedPos.z + IdlePos.z + VelPos.z + CrouchPos.z + FMPos.z + IronTiltPos.z + DownOfViewPos.z
       
        VmAng.p = WantedAng.p + IdleAng.p + FMAng.p + VelAng.p + IronTiltAng.p + DownOfViewAng.p
        VmAng.y = WantedAng.y + IdleAng.y + FMAng.y + VelAng.y + IronTiltAng.y + DownOfViewAng.y
        VmAng.r = WantedAng.r + IdleAng.r + FMAng.r + VelAng.r + IronTiltAng.r + DownOfViewAng.r
       
        pos = pos + VmPos.x * Right
        pos = pos + VmPos.y * Forward
        pos = pos + VmPos.z * Up
        
        return pos, ang
       
end

local FT, CT, vel, cos1, cos2, intensity
local curang, curviewbob = Angle(0, 0, 0), Angle(0, 0, 0)
local idlemul, walkmul, runmul
function SWEP:CalcView(ply, pos, ang, fov)
    
    FT, CT = FrameTime(), CurTime()
    intensity = 1  
    fov = fov
   bobmul = 1
    idlemul = GetConVarNumber("Cod4HeadBobIdleMul")
    walkmul = GetConVarNumber("Cod4HeadBobWalkMul")
    runmul = GetConVarNumber("Cod4HeadBobRunMul")
    
    
        vel = self.Owner:GetVelocity():Length()

        if self.Owner:OnGround() and vel > self.Owner:GetWalkSpeed() * 0.3 then
            if vel < self.Owner:GetWalkSpeed() * 1.2 then
                cos1 = math.cos(CT * 15) * walkmul
                cos2 = math.cos(CT * 12) * walkmul
                curviewbob.p = cos1 * 0.15 * walkmul
                curviewbob.y = cos2 * 0.1 * walkmul
                
            else
                cos1 = math.cos(CT * 20) * runmul
                cos2 = math.cos(CT * 10) * runmul
                curviewbob.p = cos1  /3 * runmul
                curviewbob.y = cos2 /2  * runmul
            end
        else
            if !self.dt.Ironsight then
                cos1 = math.cos(CT * 1.5) * idlemul 
                cos2 = math.cos(CT * 0.5) * idlemul
                curviewbob.p = cos1 / 3  * idlemul
                curviewbob.y = cos2 /3 * idlemul
            end
        end
   

    
    return pos, ang + curviewbob, fov
end


