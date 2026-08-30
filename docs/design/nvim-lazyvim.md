# Design: Neovim + LazyVim config on restore

**Status:** Implemented (2026-08-30)
**Superseded:** 2026-08-30 (same day) — see "Revision: public, vendored
config" below. The original private-repo-clone design is kept here as a
record of what was tried and why it changed, not a description of what
GLB does today.

## Motivation

GLB's `default` profile has installed the `neovim` package since the
project's earliest days, but never configured it — `glb restore default`
left you with a bare `nvim`. GWB (the Windows sibling) closed the same
gap on 2026-08-30 by having `gwb restore` clone Greg's own LazyVim setup.
This brought GLB to parity — at first.

## Revision: public, vendored config (2026-08-30, same day)

The first cut (below) cloned Greg's own private `nvim-config` repo on
every restore — real parity with his actual setup, but only for
machines with SSH access to that private repo. Greg caught this
directly: GLB is a public project, and its features — Neovim/LazyVim
included — should work for anyone, on any machine, with no external
dependency. **Revised**, same day: GLB now vendors the real, official
[LazyVim/starter](https://github.com/LazyVim/starter) template as a
normal tracked dotfile (`dotfiles/.config/nvim/`), fetched byte-for-byte
from upstream and symlinked exactly like every other dotfile GLB
manages — no git-clone-a-second-repo mechanism, no SSH key, no private
repo, in **all three profiles** (`default`/`developer`/`server`, per
Greg: "Neovim along with Lazy Vim should be built in for all profiles on
GLB").

**Why per-file symlinks, not a symlinked directory:** LazyVim's own
`lazy.nvim` plugin manager writes `lazy-lock.json` into
`~/.config/nvim/` on first launch, and installs the plugins themselves
into `~/.local/share/nvim/lazy/` (untouched by this at all).
`glb_apply_profile_dotfiles`'s existing per-file symlink walk (used for
every dotfile already) creates `~/.config/nvim/` as a real directory
containing individually-symlinked static files (`init.lua`, `lua/
config/*.lua`, …) — so when `lazy-lock.json` gets created later, it
lands as a plain, independent file in a real directory, never inside
GLB's own git checkout. This is the same reasoning that ruled out
symlinking `~/.config/nvim` as a whole directory (which the old
private-repo-clone design used, via `git clone`).

**What this removed:** the entire `glb_install_nvim_config` function
(`lib/profile.sh`), its calls from `glb_apply_profile`/
`glb_apply_manifest`/`glb_apply_snapshot`, `profiles/default/
nvim-config.txt`, the `GLB_NVIM_CONFIG_REPO` override, the
Neovim-specific special-casing in `glb_undo_restore` (no longer needed —
the generic per-file backup/restore logic already covers individually
symlinked dotfiles), and `tests/nvim_config.bats` (14 tests, no longer
applicable). Replaced by nothing but the vendored files themselves —
the existing dotfile machinery does the rest, for free.

**What a personal config now looks like:** the same answer as any other
GLB-managed dotfile (see CLAUDE.md's 2026-08-10 discussion of
personalizing `starship.toml`) — either edit through the symlink (lands
inside GLB's own checkout, not ideal for a personal fork) or use `glb
restore --from-manifest <path>` with your own directory. No
LazyVim-specific override mechanism was rebuilt; the generic ones
already cover it.

---

## Original design (2026-08-30, superseded same day — kept for record)

### The real fork: vendor a static copy, or clone the config repo?

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

This turned out to be exactly backwards from what Greg actually wanted
once he saw it fail on a machine without his private-repo access (a
CachyOS VM, 2026-08-30) — see the revision above.

### How it was built (no longer current)

`glb_install_nvim_config <profile_dir> [--dry-run]` in `lib/profile.sh`
resolved a repo URL from `nvim-config.txt` (or `GLB_NVIM_CONFIG_REPO`),
self-gated on `nvim`+`git` being present, and either `git pull
--ff-only`ed an existing clone or backed up/cleared `~/.config/nvim`
and `git clone`d fresh, wired into `glb_apply_profile`/
`glb_apply_manifest`/`glb_apply_snapshot` and explicitly special-cased
in `glb_undo_restore` (a directory clone, not a symlink, needed
handling before the generic backup-swap loop). Verified for real on the
Pop!_OS Cosmic laptop the same day it was built — fresh clone, backup,
idempotent pull, dry-run messages, the env override, and a full
`--undo` round-trip all confirmed working, right before the design
changed.
