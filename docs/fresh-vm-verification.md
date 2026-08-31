# Fresh-VM Verification Checklist

Install GLB on a genuinely clean virtual machine, exactly as a new user
would (`install.sh` one-liner, not a dev checkout), and confirm a
`glb restore default` works end to end.

Written against **Pop!_OS 24.04 Cosmic / apt**; the per-distro notes call
out where pacman / dnf / zypper differ. The detailed run history and
results live in `CLAUDE.md` → Working notes (search "Fresh Pop!_OS
Cosmic VM verification") — this file is the repeatable procedure.

---

## Part 0 — VM prep (in order)

1. Create the VM, install the distro, first boot.

2. Update everything, then reboot:

   ```sh
   sudo apt update && sudo apt full-upgrade -y   # dnf/zypper/pacman equivalent
   sudo reboot
   ```

   A fresh image pulls a new kernel + mesa + snapd; you want those
   current before testing Ghostty and the snaps.

3. **Give the VM a working GPU path.** This is a VM-only concern —
   Ghostty runs fine on real hardware.

   1. Turn **on** "Enable 3D Acceleration" in the VM's Display settings.
   2. Install the guest tools so the guest actually gets a 3D context —
      toggling step 1 alone is **not** enough:

      ```sh
      sudo apt install -y virtualbox-guest-utils virtualbox-guest-x11
      ```

      (or mount the Guest Additions ISO). Then reboot the VM.

   **Symptom if this is missed** — Ghostty prints on startup:

   ```
   MESA-LOADER: failed to retrieve device information
   ZINK: vkCreateInstance failed
   egl: failed to create dri2 screen
   ```

   then falls back to `llvmpipe` software rendering. It still works,
   just slow and noisy. **This is a VirtualBox limitation, not a GLB
   bug**, and it does not affect Yazi image preview (the Kitty graphics
   protocol is CPU-side). Quiet workaround without fixing the VM:

   ```sh
   LIBGL_ALWAYS_SOFTWARE=1 ghostty
   # persist it:
   mkdir -p ~/.config/environment.d
   echo 'LIBGL_ALWAYS_SOFTWARE=1' > ~/.config/environment.d/ghostty-sw.conf
   # (log out / in to take effect)
   ```

4. Confirm a real Wayland session (`wl-clipboard` needs one):

   ```sh
   echo $XDG_SESSION_TYPE   # expect: wayland
   ```

---

## Part 1 — Install GLB (the end-user way)

```sh
curl -fsSL https://raw.githubusercontent.com/ggregoro/GLB/main/install.sh | bash
```

Clones GLB to `~/.local/share/glb`. Add `~/.local/bin` to `PATH` if the
installer says to, open a new shell, then:

```sh
glb version
```

---

## Part 2 — First restore

```sh
glb restore default
```

Watch, in order:

- **Packages install from nothing** (not "Already installed").
- **`fastfetch`** hits the apt-index gap → manual-step pause. Expected;
  skip it (`s`). *(Not in apt's index on Pop!_OS/Mint — a known gap
  pending a `github-release` extras method.)*
- **`snapd` apt-installed, then three `snap install`s** — `yazi`,
  `ghostty --classic`, `atuin`. On a fresh machine snapd may need to
  seed: if a `snap install` fails with "too early for operation, device
  not yet seeded", wait ~30s and re-run `glb restore default`. The
  `/snap` classic-confinement symlink is auto-created on Ubuntu/Pop
  (manual on Fedora).
- **Dotfiles linked with no `.glb-backup`** on a clean VM:
  `~/.config/ghostty/config`, `~/.config/yazi/theme.toml`,
  `~/.local/share/applications/yazi.desktop`, and 8 `~/.config/nvim/*`
  files.
- Ends: `[SUCCESS] Profile applied: default`

---

## Part 3 — Verify each piece

**A. Terminal font (do first — affects what you can see).** GLB installs
JetBrainsMono Nerd Font system-wide but sets no terminal's font. Set
COSMIC Terminal's font (menu → Settings → Font) to *JetBrainsMono Nerd
Font* or `eza --icons` and the Starship prompt render as boxes.
Ghostty's config already sets it. (See README → "Terminal Font".)

**B. Neovim / LazyVim.** `nvim` → first launch bootstraps lazy.nvim +
the pinned plugins; `:Lazy` clean, no errors; `:q`; relaunch → straight
into a working LazyVim. No SSH key needed (vendored public
LazyVim/starter, just symlinked dotfiles).
*Known bug on apt: `neovim` 0.9.5 is too old for current LazyVim
(needs ≥ 0.11.2) — see the CLAUDE.md Roadmap entry.*

**C. Ghostty.** Launches (Part 0 step 3 matters here). A "Yazi" entry
appears in the COSMIC app launcher (`gtk-launch yazi.desktop` also
works). Window: near-black `#0d0e12`, slight transparency, blur
(cosmic-comp's call). `ghostty +show-config` loads clean, no error
dialog. Bind **Super+E** by hand (COSMIC Settings → Keyboard Shortcuts
→ Custom → `ghostty --class=com.yazi.Yazi -e yazi`) — a documented
manual step, GLB never automates it.

**D. Yazi image preview.** In Ghostty: `yazi`, highlight an image → a
real image renders in the preview pane (no chafa ASCII, no "chafa
failed").

**E. Yazi git-status signs.** In Yazi, navigate **into** a git repo
(e.g. `~/.local/share/glb`): tracked/clean files show a green `✓` at
the right edge of the active column; changes show `M`/`A`/`?`/`D`/`U`.
Non-repo directories show nothing (correct).

**F. atuin.** New shell → **Ctrl-R** opens atuin's full-screen search;
plain **Up** stays per-session history. `which atuin` → `/snap/bin/atuin`
on apt. Optional: `atuin import auto`.
*Known bug on apt (fixed on branch `claude/atuin-snap-config-dir`,
unmerged): the strict snap can't create `~/.config/atuin` on a clean
machine — every shell errors until the dotfiles redirect
`ATUIN_*_DIR` under `~/snap/atuin/`.*

**G. git-delta.** In a repo: `git diff` / `git log -p` render through
delta (syntax-highlighted, line numbers).

**H. wl-clipboard.** `echo hello | wl-copy && wl-paste` → `hello`. In
Yazi, `y` on a file (yank path) then `wl-paste`.

---

## Part 4 — developer / server

```sh
glb restore developer --dry-run
glb restore server --dry-run
```

Confirm both resolve clean and `server` lists `neovim`. A real restore
of one is a bonus.

---

## Part 5 — Idempotency + tests

- Second `glb restore default` → all "Already installed" / "Already
  linked", no pauses, exit 0.
- bats (`sudo apt install -y bats`, or a scratchpad `bats-core` clone):

  ```sh
  cd ~/.local/share/glb && bats tests/
  ```

  On a real fresh VM this has come back **227/227** — the
  `fresh`/`starship`/`yazi`-on-real-`PATH` isolation failures
  (tests 38/39/88/116) that show up in sandboxed/dev runs did not
  recur. Treat a 4-test shortfall matching exactly those as the known
  isolation gap, not a regression.

---

## Part 6 — When done

Close out the "not yet real-restored" notes on the relevant `CLAUDE.md`
Roadmap entries, and update the `claude-memory` repo's `project_glb.md`.
