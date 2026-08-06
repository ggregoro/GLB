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
- Debian 13 machine, linked to GitHub, `glb restore default` run for real
  here on 2026-08-06 (see Roadmap section) — a second real daily-driver
  machine alongside the Dell laptop, not just a test VM

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
    it's Lua, not shell. As of 2026-08-06, `glb restore` also installs
    WezTerm itself via the new `extras.txt`/Flatpak mechanism (see
    Roadmap) — previously it only symlinked this config.
- `glb prompt` (Starship install + preset picker) was built and tested
  end-to-end on a Zorin OS VirtualBox VM on 2026-08-05.
- **The unified bash/zsh/fish + Starship + `GLB_SHELL` indicator setup
  above is confirmed and locked in as the standard prompt/shell for the
  `default` profile** (Greg's words: "let's make this the standard prompt
  and shell," 2026-08-05) — not a draft or one-off experiment. Treat
  `profiles/default`'s current dotfiles as the baseline going forward;
  future shell/prompt work should extend this rather than replace it.
- **Superseded (2026-08-06): the identical-prompt-everywhere approach
  above is no longer current.** Greg asked to differentiate the three
  shells' prompts instead of keeping them visually identical, and to
  drop the `GLB_SHELL` indicator entirely now that the prompts
  themselves look different:
  - **bash**: no longer uses Starship at all. Reverted to the plain
    Linux Mint/Debian default `PS1` (green `user@host`, blue `path`,
    `$`), set directly in `.bashrc`.
  - **fish**: no longer uses Starship either. Reverted to a hand-rolled
    prompt styled after the classic "Pure" theme (two-line: path + dim
    git branch, then a colored `❯` on its own line; right-prompt shows
    command duration for slow commands) implemented as plain
    `fish_prompt`/`fish_right_prompt` functions in `config.fish` — no
    plugin manager (Fisher) added, consistent with how `lib/plugins.sh`
    already vendors zsh plugins framework-free rather than pulling in a
    framework.
  - **zsh**: still the only shell using Starship. `starship.toml` was
    replaced with the official, unmodified "Tokyo Night" preset from
    starship.rs/presets (fetched from the starship GitHub repo, not
    hand-transcribed) — nice incidental pairing with the existing Tokyo
    Night WezTerm color scheme. Since zsh is now the only Starship
    consumer, `starship.toml` no longer needs to serve three shells at
    once.
  - `GLB_SHELL` is fully removed — the export lines are gone from all
    three rc files (`.bashrc`, `.zshrc`, `config.fish`), not just hidden
    from display. Prompt differentiation now comes from each shell
    genuinely looking different, not from a text label.
  - All 68 bats tests still pass unchanged; no test asserted specific
    prompt content, only that the dotfiles get symlinked.
- For the fine-grained "what shipped when" list, check CHANGELOG.md's
  `[Unreleased]` section — this file tracks the *why* and what's still
  open, not a full change log.

## Roadmap / in progress

- **Session wrap-up brainstorm, agreed as real priorities (2026-08-06),
  not yet built — pick up here next session.** End-of-session
  discussion: what would a user *other than Greg* appreciate, without
  over-complicating GLB or the end-user experience. Four items, all
  confirmed as agreed direction (added to `docs/ROADMAP.md` Version
  0.5, three of them new additions to that version's original list):
  1. **Rollback/undo** (highest value for the effort) — a
     `glb restore --undo`-style command that restores from the
     `.glb-backup` files `glb_apply_profile_dotfiles`
     (`lib/profile.sh`) already creates on every restore. The backup
     mechanism already exists; this is "just" a command that walks
     `$HOME` looking for `*.glb-backup` and reverses the symlink swap.
     Turns "I hope this works" into "I can experiment risk-free" for
     someone trying GLB for the first time — the single best
     trust-building addition relative to how little new mechanism it
     needs.
  2. **Dry-run/preview** — `glb restore <profile> --dry-run` prints
     what packages would install, what extras would run, what
     dotfiles would be symlinked/backed up, without doing any of it.
     Was already on the roadmap as "Installation preview"; elevated in
     priority specifically for the "stranger trying this for the first
     time" reason. Threads a flag through `glb_apply_profile_packages`/
     `glb_apply_profile_extras`/`glb_apply_profile_dotfiles`
     (`lib/profile.sh`, `lib/extras.sh`) rather than needing new
     mechanism.
  3. **Interactive profile picker** — `glb restore` with no profile
     argument lists profiles (`glb_list_profiles`, `lib/profile.sh`)
     and lets the user pick one, reusing the numbered-menu pattern
     `glb_configure_starship` (`lib/prompt.sh`) already has for
     Starship presets. Helps someone who doesn't know `default` vs
     `new-to-linux` is the one meant for them without reading docs.
  4. **Shell completions for `glb` itself** (bash/zsh/fish) — smallest
     of the four, standard polish expected of a finished CLI tool.
  - **Considered and deliberately rejected** as over-complicating GLB
    for its actual scope: templating (different values per machine),
    encrypted secrets, a plugin system — the kind of thing chezmoi/
    dotbot offer. Doesn't fit "curate, don't reinvent."
  - **Reference point, not a model to port:** DHH's *Omakub* is doing
    something similar in spirit (curated, opinionated fresh-Ubuntu
    setup, interactive TUI menu, one confident choice per category —
    close to what `new-to-linux` already does) and has had a lot of
    public feedback on this exact "what does a stranger want" question.
    It's Ruby-based, so nothing to port directly given GLB's
    intentional Bash-only constraint — just worth a look for
    inspiration if picking this back up.
- **Sudo-gated install pause/resume built (2026-08-06):** `glb_install_package`
  (`lib/package.sh`) now catches a failed install and pauses via a new
  `glb_prompt_manual_step` helper — prints the exact resolved command
  (e.g. `sudo apt install -y fresh`) and waits on stdin for Enter
  (continue, rechecking via `glb_package_installed`) or `s` (skip). If
  stdin has nothing to give (EOF, no interactive input available at
  all), it doesn't hang — treats that the same as skip. This is the
  roadmap item recorded earlier today after cross-distro testing kept
  hitting manual sudo installs; closes it out. Scoped to installs only
  (not `remove`/`update`) since that's what testing actually surfaced.
  5 new tests in `tests/package.bats` cover pause-then-confirm,
  pause-then-skip, no-input-available, and the post-manual-step
  recheck.
- **bats test suite actually run for the first time on this laptop
  (2026-08-06):** installed via `sudo apt install -y bats` (Greg ran it
  manually — same sudo/TTY limitation as everything else). First run
  surfaced a real pre-existing gap: `tests/profile.bats`'s `setup()`
  only stubbed `glb_package_installed`/`glb_install_package`, not
  `glb_install_starship`/`glb_install_zsh_plugins` (also called
  unconditionally by `glb_apply_profile`) — two tests were crashing on
  "command not found", a third silently passed for the wrong reason.
  Fixed by stubbing those too, same isolation pattern as the existing
  ones. Also added: coverage for the new `firefox:zypper`/
  `libreoffice:pacman` overrides, and a `dispatcher.bats` test that
  copies the *real* `profiles/new-to-linux` directory (not a synthetic
  fixture) into the sandbox and restores it end-to-end, checking the
  right dotfiles land and `.gitconfig`/ranger are correctly absent.
  All 55 tests pass as of this note.
- **`profiles/new-to-linux` built (2026-08-06):** the first profile
  beyond `default`, picked as the next multi-profile step since
  `docs/ROADMAP.md` flags it as highest-leverage — a different value
  prop from the rest of GLB ("here's what's good" vs. "restore my exact
  setup") for someone switching from Windows/macOS. Confirmed with
  Greg: Firefox (browser), **Fresh** (`getfresh.dev` — a Rust terminal
  IDE, GPL-2.0) for code editor, LibreOffice, GIMP, VLC — plus the same
  unified bash/zsh/fish + Starship + `GLB_SHELL` shell setup as
  `default` (Greg's choice: not app-only). Fresh has no native
  apt/dnf/pacman/zypper package (curl script/AUR/`.deb`/Flatpak/cargo/
  npm only) — originally listed aspirationally in `packages.txt`
  (would silently fail), moved to `extras.txt` on 2026-08-06 once the
  non-package-manager install mechanism was built (see Roadmap), where
  it now actually installs.
  Notably `default`'s dotfiles already had unused `editbash`/
  `editstarship` aliases checking for `fresh-editor`/`fresh` on `$PATH`
  before this — the pick lines up with groundwork already in place.
  Dotfiles reused from `default` as-is (`.bashrc`, `.zshrc`,
  `.config/fish/config.fish`, `.config/starship.toml`) but *excluding*
  `.gitconfig` (Greg's personal git identity — wrong to ship to someone
  else's restore) and `ranger`/WezTerm config (paired with packages not
  in this profile). Added two `_GLB_PACKAGE_OVERRIDES` entries in
  `lib/package.sh`: `firefox:zypper` → `MozillaFirefox`,
  `libreoffice:pacman` → `libreoffice-fresh` — both well-known distro
  conventions but **unverified empirically** (unlike every other
  override, which was confirmed via real per-distro testing); flag for
  verification next time a zypper or pacman restore is tested.
  - **Fixed (2026-08-06):** the `update`/`install`/`remove`/`search`
    aliases in all three shells (`.bashrc`, `.zshrc`, `config.fish`)
    were hardcoded to `apt` (comment header even said "Pop!_OS / Ubuntu
    / Debian") with no dnf/pacman/zypper branch — a pre-existing gap in
    `default`, already shipped as-is to the Fedora/CachyOS/openSUSE
    test VMs during cross-distro testing (which checked package
    installs and symlinks, never exercised these aliases), and
    duplicated into `new-to-linux` when that profile was built. Now
    auto-detects apt/dnf/pacman/zypper via `command -v`/`command -q`
    (same detection order as `lib/package.sh`) in all three shells and
    both profiles. Verified apt still resolves correctly post-fix on
    this machine (bash, zsh, fish) — behavior on dnf/pacman/zypper
    machines not yet re-verified live, same "confirm empirically" caveat
    as the new `firefox`/`libreoffice` overrides above.
- **New roadmap item (agreed 2026-08-06): pause/resume for sudo-gated
  installs.** Across every distro tested in cross-distro testing, at
  least one package needed a manual `sudo install` because the testing
  shell had no TTY for the password prompt — Greg had to switch to a
  real terminal each time. That was a testing-environment limitation,
  not a GLB bug, but Greg pointed out the real product gap it exposes:
  a real user hitting *any* sudo prompt GLB can't satisfy (password
  needed, package held back, etc.) currently has no graceful path — the
  restore should be able to pause with a clear "run this yourself, then
  press enter to continue" instead of just failing. Greg was explicit
  this wasn't a real inconvenience during testing itself — Claude handed
  him one copy-paste command each time, and all he had to do was paste
  it, enter his password, and press enter — so the ask isn't to eliminate
  that step, just to make sure the real `glb restore` flow degrades to
  something equally low-effort (stop, show the exact command, wait for
  enter) if the sudo step genuinely can't be automated, rather than
  failing outright. Added to `docs/ROADMAP.md` under Version 0.2
  (Installation Engine), alongside the existing "Error recovery" item.
  Not started — captured as a roadmap item only.
- **Debian (apt) result (2026-08-06, tested via Claude Code on Greg's real
  Debian 13 machine, the one linked to GitHub — a genuine daily-driver
  restore, not a throwaway VM):** `glb info` detected `apt` correctly.
  `git`, `zsh`, `fish`, `curl`, `fzf`, `eza`, `zoxide`, `ranger`,
  `fastfetch` were already present; `bat` was too, installed as `batcat`
  (Debian's package-name convention) — confirmed the dotfiles' existing
  `command -v batcat` fallback (present in `.bashrc`/`.zshrc`/
  `config.fish`) already handles this correctly, no gap. **No apt
  `_GLB_PACKAGE_OVERRIDES` gaps found**, closing out the last untested
  package manager (apt itself was only previously validated via Pop!_OS/
  Zorin VMs, not Debian directly). `tmux`, `neovim`, `ripgrep` were
  missing — same sandboxed-shell-has-no-TTY-for-sudo limitation as every
  other distro, Greg ran `sudo apt install -y tmux neovim ripgrep`
  directly. Dotfiles + plugin restore path passed cleanly: all 7
  dotfiles backed up to `*.glb-backup` and symlinked, Starship (already
  present) and both zsh plugins installed fine. **Confirmed:** Greg ran
  the sudo install manually and all three came up cleanly — `tmux 3.5a`,
  `nvim 0.10.4`, `ripgrep 14.1.1`. `packages.txt` is fully covered on
  apt/Debian with zero overrides needed. **All five
  GLB-supported/tested package managers (apt, dnf, pacman, zypper, plus
  apt again here on real hardware) are now confirmed clean end-to-end.**
- **Next priority (agreed 2026-08-06, after cross-distro testing wrapped
  up): multi-profile support.** Greg agreed this is the next area of
  focus — see the "Support multiple named profiles" bullet further down
  for the reasoning (it's the prerequisite for the "New to Linux"
  profile, called out there as probably the highest-leverage way to
  make GLB useful to people beyond Greg). Not started yet as of this
  note — pick up here.
- **Done (2026-08-05 to 2026-08-06): Greg cross-distro tested `glb
  restore default` on his ~10 VirtualBox VMs, then personally reviewed
  the full terminal output and signed off — "we're good to go."** All
  four GLB-supported package managers are now confirmed clean
  end-to-end: apt (Debian-family — Pop!_OS/Zorin, previously
  validated), dnf (Fedora), pacman (Arch-family — CachyOS), and zypper
  (openSUSE). Tested both existing VMs (may already have some tools
  manually installed, masking gaps) and fresh-install signal (missing
  tools that genuinely needed installing). Goal was finding real gaps
  in `_GLB_PACKAGE_OVERRIDES` (`lib/package.sh`) — which started with
  only one entry (`fd` → `fd-find` on apt) — for `eza`, `bat`,
  `zoxide`, `fastfetch`, `fish`, etc. across dnf/pacman/zypper.
  **Zero gaps found on any of them** — every name in
  `profiles/default/packages.txt` matches the real package name on
  every tested distro/package manager. The only recurring friction was
  sudo-gated installs (`zsh`/`neovim` on Fedora, `tmux`/`neovim` on
  CachyOS, `tmux`/`neovim`/`ripgrep` on openSUSE) that Greg had to run
  manually in a real terminal, since the sandboxed Claude Code shell
  has no TTY for a sudo password prompt — an environment limitation of
  testing this way, not a GLB bug. Mint (apt-based, lowest priority)
  was never separately tested but didn't need to be — apt was already
  validated via Pop!_OS/Zorin. Full per-distro results below.
  **This cross-distro testing effort is complete.**
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
    overrides needed**, same conclusion as dnf/Fedora and pacman/CachyOS.
    **Confirmed:** Greg ran `sudo zypper install -y tmux neovim ripgrep`
    directly in a real terminal on the VM; despite some install-time
    messages Greg flagged as possible errors, all three installed
    cleanly — verified via `rpm -q` (`tmux-3.7b-1.2`, `neovim-0.12.4-1.1`,
    `ripgrep-15.2.0-1.2`) and functionally: `tmux -V`/`nvim --version`
    both ran fine, and a detached `tmux new-session`/`kill-session`
    round-trip produced no errors with no `~/.tmux.conf` present. The
    flagged install-time messages didn't reproduce as any functional
    problem, most likely a benign zypper notice (e.g. a vendor-change
    confirmation or dependency note) rather than a real failure.
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
  - **Developer/Server profile content — brainstormed 2026-08-06, not
    built, revisit when picked up:**
    - Developer candidates: Docker or Podman (containers — real fork to
      decide, not just a name swap: Docker is more familiar, Podman is
      daemonless/rootless and fits GLB's philosophy better), the C/C++
      build toolchain meta-package (another per-distro naming override
      like `libreoffice`/`firefox` — `build-essential`/`base-devel`/
      dnf's `Development Tools` group/zypper equivalent), a language
      version-manager story (per-language like `nvm`/`pyenv`/`rustup`
      vs. a universal one like `asdf`/`mise` — also a real fork to
      decide deliberately), `gh` (GitHub CLI), maybe `lazygit`/`delta`,
      `postgresql-client`/`sqlite3`, `jq`.
    - Server candidates: `htop`/`btop` (see cross-cutting gap below),
      a firewall tool (`ufw` vs `firewalld` — same kind of per-distro
      fork as Docker/Podman), unattended security updates
      (`unattended-upgrades`/`dnf-automatic`/equivalents), `rsync` +
      a backup tool (`restic`/`borgbackup`), `fail2ban`. Keep the
      `GLB_SHELL` indicator — arguably *more* useful here than
      anywhere else, for telling apart SSH sessions into different
      boxes.
    - **Design nuance Greg raised, not yet resolved:** someone who
      already identifies as "a developer" or "a server admin" likely
      already knows what tools they want and how to install them
      themselves — a rigid curated list may add little value for that
      audience (unlike `new-to-linux`, where the audience by
      definition doesn't know the options). The real target for a
      built-out Developer/Server profile may be someone newer to that
      role who wants "give me a solid complete kit" without having to
      research it — closer in spirit to `new-to-linux`'s value prop
      than to `default`'s "restore my exact setup." Worth deciding
      explicitly who each profile is *for* before building it out, not
      just what packages to put in it.
    - **Cross-cutting gap found while brainstorming, independent of
      any new profile — fixed (2026-08-06):** no profile — including
      `default` — had a live resource monitor (`htop`/`btop`).
      `fastfetch` is a one-shot system-info banner, not a monitor.
      Added `htop` to `profiles/default/packages.txt` (picked over
      `btop`: htop's been the zero-doubt universal pick across every
      distro's base repos for over a decade, no strong reason to carry
      both). Scoped to `default` only, not `new-to-linux` — a process
      monitor is the same kind of power-user CLI tool as
      `tmux`/`neovim`/`ripgrep`, already excluded there for the same
      reason.
- **Non-package-manager install mechanism — built (2026-08-06).** New
  `lib/extras.sh` + a per-profile `extras.txt` manifest
  (`<method> <name> <spec>` per line, comments/blank lines stripped
  like `packages.txt`). Supports `curl` (runs `curl -fsSL <url> | sh`,
  tracked via `command -v <name>`) and `flatpak` (ensures the flathub
  remote, `flatpak install -y flathub <app-id>`, tracked via
  `flatpak info`) — not AppImage, no real candidate for it yet, but
  the format doesn't need a redesign to add it later.
  `glb_apply_profile` (`lib/profile.sh`) now calls
  `glb_apply_profile_extras` after packages, before Starship/dotfiles.
  On a failed install, reuses `glb_prompt_manual_step`
  (`lib/package.sh`, built earlier today for sudo-gated package
  installs) — same pause/print-the-command/wait-for-confirm-or-skip
  UX, now shared across both install paths. Closes two real gaps this
  session surfaced:
  - **Fresh** (the `new-to-linux` code editor) was listed
    "aspirationally" in `packages.txt` and silently failed every
    restore — moved to `extras.txt` (`curl`) in both `default` and
    `new-to-linux`, where it now actually installs. `default`'s
    dotfiles already had unused `editbash`/`editstarship` aliases
    checking for `fresh`/`fresh-editor` on `$PATH`; this is what
    finally makes those real.
  - **WezTerm**: `default`'s dotfiles symlink
    `.config/wezterm/wezterm.lua`, but `glb restore` never installed
    the app itself (Greg set it up manually via Flatpak). Added to
    `default/extras.txt` (`flatpak`, app id
    `org.wezfurlong.wezterm`); also added plain `flatpak` to
    `default/packages.txt` since the extras entry needs the `flatpak`
    binary itself first.
  - A real bash gotcha caught while building this: `PIPESTATUS` gets
    clobbered by the very next simple command — even a plain
    assignment — so reading `${PIPESTATUS[0]}` then `${PIPESTATUS[1]}`
    on separate lines silently lost the second value. Fixed by
    capturing the whole array in one shot:
    `pipe_status=("${PIPESTATUS[@]}")`.
  - New `tests/extras.bats` (manifest parsing, both methods,
    pause/confirm/skip, the PIPESTATUS-masking case explicitly) plus
    real end-to-end restores of both actual profiles in
    `tests/dispatcher.bats`. All 68 tests pass.
  - **Not done, deliberately:** no live `glb restore` was run for real
    on this laptop — everything above was built and verified entirely
    through stubbed `curl`/`sh`/`flatpak` in bats, never touching the
    real network or actually installing Fresh/WezTerm. Running a real
    restore to verify the actual installs work is something Greg would
    do himself in a real terminal, not something run automatically
    here — deliberately the same category of boundary as the sudo
    installs earlier (don't execute a downloaded script/perform a real
    install without Greg's own hands on it), just for a different
    reason (untrusted-execution caution, not a TTY limitation).
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
  — installed on the Dell laptop as of 2026-08-06 (`sudo apt install -y
  bats`); all 55 tests pass as of that date (see Roadmap section for
  what surfaced the first time it was actually run here).

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
- **Handoff to the Dell laptop session (2026-08-06):** Greg just ran
  `glb restore default` for real on the Debian machine (see "Debian
  (apt) result" in Roadmap above) and pushed the result — commit
  `b36c5f2` is the latest on `origin/main` as of this note. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming the laptop
  is caught up; it was ~24 commits behind at one point earlier this week
  and there's no guarantee it's been synced since. Cross-distro testing
  is now fully done (apt/dnf/pacman/zypper, five machines total) — **the
  agreed next step is multi-profile support** (see the "Next priority"
  bullet at the top of Roadmap and the "Support multiple named profiles"
  bullet further down for the full reasoning). Nothing has been started
  on it yet; that's the right place to pick up.
