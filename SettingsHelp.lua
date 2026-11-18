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
        if help.kind == "test" then tip:AddLine("POUZE TESTOVACÍ NÁHLED", 0.3, 0.9, 0.85, true)
        elseif help.kind == "saved" then tip:AddLine("Ukládá se pro vybraný záznam a aktivní spec", 0.65, 0.8, 1, true) end
        local text = type(help.body) == "function" and help.body(self) or help.body
        tip:AddLine(text or "", 0.92, 0.94, 0.96, true)
        if help.disabled and self.IsEnabled and not self:IsEnabled() then
            tip:AddLine(type(help.disabled) == "function" and help.disabled(self) or help.disabled, 1, 0.75, 0.35, true)
        elseif (help.kind == "saved" or help.kind == "test") and self.IsEnabled and not self:IsEnabled() then
            tip:AddLine("Nejprve vyber záznam v levém seznamu.", 1, 0.75, 0.35, true)
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
    local kind = buffs and "buffu" or "kouzla"
    UI.Help(window.input, "Přidání " .. kind, buffs
        and "Zadej název buffu nebo ID jeho aury. Proc může mít jiné ID než talent nebo sesílané kouzlo. Potvrď Enterem nebo tlačítkem Přidat buff."
        or "Zadej název kouzla ze hry nebo spell ID. Potvrď Enterem nebo tlačítkem Přidat.")
    UI.Help(window.addButton, "Přidat do seznamu", "Přidá záznam ze vstupního pole. Už přidaný záznam vybere pro úpravu.")
    for slot, check in ipairs({window.spec1, window.spec2}) do
        UI.Help(check, "Sledovat ve specu " .. slot, "Určuje, ve které sadě talentů se záznam zobrazuje. Můžeš zapnout oba specy. Vzhled, polohu a ostatní volby má každý spec vlastní.")
    end
    UI.Help(window.sizeLess, "Zmenšit o 1 pixel", "Zmenší vybraný motiv. V náhledu lze použít také Shift + kolečko myši.", "saved")
    UI.Help(window.sizeMore, "Zvětšit o 1 pixel", "Zvětší vybraný motiv. V náhledu lze použít také Shift + kolečko myši.", "saved")
    UI.Help(window.centerButton, "Přesunout na střed", "Nastaví souřadnice X = 0 a Y = 0. Nová poloha se uloží pro aktivní spec.", "saved")
    UI.Help(window.combatOnly, "Pouze v boji", "Po zapnutí se skutečný efekt zobrazuje pouze během boje. Odemčený pracovní náhled můžeš upravovat i mimo boj.", "saved")
    UI.Help(window.categoryTabs.cooldowns, "Cooldowny", "Otevře nastavení samostatných ikon cooldownů. Tato sekce má vlastní zámek ikon.")
    UI.Help(window.categoryTabs.buffs, "Buffy a procy", "Otevře sledování buffů na postavě. Odemknutí náhledu buffu nechává cooldowny zamčené.")
    window:HookScript("OnHide", function() FSC:HideSettingsHelp() end)
end

function FSC:AddBuffSettingsHelp(window)
    if window.fscBuffHelpAttached then return end
    window.fscBuffHelpAttached = true
    Common(window, true)
    local saved = "saved"
    UI.Help(window.chooseBuff, "Buffy pro tvoji classu", "Otevře seznam s hledáním. Obsahuje předvolby pro classu a další vlastní buffy poznané mimo boj. Výběr otevře náhled buffu.")
    UI.Help(window.iconStyle, "Ikona buffu", "Použije vlastní ikonku vybraného buffu. Kliknutí otevře pracovní náhled pro přesun a velikost.", saved)
    UI.Help(window.lightningStyle, "Vlevo a vpravo", "Zobrazí dvojici bočních motivů. Dvojice má společnou polohu a velikost. U Paladina jsou to dva zlaté meče.", saved)
    UI.Help(window.topStyle, "Horní motiv", "Zobrazí jeden vodorovný motiv. U Paladina používá zlatou světelnou záři. Polohu můžeš zvolit kdekoliv na obrazovce.", saved)
    for _, card in ipairs(window.themeCards) do
        local key = card.theme
        UI.Help(card, "Motiv: " .. self.buffThemes[key].name,
            key == "paladin" and "Po stranách jsou zlaté meče, pro horní zobrazení samostatná zlatá světelná záře. Motiv můžeš použít u libovolného buffu a classy."
            or "Změní grafiku bočního nebo horního motivu. Vybraná karta je zvýrazněná a kliknutí otevře náhled.", saved,
            "Motivy vybírej u bočního nebo horního zobrazení. Ikona buffu používá vlastní obrázek.")
    end
    UI.Help(window.stacks, "Počet stacků", "Zapne číslo se skutečným počtem stacků. U jednoho procu můžeš číslo vypnout.", saved)
    UI.Help(window.duration, "Číselný odpočet času", "Zobrazí zbývající čas číslem. Tato volba je dostupná u ikony s prahem Od stacku = 1.", saved,
        "Pro číslo času vyber Ikona buffu a nastav Od stacku na 1. U oblouků lze čas znázornit mizením motivu.")
    UI.Help(window.opacity, "Průhlednost motivu", "0 % = plně viditelný motiv, 100 % = neviditelný motiv. Síla blikání a pulzování má vlastní posuvník.", saved)
    UI.Help(window.timeFade, "Časový úbytek se šedým podkladem", "Celý motiv zůstává jako tlumený šedý podklad. Barevná část se podle zbývajícího času zkracuje od obou krajů ke středu a drží svou intenzitu. Efekt běží až od zvoleného počtu stacků a při poklesu pod něj se vypne. Používej pro buffy s dobou trvání.", saved,
        "Nejprve vyber buff. Volba také vyžaduje podporu nativního časovače v klientu.", 370)
    UI.Help(window.timeFadeStacks, "Časový úbytek od stacku", "Samostatný práh pouze pro časový efekt, od 1 do nastaveného Maxima. Příklad: 5 znamená běžný motiv při 1–4 stacích; od 5 barevná část ukazuje zbývající čas a uplynulá část zůstává šedá. Pokles pod 5 časový efekt vypne. Nemění práh zobrazení celého buffu.", saved,
        "Nejprve zapni časový efekt v záložce Vzhled.")
    UI.Help(window.timeFadePreview, "Test zbytku času", "Posuvník mění pouze odemčený pracovní náhled mimo boj. Skutečný čas buffu řídí hra. 100 % = celé trvání, 50 % = polovina, 0 % = konec. Testovací hodnota se neukládá.", "test",
        function()
            local layout = BuffLayout()
            if layout and layout.timeFade and (FSC.buffPreviewStacks or layout.maxStacks) < layout.timeFadeStacks then
                return "V záložce Test náhledu nastav testovací počet alespoň na " .. layout.timeFadeStacks .. " stacků, nebo stiskni Nastavit maximum."
            end
            return "Zapni časový efekt ve Vzhledu a pracovní náhled v záložce Test náhledu."
        end)
    UI.Help(window.minimum, "Od kterého stacku zobrazit", "Nejnižší počet stacků pro zobrazení motivu. Od 5 / Maximum 5 znamená zobrazení až při pěti stacích. Rozsah je 1–40.", saved)
    UI.Help(window.maximum, "Maximum pro vzhled a upozornění", "Určuje plné nabití motivu. Používá jej zesilování, režim Po částech, záře, blikání a pulzování. Zvuk jej použije při zapnuté volbě Při maximu. Nemění skutečné maximum kouzla ve hře.", saved)
    UI.Help(window.fullMotif, "Celý motiv", "Zobrazí celý motiv po dosažení hodnoty Od stacku. Vyber právě jeden ze tří režimů: Celý motiv, Zesilování nebo Po částech.", saved)
    UI.Help(window.progressive, "Zesilování podle stacků", "S přibývajícími stacky zesiluje celý motiv až na nastavené Maximum. Vyber právě jeden režim zobrazení.", saved,
        "Zesilování vyžaduje podporu pravidel stacků v klientu.")
    UI.Help(window.revealParts, "Postupné části motivu", "S přibývajícími stacky přibývá pět částí obrázku. Při Maximu je celý. Kroky se přizpůsobí nastavenému maximu. Vyber právě jeden režim zobrazení.", saved,
        function()
            local layout = BuffLayout()
            if not layout then return "Nejprve vyber buff." end
            if layout.style == "icon" then return "Vyber boční nebo horní motiv; ikona se nedělí na části." end
            if layout.maxStacks < 2 then return "Nastav Maximum alespoň na 2." end
            return "Tento klient nepodporuje postupné části."
        end)
    UI.Help(window.glow, "Stálá záře při maximu", "Při dosažení Maxima přidá trvalou jasnější vrstvu. Po poklesu stacků záře zhasne. Lze kombinovat s blikáním a pulzováním.", saved,
        "Záře podle stacků vyžaduje podporu prahu v klientu.")
    UI.Help(window.flashMax, "Blikání při maximu", "Po dobu plných stacků opakuje dvojici krátkých ostrých záblesků s pauzou. Po spotřebování stacků hned skončí. Lze zapnout společně s pulzováním.", saved,
        "Blikání vyžaduje podporu prahu stacků v klientu.")
    UI.Help(window.pulseMax, "Pulzování při maximu", "Po dobu plných stacků plynule zesiluje a slábne záře. Po spotřebování stacků hned skončí. Lze zapnout společně s blikáním.", saved,
        "Pulzování vyžaduje podporu prahu stacků v klientu.")
    UI.Help(window.alertIntensity, "Síla vizuálního upozornění", "Nastavuje sílu blikání a pulzování od 0 do 100 %. Je nezávislá na průhlednosti základního motivu. 0 % upozornění skryje.", saved,
        "Zapni Blikat při maximu nebo Pulzovat při maximu.")
    UI.Help(window.alertPreview, "Vyzkoušet maximum", "Odemkne náhled a nastaví testovací počet na Maximum. Ukáže motiv včetně zapnuté záře, blikání a pulzování bez skutečného procu.", "test",
        "Nejprve vyber buff.")
    UI.Help(window.soundEnabled, "Zvukové upozornění", "Zapne jeden zvuk při dosažení prahu směrem nahoru. Znovu se ozve po poklesu pod práh a dalším dosažení. V boji je přesný práh dostupný jen pro buffy, jejichž stacky hra zpřístupňuje.", saved)
    UI.Help(window.soundAtMax, "Zvuk při nastaveném maximu", "Zapnuto: zvuk sleduje hodnotu Maximum. Vypnuto: můžeš zadat nezávislý Vlastní počet. Platí omezení dostupnosti stacků během boje.", saved)
    UI.Help(window.soundStacks, "Vlastní počet stacků pro zvuk", "Počet 1–40, při jehož dosažení se ozve vybraný zvuk. Může být jiný než práh zobrazení motivu.", saved,
        function() return BuffLayout() and "Zruš volbu Při maximu, abys mohl zadat vlastní počet." or "Nejprve vyber buff." end)
    UI.Help(window.soundChoice, "Vybrat zvuk", "Otevře 16 zvuků z Blizzardova cooldown manageru. Poslechnout přehraje ukázku vybraného zvuku.", saved)
    UI.Help(window.soundTest, "Poslechnout ukázku", "Přehraje jen vybraný zvuk, i když je upozornění vypnuté. Další ukázka zastaví předchozí ukázku. Používá zvukové rozhraní klienta stejně jako Blizzardův cooldown manager. Pokud klient přehrání odmítne, zobrazí se zpráva.", "test")
    for index, button in ipairs(window.soundPicker.choices) do
        UI.Help(button, self.buffSounds[index].name, "Vybere tento zvuk pro aktivní spec. Ukázku přehraje tlačítko Poslechnout.", saved)
    end
    window.soundPicker:HookScript("OnHide", function() FSC:HideSettingsHelp() end)
    UI.Help(window.x, "Vodorovná poloha X", "Pixely od středu obrazovky: kladné hodnoty doprava, záporné doleva. Potvrď Enterem; Escape úpravu zruší.", saved)
    UI.Help(window.y, "Svislá poloha Y", "Pixely od středu obrazovky: kladné hodnoty nahoru, záporné dolů. Potvrď Enterem; Escape úpravu zruší.", saved)
    UI.Help(window.sideGap, "Rozestup stran v pixelech", "Vzdálenost mezi vnitřními okraji levé a pravé části, 0–2000 px. Nula je přiblíží k sobě. Změna rozestupu nemění velikost motivů ani střed dvojice. Platí pro celý motiv, Po částech, šedý podklad i upozornění a ukládá se pro každý buff a spec zvlášť. Enter potvrdí, Escape zruší rozepsanou změnu.", saved,
        "Rozestup nastavuješ u zobrazení Vlevo + vpravo.")
    UI.Help(window.sizeInput, "Velikost motivu v pixelech", "Zadej přímo velikost obrázku. Enter potvrdí, Escape zruší rozepsanou změnu. Tlačítka −/+ mění velikost po jednom pixelu. Mezera mezi stranami má vlastní hodnotu.", saved)
    UI.Help(window.positionPreviewLink, "Přesunout motiv myší", "Otevře samostatnou záložku Test náhledu a zapne pracovní náhled vybraného buffu. Přetažení a velikost se ukládají; testovací stacky a čas se neukládají.")
    UI.Help(window.alertsPreviewLink, "Vyzkoušet nastavené efekty", "Otevře záložku Test náhledu a ukáže zvolené maximum se zapnutou září, blikáním a pulzováním. Skutečný buff se tím nemění.", "test")
    UI.Help(window.previewLess, "Test: méně stacků", "Sníží pouze testovací počet v náhledu. Skutečný buff ani uložené Maximum nemění.", "test", "Nejprve odemkni náhled buffu.")
    UI.Help(window.previewMore, "Test: více stacků", "Zvýší pouze testovací počet v náhledu, nejvýše na nastavené Maximum.", "test", "Nejprve odemkni náhled buffu.")
    UI.Help(window.lock, "Odemknout nebo zamknout náhled", "Odemčení zobrazí vybraný buff i bez procu. Přetáhni jej za rámeček; Shift + kolečko mění velikost. Poloha a velikost se ukládají. Šedá silueta je jen pomůcka. Cooldowny zůstávají zamčené.")
    UI.Help(window.settingsTabs.appearance, "Vzhled", "Tvar, motiv, průhlednost, čísla a časové mizení obrázku.")
    UI.Help(window.settingsTabs.alerts, "Stacky a upozornění", "Práh zobrazení, maximum, režim stacků, vizuální a zvuková upozornění.")
    UI.Help(window.settingsTabs.position, "Poloha", "Velikost obrázku, mezera mezi stranami, přesná poloha X/Y a zobrazení jen v boji. Tyto hodnoty se ukládají.")
    UI.Help(window.settingsTabs.preview, "Test náhledu", "Samostatná zkouška počtu stacků, času a efektů. Testovací hodnoty se neukládají. Přetažení motivu a jeho velikost se ukládají.")
end

function FSC:AddCooldownSettingsHelp(window)
    if window.fscCooldownHelpAttached then return end
    window.fscCooldownHelpAttached = true
    Common(window, false)
    UI.Help(window.drop, "Přetáhnout kouzlo", "Otevři spellbook klávesou P a přetáhni sem kouzlo. Přidá se jako samostatně nastavitelná ikona.")
    UI.Help(window.numbers, "Číselný odpočet", "Zapne číslo se zbývajícím cooldownem na ikoně.", "saved")
    UI.Help(window.spellName, "Název pod ikonou", "Zobrazí název sledovaného kouzla pod jeho ikonou.", "saved")
    UI.Help(window.opacitySlider, "Průhlednost ikony", "0 % = plně viditelná, 100 % = neviditelná. Kolečko mění hodnotu po jednom procentu.", "saved")
    UI.Help(window.xInput, "Vodorovná poloha X", "Pixely od středu: kladná hodnota doprava, záporná doleva. Enter potvrdí, Escape zruší rozepsanou změnu.", "saved")
    UI.Help(window.yInput, "Svislá poloha Y", "Pixely od středu: kladná hodnota nahoru, záporná dolů. Enter potvrdí, Escape zruší rozepsanou změnu.", "saved")
    for _, item in ipairs({{window.xLess,"X − 1 px"},{window.xMore,"X + 1 px"},{window.yLess,"Y − 1 px"},{window.yMore,"Y + 1 px"}}) do
        UI.Help(item[1], item[2], "Posune vybranou ikonu o jeden pixel v příslušném směru.", "saved")
    end
    UI.Help(window.manaTint, "Modře při nedostatku many", "Při nedostatku many zbarví ikonu modře. Nedostatečný dosah na cíl má přednost a zůstává červený.", "saved")
    UI.Help(window.flashReady, "Záblesk po skončení cooldownu", "Při dokončení cooldownu během boje upozorní krátkým zábleskem. Sílu nastavíš samostatným posuvníkem.", "saved")
    UI.Help(window.flashIntensitySlider, "Intenzita záblesku", "0–100 % síly upozornění po cooldownu. Nezávisí na průhlednosti ikony; 0 % záblesk vypne.", "saved")
    UI.Help(window.flashTest, "Test záblesku", "Přehraje ukázku záblesku na vybrané ikoně i mimo boj. Nespouští kouzlo ani jeho skutečný cooldown.", "test")
    UI.Help(window.lockButton, "Zámek ikon cooldownů", "Odemčení umožní ikony přesouvat a měnit velikost pomocí Shift + kolečko. Poloha a velikost se ukládají pro aktivní spec. Náhledy buffů mají vlastní zámek.")
end

local function Rows(window, buffs)
    if not window or not window.content then return end
    for _, row in ipairs({window.content:GetChildren()}) do
        if row.remove then
            UI.Help(row, "Vybrat pro úpravu", buffs and "Vybere buff a otevře jeho pracovní náhled pro přesun. Cooldowny zůstávají zamčené."
                or "Vybere ikonu pro úpravu vzhledu, polohy a upozornění.")
            UI.Help(row.remove, "Odebrat ze sledování", "Odstraní tento záznam a jeho nastavení z addonu. Kouzlo ve spellbooku ani buff na postavě se tím nemění.")
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
    UI.Help(window.search, "Hledání buffu", "Filtruje nabídku podle názvu nebo spell ID. Vymazání pole znovu zobrazí celou nabídku.")
    UI.Help(window.refreshButton, "Obnovit nabídku", "Mimo boj načte další právě aktivní vlastní buffy, které hra zpřístupňuje. Poznané buffy si addon zapamatuje.")
    for _, row in ipairs(window.rows) do
        UI.Help(row, "Vybrat buff", "Přidá buff do sledování, nebo otevře už přidaný buff. Potom zapne jeho pracovní náhled.")
        UI.Help(row.add, "Vybrat tento buff", "Přidá buff do sledování, nebo otevře jeho stávající nastavení a náhled.")
    end
end
