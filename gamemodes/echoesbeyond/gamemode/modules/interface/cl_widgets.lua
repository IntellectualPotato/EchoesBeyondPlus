--custom made to fit the style of EB hopefully (these are much more complicated than needed probably)
arrow = Material("echoesbeyond/echo_arrow.png", "smooth")
checkmark = Material("echoesbeyond/checkmark.png", "smooth")
chXmark = Material("echoesbeyond/chXmark.png", "smooth")
local function DrawCheckboxBox(s, w, h, checked, state)
    local boxColor = checked and Color(28, 40, 40) or (s:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50))
    if state then
        if state == 1 then
            boxColor = Color(0, 40, 0)
        elseif state == 2 then
            boxColor = Color(40, 0, 0)
        end
    end
    surface.SetDrawColor(boxColor)
    surface.DrawRect(0, 0, 20, 20)

    --lil border (yummy)
    surface.SetDrawColor(100, 100, 100)
    surface.DrawOutlinedRect(0, 0, 20, 20)

    if checked or state == 1 then
        surface.SetDrawColor(255, 255, 255)
        surface.SetMaterial(checkmark)
        surface.DrawTexturedRect(2, 2, 16, 16)
    elseif state == 2 then
        surface.SetDrawColor(255, 0, 0)
        surface.SetMaterial(chXmark)
        surface.DrawTexturedRect(2, 2, 16, 16)
    end
end

function CreateCheckbox(parent, text, convarName, y, onToggle)
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(parent:GetWide() - 100, 25)
    panel:SetPos(50, y)
    panel:SetMouseInputEnabled(true)

    local checked = false
    if convarName == "echoes_allowsandbox" or convarName == "cl_drawhud" then
        checked = GetConVar(convarName):GetBool()
    else
        checked = EchoesSettings[convarName]
    end

    local label = vgui.Create("DLabel", panel)
    label:SetText(text)
    label:SetFont("DermaDefault")
    label:SizeToContents()
    label:SetPos(30, 2)
    label:SetColor(Color(200, 200, 200))

    panel.Paint = function(s, w, h)
        DrawCheckboxBox(s, w, h, checked)
    end

    panel.OnMousePressed = function(s)
        checked = not checked
        if convarName == "echoes_allowsandbox" then --special case because its server-side
            net.Start("Echoes_ToggleAllowSandbox")
            net.WriteBool(checked)
            net.SendToServer()
        elseif convarName == "cl_drawhud" then
            RunConsoleCommand("cl_drawhud", checked and "1" or "0")
        else
            GetConVar(convarName):SetBool(checked)
        end
        if onToggle then onToggle(checked) end
        EchoSound("button_click")
        s:InvalidateLayout()
    end

    return y + panel:GetTall() + 5, panel
end

function CreateMultiCheckbox(parent, text, y, onChange, x)
    x = x or 50
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(parent:GetWide() - 100, 25)
    panel:SetPos(x, y)
    panel:SetMouseInputEnabled(true)

    local state = 0  --0: none, 1: check, 2: X (inverted :) )

    local label = vgui.Create("DLabel", panel)
    label:SetText(text)
    label:SetFont("DermaDefault")
    label:SizeToContents()
    label:SetPos(30, 2)
    label:SetColor(Color(200, 200, 200))

    panel.GetState = function() return state end
    panel.SetState = function(self, s) state = s; self:InvalidateLayout() end

    panel.Paint = function(s, w, h)
        DrawCheckboxBox(s, w, h, false, state)
    end

    panel.OnMousePressed = function(s, mouseCode)
        if mouseCode == MOUSE_LEFT then
            state = (state == 1) and 0 or 1
        elseif mouseCode == MOUSE_RIGHT then
            state = (state == 2) and 0 or 2
        end
        panel.state = state  --for external access
        if onChange then onChange(state) end
        EchoSound("button_click")
        s:InvalidateLayout()
    end

    return y + panel:GetTall() + 5, panel  -- return y and the panel for reference
end

function CreateDropdown(parent, options, defaultIndex, y, onChange, x)
    x = x or 50
    if not options or type(options) ~= "table" then options = {} end
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(parent:GetWide() - 100, 25)
    panel:SetPos(x, y)
    panel:SetMouseInputEnabled(true)

    local selectedIndex = defaultIndex or 1
    local isOpen = false

    local selectedLabel = vgui.Create("DLabel", panel)
    selectedLabel:SetText(options[selectedIndex] or "")
    selectedLabel:SetFont("DermaDefault")
    selectedLabel:SizeToContents()
    selectedLabel:SetPos(5, 6)
    selectedLabel:SetColor(Color(200, 200, 200))

    panel.GetSelected = function() return selectedIndex end
    panel.SetSelected = function(self, idx)
        selectedIndex = idx
        selectedLabel:SetText(options[selectedIndex] or "")
        selectedLabel:SizeToContents()
        if onChange then onChange(selectedIndex) end
    end

    panel.Paint = function(s, w, h)
        local bgColor = s:IsHovered() and Color(75, 75, 75) or Color(50, 50, 50)
        surface.SetDrawColor(bgColor)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(100, 100, 100)
        surface.DrawOutlinedRect(0, 0, w, h)

        -- Arrow
        local arrowColor = Color(200, 200, 200)
        surface.SetDrawColor(arrowColor)
        surface.SetMaterial(arrow)
        surface.DrawTexturedRectRotated(w - 18, 12, 16, 16, isOpen and 180 or 0)
    end

    panel.OnMousePressed = function(s)
        isOpen = not isOpen
        s:InvalidateLayout()
        EchoSound("button_click")
    end

    panel.CloseDropdown = function()
        isOpen = false
    end

    panel.OnRemove = function()
        if optionPanels then
            for _, op in ipairs(optionPanels) do
                if IsValid(op) then op:Remove() end
            end
        end
    end

    local optionPanels = {}
    for i, option in ipairs(options) do
        local optionPanel = vgui.Create("DPanel", panel:GetParent():GetParent()) --hopefulyl lets things go outside the box!!!11
        optionPanel:SetSize(panel:GetWide(), 25)
        optionPanel:SetVisible(false)
        optionPanel:SetMouseInputEnabled(true)
        optionPanel:SetZPos(100) --this too 2️⃣

        local optionLabel = vgui.Create("DLabel", optionPanel)
        optionLabel:SetText(option)
        optionLabel:SetFont("DermaDefault")
        optionLabel:SizeToContents()
        optionLabel:SetPos(5, 6)
        optionLabel:SetColor(Color(200, 200, 200))

        optionPanel.Paint = function(s, w, h)
            local bgColor = s:IsHovered() and Color(75, 75, 75) or Color(60, 60, 60)
            surface.SetDrawColor(bgColor)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(100, 100, 100)
            surface.DrawOutlinedRect(0, 0, w, h)
        end

        optionPanel.OnMousePressed = function(s)
            panel:SetSelected(i)
            isOpen = false
            for _, op in ipairs(optionPanels) do
                op:SetVisible(false)
            end
            EchoSound("button_click")
        end

        optionPanels[i] = optionPanel
    end

    panel.Think = function(s)
        for i, op in ipairs(optionPanels) do
            op:SetVisible(isOpen)
            if isOpen then
                local px, py = s:GetParent():GetPos()  -- filterPanel position
                op:SetPos(px + s:GetX(), py + s:GetY() + 25 + (i-1) * 25)
            end
        end
    end

    return y + 25, panel
end

function CreateSimpleCheckbox(parent, text, initialValue, y, onChange, x)
    x = x or 50
    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(parent:GetWide() - 100, 25)
    panel:SetPos(x, y)
    panel:SetMouseInputEnabled(true)

    local checked = initialValue or false

    local label = vgui.Create("DLabel", panel)
    label:SetText(text)
    label:SetFont("DermaDefault")
    label:SizeToContents()
    label:SetPos(30, 2)
    label:SetColor(Color(200, 200, 200))

    panel.GetChecked = function() return checked end
    panel.SetValue = function(self, val) checked = val; self:InvalidateLayout() end

    panel.Paint = function(s, w, h)
        DrawCheckboxBox(s, w, h, checked)
    end

    panel.OnMousePressed = function(s)
        checked = not checked
        if onChange then onChange(checked) end
        EchoSound("button_click")
        s:InvalidateLayout()
    end

    return y + panel:GetTall() + 5, panel
end


function CreateSlider(parent, text, convar, min, max, decimals, y, customNotches)
    local function CalculateNotchParams(range, decimals)
        local wishNotches = math.Clamp(math.floor(range / 10), 5, 10)
        if range > 100000 then
            wishNotches = wishNotches * 2
        end
        local step = math.max(10 ^ (-decimals), range / wishNotches)
        step = math.Round(step, decimals)
        return step, wishNotches
    end

    local panel = vgui.Create("DPanel", parent)
    panel:SetSize(parent:GetWide() - 100, 30)
    panel:SetPos(50, y)
    panel:SetMouseInputEnabled(true)

    local value = EchoesSettings[convar:GetName()] or min
    local isDragging = false
    local trackWidth = panel:GetWide() - 60

    local label = vgui.Create("DLabel", panel)
    label:SetText(text)
    label:SetFont("DermaDefault")
    label:SizeToContents()
    label:SetPos(0, 2)
    label:SetColor(Color(200, 200, 200))

    local valueLabel = vgui.Create("DLabel", panel)
    valueLabel:SetText(string.format("%." .. decimals .. "f", value))
    valueLabel:SetFont("DermaDefault")
    valueLabel:SizeToContents()
    valueLabel:SetPos(trackWidth + 10, 2)
    valueLabel:SetColor(Color(200, 200, 200))
    valueLabel:SetContentAlignment(5)
    valueLabel:SetWide(50)

    panel.Paint = function(s, w, h)
        --unfilled slider BG
        surface.SetDrawColor(50, 50, 50)
        surface.DrawRect(0, 15, trackWidth, 4)

        --filled slider BG
        local fillWidth = ((value - min) / (max - min)) * trackWidth
        surface.SetDrawColor(200, 200, 200)
        surface.DrawRect(0, 15, fillWidth, 4)

  		--border(lands)
  		surface.SetDrawColor(100, 100, 100)
  		surface.DrawOutlinedRect(0, 15, trackWidth, 4)

        --Notches (creator of the hit game minecraft)
    local range = max - min
        if customNotches then
            for _, notchVal in ipairs(customNotches) do
                if notchVal >= min and notchVal <= max then
                    local notchX = ((notchVal - min) / (max - min)) * trackWidth
                    surface.SetDrawColor(200, 200, 200)  --same as fill bar to blend
                    surface.DrawRect(notchX - 1, 15, 2, 6) --stick out the bottom a bit
                end
            end
        else
            local step, wishNotches = CalculateNotchParams(range, decimals)
            local numSteps = math.floor(range / step) + 1
            if numSteps <= 40 then
                for i = 0, numSteps - 1 do
                    local val = math.Clamp(math.Round(min + i * step, decimals), min, max)
                    local notchX = ((val - min) / (max - min)) * trackWidth
                    surface.SetDrawColor(200, 200, 200)  --same as fill bar to blend
                    surface.DrawRect(notchX - 1, 15, 2, 6) --stick out the bottom a bit
                end
            end
        end

        local arrowX = math.Clamp(fillWidth, 8, trackWidth - 8)
        local arrowColor = isDragging and Color(150, 150, 150) or (s:IsHovered() and Color(100, 100, 100) or Color(75, 75, 75))
        surface.SetDrawColor(arrowColor)
        surface.SetMaterial(arrow)
        surface.DrawTexturedRectRotated(arrowX, 25, 16, 16, 0)
    end

    local function SnapToNotch(val)
        if customNotches then
            local closest = min
            local minDiff = math.abs(val - closest)
            for _, notchVal in ipairs(customNotches) do
                if notchVal >= min and notchVal <= max then
                    local diff = math.abs(val - notchVal)
                    if diff < minDiff then
                        minDiff = diff
                        closest = notchVal
                    end
                end
            end
            return closest
        else
            local range = max - min
            local step = CalculateNotchParams(range, decimals)
            local snapped = math.Round(val / step) * step
            return math.Clamp(snapped, min, max)
        end
    end

    panel.OnMousePressed = function(s, mouseCode)
        if mouseCode == MOUSE_LEFT then
            isDragging = true
            panel:MouseCapture(true)
            local mouseX, _ = s:ScreenToLocal(gui.MouseX(), gui.MouseY())
            if mouseX >= 0 and mouseX <= trackWidth then
                local oldValue = value
                value = math.Clamp(min + ((mouseX / trackWidth) * (max - min)), min, max)
                if not input.IsKeyDown(KEY_LSHIFT) then
                    value = SnapToNotch(value)
                end
                if value ~= oldValue then
                    local percentage = (value - min) / (max - min)
                    local pitch = 80 + (percentage * 50)  --80% to 130%
                    EchoSound("slider_drag", pitch)
                end
                convar:SetFloat(value)
                valueLabel:SetText(string.format("%." .. decimals .. "f", value))
                s:InvalidateLayout()
            end
        end
    end

    panel.OnMouseReleased = function(s, mouseCode)
        if mouseCode == MOUSE_LEFT then
            isDragging = false
            panel:MouseCapture(false)
        end
    end

    panel.OnCursorMoved = function(s, x, y)
        if isDragging then
            local oldValue = value
            local newValue = math.Clamp(min + ((x / trackWidth) * (max - min)), min, max)
            if not input.IsKeyDown(KEY_LSHIFT) then
                newValue = SnapToNotch(newValue)
            end
            if newValue ~= value then
                value = newValue
                if newValue ~= oldValue then
                    local percentage = (newValue - min) / (max - min)
                    local pitch = 80 + (percentage * 50)  --80% to 130%
                    EchoSound("slider_drag", pitch)
                end
                convar:SetFloat(value)
                valueLabel:SetText(string.format("%." .. decimals .. "f", value))
                s:InvalidateLayout()
            end
        end
    end

    return y + panel:GetTall() + 5
end