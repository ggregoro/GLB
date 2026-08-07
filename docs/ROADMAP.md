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
  bits (`.gitconfig`, ranger, WezTerm) that don't fit this profile's
  scope.
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

### Planned

- **Express installation, guided configuration wizard, configuration
  summary, progress reporting — scoped (2026-08-07), not yet built.**
  These four bullets turned out to collapse into one small feature, not
  four separate ones: see `docs/design/guided-wizard.md`. Express
  installation and progress reporting need no new code at all (they're
  the existing direct `glb restore <profile>` path and the existing
  step-by-step log lines, respectively); configuration summary and the
  guided wizard are the same thing — a richer version of the existing
  no-argument `glb restore` picker (profile descriptions + an automatic
  `--dry-run` preview + a confirm step), discovery-only, not
  per-package customization. One open question in the doc: whether this
  becomes bare `glb restore`'s new default behavior or stays opt-in.

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
- Repair existing installations
- Update installed components

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
  test VM (2026-08-05, 2026-08-07).
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

GLB will evolve into a complete Linux workstation builder that delivers a polished, reproducible, and customizable user experience by integrating the best existing open-source software.

Rather than replacing mature open-source projects, GLB focuses on providing a consistent installation and configuration experience across supported Linux distributions.

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
