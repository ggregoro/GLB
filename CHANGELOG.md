# Changelog

## 0.1.0

- Created the GLB project.
- Established the project directory structure.
- Initialized the Git repository.

# GLB Project Changelog

All notable changes to the GLB project will be documented in this file.

This project follows a simple versioning approach:

- Major releases introduce significant new functionality.
- Minor releases add features or enhancements.
- Patch releases fix bugs or documentation.

---

## [Unreleased]

### Added
- Added package management abstraction layer.
- Added support for detecting package managers through GLB.
- Added initial `glb install <package>` command support.
- Added package installation support for apt, dnf, pacman, and zypper.
- Added `glb remove` and `glb update` commands.
- Added profile system: `glb restore [profile]` installs a profile's
  `packages.txt` and symlinks its `dotfiles/` into `$HOME`, backing up
  any existing files first.
- Added `glb profiles` command to list available profiles.
- Added the `default` profile with a starter package list.
- Added `glb prompt` command: installs the Starship binary and lets you
  pick a prompt preset (Default, Pure Prompt, Pastel Powerline, Nerd Font
  Symbols, Plain Text Symbols, No Runtime Versions), writing
  `~/.config/starship.toml` and wiring it into `~/.zshrc`.
- Added a bats test suite (`tests/`) covering package manager detection,
  the profile system (packages.txt parsing, dotfiles symlinking and
  backup), and the `glb` dispatcher's remove/update/restore/profiles
  commands.
- Added per-distro package name overrides (`_GLB_PACKAGE_OVERRIDES` /
  `glb_resolve_package_name` in `lib/package.sh`), so a profile's
  `packages.txt` can use one generic name (e.g. `fd`) and GLB will
  install the right package on each distro (e.g. `fd-find` on apt).
  `glb install`, `glb remove`, and the installed-check all resolve
  through this table.
- Added `lib/plugins.sh`: `glb restore` now vendors a small, curated set
  of zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) by
  git-cloning them into `~/.local/share/glb/plugins`, framework-free (no
  Oh My Zsh dependency).
- Populated the `default` profile with real dotfiles (`.zshrc`,
  `.gitconfig`, `.config/starship.toml`) and wired Starship installation
  and zsh plugin vendoring into `glb restore`, so restoring the `default`
  profile now sets up a complete, working shell in one pass.
- Unified aliases and tooling (`eza`, `bat`, `zoxide`, `fastfetch`,
  navigation shortcuts, apt shortcuts, guarded Homebrew shellenv) across
  bash, zsh, and fish, using Greg's existing fish config as the source of
  truth. Added `.bashrc` and `.config/fish/config.fish` to the `default`
  profile's dotfiles, and `eza`/`bat`/`zoxide`/`fastfetch`/`fish` to
  `packages.txt`. Bash and fish now use Starship too (previously
  zsh-only).
- Added a `GLB_SHELL` indicator to the prompt: each shell exports its own
  name with a unique circled-letter symbol (`Ⓑ bash`, `Ⓩ zsh`, `Ⓕ fish`)
  and the shared `starship.toml` displays it at the start of the prompt,
  so it's always visible which shell you're in when they get layered.
- Added `.config/wezterm/wezterm.lua` to the `default` profile's
  dotfiles: JetBrainsMono Nerd Font, Tokyo Night color scheme, minimal
  tab bar — written from scratch since Greg's WezTerm (Flatpak-installed)
  had no prior config. `glb restore` doesn't install WezTerm itself yet
  (Flatpak, no install mechanism for that in GLB — see Planned).
- Added `ranger` to the `default` profile's `packages.txt` plus a new
  `.config/ranger/rc.conf`: explicit `draw_borders`, and `vcs_aware`/
  `vcs_backend_git` so git status shows via ranger's built-in
  colored-letter indicators (avoids depending on an icon font).
- Added `docs/screenshots/` for test-confirmation screenshots and future
  tutorial images.

### Fixed
- Fixed zypper not being detected as an available package manager.
- Fixed `glb restore` silently reporting success when a package failed
  to install or a dotfile couldn't be symlinked/backed up. Failures
  are now logged individually and `glb_apply_profile` returns non-zero
  when any occur.
- Fixed zsh history being effectively disabled (`HISTSIZE=30`,
  `SAVEHIST=0`, no `HISTFILE`) since dropping Oh My Zsh, which used to
  configure this automatically. `.zshrc` now sets it explicitly, which
  broke Ctrl-R (fzf history search) in zsh specifically — bash and fish
  were unaffected.

### Planned

- Initial bootstrap framework
- Documentation system
- Git bootstrap
- SSH bootstrap
- Samba support
- Support for apps outside the standard package manager (flatpak,
  AppImage, curl-install scripts)

---

## [0.1.0] - 2026-08-02

### Added

- Initial GitHub repository
- Documentation structure
- Debian Server Cheat Sheet
