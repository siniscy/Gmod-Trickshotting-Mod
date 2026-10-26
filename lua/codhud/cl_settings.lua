---- [ CLIENT SETTINGS FILE ] ----

-- [[ CLIENT CONVARS ]]
CreateClientConVar("codhud_quickdisable_hud", "0", true, false, "Quickly disable all HUD options.")
CreateClientConVar("codhud_quickdisable_audio", "0", true, false, "Quickly disable all Audio options.")
CreateConVar("eb_enabled", "0", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Enable explosive bullets")
CreateConVar("eb",         "25", FCVAR_ARCHIVE + FCVAR_REPLICATED, "Explosive bullets blast radius (0-300)")

CreateClientConVar("codhud_enable_announcer", "1", true, false, "Enable or disable the announcer voices.")
CreateClientConVar("codhud_enable_announcer_english", "0", true, false, "Force the announcer voice to use English ones, regardless of language.")
CreateClientConVar("codhud_enable_music", "1", true, false, "Enable or disable the end-game music.")
CreateClientConVar("codhud_enable_suspense", "1", true, false, "Enable or disable the ambient music.")

CreateClientConVar("codhud_enable_medals", "1", true, false, "Enable or disable Kill Medals.")
CreateClientConVar("codhud_enable_minimap", "1", true, false, "Enable or disable the Minimap.")
CreateClientConVar("codhud_enable_medal_faster", "0", true, false, "Enable or disable Kill Medals moving by faster if there's many queued up at once.")
CreateClientConVar("codhud_enable_scorebar", "1", true, false, "Enable or disable the Scorebar.")
CreateClientConVar("codhud_enable_hitmarker", "1", true, false, "Enable or disable the Hitmarker.")
CreateClientConVar("codhud_enable_xp", "1", true, false, "Enable or disable XP text.")
CreateClientConVar("codhud_enable_killfeed", "1", true, false, "Enable or disable the Kill Feed.")
CreateClientConVar("codhud_enable_weaponinfo", "1", true, false, "Enable or disable the Weapon Info and Compass.")
CreateClientConVar("codhud_enable_prompts", "1", true, false, "Enable or disable Weapon Prompts.")
CreateClientConVar("codhud_enable_chat", "1", true, false, "Enable or disable the Chat.")
CreateClientConVar("codhud_enable_challenges", "1", true, false, "Enable or disable the Challenge prompts.")
CreateClientConVar("codhud_enable_scoreboard", "1", true, false, "Enable or disable the Scoreboard.")

CreateClientConVar("codhud_enable_iff", "1", true, false, "Enable/Disable target identification labels")
CreateClientConVar("codhud_enable_deathicon", "1", true, false, "Show death icon when a friendly dies")

CreateClientConVar("codhud_enable_outlinedtext", "0", true, false, "Enable or disable outlines on certain HUD texts.")
CreateClientConVar("codhud_hide_timer", "0", true, false, "Hide the round timer display.")

CreateClientConVar("codhud_fullscreen", "0", true, false, "MW2 HUD Settings open in fullscreen.")

-- [[ MENU POPULATION ]] -- Only done to present button to open proper menu
hook.Add("PopulateToolMenu", "CoDHUD_SETTINGSMenu", function()

    spawnmenu.AddToolMenuOption("Options", "CoDHUD.Title", "MW2_ClientSettings", "#CoDHUD.Title", "", "", function(panel)
        panel:ClearControls()
		panel:Button(language.GetPhrase("CoDHUD.QMenu.OpenButton"), "codhud_openmenu")
    end)

end)

local codhud_menu_frame = nil
local rs_confirm = nil
local pendingFaction = nil
local pendingGame = nil

CoDHUD.RestrictFactions = 1

net.Receive("CoDHUD_RestrictFactionsSync", function()
    CoDHUD.RestrictFactions = net.ReadUInt(2)
end)

function CoDHUD.GetHUDList()
	local mainHUDs = {}

	timer.Simple( 0.25, function()
		for _, hud in pairs(CoDHUD.TypeRegistry or {}) do
			table.insert(mainHUDs, {
				hud.name,       -- display text
				hud.codename    -- convar value
			})
		end

		table.sort(mainHUDs, function(a, b)
			return a[1] < b[1]
		end)
	end)

	return mainHUDs
end

local function CoDHUD_OpenFactionConfirm(factionID)
    pendingFaction = factionID

    if IsValid(rs_confirm) then rs_confirm:Remove() end

    local fs = GetConVar("codhud_fullscreen"):GetBool()
    local menusize = fs and 1 or 0.55

    if IsValid(codhud_menu_frame) then
        codhud_menu_frame:SetVisible(false)
    end

    rs_confirm = vgui.Create("DFrame")
    rs_confirm:SetSize(ScrW() * menusize, ScrH() * menusize)
    rs_confirm:Center()
    rs_confirm:SetTitle("#CoDHUD.Title")
    rs_confirm:MakePopup()

    if fs then
        rs_confirm:SetDraggable(false)
        rs_confirm:ShowCloseButton(false)
    end

	local factionData = CoDHUD.Factions[CoDHUD_GetHUDType()][factionID]

    rs_confirm.Paint = function(self, w, h)
		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].SettingsMenu then
			CoDHUD[CoDHUD_GetHUDType()].SettingsMenu(w, h, factionData)
		else
			draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))

			surface.SetDrawColor(255, 255, 255, 125)
			surface.SetMaterial( Material(CoDHUD_GetHUDType() .. "/menu_anim") )
			surface.DrawTexturedRect(0, 0, w, h)
			
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial( Material(CoDHUD_GetHUDType() .. "/menu_bg") )
			surface.DrawTexturedRect(0, 0, w, h)
		end

		surface.SetDrawColor(255, 255, 255)
		local badgeFn = CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].DrawFactionBadge
		if badgeFn then
			badgeFn(factionID, w - (w * 0.5) - CoDHUD_S(64), CoDHUD_S(64), CoDHUD_S(128), 255)
		else
			surface.SetMaterial(Material(factionData.scoreIcon, "smooth"))
			surface.DrawTexturedRect(w - (w * 0.5) - CoDHUD_S(64), CoDHUD_S(64), CoDHUD_S(128), CoDHUD_S(128))
		end

		local glow = factionData.glow or Color(0,0,0)

		draw.SimpleTextOutlined( "#" .. factionData.name, "MW2_ChalHeader_Pri", w * 0.5, CoDHUD_S(32), Color(255,255,255), 1, 1, 3, Color(glow.r, glow.g, glow.b, 25) )
    end

    local root = vgui.Create("DPanel", rs_confirm)
    root:Dock(FILL)
    root:DockMargin(20, 20, 20, 20)
    root.Paint = nil

    local lbl = vgui.Create("DLabel", root)
    lbl:Dock(FILL)
    lbl:SetText(language.GetPhrase("CoDHUD.Faction.ChangeWarning"))
    lbl:SetWrap(true)
    lbl:SetContentAlignment(1)
    lbl:SetFont("CoDHUD_Settings_Main")
	function lbl:PerformLayout()
		self:SetFGColor(Color(255,255,255))
	end

    local bottom = vgui.Create("DPanel", root)
    bottom:Dock(BOTTOM)
    bottom:SetTall(50)
    bottom.Paint = nil

    local no = vgui.Create("DButton", bottom)
    no:Dock(LEFT)
    no:SetWide(150)
    no:SetText("#dialog.cancel")

    no.DoClick = function()
        rs_confirm:Remove()
        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(true)
            codhud_menu_frame:MakePopup()
        end
        pendingFaction = nil
    end

    local yes = vgui.Create("DButton", bottom)
    yes:Dock(RIGHT)
    yes:SetWide(150)
    yes:SetText("#dialog.ok")

    yes.DoClick = function()
        rs_confirm:Remove()

        net.Start("CoDHUD_RequestFactionChange")
        net.WriteString(pendingFaction or "")
        net.SendToServer()

        pendingFaction = nil

        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(false)
        end
    end
end

local function CoDHUD_RS_OpenConfirm()
    if IsValid(rs_confirm) then rs_confirm:Remove() end
	
	local fs = GetConVar("codhud_fullscreen"):GetBool()
	local menusize = fs and 1 or 0.55
	
    if IsValid(codhud_menu_frame) then
        codhud_menu_frame:SetVisible(false)
    end

    rs_confirm = vgui.Create("DFrame")
    rs_confirm:SetSize(ScrW() * menusize, ScrH() * menusize)
    rs_confirm:Center()
    rs_confirm:SetTitle("#CoDHUD.Title")
    rs_confirm:MakePopup()

	if fs then
		rs_confirm:SetDraggable(false)
		rs_confirm:ShowCloseButton(false)
	end

    rs_confirm.Paint = function(self, w, h)
		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].SettingsMenu then
			CoDHUD[CoDHUD_GetHUDType()].SettingsMenu(w, h)
		else
			draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))

			surface.SetDrawColor(255, 255, 255, 125)
			surface.SetMaterial( Material(CoDHUD_GetHUDType() .. "/menu_anim") )
			surface.DrawTexturedRect(0, 0, w, h)
			
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial( Material(CoDHUD_GetHUDType() .. "/menu_bg") )
			surface.DrawTexturedRect(0, 0, w, h)
		end
    end

    local root = vgui.Create("DPanel", rs_confirm)
    root:Dock(FILL)
    root:DockMargin(20, 20, 20, 20)
    root.Paint = nil

    local lbl = vgui.Create("DLabel", root)
    lbl:Dock(TOP)
    lbl:SetTall(300)
    lbl:SetText("#CoDHUD.RoundStart.Notice")
    lbl:SetFont("CoDHUD_Settings_Main")
    lbl:SetContentAlignment(4)
    lbl:SetWrap(true)
	function lbl:PerformLayout()
		self:SetFGColor(Color(255,255,255))
	end

    local spacer = vgui.Create("DPanel", root)
    spacer:Dock(FILL)
    spacer.Paint = nil

    local bottom = vgui.Create("DPanel", root)
    bottom:Dock(BOTTOM)
    bottom:SetTall(50)
    bottom.Paint = nil

    local btn_nah = vgui.Create("DButton", bottom)
    btn_nah:Dock(LEFT)
    btn_nah:SetWide(150)
    btn_nah:SetText("#CoDHUD.RoundStart.No")

    btn_nah.DoClick = function()
        rs_confirm:Remove()

        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(true)
            codhud_menu_frame:MakePopup()
        end
    end

    local btn_go = vgui.Create("DButton", bottom)
    btn_go:Dock(RIGHT)
    btn_go:SetWide(150)
    btn_go:SetText("#CoDHUD.RoundStart.Yes")

    btn_go.DoClick = function()
        rs_confirm:Remove()

        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(false)
        end

        net.Start("CoDHUD_StartRound")
        net.SendToServer()
    end
end

local function CoDHUD_OpenGameConfirm(newGame)
    if IsValid(rs_confirm) then rs_confirm:Remove() end

    local fs = GetConVar("codhud_fullscreen"):GetBool()
    local menusize = fs and 1 or 0.55

    local currentGame = GetConVar("codhud_game"):GetString()
    pendingGame = newGame
	
	currentGame = currentGame
	newGame = newGame

    if IsValid(codhud_menu_frame) then
        codhud_menu_frame:SetVisible(false)
    end

    rs_confirm = vgui.Create("DFrame")
    rs_confirm:SetSize(ScrW() * menusize, ScrH() * menusize)
    rs_confirm:Center()
    rs_confirm:SetTitle("#CoDHUD.Title")
    rs_confirm:MakePopup()

    if fs then
        rs_confirm:SetDraggable(false)
        rs_confirm:ShowCloseButton(false)
    end

    rs_confirm.Paint = function(self, w, h)
        if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].SettingsMenu then
            CoDHUD[CoDHUD_GetHUDType()].SettingsMenu(w, h)
        else
            draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))
        end
    end

    local root = vgui.Create("DPanel", rs_confirm)
    root:Dock(FILL)
    root:DockMargin(20, 20, 20, 20)
    root.Paint = nil

    local top = vgui.Create("DLabel", root)
    top:Dock(TOP)
    top:SetTall(120)
	top:SetFont("CoDHUD_Settings_Main")
	function top:PerformLayout()
		self:SetFGColor(Color(255,255,255))
	end

    top:SetContentAlignment(5)

    top:SetText(
        string.format(
            "%s -> %s",
            language.GetPhrase("CoDHUD.Type." .. currentGame),
            language.GetPhrase("CoDHUD.Type." .. newGame)
		)
	)

    local lbl = vgui.Create("DLabel", root)
    lbl:Dock(FILL)
    lbl:SetText(language.GetPhrase("CoDHUD.Admin.RestrictType.Warning"))
    lbl:SetWrap(true)
    lbl:SetContentAlignment(7)
	lbl:SetFont("CoDHUD_Settings_Main")
	function lbl:PerformLayout()
		self:SetFGColor(Color(255,255,255))
	end

    local bottom = vgui.Create("DPanel", root)
    bottom:Dock(BOTTOM)
    bottom:SetTall(50)
    bottom.Paint = nil

    local no = vgui.Create("DButton", bottom)
    no:Dock(LEFT)
    no:SetWide(150)
    no:SetText("#dialog.cancel")

    no.DoClick = function()
        rs_confirm:Remove()

        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(true)
            codhud_menu_frame:MakePopup()
        end

        pendingGame = nil
    end

    local yes = vgui.Create("DButton", bottom)
    yes:Dock(RIGHT)
    yes:SetWide(150)
    yes:SetText("#dialog.ok")

    yes.DoClick = function()
        rs_confirm:Remove()

        net.Start("CoDHUD_SetGame")
        net.WriteString(pendingGame or "")
        net.SendToServer()

        pendingGame = nil

        if IsValid(codhud_menu_frame) then
            codhud_menu_frame:SetVisible(false)
        end
		
		timer.Simple( 0.15, function() RunConsoleCommand("codhud_openmenu") end)
    end
end

local CoDHUD_SETTINGS = {
	{ name = "#CoDHUD.Client", subtabs = {
			{ name = "#CoDHUD.Faction.Select", categories = {
				{ name = "#CoDHUD.Faction.Select", type = "factions" } }
			},

			{ name = "#CoDHUD.HUD", categories = {
					{ name = "#CoDHUD.Quick.title", controls = {
							{ type = "checkbox",	label = "#CoDHUD.Quick.DisableHUD",				convar = "codhud_quickdisable_hud",			tooltip = "CoDHUD.Quick.DisableHUD.desc" },
							{ type = "checkbox",	label = "#CoDHUD.HUD.Outline",					convar = "codhud_enable_outlinedtext",		tooltip = "CoDHUD.HUD.Outline.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.ExplosiveBullets", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.ExplosiveBullets.Enable",	convar = "eb_enabled",	tooltip = "CoDHUD.HUD.ExplosiveBullets.Enable.desc" },
							{ type = "slider",		label = "#CoDHUD.HUD.ExplosiveBullets.Radius",	convar = "eb",			min = 0, max = 300, decimals = 0, tooltip = "CoDHUD.HUD.ExplosiveBullets.Radius.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Scoreboard", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Scoreboard.Enable",		convar = "codhud_enable_scoreboard",		tooltip = "CoDHUD.HUD.Scoreboard.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Scorecounter", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Scorecounter.Enable",		convar = "codhud_enable_scorebar",			tooltip = "CoDHUD.HUD.Scorecounter.Enable.desc" },
							{ type = "checkbox",	label = "#CoDHUD.HUD.Scorecounter.HideTimer",	convar = "codhud_hide_timer",				tooltip = "CoDHUD.HUD.Scorecounter.HideTimer.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Medals", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Medals.Enable",			convar = "codhud_enable_medals",			tooltip = "CoDHUD.HUD.Medals.Enable.desc" },
							{ type = "checkbox",	label = "#CoDHUD.HUD.Medals.Speedup",			convar = "codhud_enable_medal_faster",		tooltip = "CoDHUD.HUD.Medals.Speedup.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Killfeed", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Killfeed.Enable",		convar = "codhud_enable_killfeed",				tooltip = "CoDHUD.HUD.Killfeed.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Minimap", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Minimap.Enable",		convar = "codhud_enable_minimap",				tooltip = "CoDHUD.HUD.Minimap.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Hitmarker", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Hitmarker.Enable",		convar = "codhud_enable_hitmarker",				tooltip = "CoDHUD.HUD.Hitmarker.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.WeaponInfo", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.WeaponInfo.Enable",		convar = "codhud_enable_weaponinfo",		tooltip = "CoDHUD.HUD.WeaponInfo.Enable.desc" },
							{ type = "checkbox",	label = "#CoDHUD.HUD.WeaponPrompts.Enable",		convar = "codhud_enable_prompts",			tooltip = "CoDHUD.HUD.WeaponPrompts.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.XP", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.XP.Enable",		convar = "codhud_enable_xp",			tooltip = "CoDHUD.HUD.XP.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.IFF", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.IFF.Enable",		convar = "codhud_enable_iff",			tooltip = "CoDHUD.HUD.IFF.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.DeathIcon", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.DeathIcon.Enable",		convar = "codhud_enable_deathicon",			tooltip = "CoDHUD.HUD.DeathIcon.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Chat", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Chat.Enable",		convar = "codhud_enable_chat",			tooltip = "CoDHUD.HUD.Chat.Enable.desc" },
						}
					},
					{ name = "#CoDHUD.HUD.Challenges", controls = {
							{ type = "checkbox",	label = "#CoDHUD.HUD.Challenges.Enable",		convar = "codhud_enable_challenges",			tooltip = "CoDHUD.HUD.Challenges.Enable.desc" },
						}
					},
				}
			},
			
			{ name = "#CoDHUD.Settings", categories = {
					{ name = "#CoDHUD.Audio.Announcer", controls = {
							{ type = "checkbox", label = "#CoDHUD.Audio.Announcer.Enable", convar = "codhud_enable_announcer", tooltip = "#CoDHUD.Audio.Announcer.Enable.desc" },
							{ type = "checkbox", label = "#CoDHUD.Audio.Announcer.English", convar = "codhud_enable_announcer_english", tooltip = "#CoDHUD.Audio.Announcer.English.desc" },
						}
					},
					{ name = "#CoDHUD.Audio.Music", controls = {
							{ type = "checkbox", label = "#CoDHUD.Audio.Music.Enable", convar = "codhud_enable_music", tooltip = "#CoDHUD.Audio.Music.Enable.desc" },
							{ type = "checkbox", label = "#CoDHUD.Audio.Music.Ambient", convar = "codhud_enable_suspense", tooltip = "#CoDHUD.Audio.Music.Ambient.desc" },
						}
					},
					{ name = "#CoDHUD.Challenges", controls = {
							{ type = "button",	label = "#CoDHUD.Challenges.Reset",
								func = function()
									RunConsoleCommand("codhud_challenge_clear")
								end
							},
							{ type = "label", label = "#CoDHUD.Challenges.Reset.desc" },
						}
					},
					{ name = "#CoDHUD.Controller", controls = {
							{ type = "combobox",	label = "#CoDHUD.Controller.Mode", tooltip = "CoDHUD.Controller.Mode.desc",
								choices = {
									{ "#CoDHUD.Controller.Mode.KBM", "0" },
									{ "#CoDHUD.Controller.Mode.Pad", "1" },
								},
								getCurrent = function()
									local cv = GetConVar("kc_controller")
									return cv and cv:GetString() or "0"
								end,
								onSelect = function(_, value)
									RunConsoleCommand("kc_controller", value)
								end
							},
							{ type = "slider",		label = "#CoDHUD.Controller.LookSpeed",	convar = "kc_controller_look_speed",	min = 50, max = 1500, decimals = 0, tooltip = "CoDHUD.Controller.LookSpeed.desc" },
							{ type = "slider",		label = "#CoDHUD.Controller.Curve",		convar = "kc_controller_look_curve",	min = 1, max = 3, decimals = 2, tooltip = "CoDHUD.Controller.Curve.desc" },
							{ type = "slider",		label = "#CoDHUD.Controller.Deadzone",	convar = "kc_controller_deadzone",		min = 0, max = 0.5, decimals = 2, tooltip = "CoDHUD.Controller.Deadzone.desc" },
							{ type = "checkbox",	label = "#CoDHUD.Controller.InvertY",	convar = "kc_controller_invert_y",		tooltip = "CoDHUD.Controller.InvertY.desc" },
							{ type = "checkbox",	label = "#CoDHUD.Controller.SprintLatch",	convar = "kc_controller_sprint_latch",	tooltip = "CoDHUD.Controller.SprintLatch.desc" },
							{ type = "button",	label = "#CoDHUD.Controller.Measure",
								func = function()
									if IsValid(codhud_menu_frame) then codhud_menu_frame:SetVisible(false) end
									RunConsoleCommand("kc_controller_measure")
								end
							},
							{ type = "label", label = "#CoDHUD.Controller.Layout" },
						}
					},
					{ name = "#CoDHUD.Menu", controls = {
							{ type = "checkbox",	label = "#CoDHUD.Menu.Fullscreen", convar = "codhud_fullscreen", tooltip = "CoDHUD.Menu.Fullscreen.desc" },
						}
					},
				}
			},

		}
	},

    { name = "#CoDHUD.Server", subtabs = {
            { name = "#CoDHUD.Server", adminOnly = true, categories = {
                    { name = "#CoDHUD.General", adminOnly = true, controls = {
                            { type = "checkbox", label = "#CoDHUD.Admin.EndScreen", server = true, convar = "codhud_enable_roundend", tooltip = "CoDHUD.Admin.EndScreen.desc" },
                            { type = "checkbox", label = "#CoDHUD.Admin.EndScreen.StartNext", server = true, convar = "codhud_enable_roundend_startnext", tooltip = "CoDHUD.Admin.EndScreen.StartNext.desc" },
							{ type = "checkbox", label = "#CoDHUD.Admin.FriendlyFire", server = true, convar = "codhud_friendly_fire", tooltip = "CoDHUD.Admin.FriendlyFire.desc" },
                            { type = "combobox", label = "#CoDHUD.Autobalance.Amount", tooltip = "CoDHUD.Autobalance.Amount.desc", choices = {
									{"CoDHUD.Autobalance.Amount.disable", "0"},
									{"CoDHUD.Autobalance.Amount.2", "2"},
									{"CoDHUD.Autobalance.Amount.3", "3"},
									{"CoDHUD.Autobalance.Amount.4", "4"},
								},
								getCurrent = function() return GetConVar("codhud_autofaction_limit"):GetString() end,

								onSelect = function(_, data)
									net.Start("CoDHUD_SetAutoFaction")
									net.WriteString(data)
									net.SendToServer()
								end
							},
							{ type = "combobox", label = "#CoDHUD.Admin.RestrictFactionChance", tooltip = "CoDHUD.Admin.RestrictFactionChance.desc", choices = {
									{"CoDHUD.Admin.RestrictFactionChance.disable", "0"},
									{"CoDHUD.Admin.RestrictFactionChance.freely", "1"},
									{"CoDHUD.Admin.RestrictFactionChance.pool", "2"},
								},
								getCurrent = function()
									return GetConVar("codhud_restrictfactions"):GetString()
								end,
								onSelect = function(_, data)
									RunConsoleCommand("codhud_restrictfactions", data)
								end
							}
                        }
                    },
					
					{ name = "#CoDHUD.RoundStart", adminOnly = true, controls = {

							{ type = "combobox", label = "#CoDHUD.RoundStart.Gamemode", tooltip = "CoDHUD.RoundStart.Info",
								choices = function() return CoDHUD.Gamemodes[CoDHUD_GetHUDType()] or {} end,
								getCurrent = function() return GetConVar("codhud_selected_gamemode"):GetString() end,
								onSelect = function(_, data)
									net.Start("CoDHUD_SetGamemode")
									net.WriteString(data)
									net.SendToServer()
								end
							},
							
                            { type = "slider", label = "#CoDHUD.Timelimit", server = true, convar = "codhud_time_limit", tooltip = "CoDHUD.Timelimit.desc", min = 0, max = 30 },
							
                            { type = "slider", label = "#CoDHUD.RoundStart.Timer", server = true, convar = "codhud_matchstart_timer", tooltip = "CoDHUD.RoundStart.Timer.desc", min = 0, max = 15 },

							{ type = "checkbox", label = "#CoDHUD.RoundStart.Autobalance", server = true, convar = "codhud_autobalance_on_roundstart", tooltip = "CoDHUD.RoundStart.Autobalance.desc" },

							{ type = "checkbox", label = "#CoDHUD.RoundStart.FastLastTest", server = true, convar = "kc_fastlast_enabled", tooltip = "CoDHUD.RoundStart.FastLastTest.desc" },

							{ type = "checkbox", label = "#CoDHUD.RoundStart.GodMode", server = true, convar = "kc_godmode_enabled", tooltip = "CoDHUD.RoundStart.GodMode.desc" },

							{ type = "button", label = "#CoDHUD.RoundStart.Start", 
								func = function()
									local lp = LocalPlayer()
									if not IsValid(lp) or not lp:IsAdmin() then return end

									CoDHUD_RS_OpenConfirm()

									if IsValid(codhud_menu_frame) then
										codhud_menu_frame:SetVisible(false)
									end
								end
							}
						}
					},
					
                    { name = "#CoDHUD.Admin.RestrictType", adminOnly = true, controls = {
                            { type = "combobox", label = "#CoDHUD.Admin.RestrictType.Choose", tooltip = "CoDHUD.Admin.RestrictType.desc", choices = CoDHUD.GetHUDList(),
								getCurrent = function() return GetConVar("codhud_game"):GetString() end,
								onSelect = function(_, data)
									local current = GetConVar("codhud_game"):GetString()

									if data == current then return end

									CoDHUD_OpenGameConfirm(data)
								end
							},
                        }
                    },
                }
            }
        }
    }
}

local function CreateCheckbox(parent, data)
    local cb = vgui.Create("DCheckBoxLabel", parent)

    cb:SetText(data.label)

    if data.server then
        local cv = GetConVar(data.convar)

        if cv then
            cb:SetValue(cv:GetBool() and 1 or 0)
        end

        cb.OnChange = function(_, val)
            CoDHUD_SetServerConVar(data.convar, val and "1" or "0")
        end
    else
        cb:SetConVar(data.convar)
    end

    if data.tooltip then
        cb:SetTooltip(language.GetPhrase(data.tooltip))
    end

    cb:Dock(TOP)
    cb:DockMargin(5, 2, 5, 2)
    cb:SizeToContents()
end

local function CreateLabel(parent, data)
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetText(language.GetPhrase(data.label))
    lbl:Dock(TOP)
    lbl:DockMargin(5, 2, 5, 2)
    lbl:SizeToContents()
    return lbl
end

local function CreateButton(parent, data)
    local button = vgui.Create("DButton", parent)
    button:SetText(data.label)
	button.DoClick = function(self)
		if data.func then data.func(self) end
	end
    button:Dock(TOP)
    button:DockMargin(5, 2, 5, 2)
    button:SizeToContents()
end

local function CreateSlider(parent, data)
    local slider = vgui.Create("DNumSlider", parent)

    slider:SetText(data.label)
    slider:SetMin(data.min)
    slider:SetMax(data.max)
    slider:SetDecimals(data.decimals or 0)

    local cv = GetConVar(data.convar)

    if cv then
        slider:SetValue(cv:GetFloat())
    end

    slider:Dock(TOP)

    if data.tooltip then
        slider:SetTooltip(language.GetPhrase(data.tooltip))
    end

    local lastSent = nil
    local timerName = "CoDHUD_SliderCommit_" .. tostring(slider)

    slider.OnValueChanged = function(_, val)
        val = math.Round(val, data.decimals or 0)

        timer.Create(timerName, 0.05, 1, function()

            if lastSent == val then return end
            lastSent = val

            if data.server then
                CoDHUD_SetServerConVar(data.convar, tostring(val))
            else
                RunConsoleCommand(data.convar, tostring(val))
            end
        end)
    end
end

local function CreateComboBox(parent, data)
    local container = vgui.Create("DPanel", parent)
    container:Dock(TOP)
    container:DockMargin(5, 2, 5, 2)
    container:SetTall(28)
    container.Paint = nil

    local lbl = vgui.Create("DLabel", container)
    lbl:Dock(LEFT)
    lbl:SetWide(180)
    lbl:SetText(language.GetPhrase(data.label))
    lbl:SizeToContents()
    lbl:DockMargin(5, 0, 5, 0)

    local combo = vgui.Create("DComboBox", container)
    combo:SetTall(22)

    if data.tooltip then
        local tip = language.GetPhrase(data.tooltip)
        container:SetTooltip(tip)
    end

    local choices = data.choices
    if isfunction(choices) then
        choices = choices()
    end
    choices = choices or {}

    for _, choice in ipairs(choices) do
        combo:AddChoice(language.GetPhrase(choice[1]), choice[2])
    end

    if data.getCurrent then
        local current = data.getCurrent()
        for _, choice in ipairs(choices) do
            if choice[2] == current then
                combo:SetValue(language.GetPhrase(choice[1]))
                break
            end
        end
    end

    combo.OnSelect = function(_, _, text, value)
        if data.onSelect then
            data.onSelect(text, value)
        end
    end

    function container:PerformLayout(w, h)
        local maxW = w * 0.5
        local x = lbl:GetWide() + 10

        local text = combo:GetValue() or ""
        surface.SetFont("DermaDefault")
        local textW = surface.GetTextSize(text) + 40

        local finalW = math.Clamp(textW, 120, maxW)

        combo:SetPos(x, 3)
        combo:SetSize(finalW, 22)
    end

    return container
end

local function PopulateControls(panel, controls)
    for _, ctrl in ipairs(controls or {}) do
        if ctrl.type == "checkbox" then
            CreateCheckbox(panel, ctrl)
        elseif ctrl.type == "slider" then
            CreateSlider(panel, ctrl)
        elseif ctrl.type == "label" then
            CreateLabel(panel, ctrl)
        elseif ctrl.type == "button" then
            CreateButton(panel, ctrl)
		elseif ctrl.type == "combobox" then
			CreateComboBox(panel, ctrl)
        end
    end
end

local function CreateCategory(parent, data)
    if data.adminOnly and not LocalPlayer():IsAdmin() then return end

    local cat = vgui.Create("DCollapsibleCategory", parent)

    cat:SetLabel(data.name)
	
    cat:Dock(TOP)
    cat:DockMargin(5, 5, 5, 0)
	cat.Paint = nil
	
	cat.Header.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, (w * 0.33), h, Color(0, 0, 0))
	end

    local inner = vgui.Create("DPanel", cat)
    inner:Dock(TOP)
    inner:DockPadding(5, 5, 5, 5)		
	inner.Paint = nil

    cat:SetContents(inner)

    if data.type == "factions" then
        local grid = vgui.Create("DGrid", inner)
        grid:SetCols(3)
        grid:SetColWide(64)
        grid:SetRowHeight(64)
        grid:Dock(TOP)

		local sorted = {}
		local factions = CoDHUD.Factions[CoDHUD_GetHUDType()] or {}
		local factionCounts = {}

		for _, ply in ipairs(player.GetAll()) do
			local fac = ply:GetNW2String("CoDHUD_Faction", "rangers")
			if fac == "" then fac = "rangers" end

			factionCounts[fac] = (factionCounts[fac] or 0) + 1
		end

		for id, factionData in pairs(factions) do
			table.insert(sorted, {id = id, data = factionData})
		end

		table.sort(sorted, function(a, b)
			return (a.data.order or 0) < (b.data.order or 0)
		end)

		for _, entry in ipairs(sorted) do
			local id = entry.id
			local faction = entry.data
			local count = factionCounts[id] or 0

			local btn = vgui.Create("DImageButton")
			btn:SetSize(64, 64)
			local badgeFn = CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].DrawFactionBadge
			if badgeFn then
				btn.Paint = function(self, w, h)
					badgeFn(id, 0, 0, w, 255)
				end
			elseif faction.scoreIcon then
				btn:SetImage(faction.scoreIcon)
			else
				print("[CoDHUD] Missing scoreIcon for faction:", id)
			end
            btn:SetToolTip(language.GetPhrase(faction.name) or id:upper())

			local current = LocalPlayer():GetNW2String("CoDHUD_Faction", "rangers")

			btn.DoClick = function()
				local current = LocalPlayer():GetNW2String("CoDHUD_Faction", "rangers")
				if id == current then return end

				local mode = CoDHUD.RestrictFactions

				if mode == 0 then return end

				if mode == 2 then
					local pool = CoDHUD.Factions.ActivePool or {}
					if not table.HasValue(pool, id) then return end
				end

				CoDHUD_OpenFactionConfirm(id)
				surface.PlaySound("ui/buttonclick.wav")
			end

			btn.PaintOver = function(self, w, h)
				local current = LocalPlayer():GetNW2String("CoDHUD_Faction", "rangers")
				local mode = CoDHUD.RestrictFactions

				local blocked = false

				if id ~= current then
					if mode == 0 then
						blocked = true
					elseif mode == 2 then
						local pool = CoDHUD.Factions.ActivePool or {}
						if not table.HasValue(pool, id) then
							blocked = true
						end
					end
				end

				if blocked then
					surface.SetDrawColor(0, 0, 0, 180)
					surface.DrawRect(0, 0, w, h)
				end

				if current == id then
					surface.SetDrawColor(255, 255, 255, 60)
					surface.DrawOutlinedRect(0, 0, w, h, 4)

					surface.SetDrawColor(255, 255, 255, 255)
					surface.DrawOutlinedRect(2, 2, w - 4, h - 4, 2)
				end

				if count > 0 then
					local txt = tostring(count)

					surface.SetFont("DermaDefaultBold")
					local tw, th = surface.GetTextSize(txt)

					local pad = 6
					local bx = w - tw - pad * 2 - 4
					local by = 4

					draw.RoundedBox(4, bx, by, tw + pad * 2, th + pad, Color(0, 0, 0, 225))

					draw.SimpleText(txt, "DermaDefaultBold", bx + (tw + pad * 2) / 2, by + (th + pad) / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
				end
			end

            grid:AddItem(btn)
        end
				
		local helper = vgui.Create("DLabel", inner)
		helper:SetText("#CoDHUD.Faction.Select.desc")
		helper:SetWrap(true)
		helper:SetAutoStretchVertical(true)
		helper:Dock(TOP)
		helper:DockMargin(5, 5, 5, 0)
		helper:SetContentAlignment(7)

    end

    PopulateControls(inner, data.controls)

    for _, child in ipairs(data.children or {}) do
        CreateCategory(inner, child)
    end
end

if CLIENT then
    list.Set("DesktopWindows", "CoDHUDMenu", {
        title = "#CoDHUD.Title",
        icon  = "mw2/factions/faction_128_taskforce141_fade.png",
        init = function(icon, window)
			RunConsoleCommand("codhud_openmenu")
        end
    })
end

concommand.Add("codhud_openmenu", function()
	local fs = GetConVar("codhud_fullscreen"):GetBool()
	local menusize = fs and 1 or 0.55
	
	codhud_menu_frame = vgui.Create("DFrame")
	local frame = codhud_menu_frame
	frame:SetSize(ScrW() * menusize, ScrH() * menusize)
	frame:Center()
	frame:SetTitle("#CoDHUD.Title")
	frame:MakePopup()
	
	local closebtn
	
	if fs then
		frame:SetDraggable(false)
		frame:ShowCloseButton(false)
		
		closebtn = vgui.Create("DButton", frame)
		closebtn:Dock(BOTTOM)
		closebtn:SetWide(150)
		closebtn:SetText("#close")

		closebtn.DoClick = function()
			if IsValid(codhud_menu_frame) then
				codhud_menu_frame:Close()
			end
		end
	end

	frame.Paint = function(self, w, h)
		if CoDHUD[CoDHUD_GetHUDType()] and CoDHUD[CoDHUD_GetHUDType()].SettingsMenu then
			CoDHUD[CoDHUD_GetHUDType()].SettingsMenu(w, h)
		else
			draw.RoundedBox(0, 0, 0, w, h, Color(100,100,100))

			surface.SetDrawColor(255, 255, 255, 125)
			surface.SetMaterial( Material("mw2/settings/menu_anim") )
			surface.DrawTexturedRect(0, 0, w, h)
			
			surface.SetDrawColor(255, 255, 255)
			surface.SetMaterial( Material("mw2/settings/menu_bg") )
			surface.DrawTexturedRect(0, 0, w, h)
		end
    end

	local sheet = vgui.Create("DPropertySheet", frame)
	sheet:Dock(FILL)
	sheet.Paint = nil

	for _, tab in ipairs(CoDHUD_SETTINGS) do
		local tabPanel = vgui.Create("DPanel", sheet)
		tabPanel:Dock(FILL)
		tabPanel.Paint = nil

		local subSheet = vgui.Create("DPropertySheet", tabPanel)
		subSheet:Dock(FILL)
		subSheet.Paint = nil

		for _, subtab in ipairs(tab.subtabs or {}) do
			local subPanel = vgui.Create("DScrollPanel", subSheet)
			subPanel.Paint = nil

			for _, catData in ipairs(subtab.categories or {}) do
				CreateCategory(subPanel, catData)
			end

			subSheet:AddSheet(language.GetPhrase(subtab.name), subPanel)
		end

		sheet:AddSheet(language.GetPhrase(tab.name), tabPanel)
	end
end)