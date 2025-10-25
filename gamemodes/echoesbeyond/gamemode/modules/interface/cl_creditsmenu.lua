
local vignette = Material("echoesbeyond/vignette.png", "smooth")
local flatgrassGrey, flatgrassColor, fgWidth, fgHeight = Material("echoesbeyond/flatgrass_greyscale.png", "smooth"), Material("echoesbeyond/flatgrass_color.png", "smooth"), 1000, 373

local y = 80

local function AddHeader(text, parent)
	local header = vgui.Create("DLabel", parent or creditsMenu)
	header:SetText(text)
	header:SetFont("DermaDefaultBold")
	header:SizeToContents()
	header:CenterHorizontal()
	header:SetY(y)
	y = y + 30
end

local function AddCredit(text1, text2, parent)
	local label1 = vgui.Create("DLabel", parent or creditsMenu)
	label1:SetText(text1)
	label1:SizeToContents()
	label1:SetPos(30, y)

	local label2 = vgui.Create("DLabel", parent or creditsMenu)
	label2:SetText(text2)
	label2:SizeToContents()
	label2:SetPos((parent or creditsMenu):GetWide() - 30 - label2:GetWide(), y)

	y = y + 20
end

local PANEL = {}
local lastOpenedTab = 1

function PANEL:Init()
	if (IsValid(creditsMenu)) then
		creditsMenu:Remove()
	end

	creditsMenu = self
	y = 20

	self.flatgrassSaturation = 0

	self:SetSize(ScrW() / 3.5, ScrH() / 1.3)
	self:Center()
	self:SetX(mainMenu:GetX() + mainMenu:GetWide() + 10)
	self:MakePopup()
	self:SetAlpha(0)

	self:AlphaTo(255, 0.5)
	EchoSound("whoosh", nil, 0.75)

	local title = vgui.Create("DLabel", self)
	title:SetText("Credits")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	local subTitle = vgui.Create("DLabel", self)
	subTitle:SetText("Special thanks to everyone who contributed!")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(55)

	local tabNames = {"Echoes: Beyond", "Echoes: Beyond Plus"}
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

	local currentX = (self:GetWide() - totalTabsWidth) / 2
	for i, button in ipairs(tabButtons) do
		button:SetPos(currentX, tabStartY)
		currentX = currentX + button:GetWide() + buttonSpacing
	end

	do
		local y = 20
		local pnl = tabPanels[1]
		AddHeader("Echoes: Beyond", pnl)
		AddCredit("Max Payne 1 (Remedy)", "Notification Sound", pnl)
		AddCredit("Catherine (L7D)", "Menu Movement Sound", pnl)
		AddCredit("PlayStation 2 (Sony Computer Entertainment)", "Echo Sounds", pnl)
		AddCredit("Exo One (Exbleative)", "Background Music", pnl)
		AddCredit("Clockwork (CloudSixteen)", "Vignette Texture", pnl)
		AddCredit("Gabe Newell (Valve Software)", "GabeN Mode Sounds", pnl)
		AddCredit("Kevin MacLeod", "Party Song", pnl)
		AddCredit("Aspect™", "Clientside Development, Original addon", pnl)
		AddCredit("Pancakes", "Serverside Development", pnl)
		AddCredit("Kaz", "Performance Improvements", pnl)
		AddCredit("Friends", "Feedback, ideas, support, and testing", pnl)
		AddCredit("Bad Actors", "Valuable web security experience", pnl)
	end

	do
		y = 20
		local pnl = tabPanels[2]
		AddHeader("Echoes: Beyond Plus", pnl)
		AddCredit("IntellectualPotato", "Fork creation", pnl)
		AddCredit("The Beginner's Guide (Everything Unlimited Ltd.)", "TBG Skin skin/sounds", pnl)
		AddCredit("DELTARUNE / UNDERTALE (Toby Fox)", "UTDR Skin base/sounds", pnl)
		AddCredit("Friends(+)", "Testing, Ideas, Being there when i need them ♥", pnl)

		AddHeader("(EB+) ScaryMode Songs/Ambience", pnl)

		AddCredit("Amnesia: The Dark Descent (Frictional Games)", "Songs/Ambience", pnl)
		AddCredit("OMORI (OMOCAT)", "Songs/Ambience", pnl)
		AddCredit("OneShot (Future Cat)", "Songs/Ambience", pnl)
		AddCredit("Piglet's Big Game (Doki Denki Studio / Disney Interactive)", "Songs/Ambience", pnl)
		AddCredit("Yume Nikki (Kikiyama)", "Songs/Ambience", pnl)
		AddCredit("Yume 2kki (Yume 2kki Team)", "Songs/Ambience", pnl)
		AddCredit("Undertale Yellow (Team Undertale Yellow)", "Songs/Ambience", pnl)
	end

	SwitchToTab(lastOpenedTab)



	local fgHeight = (fgHeight / fgWidth) * self:GetWide()

	local flatgrassPanel = vgui.Create("DButton", self)
	flatgrassPanel:SetSize(self:GetWide(), fgHeight)
	flatgrassPanel:SetPos(0, self:GetTall() - flatgrassPanel:GetTall())
	flatgrassPanel:SetText("")
	flatgrassPanel.Paint = function(this, width, height)
		if (this:IsHovered()) then
			self.flatgrassSaturation = math.Approach(self.flatgrassSaturation, 255, FrameTime() * 1000)
		else
			self.flatgrassSaturation = math.Approach(self.flatgrassSaturation, 0, FrameTime() * 1000)
		end

		surface.SetDrawColor(100, 100, 100, 255 - self.flatgrassSaturation)
		surface.SetMaterial(flatgrassGrey)
		surface.DrawTexturedRect(0, 0, width, height)

		surface.SetDrawColor(150, 150, 150, self.flatgrassSaturation)
		surface.SetMaterial(flatgrassColor)
		surface.DrawTexturedRect(0, 0, width, height)

		local textY = math.max(20, height - 100)
		draw.SimpleText("Hosting & Server Development", "DermaLarge", width / 2, textY, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Kindly provided by Flatgrass.net", "DermaLarge", width / 2, textY + 40, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	flatgrassPanel.DoClick = function()
		gui.OpenURL("https://github.com/flatgrassdotnet/")

		EchoSound("button_click")
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)
end

function PANEL:PaintOver(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)
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

vgui.Register("echoCreditsMenu", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "creditsmenu_OnPauseMenuShow", function()
	if (!IsValid(creditsMenu)) then return end

	creditsMenu:Close()

	return false
end)
