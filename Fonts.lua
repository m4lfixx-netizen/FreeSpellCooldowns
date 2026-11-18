local _, FSC = ...
FSC.fontPath = "Interface\\AddOns\\FreeSpellCooldowns\\Fonts\\NotoSans-Regular.ttf"
local buttonFonts = {}

function FSC:SetCzechFont(text, size)
    if not text then return end
    local _, previousSize, flags = text:GetFont()
    text:SetFont(self.fontPath, size or previousSize or 12, flags or "")
end

function FSC:SetButtonFont(button)
    for _, state in ipairs({ "Normal", "Highlight", "Disabled" }) do
        local font = buttonFonts[state]
        if not font then
            font = CreateFont("FreeSpellCooldownsButton" .. state .. "Font")
            font:CopyFontObject(button["Get" .. state .. "FontObject"](button) or GameFontNormal)
            self:SetCzechFont(font)
            buttonFonts[state] = font
        end
        button["Set" .. state .. "FontObject"](button, font)
    end
    self:SetCzechFont(button:GetFontString())
end

function FSC:GetTooltip()
    if not self.tooltip then
        self.tooltip = CreateFrame("GameTooltip", "FreeSpellCooldownsTooltip", UIParent, "GameTooltipTemplate")
    end
    return self.tooltip
end

function FSC:StyleTooltip()
    for _, region in ipairs({ self:GetTooltip():GetRegions() }) do
        if region:GetObjectType() == "FontString" then self:SetCzechFont(region) end
    end
end

function FSC:HideTooltip()
    if self.tooltip then self.tooltip:Hide() end
end
