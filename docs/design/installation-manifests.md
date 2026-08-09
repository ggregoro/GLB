# Design: Installation Manifests

**Status:** Implemented (2026-08-09)
**Added:** 2026-08-09

## Motivation

"Installation manifests" sat in `docs/ROADMAP.md`'s Version 0.6 list with
no plan written at all, unlike every other item in that version
(export/import, repair, update-components each got a `docs/design/*.md`
before being built). The term itself is ambiguous — it could mean an
audit trail of what GLB installed, a version-pinned lockfile, or letting
someone supply their own package list from outside the repo. Needed
scoping before building anything.

## Scoping decision (2026-08-09, via `AskUserQuestion`)

Three candidate meanings were considered:

1. **Bring-your-own external manifest (chosen).** Let someone point
   `glb` at their own package-list/dotfiles directory outside the
   built-in `profiles/`, for a one-off custom install without creating
   a full profile in the repo.
2. Per-run audit trail of exactly what GLB installed vs. what was
   already on the machine (would enable a real "uninstall everything
   GLB added").
3. Version-pinned lockfile — exact installed package *versions*, not
   just names (`glb export` already captures names only).

**Chose (1).** Directly matches how Greg described the gap: "provide
external options to run from within the program." (2) and (3) are both
real, separate ideas — worth their own future scoping if they come up,
not folded into this one.

## Scope

**In scope:**

- `glb restore --from-manifest <path>`: applies a profile-shaped
  directory (`packages.txt` + optional `extras.txt`/`dotfiles/`) from
  *any* path on disk — not looked up under `profiles/` or `snapshots/`
  by name, unlike every other restore mode. The whole point is that it
  lives outside the repo.
- Same six-step apply sequence as `glb_apply_profile`/
  `glb_apply_snapshot` (packages → extras → Starship → zsh plugins →
  self-symlink/completions → dotfiles), and the same `--dry-run`
  support.
- Missing `extras.txt`/`dotfiles/` handled exactly like a profile
  missing them — already-graceful no-ops in the reused functions, no
  new handling needed.

**Explicitly out of scope:**

- Any validation of the manifest directory's *contents* beyond "does it
  exist" — same posture as profiles and snapshots, which don't validate
  `packages.txt` content either. A malformed manifest fails the same
  way a malformed profile would (per-package/per-dotfile errors as
  they're encountered).
- Committing example manifests to the repo, or a scaffolding command to
  generate one — someone bringing their own manifest is expected to
  write `packages.txt` in the same plain format every profile already
  uses (documented at the top of any `profiles/*/packages.txt`).

## How it's built (reusing existing pieces, no new mechanism)

Followed the same pattern `glb_apply_snapshot` set: **duplicate, don't
refactor**, `glb_apply_profile`'s body — many existing bats tests assert
on `glb_apply_profile`'s exact log wording, so extracting a shared
helper risked breaking those for a "premature abstraction" this
project's own conventions warn against.

- New `glb_apply_manifest <path> [--dry-run]` in `lib/profile.sh`
  (co-located with `glb_apply_profile`, its natural sibling — unlike
  `glb_apply_snapshot`, there's no "export" counterpart to pair with in
  `lib/export.sh`). Validates the path is a real directory
  (`Manifest directory not found: <path>` if not), then calls the same
  six functions `glb_apply_profile`/`glb_apply_snapshot` already call,
  against the given path directly.
- Dispatcher (`glb`): `restore`'s argument loop gained a
  `--from-manifest <path>` two-token flag, parsed identically to the
  existing `--from-snapshot <name>` (works before or after
  `--dry-run`, in either order).
- 6 new bats tests in `tests/restore_manifest.bats` (mirroring
  `tests/restore_snapshot.bats` one-for-one: missing path, empty path,
  real apply, a failing package, `--dry-run`, no-`extras.txt`, plus one
  extra confirming a deeply nested arbitrary path works) and 3 new
  dispatcher end-to-end tests (apply, `--dry-run` in either order,
  nonexistent path).
