local _, FSC = ...

local layoutFields = { "x", "y", "size", "opacity", "combatOnly", "showNumbers", "showName",
    "flashReady", "flashOnly", "flashOutsideCombat", "flashIntensity", "manaTint" }

local function ReadNumber(getter)
    if type(getter) ~= "function" then return end
    local ok, value = pcall(getter)
    if ok and not (issecretvalue and issecretvalue(value))
        and type(value) == "number" and value > 0 then return value end
end

local function CopyLayout(source)
    local layout = {}
    for _, field in ipairs(layoutFields) do layout[field] = source[field] end
    return layout
end

local function NormaliseLayout(layout, fallback)
    layout, fallback = layout or {}, fallback or {}
    local function Number(field, default)
        local value = tonumber(layout[field])
        if not value or value ~= value or value <= -math.huge or value >= math.huge then
            value = tonumber(fallback[field]) or default
        end
        return value
    end
    return {
        x = Number("x", 0), y = Number("y", -100),
        size = FSC:Clamp(Number("size", 52), 24, 160),
        opacity = FSC:Clamp(Number("opacity", 1), 0, 1),
        combatOnly = layout.combatOnly == true,
        showNumbers = layout.showNumbers ~= false,
        showName = layout.showName == true,
        flashReady = layout.flashReady == true,
        flashOnly = layout.flashOnly == true,
        flashOutsideCombat = layout.flashOutsideCombat == true,
        flashIntensity = FSC:Clamp(math.floor(Number("flashIntensity", 80) + 0.5), 0, 100),
        manaTint = layout.manaTint == true,
    }
end

function FSC:ReadTalentProfile()
    local specialization = C_SpecializationInfo or {}
    local group = ReadNumber(specialization.GetActiveSpecGroup)
        or ReadNumber(specialization.GetActiveTalentGroup)
        or ReadNumber(GetActiveTalentGroup) or ReadNumber(GetActiveSpecGroup)
    if group == 1 or group == 2 then return "group:" .. group, FSC:T("Talenty ") .. group end
    local configID = ReadNumber(C_ClassTalents and C_ClassTalents.GetActiveConfigID)
    if configID then
        local name
        if C_Traits and C_Traits.GetConfigInfo then
            local ok, info = pcall(C_Traits.GetConfigInfo, configID)
            if ok and type(info) == "table" and type(info.name) == "string" and info.name ~= "" then
                name = info.name
            end
        end
        return "config:" .. configID, name
    end
end

function FSC:ResolveSpecSlot(key, preferred)
    local storage = self.storage
    local group = key and tonumber(key:match("^group:(%d+)$"))
    if group == 1 or group == 2 then
        storage.specKeys[key] = group
        return group
    end
    if key and storage.specKeys[key] then return storage.specKeys[key] end
    if key == "pending" or not key then
        return preferred or self.activeSpec or storage.activeSpec or 1
    end
    local used = {}
    for _, slot in pairs(storage.specKeys) do used[slot] = true end
    local slot = preferred
    if slot ~= 1 and slot ~= 2 then
        slot = not used[1] and 1 or (not used[2] and 2 or (self.activeSpec or storage.activeSpec or 1))
    end
    storage.specKeys[key] = slot
    return slot
end

function FSC:GetSpecLabel(slot)
    return "Spec " .. (slot or self.activeSpec or 1)
end

function FSC:IsEntryAssigned(entry, slot)
    return entry.specs and entry.specs[slot or self.activeSpec or 1] == true
end

function FSC:GetSpecSummary(entry)
    if entry.specs[1] and entry.specs[2] then return FSC:T("oba specy") end
    if entry.specs[1] then return "spec 1" end
    if entry.specs[2] then return "spec 2" end
    return "vypnuto"
end

function FSC:SaveEntrySettings(entry)
    if not self.activeSpec then return end
    entry.layouts = entry.layouts or {}
    entry.layouts[self.activeSpec] = CopyLayout(entry)
end

function FSC:LoadEntrySettings(entry, slot)
    entry.layouts = entry.layouts or {}
    local layout = NormaliseLayout(entry.layouts[slot] or entry.layouts[slot == 1 and 2 or 1] or entry)
    entry.layouts[slot] = layout
    for _, field in ipairs(layoutFields) do entry[field] = layout[field] end
end

function FSC:SaveActiveSpecSettings()
    if not self.db or not self.activeSpec then return end
    for _, entry in ipairs(self.db.icons) do self:SaveEntrySettings(entry) end
    self.storage.specProfiles[self.activeSpec].locked = self.db.locked == true
end

function FSC:ResolvePendingAssignments(slot)
    for _, entry in ipairs(self.storage.icons) do
        local previous = entry.pendingSpec
        if previous then
            if previous ~= slot then
                entry.specs[slot], entry.specs[previous] = entry.specs[previous] == true, false
                if entry.layouts[previous] then entry.layouts[slot] = CopyLayout(entry.layouts[previous]) end
                if self.storage.specProfiles[slot].locked == nil then
                    self.storage.specProfiles[slot].locked = self.storage.specProfiles[previous].locked
                end
            end
            entry.pendingSpec = nil
        end
    end
end

function FSC:MigrateSpecAssignments(currentKey)
    local storage = self.storage
    if storage.schema == 3 and type(storage.icons) == "table" then return end
    local previous = storage.profiles
    if type(previous) ~= "table" then
        previous = { [currentKey or "pending"] = {
            icons = storage.icons, nextUID = storage.nextUID, locked = storage.locked
        } }
    end
    -- Retain original profiles as a backup; migrate each old spec's layout independently.
    storage.legacyProfiles = storage.legacyProfiles or previous
    storage.icons, storage.nextUID = {}, 1
    storage.specKeys, storage.specProfiles = {}, { [1] = {}, [2] = {} }
    for key in pairs(previous) do
        local slot = type(key) == "string" and tonumber(key:match("^group:(%d+)$"))
        if slot == 1 or slot == 2 then storage.specKeys[key] = slot end
    end
    local currentGroup = currentKey and tonumber(currentKey:match("^group:(%d+)$"))
    local keys, bySpell = {}, {}
    for key in pairs(previous) do if type(key) == "string" then table.insert(keys, key) end end
    local oldActiveKey = storage.activeProfileKey
    table.sort(keys, function(a, b)
        if a == oldActiveKey then return b ~= oldActiveKey end
        if b == oldActiveKey then return false end
        return a < b
    end)
    for _, key in ipairs(keys) do
        local profile = previous[key]
        if type(profile) == "table" then
            local preferred = (key == oldActiveKey or key == "pending") and currentGroup or nil
            local slot = self:ResolveSpecSlot(key, preferred)
            local meta = storage.specProfiles[slot]
            if meta.locked == nil then meta.locked = profile.locked == true end
            meta.label = meta.label or profile.label
            for _, oldEntry in ipairs(type(profile.icons) == "table" and profile.icons or {}) do
                if type(oldEntry) == "table" and type(oldEntry.spellID) == "number" and oldEntry.spellID > 0 then
                    local entry = bySpell[oldEntry.spellID]
                    if not entry then
                        entry = {
                            uid = storage.nextUID, spellID = oldEntry.spellID,
                            name = oldEntry.name, iconID = oldEntry.iconID,
                            specs = {}, layouts = {},
                        }
                        storage.nextUID = storage.nextUID + 1
                        bySpell[entry.spellID] = entry
                        table.insert(storage.icons, entry)
                    end
                    entry.specs[slot] = true
                    entry.layouts[slot] = entry.layouts[slot] or NormaliseLayout(oldEntry)
                    if key == "pending" and not currentKey then entry.pendingSpec = slot end
                end
            end
        end
    end
    storage.profiles = nil
    storage.schema = 3
end

function FSC:PrepareProfile(profile)
    profile.icons = type(profile.icons) == "table" and profile.icons or {}
    profile.nextUID = math.max(1, math.floor(tonumber(profile.nextUID) or 1))
    local clean, used = {}, {}
    for _, entry in ipairs(profile.icons) do
        if type(entry) == "table" and type(entry.spellID) == "number" and entry.spellID > 0 then
            entry.uid = tonumber(entry.uid)
            if not entry.uid or entry.uid <= 0 or used[entry.uid] then entry.uid = profile.nextUID end
            used[entry.uid] = true
            profile.nextUID = math.max(profile.nextUID, entry.uid + 1)
            if type(entry.specs) ~= "table" then entry.specs = { [self.activeSpec] = true } end
            entry.specs[1], entry.specs[2] = entry.specs[1] == true, entry.specs[2] == true
            entry.layouts = type(entry.layouts) == "table" and entry.layouts or {}
            for slot = 1, 2 do
                if type(entry.layouts[slot]) == "table" then
                    entry.layouts[slot] = NormaliseLayout(entry.layouts[slot], entry)
                end
            end
            self:LoadEntrySettings(entry, self.activeSpec)
            entry.name = type(entry.name) == "string" and entry.name or ("Spell " .. entry.spellID)
            self:RefreshSpell(entry)
            table.insert(clean, entry)
        end
    end
    profile.icons = clean
end

function FSC:InitializeProfiles()
    self.storage = FreeSpellCooldownsDB
    local storage = self.storage
    local key, label = self:ReadTalentProfile()
    self:MigrateSpecAssignments(key)
    storage.specKeys = type(storage.specKeys) == "table" and storage.specKeys or {}
    storage.specProfiles = type(storage.specProfiles) == "table" and storage.specProfiles or {}
    for slot = 1, 2 do
        storage.specProfiles[slot] = type(storage.specProfiles[slot]) == "table" and storage.specProfiles[slot] or {}
    end
    storage.minimap = type(storage.minimap) == "table" and storage.minimap or {}
    storage.minimap.angle = (tonumber(storage.minimap.angle) or 225) % 360
    local slot = self:ResolveSpecSlot(key)
    if key then self:ResolvePendingAssignments(slot) end
    self.activeSpec, storage.activeSpec = slot, slot
    self.activeTalentKey, storage.activeTalentKey = key, key
    self.activeProfileKey, storage.activeProfileKey = "spec:" .. slot, "spec:" .. slot
    self.db = storage
    local meta = storage.specProfiles[slot]
    meta.label = label or meta.label
    self.db.label, self.db.locked = self:GetSpecLabel(slot), meta.locked == true
    self:PrepareProfile(self.db)
end

function FSC:SetEntrySpec(entry, slot, enabled)
    if not entry or (slot ~= 1 and slot ~= 2) or not self:CanEdit() then return false end
    self:ClearInputFocus()
    self:SaveEntrySettings(entry)
    entry.pendingSpec = nil -- Explicit checkbox choices always take precedence over detection.
    if enabled and not entry.layouts[slot] then entry.layouts[slot] = CopyLayout(entry) end
    entry.specs[slot] = enabled == true
    self:ApplyIcon(entry)
    self:UpdateInteraction()
    self:RefreshOptions()
    self:QueueUpdate()
    return true
end

function FSC:CheckTalentProfile()
    if not self.storage then return end
    if InCombatLockdown() then self.profileCheckPending = true; return end
    local key, label = self:ReadTalentProfile()
    if not key then return end
    local slot = self:ResolveSpecSlot(key)
    self.activeTalentKey, self.storage.activeTalentKey = key, key
    self.storage.specProfiles[slot].label = label or self.storage.specProfiles[slot].label
    if slot == self.activeSpec then self:ResolvePendingAssignments(slot); return end
    if self.window then self:ClearInputFocus() end
    self:StopAllReadyFlashes()
    for _, entry in ipairs(self.db.icons) do self:SavePosition(entry) end
    self:SaveActiveSpecSettings()
    self:ResolvePendingAssignments(slot)
    self.activeSpec, self.storage.activeSpec = slot, slot
    self.activeProfileKey, self.storage.activeProfileKey = "spec:" .. slot, "spec:" .. slot
    self.db.label = self:GetSpecLabel(slot)
    self.db.locked = self.storage.specProfiles[slot].locked == true
    self.pendingSpells = {}
    self.profileCheckPending = false
    self:HideTooltip()
    for _, entry in ipairs(self.db.icons) do
        self:LoadEntrySettings(entry, slot)
        self:RefreshSpell(entry)
        if self.frames[entry.uid] then self:ApplyIcon(entry) else self:CreateIcon(entry) end
    end
    self:UpdateInteraction()
    self:RefreshOptions()
    self:QueueUpdate()
    self:Status(FSC:T("Aktivní ") .. self:GetSpecLabel(slot) .. FSC:T(". Zobrazení kouzel určují zaškrtávátka."))
    return true
end

function FSC:QueueProfileCheck()
    if not self.storage then return end
    if InCombatLockdown() then self.profileCheckPending = true; return end
    if self.profileCheckQueued then return end
    self.profileCheckQueued = true
    C_Timer.After(0.15, function() self:CheckTalentProfile() end)
    C_Timer.After(0.8, function()
        self.profileCheckQueued = false
        self:CheckTalentProfile()
    end)
end

local events = CreateFrame("Frame")
for _, event in ipairs({ "ACTIVE_TALENT_GROUP_CHANGED", "PLAYER_TALENT_UPDATE",
    "PLAYER_SPECIALIZATION_CHANGED", "ACTIVE_PLAYER_SPECIALIZATION_CHANGED",
    "TRAIT_CONFIG_UPDATED", "TRAIT_CONFIG_LIST_UPDATED", "SPELLS_CHANGED",
    "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED", "PLAYER_LOGOUT" }) do
    pcall(events.RegisterEvent, events, event)
end
events:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGOUT" then FSC:SaveActiveSpecSettings()
    else FSC:QueueProfileCheck() end
end)
