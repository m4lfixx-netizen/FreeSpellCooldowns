local _, FSC = ...
local UI = FSC.UI

-- Starter auras, not talent/casting IDs. Names/icons come from this client.
-- The player's own observed buffs extend this list, including custom Forever IDs.
local seeds = {
    SHAMAN = {
        { ids = {408505}, stacks = 5 }, -- Forever Maelstrom Weapon
        { ids = {16246}, stacks = 2 }, -- Elemental Focus / Clearcasting
        { ids = {16188} }, -- Nature's Swiftness
        { ids = {408510}, stacks = 3 }, -- Forever Water Shield
        { ids = {425336} }, -- Forever Rage of the Farseer
        { ids = {1238931} }, -- Forever Improved Stormstrike
        { ids = {16257, 16277, 16278, 16279, 16280}, stacks = 3 }, -- Flurry ranks
        { ids = {324, 325, 905, 945, 8134, 10431, 10432}, stacks = 3 }, -- Lightning Shield ranks
    },
    DRUID = { {ids = {16870}}, {ids = {17116}}, {ids = {29166}} },
    HUNTER = { {ids = {3045}}, {ids = {19574}} },
    MAGE = { {ids = {12536}}, {ids = {12042}}, {ids = {12043}} },
    PALADIN = { {ids = {20216}}, {ids = {642, 1020}}, {ids = {1022, 5599, 10278}} },
    PRIEST = { {ids = {14751}}, {ids = {10060}}, {ids = {15286}} },
    ROGUE = { {ids = {13750}}, {ids = {13877}}, {ids = {5277, 26669}}, {ids = {14177}} },
    WARLOCK = { {ids = {17941}}, {ids = {18288}}, {ids = {18708}} },
    WARRIOR = { {ids = {12292}}, {ids = {1719}}, {ids = {18499}}, {ids = {12966, 12967, 12968, 12969, 12970}, stacks = 3} },
}

local function Public(value)
    return not (issecretvalue and issecretvalue(value))
end

local function SpellInfo(id, request)
    local ok, info = pcall(C_Spell.GetSpellInfo, id)
    if ok and type(info) == "table" and type(info.name) == "string" then return info end
    if request and C_Spell.RequestLoadSpellData and not FSC.buffCatalogRequests[id] then
        FSC.buffCatalogRequests[id] = true
        C_Spell.RequestLoadSpellData(id)
    end
end

function FSC:ScanOwnBuffCatalog()
    if not self.buffCatalogClass or InCombatLockdown() then return end
    local api = C_UnitAuras or {}
    local getBuff = api.GetBuffDataByIndex or api.GetAuraDataByIndex
    if not getBuff then return end
    local store = self.storage.buffCatalog[self.buffCatalogClass]
    for index = 1, 255 do
        -- Index/filter work stays with the API; inspect only public identity out of combat.
        local ok, aura = pcall(getBuff, "player", index,
            api.GetBuffDataByIndex and "PLAYER" or "HELPFUL|PLAYER")
        if not ok or not Public(aura) then break end
        if aura == nil then break end
        if type(aura) == "table" then
            local id = aura.spellId
            if Public(id) and type(id) == "number" and id > 0 and id == math.floor(id) then
                -- Some clients ignore PLAYER; do not learn another player's class spells.
                local source = aura.sourceUnit
                local fromPlayer = aura.isFromPlayerOrPlayerPet
                local own = Public(source) and source == "player"
                if Public(source) and source == nil and Public(fromPlayer) and fromPlayer == true then own = true end
                if own then
                    local record = store[id] or {spellID = id, maxStacks = 1}
                    local count = aura.applications
                    if Public(count) and type(count) == "number" and count >= 1 and count <= 40 then
                        record.maxStacks = math.max(record.maxStacks or 1, count)
                    end
                    store[id] = record
                end
            end
        end
    end
end

function FSC:GetClassBuffChoices(request)
    local choices, byName = {}, {}
    local function Add(id, maximum)
        local info = SpellInfo(id, request)
        if not info then return end
        local key = info.name
        local choice = byName[key]
        if not choice then
            choice = {spellID = id, name = info.name, iconID = info.iconID, ids = {}, maxStacks = 1}
            choices[#choices + 1], byName[key] = choice, choice
        end
        choice.ids[id] = true
        choice.maxStacks = math.max(choice.maxStacks, maximum or 1)
    end
    for _, seed in ipairs(seeds[self.buffCatalogClass] or {}) do
        for _, id in ipairs(seed.ids) do Add(id, seed.stacks) end
    end
    for id, record in pairs(self.storage.buffCatalog[self.buffCatalogClass] or {}) do
        if type(id) == "number" and type(record) == "table" then Add(id, tonumber(record.maxStacks)) end
    end
    -- Previously tracked custom auras are useful choices even before they proc again.
    for _, entry in ipairs(self.storage.buffs) do Add(entry.spellID, self:BuffLayout(entry).maxStacks) end
    table.sort(choices, function(a, b) return a.name:lower() < b.name:lower() end)
    return choices
end

function FSC:FindBuffChoice(choice)
    for _, entry in ipairs(self.storage.buffs) do
        if choice.ids[entry.spellID] then return entry end
        for id in pairs(entry.auraIDs or {}) do if choice.ids[id] then return entry end end
    end
end

function FSC:AddBuffChoice(choice)
    if not choice or not self:CanEdit() then return end
    self:ClearBuffFocus()
    local entry = self:FindBuffChoice(choice)
    local added = not entry
    if not entry then
        if not self:AddBuff(choice.spellID) then return end
        entry = self:FindBuff(self.selectedBuffUID)
    end
    entry.auraIDs = type(entry.auraIDs) == "table" and entry.auraIDs or {}
    for id in pairs(choice.ids) do entry.auraIDs[id] = true end
    entry.specs[self.activeSpec or 1] = true
    if added then self:BuffLayout(entry).maxStacks = self:Clamp(choice.maxStacks, 1, 40) end
    if self.buffCatalogWindow then self.buffCatalogWindow:Hide() end
    self:StartBuffPreview(entry)
end

function FSC:RefreshBuffCatalog()
    local window = self.buffCatalogWindow
    if not window or not window:IsShown() then return end
    local query = window.search:GetText():lower():match("^%s*(.-)%s*$")
    local filtered = {}
    for _, choice in ipairs(self:GetClassBuffChoices(true)) do
        if query == "" or choice.name:lower():find(query, 1, true) or tostring(choice.spellID):find(query, 1, true) then
            filtered[#filtered + 1] = choice
        end
    end
    window.caption:SetText("Classa: " .. self.buffCatalogClassName .. " — buffy v nabídce: " .. #filtered)
    window.content:SetHeight(math.max(1, #filtered * 40))
    window.empty:SetShown(#filtered == 0)
    for index, choice in ipairs(filtered) do
        local row = window.rows[index]
        if not row then
            row = CreateFrame("Button", nil, window.content)
            window.rows[index] = row
            row:SetSize(470, 38); row:SetPoint("TOPLEFT", 0, -(index - 1) * 40)
            local bg = row:CreateTexture(nil, "BACKGROUND"); bg:SetAllPoints(); bg:SetColorTexture(0.07, 0.13, 0.16, 1)
            row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(28, 28); row.icon:SetPoint("LEFT", 6, 0)
            row.name = UI.Label(row, "", 43, -5, "GameFontHighlightSmall"); row.name:SetWidth(330)
            row.detail = UI.Label(row, "", 43, -22, "GameFontDisableSmall")
            row.add = UI.Button(row, "Vybrat", 386, -6, 78, function() FSC:AddBuffChoice(row.choice) end)
            row:SetScript("OnClick", function() FSC:AddBuffChoice(row.choice) end)
        end
        row.choice = choice; row.icon:SetTexture(choice.iconID or 134400); row.name:SetText(choice.name)
        row.detail:SetText(self:FindBuffChoice(choice) and "Už sleduješ — upravit" or "Přidat do sledovaných buffů")
        row:Show()
    end
    for index = #filtered + 1, #window.rows do window.rows[index]:Hide() end
end

function FSC:OpenBuffCatalog()
    if not self:CanEdit() then return end
    self:ClearBuffFocus(); self:FinishBuffPreview(); self:ScanOwnBuffCatalog()
    local window = self.buffCatalogWindow
    if not window then
        window = CreateFrame("Frame", "FreeSpellCooldownsBuffCatalog", UIParent, "BackdropTemplate")
        self.buffCatalogWindow = window
        window:SetSize(545, 500); window:SetPoint("CENTER", UIParent, "CENTER")
        window:SetScale(math.min(1, (UIParent:GetHeight() - 40) / 500))
        window:SetFrameStrata("FULLSCREEN_DIALOG"); window:SetClampedToScreen(true); window:EnableMouse(true)
        window:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
        window:SetBackdropColor(0.035, 0.045, 0.065, 0.99); window:SetBackdropBorderColor(0.2, 0.8, 0.7, 1)
        table.insert(UISpecialFrames, "FreeSpellCooldownsBuffCatalog")
        local close = CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -3, -3); close:SetScript("OnClick", function() window:Hide() end)
        UI.Label(window, "Vyber buff k zobrazení", 20, -18, "GameFontNormalLarge")
        window.caption = UI.Label(window, "", 20, -49, "GameFontHighlightSmall")
        UI.Label(window, "Hledat:", 20, -87, "GameFontHighlightSmall")
        window.search = UI.EditBox(window, 85, -79, 285)
        window.search:SetScript("OnTextChanged", function() FSC:RefreshBuffCatalog() end)
        window:SetScript("OnHide", function() window.search:ClearFocus() end)
        window.refreshButton = UI.Button(window, "Obnovit", 395, -80, 110, function() FSC:ScanOwnBuffCatalog(); FSC:RefreshBuffCatalog() end)
        local scroll = CreateFrame("ScrollFrame", nil, window, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 20, -122); scroll:SetSize(480, 300)
        window.content = CreateFrame("Frame", nil, scroll); window.content:SetSize(480, 1); scroll:SetScrollChild(window.content)
        window.empty = UI.Label(window.content, "Zatím žádný buff. Zkus Obnovit nebo ruční název / ID.", 5, -10, "GameFontDisable")
        local hint = UI.Label(window, "Základní nabídka pro classu + další vlastní buffy poznané mimo boj.\nRuční přidání podle názvu nebo ID dál funguje.", 20, -446, "GameFontHighlightSmall")
        hint:SetWidth(505); hint:SetHeight(36); hint:SetJustifyV("TOP")
        window.rows = {}
    end
    window:Show(); window:Raise(); self:RefreshBuffCatalog()
end

local initializeBuffs = FSC.InitializeBuffs
function FSC:InitializeBuffs()
    initializeBuffs(self)
    local name, class = "Postava", "UNKNOWN"
    if UnitClass then name, class = UnitClass("player") end
    self.buffCatalogClass, self.buffCatalogClassName = class or "UNKNOWN", name or "Postava"
    self.storage.buffCatalog = type(self.storage.buffCatalog) == "table" and self.storage.buffCatalog or {}
    self.storage.buffCatalog[self.buffCatalogClass] = type(self.storage.buffCatalog[self.buffCatalogClass]) == "table"
        and self.storage.buffCatalog[self.buffCatalogClass] or {}
    self.buffCatalogRequests = {}
    self:ScanOwnBuffCatalog()
end

local queued = false
local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_AURA", "player")
for _, event in ipairs({"PLAYER_REGEN_ENABLED", "SPELL_DATA_LOAD_RESULT", "PLAYER_REGEN_DISABLED"}) do events:RegisterEvent(event) end
events:SetScript("OnEvent", function(_, event, unit)
    if not FSC.buffCatalogClass then return end
    if event == "PLAYER_REGEN_DISABLED" then
        if FSC.buffCatalogWindow then FSC.buffCatalogWindow:Hide() end
        return
    end
    if event == "UNIT_AURA" and unit ~= "player" then return end
    if InCombatLockdown() or queued then return end
    queued = true
    C_Timer.After(0.2, function()
        queued = false
        if not InCombatLockdown() then FSC:ScanOwnBuffCatalog(); FSC:RefreshBuffCatalog() end
    end)
end)
