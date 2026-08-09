# GLB Roadmap

## Purpose

This roadmap outlines the planned evolution of Greg's Linux Bootstrap (GLB).

The roadmap is intended to communicate the long-term direction of the project rather than serve as a strict schedule. Priorities may change as the project evolves.

---

# Version 0.1 — Foundation ✅

Establish the core architecture.

### Completed

- Project structure
- Git repository
- Documentation framework
- Logging module
- Utility module
- System detection module
- Banner module
- Command dispatcher
- Coding standards

---

# Version 0.2 — Installation Engine

Develop the core installation framework.

### Planned

- Package installation engine
- Distribution abstraction
- Package manager interface
- Module execution framework
- Installation verification
- Error recovery
- **Known issue, not yet fixed (confirmed 2026-08-07/2026-08-08):**
  every sudo-gated call site (`lib/package.sh`'s install/remove/update,
  `lib/prompt.sh`'s Starship install) uses plain `sudo <cmd>`. On a
  sandboxed/no-TTY restore, each failed attempt still counts as a real
  `pam_unix` auth failure — on Arch-based distros with `pam_faillock`
  enabled (`deny=3` by default), a restore with 3+ sudo-gated
  packages/extras can lock the real user out of their own terminal
  (requiring a log out/log back in, not just waiting) purely as a side
  effect of GLB's own designed-to-fail-cleanly attempts. Confirmed
  twice on real hardware: CachyOS (2026-08-07) and a separate
  EndeavourOS VM (2026-08-08) — not observed on any apt/dnf/zypper
  machine tested. Proposed fix: `sudo -n <cmd>` (non-interactive)
  instead of plain `sudo`, so a no-TTY attempt fails immediately
  without triggering the auth conversation `pam_faillock` counts. Not
  scoped or built yet — see CLAUDE.md's EndeavourOS VM Roadmap entry
  for the full root-cause writeup.
- ~~Pause/resume for sudo-gated steps~~ **Done (2026-08-06)** —
  `glb_install_package` now pauses on a failed install, prints the exact
  command to run manually, and waits for confirmation (or a skip)
  instead of failing the whole restore outright. See CLAUDE.md for
  details.
- ~~Non-package-manager installs (flatpak, AppImage, curl-install
  scripts)~~ **Done for curl/Flatpak (2026-08-06)** — new
  `lib/extras.sh` + per-profile `extras.txt`, reusing the same
  pause/resume prompt above on failure. Not AppImage — no real
  candidate for it yet. Closes the Fresh (code editor) and WezTerm
  install gaps in `default`/`new-to-linux`. See CLAUDE.md for details.

---

# Version 0.3 — Profiles

Introduce workstation profiles.

### Planned

- Greg's Recommended ⭐
- **New to Linux ✅ (2026-08-06)** — curated picks for people switching
  from Windows/macOS who don't yet know the Linux-native equivalents of
  the software they're used to (one solid choice per category, rather
  than a wall of options), built as `profiles/new-to-linux`: Firefox
  (browser), Fresh (code editor, installed via the `extras.txt`
  mechanism below), LibreOffice (office suite), GIMP (image
  editing), VLC (media player) — plus the same unified bash/zsh/fish +
  Starship shell setup as the `default` profile, minus Greg-specific
  bits (`.gitconfig`, ranger) that don't fit this profile's scope.
  **Superseded (2026-08-09):** Firefox/LibreOffice/GIMP/VLC removed —
  see the "Enhance the Terminal You Have, Don't Replace It" principle
  in `docs/PHILOSOPHY.md`. GLB doesn't install GUI applications at
  all; `new-to-linux` is now the shared shell/prompt setup plus Fresh
  (a terminal-based editor), nothing more.
- Minimal
- **Developer ✅ (2026-08-07)** — the "who is this for" question from
  the 2026-08-06 brainstorm resolved as someone newer to development
  who wants a complete kit without researching every tool choice
  (same value prop as New to Linux), built as `profiles/developer`:
  Podman (containers, chosen over Docker), gcc+make (build toolchain),
  jq, GitHub CLI (`gh`), htop, mise (language version manager, chosen
  over per-language tools like nvm/pyenv/rustup), Fresh (code editor)
  — plus the same unified bash/zsh/fish + Starship shell setup as the
  other profiles, with a guarded `mise activate` block added to each
  shell's dotfile. See CLAUDE.md for the full reasoning and forks.
- **Server ✅ (2026-08-07)** — same audience resolution as Developer
  (someone newer to server admin), built as `profiles/server`: ufw
  (firewall, chosen over firewalld), rsync + restic (backup, restic
  chosen over borgbackup), fail2ban, htop — plus the same shell setup.
  Unattended security updates deliberately **not** included — no
  single package name resolves across all four package managers (see
  CLAUDE.md and the comment in `profiles/server/packages.txt`);
  needs a new mechanism before it can be added.
- Custom

Profiles will define complete workstation experiences rather than individual package selections.

`ranger` (added to `profiles/default`'s `packages.txt` on 2026-08-05, see
CLAUDE.md) is default-on for Greg's own profile but shouldn't necessarily be
default-on for every future profile — e.g. Minimal or Server may not want a
TUI file manager. Once per-profile package selection exists, packages like
this should be opt-in per profile rather than baked into a shared list.

The "New to Linux" profile in particular targets a different value
proposition from the others: the rest of GLB (and Greg's own "Recommended"
profile) solve *restoring your own exact setup*, but someone installing
their first Linux distro doesn't have a setup to restore — their problem is
not knowing what's good. Curated, opinionated recommendations solve that in
a way a plain `packages.txt` full of names they don't recognize can't.

---

# Version 0.4 — Shell Frameworks

Expand shell support.

### Planned

- Bash enhancements
- Fish configuration
- Zsh configuration
- Oh My Zsh integration
- Fisher integration
- Bash-it evaluation
- Prompt selection and configuration

---

# Version 0.5 — User Experience

Improve the installation experience.

### Completed

- **Rollback/undo (2026-08-06).** `glb restore --undo` walks `$HOME`
  for `*.glb-backup` files left by `glb_apply_profile_dotfiles` and
  swaps each one back into place, removing the GLB-created symlink.
  Skips (doesn't clobber) any destination that's no longer a symlink,
  since that means it was touched since the restore. See CLAUDE.md.
- **Installation preview (2026-08-06).** `glb restore <profile>
  --dry-run` (flag can go before or after the profile name) prints
  what packages/extras/starship/zsh plugins/dotfiles would
  install/symlink/back up, without doing any of it — verified with a
  fully-stubbed sudo/apt/flatpak/starship/curl/git sandbox to confirm
  zero real side effects. Threaded a `dry_run` parameter through
  `glb_apply_profile_packages`/`_extras`/`_dotfiles` (`lib/profile.sh`,
  `lib/extras.sh`) plus `glb_install_starship`/`glb_install_zsh_plugins`
  (`lib/prompt.sh`, `lib/plugins.sh`), exactly as planned — no new
  mechanism needed. See CLAUDE.md.
- **Interactive profile picker (2026-08-06).** `glb restore` with no
  profile name shows a numbered menu (`glb_restore_interactive`,
  `lib/profile.sh`) reusing the same UX pattern as
  `glb_configure_starship` (`lib/prompt.sh`), and applies whichever
  profile is chosen — `--dry-run` still works, picked before or after
  the (absent) profile name. `glb_apply_profile` itself is untouched
  (still defaults to `default` for direct/scripted callers); only the
  dispatcher routes a truly-empty profile argument to the picker. See
  CLAUDE.md.
- **Shell completions for `glb` itself (2026-08-06).** New
  `completions/` directory (`glb.bash`, `_glb` for zsh, `glb.fish`)
  plus `lib/completions.sh`, called from `glb_apply_profile` like the
  other install steps: symlinks `glb` itself into `~/.local/bin` (a
  prerequisite this didn't have before — nothing previously put `glb`
  on `PATH`) and each shell's completion file into its standard
  auto-loaded location. `.bashrc`/`.zshrc` (both profiles) gained a
  `~/.local/bin` `PATH` export; `.zshrc` also gained `fpath`+`compinit`
  since zsh had no completion system initialized at all before this.
  `bash-completion` added to both profiles' `packages.txt`. See
  CLAUDE.md — including a real `GLB_ROOT` symlink-resolution bug this
  surfaced and fixed.
- **Guided configuration wizard (2026-08-07)** — closes out the last
  four Version 0.5 bullets (express installation, guided wizard,
  configuration summary, progress reporting) as one small feature, not
  four separate ones: see `docs/design/guided-wizard.md`. Express
  installation and progress reporting needed no new code (they're the
  existing direct `glb restore <profile>` path and the existing
  step-by-step log lines, respectively). The guided wizard and
  configuration summary are the same thing: `glb restore` with no
  profile name now lists each profile with a one-line description
  (`profiles/<name>/description.txt`), automatically shows a
  `--dry-run` preview of whichever one is chosen, and asks for
  confirmation before actually applying it — the new default behavior
  for the no-argument path. Discovery-only, no per-package
  customization, per the doc's scope. See CLAUDE.md for the full build.

### Planned

(none — all Version 0.5 items are complete)

---

# Version 0.6 — Configuration Management

Improve reproducibility.

### Planned

- Installation manifests
- **Configuration export/import — done (2026-08-07).** All three
  pieces of `docs/design/state-export-import.md`'s plan are now built:
  - `glb export` captures the current machine's explicitly-installed
    packages (reverse-mapped through `_GLB_PACKAGE_OVERRIDES` back to
    canonical names) plus every dotfile any local profile tracks that
    actually exists in `$HOME`, into a profile-shaped
    `snapshots/<hostname>-<date>/` directory — same
    `packages.txt`/`dotfiles/` shape `glb restore` already understands,
    plus `shell.txt` and `metadata.yaml`. Snapshots are committed
    in-repo (decided 2026-08-07), so cross-machine diffing rides the
    existing `git fetch` workflow for free.
  - `glb diff <a> <b>` compares two profile-shaped directories (either
    name is looked up in `profiles/` then `snapshots/`, so it can
    compare a snapshot against the profile it should match, two
    snapshots from different machines, or two profiles) for package and
    dotfile drift, exiting 0 if identical or 1 if any differences were
    found (matching `diff`'s own convention).
  - `glb restore --from-snapshot <name>` applies a snapshot the same
    way `glb restore <profile>` applies a profile (packages, extras,
    prompt/plugins, dotfiles) — since a snapshot is the exact same
    shape as a profile, this reuses the existing restore engine almost
    verbatim.
  - Verified end-to-end for real on the openSUSE VM, including a full
    export -> diff -> restore --from-snapshot --dry-run round-trip. See
    CLAUDE.md for the full build notes, including a real zypper
    limitation (no manual-vs-dependency package tracking) and a real
    scope gap (extras.txt-installed packages aren't reverse-mapped to
    their canonical name yet).
- **Repair existing installations (2026-08-07).** See
  `docs/design/repair.md`. Most "repair" scenarios turned out to
  already be solved by `glb restore <profile>`'s existing idempotency
  (a second restore already comes back clean, reinstalling anything
  missing) — the real gap was just a one-shot convenience command:
  `glb repair <profile>` does an ephemeral export + diff against the
  profile (no snapshot saved to disk), then offers to re-run `glb
  restore` if drift is found. Built entirely from existing pieces
  (`glb export`'s and `glb diff`'s own internals), no new detection
  mechanism. Deliberately deferred: deepening the installed-checks
  themselves to catch real corruption (concrete known gap:
  `glb_install_zsh_plugins` only checks that a directory exists, not
  that the clone inside it is complete) — worth doing once real
  corruption cases actually show up, not pre-emptively.
- **Update installed components — done (2026-08-07, Dell laptop).**
  See `docs/design/update-components.md`. `glb update` already covered
  system packages; now also updates everything else GLB installs
  outside the package manager: Starship (`glb_update_starship`,
  `lib/prompt.sh` — re-runs the installer if already present, no-op
  otherwise) and vendored zsh plugins (`glb_update_zsh_plugins`,
  `lib/plugins.sh` — `git pull` on any plugin already cloned). `glb
  update` gained an optional profile argument (`glb update [profile]`)
  — with a profile given, also re-runs that profile's already-installed
  `extras.txt` entries via new `glb_update_profile_extras`/
  `_glb_update_extra` (`lib/extras.sh`): `curl` re-runs the install
  script, `flatpak` uses the native `update` verb (not `install`),
  `font` re-downloads and re-extracts. No confirmation prompt anywhere,
  matching `glb update`'s existing unprompted style — a deliberate
  difference from the guided wizard/`glb repair`'s confirm-first
  pattern, since this extends an existing command's established
  convention rather than inventing a new one. GLB updating its own code
  stayed explicitly out of scope, as planned.
  - Dispatcher validates an explicitly-given profile name exists
    (`Profile not found: <name>`, same wording as every other
    profile-taking command) before doing anything.
  - 17 new bats tests across `tests/prompt.bats`, `tests/plugins.bats`,
    `tests/extras.bats`, and `tests/dispatcher.bats`. **Real gotcha
    caught by the dispatcher-level tests, not the unit tests:** this
    laptop has a genuine `starship` binary on `PATH` outside the test
    sandbox (`STUB_BIN` is prepended to, not a replacement for, the
    real `PATH`) — the pre-existing "glb update runs the package
    manager's update commands" test started failing because
    `glb_update_starship` found that real binary and attempted a real
    network install via unstubbed `curl`/`sh`. Fixed by stubbing
    `curl`/`sh` to safe no-ops in `tests/dispatcher.bats`'s shared
    `setup()`, the same PATH-bleed class of issue already documented
    elsewhere in this file for `fresh`/`starship`. 201/202 bats tests
    pass overall — the one failure is a pre-existing, unrelated zypper
    test that also fails on unmodified `main` on this apt machine.
  - **Real, for-real verification on this laptop (2026-08-07), Greg's
    actual daily driver:** bare `./glb update` run for real —
    `sudo apt upgrade`/Starship's reinstall both failed cleanly with
    zero side effects (no TTY for sudo), zsh plugins updated
    unprompted (`zsh-syntax-highlighting` fast-forwarded a real
    upstream commit). Greg then ran the two printed sudo-gated
    commands himself; confirmed afterward via `starship --version`
    (`1.26.0`, `/usr/local/bin/starship`) that the update genuinely
    took. `glb update`'s system/starship/plugins path is now confirmed
    on real hardware. Still only bats-verified: `glb update <profile>`'s
    `extras.txt` re-run path.

---

# Version 0.7 — Cross-Distribution Support

Expand platform support.

### Target Distributions

- **Debian ✅** — apt confirmed via a real `glb restore default` on an
  actual Debian 13 daily-driver machine (2026-08-06). Zero package
  overrides needed.
- **Ubuntu ✅ (via derivatives)** — apt confirmed via real restores on
  Ubuntu-based distros: Pop!_OS (daily-driver laptop plus a dedicated
  test VM), Linux Mint 22.3, and Zorin OS. Stock Ubuntu itself hasn't
  been separately tested, but it's the same package manager, confirmed
  clean across every derivative tried.
- **Pop!_OS ✅** — the most extensively tested target: a real
  daily-driver laptop plus a dedicated test VM where all five profiles
  (`default`, `new-to-linux`, `developer`, `server`) have each been
  restored for real, including the rollback/undo and dry-run paths.
- **Fedora ✅** — dnf confirmed via a real `glb restore default` on a
  Fedora 44 Workstation test VM (2026-08-05). Zero package overrides
  needed.
- **Arch Linux ✅** — pacman confirmed via a real `glb restore default`
  plus `new-to-linux`'s pacman-specific overrides (`libreoffice` →
  `libreoffice-fresh`, `gh` → `github-cli`) on a CachyOS (Arch-based)
  test VM (2026-08-05, 2026-08-07). Independently reconfirmed on a
  second, separate Arch-based machine — an EndeavourOS test VM
  (2026-08-08): zero `_GLB_PACKAGE_OVERRIDES` gaps, all four extras
  methods (curl/flatpak/font/starship-installer) working, and a clean
  idempotent second restore. Also where the `pam_faillock` lockout
  issue above was root-caused — see the Version 0.2 known-issue entry.
- **Manjaro** — not tested. Arch-family, so the underlying package
  manager (pacman) is already confirmed via CachyOS, but Manjaro itself
  has never actually been run.

All four package managers GLB supports (apt, dnf, pacman, zypper) are
now confirmed clean end-to-end across real hardware and VMs — see
CLAUDE.md's Roadmap section for the full per-distro verification
history. Note: zypper/openSUSE isn't on this target-distro list at all,
despite being a fully supported package manager that's since received
the deepest real-world testing of any distro here (the original
cross-distro pass, per-distro package overrides, and the entire
state-export-import feature set were all verified on an openSUSE VM) —
worth adding explicitly if openSUSE becomes a stated target, rather
than left as an unlisted extra.

Additional distributions will be added as independent modules when practical.

---

# Version 1.0 — Stable Release

Deliver the first stable version of GLB.

### Goals

- Stable installation engine
- Profile system
- Modular architecture
- Reliable cross-distribution support
- Comprehensive documentation
- Community-ready project

---

# Long-Term Vision

GLB will evolve into the easiest way to make a Linux terminal feel like
home — a polished, reproducible, and customizable shell/prompt/CLI-tool
experience, built by integrating the best existing open-source software
rather than reinventing it.

Rather than replacing mature open-source projects (or the terminal
emulator someone already has), GLB focuses on providing a consistent
configuration experience *inside the terminal* across supported Linux
distributions.

---

# Guiding Philosophy

- User Experience First
- Curate, Don't Reinvent
- Modular by Design
- Profiles Over Package Lists
- Open Source First
- Consistent Across Distributions
- Opinionated but Customizable

---

> **Note:** This roadmap reflects the current vision of GLB. It is intentionally flexible and will continue to evolve as the project grows and new ideas emerge.
