# PSQL

## Modes
\x Exteded display toggle
\s History

## Formatting
\pset format unaligned: Zobrazí výstup bez zarovnání, oddělený znakem.
\pset format csv: Zobrazí výstup ve formátu CSV, oddělený čárkou.
\pset format html: Zobrazí výstup ve formátu HTML.

## Připojení a odpojení
psql -U uživatel -d databáze: Připojí se k databázi pod zadaným uživatelským jménem.
psql: Připojí se s výchozím uživatelem a databází (obvykle postgres).
\q: Ukončí psql. 

## Přehled databází a tabulek
\l: Vypíše seznam všech databází na serveru.
\c databáze: Připojí se k jiné databázi.
\dt: Zobrazí seznam tabulek v aktuální databázi.
\dt *.*: Zobrazí tabulky ze všech schémat.
\d tabulka: Zobrazí popis tabulky (sloupce, typy, indexy, triggery).
\d+ tabulka: Zobrazí podrobnější popis tabulky, včetně velikosti. 

### Pro vyhledavani
Použijte následující syntaxi: \dt *[vzor]*
Zástupné znaky:
* – zastupuje libovolný počet libovolných znaků.
? – zastupuje jeden libovolný znak. 

## Informace o objektech
\du: Zobrazí seznam uživatelů (rolí).
\dn: Vypíše seznam schémat.
\df: Vypíše seznam funkcí.
\di: Vypíše seznam indexů.
\dv: Vypíše seznam pohledů (views).
\dx: Zobrazí seznam nainstalovaných rozšíření (extensions). 

## Zobrazování a formátování
\x: Přepíná rozšířený režim zobrazení, kde je každý řádek zobrazen jako pár klíč-hodnota. To je užitečné, pokud má tabulka mnoho sloupců.
\s: Vypíše historii příkazů.
\o soubor.txt: Přesměruje výstup dotazů do souboru.
\o: Zastaví přesměrování výstupu.
\! příkaz_shellu: Provede shell příkaz (např. \! ls). 

## Provádění SQL dotazů
\i soubor.sql: Spustí SQL příkazy ze souboru. 

## Nápověda a další
\?: Zobrazí nápovědu pro meta-příkazy psql.
\h: Zobrazí nápovědu pro SQL příkazy. 

## Export a import dat
\copy (SELECT * FROM tabulka) TO 'soubor.csv' WITH CSV: Exportuje obsah tabulky do CSV souboru.
\copy tabulka FROM 'soubor.csv' WITH CSV: Importuje data z CSV souboru do tabulky. 
