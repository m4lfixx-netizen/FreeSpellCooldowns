local _, FSC = ...
local BASE_SIZE = 52
local ART = "Interface\\AddOns\\FreeSpellCooldowns\\Textures\\"
local LIGHTNING = ART .. "Maelstrom.blp"
FSC.buffLightningTexture = LIGHTNING
FSC.buffThemes = {
    lightning = { name = "Blesky", texture = LIGHTNING, top = true },
    fire = { name = "Oheň", texture = ART .. "Fire.blp" },
    frost = { name = "Led", texture = ART .. "Frost.blp" },
    nature = { name = "Příroda", texture = ART .. "Nature.blp" },
    paladin = { name = "Paladin", texture = ART .. "PaladinSwords.blp",
        topTexture = ART .. "PaladinLight.blp", topTextureIsTop = true },
}
FSC.buffThemeOrder = {"lightning", "fire", "frost", "nature", "paladin"}

function FSC:GetBuffThemeTexture(key, style)
    local theme = self.buffThemes[key or "lightning"]
    if style == "top" and theme.topTexture then return theme.topTexture end
    return theme.texture
end

function FSC:IsBuffThemeTopTexture(key, style)
    local theme = self.buffThemes[key or "lightning"]
    if style == "top" and theme.topTexture then return theme.topTextureIsTop end
    return theme.top
end
FSC.buffFrames, FSC.pendingBuffs = {}, {}
local auraAliases = { [408498] = 408505 } -- Forever: passive Maelstrom talent -> actual proc aura.

function FSC:ResolveBuffAuraID(spellID)
    return auraAliases[spellID] or spellID
end

function FSC:BuffSizeLimits(layout)
    if layout.style ~= "icon" then return 64, 512 end
    return 24, 160
end

function FSC:AnchorBuffVisual(region, style, side, anchor, layout)
    region.fscSide = side
    if style == "lightning" then
        local offset = layout and (13 + layout.sideGap * BASE_SIZE / (2 * layout.size)) or 34
        region:SetSize(26, BASE_SIZE); region:SetPoint("CENTER", anchor, "CENTER", side * offset, 0)
    elseif style == "top" then
        region:SetSize(BASE_SIZE, 26); region:SetPoint("CENTER", anchor, "CENTER", 0, 0)
    else region:SetAllPoints(anchor) end
end

function FSC:BuffMotifTexture(layout, stage)
    return self.buffThemes[layout.theme].parts[layout.style == "lightning" and "lightning" or "top"][stage or 5]
end

function FSC:AnchorBuffMotif(region, layout, side, anchor)
    region.fscSide = layout.style == "lightning" and side or 0
    region:ClearAllPoints()
    local sides = layout.style == "lightning"
    local shift = sides and side * (layout.sideGap * BASE_SIZE / layout.size - 42) / 2 or 0
    region:SetPoint("CENTER", anchor, "CENTER", shift, 0)
    region:SetSize(sides and 94 or 52, sides and 52 or 26)
    region:SetTexCoord(0, 1, 0, 1)
    -- Use the same pre-mirrored sprite for full art, pieces, glow and underlay.
    -- StatusBar value updates may replace custom texcoords; baked orientation
    -- keeps the right sword identical in every layer and at every spacing.
    local mask = region.fscSideMask
    if not mask then
        mask = region:GetParent():CreateMaskTexture(nil, "ARTWORK")
        mask:SetTexture("Interface\\Buttons\\WHITE8X8", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        region:AddMaskTexture(mask); region.fscSideMask = mask
    end
    mask:ClearAllPoints()
    mask:SetPoint(sides and (side == 1 and "RIGHT" or "LEFT") or "CENTER", region,
        sides and (side == 1 and "RIGHT" or "LEFT") or "CENTER")
    mask:SetSize(sides and 47 or 52, sides and 52 or 26)
end

function FSC:BuffTextureCoords(texture, style, side, themeKey)
    local topTexture = self:IsBuffThemeTopTexture(themeKey, style)
    if style == "top" and topTexture then texture:SetTexCoord(0, 1, 0, 1)
    elseif style == "top" then texture:SetTexCoord(0, 1, 1, 1, 0, 0, 1, 0)
    elseif style == "lightning" and topTexture then
        if side == 1 then texture:SetTexCoord(1, 1, 0, 1, 1, 0, 0, 0)
        else texture:SetTexCoord(1, 0, 0, 0, 1, 1, 0, 1) end
    elseif style == "lightning" then texture:SetTexCoord(side == 1 and 1 or 0, side == 1 and 0 or 1, 0, 1)
    else texture:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
end

function FSC:AnchorBuffCount(text, style, anchor)
    text:ClearAllPoints()
    if style == "top" then text:SetPoint("TOP", anchor, "CENTER", 0, -16)
    elseif style == "lightning" then text:SetPoint("BOTTOM", anchor, "BOTTOM", 0, 0)
    else text:SetPoint("BOTTOMRIGHT", anchor, "BOTTOMRIGHT", -2, 2) end
    text:SetFont(self.fontPath, style == "icon" and 15 or 8, "OUTLINE")
end

local function Number(value, fallback, low, high)
    value = tonumber(value)
    if not value or value ~= value or value <= -math.huge or value >= math.huge then value = fallback end
    return math.max(low, math.min(high, value))
end

function FSC:FindBuff(uid)
    if not self.storage then return end
    for index, entry in ipairs(self.storage.buffs or {}) do
        if entry.uid == uid then return entry, index end
    end
end

function FSC:BuffLayout(entry, slot)
    slot = slot or self.activeSpec or 1
    entry.layouts = type(entry.layouts) == "table" and entry.layouts or {}
    local layout = entry.layouts[slot]
    if type(layout) ~= "table" then
        local previous = entry.layouts[slot == 1 and 2 or 1] or {}
        layout = {}
        for key, value in pairs(previous) do layout[key] = value end
        entry.layouts[slot] = layout
    end
    layout.x = Number(layout.x, 0, -100000, 100000)
    layout.y = Number(layout.y, 20, -100000, 100000)
    if layout.style ~= "lightning" and layout.style ~= "top" then layout.style = "icon" end
    if not self.buffThemes[layout.theme] then layout.theme = "lightning" end
    local low, high = self:BuffSizeLimits(layout)
    layout.size = Number(layout.size, layout.style ~= "icon" and 240 or BASE_SIZE, low, high)
    if layout.style == "lightning" or layout.sideGap ~= nil then
        layout.sideGap = Number(layout.sideGap, layout.size * 42 / BASE_SIZE, 0, 2000)
    end
    layout.opacity = Number(layout.opacity, 1, 0, 1)
    layout.minStacks = math.floor(Number(layout.minStacks, 1, 1, 40))
    layout.maxStacks = math.floor(Number(layout.maxStacks, math.max(5, layout.minStacks), layout.minStacks, 40))
    layout.progressive = layout.progressive == true
    layout.revealParts = layout.revealParts == true
    if layout.revealParts then layout.progressive = false end
    layout.glowAtMax = layout.glowAtMax == true
    layout.flashAtMax = layout.flashAtMax == true
    layout.pulseAtMax = layout.pulseAtMax == true
    layout.alertIntensity = math.floor(Number(layout.alertIntensity, 80, 0, 100) + 0.5)
    layout.soundEnabled = layout.soundEnabled == true
    layout.soundAtMax = layout.soundAtMax ~= false
    layout.soundStacks = math.floor(Number(layout.soundStacks, layout.maxStacks, 1, 40))
    layout.soundKit = self:GetBuffSound(layout.soundKit).id
    layout.timeFade = layout.timeFade == true
    layout.timeFadeStacks = math.floor(Number(layout.timeFadeStacks, layout.maxStacks, 1, layout.maxStacks))
    layout.showStacks = layout.showStacks ~= false
    layout.showDuration = layout.showDuration ~= false
    layout.combatOnly = layout.combatOnly == true
    return layout
end

function FSC:IsBuffLocked(slot)
    local profiles = self.storage and self.storage.buffProfiles
    local profile = profiles and profiles[slot or self.activeSpec or 1]
    return not profile or profile.locked ~= false
end

function FSC:IsBuffPreview(entry)
    return self.buffOptions and self.buffOptions:IsShown() and not InCombatLockdown()
        and self.db and not self:IsBuffLocked() and (not entry or entry.uid == self.selectedBuffUID)
end

function FSC:FinishBuffPreview()
    if not self.buffsInitialized then return end
    self.storage.buffProfiles[self.activeSpec or 1].locked = true
    self:UpdateAllBuffs()
    self:RefreshBuffOptions()
end

function FSC:SetBuffLocked(locked)
    if not self:CanEdit() then return end
    self:ClearBuffFocus()
    if not locked and not self.db.locked then self:SetLocked(true) end
    self.storage.buffProfiles[self.activeSpec or 1].locked = locked == true
    self:UpdateAllBuffs(); self:RefreshBuffOptions()
    self:Status(locked and FSC:T("Buffy a procy uzamčeny.") or FSC:T("Náhled vybraného buffu odemčen. Přesuň ho za tyrkysový rámeček."))
end

function FSC:StartBuffPreview(entry)
    if not entry or not self:CanEdit() then return end
    self.selectedBuffUID = entry.uid
    self.buffPreviewStacks = self:BuffLayout(entry).maxStacks
    self.buffPreviewRemaining = 1
    self:SetBuffLocked(false)
    self:MoveOptionsAsideForBuff(entry)
end

function FSC:MoveOptionsAsideForBuff(entry)
    local panel, frame = self.buffOptions, self.buffFrames[entry.uid]
    if not panel or not frame then return end
    local left, top = panel:GetLeft(), panel:GetTop()
    if not left or not top then return end
    local scale = panel:GetEffectiveScale() / UIParent:GetEffectiveScale()
    local width, height = panel:GetWidth() * scale, panel:GetHeight() * scale
    local layout = self:BuffLayout(entry)
    local x, y = UIParent:GetWidth() / 2 + layout.x, UIParent:GetHeight() / 2 + layout.y
    local halfW, halfH = frame:GetWidth() / 2 + 8, frame:GetHeight() / 2 + 22
    local function Overlap(px, py)
        return math.max(0, math.min(px + width, x + halfW) - math.max(px, x - halfW))
            * math.max(0, math.min(py, y + halfH) - math.max(py - height, y - halfH))
    end
    local best = Overlap(left * scale, top * scale)
    if best == 0 then return end
    local bx, by
    for _, px in ipairs({ UIParent:GetWidth() - width - 16, 16 }) do
        for _, py in ipairs({ UIParent:GetHeight() - 16, height + 16 }) do
            local area = Overlap(px, py)
            if area < best then best, bx, by = area, px, py end
        end
    end
    if bx then
        panel:ClearAllPoints(); panel:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", bx / scale, by / scale)
    end
end

function FSC:BuffInfo(identifier)
    local text = tostring(identifier or ""):match("^%s*(.-)%s*$")
    identifier = tonumber(text:match("spell:(%d+)") or text) or text
    local info = C_Spell.GetSpellInfo(identifier)
    local resolved = self:ResolveBuffAuraID(type(identifier) == "number" and identifier or (info and info.spellID))
    if resolved and resolved ~= (type(identifier) == "number" and identifier or (info and info.spellID)) then
        return C_Spell.GetSpellInfo(resolved), resolved
    end
    if not info and type(identifier) == "string" and C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
        local ok, aura = pcall(C_UnitAuras.GetAuraDataBySpellName, "player", identifier, "HELPFUL")
        if ok and not (issecretvalue and issecretvalue(aura)) and type(aura) == "table" then
            local id = aura.spellId
            if not (issecretvalue and issecretvalue(id)) and type(id) == "number" then
                info = C_Spell.GetSpellInfo(id)
            end
        end
    end
    return info, identifier
end

function FSC:AddBuff(identifier, fromLoad)
    if not self:CanEdit() then return false end
    if self.ClearBuffFocus then self:ClearBuffFocus() end
    local info, requested = self:BuffInfo(identifier)
    if not info then
        if type(requested) == "number" and requested > 0 and not fromLoad and C_Spell.RequestLoadSpellData then
            self.pendingBuffs[requested] = true
            C_Spell.RequestLoadSpellData(requested)
            self:Status(FSC:T("Načítám údaje o buffu…"))
        else self:Status(FSC:T("Buff nenalezen. Zadej název aktivního buffu nebo jeho aura spell ID."), true) end
        return false
    end
    for _, entry in ipairs(self.storage.buffs) do
        if entry.spellID == info.spellID then
            self.selectedBuffUID = entry.uid
            self:UpdateAllBuffs()
            self:RefreshBuffOptions()
            self:Status(FSC:T("Tento buff už sleduješ: ") .. entry.name)
            return true
        end
    end
    -- Known passive talents resolve to their proc aura; all other selected IDs stay exact.
    local entry = { uid = self.storage.buffNextUID, spellID = type(requested) == "number" and requested or info.spellID,
        name = info.name, iconID = info.iconID, specs = { [self.activeSpec or 1] = true }, layouts = {} }
    self.storage.buffNextUID = entry.uid + 1
    local layout = self:BuffLayout(entry)
    layout.x = -120 + (#self.storage.buffs % 5) * 64
    table.insert(self.storage.buffs, entry)
    self.selectedBuffUID = entry.uid
    self:CreateBuffFrame(entry)
    self:UpdateAllBuffs()
    self:RefreshBuffOptions()
    self:Status(FSC:T("Přidán buff: ") .. entry.name .. FSC:T(". Odemkni ikony pro náhled a přesun."))
    return true
end

function FSC:AddMaelstromPreset(fromLoad)
    -- Forever's proc aura, not the passive talent or the Wrath aura (53817).
    if not self:AddBuff(408505, fromLoad) then
        self.pendingMaelstromPreset = self.pendingBuffs[408505] == true
        return false
    end
    self.pendingMaelstromPreset = nil
    local entry = self:FindBuff(self.selectedBuffUID)
    entry.specs[self.activeSpec or 1] = true
    local layout = self:BuffLayout(entry)
    layout.style, layout.theme, layout.size, layout.x, layout.y = "lightning", "lightning", 240, 0, 0
    layout.minStacks, layout.maxStacks = 1, 5
    layout.progressive, layout.glowAtMax = true, true
    layout.showStacks, layout.showDuration = true, false
    self.buffPreviewStacks = 5
    self:ApplyBuff(entry); self:RefreshBuffOptions()
    self:Status(FSC:T("Maelstrom Weapon: elektrické oblouky sílí od 1 do 5 stacků. Při 5 září naplno."))
    return true
end

local function EnableGroup(group, enabled)
    if group.enabled == enabled then return end
    group.enabled = enabled
    for _, container in ipairs(group.containers) do
        container:SetEnabled(enabled)
        container:SetShown(enabled)
    end
end

function FSC:RemoveBuff(uid)
    if not self:CanEdit() then return end
    if self.ClearBuffFocus then self:ClearBuffFocus() end
    local entry, index = self:FindBuff(uid)
    if not entry then return end
    local frame = self.buffFrames[uid]
    if frame then
        frame:StopMovingOrSizing()
        for _, cached in pairs(frame.containers) do EnableGroup(cached, false) end
        frame:Hide(); frame:EnableMouse(false)
        self.buffFrames[uid] = nil
    end
    table.remove(self.storage.buffs, index)
    self.selectedBuffUID = self.storage.buffs[1] and self.storage.buffs[1].uid
    self:UpdateAllBuffs()
    self:RefreshBuffOptions()
    self:Status(FSC:T("Odebrán buff: ") .. entry.name)
end

function FSC:SetBuffSpec(entry, slot, enabled)
    if not self:CanEdit() or (slot ~= 1 and slot ~= 2) then return end
    entry.specs[slot] = enabled == true
    self:BuffLayout(entry, slot)
    self:ApplyBuff(entry)
    self:RefreshBuffOptions()
end

local function CountFormatter(minimum)
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then return end
    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    formatter:AddBreakpoint({ threshold = 0, format = "" })
    formatter:AddBreakpoint({ threshold = minimum, format = "%d" })
    return formatter
end

function FSC:BuildBuffContainer(entry, layout, frame)
    if not self.buffAuraSupported then return end
    local parts = self:GetBuffStackMode(layout) == "parts"
    if parts and not self.buffPartsSupported then
        frame.nativeError = FSC:T("Klient nepodporuje zobrazení motivu po částech. Vyber Celý motiv nebo Zesilování.")
        return
    end
    if not parts and (layout.minStacks > 1 or layout.progressive or layout.glowAtMax) and not self.buffThresholdSupported then
        frame.nativeError = FSC:T("Klient nepodporuje pravidla stacků. Vypni zesilování a záři, práh nastav na 1.")
        return
    end
    local slot = self.activeSpec or 1
    local candidates, ids = {[entry.spellID] = true}, {entry.spellID}
    for id, enabled in pairs(entry.auraIDs or {}) do
        if enabled == true and type(id) == "number" and id > 0 and id ~= entry.spellID then
            candidates[id] = true; ids[#ids + 1] = id
        end
    end
    table.sort(ids)
    local signature = table.concat({table.concat(ids, ","), layout.style, layout.theme, layout.minStacks, layout.maxStacks,
        layout.progressive and 1 or 0, parts and 1 or 0, layout.glowAtMax and 1 or 0,
        layout.showStacks and 1 or 0, layout.showDuration and 1 or 0,
        layout.flashAtMax and 1 or 0, layout.pulseAtMax and 1 or 0, layout.timeFade and 1 or 0,
        layout.timeFadeStacks, layout.style == "lightning" and layout.sideGap or 0,
        layout.style == "lightning" and layout.size or 0}, ":")
    local cached = frame.containers[slot]
    if cached and cached.signature == signature then return cached end
    if InCombatLockdown() and not self.loadingBuffs then return end
    if cached then EnableGroup(cached, false) end
    local group = { containers = {}, signature = signature }
    frame.containers[slot] = group
    local minimum, maximum = layout.minStacks, layout.maxStacks
    local overlay = layout.style ~= "icon"
    local style = layout.style
    local themeKey, asset = layout.theme, self:BuffMotifTexture(layout)
    local timed = layout.timeFade and self.buffTimeFadeSupported and self.buffThresholdSupported
    local timeMinimum = math.max(minimum, layout.timeFadeStacks)
    frame.nativeError = nil
    if timed then group.timeGate = self:CreateBuffTimeGate(layout, group, frame, candidates) end
    local function Layer(threshold, alpha, side, glow, textOnly, partsOnly, pieceTexture, alertMode, timeFloor, beforeTime)
        if timed and group.timeGate and not textOnly and not partsOnly and not timeFloor and not beforeTime and not alertMode and not glow then
            Layer(threshold, alpha, side, glow, textOnly, partsOnly, pieceTexture, alertMode, timeFloor, true)
        end
        if timed and not textOnly and not partsOnly and not timeFloor and not beforeTime and timeMinimum > 1 then
            threshold = math.max(threshold or 1, timeMinimum)
        end
        -- A separate container for each layer avoids duplicate-aura suppression in slots.
        local parent = timeFloor and frame.timeUnderlay or (alertMode and frame.alertDisplay or frame.display)
        local container = CreateFrame("AuraContainer", nil, parent, "CustomAuraContainerTemplate")
        container:SetPoint("TOPLEFT", parent, "TOPLEFT")
        container:SetAlpha(alpha)
        container:SetUnit("player")
        table.insert(group.containers, container)
        local countFormatter = textOnly and layout.showStacks and CountFormatter(minimum)
        local ok, err = pcall(container.AddAuraSlot, container, "buff", "HELPFUL", {
            candidateFilters = { includeSpellIDs = candidates },
            initializeFrame = function(button)
            -- Aura-button descendants are configured ONLY in this native creation callback.
            -- After it returns we never query their aura state or change their layout.
                button:ClearAllPoints(); button:SetAllPoints(parent)
                button:SetFrameLevel(parent:GetFrameLevel() + (textOnly and 15 or 2))
                if button.SetMouseClickEnabled then button:SetMouseClickEnabled(false) end
                if button.EnableMouseMotion then button:EnableMouseMotion(false) end
                if button.SetHideTooltipInCombat then button:SetHideTooltipInCombat(true) end
                if pieceTexture then
                    local bar = CreateFrame("StatusBar", nil, button)
                    bar:SetStatusBarTexture(pieceTexture)
                    local texture = bar:GetStatusBarTexture()
                    FSC:AnchorBuffMotif(texture, layout, side, button)
                    -- The bar gates the whole sprite; the texture's own anchors
                    -- are managed by it after SetApplicationBar.
                    bar:ClearAllPoints(); bar:SetPoint("CENTER", button, "CENTER",
                        style == "lightning" and side * (layout.sideGap * BASE_SIZE / layout.size - 42) / 2 or 0, 0)
                    bar:SetSize(style == "lightning" and 94 or 52, style == "lightning" and 52 or 26)
                    if beforeTime then FSC:BindBuffBeforeTimeGate(texture, group.timeGate)
                    else FSC:BindBuffTimeFade(button, layout, texture) end
                    local options = {minApplications = threshold - 1, maxApplications = threshold}
                    if Enum.StatusBarInterpolation then options.interpolation = Enum.StatusBarInterpolation.Immediate end
                    button:SetApplicationBar(bar, options)
                    return
                end
                if partsOnly then
                    local picture = button:CreateFontString(nil, "OVERLAY")
                    picture:SetFont(FSC.fontPath, 12, "")
                    FSC:AnchorBuffVisual(picture, style, side, button, layout)
                    picture:SetJustifyH("CENTER"); picture:SetJustifyV("MIDDLE")
                    button:SetApplicationCount(picture, {formatter = FSC:BuffPartsFormatter(layout, side)})
                    return
                end
                if textOnly then
                    if layout.showDuration and minimum == 1 and not overlay then
                        local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
                        cooldown:SetAllPoints(button)
                        cooldown:EnableMouse(false)
                        cooldown:SetHideCountdownNumbers(false)
                        if layout.timeFade and FSC.buffTimeFadeSupported then
                            cooldown:SetDrawSwipe(false); cooldown:SetDrawEdge(false)
                        end
                        button:SetDurationCooldown(cooldown)
                    end
                    if layout.showStacks and (countFormatter or minimum == 1) then
                        local text = button:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
                        FSC:AnchorBuffCount(text, style, button)
                        button:SetApplicationCount(text, { formatter = countFormatter })
                    end
                    return
                end
                local region
                if threshold then
                    local bar = CreateFrame("StatusBar", nil, button)
                    if overlay then
                        bar:SetPoint("CENTER", button, "CENTER", style == "lightning"
                            and side * (layout.sideGap * BASE_SIZE / layout.size - 42) / 2 or 0, 0)
                        bar:SetSize(style == "lightning" and 94 or 52, style == "lightning" and 52 or 26)
                    else FSC:AnchorBuffVisual(bar, style, side, button, layout) end
                    bar:SetStatusBarTexture(overlay and asset or entry.iconID or 134400)
                    region = bar:GetStatusBarTexture()
                    if not overlay then button:SetIcon(region) end
                    -- Integer stacks produce zero fill below N and full fill at N or above.
                    -- Counts stay within the native renderer, including during combat.
                    local options = { minApplications = threshold - 1, maxApplications = threshold }
                    if Enum.StatusBarInterpolation then options.interpolation = Enum.StatusBarInterpolation.Immediate end
                    button:SetApplicationBar(bar, options)
                else
                    region = button:CreateTexture(nil, "ARTWORK")
                    if not overlay then FSC:AnchorBuffVisual(region, style, side, button, layout) end
                    if overlay then
                        region:SetTexture(asset)
                    else button:SetIcon(region) end
                end
                if overlay then FSC:AnchorBuffMotif(region, layout, side, button)
                else FSC:BuffTextureCoords(region, style, side, themeKey) end
                if timeFloor then
                    region:SetDesaturated(true); region:SetVertexColor(0.9, 0.9, 0.9, 1)
                elseif beforeTime then FSC:BindBuffBeforeTimeGate(region, group.timeGate)
                else FSC:BindBuffTimeFade(button, layout, region) end
                if glow then region:SetBlendMode("ADD") end
                if alertMode then
                    -- Animate the always-present aura owner, not the threshold
                    -- bar which can be hidden at lower stacks. Blizzard starts
                    -- and stops the clock with the aura; the bar gates its art.
                    local animation = FSC:CreateBuffAlertAnimation(button, alertMode)
                    if button.AddAuraShownAnimation then button:AddAuraShownAnimation(animation)
                    else animation:Play() end
                end
            end,
        })
        if not ok then frame.nativeError = FSC:T("Buff se nepodařilo vykreslit: ") .. tostring(err); group.failed = true end
    end
    local function Visual(threshold, alpha, glow, timeFloor)
        if style == "lightning" then
            Layer(threshold, alpha, -1, glow, nil, nil, nil, nil, timeFloor)
            Layer(threshold, alpha, 1, glow, nil, nil, nil, nil, timeFloor)
        else Layer(threshold, alpha, 0, glow, nil, nil, nil, nil, timeFloor) end
    end
    if timed then
        Visual(timeMinimum > 1 and timeMinimum or nil, 1, false, true)
    end
    if parts then
        if self.buffThresholdSupported then
            for stage = 1, 5 do
                for _, side in ipairs(style == "lightning" and {-1, 1} or {0}) do
                    Layer(self:BuffPartThreshold(layout, stage), 1, side, false, false, false, self:BuffPieceTexture(layout, stage))
                end
            end
        else
            for _, side in ipairs(style == "lightning" and {-1, 1} or {0}) do
                Layer(nil, 1, side, false, false, true)
            end
        end
    elseif layout.progressive then
        local previous = 0
        for count = minimum, maximum do
            local target = count / maximum
            Visual(count, (target - previous) / (1 - previous), false)
            previous = target
        end
    else Visual(minimum > 1 and minimum or nil, 1, false) end
    if layout.glowAtMax and self.buffThresholdSupported then Visual(maximum, 0.45, true)
    elseif layout.glowAtMax and parts then frame.nativeError = FSC:T("Postupné části fungují; dodatečnou záři tento klient nepodporuje.") end
    if layout.flashAtMax or layout.pulseAtMax then
        if self.buffThresholdSupported then
            -- Non-stacking procs may report applications=0. Their aura button's
            -- own presence is the gate when the configured maximum is one.
            local alertThreshold = maximum > 1 and maximum or nil
            for _, mode in ipairs({"flash", "pulse"}) do
                if layout[mode == "flash" and "flashAtMax" or "pulseAtMax"] then
                    Layer(alertThreshold, 1, style == "lightning" and -1 or 0, true, false, false, nil, mode)
                    if style == "lightning" then Layer(alertThreshold, 1, 1, true, false, false, nil, mode) end
                end
            end
        else frame.nativeError = FSC:T("Tento klient nepodporuje blikání ani pulzování při maximu. Běžný motiv funguje dál.") end
    end
    if layout.showStacks or (layout.showDuration and minimum == 1 and not overlay) then Layer(nil, 1, 0, false, true) end
    if group.failed then EnableGroup(group, false); return end
    return group
end

function FSC:ApplyBuff(entry)
    local frame = self.buffFrames[entry.uid]
    if not frame then return end
    if frame.dragging and not self:IsBuffPreview(entry) then self:SaveBuffPosition(entry, frame) end
    local layout = self:BuffLayout(entry)
    local width = layout.style == "lightning" and (layout.size + layout.sideGap) or layout.size
    local halfWidth = math.max(0, (UIParent:GetWidth() - width) / 2 - 2)
    local height = layout.size * (layout.style == "top" and 0.5 or 1)
    local halfHeight = math.max(0, (UIParent:GetHeight() - height) / 2 - 18)
    layout.x, layout.y = self:Clamp(layout.x, -halfWidth, halfWidth), self:Clamp(layout.y, -halfHeight, halfHeight)
    frame:SetSize(width, height)
    frame.display:SetScale(layout.size / BASE_SIZE)
    frame:SetAlpha(1)
    frame.display:SetAlpha(layout.opacity)
    frame.timeUnderlay:SetScale(layout.size / BASE_SIZE)
    frame.timeUnderlay:SetAlpha(layout.opacity * 0.45)
    self:SyncBuffTimePreview(frame, layout)
    frame.alertDisplay:SetScale(layout.size / BASE_SIZE)
    frame.alertDisplay:SetAlpha(layout.alertIntensity / 100)
    frame.ghost:SetScale(layout.size / BASE_SIZE)
    frame:ClearAllPoints(); frame:SetPoint("CENTER", UIParent, "CENTER", layout.x, layout.y)
    local count = self:Clamp(self.buffPreviewStacks or layout.maxStacks, 1, layout.maxStacks)
    local qualifies = count >= layout.minStacks
    local strength = layout.progressive and count / layout.maxStacks or 1
    local overlay = layout.style ~= "icon"
    local parts = self:GetBuffStackMode(layout) == "parts"
    frame.previewIcon:SetTexture(entry.iconID or 134400)
    frame.previewIcon:SetShown(not overlay and qualifies); frame.previewIcon:SetAlpha(strength)
    frame.previewArcs:SetShown(overlay and qualifies and not parts); frame.previewArcs:SetAlpha(strength)
    frame.previewPieces:SetShown(parts and qualifies)
    frame.previewPiecesRight:SetShown(parts and qualifies and layout.style == "lightning")
    if parts and qualifies then
        frame.previewPieces:SetTexture(self:BuffPartTexture(layout, self:BuffPreviewPart(layout, count)))
        self:AnchorBuffMotif(frame.previewPieces, layout, -1, frame.display)
        frame.previewPiecesRight:SetTexture(self:BuffPartTexture(layout, self:BuffPreviewPart(layout, count)))
        self:AnchorBuffMotif(frame.previewPiecesRight, layout, 1, frame.display)
    end
    for index, texture in ipairs(frame.previewArcs.regions) do
        texture:SetTexture(self:BuffMotifTexture(layout))
        self:AnchorBuffMotif(texture, layout, index == 1 and -1 or 1, frame.display)
        texture:SetShown(layout.style == "lightning" or index == 1)
    end
    frame.previewGlow:SetShown(qualifies and layout.glowAtMax and count >= layout.maxStacks)
    for index, texture in ipairs(frame.previewGlow.regions) do
        texture:SetTexture(overlay and self:BuffMotifTexture(layout) or entry.iconID or 134400)
        texture:ClearAllPoints()
        if overlay then self:AnchorBuffMotif(texture, layout, index == 1 and -1 or 1, frame.display)
        else self:AnchorBuffVisual(texture, layout.style, 0, frame.display); self:BuffTextureCoords(texture, layout.style, 0, layout.theme) end
        texture:SetShown(layout.style == "lightning" or index == 1)
    end
    self:AnchorBuffCount(frame.previewCount, layout.style, frame.display)
    frame.previewCount:SetText(qualifies and layout.showStacks and tostring(count) or "")
    local preview = self:IsBuffPreview(entry)
    self:SyncBuffAlertPreview(entry, frame, layout, count, preview)
    -- A separate, constant-opacity silhouette keeps the selected motif visible
    -- even when its real opacity is zero or the preview stack rule is not met.
    frame.ghost:SetShown(preview)
    frame.ghost.icon:SetTexture(entry.iconID or 134400)
    frame.ghost.icon:SetShown(layout.style == "icon")
    for index, texture in ipairs(frame.ghost.arcs) do
        texture:SetTexture(self:BuffMotifTexture(layout))
        self:AnchorBuffMotif(texture, layout, index == 1 and -1 or 1, frame.ghost)
        texture:SetShown(layout.style == "lightning" or (layout.style == "top" and index == 1))
    end
    local assigned = entry.specs[self.activeSpec or 1] == true
    local visible = preview or (assigned and (not layout.combatOnly or InCombatLockdown()))
    frame:SetFrameStrata(preview and "TOOLTIP" or "MEDIUM")
    frame.previewTitle:SetText(FSC:T("NÁHLED: ") .. entry.name .. (not assigned and FSC:T(" (v tomto specu vypnuto)") or ""))
    frame:SetShown(visible)
    frame.preview:SetShown(preview and visible)
    frame.previewLabel:SetShown(preview and visible)
    frame:EnableMouse(preview and visible)
    frame:EnableMouseWheel(preview and visible)
    local group = self:BuildBuffContainer(entry, layout, frame)
    for _, cached in pairs(frame.containers) do
        EnableGroup(cached, cached == group and visible and not preview and not cached.failed)
    end
end

function FSC:SaveBuffPosition(entry, frame)
    frame:StopMovingOrSizing(); frame.dragging = nil
    local x, y = frame:GetCenter(); local originX, originY = UIParent:GetCenter()
    if x and originX then
        local scale = frame:GetEffectiveScale() / UIParent:GetEffectiveScale()
        local layout = self:BuffLayout(entry)
        layout.x, layout.y = math.floor(x * scale - originX + 0.5), math.floor(y * scale - originY + 0.5)
    end
end

function FSC:UpdateAllBuffs()
    if not self.buffsInitialized then return end
    for _, entry in ipairs(self.storage.buffs) do
        if not self.buffFrames[entry.uid] then self:CreateBuffFrame(entry)
        else self:ApplyBuff(entry) end
    end
end

function FSC:CreateBuffFrame(entry)
    local frame = CreateFrame("Button", nil, UIParent)
    self.buffFrames[entry.uid] = frame
    frame.containers = {}
    frame:SetFrameStrata("MEDIUM"); frame:SetMovable(true); frame:SetClampedToScreen(true)
    frame:RegisterForDrag("LeftButton"); frame:RegisterForClicks("RightButtonUp")
    frame.ghost = CreateFrame("Frame", nil, frame)
    frame.ghost:SetPoint("CENTER", frame, "CENTER"); frame.ghost:SetSize(BASE_SIZE, BASE_SIZE)
    frame.ghost:SetFrameLevel(frame:GetFrameLevel() + 1)
    frame.ghost:EnableMouse(false); frame.ghost:SetAlpha(0.45)
    frame.ghost.icon = frame.ghost:CreateTexture(nil, "ARTWORK")
    frame.ghost.icon:SetAllPoints(frame.ghost); frame.ghost.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.ghost.icon:SetDesaturated(true); frame.ghost.icon:SetVertexColor(0.9, 0.9, 0.9, 1)
    frame.ghost.arcs = {}
    for index = 1, 2 do
        local texture = frame.ghost:CreateTexture(nil, "ARTWORK")
        texture:SetDesaturated(true); texture:SetVertexColor(0.9, 0.9, 0.9, 1)
        frame.ghost.arcs[index] = texture
    end
    frame.display = CreateFrame("Frame", nil, frame)
    frame.timeUnderlay = CreateFrame("Frame", nil, frame)
    frame.timeUnderlay:SetPoint("CENTER", frame, "CENTER"); frame.timeUnderlay:SetSize(BASE_SIZE, BASE_SIZE)
    frame.timeUnderlay:SetFrameLevel(frame:GetFrameLevel() + 1); frame.timeUnderlay:EnableMouse(false)
    frame.alertDisplay = CreateFrame("Frame", nil, frame)
    frame.alertDisplay:SetPoint("CENTER", frame, "CENTER"); frame.alertDisplay:SetSize(BASE_SIZE, BASE_SIZE)
    frame.alertDisplay:SetFrameLevel(frame:GetFrameLevel() + 10); frame.alertDisplay:EnableMouse(false)
    self:CreateBuffAlertPreview(frame)
    frame.display:SetFrameLevel(frame:GetFrameLevel() + 2)
    frame.display:SetPoint("CENTER", frame, "CENTER"); frame.display:SetSize(BASE_SIZE, BASE_SIZE)
    frame.preview = CreateFrame("Frame", nil, frame.display)
    frame.preview:SetAllPoints(frame.display); frame.preview:EnableMouse(false)
    frame.previewIcon = frame.preview:CreateTexture(nil, "ARTWORK")
    frame.previewIcon:SetAllPoints(frame.display); frame.previewIcon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    frame.previewPieces = frame.preview:CreateTexture(nil, "ARTWORK")
    frame.previewPiecesRight = frame.preview:CreateTexture(nil, "ARTWORK")
    frame.previewArcs = CreateFrame("Frame", nil, frame.preview); frame.previewArcs:SetAllPoints(frame.display)
    frame.previewArcs.regions = {}
    for _, side in ipairs({-1, 1}) do
        local texture = frame.previewArcs:CreateTexture(nil, "ARTWORK")
        texture:SetTexture(LIGHTNING); texture:SetSize(26, BASE_SIZE)
        texture:SetPoint("CENTER", frame.display, "CENTER", side * 34, 0)
        texture:SetTexCoord(side == 1 and 1 or 0, side == 1 and 0 or 1, 0, 1)
        table.insert(frame.previewArcs.regions, texture)
    end
    frame.previewGlow = CreateFrame("Frame", nil, frame.preview)
    frame.previewGlow:SetAllPoints(frame.display); frame.previewGlow:SetAlpha(0.45); frame.previewGlow.regions = {}
    for index = 1, 2 do
        local texture = frame.previewGlow:CreateTexture(nil, "OVERLAY")
        texture:SetBlendMode("ADD"); frame.previewGlow.regions[index] = texture
    end
    frame.previewCount = frame.preview:CreateFontString(nil, "OVERLAY", "NumberFontNormalLarge")
    self:CreateBuffTimePreview(frame)
    frame.previewLabel = CreateFrame("Frame", nil, frame)
    frame.previewLabel:SetAllPoints(frame); frame.previewLabel:EnableMouse(false)
    local label = frame.previewLabel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    frame.previewTitle = label
    self:SetCzechFont(label); label:SetPoint("BOTTOM", frame, "TOP", 0, 3)
    for _, edge in ipairs({"TOP", "BOTTOM", "LEFT", "RIGHT"}) do
        local line = frame.previewLabel:CreateTexture(nil, "OVERLAY")
        line:SetColorTexture(0.2, 1, 0.9, 0.9)
        if edge == "TOP" or edge == "BOTTOM" then
            line:SetPoint(edge .. "LEFT", frame, edge .. "LEFT", 0, 0)
            line:SetPoint(edge .. "RIGHT", frame, edge .. "RIGHT", 0, 0); line:SetHeight(1)
        else
            line:SetPoint("TOP" .. edge, frame, "TOP" .. edge, 0, 0)
            line:SetPoint("BOTTOM" .. edge, frame, "BOTTOM" .. edge, 0, 0); line:SetWidth(1)
        end
    end
    frame:SetScript("OnDragStart", function()
        if FSC:IsBuffPreview(entry) then frame.dragging = true; frame:StartMoving() end
    end)
    frame:SetScript("OnDragStop", function()
        FSC:SaveBuffPosition(entry, frame)
        FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
    end)
    frame:SetScript("OnMouseWheel", function(_, delta)
        if FSC:IsBuffPreview(entry) and IsShiftKeyDown() then
            local layout = FSC:BuffLayout(entry); local low, high = FSC:BuffSizeLimits(layout)
            layout.size = FSC:Clamp(layout.size + delta * 2, low, high)
            FSC:ApplyBuff(entry); FSC:RefreshBuffOptions()
        end
    end)
    frame:SetScript("OnClick", function() if FSC:CanEdit() then FSC:OpenBuffOptions(entry.uid) end end)
    self:ApplyBuff(entry)
end

function FSC:InitializeBuffs()
    local separateLocks = type(self.storage.buffProfiles) == "table"
    self.storage.buffProfiles = type(self.storage.buffProfiles) == "table" and self.storage.buffProfiles or {}
    for slot = 1, 2 do
        local previous = self.storage.buffProfiles[slot]
        self.storage.buffProfiles[slot] = { locked = type(previous) ~= "table" or previous.locked ~= false }
    end
    self.storage.buffs = type(self.storage.buffs) == "table" and self.storage.buffs or {}
    self.storage.buffNextUID = math.max(1, tonumber(self.storage.buffNextUID) or 1)
    if C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, "Blizzard_AuraContainer") end
    local ok, probe = pcall(CreateFrame, "AuraContainer", nil, UIParent, "CustomAuraContainerTemplate")
    self.buffAuraSupported = ok and probe and type(probe.AddAuraSlot) == "function" or false
    if ok and probe then probe:Hide() end
    self.buffThresholdSupported = false
    if C_AuraContainerUtil and C_AuraContainerUtil.ProcessCustomAuraButtonApplicationBarOptions then
        local readable, options = pcall(C_AuraContainerUtil.ProcessCustomAuraButtonApplicationBarOptions,
            { minApplications = 2, maxApplications = 3 })
        self.buffThresholdSupported = readable and type(options) == "table" and options.minApplications == 2
    end
    self.buffPartsSupported = self:SupportsBuffParts()
    self.buffTimeFadeSupported = self.buffAuraSupported and Enum.StatusBarFillStyle
        and Enum.StatusBarFillStyle.Center ~= nil and Enum.StatusBarTimerDirection
        and Enum.StatusBarTimerDirection.RemainingTime ~= nil or false
    local clean, used = {}, {}
    for _, entry in ipairs(self.storage.buffs) do
        if type(entry) == "table" and type(entry.spellID) == "number" and entry.spellID > 0 then
            entry.spellID = self:ResolveBuffAuraID(entry.spellID)
            entry.uid = math.floor(Number(entry.uid, self.storage.buffNextUID, 1, 100000000))
            if used[entry.uid] then entry.uid = self.storage.buffNextUID end
            used[entry.uid] = true; self.storage.buffNextUID = math.max(self.storage.buffNextUID, entry.uid + 1)
            entry.specs = type(entry.specs) == "table" and entry.specs or { [self.activeSpec or 1] = true }
            entry.specs[1], entry.specs[2] = entry.specs[1] == true, entry.specs[2] == true
            if type(entry.auraIDs) == "table" then
                local ids = {}
                for id, enabled in pairs(entry.auraIDs) do
                    if enabled == true and type(id) == "number" and id > 0 and id == math.floor(id) then
                        ids[self:ResolveBuffAuraID(id)] = true
                    end
                end
                entry.auraIDs = ids
            else entry.auraIDs = nil end
            local info = C_Spell.GetSpellInfo(entry.spellID)
            entry.name = info and info.name or entry.name or ("Buff " .. entry.spellID)
            entry.iconID = info and info.iconID or entry.iconID or 134400
            self:BuffLayout(entry, 1); self:BuffLayout(entry, 2)
            table.insert(clean, entry)
        end
    end
    self.storage.buffs = clean
    self.buffsInitialized = true
    if not separateLocks and self.storage.optionsTab == "buffs" and not self.db.locked then self:SetLocked(true) end
    self.loadingBuffs = true
    self:UpdateAllBuffs()
    self.loadingBuffs = nil
end

local updateInteraction = FSC.UpdateInteraction
function FSC:UpdateInteraction()
    updateInteraction(self)
    self:UpdateAllBuffs()
end
local checkTalents = FSC.CheckTalentProfile
function FSC:CheckTalentProfile()
    if self.buffsInitialized then
        for _, entry in ipairs(self.storage.buffs) do
            local frame = self.buffFrames[entry.uid]
            if frame and frame.dragging then self:SaveBuffPosition(entry, frame) end
        end
    end
    local previousSlot = self.activeSpec
    local changed = checkTalents(self)
    if changed then
        if self.storage.buffProfiles[previousSlot] then self.storage.buffProfiles[previousSlot].locked = true end
        self:FinishBuffPreview()
        if self.buffOptions and self.buffOptions:IsShown() and not self.db.locked then self:SetLocked(true) end
    end
    return changed
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "DISPLAY_SIZE_CHANGED",
    "UI_SCALE_CHANGED", "SPELL_DATA_LOAD_RESULT" }) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, id, success)
    if not FSC.buffsInitialized then return end
    if event == "PLAYER_REGEN_DISABLED" then
        if FSC.buffOptions then FSC.buffOptions:Hide() end
    elseif event == "SPELL_DATA_LOAD_RESULT" and FSC.pendingBuffs[id] and not InCombatLockdown() then
        FSC.pendingBuffs[id] = nil
        if success then
            if id == 408505 and FSC.pendingMaelstromPreset then FSC:AddMaelstromPreset(true)
            else FSC:AddBuff(id, true) end
        else FSC.pendingMaelstromPreset = nil; FSC:Status(FSC:T("Údaje o buffu se nepodařilo načíst."), true) end
    elseif event == "PLAYER_REGEN_ENABLED" then
        local pending = FSC.pendingBuffs; FSC.pendingBuffs = {}
        for spellID in pairs(pending) do
            if spellID == 408505 and FSC.pendingMaelstromPreset then FSC:AddMaelstromPreset(true)
            else FSC:AddBuff(spellID, true) end
        end
    end
    FSC:UpdateAllBuffs()
end)
