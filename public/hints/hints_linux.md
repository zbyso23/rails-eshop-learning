# Linux

## Find filename

### Najde všechny soubory, které končí na .txt
`find . -name "*.txt"`

### Najde všechny soubory, které začínají na "foto"
`find . -name "foto*"`

### Najde všechny soubory, které obsahují slovo "zprava"
`find . -name "*zprava*"`

### Najde pouze soubory s koncovkou .pdf
`find . -type f -name "*.pdf"`

### Najde pouze adresáře s názvem "dokumenty"
`find . -type d -name "dokumenty"`

### Najde soubory jako např. "Dokument.txt", "dokument.TXT" apod.
`find . -iname "dokument.txt"`


## Find in files
Find files with `phrase1` **AND** `phrase2`
`grep -r "phrase1" /path/ | grep "phrase2"`