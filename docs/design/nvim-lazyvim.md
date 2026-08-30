# Design: Neovim + LazyVim config on restore

**Status:** Implemented (2026-08-30)
**Added:** 2026-08-30

## Motivation

GLB's `default` profile has installed the `neovim` package since the
project's earliest days, but never configured it — `glb restore default`
left you with a bare `nvim`. GWB (the Windows sibling) closed the same
gap on 2026-08-30 by having `gwb restore` clone Greg's own LazyVim setup
(`Install-GwbNvimConfig`, see GWB's `docs/design/nvim-lazyvim.md`). This
brings GLB to parity.

## The real fork: vendor a static copy, or clone the config repo?

Every other config GLB manages (`dotfiles/`, `starship.toml`, the
`yazi/` config) is a static file vendored into this repo and symlinked
into place. Greg's Neovim setup is different: it's his own
actively-maintained personal config, already a separate private GitHub
repo (`github.com/ggregoro/nvim-config`, a LazyVim starter he keeps
tweaking). Vendoring a snapshot into GLB would go stale the moment he
changed anything there and force a manual re-sync into this repo on
every tweak.

**Decided (2026-08-30, via `AskUserQuestion`):** treat `nvim-config` as
the living source of truth and clone it. Two sub-decisions:

- **True parity — clone the real private repo**, not the public
  `LazyVim/starter` and not an env-var-only stub. A machine without SSH
  access to `nvim-config` (i.e. anyone who isn't Greg) gets a clean
  "clone failed" message and an otherwise-normal restore; `nvim` still
  installs, it's just unconfigured. `GLB_NVIM_CONFIG_REPO` in the
  environment overrides the URL (mirrors GWB's `GWB_NVIM_CONFIG_REPO`),
  so a fork or a different user can point it at their own.
- **`default` profile only.** GWB put it in all three profiles; for GLB,
  `neovim` is only in `default`'s `packages.txt` today and that's where
  the config belongs too. `developer`/`server` are untouched.

This is a new pattern for GLB — a restore reaching out to clone a
*second*, separate git repo, rather than installing a package or
symlinking a vendored file. The closest precedent is `lib/plugins.sh`
git-cloning the zsh plugins, but those are public, pinned, and
write-once; this is a private repo that gets pulled on every restore.

## Scope

**In scope:**

- **Opt-in per profile** via `profiles/<name>/nvim-config.txt` — one
  line, the repo's clone URL (blank lines and `#` comments ignored, same
  parser rules as `packages.txt`). Only `profiles/default/` ships one.
  No file → `glb_install_nvim_config` is a silent no-op.
- **`glb_install_nvim_config` (`lib/profile.sh`)**, called from
  `glb_apply_profile`, `glb_apply_manifest`, and `glb_apply_snapshot`
  (snapshots never carry an `nvim-config.txt`, so it no-ops there —
  wired in for consistency, not because a snapshot needs it).
- Self-gates on `nvim` **and** `git` being present. A restore where the
  `neovim` package install was skipped (no TTY for the sudo prompt, say)
  doesn't then fail here.
- Target is `${XDG_CONFIG_HOME:-$HOME/.config}/nvim`. If that directory
  is already a clone of the resolved repo URL (checked via `git -C …
  remote get-url origin`), `git pull --ff-only`; otherwise clone fresh.
- **Backup-on-first-touch**, the same rule `glb_apply_profile_dotfiles`
  follows: a real pre-existing `~/.config/nvim` that *isn't* already
  this clone is moved (not copied — `git clone` needs an empty
  destination) to `~/.config/nvim.glb-backup` exactly once. A later run
  that finds a backup already present re-clones over the directory
  rather than clobbering the backup that's protecting the original data.
- **`--dry-run`** threaded through: reports "Would clone / Would pull /
  Would back up … then clone" without touching anything.
- **`glb restore --undo`** (`glb_undo_restore`) restores `~/.config/nvim`
  from `~/.config/nvim.glb-backup` explicitly, *before* the generic
  `$HOME`-walk — the generic symlink-swap logic can't handle a directory
  that's a git clone rather than a symlink.

**Explicitly out of scope:**

- `developer`/`server` profiles (see the scoping decision above).
- `glb export` / `glb diff` / `glb repair` awareness of the Neovim
  config — same call GWB made. Those operate on packages + dotfiles;
  `nvim-config` is neither, and it has its own `git` history for
  tracking changes.
- Bootstrapping LazyVim itself if `nvim-config` is unreachable — the
  clone either works or it doesn't, and a failed clone is a logged
  warning, not a fallback path.

## How it's built

`glb_install_nvim_config <profile_dir> [--dry-run]` in `lib/profile.sh`:

1. `return 0` immediately if `<profile_dir>/nvim-config.txt` is absent.
2. Resolve the repo URL: `GLB_NVIM_CONFIG_REPO` if set, else the first
   non-blank, non-`#` line of `nvim-config.txt` (read in pure bash, no
   `grep`/`head`, so the nvim-absent path needs no external commands).
3. `return 0` (with a dry-run note) if `nvim` isn't on `PATH`; warn and
   `return 0` if `git` isn't.
4. Decide "is this already our clone?" via `git -C "$config_dir" remote
   get-url origin` matching the resolved URL.
5. Own clone → `git pull --ff-only --quiet` (a failed pull is a warning,
   not an error — the machine keeps working). Not our clone → back up
   or clear `~/.config/nvim` per the rule above, then
   `git clone --quiet`, and confirm `init.lua` landed.

Tests: `tests/nvim_config.bats` (14 tests — the gate, clone, pull,
backup, no-clobber, env override, every dry-run message, the
nvim-absent branch, and the undo round-trip), with `git`/`nvim` stubbed.
`tests/dispatcher.bats`'s shared `git` stub now drops an `init.lua` on
`git clone <dest>` so the real-`default`-profile end-to-end tests pass
cleanly through the new step.

Verified for real on the Pop!_OS Cosmic laptop, 2026-08-30: fresh clone
+ one-time backup, an idempotent second run (`git pull`, backup
untouched), every dry-run message, the `GLB_NVIM_CONFIG_REPO` override,
and a full `--undo` round-trip restoring the original directory.
