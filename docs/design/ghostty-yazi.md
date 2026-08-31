# Design: Ghostty as a Yazi image-preview dependency

**Status:** Implemented (2026-08-30)
**Added:** 2026-08-30

## Motivation

`default` installs `yazi` (via `extras.txt`, since 2026-08-13) for its
stronger plugin support — image previews chief among them. But Yazi can
only *show* an image if the terminal it's running in can draw one.
Yazi's own detection order is: a native inline-image protocol (Kitty
graphics / iTerm2 / Sixel) if the terminal has one, then überzug++, then
`chafa` Unicode-block art as the last resort.

On Greg's daily driver — Pop!_OS with **COSMIC Terminal** — every one of
those paths is blocked:

- cosmic-term supports **no inline image protocol at all**
  ([pop-os/cosmic-term#438](https://github.com/pop-os/cosmic-term/issues/438),
  open, no work started).
- The `chafa` fallback is broken by a version gap: Yazi 26.x calls
  `chafa --probe`, an option added in **chafa 1.16.0**, but Pop!_OS
  24.04 (and the chafa bundled in Yazi's own snap) ship **1.14.0**,
  which exits non-zero on the unknown flag. Result in the preview pane:
  `chafa failed with status: exit status: 2`.

So on cosmic-term there is *no* working image preview without a terminal
that renders the images itself. **Ghostty** — GPU-accelerated, speaks
the Kitty graphics protocol, and packaged on every distro family GLB
targets — is that terminal. This closes a real gap in a feature
`default` already ships, on the exact machine GLB is developed on.

## The real fork: does a terminal emulator belong in GLB at all?

By the rule GLB had at the time, no — WezTerm and `new-to-linux`'s
desktop apps were both added and reversed on 2026-08-09, and
`docs/PHILOSOPHY.md` named Ghostty *by name* as an example of what GLB
would not install.

**Decided (2026-08-30):** the rule itself was the problem. Greg's call,
stated directly — first "adding Ghostty, GUI or not, makes the whole
project a little more powerful and useful," then "as we move forward the
no GUI rule is going to limit the capabilities of the GLB and GWB
projects... we should remove that rule." The no-GUI prohibition was
dropped in both projects; `docs/PHILOSOPHY.md`'s section is now
"Terminal-First, Not Terminal-Only" and the boundary that replaced the
rule is **curated and opinionated, install-not-vendor-manage**: a GUI
app is in scope when it's a deliberate pick that complements the
terminal-first mission, installed and lightly configured like any other
tool, with GLB never trying to be a general software center or to own a
GUI app's full config.

Ghostty is the first pick under that stance, and it's a clean fit:

- **It complements the mission concretely.** Yazi (already in `default`)
  can only preview images if its terminal can draw them; some distros'
  defaults can't. Ghostty is the smallest thing that makes an existing
  `default` feature actually work.
- **"Install, don't vendor-manage" is applied, not waived.** GLB
  installs the package and ships one launcher line. It does not set
  Ghostty as the default terminal, rebind the terminal shortcut, or
  ship a Ghostty config — the vendored `wezterm.lua` plus
  window-decoration and Flatpak-sandbox rabbit holes were what made
  WezTerm a time sink, and none of that is here.

## Scope

**In scope:**

- **`snap ghostty classic`** in `profiles/default/extras.txt`, mirroring
  the existing `snap yazi classic` entry.
- **Per-distro native routing** via the existing
  `_GLB_SNAP_NATIVE_OVERRIDES` table (`lib/extras.sh`) — the same
  mechanism `yazi:pacman` already uses:
  - `ghostty:pacman` → `ghostty` (Arch `extra` repo) — confirmed.
  - `ghostty:zypper` → `ghostty` (openSUSE `repo-oss`) — confirmed.
    Note this is *better* than `yazi`, which has no zypper path at all:
    openSUSE installs Ghostty natively even though snapd is unavailable
    there.
  - **apt** (Debian/Ubuntu/Pop!_OS/Mint): no package in any of their
    indexes → falls through to `snap`, with the same snapd caveats
    `yazi` carries (notably Mint's `nosnap.pref` policy block, see
    `profiles/default/packages.txt`).
  - **dnf** (Fedora): Ghostty is packaged only via COPR
    (`scottames/ghostty`), not Fedora's official repos. GLB doesn't
    route through non-default repos (same call as `lazygit` on dnf) →
    falls through to `snap`.
- **A portable launcher**,
  `profiles/default/dotfiles/.local/share/applications/yazi.desktop`,
  shipped as an ordinary tracked dotfile. `Exec=ghostty
  --class=com.yazi.Yazi -e yazi` — bare command names, so it resolves
  whether Ghostty and Yazi are snaps (`/snap/bin`) or native packages
  (`/usr/bin`). `.desktop` files are a freedesktop standard, so this
  one entry works on COSMIC, KDE, GNOME, and Xfce alike. It's the first
  `.local/share/` dotfile GLB ships; `glb_apply_profile_dotfiles`'s
  existing per-file `find` walk picks it up with no code change.

**Explicitly out of scope:**

- **Setting Ghostty as the default terminal**, or rebinding the
  terminal keyboard shortcut. GLB's shell/prompt setup stays
  terminal-agnostic; cosmic-term (or whatever the user has) remains
  their default.
- **A Ghostty config dotfile.** Deliberately none — this is exactly the
  WezTerm mistake. Ghostty's own defaults are fine for running Yazi.
- **Automating the keyboard shortcut.** Binding a key to `ghostty
  --class=com.yazi.Yazi -e yazi` is a one-time, per-machine step, and
  COSMIC (a RON file), KDE (`kglobalshortcutsrc`), and GNOME
  (`gsettings` custom-keybinding array) each do it differently, none
  portably. GLB documents the command; the user binds it in their DE.
  Same "document the known gap rather than chase non-default paths"
  posture GLB already takes for `lazygit`/dnf and `snapd`/zypper.
- **`developer`/`server` profiles.** `developer` is container/headless
  focused and has no `snap` extras method at all; `server` is headless.
  Ghostty is a `default`-only concern, like the WezTerm config used to
  be.

## How it's built

Nothing new — this rides entirely on mechanisms that already existed:

1. `profiles/default/extras.txt` gains `snap ghostty classic`.
   `glb_apply_profile_extras` → `glb_install_extra` already handles the
   `snap` method, including the `_GLB_SNAP_NATIVE_OVERRIDES` lookup that
   redirects to `glb_install_package` when a native package is known
   for the current package manager.
2. `lib/extras.sh`'s `_GLB_SNAP_NATIVE_OVERRIDES` gains
   `[ghostty:pacman]` and `[ghostty:zypper]`.
3. `profiles/default/dotfiles/.local/share/applications/yazi.desktop` is
   a plain tracked file; the existing dotfile symlink/backup walk
   installs it like any other.

No new function, no new command, no new test file. The change is
verified by the existing bats suite (223/227 — the 4 failures are the
pre-existing `fresh`/`starship`-on-PATH test-isolation gap, tests
38/39/88/116, confirmed unchanged via `git stash`) plus a `glb restore
default --dry-run` on the Pop!_OS Cosmic laptop that picks up both the
`ghostty` extra and the `yazi.desktop` dotfile correctly.

**Not yet verified:** a real (non-dry-run) `glb restore default` that
installs Ghostty from scratch on a machine that doesn't already have it,
on any of the four package managers — same "needs a real fresh-machine
run" caveat as most recent `default` additions.
