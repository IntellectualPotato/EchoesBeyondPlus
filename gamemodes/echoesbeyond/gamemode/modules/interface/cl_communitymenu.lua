local vignette = Material("echoesbeyond/vignette.png", "smooth")
local notif = Material("echoesbeyond/notification.png")
local communityMat = Material("echoesbeyond/community.png", "smooth")
local echoMat = Material("echoesbeyond/echo.png", "smooth")
local arrow = Material("echoesbeyond/echo_arrow.png", "smooth")

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
		local panelWidth = this:GetWide()
		local fadeInDuration = 15

		for _, particle in ipairs(this.particles) do
			particle.y = particle.y - particle.speed

			--calculate fade in progress
			local timeSinceReset = CurTime() - particle.resetTime
			local fadeInProgress = math.min(1, timeSinceReset / fadeInDuration)

			--calculate fade out progress
			local fadeStartPercent = 0.8 --80% down the panel
			local fadeEndPercent = 0.3 --fade completely by 30% down
			local fadeStart = panelHeight * fadeStartPercent
			local fadeEnd = panelHeight * fadeEndPercent
			local fadeOutProgress = 0
			if particle.y < fadeStart then
				fadeOutProgress = (fadeStart - particle.y) / (fadeStart - fadeEnd)
			end

			--combine fade progress, get that low taper fade
			particle.alpha = 255 * fadeInProgress * (1 - fadeOutProgress)

			--reset to bottom when reaching top
			local resetStartPercent = 0.7
			if particle.y < fadeEnd then
				local newX = math.random(0, panelWidth - PARTICLE_SIZE * particle.scale)
				local resetStart = panelHeight * resetStartPercent
				particle.x = newX
				particle.y = math.random(resetStart, panelHeight)
				particle.resetTime = CurTime()
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
		local resetStart = panelHeight * 0.7 --70% of panel height
		local particle = {
			x = math.random(0, panelWidth - PARTICLE_SIZE),
			y = math.random(resetStart, panelHeight),
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
	local ttlRead = #ReadEchoes() + #writtenEchoes
	readText:SetText("You have read " .. ttlRead .. " Echoes from the community, That's " .. (globalEchoCount > 0 and math.Round((ttlRead / globalEchoCount) * 100, 2) or 0) .. "% of all echoes!")	
	readText:SetFont("DermaDefaultBold")
	readText:SizeToContents()
	readText:CenterHorizontal()
	readText:SetY(50)

	AddText("Below is a wall of names of those who have contributed to the EB community\nNote: Names are subjective, and can be removed/added at any time\nNothing personal if your name may be absent, there are a lot of people!", self)

	AddSeparator(self)

	-- scrollable panel for names
	local namesScrollPanel = vgui.Create("DScrollPanel", self)
	namesScrollPanel:SetSize(self:GetWide() - 40, self:GetTall() * 0.7 - y - 10)
	namesScrollPanel:SetPos(20, y)
	namesScrollPanel.Paint = function(this, width, height)
		surface.SetDrawColor(0, 0, 0, 50)
		surface.DrawRect(0, 0, width, height)
	end
	local sbar = namesScrollPanel:GetVBar()
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

	local namesY = 0
	local function AddRowToScroll(name1, name2, name3)
		local rowPanel = vgui.Create("DPanel", namesScrollPanel)
		rowPanel:SetSize(namesScrollPanel:GetWide() - 20, 30)
		rowPanel:SetPos(10, namesY)
		rowPanel:SetAlpha(0)
		rowPanel:AlphaTo(255, 0.5 + (fadeCounter / 3 * 0.5), fadeCounter * 0.1)
		fadeCounter = fadeCounter + 1
		rowPanel.Paint = function() end

		local names = {name1, name2, name3}
		local nameWidth = rowPanel:GetWide() / 3

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

		namesY = namesY + 35
	end

	--   m any    names .. . . subjective of course, this is just ones ive found/remembered as i was doing this, may update ofc, order means nothing
	AddRowToScroll("Muffin", "Salithin", "Lafta")
	AddRowToScroll("Shimmer", "Aether", "Tomi")
	AddRowToScroll("Sevvii", "Vladimir Plazovich", "Amtias")
	AddRowToScroll("Kaz", "Mari", "Cheese eater")
	AddRowToScroll("CNate", "InfiniteArchive", "Skolli")
	AddRowToScroll("LordOfGeckos (Gecko)", "Funky493", "nathan51310")
	AddRowToScroll("R. Rivers", "XG417", "Randomly Initialed girl (Lucy)")
	AddRowToScroll("Fluman", "Vivian", "Derra")
	AddRowToScroll("Dodeca", "Nelymi Ruxspin (N.R.)", "Den4ik17")
	AddRowToScroll("Hazmat141", "EchoBlu", "On The Run!")
	AddRowToScroll("Pix", "redfoxlol", "Panton_CLEO")
	AddRowToScroll("Chlebiri", "\"Golf\" Guy", "Fluffy A")
	AddRowToScroll("Xlutch", "#LNG1LND", "Artanis")
	AddRowToScroll("Potion", "Misty_Bun", "Knaurl")
	AddRowToScroll("AnonBW", "hazxyte", "Akari")
	AddRowToScroll("KABLUEE2", "GMod Explorer", "Delte")
	AddRowToScroll("Section 2", "Omniversequirk", "ihzma")
	AddRowToScroll("Calvin", "Canned_Toaster", "Hgrunt2009")
	AddRowToScroll("MoonMast3r", "Gunterb/Corvus", "Flufflez")
	AddRowToScroll("Dark", "Jame", "Mo")
	AddRowToScroll("A.G.A.", "qdshuck", "TotallyNotEd")
	AddRowToScroll("Avis", "Traya Tyto", "Whatwat")
	AddRowToScroll("MidnightGamer","Gatecat 13","")
	y = y + namesScrollPanel:GetTall() + 10

	local communityHeightScaled = (373 / 1000) * self:GetWide()

	local communityPanel = vgui.Create("DPanel", self)
	communityPanel:SetSize(self:GetWide(), communityHeightScaled)
	communityPanel:SetPos(0, self:GetTall() - communityPanel:GetTall())
	communityPanel:SetZPos(-2)
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
