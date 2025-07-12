pinnedEchoes = {}
local PINS_FILE = "echoesbeyond/pinned_echoes.json"

function LoadPinnedEchoes()
    if not file.Exists(PINS_FILE, "DATA") then
        pinnedEchoes = {}
        return
    end

    local content = file.Read(PINS_FILE, "DATA")
    if content and content ~= "" then
        local success, data = pcall(util.JSONToTable, content)
        if success and type(data) == "table" then
            pinnedEchoes = data
        end
    else
        pinnedEchoes = {}
    end
end

function SavePinnedEchoes()
    local json = util.TableToJSON(pinnedEchoes, true)
    file.Write(PINS_FILE, json)
end

function IsEchoPinned(echoId)
    for _, pin in ipairs(pinnedEchoes) do
        if pin.id == echoId then
            return true, pin
        end
    end
    return false
end

function TogglePin(echo)
    local isPinned, _ = IsEchoPinned(echo.id)

    if isPinned then
        for i, pin in ipairs(pinnedEchoes) do
            if pin.id == echo.id then
                table.remove(pinnedEchoes, i)
                break
            end
        end
        echo.pinned = false
        SavePinnedEchoes()
        EchoNotify("Echo unpinned.")
        EchoSound("echo_unpin", math.random(95, 105), 0.4)

        if echo.pinTime then echo.pinTime = nil end
    else
        local newPin = {
            id = echo.id,
            map = game.GetMap(),
            text = echo.text,
            pos = echo.pos,
            timestamp = os.time()
        }
        table.insert(pinnedEchoes, newPin)
        echo.pinned = true
        SavePinnedEchoes()
        EchoNotify("Echo pinned!")
        EchoSound("echo_pin", math.random(95, 105), 0.5)

        echo.pinTime = CurTime()
    end
    SyncPinnedStatus()
end

local vignette = Material("echoesbeyond/vignette.png", "smooth")
local unpinMat = Material("echoesbeyond/trash.png", "smooth")
local teleportMat = Material("echoesbeyond/teleport.png", "smooth")

local PANEL = {}

function PANEL:Init()
    if (IsValid(pinnedEchoesMenu)) then
        pinnedEchoesMenu:Remove()
    end

    pinnedEchoesMenu = self

    self.echoList = {}
    self.unpinning = false

    self:SetSize(ScrW() / 4, ScrH() / 1.5)
     if IsValid(mainMenu) then
        self:SetPos(mainMenu:GetX() - self:GetWide() - 10, mainMenu:GetY())
    else
        self:Center()
        self:SetX(10)
    end
    self:CenterVertical()
    self:MakePopup()
    self:SetAlpha(0)

    self:AlphaTo(255, 0.25)
    EchoSound("whoosh", nil, 0.75)

    local title = vgui.Create("DLabel", self)
    title:SetText("Pinned Echoes")
    title:SetFont("DermaLarge")
    title:SizeToContents()
    title:CenterHorizontal()
    title:SetY(20)

    local subTitle = vgui.Create("DLabel", self)
    subTitle:SetText("Your collection of saved Echoes.")
    subTitle:SizeToContents()
    subTitle:CenterHorizontal()
    subTitle:SetY(55)

    local subTitle = vgui.Create("DLabel", self)
    subTitle:SetText("Hold alt and press \"E\" to pin the closest active echo.")
    subTitle:SizeToContents()
    subTitle:CenterHorizontal()
    subTitle:SetY(73)

    self.searchBar = vgui.Create("DTextEntry", self)
    self.searchBar:SetSize(self:GetWide() - 20, 20)
    self.searchBar:SetPos(10, 90)
    self.searchBar:SetPlaceholderText("Search for a Pinned Echo...")
    self.searchBar.OnChange = function(this)
        self:ListEchoes(this:GetValue():lower())
    end
    self.searchBar.Paint = function(this, width, height)
        surface.SetDrawColor(50, 50, 50)
        surface.DrawRect(0, 0, width, height)
        this:DrawTextEntryText(color_white, color_white, color_white)
    end
    self.searchBar:RequestFocus()

    self.echoContainer = vgui.Create("DScrollPanel", self)
    self.echoContainer:SetPos(10, 120)
    self.echoContainer:SetSize(self:GetWide() - 20, self:GetTall() - 130)
    self.echoContainer.Paint = function(this, width, height)
        surface.SetDrawColor(0, 0, 0, 100)
        surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
    end
    self.echoContainer.VBar.Paint = function(this, width, height)
        surface.SetDrawColor(35, 35, 35)
        surface.DrawRect(0, 0, this:GetWide(), this:GetTall())
    end
    self.echoContainer.VBar.btnGrip.Paint = function(this, width, height)
        surface.SetDrawColor(45, 45, 45)
        surface.DrawRect(0, 0, self.echoContainer.VBar.btnGrip:GetWide(), self.echoContainer.VBar.btnGrip:GetTall())
    end
    self.echoContainer.VBar.btnUp.Paint = function() end
    self.echoContainer.VBar.btnDown.Paint = function() end

    self:ListEchoes()
end

function PANEL:ListEchoes(filter)
    self.echoContainer:Clear()
    self.echoList = {}

    if (filter) then
        filter = filter:Trim()
        filter = filter ~= "" and filter
    end

    local currMap = game.GetMap()
    local echoNum = 1

    for i = #pinnedEchoes, 1, -1 do
        local echo = pinnedEchoes[i]
        local mapName = echo.map

        if (filter and not echo.text:lower():find(filter:lower())) then continue end

        local basePanel = vgui.Create("DPanel", self.echoContainer)
        basePanel:Dock(TOP)
        basePanel:SetTall(80)
        basePanel:DockMargin(0, 0, 10, 10)
        basePanel.Paint = function(this, width, height)
            surface.SetDrawColor(30, 30, 30)
            surface.DrawRect(0, 0, width, height)
        end

        local mapLabel = vgui.Create("DLabel", basePanel)
        mapLabel:SetPos(5, 3)
        mapLabel:SetText(mapName)
        mapLabel:SetFont("TargetID")
        mapLabel:SetTextColor(Color(200, 200, 200))
        mapLabel:SizeToContents()
        mapLabel:SetContentAlignment(4)

        if echo.timestamp then
            local timeLabel = vgui.Create("DLabel", basePanel)
            timeLabel:SetFont("DermaDefault")
            timeLabel:SetText(os.date("%Y-%m-%d %H:%M", echo.timestamp))
            timeLabel:SetTextColor(Color(150, 150, 150))
            timeLabel:SizeToContents()
            timeLabel:SetPos(mapLabel:GetX() + mapLabel:GetWide() + 10, mapLabel:GetY() + 5)
        end

        local echoText = vgui.Create("DTextEntry", basePanel)
        echoText:SetSize(self.echoContainer:GetWide() - 30, basePanel:GetTall())
        echoText:SetPos(3, 30)
        echoText:SetText(echo.text)
        echoText:SetMultiline(true)
        echoText:SetEditable(false)
        echoText:SetDrawBackground(false)
        echoText:SetTextColor(Color(200, 200, 200))
        echoText:SetPaintBackground(false)

        local barEnabled = self.echoContainer.VBar.Enabled
        if (self.unpinning) then barEnabled = not barEnabled end

        local unpinButton = vgui.Create("DButton", basePanel)
        unpinButton:SetSize(20, 20)
        unpinButton:SetPos(self.echoContainer:GetWide() - (barEnabled and 35 or 50), 5)
        unpinButton:SetText("")
        unpinButton.Paint = function(this, width, height)
            surface.SetDrawColor(this:IsDown() and Color(125, 125, 125) or this:IsHovered() and Color(100, 100, 100) or Color(75, 75, 75))
            surface.SetMaterial(unpinMat)
            surface.DrawTexturedRect(0, 0, width, height)
        end
        unpinButton.DoClick = function(this)
            EchoSound("button_click")
            EchoesConfirm("Unpin Echo", "Are you sure you want to unpin this Echo?", function()
                self.unpinning = true
                table.remove(pinnedEchoes, i)
                SavePinnedEchoes()
                self:ListEchoes(self.searchBar:GetValue())
                EchoNotify("Echo unpinned successfully.")
                self.unpinning = false
                SyncPinnedStatus()
            end)
        end

        local teleportButton = vgui.Create("DButton", basePanel)
        teleportButton:SetSize(20, 20)
        teleportButton:SetPos(self.echoContainer:GetWide() - (barEnabled and 60 or 75), 5)
        teleportButton:SetText("")
        teleportButton.Paint = function(this, width, height)
            surface.SetDrawColor(this:IsDown() and Color(125, 125, 125) or this:IsHovered() and Color(100, 100, 100) or Color(75, 75, 75))
            surface.SetMaterial(teleportMat)
            surface.DrawTexturedRect(0, 0, width, height)
        end
        teleportButton.DoClick = function(this)
            EchoSound("button_click")
            if (mapName != currMap) then
                EchoesConfirm("Switch Map", "This Echo is in a different map. Do you want to change to it?", function()
                    if (file.Exists("maps/" .. mapName .. ".bsp", "GAME")) then
                        file.Write("echoesbeyond/teleport.json", util.TableToJSON({map = mapName, pos = echo.pos}))
                        RunConsoleCommand("changelevel", mapName)
                    else
                        gui.OpenURL("https://steamcommunity.com/workshop/browse/?appid=4000&searchtext=" .. mapName .. "&requiredtags%5B%5D=Map&requiredtags%5B%5D=Addon")
                    end
                end)
            else
                net.Start("echoTeleport")
                    net.WriteVector(echo.pos)
                net.SendToServer()
            end
        end

        basePanel:SetAlpha(0)
        basePanel:AlphaTo(255, 0.25, 0.05 * echoNum)
        self.echoList[#self.echoList + 1] = basePanel
        echoNum = echoNum + 1
    end
end

function PANEL:Paint(width, height)
    surface.SetDrawColor(25, 25, 25)
    surface.DrawRect(0, 0, width, height)
    surface.SetMaterial(vignette)
    surface.DrawTexturedRect(0, 0, width, height)
end

function PANEL:OnKeyCodePressed(key)
    if (key == KEY_ESCAPE or key == KEY_TAB) then self:Close() end
end

function PANEL:Close(bNoSound)
    self:AlphaTo(0, 0.25, 0, function() self:Remove() end)
    if (bNoSound) then return end
    EchoSound("whoosh", 90, 0.75)
end

vgui.Register("echoPinnedEchoesMenu", PANEL, "EditablePanel")

hook.Add("OnPauseMenuShow", "pinnedechoes_OnPauseMenuShow", function()
    if (IsValid(pinnedEchoesMenu)) then
        pinnedEchoesMenu:Close()
        return false
    end
end)