# ripgrep (`rg`) Cheat Sheet

Every GLB profile installs `ripgrep`. It's a faster, friendlier `grep`.
GLB deliberately doesn't alias `grep` to `rg`: they use different flags
and regex rules, so pasted `grep` commands would behave unexpectedly.

The main difference from `grep`: `rg` searches the current directory and
everything below it by default. You don't need `-r` or a path.

## Everyday use

```
rg todo                  # search everything under here
rg -i todo               # ignore case
rg -S todo               # "smart case": case-insensitive unless you type a capital
rg -w log                # whole word only (won't match "login")
rg -F 'a.b(c)'           # literal text, no regex
rg todo lib/             # search one folder or file
```

## Narrowing it down

```
rg -t sh pacman          # only shell scripts (rg --type-list shows all types)
rg -g '*.md' ripgrep     # only files matching a glob
rg -g '!tests' foo       # exclude a path
rg -l pacman             # just list matching filenames
rg -c pacman             # count matches per file
rg -C 2 pacman           # 2 lines of context around each match
```

## Things that trip people up

- **It skips some files by default:** hidden files (dotfiles), anything in
  `.gitignore`, and binary files. Use `rg --hidden`, or `rg -uu` to search
  nearly everything.
- **`-r` doesn't mean "recursive".** In `rg`, `-r` means *replace* (it
  only changes the output, never the file). Searching subfolders is
  already the default.
- **Put regex in single quotes** so your shell doesn't interpret it first,
  e.g. `rg 'fn \w+\('`.

## Two combos worth remembering

```
rg --files | rg nvim     # find files by name (a quick "find")
rg -l foo | xargs nvim   # open every matching file in Neovim
```

## Try it

From inside your GLB checkout:

```
rg -S alias --hidden profiles
```

This lists every alias across the GLB profiles, dotfiles included. For
more, `rg --help` is well organized.
