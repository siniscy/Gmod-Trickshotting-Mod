if SERVER then
	AddCSLuaFile()
end

concommand.Add( "savepos", function( ply, cmd, args )
	ply.savedPosition = ply:GetPos()
	print( "Position Saved at: "..tostring(ply:GetPos()) )
	for i, ply in ipairs( player.GetAll() ) do
	ply:ChatPrint( "Position Saved at: "..tostring(ply:GetPos()) )
	end
end )

concommand.Add( "loadpos", function( ply, cmd, args )
	ply:SetPos(Vector(ply.savedPosition))
	currentVel = ply:GetVelocity()
	ply:SetVelocity(Vector(-currentVel))
	print( "Position Loaded" )
end )