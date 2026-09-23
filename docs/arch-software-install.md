# Installing Software on Arch

How to install extra applications on an Arch-based machine after GLB has
set it up. Use the command line. Graphical app stores such as the COSMIC
Store only show Flatpaks on Arch unless PackageKit is installed, and GLB
deliberately leaves PackageKit out (see [Decisions](#decisions)).

## Where to get it, in order

1. **Official repos (pacman):** the first choice every time.
   ```
   pacman -Ss <name>          # search  (GLB shortcut: search <name>)
   sudo pacman -S <name>      # install (GLB shortcut: install <name>)
   ```
2. **AUR (paru or yay):** only if the app isn't in the official repos.
   ```
   paru -S <name>
   ```
   Before it builds, the helper shows the PKGBUILD. Skim it and make sure it
   downloads from the real project and doesn't do anything strange.
3. **Flatpak:** a last resort, for apps that aren't packaged for Arch or
   that only ship as a Flatpak.
   ```
   flatpak install flathub <app-id>
   ```

## Rules

- **Update before installing** if it's been a while. GLB's `update` shortcut
  does this in one step (see below).
- **Never run `sudo pacman -Sy <pkg>` on its own.** It refreshes the package
  lists without upgrading the system, so the new package is newer than
  everything else ("partial upgrade"). Arch doesn't support that, and it
  can break things.
- **Read the "Optional dependencies" list** that pacman prints after an
  install, and add the ones you want. For example, LibreOffice
  (`libreoffice-fresh`) only gets English spell check, hyphenation and a
  thesaurus from `hunspell-en_us`, `hyphen-en` and `mythes-en`.

## Keeping everything updated

In GLB's profiles, `update` runs `paru -Syu` (or `yay -Syu`, or
`sudo pacman -Syu` if there's no AUR helper), which covers the repos and the
AUR. On the `default` profile it then runs `flatpak update` too. To do it by
hand:

```
sudo pacman -Syu     # official repos
paru -Syu            # official repos + AUR
flatpak update       # Flatpak apps
```

## Removing software

```
sudo pacman -Rns <name>    # removes the package, its unused dependencies, and system config files
```

GLB's `remove` shortcut is plain `sudo pacman -R`, which leaves the package's
unused dependencies installed. Use the full `-Rns` command above for a clean
removal.

## Decisions

- **No PackageKit.** Installing `packagekit` would let the COSMIC Store list
  pacman packages too, but PackageKit refreshes the package lists in the
  background. Installing a single app from the Store after that is a
  partial upgrade. The Store can never install AUR packages either, so the
  command line stays the single, predictable way to install software.
