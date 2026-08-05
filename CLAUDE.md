# CLAUDE.md — GLB (Greg's Linux Bootstrap)

## What this project is

GLB is a Bash CLI tool that bootstraps and customizes fresh Linux installs —
installing software and applying shell configs in one pass instead of doing
it manually item by item every time a distro gets reinstalled.

- Repo: https://github.com/ggregoro/GLB (private)
- License: MIT
- Language: Bash

## Why it exists

Greg distro-hops a lot and got tired of manually reconfiguring each fresh
install by hand. GLB automates that setup. It's built with the idea that it
might eventually be shared publicly if there's interest — so keep code
reasonably clean and documented, not just "works on my machine."

## Test environments

- Dell E7450 laptop running Pop!_OS
- Windows 10 PC running VirtualBox, used to test other distros

When suggesting changes, keep portability across distros in mind — don't
assume a single package manager or init system unless the script already
branches on it.

## Roadmap / in progress

- Add WezTerm and Ghostty terminal emulator setup (Greg already uses both)
- Add a Homebrew/Linuxbrew repository as an install source
- Populate `profiles/default/` with Greg's real dotfiles and package list
  (currently just a placeholder starter list and an empty `dotfiles/`)
- Add a mechanism for installs outside the package manager (flatpak,
  AppImage, curl-install scripts) — doesn't fit the plain `packages.txt`
  model yet
- Terminal prompt/shell customization — split into two pieces:
  - **Prompt** (in progress, `lib/prompt.sh` + `glb prompt`): uses Starship
    (starship.rs), not an OMZ theme — installs the `starship` binary via
    its official installer, then a restore-time menu lets the user pick
    exactly one full preset (Default, Pure Prompt, Pastel Powerline, Nerd
    Font Symbols, Plain Text Symbols, No Runtime Versions), generated via
    `starship preset <name> -o ~/.config/starship.toml`. Starship presets
    turned out to be whole standalone configs, not composable modules —
    even starship.rs itself has no way to mix e.g. Pastel Powerline's
    layout with Plain Text symbols — so a per-module mix-and-match picker
    was dropped in favor of picking one preset outright (no TOML parser to
    lean on, Bash-only). Zsh-only so far (`eval "$(starship init zsh)"`
    appended to `~/.zshrc`, idempotent); bash/fish support and wiring into
    `profiles/default` (once real dotfiles are populated) still open.
  - **Plugins** (not started): stay framework-free — don't install Oh My
    Zsh itself, cap to a curated subset of OMZ plugins (e.g.
    autosuggestions, syntax-highlighting) vendored directly into GLB's own
    dotfiles rather than the full OMZ catalog. Still open: which specific
    plugins make the cut.

## Testing

- `tests/` has a bats suite (`tests/detect.bats`, `package.bats`,
  `profile.bats`, `dispatcher.bats`) covering package manager detection,
  packages.txt parsing, dotfiles symlink/backup, per-distro package
  overrides, and the dispatcher's remove/update/restore/profiles commands.
  Runs in an isolated `GLB_ROOT`/`HOME` with sudo and package managers
  stubbed, so nothing touches the real system. Run with `bats tests/`
  (needs `bats` installed — not present on the Dell laptop as of
  2026-08-05, so run there or on the Zorin VM until it's installed).

## Conventions

- Bash only — no dependency on Python/Node/etc. for core functionality
- Keep the "customize a fresh install fast" goal central — prefer one clear
  path over many configurable options unless a real need shows up
- Since this may be shared publicly later, avoid hardcoding anything
  specific to Greg's personal setup unless it's clearly marked as an
  example/default that others would edit

## Working notes

- This file is read by Claude Code at the start of every session in this
  repo — update it as decisions get made so context isn't lost between
  sessions.
