local _, FSC = ...

local readyColor = CreateColor(1, 0.9, 0.45, 1)
local hiddenColor = CreateColor(1, 0.9, 0.45, 0)
local iconColor = CreateColor(1, 1, 1, 1)
local hiddenIconColor = CreateColor(1, 1, 1, 0)

function FSC:ShouldFlashOnReady(entry, inCombat)
    return (entry.flashReady or entry.flashOnly) and (inCombat or entry.flashOutsideCombat)
end

function FSC:GetFlashIntensity(entry)
    local value = tonumber(entry.flashIntensity)
    if not value or value ~= value or value <= -math.huge or value >= math.huge then value = 80 end
    return self:Clamp(math.floor(value + 0.5), 0, 100)
end

function FSC:StopReadyFlashEffect(frame)
    local flash = frame.readyFlash
    if not flash then return end
    flash.animation:Stop()
    flash:Hide()
    flash:SetAlpha(0)
end

function FSC:StopReadyFlash(entry)
    local frame = self.frames[entry.uid]
    if frame then self:StopReadyFlashEffect(frame) end
end

function FSC:StopAllReadyFlashes()
    if not self.db then return end
    for _, entry in ipairs(self.db.icons) do self:StopReadyFlash(entry) end
end

function FSC:SyncReadyFlash(entry)
    local frame = self.frames[entry.uid]
    local flash = frame and frame.readyFlash
    if flash then flash.glow:SetAlpha(self:GetFlashIntensity(entry) / 100) end
    if flash and (not self:ShouldFlashOnReady(entry, self.inCombat)
        or not self:IsEntryAssigned(entry)) then self:StopReadyFlash(entry) end
end

local function SetUsabilityColor(flash, usable)
    local nativeBoolean = (issecretvalue and issecretvalue(usable)) or type(usable) == "boolean"
    for _, texture in ipairs(flash.regions) do
        if nativeBoolean then
            -- The renderer can consume even a restricted boolean. Never branch on its value.
            texture:SetVertexColorFromBoolean(usable, readyColor, hiddenColor)
        else
            texture:SetVertexColor(1, 0.9, 0.45, 1)
        end
    end
end

function FSC:PlayCooldownReadyVisual(frame, entry, usable)
    local intensity = self:GetFlashIntensity(entry)
    if intensity == 0 then return false end
    local iconTexture
    if entry.flashOnly or not frame.fscDrawIcon then iconTexture = entry.iconID or 134400 end
    if entry.flashOnly then usable = nil end
    self:StopReadyFlashEffect(frame)
    local flash = frame.readyFlash
    flash.glow:SetAlpha(intensity / 100)
    flash.icon:SetShown(iconTexture ~= nil)
    if iconTexture then
        flash.icon:SetTexture(iconTexture)
        flash.icon:SetAlpha(entry.opacity or 1)
        if (issecretvalue and issecretvalue(usable)) or type(usable) == "boolean" then
            flash.icon:SetVertexColorFromBoolean(usable, iconColor, hiddenIconColor)
        else
            flash.icon:SetVertexColor(1, 1, 1, 1)
        end
    end
    flash.fill:SetColorTexture(1, 1, 1, iconTexture and 0.28 or 0.65)
    SetUsabilityColor(flash, usable)
    flash:Show()
    flash.animation:Play()
    return true
end

function FSC:PlayReadyFlash(entry)
    local frame = entry and self.frames[entry.uid]
    if not frame or not frame.readyFlash or not self:ShouldFlashOnReady(entry, self.inCombat)
        or not self:IsEntryAssigned(entry) or not frame:IsShown() then return false end
    local intensity = self:GetFlashIntensity(entry)
    if intensity == 0 then return false end
    local now = GetTime()
    if frame.lastReadyFlashAt and now - frame.lastReadyFlashAt < 0.2 then return false end
    frame.lastReadyFlashAt = now
    local usable
    if not entry.flashOnly and C_Spell.IsSpellUsable then
        local ok, value = pcall(C_Spell.IsSpellUsable, entry.activeSpellID or entry.spellID)
        if ok then usable = value end
    end
    return self:PlayCooldownReadyVisual(frame, entry, usable)
end

function FSC:OnCooldownReady(entry, cooldown)
    if cooldown.fscUpdating or cooldown.fscProfileKey ~= self.activeProfileKey
        or cooldown.fscSpellID ~= (entry.activeSpellID or entry.spellID)
        or not self:ShouldFlashOnReady(entry, self.inCombat) or not self:IsEntryAssigned(entry) then return end
    local frame, profile, spellID = self.frames[entry.uid], self.activeProfileKey, cooldown.fscSpellID
    if not frame or not frame:IsShown() then return end
    -- Let spell usability settle after the native timer finishes. Do not read cooldown times.
    C_Timer.After(0, function()
        if self.frames[entry.uid] == frame and self.activeProfileKey == profile
            and (entry.activeSpellID or entry.spellID) == spellID then self:PlayReadyFlash(entry) end
    end)
end

function FSC:CreateReadyFlashEffect(frame, parent, onFinished)
    -- The flash is a sibling of the tracked icon so it can show when that icon is hidden.
    local layer = CreateFrame("Frame", nil, parent)
    frame.readyFlashLayer = layer
    layer:SetAllPoints(frame)
    layer:SetFrameStrata(frame:GetFrameStrata())
    layer:SetFrameLevel(frame:GetFrameLevel() + 6)
    layer:EnableMouse(false)
    local flash = CreateFrame("Frame", nil, layer)
    frame.readyFlash = flash
    flash:SetAllPoints(frame)
    flash:EnableMouse(false)
    flash:SetAlpha(0)
    flash:Hide()
    flash.regions = {}
    flash.icon = flash:CreateTexture(nil, "BACKGROUND")
    flash.icon:SetAllPoints()
    flash.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    flash.icon:Hide()
    flash.glow = CreateFrame("Frame", nil, flash)
    flash.glow:SetAllPoints()
    flash.glow:EnableMouse(false)
    flash.fill = flash.glow:CreateTexture(nil, "ARTWORK")
    flash.fill:SetAllPoints()
    table.insert(flash.regions, flash.fill)
    for _, edge in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local line = flash.glow:CreateTexture(nil, "OVERLAY")
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
    animation:SetScript("OnFinished", function()
        self:StopReadyFlashEffect(frame)
        if onFinished then onFinished() end
    end)
end

function FSC:CreateReadyFlash(entry)
    local frame = self.frames[entry.uid]
    self:CreateReadyFlashEffect(frame, UIParent)
    local function Done(cooldown) FSC:OnCooldownReady(entry, cooldown) end
    frame.cooldown:SetScript("OnCooldownDone", Done)
    frame.chargeCooldown:SetScript("OnCooldownDone", Done)
    frame:SetScript("OnHide", function() FSC:StopReadyFlash(entry) end)
end

