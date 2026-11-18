local _, FSC = ...

-- Configured once, before the native aura button adopts its descendants.
-- The native application bar gates the effect at the configured maximum;
-- animation clocks never read, infer, or publish the aura's stack count.
function FSC:CreateBuffAlertAnimation(region, mode)
    region:SetAlpha(0)
    local group = region:CreateAnimationGroup()
    group:SetLooping("REPEAT")
    local steps = mode == "flash" and {
        {0, 1, 0.06}, {1, 0, 0.14}, {0, 0, 0.08},
        {0, 1, 0.06}, {1, 0, 0.22}, {0, 0, 0.70},
    } or { {0.08, 0.85, 0.55}, {0.85, 0.08, 0.55} }
    for order, step in ipairs(steps) do
        local alpha = group:CreateAnimation("Alpha")
        alpha:SetOrder(order); alpha:SetFromAlpha(step[1]); alpha:SetToAlpha(step[2]); alpha:SetDuration(step[3])
    end
    return group
end

function FSC:CreateBuffAlertPreview(frame)
    frame.alertPreview = CreateFrame("Frame", nil, frame.alertDisplay)
    frame.alertPreview:SetAllPoints(frame.alertDisplay); frame.alertPreview:EnableMouse(false)
    frame.alertPreview:Hide()
    frame.alertPreview.effects = {}
    for _, mode in ipairs({"flash", "pulse"}) do
        local effect = CreateFrame("Frame", nil, frame.alertPreview)
        effect:SetAllPoints(frame.alertDisplay); effect:EnableMouse(false)
        effect.regions, effect.animations = {}, {}
        for index = 1, 2 do
            local texture = effect:CreateTexture(nil, "ARTWORK")
            texture:SetBlendMode("ADD")
            effect.regions[index] = texture
            effect.animations[index] = self:CreateBuffAlertAnimation(texture, mode)
        end
        frame.alertPreview.effects[mode] = effect
    end
end

function FSC:SyncBuffAlertPreview(entry, frame, layout, count, preview)
    local visible = preview and count >= layout.minStacks and count >= layout.maxStacks
    frame.alertPreview:SetShown(visible)
    for _, mode in ipairs({"flash", "pulse"}) do
        local effect = frame.alertPreview.effects[mode]
        local enabled = visible and layout[mode == "flash" and "flashAtMax" or "pulseAtMax"] and layout.alertIntensity > 0
        effect:SetShown(enabled)
        for index, texture in ipairs(effect.regions) do
            local used = layout.style == "lightning" or index == 1
            texture:SetTexture(layout.style == "icon" and (entry.iconID or 134400) or self:BuffMotifTexture(layout))
            texture:ClearAllPoints()
            if layout.style == "icon" then
                self:AnchorBuffVisual(texture, layout.style, 0, frame.alertDisplay)
                self:BuffTextureCoords(texture, layout.style, 0, layout.theme)
            else self:AnchorBuffMotif(texture, layout, index == 1 and -1 or 1, frame.alertDisplay) end
            texture:SetShown(used)
            local animation = effect.animations[index]
            if enabled and used then
                if not animation:IsPlaying() then animation:Play() end
            else animation:Stop(); texture:SetAlpha(0) end
        end
    end
end
