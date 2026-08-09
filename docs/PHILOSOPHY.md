# GLB Philosophy

## Purpose

Greg's Linux Bootstrap (GLB) exists to make the terminal the easiest,
most approachable part of using Linux — not the intimidating black
window it is for most people arriving from Windows or macOS, where "the
terminal" is one of the biggest barriers to switching at all.

GLB is built on the belief that a good shell, a good prompt, and a
handful of well-chosen CLI tools can turn that intimidating window into
something people actually want to use — and that getting there should
take one command, not hours of manually piecing together dotfiles.

The project focuses on delivering an exceptional terminal experience
while embracing the strength of the open-source ecosystem.

---

# Our Philosophy

## User Experience First

Every design decision should improve the overall user experience.

Users should be guided through the installation process with clear choices and sensible defaults rather than being overwhelmed by technical details.

The goal is to make Linux approachable without sacrificing flexibility.

---

## Curate, Don't Reinvent

GLB exists to integrate the best open-source projects—not replace them.

Whenever practical, GLB should leverage mature and well-maintained software rather than creating duplicate functionality.

Examples include:

- Starship
- eza
- bat
- zoxide
- ranger
- tmux
- Neovim
- fzf
- ripgrep
- fastfetch
- Fresh
- Git

GLB provides the framework that brings these projects together into a cohesive workstation.

Where a whole framework doesn't fit — e.g. zsh's autosuggestions and syntax-highlighting — GLB
vendors the individual plugins directly (git-cloned into `~/.local/share/glb/plugins`) rather than
adopting a plugin manager like Oh My Zsh or Fisher. Same principle at a smaller grain: bring in the
project that does the job well, without inheriting a framework's extra weight.

---

## Enhance the Terminal You Have, Don't Replace It

**GLB does not install GUI applications, full stop — not a terminal
emulator, not a browser, not an office suite, not anything with its own
window.** Everything GLB installs and configures must run *inside*
whatever terminal a distro already ships (GNOME Terminal, Konsole, Cosmic
Terminal, etc.): shells, prompts, terminal-based editors, CLI tools, zsh
plugins. If it needs its own window, it's out of scope.

This was learned the hard way, twice, in the same session (2026-08-09):

- **Terminal emulators.** GLB briefly installed and managed WezTerm as
  part of the `default` profile (2026-08-05 through 2026-08-09), before
  being reversed. The install/config path ended up consuming significant
  real time chasing Flatpak-sandbox and desktop-compositor interactions
  (COSMIC-specific window-decoration and config-resolution behavior)
  that had nothing to do with GLB's actual job — shell and prompt
  configuration. A terminal emulator is a bigger, more opinionated
  commitment than a CLI tool or a dotfile; picking one for someone is a
  step beyond "curate a workstation" into "replace a tool the user
  already has an opinion about."
- **Desktop applications.** `new-to-linux` originally curated a browser,
  office suite, image editor, and media player (Firefox, LibreOffice,
  GIMP, VLC) for people switching from Windows/macOS. Reversed the same
  day for the same underlying reason: these are easy for anyone to
  install themselves via their distro's own software center once
  they've found their way around a real terminal, and GLB picking them
  is scope creep beyond what a shell-bootstrapping tool should own.
  Without the desktop-app picks, `new-to-linux` had shrunk to a near-
  duplicate of `default`'s shared shell setup — retired as a separate
  profile entirely (2026-08-09), rather than keep two profiles this
  similar. The terminal-onboarding mission it served isn't a
  profile-specific job; it's what GLB's shared shell/prompt setup is
  built to do regardless of which profile someone picks.

Someone who wants WezTerm, Ghostty, Firefox, LibreOffice, or anything
else with a window is free to install and configure it themselves — GLB
just needs whatever they land on to keep working, which "enhance
whatever terminal is already there" already guarantees, since none of
GLB's own configuration assumes a specific terminal emulator.

**The line is GUI vs. terminal, not "simple" vs. "complex."** A
full-screen TUI application that takes over the whole terminal window —
Ranger, Midnight Commander, htop, btop, even something as involved as
the Claude Code CLI — is still fully in scope, because it never opens a
window of its own; it runs entirely inside whatever terminal is already
there, same as `bat` or `fzf`. Ranger and htop are already curated in
`default` for exactly this reason. The disqualifying question is never
"how much does this app do," it's "does launching it ever produce a
window separate from the terminal it was launched in." A yes to that
question is what put WezTerm and the `new-to-linux` desktop apps out of
scope — it isn't a complexity or feature-set judgment.

---

## Opinionated but Customizable

GLB provides carefully selected defaults based on extensive real-world experience.

The `default` profile represents the environment used to develop and maintain GLB — Greg's own,
real setup, not a placeholder.

Users who prefer different tools or workflows should always have the ability to customize their installation.

Good defaults should never limit personal choice.

---

## Profiles Instead of Package Lists

Users should choose experiences rather than individual packages.

Examples include:

- `default` (Greg's own, real setup) ✅
- Developer ✅
- Server ✅

Profiles define complete workstation environments that are reproducible and easy to maintain.

---

## Modular by Design

Every feature should exist as an independent module.

Modules should be:

- Reusable
- Testable
- Maintainable
- Independent

This modular architecture allows GLB to grow without becoming difficult to maintain.

---

## Open Source First

GLB embraces open-source software and the communities that build it.

Whenever possible, GLB contributes by promoting existing projects instead of replacing them.

The project succeeds when the entire Linux ecosystem succeeds.

---

## Consistency Across Distributions

Linux distributions differ, but the user experience should remain familiar.

GLB strives to provide a consistent workstation experience across supported Linux distributions while respecting each distribution's package manager and conventions.

---

## Simplicity Over Complexity

Complexity should exist inside GLB—not in front of the user.

The installer should present clear choices and hide unnecessary implementation details.

Simple experiences are often the result of thoughtful engineering.

---

## Learn by Building

GLB is both a practical tool and an educational project.

Every module should demonstrate good software engineering practices including:

- Clean code
- Consistent documentation
- Modular architecture
- Reproducible behavior
- Maintainable design

The project should serve as an example of professional Bash development.

---

# Long-Term Vision

GLB aims to become a complete Linux workstation builder capable of transforming a fresh installation into a polished development environment through either:

- Express Installation using the `default` profile
- A guided customization wizard

Both paths should deliver reliable, reproducible, and maintainable systems.

---

# Guiding Principle

Whenever a design decision is uncertain, ask one question:

**Does this improve the user's experience while respecting the open-source ecosystem?**

If the answer is yes, it is likely consistent with the philosophy of GLB.

---

> **Our Mission:** Build the Linux workstation we would want to install ourselves, and make it available to everyone.
