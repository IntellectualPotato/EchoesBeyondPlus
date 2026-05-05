
local PANEL = {}

function PANEL:Init()
	if (IsValid(echoConfirmation)) then
		echoConfirmation:Remove()
	end

	echoConfirmation = self

	self:SetSize(600, 210)
	self:Center()
	self:MakePopup()
	self:SetAlpha(0)

	self.startTime = SysTime()

	self:AlphaTo(255, 0.25)

	LocalPlayer():EmitSound("echoesbeyond/whoosh.wav", 75, 100, 0.75)

	self.title = vgui.Create("DLabel", self)
	self.title:SetFont("DermaLarge")
	self.title:SetText("Confirmation Title")
	self.title:SetTextColor(Color(200, 200, 200))
	self.title:SizeToContents()
	self.title:CenterHorizontal()
	self.title:SetY(10)

	self.subTitle = vgui.Create("DLabel", self)
	self.subTitle:SetText("Echo your thoughts into the text field below.")
	self.subTitle:SetTextColor(Color(200, 200, 200))
	self.subTitle:SizeToContents()
	self.subTitle:CenterHorizontal()
	self.subTitle:SetY(60)

	self.confirm = vgui.Create("DButton", self)
	self.confirm:SetSize(self:GetWide() * 0.3, 30)
	self.confirm:SetText("Confirm")
	self.confirm:SetFont("CreditsText")
	self.confirm:SetColor(Color(175, 175, 175))
	self.confirm:CenterHorizontal()
	self.confirm:SetY(125)
	self.confirm.Paint = function(this, width, height)
		surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.DrawRect(0, 0, width, height)
	end
	self.confirm.DoClick = function()
		if (self.callback) then
			self.callback()
		end

		self:Close()

		LocalPlayer():EmitSound("echoesbeyond/button_click.wav")
	end

	self.cancel = vgui.Create("DButton", self)
	self.cancel:SetSize(self:GetWide() * 0.3, 30)
	self.cancel:SetText("Cancel")
	self.cancel:SetFont("CreditsText")
	self.cancel:SetColor(Color(175, 175, 175))
	self.cancel:CenterHorizontal()
	self.cancel:SetY(165)
	self.cancel.Paint = function(this, width, height)
		surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.DrawRect(0, 0, width, height)
	end
	self.cancel.DoClick = function()
		if (self.cancelCallback) then
			self.cancelCallback()
		end

		self:Close()
		LocalPlayer():EmitSound("echoesbeyond/button_click.wav")
	end
end

function PANEL:Populate(title, text, callback, cancelCallback)
	self.title:SetText(title)
	self.title:SizeToContents()
	self.title:CenterHorizontal()

	self.subTitle:SetText(text)
	self.subTitle:SizeToContents()
	self.subTitle:CenterHorizontal()

	self.callback = callback
	self.cancelCallback = cancelCallback
end

function PANEL:Close()
	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	LocalPlayer():EmitSound("echoesbeyond/whoosh.wav", 75, 90, 0.75)
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_TAB) then return end

	self:Close()
end

local notif = Material("echoesbeyond/notification.png")
local vignette = Material("echoesbeyond/vignette.png")

function PANEL:Paint(width, height)
	Derma_DrawBackgroundBlur(self, self.startTime)

	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)

	surface.SetDrawColor(200, 200, 200)
	surface.SetMaterial(notif)
	surface.DrawTexturedRect(width * 0.15, 45, width - width * 0.3, 2)
end

vgui.Register("EchoesConfirm", PANEL, "DPanel")

function EchoesConfirm(title, text, callback, cancelCallback)
	vgui.Create("EchoesConfirm"):Populate(title, text, callback, cancelCallback)
end

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "confirm_OnPauseMenuShow", function()
	if (!IsValid(echoConfirmation)) then return end

	echoConfirmation:Close()

	return false
end)
