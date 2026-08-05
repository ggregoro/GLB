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

## Current state (as of 2026-08-05)

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update`, `restore [profile]`, `profiles`, `prompt`.
- Modules: `lib/banner.sh`, `lib/logging.sh`, `lib/utils.sh`,
  `lib/detect.sh`, `lib/package.sh`, `lib/profile.sh`, `lib/prompt.sh`,
  `lib/plugins.sh` — all sourced by the `glb` dispatcher.
- `profiles/default/` is now Greg's real setup, not a placeholder, and
  **`glb restore default` has been run for real on this laptop** — Oh My
  Zsh + Powerlevel10k are no longer active (backed up to `~/.zshrc
  .glb-backup`; `~/.oh-my-zsh`/`~/.p10k.zsh` are just unused now, not
  deleted). All three real shells are unified around what was discovered
  to be Greg's most-maintained config, `~/.config/fish/config.fish`
  (already used Starship, `eza`, `bat`, `zoxide`, fzf key-bindings,
  Homebrew — far more developed than the old `.zshrc`, which only had one
  alias):
  - `packages.txt`: git, zsh, fish, tmux, neovim, curl, ripgrep, fzf,
    eza, bat, zoxide, fastfetch (tmux/neovim/ripgrep/fastfetch kept as
    aspirational even where not apt-installable on every distro).
  - `dotfiles/`: `.bashrc`, `.zshrc`, `.config/fish/config.fish`,
    `.gitconfig`, `.config/starship.toml` (Greg's real hand-crafted
    config — plain text style: directory, git info, colored `❯`, no
    icons/segments, visually different from the old Powerlevel10k look).
    All three shells now share the same aliases (eza-based `ls` family,
    `bat` as `cat`, nav shortcuts, apt shortcuts, zoxide, guarded
    Homebrew shellenv) and all three now init Starship (bash and fish
    newly added; previously zsh-only).
  - `glb restore default` installs Starship + vendors
    `zsh-autosuggestions`/`zsh-syntax-highlighting` framework-free
    (`lib/plugins.sh`) in addition to packages/dotfiles — a genuinely
    complete, working shell setup in one pass, now proven on real
    hardware.
  - fzf Ctrl-T/Ctrl-R key-bindings confirmed working in all three shells
    on this machine after the real restore (the guarded `source`-if-
    present logic found what it needed).
  - Added a `GLB_SHELL` prompt indicator (2026-08-05): each shell exports
    its own name and the shared `starship.toml` shows it (🐚 symbol) at
    the start of the prompt — Greg asked for this after noticing all
    three shells now look identical and wanting an easy way to tell them
    apart when layered (e.g. running `bash` from inside `zsh`).
  - Nerd Font glyphs need each *terminal emulator* (not shell) to have
    its own font set to the already-installed `JetBrainsMono Nerd Font`
    — GLB doesn't automate that per-terminal setting yet. Confirmed
    working in WezTerm; COSMIC Terminal/Konsole not yet addressed (see
    roadmap).
- `glb prompt` (Starship install + preset picker) was built and tested
  end-to-end on a Zorin OS VirtualBox VM on 2026-08-05.
- For the fine-grained "what shipped when" list, check CHANGELOG.md's
  `[Unreleased]` section — this file tracks the *why* and what's still
  open, not a full change log.

## Roadmap / in progress

- Add WezTerm and Ghostty terminal emulator setup (Greg already uses both)
- Add a Homebrew/Linuxbrew repository as an install source
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
    lean on, Bash-only). The `glb prompt` *command itself* (interactive
    picker for someone with an existing `.zshrc`) is still zsh-only —
    that's still open. Separately, `profiles/default`'s vendored
    `.bashrc`/`.zshrc`/`.config/fish/config.fish` all now bake in their
    own `starship init <shell>` directly, so restoring the `default`
    profile gets Starship in all three shells regardless of `glb
    prompt`'s own scope. `glb_install_starship` runs as part of
    `glb restore`.
  - **Plugins** (done, `lib/plugins.sh`): framework-free — no Oh My Zsh
    dependency. Curated to exactly `zsh-autosuggestions` and
    `zsh-syntax-highlighting` (the two Greg's real `.zshrc` actually
    used), git-cloned into `~/.local/share/glb/plugins` as part of
    `glb restore`. No OMZ-style "git aliases" plugin equivalent was
    built.

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
