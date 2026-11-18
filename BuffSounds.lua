local _, FSC = ...

-- SoundKit IDs from Blizzard_CooldownViewer/CooldownViewerSoundAlertData.lua,
-- verified in the installed Forever client. The game provides the audio assets.
FSC.buffSounds = {
    {id = 316493, name = "Zvonek"}, {id = 353392, name = "Krátké cinknutí"},
    {id = 353393, name = "Kravský zvonec"}, {id = 316447, name = "Stoupající zvonkohra"},
    {id = 353426, name = "Kapka vody"}, {id = 353402, name = "Syntetické pípnutí"},
    {id = 353397, name = "Chybové pípnutí"}, {id = 316434, name = "Lupnutí"},
    {id = 316528, name = "Úder do kovadliny"}, {id = 316436, name = "Vzduchový klakson"},
    {id = 316713, name = "Klakson kola"}, {id = 316446, name = "Pokladna"},
    {id = 316401, name = "Kočka"}, {id = 316406, name = "Slepice"},
    {id = 316414, name = "Ovce"}, {id = 316415, name = "Vlk"},
}
FSC.buffSoundStates = {}
FSC.buffSoundFailures = {}
FSC.buffSoundRestrictedInCombat = {}

function FSC:GetBuffSound(id)
    for _, sound in ipairs(self.buffSounds) do if sound.id == id then return sound end end
    return self.buffSounds[1]
end

local function Public(value) return not (issecretvalue and issecretvalue(value)) end
local function IDs(entry)
    local ids = {[entry.spellID] = true}
    for id, enabled in pairs(entry.auraIDs or {}) do if enabled then ids[id] = true end end
    return ids
end

local function ReadPublicCount(entry)
    local count = 0
    for id in pairs(IDs(entry)) do
        local ok, aura = pcall(C_UnitAuras.GetUnitAuraBySpellID, "player", id)
        if not ok or not Public(aura) then return end
        if aura then
            local applications = aura.applications
            if not Public(applications) or type(applications) ~= "number" then return end
            count = math.max(count, math.max(1, applications))
        end
    end
    return count
end

function FSC:IsBuffSoundReadable(entry)
    if not C_UnitAuras or not C_UnitAuras.GetUnitAuraBySpellID then return false end
    for id in pairs(IDs(entry)) do
        if C_Secrets and C_Secrets.ShouldSpellAuraBeSecret then
            local ok, secret = pcall(C_Secrets.ShouldSpellAuraBeSecret, id)
            if not ok or not Public(secret) or secret then return false end
        elseif InCombatLockdown() then return false end
    end
    return true
end

function FSC:PlayBuffSound(entry, preview)
    if not entry then return false end
    local sound = self:GetBuffSound(self:BuffLayout(entry).soundKit)
    if preview and self.buffSoundPreviewHandle and StopSound then pcall(StopSound, self.buffSoundPreviewHandle, 100) end
    local ok, success, handle
    if C_Sound and C_Sound.PlaySoundWithOptions then
        ok, success, handle = pcall(C_Sound.PlaySoundWithOptions, {soundKitID = sound.id})
    elseif C_Sound and C_Sound.PlaySound then
        ok, success, handle = pcall(C_Sound.PlaySound, sound.id)
    elseif type(PlaySound) == "function" then
        ok, success, handle = pcall(PlaySound, sound.id, "Master")
    end
    self.buffSoundFailures[entry.uid] = (not ok or success ~= true) and true or nil
    if preview then self.buffSoundPreviewHandle = ok and success and handle or nil end
    if preview then
        self:Status(ok and success == true and ("Ukázka zvuku: " .. sound.name)
            or "Zvuk se nepodařilo spustit. Zkontroluj zvuk hry a zkus Poslechnout znovu.", not (ok and success == true))
        self:RefreshBuffOptions()
    end
    return ok and success == true
end

function FSC:GetBuffSoundStatus(entry)
    if not entry then return "Vyber buff. Tlačítko Poslechnout vyzkouší zvuk i při vypnutém upozornění." end
    local layout = self:BuffLayout(entry)
    if self.buffSoundFailures[entry.uid] then
        return "Zvuk se nepodařilo spustit. Ověř zvuk hry a zkus Poslechnout. Výběr zvuku se neztratil."
    end
    if not layout.soundEnabled then return "Zvuk je vypnutý. Zapni Zapnout zvuk. Poslechnout přehraje pouze ukázku." end
    if not entry.specs[self.activeSpec or 1] then return "Buff je v aktivním specu vypnutý; skutečné zvukové upozornění neběží." end
    if self:IsBuffPreview(entry) then return "Právě upravuješ náhled. Pro skutečné procy zamkni náhled; zvuk samostatně vyzkoušíš tlačítkem Poslechnout." end
    local threshold = layout.soundAtMax and layout.maxStacks or layout.soundStacks
    if self:ReadMaelstromSoundSignal(entry, threshold) ~= nil then
        return "Maelstrom, 5 stacků: zvuk sleduje okamžitý Blesk bez many. Zazní jednou při plném nabití a znovu po spotřebování a dalším nabití."
    end
    if not self:IsBuffSoundReadable(entry) or (self.buffSoundStates[entry.uid] or {}).restricted then
        return "Hra nyní skrývá stacky tohoto buffu. Přesný zvukový práh je nedostupný; ukázka zvuku funguje nezávisle."
    end
    if self.buffSoundRestrictedInCombat[entry.uid] then
        return "V posledním boji hra skryla stacky a automatický zvukový práh byl nedostupný. Přehrát ukázku zkouší pouze zvuk, ne dostupnost prahu."
    end
    if layout.combatOnly and not InCombatLockdown() then return "Zvuk čeká na boj, protože je zapnutá volba Pouze v boji." end
    return "Nastavený práh: " .. threshold .. " stacků. Automatický zvuk vyžaduje dostupné stacky; mimo boj nelze potvrdit jejich dostupnost pro příští boj."
end

function FSC:ResetBuffSound(entry)
    self.buffSoundStates[entry.uid] = nil
end

function FSC:UpdateBuffSound(entry, eventUpdate)
    local layout, slot = self:BuffLayout(entry), self.activeSpec or 1
    if not layout.soundEnabled or not entry.specs[slot] or self:IsBuffPreview(entry)
        or (layout.combatOnly and not InCombatLockdown()) then
        self:ResetBuffSound(entry); return
    end
    local threshold = layout.soundAtMax and layout.maxStacks or layout.soundStacks
    local signature = table.concat({slot, threshold, layout.soundKit}, ":")
    local state = self.buffSoundStates[entry.uid]
    if not state or state.signature ~= signature then
        state = {signature = signature}; self.buffSoundStates[entry.uid] = state
    end
    local readable = self:IsBuffSoundReadable(entry)
    -- Layout refreshes must not consume a crossing before UNIT_AURA delivers it.
    if readable and not eventUpdate and state.above ~= nil then return end
    local count = readable and ReadPublicCount(entry) or nil
    local signal = count == nil and self:ReadMaelstromSoundSignal(entry, threshold)
    if count == nil and signal == nil then
        state.above = nil; state.restricted = true
        if InCombatLockdown() then self.buffSoundRestrictedInCombat[entry.uid] = true end
        return
    end
    state.restricted = nil; state.signal = count == nil and "maelstrom_instant_free" or nil
    if not eventUpdate and state.above ~= nil then return end
    local above
    if count ~= nil then above = count >= threshold else above = signal end
    if eventUpdate and state.above == false and above then self:PlayBuffSound(entry) end
    state.above = above
end

local update = FSC.UpdateAllBuffs
function FSC:UpdateAllBuffs()
    update(self)
    if not self.buffsInitialized then return end
    for _, entry in ipairs(self.storage.buffs) do self:UpdateBuffSound(entry, false) end
end
local apply = FSC.ApplyBuff
function FSC:ApplyBuff(entry)
    apply(self, entry)
    if self.buffsInitialized then self:UpdateBuffSound(entry, false) end
end
local remove = FSC.RemoveBuff
function FSC:RemoveBuff(uid)
    if not self:CanEdit() then return end
    local entry = self:FindBuff(uid)
    if entry then self:ResetBuffSound(entry) end
    remove(self, uid)
end

local events = CreateFrame("Frame")
events:RegisterUnitEvent("UNIT_AURA", "player")
events:RegisterEvent("SPELL_UPDATE_USABLE")
events:SetScript("OnEvent", function()
    if not FSC.buffsInitialized then return end
    for _, entry in ipairs(FSC.storage.buffs) do FSC:UpdateBuffSound(entry, true) end
    if C_Timer and C_Timer.After and not FSC.buffSoundRefreshQueued then
        FSC.buffSoundRefreshQueued = true
        C_Timer.After(0, function()
            FSC.buffSoundRefreshQueued = nil
            for _, entry in ipairs(FSC.storage.buffs) do FSC:UpdateBuffSound(entry, true) end
        end)
    end
    if FSC.buffOptions and FSC.buffOptions:IsShown() then FSC:RefreshBuffOptions() end
end)
