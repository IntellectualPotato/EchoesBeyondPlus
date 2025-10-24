-- The settings menu
local vignette = Material("echoesbeyond/vignette.png", "smooth")

local PANEL = {}
local lastOpenedTab = 1

local function CreateCheckbox(parent, text, convarName, y)
    local checkbox = vgui.Create("DCheckBoxLabel", parent)
    checkbox:SetText(text)
    checkbox:SizeToContents()
    checkbox:SetPos(50, y)
    if convarName == "echoes_allowsandbox" or convarName == "cl_drawhud" then
        checkbox:SetValue(GetConVar(convarName):GetBool())
    else
        checkbox:SetValue(EchoesSettings[convarName])
    end
    checkbox.OnChange = function(self, value)
        if convarName == "echoes_allowsandbox" then
            net.Start("Echoes_ToggleAllowSandbox")
            net.WriteBool(value)
            net.SendToServer()
        elseif convarName == "cl_drawhud" then
            RunConsoleCommand("cl_drawhud", value and "1" or "0")
        else
            GetConVar(convarName):SetBool(value)
        end
    end
    return y + 25
end
local function CreateSlider(parent, text, convar, min, max, decimals, y)
	local slider = vgui.Create("DNumSlider", parent)
	slider:SetText(text)
	slider:SetMin(min)
	slider:SetMax(max)
	slider:SetDecimals(decimals)
	slider:SetValue(EchoesSettings[convar:GetName()])
	slider:SetWide(parent:GetWide() - 100)
	slider:SetPos(50, y)
	slider.OnValueChanged = function(self, value)
		convar:SetInt(value)
	end

	return y + 25
end

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
		local panel = vgui.Create("DPanel", self)
		panel:SetPos(0, tabContentY)
		panel:SetSize(self:GetWide(), self:GetTall() - tabContentY)
		panel.Paint = function() end
		tabPanels[i] = panel
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
		y = CreateCheckbox(pnl, "Enable music", "echoes_music", y)
		y = CreateCheckbox(pnl, "Show read Echoes", "echoes_showread", y)
		y = CreateCheckbox(pnl, "Don't fade read echoes", "echoes_disablereadsys", y)
		y = CreateCheckbox(pnl, "Show offensive Echoes", "echoes_profanity", y)
		y = CreateCheckbox(pnl, "Flash game window when a new Echo is created", "echoes_windowflash", y)
		if not EchoesSettings["echoes_immersivemode"] then
			y = CreateCheckbox(pnl, "Notify when an echo is created on ANY map", "echoes_notifynew", y)
		end
	end

	do
		local y = 20
		local pnl = tabPanels[2]
		y = CreateCheckbox(pnl, "Enable GabeN mode", "echoes_gabenmode", y)
		y = CreateCheckbox(pnl, "Enable void Echoes", "echoes_enablevoidechoes", y)
		y = CreateCheckbox(pnl, "Enable floating Echoes", "echoes_enableairechoes", y)
		y = CreateSlider(pnl, "Movement Speed", GetConVar("echoes_speed"), 1, 1000, 0, y)
	end

	do
		local y = 20
		local pnl = tabPanels[3]
		y = CreateCheckbox(pnl, "Enable smooth view", "echoes_smoothview", y)
		y = CreateCheckbox(pnl, "Enable dynamic lights", "echoes_dlights", y)
		y = y - 13
		y = CreateSlider(pnl, "Dynamic lights Brightness", GetConVar("echoes_dlights_brightness"), 0.1, 3, 0, y)
		y = y + 5
		y = CreateSlider(pnl, "Render Distance", GetConVar("echoes_renderdist"), 10000, 100000000, 0, y)
		y = y + 5
		y = CreateCheckbox(pnl, "Slow Echo activation", "echoes_slowactivate", y)
		y = CreateCheckbox(pnl, "Hide author signatures", "echoes_disablesigning", y)
		y = y + 25
		y = CreateCheckbox(pnl, "Draw Hud", "cl_drawhud", y)
		y = CreateCheckbox(pnl, "Hide Suit/Health/Ammo", "echoes_hidehud_suit", y)
		y = CreateCheckbox(pnl, "Hide Crosshair", "echoes_hidehud_crosshair", y)
		y = CreateCheckbox(pnl, "Hide Weapon Selection", "echoes_hidehud_weaponsel", y)
	end

	do
		local y = 20
		local pnl = tabPanels[4]

		local ImmersionLabel = vgui.Create("DLabel", pnl)
		ImmersionLabel:SetText("⬇ Hide's/disables options that may be considered \"Cheaty\" or immersion breaking.")
		ImmersionLabel:SetFont("Echoes_statsfont")
		ImmersionLabel:SetColor(Color(105, 105, 200))
		ImmersionLabel:SizeToContents()
		ImmersionLabel:SetPos(50, y)
		y = y + ImmersionLabel:GetTall() + 5

		y = CreateCheckbox(pnl, "Immersive Mode", "echoes_immersivemode", y)

		y = y + 10

		local SandboxLabel = vgui.Create("DLabel", pnl)
		SandboxLabel:SetText("⬇ May be buggy, use with caution")
		SandboxLabel:SetFont("Echoes_statsfont")
		SandboxLabel:SetColor(Color(255, 60, 60))
		SandboxLabel:SizeToContents()
		SandboxLabel:SetPos(50, y)
		y = y + SandboxLabel:GetTall() + 5

		y = CreateCheckbox(pnl, "Inject Sandbox Functions (Spawnmenu, etc, Requires mapchange)", "echoes_allowsandbox", y)
		y = y + 20

		if not EchoesSettings["echoes_immersivemode"] then
			y = CreateCheckbox(pnl, "Bypass placement checks (void, ground, etc)", "echoes_bypasschecks", y)
			y = CreateCheckbox(pnl, "Debug info", "echoes_debuginfo", y)
		end

		local deleteAll = vgui.Create("DButton", pnl)
		deleteAll:SetSize(pnl:GetWide() * 0.5, 30)
		deleteAll:SetText("Delete all data")
		deleteAll:SetFont("CreditsText")
		deleteAll:SetColor(Color(175, 175, 175))
		deleteAll:CenterHorizontal()
		deleteAll:SetY(pnl:GetTall() - 50)
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

		local ForceParty = vgui.Create("DButton", pnl)
		ForceParty:SetSize(pnl:GetWide() * 0.5, 30)
		ForceParty:SetText("Force party mode")
		ForceParty:SetFont("CreditsText")
		ForceParty:SetColor(Color(175, 175, 175))
		ForceParty:CenterHorizontal()
		ForceParty:SetY(pnl:GetTall() - 100)
		ForceParty.Paint = function(this, width, height)
			surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
			surface.DrawRect(0, 0, width, height)
		end
		ForceParty.DoClick = function()
			InitPartyMode("Engage party mode!")
		end

		y = y + 20

		local scaryLabel = vgui.Create("DLabel", pnl)
		scaryLabel:SetText("⬇ Requires Gmod Light / Environment Editor, click to download")
		scaryLabel:SetFont("Echoes_statsfont")
		scaryLabel:SetColor(Color(255, 60, 60))
		scaryLabel:SizeToContents()
		scaryLabel:SetPos(50, y)
		scaryLabel:SetCursor("hand")
		scaryLabel:SetMouseInputEnabled(true)
		scaryLabel.OnMousePressed = function()
			gui.OpenURL("https://steamcommunity.com/sharedfiles/filedetails/?id=2779451924")
		end
		y = y + scaryLabel:GetTall() + 5

		local scaryCheckbox = vgui.Create("DCheckBoxLabel", pnl)
		scaryCheckbox:SetText("Scary mode (dark, disables static lighting, new music)")
		scaryCheckbox:SizeToContents()
		scaryCheckbox:SetPos(50, y)
		scaryCheckbox:SetValue(EchoesSettings["echoes_scarymode"])
		scaryCheckbox.OnChange = function(self, value)
			GetConVar("echoes_scarymode"):SetBool(value)
			ApplyScaryMode(value)
		end
		y = y + 50

		local draftsLabel = vgui.Create("DLabel", pnl)
		draftsLabel:SetText("⬇ May bug, as i suck, so it needs to be enabled manually")
		draftsLabel:SetFont("Echoes_statsfont")
		draftsLabel:SetColor(Color(255, 60, 60))
		draftsLabel:SizeToContents()
		draftsLabel:SetPos(50, y)
		y = y + draftsLabel:GetTall() + 5

		local draftsCheckbox = vgui.Create("DCheckBoxLabel", pnl)
		draftsCheckbox:SetText("Enable drafts (Make echoes on cooldown)")
		draftsCheckbox:SizeToContents()
		draftsCheckbox:SetPos(50, y)
		draftsCheckbox:SetValue(EchoesSettings["echoes_enable_drafts"])
		draftsCheckbox.OnChange = function(self, value)
			GetConVar("echoes_enable_drafts"):SetBool(value)
		end
		y = y + 20

		local draftsInfo = vgui.Create("DLabel", pnl)
		draftsInfo:SetText("Drafts allow creating up to 3 echoes while on cooldown, Drafts can be seen in personal echoes menu.")
		draftsInfo:SetColor(Color(128, 128, 128))
		draftsInfo:SizeToContents()
		draftsInfo:SetPos(50, y)
		y = y + draftsInfo:GetTall() + 5
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