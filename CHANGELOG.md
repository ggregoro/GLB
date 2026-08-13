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
- Added a `font` method to `lib/extras.sh`/`extras.txt`: downloads a Nerd
  Fonts release zip, extracts it into `~/.local/share/fonts/<name>`, and
  refreshes the font cache. `default` and `new-to-linux` now both install
  JetBrainsMono Nerd Font this way (needed for `eza --icons`, and for
  `default`'s WezTerm config) — previously `glb restore` assumed the font
  was already present, which every prior test machine happened to have
  pre-installed by hand.
- Extended `glb update` to also cover what it previously missed:
  Starship (re-runs its installer if already present) and vendored zsh
  plugins (`git pull` on any plugin already cloned). `glb update
  [profile]` now takes an optional profile argument to also re-run
  that profile's `extras.txt` entries that are currently installed
  (`curl` re-runs the install script, `flatpak` runs the native
  `update` verb, `font` re-downloads and re-extracts). No confirmation
  prompt, matching `glb update`'s existing unprompted style.
- Added a gradient background, 90% window opacity, and a tmux-style
  `Ctrl+a` leader keybinding set (tabs, splits, vim-style pane
  navigation, zoom, a resize key-table, copy mode) to `default`'s
  `.config/wezterm/wezterm.lua`.
- Added `glb restore --from-manifest <path>`: applies a profile-shaped
  directory (`packages.txt` + optional `extras.txt`/`dotfiles/`) from
  anywhere on disk, not just `profiles/` or `snapshots/`, for a one-off
  custom install without adding a profile to the repo.
- Added `install.sh`, a curl-install bootstrap script
  (`curl -fsSL <url>/install.sh | bash`) that clones GLB itself into
  `~/.local/share/glb` (or updates it in place if already there) and
  prints the next command to run. Doesn't run `glb restore` itself -
  that's a separate, opinionated, interactive step. Requires the
  source repo to be publicly reachable.
- Added `ncdu`, `lazygit`, and `glow` to `developer`'s `packages.txt`,
  and `lazydocker` (via `extras.txt`, curl method - no native package
  on any of the four managers) - a disk usage analyzer, a TUI git
  client, a terminal markdown renderer, and a TUI for container
  management pairing with the existing Podman pick. `lazygit`/`glow`
  aren't as long-established as the rest of `developer`'s picks;
  package availability across all four managers isn't empirically
  verified yet, same caveat as the existing `gh` note.

### Changed
- Switched the live resource monitor pick from `htop` to `btop` across
  `default`/`developer`/`server` - supersedes the original
  htop-over-btop call from 2026-08-06 (`btop` is judged the better
  tool now, not a case for carrying both).
- Fixed the `curl` extras method (`lib/extras.sh`) piping installer
  scripts to `sh` instead of `bash`. `sh` is `dash` on Debian/Ubuntu,
  which doesn't support bash-only syntax (e.g. `${VAR//pattern/repl}`)
  that's common in real-world curl-install scripts - found while
  adding `lazydocker`, whose official installer requires bash and
  would have silently failed under the old behavior. GLB itself
  already requires bash 5.x, so there's no reason extras shouldn't too.
- Changed `default`'s `.gitconfig` dotfile to stop hardcoding a
  personal git identity: it now only contains an `[include] path =
  ~/.gitconfig.local` directive, so anyone restoring `default` gets
  their own commits attributed correctly instead of someone else's
  name/email. Was broken for anyone but the original author; also
  part of getting the repo ready to go public.
- Replaced `default`'s `.config/wezterm/wezterm.lua` (the gradient/
  opacity/keybindings version above) with the simpler config that was
  actually already running on Greg's Dell laptop via an untracked
  `~/.wezterm.lua` - discovered during a `$HOME` cleanup that WezTerm
  had been silently preferring that stray file over the real
  GLB-managed one the whole time. See CLAUDE.md for the full writeup.

### Removed
- Removed WezTerm entirely from GLB's scope: the `flatpak wezterm
  org.wezfurlong.wezterm` entry in `default`'s `extras.txt`, the now-
  unneeded `flatpak` package dependency, and the
  `.config/wezterm/wezterm.lua` dotfile. Real time spent chasing
  Flatpak-sandbox and COSMIC-compositor interactions unrelated to
  GLB's actual job (shell/prompt configuration) made clear that
  managing a terminal emulator was scope creep. GLB now only
  configures whatever terminal a distro already ships.
- Removed the curated desktop-app picks (Firefox, LibreOffice, GIMP,
  VLC) from `new-to-linux`. Same reasoning as WezTerm's removal, one
  level up: these are easy for anyone to install themselves, and
  GLB choosing them on someone's behalf is a bigger commitment than a
  shell-bootstrapping tool should make.
- Removed the `new-to-linux` profile entirely. Without its desktop-app
  picks it had shrunk to a near-duplicate of `default`'s shared shell
  setup, so rather than maintain two profiles this similar, it was
  retired the same day its distinguishing content was removed. The
  terminal-onboarding mission it served isn't profile-specific - it's
  what GLB's shared shell/prompt setup is built to do regardless of
  which profile someone picks.
- Removed `docs/reference/debian-server-cheat-sheet.md`: personal
  SSH/SCP/Samba reference material for the author's own home server,
  including its real LAN IP and username - unrelated to GLB itself,
  and not appropriate to carry into a public repo.
- New project-wide principle (see `docs/PHILOSOPHY.md`, "Enhance the
  Terminal You Have, Don't Replace It" and `docs/PROJECT.md`'s
  Non-Goals): GLB does not install GUI applications of any kind -
  terminal emulators included. Everything GLB manages must run inside
  whatever terminal the user already has.

### Fixed
- Fixed `default`'s zsh `starship.toml`: roughly half its Nerd Font
  glyphs (the git-branch symbol, all five language-module icons, half
  the OS icons, and the powerline separator arrows between prompt
  segments) were silently empty strings in the tracked file, present
  since the very first commit that added it. Root cause: every glyph
  in the Basic Multilingual Plane's Private Use Area (`U+E000`-
  `U+F8FF`) was missing, while every glyph in the Supplementary
  Private Use Area-A (`U+F0000`+, which requires UTF-16 surrogate
  pairs) survived intact - confirmed by diffing codepoint-by-codepoint
  against a freshly `curl`-fetched copy of the real, current, official
  Tokyo Night preset. Rebuilt the file from those verified bytes, kept
  the existing `$cmd_duration` customization, and reused `$time`'s
  clock icon for `$cmd_duration` (its own icon had been empty since
  the commit that added it, so there was no correct original to
  recover). No `glb restore` re-run needed to pick this up on an
  existing machine - `~/.config/starship.toml` is a live symlink, so a
  plain `git pull` in the GLB checkout is enough.
- Fixed `install.sh`'s documented one-liner using `curl | sh` when the
  script itself requires bash (`set -o pipefail`, a bash-only option -
  `sh` is `dash` on Debian/Ubuntu, which rejects it at runtime with
  `set: Illegal option -o pipefail`). Found via a real end-user test
  on a fresh machine, not caught by the test suite, since the bats
  tests invoke the script via `bash install.sh` directly rather than
  through the documented `curl | sh` pipe. Changed every reference
  (`README.md`, `install.sh`'s own header comment,
  `docs/ARCHITECTURE.md`) to `curl | bash`.
- Fixed a real `pam_faillock` lockout bug: sudo-gated package
  install/remove/update calls used plain `sudo`, which on a no-TTY
  invocation still triggers a real `pam_unix` auth-failure attempt -
  on Arch-based distros with `pam_faillock` enabled, this could lock a
  user out of their own terminal after a few sudo-gated steps. New
  `glb_sudo` helper (`lib/utils.sh`) uses plain `sudo` when a real TTY
  is available (normal interactive password prompt still works
  exactly as before) and only falls back to non-interactive `sudo -n`
  when there isn't one, avoiding the auth attempt `pam_faillock`
  counts. The manual-step fallback message always shows the plain
  interactive `sudo ...` form for copy-pasting.
- Fixed the `ls`/`ll`/`la`/`l` eza aliases (all profiles, all three
  shells) never showing per-file git status indicators in file
  listings, even inside a git repo. The aliases passed `--icons` but
  never `--git` - eza only queries/displays Git status when explicitly
  told to. Confirmed via full git history that this flag was never
  present in any commit, so it wasn't a regression, just never wired
  up. Ranger showing this correctly the whole time is unrelated - its
  `rc.conf` enables its own separate `vcs_aware`/`vcs_backend_git`.
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
- Fixed the sudo-gated manual-step pause (`glb_prompt_manual_step`)
  never actually waiting for the user when triggered from
  `glb_apply_profile_packages`/`glb_apply_profile_extras`. Both loops
  read `packages.txt`/`extras.txt` via `done < "$file"`, which binds
  stdin for the whole loop body to that file — so the manual step's
  interactive `read -p` silently consumed the *next line of the
  manifest* instead of waiting on the real terminal, and anything
  listed after a failed package/extra vanished without being
  processed. Fixed by reading each manifest on fd 3 instead of stdin.
- Fixed two `tests/export.bats` tests silently relying on the real
  host's package manager instead of their stubs, which only passed by
  accident on non-pacman/non-dnf hosts; they now override
  `glb_detect_package_manager` directly so the apt/zypper-specific
  branches they exercise actually run regardless of the real host.
- Fixed `developer` and `server`'s `starship.toml` still shipping the
  original 2026-08-06 glyph-corruption bug (git-branch symbol, all five
  language-module icons, half the OS icons, powerline separators all
  silently empty) — the 2026-08-10 byte-level fix only ever touched
  `default`'s copy. Confirmed via the same codepoint-level technique
  that found the original bug: `developer`/`server` had 0 glyphs in the
  BMP Private Use Area range (`U+E000`-`U+F8FF`) versus `default`'s 25,
  with the unaffected astral-PUA range (14 glyphs, surrogate pairs)
  matching on all three — the exact signature of the original bug.
  Fixed by raw byte-copying `default`'s already-verified-correct file
  over both (never hand-typing/regenerating the glyphs through any text
  pipeline, per this file's own hard-won lesson), then reapplying each
  file's own small pre-existing wording difference (an em-dash vs a
  hyphen, "doesn't" vs "does not" in the header comment). Verified: all
  three files now show identical BMP-PUA/astral-PUA counts (25/14), and
  `starship prompt --path .` renders cleanly against all three with no
  parse warnings.
- Added `scan_timeout = 1000` to all three profiles' `starship.toml`
  (previously unset, so every restore ran on Starship's own tight 30ms
  default) — ported from the same fix on GWB, GLB's Windows sibling,
  after it hit a real `Scanning current directory timed out` warning
  there (measured ~305ms scanning a real slow directory before landing
  on 1000ms as a safe margin). Not yet hit as a live symptom on GLB
  itself, but the same latent gap existed here too - preemptive, not
  reactive.

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
