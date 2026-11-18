local _, FSC = ...
local rows = {}

local function Label(parent, text, x, y, font)
    local label = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    FSC:SetCzechFont(label)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    label:SetJustifyH("LEFT")
    return label
end

local function Button(parent, text, x, y, width, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 25)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    FSC:SetButtonFont(button)
    button:SetScript("OnClick", callback)
    return button
end

-- Draw +/- directly so these controls never depend on legacy button artwork.
local function StepButton(parent, x, y, positive, callback)
    local button = CreateFrame("Button", nil, parent, "BackdropTemplate")
    button:SetSize(24, 24)
    button:SetPoint("TOPLEFT", x, y)
    button:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    button:SetBackdropColor(0.07, 0.13, 0.16, 1)
    button:SetBackdropBorderColor(0.25, 0.6, 0.6, 1)
    local horizontal = button:CreateTexture(nil, "OVERLAY")
    horizontal:SetSize(10, 2)
    horizontal:SetPoint("CENTER")
    horizontal:SetColorTexture(0.9, 1, 1, 1)
    local vertical
    if positive then
        vertical = button:CreateTexture(nil, "OVERLAY")
        vertical:SetSize(2, 10)
        vertical:SetPoint("CENTER")
        vertical:SetColorTexture(0.9, 1, 1, 1)
    end
    local highlight = button:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetColorTexture(0.2, 0.6, 0.6, 0.25)
    local function Paint(enabled)
        local color = enabled and 1 or 0.35
        horizontal:SetVertexColor(color, color, color)
        if vertical then vertical:SetVertexColor(color, color, color) end
    end
    button:SetScript("OnEnable", function() Paint(true) end)
    button:SetScript("OnDisable", function() Paint(false) end)
    button:SetScript("OnClick", callback)
    return button
end

local function EditBox(parent, x, y, width)
    local edit = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    edit:SetSize(width, 28)
    edit:SetPoint("TOPLEFT", x, y)
    edit:SetAutoFocus(false)
    FSC:SetCzechFont(edit)
    edit:SetMaxLetters(180)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if edit:HasScript("OnEnable") then edit:SetScript("OnEnable", function(self) self:SetAlpha(1) end) end
    if edit:HasScript("OnDisable") then edit:SetScript("OnDisable", function(self) self:SetAlpha(0.45) end) end
    return edit
end

local function CheckBox(parent, text, x, y, callback, template)
    local check = CreateFrame("CheckButton", nil, parent, template or "UICheckButtonTemplate")
    check:SetSize(26, 26)
    check:SetPoint("TOPLEFT", x, y)
    local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    FSC:SetCzechFont(label)
    check.label = label
    label:SetPoint("LEFT", check, "RIGHT", 1, 0)
    label:SetText(text)
    check:SetScript("OnClick", callback)
    check:SetScript("OnEnable", function() label:SetAlpha(1) end)
    check:SetScript("OnDisable", function() label:SetAlpha(0.45) end)
    return check
end

local function RadioButton(parent, text, x, y, callback)
    return CheckBox(parent, text, x, y, callback, "UIRadioButtonTemplate")
end

local function PercentSlider(parent, x, y, width)
    local slider = CreateFrame("Slider", nil, parent, "BackdropTemplate")
    slider:SetSize(width, 18)
    slider:SetPoint("TOPLEFT", x, y)
    slider:SetOrientation("HORIZONTAL")
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(1)
    if slider.SetObeyStepOnDrag then slider:SetObeyStepOnDrag(true) end
    slider:EnableMouse(true)
    slider:EnableMouseWheel(true)
    local track = slider:CreateTexture(nil, "BACKGROUND")
    track:SetPoint("LEFT", 0, 0)
    track:SetPoint("RIGHT", 0, 0)
    track:SetHeight(4)
    track:SetColorTexture(0.2, 0.35, 0.38, 1)
    local thumb = slider:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(10, 18)
    thumb:SetColorTexture(0.4, 0.85, 0.8, 1)
    slider:SetThumbTexture(thumb)
    if slider:HasScript("OnEnable") then slider:SetScript("OnEnable", function(self) self:SetAlpha(1) end) end
    if slider:HasScript("OnDisable") then slider:SetScript("OnDisable", function(self) self:SetAlpha(0.35) end) end
    return slider
end

local function NumericBox(parent, x, y, width, apply)
    local edit = EditBox(parent, x, y, width)
    edit:SetMaxLetters(9)
    edit:SetScript("OnEditFocusGained", function(self)
        self.editingUID, self.editingProfile = FSC.selectedUID, FSC.activeProfileKey
    end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function(self)
        self.cancelled = true
        self:ClearFocus()
    end)
    edit:SetScript("OnEditFocusLost", function(self)
        local entry = FSC:FindEntry(self.editingUID)
        local cancelled = self.cancelled
        self.cancelled = nil
        if not cancelled and entry and self.editingProfile == FSC.activeProfileKey and FSC:CanEdit() then
            local value = tonumber(self:GetText())
            if value and value == value and value > -math.huge and value < math.huge then
                apply(entry, value)
                FSC:ApplyIcon(entry)
            else
                FSC:Status("Zadej platné číslo a potvrď Enterem.", true)
            end
        end
        FSC:RefreshOptions()
    end)
    return edit
end

function FSC:ClearInputFocus()
    if not self.window then return end
    for _, edit in ipairs({ self.window.input, self.window.xInput,
        self.window.yInput }) do edit:ClearFocus() end
end

local function SyncNumber(edit, value)
    if not edit:HasFocus() then edit:SetText(value or "") end
end

local function AdjustSize(amount)
    if not FSC:CanEdit() then return end
    FSC:ClearInputFocus()
    local entry = FSC:FindEntry(FSC.selectedUID)
    if entry then FSC:ResizeIcon(entry, entry.size + amount) end
end

local function AdjustPosition(axis, amount)
    if not FSC:CanEdit() then return end
    FSC:ClearInputFocus()
    local entry = FSC:FindEntry(FSC.selectedUID)
    if not entry then return end
    entry[axis] = math.floor(entry[axis] + 0.5) + amount
    FSC:ApplyIcon(entry)
    FSC:RefreshOptions()
end

function FSC:OpenOptions(uid)
    if not self:CanEdit() then return end
    if uid then self.selectedUID = uid end
    self.window:Show()
    self.window:Raise()
    self:RefreshOptions()
end

function FSC:RefreshOptions()
    local window = self.window
    if not window then return end
    window.profileStatus:SetText("Aktivní: " .. self:GetSpecLabel() .. "  |  Vzhled a poloha níže platí pro tento spec.")
    window.lockButton:SetText(self.db.locked and "Odemknout ikony" or "Zamknout ikony")
    window.listTitle:SetText("Kouzla (" .. #self.db.icons .. ") - společný seznam pro oba specy")
    if not self.selectedUID or not self:FindEntry(self.selectedUID) then
        self.selectedUID = self.db.icons[1] and self.db.icons[1].uid
    end
    window.empty:SetShown(#self.db.icons == 0)
    window.content:SetHeight(math.max(1, #self.db.icons * 38))
    for index, entry in ipairs(self.db.icons) do
        local row = rows[index]
        if not row then
            row = CreateFrame("Button", nil, window.content)
            rows[index] = row
            row:SetSize(270, 36)
            row:SetPoint("TOPLEFT", 0, -(index - 1) * 38)
            row.background = row:CreateTexture(nil, "BACKGROUND")
            row.background:SetAllPoints()
            row.icon = row:CreateTexture(nil, "ARTWORK")
            row.icon:SetSize(28, 28)
            row.icon:SetPoint("LEFT", 5, 0)
            row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            FSC:SetCzechFont(row.name)
            row.name:SetPoint("LEFT", 42, 0)
            row.name:SetWidth(184)
            row.name:SetJustifyH("LEFT")
            row.remove = Button(row, "×", 238, -5, 28, function()
                FSC:RemoveSpell(row.uid)
            end)
            row:SetScript("OnClick", function()
                FSC.selectedUID = row.uid
                FSC:RefreshOptions()
            end)
        end
        row.uid = entry.uid
        row.icon:SetTexture(entry.iconID or 134400)
        row.name:SetText(entry.name .. "  |cff999999" .. entry.size .. " px · " .. self:GetSpecSummary(entry) .. "|r")
        row.icon:SetDesaturated(not self:IsEntryAssigned(entry))
        row.name:SetAlpha(self:IsEntryAssigned(entry) and 1 or 0.6)
        local selected = entry.uid == self.selectedUID
        row.background:SetColorTexture(selected and 0.10 or 0.06,
            selected and 0.28 or 0.07, selected and 0.29 or 0.09, 0.95)
        row:Show()
    end
    for index = #self.db.icons + 1, #rows do rows[index]:Hide() end
    local entry = self.selectedUID and self:FindEntry(self.selectedUID)
    window.selected:SetText(entry and ("Vybraná ikona: " .. entry.name) or "Nejdřív přidej kouzlo")
    window.sizeValue:SetText(entry and (entry.size .. " px") or "—")
    window.numbers:SetChecked(entry and entry.showNumbers or false)
    window.spellName:SetChecked(entry and entry.showName or false)
    window.combatOnly:SetChecked(entry and entry.combatOnly or false)
    window.flashReady:SetChecked(entry and entry.flashReady or false)
    window.manaTint:SetChecked(entry and entry.manaTint or false)
    local intensity = entry and self:GetFlashIntensity(entry) or 80
    window.flashIntensitySlider.syncing = true
    window.flashIntensitySlider:SetValue(intensity)
    window.flashIntensitySlider.syncing = false
    window.flashIntensityValue:SetText(entry and (intensity .. " %") or "-")
    window.spec1:SetChecked(entry and self:IsEntryAssigned(entry, 1) or false)
    window.spec2:SetChecked(entry and self:IsEntryAssigned(entry, 2) or false)
    window.spec1.label:SetText("Spec 1" .. (self.activeSpec == 1 and " (aktivní)" or ""))
    window.spec2.label:SetText("Spec 2" .. (self.activeSpec == 2 and " (aktivní)" or ""))
    local transparency = entry and math.floor((1 - entry.opacity) * 100 + 0.5) or 0
    window.opacitySlider.syncing = true
    window.opacitySlider:SetValue(transparency)
    window.opacitySlider.syncing = false
    window.opacityValue:SetText(entry and (transparency .. " %") or "-")
    SyncNumber(window.xInput, entry and math.floor(entry.x + 0.5))
    SyncNumber(window.yInput, entry and math.floor(entry.y + 0.5))
    for _, control in ipairs(window.entryControls) do control:SetEnabled(entry ~= nil) end
end

function FSC:CreateOptions()
    local window = CreateFrame("Frame", "FreeSpellCooldownsOptions", UIParent, "BackdropTemplate")
    self.window = window
    window:Hide()
    window:SetSize(560, 908)
    window:SetPoint("CENTER", UIParent, "CENTER", 235, 20)
    window:SetFrameStrata("DIALOG")
    window:SetClampedToScreen(true)
    window:SetMovable(true)
    window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", function(self) self:StartMoving() end)
    window:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    window:SetScript("OnHide", function() FSC:ClearInputFocus() end)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    window:SetBackdropColor(0.035, 0.045, 0.065, 0.98)
    window:SetBackdropBorderColor(0.2, 0.6, 0.6, 1)
    table.insert(UISpecialFrames, "FreeSpellCooldownsOptions")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3)
    Label(window, "Free Spell Cooldowns", 20, -19, "GameFontNormalLarge")
    self:AttachCategoryTabs(window, "cooldowns")
    Label(window, "Každé kouzlo má vlastní ikonu, velikost a místo na obrazovce.", 20, -48, "GameFontHighlightSmall")
    window.profileStatus = Label(window, "", 20, -70, "GameFontNormalSmall")
    window.profileStatus:SetWidth(510)

    local drop = CreateFrame("Button", nil, window, "BackdropTemplate")
    window.drop = drop
    drop:SetPoint("TOPLEFT", 20, -100)
    drop:SetSize(520, 65)
    drop:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    drop:SetBackdropColor(0.05, 0.14, 0.16, 1)
    drop:SetBackdropBorderColor(0.2, 0.6, 0.6, 1)
    local dropLabel = drop:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    window.dropLabel = dropLabel
    self:SetCzechFont(dropLabel)
    dropLabel:SetPoint("CENTER", 0, 8)
    dropLabel:SetText("PŘETÁHNI SEM KOUZLO ZE SPELLBOOKU")
    local dropHint = drop:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    window.dropHint = dropHint
    self:SetCzechFont(dropHint)
    dropHint:SetPoint("CENTER", 0, -13)
    dropHint:SetText("Spellbook otevřeš klávesou P. Přidávej přímo kouzla.")
    drop:SetScript("OnReceiveDrag", function() FSC:AddFromCursor() end)
    drop:SetScript("OnClick", function() FSC:AddFromCursor() end)

    window.inputLabel = Label(window, "Nebo napiš název kouzla ze hry / spell ID:", 20, -179, "GameFontHighlightSmall")
    window.input = EditBox(window, 25, -199, 385)
    local function Submit()
        if FSC:AddSpell(window.input:GetText()) then
            window.input:SetText("")
            window.input:ClearFocus()
        end
    end
    window.input:SetScript("OnEnterPressed", Submit)
    window.addButton = Button(window, "Přidat", 425, -200, 110, Submit)
    window.status = Label(window, "Začni přidáním kouzla. Potom odemkni ikony a rozmísti je.", 20, -238, "GameFontHighlightSmall")
    window.status:SetWidth(515)
    window.status:SetHeight(28)
    window.status:SetJustifyV("TOP")
    window.listTitle = Label(window, "", 20, -278, "GameFontNormalSmall")

    local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    window.scroll = scroll
    scroll:SetPoint("TOPLEFT", 20, -303)
    scroll:SetSize(490, 155)
    window.content = CreateFrame("Frame", nil, scroll)
    window.content:SetSize(490, 1)
    scroll:SetScrollChild(window.content)
    window.empty = Label(window.content, "Zatím nesleduješ žádná kouzla.", 8, -12, "GameFontDisable")

    window.selected = Label(window, "", 20, -478, "GameFontNormal")
    window.selected:SetWidth(510)
    window.specLabel = Label(window, "Zobrazovat ve:", 20, -515, "GameFontHighlightSmall")
    local function ToggleSpec(slot, check)
        local entry = FSC:FindEntry(FSC.selectedUID)
        if not FSC:SetEntrySpec(entry, slot, check:GetChecked() == true) then FSC:RefreshOptions() end
    end
    window.spec1 = CheckBox(window, "Spec 1", 173, -503, function(check) ToggleSpec(1, check) end)
    window.spec2 = CheckBox(window, "Spec 2", 340, -503, function(check) ToggleSpec(2, check) end)
    window.sizeLabel = Label(window, "Velikost:", 20, -557, "GameFontHighlightSmall")
    local minus = StepButton(window, 85, -549, false, function() AdjustSize(-1) end)
    window.sizeValue = Label(window, "", 127, -557, "GameFontHighlightSmall")
    local plus = StepButton(window, 185, -549, true, function() AdjustSize(1) end)
    window.sizeLess, window.sizeMore = minus, plus
    window.numbers = CheckBox(window, "Číselný odpočet", 270, -545, function(self)
        if not FSC:CanEdit() then return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.showNumbers = self:GetChecked() == true; FSC:ApplyIcon(entry) end
    end)
    window.spellName = CheckBox(window, "Název pod ikonou", 270, -580, function(self)
        if not FSC:CanEdit() then return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.showName = self:GetChecked() == true; FSC:ApplyIcon(entry) end
    end)
    window.combatOnly = CheckBox(window, "Pouze v boji", 270, -615, function(self)
        if not FSC:CanEdit() then return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.combatOnly = self:GetChecked() == true; FSC:ApplyIcon(entry) end
    end)
    window.opacityLabel = Label(window, "Průhlednost:", 20, -594, "GameFontHighlightSmall")
    local opacity = PercentSlider(window, 103, -590, 104)
    window.opacitySlider = opacity
    window.opacityValue = Label(window, "", 215, -594, "GameFontHighlightSmall")
    window.opacityValue:SetWidth(45)
    opacity:SetScript("OnMouseDown", function(self)
        FSC:ClearInputFocus()
        self.dragUID, self.dragProfile = FSC.selectedUID, FSC.activeProfileKey
    end)
    local function EndOpacityDrag(self)
        self.dragUID, self.dragProfile = nil, nil
    end
    opacity:SetScript("OnMouseUp", EndOpacityDrag)
    opacity:SetScript("OnHide", EndOpacityDrag)
    opacity:SetScript("OnValueChanged", function(self, value)
        if self.syncing then return end
        if not FSC:CanEdit() or (self.dragUID and (self.dragUID ~= FSC.selectedUID
            or self.dragProfile ~= FSC.activeProfileKey)) then
            FSC:RefreshOptions()
            return
        end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if not entry then return end
        local percent = FSC:Clamp(math.floor(value + 0.5), 0, 100)
        entry.opacity = 1 - percent / 100
        window.opacityValue:SetText(percent .. " %")
        FSC:ApplyIcon(entry)
    end)
    opacity:SetScript("OnMouseWheel", function(self, delta)
        if self:IsEnabled() then self:SetValue(FSC:Clamp(self:GetValue() + delta, 0, 100)) end
    end)
    window.xLabel = Label(window, "X:", 20, -659, "GameFontHighlightSmall")
    local xMinus = StepButton(window, 43, -651, false, function() AdjustPosition("x", -1) end)
    window.xInput = NumericBox(window, 77, -649, 70, function(entry, value)
        entry.x = math.floor(value + 0.5)
    end)
    local xPlus = StepButton(window, 153, -651, true, function() AdjustPosition("x", 1) end)
    window.yLabel = Label(window, "Y:", 285, -659, "GameFontHighlightSmall")
    local yMinus = StepButton(window, 308, -651, false, function() AdjustPosition("y", -1) end)
    window.yInput = NumericBox(window, 342, -649, 70, function(entry, value)
        entry.y = math.floor(value + 0.5)
    end)
    local yPlus = StepButton(window, 418, -651, true, function() AdjustPosition("y", 1) end)
    window.xLess, window.xMore, window.yLess, window.yMore = xMinus, xPlus, yMinus, yPlus
    window.flashReady = CheckBox(window, "Probliknout po CD (jen v boji)", 20, -684, function(check)
        if not FSC:CanEdit() then FSC:RefreshOptions(); return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.flashReady = check:GetChecked() == true; FSC:ApplyIcon(entry) end
    end)
    window.flashTest = Button(window, "Vyzkoušet probliknutí", 380, -721, 155, function()
        if not FSC:CanEdit() then return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then FSC:PlayReadyFlash(entry, true) end
    end)
    window.manaTint = CheckBox(window, "Modře při nedostatku many", 270, -684, function(check)
        if not FSC:CanEdit() then FSC:RefreshOptions(); return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.manaTint = check:GetChecked() == true; FSC:ApplyIcon(entry) end
    end)
    window.flashIntensityLabel = Label(window, "Intenzita záblesku:", 20, -729, "GameFontHighlightSmall")
    local intensity = PercentSlider(window, 150, -725, 155)
    window.flashIntensitySlider = intensity
    window.flashIntensityValue = Label(window, "", 313, -729, "GameFontHighlightSmall")
    window.flashIntensityValue:SetWidth(55)
    intensity:SetScript("OnMouseDown", function(self)
        FSC:ClearInputFocus()
        self.dragUID, self.dragProfile = FSC.selectedUID, FSC.activeProfileKey
    end)
    local function EndIntensityDrag(self)
        self.dragUID, self.dragProfile = nil, nil
    end
    intensity:SetScript("OnMouseUp", EndIntensityDrag)
    intensity:SetScript("OnHide", EndIntensityDrag)
    intensity:SetScript("OnValueChanged", function(self, value)
        if self.syncing then return end
        if not FSC:CanEdit() or (self.dragUID and (self.dragUID ~= FSC.selectedUID
            or self.dragProfile ~= FSC.activeProfileKey)) then
            FSC:RefreshOptions()
            return
        end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if not entry then return end
        entry.flashIntensity = FSC:Clamp(math.floor(value + 0.5), 0, 100)
        window.flashIntensityValue:SetText(entry.flashIntensity .. " %")
        FSC:ApplyIcon(entry)
    end)
    intensity:SetScript("OnMouseWheel", function(self, delta)
        if self:IsEnabled() then self:SetValue(FSC:Clamp(self:GetValue() + delta, 0, 100)) end
    end)
    window.opacityHint = Label(window, "Průhlednost: 0 % = plná ikona, 100 % = neviditelná.", 20, -773, "GameFontHighlightSmall")
    window.coordinatesHint = Label(window, "X/Y: pixely od středu. Tlačítka - / + mění polohu po 1 px.", 20, -791, "GameFontHighlightSmall")
    local center = Button(window, "Přesunout na střed", 20, -816, 195, function()
        if not FSC:CanEdit() then return end
        local entry = FSC:FindEntry(FSC.selectedUID)
        if entry then entry.x = 0; entry.y = 0; FSC:ApplyIcon(entry); FSC:RefreshOptions() end
    end)
    window.centerButton = center
    window.entryControls = { minus, plus, center, window.numbers, window.spellName,
        window.combatOnly, window.opacitySlider, window.xInput, window.yInput,
        xMinus, xPlus, yMinus, yPlus, window.spec1, window.spec2, window.flashReady, window.flashTest,
        window.manaTint, window.flashIntensitySlider }
    window.lockButton = Button(window, "", 20, -867, 195, function()
        FSC:SetLocked(not FSC.db.locked)
    end)
    local hint = Label(window, "Přetažení: poloha · Shift + kolečko: velikost\nPravé tlačítko na odemčené ikoně: nastavení", 235, -863, "GameFontHighlightSmall")
    window.moveHint = hint
    hint:SetWidth(305)
    hint:SetHeight(34)
    hint:SetJustifyV("TOP")
end

FSC.UI = { Label = Label, Button = Button, StepButton = StepButton, EditBox = EditBox,
    CheckBox = CheckBox, RadioButton = RadioButton, PercentSlider = PercentSlider }
