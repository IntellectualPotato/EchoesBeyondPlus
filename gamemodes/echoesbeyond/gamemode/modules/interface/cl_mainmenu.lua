local echoMat = Material("echoesbeyond/echo_simple.png", "smooth")
local mapMat = Material("echoesbeyond/map.png", "smooth")
local settingsMat = Material("echoesbeyond/settings.png", "smooth")
local reportMat = Material("echoesbeyond/report.png", "smooth")
local vignette = Material("echoesbeyond/vignette.png", "smooth")
local creditsMat = Material("echoesbeyond/credits.png", "smooth")
local communityMat = Material("echoesbeyond/communitybtn.png", "smooth")
local changelogMat = Material("echoesbeyond/changelog.png", "smooth")
local pinsMat = Material("echoesbeyond/pins.png", "smooth")
local plusMat = Material("echoesbeyond/echo_plus.png", "smooth")
local teleportMat = Material("echoesbeyond/teleport.png", "smooth")
local progressMat = Material("echoesbeyond/EchoProgress.png", "smooth")
local progressMatlc = Material("echoesbeyond/EchoProgress_lowcontrast.png", "smooth")

surface.CreateFont( "Echoes_statsfont", {
	font = "Roboto",
	size = 18,
	scanlines = 0,
	antialias = true,
} )

local function UpdatePlyStats()
	UpdateEchoesOnMaps()
	net.Start("EchoGiveInfo")
		net.WriteUInt(#writtenEchoes or 0, 20)
		net.WriteUInt(EchoesOnMaps[game.GetMap()] or 0, 20)
	net.SendToServer()
end

timer.Simple(5, function()
	UpdatePlyStats()
end)

timer.Create("updateSVstats", 60, -1, function()
	UpdatePlyStats()
end)

local PANEL = {}

function PANEL:Init()
	if (IsValid(mainMenu)) then
		mainMenu:Remove()
	end

	mainMenu = self

	FetchStats()
	UpdateEchoesOnMaps()
	timer.Create("echoesFetchStats", 1, 0, FetchStats)

	self.colorStats1, self.colorStats3 = Color(200, 200, 200), Color(200, 200, 200)

	self:SetSize(ScrW() / 2.5, ScrH() / 2)
	self:Center()
	self:MakePopup()
	self:SetAlpha(0)
	self:AlphaTo(255, 0.5)

	EchoSound("whoosh", nil, 0.75)

	local title = vgui.Create("DLabel", self)
	title:SetText("Echoes Beyond")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	local subTitle = vgui.Create("DLabel", self)
	subTitle:SetText("- A cinematic thought experiment -")
	subTitle:SizeToContents()
	subTitle:CenterHorizontal()
	subTitle:SetY(55)

	--update available button
	local updateButton = vgui.Create("DButton", self)
	updateButton:SetText("")
	updateButton:SetSize(180, 25)
	updateButton:SetPos((self:GetWide() - 180) / 2, self:GetTall() - 160)
	updateButton:SetVisible(EBPLUS_UpdateAvailable or false)
	updateButton.Paint = function(self, w, h)
		if not EBPLUS_UpdateAvailable then return end
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.DrawRect(0, 0, w, h)
		surface.SetMaterial(progressMatlc)
		local tileSize = h + 25
		local yOffset = CurTime() * 8 % tileSize
		for x = 0, w - tileSize, tileSize do
			surface.DrawTexturedRect(x, yOffset - tileSize, tileSize, tileSize)
			surface.DrawTexturedRect(x, yOffset, tileSize, tileSize)
		end
		local remaining = w % tileSize
		if remaining > 0 then
			local x = w - remaining
			surface.DrawTexturedRectUV(x, yOffset - tileSize, remaining, tileSize, 0, 0, remaining / tileSize, 1)
			surface.DrawTexturedRectUV(x, yOffset, remaining, tileSize, 0, 0, remaining / tileSize, 1)
		end
		draw.SimpleText("EB+ Update Available!", "DermaDefaultBold", w/2, h/2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		surface.SetDrawColor(0, 0, 0, 200)
		surface.SetMaterial(vignette)
		surface.DrawTexturedRect(0, 0, w, h)
	end
	updateButton.DoClick = function()
		gui.OpenURL("https://github.com/IntellectualPotato/EchoesBeyondPlus")
		EchoSound("button_click")
	end


	local mapOption = vgui.Create("DButton", self)
	mapOption:SetSize(48, 48)
	mapOption:SetPos(10, 10)
	mapOption:SetText("")
	mapOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(mapMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	mapOption.DoClick = function()
		EchoSound("button_click")

		if (IsValid(pinnedEchoesMenu)) then pinnedEchoesMenu:Close(true) end
		if (IsValid(personalEchoesMenu)) then personalEchoesMenu:Close(true) end

		if (IsValid(mapMenu)) then
			mapMenu:Close()
		else
			vgui.Create("echoMapMenu")
		end
	end

	local personalEchoes = vgui.Create("DButton", self)
	personalEchoes:SetSize(48, 48)
	personalEchoes:SetPos(10, 48 + 20)
	personalEchoes:SetText("")
	personalEchoes.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(echoMat)
		surface.DrawTexturedRect(-7, -7, width + 14, height + 14)
	end
	personalEchoes.DoClick = function()
		EchoSound("button_click")

		if (IsValid(pinnedEchoesMenu)) then pinnedEchoesMenu:Close(true) end
		if (IsValid(mapMenu)) then mapMenu:Close(true) end

		if (IsValid(personalEchoesMenu)) then
			personalEchoesMenu:Close()
		else
			vgui.Create("echoPersonalEchoesMenu")
		end
	end

	local pinnedEchoesButton = vgui.Create("DButton", self)
    pinnedEchoesButton:SetSize(48, 48)
    pinnedEchoesButton:SetPos(10, personalEchoes:GetY() + personalEchoes:GetTall() + 10) 
    pinnedEchoesButton:SetText("")
    pinnedEchoesButton.Paint = function(self, width, height)
        surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
        surface.SetMaterial(pinsMat)
        surface.DrawTexturedRect(0, 0, width, height)
    end
    pinnedEchoesButton.DoClick = function()
        EchoSound("button_click")

        if (IsValid(mapMenu)) then mapMenu:Close(true) end
        if (IsValid(personalEchoesMenu)) then personalEchoesMenu:Close(true) end

        if (IsValid(pinnedEchoesMenu)) then
            pinnedEchoesMenu:Close()
        else
            vgui.Create("echoPinnedEchoesMenu")
        end
    end

	if not EchoesSettings["echoes_immersivemode"] then
		local allEchoes = vgui.Create("DButton", self)
		allEchoes:SetSize(48, 48)
		allEchoes:SetPos(10, pinnedEchoesButton:GetY() + pinnedEchoesButton:GetTall() + 10)
		allEchoes:SetText("")
		allEchoes.Paint = function(self, width, height)
			surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
			surface.SetMaterial(Material("echoesbeyond/echo_multi.png", "smooth"))
			surface.DrawTexturedRect(-7, -7, width + 14, height + 14)
		end
		allEchoes.DoClick = function()
			EchoSound("button_click")
			if (IsValid(mainMenu)) then mainMenu:Close(true) end
			LocalPlayer():ConCommand("echoes_menu")
		end
	end
	
	local settingsOption = vgui.Create("DButton", self)
	settingsOption:SetSize(48, 48)
	settingsOption:SetPos(self:GetWide() - 48 - 10, 10)
	settingsOption:SetText("")
	settingsOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(settingsMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	settingsOption.DoClick = function()
		EchoSound("button_click")

		if (IsValid(reportMenu)) then reportMenu:Close(true) end
		if (IsValid(creditsMenu)) then creditsMenu:Close(true) end

		if (IsValid(settingsMenu)) then
			settingsMenu:Close()
		else
			vgui.Create("echoSettingsMenu")
		end
	end

	local creditsOption = vgui.Create("DButton", self)
	creditsOption:SetSize(48, 48)
	creditsOption:SetPos(self:GetWide() - 48 - 10, self:GetTall() - 48 - 10)
	creditsOption:SetText("")
	creditsOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(creditsMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	creditsOption.DoClick = function()
		EchoSound("button_click")

		if (IsValid(settingsMenu)) then settingsMenu:Close(true) end
		if (IsValid(reportMenu)) then reportMenu:Close(true) end
		if (IsValid(communityMenu)) then communityMenu:Close(true) end

		if (IsValid(creditsMenu)) then
			creditsMenu:Close()
		else
			vgui.Create("echoCreditsMenu")
		end
	end

	local CommunityOption = vgui.Create("DButton", self)
	CommunityOption:SetSize(48, 48)
	CommunityOption:SetPos(self:GetWide() - 48 - 10, creditsOption:GetY() - 48 - 10)
	CommunityOption:SetText("")
	CommunityOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(communityMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	CommunityOption.DoClick = function()
		EchoSound("button_click")

		if (IsValid(settingsMenu)) then settingsMenu:Close(true) end
		if (IsValid(reportMenu)) then reportMenu:Close(true) end
		if (IsValid(creditsMenu)) then creditsMenu:Close(true) end

		if (IsValid(communityMenu)) then
			communityMenu:Close()
		else
			vgui.Create("echoCommunityMenu")
		end
	end

	local changelogOption = vgui.Create("DButton", self)
	changelogOption:SetSize(48, 48)
	changelogOption:SetPos(10, self:GetTall() - 48 - 10)
	changelogOption:SetText("")
	changelogOption.Paint = function(self, width, height)
		surface.SetDrawColor(self:IsDown() and Color(100, 100, 100) or self:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
		surface.SetMaterial(changelogMat)
		surface.DrawTexturedRect(0, 0, width, height)
	end
	changelogOption.DoClick = function()
		EchoSound("button_click")

		vgui.Create("echoChangelog")
	end

	if (endPartyEnabled) then
		local endParty = vgui.Create("DButton", self)
		endParty:SetSize(self:GetWide() * 0.25, 30)
		endParty:SetText("End Party Mode")
		endParty:SetFont("CreditsText")
		endParty:SetColor(Color(175, 175, 175))
		endParty:Center()
		endParty.Paint = function(this, width, height)
			surface.SetDrawColor(this:IsDown() and Color(100, 100, 100) or this:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
			surface.DrawRect(0, 0, width, height)
		end
		endParty.DoClick = function(this)
			this:Remove()
			timer.Adjust("echoesParty", 0)

			EchoNotify("Party mode disabled.")
		end
	end

	local maps = {}
	self.ownMapCount = 0

	for i = 1, #writtenEchoes do
		local map = writtenEchoes[i].map
		if (maps[map]) then continue end

		maps[map] = true
	end

	self.ownMapCount = table.Count(maps)

	local players = player.GetAll()
    local numPlayers = #players
    local columns = 3
    local rows = math.ceil(numPlayers / columns)
    local entryGap = 5
    local padding = 10
    local entryHeight = 60

    local panelWidth = mainMenu:GetWide()
    local entryWidth = (panelWidth - padding * 2 - entryGap * (columns - 1)) / columns
    local panelHeight = padding * 2 + rows * entryHeight + (rows - 1) * entryGap

    self.playerListPanel = vgui.Create("DPanel", mainMenu:GetParent())
    self.playerListPanel:SetSize(panelWidth, panelHeight)
    self.playerListPanel:SetPos(mainMenu:GetX(), mainMenu:GetY() + mainMenu:GetTall() + 10)
    self.playerListPanel:SetAlpha(0)
    self.playerListPanel:AlphaTo(255, 0.5)
    self.playerListPanel.Paint = function(self, w, h)
        surface.SetDrawColor(25, 25, 25)
        surface.DrawRect(0, 0, w, h)
        surface.SetMaterial(vignette)
        surface.DrawTexturedRect(0, 0, w, h)
    end
    self.playerListPanel.Think = function(self)
        if not IsValid(mainMenu) then self:Remove() return end
    end

    local function RefreshPlayerList()
    	self.playerListPanel:Clear()
	    for i, ply in ipairs(players) do
	        local col = (i - 1) % columns
	        local row = math.floor((i - 1) / columns)
	        local xPos = padding + col * (entryWidth + entryGap)
	        local yPos = padding + row * (entryHeight + entryGap)

	        local entry = vgui.Create("DPanel", self.playerListPanel)
	        entry:SetSize(entryWidth, entryHeight)
	        entry:SetPos(xPos, yPos)
	        entry.Paint = function(self, w, h)
	        	if (not IsValid(ply) or numPlayers ~= #player.GetAll()) then players = player.GetAll() numPlayers = #players RefreshPlayerList() return  end
	            draw.RoundedBox(4, 0, 0, w, h, ply:Alive() and Color(50, LocalPlayer() == ply and 60 or 50, 50, 200) or Color(80, 40, 40, 200))
	              draw.SimpleText(ply:Nick()..(ply:Alive() and "" or " (DEAD)"), "DermaDefaultBold", 50, 5, Color(255, 255, 255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	            local totalEchoes = ply:GetNWInt("TotalEchoes", 0)
	            local mapEchoes = ply:GetNWInt("MapEchoes", 0)
	            draw.SimpleText("Echoes: " .. totalEchoes .. " | This map: " .. mapEchoes, "DermaDefault", 50, 25, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	            draw.SimpleText("Ping: " .. ply:Ping(), "DermaDefault", 50, 45, Color(200, 200, 200), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP)
	        end

	        local avatar = vgui.Create("AvatarImage", entry)
	        avatar:SetSize(40, 40)
	        avatar:SetPos(5, (entryHeight - 40) / 2)
	        avatar:SetPlayer(ply, 40)

	        if LocalPlayer() == ply then continue end
	        local teleportButton = vgui.Create("DButton", entry)
	        teleportButton:SetSize(30, 30)
	        teleportButton:SetPos(entry:GetWide() - 35, entryHeight - 35)
	        teleportButton:SetText("")
	        teleportButton.Paint = function(self, w, h)
	            surface.SetDrawColor(
	                self:IsDown() and Color(125, 125, 125) or 
	                self:IsHovered() and Color(100, 100, 100) or 
	                Color(75, 75, 75)
	            )
	            surface.SetMaterial(teleportMat)
	            surface.DrawTexturedRect(0, 0, w, h)
	        end
	        teleportButton.DoClick = function()
	            EchoSound("button_click")
	            net.Start("echoTeleport")
	                net.WriteVector(ply:GetPos())
	            net.SendToServer()
	        end
	    end
	end
	RefreshPlayerList()
end

function PANEL:UpdateStats(newUserCount, newEchoCount, newMapCount, newMaps)
	if (newUserCount != userCount or newMapCount != mapCount or newEchoCount != globalEchoCount) then
		self.colorStats3 = Color(50, 150, 255)
	end

	if (!newUserCount and newEchoCount != #echoes) then
		self.colorStats1 = Color(50, 150, 255)
	end

	if (!IsValid(mapMenu) or !newMaps) then return end

	mapMenu:UpdateMaps(newMaps)
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)

	local breatheLayer = math.cos(CurTime() * 1.5)
	surface.SetDrawColor(255,255,255,50)
	surface.SetMaterial(plusMat)

	surface.DrawTexturedRectRotated(
	    width / 2,           -- x-position adjusted by spacing
	    height / 4 + 5 * breatheLayer, -- y-position with a slight vertical breathing effect
	    height / 1.5,                 -- width of the object
	    height / 1.5,                 -- height of the object
	    0                             -- rotation
	)

	local spacing = width * 0.33
	for num = 1, 3 do
	     local breatheLayer = math.sin(CurTime() + (num * 2) * 1.5)
	     surface.SetDrawColor(num == 2 and 0 or 255, num == 1 and 0 or 255, num == 3 and 0 or 255, 5)
	     surface.SetMaterial(echoMat)

	     local offset = 0
	    if num == 1 then
	         offset = -spacing  -- left side
	     elseif num == 3 then
	         offset = spacing   -- right side
	    end

	     surface.DrawTexturedRectRotated(
	        width / 2 + offset,           -- x-position adjusted by spacing
	        height / 2 + 5 * breatheLayer, -- y-position with a slight vertical breathing effect
	        height / 1.5,                 -- width of the object
	        height / 1.5,                 -- height of the object
	            0                             -- rotation
	    )
	end

	if (endPartyEnabled) then
		surface.SetDrawColor(0, 0, 0, 200)
		surface.DrawRect(0, 0, width, height)
	end

	local function countRealEchoes()
		local count = 0
		for _, echo in ipairs(echoes) do
			if not echo.isDraft then
				count = count + 1
			end
		end
		return count
	end

	local echoCount = countRealEchoes()
	local frameTime = FrameTime()
	local percentage = 0
	if globalEchoCount > 0 then
		percentage = math.Round((#writtenEchoes / globalEchoCount) * 100, 2)
	end

	local function wrapColoredText(segments, maxWidth, font)
		surface.SetFont(font)
		local lines = {}
		local currentLine = {}
		local currentWidth = 0

		for _, segment in ipairs(segments) do
			local words = string.Explode(" ", segment.text)
			for wordIndex, word in ipairs(words) do
				local testWidth = currentWidth
				if #currentLine > 0 then
					testWidth = testWidth + surface.GetTextSize(" ")
				end
				testWidth = testWidth + surface.GetTextSize(word)

				if testWidth > maxWidth and #currentLine > 0 then
					--line full, add current line to lines
					table.insert(lines, currentLine)
					currentLine = {{text = word, color = segment.color}}
					currentWidth = surface.GetTextSize(word)
				else
					if #currentLine > 0 then
						currentWidth = currentWidth + surface.GetTextSize(" ")
					end
					table.insert(currentLine, {text = word, color = segment.color})
					currentWidth = currentWidth + surface.GetTextSize(word)
				end
			end
		end

		if #currentLine > 0 then
			table.insert(lines, currentLine)
		end

		return lines
	end

	local font = self.statsFont or "Echoes_statsfont"
	local maxWidth = width - 116
	local lineHeight = draw.GetFontHeight(font)

	if not EchoesOnMaps[game.GetMap()] then
		draw.SimpleText("LOADING", "DermaLarge", width / 2, height - 120, Color(180, 180, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
		return
	end

	--colored segments for progress text
	local progressSegments = {
		{text = "There " .. (echoCount == 1 and "is" or "are") .. " currently " .. echoCount .. " echo" .. (echoCount == 1 and "" or "es") .. " on this map. You have read ", color = self.colorStats1}
	}
	local progressTbl = CreateProgressColorTable(readEchoCount, echoCount)
	for _, v in ipairs(progressTbl) do
		table.insert(progressSegments, {text = v.text, color = v.color})
	end
	table.insert(progressSegments, {text = " of them.", color = self.colorStats1})

	local personalText = "You have written " .. #writtenEchoes .. " echo" .. (#writtenEchoes == 1 and "" or "es") .. " across " .. self.ownMapCount .. (self.ownMapCount == 1 and " map." or " different maps. and " .. EchoesOnMaps[game.GetMap()] .. " on this map.")
	local globalText = "There are currently " .. globalEchoCount .. " total echoes across " .. mapCount .. " different maps from " .. userCount .. " different users."

	local textData = {
		{segments = {{text = "You represent " .. percentage .. "% of the total echoes.", color = Color(180, 180, 180)}}},
		{segments = progressSegments},
		{segments = {{text = personalText, color = Color(200, 200, 200)}}},
		{segments = {{text = globalText, color = self.colorStats3}}}
	}

	local allLines = {}
	for _, data in ipairs(textData) do
		local lines = wrapColoredText(data.segments, maxWidth, font)
		for _, line in ipairs(lines) do
			table.insert(allLines, line)
		end
	end

	local totalHeight = #allLines * lineHeight
	local startY = height - totalHeight

	for i, line in ipairs(allLines) do
		local y = startY + (i-1) * lineHeight
		local lineWidth = 0
		for _, segment in ipairs(line) do
			lineWidth = lineWidth + surface.GetTextSize(segment.text)
		end
		lineWidth = lineWidth + surface.GetTextSize(" ") * (#line - 1)

		local startX = (width / 2) - (lineWidth / 2)
		for j, segment in ipairs(line) do
			draw.SimpleText(segment.text, font, startX, y, segment.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			startX = startX + surface.GetTextSize(segment.text)
			if j < #line then
				startX = startX + surface.GetTextSize(" ")
			end
		end
	end

	self.colorStats1 = LerpColor(frameTime, self.colorStats1, Color(200, 200, 200))
	self.colorStats3 = LerpColor(frameTime, self.colorStats3, Color(200, 200, 200))
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_TAB) then return end

	self:Close()
end

function PANEL:Close()
	timer.Remove("echoesFetchStats")

	local panel = self.playerListPanel

	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	if (IsValid(panel)) then
		panel:AlphaTo(0, 0.25, 0, function()
			panel:Remove()
		end)
	end

	if (IsValid(mapMenu)) then
		mapMenu:Close(true)
	end

	if (IsValid(settingsMenu)) then
		settingsMenu:Close(true)
	end

	if (IsValid(reportMenu)) then
		reportMenu:Close(true)
	end

	if (IsValid(creditsMenu)) then
		creditsMenu:Close(true)
	end

	if (IsValid(communityMenu)) then
		communityMenu:Close(true)
	end

	if (IsValid(personalEchoesMenu)) then
		personalEchoesMenu:Close(true)
	end

	if (IsValid(pinnedEchoesMenu)) then
	       pinnedEchoesMenu:Close(true)
	   end

	EchoSound("whoosh", 90, 0.75)

	self:SetKeyboardInputEnabled(false)
	self:SetMouseInputEnabled(false)
end

vgui.Register("echoMainMenu", PANEL, "EditablePanel")

hook.Add("ScoreboardShow", "mainmenu_ScoreboardShow", function()
	vgui.Create("echoMainMenu")

	return false
end)

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "mainmenu_OnPauseMenuShow", function()
	if (!IsValid(mainMenu)) then return end

	mainMenu:Close()

	return false
end)

hook.Add("HUDPaint", "mainmenu_HUDPaint", function()
	if (!IsValid(mainMenu)) then return end
	local alpha = mainMenu:GetAlpha()

	surface.SetDrawColor(25, 25, 25, 200 * (alpha / 255))
	surface.DrawRect(0, 0, ScrW(), ScrH())
end)
