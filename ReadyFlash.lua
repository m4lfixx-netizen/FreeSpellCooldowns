local _, FSC = ...

local readyColor = CreateColor(1, 0.9, 0.45, 1)
local hiddenColor = CreateColor(1, 0.9, 0.45, 0)

function FSC:GetFlashIntensity(entry)
    local value = tonumber(entry.flashIntensity)
    if not value or value ~= value or value <= -math.huge or value >= math.huge then value = 80 end
    return self:Clamp(math.floor(value + 0.5), 0, 100)
end

function FSC:StopReadyFlash(entry, suppressRestore)
    local frame = self.frames[entry.uid]
    local flash = frame and frame.readyFlash
    if not flash then return end
    local preview = flash.preview
    flash.preview = nil
    flash.animation:Stop()
    flash:Hide()
    flash:SetAlpha(0)
    frame.readyFlashStrength.previewIcon:Hide()
    frame.readyFlashStrength:SetFrameStrata("MEDIUM")
    if preview then
        frame:SetAlpha(entry.opacity or 1)
        if not suppressRestore then self:ApplyVisibility(entry) end
    end
end

function FSC:StopAllReadyFlashes()
    if not self.db then return end
    for _, entry in ipairs(self.db.icons) do self:StopReadyFlash(entry) end
end

function FSC:SyncReadyFlash(entry)
    local frame = self.frames[entry.uid]
    local flash = frame and frame.readyFlash
    if frame and frame.readyFlashStrength then
        frame.readyFlashStrength:SetAlpha(self:GetFlashIntensity(entry) / 100)
    end
    if flash and not flash.preview and (not entry.flashReady or not InCombatLockdown()
        or not self:IsEntryAssigned(entry)) then self:StopReadyFlash(entry) end
end

local function SetUsabilityColor(entry, flash, preview)
    local ok, usable
    if not preview and C_Spell.IsSpellUsable then
        ok, usable = pcall(C_Spell.IsSpellUsable, entry.activeSpellID or entry.spellID)
    end
    local nativeBoolean = ok and ((issecretvalue and issecretvalue(usable)) or type(usable) == "boolean")
    for _, texture in ipairs(flash.regions) do
        if nativeBoolean then
            -- The renderer can consume even a restricted boolean. Never branch on its value.
            texture:SetVertexColorFromBoolean(usable, readyColor, hiddenColor)
        else
            texture:SetVertexColor(1, 0.9, 0.45, 1)
        end
    end
end

function FSC:PlayReadyFlash(entry, preview)
    local frame = entry and self.frames[entry.uid]
    local flash = frame and frame.readyFlash
    if not flash then return false end
    local intensity = self:GetFlashIntensity(entry)
    if intensity == 0 then return false end
    if not preview and (not entry.flashReady or not InCombatLockdown()
        or not self:IsEntryAssigned(entry) or not frame:IsShown()) then return false end
    local now = GetTime()
    if not preview and frame.lastReadyFlashAt and now - frame.lastReadyFlashAt < 0.2 then return false end
    self:StopReadyFlash(entry)
    frame.readyFlashStrength:SetAlpha(intensity / 100)
    flash.preview = preview == true
    if preview then
        frame.readyFlashStrength:SetFrameStrata("TOOLTIP")
        frame.readyFlashStrength.previewIcon:SetTexture(entry.iconID or 134400)
        frame.readyFlashStrength.previewIcon:Show()
        frame:SetAlpha(1)
        frame:Show()
    else frame.lastReadyFlashAt = now end
    SetUsabilityColor(entry, flash, preview)
    flash:SetAlpha(0)
    flash:Show()
    flash.animation:Play()
    return true
end

function FSC:OnCooldownReady(entry, cooldown)
    if cooldown.fscUpdating or cooldown.fscProfileKey ~= self.activeProfileKey
        or cooldown.fscSpellID ~= (entry.activeSpellID or entry.spellID)
        or not InCombatLockdown() or not entry.flashReady or not self:IsEntryAssigned(entry) then return end
    local frame, profile, spellID = self.frames[entry.uid], self.activeProfileKey, cooldown.fscSpellID
    if not frame or not frame:IsShown() then return end
    -- Let spell usability settle after the native timer finishes. Do not read cooldown times.
    C_Timer.After(0, function()
        if self.frames[entry.uid] == frame and self.activeProfileKey == profile
            and (entry.activeSpellID or entry.spellID) == spellID then self:PlayReadyFlash(entry) end
    end)
end

function FSC:CreateReadyFlash(entry)
    local frame = self.frames[entry.uid]
    -- Keep notification strength independent of the icon's configured opacity.
    local strength = CreateFrame("Frame", nil, UIParent)
    frame.readyFlashStrength = strength
    strength:SetAllPoints(frame)
    strength:SetFrameStrata("MEDIUM")
    strength:SetFrameLevel(frame:GetFrameLevel() + 6)
    strength:EnableMouse(false)
    strength:SetAlpha(self:GetFlashIntensity(entry) / 100)
    strength.previewIcon = strength:CreateTexture(nil, "BACKGROUND")
    strength.previewIcon:SetAllPoints()
    strength.previewIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    strength.previewIcon:Hide()
    local flash = CreateFrame("Frame", nil, strength)
    frame.readyFlash = flash
    flash:SetAllPoints(frame)
    flash:EnableMouse(false)
    flash:SetAlpha(0)
    flash:Hide()
    flash.regions = {}
    local fill = flash:CreateTexture(nil, "ARTWORK")
    fill:SetAllPoints()
    fill:SetColorTexture(1, 1, 1, 0.65)
    table.insert(flash.regions, fill)
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = flash:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(1, 1, 1, 1)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetPoint(edge .. "LEFT", -2, edge == "TOP" and 2 or -2)
            line:SetPoint(edge .. "RIGHT", 2, edge == "TOP" and 2 or -2)
            line:SetHeight(3)
        else
            line:SetPoint("TOP" .. edge, edge == "LEFT" and -2 or 2, 2)
            line:SetPoint("BOTTOM" .. edge, edge == "LEFT" and -2 or 2, -2)
            line:SetWidth(3)
        end
        table.insert(flash.regions, line)
    end
    local animation = flash:CreateAnimationGroup()
    flash.animation = animation
    for order, step in ipairs({ {0, 1, 0.08}, {1, 0.05, 0.20}, {0.05, 0.9, 0.08}, {0.9, 0, 0.34} }) do
        local alpha = animation:CreateAnimation("Alpha")
        alpha:SetOrder(order)
        alpha:SetFromAlpha(step[1])
        alpha:SetToAlpha(step[2])
        alpha:SetDuration(step[3])
    end
    animation:SetScript("OnFinished", function() FSC:StopReadyFlash(entry) end)
    local function Done(cooldown) FSC:OnCooldownReady(entry, cooldown) end
    frame.cooldown:SetScript("OnCooldownDone", Done)
    frame.chargeCooldown:SetScript("OnCooldownDone", Done)
    frame:SetScript("OnHide", function() FSC:StopReadyFlash(entry, true) end)
end

