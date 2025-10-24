local vignette = Material("echoesbeyond/vignette.png", "smooth")
local notif = Material("echoesbeyond/notification.png")
local communityMat = Material("echoesbeyond/community.png", "smooth")
local echoMat = Material("echoesbeyond/echo.png", "smooth")

local PARTICLE_SIZE = 42
local y = 80
local fadeCounter = 0

local function AddText(text, menu)
	local lines = string.Split(text, "\n")
	for _, line in ipairs(lines) do
		local label = vgui.Create("DLabel", menu)
		label:SetText(line)
		label:SetFont("DermaDefault")
		label:SizeToContents()
		label:CenterHorizontal()
		label:SetY(y)
		y = y + 20
	end
end

local function AddRow(name1, name2, name3, menu)
	local rowPanel = vgui.Create("DPanel", menu)
	rowPanel:SetSize(menu:GetWide() - 40, 30)
	rowPanel:SetPos(20, y)
	rowPanel:SetAlpha(0)
	rowPanel:AlphaTo(255, 0.5 + (fadeCounter / 3 * 0.5), fadeCounter * 0.1)
	fadeCounter = fadeCounter + 1
	rowPanel.Paint = function() end

	local names = {name1, name2, name3}
	local nameWidth = (rowPanel:GetWide() - 20) / 3

	for i, name in ipairs(names) do
		if name and name ~= "" then
			--backdrop
			local backdrop = vgui.Create("DPanel", rowPanel)
			backdrop:SetSize(nameWidth - 10, 30)
			backdrop:SetPos((i-1) * nameWidth + 5, 2.5)
			backdrop.Paint = function(this, width, height)
				surface.SetDrawColor(50, 50, 50, 150)
				surface.SetMaterial(notif)
				surface.DrawTexturedRect(0, 0, width, height)
			end

			local label = vgui.Create("DLabel", backdrop)
			label:SetText(name)
			label:SetFont("DermaLarge")
			label:SizeToContents()
			if label:GetWide() > backdrop:GetWide() then
				label:SetFont("DermaDefaultBold")
				label:SizeToContents()
				if label:GetWide() > backdrop:GetWide() then
					label:SetText(string.sub(name, 1, 15) .. "...")
					label:SizeToContents()
				end
			end
			label:Center()
		end
	end

	--vertical separators between names (2 per row)
	local sep1 = vgui.Create("DPanel", rowPanel)
	sep1:SetSize(5, 30)
	sep1:SetPos(nameWidth - 1, 2.5)
	sep1.Paint = function(this, width, height)
		surface.SetDrawColor(100, 120, 120)
		surface.SetMaterial(notif)
		surface.DrawTexturedRect(0, 0, width, height)
	end

	local sep2 = vgui.Create("DPanel", rowPanel)
	sep2:SetSize(5, 30)
	sep2:SetPos(nameWidth * 2 - 1, 2.5)
	sep2.Paint = function(this, width, height)
		surface.SetDrawColor(100, 120, 120)
		surface.SetMaterial(notif)
		surface.DrawTexturedRect(0, 0, width, height)
	end

	y = y + 35
end

local function AddSeparator(menu)
	local sep = vgui.Create("DPanel", menu)
	sep:SetSize(menu:GetWide() - 40, 2)
	sep:SetPos(20, y)
	sep.Paint = function(this, width, height)
		surface.SetDrawColor(200, 200, 200)
		surface.SetMaterial(notif)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	y = y + 10
end

local PANEL = {}

function PANEL:Init()
	if (IsValid(communityMenu)) then
		communityMenu:Remove()
	end

	communityMenu = self
	y = 80
	fadeCounter = 0

	self:SetSize(ScrW() / 4, ScrH() / 1.5)
	self:Center()
	self:SetX(mainMenu:GetX() + mainMenu:GetWide() + 10)
	self:MakePopup()
	self:SetAlpha(0)

	self:AlphaTo(255, 0.5)
	EchoSound("whoosh", nil, 0.75)

	--separate particle panel so thye render UNDER names
	local particlesPanel = vgui.Create("DPanel", self)
	particlesPanel:SetSize(self:GetWide(), self:GetTall())
	particlesPanel:SetPos(0, 0)
	particlesPanel:SetZPos(-1)
	particlesPanel.Paint = function(this, width, height)
		--draw them' particles mmyes
		for _, particle in ipairs(this.particles) do
			if particle.y <= height and particle.y >= 0 then
				surface.SetDrawColor(particle.color.r, particle.color.g, particle.color.b, particle.alpha)
				surface.SetMaterial(echoMat)
				local scaledSize = PARTICLE_SIZE * particle.scale
				surface.DrawTexturedRect(particle.x, particle.y, scaledSize, scaledSize)
			end
		end
	end
	particlesPanel.Think = function(this)
		local panelHeight = this:GetTall()
		local fadeInDuration = 15

		for _, particle in ipairs(this.particles) do
			particle.y = particle.y - particle.speed

			--calculate fade in progress
			local timeSinceReset = CurTime() - particle.resetTime
			local fadeInProgress = math.min(1, timeSinceReset / fadeInDuration)

			--calculate fade out progress
			local fadeStart = panelHeight - 300
			local fadeEnd = 500
			local fadeOutProgress = 0
			if particle.y < fadeStart then
				fadeOutProgress = (fadeStart - particle.y) / (fadeStart - fadeEnd)
			end

			--combine fade progress, get that low taper fade
			particle.alpha = 255 * fadeInProgress * (1 - fadeOutProgress)

			--reset to bottom when reaching top
			if particle.y < fadeEnd then
				local newX = math.random(0, this:GetWide() - PARTICLE_SIZE)
				particle.x = newX
				particle.y = math.random(panelHeight - 500, panelHeight)
				particle.resetTime = CurTime() --i forgot curtime exists, dying
				particle.color = math.random(1, 4) == 1 and Color(100, 100, 100) or Color(150, 255, 255)
				particle.scale = math.random(75, 115) / 100 --0.75x to 1.15x
			end
		end
	end

	--init particles
	particlesPanel.particles = {}
	local numParticles = 20
	local panelWidth = particlesPanel:GetWide()
	local panelHeight = particlesPanel:GetTall()

	for i = 1, numParticles do
		local particle = {
			x = math.random(0, panelWidth - PARTICLE_SIZE),
			y = math.random(panelHeight - 500, panelHeight),
			alpha = 0,
			speed = math.random(15, 50) / 100, --slow float up, like a dead fish in a fishtank :pensive:
			color = math.random(1, 4) == 1 and Color(100, 100, 100) or Color(150, 255, 255), --1 in 4 chance for read, else unread
			resetTime = CurTime(),
			scale = math.random(75, 115) / 100 --0.75x to 1.15x
		}
		table.insert(particlesPanel.particles, particle)
	end

	local title = vgui.Create("DLabel", self)
	title:SetText("Community")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	--Global read counts tracker to see how much time you've wasted reading echoes hehe
	local readText = vgui.Create("DLabel", self)
	readText:SetText("You have read " .. #ReadEchoes() .. " Echoes from this amazing community, That's " .. (globalEchoCount > 0 and math.Round((#ReadEchoes() / globalEchoCount) * 100, 2) or 0) .. "% of all echoes!")	
	readText:SetFont("DermaDefaultBold")
	readText:SizeToContents()
	readText:CenterHorizontal()
	readText:SetY(50)

	AddText("Below is a wall of names of those who have contributed to the EB community\nNote: Names are subjective, and can be removed/added at any time\nNothing personal if your name may be absent, there are a lot of people!", self)

	AddSeparator(self)

	--   m any    names .. . . subjective of course, this is just ones ive found/remembered as i was doing this, may update ofc, order means nothing
	AddRow("Muffin", "Salithin", "Lafta", self)
	AddRow("Shimmer", "Aether", "Tomi", self)
	AddRow("Sevvii", "Vladimir Plazovich", "Amtias", self)
	AddRow("Kaz", "Mari", "Cheese eater", self)
	AddRow("CNate", "InfiniteArchive", "Skolli", self)
	AddRow("LordOfGeckos (Gecko)", "Funky493", "nathan51310", self)
	AddRow("R. Rivers", "XG417", "Randomly Initialed girl (Lucy)", self)
	AddRow("Fluman", "Vivian", "Derra", self)
	AddRow("Dodeca", "Nelymi Ruxspin (N.R.)", "Den4ik17", self)
	AddRow("Hazmat141", "EchoBlu", "On The Run!", self)
	AddRow("Pix", "redfoxlol", "Panton_CLEO", self)
	AddRow("Chlebiri", "\"Golf\" Guy", "Fluffy A", self)
	AddRow("Xlutch", "#LNG1LND", "Artanis", self)
	AddRow("Potion", "Misty_Bun", "Knaurl", self)
	AddRow("AnonBW", "hazxyte", "Akari", self)
	AddRow("KABLUEE2", "GMod Explorer", "", self)

	local communityHeightScaled = (373 / 1000) * self:GetWide()

	local communityPanel = vgui.Create("DPanel", self)
	communityPanel:SetSize(self:GetWide(), communityHeightScaled)
	communityPanel:SetPos(0, self:GetTall() - communityPanel:GetTall())
	communityPanel.Paint = function(this, width, height)
		surface.SetDrawColor(255, 255, 255, 255)
		surface.SetMaterial(communityMat)
		surface.DrawTexturedRect(0, 0, width, height)
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

vgui.Register("echoCommunityMenu", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "communitymenu_OnPauseMenuShow", function()
	if (!IsValid(communityMenu)) then return end

	communityMenu:Close()

	return false
end)
