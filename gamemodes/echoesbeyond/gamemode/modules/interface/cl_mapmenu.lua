include("cl_widgets.lua")
local vignette = Material("echoesbeyond/vignette.png", "smooth")

-- The map menu
local PANEL = {}

function PANEL:Init()
	if (IsValid(mapMenu)) then
		mapMenu:Remove()
	end

	mapMenu = self

	self.mapList = {}
	self.installedMaps = {}

	for _, map in pairs(file.Find("maps/*.bsp", "GAME")) do
		self.installedMaps[string.StripExtension(map)] = true
	end

	timer.Create("echoesMapUpdater", 1, 0, function()
		self.installedMaps = {}

		for _, map in pairs(file.Find("maps/*.bsp", "GAME")) do
			self.installedMaps[string.StripExtension(map)] = true
		end
	end)

	self:SetSize(ScrW() / 4, ScrH() / 1.5)
	self:Center()
	self:SetX(mainMenu:GetX() - self:GetWide() - 10)
	self:MakePopup()
	self:SetAlpha(0)

	self:AlphaTo(255, 0.5)
	EchoSound("whoosh", nil, 0.75)

	local title = vgui.Create("DLabel", self)
	title:SetText("Map List")
	title:SetFont("DermaLarge")
	title:SizeToContents()
	title:CenterHorizontal()
	title:SetY(20)

	self.subTitle = vgui.Create("DLabel", self)
	self.subTitle:SetText("Below is a list of 0 maps with Echoes in them.")
	self.subTitle:SizeToContents()
	self.subTitle:CenterHorizontal()
	self.subTitle:SetY(55)

	local subSubTitle = vgui.Create("DLabel", self)
	subSubTitle:SetText("Click on a map to search for it in the Steam Workshop, or change to it if it's downloaded.")
	subSubTitle:SizeToContents()
	subSubTitle:CenterHorizontal()
	subSubTitle:SetY(75)

	local searchBar = vgui.Create("DTextEntry", self)
	searchBar:SetSize(self:GetWide() - 20, 20)
	searchBar:SetPos(10, 100)
	searchBar:SetPlaceholderText("Search for a map...")
	searchBar.oldValue = ""
	searchBar.OnChange = function(this)
		local search = this:GetValue():lower()
		if (search == this.oldValue) then return end

		this.oldValue = search

		self:ListMaps(search)
	end
	searchBar.Paint = function(this, width, height)
		surface.SetDrawColor(50, 50, 50)
		surface.DrawRect(0, 0, width, height)

		this:DrawTextEntryText(color_white, color_white, color_white)
	end

	searchBar:RequestFocus()

	self.mapListPanel = vgui.Create("DScrollPanel", self)
	self.mapListPanel:SetPos(10, 130)
	self.mapListPanel:SetSize(self:GetWide() - 20, self:GetTall() - 140)

	-- floating filter panel below the main map panel, this looks better
	local filterPanel = vgui.Create("DPanel", self:GetParent() or self)
	filterPanel:SetSize(self:GetWide() - 20, 100) --will be adjusted
	filterPanel:SetPos(self:GetX() + 10, self:GetY() + self:GetTall() + 10)
	filterPanel:SetAlpha(0)
	filterPanel:AlphaTo(255, 0.5)
	filterPanel.Paint = function(this, width, height)
		surface.SetDrawColor(30, 30, 30, 230)
		surface.DrawRect(0, 0, width, height)
		surface.SetDrawColor(60, 60, 60)
		surface.DrawOutlinedRect(0, 0, width, height, 1)
	end

	local leftColumnX = 10
	local rightColumnX = filterPanel:GetWide() / 2 + 10

	local sortLabel = vgui.Create("DLabel", filterPanel)
	sortLabel:SetText("Sort by:")
	sortLabel:SetFont("DermaDefault")
	sortLabel:SizeToContents()
	sortLabel:SetPos(leftColumnX, 18)
	sortLabel:SetColor(Color(200, 200, 200))

	_, self.SortDropdown = CreateDropdown(filterPanel, {"Echo count", "My Echo count", "Percentage read"}, 1, 18, function(selected)
		self:ListMaps(searchBar:GetValue())
	end, leftColumnX + 50)

	local helpText = vgui.Create("DLabel", filterPanel)
	helpText:SetText("Left click to check, right click to invert filter")
	helpText:SetFont("DermaDefault")
	helpText:SizeToContents()
	helpText:SetPos(10, 45)
	helpText:SetColor(Color(150, 150, 150))

	_, self.FilterEchoed = CreateMultiCheckbox(filterPanel, "Echoed on", 65, function(state)
		if state ~= 0 then self.FilterShowLocal:SetValue(false) end
		self:ListMaps(searchBar:GetValue())
	end, leftColumnX)

	_, self.FilterInstalled = CreateMultiCheckbox(filterPanel, "Installed", 65, function(state)
		if state ~= 0 then self.FilterShowLocal:SetValue(false) end
		self:ListMaps(searchBar:GetValue())
	end, rightColumnX)

	_, self.FilterCompleted = CreateMultiCheckbox(filterPanel, "100% read", 85, function(state)
		self:ListMaps(searchBar:GetValue())
	end, leftColumnX)

	_, self.FilterShowLocal = CreateSimpleCheckbox(filterPanel, "Show local", false, 85, function(checked)
		if checked then
			self.FilterInstalled:SetState(0)
			self.FilterEchoed:SetState(0)
		end
		self:ListMaps(searchBar:GetValue())
	end, rightColumnX)

	--panel height to fit content
	filterPanel:SetTall(110)

	--reference to filter panel for closing
	self.filterPanel = filterPanel
	self.mapListPanel.Paint = function(this, width, height)
		surface.SetDrawColor(0, 0, 0, 100)
		surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
	end
	self.mapListPanel.VBar.Paint = function(this, width, height)
		surface.SetDrawColor(35, 35, 35)
		surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
	end
	self.mapListPanel.VBar.btnGrip.Paint = function(this, width, height)
		surface.SetDrawColor(45, 45, 45)
		surface.DrawRect(0, 0, self.mapListPanel.VBar.btnGrip:GetWide(), self.mapListPanel.VBar.btnGrip:GetTall())
	end
	self.mapListPanel.VBar.btnUp.Paint = function() end
	self.mapListPanel.VBar.btnDown.Paint = function() end

	self:ListMaps()
end

function PANEL:ListMaps(filter)
	for _, entry in pairs(self.mapList) do
		entry:Remove()
	end

	local mapNum = 1

	if (filter) then
		filter = filter:Trim()
		filter = filter != "" and filter
	end

	self.mapList = {}

	local echoedFilter = self.FilterEchoed and self.FilterEchoed:GetState() or 0
	local installFilter = self.FilterInstalled and self.FilterInstalled:GetState() or 0
	local sortMode = self.SortDropdown and self.SortDropdown:GetSelected() or 1
	local showLocal = self.FilterShowLocal and self.FilterShowLocal:GetChecked()
	local completedFilter = self.FilterCompleted and self.FilterCompleted:GetState() or 0

	local mapPairs
	if (showLocal) then
		mapPairs = {}
		for name, _ in pairs(self.installedMaps) do
			mapPairs[#mapPairs+1] = {name=name, amount=mapList[name] or 0}
		end
		table.sort(mapPairs, function(a, b) return a.name:lower() < b.name:lower() end)
	else
		if sortMode == 2 then  --my Echo count
			local t = {}
			for name, amount in pairs(mapList) do
				t[#t+1] = {name=name, amount=amount, personal=EchoesOnMaps and EchoesOnMaps[name] or 0}
			end
			table.SortByMember(t, "personal", false)
			mapPairs = t
		elseif sortMode == 3 then  --percentage read
			local t = {}
			for name, amount in pairs(mapList) do
				local read = readMapCounts[name] or 0
				local percentage = amount > 0 and (read / amount) * 100 or 0
				t[#t+1] = {name=name, amount=amount, percentage=percentage}
			end
			table.SortByMember(t, "percentage", false)
			mapPairs = t
		else  --echo count (default)
			mapPairs = {}
			for name, amount in SortedPairsByValue(mapList, true) do
				mapPairs[#mapPairs+1] = {name=name, amount=amount}
			end
		end
	end

	for _, v in ipairs(mapPairs) do
		local name = v.name
		local amount = v.amount

		if (filter) then
			local normalized_filter = filter:lower():gsub("[%s_]", "")
			local normalized_name = name:lower():gsub("[%s_]", "")
			if (!normalized_name:find(normalized_filter, 1, true)) then continue end
		end
		if (not showLocal and not filter and amount < 10) then continue end

		local totalEchoesOnMap = mapList[name] or amount
		local readOnMap = readMapCounts[name] or 0
		local isCompleted = (readOnMap >= totalEchoesOnMap) and totalEchoesOnMap > 0

		if hideCompleted and isCompleted then continue end

		local echoed = EchoesOnMaps and EchoesOnMaps[name] and EchoesOnMaps[name] > 0
		local notEchoed = not (EchoesOnMaps and EchoesOnMaps[name] and EchoesOnMaps[name] > 0)
		local installed = self.installedMaps[name]

		if echoedFilter == 1 and not echoed then continue elseif echoedFilter == 2 and echoed then continue end
		if installFilter == 1 and not installed then continue elseif installFilter == 2 and installed then continue end
		if completedFilter == 1 and not isCompleted then continue elseif completedFilter == 2 and isCompleted then continue end

		local entry = vgui.Create("DPanel", self.mapListPanel)
		entry:Dock(TOP)
		entry:DockPadding(5, 0, 15, 0)
		entry:SetTall(20)
		entry:DockMargin(0, 0, 0, 5)
		entry.Paint = function(this, width, height)
			local totalEchoesOnMap = mapList[name] or amount
			local readOnMap = readMapCounts[name] or 0
			local personalEchoesOnMap = (EchoesOnMaps and EchoesOnMaps[name]) or 0
			local textPieces = {}
			table.insert(textPieces, {text = "(" .. tostring(personalEchoesOnMap) .. ") ", color = (personalEchoesOnMap == 0 and Color(150, 50, 50) or Color(50, 150, 255))})
			local progressTbl = CreateProgressColorTable(readOnMap, totalEchoesOnMap)
			for _, piece in ipairs(progressTbl) do
				table.insert(textPieces, piece)
			end
			table.insert(textPieces, {text = " Echoes", color = Color(200, 200, 200)})
			surface.SetFont("DermaDefault")
			local total_w = 0
			for _, piece in ipairs(textPieces) do
				local w, _ = surface.GetTextSize(piece.text)
				total_w = total_w + w
			end
			local start_x = width - 10 - total_w
			for _, piece in ipairs(textPieces) do
				draw.SimpleText(piece.text, "DermaDefault", start_x, height / 2, piece.color, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				local w, _ = surface.GetTextSize(piece.text)
				start_x = start_x + w
			end
			local installed = self.installedMaps[name]
			local allRead = (readOnMap >= totalEchoesOnMap) and totalEchoesOnMap > 0
			local targetColor
			if allRead then
				targetColor = Color(255, 215, 0)
			elseif installed then
				targetColor = Color(100, 200, 100)
			else
				targetColor = Color(200, 200, 200)
			end
			this.textColor = LerpColor(FrameTime() * 3, this.textColor, targetColor)
		end
		entry.textColor = Color(200, 200, 200)

		local mapName = vgui.Create("DButton", entry)
		mapName:SetText(name)
		mapName:SizeToContents()
		mapName:Dock(LEFT)
		mapName:SetContentAlignment(4)
		mapName:SetPaintBackground(false)
		mapName.Think = function(this)
			if (this:IsHovered()) then
				this:SetTextColor(Color(0, 125, 255))
			else
				this:SetTextColor(entry.textColor)
			end
		end
		mapName.DoClick = function(this)
			if (file.Read("maps/" .. name .. ".bsp", "GAME")) then
				RunConsoleCommand("changelevel", name)
			else
				gui.OpenURL("https://steamcommunity.com/workshop/browse/?appid=4000&searchtext=" .. name .. "&requiredtags%5B%5D=Map&requiredtags%5B%5D=Addon")
			end
		end
		--[[
		entry:SetAlpha(0)
		entry:AlphaTo(255, 0.25, 0.02 * mapNum)
		]] --this may make it funky with some stuff and its annoying to wait for it
		self.mapList[name] = entry
		mapNum = mapNum + 1
	end

	self.subTitle:SetText("Below is a list of " .. table.Count(self.mapList) .. " maps with Echoes in them.")
	self.subTitle:SizeToContents()
end

function PANEL:UpdateMaps(newMaps)
	for name, amount in pairs(newMaps) do
		local entry = self.mapList[name]
		if (!entry) then continue end
		if (mapList[name] == amount) then continue end

		entry.textColor = self.installedMaps[name] and Color(25, 200, 25) or Color(50, 150, 255)
	end
end

function PANEL:Paint(width, height)
	surface.SetDrawColor(25, 25, 25)
	surface.DrawRect(0, 0, width, height)

	surface.SetMaterial(vignette)
	surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:OnKeyCodePressed(key)
	if (key != KEY_TAB) then return end

	self:Close()
end

function PANEL:Close(bNoSound)
	timer.Remove("echoesMapUpdater")

	if IsValid(self.filterPanel) then
		--close any open dropdowns ( ihate this so much)
		if self.SortDropdown and self.SortDropdown.CloseDropdown then
			self.SortDropdown:CloseDropdown()
		end
		--disable input too
		self.filterPanel:SetMouseInputEnabled(false)
		self.filterPanel:AlphaTo(0, 0.25, 0, function()
			self.filterPanel:Remove()
		end)
	end

	self:AlphaTo(0, 0.25, 0, function()
		self:Remove()
	end)

	if (bNoSound) then return end
	EchoSound("whoosh", 90, 0.75)
end

vgui.Register("echoMapMenu", PANEL, "EditablePanel")

-- Close when pressing escape
hook.Add("OnPauseMenuShow", "mapmenu_OnPauseMenuShow", function()
	if (!IsValid(mapMenu)) then return end

	mapMenu:Close()

	return false
end)
