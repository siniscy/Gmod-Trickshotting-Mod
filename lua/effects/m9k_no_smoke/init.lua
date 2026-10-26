function EFFECT:Init(data)
	self.Entity = data:GetEntity()
	pos = data:GetOrigin()
	self.Emitter = ParticleEmitter(pos)
	for i=1, 100 do
		local particle = self.Emitter:Add( "particle/smokesprites_000"..math.random(1,9), pos)
		if (particle) then
			particle:SetVelocity( VectorRand():GetNormalized()*math.Rand(300, 600) )
			if i <= 5 then 
			particle:SetDieTime( 25 )
			else
			particle:SetDieTime( math.Rand( 15, 25 ) )
			end
			particle:SetStartAlpha( 1000 )
			particle:SetEndAlpha( 1000 )
			particle:SetStartSize( 0 )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(0, 360) )
			particle:SetRollDelta( math.Rand(-1, 1) )
			particle:SetColor( 0 , 0, 0 ) 
			particle:SetAirResistance( 100 ) 
			//particle:SetGravity( Vector(math.Rand(-30, 30),math.Rand(-30, 30), -200 )) 	
			particle:SetCollide( true )
			particle:SetBounce( 1 )
		end
	end

end

function EFFECT:Think()
return false
end

function EFFECT:Render()

end