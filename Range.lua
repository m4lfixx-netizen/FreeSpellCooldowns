local _, FSC = ...
local normal = CreateColor(1, 1, 1, 1)
local outside = CreateColor(1, 0.15, 0.15, 0.45)
local noMana = CreateColor(0.5, 0.5, 1, 1)
local transparent = CreateColor(0.5, 0.5, 1, 0)

local function DisplayBoolean(value)
    return (issecretvalue and issecretvalue(value)) or type(value) == "boolean"
end

function FSC:PaintIconAvailability(frame, inRange, insufficientPower)
    local hasRange = DisplayBoolean(inRange)
    if hasRange then
        frame.texture:SetVertexColorFromBoolean(inRange, normal, outside)
    else
        frame.texture:SetVertexColor(1, 1, 1, 1)
    end

    -- Reset the separate mana layer even when the API is unavailable or the
    -- option is turned off, so a prior blue tint can never stick.
    frame.manaTexture:SetVertexColor(1, 1, 1, 0)
    frame.manaLayer:SetAlpha(1)
    if not DisplayBoolean(insufficientPower) then return end
    frame.manaTexture:SetVertexColorFromBoolean(insufficientPower, noMana, transparent)
    if hasRange then
        -- These are two independent native masks: insufficient power chooses
        -- the blue texture's alpha, range chooses its parent's alpha.
        frame.manaLayer:SetAlphaFromBoolean(inRange, 1, 0)
    end
end

function FSC:UpdateRange(entry)
    local frame = self.frames[entry.uid]
    if not frame then return end
    local id = entry.activeSpellID or entry.spellID
    local inRange, insufficientPower
    if C_Spell.IsSpellInRange then
        local ok, value = pcall(C_Spell.IsSpellInRange, id, "target")
        if ok then inRange = value end
    end
    if entry.manaTint and C_Spell.IsSpellUsable then
        local ok, _, value = pcall(C_Spell.IsSpellUsable, id)
        if ok then insufficientPower = value end
    end
    self:PaintIconAvailability(frame, inRange, insufficientPower)
end

function FSC:UpdateAllRanges()
    if not self.db then return end
    for _, entry in ipairs(self.db.icons) do
        local frame = self.frames[entry.uid]
        if frame and frame:IsShown() then self:UpdateRange(entry) end
    end
end

local timer, elapsed = CreateFrame("Frame"), 0
timer:RegisterEvent("PLAYER_TARGET_CHANGED")
timer:RegisterEvent("SPELL_UPDATE_USABLE")
timer:RegisterUnitEvent("UNIT_POWER_UPDATE", "player")
timer:RegisterUnitEvent("UNIT_MAXPOWER", "player")
timer:RegisterUnitEvent("UNIT_DISPLAYPOWER", "player")
timer:SetScript("OnEvent", function() FSC:UpdateAllRanges() end)
timer:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 0.15 then
        elapsed = 0
        FSC:UpdateAllRanges()
    end
end)
