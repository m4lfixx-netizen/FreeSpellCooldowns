local _, FSC = ...
local UI = FSC.UI

function FSC:HideSettingsHelp()
    if self.settingsHelpOwner then self:GetTooltip():Hide(); self.settingsHelpOwner = nil end
end

function UI.Help(widget, title, body, kind, disabled, labelWidth)
    if not widget then return end
    widget.fscHelp = {title = title, body = body, kind = kind, disabled = disabled}
    if widget.SetMotionScriptsWhileDisabled then widget:SetMotionScriptsWhileDisabled(true) end
    if widget.label and widget.SetHitRectInsets then
        local width = widget.label.GetStringWidth and widget.label:GetStringWidth() or 160
        widget:SetHitRectInsets(0, -math.min(width + 6, labelWidth or 180), 0, 0)
    end
    if widget.fscHelpAttached then return end
    widget.fscHelpAttached = true
    widget:HookScript("OnEnter", function(self)
        local help, tip = self.fscHelp, FSC:GetTooltip()
        tip:SetOwner(self, "ANCHOR_RIGHT"); tip:ClearLines(); tip:SetClampedToScreen(true)
        tip:AddLine(help.title, 1, 0.83, 0.2, true)
        if help.kind == "test" then tip:AddLine(FSC:T("POUZE TESTOVACÍ NÁHLED"), 0.3, 0.9, 0.85, true)
        elseif help.kind == "saved" then tip:AddLine(FSC:T("Ukládá se pro vybraný záznam a aktivní spec"), 0.65, 0.8, 1, true) end
        local text = type(help.body) == "function" and help.body(self) or help.body
        tip:AddLine(text or "", 0.92, 0.94, 0.96, true)
        if help.disabled and self.IsEnabled and not self:IsEnabled() then
            tip:AddLine(type(help.disabled) == "function" and help.disabled(self) or help.disabled, 1, 0.75, 0.35, true)
        elseif (help.kind == "saved" or help.kind == "test") and self.IsEnabled and not self:IsEnabled() then
            tip:AddLine(FSC:T("Nejprve vyber záznam v levém seznamu."), 1, 0.75, 0.35, true)
        end
        FSC:StyleTooltip(); FSC.settingsHelpOwner = self; tip:Show()
    end)
    widget:HookScript("OnLeave", function(self)
        if FSC.settingsHelpOwner == self then FSC:HideSettingsHelp() end
    end)
end

local function BuffLayout()
    local entry = FSC:FindBuff(FSC.selectedBuffUID)
    return entry and FSC:BuffLayout(entry)
end

local function Common(window, buffs)
    UI.Help(window.input, buffs and FSC:T("Přidání buffu") or FSC:T("Přidání kouzla"), buffs
        and FSC:T("Zadej název buffu nebo ID jeho aury. Proc může mít jiné ID než talent nebo sesílané kouzlo. Potvrď Enterem nebo tlačítkem Přidat buff.")
        or FSC:T("Zadej název kouzla ze hry nebo spell ID. Potvrď Enterem nebo tlačítkem Přidat."))
    UI.Help(window.addButton, FSC:T("Přidat do seznamu"), FSC:T("Přidá záznam ze vstupního pole. Už přidaný záznam vybere pro úpravu."))
    for slot, check in ipairs({window.spec1, window.spec2}) do
        UI.Help(check, FSC:T("Sledovat ve specu ") .. slot, FSC:T("Určuje, ve které sadě talentů se záznam zobrazuje. Můžeš zapnout oba specy. Vzhled, polohu a ostatní volby má každý spec vlastní."))
    end
    UI.Help(window.sizeLess, FSC:T("Zmenšit o 1 pixel"), FSC:T("Zmenší vybraný motiv. V náhledu lze použít také Shift + kolečko myši."), "saved")
    UI.Help(window.sizeMore, FSC:T("Zvětšit o 1 pixel"), FSC:T("Zvětší vybraný motiv. V náhledu lze použít také Shift + kolečko myši."), "saved")
    UI.Help(window.centerButton, FSC:T("Přesunout na střed"), FSC:T("Nastaví souřadnice X = 0 a Y = 0. Nová poloha se uloží pro aktivní spec."), "saved")
    UI.Help(window.combatOnly, FSC:T("Pouze v boji"), buffs
        and FSC:T("Po zapnutí se skutečný efekt zobrazuje pouze během boje. Odemčený pracovní náhled můžeš upravovat i mimo boj.")
        or FSC:T("Po zapnutí se ikona zobrazí při vstupu do boje a schová se po jeho skončení. V Testu náhledu můžeš boj simulovat."), "saved")
    UI.Help(window.categoryTabs.cooldowns, FSC:T("Cooldowny"), FSC:T("Otevře nastavení samostatných ikon cooldownů. Tato sekce má vlastní zámek ikon."))
    UI.Help(window.categoryTabs.buffs, FSC:T("Buffy a procy"), FSC:T("Otevře sledování buffů na postavě. Odemknutí náhledu buffu nechává cooldowny zamčené."))
    for _, button in pairs(window.languageButtons) do
        UI.Help(button, FSC:T("Jazyk nastavení"), FSC:T("Přepnutí jazyka uloží volbu pro tuto postavu a znovu načte herní rozhraní."))
    end
    window:HookScript("OnHide", function() FSC:HideSettingsHelp() end)
end

function FSC:AddBuffSettingsHelp(window)
    if window.fscBuffHelpAttached then return end
    window.fscBuffHelpAttached = true
    Common(window, true)
    local saved = "saved"
    UI.Help(window.chooseBuff, FSC:T("Buffy pro tvoji classu"), FSC:T("Otevře seznam s hledáním. Obsahuje předvolby pro classu a další vlastní buffy poznané mimo boj. Výběr otevře náhled buffu."))
    UI.Help(window.iconStyle, FSC:T("Ikona buffu"), FSC:T("Použije vlastní ikonku vybraného buffu. Kliknutí otevře pracovní náhled pro přesun a velikost."), saved)
    UI.Help(window.lightningStyle, FSC:T("Vlevo a vpravo"), FSC:T("Zobrazí dvojici bočních motivů. Dvojice má společnou polohu a velikost. U Paladina jsou to dva zlaté meče."), saved)
    UI.Help(window.topStyle, FSC:T("Horní motiv"), FSC:T("Zobrazí jeden vodorovný motiv. U Paladina používá zlatou světelnou záři. Polohu můžeš zvolit kdekoliv na obrazovce."), saved)
    for _, card in ipairs(window.themeCards) do
        local key = card.theme
        UI.Help(card, FSC:T("Motiv: ") .. self:T(self.buffThemes[key].name),
            key == "paladin" and FSC:T("Po stranách jsou zlaté meče, pro horní zobrazení samostatná zlatá světelná záře. Motiv můžeš použít u libovolného buffu a classy.")
            or FSC:T("Změní grafiku bočního nebo horního motivu. Vybraná karta je zvýrazněná a kliknutí otevře náhled."), saved,
            FSC:T("Motivy vybírej u bočního nebo horního zobrazení. Ikona buffu používá vlastní obrázek."))
    end
    UI.Help(window.stacks, FSC:T("Počet stacků"), FSC:T("Zapne číslo se skutečným počtem stacků. U jednoho procu můžeš číslo vypnout."), saved)
    UI.Help(window.duration, FSC:T("Číselný odpočet času"), FSC:T("Zobrazí zbývající čas číslem. Tato volba je dostupná u ikony s prahem Od stacku = 1."), saved,
        FSC:T("Pro číslo času vyber Ikona buffu a nastav Od stacku na 1. U oblouků lze čas znázornit mizením motivu."))
    UI.Help(window.opacity, FSC:T("Průhlednost motivu"), FSC:T("0 % = plně viditelný motiv, 100 % = neviditelný motiv. Síla blikání a pulzování má vlastní posuvník."), saved)
    UI.Help(window.timeFade, FSC:T("Časový úbytek se šedým podkladem"), FSC:T("Celý motiv zůstává jako tlumený šedý podklad. Barevná část se podle zbývajícího času zkracuje od obou krajů ke středu a drží svou intenzitu. Efekt běží až od zvoleného počtu stacků a při poklesu pod něj se vypne. Používej pro buffy s dobou trvání."), saved,
        FSC:T("Nejprve vyber buff. Volba také vyžaduje podporu nativního časovače v klientu."), 370)
    UI.Help(window.timeFadeStacks, FSC:T("Časový úbytek od stacku"), FSC:T("Samostatný práh pouze pro časový efekt, od 1 do nastaveného Maxima. Příklad: 5 znamená běžný motiv při 1–4 stacích; od 5 barevná část ukazuje zbývající čas a uplynulá část zůstává šedá. Pokles pod 5 časový efekt vypne. Nemění práh zobrazení celého buffu."), saved,
        FSC:T("Nejprve zapni časový efekt v záložce Vzhled."))
    UI.Help(window.timeFadePreview, FSC:T("Test zbytku času"), FSC:T("Posuvník mění pouze odemčený pracovní náhled mimo boj. Skutečný čas buffu řídí hra. 100 % = celé trvání, 50 % = polovina, 0 % = konec. Testovací hodnota se neukládá."), "test",
        function()
            local layout = BuffLayout()
            if layout and layout.timeFade and (FSC.buffPreviewStacks or layout.maxStacks) < layout.timeFadeStacks then
                return FSC:T("V záložce Test náhledu nastav testovací počet alespoň na ") .. layout.timeFadeStacks .. FSC:T(" stacků, nebo stiskni Nastavit maximum.")
            end
            return FSC:T("Zapni časový efekt ve Vzhledu a pracovní náhled v záložce Test náhledu.")
        end)
    UI.Help(window.minimum, FSC:T("Od kterého stacku zobrazit"), FSC:T("Nejnižší počet stacků pro zobrazení motivu. Od 5 / Maximum 5 znamená zobrazení až při pěti stacích. Rozsah je 1–40."), saved)
    UI.Help(window.maximum, FSC:T("Maximum pro vzhled a upozornění"), FSC:T("Určuje plné nabití motivu. Používá jej zesilování, režim Po částech, záře, blikání a pulzování. Zvuk jej použije při zapnuté volbě Při maximu. Nemění skutečné maximum kouzla ve hře."), saved)
    UI.Help(window.fullMotif, FSC:T("Celý motiv"), FSC:T("Zobrazí celý motiv po dosažení hodnoty Od stacku. Vyber právě jeden ze tří režimů: Celý motiv, Zesilování nebo Po částech."), saved)
    UI.Help(window.progressive, FSC:T("Zesilování podle stacků"), FSC:T("S přibývajícími stacky zesiluje celý motiv až na nastavené Maximum. Vyber právě jeden režim zobrazení."), saved,
        FSC:T("Zesilování vyžaduje podporu pravidel stacků v klientu."))
    UI.Help(window.revealParts, FSC:T("Postupné části motivu"), FSC:T("S přibývajícími stacky přibývá pět částí obrázku. Při Maximu je celý. Kroky se přizpůsobí nastavenému maximu. Vyber právě jeden režim zobrazení."), saved,
        function()
            local layout = BuffLayout()
            if not layout then return FSC:T("Nejprve vyber buff.") end
            if layout.style == "icon" then return FSC:T("Vyber boční nebo horní motiv; ikona se nedělí na části.") end
            if layout.maxStacks < 2 then return FSC:T("Nastav Maximum alespoň na 2.") end
            return FSC:T("Tento klient nepodporuje postupné části.")
        end)
    UI.Help(window.glow, FSC:T("Stálá záře při maximu"), FSC:T("Při dosažení Maxima přidá trvalou jasnější vrstvu. Po poklesu stacků záře zhasne. Lze kombinovat s blikáním a pulzováním."), saved,
        FSC:T("Záře podle stacků vyžaduje podporu prahu v klientu."))
    UI.Help(window.flashMax, FSC:T("Blikání při maximu"), FSC:T("Po dobu plných stacků opakuje dvojici krátkých ostrých záblesků s pauzou. Po spotřebování stacků hned skončí. Lze zapnout společně s pulzováním."), saved,
        FSC:T("Blikání vyžaduje podporu prahu stacků v klientu."))
    UI.Help(window.pulseMax, FSC:T("Pulzování při maximu"), FSC:T("Po dobu plných stacků plynule zesiluje a slábne záře. Po spotřebování stacků hned skončí. Lze zapnout společně s blikáním."), saved,
        FSC:T("Pulzování vyžaduje podporu prahu stacků v klientu."))
    UI.Help(window.alertIntensity, FSC:T("Síla vizuálního upozornění"), FSC:T("Nastavuje sílu blikání a pulzování od 0 do 100 %. Je nezávislá na průhlednosti základního motivu. 0 % upozornění skryje."), saved,
        FSC:T("Zapni Blikat při maximu nebo Pulzovat při maximu."))
    UI.Help(window.alertPreview, FSC:T("Vyzkoušet maximum"), FSC:T("Odemkne náhled a nastaví testovací počet na Maximum. Ukáže motiv včetně zapnuté záře, blikání a pulzování bez skutečného procu."), "test",
        FSC:T("Nejprve vyber buff."))
    UI.Help(window.soundEnabled, FSC:T("Zvukové upozornění"), FSC:T("Zapne jeden zvuk při dosažení prahu směrem nahoru. Znovu se ozve po poklesu pod práh a dalším dosažení. V boji je přesný práh dostupný jen pro buffy, jejichž stacky hra zpřístupňuje."), saved)
    UI.Help(window.soundAtMax, FSC:T("Zvuk při nastaveném maximu"), FSC:T("Zapnuto: zvuk sleduje hodnotu Maximum. Vypnuto: můžeš zadat nezávislý Vlastní počet. Platí omezení dostupnosti stacků během boje."), saved)
    UI.Help(window.soundStacks, FSC:T("Vlastní počet stacků pro zvuk"), FSC:T("Počet 1–40, při jehož dosažení se ozve vybraný zvuk. Může být jiný než práh zobrazení motivu."), saved,
        function() return BuffLayout() and FSC:T("Zruš volbu Při maximu, abys mohl zadat vlastní počet.") or FSC:T("Nejprve vyber buff.") end)
    UI.Help(window.soundChoice, FSC:T("Vybrat zvuk"), FSC:T("Otevře 16 zvuků z Blizzardova cooldown manageru. Poslechnout přehraje ukázku vybraného zvuku."), saved)
    UI.Help(window.soundTest, FSC:T("Poslechnout ukázku"), FSC:T("Přehraje jen vybraný zvuk, i když je upozornění vypnuté. Další ukázka zastaví předchozí ukázku. Používá zvukové rozhraní klienta stejně jako Blizzardův cooldown manager. Pokud klient přehrání odmítne, zobrazí se zpráva."), "test")
    for index, button in ipairs(window.soundPicker.choices) do
        UI.Help(button, self.buffSounds[index].name, FSC:T("Vybere tento zvuk pro aktivní spec. Ukázku přehraje tlačítko Poslechnout."), saved)
    end
    window.soundPicker:HookScript("OnHide", function() FSC:HideSettingsHelp() end)
    UI.Help(window.x, FSC:T("Vodorovná poloha X"), FSC:T("Pixely od středu obrazovky: kladné hodnoty doprava, záporné doleva. Potvrď Enterem; Escape úpravu zruší."), saved)
    UI.Help(window.y, FSC:T("Svislá poloha Y"), FSC:T("Pixely od středu obrazovky: kladné hodnoty nahoru, záporné dolů. Potvrď Enterem; Escape úpravu zruší."), saved)
    UI.Help(window.sideGap, FSC:T("Rozestup stran v pixelech"), FSC:T("Vzdálenost mezi vnitřními okraji levé a pravé části, 0–2000 px. Nula je přiblíží k sobě. Změna rozestupu nemění velikost motivů ani střed dvojice. Platí pro celý motiv, Po částech, šedý podklad i upozornění a ukládá se pro každý buff a spec zvlášť. Enter potvrdí, Escape zruší rozepsanou změnu."), saved,
        FSC:T("Rozestup nastavuješ u zobrazení Vlevo + vpravo."))
    UI.Help(window.sizeInput, FSC:T("Velikost motivu v pixelech"), FSC:T("Zadej přímo velikost obrázku. Enter potvrdí, Escape zruší rozepsanou změnu. Tlačítka −/+ mění velikost po jednom pixelu. Mezera mezi stranami má vlastní hodnotu."), saved)
    UI.Help(window.positionPreviewLink, FSC:T("Přesunout motiv myší"), FSC:T("Otevře samostatnou záložku Test náhledu a zapne pracovní náhled vybraného buffu. Přetažení a velikost se ukládají; testovací stacky a čas se neukládají."))
    UI.Help(window.alertsPreviewLink, FSC:T("Vyzkoušet nastavené efekty"), FSC:T("Otevře záložku Test náhledu a ukáže zvolené maximum se zapnutou září, blikáním a pulzováním. Skutečný buff se tím nemění."), "test")
    UI.Help(window.previewLess, FSC:T("Test: méně stacků"), FSC:T("Sníží pouze testovací počet v náhledu. Skutečný buff ani uložené Maximum nemění."), "test", FSC:T("Nejprve odemkni náhled buffu."))
    UI.Help(window.previewMore, FSC:T("Test: více stacků"), FSC:T("Zvýší pouze testovací počet v náhledu, nejvýše na nastavené Maximum."), "test", FSC:T("Nejprve odemkni náhled buffu."))
    UI.Help(window.lock, FSC:T("Odemknout nebo zamknout náhled"), FSC:T("Odemčení zobrazí vybraný buff i bez procu. Přetáhni jej za rámeček; Shift + kolečko mění velikost. Poloha a velikost se ukládají. Šedá silueta je jen pomůcka. Cooldowny zůstávají zamčené."))
    UI.Help(window.settingsTabs.appearance, FSC:T("Vzhled"), FSC:T("Tvar, motiv, průhlednost, čísla a časové mizení obrázku."))
    UI.Help(window.settingsTabs.alerts, FSC:T("Stacky a upozornění"), FSC:T("Práh zobrazení, maximum, režim stacků, vizuální a zvuková upozornění."))
    UI.Help(window.settingsTabs.position, FSC:T("Poloha"), FSC:T("Velikost obrázku, mezera mezi stranami, přesná poloha X/Y a zobrazení jen v boji. Tyto hodnoty se ukládají."))
    UI.Help(window.settingsTabs.preview, FSC:T("Test náhledu"), FSC:T("Samostatná zkouška počtu stacků, času a efektů. Testovací hodnoty se neukládají. Přetažení motivu a jeho velikost se ukládají."))
end

function FSC:AddCooldownSettingsHelp(window)
    if window.fscCooldownHelpAttached then return end
    window.fscCooldownHelpAttached = true
    Common(window, false)
    local function IconOptionDisabled()
        return FSC:FindEntry(FSC.selectedUID) and FSC:T("Tato volba platí pro běžnou ikonu.")
            or FSC:T("Nejprve vyber kouzlo.")
    end
    UI.Help(window.drop, FSC:T("Přetáhnout kouzlo"), FSC:T("Otevři spellbook klávesou P a přetáhni sem kouzlo. Přidá se jako samostatně nastavitelná ikona."))
    UI.Help(window.sizeInput, FSC:T("Velikost ikony v pixelech"),
        FSC:T("Zadej 24 až 160 px a potvrď Enterem. Podrž + nebo − pro průběžnou změnu po jednom pixelu."), "saved")
    UI.Help(window.numbers, FSC:T("Číselný odpočet"), FSC:T("Zapne číslo se zbývajícím cooldownem na ikoně."), "saved", IconOptionDisabled)
    UI.Help(window.spellName, FSC:T("Název pod ikonou"), FSC:T("Zobrazí název sledovaného kouzla pod jeho ikonou."), "saved", IconOptionDisabled)
    UI.Help(window.opacitySlider, FSC:T("Průhlednost ikony"), FSC:T("0 % = plně viditelná, 100 % = neviditelná. Platí pro ikonu při záblesku i běžnou ikonu. Sílu záře nastavíš zvlášť."), "saved")
    UI.Help(window.xInput, FSC:T("Vodorovná poloha X"), FSC:T("Pixely od středu: kladná hodnota doprava, záporná doleva. Enter potvrdí, Escape zruší rozepsanou změnu."), "saved")
    UI.Help(window.yInput, FSC:T("Svislá poloha Y"), FSC:T("Pixely od středu: kladná hodnota nahoru, záporná dolů. Enter potvrdí, Escape zruší rozepsanou změnu."), "saved")
    for _, item in ipairs({{window.xLess,"X − 1 px"},{window.xMore,"X + 1 px"},{window.yLess,"Y − 1 px"},{window.yMore,"Y + 1 px"}}) do
        UI.Help(item[1], item[2], FSC:T("Posune vybranou ikonu o jeden pixel v příslušném směru."), "saved")
    end
    UI.Help(window.manaTint, FSC:T("Modře při nedostatku many"), FSC:T("Při nedostatku many zbarví ikonu modře. Nedostatečný dosah na cíl má přednost a zůstává červený."), "saved", IconOptionDisabled)
    UI.Help(window.combatOnly, FSC:T("Pouze v boji"), FSC:T("Omezí zobrazení běžné ikony na dobu boje. Pro samotný záblesk použij nastavení níže."), "saved", IconOptionDisabled)
    UI.Help(window.flashOnly, FSC:T("Jen probliknutí po nabití cooldownu"), FSC:T("Ukáže samotnou ikonu až jako krátké upozornění po dokončení cooldownu nebo nabíjení. Velikost a polohu nastav ve Vzhledu ikony."), "saved", nil, 280)
    UI.Help(window.flashReady, FSC:T("Záblesk po skončení cooldownu"), FSC:T("Přidá upozornění k běžné ikoně. Sílu nastavíš posuvníkem. Režim Jen probliknutí po nabití cooldownu má upozornění zapnuté automaticky."), "saved", IconOptionDisabled, 280)
    UI.Help(window.flashOutsideCombat, FSC:T("Probliknout i mimo boj"), FSC:T("Povolí upozornění také u cooldownu, který skončí mimo boj."), "saved",
        FSC:T("Vyber kouzlo a zapni jeho upozornění."), 260)
    UI.Help(window.flashIntensitySlider, FSC:T("Intenzita záblesku"), FSC:T("0–100 % síly upozornění po cooldownu. Nezávisí na průhlednosti ikony; 0 % záblesk vypne."), "saved")
    UI.Help(window.lockButton, FSC:T("Zámek ikon cooldownů"), FSC:T("Odemčení umožní ikony přesouvat a měnit velikost pomocí Shift + kolečko. Poloha a velikost se ukládají pro aktivní spec. Náhledy buffů mají vlastní zámek."))
    UI.Help(window.settingsTabs.appearance, FSC:T("Vzhled ikony"), FSC:T("Velikost, název, číselný odpočet, průhlednost a poloha na obrazovce."))
    UI.Help(window.settingsTabs.alerts, FSC:T("Boj a upozornění"), FSC:T("Zobrazení během boje, modré zabarvení a intenzita záblesku."))
    UI.Help(window.settingsTabs.preview, FSC:T("Test náhledu"), FSC:T("Vyzkoušej ikonu vybraného kouzla s testovacím odpočtem a bojovými stavy."))
    local preview = window.cooldownPreview
    UI.Help(preview.screenCheck, FSC:T("Uložená pozice"), FSC:T("Přepne náhled z okna na uloženou pozici ikony na obrazovce."), "test")
    UI.Help(preview.combatCheck, FSC:T("Simulovat boj"), FSC:T("Vyzkoušej zobrazení ikony s volbou Pouze v boji a záblesk po skončení odpočtu."), "test")
    UI.Help(preview.choices.range, FSC:T("Mimo dosah"), FSC:T("Ukáže červené zabarvení při nedostatečném dosahu na cíl."), "test", IconOptionDisabled)
    UI.Help(preview.choices.mana, FSC:T("Nedostatek many"), FSC:T("Ukáže modré zabarvení, pokud je pro ikonu zapnuté. Zkus i doběhnutí odpočtu s nedostatkem many."), "test", IconOptionDisabled)
    UI.Help(preview.countdownButton, FSC:T("Test odpočtu"), FSC:T("Přehraje pětisekundový odpočet s nastavením číslic a záblesku vybrané ikony."), "test")
    UI.Help(preview.chargeButton, FSC:T("Test nabíjení"), FSC:T("Ukáže okraj odpočtu pro nabití a přechod z jednoho dostupného nabití na dvě."), "test")
    UI.Help(preview.flashButton, FSC:T("Test záblesku"), FSC:T("Přehraje záblesk s nastavenou intenzitou. Funguje i před zapnutím automatického upozornění."), "test",
        function()
            local entry = FSC:FindEntry(FSC.selectedUID)
            return entry and FSC:T("V záložce Boj a upozornění nastav intenzitu vyšší než 0 %.") or FSC:T("Nejprve vyber kouzlo.")
        end)
    UI.Help(preview.resetButton, FSC:T("Obnovit náhled"), FSC:T("Zastaví test a vrátí ikonu do výchozího stavu náhledu."), "test")
end

local function Rows(window, buffs)
    if not window or not window.content then return end
    for _, row in ipairs({window.content:GetChildren()}) do
        if row.remove then
            UI.Help(row, FSC:T("Vybrat pro úpravu"), buffs and FSC:T("Vybere buff a otevře jeho pracovní náhled pro přesun. Cooldowny zůstávají zamčené.")
                or FSC:T("Vybere ikonu pro úpravu vzhledu, polohy a upozornění."))
            UI.Help(row.remove, FSC:T("Odebrat ze sledování"), FSC:T("Odstraní tento záznam a jeho nastavení z addonu. Kouzlo ve spellbooku ani buff na postavě se tím nemění."))
        end
    end
end

local buffCreate = FSC.CreateBuffOptions
function FSC:CreateBuffOptions()
    local window = buffCreate(self); self:AddBuffSettingsHelp(window); return window
end
local cooldownCreate = FSC.CreateOptions
function FSC:CreateOptions()
    cooldownCreate(self); self:AddCooldownSettingsHelp(self.window)
end
local buffRefresh = FSC.RefreshBuffOptions
function FSC:RefreshBuffOptions() buffRefresh(self); Rows(self.buffOptions, true) end
local cooldownRefresh = FSC.RefreshOptions
function FSC:RefreshOptions() cooldownRefresh(self); Rows(self.window, false) end

local catalogRefresh = FSC.RefreshBuffCatalog
function FSC:RefreshBuffCatalog()
    catalogRefresh(self)
    local window = self.buffCatalogWindow
    if not window then return end
    UI.Help(window.search, FSC:T("Hledání buffu"), FSC:T("Filtruje nabídku podle názvu nebo spell ID. Vymazání pole znovu zobrazí celou nabídku."))
    UI.Help(window.refreshButton, FSC:T("Obnovit nabídku"), FSC:T("Mimo boj načte další právě aktivní vlastní buffy, které hra zpřístupňuje. Poznané buffy si addon zapamatuje."))
    for _, row in ipairs(window.rows) do
        UI.Help(row, FSC:T("Vybrat buff"), FSC:T("Přidá buff do sledování, nebo otevře už přidaný buff. Potom zapne jeho pracovní náhled."))
        UI.Help(row.add, FSC:T("Vybrat tento buff"), FSC:T("Přidá buff do sledování, nebo otevře jeho stávající nastavení a náhled."))
    end
end
