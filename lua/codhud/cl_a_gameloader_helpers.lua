---- [ CLIENT GAME LOADER & GLOBAL HELPERS ] ----
CoDHUD = CoDHUD or {}
CoDHUD.Factions = CoDHUD.Factions or {}
CoDHUD.Gamemodes = CoDHUD.Gamemodes or {}

-- [[ RESOLUTION SCALING ]]
local BASE_W, BASE_H = 1920, 1080

function CoDHUD_GetUIScale()
    local scaleX = ScrW() / BASE_W
    local scaleY = ScrH() / BASE_H
    return math.min(scaleX, scaleY)
end

function CoDHUD_S(x)  return math.Round(x * CoDHUD_GetUIScale()) end
function CoDHUD_SX(x) return math.Round(x * CoDHUD_GetUIScale()) end
function CoDHUD_SY(y) return math.Round(y * CoDHUD_GetUIScale()) end

-- [[ FONT INIT ]]
local function InitiateCoDFonts()
	-- [ SETTINGS ]
    surface.CreateFont( "CoDHUD_Settings_Main",		{ font = "Conduit ITC", size = CoDHUD_S(42), weight = 10,  antialias = true })
	
	-- [ CoD4 ]
	-- Hitmarker / XP
	surface.CreateFont( "CoD4_Score_Main",			{ font = "Carbon Regular", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true })
	surface.CreateFont( "CoD4_Score_Plus",			{ font = "Carbon Regular", size = CoDHUD_S(32), weight = 800, antialias = true, shadow = true })
	
	-- Round End
	surface.CreateFont( "CoD4_RE_Sc_Pri",			{ font = "Carbon Regular", size = CoDHUD_S(54),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Sc_Sec",			{ font = "Carbon Regular", size = CoDHUD_S(54),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Sc_Shd",			{ font = "Carbon Regular", size = CoDHUD_S(54),  weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "CoD4_RE_Re_Pri",			{ font = "Carbon Regular", size = CoDHUD_S(72), weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Re_Sec",			{ font = "Carbon Regular", size = CoDHUD_S(72), weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Re_Shd",			{ font = "Carbon Regular", size = CoDHUD_S(72), weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "CoD4_RE_Li_Pri",			{ font = "Carbon Regular", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Li_Sec",			{ font = "Carbon Regular", size = CoDHUD_S(48),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "CoD4_RE_Li_Shd",			{ font = "Carbon Regular", size = CoDHUD_S(48),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "CoD4_RE_Bonus",			{ font = "Carbon Regular", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })

	-- Round Start
    surface.CreateFont( "CoD4_RS_Timer",			{ font = "Carbon Regular", size = CoDHUD_S(80), weight = 400, antialias = true, shadow = true })

	-- Score Bar
	surface.CreateFont( "CoD4_Timer", 				{ font = "Carbon Regular", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = false, })
    surface.CreateFont( "CoD4_Status",				{ font = "Carbon Regular", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "CoD4_Font",				{ font = "Carbon Regular", size = CoDHUD_S(36), weight = 400, antialias = true, })
			
	-- Scoreboard
    surface.CreateFont( "CoD4_Scoreboard_Text",		{ font = "Carbon Regular", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "CoD4_Scoreboard_Headers",	{ font = "Carbon Regular", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "CoD4_Scoreboard_Timer",	{ font = "BankGothic Md BT", size = CoDHUD_S(34), weight = 400, antialias = true, })
	
	-- Weapon HUD
    surface.CreateFont("CoD4_Res",					{ font = "Carbon Regular", size = CoDHUD_S(64), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("CoD4_Res_3D",				{ font = "Carbon Regular", size = CoDHUD_S(44), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("CoD4_Res_4D",				{ font = "Carbon Regular", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("CoD4_Wep_Name",				{ font = "Carbon Regular", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("CoD4_Stat_Font",			{ font = "Carbon Regular", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("CoD4_Ammo_Alt",				{ font = "Carbon Regular", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true, extended = true })
	
	-- [ WaW ]
	-- Challenges
    surface.CreateFont( "WaW_ChalHeader_Pri",		{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_ChalHeader_Sec",		{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_ChalHeader_Shd",		{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true , extended = true })

    surface.CreateFont( "WaW_ChalHeader",			{ font = "Optima Std Roman", size = CoDHUD_S(50), weight = 800,  antialias = true, extended = true })
    surface.CreateFont( "WaW_ChalHeader_Glow",		{ font = "Optima Std Roman", size = CoDHUD_S(52), weight = 1000, blursize = CoDHUD_S(12), antialias = true, extended = true })
    surface.CreateFont( "WaW_ChalSub",				{ font = "Optima Std Roman", size = CoDHUD_S(28), weight = 400,  antialias = true, extended = true })
	
	-- Chat
	surface.CreateFont( "WaW_ChatFont",				{ font = "Optima Std Roman",  size = CoDHUD_S(22),  weight = 400,  antialias = true, shadow = true })
	
	-- Hitmarker / XP
	surface.CreateFont( "WaW_Score_Main",			{ font = "Optima Std Roman", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true })
	surface.CreateFont( "WaW_Score_Plus",			{ font = "Optima Std Roman", size = CoDHUD_S(32), weight = 800, antialias = true, shadow = true })
	
	-- Round End
	surface.CreateFont( "WaW_RE_Sc_Pri",			{ font = "Optima Std Roman", size = CoDHUD_S(54),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Sc_Sec",			{ font = "Optima Std Roman", size = CoDHUD_S(54),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Sc_Shd",			{ font = "Optima Std Roman", size = CoDHUD_S(54),  weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "WaW_RE_Re_Pri",			{ font = "Optima Std Roman", size = CoDHUD_S(72), weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Re_Sec",			{ font = "Optima Std Roman", size = CoDHUD_S(72), weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Re_Shd",			{ font = "Optima Std Roman", size = CoDHUD_S(72), weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "WaW_RE_Li_Pri",			{ font = "Optima Std Roman", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Li_Sec",			{ font = "Optima Std Roman", size = CoDHUD_S(48),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "WaW_RE_Li_Shd",			{ font = "Optima Std Roman", size = CoDHUD_S(48),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "WaW_RE_Bonus",				{ font = "Optima Std Roman", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
		
	-- Round Start	
	surface.CreateFont( "WaW_RS_H_Pri",				{ font = "Optima Std Roman", size = CoDHUD_S(64), weight = 800,  blursize = 0, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_RS_H_Sec",				{ font = "Optima Std Roman", size = CoDHUD_S(64), weight = 800,  blursize = 5, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_RS_H_Shd",				{ font = "Optima Std Roman", size = CoDHUD_S(64), weight = 800, blursize = 2, antialias = false, outline = true , extended = true })

    surface.CreateFont( "WaW_RS_O_Pri",				{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_RS_O_Sec",				{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false, extended = true })
    surface.CreateFont( "WaW_RS_O_Shd",				{ font = "Optima Std Roman", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true , extended = true })

    surface.CreateFont( "WaW_RS_S_Pri",				{ font = "Optima Std Roman", size = CoDHUD_S(32), weight = 400, antialias = true, shadow = true })

    surface.CreateFont( "WaW_RS_Timer",				{ font = "Optima Std Roman", size = CoDHUD_S(80), weight = 400, antialias = true, shadow = true })

	-- Round Start
    surface.CreateFont( "WaW_RS_Timer",				{ font = "Optima Std Roman", size = CoDHUD_S(60), weight = 400, antialias = true, shadow = true })

	-- Score Bar
	surface.CreateFont( "WaW_Timer", 				{ font = "Optima Std Roman", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = false, })
    surface.CreateFont( "WaW_Status",				{ font = "Optima Std Roman", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "WaW_Font",					{ font = "Optima Std Roman", size = CoDHUD_S(32), weight = 400, antialias = true, })

	-- Scoreboard
    surface.CreateFont( "WaW_Scoreboard_Text",		{ font = "Optima Std Roman", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "WaW_Scoreboard_Headers",	{ font = "Optima Std Roman", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "WaW_Scoreboard_Timer",		{ font = "Optima Std Roman", size = CoDHUD_S(34), weight = 400, antialias = true, })
	
	-- Weapon HUD
    surface.CreateFont("WaW_Res",					{ font = "Optima Std Roman", size = CoDHUD_S(64), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("WaW_Res_3D",				{ font = "Optima Std Roman", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("WaW_Res_4D",				{ font = "Optima Std Roman", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("WaW_Wep_Name",				{ font = "Optima Std Roman", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("WaW_Stat_Font",			{ font = "Optima Std Roman", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("WaW_Ammo_Alt",				{ font = "Optima Std Roman", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true, extended = true })
	
	-- [ MW2 ]
	-- Challenges
    surface.CreateFont( "MW2_ChalHeader_Pri",		{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_ChalHeader_Sec",		{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_ChalHeader_Shd",		{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "MW2_ChalHeader",			{ font = "Conduit ITC", size = CoDHUD_S(50), weight = 800,  antialias = true })
    surface.CreateFont( "MW2_ChalHeader_Glow",		{ font = "Conduit ITC", size = CoDHUD_S(52), weight = 1000, blursize = CoDHUD_S(12), antialias = true })
    surface.CreateFont( "MW2_ChalSub",				{ font = "Conduit ITC", size = CoDHUD_S(28), weight = 400,  antialias = true })
	
	-- Chat
	surface.CreateFont( "MW2_ChatFont",				{ font = "Conduit ITC",  size = CoDHUD_S(22),  weight = 400,  antialias = true, shadow = true })
	
	-- Hitmarker / XP
	surface.CreateFont( "MW2_Score_Main",			{ font = "BankGothic Md BT", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true })
	surface.CreateFont( "MW2_Score_Plus",			{ font = "BankGothic Md BT", size = CoDHUD_S(32), weight = 800, antialias = true, shadow = true })
	
	-- Killfeed
    surface.CreateFont( "MW2_KillfeedFont",			{ font = "Conduit ITC", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, outline = false, })
	
	-- Medals
	surface.CreateFont( "MW2_MedalPrimary",			{ font = "Conduit ITC", size = CoDHUD_S(42), weight = 800,  antialias = true })
	surface.CreateFont( "MW2_MedalGlow",			{ font = "Conduit ITC", size = CoDHUD_S(44), weight = 1000, antialias = true, blursize = CoDHUD_S(12) })
	surface.CreateFont( "MW2_MedalOutline",			{ font = "Conduit ITC", size = CoDHUD_S(42), weight = 900,  antialias = true, outline = false })
	surface.CreateFont( "MW2_MedalPoints",			{ font = "Conduit ITC", size = CoDHUD_S(30), weight = 400,  antialias = true })
	surface.CreateFont( "MW2_MedalDesc",			{ font = "Conduit ITC", size = CoDHUD_S(26), weight = 500,  antialias = true })
	
	-- Round End
	surface.CreateFont( "MW2_RE_Sc_Pri",			{ font = "BankGothic Md BT", size = CoDHUD_S(54),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Sc_Sec",			{ font = "BankGothic Md BT", size = CoDHUD_S(54),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Sc_Shd",			{ font = "BankGothic Md BT", size = CoDHUD_S(54),  weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "MW2_RE_Re_Pri",			{ font = "BankGothic Md BT", size = CoDHUD_S(72), weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Re_Sec",			{ font = "BankGothic Md BT", size = CoDHUD_S(72), weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Re_Shd",			{ font = "BankGothic Md BT", size = CoDHUD_S(72), weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "MW2_RE_Li_Pri",			{ font = "BankGothic Md BT", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Li_Sec",			{ font = "BankGothic Md BT", size = CoDHUD_S(48),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RE_Li_Shd",			{ font = "BankGothic Md BT", size = CoDHUD_S(48),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "MW2_RE_Bonus",				{ font = "BankGothic Md BT", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
		
	-- Round Start	
	surface.CreateFont( "MW2_RS_H_Pri",				{ font = "Carbon Regular", size = CoDHUD_S(64), weight = 800,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RS_H_Sec",				{ font = "Carbon Regular", size = CoDHUD_S(64), weight = 800,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RS_H_Shd",				{ font = "Carbon Regular", size = CoDHUD_S(64), weight = 800, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "MW2_RS_O_Pri",				{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RS_O_Sec",				{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "MW2_RS_O_Shd",				{ font = "Carbon Regular", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "MW2_RS_S_Pri",				{ font = "Carbon Regular", size = CoDHUD_S(32), weight = 400, antialias = true, shadow = true })

    surface.CreateFont( "MW2_RS_Timer",				{ font = "BankGothic Md BT", size = CoDHUD_S(80), weight = 400, antialias = true, shadow = true })

	-- Score Bar	
	surface.CreateFont( "MW2_Timer", 				{ font = "BankGothic Md BT", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = false, })
    surface.CreateFont( "MW2_Status",				{ font = "BankGothic Md BT", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "MW2_Font",					{ font = "BankGothic Md BT", size = CoDHUD_S(36), weight = 400, antialias = true, })
		
	-- Scoreboard
    surface.CreateFont( "MW2_Scoreboard_Text",		{ font = "Conduit ITC Light", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "MW2_Scoreboard_Timer",		{ font = "BankGothic Md BT", size = CoDHUD_S(34), weight = 400, antialias = true, })
	
	-- IFF
    surface.CreateFont("MW2_TargetName_Primary",	{ font = "Conduit ITC",  size = CoDHUD_S(32), weight = 400, antialias = true, shadow = true })

	-- Voice Chat
	surface.CreateFont("MW2_VoiceFont",				{ font = "Conduit ITC",  size = CoDHUD_S(30),  weight = 600,  antialias = true, shadow = true })
	
	-- Weapon HUD
    surface.CreateFont("MW2_Res",					{ font = "BankGothic Md BT", size = CoDHUD_S(64), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("MW2_Res_3D",				{ font = "BankGothic Md BT", size = CoDHUD_S(48), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("MW2_Res_4D",				{ font = "BankGothic Md BT", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("MW2_Wep_Name",				{ font = "BankGothic Md BT", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("MW2_Stat_Font",				{ font = "BankGothic Md BT", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("MW2_Ammo_Alt",				{ font = "BankGothic Md BT", size = CoDHUD_S(36), weight = 400, antialias = true, shadow = true, extended = true })	

	-- [ BO1 ]
	-- Challenges
    surface.CreateFont( "BO1_ChalHeader",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(64), weight = 800,  antialias = true })
    surface.CreateFont( "BO1_ChalSub",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(40), weight = 400,  antialias = true })
	
	-- Chat
	surface.CreateFont( "BO1_ChatFont",				{ font = "HelveticaNeue MediumCond",  size = CoDHUD_S(22),  weight = 400,  antialias = true, shadow = true })
	
	-- Hitmarker / XP
	surface.CreateFont( "BO1_Score_Main",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(46), weight = 400, antialias = true, shadow = true })
	surface.CreateFont( "BO1_Score_Plus",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(42), weight = 800, antialias = true, shadow = true })
	
	-- Killfeed
    surface.CreateFont( "BO1_KillfeedFont",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, outline = false, })
	
	-- Medals
	surface.CreateFont( "BO1_MedalPrimary",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(72), weight = 100,  antialias = true })
	surface.CreateFont( "BO1_MedalPoints",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(28), weight = 400,  antialias = true })
	surface.CreateFont( "BO1_MedalDesc",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(32), weight = 500,  antialias = true })
	
	-- Round End
	surface.CreateFont( "BO1_RE_Sc_Pri",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(54),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Sc_Sec",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(54),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Sc_Shd",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(54),  weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "BO1_RE_Re_Pri",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(72), weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Re_Sec",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(72), weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Re_Shd",			{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(72), weight = 400, blursize = 2, antialias = false, outline = true  })
    
    surface.CreateFont( "BO1_RE_Li_Pri",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Li_Sec",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(48),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RE_Li_Shd",			{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(48),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO1_RE_Bonus",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
		
	-- Round Start	
	surface.CreateFont( "BO1_RS_H_Pri",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(64), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RS_H_Sec",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(64), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RS_H_Shd",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(64), weight = 10, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO1_RS_O_Pri",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RS_O_Sec",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO1_RS_O_Shd",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO1_RS_S_Pri",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(28), weight = 1, antialias = true, shadow = true })

    surface.CreateFont( "BO1_RS_Timer",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(64), weight = 400, antialias = true, shadow = true })

	-- Score Bar	
	surface.CreateFont( "BO1_Timer", 				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = false, })
    surface.CreateFont( "BO1_Status",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(28), weight = 0, antialias = true, shadow = true, })
    surface.CreateFont( "BO1_Font",					{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(40), weight = 0, antialias = true, })
    surface.CreateFont( "BO1_Font2",					{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(30), weight = 400, antialias = true, })
		
	-- Scoreboard
    surface.CreateFont( "BO1_Scoreboard_Text",		{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(28), weight = 100, antialias = true, shadow = true, })
    surface.CreateFont( "BO1_Scoreboard_Score",		{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(64), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "BO1_Scoreboard_Timer",		{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(34), weight = 400, antialias = true, })
	
	-- IFF
    surface.CreateFont("BO1_TargetName_Primary",	{ font = "HelveticaNeue MediumCond",  size = CoDHUD_S(32), weight = 400, antialias = true, shadow = true })

	-- Voice Chat
	surface.CreateFont("BO1_VoiceFont",				{ font = "HelveticaNeue MediumCond",  size = CoDHUD_S(30),  weight = 600,  antialias = true, shadow = true })
	
	-- Weapon HUD
    surface.CreateFont("BO1_Res",					{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("BO1_Res_Large",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(56), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("BO1_Wep_Name",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(38), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("BO1_Stat_Font",				{ font = "MorrisSansW04-MediumCond", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont("BO1_Ammo_Alt",				{ font = "HelveticaNeue MediumCond", size = CoDHUD_S(20), weight = 400, antialias = true, shadow = true, extended = true })

	-- [ BO2 ]
	-- Challenges
    surface.CreateFont( "BO2_ChalHeader",			{ font = "AgencyFB", size = CoDHUD_S(48), weight = 800,  antialias = true })
    surface.CreateFont( "BO2_ChalSub",				{ font = "AgencyFB", size = CoDHUD_S(32), weight = 400,  antialias = true })

	-- Chat
	surface.CreateFont( "BO2_ChatFont",				{ font = "AgencyFB",  size = CoDHUD_S(22),  weight = 400,  antialias = true, shadow = true })

	-- Hitmarker / XP
	surface.CreateFont( "BO2_Score_Main",			{ font = "AgencyFB", size = CoDHUD_S(46), weight = 400, antialias = true, shadow = true })
	surface.CreateFont( "BO2_Score_Plus",			{ font = "AgencyFB", size = CoDHUD_S(42), weight = 800, antialias = true, shadow = true })

	-- Killfeed
    surface.CreateFont( "BO2_KillfeedFont",			{ font = "AgencyFB", size = CoDHUD_S(34), weight = 400, antialias = true, shadow = true, outline = false, })

	-- Medals
	surface.CreateFont( "BO2_MedalPrimary",			{ font = "AgencyFB", size = CoDHUD_S(32), weight = 100,  antialias = true })
	surface.CreateFont( "BO2_MedalPoints",			{ font = "AgencyFB", size = CoDHUD_S(28), weight = 400,  antialias = true })
	surface.CreateFont( "BO2_MedalDesc",			{ font = "AgencyFB", size = CoDHUD_S(26), weight = 500,  antialias = true })

	-- Round End
	surface.CreateFont( "BO2_RE_Sc_Pri",			{ font = "AgencyFB", size = CoDHUD_S(54),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Sc_Sec",			{ font = "AgencyFB", size = CoDHUD_S(54),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Sc_Shd",			{ font = "AgencyFB", size = CoDHUD_S(54),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO2_RE_Re_Pri",			{ font = "AgencyFB", size = CoDHUD_S(72), weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Re_Sec",			{ font = "AgencyFB", size = CoDHUD_S(72), weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Re_Shd",			{ font = "AgencyFB", size = CoDHUD_S(72), weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO2_RE_Li_Pri",			{ font = "AgencyFB", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Li_Sec",			{ font = "AgencyFB", size = CoDHUD_S(48),  weight = 400, blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RE_Li_Shd",			{ font = "AgencyFB", size = CoDHUD_S(48),  weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO2_RE_Bonus",				{ font = "AgencyFB", size = CoDHUD_S(48),  weight = 400, blursize = 0, antialias = true,  outline = false })

	-- Round Start
	surface.CreateFont( "BO2_RS_H_Pri",				{ font = "AgencyFB", size = CoDHUD_S(32), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RS_H_Sec",				{ font = "AgencyFB", size = CoDHUD_S(32), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RS_H_Shd",				{ font = "AgencyFB", size = CoDHUD_S(32), weight = 10, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO2_RS_O_Pri",				{ font = "AgencyFB", size = CoDHUD_S(46), weight = 10,  blursize = 0, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RS_O_Sec",				{ font = "AgencyFB", size = CoDHUD_S(46), weight = 10,  blursize = 5, antialias = true,  outline = false })
    surface.CreateFont( "BO2_RS_O_Shd",				{ font = "AgencyFB", size = CoDHUD_S(46), weight = 400, blursize = 2, antialias = false, outline = true  })

    surface.CreateFont( "BO2_RS_S_Pri",				{ font = "AgencyFB", size = CoDHUD_S(36), weight = 1, antialias = true, shadow = true })
    surface.CreateFont( "BO2_RS_Timer",				{ font = "AgencyFB", size = CoDHUD_S(48), weight = 400, antialias = true, shadow = true })

	-- Score Bar
	surface.CreateFont( "BO2_Timer", 				{ font = "AgencyFB", size = CoDHUD_S(34), weight = 400, antialias = true, italic = true, })
    surface.CreateFont( "BO2_Status",				{ font = "AgencyFB", size = CoDHUD_S(34), weight = 0, antialias = true, italic = true, })
    surface.CreateFont( "BO2_Font",					{ font = "AgencyFB", size = CoDHUD_S(72), weight = 0, antialias = true, italic = true, })
    surface.CreateFont( "BO2_Font2",				{ font = "AgencyFB", size = CoDHUD_S(48), weight = 400, antialias = true, italic = true, })

	-- Scoreboard
    surface.CreateFont( "BO2_Scoreboard_Text",		{ font = "AgencyFB", size = CoDHUD_S(32), weight = 100, antialias = true, shadow = true, })
    surface.CreateFont( "BO2_Scoreboard_Text2",		{ font = "AgencyFB", size = CoDHUD_S(36), weight = 100, antialias = true, shadow = true, })
    surface.CreateFont( "BO2_Scoreboard_Score",		{ font = "AgencyFB", size = CoDHUD_S(72), weight = 400, antialias = true, shadow = true, })
    surface.CreateFont( "BO2_Scoreboard_Timer",		{ font = "AgencyFB", size = CoDHUD_S(34), weight = 400, antialias = true, })

	-- IFF
    surface.CreateFont( "BO2_TargetName_Primary",	{ font = "AgencyFB",  size = CoDHUD_S(32), weight = 400, antialias = true, shadow = true })

	-- Voice Chat
	surface.CreateFont( "BO2_VoiceFont",			{ font = "AgencyFB",  size = CoDHUD_S(30),  weight = 600,  antialias = true, shadow = true })

	-- Weapon HUD
    surface.CreateFont( "BO2_Res",					{ font = "AgencyFB", size = CoDHUD_S(54), weight = 400, antialias = true, shadow = true, italic = true, extended = true })
    surface.CreateFont( "BO2_Res_Large",			{ font = "AgencyFB", size = CoDHUD_S(73), weight = 400, antialias = true, shadow = true, italic = true, extended = true })
    surface.CreateFont( "BO2_Wep_Name",				{ font = "AgencyFB", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, italic = true, extended = true })
    surface.CreateFont( "BO2_Stat_Font",			{ font = "AgencyFB", size = CoDHUD_S(28), weight = 400, antialias = true, shadow = true, extended = true })
    surface.CreateFont( "BO2_Ammo_Alt",				{ font = "AgencyFB", size = CoDHUD_S(26), weight = 400, antialias = true, shadow = true, italic = true, extended = true })
end

InitiateCoDFonts()

hook.Add("OnScreenSizeChanged", "CoDHUD_ReinitChallengeFonts", function()
    InitiateCoDFonts()
end)

-- Restored from the original mini_dm_gamemode addon this was forked from --
-- bo2.lua's weaponinfo() (weapon name display) still calls this, and its
-- absence here was throwing "attempt to call global 'CoDHUD_UpperText' (a
-- nil value)" on every single frame, which aborted that HUD element
-- mid-draw: everything after the crash point (weapon name, alt/clip ammo,
-- low-ammo status text) never rendered, leaving only the reserve ammo
-- number that had already drawn before the crash.
local utf8_upper_map = {
    -- Latin-1 Supplement
    ["à"]="À",["á"]="Á",["â"]="Â",["ã"]="Ã",["ä"]="Ä",["å"]="Å",["æ"]="Æ",["ç"]="Ç",["è"]="È",["é"]="É",["ê"]="Ê",
    ["ë"]="Ë",["ì"]="Ì",["í"]="Í",["î"]="Î",["ï"]="Ï",["ð"]="Ð",["ñ"]="Ñ",["ò"]="Ò",["ó"]="Ó",["ô"]="Ô",
    ["õ"]="Õ", ["ö"]="Ö", ["ø"]="Ø", ["ù"]="Ù", ["ú"]="Ú", ["û"]="Û", ["ü"]="Ü", ["ý"]="Ý", ["þ"]="Þ", ["ß"]="SS",

    -- Latin Extended-A (common EU letters)
    ["ą"]="Ą",["ć"]="Ć",["ę"]="Ę",["ł"]="Ł",["ń"]="Ń",["ś"]="Ś",["ź"]="Ź",["ż"]="Ż",["č"]="Č",["ď"]="Ď",
    ["ě"]="Ě",["ň"]="Ň",["ř"]="Ř",["š"]="Š",["ť"]="Ť",["ů"]="Ů",["ž"]="Ž",["ā"]="Ā",["ē"]="Ē",["ī"]="Ī",["ū"]="Ū",["ō"]="Ō",

    -- Greek
    ["α"]="Α",["β"]="Β",["γ"]="Γ",["δ"]="Δ",["ε"]="Ε",["ζ"]="Ζ",["η"]="Η",["θ"]="Θ",["ι"]="Ι",["κ"]="Κ",["λ"]="Λ",["μ"]="Μ",
    ["ν"]="Ν",["ξ"]="Ξ",["ο"]="Ο",["π"]="Π",["ρ"]="Ρ",["σ"]="Σ",["ς"]="Σ",["τ"]="Τ",["υ"]="Υ",["φ"]="Φ",["χ"]="Χ",["ψ"]="Ψ",["ω"]="Ω",

    -- Cyrillic
    ["а"]="А",["б"]="Б",["в"]="В",["г"]="Г",["д"]="Д",["е"]="Е",["ё"]="Ё",["ж"]="Ж",["з"]="З",["и"]="И",["й"]="Й",["к"]="К",["л"]="Л",
    ["м"]="М",["н"]="Н",["о"]="О",["п"]="П",["р"]="Р",["с"]="С",["т"]="Т",["у"]="У",["ф"]="Ф",["х"]="Х",["ц"]="Ц",["ч"]="Ч",["ш"]="Ш",["щ"]="Щ",
    ["ъ"]="Ъ",["ы"]="Ы",["ь"]="Ь",["э"]="Э",["ю"]="Ю",["я"]="Я",
}

function CoDHUD_UpperText(str)
    if not str then return "" end

    -- First pass: ASCII upper (fast + handles A-Z)
    str = string.upper(str)

    -- UTF-8 pass
    return (str:gsub("[%z\1-\127\194-\244][\128-\191]*", function(c)
        return utf8_upper_map[c] or c
    end))
end