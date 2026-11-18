local _, FSC = ...
local ART = "Interface\\AddOns\\FreeSpellCooldowns\\Textures\\Parts\\"

for key, name in pairs({lightning = "Maelstrom", fire = "Fire", frost = "Frost", nature = "Nature", paladin = "Paladin"}) do
    local stages = { top = {}, lightning = {} }
    for step = 1, 5 do
        stages.top[step] = ART .. name .. "Top" .. step .. ".tga"
        stages.lightning[step] = ART .. name .. "Sides" .. step .. ".tga"
    end
    FSC.buffThemes[key].parts = stages
    local pieces = {top = {}, lightning = {}}
    for step = 1, 5 do
        pieces.top[step] = ART .. name .. "TopPiece" .. step .. ".tga"
        pieces.lightning[step] = ART .. name .. "SidesPiece" .. step .. ".tga"
    end
    FSC.buffThemes[key].pieces = pieces
end

function FSC:GetBuffStackMode(layout)
    if not layout then return "full" end
    if layout.revealParts and layout.style ~= "icon" and layout.maxStacks >= 2 then return "parts" end
    return layout.progressive and "opacity" or "full"
end

function FSC:BuffPartThreshold(layout, stage)
    return math.max(layout.minStacks, 1 + math.ceil((layout.maxStacks - 1) * (stage - 1) / 4))
end

function FSC:BuffPreviewPart(layout, count)
    -- Only the user-selected preview count is evaluated in Lua. Real aura counts
    -- are consumed by native application bars or a formatter, never by this function.
    local result = 0
    for stage = 1, 5 do if count >= self:BuffPartThreshold(layout, stage) then result = stage end end
    return result
end

function FSC:BuffPartTexture(layout, stage)
    return self.buffThemes[layout.theme].parts[layout.style][stage]
end

function FSC:BuffPieceTexture(layout, stage)
    return self.buffThemes[layout.theme].pieces[layout.style][stage]
end

function FSC:AnchorBuffParts(region, style, anchor)
    region:ClearAllPoints(); region:SetPoint("CENTER", anchor, "CENTER")
    region:SetSize(style == "lightning" and 94 or 52, style == "lightning" and 52 or 26)
end

function FSC:BuffPartTag(layout, stage, side)
    if layout.style == "lightning" and side and side ~= 0 then
        return "|T" .. self:BuffPartTexture(layout, stage) .. ":52:26:0:0:512:256:"
            .. (side == 1 and "370:512" or "0:142") .. ":0:256|t"
    end
    local height, width = layout.style == "lightning" and 52 or 26, layout.style == "lightning" and 94 or 52
    return "|T" .. self:BuffPartTexture(layout, stage) .. ":" .. height .. ":" .. width .. ":0:0|t"
end

function FSC:BuffPartsFormatter(layout, side)
    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    formatter:AddBreakpoint({threshold = 0, format = ""})
    local thresholds, sorted = {}, {}
    for stage = 1, 5 do thresholds[self:BuffPartThreshold(layout, stage)] = stage end
    for value in pairs(thresholds) do sorted[#sorted + 1] = value end
    table.sort(sorted)
    for _, value in ipairs(sorted) do
        formatter:AddBreakpoint({threshold = value, format = self:BuffPartTag(layout, thresholds[value], side)})
    end
    return formatter
end

function FSC:SupportsBuffParts()
    if self.buffThresholdSupported then return true end
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then return false end
    local ok, valid = pcall(function()
        local layout = {style = "top", theme = "lightning", minStacks = 1, maxStacks = 5}
        local formatter = self:BuffPartsFormatter(layout)
        return formatter:FormatNumber(0) == "" and formatter:FormatNumber(1) == self:BuffPartTag(layout, 1)
            and formatter:FormatNumber(5) == self:BuffPartTag(layout, 5)
    end)
    return ok and valid == true
end
