# GLB Documentation Changelog

This changelog records significant milestones, improvements, and lessons learned while developing the Greg's Linux Bootstrap (GLB) project.

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
- Ghostty Cheat Sheet
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
