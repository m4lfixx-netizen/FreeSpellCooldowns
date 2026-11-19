local addonName, FSC = ...
FSC.name = addonName
FSC.version = "1.16.2"
FSC.frames = {}
FSC.pendingSpells = {}
FSC.requestedSpellData = {}

local eventFrame = CreateFrame("Frame")
local updateQueued = false
local refreshSpellsAfterCombat = false

function FSC:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff65d6cfFree Spell Cooldowns:|r " .. message)
end

function FSC:Status(message, isError)
    if self.window and self.window:IsShown() then
        self.window.status:SetText(message)
        self.window.status:SetTextColor(isError and 1 or 0.4, isError and 0.4 or 0.9, 0.8)
    else
        self:Print(message)
    end
end

function FSC:CanEdit()
    if InCombatLockdown() then
        self:Status(FSC:T("Nastavení ikon uprav až po skončení boje."), true)
        return false
    end
    return true
end

function FSC:Clamp(value, low, high)
    return math.max(low, math.min(high, value))
end

function FSC:FindEntry(uid)
    for index, entry in ipairs(self.db.icons) do
        if entry.uid == uid then return entry, index end
    end
end

function FSC:BaseSpellID(spellID)
    if C_Spell.GetBaseSpell then
        return C_Spell.GetBaseSpell(spellID) or spellID
    end
    return spellID
end

function FSC:RefreshSpell(entry)
    -- Spell identity is resolved out of combat; cooldown values are never read here.
    local info = C_Spell.GetSpellInfo(entry.spellID)
    if info then
        entry.name = info.name
        entry.iconID = info.iconID
    elseif C_Spell.RequestLoadSpellData and not self.requestedSpellData[entry.spellID] then
        self.requestedSpellData[entry.spellID] = true
        C_Spell.RequestLoadSpellData(entry.spellID)
    end
    entry.activeSpellID = C_Spell.GetOverrideSpell
        and C_Spell.GetOverrideSpell(entry.spellID) or entry.spellID
    local activeInfo = C_Spell.GetSpellInfo(entry.activeSpellID)
    if activeInfo then
        entry.name = activeInfo.name
        entry.iconID = activeInfo.iconID
    end
end

function FSC:RefreshAllSpells()
    if InCombatLockdown() then
        refreshSpellsAfterCombat = true
        return
    end
    for _, entry in ipairs(self.db.icons) do
        self:RefreshSpell(entry)
        self:ApplyIcon(entry)
    end
    if self.RefreshOptions then self:RefreshOptions() end
end

function FSC:QueueUpdate()
    if updateQueued or not self.db then return end
    updateQueued = true
    C_Timer.After(0, function()
        updateQueued = false
        self:UpdateAllCooldowns()
    end)
end

function FSC:AddSpell(identifier, fromLoad)
    if not self:CanEdit() then return false end
    local text = tostring(identifier or ""):match("^%s*(.-)%s*$")
    if text == "" then
        self:Status(FSC:T("Napiš název kouzla nebo ho přetáhni ze spellbooku."), true)
        return false
    end
    local linkID = text:match("spell:(%d+)")
    identifier = tonumber(linkID or text) or text
    local info = C_Spell.GetSpellInfo(identifier)
    if not info or not info.spellID then
        if type(identifier) == "number" and identifier > 0
            and not fromLoad and C_Spell.RequestLoadSpellData then
            self.pendingSpells[identifier] = true
            C_Spell.RequestLoadSpellData(identifier)
            self:Status(FSC:T("Načítám údaje o kouzlu…"))
        else
            self:Status(FSC:T("Kouzlo nenalezeno. Použij název ze hry, spell ID nebo přetažení."), true)
        end
        return false
    end
    local spellID = self:BaseSpellID(info.spellID)
    for _, entry in ipairs(self.db.icons) do
        if entry.spellID == spellID then
            self.selectedUID = entry.uid
            self:RefreshOptions()
            self:Status(FSC:T("Toto kouzlo už sleduješ: ") .. entry.name)
            return true
        end
    end
    local index = #self.db.icons
    local entry = {
        uid = self.db.nextUID,
        spellID = spellID,
        name = info.name,
        iconID = info.iconID,
        size = 52,
        x = -120 + (index % 5) * 64,
        y = -100 - math.floor(index / 5) * 64,
        showNumbers = true,
        showName = false,
        opacity = 1,
        combatOnly = false,
        flashReady = false,
        flashOnly = false,
        flashOutsideCombat = false,
        flashIntensity = 80,
        manaTint = false,
        specs = { [self.activeSpec or 1] = true },
        layouts = {},
        pendingSpec = not self.activeTalentKey and (self.activeSpec or 1) or nil,
    }
    self.db.nextUID = entry.uid + 1
    table.insert(self.db.icons, entry)
    self:RefreshSpell(entry)
    self:CreateIcon(entry)
    self.selectedUID = entry.uid
    self:RefreshOptions()
    self:QueueUpdate()
    self:Status(FSC:T("Přidáno: ") .. entry.name .. FSC:T(". Polohu změníš po odemčení ikon."))
    return true
end

function FSC:AddFromCursor()
    if not self:CanEdit() then return false end
    local kind, slot, bank, spellID = GetCursorInfo()
    -- Modern spell cursors put the spell ID in the FOURTH return value.
    if kind ~= "spell" then
        self:Status(FSC:T("Sem přetáhni přímo kouzlo ze spellbooku (klávesa P)."), true)
        return false
    end
    if not spellID and C_SpellBook and C_SpellBook.GetSpellBookItemInfo then
        local spellBank = type(bank) == "number" and bank
            or Enum.SpellBookSpellBank.Player
        local item = C_SpellBook.GetSpellBookItemInfo(slot, spellBank)
        spellID = item and item.spellID
    end
    if not spellID then
        self:Status(FSC:T("Z přetaženého kouzla nelze získat spell ID."), true)
        return false
    end
    local added = self:AddSpell(spellID)
    if added then ClearCursor() end
    return added
end

function FSC:RemoveSpell(uid)
    if not self:CanEdit() then return end
    local entry, index = self:FindEntry(uid)
    if not entry then return end
    local frame = self.frames[uid]
    if frame then
        frame:StopMovingOrSizing()
        frame:Hide()
        frame:EnableMouse(false)
        self.frames[uid] = nil
    end
    table.remove(self.db.icons, index)
    self.selectedUID = self.db.icons[index] and self.db.icons[index].uid
        or (self.db.icons[1] and self.db.icons[1].uid)
    self:RefreshOptions()
    self:Status(FSC:T("Odebráno: ") .. entry.name)
end

function FSC:SetLocked(locked)
    if not self:CanEdit() then return end
    self.db.locked = locked
    self:SaveActiveSpecSettings()
    self:UpdateInteraction()
    self:RefreshOptions()
    self:Status(locked and FSC:T("Ikony uzamčeny. Nastavení otevřeš příkazem /fsc.")
        or FSC:T("Ikony odemčeny. Přetáhni každou na požadované místo."))
end

function FSC:Initialize()
    if not (C_Spell and C_Spell.GetSpellInfo and C_Spell.GetSpellCooldownDuration) then
        self:Print(FSC:T("Tato verze addonu vyžaduje WoW Forever 1.60.1 a jeho moderní API."))
        return
    end
    if type(FreeSpellCooldownsDB) ~= "table" then FreeSpellCooldownsDB = {} end
    self.inCombat = not not InCombatLockdown()
    self:InitializeProfiles()
    local db = self.db
    self:CreateOptions()
    self:CreateMinimapButton()
    for _, entry in ipairs(db.icons) do self:CreateIcon(entry) end
    self:InitializeBuffs()
    self:UpdateInteraction()
    self:QueueUpdate()
    self:Print(FSC:T("Načteno. /fsc otevře správu samostatných ikon."))
    local restore = self.storage.languageReloadSelection
    self.storage.languageReloadSelection = nil
    if type(restore) == "table" then
        self.selectedUID = restore.cooldown
        self.selectedBuffUID = restore.buff
    end
    if not self.storage.introSeen or type(restore) == "table" then
        self.storage.introSeen = true
        self:OpenOptions()
    end
end

eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        FSC:Initialize()
        if not FSC.db then return end
        for _, name in ipairs({ "SPELL_UPDATE_COOLDOWN", "SPELL_UPDATE_CHARGES",
            "SPELL_UPDATE_USES", "SPELLS_CHANGED", "PLAYER_ENTERING_WORLD",
            "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED", "SPELL_DATA_LOAD_RESULT",
            "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do
            eventFrame:RegisterEvent(name)
        end
        eventFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player")
    elseif not FSC.db then
        return
    elseif event == "PLAYER_REGEN_DISABLED" then
        -- The game enters lockdown after dispatching this event.
        FSC.inCombat = true
        FSC:UpdateInteraction()
        if FSC.window then FSC.window:Hide() end
    elseif event == "PLAYER_REGEN_ENABLED" then
        FSC.inCombat = false
        FSC:CheckTalentProfile()
        FSC:UpdateInteraction()
        if refreshSpellsAfterCombat then
            refreshSpellsAfterCombat = false
            FSC:RefreshAllSpells()
        end
        if next(FSC.pendingSpells) then
            local pending = FSC.pendingSpells
            FSC.pendingSpells = {}
            for id in pairs(pending) do FSC:AddSpell(id, true) end
        end
        FSC:QueueUpdate()
    elseif event == "SPELLS_CHANGED" or event == "PLAYER_ENTERING_WORLD" then
        FSC:RefreshAllSpells()
        FSC:PositionMinimapButton()
        FSC:QueueUpdate()
    elseif event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED" then
        for _, entry in ipairs(FSC.db.icons) do FSC:ApplyIcon(entry) end
        FSC:PositionMinimapButton()
    elseif event == "SPELL_DATA_LOAD_RESULT" then
        local spellID, success = ...
        if FSC.pendingSpells[spellID] and not InCombatLockdown() then
            FSC.pendingSpells[spellID] = nil
            if success then FSC:AddSpell(spellID, true)
            else FSC:Status(FSC:T("Kouzlo s tímto ID se nepodařilo načíst."), true) end
        end
        FSC:RefreshAllSpells()
        FSC:QueueUpdate()
    else
        FSC:QueueUpdate()
        if event == "UNIT_SPELLCAST_SUCCEEDED" then
            -- Some casts publish the cooldown a moment after the cast event.
            C_Timer.After(0.1, function() FSC:QueueUpdate() end)
        end
    end
end)

SLASH_FREESPELLCOOLDOWNS1 = "/fsc"
SLASH_FREESPELLCOOLDOWNS2 = "/cdikony"
SlashCmdList.FREESPELLCOOLDOWNS = function(message)
    if not FSC.db then
        FSC:Print(FSC:T("Addon není připraven. Podporovaný klient: WoW Forever 1.60.1."))
        return
    end
    local command, rest = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "buff" then
        if rest == "" then FSC:OpenBuffOptions() else FSC:AddBuff(rest) end
    elseif command == "add" then FSC:AddSpell(rest)
    elseif command == "lock" then FSC:SetCurrentLocked(true)
    elseif command == "unlock" then FSC:SetCurrentLocked(false)
    elseif command == "help" then
        FSC:Print(FSC:T("/fsc — nastavení | /fsc add Stormstrike — přidat | /fsc buff — buffy/procy | /fsc lock — zamknout | /fsc unlock — odemknout"))
    else FSC:OpenOptions() end
end
