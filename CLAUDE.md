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
    eza, bat, zoxide, fastfetch, ranger (tmux/neovim/ripgrep/fastfetch
    kept as aspirational even where not apt-installable on every
    distro).
  - `dotfiles/`: `.bashrc`, `.zshrc`, `.config/fish/config.fish`,
    `.gitconfig`, `.config/starship.toml`, `.config/ranger/rc.conf`
    (Greg's real hand-crafted config — plain text style: directory, git
    info, colored `❯`, no icons/segments, visually different from the
    old Powerlevel10k look).
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
    its own name with a unique circled-letter symbol baked in (`Ⓑ bash`,
    `Ⓩ zsh`, `Ⓕ fish` — plain Unicode, not Nerd Font, so it renders
    everywhere) and the shared `starship.toml` shows it at the start of
    the prompt — Greg asked for this after noticing all three shells now
    look identical and wanting an easy way to tell them apart when
    layered (e.g. running `bash` from inside `zsh`). Iterated from an
    initial generic 🐚 symbol to per-shell symbols per Greg's feedback.
  - Nerd Font glyphs need each *terminal emulator* (not shell) to have
    its own font set to the already-installed `JetBrainsMono Nerd Font`.
    Checked directly (2026-08-05): COSMIC Terminal (`cosmic-term`) is
    already correctly configured (`~/.config/cosmic/com.system76
    .CosmicTerm/v1/font_name` = `JetBrainsMono Nerd Font`) — nothing to
    do there. Konsole isn't installed on this machine (the Dell laptop)
    at all, was only raised earlier as a hypothetical example. WezTerm
    now has a real vendored config (see below).
    - **Confirmed on the CachyOS test VM (2026-08-05):** Konsole renders
      the Nerd Font glyphs correctly — `GLB_SHELL` indicators (`Ⓑ`/`Ⓩ`/`Ⓕ`)
      and `eza`'s file-type icons both display properly after `glb
      restore default`, screenshot-verified by Greg. One more terminal
      emulator off the "does the font actually render" list.
    - **Independently reconfirmed (2026-08-05):** Greg took a second
      screenshot on the CachyOS VM itself and reviewed it in a separate
      Claude session running there (via Claude Desktop, which also
      installed cleanly on that Arch-based distro) — same result, Konsole
      renders fine on Arch-based distros too.
  - `.config/wezterm/wezterm.lua` (2026-08-05): written from scratch —
    Greg's WezTerm (installed via Flatpak, `org.wezfurlong.wezterm`) had
    no prior config at all. JetBrainsMono Nerd Font, Tokyo Night color
    scheme, minimal tab bar. Validated with WezTerm's own CLI
    (`wezterm --config-file <path> show-keys`), not just `bash -n`, since
    it's Lua, not shell. `glb restore` symlinks this config but does
    **not** install WezTerm itself — Flatpak-installed apps aren't
    covered by `packages.txt` (apt/dnf/pacman/zypper only), tied to the
    still-open "non-package-manager installs" roadmap item below.
- `glb prompt` (Starship install + preset picker) was built and tested
  end-to-end on a Zorin OS VirtualBox VM on 2026-08-05.
- **The unified bash/zsh/fish + Starship + `GLB_SHELL` indicator setup
  above is confirmed and locked in as the standard prompt/shell for the
  `default` profile** (Greg's words: "let's make this the standard prompt
  and shell," 2026-08-05) — not a draft or one-off experiment. Treat
  `profiles/default`'s current dotfiles as the baseline going forward;
  future shell/prompt work should extend this rather than replace it.
- For the fine-grained "what shipped when" list, check CHANGELOG.md's
  `[Unreleased]` section — this file tracks the *why* and what's still
  open, not a full change log.

## Roadmap / in progress

- **In progress (2026-08-05): Greg is cross-distro testing `glb restore
  default` on his ~10 VirtualBox VMs** — Fedora (dnf), openSUSE (zypper),
  and CachyOS (pacman) are the priority ones (Mint is apt-based, lowest
  priority — already validated on Pop!_OS/Zorin). Testing both existing
  VMs (may already have some tools manually installed, masking gaps) and
  fresh installs (the real signal — whether `packages.txt`'s tools are
  actually available via each distro's default repos). Goal: find real
  gaps in `_GLB_PACKAGE_OVERRIDES` (`lib/package.sh`) — currently only
  has one entry (`fd` → `fd-find` on apt) — for `eza`, `bat`, `zoxide`,
  `fastfetch`, `fish`, etc. across dnf/pacman/zypper. Waiting on Greg to
  report back distro name + specific errors (package not found, or
  installed under a different binary name like `bat`/`batcat`) so they
  can be turned into override entries. **Fedora, CachyOS, and now
  openSUSE are all done and all three came back clean** — every
  priority distro has zero `_GLB_PACKAGE_OVERRIDES` gaps. Only Mint
  remains, and it's apt-based/lowest-priority (already validated via
  Pop!_OS/Zorin), so this cross-distro testing effort is effectively
  complete pending Greg's manual confirmation of the openSUSE package
  installs below.
  - **Fedora 44 (dnf) result (2026-08-05, tested via Claude Code on a
    Fedora Workstation test VM, confirmed a throwaway machine — not a
    real install):** `glb info` detected `dnf` correctly. This was an
    *existing* VM, so most of `packages.txt` was already present:
    `git`, `fish`, `tmux`, `curl`, `ripgrep`, `fzf`, `eza`, `bat`,
    `zoxide`, `ranger`, `fastfetch` were all already installed. `zsh`
    and `neovim` were missing, so this test did cover real fresh-install
    signal for those two. **No dnf `_GLB_PACKAGE_OVERRIDES` gaps
    found** — every package name in `packages.txt` matches the real dnf
    package name, confirmed via `dnf info`'s "From repository" field to
    come from the official `fedora`/`updates` repos specifically (not
    the Terra/RPM Fusion/COPR third-party repos this VM happened to have
    enabled — important since a fresh Fedora install wouldn't have
    those). As with CachyOS, the sandboxed Claude Code shell has no TTY
    for the sudo password prompt, so `sudo dnf install -y zsh neovim`
    couldn't be run end-to-end from within the session — Greg ran it
    directly in a real terminal on the VM instead, and both installed
    cleanly (`zsh-5.9-21.fc44`, `neovim-0.12.4-3.fc44`, verified via
    `rpm -q` and `command -v zsh nvim`). Dotfiles + plugin restore path
    also passed cleanly: `~/.bashrc`, `~/.config/fish/config.fish`,
    `~/.config/starship.toml` were correctly backed up to
    `*.glb-backup` and all 7 dotfiles symlinked (including
    `.config/ranger/rc.conf` and `.config/wezterm/wezterm.lua`);
    Starship (already present) plus both zsh plugins installed fine.
    **`packages.txt` is fully covered on dnf/Fedora with zero overrides
    needed**, same conclusion as pacman/CachyOS.
  - **CachyOS (pacman) result (2026-08-05, tested via Claude Code in a
    sandboxed shell on a CachyOS test VM):** `glb info` detected `pacman`
    correctly. This was an *existing* VM (not fresh), so most of
    `packages.txt` was already installed and the test mostly confirms
    the dotfiles/plugin path rather than fresh-repo package availability:
    `git`, `zsh`, `fish`, `curl`, `ripgrep`, `fzf`, `eza`, `bat`,
    `zoxide`, `fastfetch`, `ranger` were all already present (ranger's
    presence here is in fact what prompted adding it to `packages.txt`
    — see the ranger bullet below). **No pacman
    `_GLB_PACKAGE_OVERRIDES` gaps found** — none of the tested names
    needed a pacman-specific override. `tmux` and `neovim` were not yet
    installed; both are valid, unambiguous pacman package names (no
    override needed), but the actual `sudo pacman -S` install couldn't
    be verified end-to-end because the sandboxed shell has no TTY for
    the sudo password prompt (`sudo: a terminal is required...`) and its
    sudo timestamp cache doesn't share with a real terminal session
    either — an environment limitation of testing via Claude Code, not a
    GLB bug. Dotfiles + plugins path worked cleanly: `~/.bashrc`,
    `~/.config/fish/config.fish`, `~/.config/starship.toml`, `~/.zshrc`
    were all correctly backed up to `*.glb-backup` and symlinked;
    Starship, `zsh-autosuggestions`, `zsh-syntax-highlighting` all
    installed fine. Separately noted: `/etc/os-release` on CachyOS (a
    rolling release) has no `VERSION_ID`, so `glb info` shows a blank
    Version field — cosmetic, `glb_detect_version` isn't relied on
    anywhere for logic, not worth fixing unless it starts to matter.
    **Confirmed:** Greg ran `sudo pacman -S --noconfirm tmux neovim`
    directly in a real terminal on the VM, and both installed cleanly
    (`tmux 3.7_b-1.1`, `neovim 0.12.4-1.1`, verified via `pacman -Q`) —
    so `packages.txt` is fully covered on pacman/CachyOS with zero
    overrides needed.
  - Mid-testing, CachyOS (rolling release) pushed a major system upgrade
    on its own. Greg waited for it to finish and re-ran a test
    afterward — nothing broke, `glb restore default` still worked fine
    post-upgrade. Not a rigorous regression test, just a good sign that
    GLB doesn't depend on anything fragile enough to be upset by a
    rolling-release update.
  - Also on that CachyOS VM (2026-08-05, Greg's own notes, not part of
    the GLB restore test itself): Claude Desktop installed easily —
    Greg's preferred way to work over the web UI. Unrelated to GLB
    functionality, noted for context only.
  - **openSUSE Tumbleweed (zypper) result (2026-08-06, tested via Claude
    Code running directly on the openSUSE VM itself — this session's own
    machine, not inspected remotely):** `glb info` detected `zypper`
    correctly and reported the distro as `opensuse-tumbleweed`. This was
    an *existing* VM, so most of `packages.txt` was already present:
    `git`, `zsh`, `fish`, `curl`, `fzf`, `eza`, `bat`, `zoxide`, `ranger`,
    `fastfetch` were all already installed. `tmux`, `neovim`, and
    `ripgrep` were missing, so this test covered real fresh-install
    signal for those three. **No zypper `_GLB_PACKAGE_OVERRIDES` gaps
    found** — every name in `packages.txt` matches the real zypper/RPM
    package name exactly, confirmed via `zypper info`. As with
    CachyOS/Fedora, the sandboxed Claude Code shell has no TTY for the
    sudo password prompt, so `sudo zypper install -y tmux neovim
    ripgrep` couldn't be run end-to-end from within the session — Greg
    needs to run it directly in a real terminal on the VM. One false
    alarm caught and ruled out mid-test: `rg` initially looked like it
    resolved to an installed binary, but turned out to be a shell
    function Claude Code itself injects into the session (a wrapper
    around its own ripgrep tool) — `rpm -q ripgrep` confirmed ripgrep is
    genuinely not installed, not a GLB bug. Dotfiles + plugin restore
    path passed cleanly: all 7 dotfiles (`.bashrc`, `.zshrc`,
    `.gitconfig`, `.config/fish/config.fish`, `.config/starship.toml`,
    `.config/ranger/rc.conf`, `.config/wezterm/wezterm.lua`) were
    correctly backed up to `*.glb-backup` and symlinked; Starship
    (already present) and both zsh plugins installed fine.
    **`packages.txt` is fully covered on zypper/openSUSE with zero
    overrides needed**, same conclusion as dnf/Fedora and pacman/CachyOS
    — pending Greg's manual confirmation that `tmux`/`neovim`/`ripgrep`
    install cleanly via `sudo zypper install`.
  - **ranger added to `profiles/default` (2026-08-05):** originally just
    a `docs/PHILOSOPHY.md` example of a "curate, don't reinvent"
    candidate tool, ranger is now a real part of Greg's base profile —
    he asked for it in after noticing it was already on the CachyOS VM
    and liking it, borders and all. Added `ranger` to `packages.txt` and
    a new `dotfiles/.config/ranger/rc.conf`. The rc.conf explicitly
    turns on `vcs_aware`/`vcs_backend_git` so git status shows via
    ranger's *built-in* colored-letter indicators — this sidesteps the
    icon-based git-status indicator that failed to render on the
    CachyOS VM (a Nerd Font glyph gap, never root-caused) rather than
    fixing it directly. `draw_borders` is also set explicitly since
    that's what looked good on CachyOS. If Greg later wants icon-based
    (not letter-based) git status, that likely means a `devicons`-style
    ranger plugin, which needs an actual plugin-install step (like
    `lib/plugins.sh` does for zsh) — dotfiles alone can't do it.
    **Per-profile scope:** ranger is default-on for Greg's own
    `profiles/default` only. Once the multi-profile system in
    `docs/ROADMAP.md` V0.3 (Minimal/Developer/Server/Custom/etc.) is
    built, ranger should be an *optional* package for those other
    profiles, not mandatory — not every profile needs a TUI file
    manager. Not yet enforceable in code since only `default` exists
    today.
- WezTerm config is done (see "Current state"). Ghostty turned out to
  **not** be installed or available via Flatpak on this machine (the
  original "Greg already uses both" premise was wrong) — dropped from
  active scope; revisit only if Greg actually starts using it.
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
- Terminal prompt/shell customization for `profiles/default` is **done**
  (see "Current state" above — Starship + unified bash/zsh/fish +
  framework-free plugins, locked in as standard). One narrower piece
  remains open: the `glb prompt` *command itself* (`lib/prompt.sh` —
  interactive preset picker for someone with an existing `.zshrc`, not
  tied to `profiles/default`) is still zsh-only; bash/fish support for
  that standalone command hasn't been built. Starship presets themselves
  turned out to be whole standalone configs, not composable modules —
  even starship.rs has no way to mix e.g. Pastel Powerline's layout with
  Plain Text symbols — so `glb prompt`'s menu picks one full preset
  outright rather than mixing-and-matching (no TOML parser to lean on,
  Bash-only).

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
