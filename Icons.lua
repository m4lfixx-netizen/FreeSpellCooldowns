local _, FSC = ...

local function SetDuration(cooldown, duration)
    -- The opaque duration object goes straight to Blizzard's renderer.
    -- Never compare, format, subtract, or otherwise inspect restricted times.
    if duration then
        cooldown:SetCooldownFromDurationObject(duration, true)
    else
        cooldown:Clear()
    end
    cooldown.fscUpdating = false
end

local function StyleCountdown(cooldown, size)
    if cooldown.GetCountdownFontString then
        local text = cooldown:GetCountdownFontString()
        if text then
            text:SetFont(STANDARD_TEXT_FONT, math.max(12, math.floor(size * 0.34)), "OUTLINE")
        end
    end
end

function FSC:UpdateCooldown(entry)
    local frame = self.frames[entry.uid]
    if not frame then return end
    local id = entry.activeSpellID or entry.spellID
    for _, cooldown in ipairs({ frame.cooldown, frame.chargeCooldown }) do
        -- Suppress callbacks only while binding a different spell/spec. A normal
        -- refresh may clear an expired timer before its own OnUpdate runs.
        cooldown.fscUpdating = cooldown.fscProfileKey ~= self.activeProfileKey or cooldown.fscSpellID ~= id
        cooldown.fscProfileKey, cooldown.fscSpellID = self.activeProfileKey, id
    end
    -- ignoreGCD=true is supported by Forever's modern spell API.
    SetDuration(frame.cooldown, C_Spell.GetSpellCooldownDuration(id, true))
    if C_Spell.GetSpellChargeDuration then
        SetDuration(frame.chargeCooldown, C_Spell.GetSpellChargeDuration(id))
    end
    -- Display strings can also be restricted: pass straight into SetText.
    if C_Spell.GetSpellDisplayCount then
        frame.count:SetText(C_Spell.GetSpellDisplayCount(id, 99, "*"))
    end
end

function FSC:UpdateAllCooldowns()
    for _, entry in ipairs(self.db.icons) do
        self:UpdateCooldown(entry)
        self:UpdateRange(entry)
    end
end

function FSC:GetCooldownIconVisibility(entry, inCombat)
    local drawIcon = not entry.flashOnly and (not entry.combatOnly or inCombat)
    local trackCooldown = drawIcon or entry.flashOnly or (entry.flashReady and entry.flashOutsideCombat)
    return trackCooldown, drawIcon
end

function FSC:SetCooldownIconDrawing(frame, entry, drawIcon)
    -- A transparent frame keeps receiving native cooldown completion events.
    -- The alert has its own frame, so its opacity is independent of this icon.
    frame.fscDrawIcon = drawIcon
    frame:SetAlpha(drawIcon and (entry.opacity or 1) or 0)
end

function FSC:ApplyVisibility(entry)
    local frame = self.frames[entry.uid]
    if not frame then return end
    local trackCooldown, drawIcon = self:GetCooldownIconVisibility(entry, self.inCombat)
    local assigned = self:IsEntryAssigned(entry)
    local editable = not self.db.locked and not self.inCombat
    drawIcon = assigned and (drawIcon or (editable and entry.flashOnly))
    self:SetCooldownIconDrawing(frame, entry, drawIcon)
    frame:SetShown(assigned and trackCooldown)
    frame:EnableMouse(editable and drawIcon)
    frame:EnableMouseWheel(editable and drawIcon)
end

function FSC:SavePosition(entry)
    local frame = self.frames[entry.uid]
    if not frame then return end
    frame:StopMovingOrSizing()
    local x, y = frame:GetCenter()
    local ux, uy = UIParent:GetCenter()
    if x and y and ux and uy then
        local ratio = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        entry.x = math.floor(x * ratio - ux + 0.5)
        entry.y = math.floor(y * ratio - uy + 0.5)
    end
    self:ApplyIcon(entry)
end

function FSC:UpdateInteraction()
    local editable = not self.db.locked and not self.inCombat
    for _, entry in ipairs(self.db.icons) do
        local frame = self.frames[entry.uid]
        if frame then
            if not editable then self:SavePosition(entry) end
            frame.border:SetColorTexture(editable and 0.2 or 0.06,
                editable and 0.85 or 0.06, editable and 0.8 or 0.06, 1)
            self:ApplyVisibility(entry)
            self:SyncReadyFlash(entry)
            self:UpdateRange(entry)
        end
    end
end

function FSC:ApplyIconAppearance(frame, entry)
    frame:SetSize(entry.size, entry.size)
    frame.texture:SetTexture(entry.iconID or 134400)
    frame.manaTexture:SetTexture(entry.iconID or 134400)
    frame.label:SetText(entry.name)
    frame.label:SetWidth(math.max(110, entry.size * 2.5))
    frame.label:SetShown(entry.showName)
    frame.cooldown:SetHideCountdownNumbers(not entry.showNumbers)
    StyleCountdown(frame.cooldown, entry.size)
    frame.count:SetFont(STANDARD_TEXT_FONT, math.max(10, math.floor(entry.size * 0.24)), "OUTLINE")
end

function FSC:ApplyIcon(entry)
    local frame = self.frames[entry.uid]
    if not frame then return end
    local halfWidth = math.max(0, (UIParent:GetWidth() - entry.size) / 2 - 2)
    local halfHeight = math.max(0, (UIParent:GetHeight() - entry.size) / 2 - 18)
    entry.x = self:Clamp(entry.x, -halfWidth, halfWidth)
    entry.y = self:Clamp(entry.y, -halfHeight, halfHeight)
    self:ApplyIconAppearance(frame, entry)
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", entry.x, entry.y)
    self:ApplyVisibility(entry)
    self:SyncReadyFlash(entry)
    self:SaveEntrySettings(entry)
    self:UpdateRange(entry)
end

function FSC:ClampIconSize(size)
    return self:Clamp(math.floor(size + 0.5), 24, 160)
end

function FSC:ResizeIcon(entry, size)
    if not self:CanEdit() then return end
    size = self:ClampIconSize(size)
    if entry.size == size then return end
    entry.size = size
    self:ApplyIcon(entry)
    self:RefreshOptions()
end

function FSC:CreateCooldownIconFrame(parent)
    local frame = CreateFrame("Button", nil, parent)
    frame.border = frame:CreateTexture(nil, "BACKGROUND")
    frame.border:SetPoint("TOPLEFT", -2, 2)
    frame.border:SetPoint("BOTTOMRIGHT", 2, -2)
    frame.texture = frame:CreateTexture(nil, "ARTWORK")
    frame.texture:SetAllPoints()
    frame.texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    -- Separate alpha masks compose mana tint with range without branching on
    -- restricted combat booleans. The range mask keeps red out-of-range priority.
    frame.manaLayer = CreateFrame("Frame", nil, frame)
    frame.manaLayer:SetAllPoints()
    frame.manaLayer:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.manaLayer:EnableMouse(false)
    frame.manaTexture = frame.manaLayer:CreateTexture(nil, "ARTWORK")
    frame.manaTexture:SetAllPoints()
    frame.manaTexture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.manaTexture:SetVertexColor(1, 1, 1, 0)

    frame.cooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.cooldown:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.cooldown:SetAllPoints()
    frame.cooldown:EnableMouse(false)
    frame.cooldown:SetDrawEdge(false)
    frame.cooldown:SetSwipeColor(0, 0, 0, 0.75)
    if frame.cooldown.SetMinimumCountdownDuration then
        frame.cooldown:SetMinimumCountdownDuration(0)
    end

    frame.chargeCooldown = CreateFrame("Cooldown", nil, frame, "CooldownFrameTemplate")
    frame.chargeCooldown:SetFrameLevel(frame:GetFrameLevel() + 3)
    frame.chargeCooldown:SetAllPoints()
    frame.chargeCooldown:EnableMouse(false)
    frame.chargeCooldown:SetDrawSwipe(false)
    frame.chargeCooldown:SetDrawEdge(true)
    frame.chargeCooldown:SetHideCountdownNumbers(true)

    -- Text is above both native cooldown widgets.
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(frame.chargeCooldown:GetFrameLevel() + 2)
    overlay:EnableMouse(false)
    frame.count = overlay:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    frame.count:SetPoint("BOTTOMRIGHT", -2, 2)
    frame.label = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    self:SetCzechFont(frame.label)
    frame.label:SetPoint("TOP", frame, "BOTTOM", 0, -4)
    frame.label:SetTextColor(1, 1, 1)
    return frame
end

function FSC:CreateIcon(entry)
    local frame = self:CreateCooldownIconFrame(UIParent)
    self.frames[entry.uid] = frame
    frame:SetFrameStrata("MEDIUM")
    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton")
    frame:RegisterForClicks("RightButtonUp")
    self:CreateReadyFlash(entry)

    frame:SetScript("OnDragStart", function()
        if not FSC.db.locked and not InCombatLockdown() then
            frame:StartMoving()
        end
    end)
    frame:SetScript("OnDragStop", function()
        FSC:SavePosition(entry)
        FSC:RefreshOptions()
    end)
    frame:SetScript("OnClick", function(_, button)
        if button == "RightButton" and not FSC.db.locked then
            FSC:OpenOptions(entry.uid)
        end
    end)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if not FSC.db.locked and IsShiftKeyDown() then
            FSC:ResizeIcon(entry, entry.size + delta * 2)
        end
    end)
    frame:SetScript("OnEnter", function()
        if FSC.db.locked or InCombatLockdown() then return end
        local tooltip = FSC:GetTooltip()
        tooltip:SetOwner(frame, "ANCHOR_RIGHT")
        tooltip:SetSpellByID(entry.activeSpellID or entry.spellID)
        tooltip:AddLine(FSC:T("Přetáhni: pozice  |  Shift + kolečko: velikost"), 0.4, 0.9, 0.85)
        tooltip:AddLine(FSC:T("Pravé tlačítko: nastavení této ikony"), 0.4, 0.9, 0.85)
        FSC:StyleTooltip()
        tooltip:Show()
    end)
    frame:SetScript("OnLeave", function() FSC:HideTooltip() end)
    self:ApplyIcon(entry)
    self:UpdateInteraction()
    self:UpdateCooldown(entry)
end
