# Design: Updating Installed Components

**Status:** Built (2026-08-07, Dell laptop)
**Added:** 2026-08-07

## Motivation

`glb update` already exists and runs the package manager's own upgrade
(`apt update && apt upgrade -y`, `dnf upgrade -y`, `pacman -Syu
--noconfirm`, `zypper refresh && zypper update -y`) — unprompted, no
confirmation step, matching its existing "just do it" style. Plain
system packages are already covered.

Everything else GLB installs *outside* the package manager has no
update path at all today:

- **Extras** (`extras.txt`): curl-installed things like Fresh never get
  re-run once installed; Flatpak apps (the `flatpak` extras method is
  still supported, even though no current profile uses it) are never
  `flatpak update`d; the Nerd Font's install URL is already a "latest"
  redirect (so re-running the same download would pick up the current
  release automatically), it's just never re-run.
- **Vendored zsh plugins** (`_GLB_ZSH_PLUGINS`, `git clone --depth 1`):
  the install check is presence-only (`[[ -d "$dest" ]]`) — once
  cloned, never `git pull`ed.
- **Starship**: same presence-only check. Its own official installer
  (`curl -sS https://starship.rs/install.sh | sh -s -- -y`) is safe to
  re-run and updates in place, but GLB's check currently prevents that
  from ever happening automatically.

## Scoping decisions (2026-08-07, via `AskUserQuestion`)

- **Extend the existing `glb update` command**, don't add a separate
  new one. Matches "one clear path" and what a user would already
  expect `glb update` to mean, rather than making them remember a
  second command for the pieces a package manager can't reach.
- **GLB updating its own code is explicitly out of scope.** A `git
  pull` of the GLB repo itself is a meaningfully different, more
  sensitive operation (self-modifying a running script mid-execution)
  — worth treating as its own separate future item, not bundled here.
  This feature covers only what `glb restore` installs.

## A necessary consequence, not a separate design fork

`extras.txt` is per-profile data, but `glb update` currently takes no
arguments at all — there's no way to know *which* profile's
`extras.txt` to check. Starship and the curated zsh plugins aren't
profile-specific (one global list/binary regardless of which profile
was restored), so they don't have this problem. Extras do.

Resolution: `glb update` gains an **optional** profile argument (`glb
update [profile]`). With no argument, behavior is a strict superset of
today's — system packages, plus starship and zsh plugins if present
(new), but no extras (nothing to key them against). With a profile
name given, it additionally re-runs that profile's `extras.txt`
entries. Existing scripted/muscle-memory usage of bare `glb update`
keeps working and gets more thorough, not different.

## Scope

**In scope:**

- System packages: unchanged, existing `glb_update_packages` per-distro
  logic.
- Starship: new `glb_update_starship` (`lib/prompt.sh`) — if `starship`
  is on `PATH`, re-run the same installer command that installs it;
  skip entirely if not installed at all (only touch what's actually
  here, matching every other GLB check's philosophy).
- Zsh plugins: new `glb_update_zsh_plugins` (`lib/plugins.sh`) — for
  each curated plugin whose directory already exists, run `git -C
  <dest> pull` (a safe no-op if already current).
- Extras (only when a profile name is given): new
  `glb_update_profile_extras` (`lib/extras.sh`), parallel to the
  existing `glb_apply_profile_extras` — for each `extras.txt` entry
  that's currently installed:
  - `curl`: re-run the same `curl -fsSL <url> | sh` command.
  - `flatpak`: run `flatpak update -y <app-id>` (the correct native
    update verb, distinct from `install`).
  - `font`: re-run the same download+extract (the URL is already a
    "latest" redirect, so this naturally fetches the current release).
- No confirmation prompt anywhere in this — matches `glb update`'s
  existing unprompted style. This is a deliberate difference from the
  guided wizard/`glb repair`'s confirm-before-apply pattern: those are
  new commands free to set their own convention, this is extending a
  command whose convention already exists.
- Validate an explicitly-given profile name exists (error cleanly if
  not), same as every other profile-taking command.

**Explicitly out of scope:**

- GLB updating its own code (see decision above).
- Any new confirmation/preview step for `glb update` itself.
- `--dry-run` support for `glb update` — it doesn't have one today and
  extending it isn't part of this feature.

## Why this is viable rather than scope creep

Every mechanism needed already exists somewhere in the codebase: the
per-distro update commands, the curl/flatpak/font install commands
(just re-run instead of skipped), and `git pull` is a one-line addition
parallel to the existing `git clone --depth 1`. The only genuinely new
code is three small functions and the optional-argument plumbing in the
dispatcher.
