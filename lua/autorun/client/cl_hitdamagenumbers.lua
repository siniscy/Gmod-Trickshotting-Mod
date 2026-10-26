local hit_txts = {}
local hit_lastcurtime = 0
local alpha = 255

local dmg_cols =
{

}

surface.CreateFont( "iHDN_Font", {
	font 		= "coolvetica",
	size 		= 50,
	weight 		= 800,
	blursize 	= 0,
	scanlines 	= 0,
	antialias 	= true,
	underline 	= false,
	italic 		= false,
	strikeout 	= false,
	symbol 		= false,
	rotary 		= false,
	shadow 		= false,
	additive 	= false,
	outline 	= true
} )


local on = true
CreateConVar("hitnums_enable", 1)
cvars.AddChangeCallback( "hitnums_enable", function()
	on = (GetConVarNumber("hitnums_enable") ~= 0)
	
	Msg("Damage indicators ")
	if on then
		MsgN("enabled")
	else
		MsgN("disabled")
		table.Empty(hit_txts)
	end
end)


function createHitNumber()

	if not on then return end
	local lply = LocalPlayer()
	
	if not lply:IsValid() then return end
	
	local data = {}
	
	local dmg = net.ReadFloat()
	local dmgtype = net.ReadUInt(32)
	

local bHitActive = true
local bHitSound = true
local x
local y
local ulti = 1

local Underwater = {}
Underwater.BulletImpact =
{
	"hit.wav",
}

hook.Add( "HUDPaint", "CHitMarker", function()

if ( bHitSound ) then
surface.PlaySound( table.Random( Underwater.BulletImpact ) )
bHitSound = false
ulti = 1
end

  local player	= LocalPlayer()
  if ( !player:Alive() ) then alpha = 0 return end
  
  if not ( ulti == 1) then
    alpha = 0
	end
	

	 -- Ask the gamemode if it's ok to do this
  if ( !gamemode.Call( "HUDShouldDraw", "CHitMarker" ) ) then return end
  
  --make hitmarker visible fade out
	timer.Simple( 0, function() alpha = 255 end )
	timer.Simple( 0.13, function() alpha = 200 end )
	timer.Simple( 0.14, function() alpha = 190 end )
	timer.Simple( 0.15, function() alpha = 180 end )
	timer.Simple( 0.16, function() alpha = 170 end )
	timer.Simple( 0.17, function() alpha = 160 end )
	timer.Simple( 0.18, function() alpha = 150 end )
	timer.Simple( 0.19, function() alpha = 140 end )
	timer.Simple( 0.11, function() alpha = 130 end )
	timer.Simple( 0.21, function() alpha = 120 end )
	timer.Simple( 0.22, function() alpha = 110 end )
	timer.Simple( 0.23, function() alpha = 100 end )
	timer.Simple( 0.24, function() alpha = 90 end )
	timer.Simple( 0.25, function() alpha = 80 end )
	timer.Simple( 0.26, function() alpha = 70 end )
	timer.Simple( 0.27, function() alpha = 60 end )
	timer.Simple( 0.28, function() alpha = 50 end )
	timer.Simple( 0.29, function() alpha = 40 end )
	timer.Simple( 0.30, function() alpha = 30 end )
	timer.Simple( 0.31, function() alpha = 20 end )
	timer.Simple( 0.32, function() alpha = 10 end )
	timer.Simple( 0.33, function() alpha = 5 end )
	timer.Simple( 0.34, function() alpha = 2 end )
	timer.Simple( 0.35, function() alpha = 0 end )
	timer.Simple( 0.35, function() ulti = 0 end )
  
  --always draw hitmarker invisible
    x = ScrW() / 2
	y = ScrH() / 2
	surface.SetDrawColor( 255, 255, 255, alpha )
	surface.DrawLine( x - 7, y - 6, x - 12, y - 11 )
	surface.DrawLine( x + 6, y - 6, x + 11, y - 11 )
	surface.DrawLine( x - 7, y + 6, x - 12, y + 11 )
	surface.DrawLine( x + 6, y + 6, x + 11, y + 11 )
	


end )
end

net.Receive( "imHDN_createHitNumber", createHitNumber)
