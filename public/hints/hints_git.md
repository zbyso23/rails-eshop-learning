# Git

## Stash

**List stashs**
```bash
git stash list
```

**Save stash**
```bash
git stash 
# or
git stash push -m "feature"
```

**Load stash**
```bash
git stash pop
# or
git stash pop stash@{0}
# or apply without remove from stash
git stash apply stash@{0}
```

**Remove stash**
```bash
git stash drop
# or
git stash drop stash@{1}
```

**Clear shashes**
```bash
git stash clear
```

