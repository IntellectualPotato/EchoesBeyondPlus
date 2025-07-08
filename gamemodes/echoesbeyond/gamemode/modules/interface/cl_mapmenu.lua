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

	for name, amount in SortedPairsByValue(mapList, true) do
		if (filter and !name:lower():find(filter:lower())) then continue end
		if (!filter and amount < 10) then continue end

		local entry = vgui.Create("DPanel", self.mapListPanel)
		entry:Dock(TOP)
		entry:DockPadding(5, 0, 15, 0)
		entry:SetTall(20)
		entry:DockMargin(0, 0, 0, 5)
		entry.Paint = function(this, width, height)
			local amount = mapList[name] or amount
			local echoDisplay = (EchoesOnMaps and (EchoesOnMaps[name] ~= nil and EchoesOnMaps[name] or "NONE") or "NONE")
			draw.SimpleText("(" .. echoDisplay .. ") " .. amount .. " Echoes", "DermaDefault", width - 10, height / 2, this.textColor, TEXT_ALIGN_RIGHT, TEXT_ALIGN_CENTER)
			local installed = self.installedMaps[name]
			this.textColor = LerpColor(FrameTime() * (installed and 3 or 1), this.textColor, installed and Color(100, 200, 100) or Color(200, 200, 200))
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

		entry:SetAlpha(0)
		entry:AlphaTo(255, 0.25, 0.02 * mapNum)
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
