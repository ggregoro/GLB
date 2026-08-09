# Greg's Linux Bootstrap (GLB)

Make the terminal the easiest part of using Linux, not the scariest.
GLB configures a curated shell, prompt, and set of CLI tools inside
whatever terminal your distro already has — in one command, instead of
piecing it together by hand every time a distro gets reinstalled.

## Why GLB?

The terminal is one of the biggest barriers for anyone coming from
Windows or macOS — a blank prompt with no hints, no colors, no context.
GLB closes that gap: a good prompt (branch info, clear directory context),
modern replacements for basic commands (`eza`, `bat`, `zoxide`, `fzf`),
and a shell that's actually pleasant to live in, all applied in one pass
as a reusable **profile** — a package list, dotfiles, and any extra
install steps — to any fresh install of a supported distro.

Reinstalling or distro-hopping is the other half of the problem GLB
solves: redoing the same terminal setup from memory every time, hoping
you remembered everything. A profile captures it once and reapplies it
identically anywhere.

GLB enhances the terminal you already have — it doesn't install or
replace it. See [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) for why.

## Features

- **Package installation** across apt, dnf, pacman, and zypper, with
  per-distro name overrides (e.g. `fd` → `fd-find` on apt) handled
  automatically.
- **Non-package-manager installs** (`extras.txt`) for software that only
  ships as a curl-install script, a Flatpak app, or a font archive.
- **Dotfile management** — symlinks a profile's dotfiles into `$HOME`,
  backing up anything already there first.
- **Sudo-gated install pause/resume** — if a package needs a password GLB
  can't supply (no TTY), it pauses, prints the exact command to run
  yourself, and continues once you confirm.
- **Dry-run previews**, **rollback/undo**, and an **interactive profile
  picker** with descriptions and a preview before applying.
- **State export/import** — `glb export` snapshots a machine's current
  packages and dotfiles; `glb diff` compares two profiles or snapshots for
  drift; `glb restore --from-snapshot` reapplies a captured snapshot.
- **`glb repair`** — checks a machine against a profile and offers to fix
  any drift it finds.
- **`glb update`** — updates system packages, the Starship prompt, vendored
  zsh plugins, and (with a profile name) that profile's `extras.txt`
  entries.
- **Shell completions** for `glb` itself (bash, zsh, fish).

## Installation

Clone the repository and run `glb` directly, or restore a profile to also
put `glb` itself on your `PATH` with completions:

```bash
git clone https://github.com/ggregoro/GLB.git
cd GLB
./glb restore
```

Running `restore` with no profile name shows an interactive picker with a
description of each profile, a preview of what it would do, and a
confirmation prompt before anything changes.

## Usage

```
glb help                              Show all commands
glb info                              Show detected distro/package manager/shell
glb install <package>                 Install a single package
glb remove <package>                  Remove a package
glb update [profile]                  Update packages, Starship, zsh plugins
                                       (and a profile's extras, if given)
glb restore [profile]                 Apply a profile (packages + dotfiles)
glb restore --dry-run                 Preview a restore without changing anything
glb restore --undo                    Undo the last restore's dotfile changes
glb restore --from-snapshot <name>    Apply a snapshot captured by `glb export`
glb profiles                          List available profiles
glb prompt                            Install/configure the Starship prompt
glb export                            Snapshot this machine's packages + dotfiles
glb diff <a> <b>                      Compare two profiles/snapshots for drift
glb repair <profile>                  Check this machine against a profile
```

## Profiles

| Profile | For |
|---|---|
| `default` | Greg's own daily-driver setup: shell/prompt, editor, personal dotfiles. |
| `developer` | Someone newer to development who wants solid defaults without researching every tool. |
| `server` | Someone newer to server administration: firewall, backups, intrusion protection. |

All profiles share the same underlying shell setup (bash/zsh/fish with
per-shell distinct prompts) and differ in their package lists, extras, and
profile-specific dotfiles.

## Supported Distributions

GLB detects and supports four package managers, each verified end-to-end
with a real restore on real hardware or VMs:

- **apt** — Debian, Ubuntu and derivatives (Pop!_OS, Linux Mint, Zorin OS)
- **dnf** — Fedora
- **pacman** — Arch and Arch-based distros (CachyOS, EndeavourOS)
- **zypper** — openSUSE

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the full per-distro
verification history.

## Architecture

GLB is a Bash CLI — a single `glb` dispatcher script sourcing focused
library modules from `lib/`, driven by per-profile `packages.txt`/
`extras.txt`/`dotfiles/` under `profiles/`. See
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full module
breakdown.

## Roadmap

GLB's direction and current progress are tracked in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Contributing

GLB is currently a personal project (private repository) built and tested
by its author across several real machines and VMs, documented in detail in
`CLAUDE.md`. It's built with the idea that it might be shared publicly if
there's interest — see [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) for the
guiding principles behind its design decisions.

## License

MIT — see [`LICENSE`](LICENSE).
