local _, FSC = ...
local UI = FSC.UI
local WIDTH, HEIGHT = 1040, 700

local function Put(region, parent, x, y, width, height)
    region:ClearAllPoints()
    if region:GetParent() ~= parent then region:SetParent(parent) end
    region:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if width then region:SetWidth(width) end
    if height then region:SetHeight(height) end
    return region
end

local function Panel(parent, title, x, y, width, height)
    local panel = parent:CreateTexture(nil, "BACKGROUND")
    panel:SetPoint("TOPLEFT", x, y); panel:SetSize(width, height)
    panel:SetColorTexture(0.055, 0.09, 0.115, 0.96)
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local line = parent:CreateTexture(nil, "BACKGROUND")
        line:SetColorTexture(0.23, 0.43, 0.46, 1)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetPoint("TOPLEFT", x, y - (edge == "BOTTOM" and height or 0)); line:SetSize(width, 1)
        else line:SetPoint("TOPLEFT", x + (edge == "RIGHT" and width or 0), y); line:SetSize(1, height) end
    end
    if title ~= "" then UI.Label(parent, title, x + 14, y - 12, "GameFontNormal") end
    return panel
end

local function SectionTab(parent, text, x, callback)
    local tab = CreateFrame("Button", nil, parent, "BackdropTemplate")
    tab:SetPoint("TOPLEFT", x, -165); tab:SetSize(160, 28)
    tab:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    tab.caption = UI.Label(tab, text, 0, 0, "GameFontHighlightSmall")
    tab.caption:ClearAllPoints(); tab.caption:SetAllPoints(tab)
    tab.caption:SetJustifyH("CENTER"); tab.caption:SetJustifyV("MIDDLE")
    tab:SetScript("OnClick", callback)
    return tab
end

function FSC:FitSettingsWindow(window)
    window:SetSize(WIDTH, HEIGHT)
    window:SetScale(math.min(1, (UIParent:GetWidth() - 40) / WIDTH, (UIParent:GetHeight() - 40) / HEIGHT))
end

local function Shell(window)
    FSC:FitSettingsWindow(window)
    window:ClearAllPoints(); window:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    Panel(window, "", 12, -97, 316, 551)
    local divider = window:CreateTexture(nil, "BACKGROUND")
    divider:SetColorTexture(0.12, 0.3, 0.34, 1); divider:SetSize(1, 550)
    divider:SetPoint("TOPLEFT", 338, -97)
    UI.Label(window, FSC:T("Jazyk"), 730, -60, "GameFontHighlightSmall")
    window.languageButtons = {
        cs = UI.Button(window, "Čeština", 809, -53, 100, function() FSC:RequestLanguageChange("cs") end),
        en = UI.Button(window, "English", 919, -53, 100, function() FSC:RequestLanguageChange("en") end),
    }
    window.languageButtons[FSC:GetLanguage()]:SetEnabled(false)
end

local function SoundCount(parent, window, x, y, field)
    field = field or "soundStacks"
    local edit = UI.EditBox(parent, x, y, (field == "sideGap" or field == "size") and 85 or 55)
    edit:SetMaxLetters(field == "sideGap" and 4 or (field == "size" and 3 or 2))
    edit:SetScript("OnEditFocusGained", function(self) self.buffUID, self.spec = FSC.selectedBuffUID, FSC.activeSpec end)
    edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
    edit:SetScript("OnEscapePressed", function(self) self.cancelled = true; self:ClearFocus() end)
    edit:SetScript("OnEditFocusLost", function(self)
        local entry, value = FSC:FindBuff(self.buffUID), tonumber(self:GetText())
        if not self.cancelled and entry and self.spec == FSC.activeSpec and FSC:CanEdit() and value and value == value then
            local layout = FSC:BuffLayout(entry)
            local low, high = field == "sideGap" and 0 or 1,
                field == "sideGap" and 2000 or (field == "timeFadeStacks" and layout.maxStacks or 40)
            if field == "size" then low, high = FSC:BuffSizeLimits(layout) end
            layout[field] = FSC:Clamp(math.floor(value + 0.5), low, high)
            if field == "soundStacks" then FSC:ResetBuffSound(entry) end
            FSC:ApplyBuff(entry)
        end
        self.cancelled = nil; FSC:RefreshBuffOptions()
    end)
    table.insert(window.edits, edit)
    return edit
end

function FSC:CreateBuffSoundControls(window, page)
    Panel(page, FSC:T("ZVUKOVÉ UPOZORNĚNÍ"), 0, -264, 670, 180)
    local function Toggle(field, check)
        if not FSC:CanEdit() then return end
        local entry = FSC:FindBuff(FSC.selectedBuffUID)
        if entry then
            FSC:BuffLayout(entry)[field] = check:GetChecked() == true
            FSC:ResetBuffSound(entry); FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end
    window.soundEnabled = UI.CheckBox(page, FSC:T("Zapnout zvuk"), 16, -296, function(check) Toggle("soundEnabled", check) end)
    window.soundAtMax = UI.CheckBox(page, FSC:T("Při maximu"), 235, -296, function(check) Toggle("soundAtMax", check) end)
    UI.Label(page, FSC:T("Vlastní počet:"), 440, -304, "GameFontHighlightSmall")
    window.soundStacks = SoundCount(page, window, 548, -296)
    local picker = CreateFrame("Frame", nil, window, "BackdropTemplate")
    picker:SetSize(378, #self.buffSounds * 24 + 12); picker:SetFrameStrata("TOOLTIP")
    picker:SetClampedToScreen(true); picker:EnableMouse(true)
    picker:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
    picker:SetBackdropColor(0.035, 0.055, 0.07, 1); picker:SetBackdropBorderColor(0.25, 0.7, 0.7, 1)
    window.soundPicker = picker; picker:Hide(); picker.choices = {}
    window.soundChoice = UI.Button(page, "", 16, -336, 400, function()
        FSC:ClearBuffFocus(); picker:SetShown(not picker:IsShown())
    end)
    picker:SetPoint("BOTTOMLEFT", window.soundChoice, "TOPLEFT", 0, 4)
    for index, sound in ipairs(self.buffSounds) do
        local selected = sound
        picker.choices[index] = UI.Button(picker, FSC:T(sound.name), 6, -6 - (index - 1) * 24, 366, function()
            if not FSC:CanEdit() then return end
            local entry = FSC:FindBuff(FSC.selectedBuffUID)
            if entry then FSC:BuffLayout(entry).soundKit = selected.id; FSC:ResetBuffSound(entry); FSC:ApplyBuff(entry) end
            picker:Hide(); FSC:RefreshBuffOptions()
        end)
    end
    window.soundTest = UI.Button(page, FSC:T("Přehrát ukázku zvuku"), 435, -336, 218, function()
        FSC:PlayBuffSound(FSC:FindBuff(FSC.selectedBuffUID), true)
    end)
    window.soundHint = UI.Label(page, "", 16, -376, "GameFontHighlightSmall")
    window.soundHint:SetWidth(638); window.soundHint:SetHeight(56); window.soundHint:SetJustifyV("TOP")
    local hidden = window:GetScript("OnHide")
    window:SetScript("OnHide", function(...) picker:Hide(); if hidden then hidden(...) end end)
    for _, control in ipairs({window.soundEnabled, window.soundAtMax, window.soundStacks, window.soundChoice, window.soundTest}) do
        table.insert(window.controls, control)
    end
end

local function ShowSettingsPage(window, key)
    if not window.settingsPages[key] then key = "appearance" end
    window.settingsPage = key
    for name, page in pairs(window.settingsPages) do
        local selected, tab = name == key, window.settingsTabs[name]
        page:SetShown(selected); tab:SetEnabled(true); tab.selected = selected
        tab:SetBackdropColor(selected and 0.08 or 0.035, selected and 0.26 or 0.065, selected and 0.28 or 0.08, 1)
        tab:SetBackdropBorderColor(selected and 0.3 or 0.18, selected and 0.95 or 0.32, selected and 0.85 or 0.36, 1)
        tab.caption:SetTextColor(selected and 1 or 0.78, selected and 0.84 or 0.82, selected and 0.2 or 0.85)
    end
    return key
end

function FSC:SetBuffSettingsPage(key)
    local window = self.buffOptions
    if not window or not window.settingsPages then return end
    self:ClearBuffFocus()
    if window.soundPicker then window.soundPicker:Hide() end
    key = ShowSettingsPage(window, key)
    if self.storage then self.storage.buffSettingsTab = key end
    if window.saveNotice then window.saveNotice:SetText(key == "preview"
        and FSC:T("Testovací stacky a čas se neukládají. Přesun a velikost motivu se ukládají.")
        or FSC:T("Nastavení se ukládá automaticky pro vybraný buff a aktivní spec.")) end
end

local originalBuffCreate = FSC.CreateBuffOptions
function FSC:CreateBuffOptions()
    local window = originalBuffCreate(self)
    Shell(window)
    window.profile:SetWidth(990)
    Put(window.inputLabel, window, 24, -117, 290)
    Put(window.input, window, 25, -139, 288)
    Put(window.addButton, window, 20, -178, 112)
    Put(window.chooseBuff, window, 142, -178, 176); window.chooseBuff:SetText(FSC:T("Vybrat buff pro classu"))
    Put(window.status, window, 20, -214, 295, 26)
    Put(window.listTitle, window, 20, -254, 295)
    local scroll = window.content:GetParent()
    Put(scroll, window, 20, -280, 270, 345); window.content:SetWidth(270)
    Put(window.selected, window, 350, -105, 668)
    Put(window.spec1, window, 350, -130); Put(window.spec2, window, 560, -130)
    window.settingsPages, window.settingsTabs = {}, {}
    local appearance, alerts, position, preview
    for index, spec in ipairs({{"appearance", FSC:T("Vzhled")}, {"alerts", FSC:T("Stacky a zvuk")}, {"position", FSC:T("Poloha")}, {"preview", FSC:T("Test náhledu")}}) do
        local key = spec[1]
        local page = CreateFrame("Frame", nil, window)
        Put(page, window, 350, -205, 670, 450); window.settingsPages[key] = page
        window.settingsTabs[key] = SectionTab(window, spec[2], 350 + (index - 1) * 170,
            function() FSC:SetBuffSettingsPage(key) end)
    end
    appearance, alerts, position = window.settingsPages.appearance, window.settingsPages.alerts, window.settingsPages.position
    preview = window.settingsPages.preview
    Panel(appearance, FSC:T("TVAR UPOZORNĚNÍ"), 0, 0, 670, 114)
    for i, card in ipairs(window.styleCards) do Put(card, appearance, 12 + (i - 1) * 220, -31, 204, 80) end
    Panel(appearance, "", 0, -124, 670, 96)
    Put(window.themeLabel, appearance, 14, -136); window.themeLabel:SetText(FSC:T("GRAFICKÝ MOTIV"))
    local themeWidth = math.floor((646 - (#window.themeCards - 1) * 10) / #window.themeCards)
    for i, card in ipairs(window.themeCards) do Put(card, appearance, 12 + (i - 1) * (themeWidth + 10), -155, themeWidth, 58) end
    Panel(appearance, FSC:T("ČÍSLA A PRŮHLEDNOST"), 0, -230, 670, 94)
    Put(window.stacks, appearance, 16, -254); Put(window.duration, appearance, 310, -254)
    Put(window.opacityLabel, appearance, 16, -299)
    Put(window.opacity, appearance, 135, -292, 300); Put(window.opacityValue, appearance, 455, -299)
    Panel(appearance, FSC:T("ČASOVÝ EFEKT"), 0, -334, 670, 110)
    window.timeFade = UI.CheckBox(appearance, FSC:T("Časový úbytek se šedým podkladem"), 16, -361, function(check)
        if not FSC:CanEdit() then return end
        local entry = FSC:FindBuff(FSC.selectedBuffUID)
        if entry then
            FSC:BuffLayout(entry).timeFade = check:GetChecked() == true
            FSC.buffPreviewRemaining = 1; FSC:StartBuffPreview(entry)
        end
    end)
    window.timeFadeStacksLabel = UI.Label(appearance, FSC:T("Spustit od stacku:"), 420, -369, "GameFontHighlightSmall")
    window.timeFadeStacks = SoundCount(appearance, window, 575, -361, "timeFadeStacks")
    local timeHelp = UI.Label(appearance, FSC:T("Barevná část ukazuje zbývající čas, uplynulá část zůstává šedá.\nPráh platí jen pro časový efekt. Jednotlivé části přibývají dál podle stacků."), 16, -400, "GameFontHighlightSmall")
    timeHelp:SetWidth(638); timeHelp:SetHeight(36)
    window.timeFadeLabel = UI.Label(preview, FSC:T("Test času (jen náhled):"), 16, -282, "GameFontHighlightSmall")
    window.timeFadeLabel:SetWidth(220); window.timeFadeLabel:SetHeight(30)
    window.timeFadeLabel:SetJustifyV("TOP")
    window.timeFadePreview = UI.PercentSlider(preview, 245, -275, 310)
    window.timeFadeValue = UI.Label(preview, "", 580, -282, "GameFontHighlightSmall")
    window.timeFadePreview:SetScript("OnValueChanged", function(_, value)
        if window.syncing then return end
        local entry = FSC:FindBuff(FSC.selectedBuffUID)
        if entry and FSC:CanEdit() then FSC.buffPreviewRemaining = FSC:Clamp(value / 100, 0, 1); FSC:ApplyBuff(entry); FSC:RefreshBuffOptions() end
    end)
    Panel(alerts, FSC:T("ZOBRAZENÍ PODLE STACKŮ"), 0, 0, 670, 112)
    Put(window.minimumLabel, alerts, 16, -39); window.minimumLabel:SetText(FSC:T("Ukázat od stacku:"))
    Put(window.minimum, alerts, 165, -31)
    Put(window.maximumLabel, alerts, 350, -39); window.maximumLabel:SetText(FSC:T("Maximum stacků:"))
    Put(window.maximum, alerts, 515, -31)
    Put(window.fullMotif, alerts, 16, -72); Put(window.progressive, alerts, 235, -72); Put(window.revealParts, alerts, 450, -72)
    Panel(alerts, FSC:T("ZÁŘE A POHYB PŘI MAXIMU"), 0, -124, 670, 128)
    Put(window.glow, alerts, 16, -154); Put(window.flashMax, alerts, 235, -154); Put(window.pulseMax, alerts, 450, -154)
    Put(window.alertIntensityLabel, alerts, 16, -198); Put(window.alertIntensity, alerts, 165, -191, 220)
    Put(window.alertValue, alerts, 400, -198)
    Put(window.ruleHint, alerts, 16, -223, 638, 26)
    local function OpenPreview()
        FSC:SetBuffSettingsPage("preview")
        local entry = FSC:FindBuff(FSC.selectedBuffUID); if entry then FSC:StartBuffPreview(entry) end
    end
    window.alertsPreviewLink = UI.Button(alerts, FSC:T("Otestovat efekty"), 490, -189, 165, OpenPreview)
    Panel(position, FSC:T("ROZMĚRY"), 0, 0, 670, 112)
    Put(window.sizeLabel, position, 16, -35); window.sizeLabel:SetText(FSC:T("Velikost motivu (px):"))
    Put(window.sizeLess, position, 16, -61); Put(window.sizeMore, position, 145, -61)
    Put(window.size, position, 50, -59); window.size:Hide()
    window.sizeInput = SoundCount(position, window, 50, -59, "size")
    window.sideGapLabel = UI.Label(position, FSC:T("Mezera mezi stranami (px):"), 350, -35, "GameFontHighlightSmall")
    window.sideGap = SoundCount(position, window, 350, -59, "sideGap")
    Panel(position, FSC:T("POLOHA NA OBRAZOVCE"), 0, -124, 670, 156)
    Put(window.xLabel, position, 16, -164); window.xLabel:SetText(FSC:T("Vodorovně (X):"))
    Put(window.x, position, 160, -156, 110)
    Put(window.yLabel, position, 350, -164); window.yLabel:SetText(FSC:T("Svisle (Y):"))
    Put(window.y, position, 490, -156, 110)
    Put(window.positionUnit, position, 16, -241); window.positionUnit:Hide()
    local direction = UI.Label(position, FSC:T("X: záporné = vlevo, kladné = vpravo.   Y: záporné = dolů, kladné = nahoru."), 16, -201, "GameFontHighlightSmall")
    direction:SetWidth(638); direction:SetHeight(24)
    UI.Label(position, FSC:T("Pixely od středu obrazovky."), 16, -241, "GameFontHighlightSmall")
    Put(window.centerButton, position, 420, -233, 230)
    Panel(position, FSC:T("KDY ZOBRAZOVAT"), 0, -292, 670, 84)
    Put(window.combatOnly, position, 16, -324); window.combatOnly.label:SetText(FSC:T("Zobrazovat pouze v boji"))
    UI.Label(position, FSC:T("Vypnuto = také mimo boj."), 350, -332, "GameFontHighlightSmall")
    Panel(position, "", 0, -388, 670, 56)
    UI.Label(position, FSC:T("Chceš motiv přesunout myší?"), 16, -408, "GameFontHighlightSmall")
    window.positionPreviewLink = UI.Button(position, FSC:T("Otevřít pracovní náhled"), 420, -403, 230, OpenPreview)
    Panel(preview, FSC:T("PRACOVNÍ NÁHLED"), 0, 0, 670, 92)
    UI.Label(preview, FSC:T("Pouze zkouška vzhledu. Skutečný buff a jeho stacky se nemění."), 16, -35, "GameFontHighlightSmall")
    window.previewState = UI.Label(preview, "", 16, -64, "GameFontNormalSmall")
    Put(window.lock, preview, 380, -55, 270)
    Panel(preview, FSC:T("VYZKOUŠET POČET STACKŮ"), 0, -104, 670, 126)
    Put(window.previewStacksLabel, preview, 16, -145); window.previewStacksLabel:SetText(FSC:T("Testovací počet:"))
    Put(window.previewLess, preview, 175, -137); Put(window.previewCount, preview, 214, -145)
    Put(window.previewMore, preview, 250, -137); Put(window.alertPreview, preview, 415, -137, 238)
    Put(window.previewHint, preview, 16, -188, 638, 30)
    window.previewHint:SetText(FSC:T("Tlačítka −/+ mění jen testovací stacky. Maximum ukáže také zapnuté blikání a pulzování."))
    Panel(preview, FSC:T("VYZKOUŠET ZBÝVAJÍCÍ ČAS"), 0, -242, 670, 104)
    window.timePreviewHint = UI.Label(preview, "", 16, -315, "GameFontHighlightSmall")
    window.timePreviewHint:SetWidth(638); window.timePreviewHint:SetHeight(28)
    Panel(preview, FSC:T("JAK MOTIV PŘESUNOUT"), 0, -358, 670, 86)
    Put(window.previewInstructions, preview, 16, -391, 638, 42)
    window.previewInstructions:SetText(FSC:T("Táhni za tyrkysový rámeček. Shift + kolečko mění velikost.\nPoloha a velikost se uloží pro vybraný buff a aktivní spec."))
    window.saveNotice = UI.Label(window, "", 350, -670, "GameFontHighlightSmall")
    self:CreateBuffSoundControls(window, alerts)
    table.insert(window.controls, window.timeFade); table.insert(window.controls, window.timeFadeStacks)
    table.insert(window.controls, window.sideGap)
    table.insert(window.controls, window.sizeInput); table.insert(window.controls, window.positionPreviewLink)
    table.insert(window.controls, window.alertsPreviewLink)
    table.insert(window.controls, window.timeFadePreview)
    self:SetBuffSettingsPage(self.storage and self.storage.buffSettingsTab)
    return window
end

local originalRefresh = FSC.RefreshBuffOptions
function FSC:RefreshBuffOptions()
    originalRefresh(self)
    local window = self.buffOptions
    if not window or not window.soundEnabled then return end
    local entry = self:FindBuff(self.selectedBuffUID)
    local layout = entry and self:BuffLayout(entry)
    if layout and self:GetBuffStackMode(layout) == "parts" and layout.minStacks > 1 then
        window.ruleHint:SetText(FSC:T("Postupné části se nyní zobrazí až od ") .. layout.minStacks
            .. FSC:T(" stacků. Pro zobrazení od prvního kroku nastav Ukázat od stacku na 1."))
    end
    if not window.sizeInput:HasFocus() then window.sizeInput:SetText(layout and tostring(layout.size) or "") end
    local previewing = entry and self:IsBuffPreview(entry)
    window.previewState:SetText(previewing and FSC:T("NÁHLED ZAPNUTÝ — motiv můžeš upravovat") or FSC:T("NÁHLED VYPNUTÝ"))
    window.previewState:SetTextColor(previewing and 0.35 or 0.8, previewing and 0.95 or 0.82, previewing and 0.8 or 0.85)
    window.lock:SetText(previewing and FSC:T("Dokončit úpravy náhledu") or FSC:T("Zapnout pracovní náhled"))
    window.alertPreview:SetText(layout and (FSC:T("Nastavit maximum (") .. layout.maxStacks .. ")") or FSC:T("Nastavit maximum"))
    local canSpace = layout ~= nil and layout.style == "lightning"
    window.sideGap:SetEnabled(canSpace); window.sideGapLabel:SetAlpha(canSpace and 1 or 0.45)
    if not window.sideGap:HasFocus() then window.sideGap:SetText(layout and layout.sideGap and tostring(math.floor(layout.sideGap + 0.5)) or "") end
    window.soundEnabled:SetChecked(layout and layout.soundEnabled or false)
    window.soundAtMax:SetChecked(layout and layout.soundAtMax or false)
    window.soundAtMax:SetEnabled(entry ~= nil)
    window.soundStacks:SetEnabled(layout ~= nil and not layout.soundAtMax)
    if not window.soundStacks:HasFocus() then window.soundStacks:SetText(layout and tostring(layout.soundStacks) or "") end
    window.soundChoice:SetText(layout and (self:T(self:GetBuffSound(layout.soundKit).name) .. FSC:T(" (vybrat)")) or FSC:T("Vyber buff"))
    window.soundHint:SetText(self:GetBuffSoundStatus(entry))
    window.timeFade:SetChecked(layout and layout.timeFade or false)
    window.timeFade:SetEnabled(entry ~= nil and ((self.buffTimeFadeSupported and self.buffThresholdSupported) or layout.timeFade))
    local canSetTime = layout ~= nil and layout.timeFade
    window.timeFadeStacks:SetEnabled(canSetTime); window.timeFadeStacksLabel:SetAlpha(canSetTime and 1 or 0.45)
    if not window.timeFadeStacks:HasFocus() then window.timeFadeStacks:SetText(layout and tostring(layout.timeFadeStacks) or "") end
    local previewCount = layout and self:Clamp(self.buffPreviewStacks or layout.maxStacks, 1, layout.maxStacks) or 0
    local canTestTime = canSetTime and previewCount >= layout.timeFadeStacks and self:IsBuffPreview(entry)
    window.timePreviewHint:SetText(not canSetTime and FSC:T("Nejprve zapni časový efekt v záložce Vzhled.")
        or (not previewing and FSC:T("Nejprve zapni pracovní náhled tlačítkem nahoře.")
        or (previewCount < layout.timeFadeStacks and (FSC:T("Časový efekt běží od ") .. layout.timeFadeStacks .. FSC:T(" stacků. Zvyš testovací počet nebo nastav maximum."))
        or FSC:T("100 % = celá doba, 0 % = konec. Uplynulá část zůstává šedá."))))
    window.timeFadePreview:SetEnabled(canTestTime)
    window.timeFadePreview:SetAlpha(canTestTime and 1 or 0.35)
    window.timeFadeLabel:SetAlpha(canTestTime and 1 or 0.45); window.timeFadeValue:SetAlpha(canTestTime and 1 or 0.45)
    window.syncing = true
    local remaining = math.floor((self.buffPreviewRemaining or 1) * 100 + 0.5)
    window.timeFadePreview:SetValue(remaining); window.timeFadeValue:SetText(remaining .. " %")
    window.syncing = false
end

function FSC:SetCooldownSettingsPage(key)
    local window = self.window
    if not window or not window.settingsPages then return end
    self:ClearInputFocus()
    key = ShowSettingsPage(window, key)
    self.storage.cooldownSettingsTab = key
    window.saveNotice:SetText(key == "preview" and FSC:T("Testovací stavy a časy se neukládají.")
        or FSC:T("Nastavení se ukládá pro vybrané kouzlo a aktivní spec."))
    self:RefreshCooldownPreview()
end

local originalCooldownCreate = FSC.CreateOptions
function FSC:CreateOptions()
    originalCooldownCreate(self)
    local window = self.window
    Shell(window)
    window.profileStatus:SetWidth(990)
    Put(window.drop, window, 20, -112, 295, 73)
    window.dropLabel:SetWidth(275); window.dropLabel:SetText(FSC:T("Přetáhni kouzlo ze spellbooku"))
    window.dropHint:SetWidth(275); window.dropHint:SetText(FSC:T("Spellbook otevřeš klávesou P."))
    Put(window.inputLabel, window, 20, -200, 295)
    Put(window.input, window, 25, -224, 285)
    Put(window.addButton, window, 20, -263, 295)
    Put(window.status, window, 20, -302, 295, 36)
    Put(window.listTitle, window, 20, -351, 295, 30)
    Put(window.scroll, window, 20, -392, 270, 235); window.content:SetWidth(270)
    Put(window.selected, window, 350, -105, 668)
    Put(window.specLabel, window, 350, -142)
    Put(window.spec1, window, 470, -130); Put(window.spec2, window, 710, -130)
    window.settingsPages, window.settingsTabs = {}, {}
    for index, spec in ipairs({
        {"appearance", FSC:T("Vzhled ikony")}, {"alerts", FSC:T("Boj a upozornění")}, {"preview", FSC:T("Test náhledu")},
    }) do
        local key = spec[1]
        local page = CreateFrame("Frame", nil, window)
        Put(page, window, 350, -205, 670, 450)
        window.settingsPages[key] = page
        local tab = SectionTab(window, spec[2], 350 + (index - 1) * 227,
            function() FSC:SetCooldownSettingsPage(key) end)
        tab:SetWidth(216)
        window.settingsTabs[key] = tab
    end

    local appearance, alerts = window.settingsPages.appearance, window.settingsPages.alerts
    Panel(appearance, FSC:T("ROZMĚRY A TEXT"), 0, 0, 670, 116)
    Put(window.sizeLabel, appearance, 16, -55); Put(window.sizeLess, appearance, 94, -47)
    Put(window.sizeInput, appearance, 128, -45, 64); Put(window.sizeMore, appearance, 202, -47)
    Put(window.sizeUnit, appearance, 235, -55)
    Put(window.numbers, appearance, 330, -36); Put(window.spellName, appearance, 330, -70)
    Panel(appearance, FSC:T("PRŮHLEDNOST"), 0, -128, 670, 100)
    Put(window.opacityLabel, appearance, 16, -173)
    Put(window.opacitySlider, appearance, 139, -167, 300); Put(window.opacityValue, appearance, 458, -173)
    Put(window.opacityHint, appearance, 16, -199, 638)
    Panel(appearance, FSC:T("POLOHA NA OBRAZOVCE"), 0, -240, 670, 204)
    Put(window.xLabel, appearance, 16, -292); Put(window.xLess, appearance, 46, -284)
    Put(window.xInput, appearance, 84, -282, 95); Put(window.xMore, appearance, 192, -284)
    Put(window.yLabel, appearance, 285, -292); Put(window.yLess, appearance, 315, -284)
    Put(window.yInput, appearance, 353, -282, 95); Put(window.yMore, appearance, 460, -284)
    Put(window.centerButton, appearance, 16, -324, 222)
    Put(window.coordinatesHint, appearance, 253, -330, 397, 25)
    window.coordinatesHint:SetText(FSC:T("X/Y = pixely od středu. Tlačítka mění polohu o 1 px."))
    Put(window.lockButton, appearance, 16, -379, 222)
    Put(window.moveHint, appearance, 253, -374, 397, 34)

    Panel(alerts, FSC:T("ZOBRAZENÍ IKONY"), 0, 0, 670, 140)
    Put(window.flashOnly, alerts, 16, -34)
    Put(window.combatOnly, alerts, 16, -70); Put(window.manaTint, alerts, 330, -70)
    window.cooldownDisplayHint = UI.Label(alerts, "", 16, -110, "GameFontHighlightSmall")
    Panel(alerts, FSC:T("ZÁBLESK PO COOLDOWNU"), 0, -152, 670, 168)
    Put(window.flashReady, alerts, 16, -188); Put(window.flashOutsideCombat, alerts, 330, -188)
    Put(window.flashIntensityLabel, alerts, 16, -257)
    Put(window.flashIntensitySlider, alerts, 158, -251, 225)
    Put(window.flashIntensityValue, alerts, 397, -257)
    UI.Button(alerts, FSC:T("Otevřít test náhledu"), 465, -247, 189, function()
        FSC:SetCooldownSettingsPage("preview")
    end)

    self:CreateCooldownPreview(window, window.settingsPages.preview, Panel)
    window.saveNotice = UI.Label(window, "", 350, -670, "GameFontHighlightSmall")
    self:SetCooldownSettingsPage(self.storage.cooldownSettingsTab)
end

local originalCooldownRefresh = FSC.RefreshOptions
function FSC:RefreshOptions()
    originalCooldownRefresh(self)
    self:RefreshCooldownPreview()
end

local events = CreateFrame("Frame")
events:RegisterEvent("DISPLAY_SIZE_CHANGED"); events:RegisterEvent("UI_SCALE_CHANGED")
events:SetScript("OnEvent", function()
    if FSC.window then FSC:FitSettingsWindow(FSC.window) end
    if FSC.buffOptions then FSC:FitSettingsWindow(FSC.buffOptions) end
end)
