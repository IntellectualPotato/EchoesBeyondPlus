
local PANEL = {}

local maxSmallLength = 49 -- Max text length before the text field expands
local maxBigSize = 250 -- Max text length

function PANEL:Init()
	if (IsValid(echoEntry)) then
		echoEntry:Remove()
	end

	echoEntry = self

	self:SetSize(600, 210)
	self:Center()
	self:MakePopup()
	self:SetAlpha(0)

	self.startTime = SysTime()

	self:AlphaTo(255, 0.25)

	EchoSound("whoosh", nil, 0.75)

	self.title = vgui.Create("DLabel", self)
	self.title:SetFont("DermaLarge")
	self.title:SetText("Create Echo")
	self.title:SizeToContents()
	self.title:CenterHorizontal()
	self.title:SetY(10)

	local subTitle = vgui.Create("DLabel", self)
	subTitle:SetText("Echo your thoughts into the text field below.")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(60)

	self.entry = vgui.Create("DTextEntry", self)
	self.entry:SetSize(self:GetWide() - 40, 30)
	self.entry:CenterHorizontal()
	self.entry:SetFont("HudDefault")
	self.entry:SetY(85)
	
	self.panelTint = Color(25, 25, 25) --default background

	self.charCounter = vgui.Create("DLabel", self)
	self.charCounter:SetFont("DermaDefault")
	self.charCounter:SetColor(Color(175, 175, 175))
	self.charCounter:SetText((maxBigSize - 0) .. " characters left")
	self.charCounter:SizeToContents()
	self.charCounter.initialWidth = self.charCounter:GetWide()

	self.cooldownLabel = vgui.Create("DLabel", self)
	self.cooldownLabel:SetFont("DermaDefault")
	self.cooldownLabel:SetColor(Color(175, 175, 175))

	self.charProgressBg = vgui.Create("DPanel", self)
	self.charProgressBg.Paint = function(this, w, h)
		surface.SetDrawColor(50, 50, 50)
		surface.DrawRect(0, 0, w, h)
	end

	self.charProgress = vgui.Create("DPanel", self.charProgressBg)
	self.charProgress:SetWide(0)
	self.charProgress.Paint = function(this, w, h)
		surface.SetDrawColor(175, 175, 175)
		surface.DrawRect(0, 0, w, h)
	end

	self.entry.OnTextChanged = function(this) -- Add length & profanity warnings
		local text = this:GetValue()
		local length = text:len()

		self.charCounter:SetText(math.max(0, maxBigSize - length) .. " characters left")
		self.charCounter:SizeToContents()

		local progress = math.Clamp(length / maxBigSize, 0, 1)
		self.charProgress:SetWide(self.charProgressBg:GetWide() * progress)

		local r, g, b = 175, 175, 175
		if progress > 0.9 then
			r, g, b = 255, 50, 50
		elseif progress > 0.7 then
			r, g, b = 255, 150, 0
		end
		self.charProgress.Paint = function(this, w, h)
			surface.SetDrawColor(r, g, b)
			surface.DrawRect(0, 0, w, h)
		end

		if (length > maxBigSize) then
			this:SetText(text:sub(1, maxBigSize))
			this:SetCaretPos(maxBigSize)

			self:ToggleWarning(true, false)
		else
			self:ToggleWarning(false, false)
		end

		if (IsOffensive(text)) then
			self:ToggleWarning(true, true)
		else
			self:ToggleWarning(false, true)
		end

		if (length > maxSmallLength and !self.large) then
			self.large = true
			self:ToggleSize(true)

		elseif (length <= maxSmallLength and self.large) then
			self:ToggleSize(false)
			self.large = false
		end
	end
	self.entry.OnKeyCodePressed = function(this, key)
		if (key != KEY_ESCAPE) then return end

		self:Close()
	end
	self.entry.Paint = function(this, width, height)
		surface.SetDrawColor(50, 50, 50)
		surface.DrawRect(0, 0, width, height)

		this:DrawTextEntryText(Color(175, 175, 175), color_white, Color(175, 175, 175))
	end
	self.entry:RequestFocus()

	self.submit = vgui.Create("DButton", self)
	self.submit:SetSize(self:GetWide() * 0.3, 30)
	self.submit:SetText("Submit")
	self.isDraftMode = false
	self.submit:SetFont("CreditsText")
	self.submit:SetColor(Color(175, 175, 175))
	self.submit:CenterHorizontal()
	self.submit:SetY(125)
	self.submit.Paint = function(this, width, height)
		surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.DrawRect(0, 0, width, height)
	end
	self.submit.DoClick = function()
		CreateEcho(self.entry:GetValue())

		self:Close()

		EchoSound("button_click")
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
		self:Close()

		EchoSound("button_click")
	end
end

local warningTypes = {
	[true] = "A wise message avoids profanity and hate speech.",
	[false] = "A wise message is concise and to the point."
}

function PANEL:ToggleWarning(bState, bAlt)
	if (bState) then
		if (IsValid(self["warning" .. (bAlt and "Offensive" or "Length")])) then return end

		local warning = vgui.Create("DLabel", self)
		warning:SetText(warningTypes[bAlt])
		warning:SetColor(bAlt and Color(255, 50, 50) or Color(255, 255, 75))
		warning:SizeToContents()
		warning:CenterHorizontal()
		warning:SetY(((IsValid(self.warningOffensive) or IsValid(self.warningLength)) and 100) or 80)
		warning:SetAlpha(0)
		warning:AlphaTo(255, 0.25)

		self["warning" .. (bAlt and "Offensive" or "Length")] = warning
		self:ToggleSize(true)
	elseif (IsValid(self["warning" .. (bAlt and "Offensive" or "Length")])) then
		local warning = self["warning" .. (bAlt and "Offensive" or "Length")]
		warning.removing = true

		warning:AlphaTo(0, 0.25, 0, function()
			warning:Remove()
		end)

		self:ToggleSize(true)
	end
end

function PANEL:ToggleSize(bEnlarge)
	if (bEnlarge) then
		local extra = 0
		local bLarge = self.large

		if (IsValid(self.warningLength) and !self.warningLength.removing) then
			extra = extra + 20
		end

		if (IsValid(self.warningOffensive) and !self.warningOffensive.removing) then
			extra = extra + 20
		end

		if (bLarge) then
			EchoSound("whoosh", nil, 0.75)
		end

		self:SizeTo(self:GetWide(), (bLarge and 310 or 210) + extra, 0.5)
		self:MoveTo(self:GetX(), ScrH() / 2 - ((bLarge and 155 or 100) + extra / 2), 0.5)

		self.entry:MoveTo(self.entry:GetX(), 85 + extra, 0.5)
		self.entry:SizeTo(self.entry:GetWide(), bLarge and 130 or 30, 0.5)
		self.entry:SetMultiline(true)

		self.submit:MoveTo(self.submit:GetX(), (bLarge and 225 or 125) + extra, 0.5)
		self.cancel:MoveTo(self.cancel:GetX(), (bLarge and 265 or 165) + extra, 0.5)
	else
		local extra = 0

		if (IsValid(self.warningLength) and !self.warningLength.removing) then
			extra = extra + 20
		end

		if (IsValid(self.warningOffensive) and !self.warningOffensive.removing) then
			extra = extra + 20
		end

		if (self.large) then
			EchoSound("whoosh", 90, 0.75)
		end

		self:SizeTo(self:GetWide(), 210 + extra, 0.5)
		self:MoveTo(self:GetX(), ScrH() / 2 - 100 + extra / 2, 0.5)

		self.entry:MoveTo(self.entry:GetX(), 85 + extra, 0.5)
		self.entry:SizeTo(self.entry:GetWide(), 30, 0.5, nil, nil, function(animData, targetPanel)
			if not self.large then
				targetPanel:SetMultiline(false)
			end
		end)

		self.submit:MoveTo(self.submit:GetX(), 125 + extra, 0.5)
		self.cancel:MoveTo(self.cancel:GetX(), 165 + extra, 0.5)
	end
end

function PANEL:Close()
	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	EchoSound("whoosh", 90, 0.75)
end

function PANEL:Think()
	if (IsValid(self.charCounter)) then
		self.charCounter:SetPos(self:GetWide() - self.charCounter:GetWide() - 20, self.entry:GetY() + self.entry:GetTall() + 4)

		if (IsValid(self.charProgressBg)) then
			self.charProgressBg:SetPos(self:GetWide() - self.charCounter.initialWidth - 20, self.charCounter:GetY() + self.charCounter:GetTall() + 2)
			self.charProgressBg:SetSize(self.charCounter.initialWidth, 4)
		end
	end

	if (IsValid(self.cooldownLabel)) then
		local currentTime = os.time()
		local totalRemaining = math.max(0, nextEcho - currentTime)
		local isOnCooldown = totalRemaining > 0
		local draftsEnabled = GetConVar("echoes_enable_drafts"):GetBool()
		self.isDraftMode = draftsEnabled and isOnCooldown
		
		local cooldownText, cooldownColor
		if self.isDraftMode then
			local newSendTime = GetProjectedDraftSendTime()
			local draftWait = math.max(0, newSendTime - os.time())
			cooldownText = "Will be sent in: " .. string.NiceTime(draftWait)
			cooldownColor = Color(255, 165, 0)
		else
			if isOnCooldown then
				cooldownText = "Cooldown: " .. string.NiceTime(totalRemaining)
				cooldownColor = Color(255, 165, 0)
			else
				local currentMap = game.GetMap()
				local mapEchoCount = 0
				for _, echo in ipairs(writtenEchoes) do
					if echo.map == currentMap then
						mapEchoCount = mapEchoCount + 1
					end
				end
				local nextCooldown = (mapEchoCount + 1) * 60  --60s per map echo +1 for new
				cooldownText = "Next cooldown: " .. string.NiceTime(nextCooldown)
				cooldownColor = Color(175, 175, 175)
			end
		end
		
		self.cooldownLabel:SetText(cooldownText)
		self.cooldownLabel:SetColor(cooldownColor)
		self.cooldownLabel:SizeToContents()
		self.cooldownLabel:SetPos(self:GetWide() - self.cooldownLabel:GetWide() - 10, self:GetTall() - self.cooldownLabel:GetTall() - 10)
	end

	if IsValid(self.title) then
		local titleText = self.isDraftMode and "Draft Echo" or "Create Echo"
		local titleColor = self.isDraftMode and Color(255, 165, 0) or color_white
		self.title:SetText(titleText)
		self.title:SetTextColor(titleColor)
		self.title:SizeToContents()
	end

	self.panelTint = self.isDraftMode and LerpColor(0.1, Color(25, 25, 25), Color(255, 165, 0)) or Color(25, 25, 25)

	if IsValid(self.submit) then
		local buttonText = self.isDraftMode and "Submit Draft" or "Submit"
		self.submit:SetText(buttonText)
		self.submit:SetColor(self.isDraftMode and Color(255, 165, 0) or Color(175, 175, 175))
	end

	local draftCount = #drafts or 0
	local draftText = self.isDraftMode and "Draft(" .. draftCount .. "/3)" or ""
	if IsValid(self.draftCountLabel) then
		self.draftCountLabel:SetText(draftText)
		self.draftCountLabel:SizeToContents()
		self.draftCountLabel:SetPos(10, self:GetTall() - self.draftCountLabel:GetTall() - 10)
	else
		if draftText ~= "" then
			self.draftCountLabel = vgui.Create("DLabel", self)
			self.draftCountLabel:SetFont("DermaDefault")
			self.draftCountLabel:SetColor(Color(255, 165, 0))
			self.draftCountLabel:SetText(draftText)
			self.draftCountLabel:SizeToContents()
			self.draftCountLabel:SetPos(10, self:GetTall() - self.draftCountLabel:GetTall() - 10)
		end
	end
	if IsValid(self.draftCountLabel) and draftText == "" then
		self.draftCountLabel:Remove()
		self.draftCountLabel = nil
	end

	if IsValid(self.charCounter) then
		self.charCounter:SetPos(self:GetWide() - self.charCounter:GetWide() - 20, self.entry:GetY() + self.entry:GetTall() + 4)
	end
	if IsValid(self.charProgressBg) then
		self.charProgressBg:SetPos(self:GetWide() - self.charCounter.initialWidth - 20, self.charCounter:GetY() + self.charCounter:GetTall() + 2)
		self.charProgressBg:SetSize(self.charCounter.initialWidth, 4)
	end
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_R and key != KEY_TAB) then return end

	self:Close()
end

local notif = Material("echoesbeyond/notification.png")
local vignette = Material("echoesbeyond/vignette.png")

function PANEL:Paint(width, height)
	Derma_DrawBackgroundBlur(self, self.startTime)

	local bgColor = self.panelTint or Color(25, 25, 25)
	if self.isDraftMode then
		local orangeTint = LerpColor(0.1, Color(25, 25, 25), Color(255, 165, 0))
		bgColor = orangeTint
	end
	
	surface.SetDrawColor(bgColor)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)

	surface.SetDrawColor(200, 200, 200)
	surface.SetMaterial(notif)
	surface.DrawTexturedRect(width * 0.15, 45, width - width * 0.3, 2)
end

vgui.Register("echoEntry", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "entry_OnPauseMenuShow", function()
	if (!IsValid(echoEntry)) then return end

	echoEntry:Close()

	return false
end)
