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

### Planned

- Express installation
- Guided configuration wizard
- **Installation preview** — agreed priority (2026-08-06): `glb restore
  <profile> --dry-run` showing what would install/symlink/back up
  without touching anything. Highest-value trust-builder for someone
  other than Greg trying GLB for the first time; mostly threads a flag
  through logic that already exists. See CLAUDE.md for full reasoning.
- Configuration summary
- Progress reporting
- **Interactive profile picker — agreed priority (2026-08-06), not on
  the original list.** `glb restore` with no profile argument lists
  profiles and lets the user pick, reusing the numbered-menu UX
  `lib/prompt.sh`'s `glb_configure_starship` already has for Starship
  presets. Helps someone who doesn't know which profile name
  (`default` vs `new-to-linux`) is meant for them. See CLAUDE.md.
- **Shell completions for `glb` itself — agreed priority (2026-08-06),
  not on the original list.** bash/zsh/fish completion for `glb
  <TAB>` — small effort, standard polish expected of a finished CLI
  tool. See CLAUDE.md.

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
