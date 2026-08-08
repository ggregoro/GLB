# GLB Project

## Project Vision

Turn a fresh Linux install into a polished, productive workstation with a
single command — instead of manually reinstalling the same packages,
rewriting the same dotfiles, and reconfiguring the same shell prompt every
time a distro gets reinstalled or a new machine gets set up.

## Mission

Build the Linux workstation setup we'd want to install ourselves, and make
it reproducible enough to run again on any supported distro with confidence
that it will produce the same result.

## Core Principles

- **User experience first.** Clear defaults and guided choices beat a wall
  of configuration options.
- **Curate, don't reinvent.** GLB integrates mature open-source projects
  (Starship, eza, bat, zoxide, ranger, Neovim, fzf, WezTerm, Fresh, ...)
  rather than duplicating their functionality.
- **Profiles over package lists.** Users choose a complete workstation
  experience (`default`, `new-to-linux`, `developer`, `server`), not an
  à la carte list of packages.
- **Modular by design.** Each concern — package installation, dotfile
  management, prompt setup, plugin vendoring, state export/diff/repair —
  lives in its own focused `lib/` module.
- **Consistent across distributions.** The same profile produces the same
  result on apt, dnf, pacman, and zypper, with per-distro package-name
  differences handled internally rather than exposed to the user.
- **Opinionated but customizable.** GLB ships carefully chosen defaults
  (the `default` profile is a real, working daily-driver setup, not a
  placeholder) while leaving room to fork or edit a profile for anyone who
  wants something different.

See [`PHILOSOPHY.md`](PHILOSOPHY.md) for the full guiding philosophy behind
these principles.

## Target Audience

- **Greg**, first and foremost — GLB exists because distro-hopping and
  reinstalling meant manually reconfiguring the same setup over and over.
- **People newer to Linux, development, or server administration** who want
  a solid, curated starting point without researching every tool choice
  themselves (`new-to-linux`, `developer`, `server` profiles).
- Potentially a **wider public audience** later, if there's interest —
  GLB is built with reasonably clean, documented code in mind for that
  possibility, not just "works on my machine."

## Supported Platforms

GLB targets any Linux distribution using one of four package managers:
apt, dnf, pacman, or zypper. See [`ROADMAP.md`](ROADMAP.md)'s Version 0.7
section for the specific distributions verified end-to-end (Debian,
Ubuntu-family, Pop!_OS, Fedora, Arch-family) and their test history.

## Project Goals

- A single command (`glb restore <profile>`) that reliably reproduces a
  complete workstation setup — packages, non-package-manager extras, shell
  prompt, and dotfiles — on any supported distro.
- Idempotent, safe-to-rerun behavior: restoring the same profile twice
  should always converge to a clean state, never duplicate work or clobber
  user changes without a backup.
- A path from "something's wrong" back to a known-good state: dry-run
  previews, rollback/undo, drift detection (`glb diff`), and one-shot
  repair (`glb repair`).
- Enough real-world verification (not just automated tests) that "GLB says
  it worked" is trustworthy — every feature in this project has been run
  for real on at least one physical machine or VM before being considered
  done.

## Non-Goals

- **Not a general-purpose configuration management system.** GLB
  deliberately avoids templating, encrypted secrets, and a plugin
  ecosystem — the kind of scope chezmoi or dotbot cover. If a need grows
  beyond "curate a workstation setup," it's likely out of scope.
- **Not a dependency on other languages.** Core functionality stays
  Bash-only; no Python/Node/etc. runtime requirement for `glb` itself.
- **Not a fork or replacement of the tools it curates.** GLB brings
  together existing, mature open-source projects rather than
  reimplementing what they already do well.

## Release Strategy

GLB has not yet cut a version beyond the initial `0.1.0` foundation.
Development happens directly against `main`, with features tracked as
"Planned" vs. "Completed" per roadmap version in
[`ROADMAP.md`](ROADMAP.md) and itemized as they ship in the root
[`CHANGELOG.md`](../CHANGELOG.md)'s `[Unreleased]` section. A version bump
is expected once a roadmap milestone's items are all complete and the
project is ready to tag a real release.

## Long-Term Vision

GLB aims to become a complete Linux workstation builder: a curated,
opinionated, cross-distribution tool that gets someone from a fresh install
to a polished, personalized environment through either an express install
(`glb restore <profile>` directly) or a guided, discovery-oriented wizard
(`glb restore` with no arguments). See [`ROADMAP.md`](ROADMAP.md)'s
"Long-Term Vision" section for the fuller statement of direction.
