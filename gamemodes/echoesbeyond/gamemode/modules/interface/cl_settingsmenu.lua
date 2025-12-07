-- The settings menu
include("cl_widgets.lua") --moved to a NEW file!!
local vignette = Material("echoesbeyond/vignette.png", "smooth")

local PANEL = {}
local lastOpenedTab = 1


function PANEL:Init()
	if (IsValid(settingsMenu)) then
		settingsMenu:Remove()
	end

	settingsMenu = self

	self:SetSize(ScrW() / 4, ScrH() / 1.5)
	self:Center()
	self:SetX(mainMenu:GetX() + mainMenu:GetWide() + 10)
	self:MakePopup()
	self:SetAlpha(0)

	self:AlphaTo(255, 0.5)
	EchoSound("whoosh", nil, 0.75)

	local title = vgui.Create("DLabel", self)
	title:SetText("Settings")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	local subTitle = vgui.Create("DLabel", self)
	subTitle:SetText("Configure your experience here.")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(55)

	local tabNames = {"General", "Gameplay", "Visual", "Advanced"}
	local tabButtons = {}
	local tabPanels = {}
	local tabStartY = 90
	local tabHeight = 30
	local tabContentY = tabStartY + tabHeight

	for i, name in ipairs(tabNames) do
		local scrollPanel = vgui.Create("DScrollPanel", self)
		scrollPanel:SetPos(0, tabContentY)
		scrollPanel:SetSize(self:GetWide(), self:GetTall() - tabContentY)
		scrollPanel.Paint = function() end -- transparent to show main background
		local sbar = scrollPanel:GetVBar()
		function sbar:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(25, 25, 25, 150))
		end
		function sbar.btnUp:Paint(w, h)
			surface.SetDrawColor(100, 100, 100)
			surface.SetMaterial(arrow)
			surface.DrawTexturedRectRotated(w / 2, h / 2, w * 1.5, h * 1.5, 0)
		end
		function sbar.btnDown:Paint(w, h)
			surface.SetDrawColor(100, 100, 100)
			surface.SetMaterial(arrow)
			surface.DrawTexturedRectRotated(w / 2, h / 2, w * 1.5, h * 1.5, 180)
		end
		function sbar.btnGrip:Paint(w, h)
			draw.RoundedBox(0, 0, 0, w, h, Color(75, 75, 75))
			surface.SetDrawColor(0, 0, 0, 255)
			surface.SetMaterial(vignette)
			surface.DrawTexturedRect(0, 0, w, h)
		end
		local panel = vgui.Create("DPanel", scrollPanel)
		panel:SetSize(self:GetWide(), 1000) --height for content
		panel.Paint = function() end --inner panel transparent too
		scrollPanel:AddItem(panel)
		tabPanels[i] = scrollPanel
	end

	local function SwitchToTab(index)
		lastOpenedTab = index
		for i, panel in ipairs(tabPanels) do
			panel:SetVisible(i == index)
		end
		for i, button in ipairs(tabButtons) do
			button.m_bActive = (i == index)
		end
	end

local totalTabsWidth = 0
	local buttonSpacing = 2
	for i, name in ipairs(tabNames) do
		local button = vgui.Create("DButton", self)
		button:SetText(name)
		button:SetFont("TargetID")
		button:SizeToContentsX(15)
		button:SetTall(tabHeight)
		button.m_bActive = false

		button.Paint = function(s, w, h)
			if s.m_bActive then
				surface.SetDrawColor(28, 40, 40)
				surface.DrawRect(0, 0, w, h)
			else
				surface.SetDrawColor(s:IsDown() and Color(100, 100, 100) or s:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
				surface.DrawRect(0, 0, w, h)
			end
		end

		button.DoClick = function()
			SwitchToTab(i)
			EchoSound("button_click")
		end

		tabButtons[i] = button
		totalTabsWidth = totalTabsWidth + button:GetWide()
	end

	if #tabButtons > 1 then
		totalTabsWidth = totalTabsWidth + (#tabButtons - 1) * buttonSpacing
	end

	-- Now, calculate the starting position and place the buttons
	local currentX = (self:GetWide() - totalTabsWidth) / 2
	for i, button in ipairs(tabButtons) do
		button:SetPos(currentX, tabStartY)
		currentX = currentX + button:GetWide() + buttonSpacing
	end

	do
		local y = 20
		local pnl = tabPanels[1]
		y, _ = CreateCheckbox(pnl, "Enable music", "echoes_music", y)
		y, _ = CreateCheckbox(pnl, "Show read Echoes", "echoes_showread", y)
		y, _ = CreateCheckbox(pnl, "Don't fade read echoes", "echoes_disablereadsys", y)
		y, _ = CreateCheckbox(pnl, "Show offensive Echoes", "echoes_profanity", y)
		y, _ = CreateCheckbox(pnl, "Flash game window when a new Echo is created", "echoes_windowflash", y)
		if not EchoesSettings["echoes_immersivemode"] then
			y, _ = CreateCheckbox(pnl, "Notify when an echo is created on ANY map", "echoes_notifynew", y)
		end
	end

	do
		local y = 20
		local pnl = tabPanels[2]
		y, _ = CreateCheckbox(pnl, "Enable GabeN mode", "echoes_gabenmode", y)
		y, _ = CreateCheckbox(pnl, "Enable void Echoes", "echoes_enablevoidechoes", y)
		y, _ = CreateCheckbox(pnl, "Enable floating Echoes", "echoes_enableairechoes", y)
		y = CreateSlider(pnl, "Movement Speed", GetConVar("echoes_speed"), 1, 1000, 0, y)
	end

	do
		local y = 20
		local pnl = tabPanels[3]
		y, _ = CreateCheckbox(pnl, "Enable smooth view", "echoes_smoothview", y)
		y, _ = CreateCheckbox(pnl, "Enable particles", "echoes_enableparticles", y)
		y, _ = CreateCheckbox(pnl, "Enable dynamic lights", "echoes_dlights", y)
		y = y - 13
		y = CreateSlider(pnl, "Dynamic lights Brightness", GetConVar("echoes_dlights_brightness"), 0.1, 3, 0, y)
		y = y + 5
		y = CreateSlider(pnl, "Render Distance", GetConVar("echoes_renderdist"), 10000, 100000000, 0, y)
		y = y + 5
		y, _ = CreateCheckbox(pnl, "Slow Echo activation", "echoes_slowactivate", y)
		y = y + 5
		y, _ = CreateCheckbox(pnl, "Activate within FOV", "echoes_visibleonly", y)
		y = y - 13
		y = CreateSlider(pnl, "Activation FOV", GetConVar("echoes_visiblefov"), 10, 180, 0, y, {10, 15, 20, 30, 45, 60, 90, 120, 150, 180})
		y = y + 5
		y, _ = CreateCheckbox(pnl, "Hide author signatures", "echoes_disablesigning", y)
		y = y + 5
		local sigOwnPanel
		local y, sigColorsPanel = CreateCheckbox(pnl, "Show custom author signature colors", "echoes_showsignaturecolors", y, function(checked)
			--sigOwnPanel:SetMouseInputEnabled(checked)
			sigOwnPanel:SetAlpha(checked and 255 or 100)
		end)
		local y, sigOwnPanelTemp = CreateCheckbox(pnl, "Allow signature colors on own echoes", "echoes_allowsigsown", y)
		sigOwnPanel = sigOwnPanelTemp
		if not EchoesSettings["echoes_showsignaturecolors"] then
			--sigOwnPanel:SetMouseInputEnabled(false)
			sigOwnPanel:SetAlpha(100)
		end
		y = y + 5
		y, _ = CreateCheckbox(pnl, "Draw Hud", "cl_drawhud", y)
		y, _ = CreateCheckbox(pnl, "Hide Suit/Health/Ammo", "echoes_hidehud_suit", y)
		y, _ = CreateCheckbox(pnl, "Hide Crosshair", "echoes_hidehud_crosshair", y)
		y, _ = CreateCheckbox(pnl, "Hide Weapon Selection", "echoes_hidehud_weaponsel", y)
	end

	do
		local y = 20
		local pnl = tabPanels[4]

		local ImmersionLabel = vgui.Create("DLabel", pnl)
		ImmersionLabel:SetText("⬇ Hide's/disables options that may be considered \"Cheaty\" or immersion breaking.")
		ImmersionLabel:SetFont("Echoes_statsfont")
		ImmersionLabel:SetColor(Color(105, 105, 200))
		ImmersionLabel:SetWide(pnl:GetWide() - 100)
		ImmersionLabel:SetPos(50, y)
		ImmersionLabel:SetWrap(true)
		ImmersionLabel:SetAutoStretchVertical(true)
		local immersionHeight = CalculateWrappedHeight(ImmersionLabel, ImmersionLabel:GetText(), ImmersionLabel:GetWide())
		y = y + immersionHeight + 5

		y, _ = CreateCheckbox(pnl, "Immersive Mode", "echoes_immersivemode", y)

		y = y + 10

		local SandboxLabel = vgui.Create("DLabel", pnl)
		SandboxLabel:SetText("⬇ May be buggy, use with caution")
		SandboxLabel:SetFont("Echoes_statsfont")
		SandboxLabel:SetColor(Color(255, 60, 60))
		SandboxLabel:SetWide(pnl:GetWide() - 100)
		SandboxLabel:SetPos(50, y)
		SandboxLabel:SetWrap(true)
		SandboxLabel:SetAutoStretchVertical(true)
		local sandboxHeight = CalculateWrappedHeight(SandboxLabel, SandboxLabel:GetText(), SandboxLabel:GetWide())
		y = y + sandboxHeight + 5

		y, _ = CreateCheckbox(pnl, "Inject Sandbox Functions (Spawnmenu, etc, Requires mapchange)", "echoes_allowsandbox", y)

		if not EchoesSettings["echoes_immersivemode"] then
			y = y + 20
			y, _ = CreateCheckbox(pnl, "Bypass placement checks (void, ground, etc)", "echoes_bypasschecks", y)
			y, _ = CreateCheckbox(pnl, "Debug info", "echoes_debuginfo", y)
			y = y + 20
		end

		local deleteAll = vgui.Create("DButton", pnl)
		deleteAll:SetSize(pnl:GetWide() * 0.5, 30)
		deleteAll:SetText("Delete all data")
		deleteAll:SetFont("CreditsText")
		deleteAll:SetColor(Color(175, 175, 175))
		deleteAll:SetPos((pnl:GetWide() - deleteAll:GetWide()) / 2, 1000 - 50)
		deleteAll.Paint = function(this, width, height)
			surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
			surface.DrawRect(0, 0, width, height)
		end
		deleteAll.DoClick = function()
			EchoesConfirm("Delete all data", "This will delete all of your data from Echoes Beyond, including all Echoes. Are you sure?", function()
				http.Fetch("https://resonance.flatgrass.net/nuke", function(body, _, _, code)
					if (code != 200) then
						if (code == 401) then
							EchoNotify("Your authentication token has expired. Please log in again.")

							authToken = nil
						else
							EchoNotify("RESONANCE ERROR: " .. string.sub(body, 1, -2))
						end

						return
					end

					mainMenu:Close()

					file.Delete("echoesbeyond/readechoes_plus.txt")
					file.Delete("echoesbeyond/authtoken.txt")
					authToken = nil
					writtenEchoes = {}
					readEchoCount = 0

					local newEchoes = {}

					for i = 1, #echoes do
						local echo = echoes[i]
						if (echo.isOwner) then continue end

						newEchoes[#newEchoes + 1] = echo
					end

					echoes = newEchoes

					EchoNotify("All data has been deleted.")

					EchoSound("button_click")
				end, function(error)
					EchoNotify(error)
				end, {authorization = authToken})
			end)

			EchoSound("button_click")
		end

		if not EchoesSettings["echoes_immersivemode"] then
			local ForceParty = vgui.Create("DButton", pnl)
			ForceParty:SetSize(pnl:GetWide() * 0.5, 30)
			ForceParty:SetText("Force party mode")
			ForceParty:SetFont("CreditsText")
			ForceParty:SetColor(Color(175, 175, 175))
			ForceParty:SetPos((pnl:GetWide() - ForceParty:GetWide()) / 2, 1000 - 100)
			ForceParty.Paint = function(this, width, height)
				surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
				surface.DrawRect(0, 0, width, height)
			end
			ForceParty.DoClick = function()
				InitPartyMode("Engage party mode!")
			end
		end

		local scaryLabel = vgui.Create("DLabel", pnl)
		scaryLabel:SetText("⬇ Requires Gmod Light / Environment Editor, click to download")
		scaryLabel:SetFont("Echoes_statsfont")
		scaryLabel:SetColor(Color(255, 60, 60))
		scaryLabel:SetWide(pnl:GetWide() - 100)
		scaryLabel:SetPos(50, y)
		scaryLabel:SetWrap(true)
		scaryLabel:SetAutoStretchVertical(true)
		scaryLabel:SetCursor("hand")
		scaryLabel:SetMouseInputEnabled(true)
		scaryLabel.OnMousePressed = function()
			gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=2779451924")
		end
		local scaryHeight = CalculateWrappedHeight(scaryLabel, scaryLabel:GetText(), scaryLabel:GetWide())
		y = y + scaryHeight + 5

		y, _ = CreateCheckbox(pnl, "Scary mode (dark, disables static lighting, new music)", "echoes_scarymode", y, function(checked)
			ApplyScaryMode(checked)
		end)

		local draftsLabel = vgui.Create("DLabel", pnl)
		draftsLabel:SetText("⬇ May bug, as i suck, so it needs to be enabled manually")
		draftsLabel:SetFont("Echoes_statsfont")
		draftsLabel:SetColor(Color(255, 60, 60))
		draftsLabel:SetWide(pnl:GetWide() - 100)
		draftsLabel:SetPos(50, y)
		draftsLabel:SetWrap(true)
		draftsLabel:SetAutoStretchVertical(true)
		local draftsLabelHeight = CalculateWrappedHeight(draftsLabel, draftsLabel:GetText(), draftsLabel:GetWide())
		y = y + draftsLabelHeight + 5

		y, _ = CreateCheckbox(pnl, "Enable drafts (Make echoes on cooldown)", "echoes_enable_drafts", y)

		local draftsInfo = vgui.Create("DLabel", pnl)
		draftsInfo:SetText("Drafts allow creating up to 3 echoes while on cooldown, Drafts can be seen in personal echoes menu.")
		draftsInfo:SetColor(Color(128, 128, 128))
		draftsInfo:SetWide(pnl:GetWide() - 100)
		draftsInfo:SetPos(50, y)
		draftsInfo:SetWrap(true)
		draftsInfo:SetAutoStretchVertical(true)
		local draftsInfoHeight = CalculateWrappedHeight(draftsInfo, draftsInfo:GetText(), draftsInfo:GetWide())
		y = y + draftsInfoHeight + 5
	end

	SwitchToTab(lastOpenedTab)
end

local notif = Material("echoesbeyond/notification.png")

function PANEL:Paint(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)

	surface.SetDrawColor(45, 45, 45)
	surface.SetMaterial(notif)
	surface.DrawTexturedRect((width - width * 0.85) / 2, 85, width * 0.85, 40)
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_TAB) then return end

	self:Close()
end

function PANEL:Close(bNoSound)
	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	if (bNoSound) then return end
	EchoSound("whoosh", 90, 0.75)
end

vgui.Register("echoSettingsMenu", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "settingsmenu_OnPauseMenuShow", function()
	if (!IsValid(settingsMenu)) then return end

	settingsMenu:Close()

	return false
end)