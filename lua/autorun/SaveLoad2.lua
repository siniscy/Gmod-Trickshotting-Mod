if SERVER then
	AddCSLuaFile()
end

hook.Add( "KeyPress", "loadpos", function( ply, key )
	if ( key == IN_ALT2  ) then
			player.savedPosition = ply:GetPos()
			print( "Position Saved at: "..tostring(player.savedPosition, ply) )
		end

	if ( key == IN_ALT1  ) then
			print(player.savedPosition, ply)
			ply:SetPos(Vector( player.savedPosition ))
		end
end)
