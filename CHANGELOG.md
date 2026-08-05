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
- Added a bats test suite (`tests/`) covering package manager detection,
  the profile system (packages.txt parsing, dotfiles symlinking and
  backup), and the `glb` dispatcher's remove/update/restore/profiles
  commands.

### Fixed
- Fixed zypper not being detected as an available package manager.

### Planned

- Initial bootstrap framework
- Documentation system
- Fish shell configuration
- Ranger configuration
- Git bootstrap
- SSH bootstrap
- Samba support
- Support for apps outside the standard package manager (flatpak,
  AppImage, curl-install scripts)
- Per-distro package name overrides (e.g. `fd` vs `fd-find`)

---

## [0.1.0] - 2026-08-02

### Added

- Initial GitHub repository
- Documentation structure
- Debian Server Cheat Sheet
