
local vignette = Material("echoesbeyond/vignette.png", "smooth")
local flatgrassGrey, flatgrassColor, fgWidth, fgHeight = Material("echoesbeyond/flatgrass_greyscale.png", "smooth"), Material("echoesbeyond/flatgrass_color.png", "smooth"), 1000, 373

local y = 80

local function AddHeader(text)
	local header = vgui.Create("DLabel", creditsMenu)
	header:SetText(text)
	header:SetFont("DermaDefaultBold")
	header:SizeToContents()
	header:CenterHorizontal()
	header:SetY(y)
	y = y + 30
end

local function AddCredit(text1, text2)
	local label1 = vgui.Create("DLabel", creditsMenu)
	label1:SetText(text1)
	label1:SizeToContents()
	label1:SetPos(30, y)

	local label2 = vgui.Create("DLabel", creditsMenu)
	label2:SetText(text2)
	label2:SizeToContents()
	label2:SetPos(creditsMenu:GetWide() - 30 - label2:GetWide(), y)

	y = y + 20
end

local PANEL = {}

function PANEL:Init()
	if (IsValid(creditsMenu)) then
		creditsMenu:Remove()
	end

	creditsMenu = self
	y = 80

	self.flatgrassSaturation = 0

	self:SetSize(ScrW() / 4, ScrH() / 1.5)
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

	AddHeader("Echoes: Beyond")
	AddCredit("Max Payne 1 (Remedy)", "Notification Sound")
	AddCredit("Catherine (L7D)", "Menu Movement Sound")
	AddCredit("PlayStation 2 (Sony Computer Entertainment)", "Echo Sounds")
	AddCredit("Exo One (Exbleative)", "Background Music")
	AddCredit("Clockwork (CloudSixteen)", "Vignette Texture")
	AddCredit("Gabe Newell (Valve Software)", "GabeN Mode Sounds")
	AddCredit("Kevin MacLeod", "Party Song")
	AddCredit("Aspect™", "Clientside Development, Original addon")
	AddCredit("Pancakes", "Serverside Development")
	AddCredit("Kaz", "Performance Improvements")
	AddCredit("Friends", "Feedback, ideas, support, and testing")
	AddCredit("Bad Actors", "Valuable web security experience")

	AddHeader("Echoes: Beyond Plus")
	AddCredit("IntellectualPotato", "Fork creation")
	AddCredit("The Beginner's Guide (Everything Unlimited Ltd.)", "TBG Skin skin/sounds")
	AddCredit("DELTARUNE / UNDERTALE (Toby Fox)", "UTDR Skin base/sounds")
	AddCredit("Friends(+)", "Testing, Ideas, Being there when i need them ♥")

	AddHeader("(EB+) ScaryMode Songs/Ambience")

	AddCredit("Amnesia: The Dark Descent (Frictional Games)", "Songs/Ambience")
	AddCredit("OMORI (OMOCAT)", "Songs/Ambience")
	AddCredit("OneShot (Future Cat)", "Songs/Ambience")
	AddCredit("Piglet's Big Game (Doki Denki Studio / Disney Interactive)", "Songs/Ambience")
	AddCredit("Yume Nikki (Kikiyama)", "Songs/Ambience")
	AddCredit("Yume 2kki (Yume 2kki Team)", "Songs/Ambience")
	AddCredit("Undertale Yellow (Team Undertale Yellow)", "Songs/Ambience")



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

		draw.SimpleText("Hosting & Server Development", "DermaLarge", width / 2, height - 100, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		draw.SimpleText("Kindly provided by Flatgrass.net", "DermaLarge", width / 2, height - 60, Color(200, 200, 200), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
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
