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

## Current state (as of 2026-08-05, commit e84975a)

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update`, `restore [profile]`, `profiles`, `prompt`.
- Modules: `lib/banner.sh`, `lib/logging.sh`, `lib/utils.sh`,
  `lib/detect.sh`, `lib/package.sh`, `lib/profile.sh`, `lib/prompt.sh` —
  all sourced by the `glb` dispatcher.
- `profiles/default/` is still the only profile: placeholder
  `packages.txt` (git, zsh, tmux, neovim, curl, ripgrep, fzf), empty
  `dotfiles/`. Real dotfiles/package list not populated yet.
- `glb prompt` (Starship install + preset picker) was built and tested
  end-to-end on a Zorin OS VirtualBox VM on 2026-08-05.
- For the fine-grained "what shipped when" list, check CHANGELOG.md's
  `[Unreleased]` section — this file tracks the *why* and what's still
  open, not a full change log.

## Roadmap / in progress

- Add WezTerm and Ghostty terminal emulator setup (Greg already uses both)
- Add a Homebrew/Linuxbrew repository as an install source
- Populate `profiles/default/` with Greg's real dotfiles and package list
  (currently just a placeholder starter list and an empty `dotfiles/`)
- Support multiple named profiles, not just `default` — `docs/ROADMAP.md`'s
  Version 0.3 already envisions Minimal/Developer/Server/Custom, plus a new
  "New to Linux" profile: curated, opinionated software picks (one solid
  browser/editor/office-suite/image-editor/media-player, not a menu) aimed
  at people switching from Windows/macOS who don't know the Linux-native
  options yet. This is a different value proposition from the rest of
  GLB — "restore my exact setup" doesn't help someone who has no setup to
  restore, "here's what's good" does. Probably the highest-leverage way to
  make GLB useful to people beyond Greg.
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
- Greg develops across multiple machines (Dell E7450 laptop, a VirtualBox
  VM — Zorin OS as of 2026-08-05) with Claude Code sessions running
  independently on each, not always in sync in real time. **Before
  pushing, check for commits on `origin/main` you don't have locally**
  (`git fetch && git log main..origin/main`) — this file was committed
  specifically because a VM session had already pushed 3 real commits
  (per-distro package overrides, `glb restore` error handling, the bats
  test suite) that the laptop session only found out about when a push
  was rejected. Don't assume you have the full picture from this file
  alone if it's been a while since the last pull on this machine.
