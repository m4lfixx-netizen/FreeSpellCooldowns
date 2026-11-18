local _, FSC = ...
local UI, rows = FSC.UI, {}

local function AtSamePosition(target, source)
    local x, y = source:GetLeft(), source:GetTop()
    target:ClearAllPoints()
    if x and y then
        local ratio = source:GetEffectiveScale() / target:GetEffectiveScale()
        target:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x * ratio, y * ratio)
    else target:SetPoint("CENTER", UIParent, "CENTER", 235, 20) end
end

local function Selected()
    local entry = FSC:FindBuff(FSC.selectedBuffUID)
    return entry, entry and FSC:BuffLayout(entry)
end

local function NumericBox(parent, x, y, width, apply)
    local edit = UI.EditBox(parent, x, y, width)
    edit:SetMaxLetters(9)
    edit:SetScript("OnEditFocusGained", function(self)
        self.buffUID, self.spec = FSC.selectedBuffUID, FSC.activeSpec
    end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function(self) self.cancelled = true; self:ClearFocus() end)
    edit:SetScript("OnEditFocusLost", function(self)
        local entry = FSC:FindBuff(self.buffUID)
        local value = tonumber(self:GetText())
        if not self.cancelled and entry and self.spec == FSC.activeSpec and FSC:CanEdit() then
            if value and value == value and value > -math.huge and value < math.huge then
                apply(entry, FSC:BuffLayout(entry), value)
                FSC:ApplyBuff(entry)
            else FSC:Status("Zadej platné číslo.", true) end
        end
        self.cancelled = nil
        FSC:RefreshBuffOptions()
    end)
    return edit
end

local function StyleCard(parent, x, style, title, callback)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", x, -438); card:SetSize(165, 86)
    card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    card:SetBackdropColor(0.06, 0.10, 0.14, 1)
    card:SetScript("OnClick", callback)
    card.style = style
    local anchor = CreateFrame("Frame", nil, card)
    anchor:SetSize(52, 52); anchor:SetPoint("TOP", card, "TOP", 0, -3)
    card.anchor, card.art = anchor, {}
    if style == "icon" then
        card.icon = anchor:CreateTexture(nil, "ARTWORK"); card.icon:SetSize(34, 34)
        card.icon:SetPoint("CENTER", anchor, "CENTER"); card.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    else
        for _, side in ipairs(style == "lightning" and {-1, 1} or {0}) do
            local texture = anchor:CreateTexture(nil, "ARTWORK")
            texture:SetTexture(FSC.buffLightningTexture)
            if style == "lightning" then
                texture:SetSize(20, 40); texture:SetPoint("CENTER", anchor, "CENTER", side * 26, 0)
            else texture:SetSize(52, 26); texture:SetPoint("CENTER", anchor, "CENTER", 0, 2) end
            FSC:BuffTextureCoords(texture, style, side)
            table.insert(card.art, texture)
        end
    end
    card.count = anchor:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    FSC:SetCzechFont(card.count, 11)
    if card.icon then card.count:SetPoint("BOTTOMRIGHT", card.icon, "BOTTOMRIGHT", 0, 0)
    else card.count:SetPoint("BOTTOM", anchor, "BOTTOM", 0, -2) end
    local label = UI.Label(card, title, 0, 0, "GameFontHighlightSmall")
    label:ClearAllPoints(); label:SetPoint("BOTTOM", card, "BOTTOM", 0, 7)
    return card
end

local function ThemeCard(parent, x, themeKey, callback)
    local card = CreateFrame("Button", nil, parent, "BackdropTemplate")
    card:SetPoint("TOPLEFT", x, -558); card:SetSize(122, 64)
    card:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    card:SetScript("OnClick", callback)
    card.theme, card.art = themeKey, {}
    card.anchor = CreateFrame("Frame", nil, card)
    card.anchor:SetSize(52, 38); card.anchor:SetPoint("TOP", card, "TOP", 0, -2)
    for index = 1, 2 do table.insert(card.art, card.anchor:CreateTexture(nil, "ARTWORK")) end
    local label = UI.Label(card, FSC.buffThemes[themeKey].name, 0, 0, "GameFontHighlightSmall")
    label:ClearAllPoints(); label:SetPoint("BOTTOM", card, "BOTTOM", 0, 6)
    return card
end

local function PaintCard(card, style, themeKey, small)
    for index, texture in ipairs(card.art) do
        local side = index == 1 and -1 or 1
        texture:SetTexture(FSC:GetBuffThemeTexture(themeKey, style))
        texture:ClearAllPoints()
        if style == "top" then texture:SetSize(48, 24); texture:SetPoint("CENTER", card.anchor, "CENTER", 0, 0)
        else
            texture:SetSize(small and 16 or 20, small and 32 or 40)
            texture:SetPoint("CENTER", card.anchor, "CENTER", side * (small and 23 or 26), 0)
        end
        FSC:BuffTextureCoords(texture, style, side, themeKey)
        texture:SetShown(style == "lightning" or index == 1)
    end
end

function FSC:ClearBuffFocus()
    local window = self.buffOptions
    if not window then return end
    for _, edit in ipairs(window.edits) do edit:ClearFocus() end
end

function FSC:AttachCategoryTabs(window, active)
    local cooldowns = UI.Button(window, "Cooldowny", 650, -17, 145, function() FSC:OpenCooldownOptions() end)
    local buffs = UI.Button(window, "Buffy / procy", 805, -17, 190, function() FSC:OpenBuffOptions() end)
    window.categoryTabs = {cooldowns = cooldowns, buffs = buffs}
    cooldowns:SetEnabled(active ~= "cooldowns")
    buffs:SetEnabled(active ~= "buffs")
end

function FSC:RefreshBuffOptions()
    local window = self.buffOptions
    if not window or not self.storage then return end
    window.profile:SetText("Aktivní " .. self:GetSpecLabel() .. " — vzhled se ukládá pro každý spec zvlášť")
    window.lock:SetText(self:IsBuffLocked() and "Odemknout náhled buffu" or "Zamknout náhled buffu")
    if not self.selectedBuffUID or not self:FindBuff(self.selectedBuffUID) then
        self.selectedBuffUID = self.storage.buffs[1] and self.storage.buffs[1].uid
    end
    window.listTitle:SetText("Sledované buffy (" .. #self.storage.buffs .. ")")
    window.empty:SetShown(#self.storage.buffs == 0)
    window.content:SetHeight(math.max(1, #self.storage.buffs * 38))
    for index, entry in ipairs(self.storage.buffs) do
        local row = rows[index]
        if not row then
            row = CreateFrame("Button", nil, window.content)
            rows[index] = row
            row:SetSize(270, 36); row:SetPoint("TOPLEFT", 0, -(index - 1) * 38)
            row.background = row:CreateTexture(nil, "BACKGROUND"); row.background:SetAllPoints()
            row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(28, 28); row.icon:SetPoint("LEFT", 5, 0)
            row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
            FSC:SetCzechFont(row.name); row.name:SetPoint("LEFT", 42, 0); row.name:SetWidth(184); row.name:SetJustifyH("LEFT")
            row.remove = UI.Button(row, "×", 238, -5, 28, function() FSC:RemoveBuff(row.uid) end)
            row:SetScript("OnClick", function()
                FSC:ClearBuffFocus(); FSC:StartBuffPreview(FSC:FindBuff(row.uid))
            end)
        end
        row.uid = entry.uid; row.icon:SetTexture(entry.iconID)
        local layout = self:BuffLayout(entry)
        row.name:SetText(entry.name .. "  |cff999999" .. self:GetSpecSummary(entry)
            .. (layout.minStacks > 1 and (", od " .. layout.minStacks .. " stacků") or "") .. "|r")
        local active = entry.uid == self.selectedBuffUID
        row.background:SetColorTexture(active and 0.10 or 0.06, active and 0.28 or 0.07, active and 0.29 or 0.09, 0.95)
        row:SetAlpha(self:IsEntryAssigned(entry) and 1 or 0.5); row:Show()
    end
    for index = #self.storage.buffs + 1, #rows do rows[index]:Hide() end
    local entry, layout = Selected()
    window.selected:SetText(entry and ("Vybraný buff: " .. entry.name) or "Nejdřív přidej buff")
    for _, control in ipairs(window.controls) do control:SetEnabled(entry ~= nil) end
    window.spec1:SetChecked(entry and entry.specs[1] or false)
    window.spec2:SetChecked(entry and entry.specs[2] or false)
    window.spec1.label:SetText("Spec 1" .. (self.activeSpec == 1 and " (aktivní)" or ""))
    window.spec2.label:SetText("Spec 2" .. (self.activeSpec == 2 and " (aktivní)" or ""))
    window.stacks:SetChecked(layout and layout.showStacks or false)
    window.duration:SetChecked(layout and layout.showDuration or false)
    window.duration:SetEnabled(entry ~= nil and layout.minStacks == 1 and layout.style == "icon")
    for _, card in ipairs(window.styleCards) do
        local selected = layout and layout.style == card.style
        card:SetEnabled(entry ~= nil)
        card:SetBackdropBorderColor(selected and 0.3 or 0.16, selected and 0.95 or 0.3, selected and 0.9 or 0.35, 1)
        card:SetBackdropColor(selected and 0.08 or 0.04, selected and 0.23 or 0.07, selected and 0.25 or 0.10, 1)
        if card.icon then card.icon:SetTexture(entry and entry.iconID or 134400) end
        if not card.icon then PaintCard(card, card.style, layout and layout.theme or "lightning", false) end
        card.count:SetText(layout and layout.showStacks and tostring(layout.maxStacks) or "")
    end
    for _, card in ipairs(window.themeCards) do
        local selected = layout and layout.theme == card.theme
        local enabled = entry ~= nil and layout.style ~= "icon"
        card:SetEnabled(enabled); card:SetAlpha(enabled and 1 or 0.4)
        card:SetBackdropBorderColor(selected and 0.3 or 0.16, selected and 0.95 or 0.3, selected and 0.9 or 0.35, 1)
        card:SetBackdropColor(selected and 0.08 or 0.04, selected and 0.23 or 0.07, selected and 0.25 or 0.1, 1)
        PaintCard(card, layout and layout.style == "top" and "top" or "lightning", card.theme, true)
    end
    local mode = self:GetBuffStackMode(layout)
    window.fullMotif:SetChecked(entry ~= nil and mode == "full")
    window.progressive:SetChecked(entry ~= nil and mode == "opacity")
    window.progressive:SetEnabled(entry ~= nil and self.buffThresholdSupported)
    window.revealParts:SetChecked(entry ~= nil and mode == "parts")
    window.revealParts:SetEnabled(entry ~= nil and layout.style ~= "icon" and layout.maxStacks >= 2 and self.buffPartsSupported)
    window.glow:SetChecked(layout and layout.glowAtMax or false)
    window.glow:SetEnabled(entry ~= nil and (self.buffThresholdSupported or layout.glowAtMax))
    window.flashMax:SetChecked(layout and layout.flashAtMax or false)
    window.pulseMax:SetChecked(layout and layout.pulseAtMax or false)
    local alerts = entry ~= nil and self.buffThresholdSupported
    window.flashMax:SetEnabled(alerts or (entry ~= nil and layout.flashAtMax))
    window.pulseMax:SetEnabled(alerts or (entry ~= nil and layout.pulseAtMax))
    local alertEnabled = alerts and (layout.flashAtMax or layout.pulseAtMax)
    window.alertIntensity:SetEnabled(alertEnabled); window.alertPreview:SetEnabled(entry ~= nil)
    window.alertValue:SetAlpha(alertEnabled and 1 or 0.45)
    window.combatOnly:SetChecked(layout and layout.combatOnly or false)
    window.size:SetText(layout and (layout.size .. " px") or "—")
    local function Sync(edit, value) if not edit:HasFocus() then edit:SetText(value or "") end end
    Sync(window.minimum, layout and layout.minStacks)
    Sync(window.maximum, layout and layout.maxStacks)
    Sync(window.x, layout and math.floor(layout.x + 0.5))
    Sync(window.y, layout and math.floor(layout.y + 0.5))
    window.syncing = true
    window.opacity:SetValue(layout and math.floor((1 - layout.opacity) * 100 + 0.5) or 0)
    window.opacityValue:SetText(layout and (math.floor((1 - layout.opacity) * 100 + 0.5) .. " %") or "—")
    window.alertIntensity:SetValue(layout and layout.alertIntensity or 80)
    window.alertValue:SetText(layout and (layout.alertIntensity .. " %") or "—")
    window.syncing = false
    window.previewCount:SetText(layout and tostring(self:Clamp(self.buffPreviewStacks or layout.maxStacks, 1, layout.maxStacks)) or "-")
    window.previewLess:SetEnabled(entry ~= nil and self:IsBuffPreview())
    window.previewMore:SetEnabled(entry ~= nil and self:IsBuffPreview())
    local error = entry and self.buffFrames[entry.uid] and self.buffFrames[entry.uid].nativeError
    window.ruleHint:SetText(not self.buffAuraSupported and "Tento klient nepodporuje nativní sledování buffů."
        or error or (alertEnabled and "Blikání = krátké záblesky; pulzování = plynulá záře. Obojí běží jen při maximu, i současně."
        or (mode == "parts" and "Po částech: přibývá pět částí motivu, při maximu je celý. Vyzkoušej náhled stacků."
        or (not self.buffThresholdSupported and "Práh stacků tento klient nepodporuje. Běžné zobrazení: od 1."
        or "Zesilování: slabý efekt při nízkých stackách, plný při maximu. Odpočet: pouze ikona od 1 stacku."))))
end

function FSC:CreateBuffOptions()
    local window = CreateFrame("Frame", "FreeSpellCooldownsBuffOptions", UIParent, "BackdropTemplate")
    self.buffOptions = window
    window:Hide(); window:SetSize(560, 1133)
    window:SetScale(math.min(1, (UIParent:GetHeight() - 35) / 1133))
    window:SetPoint("CENTER", UIParent, "CENTER", 235, 20)
    window:SetFrameStrata("DIALOG"); window:SetClampedToScreen(true); window:SetMovable(true); window:EnableMouse(true)
    window:RegisterForDrag("LeftButton")
    window:SetScript("OnDragStart", window.StartMoving)
    window:SetScript("OnDragStop", window.StopMovingOrSizing)
    window:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    window:SetBackdropColor(0.035, 0.045, 0.065, 0.98); window:SetBackdropBorderColor(0.2, 0.6, 0.6, 1)
    table.insert(UISpecialFrames, "FreeSpellCooldownsBuffOptions")
    local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -3, -3); close:SetScript("OnClick", function() window:Hide() end)
    UI.Label(window, "Free Spell Cooldowns", 20, -19, "GameFontNormalLarge")
    self:AttachCategoryTabs(window, "buffs")
    UI.Label(window, "Buffy a procy – ikony, boční dvojice nebo horní motiv.", 20, -48, "GameFontHighlightSmall")
    window.profile = UI.Label(window, "", 20, -70, "GameFontNormalSmall")
    window.inputLabel = UI.Label(window, "Název buffu / aura spell ID:", 20, -100, "GameFontHighlightSmall")
    window.input = UI.EditBox(window, 25, -120, 385)
    local function Add()
        if FSC:AddBuff(window.input:GetText()) then window.input:SetText(""); window.input:ClearFocus() end
    end
    window.input:SetScript("OnEnterPressed", Add)
    window.addButton = UI.Button(window, "Přidat buff", 425, -121, 110, Add)
    window.chooseBuff = UI.Button(window, "Vybrat buff pro moji classu…", 20, -160, 370, function() FSC:OpenBuffCatalog() end)
    window.status = UI.Label(window, "Přidej buff a odemkni ikony pro náhled a přesun.", 20, -196, "GameFontHighlightSmall")
    window.status:SetWidth(515); window.status:SetHeight(30); window.status:SetJustifyV("TOP")
    window.listTitle = UI.Label(window, "", 20, -237, "GameFontNormalSmall")
    local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 20, -261); scroll:SetSize(490, 100)
    window.content = CreateFrame("Frame", nil, scroll); window.content:SetSize(490, 1); scroll:SetScrollChild(window.content)
    window.empty = UI.Label(window.content, "Zatím nesleduješ žádné buffy.", 8, -10, "GameFontDisable")
    window.selected = UI.Label(window, "", 20, -376, "GameFontNormal"); window.selected:SetWidth(510)
    window.spec1 = UI.CheckBox(window, "Spec 1", 20, -398, function(self)
        local entry = Selected(); if entry then FSC:SetBuffSpec(entry, 1, self:GetChecked()) end
    end)
    window.spec2 = UI.CheckBox(window, "Spec 2", 220, -398, function(self)
        local entry = Selected(); if entry then FSC:SetBuffSpec(entry, 2, self:GetChecked()) end
    end)
    local function Style(style)
        if not FSC:CanEdit() then return end
        FSC:ClearBuffFocus()
        local entry, layout = Selected()
        if layout then
            if layout.style ~= style then
                layout.style = style
                layout.size = style == "icon" and 52 or 240
            end
            FSC:StartBuffPreview(entry)
        end
    end
    window.iconStyle = StyleCard(window, 20, "icon", "Ikona buffu", function() Style("icon") end)
    window.lightningStyle = StyleCard(window, 195, "lightning", "Vlevo + vpravo", function() Style("lightning") end)
    window.topStyle = StyleCard(window, 370, "top", "Horní motiv", function() Style("top") end)
    window.styleCards = { window.iconStyle, window.lightningStyle, window.topStyle }
    window.themeLabel = UI.Label(window, "Motiv bočního a horního zobrazení:", 20, -537, "GameFontHighlightSmall")
    window.themeCards = {}
    for index, key in ipairs(FSC.buffThemeOrder) do
        local themeKey = key
        window.themeCards[index] = ThemeCard(window, 20 + (index - 1) * 132, key, function()
            if not FSC:CanEdit() then return end
            FSC:ClearBuffFocus()
            local entry, layout = Selected()
            if layout and layout.style ~= "icon" then
                layout.theme = themeKey; FSC:StartBuffPreview(entry)
            end
        end)
    end
    window.minimumLabel = UI.Label(window, "Od stacku:", 20, -652, "GameFontHighlightSmall")
    window.minimum = NumericBox(window, 110, -644, 65, function(_, layout, value)
        value = FSC:Clamp(math.floor(value + 0.5), 1, 40)
        if value > 1 and not FSC.buffThresholdSupported and FSC:GetBuffStackMode(layout) ~= "parts" then FSC:Status("Klient nepodporuje nativní práh stacků.", true)
        else layout.minStacks = value; layout.maxStacks = math.max(value, layout.maxStacks) end
    end)
    window.maximumLabel = UI.Label(window, "Maximum:", 280, -652, "GameFontHighlightSmall")
    window.maximum = NumericBox(window, 405, -644, 65, function(_, layout, value)
        layout.maxStacks = FSC:Clamp(math.floor(value + 0.5), 1, 40)
        layout.minStacks = math.min(layout.minStacks, layout.maxStacks)
    end)
    local function Toggle(field, value)
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then layout[field] = value == true; FSC:ApplyBuff(entry); FSC:RefreshBuffOptions() end
    end
    local function StackMode(mode)
        if not FSC:CanEdit() then return end
        FSC:ClearBuffFocus()
        local entry, layout = Selected()
        if not layout then return end
        if mode == "parts" and (layout.style == "icon" or layout.maxStacks < 2 or not FSC.buffPartsSupported) then
            FSC:Status("Po částech vyber u bočního nebo horního motivu s alespoň dvěma stacky.", true)
            FSC:RefreshBuffOptions(); return
        end
        layout.progressive, layout.revealParts = mode == "opacity", mode == "parts"
        FSC:StartBuffPreview(entry)
        if mode == "parts" then
            FSC.buffPreviewStacks = layout.minStacks
            FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end
    window.fullMotif = UI.RadioButton(window, "Celý motiv", 20, -678, function() StackMode("full") end)
    window.progressive = UI.RadioButton(window, "Zesilování", 195, -678, function() StackMode("opacity") end)
    window.revealParts = UI.RadioButton(window, "Po částech", 370, -678, function() StackMode("parts") end)
    window.glow = UI.CheckBox(window, "Zářit při maximu", 195, -713, function(self) Toggle("glowAtMax", self:GetChecked()) end)
    window.stacks = UI.CheckBox(window, "Počet stacků", 20, -713, function(self)
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then layout.showStacks = self:GetChecked() == true; FSC:ApplyBuff(entry) end
    end)
    window.duration = UI.CheckBox(window, "Časový odpočet", 370, -713, function(self)
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then layout.showDuration = self:GetChecked() == true; FSC:ApplyBuff(entry) end
    end)
    local function Alert(field, checked)
        if not FSC:CanEdit() or (checked == true and not FSC.buffThresholdSupported) then return end
        local entry, layout = Selected()
        if not layout then return end
        layout[field] = checked == true
        FSC:StartBuffPreview(entry)
    end
    window.flashMax = UI.CheckBox(window, "Blikat při maximu", 20, -748, function(self) Alert("flashAtMax", self:GetChecked()) end)
    window.pulseMax = UI.CheckBox(window, "Pulzovat při maximu", 270, -748, function(self) Alert("pulseAtMax", self:GetChecked()) end)
    window.alertIntensityLabel = UI.Label(window, "Síla blikání/pulzů:", 20, -789, "GameFontHighlightSmall")
    window.alertIntensity = UI.PercentSlider(window, 145, -783, 180)
    window.alertValue = UI.Label(window, "", 345, -789, "GameFontHighlightSmall")
    window.alertIntensity:SetScript("OnValueChanged", function(_, value)
        if window.syncing or not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then
            layout.alertIntensity = FSC:Clamp(math.floor(value + 0.5), 0, 100)
            FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end)
    window.alertPreview = UI.Button(window, "Náhled maxima", 410, -780, 125, function()
        local entry = Selected(); if entry then FSC:StartBuffPreview(entry) end
    end)
    window.ruleHint = UI.Label(window, "", 20, -837, "GameFontHighlightSmall")
    window.ruleHint:SetWidth(515); window.ruleHint:SetHeight(30); window.ruleHint:SetJustifyV("TOP")
    window.sizeLabel = UI.Label(window, "Velikost:", 20, -881, "GameFontHighlightSmall")
    local function Resize(delta)
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then
            local low, high = FSC:BuffSizeLimits(layout)
            layout.size = FSC:Clamp(layout.size + delta, low, high); FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end
    local minus = UI.StepButton(window, 90, -873, false, function() Resize(-1) end)
    window.size = UI.Label(window, "", 125, -881, "GameFontHighlightSmall")
    local plus = UI.StepButton(window, 191, -873, true, function() Resize(1) end)
    window.sizeLess, window.sizeMore = minus, plus
    window.combatOnly = UI.CheckBox(window, "Pouze v boji", 280, -868, function(self)
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then layout.combatOnly = self:GetChecked() == true; FSC:ApplyBuff(entry) end
    end)
    window.opacityLabel = UI.Label(window, "Průhlednost:", 20, -920, "GameFontHighlightSmall")
    window.opacity = UI.PercentSlider(window, 110, -914, 200)
    window.opacityValue = UI.Label(window, "", 328, -920, "GameFontHighlightSmall")
    window.opacity:SetScript("OnValueChanged", function(_, value)
        if window.syncing or not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then
            layout.opacity = 1 - FSC:Clamp(math.floor(value + 0.5), 0, 100) / 100
            FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end)
    window.xLabel = UI.Label(window, "X:", 20, -960, "GameFontHighlightSmall")
    window.x = NumericBox(window, 45, -952, 80, function(_, layout, value) layout.x = math.floor(value + 0.5) end)
    window.yLabel = UI.Label(window, "Y:", 195, -960, "GameFontHighlightSmall")
    window.y = NumericBox(window, 220, -952, 80, function(_, layout, value) layout.y = math.floor(value + 0.5) end)
    window.positionUnit = UI.Label(window, "px od středu", 322, -960, "GameFontHighlightSmall")
    window.previewStacksLabel = UI.Label(window, "Náhled stacků:", 20, -1003, "GameFontHighlightSmall")
    local function Preview(delta)
        local entry, layout = Selected()
        if layout and FSC:IsBuffPreview() then
            FSC.buffPreviewStacks = FSC:Clamp(FSC:Clamp(FSC.buffPreviewStacks or layout.maxStacks, 1, layout.maxStacks) + delta, 1, layout.maxStacks)
            FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end
    window.previewLess = UI.StepButton(window, 145, -995, false, function() Preview(-1) end)
    window.previewCount = UI.Label(window, "", 190, -1003, "GameFontHighlightSmall")
    window.previewMore = UI.StepButton(window, 230, -995, true, function() Preview(1) end)
    window.previewHint = UI.Label(window, "Po odemčení", 280, -1003, "GameFontHighlightSmall")
    window.lock = UI.Button(window, "", 20, -1046, 210, function()
        if FSC:IsBuffLocked() then
            local entry = Selected(); if entry then FSC:StartBuffPreview(entry) end
        else FSC:SetBuffLocked(true) end
    end)
    local center = UI.Button(window, "Přesunout na střed", 275, -1046, 235, function()
        if not FSC:CanEdit() then return end
        local entry, layout = Selected()
        if layout then layout.x, layout.y = 0, 0; FSC:ApplyBuff(entry); FSC:RefreshBuffOptions() end
    end)
    window.centerButton = center
    local hint = UI.Label(window, "NÁHLED: přetažení = poloha, Shift + kolečko = velikost.\nŠedý motiv pomáhá s polohou i při průhlednosti 100 %.", 20, -1085, "GameFontHighlightSmall")
    window.previewInstructions = hint
    hint:SetWidth(520); hint:SetHeight(32); hint:SetJustifyV("TOP")
    window.controls = { window.spec1, window.spec2, window.minimum, window.maximum,
        window.fullMotif, window.progressive, window.revealParts, window.glow, window.stacks, window.duration,
        window.flashMax, window.pulseMax, window.alertIntensity, window.alertPreview,
        minus, plus, window.combatOnly, window.opacity, window.x, window.y, center }
    window.edits = { window.input, window.minimum, window.maximum, window.x, window.y }
    window:SetScript("OnHide", function()
        if FSC.buffCatalogWindow then FSC.buffCatalogWindow:Hide() end
        FSC:ClearBuffFocus(); FSC:FinishBuffPreview()
    end)
    return window
end

function FSC:OpenBuffOptions(uid)
    if not self:CanEdit() then return end
    if uid then self.selectedBuffUID = uid end
    local window = self.buffOptions or self:CreateBuffOptions()
    if self.window:IsShown() then AtSamePosition(window, self.window) end
    self.window:Hide()
    if not self.db.locked then self:SetLocked(true) end
    self.activeOptionsTab, self.storage.optionsTab = "buffs", "buffs"
    window:Show(); window:Raise()
    self:RefreshBuffOptions(); self:UpdateAllBuffs()
    if uid then self:StartBuffPreview(self:FindBuff(uid)) end
end

local openCooldowns = FSC.OpenOptions
function FSC:OpenCooldownOptions(uid)
    if not self:CanEdit() then return end
    if self.buffOptions and self.buffOptions:IsShown() then
        AtSamePosition(self.window, self.buffOptions); self.buffOptions:Hide()
    end
    self.activeOptionsTab, self.storage.optionsTab = "cooldowns", "cooldowns"
    openCooldowns(self, uid)
end
function FSC:OpenOptions(uid)
    if not uid and self.storage and self.storage.optionsTab == "buffs" then self:OpenBuffOptions()
    else self:OpenCooldownOptions(uid) end
end
local status = FSC.Status
function FSC:Status(message, isError)
    if self.buffOptions and self.buffOptions:IsShown() then
        self.buffOptions.status:SetText(message)
        self.buffOptions.status:SetTextColor(isError and 1 or 0.4, isError and 0.4 or 0.9, 0.8)
    else status(self, message, isError) end
end
local clearFocus = FSC.ClearInputFocus
function FSC:ClearInputFocus()
    clearFocus(self)
    self:ClearBuffFocus()
end
local setLocked = FSC.SetLocked
function FSC:SetLocked(locked)
    setLocked(self, locked)
    if not locked and self.buffsInitialized then self:FinishBuffPreview() end
    self:RefreshBuffOptions()
end

function FSC:SetCurrentLocked(locked)
    if (self.activeOptionsTab or (self.storage and self.storage.optionsTab)) == "buffs" then
        if not locked then
            self:OpenBuffOptions()
            self:StartBuffPreview(self:FindBuff(self.selectedBuffUID))
        else self:SetBuffLocked(true) end
    else self:SetLocked(locked) end
end

function FSC:ToggleCurrentLock()
    local buffs = (self.activeOptionsTab or (self.storage and self.storage.optionsTab)) == "buffs"
    self:SetCurrentLocked(buffs and not self:IsBuffLocked() or (not buffs and not self.db.locked))
end
