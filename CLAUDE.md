# CLAUDE.md — GLB (Greg's Linux Bootstrap)

Guidance for Claude Code (and contributors) working in this repo.

> **Detailed session history is not in this file.** The running
> roadmap, the machine/VM test inventory, and the session-by-session
> work log live in a local, git-ignored **`CLAUDE.local.md`** on the
> maintainer's machines — kept out of the public repo deliberately.
> Design rationale that *is* public lives in [`docs/`](docs/). This file
> is the durable, public orientation only.

## What this project is

GLB is a Bash CLI that makes the terminal the easiest, most approachable
part of using Linux — a curated shell, prompt, and set of CLI tools,
configured in one pass inside whatever terminal a distro already ships,
instead of piecing it together by hand every time a distro gets
reinstalled.

GLB is **terminal-first**: it enhances whatever terminal you already
have, and its focus stays the shell and CLI. GUI apps are in scope only
when they're a deliberate, opinionated pick that complements that
mission — installed and lightly configured, never vendor-managed, never
a general app menu (see [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md),
"Terminal-First, Not Terminal-Only"). The first such pick is **Ghostty**
in `default`, so Yazi's image preview works where a distro's default
terminal can't draw one.

- Repo: <https://github.com/ggregoro/GLB> (public)
- License: MIT
- Language: Bash (no runtime dependency on Python/Node/etc.)

## Why it exists

Two problems, one tool:

1. **Distro-hopping churn** — redoing the same terminal setup by hand on
   every fresh install, from memory, hoping nothing was missed. A
   **profile** (a package list, dotfiles, and any extra install steps)
   captures it once and reapplies it identically anywhere.
2. **The terminal is a barrier for newcomers** — an unstyled prompt with
   no hints, colors, or context is one of the hardest parts of moving to
   Linux from Windows/macOS. GLB's shared shell/prompt setup is built to
   close that gap for *any* profile.

## Architecture

A single `glb` dispatcher script sources focused library modules from
`lib/` (`detect`, `package`, `extras`, `profile`, `export`, `diff`,
`repair`, `prompt`, `plugins`, `completions`), driven by per-profile
directories under `profiles/`:

```
profiles/<name>/
  packages.txt      # package-manager installs, with per-distro name overrides
  extras.txt        # non-package-manager installs (curl script, snap, font, …)
  dotfiles/         # symlinked into $HOME, backing up anything already there
  description.txt   # shown in the interactive picker
```

Full module breakdown: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

**Commands:** `help` · `version` · `info` · `install <pkg>` ·
`remove <pkg>` · `update [profile]` · `restore [profile]`
(`--dry-run` / `--undo` / `--from-snapshot <name>` /
`--from-manifest <path>`) · `profiles` · `prompt` · `export` ·
`diff <a> <b>` · `repair <profile>`.

## Profiles

| Profile | For |
|---|---|
| `default` | The maintainer's own daily-driver setup: shell/prompt, editor, personal dotfiles — also the reference for how a fully-configured GLB machine looks. |
| `developer` | Someone newer to development who wants solid defaults without researching every tool. |
| `server` | Someone newer to server administration: firewall, backups, intrusion protection. |

All profiles share the same bash/zsh/fish shell setup (with per-shell
distinct prompts) and differ in package lists, extras, and
profile-specific dotfiles. (`new-to-linux` was retired — once its
curated-desktop-apps content was dropped as scope creep it duplicated
`default`, and the terminal-onboarding mission was never
profile-specific.)

## Package managers

apt, dnf, pacman, zypper — detected automatically, with per-distro name
overrides (e.g. `fd` → `fd-find` on apt) and a manual-step pause when a
package needs a password GLB can't supply. Every supported manager has
been exercised with real `glb restore` runs on real machines and VMs;
the per-distro verification history is in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Status

The repo is **public**; the current version is in
[`VERSION`](VERSION), and what shipped when is itemized in
[`CHANGELOG.md`](CHANGELOG.md). Direction and progress are tracked in
[`docs/ROADMAP.md`](docs/ROADMAP.md). GLB is essentially feature-complete
— expect occasional small add-ons, not large feature work.

## Testing

`tests/` is a `bats` suite covering package-manager detection,
`packages.txt` parsing, dotfile symlink/backup, per-distro overrides,
and the dispatcher commands. It runs in an isolated `GLB_ROOT`/`HOME`
with `sudo` and the package managers stubbed, so nothing touches the
real system:

```bash
bats tests/
```

If `bats` isn't packaged for your distro, a shallow clone of
`bats-core` and its `bin/bats` works without installing anything.

A known, environment-dependent gap: a few end-to-end/extras tests don't
stub `fresh`/`starship`/`yazi`, so on a machine that has actually run
`glb restore` they can see "already installed" and miss an expected
"installing via curl" assertion. Not a regression — see `CHANGELOG.md`.

For end-to-end verification on a clean machine, follow
[`docs/fresh-vm-verification.md`](docs/fresh-vm-verification.md).

## Conventions

- **Bash only** — no Python/Node/etc. for core functionality.
- Keep the "customize a fresh install fast" goal central — prefer one
  clear path over many configurable options unless a real need shows up.
- Don't hardcode anything specific to one person's setup unless it's
  clearly an example/default that others would edit. `default`'s
  dotfiles are opinionated *by design*; treat that as the baseline and
  extend rather than replace.
- Match the surrounding code's style: focused `lib/*.sh` modules,
  `glb_`-prefixed public functions, `_glb_`-prefixed internal ones.

## Docs map

| File | Contents |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Module-by-module breakdown |
| [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) | Guiding principles, scope boundaries, non-goals |
| [`docs/PROJECT.md`](docs/PROJECT.md) | Project overview, release strategy, long-term vision |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Direction, progress, per-distro verification history |
| [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md) | Style rules |
| [`docs/design/`](docs/design/) | Per-feature design notes |
