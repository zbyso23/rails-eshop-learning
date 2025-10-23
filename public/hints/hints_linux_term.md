## How to disable Ctrl+V in Terminal (Readline)
Add this line `"\C-v": ""` to file `~/.inputrc`

---

## Find

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