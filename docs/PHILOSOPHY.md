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

## Terminal-First, Not Terminal-Only

GLB's mission is the terminal: making the shell, prompt, and CLI tooling
of a fresh install approachable in one pass. The default move is always
to **enhance whatever terminal you already have** rather than replace it
— none of GLB's shell/prompt configuration assumes a particular terminal
emulator, so it keeps working wherever it lands.

**GUI applications are in scope when they're a deliberate, opinionated
pick that complements that mission** — installed and lightly configured
the same way as any CLI tool. What stays out of scope is GLB behaving
like a general software center (a menu of browsers, office suites, media
players that anyone can install themselves), and sinking real effort
into deep GUI-app configuration management. Install it, set the handful
of options that make it useful for GLB's purpose, and stop there.

This boundary was drawn from experience (2026-08-09), and the history is
worth keeping even though the rule it produced has since been relaxed:

- **WezTerm** was briefly installed and *managed* as part of `default`
  (2026-08-05 through 2026-08-09), then removed. The problem wasn't
  "GLB installed a terminal emulator" — it was that GLB tried to *own*
  WezTerm's configuration: a vendored `wezterm.lua`, and real time lost
  chasing Flatpak-sandbox and COSMIC window-decoration interactions
  that had nothing to do with shell and prompt setup. That's the line
  the "install, don't vendor-manage" rule above draws.
- **`new-to-linux`'s desktop apps** (Firefox, LibreOffice, GIMP, VLC)
  were removed the same day because they were *padding*, not a
  deliberate pick that complemented the terminal-onboarding mission —
  and trivially self-installed from any software center. The question
  they failed is still the right one to ask of any GUI candidate: does
  this specifically complement what GLB is *for*, or is it just "apps a
  new user might want"? Without those picks, `new-to-linux` had shrunk
  to a near-duplicate of `default`'s shared shell setup and was retired
  as a separate profile.

Terminal-based tools were never in question and remain the core: a
full-screen TUI — Ranger, Midnight Commander, htop, btop, the Claude
Code CLI — is in scope no matter how involved it is, because it runs
inside whatever terminal is already there. Ranger and htop are curated
in `default` for exactly that reason.

### Ghostty — the first GUI pick under this stance

`default` installs **Ghostty**, a GPU-accelerated terminal emulator
(2026-08-30). It's a curated pick that complements the mission rather
than a replacement for anyone's terminal: Yazi's image preview needs a
graphics-capable host, and some distros' default terminals provide none.
COSMIC Terminal — Greg's daily driver — supports no inline image
protocol at all
([pop-os/cosmic-term#438](https://github.com/pop-os/cosmic-term/issues/438)),
and its packaged `chafa` is too old for Yazi's ASCII-art fallback, so on
cosmic-term there is *no* working image preview without a terminal that
draws the images itself. Ghostty (Kitty graphics protocol) is that
terminal.

GLB is **opinionated** about Ghostty — it ships a package, a launcher,
and a small config — while still staying on the right side of "install,
don't vendor-manage":

- The config (`dotfiles/.config/ghostty/config`) is deliberately small
  and about *appearance*, not behavior: a dark background, slight
  transparency and blur, the Tokyo Night palette GLB's Starship prompt
  already uses, and JetBrainsMono Nerd Font. It's the same kind of
  curated default as `starship.toml` — a look, not a maze of
  keybindings and window-manager workarounds. That's the WezTerm line:
  WezTerm became a time sink because GLB was chasing its config across
  Flatpak-sandbox and compositor bugs, not because a config file
  existed.
- GLB does **not** set Ghostty as the default terminal or rebind the
  terminal shortcut. It's installed and launched on demand, via an
  app-menu entry (`ghostty --class=com.yazi.Yazi -e yazi`) that runs
  Yazi inside it.
- Binding a key to that launcher is left to the user — COSMIC, KDE, and
  GNOME each do custom keyboard shortcuts differently and none
  portably, so GLB documents the one-liner rather than automating three
  fragile per-desktop code paths.

See `docs/design/ghostty-yazi.md` for the full rationale and the
per-distro packaging details.

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
