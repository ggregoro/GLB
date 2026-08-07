# Design: State Export / Import

**Status:** Proposed — not yet implemented
**Added:** 2026-08-07

## Motivation

GLB currently handles one direction: given a profile (declarative — what *should* be installed/configured), `glb restore` bootstraps a fresh machine to match it.

This proposal adds the reverse direction: capture what a machine *actually* has installed/configured right now, in the same profile-shaped format GLB already understands. This turns GLB into a light backup/restore tool for system configuration — without duplicating what full disk-imaging or personal-file-backup tools already do well.

## Scope

**In scope:**
- Packages (reverse-mapped through existing `_GLB_PACKAGE_OVERRIDES` back to canonical names)
- Dotfiles GLB already tracks/links
- Shell + prompt configuration
- Drift detection between a live machine and a named profile

**Explicitly out of scope:**
- Disk/partition imaging (Clonezilla's job)
- Personal file backup — documents, photos, downloads (Deja Dup/restic/BorgBackup territory)
- Reimplementing filesystem snapshotting (Timeshift/Snapper already do this well; GLB can optionally *trigger* a snapshot before a risky restore, not reimplement the mechanism)

## Structural sketch

```
   [live machine]  --export-->  [state snapshot]  --diff/merge-->  [profile]
   [profile]       --restore--> [live machine]     (already exists: glb restore)
```

### 1. `glb export` — capture current state

Writes a snapshot in the same shape as an existing profile, not a new format:

```
snapshots/
  <hostname>-<date>/
    packages.txt          # same format as profiles/default/packages.txt
    dotfiles/               # actual copies of tracked config files
    shell.txt                # detected shell + prompt setup
    metadata.yaml            # distro, GLB version, timestamp, hostname
```

- Package list is queried per package manager (`pacman -Qqe`, `dpkg --get-selections`, `rpm -qa`, etc.), then reverse-mapped through `_GLB_PACKAGE_OVERRIDES` so it comes out in GLB's canonical package names rather than raw distro-specific ones.
- Dotfiles: only files GLB's existing dotfile-linking logic already manages — not a blind home-directory scrape. Keeps scope sane, avoids becoming a personal-file backup tool.
- Output is directly consumable by the existing `glb restore` code path — no new restore logic needed for the basic case.

### 2. `glb diff <snapshot> <profile>` — drift detection

Compares live state against a named profile and reports differences:

```
+ installed but not in profile: neovim, htop
- in profile but missing: ranger
~ dotfile changed since last restore: ~/.wezterm.lua
```

Useful standalone, independent of backup/restore — e.g., catching packages installed ad hoc on a test VM that never made it into the tracked profile.

### 3. `glb restore --from-snapshot <name>` — reuses existing restore engine

Since a snapshot is just a profile variant, this is close to free — same code path as `glb restore default`, pointed at a different profile source.

## Open design question

Should snapshots live in the GLB repo itself (versioned, shareable across machines like `CLAUDE.md`), or in a separate location per machine?

Given the existing multi-machine workflow (`git fetch && git log main..origin/main` at session start), keeping snapshots in-repo would allow diffing snapshots across machines directly — e.g., "what does CachyOS actually have installed" vs. "what does openSUSE actually have installed" — for free, with no extra sync mechanism.

## Why this is viable rather than scope creep

Most of the underlying machinery already exists: the profile format, package overrides, dotfile linking, and restore engine. Export is largely the inverse of restore, using the same data shapes. The genuinely new work is small — querying installed packages per package manager, and the diff comparison — rather than building a backup tool from scratch.
