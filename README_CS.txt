FREE SPELL COOLDOWNS 1.16.2
Samostatné cooldowny a buffy/procy pro WoW Forever 1.60.1 (Interface 16001)

NOVINKA 1.16.2 – ČESKÉ ZNAKY V POTVRZENÍ ZMĚNY JAZYKA
- Text a tlačítka potvrzení používají font addonu s českou diakritikou.

NOVINKY 1.16.1 – POTVRZENÍ JAZYKA A PŮVODNÍ VZHLED
- Při volbě jiného jazyka se otevře potvrzení. Přepnout uloží jazyk
  pro postavu a znovu načte herní rozhraní. Zrušit dialog zavře.
- Okna mají původní tmavě modrý vzhled z verze 1.15.0.
- Ve Vzhledu ikony můžeš napsat velikost 24–160 px a potvrdit Enterem.
  Kliknutí na + nebo − změní velikost o 1 px. Podržení změnu opakuje.

NOVINKY 1.15.0 – ČEŠTINA A ANGLIČTINA
- Čeština / English je v horní části nastavení Cooldownů i Buffů a proců.
  Volba se uloží pro postavu a následně se znovu načte herní rozhraní.
- Jen probliknutí po nabití cooldownu ukazuje vybranou ikonu v Testu náhledu.
  Test odpočtu a test nabíjení ukazují, kolik sekund ještě zbývá.
- Průhlednost ve Vzhledu ikony platí i pro ikonu při záblesku. Sílu záře
  můžeš měnit zvlášť v položce Intenzita záblesku.

NOVINKY 1.14.0 – JEN PROBLIKNUTÍ PO COOLDOWNU
- Pod Boj a upozornění můžeš u kouzla zapnout Jen probliknutí po nabití cooldownu.
  Ikona se ukáže krátce po skončení cooldownu nebo doběhnutí nabíjení.
- Velikost a polohu nastav ve Vzhledu ikony. Odemčenou ikonu jde přetáhnout
  jako při běžném nastavování. Sílu záblesku nastav v Boji a upozornění.
- Probliknout i mimo boj povolí upozornění při dokončení cooldownu mimo boj.
- Test náhledu přehraje efekt samostatně nebo na konci testovacího odpočtu.

NOVINKY 1.13.0 – ZÁLOŽKY COOLDOWNŮ A TEST NÁHLEDU
- Vzhled ikony obsahuje velikost, text, průhlednost a polohu v pixelech.
- Boj a upozornění obsahuje volbu Pouze v boji, zabarvení při nedostatku
  many a záblesk po dokončení cooldownu včetně jeho intenzity.
- Test náhledu umožní zkusit ikonu v okně i na uložené pozici, simulovat boj,
  nedostatečný dosah či nedostatek many, spustit odpočet a nabíjení nebo
  přehrát záblesk samostatně. Testovací stavy se neukládají.
- Opravené Pouze v boji zobrazí ikonu hned při vstupu do boje a schová ji
  po jeho skončení.

NOVINKY 1.12.0 - PŘEHLEDNĚJŠÍ NASTAVENÍ, POSTUPNÉ ČÁSTI A ZVUK MAELSTROMU
- Nastavení buffu má čtyři jednoznačné záložky: Vzhled, Stacky a zvuk,
  Poloha a Test náhledu. Aktivní záložka je barevně zvýrazněná a čitelná,
  nezešedne jako nedostupné tlačítko. Viditelné rámečky oddělují skupiny voleb.
- Poloha obsahuje Rozměry, Polohu na obrazovce a Kdy zobrazovat. Velikost
  obrázku lze zadat přímo číslem. Mezera mezi stranami je samostatně popsaná.
  X a Y mají slovní popisy směru a jednotek. Přesun na střed je u souřadnic.
- Zkoušení stacků a času je pouze v Test náhledu. Je zde stav náhledu,
  tlačítko Zapnout pracovní náhled / Dokončit úpravy náhledu, testovací počet,
  maximum a samostatný test času. Pokyny vysvětlují, proč je test nedostupný.
  Patička rozlišuje ukládané nastavení od dočasných testovacích hodnot.
- Opraveno zobrazení Po částech s časovým prahem 5: první čtyři kroky
  používají skutečné textury jako pátý krok, ne obrázek vložený do textového
  pole. Nativní maska ponechá běžné díly pod časovým prahem a nad ním přepne
  na barevný časový úbytek se šedým podkladem. Počet stacků se pro toto
  vykreslování v Lua nečte. Odpočet tedy neblokuje běžné kroky 1-2-3-4.
- Pro postupný Maelstrom od prvního stacku nastav ve Stacky a zvuk:
  Ukázat od stacku = 1, Maximum stacků = 5, Po částech. Ve Vzhledu můžeš
  nezávisle zapnout časový efekt a Spustit od stacku = 5. Vyšší práh pro
  samotné zobrazení nyní vysvětluje zpráva u nastavení stacků.
- Maelstrom Weapon, zvuk při 5 stacích: pokud jsou stacky skryté, addon
  může sledovat veřejný stav Blesku, který je současně okamžitý a bez many.
  Zvuk se ozve jednou při dosažení tohoto stavu a znovu po jeho spotřebování
  a dalším dosažení. Kontrola se zopakuje po aktualizaci herních údajů.
- Tento zvláštní signál vyžaduje dostupnou dobu sesílání a cenu Blesku.
  Záměrně se nepoužije, pokud se postava naučila Nature's Swiftness nebo
  Elemental Mastery, které by mohly stav zaměnit. Jiné prahy než 5 a ostatní
  buffy dál vyžadují dostupné stacky. Nejde o odhad mezilehlých stacků.
  Pokud je dostupný přímo skutečný počet, má přednost před tímto signálem.
- Stav zvuku už mimo boj neslibuje dostupnost skrytých stacků pro příští boj.
  Zjištěné omezení se připomene i po skončení boje. Přehrát ukázku zkouší
  samotný zvuk; nezaměňuje se s ověřením automatického prahu.
- Úplně ukonči WoW, přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns
  a hru znovu spusť. Složku WTF nemaž, obsahuje uložená nastavení.

OVĚŘENÍ 1.12.0
Simulované kontroly ověřují čtyři záložky, přepínání viditelnosti, jasný
aktivní stav, přímé zadání velikosti a zrušení změny, tooltipy a ukládání.
Grafické testy pokrývají skutečné díly pod časovým prahem i v prostředí bez
podpory obrázků v textu, přepnutí při pěti stacích, následný pokles, všechny
motivy a styly, šedý podklad a rozestup. Zvukové testy ověřují zvoleného Vlka
při veřejném signálu plného Maelstromu v boji, opakované nabití, chybějící
nebo skryté údaje, konflikt talentů a absenci čtení chráněné aury. Regresní
kontroly starších funkcí a obou speců prošly. Všechny viditelné popisky
a ovládání se vejdou do okna. Přímé ověření v běžící hře ještě zbývá.

NOVINKY 1.11.0 - ŠEDÝ ČASOVÝ PODKLAD, PRÁH STACKŮ, ROZESTUP A OPRAVY
- Časový úbytek ponechá celý motiv jako tlumený šedý podklad. Barevná část
  se od krajů zkracuje ke středu podle zbývající doby a zachovává svou sílu.
  Uplynulá část tedy nezmizí úplně. Při skončení buffu zhasne celý efekt.
- V části Vzhled je u časového efektu samostatné pole Od stacku. Při hodnotě
  5 se při 1-4 stacích používá běžný motiv; až od 5 ukazuje barevná plocha
  zbývající čas. Při poklesu pod 5 se časový efekt vypne. Práh lze zvolit od
  1 do nastaveného Maxima; výchozí hodnota je Maximum. Nezávisí na poli
  Od stacku v části Stacky a upozornění, které určuje zobrazení celého buffu.
- Test zbytku času je stále pouze náhled. Když je testovací počet stacků
  pod prahem časového efektu, posuvník se ztlumí a nápověda vysvětlí proč.
- V Poloha a náhled je Rozestup stran (px), dostupný pro Vlevo + vpravo.
  Udává mezeru mezi vnitřními okraji obou částí. Změna rozestupu neprotahuje
  obrázky. Rozsah je 0-2000 px. Velikost lze měnit samostatně a mezera zůstává
  stejná. Rozestup i časový práh se ukládají zvlášť pro každý buff a spec.
- Celý motiv, šedý podklad, jednotlivé části i upozornění nyní používají
  stejné předem zrcadlené obrázky. Tím se opravuje nesouhlas pravého meče
  mezi vrstvami, který vytvářel dojem dvou mečů vedle sebe.
- Přehrávání používá C_Sound.PlaySoundWithOptions jako cooldown manager
  tohoto klienta. Není závislé na starém globálním PlaySound. Poslechnout
  oznámí odmítnutí přehrávání, místo aby chyba zůstala tichá. Obnovení vzhledu
  už nespotřebuje přechod přes práh dřív, než dorazí zvukové vyhodnocení.
- V nastavení je aktuální stav zvuku: vypnuto, náhled, vypnutý spec, čekání
  na boj, připravený práh, odmítnuté přehrání nebo skryté stacky.
  OMEZENÍ ZŮSTÁVÁ: pokud hra během boje skrývá počet stacků, přesný zvuk při
  konkrétním počtu nelze zaručit. Ukázka zvuku je nezávislá na této podmínce.
- Opravené rozložení: popisky i tlačítka se umisťují přímo podle svých
  referencí. Nehledají se podle přesné shody starých souřadnic, které klient
  po škálování může vracet jako desetinná čísla. Velikost, Maximum, náhledy,
  plus/minus, přidávací tlačítka i ostatní prvky patří do správných záložek.
- Úplně ukonči WoW, přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns
  včetně Textures a obou souborů .toc a hru znovu spusť. Složku WTF nemaž.

OVĚŘENÍ 1.11.0
Regresní simulace Lua 5.1 / LuaJIT reprodukují chyby 1.10 se souřadnicemi
a starým zvukovým voláním a ověřují jejich opravu. Pokrývají šedý podklad,
časový průběh 30/15/0 sekund, přechod 4-5-4 stacky, všechny motivy, styly
a režimy, samostatný rozestup, zarovnání pravého meče, oba specy a nové
načtení. Zvlášť se ověřuje zvuk bez starých aliasů, odmítnutí přehrávání,
skryté stacky bez jejich čtení a zachování původních cooldownů a zámků.
Kontroly všech záložek zahrnují i popisky a desetinné souřadnice; okna se
vejdou při rozlišení 720p, 1080p i 1440p. Původní grafické soubory zůstaly
beze změny. Přímé ověření v běžícím herním klientu ještě zbývá.

NOVINKY 1.10.0 - PALADIN A SROZUMITELNĚJŠÍ NASTAVENÍ
- Pátý motiv Paladin: vlevo a vpravo původní zlaté meče podle předlohy.
  Horní varianta používá samostatnou vodorovnou zlatou světelnou záři,
  aby meč nebyl otočený nad postavou. Karty v nastavení ukazují zvolený tvar.
  Obě varianty podporují Po částech, zesilování, záři, blikání, pulzování
  a časové mizení. Jejich nastavení je samostatné pro každý buff a spec.
- Ovládací prvky buffů i cooldownů mají české vysvětlivky po najetí myší.
  Popisují účinek, jednotky, ukládání a důvod případné nedostupnosti volby.
  Nápovědu mají i karty motivů, seznamy, přepínače sekcí a výběr zvuků.
- Posuvník má název Test zbytku času (jen náhled). Testovací prvky jsou
  v nápovědě označené POUZE TESTOVACÍ NÁHLED. Posuvník ani testovací počet
  stacků nemění skutečný buff; jejich hodnoty se neukládají do nastavení.
  Časový test se zpřístupní po zapnutí časového mizení a odemknutí náhledu.
  Nedostupné posuvníky jsou ztlumené a jejich nápověda vysvětluje postup.
- Celý motiv, Zesilování a Po částech používají přepínače pro výběr jedné
  možnosti. Náhled maxima lze spustit i s vypnutým blikáním a pulzováním.
- U klienta bez podpory prahu zůstávají dříve zapnuté vizuální volby
  vypnutelné. Starší nastavení, polohy a oddělené zámky zůstávají zachované.
- Úplně ukonči WoW, přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns
  včetně Textures a souborů .toc a hru znovu spusť. Složku WTF nemaž.

OVĚŘENÍ 1.10.0
Simulované kontroly Lua 5.1 / LuaJIT pokrývají všech pět motivů, styly,
stacky, upozornění, časové mizení, oba specy a původní cooldowny. Samostatně
ověřují tooltipy, jejich český font, nedostupné volby, zachované kliknutí,
testovací hodnoty bez změny uložených nastavení a oddělené zámky sekcí.
Původní BLP grafika odpovídá šesti ověřeným souborům klienta. Sto TGA částí
se skládá do odpovídajících celých motivů. Rozložení ovládání se vejde do
okna 1040 x 700. Přímé ověření v běžícím herním klientu ještě zbývá.

NOVINKY 1.9.0 - ŠIRŠÍ NASTAVENÍ, ZVUK A ČAS V MOTIVU
- Obě hlavní sekce mají širší a nižší okno 1040 x 700. Přizpůsobí se velikosti
  obrazovky. Seznam kouzel nebo buffů je vlevo, nastavení vybraného záznamu
  vpravo. Už se nemusí zobrazovat dlouhý panel přes celou výšku monitoru.
- Buffy / procy mají tři části: Vzhled, Stacky a upozornění, Poloha a náhled.
  Cooldowny jsou rozdělené do bloků Vzhled ikony, Poloha v pixelech a Boj
  a upozornění. Poslední vybraná část buffového nastavení se pamatuje.
- Ve Vzhledu je volba Odpočítávat čas mizením od krajů ke středu. Obrázek
  buffu se podle zbývající doby současně ztrácí zleva a zprava. Měkký okraj
  zachovává původní tvar motivu. Obnovení buffu obnoví i časový vzhled.
  Volba funguje s ikonou i oběma tvary oblouků, všemi motivy a režimy stacků.
  Počty stacků a jejich volitelný textový odpočet zůstávají čitelné.
- Tento efekt je pro BUFF S DOBOU TRVÁNÍ. U trvalého buffu jej nezapínej.
  Platí po dobu zobrazení buffu, nejen při plných stackách. Náhled zbytku času
  umožní vyzkoušet 0-100 % bez aktivního buffu. Šedá pomocná silueta zůstává
  při úpravě celá; do skutečného procu se nepřenáší.
- Ve Stacky a upozornění je Zapnout zvuk. Při maximu automaticky sleduje
  hodnotu Maximum. Po zrušení této volby zadej Vlastní počet v rozsahu 1-40.
  Ozve se jeden zvuk při dosažení nebo překročení prahu směrem nahoru.
  Další přehrání se povolí po poklesu pod práh. Držení stacků zvuk neopakuje.
- Na výběr je 16 zvuků přímo z Blizzardova cooldown manageru: zvonky,
  cinknutí, pípnutí, kapka vody, klaksony, kovadlina, pokladna, kočka,
  slepice, ovce a vlk. Poslechnout přehraje vybraný zvuk i při vypnutém
  upozornění. Další ukázka zastaví předchozí ukázku. Zvuky jiných buffů se
  navzájem nezastavují. Používá se herní zvukový kanál Master.
- DŮLEŽITÉ OMEZENÍ ZVUKU: přesný počet stacků může být během boje skrytý.
  Aktuální AddAuraSound umí přidání buffu nebo zvýšení stacků, ale nemá
  parametr pro konkrétní počet. Addon proto přehraje přesné upozornění jen
  tehdy, když hra zpřístupní stacky daného buffu. U skrytého buffu je zvuk
  během omezení tichý; žádný chráněný počet se nečte a nenahrazuje odhadem.
  Tato verze tedy nemůže zaručit zvuk při pěti stackách Maelstromu v boji.
  Vizuální efekty a časové mizení používají nativní vykreslování a fungují
  nezávisle na dostupnosti stacků pro zvuk. Omezení je uvedené i v nastavení.
- Zvuk, vybraný počet, zvuková varianta a časové mizení se ukládají pro každý
  buff a spec samostatně. Nové volby jsou při aktualizaci vypnuté. Původní
  motivy, souřadnice, cooldowny a zámky zůstávají uložené.
- Úplně ukonči WoW, přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns
  včetně souborů .toc a Textures a hru znovu spusť. Složku WTF nemaž.

OVĚŘENÍ 1.9.0
Prošly kontroly Lua 5.1 / LuaJIT: širší okna a všechny části při rozlišení
720p, původní ovládací prvky, zvuk při maximu i vlastním prahu, opětovné
spuštění po spotřebování, tiché náhledy a vypnutí. Skryté bojové aury se
nečtou; veřejná aura podporuje zvuk i v boji. Nativní časový posun byl
ověřen pro 30 / 15 / 0 sekund i obnovení doby, všechny motivy, tvary a režimy.
Oba specy a nové volby se obnoví v nové relaci. Regresní kontroly prošly.
Rozložení bylo vizuálně zkontrolováno z vytvořených ovládacích prvků.
Přímé ověření v běžícím herním klientu ještě zbývá.

NOVINKY 1.8.0 - BLIKÁNÍ A PULZOVÁNÍ PŘI MAXIMU
- V Buffy / procy jsou dvě nové nezávislé volby: Blikat při maximu
  a Pulzovat při maximu. Můžeš zapnout jednu, obě současně nebo žádnou.
- Blikání opakuje dvojici krátkých jasných záblesků s pauzou. Pulzování
  plynule zesiluje a zeslabuje záři motivu. Oba efekty běží po dobu, kdy
  počet stacků dosahuje nastaveného Maxima. Po spotřebování ihned zhasnou.
  Blikání není jednorázové upozornění při přechodu na maximum.
- Síla upozornění má vlastní posuvník 0-100 %. Je nezávislá na průhlednosti
  základního motivu; 0 % upozornění skryje. Náhled maxima ukáže oba vybrané
  efekty bez aktivního buffu. Tlačítky náhledu stacků ověříš jejich zhasnutí.
- Funguje ikona, horní oblouk i boční dvojice, všechny čtyři motivy a všechny
  tři režimy zobrazení stacků včetně Po částech. Při upozornění září celý
  motiv. Volba Zářit při maximu dál ovládá samostatnou stálou záři.
- Obě volby i síla se ukládají pro každý buff a spec zvlášť. Respektují
  přiřazení specu a Pouze v boji. Původní nastavení cooldownů se nemění.
  Při aktualizaci jsou nové volby vypnuté, zapni je u požadovaného buffu.
- Práh vyhodnocuje přímo nativní herní API, animace nečtou počet stacků
  ani stav nativního widgetu. Klient bez podpory minimálního počtu aplikací
  vysvětlí omezení v nastavení a zachová běžné zobrazení buffu.
- Úplně ukonči WoW, přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns
  a hru znovu spusť. Složku WTF nemaž, obsahuje tvoje uložená nastavení.

OVĚŘENÍ 1.8.0
Prošly simulované kontroly Lua 5.1 / LuaJIT: odlišení ostrých záblesků od
plynulého pulzování, souběh obou efektů, práh maxima i jeho vlastní hodnota,
spotřebování buffu, 0-100 % intenzity nezávislé na průhlednosti, všechny
motivy, tři tvary, tři režimy stacků, boj a oba specy. Nová relace obnovuje
nastavení obou speců. Regresní kontroly starších funkcí také prošly.
Integrace prahu byla porovnána se zdrojovým souborem CustomAuraButton
z nainstalovaného klienta Forever 1.60.1.70938. Přímé ověření zobrazení
v běžícím herním klientu ještě zbývá.

NOVINKY 1.7.0 - MOTIV PO ČÁSTECH
- U buffu jsou tři vzájemně výlučné režimy: Celý motiv, Zesilování a nově
  Po částech. Nový režim funguje pro Blesky, Oheň, Led i Přírodu, pro horní
  oblouk i dvojici bočních oblouků. Ikona buffu má nadále vlastní zobrazení.
- V režimu Po částech s přibývajícími stacky přibývají části motivu; při
  spotřebování stacků opět mizí. Na nastaveném maximu je vidět celý motiv.
- Maelstrom Weapon, horní oblouk, od 1 / maximum 5:
  1 = malý levý blesk, 2 = přibude malý pravý, 3 = větší levý,
  4 = větší pravý, 5 = prostřední blesk. Ostatní motivy se obdobně skládají
  od krajů ke středu. Boční varianta používá části na obou stranách.
- Pět částí se přizpůsobí nastavenému maximu. U maxima 10 přibývají při
  1, 4, 6, 8 a 10 stacích. U nižšího maxima mohou přibýt některé současně.
  Od stacku nadále určuje nejnižší počet pro zobrazení efektu.
- Kliknutí na Po částech otevře přesouvatelný náhled na prvním povoleném
  stacku. Tlačítky Náhled stacků vyzkoušíš jednotlivé kroky. Šedá silueta
  ukazuje celkový rozměr motivu jen při úpravě. Poloha, velikost, průhlednost,
  volitelný počet stacků a záře při maximu zůstávají dostupné.
- Zvolený režim se ukládá pro každý buff a spec zvlášť. Starší nastavení
  celého motivu nebo zesilování zůstává při aktualizaci zachováno.
- Grafické části jsou přibalené ve složce Textures/Parts. Úplně ukonči hru,
  přepiš CELOU složku FreeSpellCooldowns v Interface/AddOns a hru znovu spusť.
  Pouhé /reload pro nově přidané textury nestačí. Složku WTF nemaž.

OVĚŘENÍ 1.7.0
Kontroly v Lua 5.1 / LuaJIT se simulovaným WoW API prošly: všechny čtyři
motivy a oba tvary, jednotlivé kroky náhledu, skutečné změny počtu v simulaci
1-5-3-1, vlastní maximum a práh, volitelná čísla, oba specy a načtení po
restartu. Regresní kontroly původních cooldownů a zámků také prošly.
Všech 80 nových obrázků bylo dekódováno; kontrola potvrzuje přibývající
pokrytí a skládání jednotlivých částí do původního motivu.
Vlastní proc vykresluje nativní herní API bez čtení omezeného počtu stacků
v Lua. Při chybějící podpoře minimálního počtu aplikací používá nový režim
nativní formátování obrázku; dodatečná záře pak nemusí být dostupná.
Aktualizace ještě nebyla ověřena přímo v běžícím herním klientu.

OPRAVA MOTIVŮ A NÁHLEDU 1.6.2
- Opraven případ, kdy se skutečný buff správně sledoval a ukazoval počet
  stacků, ale jeho motiv zůstával neviditelný kvůli starým cestám k texturám.
- Čtyři původní motivy z WoW jsou nyní přímo v balíčku ve složce Textures.
  Náhled, obrázkové karty i skutečné procy používají stejné přibalené soubory.
- Opravena orientace podle skutečné grafiky: Maelstrom je přirozeně horní
  motiv, oheň, led a příroda jsou boční. Pro druhý tvar se správně otočí.
- Při úpravě je vždy vidět šedá silueta právě zvoleného motivu s průhledností
  55 %. Pomáhá s polohou a velikostí i při skutečné průhlednosti 100 %, bez
  aktivního buffu nebo s náhledem stacků pod nastaveným prahem.
- Šedá silueta existuje jen během úpravy vybraného buffu. Po zamknutí nebo
  zavření okna zmizí a skutečné procy používají tvoji uloženou průhlednost,
  pravidla stacků a barevný motiv. Zámky cooldownů zůstávají oddělené.
- Při aktualizaci úplně ukonči hru a přepiš CELOU složku FreeSpellCooldowns,
  včetně nové podsložky Textures. Potom hru znovu spusť. WTF nemaž.

OVĚŘENÍ 1.6.2
Všechny čtyři BLP textury byly načteny, vizuálně zkontrolovány a porovnány
s obsahovými kontrolními součty nainstalovaného klienta WoW Forever.
Test reprodukuje starou chybu: tři stacky se zobrazují, ale stará cesta
neposkytne obrázek. Nová verze vykresluje obrázek i číslo, ověřeno pro oba
tvary oblouků, všechny čtyři motivy, změny stacků a zamknutí/odemknutí.
Další kontroly ověřují šedou siluetu i při nulové neprůhlednosti, původní
cooldowny, specy, polohy a načtení po restartu. Kontroly Lua 5.1 prošly.
Přímé ověření aktualizace v běžícím herním klientu ještě zbývá.

OPRAVY A NOVINKY 1.6.1
- Opraveno skutečné sledování Maelstrom Weapon: talent 408498 se při přidání
  podle názvu nebo ID převede na proc buff 408505. Již uložený chybný záznam
  se opraví při načtení automaticky; jeho pozice, vzhled a oba specy zůstanou.
- Místo tlačítka s jednou předvolbou je Vybrat buff pro moji classu.
  Otevře nabídku s ikonami a hledáním. Nabídka vychází z classy postavy,
  základního katalogu a dalších vlastních buffů poznaných mimo boj.
  U šamana nabízí například Maelstrom Weapon, Clearcasting, Flurry,
  Lightning Shield, Water Shield a Nature's Swiftness.
- Další vlastní buffy se do nabídky doplní, pokud hra mimo boj zpřístupní
  jejich identitu. Seznam si pamatuje i po odhlášení. Obnovit načte aktuální
  vlastní buffy; ruční přidání názvem či ID zůstává dostupné.
- Různé ranky vybraného buffu mohou sdílet jeden záznam. Opětovný výběr
  již sledovaného buffu otevře jeho úpravu a zachová nastavený vzhled.
- Výběr buffu z nabídky nebo kliknutí na kartu tvaru či motivu ihned zapne
  přesouvatelný náhled. Funguje i kliknutí na již zvolený tvar.
- Náhled začíná na nastaveném maximu stacků, takže jej neschová vyšší práh.
  Pro úpravu nepotřebuješ aktivní buff ani boj. Vybraný buff lze upravit
  i ve specu, kde je vypnutý; náhled má v takovém případě výslovný popisek.
- Tyrkysový rámeček a název označují právě upravovaný buff. Zůstanou viditelné
  i při průhlednosti 100 %. Samotná grafika respektuje nastavenou průhlednost.
  Přetažení mění polohu, Shift + kolečko velikost; čísla X/Y fungují dál.
  Náhled se zobrazí nad nastavením a panel při překrytí uvolní místo.
- Buffy / procy mají vlastní zámek, samostatný pro oba specy. Cooldowny mají
  svůj původní zámek. Odemčení buffu nechává cooldowny zamčené. Přechod
  do cooldownů ukončí úpravu buffu; odemčení cooldownů upravuje jen cooldowny.
- Pravé tlačítko minimapy a příkazy /fsc lock a /fsc unlock ovládají právě
  zvolenou sekci. Při vstupu do boje a zavření buffového okna náhled skončí.
- Náhled se týká pouze vybraného buffu. Ostatní buffy dál sledují skutečné
  procy a nezachytávají myš. Původní konfiguraci ve WTF není potřeba mazat.

OVĚŘENÍ 1.6.1
Automaticky ověřeno v Lua 5.1 / LuaJIT se simulovaným WoW API: kliknutí na
všechny tvary, chybějící buff, přesun, velikost, plná průhlednost, samostatné
zámky včetně minimapy a příkazů, oba specy, třídy, katalog, hledání, ranky,
automatické poznávání vlastních buffů a načtení po restartu. Nový test pokrývá
nahlášenou konfiguraci s talentem 408498 a skutečnou aktivaci aury 408505.
Omezené bojové hodnoty se nečtou. Regresní kontroly původních cooldownů,
dosahu, many, intenzity záblesku a uložených poloh také prošly.
Tato aktualizace ještě nebyla ověřená přímo v běžícím herním klientu.

NOVINKY VE VERZI 1.6.0 - BUFFY A PROCY
- V /fsc je nová záložka Buffy / procy. Sleduje buffy na tvé postavě.
- Přidej název nebo aura spell ID buffu. U procu může být jiné než ID talentu
  nebo sesílaného kouzla. Příkaz /fsc buff otevře přímo tuto záložku.
- Maelstrom Weapon - předvolba (5 stacků) přidá správný buff pro Forever
  (408505), dva elektrické oblouky, zesilování a záři při pěti stackách.
  Předvolba upravuje vzhled v právě aktivním specu.
- Tři obrázkové karty vybírají zobrazení: Ikona buffu, Vlevo + vpravo,
  Horní oblouk. Zvýrazněný rámeček ukazuje vybranou variantu.
- Pro oblouky jsou čtyři další obrázkové karty retailových proc efektů:
  Blesky (Maelstrom Weapon), Oheň (Hot Streak), Led (Fingers of Frost),
  Příroda (Nature's Grace). Horní motivy se pro boky otočí a naopak.
  Ikona vždy používá vlastní obrázek buffu, motiv oblouků ji nemění.
- Počet stacků lze zapnout nebo vypnout pro každý buff a spec samostatně.
  Běžný proc bez stacků se ukáže i tehdy, když hra hlásí počet aplikací 0.
- Od stacku určuje nejnižší počet pro zobrazení; Maximum určuje plné nabití.
  Například od 5 / maximum 5 zobrazí upozornění teprve při pěti stackách.
- Zesilovat podle stacků postupně snižuje průhlednost směrem k maximu.
  U Maelstrom Weapon: 1/2/3/4/5 stacků = 20/40/60/80/100 % síly efektu.
  Zářit při maximu přidá při dosažení nastaveného maxima jasnou vrstvu.
  Po spotřebování stacků se síla ihned sníží; bez buffu efekt zmizí.
- Celková průhlednost dále tlumí celý efekt včetně záře.
- Každý buff má vlastní polohu X/Y od středu, velikost a Pouze v boji.
  Ikona má rozsah 24-160 px, oblouky 64-512 px. U bočních oblouků velikost
  znamená výšku a přesouvá se celá dvojice. U horního oblouku znamená šířku.
- Spec 1 / Spec 2 určují, ve kterých sadách talentů se buff sleduje.
  Zobrazení, motiv, poloha, velikost, průhlednost a pravidla se ukládají
  pro oba specy samostatně. Přepnutí talentů je vybere automaticky.
- Odemknout pro náhled zobrazí označený NÁHLED i bez aktivního buffu.
  Přetáhni ho, velikost změň pomocí Shift + kolečko. Tlačítky u Náhled stacků
  můžeš vyzkoušet různé počty. Zamknutí nebo zavření okna náhled ukončí;
  poté se zobrazují jen skutečné buffy. Zamčené efekty propouštějí kliknutí.
- Časový odpočet je volitelný u ikony s prahem od 1 stacku.
  U vyššího prahu a u oblouků je vypnutý, aby se neobjevil předčasně.
- Ostatní cooldowny včetně probliknutí, many, dosahu, minimapy a uložených
  nastavení z verze 1.5 jsou zachovány. Složku WTF při aktualizaci nemaž.

OVĚŘENÍ NOVÉ VERZE
- Všechny Lua soubory zkompilované v Lua 5.1 / LuaJIT.
- Simulované API ověřuje chybějící buff, počty 1-5 i pokles počtu, prahy,
  plnou záři, tři styly, čtyři motivy, volitelná čísla, nativní odpočet,
  pixelové polohy, přetažení, náhled, boj, oba specy a načtení po restartu.
- Kontroly zakazují čtení i úpravy nativních aura widgetů po jejich vytvoření.
- Znovu ověřené původní cooldowny, jejich dvě rozložení, dosah, mana, záblesk,
  minimapa a uložení všech nastavení. Balíček ještě není ověřený přímo ve hře.
- Zobrazení používá herní AuraContainer / AuraButton. Práh stacků, zesilování
  a záře vyžadují podporu minApplications v nativním API klienta. Pokud chybí,
  nastavení vysvětlí omezení; běžný buff s prahem 1 dál funguje.
- Grafika se načítá z retailových textur přítomných v klientu.

PODKLADY K BUFFŮM A MOTIVŮM (15. 11. 2026)
SpellActivationOverlay: proc efekty včetně Maelstrom Weapon pro Forever.
https://github.com/ennvina/spellactivationoverlay
TellMeWhen: sledování buffů a jejich podmínek.
https://github.com/ascott18/TellMeWhen/blob/master/Components/IconTypes/IconType_buff/buff.lua
Nativní API pro stacky, jejich čísla a rozsah aplikací:
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/AuraContainerUtilDocumentation.lua
EllesmereUI: použití nativního vykreslování počtu aplikací.
https://github.com/EllesmereGaming/EllesmereUI/blob/main/EllesmereUI_WarriorCharges.lua
Retailové soubory proc efektů v registraci SharedMedia:
https://github.com/anson0370/eui-mirror/blob/master/ElvUI/media/sharedmedia.lua
Ověřené ID Maelstrom Weapon pro klient Forever 1.60.1:
https://github.com/gunba/wow-forever-sim/blob/forever/docs/beta-pass/shaman.md
Implementace je vlastní; žádný z uvedených addonů není nutné instalovat.

NOVINKY VE VERZI 1.5.0
- Každý spell má posuvník Intenzita záblesku v rozsahu 0-100 %.
  0 % = bez záblesku, 100 % = nejsilnější záblesk. Výchozí hodnota je 80 %.
  Kolečko nad posuvníkem mění intenzitu po 1 %.
- Intenzita upozornění je nezávislá na průhlednosti samotné ikony.
  Záblesk je výraznější než ve verzi 1.4, i když máš ikonu průhlednější.
  Polohu a velikost stále přebírá přímo od příslušné ikony.
- Zapnutí záblesku dál ovládá Probliknout po CD (jen v boji).
  Tlačítko Vyzkoušet probliknutí ukáže zvolenou intenzitu nad nastavením.
- Nové zaškrtávátko Modře při nedostatku many lehce zabarví ikonu do modra,
  pokud hře chybí mana na konkrétní kouzlo. Po doplnění many se barva obnoví.
  U kouzel s jiným zdrojem hra použije odpovídající nedostatek tohoto zdroje.
- Modrá vychází přímo z údaje hry o nedostatku zdroje.
  Stávající červená indikace cíle mimo dosah má před modrou přednost.
- Obě nové volby se ukládají pro každý spell a každý spec samostatně.
  Modré zabarvení je ve výchozím stavu vypnuté, aby aktualizace neměnila
  vzhled starších ikon. Zapneš ho u požadovaných kouzel v /fsc.
- Původní kouzla, přiřazení do speců, polohy a další volby zůstávají zachované.

NOVINKY VE VERZI 1.4.0
- Volitelné probliknutí přímo na ikoně při konci cooldownu během boje.
- V /fsc vyber kouzlo a zaškrtni Probliknout po CD (jen v boji).
  Volba je samostatná pro každý spell i spec a ve výchozím stavu je vypnutá.
- Dva krátké zlaté záblesky trvají dohromady přibližně 0,7 sekundy.
  Efekt nemění polohu, velikost ani uloženou průhlednost ikony.
- Konec CD i obnova náboje používají událost nativního herního odpočtu.
  Globální cooldown se ignoruje. Souběžná upozornění na stejné ikoně
  se sloučí, aby neproblikla dvakrát.
- Pokud hra poskytuje údaj o použitelnosti, nepoužitelné kouzlo se
  vizuálně nezvýrazní (například při nedostatku many).
- Tlačítko Vyzkoušet probliknutí ukáže náhled i mimo boj a dočasně zobrazí
  skrytou ikonu. Po náhledu obnoví její původní průhlednost a viditelnost.
  Tento ruční náhled funguje i bez zapnutého automatického probliknutí.
- Automatický efekt se při konci boje, přepnutí specu nebo skrytí ikony zastaví.
- Ostatní funkce včetně zaškrtávátek pro oba specy jsou zachovány.

PŘIŘAZENÍ KOUZEL DO SPECŮ
- Jeden společný seznam kouzel pro obě sady talentů.
- U každého kouzla jsou zaškrtávátka Spec 1 a Spec 2.
  Pouze Spec 1: ikona se ukazuje v první sadě talentů.
  Pouze Spec 2: ikona se ukazuje ve druhé sadě talentů.
  Obě políčka: stejné kouzlo se sleduje v obou sadách.
  Žádné políčko: ikona je skrytá, ale kouzlo zůstává v seznamu.
- Po změně dual specu se zobrazení ikon přepne automaticky.
- Poloha, velikost, průhlednost, odpočet, název a volba Pouze v boji
  se dál ukládají pro každý spec samostatně.
- Zachovaný posuvník průhlednosti a tlačítka -/+ pro velikost i X/Y.

INSTALACE A AKTUALIZACE
1. Ukonči World of Warcraft.
2. Rozbal ZIP a složkou FreeSpellCooldowns přepiš stejnojmennou složku:
   World of Warcraft\_forever_\Interface\AddOns\FreeSpellCooldowns
3. Soubor FreeSpellCooldowns.toc musí být přímo v této složce.
   Nevytvářej další vnořenou složku FreeSpellCooldowns.
4. Nastavení uložené ve WTF nemaž. Původní kouzla a vzhled pro obě sady
   talentů se převedou automaticky. Společné kouzlo bude v seznamu jednou
   a zachová odlišnou polohu i vzhled z každého původního profilu.
5. Spusť hru a otevři /fsc (funguje také /cdikony).

PŘIDÁNÍ A PŘIŘAZENÍ KOUZLA
1. Přetáhni kouzlo ze spellbooku (P) do označené plochy, nebo napiš jeho
   celý název, spell ID či spell link a klikni na Přidat.
2. Klikni na kouzlo ve společném seznamu.
3. U Zobrazovat ve vyber Spec 1, Spec 2 nebo obě políčka.
   Nové kouzlo je ve výchozím stavu přiřazené právě aktivnímu specu.
4. Přiřazení oběma specům nevyžaduje přidávat kouzlo podruhé.
   Obě políčka lze nastavit rovnou, bez přepínání talentů.
5. Nahoře vidíš aktivní spec. U příslušného zaškrtávátka je také označení
   (aktivní). V seznamu je uvedeno spec 1, spec 2, oba specy nebo vypnuto.
6. Kouzla nepřiřazená aktuálnímu specu jsou v seznamu ztlumená a stále
   je lze vybrat a znovu přiřadit. Tlačítko × odebere kouzlo z obou speců.

POLOHA A VZHLED
- Nastavení vzhledu upravuje vybraný spell v právě aktivním specu.
- Odemkni ikony a přetáhni každou na požadované místo.
- Velikost uprav tlačítky -/+ po 1 px (rozsah 24-160 px).
  Shift + kolečko nad odemčenou ikonou mění velikost po 2 px.
- Průhlednost má posuvník 0-100 % a okamžitý náhled.
  0 % = plná ikona, 100 % = neviditelná. Kolečko mění hodnotu po 1 %.
- X i Y mají vlastní tlačítka -/+ pro posun po 1 px.
  Čísla můžeš také vepsat a potvrdit Enterem. Escape zruší rozepsanou změnu.
  X roste doprava, Y nahoru; souřadnice jsou od středu obrazovky.
- Lze zapnout číselný odpočet, název pod ikonou a Pouze v boji.
- Při přiřazení oběma specům můžeš mít pro každý jiný vzhled a polohu.
  Změň dual spec ve hře a nastav hodnoty pro nově aktivní sadu.
- Ikona se zobrazí pouze ve zvolených specích a při splnění Pouze v boji.
- Až vše rozmístíš, zamkni ikony. Uzamčené ikony propouštějí kliknutí.
  Během boje jsou úpravy automaticky nedostupné.

COOLDOWNY A DOSAH
- Cooldown, obnovu nábojů a počet použití poskytuje přímo hra.
- Běžný globální cooldown se nezobrazuje jako cooldown každého spellu.
- Mimo dosah cíle je ikona červená a více průhledná. Bez cíle má běžný vzhled.
- Přepnutí specu vybírá zobrazení a nastavení ikon; addon cooldowny neresetuje.
- Ikony slouží ke sledování. Kouzla dál sesíláš svými běžnými klávesami.

MINIMAPA A PŘÍKAZY
- Levý klik na tlačítko s hodinkami otevře nebo zavře nastavení.
- Pravý klik zamkne nebo odemkne ikony pro právě aktivní spec.
- Tlačítko lze přetáhnout po obvodu minimapy.
- /fsc nebo /cdikony: nastavení
- /fsc add Stormstrike: přidat kouzlo
- /fsc lock a /fsc unlock: zamknout a odemknout ikony

ULOŽENÍ A OVĚŘENÍ
Nastavení se ukládá pro každou postavu zvlášť prostřednictvím SavedVariables.
Použij /reload nebo hru ukonči běžným odhlášením, aby hra změny zapsala.
Ověřeno: kompilace všech souborů v Lua 5.1 a simulované WoW API pro převod
nastavení, zaškrtávátka, přepínání speců, průhlednost a načtení po restartu.
Probliknutí bylo ověřeno také pro konec CD, náboje, boj, náhled, skrytí
a odebrání ikony, přepnutí specu a nativní předání omezených hodnot.
Tato verze zatím nebyla ověřena přímo v herním klientu.
Při chybě: /console scriptErrors 1, potom /reload a poznamenej celý text chyby.
Hlášení vypneš přes /console scriptErrors 0.

KOMPATIBILITA A FONT
Bez dalších addonů či knihoven. Moderní C_Spell API a nativní Cooldown widget
s LuaDurationObject; addon nepočítá ze skrytých bojových hodnot.
Distribuce cílí na WoW Forever; kompatibilita s jinými klienty se neslibuje.
Font Noto Sans, Copyright 2018 The Noto Project Authors.
Licence SIL Open Font License 1.1 je ve Fonts/OFL.txt.

PODKLADY K PROBLIKNUTÍ (13. 11. 2026)
Doom_CooldownPulse: krátké vizuální upozornění po konci cooldownu, náhled.
https://github.com/aduth/Doom_CooldownPulse
TellMeWhen: nativní OnCooldownDone pro konec odpočtu s omezenými hodnotami.
https://github.com/ascott18/TellMeWhen/blob/master/Components/Core/Icon.lua
Implementace efektu v tomto addonu je vlastní a nevyžaduje další addon.

PODKLADY K MANA BARVĚ (14. 11. 2026)
WoW Spell API vrací zvlášť použitelnost a nedostatek potřebného zdroje.
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpellDocumentation.lua
Nativní masky barev a průhlednosti umožňují zobrazení i v boji bez čtení
omezených hodnot v Lua. Oddělené vrstvy zachovávají přednost barvy dosahu.
https://github.com/Gethe/wow-ui-source/blob/live/Interface/AddOns/Blizzard_APIDocumentationGenerated/SimpleRegionAPIDocumentation.lua
Nové volby jsou ověřené automatickými testy v Lua 5.1 a simulovaném WoW API.
Tato verze zatím nebyla ověřená přímo v herním klientu.
