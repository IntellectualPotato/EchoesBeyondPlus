local echoList, echoMenuPanel
local hideRead, hideOwner, hideVoid, onlyMilestones, superMilestones = false, false, false, false, false
local searchTerm = ""

local function PopulateEchoList()
    if not echoList then return end
    echoList:Clear()
    for _, echo in ipairs(echoes or {}) do
        if hideRead and echo.read then continue end
        if hideOwner and echo.isOwner then continue end
        if hideVoid and echo.inVoid then continue end

        local id = echo.id
        local mapid = idToSequential[echo.id] or -1
        local readText   = echo.read   and "Yes" or "No"
        local ownerText  = echo.isOwner and "Yes" or "No"
        local inVoidText = echo.inVoid and "In Void" or "Active"
        local echoText   = echo.text or ""

        if searchTerm ~= "" then
            local search = tostring(searchTerm or "")
            if not string.find(string.lower(echoText), string.lower(search)) then
                continue
            end
        end

        if onlyMilestones then
            local isMilestone = (id % 100 == 0 or mapid % 100 == 0)
            if not isMilestone then continue end
        end

        if superMilestones then
            local isSuperMilestone = (id % 1000 == 0 or mapid % 1000 == 0)
            if not isSuperMilestone then continue end
        end

        local row = echoList:AddLine(id, mapid, readText, ownerText, inVoidText, echoText)
        row.EchoData = echo

        for colIndex, colLabel in ipairs(row.Columns) do
            if colLabel:GetText() == "Yes" then
                colLabel:SetTextColor(Color(0,255,0))
            elseif colLabel:GetText() == "No" then
                colLabel:SetTextColor(Color(255,0,0))
            else
                colLabel:SetTextColor(Color(255,255,255))
            end
        end

        if id % 100 == 0 then
            row.Columns[1]:SetTextColor(Color(255,255,0))
        end
        if mapid % 100 == 0 then
            row.Columns[2]:SetTextColor(Color(255,255,0))
        end
    end
end

local function CreateEchoMenu()
    echoMenuPanel = vgui.Create("DFrame")
    echoMenuPanel:SetTitle("Echoes (" .. game.GetMap() .. ")")
    echoMenuPanel:SetSize(800, 600)
    echoMenuPanel:Center()
    echoMenuPanel:SetDraggable(true)
    echoMenuPanel:ShowCloseButton(true)
    echoMenuPanel:SetDeleteOnClose(false)
    echoMenuPanel:MakePopup()
    echoMenuPanel.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 30, 255))
    end

    local panelFilters = vgui.Create("DPanel", echoMenuPanel)
    panelFilters:SetSize(760, 30)
    panelFilters:SetPos(20, 30)
    panelFilters.Paint = function(self, w, h)
        draw.RoundedBox(0, 0, 0, w, h, Color(50, 50, 50, 255))
    end

    local checkboxHideRead = vgui.Create("DCheckBoxLabel", panelFilters)
    checkboxHideRead:SetText("Hide Read")
    checkboxHideRead:SetPos(10, 5)
    checkboxHideRead:SetValue(0)
    checkboxHideRead:SizeToContents()
    checkboxHideRead.OnChange = function(self, val)
        hideRead = val
        PopulateEchoList()
    end

    local checkboxHideOwner = vgui.Create("DCheckBoxLabel", panelFilters)
    checkboxHideOwner:SetText("Hide Owner")
    checkboxHideOwner:SetPos(120, 5)
    checkboxHideOwner:SetValue(0)
    checkboxHideOwner:SizeToContents()
    checkboxHideOwner.OnChange = function(self, val)
        hideOwner = val
        PopulateEchoList()
    end

    local checkboxHideVoid = vgui.Create("DCheckBoxLabel", panelFilters)
    checkboxHideVoid:SetText("Hide Void")
    checkboxHideVoid:SetPos(230, 5)
    checkboxHideVoid:SetValue(0)
    checkboxHideVoid:SizeToContents()
    checkboxHideVoid.OnChange = function(self, val)
        hideVoid = val
        PopulateEchoList()
    end

    local checkboxMilestones = vgui.Create("DCheckBoxLabel", panelFilters)
    checkboxMilestones:SetText("Only Milestones")
    checkboxMilestones:SetPos(340, 5)
    checkboxMilestones:SetValue(0)
    checkboxMilestones:SizeToContents()
    checkboxMilestones.OnChange = function(self, val)
        onlyMilestones = val
        PopulateEchoList()
    end

    local checkboxSuperMilestones = vgui.Create("DCheckBoxLabel", panelFilters)
    checkboxSuperMilestones:SetText("Super Milestones")
    checkboxSuperMilestones:SetPos(460, 5)
    checkboxSuperMilestones:SetValue(0)
    checkboxSuperMilestones:SizeToContents()
    checkboxSuperMilestones.OnChange = function(self, val)
        superMilestones = val
        PopulateEchoList()
    end

    local searchEntry = vgui.Create("DTextEntry", panelFilters)
    searchEntry:SetSize(200, 20)
    searchEntry:SetPos(580, 5)
    searchEntry:SetText("")
    searchEntry:SetTooltip("Search Text")
    searchEntry.OnChange = function(self)
        searchTerm = self:GetValue()
        PopulateEchoList()
    end

    echoList = vgui.Create("DListView", echoMenuPanel)
    echoList:SetPos(20, 70)
    echoList:SetSize(760, 450)
    echoList:SetMultiSelect(false)

    echoList:AddColumn("ID"):SetFixedWidth(50)
    echoList:AddColumn("map ID"):SetFixedWidth(50)
    echoList:AddColumn("Read"):SetFixedWidth(60)
    echoList:AddColumn("Owner"):SetFixedWidth(60)
    echoList:AddColumn("In Void"):SetFixedWidth(80)
    echoList:AddColumn("Text")

    echoList.Paint = function(self, width, height)
        surface.SetDrawColor(25, 25, 25)
        surface.DrawRect(0, 0, width, height)
        if vignette then
            surface.SetMaterial(vignette)
            surface.DrawTexturedRect(0, 0, width, height)
        end
    end
    echoMenuPanel.Paint = function(self, width, height)
        surface.SetDrawColor(25, 25, 25)
        surface.DrawRect(0, 0, width, height)
        if vignette then
            surface.SetMaterial(vignette)
            surface.DrawTexturedRect(0, 0, width, height)
        end
    end

    PopulateEchoList()

    local teleportButton = vgui.Create("DButton", echoMenuPanel)
    teleportButton:SetText("")
    teleportButton:SetPos(20, 530)
    teleportButton:SetSize(200, 30)
    teleportButton.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(70, 70, 70, 255) or Color(50, 50, 50, 255)
        draw.RoundedBox(0, 0, 0, w, h, col)
        draw.SimpleText("Teleport to Selected Echo", "DermaDefault", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    teleportButton.DoClick = function()
        local selected = echoList:GetSelectedLine()
        if not selected then return end
        local row = echoList:GetLine(selected)
        if row and row.EchoData then
            PrintTable(row.EchoData)
                net.Start("EchoTeleport")
                    net.WriteVector(row.EchoData.pos)
                net.SendToServer()
            echoMenuPanel:SetVisible(false)
        end
    end

    local refreshButton = vgui.Create("DButton", echoMenuPanel)
    refreshButton:SetText("")
    refreshButton:SetPos(240, 530)
    refreshButton:SetSize(100, 30)
    refreshButton.Paint = function(self, w, h)
        local col = self:IsHovered() and Color(70, 70, 70, 255) or Color(50, 50, 50, 255)
        draw.RoundedBox(0, 0, 0, w, h, col)
        draw.SimpleText("Refresh", "DermaDefault", w / 2, h / 2, Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
    refreshButton.DoClick = function()
        PopulateEchoList()
    end

    return echoMenuPanel
end

concommand.Add("echoes_menu", function()
    if not IsValid(echoMenuPanel) then
        CreateEchoMenu()
    else
        echoMenuPanel:SetVisible(true)
        echoMenuPanel:MakePopup()
    end
end)
