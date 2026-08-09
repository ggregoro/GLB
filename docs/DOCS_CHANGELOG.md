# GLB Documentation Changelog

This changelog records significant milestones, improvements, and lessons
learned while developing the Greg's Linux Bootstrap (GLB) *project itself*
(docs restructuring, dev-environment setup, networking/SSH groundwork) —
distinct from the root [`CHANGELOG.md`](../CHANGELOG.md), which tracks
`glb`'s actual feature/code changes. This file has been quiet since the
early docs restructuring (2026-08-02); day-to-day feature work is
recorded in the root CHANGELOG and in `CLAUDE.md`'s Roadmap section.

## [Unreleased]

### Added

- Added `PHILOSOPHY.md` to document the guiding principles of GLB.
- Added `ROADMAP.md` outlining the long-term direction of the project.

### Changed

- Updated the README to reflect the evolution of GLB into a Linux workstation builder.
- Revised PROJECT.md with a new mission, vision, and core principles.
- Reworked ARCHITECTURE.md to document the modular workstation builder architecture.
- Expanded CODING_STANDARDS.md to emphasize user experience, modularity, and integration with existing open-source projects.
- Updated the project's guiding philosophy from a Linux bootstrap script to a user experience focused workstation builder.
---

## 2026-08-02

### Documentation

- Created the `docs/` directory structure.
- Added `docs/README.md`.
- Added the first reference page:
  - `docs/reference/debian-server-cheat-sheet.md`

### Git & GitHub

- Configured Git on the Pop!_OS laptop.
- Generated an ED25519 SSH key for the laptop.
- Added the laptop SSH key to GitHub.
- Successfully cloned the GLB repository to the laptop.
- Successfully committed and pushed documentation from the laptop.

### Networking

- Configured Samba file sharing on the Debian VM.
- Verified Windows access to the Samba Exchange share.
- Verified Pop!_OS access to the Samba Exchange share.
- Connected to Samba shares using `smbclient`.

### SSH

- Verified SSH connectivity from Pop!_OS to the Debian VM.
- Mounted the Debian home directory using SSHFS.
- Verified remote filesystem access through Ranger.

### Development Environment

- Established the Pop!_OS laptop as a GLB development workstation.
- Established the Debian VM as a network services and development server.

---

## Future Documentation

Planned reference pages:

- Git Cheat Sheet
- Ranger Cheat Sheet
- Fish Shell Cheat Sheet
- VirtualBox Cheat Sheet
- COSMIC Desktop Cheat Sheet
- Samba Cheat Sheet
- SSH Cheat Sheet

Planned tutorials:

- Installing Pop!_OS
- Installing Debian
- GitHub SSH Setup
- Samba Server Setup
- SSHFS Setup
- Fish Shell Configuration
- Ranger Configuration
- Git Workflow

---

## Project Goal

GLB is intended to become both:

1. A reproducible Linux bootstrap and configuration system.
2. A living knowledge base documenting the design decisions, tools, workflows, and lessons learned throughout the project.
