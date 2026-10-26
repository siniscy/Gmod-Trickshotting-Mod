/*---------------------------------------------------------
	EFFECT:Init(data)
---------------------------------------------------------*/
function EFFECT:Init(data)
	
	
	
	self.Position 		= data:GetOrigin()
	self.Mag = data:GetMagnitude()
		
	local emitter 		= ParticleEmitter(self.Position)
		
	
		for i=1,2 do
			local Eff = emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.Position)
			Eff:SetVelocity(Vector(math.random(20,30),math.random(20,30),math.random(20,30)))
			Eff:SetLifeTime(0)
			Eff:SetDieTime(50)
			Eff:SetColor(105, 105, 105)
			Eff:SetStartAlpha(50)
			Eff:SetEndAlpha(5)
			Eff:SetStartSize(math.Rand(40, 80)*self.Mag/2 )
			Eff:SetEndSize(math.Rand(120, 150 )*self.Mag/2)
			Eff:SetRoll(0.1)
			Eff:SetRollDelta(0.1)
			Eff:SetAirResistance(70)
			Eff:SetGravity(Vector(math.Rand(3, 5), math.Rand(3, 5), 6))
		end


			
	emitter:Finish()


end


function EFFECT:Think()

	return false
end


function EFFECT:Render()
end
