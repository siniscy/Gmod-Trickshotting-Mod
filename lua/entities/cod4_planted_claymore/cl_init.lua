include("shared.lua")


function ENT:Draw()
	self:DrawModel()
	--render.DrawBox( self:GetPos() , self:GetAngles( ) , Vector(-10,1,0), Vector(10,70,14), Color(255,0,0))
	if GetConVarNumber("Cod4_sv_Claymore_Debug") >= 1 then
		local TrData = {}
		local Ent = self
		local mins = Ent:OBBMins()
		local maxs = Ent:OBBMaxs()
		local startpos = Ent:GetPos() + Vector(0,0,5)
		local dir = Ent:GetForward( )
		local len = 150

		local TrData = util.TraceHull( {
			start = startpos,
			endpos = startpos + dir * len,
			maxs = maxs,
			mins = mins,
			filter = function( ent ) if ent == self:GetOwner() then return false end if ent:IsPlayer() or ent:IsNPC() or ent:IsVehicle() or ent:GetClass() == "prop_physics" then return true end if ent == Ent then return false end  end
		} )

		render.DrawLine( TrData.HitPos, startpos + dir * len, color_white, true)

		render.DrawLine( startpos, TrData.HitPos, Color( 0, 0, 255 ), true )
		
		local clr = color_white
		if ( TrData.Fraction<1 and !TrData.Entity:IsWorld() and TrData.Entity:GetClass() != "prop_physics") then
			clr = Color( 255, 0, 0 )
		end
		render.DrawWireframeBox( startpos, Angle( 0, 0, 0 ), mins, maxs, Color( 255, 255, 255 ), true )
		render.DrawWireframeBox( TrData.HitPos, Angle( 0, 0, 0 ), mins, maxs, clr, true )
	end




end




function ENT:OnRemove()
	if GetConVarNumber("Cod4AmbSmoke") >= 1 and self:GetNetworkedBool( "Det") then
		local effectdata = EffectData()
    	effectdata:SetOrigin(self:GetPos())
    	effectdata:SetMagnitude(3)
   		util.Effect("cod4_ambient_smoke", effectdata)
	
   	end
	timer.Destroy( self:EntIndex().."Blink" )
end 



