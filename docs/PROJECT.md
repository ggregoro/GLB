# GLB Project

## Project Vision

Make the terminal the easiest, most approachable part of using Linux —
not the intimidating black window it is for most people arriving from
Windows or macOS. GLB gets there by configuring a curated shell, prompt,
and set of CLI tools with a single command, instead of manually
reinstalling the same packages, rewriting the same dotfiles, and
reconfiguring the same shell prompt every time a distro gets reinstalled
or a new machine gets set up.

## Mission

Build the terminal experience we'd want for anyone — someone who's never
opened a shell before, and someone who's done it a thousand times — and
make it reproducible enough to run again on any supported distro with
confidence that it will produce the same result.

## Core Principles

- **User experience first.** Clear defaults and guided choices beat a wall
  of configuration options.
- **Curate, don't reinvent.** GLB integrates mature open-source projects
  (Starship, eza, bat, zoxide, ranger, Neovim, fzf, Fresh, ...) rather
  than duplicating their functionality.
- **Profiles over package lists.** Users choose a complete workstation
  experience (`default`, `developer`, `server`), not an à la carte list
  of packages.
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
- **People newer to development or server administration** who want a
  solid, curated starting point without researching every tool choice
  themselves (`developer`, `server` profiles).
- **Anyone for whom the terminal itself is the barrier** — someone
  switching from Windows/macOS whose biggest hurdle isn't picking
  software, it's that the command line is unfamiliar territory. This
  isn't a separate profile's job; it's what the shared shell/prompt
  setup every profile ships is built to solve, since that's GLB's core
  purpose (see `PHILOSOPHY.md`).
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
- **Not a GUI application installer.** GLB installs and configures
  things that run inside whatever terminal a distro already ships —
  shells, prompts, terminal-based editors, CLI tools. It does not
  install terminal emulators, browsers, office suites, or any other
  application with its own window. See `PHILOSOPHY.md` ("Enhance the
  Terminal You Have, Don't Replace It") for why — this was tried twice
  (a managed WezTerm install, `new-to-linux`'s curated desktop apps)
  and reversed both times as scope creep.

## Release Strategy

Development happens directly against `main`, with features tracked as
"Planned" vs. "Completed" per roadmap version in
[`ROADMAP.md`](ROADMAP.md) and itemized as they ship in the root
[`CHANGELOG.md`](../CHANGELOG.md).

**GLB is now on Version `1.0.0` (2026-08-18)** — the bar set below for
"going public" was met (genuine end-to-end restores on fresh VMs and
real hardware across every supported package manager, not just the
automated test suite; see `CLAUDE.md`'s Roadmap/Test Environments
sections for the full history) and the repository is now public. See
`CLAUDE.md`'s "Repository is now public" Working notes entry for the
decision record.

**Prior policy, kept for history**: the repository stayed private until
GLB was fully tested and vetted (decided 2026-08-09, no fixed date
attached — an open timetable, not a deferred-indefinitely non-decision).
The bar for "going public" was real-world confidence, not a version
number, and going public was a separate decision GLB's author would make
explicitly when that bar was met — not something that happened
automatically once testing wrapped up. That decision has now been made,
per the note above.

## Long-Term Vision

GLB aims to become a complete Linux workstation builder: a curated,
opinionated, cross-distribution tool that gets someone from a fresh install
to a polished, personalized environment through either an express install
(`glb restore <profile>` directly) or a guided, discovery-oriented wizard
(`glb restore` with no arguments). See [`ROADMAP.md`](ROADMAP.md)'s
"Long-Term Vision" section for the fuller statement of direction.
