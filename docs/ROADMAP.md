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
- Developer — candidate tools and an open question on who this profile
  is really for (see CLAUDE.md, 2026-08-06 brainstorm) brainstormed but
  not built
- Server — same, candidate tools brainstormed but not built (see
  CLAUDE.md)
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

- Express installation
- Guided configuration wizard
- Configuration summary
- Progress reporting

---

# Version 0.6 — Configuration Management

Improve reproducibility.

### Planned

- Installation manifests
- Configuration export
- Configuration import
- Repair existing installations
- Update installed components

---

# Version 0.7 — Cross-Distribution Support

Expand platform support.

### Target Distributions

- Debian
- Ubuntu
- Pop!_OS
- Fedora
- Arch Linux
- Manjaro

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
