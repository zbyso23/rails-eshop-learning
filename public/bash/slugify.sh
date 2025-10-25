#!/bin/bash
# Robustní skript pro slugifikaci, který zpracuje všechny argumenty bez uvozovek.

# Povolení "přísného režimu" pro robustnější skript
set -o errexit   # Ukončí se okamžitě, pokud příkaz skončí s nenulovým stavem.
set -o nounset   # S neexistujícími proměnnými zachází jako s chybou.
set -o pipefail  # Návratová hodnota pipeline je stav posledního příkazu, který skončil s nenulovým stavem.

# Funkce slugify
# Vezme řetězec jako argument nebo čte ze vstupu.
# Používá kombinaci iconv, sed a tr pro pokročilé manipulace s řetězci.
function slugify() {
  local input_string
  
  # Zpracuje vstup z argumentů (spojených do jednoho řetězce pomocí "$*") nebo ze standardního vstupu.
  if [[ -n "${1-}" ]]; then
    # Zde se používá $* (bez uvozovek), který se rozbalí na jednotlivá slova, a poté se spojí `printf "%s "` do jednoho řetězce
    # A nakonec se odstraní poslední mezera.
    input_string=$(printf "%s " "$*")
    input_string=${input_string% }
  else
    input_string=$(cat)
  fi
  
  # 1. Transliteruje Unicode znaky na ASCII
  # 2. Převede na malá písmena
  # 3. Nahradí všechny ne-alfanumerické znaky spojovníkem
  # 4. Odstraní úvodní nebo koncové spojovníky
  echo "${input_string}" \
    | iconv -t ascii//TRANSLIT \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g' \
    | sed -E 's/^-+|-+$//g'
}

# Pokud je skript spuštěn přímo (ne jako funkce), spustí slugify
if [[ "${BASH_SOURCE}" == "${0}" ]]; then
  if [[ -n "${1-}" ]]; then
    slugify "$*"
  else
    echo "Použití: $(basename "$0") <text_k_slugifikaci>"
    echo "       echo \"Text s mezerami\" | $(basename "$0")"
    exit 1
  fi
fi
