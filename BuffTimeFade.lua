local _, FSC = ...
local WHITE = "Interface\\Buttons\\WHITE8X8"
local MASK = "Interface\\AddOns\\FreeSpellCooldowns\\Textures\\TimeFeather.tga"

local function Place(bar, layout, owner)
    bar:ClearAllPoints(); bar:SetPoint("CENTER", owner, "CENTER")
    bar:SetSize(layout.style == "lightning" and (52 + layout.sideGap * 52 / layout.size) or 52,
        layout.style == "top" and 26 or 52)
end

local function Mask(region, fill)
    local mask = region:GetParent():CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture(MASK, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(fill)
    region:AddMaskTexture(mask)
end

function FSC:BindBuffTimeFade(button, layout, region)
    if not layout.timeFade or not self.buffTimeFadeSupported or not self.buffThresholdSupported then return end
    local bar = CreateFrame("StatusBar", nil, button)
    Place(bar, layout, button)
    bar:SetOrientation("HORIZONTAL"); bar:SetFillStyle(Enum.StatusBarFillStyle.Center)
    bar:SetStatusBarTexture(WHITE); bar:SetAlpha(0)
    Mask(region, bar:GetStatusBarTexture())
    button:SetDurationBar(bar, {direction = Enum.StatusBarTimerDirection.RemainingTime,
        interpolation = Enum.StatusBarInterpolation.Immediate})
end

function FSC:CreateBuffTimePreview(frame)
    if not self.buffTimeFadeSupported then return end
    local bar = CreateFrame("StatusBar", nil, frame)
    frame.timePreview = bar
    bar:SetStatusBarTexture(WHITE); bar:SetFillStyle(Enum.StatusBarFillStyle.Center)
    bar:SetMinMaxValues(0, 1); bar:SetValue(1); bar:SetAlpha(0)
    local fill = bar:GetStatusBarTexture()
    Mask(frame.previewIcon, fill); Mask(frame.previewPieces, fill); Mask(frame.previewPiecesRight, fill)
    for _, region in ipairs(frame.previewArcs.regions) do Mask(region, fill) end
    for _, region in ipairs(frame.previewGlow.regions) do Mask(region, fill) end
    for _, effect in pairs(frame.alertPreview.effects) do
        for _, region in ipairs(effect.regions) do Mask(region, fill) end
    end
end

function FSC:SyncBuffTimePreview(frame, layout)
    if not frame.timePreview then return end
    Place(frame.timePreview, layout, frame)
    frame.timePreview:SetScale(layout.size / 52)
    local count = self:Clamp(self.buffPreviewStacks or layout.maxStacks, 1, layout.maxStacks)
    local active = layout.timeFade and self.buffThresholdSupported and count >= layout.timeFadeStacks
    frame.timePreview:SetValue(active and self:Clamp(self.buffPreviewRemaining or 1, 0, 1) or 1)
end

-- Native geometry supplies the upper gate. This uses actual textures below
-- the time threshold, rather than texture escape sequences in secret text.
-- The fill is full at N and empty below N; the mask spans its empty remainder.
-- No aura counts or protected widget properties are queried after creation.
function FSC:CreateBuffTimeGate(layout, group, frame, candidates)
    local stop = math.max(layout.minStacks, layout.timeFadeStacks)
    if stop <= 1 then return end
    local container = CreateFrame("AuraContainer", nil, frame.display, "CustomAuraContainerTemplate")
    container:SetPoint("TOPLEFT", frame.display, "TOPLEFT"); container:SetAlpha(0); container:SetUnit("player")
    table.insert(group.containers, container)
    local gate
    local ok, err = pcall(container.AddAuraSlot, container, "buff", "HELPFUL", {
        candidateFilters = {includeSpellIDs = candidates},
        initializeFrame = function(button)
            button:ClearAllPoints(); button:SetAllPoints(frame.display)
            if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
            if button.EnableMouseMotion then button:EnableMouseMotion(false) end
            local bar = CreateFrame("StatusBar", nil, button)
            Place(bar, layout, button); bar:SetOrientation("HORIZONTAL"); bar:SetStatusBarTexture(WHITE)
            gate = {bar = bar, fill = bar:GetStatusBarTexture()}
            button:SetApplicationBar(bar, {minApplications = stop - 1, maxApplications = stop,
                interpolation = Enum.StatusBarInterpolation.Immediate})
        end,
    })
    if not ok then frame.nativeError = "Časový práh se nepodařilo připravit: " .. tostring(err); group.failed = true end
    return gate
end

function FSC:BindBuffBeforeTimeGate(region, gate)
    if not gate then return end
    local mask = region:GetParent():CreateMaskTexture(nil, "ARTWORK")
    mask:SetTexture(WHITE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetPoint("TOPLEFT", gate.fill, "TOPRIGHT", 0, 0)
    mask:SetPoint("BOTTOMRIGHT", gate.bar, "BOTTOMRIGHT", 0, 0)
    mask.fscInverseBar = gate.bar
    region:AddMaskTexture(mask)
end
