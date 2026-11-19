local _, FSC = ...
local UI = FSC.UI
local TEST_SECONDS = 5

local function ClearTimer(preview)
    preview.timer = nil
    preview.page:SetScript("OnUpdate", nil)
    preview.icon.cooldown:Clear()
    preview.icon.chargeCooldown:Clear()
    preview.icon.count:SetText("")
    preview.countdownText:SetText("")
end

function FSC:StopCooldownPreview()
    local preview = self.window and self.window.cooldownPreview
    if not preview or not preview.uid then return end
    ClearTimer(preview)
    self:StopReadyFlashEffect(preview.icon)
    preview.stage:Hide()
    preview.uid, preview.profile = nil, nil
end

function FSC:RefreshCooldownPreview()
    local window = self.window
    local preview = window and window.cooldownPreview
    if not preview then return end
    if window.settingsPage ~= "preview" or not window:IsShown() or self.inCombat then
        self:StopCooldownPreview()
        return
    end
    local entry = self:FindEntry(self.selectedUID)
    for _, control in ipairs(preview.controls) do control:SetEnabled(entry ~= nil) end
    if not entry then
        self:StopCooldownPreview()
        preview.combatCheck:SetChecked(false)
        preview.screenCheck:SetChecked(false)
        for _, choice in pairs(preview.choices) do choice:SetChecked(false) end
        preview.status:SetText(FSC:T("Nejdřív přidej nebo vyber kouzlo."))
        return
    end
    if preview.uid ~= entry.uid or preview.profile ~= self.activeProfileKey then
        self:StopCooldownPreview()
        preview.uid, preview.profile = entry.uid, self.activeProfileKey
        preview.inCombat, preview.onScreen, preview.mode = true, false, "ready"
    end

    local icon, stage = preview.icon, preview.stage
    local parent = preview.onScreen and UIParent or preview.sample
    local strata = preview.onScreen and "TOOLTIP" or window:GetFrameStrata()
    stage:ClearAllPoints()
    if stage:GetParent() ~= parent then stage:SetParent(parent) end
    stage:SetPoint("CENTER", parent, "CENTER", preview.onScreen and entry.x or 0,
        preview.onScreen and entry.y or 8)
    stage:SetFrameStrata(strata)
    icon:SetFrameStrata(strata)
    icon.readyFlashLayer:SetFrameStrata(strata)
    self:ApplyIconAppearance(icon, entry)
    if not preview.onScreen then icon.label:SetWidth(math.min(247, icon.label:GetWidth())) end
    self:PaintIconAvailability(icon, preview.mode ~= "range", entry.manaTint and preview.mode == "mana")

    local visible, drawIcon = self:GetCooldownIconVisibility(entry, preview.inCombat)
    self:SetCooldownIconDrawing(icon, entry, drawIcon or (entry.flashOnly and not icon.readyFlash:IsShown()))
    if not visible then self:StopReadyFlashEffect(icon) end
    stage:SetShown(visible)
    preview.combatCheck:SetChecked(preview.inCombat)
    preview.screenCheck:SetChecked(preview.onScreen)
    for mode, choice in pairs(preview.choices) do choice:SetChecked(preview.mode == mode) end
    preview.choices.range:SetEnabled(not entry.flashOnly)
    preview.choices.mana:SetEnabled(not entry.flashOnly)
    preview.flashButton:SetEnabled(self:GetFlashIntensity(entry) > 0)

    local status
    if preview.timer then status = preview.timer.status
    elseif not visible then status = FSC:T("Mimo boj · ikona je schovaná.")
    elseif entry.flashOnly then status = self:ShouldFlashOnReady(entry, preview.inCombat)
        and FSC:T("Náhled ikony pro záblesk.") or FSC:T("Mimo boj · upozornění je vypnuté.")
    elseif preview.mode == "range" then status = FSC:T("Cíl mimo dosah.")
    elseif preview.mode == "mana" then status = entry.manaTint and FSC:T("Nedostatek many.") or FSC:T("Nedostatek many · modré zabarvení je vypnuté.")
    elseif preview.onScreen then status = FSC:T("Náhled je na uložené pozici.")
    else status = FSC:T("Kouzlo je připravené.") end
    preview.status:SetText(status)
    return entry
end

local function StartNativeVisual(widget, start)
    if C_DurationUtil and C_DurationUtil.CreateDuration and widget.SetCooldownFromDurationObject then
        local ok = pcall(function()
            local duration = C_DurationUtil.CreateDuration()
            duration:SetTimeFromStart(start, TEST_SECONDS)
            widget:SetCooldownFromDurationObject(duration, true)
        end)
        if ok then return true end
    end
    if widget.SetCooldown then
        local ok = pcall(widget.SetCooldown, widget, start, TEST_SECONDS)
        return ok
    end
    return false
end

local function UpdateTimer(preview)
    local timer = preview.timer
    local remaining = timer.endsAt - GetTime()
    if remaining > 0 then
        local seconds = math.ceil(remaining)
        if timer.seconds ~= seconds then
            timer.seconds = seconds
            timer.status = (timer.charges and FSC:T("Nabíjení skončí za %d s.") or FSC:T("Odpočet skončí za %d s.")):format(seconds)
            preview.status:SetText(timer.status)
            if timer.showFallbackNumber then preview.countdownText:SetText(seconds) end
        end
        return
    end
    local uid, profile = preview.uid, preview.profile
    ClearTimer(preview)
    local entry = FSC:RefreshCooldownPreview()
    if not entry or entry.uid ~= uid or preview.profile ~= profile then return end
    if timer.charges then preview.icon.count:SetText("2") end
    if FSC:ShouldFlashOnReady(entry, preview.inCombat) then
        if FSC:PlayCooldownReadyVisual(preview.icon, entry, preview.mode ~= "mana") then
            FSC:RefreshCooldownPreview()
        end
    end
end

local function StartTimer(preview, charges)
    local entry = FSC:RefreshCooldownPreview()
    if not entry then return end
    ClearTimer(preview)
    local icon, start = preview.icon, GetTime()
    FSC:StopReadyFlashEffect(icon)
    FSC:RefreshCooldownPreview()
    if charges then icon.count:SetText("1") end
    local widget = charges and icon.chargeCooldown or icon.cooldown
    local nativeVisual = StartNativeVisual(widget, start)
    preview.timer = {
        charges = charges,
        endsAt = start + TEST_SECONDS,
        showFallbackNumber = not nativeVisual and not charges and (entry.showNumbers or entry.flashOnly),
    }
    preview.countdownText:SetFont(STANDARD_TEXT_FONT, math.max(12, math.floor(entry.size * 0.34)), "OUTLINE")
    UpdateTimer(preview)
    preview.page:SetScript("OnUpdate", function() UpdateTimer(preview) end)
end

function FSC:CreateCooldownPreview(window, page, panel)
    panel(page, FSC:T("NÁHLED IKONY"), 0, 0, 288, 390)
    local sample = CreateFrame("Frame", nil, page)
    sample:SetPoint("TOPLEFT", 14, -37)
    sample:SetSize(260, 232)
    panel(sample, "", 0, 0, 260, 232)
    local stage = CreateFrame("Frame", nil, sample)
    stage:SetSize(1, 1)
    stage:Hide()
    local icon = self:CreateCooldownIconFrame(stage)
    icon:SetPoint("CENTER", stage, "CENTER")
    icon:EnableMouse(false)
    icon.border:SetColorTexture(0.06, 0.06, 0.06, 1)
    self:CreateReadyFlashEffect(icon, stage, function() FSC:RefreshCooldownPreview() end)
    local countdownText = icon:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    countdownText:SetPoint("CENTER")
    local preview = {sample = sample, stage = stage, icon = icon, choices = {}, page = page, countdownText = countdownText}
    window.cooldownPreview = preview

    preview.status = UI.Label(page, "", 16, -280, "GameFontHighlightSmall")
    preview.status:SetSize(254, 40)
    preview.status:SetJustifyV("TOP")
    preview.screenCheck = UI.CheckBox(page, FSC:T("Ukázat v uložené poloze"), 16, -329, function(check)
        preview.onScreen = check:GetChecked() == true
        FSC:RefreshCooldownPreview()
    end)
    panel(page, FSC:T("SIMULACE BOJE"), 300, 0, 370, 156)
    preview.combatCheck = UI.CheckBox(page, FSC:T("Simulovat boj"), 316, -32, function(check)
        preview.inCombat = check:GetChecked() == true
        FSC:RefreshCooldownPreview()
    end)
    for _, item in ipairs({
        {"ready", FSC:T("Připraveno"), 316, -70},
        {"range", FSC:T("Mimo dosah"), 481, -70},
        {"mana", FSC:T("Nedostatek many"), 316, -108},
    }) do
        local mode = item[1]
        preview.choices[mode] = UI.RadioButton(page, item[2], item[3], item[4], function()
            preview.mode = mode
            FSC:RefreshCooldownPreview()
        end)
    end
    panel(page, FSC:T("ODPOČET A PROBLIKNUTÍ"), 300, -168, 370, 222)
    preview.countdownButton = UI.Button(page, FSC:T("Test odpočtu (5 s)"), 316, -205, 167, function()
        StartTimer(preview, false)
    end)
    preview.chargeButton = UI.Button(page, FSC:T("Test nabíjení (5 s)"), 490, -205, 164, function()
        StartTimer(preview, true)
    end)
    preview.flashButton = UI.Button(page, FSC:T("Vyzkoušet probliknutí"), 316, -245, 167, function()
        local entry = FSC:RefreshCooldownPreview()
        if not entry then return end
        if not preview.stage:IsShown() then
            preview.inCombat = true
            FSC:RefreshCooldownPreview()
        end
        if FSC:PlayCooldownReadyVisual(icon, entry, true) then FSC:RefreshCooldownPreview() end
    end)
    preview.resetButton = UI.Button(page, FSC:T("Obnovit náhled"), 490, -245, 164, function()
        FSC:StopCooldownPreview()
        FSC:RefreshCooldownPreview()
    end)
    UI.Label(page, FSC:T("Odpočet a nabíjení se řídí nastavením v záložce Boj a upozornění."),
        316, -292, "GameFontHighlightSmall"):SetWidth(338)
    preview.controls = {preview.screenCheck, preview.combatCheck, preview.countdownButton,
        preview.chargeButton, preview.flashButton, preview.resetButton}
    for _, choice in pairs(preview.choices) do table.insert(preview.controls, choice) end
    window:HookScript("OnHide", function() FSC:StopCooldownPreview() end)
end
