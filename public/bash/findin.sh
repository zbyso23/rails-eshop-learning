#!/bin/bash

# Zkontroluje, zda byly zadány 3 parametry
if [ "$#" -ne 3 ]; then
    echo "findin - vyhledava phrase1 A phrase2 ve vsech souborech v ceste"
    echo "Použití: $0 <cesta> <phrase1> <phrase2>"
    exit 1
fi

# Přiřadí parametry do proměnných pro lepší čitelnost
path=$1
phrase1=$2
phrase2=$3

# Spustí příkaz `grep` s parametry
#  -r: pro rekurzivní hledání
#  $path: cesta, kde se má hledat
#  $phrase1: první fráze
# | grep "$phrase2": filtruje výstup, aby obsahoval pouze řádky s druhou frází
grep -r "$phrase1" "$path" | grep "$phrase2"