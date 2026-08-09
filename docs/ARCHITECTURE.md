# GLB Architecture

## Overview

GLB is a single `glb` dispatcher script that sources a set of focused
library modules from `lib/`, each responsible for one concern. There is no
separate build step or compiled binary — `glb` is meant to be run directly
(or via a symlink into `~/.local/bin/glb`, which `lib/completions.sh`
sets up).

```
GLB/
├── glb                  # dispatcher: parses the command, sources lib/*, dispatches
├── VERSION               # current GLB_VERSION, read by glb and embedded in exports
├── lib/                  # library modules (see below)
├── profiles/              # named profiles: packages.txt, extras.txt, dotfiles/, description.txt
├── completions/           # bash/zsh/fish completion scripts, installed by lib/completions.sh
├── snapshots/              # glb export output (machine-state snapshots), when present
├── tests/                  # bats test suite, one file per lib module + dispatcher.bats
└── docs/                   # this documentation, including docs/design/ for feature design docs
```

## The dispatcher (`glb`)

`glb` resolves its own real path (following the `~/.local/bin/glb` symlink
so `GLB_ROOT` is always the actual repo, not the symlink's directory),
reads `VERSION`, sources every `lib/*.sh` module, then dispatches on
`$1` (`help`, `version`, `info`, `install`, `remove`, `update`, `restore`,
`profiles`, `prompt`, `export`, `diff`, `repair`). Each case is a thin
wrapper calling into the relevant `lib/` function — the dispatcher itself
has no business logic beyond argument parsing (e.g. `restore`'s
`--dry-run`/`--undo`/`--from-snapshot <name>`/`--from-manifest <path>`
flags).

## Library modules (`lib/`)

| Module | Responsibility |
|---|---|
| `banner.sh` | Displays the GLB banner shown at the start of every invocation. |
| `logging.sh` | Consistent `glb_log_info`/`_success`/`_warn`/`_error` output — all user-facing messages go through here, not raw `echo`. |
| `utils.sh` | Small reusable helpers (e.g. directory creation) shared across modules. |
| `detect.sh` | Detects the distro, distro version, package manager (apt/dnf/pacman/zypper), and current shell. |
| `package.sh` | Package management abstraction: install/remove/list, per-distro name resolution (`_GLB_PACKAGE_OVERRIDES`) and its reverse for `glb export`, and the sudo-gated manual-step pause/resume. |
| `extras.sh` | Installs software outside the package-manager model — curl-install scripts, Flatpak apps, and Nerd Font archives — driven by a profile's `extras.txt`. |
| `profile.sh` | Applies a profile: packages, dotfiles (symlink + backup), the interactive picker (`glb restore` with no profile name), `--undo` rollback, and `--from-manifest <path>` for applying a profile-shaped directory from anywhere on disk. |
| `prompt.sh` | Installs and configures the Starship prompt (`glb prompt`), including the update path. |
| `plugins.sh` | Vendors a curated set of zsh plugins (`zsh-autosuggestions`, `zsh-syntax-highlighting`) by git-cloning them directly — framework-free, no Oh My Zsh/Fisher dependency. |
| `completions.sh` | Symlinks `glb` itself onto `PATH` and installs its bash/zsh/fish completion scripts. |
| `export.sh` | Captures the current machine's state (installed packages reverse-mapped to canonical names, tracked dotfiles, shell/prompt setup) into a profile-shaped `snapshots/<hostname>-<date>/` directory; also applies a snapshot the same way a profile is applied. |
| `diff.sh` | Compares two profile-shaped directories — a profile, a snapshot, or either against the other — for package and dotfile drift. |
| `repair.sh` | Checks the current machine against a profile (via an ephemeral export + diff, nothing saved to disk) and offers to re-run `restore` if drift is found. |

Every module begins with a `# Purpose:` header comment and guards against
direct execution (it must be sourced by `glb`, not run standalone).

## Profiles (`profiles/<name>/`)

A profile is a directory containing:

- **`packages.txt`** — one package per line (generic names; per-distro
  overrides are resolved via `lib/package.sh`).
- **`extras.txt`** *(optional)* — `<method> <name> <spec>` lines for
  curl/Flatpak/font installs, parsed by `lib/extras.sh`.
- **`dotfiles/`** — files copied verbatim into the same relative path under
  `$HOME`, applied as symlinks (existing files backed up to `*.glb-backup`
  first).
- **`description.txt`** *(optional)* — one line shown by the interactive
  picker.

`glb restore <profile>` runs, in order: packages → extras → Starship →
zsh plugins → self-symlink + completions → dotfiles. `glb export` and
`glb diff`/`glb repair` all operate on this same shape, so a snapshot
captured by `glb export` can be diffed against or restored from exactly
like a profile.

## Testing (`tests/`)

A [bats](https://github.com/bats-core/bats-core) suite, roughly one file
per `lib/` module plus `dispatcher.bats` for end-to-end command coverage.
Tests run against an isolated `GLB_ROOT`/`HOME` with `sudo` and the
package managers stubbed out, so nothing touches the real system —
real-machine verification (documented per-session in `CLAUDE.md`) happens
separately, by hand, on actual test VMs and daily-driver machines.
