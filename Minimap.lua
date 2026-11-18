local _, FSC = ...

function FSC:PositionMinimapButton()
    local button = self.minimapButton
    if not button then return end
    local angle = math.rad(self.storage.minimap.angle)
    local x, y = math.cos(angle), math.sin(angle)
    if GetMinimapShape and GetMinimapShape() == "SQUARE" then
        local longest = math.max(math.abs(x), math.abs(y))
        x, y = x / longest, y / longest
    end
    local radiusX = Minimap:GetWidth() / 2 + 8
    local radiusY = Minimap:GetHeight() / 2 + 8
    button:ClearAllPoints()
    button:SetPoint("CENTER", Minimap, "CENTER", x * radiusX, y * radiusY)
end

local function MoveWithCursor()
    local centerX, centerY = Minimap:GetCenter()
    if not centerX or not centerY then return end
    local cursorX, cursorY = GetCursorPosition()
    local scale = Minimap:GetEffectiveScale()
    local dx, dy = cursorX / scale - centerX, cursorY / scale - centerY
    if dx == 0 and dy == 0 then return end
    FSC.storage.minimap.angle = math.deg(math.atan2(dy, dx)) % 360
    FSC:PositionMinimapButton()
end

function FSC:CreateMinimapButton()
    if self.minimapButton or not Minimap then return end
    local button = CreateFrame("Button", "FreeSpellCooldownsMinimapButton", Minimap)
    self.minimapButton = button
    button:SetSize(31, 31)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
    button:EnableMouse(true)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:RegisterForDrag("LeftButton")
    button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetSize(20, 20)
    background:SetPoint("CENTER")
    background:SetColorTexture(0.025, 0.04, 0.045, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetSize(20, 20)
    button.icon:SetPoint("CENTER")
    button.icon:SetTexture("Interface\\Icons\\INV_Misc_PocketWatch_01")
    button.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetSize(53, 53)
    border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

    button:SetScript("OnMouseDown", function(self) self.dragged = false end)
    button:SetScript("OnClick", function(self, mouseButton)
        if self.dragged then return end
        if mouseButton == "RightButton" then
            FSC:ToggleCurrentLock()
        elseif mouseButton == "LeftButton" then
            if FSC.buffOptions and FSC.buffOptions:IsShown() then FSC.buffOptions:Hide()
            elseif FSC.window:IsShown() then FSC.window:Hide()
            else FSC:OpenOptions() end
        end
    end)
    button:SetScript("OnDragStart", function(self)
        if not FSC:CanEdit() then return end
        self.dragged = true
        self.dragging = true
        FSC:HideTooltip()
        self:SetScript("OnUpdate", MoveWithCursor)
        MoveWithCursor()
    end)
    button:SetScript("OnDragStop", function(self)
        self:SetScript("OnUpdate", nil)
        if self.dragging then MoveWithCursor() end
        self.dragging = false
    end)
    button:SetScript("OnHide", function(self)
        self:SetScript("OnUpdate", nil)
        self.dragging = false
    end)
    button:SetScript("OnEnter", function(self)
        if self.dragging then return end
        local tooltip = FSC:GetTooltip()
        tooltip:SetOwner(self, "ANCHOR_LEFT")
        tooltip:SetText("Free Spell Cooldowns", 0.4, 0.9, 0.85)
        tooltip:AddLine("Levý klik: otevřít / zavřít nastavení", 1, 1, 1)
        tooltip:AddLine("Pravý klik: zamknout / odemknout aktuální sekci", 1, 1, 1)
        tooltip:AddLine("Přetažení: posunout tlačítko kolem minimapy", 1, 1, 1)
        FSC:StyleTooltip()
        tooltip:Show()
    end)
    button:SetScript("OnLeave", function() FSC:HideTooltip() end)
    self:PositionMinimapButton()
end
