# Trailblazer

Porozumění základním prvkům Trailblazeru a jeho architektuře na vysoké úrovni nezabere více než 20 minut. Jakmile opustíte myšlení „MVC“ a necháte Trailblazer ukázat, jak restrukturalizuje aplikace, definuje silné konvence, kde by měl být kód umístěn, a jak objekty interagují, stane se pro vás jen dalším nástrojem ve vašem repertoáru.
Upozorňujeme, že tato příručka popisuje pouze operaci Vytvořit. Popisované koncepty se vztahují na všechny druhy funkcí, jako je aktualizace nebo mazání.
Doufáme, že se vám bude líbit!

## Architektura na vysoké úrovni
Trailblazer, který se prezentuje jako architektura na vysoké úrovni, si klade za cíl pomáhat softwarovým týmům implementovat skutečnou obchodní logiku jejich aplikací. Obchodní logiku chápeme jako vše, co se děje po zachycení HTTP požadavku a před vrácením odpovědi.

Trailblazer ponechává zpracování HTTP a pokyny pro vykreslování na infrastruktuře frameworku: Může to být jakákoli knihovna, kterou máte rádi, Rails, Hanami, Sinatra nebo Roda.

Obchodní kód je zapouzdřen do operací, které jsou základním a klíčovým prvkem Trailblazeru. Operace vás jemně nutí oddělit kód aplikace od frameworku. Proto by se váš kód v ideálním případě neměl starat o podkladový framework.

## Tok
Ve webovém prostředí jsou akce uživatelů zpracovávány prostřednictvím požadavků. Každý typický obchodní pracovní tok v požadavku je strukturován do pěti kroků.

Podívejte se na levou stranu diagramu. Toto je to, co musí každý požadavek zpracovat.

![Flow](high-level.jpg "Flow")

- Deserializace
- Validace
- Trvalost
- Následné zpracování, tzv. zpětná volání
- Prezentace, vykreslení odpovědi

Na pravé straně můžete vidět, jak Trailblazer zavádí nové zajímavé abstrakční vrstvy. **Vrstvy jsou implementovány jako objekty.** Každý objekt zpracovává pouze jeden konkrétní aspekt, čímž se minimalizuje odpovědnost každé vrstvy.

Vertikální autorizační vrstva umožňuje zapojit zásady do každého bodu vašeho kódu.

Tento přístup povede k tomu, že řadiče budou prázdnými koncovými body HTTP, štíhlými modely s rozsahy relevantními pro perzistenci, vyhledávači a asociacemi a pouze několika novými inovativními objekty, které vám pomohou implementovat podnikání.

## Funkce aplikace
Každá aplikace je souborem funkcí (nebo „funkcí“), které může uživatel spustit. Může se jednat o zobrazení komentáře, aktualizaci údajů o uživateli, sledování obchodu s točeným pivem nebo import CSV souboru mlýnků na kávu do databáze.

Každá funkce je implementována jednou veřejnou operací. Operace jsou objekty. To znamená, že pro každou funkci vaší aplikace napíšete třídu operace, která se pak připojí k koncovému bodu frameworku.

Skvělé na tom je, že můžete také postupně zavádět operace do stávajících systémů a nahrazovat starý kód nebo přidávat nové funkce pomocí operací a buněk.

## Řadič
Každý webový framework má koncept řadičů: koncové body připojené k HTTP trase. Může se například jednat o akci řadiče Rails vyvolanou prostřednictvím požadavku POST `/comments`.

Kód, který byste obvykle vložili do metody zachycující akci, jako je vytvoření objektu, přiřazení parametrů požadavku k němu atd., tam již není.

Místo toho koncový bod jednoduše odesílá svou operaci.