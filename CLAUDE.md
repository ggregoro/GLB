# CLAUDE.md — GLB (Greg's Linux Bootstrap)

## What this project is

GLB is a Bash CLI tool that makes the terminal the easiest, most
approachable part of using Linux — a curated shell, prompt, and set of
CLI tools, configured in one pass inside whatever terminal a distro
already ships, instead of piecing it together by hand every time a
distro gets reinstalled. **GLB does not install GUI applications of any
kind, terminal emulators included** (see the "Removed entirely
(2026-08-09)" Roadmap entry below for why) — the focus is entirely the
terminal itself.

- Repo: https://github.com/ggregoro/GLB (private)
- License: MIT
- Language: Bash

## Why it exists

Greg distro-hops a lot and got tired of manually reconfiguring each fresh
install by hand. GLB automates that setup. Separately, the terminal is one
of the biggest barriers for anyone switching from Windows/macOS — an
unfamiliar, unstyled prompt with none of the conveniences a good shell
setup provides — which is why GLB's whole focus narrowed to the terminal
itself (2026-08-09, per Greg: "One of the biggest issues that people
[moving] over from Windows is terminal. The project should make it
easier for new users to work their way around the terminal."). This used
to be framed as one profile's job (`new-to-linux`); once that profile's
distinguishing content (curated desktop apps) was removed as scope creep
the same day, it became clear the terminal-onboarding mission was never
really profile-specific — it's what GLB's shared shell/prompt setup is
built to do for *any* profile, so `new-to-linux` was retired rather than
kept as a near-duplicate of `default` (see the Roadmap section's
"Retired entirely" entry). It's built with the idea that it might
eventually be shared publicly if there's interest — so keep code
reasonably clean and documented, not just "works on my machine."

## Test environments

- **Plan going forward (decided 2026-08-09):** the repo stays private
  until GLB is genuinely tested and vetted on real machines — see
  `docs/PROJECT.md`'s Release Strategy. Greg's plan is fresh VMs,
  connected to the GLB GitHub repo from the start (not retrofitted
  onto old ones), rather than continuing to reuse/patch up the older
  test VMs listed below — those are being retired once the project
  reaches a stable point. Every entry below this point is history from
  before that decision; new real-hardware verification should happen
  on new VMs set up specifically for this, not by resurrecting these.
- Dell E7450 laptop running Pop!_OS
- Windows 10 PC running VirtualBox, used to test other distros
- Debian 13 machine, linked to GitHub, `glb restore default` run for real
  here on 2026-08-06 (see Roadmap section) — a second real daily-driver
  machine alongside the Dell laptop, not just a test VM
- **New (2026-08-06): a dedicated Pop!_OS test VM** — a fresh VM Greg set
  up with its own SSH key, cloned separately from the Dell laptop/Debian
  machine. Distinct from the Dell E7450 above despite same distro; this
  one exists purely for testing, not as a daily driver. First session
  here ran `glb restore default` for real (first time on this machine)
  and found/fixed a genuine bug in the process — see the manual-step
  pause entry in Roadmap below.
- **New (2026-08-07): a Linux Mint 22.3 (Cinnamon) test machine** —
  another dedicated test box, distinct from every prior environment
  (first genuinely fresh Mint machine tested; apt itself was already
  validated via Pop!_OS/Zorin/Debian, but this is the first time GLB
  hit a machine with the Nerd Font *not* already pre-installed by hand
  — see Roadmap for the real gap that surfaced). Default terminal here
  is gnome-terminal (Cinnamon's stock terminal, GNOME Terminal 3.52.0 /
  VTE 0.76.0); WezTerm also installed via Flatpak during this session's
  restore.
- **The CachyOS VM (KDE Plasma), confirmed 2026-08-07 to be the same VM
  used for the original pacman cross-distro testing on 2026-08-05** —
  not a fresh VM. Session on it that day used `glb info`/`glb restore
  default` end-to-end but predates `new-to-linux`/`developer`/`server`.
  Revisited 2026-08-07 specifically to verify pacman-specific package
  overrides added after that original session (see Roadmap).
- **The openSUSE Tumbleweed VM (zypper), same VM used for the original
  zypper cross-distro testing on 2026-08-06** — not a fresh VM. That
  original session used `glb info`/`glb restore default` end-to-end but
  predates `new-to-linux`/`developer`/`server`. Revisited 2026-08-07
  specifically to verify the `firefox:zypper` override on `new-to-linux`
  (see Roadmap) — the last piece of item 1's per-distro override
  verification.
- **New (2026-08-08): a dedicated EndeavourOS test VM** — hostname
  `grego-Endeavour`, another genuinely fresh test box, distinct from
  the CachyOS VM (both pacman/Arch-based, but separate machines). Came
  with `git`/`curl`/`ripgrep`/`fzf`/`unzip`/`bash-completion`/`yay`
  already present, not a fully bare install. First real `glb restore
  default` here found zero pacman override gaps and, more
  significantly, root-caused the `pam_faillock` lockout mechanism only
  suspected-not-confirmed on the CachyOS VM (see Roadmap) — GLB's own
  no-TTY sudo attempts during a sandboxed restore count as failed auth
  attempts against `pam_faillock`'s `deny=3` default, and can lock a
  real user out of their own terminal as a side effect.

When suggesting changes, keep portability across distros in mind — don't
assume a single package manager or init system unless the script already
branches on it.

## Current state (as of 2026-08-07)

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update [profile]` (system packages, starship, zsh plugins always;
  with a profile name, also that profile's already-installed
  `extras.txt` entries), `restore [profile] [--undo|--dry-run|--from-
  snapshot <name>]` (no profile name shows a guided picker —
  descriptions, an automatic `--dry-run` preview, then a confirm prompt
  before applying; `--dry-run` explicitly passed skips the confirm and
  just previews), `profiles`, `prompt`, `export`, `diff <a> <b>`,
  `repair <profile>`.
- Modules: `lib/banner.sh`, `lib/logging.sh`, `lib/utils.sh`,
  `lib/detect.sh`, `lib/package.sh`, `lib/extras.sh`, `lib/profile.sh`,
  `lib/export.sh`, `lib/diff.sh`, `lib/prompt.sh`, `lib/plugins.sh`,
  `lib/completions.sh` — all sourced by the `glb` dispatcher.
- `profiles/default/` is now Greg's real setup, not a placeholder, and
  **`glb restore default` has been run for real on this laptop** — Oh My
  Zsh + Powerlevel10k are no longer active (backed up to `~/.zshrc
  .glb-backup`; `~/.oh-my-zsh`/`~/.p10k.zsh` are just unused now, not
  deleted). All three real shells are unified around what was discovered
  to be Greg's most-maintained config, `~/.config/fish/config.fish`
  (already used Starship, `eza`, `bat`, `zoxide`, fzf key-bindings,
  Homebrew — far more developed than the old `.zshrc`, which only had one
  alias):
  - `packages.txt`: git, zsh, fish, tmux, neovim, curl, ripgrep, fzf,
    eza, bat, zoxide, fastfetch, ranger (tmux/neovim/ripgrep/fastfetch
    kept as aspirational even where not apt-installable on every
    distro).
  - `dotfiles/`: `.bashrc`, `.zshrc`, `.config/fish/config.fish`,
    `.gitconfig`, `.config/starship.toml`, `.config/ranger/rc.conf`
    (Greg's real hand-crafted config — plain text style: directory, git
    info, colored `❯`, no icons/segments, visually different from the
    old Powerlevel10k look).
    All three shells now share the same aliases (eza-based `ls` family,
    `bat` as `cat`, nav shortcuts, apt shortcuts, zoxide, guarded
    Homebrew shellenv) and all three now init Starship (bash and fish
    newly added; previously zsh-only).
  - `glb restore default` installs Starship + vendors
    `zsh-autosuggestions`/`zsh-syntax-highlighting` framework-free
    (`lib/plugins.sh`) in addition to packages/dotfiles — a genuinely
    complete, working shell setup in one pass, now proven on real
    hardware.
  - fzf Ctrl-T/Ctrl-R key-bindings confirmed working in all three shells
    on this machine after the real restore (the guarded `source`-if-
    present logic found what it needed).
  - Added a `GLB_SHELL` prompt indicator (2026-08-05): each shell exports
    its own name with a unique circled-letter symbol baked in (`Ⓑ bash`,
    `Ⓩ zsh`, `Ⓕ fish` — plain Unicode, not Nerd Font, so it renders
    everywhere) and the shared `starship.toml` shows it at the start of
    the prompt — Greg asked for this after noticing all three shells now
    look identical and wanting an easy way to tell them apart when
    layered (e.g. running `bash` from inside `zsh`). Iterated from an
    initial generic 🐚 symbol to per-shell symbols per Greg's feedback.
  - Nerd Font glyphs need each *terminal emulator* (not shell) to have
    its own font set to the already-installed `JetBrainsMono Nerd Font`.
    Checked directly (2026-08-05): COSMIC Terminal (`cosmic-term`) is
    already correctly configured (`~/.config/cosmic/com.system76
    .CosmicTerm/v1/font_name` = `JetBrainsMono Nerd Font`) — nothing to
    do there. Konsole isn't installed on this machine (the Dell laptop)
    at all, was only raised earlier as a hypothetical example. WezTerm
    now has a real vendored config (see below).
    - **Confirmed on the CachyOS test VM (2026-08-05):** Konsole renders
      the Nerd Font glyphs correctly — `GLB_SHELL` indicators (`Ⓑ`/`Ⓩ`/`Ⓕ`)
      and `eza`'s file-type icons both display properly after `glb
      restore default`, screenshot-verified by Greg. One more terminal
      emulator off the "does the font actually render" list.
    - **Independently reconfirmed (2026-08-05):** Greg took a second
      screenshot on the CachyOS VM itself and reviewed it in a separate
      Claude session running there (via Claude Desktop, which also
      installed cleanly on that Arch-based distro) — same result, Konsole
      renders fine on Arch-based distros too.
  - `.config/wezterm/wezterm.lua` (2026-08-05): written from scratch —
    Greg's WezTerm (installed via Flatpak, `org.wezfurlong.wezterm`) had
    no prior config at all. JetBrainsMono Nerd Font, Tokyo Night color
    scheme, minimal tab bar. Validated with WezTerm's own CLI
    (`wezterm --config-file <path> show-keys`), not just `bash -n`, since
    it's Lua, not shell. As of 2026-08-06, `glb restore` also installs
    WezTerm itself via the new `extras.txt`/Flatpak mechanism (see
    Roadmap) — previously it only symlinked this config.
  - **(2026-08-08, EndeavourOS VM) Real Flatpak-sandbox bug found and
    fixed, unrelated to the config file itself: every WezTerm launch
    printed `tty: ttyname failed: No such device`.** Root cause: the
    Flatpak app's default permissions (`devices=dri` only) don't bind
    `/dev/pts`, so WezTerm's own pty (allocated inside its sandboxed
    devpts instance) can't be resolved by `ttyname()` when
    `/etc/profile.d/gpm.sh` calls `tty` during every login shell's
    `/etc/profile`. **Not a GLB code fix** (Flatpak permissions are
    per-machine state, not something `glb restore` manages) — fixed by
    running `flatpak override --user org.wezfurlong.wezterm
    --device=all` once on this VM, then a full kill
    (`pkill -f wezterm-gui`)/relaunch (the already-running GUI instance
    keeps its old sandbox permissions until restarted). Worth knowing
    if this surfaces on another machine's WezTerm-via-Flatpak install.
  - **(2026-08-08, EndeavourOS VM) Wallpaper/opacity/keybindings added
    to `default`'s WezTerm config, Greg's explicit ask.** Used
    `window_background_gradient` (`#1a1b26` → `#0f0f17`, matching Tokyo
    Night) instead of an image file — deliberately, since the Flatpak
    sandbox's `filesystems=home:ro;xdg-config/wezterm` permission set
    makes an arbitrary wallpaper path unreliable to serve. Added
    `window_background_opacity = 0.9` (confirmed rendering correctly on
    this VM's KWin/Wayland session, which composites natively — no
    separate compositor needed). Added a tmux-style leader
    (`Ctrl+a`, 1s timeout): `c`/`x` new/close, `n`/`p`/`1`-`9` tab
    nav, `-`/`Shift+|` splits, vim-style `hjkl` pane nav, `z` zoom,
    `r` a resize key-table, `[` copy mode, double-leader to send a
    literal `Ctrl+a` through. Validated via `wezterm show-keys`
    against the real config file, same discipline as the original
    2026-08-05 build.
  - **Superseded (2026-08-09, Dell laptop): the gradient/opacity/
    keybindings config above is no longer what `default` ships.**
    While auditing `$HOME` clutter on the Dell laptop, found a
    long-standing, un-tracked `~/.wezterm.lua` (a plain file, not a
    GLB symlink, dated 2026-08-07 — predates the EndeavourOS session
    above) that WezTerm was silently preferring over the real
    GLB-managed `~/.config/wezterm/wezterm.lua`, since WezTerm checks
    `~/.wezterm.lua` first. That stray file had a simpler config
    (`font_size = 12.0`, `enable_tab_bar = false`,
    `window_decorations = "RESIZE"`, `color_scheme = 'Tokyo Night'`,
    `window_background_opacity = 0.92`, no gradient, no keybindings) —
    meaning the EndeavourOS additions above were never actually
    visible on Greg's real daily driver at all. Confirmed via
    `AskUserQuestion`: Greg chose to promote *this* laptop config into
    the repo (discarding the gradient/keybindings/explicit-Nerd-Font
    lines) rather than keep the EndeavourOS version, since this is
    what he's actually been using day to day. `profiles/default/
    dotfiles/.config/wezterm/wezterm.lua` now matches the old
    `~/.wezterm.lua` content exactly. The stray file itself was moved
    to `~/archived-configs/` on the laptop (not deleted), alongside
    other unrelated `$HOME` cleanup from the same session (old
    Oh-My-Zsh-migration leftovers: `.p10k.zsh`, `.shell.pre-oh-my-zsh`,
    `.zshrc.pre-oh-my-zsh`, `.zshrc.pre-oh-my-zsh-2026-08-02_22-24-02`,
    `.bashrc.original`) so WezTerm now falls through to the real
    GLB-managed symlink.
  - **Real gap found verifying the above (2026-08-09, same session):
    moving `~/.wezterm.lua` out of `$HOME` broke WezTerm entirely**
    (`Error opening /home/grego/.wezterm.lua: No such file or
    directory (os error 2)`) instead of falling through to
    `~/.config/wezterm/wezterm.lua` the way WezTerm's own documented
    config-search order says it should when that file is simply
    absent. Nothing in any GLB-managed dotfile sets `WEZTERM_CONFIG_FILE`
    or passes `--config-file` at runtime (checked directly), so
    something *outside* the repo — most likely a Flatpak environment
    override on `org.wezfurlong.wezterm` (`flatpak override --user
    --show org.wezfurlong.wezterm`, checking for a
    `WEZTERM_CONFIG_FILE` line) or a `WEZTERM_CONFIG_FILE` set
    somewhere else on this specific machine — is explicitly pinning
    that exact path rather than letting WezTerm search normally.
    **Not yet root-caused or fixed** — reverted immediately by moving
    `~/.wezterm.lua` back out of `~/archived-configs/` to unbreak
    WezTerm, since the file's content is now identical to the
    GLB-managed one anyway (see above), so nothing is lost by leaving
    it in place for now. Worth investigating on this machine
    specifically next time it comes up — check the Flatpak override
    first.
  - **Removed entirely (2026-08-09, same session, right after the above)
    — GLB no longer installs or manages WezTerm at all, and by
    extension no longer manages any terminal emulator.** After all of
    the above (Flatpak sandbox pty permissions, the stray
    `~/.wezterm.lua` shadowing bug, the COSMIC title-bar/tab-bar
    decoration confusion, the WezTerm-hard-errors-on-missing-config
    mystery that was never root-caused, and the wasted real time
    chasing all of it live on Greg's actual daily driver) Greg called
    it: "We are wasting too much time on WezTerm. Please remove it
    completely from this laptop and the project." New standing scope
    rule, written up properly in `docs/PHILOSOPHY.md` ("Enhance the
    Terminal You Have, Don't Replace It") and `docs/PROJECT.md`'s
    Non-Goals: **GLB does not install GUI applications of any kind,
    terminal emulators included** — only things that run inside
    whatever terminal a distro already ships. Removed the `flatpak
    wezterm org.wezfurlong.wezterm` extras.txt entry, the `flatpak`
    package dependency it needed, and `.config/wezterm/wezterm.lua`
    from `profiles/default`. The generic `flatpak` extras *method*
    itself stays in `lib/extras.sh` (harmless, reusable infrastructure,
    not the thing that caused the problem) even though no profile
    currently uses it. Same session, same reasoning one level up: also
    stripped `new-to-linux`'s curated desktop-app picks (Firefox,
    LibreOffice, GIMP, VLC) — Greg's words: "It is also right to remove
    Firefox LibreOffice etc. Also easy for end users to install. ...
    Let's apply the KISS approach to this project. We have scope creep
    adding these programs." `new-to-linux` was, at this point, just the
    shared shell/prompt setup plus Fresh (a terminal-based editor) — see
    its own Roadmap entry for the full detail. All the WezTerm history
    above (2026-08-05 through 2026-08-09) stays in this file as a
    record of what was tried and why it didn't work out, not as a
    description of anything GLB currently does. Updated `docs/`
    (PHILOSOPHY.md, PROJECT.md, ROADMAP.md, README.md,
    CODING_STANDARDS.md, DOCS_CHANGELOG.md, two design docs) and the
    bats suite (`tests/dispatcher.bats`) to match.
  - **`new-to-linux` retired entirely (2026-08-09, same session,
    follow-up discussion right after the above).** Talking through next
    steps after the WezTerm/GUI-apps removal, Greg asked to also sharpen
    the project's overall messaging around "the terminal is the barrier"
    (see the "Why it exists" section at the top of this file) and, when
    asked to flesh out what that meant for `new-to-linux` specifically
    (now that it had shrunk to shared-shell-setup-plus-Fresh, a near-
    duplicate of `default` minus `.gitconfig`/ranger): **retire the
    profile entirely** rather than keep two profiles this similar, or
    fold it into a still-unbuilt "Minimal" profile concept. Removed
    `profiles/new-to-linux/` (`packages.txt`, `extras.txt`,
    `description.txt`, `dotfiles/`) from the repo entirely. Updated the
    three tests in `tests/dispatcher.bats` that referenced the real
    `new-to-linux` profile directory (the full end-to-end restore test,
    the interactive-picker description test, and the `glb diff`
    real-drift test) to use `developer` instead, which has an
    equivalent shape (no `.gitconfig`, real package/dotfile
    differences from `default`). Updated every doc that described
    `new-to-linux` as a current, live profile (`README.md`,
    `docs/PROJECT.md`, `docs/PHILOSOPHY.md`, `docs/ROADMAP.md`,
    `docs/CODING_STANDARDS.md`, `CHANGELOG.md`, plus comment references
    in `profiles/developer/`'s and `profiles/server/`'s manifests) —
    left the many historical dated entries throughout *this* file
    (CLAUDE.md) untouched, since they're an accurate record of what
    happened at the time, not a description of current state.
    **Deliberately not re-tested on real hardware** — Greg's call: the
    old test VMs are being retired once this project reaches a stable
    point anyway, and real-world verification will happen against
    fresh VMs later rather than re-validating on machines about to be
    thrown away. So this (and the WezTerm/GUI-apps removal above) is
    verified by code/doc review only for now, not a live restore.
- `glb prompt` (Starship install + preset picker) was built and tested
  end-to-end on a Zorin OS VirtualBox VM on 2026-08-05.
- **The unified bash/zsh/fish + Starship + `GLB_SHELL` indicator setup
  above is confirmed and locked in as the standard prompt/shell for the
  `default` profile** (Greg's words: "let's make this the standard prompt
  and shell," 2026-08-05) — not a draft or one-off experiment. Treat
  `profiles/default`'s current dotfiles as the baseline going forward;
  future shell/prompt work should extend this rather than replace it.
- **Superseded (2026-08-06): the identical-prompt-everywhere approach
  above is no longer current.** Greg asked to differentiate the three
  shells' prompts instead of keeping them visually identical, and to
  drop the `GLB_SHELL` indicator entirely now that the prompts
  themselves look different:
  - **bash**: no longer uses Starship at all. Reverted to the plain
    Linux Mint/Debian default `PS1` (green `user@host`, blue `path`,
    `$`), set directly in `.bashrc`.
  - **fish**: no longer uses Starship either. Reverted to a hand-rolled
    prompt styled after the classic "Pure" theme (two-line: path + dim
    git branch, then a colored `❯` on its own line; right-prompt shows
    command duration for slow commands) implemented as plain
    `fish_prompt`/`fish_right_prompt` functions in `config.fish` — no
    plugin manager (Fisher) added, consistent with how `lib/plugins.sh`
    already vendors zsh plugins framework-free rather than pulling in a
    framework.
  - **zsh**: still the only shell using Starship. `starship.toml` was
    replaced with the official, unmodified "Tokyo Night" preset from
    starship.rs/presets (fetched from the starship GitHub repo, not
    hand-transcribed) — nice incidental pairing with the existing Tokyo
    Night WezTerm color scheme. Since zsh is now the only Starship
    consumer, `starship.toml` no longer needs to serve three shells at
    once.
  - `GLB_SHELL` is fully removed — the export lines are gone from all
    three rc files (`.bashrc`, `.zshrc`, `config.fish`), not just hidden
    from display. Prompt differentiation now comes from each shell
    genuinely looking different, not from a text label.
  - All 68 bats tests still pass unchanged; no test asserted specific
    prompt content, only that the dotfiles get symlinked.
  - Two follow-ups the same session: fish's dirty marker was expanded
    from a single `*` to the same symbol set Starship's `git_status`
    uses by default (`=` conflicted, `$` stashed, `✘` deleted, `»`
    renamed, `!` modified, `+` staged, `?` untracked), parsed from
    `git status --porcelain` — verified against both this repo's real
    state and a synthetic scratch repo exercising every symbol.
    Separately, zsh's Tokyo Night preset doesn't include a
    `cmd_duration` module by default, so one was added (5s threshold,
    styled to match the existing `$time` segment).
  - **Locked in (2026-08-06): Greg confirmed all three are good as-is
    — "everything should be locked in regarding shell prompts."** His
    read on each: bash-as-plain-default "will provide some level of
    comfort" (i.e. familiar/unsurprising for that shell), fish "looks
    like it should" (matches the Pure aesthetic he wanted), zsh "has
    some pizzazz" (Tokyo Night's the deliberately flashier one of the
    three). Treat per-shell distinct prompts (not a shared
    Starship-everywhere look) as the standing design for `default`
    going forward — same status the old unified approach had before
    this session, now superseded by this. Pushed to `origin/main` as
    commits `08d8769` and `dc0465a`.
- For the fine-grained "what shipped when" list, check CHANGELOG.md's
  `[Unreleased]` section — this file tracks the *why* and what's still
  open, not a full change log.

## Roadmap / in progress

- **`install.sh` curl-install bootstrap script built (2026-08-09,
  cloud session), prompted by Greg's next testing step.** Greg's plan
  for the first fresh-VM test (Pop!_OS, not directly connected to the
  GitHub repo) is deliberately more realistic than every prior test:
  an actual end-user-style install (`sudo apt install glb`-equivalent)
  rather than `git clone` + `./glb restore`. Confirmed via
  `AskUserQuestion` which install mechanism to build: a curl-install
  script (chosen) over a real `.deb`/PPA package (much heavier
  infrastructure, not a same-session task) or just testing the
  existing clone method first.
  - New `install.sh` at the repo root: clones GLB into
    `~/.local/share/glb` (`git pull --ff-only`s in place if already
    there; refuses to clobber an unrelated existing directory).
    Deliberately does **not** run `glb restore` itself — that's a
    separate, interactive, opinionated step (real package installs,
    dotfile changes), and auto-running it as a side effect of "get GLB
    onto my machine" would be a surprise no curl-install script this
    project curates (Fresh, Starship) actually pulls. Chose
    `~/.local/share/glb` deliberately — already used by
    `lib/plugins.sh` for vendored zsh plugins
    (`~/.local/share/glb/plugins`), confirmed no collision since
    `plugins/` isn't a git-tracked path at the repo root, so it just
    sits as an untracked directory inside the cloned working tree.
  - 4 new bats tests (`tests/install.bats`): no-git error, fresh
    clone, update-in-place, refuses-to-clobber. One real gotcha hit
    writing the "no git" test: emptying `PATH` entirely to hide `git`
    also hides `bash` itself from `run`'s own lookup (bash, git, and
    every coreutils binary all live in the same `/usr/bin` on this
    sandbox, so there's no directory-level way to exclude just `git`)
    — fixed by resolving `bash`'s absolute path *before* emptying
    `PATH`, then invoking it directly; the failure path only needs
    bash builtins (`command`, `echo`, `exit`) so an empty `PATH` is
    otherwise safe. 211/215 bats tests pass overall (same 4
    pre-existing root-sandbox permission-check failures documented in
    the entry below, unrelated).
  - **Real, not-yet-resolved blocker, flagged clearly rather than
    acted on: this script cannot actually work end-to-end while the
    repo stays private** — a fresh machine has no GitHub credentials
    to `git clone` a private repo. Greg said explicitly he's fine
    going public as part of this specific test if that's what's
    needed ("If the Project needs to go public to do that then we
    will do that as part of the test") — but flipping repo visibility
    is a real, hard-to-reverse action (once cloned/cached/indexed by
    anyone, "private" again doesn't undo that), so it was deliberately
    **not done automatically** as part of building this script. Making
    the repo public is Greg's own action to take when he's ready to
    actually run this test — not something this session did on his
    behalf. Docs updated (`README.md`'s Installation section now leads
    with the curl-install one-liner, `docs/ARCHITECTURE.md`,
    `docs/CODING_STANDARDS.md`) to match.
- **Full bats suite actually run for real (2026-08-09, cloud session)
  — first time this session's own test edits were executed, not just
  syntax-checked.** This cloud sandbox has no `bats` installed and no
  sudo access to install it, so used the same no-install workaround
  documented elsewhere in this file for VMs without `bats`: cloned
  `bats-core` directly into the scratchpad and ran it from source, no
  install needed. **207/211 pass.** The 4 failures are a single root
  cause, not a regression: this sandbox runs as `root`
  (`whoami`/`id` confirmed), and all 4 failing tests simulate a
  permission-denied scenario via `chmod 555` on a directory before
  attempting to write into it — a real, unprivileged user gets blocked
  by that, root doesn't (root bypasses filesystem permission checks
  entirely). Confirmed by reading each failing test
  (`tests/profile.bats`: "reports failure when a destination directory
  cannot be created" / "...backing up an existing file is not
  permitted" / "...creating a new symlink is not permitted";
  `tests/completions.bats`: "reports failure and continues when a
  directory can't be created") — all four follow the identical
  `chmod 555` pattern. This would fail identically on unmodified `main`
  from before any of today's changes; it's a property of running the
  suite as root, not something today's edits caused. **The signal that
  matters: every test touched by today's changes passed** — the eza
  `--git` fix, WezTerm removal, `new-to-linux` retirement, the
  `pam_faillock`/`glb_sudo` fix (including the sudo-stub `-n`-handling
  and `utils.sh`-sourcing fixes it required), and the 7 new
  `--from-manifest` tests. Confirms the whole session's work is
  internally consistent. The 4 permission-check tests still need a
  real non-root run (any actual machine) for genuine signal on that
  narrow slice — a pre-existing test-environment gap, not new.
- **Installation manifests built (2026-08-09, cloud session) — closes
  out Version 0.6 entirely.** The one Version 0.6 item with no design
  doc at all, unlike export/import/repair/update-components which
  each got scoped before being built. Confirmed via `AskUserQuestion`
  which of three candidate meanings Greg actually wanted (bring-your-
  own external manifest / a per-run audit trail of what GLB installed
  / a version-pinned lockfile) — chose the first, directly matching
  how he described the gap: "provide external options to run from
  within the program." See `docs/design/installation-manifests.md`
  for the full scoping writeup.
  - New `glb_apply_manifest <path> [--dry-run]` (`lib/profile.sh`),
    wired into the dispatcher as `glb restore --from-manifest <path>`
    — same two-token-flag parsing as the existing `--from-snapshot
    <name>`, works before or after `--dry-run` in either order. Unlike
    every other restore mode (profile name, `--from-snapshot`), this
    one takes a raw filesystem path, not a name resolved under
    `profiles/` or `snapshots/` — the whole point is running a
    profile-shaped directory (`packages.txt` + optional
    `extras.txt`/`dotfiles/`) that lives *outside* the repo, for a
    one-off custom install without committing a full profile.
  - Followed the exact same "duplicate, don't refactor" pattern
    `glb_apply_snapshot` already established: `glb_apply_manifest`'s
    body is a near-verbatim copy of `glb_apply_profile`'s six-step
    sequence (packages → extras → Starship → zsh plugins →
    self-symlink/completions → dotfiles) rather than a shared helper,
    since several existing bats tests assert on `glb_apply_profile`'s
    exact log wording and a refactor risked breaking those for a
    premature abstraction. Placed in `lib/profile.sh` itself (not
    `lib/export.sh`, where `glb_apply_snapshot` lives) since there's
    no "export" counterpart to pair with — profile.sh is the natural
    home for a third "apply a profile-shaped thing" entry point.
  - 6 new bats tests in `tests/restore_manifest.bats` (mirroring
    `tests/restore_snapshot.bats` one-for-one, plus one extra
    confirming a deeply nested arbitrary path works) and 3 new
    dispatcher end-to-end tests. Updated `README.md`,
    `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`, and `CHANGELOG.md` to
    match. **Version 0.6 (Configuration Management) is now fully
    complete.**
  - **Not yet verified for real** — built and tested from the repo
    alone (cloud session, no direct hardware access). A real `glb
    restore --from-manifest <path>` against a hand-written directory
    on an actual machine is still open, same as everything else from
    today's cloud session.
- **`pam_faillock` sudo-lockout bug fixed (2026-08-09, cloud session).**
  Picked up the known issue confirmed twice on real hardware (CachyOS
  2026-08-07, EndeavourOS VM 2026-08-08): every sudo-gated call in
  `lib/package.sh` used plain `sudo`, and a no-TTY invocation (e.g.
  GLB run from an automated/sandboxed context) still triggers a real
  `pam_unix` auth-failure attempt even though it was always going to
  fail — enough of those in a row trips `pam_faillock`'s `deny=3` and
  locks the real user out of their own terminal, entirely as a side
  effect of GLB's own designed-to-fail-cleanly attempts.
  - **Real design question worked through before fixing:** a naive
    global swap to `sudo -n` would have fixed the lockout but broken
    something more important — a user running `glb restore` or `glb
    install` directly in their own real terminal currently gets a
    normal interactive sudo password prompt (when a TTY is available),
    and `-n` unconditionally refuses to ever prompt, regardless of
    whether a TTY exists. Blindly switching would have made every
    sudo-gated step immediately fall through to the manual-step
    fallback on every real run, even for someone sitting right there
    ready to type their password — a real regression traded for fixing
    a real bug, not a clean win.
  - **Fix:** new `glb_sudo` helper (`lib/utils.sh`) checks `[[ -t 0 ]]`
    (is stdin a real terminal) and picks plain `sudo` when true, `sudo
    -n` when false. `lib/package.sh`'s install/remove/update now call
    `glb_sudo` instead of `sudo` directly. The manual-step fallback
    message (`glb_prompt_manual_step`) always displays the plain
    interactive `sudo ...` form, never `-n` — a human copy-pasting the
    printed command needs the real password prompt, even on a run
    where GLB's own automatic attempt used `-n`. Required restructuring
    `glb_install_package` slightly: the per-package-manager `cmd` array
    no longer includes the `sudo` prefix itself, so it can be reused
    for both the real `glb_sudo "${cmd[@]}"` call and the
    manually-displayed `"sudo ${cmd[*]}"` string.
  - `lib/prompt.sh`'s Starship install was flagged in the original bug
    report too, but doesn't actually call `sudo` directly — the
    third-party `curl | sh` installer script handles its own sudo
    internally, outside GLB's code, so there was nothing to change
    there.
  - **Real test-suite gap this surfaced:** several bats files source
    `lib/package.sh` directly (bypassing the real `glb` dispatcher,
    which sources every `lib/` module in the right order) without also
    sourcing `lib/utils.sh` first — `glb_sudo` would have been
    undefined in those isolated subshells. Fixed by adding `source
    lib/utils.sh` to every test block in `tests/package.bats` (9
    occurrences) and one in `tests/profile.bats` that actually
    exercises the real install path. Separately, two bats files
    (`tests/dispatcher.bats`, `tests/repair.bats`) stub `sudo` as
    `'exec "$@"'` to simulate it stepping out of the way — that stub
    would have tried to `exec` a program literally named `-n` if
    `glb_sudo` ever passed the flag through (which it does by default
    in the bats sandbox, since `run`'s subshells don't have a TTY on
    stdin). Fixed both stubs to strip a leading `-n` before exec'ing.
    Confirmed via `grep -q` (substring, not exact-match) that every
    other test asserting on captured `sudo`/package-manager call text
    tolerates the `-n` prefix appearing or not without needing changes.
  - **Not yet verified for real** — done from the repo alone (cloud
    session, no direct hardware access); the next real restore on an
    Arch-based machine (once fresh test VMs exist, per Greg's plan)
    should confirm no lockout occurs, and a real interactive `glb
    install <pkg>` run in an actual terminal should confirm the normal
    password prompt still works exactly as before.
- **Real bug found and fixed (2026-08-09, Dell laptop): per-file git
  status indicators never showed up in `ls`/`ll`/`la`/`l` output in
  any of the three shells, on either Cosmic Terminal or WezTerm — only
  visible inside Ranger.** Greg noticed this had "worked once before"
  and asked whether it was a config file issue or something `git`
  itself adds automatically. Root cause: the `eza --icons ...` aliases
  in every profile's `.bashrc`/`.zshrc`/`config.fish` never passed
  eza's `--git` flag, which is required for eza to query and display
  per-file Git status at all — confirmed via the full git history that
  this flag was never present in any commit, so it wasn't a
  regression, it was simply never wired up. It showed up identically
  missing across bash/zsh/fish because the cause was shared (the eza
  alias definitions), not shell-specific — a useful diagnostic signal:
  since bash's prompt has no git info by design (see the prompt
  differentiation entry further down) but the file-listing gap was
  present in zsh/fish too (which *do* show git info in their own
  prompts, confirmed via a WezTerm/fish screenshot showing the branch
  name `main` in the prompt itself), that ruled out the shell prompts
  and pointed at the one thing shared verbatim across all three
  shells' dotfiles. Ranger showing it correctly the whole time was a
  red herring in the opposite direction — unrelated, its `rc.conf`
  enables its own separate `vcs_aware`/`vcs_backend_git`. Fixed by
  adding `--git` to all four aliases across all four profiles' three
  shells (12 files). **Confirmed working for real (same day, Dell
  laptop)** — Greg's `eza` (v0.18.2) already had git support built in
  (`[+git]`), so the fix itself was correct on the first try; the only
  snag during verification was a genuine, separate gotcha, not a bug:
  running the raw `eza --icons --git -lah --group-directories-first`
  directly showed the new "Git" status column immediately, but the
  `ll` *alias* kept showing no column at all in the same terminal
  window, because fish only defines `alias`-created functions once at
  shell startup — pulling new file content into `config.fish` doesn't
  retroactively update an already-running session's function
  definitions. Confusingly, the fish *prompt itself* (a different
  mechanism — it re-runs `git status --porcelain` fresh on every
  prompt redraw, not just at startup) correctly showed a live `?` for
  an untracked test file in the same stale session, which briefly
  looked like partial success/failure rather than a single consistent
  stale-alias cause. Resolved with `exec fish` (replaces the running
  shell process, forcing a fresh `config.fish` read) — worth
  remembering for any future dotfile change that defines an alias or
  function: a plain `git pull` is not enough to pick it up in an
  already-open shell, even though the dotfile is a live symlink.
- **`glb restore default` verified end-to-end (2026-08-08, new
  EndeavourOS test VM), and a real root cause found for the
  `pam_faillock` lockout previously only guessed at on the CachyOS VM
  (2026-08-07 entry below).** Session paused mid-testing for a
  lockout-clearing logout/login, then resumed and finished in a second
  sitting the same day.
  - `glb info` detected `pacman`/`endeavouros` correctly. This VM
    already has `git`/`curl`/`ripgrep`/`fzf`/`unzip`/`bash-completion`
    and `yay` (AUR helper) present going in — not a fully bare install.
  - First `./glb restore default` (sandboxed, no TTY): zsh plugins,
    self-symlink, all 4 completions, the Nerd Font extra (confirmed via
    `fc-list`), and all dotfiles linked correctly (`.bashrc` correctly
    backed up to `.bashrc.glb-backup` first since it pre-existed). As
    expected, every sudo-gated step failed cleanly (no TTY) and paused/
    skipped per the existing manual-step mechanism: `zsh fish tmux
    neovim eza bat zoxide ranger htop flatpak fastfetch` all need a
    manual `sudo pacman -S`. **Zero pacman `_GLB_PACKAGE_OVERRIDES` gaps
    found** — every name resolves as a real package. `fresh` extra hit
    the exact same Arch-specific behavior already documented for
    CachyOS (installer builds `fresh-editor-bin` via `yay`/`makepkg`,
    ends with its own separate `sudo pacman -U` — built and cached
    successfully, just needs that final sudo step). `wezterm` extra
    failed only because `flatpak` itself wasn't installed yet (cascading
    from the packages.txt failure, not a new bug). `starship`'s
    installer also needs its own sudo for `/usr/local/bin`, same as
    every prior machine.
  - **Real root cause found for the `pam_faillock` lockout — and this
    is the second confirmed occurrence of GLB itself causing this, not
    a one-off.** The CachyOS VM hit the identical symptom on 2026-08-07
    (see that entry further down, now corrected as of 2026-08-08 to
    match: Greg originally assumed he'd mistyped his password three
    times in a row, and originally noted the lockout cleared just by
    waiting out the 10-minute window — **both wrong**. Both times, the
    password was entered correctly with no typos (same password is
    used for both the user account and sudo on these VMs), and both
    times a log out/log back in was required to regain sudo access,
    not just waiting. This time, `faillock --user grego` and
    `journalctl _COMM=sudo` were checked immediately, before the state
    changed, which is what nailed the actual mechanism down:
    - Every one of GLB's own automatic sudo attempts during the restore
      above (one per sudo-gated package/extra) logged `pam_unix(sudo:
      auth): conversation failed` / `auth could not identify password`
      — expected, since there's no TTY/askpass for sudo to prompt
      through. But `pam_unix` still counts each of these as a failed
      auth attempt against `pam_faillock`'s `deny=3` default. By the
      3rd sudo-gated package in the manifest (`tmux`, 17:24:44),
      `pam_faillock(sudo:auth): Consecutive login failures for user
      grego account temporarily locked` fired — **triggered entirely by
      GLB's own no-TTY attempts, not by anyone mistyping a password.**
    - Greg then hit the *same* lockout window when he tried the real
      bundled `sudo pacman -S ...` command himself in a real terminal a
      few minutes later (17:28:31, real TTY, `journalctl` shows "2
      incorrect password attempts") — the lockout rejecting an
      actually-correct, correctly-typed password, exactly the same
      failure mode the CachyOS entry hit and (per the correction above)
      also needed a log out/log back in to clear.
    - **Observed pattern (Greg, 2026-08-08): appears specific to
      Arch-based distros.** Both confirmed occurrences are on pacman
      machines — CachyOS (2026-08-07) and this EndeavourOS VM
      (2026-08-08) — despite `glb restore` hitting just as many
      sudo-gated packages/extras, just as many designed-to-fail-cleanly
      no-TTY attempts, on every apt (Pop!_OS/Mint/Debian/Dell laptop),
      dnf (Fedora), and zypper (openSUSE) machine tested throughout this
      whole project, with zero lockouts reported on any of them. Not
      independently root-caused yet (could be `pam_faillock` enabled by
      default on Arch's stock PAM config where it isn't on the others,
      or some other Arch-specific PAM default) — flagged as a real lead
      for whoever picks up the actual fix, not confirmed as the
      complete explanation.
    - **Real GLB gap, confirmed twice now, not fixed this session:**
      every sudo-gated call site (`lib/package.sh` install/remove/
      update, `lib/prompt.sh`'s Starship install) uses plain
      `sudo <cmd>`, which lets `pam_unix` attempt a real (failed) auth
      conversation. Using `sudo -n <cmd>` (non-interactive) instead
      would fail immediately on "no password available" without that
      conversation — worth checking whether that avoids counting
      against `pam_faillock` at all, since right now a fresh
      multi-package restore on a `faillock`-enabled distro can lock a
      real user out of their own terminal (requiring a log out/log back
      in, not just waiting) as a direct side effect of GLB's own
      designed-to-fail-cleanly sandboxed attempts. Given this has now
      happened on two separate real machines — both Arch-based — this
      should be treated as a real, reproducible bug to prioritize
      fixing, not just a flagged-for-later note — not scoped or built
      yet.
  - **Session paused here** — Greg is logging out/back in to clear the
    lockout. Not yet done: the 4 manual commands (bundled pacman
    install, fresh, wezterm, starship), a second `glb restore default`
    to confirm clean/idempotent, the bats suite, and the full
    Test-environments/Testing-section CLAUDE.md writeup once verified.
  - **Resumed same day after the logout/login cleared the lockout**
    (`faillock --user grego` came back with a clean history). Greg ran
    the 4 manual commands himself in a real terminal:
    `sudo pacman -S zsh fish tmux neovim eza bat zoxide ranger htop
    flatpak fastfetch`, `sudo pacman -U` the cached
    `fresh-editor-bin-0.4.6-1` package, `sudo flatpak install -y
    flathub org.wezfurlong.wezterm`, and the Starship curl installer.
    All four confirmed genuinely installed afterward: 11 packages via
    `pacman -Qi`, `fresh 0.4.6`, WezTerm `20240203-110809-5046fc22` via
    `flatpak list`, `starship 1.26.0`.
  - **WezTerm installed correctly but doesn't visibly launch on this
    VM — root-caused, and it's a VM/host graphics config issue, not a
    GLB bug.** Greg reported WezTerm as the one thing that "didn't
    install" even though every GLB-side check said otherwise: `flatpak
    list --app` shows it present (`20240203-110809-5046fc22`), its
    `.desktop` file is correctly exported
    (`/var/lib/flatpak/exports/share/applications/
    org.wezfurlong.wezterm.desktop`), and `~/.config/wezterm/
    wezterm.lua` is correctly symlinked — GLB's own job (install +
    config) is fully done. Launching it directly
    (`flatpak run org.wezfurlong.wezterm`) confirmed the real problem:
    the `wezterm-gui` process starts and stays alive (not a crash), but
    never produces a visible window, and its stderr shows why:
    ```
    VMware: No 3D enabled (0, Success).
    libEGL warning: egl: failed to create dri2 screen
    MESA: error: ZINK: failed to choose pdev
    ```
    This VM's virtual GPU (`VMware SVGA II Adapter`, VirtualBox's
    VMSVGA emulation) has 3D acceleration unavailable to the guest, so
    WezTerm's `wgpu`-based renderer can't get a hardware EGL context,
    and its Zink software-Vulkan-over-GL fallback also can't find a
    usable device — it just hangs with no window, which reads as "did
    nothing" from the outside. **Confirmed as the actual cause, not
    just a guess:** relaunching with `LIBGL_ALWAYS_SOFTWARE=1` (forces
    Mesa's `llvmpipe` software rasterizer, skipping the GPU/Zink path
    entirely) produces the exact same alive-process, no-crash behavior
    but with **none of those GPU errors in the log** — the failure
    disappears entirely once the GPU path is bypassed.
    - **Not a GLB bug, no code change needed** — this is a
      VirtualBox/guest-graphics configuration gap, the same category
      as the gnome-terminal font-cache issue documented for the Linux
      Mint machine elsewhere in this file. Two real fixes for Greg to
      choose from, neither of which GLB should attempt automatically:
      1. Enable **3D acceleration** for this VM in VirtualBox's own
         settings (Display tab, "Enable 3D Acceleration") and confirm
         Guest Additions are installed with 3D/OpenGL passthrough,
         then restart the VM — the real fix, gets GPU-accelerated
         rendering working as intended.
      2. As an immediate workaround without touching VM settings,
         launch WezTerm with software rendering forced:
         `LIBGL_ALWAYS_SOFTWARE=1 flatpak run org.wezfurlong.wezterm`
         (or set that env var globally for the flatpak app via
         `flatpak override --env=LIBGL_ALWAYS_SOFTWARE=1
         org.wezfurlong.wezterm` so it applies on every launch,
         including from the desktop app menu) — slower, but should
         render a working window on this VM as-is.
  - **Second `./glb restore default` confirmed fully clean/idempotent**
    — every package/extra/dotfile line "already installed"/"already
    linked", exit 0. `default` is now empirically confirmed working
    end-to-end on this machine, not just the sandboxed first pass.
  - **Full bats suite run** (via a scratchpad-cloned `bats-core`,
    `bats` itself still not installed on this VM, same workaround as
    every other machine without it): 195/202 on the first pass. 5 of
    the 7 failures were the same already-documented `fresh`-on-real-
    PATH class (`tests/dispatcher.bats`'s three real-profile end-to-end
    tests, `tests/extras.bats`'s curl dry-run test and its "skips an
    extra that isn't currently installed" update test) — expected,
    since this VM's own restore installed `fresh` for real this
    session, same pattern seen on every prior VM's first real `fresh`
    install.
  - **Real, newly-discovered test-isolation bug, found and fixed this
    session (`tests/export.bats`):** two tests — "export_packages
    writes canonical names, reversing overrides" and "export_packages
    adds the zypper base-package caveat only on zypper" — stub
    `apt-mark`/`rpm` to force apt/zypper-flavored behavior, but
    `glb_export_packages` (`lib/export.sh`) detects the package
    manager via the real `glb_detect_package_manager`
    (`command -v apt/dnf/pacman/zypper` against the real host, not
    stubs). On a real apt or zypper host these tests happened to pass
    by accident; this is the first time `tests/export.bats` has run
    against a real pacman machine, and detection correctly returned
    `pacman`, so neither the apt-specific `fd-find`→`fd` reversal nor
    the zypper caveat branch ever ran — a genuine bug that would fail
    identically on any dnf host too, not something specific to this
    VM. **Fixed** by overriding the `glb_detect_package_manager`
    function directly inside each test's subshell (`glb_detect_package_
    manager() { printf 'apt\n'; }` / `'zypper\n'`) rather than PATH-
    restricting to `STUB_BIN` (tried first, but that also hides the
    coreutils `glb_export_packages` itself needs — `mkdir`, `hostname`,
    `date`, `sort` — since the real pacman binary lives alongside them
    in the same system directories and can't be selectively hidden via
    PATH ordering). Confirmed the fix is deterministic regardless of
    host package manager, not just "happens to work on pacman" — both
    tests now force their target manager explicitly. 197/202 pass
    after the fix; the remaining 5 are the pre-existing `fresh`-on-PATH
    class described above, confirmed via `git diff --stat` that no
    other files changed this session besides this test fix and this
    CLAUDE.md note.
  - **`default` is now confirmed on real pacman/EndeavourOS hardware,
    end-to-end** — zero `_GLB_PACKAGE_OVERRIDES` gaps, all four extras
    methods (curl/flatpak/font/starship-installer) working, a clean
    idempotent second restore, and a genuine (if narrow) test-suite bug
    fixed as a direct result of testing on a package manager
    (`tests/export.bats` had never run against) this project's CI-less,
    single-machine-at-a-time testing style hadn't exercised before.

- **"Updating installed components" built (2026-08-07, Dell laptop) —
  last item in Version 0.6, closing it out entirely.** Picked up
  exactly where the openSUSE VM session's scoping (`docs/design/
  update-components.md`, entry right below this one) left off.
  - New `glb_update_starship` (`lib/prompt.sh`): if `starship` is
    already on `PATH`, re-runs the exact same installer command
    `glb_install_starship` uses; a plain no-op (no curl call at all)
    if it isn't installed. New `glb_update_zsh_plugins`
    (`lib/plugins.sh`): for each curated plugin whose directory
    already exists under `~/.local/share/glb/plugins`, runs `git -C
    <dest> pull`; plugins never cloned are silently skipped. Both
    called unconditionally by `glb update`, matching the design doc's
    "Starship/zsh plugins aren't profile-specific" call.
  - New `_glb_update_extra`/`glb_update_profile_extras`
    (`lib/extras.sh`), parallel to the existing `glb_install_extra`/
    `glb_apply_profile_extras` but update-flavored: only re-runs an
    entry if `glb_extra_installed` already says yes (nothing to key an
    update against otherwise). `curl` re-runs the same install script
    (same `PIPESTATUS`-array-capture care as the install path);
    `flatpak` runs `flatpak update -y <app-id>` — the correct native
    verb, deliberately distinct from `install`; `font` re-downloads
    and re-extracts into the same directory (the URL's already a
    "latest" redirect, so this naturally picks up the current
    release). No manual-step pause on any failure here, unlike the
    install path — matches `glb update`'s existing unprompted
    convention rather than the first-install pause/retry UX.
  - Dispatcher (`glb`): `update` case now takes an optional profile
    argument. Validates an explicitly-given name exists first
    (`Profile not found: <name>`, same wording/pattern as every other
    profile-taking command) before doing anything. Always runs
    packages + starship + zsh plugins; only calls
    `glb_update_profile_extras` when a profile name was actually
    given. Failures across all steps are aggregated into one overall
    exit status via `exit "$update_status"` rather than the plain
    fall-through every other dispatcher branch uses, since `update`
    now runs multiple independent steps whose individual failures all
    need to surface in the final exit code.
  - 17 new bats tests across `tests/prompt.bats`, `tests/plugins.bats`,
    `tests/extras.bats`, `tests/dispatcher.bats`. **Real gotcha caught
    by the dispatcher-level tests, not the smaller unit tests:** this
    laptop has a genuine `starship` binary on real `PATH` (bats'
    sandbox prepends `STUB_BIN` to the real `PATH`, it doesn't replace
    it) — the pre-existing "glb update runs the package manager's
    update commands" test started failing because
    `glb_update_starship` found that real binary "installed" and tried
    a real network install via unstubbed `curl`/`sh`. Same PATH-bleed
    class of gap already documented elsewhere in this file for `fresh`
    and `starship` (`glb_export_shell`'s tests). Fixed by stubbing
    `curl`/`sh` to safe no-ops in `tests/dispatcher.bats`'s shared
    `setup()`, alongside the existing `sudo`/`apt`/`dpkg` stubs — the
    same isolation fix pattern, not a new one. 201/202 bats tests
    pass; the one failure (`export_packages adds the zypper
    base-package caveat only on zypper`) is pre-existing and unrelated
    — confirmed via `git stash` to fail identically on unmodified
    `main` on this apt machine.
  - **Real, for-real verification, not just bats — run on this
    Dell laptop (2026-08-07), Greg's actual daily-driver machine, not
    a throwaway VM.** Ran bare `./glb update` for real: `sudo apt
    upgrade` and the Starship reinstall both initially failed cleanly
    with zero side effects (no TTY for the sudo password prompt, same
    limitation documented everywhere else in this file) — nothing was
    touched. The zsh plugin `git pull`s ran unprompted and succeeded
    (`zsh-autosuggestions` already current, `zsh-syntax-highlighting`
    fast-forwarded one real upstream commit). Greg then ran the two
    printed sudo-gated commands himself in a real terminal
    (`sudo apt update && sudo apt upgrade -y`, then
    `curl -sS https://starship.rs/install.sh | sh -s -- -y`) —
    confirmed afterward via `starship --version`: `starship 1.26.0`
    at `/usr/local/bin/starship`, a genuine version bump from
    whatever was previously installed. `glb update`'s non-profile path
    (system packages, Starship, zsh plugins) is now confirmed working
    end-to-end on real hardware, not just through the stubbed bats
    sandbox. **Not yet exercised for real:** `glb update <profile>`'s
    `extras.txt` re-run path (`curl`/`flatpak update`/`font`) — still
    only bats-verified.
- **"Updating installed components" scoped (2026-08-07, openSUSE VM),
  not yet built — last item in Version 0.6.** Same approach as the
  wizard and repair scoping earlier this session: checked what already
  exists first. `glb update` already runs the package manager's own
  upgrade (apt/dnf/pacman/zypper), unprompted — plain system packages
  are covered. Everything else GLB installs *outside* the package
  manager has no update path at all: `extras.txt` entries (curl-installed
  things like Fresh, Flatpak apps like WezTerm, the Nerd Font),
  vendored zsh plugins (`git clone --depth 1`, never `git pull`ed), and
  Starship (its own installer is safe to re-run, but GLB's
  presence-only check currently prevents that from ever happening
  automatically). Confirmed via `AskUserQuestion`: extend the existing
  `glb update` command rather than add a new one, and explicitly leave
  GLB updating its own code (`git pull` in the GLB repo) out of scope —
  a meaningfully different, more sensitive operation, deferred as its
  own future item. One consequence worked out directly (not asked,
  since it's mechanical rather than debatable): `extras.txt` is
  per-profile data but `glb update` currently takes no arguments at
  all, so it needs an *optional* profile argument to know which
  `extras.txt` to reach — Starship and zsh plugins aren't
  profile-specific, so they'd update regardless of whether a profile
  name is given. Wrote `docs/design/update-components.md` with the full
  plan: `glb_update_starship` (`lib/prompt.sh`),
  `glb_update_zsh_plugins` (`lib/plugins.sh`), and
  `glb_update_profile_extras` (`lib/extras.sh`, only when a profile
  name is given) — no confirmation prompt anywhere in it, deliberately
  matching `glb update`'s existing unprompted convention rather than
  the guided-wizard/`glb repair` confirm-first pattern, since this is
  extending an existing command's established behavior, not inventing
  a new one. Docs only, no code changed this round.
- **`glb repair` built (2026-08-07, openSUSE VM, same session as the
  scoping below) — closes out "repairing existing installations."**
  Followed `docs/design/repair.md`'s plan exactly, built right after
  writing it.
  - New `lib/repair.sh`: `glb_repair <profile>` — `mktemp -d`s an
    ephemeral directory, calls `glb_export_packages`/
    `glb_export_dotfiles` (`lib/export.sh`) against it directly (not
    the full `glb_export_snapshot`, since `shell.txt`/`metadata.yaml`
    aren't needed and nothing should be saved to disk), then calls
    `lib/diff.sh`'s own internal `_glb_diff_packages`/
    `_glb_diff_dotfiles` directly against (ephemeral dir, "current
    state") vs. (the profile's real directory, the profile name) —
    deliberately reusing another module's `_glb_`-prefixed "private"
    helpers directly, the same kind of cross-module reuse
    `glb_apply_snapshot` (`lib/export.sh`) already does with
    `lib/profile.sh`'s functions. The ephemeral directory is `rm -rf`'d
    unconditionally before returning, whichever path is taken. No
    drift → logs healthy, exit 0. Drift → prints the same-shaped report
    `glb diff` produces, then asks "Re-run 'glb restore <profile>' now
    to fix this?" (same confirm-prompt pattern as the guided wizard);
    confirming calls the real `glb_apply_profile <profile>` and returns
    its status, declining or no input leaves the machine untouched and
    returns 1.
  - Wired into the dispatcher as `repair <profile>`.
  - 8 new bats tests in `tests/repair.bats` (missing/unknown profile,
    clean report, drift-then-confirm actually installing for real,
    decline, no-input, ephemeral-directory cleanup verified by stubbing
    `mktemp` to a known path and confirming it's gone afterward, and a
    changed-dotfile-detection case) plus 3 new dispatcher end-to-end
    tests (`tests/dispatcher.bats`, real `default` profile: finds real
    drift and fixes it once confirmed, declines cleanly, unknown
    profile). 182/186 total pass — same 4 pre-existing `fresh`-on-PATH
    failures, unrelated. One real bug caught by the dispatcher-level
    test that a smaller unit test wouldn't have: the first version of
    that test only stubbed `starship`/`git`/`apt-mark`, and applying
    the real `default` profile for real also needs
    `curl`/`sh`/`flatpak`/`unzip`/`fc-cache` stubbed (its `extras.txt`
    entries) — copied the same full stub set the existing "glb restore
    applies the real default profile" test already used.
  - **Real, for-real verification, not just bats:** ran `./glb repair
    default` on this VM for real, declining the fix. Output was
    accurate and consistent with this session's earlier `glb
    export`/`glb diff` verifications against this same profile (same
    zypper base-package noise, same `default`-only packages missing
    since this VM was actually restored with `new-to-linux`, not
    `default`) — confirmed no snapshot directory and no other on-disk
    trace was left behind after the ephemeral check ran.
- **"Repairing existing installations" scoped (2026-08-07, openSUSE
  VM), not yet built.** Reviewed what already exists before assuming
  anything new was needed: `glb restore <profile>` is already fully
  idempotent (documented repeatedly across this file's own Roadmap
  entries — a second restore always comes back clean, reinstalling
  whatever's missing), so the obvious "something broke, fix it"
  scenario is already solved. Confirmed via `AskUserQuestion` which of
  two real remaining gaps to target: a one-shot check-then-fix
  convenience command (chosen) versus deepening the installed-checks
  themselves to catch real corruption (deliberately deferred — concrete
  known example: `glb_install_zsh_plugins`, `lib/plugins.sh`, only
  checks `[[ -d "$dest" ]]`, so a directory left behind by an
  interrupted `git clone` would be reported "already installed"
  forever; not worth auditing every check pre-emptively when this is
  the only known instance). Wrote `docs/design/repair.md`: `glb repair
  <profile>` would do an ephemeral export (packages + dotfiles only,
  reusing `glb_export_packages`/`glb_export_dotfiles` directly, no
  snapshot saved to disk) diffed against the profile (reusing
  `lib/diff.sh`'s internal `_glb_diff_packages`/`_glb_diff_dotfiles`
  directly, bypassing name-based snapshot/profile resolution since real
  paths are already in hand), then offers to re-run `glb restore` if
  drift is found — reusing the same confirm-prompt pattern just built
  for the guided wizard. No new detection mechanism, entirely built
  from pieces that already existed by the end of this session. Docs
  only, no code changed this round.
- **Guided configuration wizard built (2026-08-07, openSUSE VM) —
  closes out the last four Version 0.5 bullets.** Followed the
  scoping this same session already locked down in
  `docs/design/guided-wizard.md` (discovery-only, express-install and
  progress-reporting need no code, and — confirmed via a follow-up
  `AskUserQuestion` right before building — the richer flow becomes
  bare `glb restore`'s new default, not an opt-in flag).
  - **New `profiles/<name>/description.txt`** (one line each) added to
    all four existing profiles, and a new `_glb_profile_description`
    helper (`lib/profile.sh`) that reads it, falling back to nothing
    (bare name shown) if a profile doesn't have one — kept genuinely
    optional rather than required.
  - **`glb_restore_interactive` (`lib/profile.sh`) rewritten**: the
    picker menu now shows each profile's description next to its
    name; once a number is chosen, it automatically runs the same
    `--dry-run` preview `glb restore <profile> --dry-run` would show,
    then asks "Apply this profile now? [Y/n]" before doing a real
    apply. Explicit `--dry-run` passed to the bare command (`glb
    restore --dry-run`) skips the confirm step entirely and just
    previews, unchanged from before — only the fully-bare `glb
    restore` gained the new confirm gate. A decline, or no input
    available to answer with, cancels cleanly with nothing changed
    (same fail-safe posture as `glb_prompt_manual_step`'s existing
    skip-on-EOF handling) — returns 1, doesn't hang.
  - **Real gotcha found while writing the tests, not a GLB bug:**
    bash's `read -p` prints its prompt to neither stdout nor stderr in
    a way `bats`' `run` can capture when stdin is a redirected
    here-string/pipe rather than a real terminal — confirmed with a
    minimal `bash -c 'read -p "X: " v <<< "y"'` repro showing the
    prompt text simply never appears in captured output at all,
    regardless of stream redirection. This is why the *existing*
    `glb_prompt_manual_step` tests (`tests/package.bats`) already never
    asserted on its own prompt text either — an established pattern in
    this codebase, not something this session discovered as broken;
    just something worth knowing if a new interactive prompt's test
    ever seems to inexplicably not see its own prompt string.
  - **Deliberately duplicated, not refactored, existing dry-run/apply
    calls** — `glb_restore_interactive` now calls `glb_apply_profile`
    twice (once with `"--dry-run"` for the preview, once for real if
    confirmed) rather than inventing a new "preview-then-commit"
    primitive. Exactly the "close to free" reuse the design doc
    predicted: no new mechanism, just two calls to something that
    already existed.
  - Existing interactive-picker tests in `tests/profile.bats` and
    `tests/dispatcher.bats` were **updated, not just extended** — they
    now feed a second line of input for the new confirmation prompt,
    since the default behavior genuinely changed (anticipated
    explicitly in the design doc's now-resolved open question). 9 new
    tests total across both files (description display, bare-Enter
    defaults to yes, explicit decline, no-input-available, a profile
    with no `description.txt` falling back to a bare name, and a
    dispatcher-level test confirming the real shipped profiles' actual
    description text renders correctly). 175 total bats tests, 171
    pass — same 4 pre-existing `fresh`-on-PATH failures, unrelated.
  - **Real, for-real verification, not just bats:** ran `./glb restore`
    with no arguments for real on this VM, chose `default`, declined
    the confirmation — output showed all four real profiles with their
    real descriptions, a full accurate preview of `default` (including
    real "already installed" vs. "would install" distinctions for this
    VM's actual state), and confirmed nothing on the real machine
    changed after declining.
- **`glb export` built (2026-08-07, openSUSE VM) — first slice of
  Version 0.6's Configuration Management, picked up after item 1
  (per-distro override verification) closed out on this same machine
  this session.** Read `docs/ROADMAP.md` and
  `docs/design/state-export-import.md` (written 2026-08-06, previously
  just "Proposed — not yet implemented") before building — the design
  doc already had a scoped three-part plan (`glb export` / `glb diff` /
  `glb restore --from-snapshot`); only `glb export` was built this
  session, the other two are still just design. One open question in
  the doc — snapshots in-repo (versioned, diffable across machines via
  the existing `git fetch` workflow) vs. a separate per-machine
  location — was resolved via `AskUserQuestion`: **in-repo**, decision
  recorded directly in the design doc.
  - New `lib/export.sh`: `glb_export_snapshot` writes
    `snapshots/<hostname>-<date>/` containing `packages.txt` (same
    format `glb restore` already reads), `dotfiles/` (real copies, not
    symlinks), `shell.txt`, and `metadata.yaml`. Wired into the
    dispatcher (`glb`) as a new `export` command alongside the existing
    ones.
  - **Packages:** two new functions in `lib/package.sh` —
    `glb_list_installed_packages` (per-package-manager query for
    explicitly-installed-not-just-a-dependency packages: `apt-mark
    showmanual`, `dnf repoquery --userinstalled`, `pacman -Qqe`) and
    `glb_reverse_resolve_package_name` (the inverse of the existing
    `glb_resolve_package_name` — maps a distro-specific name like
    `fd-find` back to GLB's canonical `fd` via
    `_GLB_PACKAGE_OVERRIDES`, so exported `packages.txt` reads the same
    as a hand-written profile would).
  - **Real gap found building this: zypper has no first-class
    manual-vs-dependency query** like the other three managers. Worked
    around using `/var/lib/zypp/AutoInstalled` — a plain-text list
    libzypp itself maintains internally (confirmed real and current on
    this VM, dated the same day, 2572 lines) for its own `zypper info`
    "Installed: Yes (automatically)" reporting; manual = `rpm -qa` minus
    that list. Verified for real on this VM: 2592 total installed RPMs,
    43 resolve as "manual" this way. **Real limitation, not fully
    solved:** that 43 includes genuine base-system/pattern packages
    (`glibc`, `kernel-default`, `grub2`, `NetworkManager`, `firewalld`,
    `patterns-base-*`, ...) that were never a deliberate user choice,
    just part of the OS install itself — zypper's tracking can't tell
    those apart from something the user actually asked for. Documented
    both in a code comment (`glb_list_installed_packages`) and as a
    zypper-only note `glb_export_packages` writes directly into the
    exported `packages.txt`, rather than silently shipping a misleading
    file — same "flag the real gap rather than paper over it" pattern
    as the existing zypper/`unattended-upgrades` and unverified-override
    notes elsewhere in this file.
  - **Dotfiles:** exports the union of relative paths across every
    local profile's `dotfiles/` (not a blind `$HOME` scrape — matches
    the design doc's explicit scope boundary), copying real content via
    `cp -L` for whichever of those actually exist in `$HOME` right now
    — so a file hand-edited since the last restore is captured as its
    real current content, not the stale symlink target.
  - **Real scope gap found via a real end-to-end run on this VM, not
    just bats — deliberately not fixed this session:** the exported
    `packages.txt` included `fresh-editor` under its raw RPM name, not
    GLB's canonical `fresh`, because Fresh is installed via
    `extras.txt`'s curl method, not a `_GLB_PACKAGE_OVERRIDES` entry —
    only the package-manager path is reverse-mapped right now, extras
    aren't cross-referenced at all. Flagged here as a known follow-up,
    not silently left undiscovered.
  - 16 new bats tests in `tests/export.bats` (reverse-resolution, each
    package manager's listing command, the zypper
    AutoInstalled-diffing logic, dotfiles export including the
    symlink-follows-to-real-content case, shell.txt, metadata.yaml, and
    two `glb_export_snapshot` integration tests) plus 1 new dispatcher
    end-to-end test in `tests/dispatcher.bats` (real `default` profile's
    dotfiles, real `glb export` invocation). Two real bugs caught and
    fixed by actually running the suite on this VM before calling it
    done, not by inspection alone: two `export_shell` tests initially
    read the real host's actually-installed `starship` (this VM has one
    — same class of real-host-PATH-bleed gap already documented
    elsewhere in this file for `fresh`), fixed by scoping `PATH` to
    `STUB_BIN` only, matching the isolation pattern `tests/detect.bats`
    already established; separately, those same two tests initially
    forgot to source `lib/detect.sh` (needed for `glb_detect_shell`)
    inside their restricted-PATH subshell, caught by the very next test
    run. 137/141 bats tests pass overall — the same 4 pre-existing,
    already-documented `fresh`-genuinely-on-PATH failures this VM has
    from this session's real `new-to-linux` restore earlier (see
    Testing section), confirmed via `command -v fresh` directly rather
    than assumed.
  - **Real, for-real verification, not just bats:** ran `./glb export`
    for real on this VM (safe to do live, unlike `restore` — no sudo,
    no network, no destructive action, purely reads system state).
    Produced a real 40-package `packages.txt`, all 7 real tracked
    dotfiles, a correct `shell.txt` (zsh, starship installed, both
    curated zsh plugins present), and `metadata.yaml`. **Confirmed with
    Greg via `AskUserQuestion` and then deleted before committing**
    (chosen over keeping it) — the real snapshot was a noisy first cut
    (zypper base-package cruft per the limitation above) and not a
    great precedent to set as the first real machine-data commit in a
    repo that may go public later; this session's commit is code +
    tests only, no real snapshot data.
  - **Not started (at the time):** `glb diff <snapshot> <profile>`
    (drift detection) and `glb restore --from-snapshot <name>` — built
    `glb diff` immediately after, same session, see next entry.
    `glb restore --from-snapshot` is still the only unbuilt piece.
- **`glb diff` built (2026-08-07, openSUSE VM, same session as `glb
  export` above).** Second slice of Version 0.6, following the same
  design doc.
  - New `lib/diff.sh`: `glb_diff_snapshot <a> <b>` resolves each name
    against `profiles/` then `snapshots/` (`_glb_diff_resolve_dir`) —
    a deliberate generalization beyond the design doc's literal
    `<snapshot> <profile>` signature, since both are the exact same
    shape (`packages.txt` + `dotfiles/`). Means `glb diff` can compare
    a snapshot against the profile it should match (the doc's original
    use case), two snapshots from different machines against each
    other (the cross-machine comparison the in-repo-snapshots decision
    was specifically chosen to enable — see the `glb export` entry
    above), or even two profiles directly. Reports package drift
    (`+`/`-` only-in-one-side, comma-joined, matching the design doc's
    example format) and dotfile drift (`~` changed content via `cmp
    -s`, plus `+`/`-` for a dotfile only tracked on one side). Exit
    status follows plain `diff`'s own convention: 0 if identical, 1 if
    any differences were found (or on a usage/lookup error) — wired
    straight through as `glb diff`'s own exit code, no extra status
    logic needed in the dispatcher.
  - 15 new bats tests in `tests/diff.bats` (name resolution and its
    profile-over-snapshot precedence, `packages.txt` parsing reusing
    the same comment/whitespace-stripping rules
    `glb_apply_profile_packages` already uses, package drift, dotfile
    drift including the changed-content case, and full
    `glb_diff_snapshot` integration tests) plus 3 new dispatcher
    end-to-end tests in `tests/dispatcher.bats` (real `default` vs
    `new-to-linux` — confirms `.gitconfig`/ranger/WezTerm show up as
    default-only exactly as documented elsewhere in this file — a
    profile diffed against itself reporting clean, and an unresolvable
    name erroring cleanly). 155/159 total pass — the same 4
    pre-existing `fresh`-on-PATH failures, unrelated to this work.
  - **Real, for-real verification, not just bats:** ran `./glb diff
    default new-to-linux` for real on this VM — output matched the
    documented differences between the two profiles exactly
    (`.gitconfig`/ranger/WezTerm default-only; Firefox/GIMP/LibreOffice/
    VLC new-to-linux-only). Then chained it with `glb export`: ran a
    real `./glb export` on this VM, `glb diff <that-snapshot>
    default`, and got back an accurate real diff — this VM's real
    zypper base-package noise on one side (same limitation documented
    in the `glb export` entry above) and `default`-only packages
    (`bash-completion`/`curl`/`flatpak`/`htop`/`unzip`) correctly
    reported missing, since this VM was actually restored with
    `new-to-linux` this session, not `default` — exactly the real
    drift a genuinely different profile would produce, not a bug.
    Deleted the real snapshot before committing, same call as the
    `glb export` entry above and for the same reason.
  - **Built immediately after, same session — see next entry.**
- **`glb restore --from-snapshot` built (2026-08-07, openSUSE VM, same
  session as `glb export`/`glb diff` above) — closes out the
  state-export-import design doc entirely.** Third and last piece.
  - New `glb_apply_snapshot` in `lib/export.sh` (co-located with
    `glb_export_snapshot`, its natural symmetric pair) — deliberately
    **duplicates `glb_apply_profile`'s body** (`lib/profile.sh`) rather
    than refactoring it into a shared helper: many existing bats tests
    assert on `glb_apply_profile`'s exact log wording (`"Profile
    applied: $name"`, `"Profile not found: $name"`, etc.), so a
    refactor risked silently breaking assertions in
    `tests/dispatcher.bats`/`tests/profile.bats` for a "premature
    abstraction" the project's own conventions warn against. The
    duplicate calls the exact same six steps in the exact same order
    (packages, extras, starship, zsh plugins, self-symlink,
    completions, dotfiles) against `snapshots/<name>` instead of
    `profiles/<name>`, with snapshot-flavored wording (`"Applying
    snapshot: $name"` / `"Snapshot applied: $name"` /
    `"Snapshot not found: $name"`). `glb_apply_profile_extras` already
    no-ops cleanly when `extras.txt` is absent (confirmed by reading
    `lib/extras.sh` before assuming it needed special-casing) — since
    `glb_export_snapshot` never writes one, this just works without
    any snapshot-specific branch.
  - Dispatcher (`glb`): the `restore` case's argument loop changed from
    a plain `for` loop to an indexed `while` loop so `--from-snapshot`
    can consume its own value (`<name>`) as a second token, same
    pattern needed for any two-token flag; `--dry-run` and a bare
    profile name still parse exactly as before in either order.
  - 6 new bats tests in `tests/restore_snapshot.bats` (mirroring
    `tests/profile.bats`'s `glb_apply_profile` test block one-for-one:
    unknown snapshot, missing name, real apply, a failing package,
    `--dry-run`, and the no-`extras.txt` case) plus 5 new dispatcher
    end-to-end tests (`--from-snapshot` alone, `--dry-run` before and
    after `--from-snapshot`, a nonexistent snapshot, and a full **`glb
    export` -> `glb restore --from-snapshot`** round-trip test that
    deletes `~/.bashrc` after exporting and confirms the restore
    relinks it with the exported content). 165/169 total pass — same 4
    pre-existing `fresh`-on-PATH failures, unrelated.
  - **Real, for-real verification, not just bats:** ran a real `./glb
    export` on this VM, then `./glb restore --from-snapshot <name>
    --dry-run` against it (dry-run deliberately chosen over a real
    apply, since this snapshot's `packages.txt` still carries the
    documented zypper base-package noise — installing/verifying things
    like `glibc`/`kernel-default` for real wasn't a risk worth taking
    just to prove the code path). Output was exactly right: every
    package "already installed," every dotfile "would replace .../kept
    as-is" — a snapshot round-tripped against the exact machine it came
    from should show zero real drift, and it did. Deleted the real
    snapshot before committing, same call as the other two entries.
  - **State-export-import is now fully built**, all three pieces done
    in one session on this VM: `glb export`, `glb diff`, `glb restore
    --from-snapshot`.
- **`new-to-linux`'s `firefox:zypper` override verified for real
  (2026-08-07, openSUSE Tumbleweed VM — the same VM from the original
  2026-08-06 zypper cross-distro test).** Closes out the last open piece
  of item 1 — both the pacman side (CachyOS VM entry below) and the
  zypper side are now confirmed on real hardware. `glb info` detected
  `zypper` correctly. Ran a real `glb restore new-to-linux`:
  - **`firefox:zypper` → `MozillaFirefox` confirmed correct** — the
    restore reported `Already installed: firefox` on the first run, and
    `glb_resolve_package_name "firefox" "zypper"` independently confirmed
    it resolves to `MozillaFirefox`. `rpm -q MozillaFirefox` confirmed a
    real installed package (`153.0.3-1.1`); `rpm -q firefox` confirmed
    plain `firefox` isn't a package name on this system at all — so the
    override is doing real work, not coincidentally matching a binary
    name.
  - **`gimp` and `fresh` both hit the same no-TTY-for-sudo limitation as
    every other distro/profile tested** — Greg ran
    `sudo zypper install -y gimp` and the `fresh` curl installer manually
    in a real terminal (a WezTerm split, copy-pasted via WezTerm's
    click-to-copy/`Ctrl+Shift+V` paste). Both confirmed installed
    afterward (`gimp-3.2.4-3.1`, `fresh-editor-0.4.7-1` with
    `/usr/bin/fresh` on PATH), and a second `glb restore new-to-linux`
    came back fully clean — every line "already installed"/"already
    linked", exit 0.
  - `libreoffice` and `vlc` were already present on this VM going in
    (`libreoffice-26.2.5.1-1.3`, `vlc-3.0.23-7.10`), so this run didn't
    add fresh-install signal for those two, only for `gimp`/`fresh`.
  - **Item 1 (verifying `new-to-linux`'s per-distro package overrides on
    real hardware) is now fully closed** — `firefox:zypper`,
    `libreoffice:pacman`, and `gh:pacman` are all confirmed on real
    hardware.
- **`new-to-linux`'s pacman-specific package overrides verified for real
  (2026-08-07, CachyOS VM — the same VM from the original 2026-08-05
  pacman cross-distro test).** Closes most of item 1 from the "next
  session, pick up here" list below. `glb info` detected `pacman`
  correctly. Ran a real `glb restore new-to-linux`:
  - **`libreoffice:pacman` → `libreoffice-fresh` confirmed correct** —
    the install log showed the resolved name explicitly
    (`Installing package: libreoffice (as libreoffice-fresh)`), and
    after Greg ran the printed manual command
    (`sudo pacman -S --noconfirm gimp libreoffice-fresh`),
    `pacman -Q libreoffice-fresh` confirmed `26.2.5-1.1` installed and
    a second `glb restore new-to-linux` came back fully clean
    (`already installed: libreoffice`), confirming the "already
    installed" detection also checks for the overridden name, not just
    the generic one.
  - **`gh:pacman` → `github-cli` confirmed correct** — verified via
    `glb_resolve_package_name "gh" "pacman"` (returns `github-cli`) plus
    `pacman -Si github-cli` (real package, `2.97.0-1.1` in
    `cachyos-extra-v3`). Not exercised through a full `developer`
    profile restore on this VM — the resolution logic and package
    existence were both independently confirmed, judged sufficient
    without a third profile switch on the same test box.
  - **Real, new finding: the `fresh` curl-installer behaves differently
    on Arch than on every other distro tested so far.** Instead of
    dropping a prebuilt binary, `getfresh.dev`'s install script detects
    Arch and builds `fresh-editor-bin` from source via `makepkg` (no AUR
    helper present), then does its own `sudo pacman -U` at the end. That
    final step needs its own sudo prompt, separate from and in addition
    to GLB's own package-install sudo gate. Ran for real after the
    lockout below cleared; confirmed installed (`fresh-editor-bin
    0.4.6-1`, `/usr/bin/fresh` on PATH) and a second restore reports
    `already installed: fresh` correctly.
  - **Real `pam_faillock` lockout mid-session — corrected 2026-08-08,
    now understood to be GLB-caused, not a config fluke or user error.**
    Three sudo attempts failed in a row (`journalctl _COMM=sudo` showed
    genuine `pam_unix(sudo:auth): auth could not identify password`
    failures), which tripped the default `pam_faillock` policy
    (`deny=3`, all settings in `/etc/security/faillock.conf` are
    commented/default, so `unlock_time=600`s applies) —
    `pam_faillock(sudo:auth): Consecutive login failures for user grego
    account temporarily locked`. **Correction (2026-08-08, per Greg):**
    this originally read as if waiting out the 10-minute window cleared
    it — that's wrong. A log out/log back in was actually required to
    regain sudo access, same as the EndeavourOS VM's incident below.
    Greg also originally assumed he'd mistyped the same password three
    times in a row (hence "root cause never conclusively identified"
    below) — also wrong. **Root cause is now confirmed** (see the
    EndeavourOS VM entry further up this file, 2026-08-08): GLB's own
    automatic sudo attempts during a sandboxed/no-TTY restore each
    trigger a real `pam_unix` auth-failure conversation, and by the 3rd
    one `pam_faillock`'s `deny=3` fires — entirely GLB's own doing, not
    a mistyped password. **This is the second confirmed occurrence of
    GLB's no-TTY sudo attempts locking Greg out of his own terminal**
    (first here on CachyOS 2026-08-07, second on the EndeavourOS VM
    2026-08-08) — no longer a one-off curiosity, a real recurring
    product gap. See the EndeavourOS entry for the concrete fix
    proposal (`sudo -n` instead of plain `sudo` at every sudo-gated call
    site, so a no-TTY attempt fails immediately instead of triggering a
    real failed-auth conversation that counts against `pam_faillock`).
  - Full bats suite (via a scratchpad-cloned `bats-core`, `bats` itself
    still not installed on this VM): 120/124 pass. The 4 failures are
    the exact same pre-existing, already-documented
    `fresh-editor`-genuinely-on-PATH test-isolation gap seen on the
    Pop!_OS VM and Linux Mint machine (`tests/dispatcher.bats`'s three
    real-profile end-to-end tests plus `tests/extras.bats`'s curl
    dry-run test all assume `fresh` isn't already installed) — now also
    true here since this session's own restore installed it for real.
    Not a regression; no code changed this session, this was a
    verification-only pass.
  - `libreoffice:pacman` and `gh:pacman` are now both confirmed (or
    code-confirmed) on real pacman hardware; `firefox:zypper` was
    confirmed separately the next day on the openSUSE VM (see entry
    above) — item 1 is now fully closed.
- **`profiles/server` verified with a real restore (2026-08-07, Pop!_OS
  test VM).** Same session as `profiles/developer`'s real verification
  and the backup-overwrite fix above — third profile restored for real
  on this VM (`default` -> `developer` -> `server`), so this run also
  exercised the just-fixed backup logic for real (switching from
  `default`'s dotfiles to `server`'s correctly created a fresh backup,
  no clobbering). `glb info` detected `apt` correctly. Most packages
  (git, curl, zsh, fish, fzf, eza, bat, zoxide, bash-completion, unzip,
  htop, ufw, rsync) were already present. `restic` and `fail2ban` hit
  the same no-TTY-for-sudo limitation as every other distro/profile
  tested — Greg ran `sudo apt install -y restic` and
  `sudo apt install -y fail2ban` manually, then a second
  `glb restore server` came back fully clean (`[SUCCESS] Profile
  applied: server`, every line "already installed"/"already linked" on
  the re-run). All four confirmed functional afterward: `restic 0.16.4`,
  `Fail2Ban v1.0.2`, `rsync 3.2.7`, `ufw 0.36.2-6` (`ufw status` itself
  needs root to query — unrelated to whether the package is installed,
  confirmed installed via `dpkg -s`).
  - **All five GLB profiles have now been restored for real on at least
    one machine** (`default` — many machines; `new-to-linux`,
    `developer`, `server` — this Pop!_OS VM). Every profile's package
    list and extras methods are now empirically confirmed working, not
    just bats-verified, at least on apt.
- **Real bug found and fixed (2026-08-07, Pop!_OS test VM): a second
  profile restore silently overwrote the `.glb-backup` from the first
  one, permanently destroying the true pre-GLB original config.**
  Surfaced while testing whether `glb restore --undo` could take this VM
  fully back to its state from before GLB ever ran — Greg's actual ask
  after restoring `developer` today. It couldn't: this VM's `default`
  restore (2026-08-06) correctly backed up the real stock Pop!_OS
  dotfiles to `*.glb-backup`. Restoring `developer` today (switching
  profiles for the first time ever tested back-to-back on one real
  machine) found those dotfiles already existing as `default`'s
  symlinks, and backed *them* up too — via a plain `mv "$dest"
  "$dest.glb-backup"` in `glb_apply_profile_dotfiles`
  (`lib/profile.sh`) with no check for whether `.glb-backup` already
  existed. `mv` to an existing target overwrites silently, so the
  Aug 6 backup (the real original) was destroyed and replaced with the
  Aug 7 intermediate (`default`'s symlink). Ran `glb restore --undo`
  afterward to confirm the actual, now-diminished behavior: it
  correctly swapped back to `default` (mechanically working as
  designed for one level of history) but **not** to true pre-GLB
  defaults, since that data no longer existed anywhere to restore from.
  - **Fix:** `glb_apply_profile_dotfiles` now checks for an existing
    `~/$rel.glb-backup` before touching `$dest`. If one already exists
    and `$dest` is a symlink (the normal case — just switching
    profiles, nothing new to preserve), it replaces the link directly
    and leaves the existing backup untouched. If one already exists and
    `$dest` is *not* a symlink (an unexpected/anomalous state — real
    data sitting where a backup already exists), it refuses and fails
    that file rather than silently destroying the backup, same
    fail-safe philosophy as `glb_undo_restore`'s existing "skip a
    hand-modified destination" case. Dry-run output updated to
    distinguish "would replace the link, backup untouched" from "would
    back up, then link" from the new refusal case.
  - 3 new bats tests in `tests/profile.bats`: switching profiles twice
    preserves the original backup unchanged, a real (non-symlink) file
    colliding with an existing backup is refused rather than
    overwritten, and the dry-run variant reports the right message.
    120/124 bats tests pass overall (the same 4 pre-existing,
    already-documented `fresh-editor`-on-PATH failures on this VM, see
    Testing section — confirmed unrelated to this fix).
  - **This VM's own pre-GLB baseline is unrecoverable** — the fix
    prevents this from happening to anyone else, but doesn't restore
    what's already lost here. Left this VM on `default` post-undo (Greg's
    call, since it's a test machine and the loss doesn't matter here).
- **`profiles/developer` verified with a real restore (2026-08-07, Pop!_OS
  test VM).** First genuinely real (non-sandboxed) `glb restore developer`
  anywhere — everything built the day before on the Dell laptop was only
  verified through stubbed bats until now. `glb info` detected `apt`
  correctly. Most packages (git, curl, zsh, fish, fzf, eza, bat, zoxide,
  htop, bash-completion, unzip, gcc, make, jq) were already present.
  `podman` and `gh` hit the same no-TTY-for-sudo limitation as every other
  distro tested — Greg ran `sudo apt install -y podman` and
  `sudo apt install -y gh` manually, then a second `glb restore developer`
  came back fully clean (`[SUCCESS] Profile applied: developer`, every
  line "already installed"/"already linked" on the re-run, confirming
  idempotency). Both binaries confirmed functional afterward: `podman
  version 4.9.3`, `gh version 2.45.0`.
  - **mise confirmed working for real** — first live verification of the
    curl-piped `https://mise.run` installer extras method (previously only
    stubbed in bats). Installed cleanly to `~/.local/bin/mise`
    (`2026.8.2`); the guarded `mise activate` blocks already present in
    `.bashrc`/`.zshrc`/`config.fish` from the Dell laptop session work as
    designed.
  - **fresh** — already installed on this VM going into the restore (same
    pre-existing-`fresh-editor` quirk already documented for this machine
    under "Real bug found... Pop!_OS test VM" further down).
  - **Nerd Font extras method also confirmed working for real** —
    downloaded, unzipped into `~/.local/share/fonts/jetbrains-mono-nerd-
    font/`, `fc-cache`'d, `fc-list` resolves it correctly.
  - **Real gap found, not a GLB bug:** `fc-list` showed a *second*,
    separate pre-existing Nerd Font directory already on this VM
    (`~/.local/share/fonts/JetBrainsMonoNerdFont/`, capitalized/no
    dashes, dated before this session) — meaning this machine wasn't
    actually a clean test of the font-gap fix; the font may already have
    been present by hand before GLB ran here. Worth knowing if this VM
    is reused for "fresh install" font-gap testing later — it isn't
    fresh with respect to fonts anymore.
- **`profiles/developer` and `profiles/server` built (2026-08-07, Dell
  laptop).** Next items in the agreed pick-up-here order after the
  Linux Mint session (see prior entry). Before picking packages,
  resolved the open design question flagged on 2026-08-06 (via
  `AskUserQuestion`): both profiles are for someone **newer to that
  role** who wants a complete kit without researching it themselves —
  same value prop as `new-to-linux`, not a rigid list for someone who
  already knows what they want. Three further forks confirmed the same
  way before building:
  - **Podman over Docker** (Developer) — daemonless/rootless is a safer
    default for a newcomer and fits GLB's philosophy better than
    Docker's more familiar name.
  - **mise over per-language version managers** (Developer) — one
    universal tool/mental model beats juggling nvm/pyenv/rustup
    separately for someone new to managing multiple runtimes. Installed
    via `extras.txt` (`curl`, official `https://mise.run` installer,
    matches the curl-pipe-sh pattern exactly) since no distro packages
    it. Needs shell activation to be useful, so — unlike `default`/
    `new-to-linux`, whose dotfiles are kept byte-identical on purpose —
    `profiles/developer`'s `.bashrc`/`.zshrc`/`config.fish` each got a
    small guarded `mise activate` block appended (same
    `if -x ~/.local/bin/mise` guard style as the existing Homebrew/
    zoxide blocks), a deliberate, targeted divergence rather than a
    wholesale prompt redesign.
  - **ufw over firewalld** (Server) — simpler allow/deny syntax reads
    more like English than firewalld's zone model, easier for a
    newcomer to reason about.
  - **restic over borgbackup** (Server, paired with `rsync`) — simpler
    single-binary CLI and repo model, easier starting point for someone
    new to backup strategy.
  - `profiles/developer/packages.txt`: git, curl, zsh, fish, fzf, eza,
    bat, zoxide, htop, bash-completion, unzip (shared shell foundation,
    same as `new-to-linux`) + podman, gcc, make, jq, gh.
    `extras.txt`: fresh (curl, same editor as `default`/`new-to-linux`),
    mise (curl), the Nerd Font (same `font` extra as every other
    profile, needed for `eza --icons`).
  - **Deliberately did not chase a `build-essential`-equivalent
    meta-package** across dnf's `Development Tools` group / pacman's
    `base-devel` group / zypper's `devel_basis` pattern — none of those
    resolve as a single `<mgr> install -y <name>`, which is all
    `glb_install_package` supports (no group-install syntax). Used
    plain `gcc`+`make` instead, which do resolve as ordinary packages
    everywhere. Revisit only if a real group-install mechanism gets
    built for some other reason.
  - `profiles/server/packages.txt`: git, curl, zsh, fish, fzf, eza, bat,
    zoxide, bash-completion, unzip (same shared foundation) + htop, ufw,
    rsync, restic, fail2ban. `extras.txt`: just the Nerd Font (no code
    editor — nano/vi are typically already on a server, wasn't
    brainstormed as a Server candidate either).
  - **Unattended security updates deliberately left out of v1** (was a
    brainstormed Server candidate) — apt's `unattended-upgrades` and
    dnf's `dnf-automatic` are real single packages, but pacman has no
    standard package at all (Arch's rolling-release model leans on
    manual/scripted updates instead) and zypper's story is a
    cron+script pattern, not a plain package. Doesn't fit the existing
    `<generic-name>:<package-manager>` override table since two of the
    four managers have nothing to map to — would need either a real
    per-distro opt-out mechanism or an extras.txt-style script install,
    neither of which exists yet. Flagged in both
    `profiles/server/packages.txt` and `docs/ROADMAP.md` rather than
    silently dropped.
  - **New override:** `gh:pacman` → `github-cli` in
    `_GLB_PACKAGE_OVERRIDES` (`lib/package.sh`) — Arch's official repo
    package for GitHub CLI is named differently from the `gh` binary.
    Like the `firefox:zypper`/`libreoffice:pacman` overrides added for
    `new-to-linux`, this is **not yet empirically verified** on real
    pacman hardware — same "confirm next time a pacman machine is
    tested" caveat. `gh` itself (apt/dnf/zypper, no override needed) is
    flagged in `packages.txt` as unverified too, since GitHub CLI only
    landed in Debian/Ubuntu's default repos fairly recently.
  - 2 new end-to-end bats tests in `tests/dispatcher.bats` (real
    restore of both actual profile directories, stubbed
    sudo/apt/starship/git/curl/sh/unzip/fc-cache, same pattern as the
    existing `default`/`new-to-linux` tests) — confirms packages
    resolve, extras install, dotfiles symlink correctly, and
    `.gitconfig`/ranger stay absent. All 121 bats tests pass (up from
    119 after the Mint session).
  - **Not done, deliberately, same boundary as Fresh/WezTerm/mise
    earlier:** no live `glb restore developer`/`glb restore server` was
    run for real on this laptop — verified entirely through the
    stubbed bats sandbox, never touching the real network or actually
    installing podman/gh/mise/ufw/restic/fail2ban. A real restore is
    something Greg would run himself in a real terminal.
  - Per the agreed next-steps order, item 1 (verifying `new-to-linux`'s
    `firefox:zypper`/`libreoffice:pacman` overrides on real hardware)
    was skipped for now since it needs a real zypper or Arch-family
    machine, not something buildable from the Dell laptop (apt). Still
    open — needs Greg to run it on the right hardware.
- **Real gaps found and fixed on the new Linux Mint test machine
  (2026-08-07).** First real `glb restore default` here surfaced a
  genuine, previously-masked gap: every machine tested before this one
  already had the Nerd Font pre-installed by hand, so nobody had
  noticed `glb restore` never actually installed it itself.
  - **Fix: new `font` method in `lib/extras.sh`/`extras.txt`.**
    Downloads a Nerd Fonts release zip, extracts it into
    `~/.local/share/fonts/<name>`, then runs `fc-cache -f`. Detection
    (`glb_extra_installed`) checks for any `.ttf`/`.otf` file in that
    directory rather than `command -v` (no binary to check) or
    `flatpak info` (not a Flatpak). Reuses the existing
    `glb_prompt_manual_step` pause/skip UX on failure, same as
    curl/flatpak. Added `unzip` to both profiles' `packages.txt`
    (needed by the new method, same pattern as `flatpak` being added
    for the WezTerm extras entry) and a `font jetbrains-mono-nerd-font
    <nerd-fonts-release-zip-url>` entry to **both** `default` and
    `new-to-linux`'s `extras.txt` — confirmed both profiles' dotfiles
    use `eza --icons` in all three shells, not just `default`'s
    WezTerm config, so both need it. 9 new bats tests in
    `tests/extras.bats` (detection, dry-run, real download+unzip via
    stubbed curl/unzip/fc-cache, pause/confirm, pause/skip); the two
    existing dispatcher end-to-end tests needed `unzip`/`fc-cache`
    stubs added too, since they restore the real profiles/extras.txt
    files which now include the font entry. Verified for real on this
    machine, not just in bats: `jetbrains-mono-nerd-font` downloaded,
    unzipped, `fc-cache`'d, and `fc-list`/`fc-match` both resolve
    "JetBrainsMono Nerd Font" to it correctly afterward.
  - **Real gotcha found verifying the fix, not fixed in code (a
    terminal-emulator/OS-level issue, not a GLB bug): gnome-terminal
    didn't pick up the newly-installed font at all**, even after
    setting its profile to the right font via `gsettings` and opening
    brand-new windows. Root cause: `gnome-terminal-server` is a single
    persistent background process shared across all windows/tabs (for
    performance); it built its Pango font cache once at startup,
    before the font existed on disk, and neither closing/reopening
    windows nor `fc-cache` retroactively refreshes an already-running
    process's font map. Fix (manual, one-time, not something `glb
    restore` should do): `pkill -f gnome-terminal-server`, then open a
    new window — confirmed this Claude Code session isn't itself
    running inside that process before killing it. Separately, the
    *regular* "Complete" Nerd Font variant rendered icons with broken
    spacing in gnome-terminal specifically (VTE's fixed-cell-width
    grid doesn't cope well with that variant's glyph metrics) — the
    Nerd Fonts project ships a `Mono` variant precisely for this;
    switching the gsettings profile font to "JetBrainsMono Nerd Font
    Mono" (combined with the server restart) fully fixed it. **Ruled
    out as a general GNOME Terminal limitation**, not just a config
    fix here: Greg independently tested the same font on a Fedora 44
    GNOME machine's gnome-terminal and icons rendered correctly there
    without needing the Mono variant — so this was specifically a
    stale-cache/VTE-version interaction on this Mint machine (GNOME
    Terminal 3.52.0 / VTE 0.76.0 via Ubuntu Noble's older package
    versions), not something inherent to gnome-terminal as an app.
    Confirmed fully working end-to-end afterward: `eza --icons`
    file-type icons render correctly in both gnome-terminal and
    WezTerm on this machine.
  - **Separate real bug found and fixed: `default`'s
    `.config/wezterm/wezterm.lua` had `window_decorations = "RESIZE"`**
    (resize border only, no title bar) — on Cinnamon/Muffin specifically,
    with no title bar to grab, the window couldn't be moved at all. Not
    machine-specific (it's the shared profile dotfile). Changed to
    `"TITLE | RESIZE"` (WezTerm's own default) to restore a draggable
    title bar. Confirmed working immediately since the dotfile is
    symlinked (no restore re-run needed) — just closing/reopening
    WezTerm picked it up.
  - **Linux Mint (apt) package result:** `neovim`/`ripgrep`/`fastfetch`
    all needed sudo (same no-TTY-in-sandbox limitation as every prior
    machine) — Greg ran them manually. `fastfetch` specifically **isn't
    in Mint's apt index at all** (same gap already known on Pop!_OS,
    now confirmed on Mint too) — apt aborts the *entire* transaction
    when one package name can't be resolved, so bundling it with
    `neovim ripgrep` in one manual command silently installed neither;
    had to split it into two commands. **Decided: not worth adding a
    fallback for** — Mint already ships `neofetch` preinstalled, which
    covers the same niche well enough there even though neofetch itself
    is archived/unmaintained upstream; this is a Mint-specific
    coincidence, not a reason to build real cross-distro fastfetch/
    neofetch fallback logic into GLB. `packages.txt`'s existing
    comment on the `fastfetch` line updated to note this.
  - **ranger confirmed working here too:** borders and letter-based
    git-status indicators both render correctly after `glb restore
    default`, matching every other machine tested so far.
  - Full bats suite: 116/119 passing. The 3 failures are the exact
    same pre-existing, already-documented gap as the Pop!_OS VM (see
    entry below) — this machine also now has `fresh-editor` genuinely
    installed for real (from this session's own restore), which a few
    tests don't isolate against. Confirmed via `git stash` to fail
    identically on unmodified `main`, unrelated to this session's
    changes. `bats` itself isn't installed on this machine either —
    ran via a locally cloned `bats-core` in the scratchpad, same
    workaround as the Pop!_OS VM.
- **Real bug found and fixed on the Pop!_OS test VM (2026-08-06):
  sudo-gated manual-step pause was silently broken whenever it fired
  from a real `packages.txt`/`extras.txt` run.** Greg ran
  `glb restore default` for real here (the first restore on this VM),
  saw the sudo password prompt for `zsh`, entered it correctly, but
  `zsh` still wasn't installed — he had to run the install manually
  himself outside of glb. Root cause: `glb_apply_profile_packages`
  (`lib/profile.sh`) and `glb_apply_profile_extras` (`lib/extras.sh`)
  each read their manifest file via `done < "$file"`, which rebinds
  stdin (fd 0) for the *entire loop body* to that file. When a package
  install fails and falls through to `glb_prompt_manual_step`'s
  interactive `read -p "Press Enter once it's done..."`
  (`lib/package.sh`), that read inherited the loop's stdin — so instead
  of waiting on the real terminal, it silently consumed the **next
  line of the manifest** as if it were the user's answer. Concretely:
  packages.txt was `zsh`, `tmux`, ...; when `zsh` failed, the pause
  "read" `tmux` off the file, decided that wasn't `s`/`S` (dry-run
  packages.txt reading loop assumed input already, sudo password
  entry succeeded fine since sudo reads `/dev/tty` directly), so it
  logged zsh as still-not-installed and moved on — and because the
  outer loop's next `read` was now positioned past `tmux` in the same
  file stream, `tmux` itself was silently consumed and never
  processed at all, not even attempted.
  - **Never caught by the existing bats suite** because
    `tests/profile.bats` stubs `glb_install_package` entirely (never
    calls the real `glb_prompt_manual_step`), and `tests/extras.bats`,
    while using the real `glb_install_extra`, never drove it through
    the full `glb_apply_profile_extras` loop with a real multi-line
    manifest and a failing entry.
  - **Fix:** both loops now read their manifest on fd 3
    (`done 3< "$file"`, `read -r line <&3`) instead of stdin, leaving
    real stdin free for `glb_prompt_manual_step`'s interactive read.
  - Added regression tests in both `tests/profile.bats` and
    `tests/extras.bats` using the real (unstubbed) install path
    through a `run bash -c "..."` subshell — a two-line manifest where
    the first entry fails and pauses, confirming the manual step reads
    real stdin (not the manifest) and that the second manifest entry
    still gets processed afterward. 113 total tests, all passing.
  - **Separately noticed while testing, not fixed:** this VM already
    has `fresh-editor` installed at `/usr/bin/fresh` (unclear why —
    predates this session), which makes 3 pre-existing tests
    (`tests/extras.bats`'s curl dry-run test, `tests/dispatcher.bats`'s
    two real-profile end-to-end restores) fail here specifically,
    since they assume `fresh` isn't already on PATH. Confirmed via
    `git stash` that these fail identically on unmodified `main`, so
    it's a pre-existing environment-specific test-isolation gap, not
    something the stdin fix touched. Not fixed — flagged for whenever
    it's worth tightening those tests' PATH isolation.
  - `bats` itself isn't installed on this VM and couldn't be via
    `sudo apt install` from the sandboxed shell (no TTY) — ran the
    suite via a locally cloned `bats-core` (no install needed) instead.
- **Next session: pick up here, in this order (agreed 2026-08-06,
  updated 2026-08-07).** All four items from the prior session-wrap-up
  brainstorm just below (rollback/undo, dry-run, interactive profile
  picker, shell completions) are done, plus a follow-up resyncing
  `new-to-linux`'s prompt dotfiles to match `default`, plus (as of
  2026-08-07) item 2 below — Developer/Server profiles, plus (also
  2026-08-07) item 1 below is now fully closed too:
  1. **Verify `new-to-linux`'s per-distro package overrides on real
     hardware — done (2026-08-07: pacman on the CachyOS VM, zypper on
     the openSUSE VM).** `libreoffice:pacman` → `libreoffice-fresh` and
     `gh:pacman` → `github-cli` are confirmed on real pacman
     hardware; `firefox:zypper` → `MozillaFirefox` is confirmed on real
     zypper hardware — see the two Roadmap entries above for the full
     verification of each (real restores, real installs, resolved-name
     checks, clean idempotent re-runs).
  2. **Developer/Server profiles — done (2026-08-07, Dell laptop).**
     See the Roadmap entry below for the full build (packages picked,
     forks resolved via `AskUserQuestion`, dotfiles, extras, new
     `gh:pacman` override, bats coverage). Design question resolved:
     both are for someone newer to that role, not someone who already
     knows what they want.
  3. **Original Version 0.5 items — done (2026-08-07, openSUSE VM):
     express installation, guided configuration wizard, configuration
     summary, progress reporting.** Turned out to collapse into one
     small feature: see `docs/design/guided-wizard.md` and the Roadmap
     entry above for the full build. **Version 0.5 has no planned
     items left.**
  4. **Version 0.6 — Configuration Management: installation
     manifests, configuration export/import, repairing existing
     installations, updating installed components.**
     `docs/design/state-export-import.md`'s configuration export/import
     plan is **fully done (2026-08-07, openSUSE VM)** — `glb export`,
     `glb diff`, and `glb restore --from-snapshot <name>`. Repairing
     existing installations is **also done (2026-08-07, same VM, same
     session)** — `glb repair <profile>`, see `docs/design/repair.md`.
     Updating installed components is **scoped but not yet built
     (2026-08-07, same VM, same session)** — see
     `docs/design/update-components.md` and the Roadmap entry above;
     next session, this can go straight to building it, same as the
     wizard and repair did the same day they were scoped. Still
     genuinely unscoped: installation manifests, the only item left in
     this version with no plan written yet.
- **Session wrap-up brainstorm, agreed as real priorities (2026-08-06),
  not yet built — pick up here next session.** End-of-session
  discussion: what would a user *other than Greg* appreciate, without
  over-complicating GLB or the end-user experience. Four items, all
  confirmed as agreed direction (added to `docs/ROADMAP.md` Version
  0.5, three of them new additions to that version's original list):
  1. **Rollback/undo** (highest value for the effort) — a
     `glb restore --undo`-style command that restores from the
     `.glb-backup` files `glb_apply_profile_dotfiles`
     (`lib/profile.sh`) already creates on every restore. The backup
     mechanism already exists; this is "just" a command that walks
     `$HOME` looking for `*.glb-backup` and reverses the symlink swap.
     Turns "I hope this works" into "I can experiment risk-free" for
     someone trying GLB for the first time — the single best
     trust-building addition relative to how little new mechanism it
     needs.
  2. **Dry-run/preview** — `glb restore <profile> --dry-run` prints
     what packages would install, what extras would run, what
     dotfiles would be symlinked/backed up, without doing any of it.
     Was already on the roadmap as "Installation preview"; elevated in
     priority specifically for the "stranger trying this for the first
     time" reason. Threads a flag through `glb_apply_profile_packages`/
     `glb_apply_profile_extras`/`glb_apply_profile_dotfiles`
     (`lib/profile.sh`, `lib/extras.sh`) rather than needing new
     mechanism.
  3. **Interactive profile picker** — `glb restore` with no profile
     argument lists profiles (`glb_list_profiles`, `lib/profile.sh`)
     and lets the user pick one, reusing the numbered-menu pattern
     `glb_configure_starship` (`lib/prompt.sh`) already has for
     Starship presets. Helps someone who doesn't know `default` vs
     `new-to-linux` is the one meant for them without reading docs.
  4. **Shell completions for `glb` itself** (bash/zsh/fish) — smallest
     of the four, standard polish expected of a finished CLI tool.
  - **Item 1 done (2026-08-06): `glb restore --undo` built and tested.**
    `glb_undo_restore` (`lib/profile.sh`) walks `$HOME` for
    `*.glb-backup` files and swaps each one back into place, removing
    the symlink `glb_apply_profile_dotfiles` created. If a destination
    is no longer a symlink (edited by hand since the restore), it's
    skipped with a warning rather than clobbered — the backup is left
    in place for the user to resolve manually. Wired up as `glb restore
    --undo` in the dispatcher (`glb`), not a separate top-level
    command, matching the roadmap's original naming. 12 new bats tests
    (7 unit-level in `tests/profile.bats`, 2 dispatcher end-to-end in
    `tests/dispatcher.bats`, all 77 total passing) cover: flat and
    nested restores, restoring multiple backups in one pass, the
    no-backups-found case, skipping a hand-modified destination,
    restoring when the symlink was already manually removed, and
    idempotency (running it twice is a safe no-op the second time).
    Verified end-to-end against a real (sandboxed) restore + undo
    round-trip, not just the unit tests.
  - **Item 2 done (2026-08-06): `glb restore <profile> --dry-run`
    built and tested.** Threaded a `dry_run` parameter (the literal
    string `"--dry-run"` or empty) through
    `glb_apply_profile_packages`/`glb_apply_profile_extras`/
    `glb_apply_profile_dotfiles` (`lib/profile.sh`, `lib/extras.sh`)
    and `glb_install_starship`/`glb_install_zsh_plugins`
    (`lib/prompt.sh`, `lib/plugins.sh`) — exactly the "thread a flag
    through existing logic" approach the roadmap called for, no new
    mechanism. Each already-installed check stays real (read-only:
    `dpkg -s`, `flatpak info`, `command -v`, symlink comparison); only
    the actual install/link/backup calls are skipped and replaced with
    a "Would ..." log line. The dotfiles function's "already linked"
    check was reordered ahead of directory creation so dry-run can
    bail out before any real `mkdir`. Dispatcher parses `--dry-run`
    anywhere after `restore` (before or after the profile name), same
    pattern as `--undo`. 21 new bats tests across `tests/profile.bats`,
    `tests/extras.bats`, and two new files — `tests/prompt.bats` and
    `tests/plugins.bats`, neither module had dedicated tests before —
    plus 2 dispatcher end-to-end tests; 94 total passing.
    - **Found and fixed a real latent bug along the way:**
      `declare -A _GLB_ZSH_PLUGINS` in `lib/plugins.sh` (and
      `_GLB_PACKAGE_OVERRIDES` in `lib/package.sh`) becomes
      **function-scoped, not global**, when sourced from inside a bash
      function — which is exactly what bats' `setup()` is. The array
      would silently vanish before the test body ran, making every
      plugin-related assertion fail with empty output. Fixed by adding
      `-g` to both `declare -A` calls. Zero behavior change for the
      real `glb` script (already sourced at top level there, so
      already effectively global) — this was purely a test-sourcing
      footgun, but a real one worth knowing about if either array is
      ever touched again.
    - Verified end-to-end in a sandbox with `sudo`/`apt`/`dpkg`/
      `flatpak`/`starship`/`curl`/`sh`/`git` **all stubbed to exit 1**
      (deliberately hostile, so anything actually invoked would be
      loud and obvious) against the real `default` profile: every
      package/extra/starship/plugin/dotfile line printed correctly,
      exit code 0, and confirmed zero real side effects (no symlinks,
      no `.local` plugins dir, `.bashrc` untouched).
    - This sandboxed-verification discipline is itself a direct fix
      for a mistake earlier the same session: an unstubbed manual
      "smoke test" of the undo feature accidentally ran a real
      `flatpak install --system` for `default`'s WezTerm extra,
      triggering a genuine PolicyKit password prompt Greg had to
      answer for real. See the "no real restore on laptop" memory —
      this is why every verification after that point stubs the
      package manager and flatpak explicitly rather than trusting a
      sandboxed `$HOME` alone.
  - **Item 3 done (2026-08-06): interactive profile picker built and
    tested.** `glb_restore_interactive` (`lib/profile.sh`) is called
    by the dispatcher (`glb`) only when `restore` gets no profile
    name — it scans `$GLB_ROOT/profiles/*/` (same glob
    `glb_list_profiles` already uses), prints a numbered menu, reads
    one line, and applies whichever profile was chosen via the normal
    `glb_apply_profile`, `--dry-run` included. Deliberately did *not*
    change `glb_apply_profile`'s own default-to-`default` behavior —
    that stays for any direct/scripted caller (and the existing test
    asserting it); only the dispatcher treats a truly-empty profile
    argument as "show the picker" instead of "assume default". Invalid
    input (out-of-range number, non-numeric) errors cleanly rather
    than guessing. 8 new bats tests (6 unit-level in
    `tests/profile.bats`, 2 dispatcher end-to-end in
    `tests/dispatcher.bats`; 102 total passing) cover: listing and
    applying the chosen profile by number, `--dry-run` passthrough, an
    out-of-range choice, non-numeric input, no profiles present, and a
    missing profiles directory entirely. Verified end-to-end in the
    same fully-stubbed-hostile sandbox pattern used for the dry-run
    work (sudo/apt/dpkg/flatpak/starship/curl/sh/git all exit 1),
    against the real `default`/`new-to-linux` profiles: menu renders
    correctly, dry-run preview of the chosen profile works, invalid
    choice errors without crashing.
  - **Item 4 done (2026-08-06): shell completions built and tested —
    all four session-wrap-up priorities now complete.** New
    `completions/` directory at repo root (not per-profile, since
    completions are a property of `glb` itself): `glb.bash`, `_glb`
    (zsh), `glb.fish`. New `lib/completions.sh` with
    `glb_install_self_symlink` and `glb_install_completions`, both
    wired into `glb_apply_profile` alongside the existing
    starship/zsh-plugins steps (dry-run included, via the same shared
    `_glb_link_with_backup` helper both functions use).
    - **Real prerequisite this exposed: nothing previously put `glb`
      on `PATH`.** Confirmed with Greg before building
      (`AskUserQuestion`) rather than assuming — he chose to add it.
      `glb_install_self_symlink` symlinks the repo's `glb` script into
      `~/.local/bin/glb`; `.bashrc`/`.zshrc` (both profiles now, not
      just `default`) gained a `~/.local/bin` `PATH` export to match
      what `config.fish` already had via `fish_add_path`.
    - **zsh had no completion system initialized at all** (no
      `compinit` anywhere — Oh My Zsh used to handle this, nothing
      replaced it when it was removed). Added `fpath`+`compinit` to
      `.zshrc` (both profiles), pointing `fpath` at
      `~/.local/share/zsh/completions` where the `_glb` file gets
      symlinked.
    - `bash-completion` added to both profiles' `packages.txt` — the
      dotfiles already conditionally sourced it, but nothing had
      guaranteed it was actually installed.
    - **Two real bugs found and fixed via end-to-end testing, not
      caught by the unit tests alone:**
      1. `GLB_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"`
         (`glb`, top of file) doesn't resolve symlinks —
         `${BASH_SOURCE[0]}` when invoked via the new
         `~/.local/bin/glb` symlink is the symlink's own path, so
         `GLB_ROOT` resolved to `~/.local/bin` instead of the real
         repo, breaking every `source "$GLB_ROOT/lib/*.sh"` call.
         Fixed with `readlink -f` before `dirname`. Found by actually
         restoring in a sandbox, adding the symlink to `PATH`, and
         running `glb version` through it — not something a unit test
         sourcing `lib/*.sh` directly would ever exercise.
      2. The bash/zsh completion scripts' dynamic profile-name lookup
         parsed `glb profiles` output with `awk 'NR>3 && NF'`, assuming
         a fixed number of header lines to skip — but every `glb`
         invocation prints a 6-line banner first
         (`glb_show_banner`/`lib/banner.sh`), so real output actually
         had banner text (`"Version ============"`, etc.) leaking into
         the completion candidates. Fixed by matching structurally
         instead of counting lines: `awk 'NF==1 && /^[[:space:]]/'`
         picks out only single-token indented lines (exactly how
         `glb_list_profiles` formats each name), which no banner or
         header line matches regardless of how long the banner ever
         gets. Fish's completion used a regex (`^\s+(\S+)$`) that was
         already structurally correct from the start — only bash/zsh's
         line-counting approach was wrong. Found by literally sourcing
         the installed completion file in a real `bash -c` and a real
         `fish -c 'complete -C...'` and checking the actual candidate
         list, not just a syntax check.
    - 9 new bats tests in `tests/completions.bats` (self-symlink and
      completions: fresh install, already-linked, backup-existing,
      dry-run for both, permission-failure reporting) plus updated
      `tests/test_helper.bash` to copy the new `completions/`
      directory into the sandbox; 111 total passing.
    - At the time, deliberately did **not** resync `new-to-linux`'s
      still-old unified-prompt dotfiles (the `GLB_SHELL`/starship-for-
      bash setup predating this session's prompt differentiation work)
      — only added the `PATH`/`compinit` lines needed for completions,
      to stay scoped to what was actually asked for that round.
      **Resynced right after, as an explicit follow-up (2026-08-06):**
      Greg asked for recommended next steps once all four priorities
      landed; this was the top pick — a small, already-scoped, already-
      tested gap versus the other open items (per-distro override
      verification needs real hardware Greg would have to run; the
      Developer/Server profiles need a design decision made first; the
      rest of Version 0.5/0.6 aren't concretely scoped yet). Since
      `.bashrc`/`.zshrc`/`config.fish`/`starship.toml` are meant to be
      byte-for-byte the same "standard" shell/prompt setup regardless
      of profile (no `new-to-linux`-specific customization in any of
      them — confirmed via `diff` before touching anything, the only
      differences were the stale prompt sections plus the dead
      `editstarship`/`editconfig` aliases), copied all four files from
      `default` over `new-to-linux` wholesale rather than hand-patching
      — simpler and less error-prone than re-deriving the same edits.
      All 111 bats tests still pass unchanged (none assert
      profile-specific prompt content). Verified end-to-end in the
      same fully-stubbed sandbox pattern: real `new-to-linux` restore,
      `--dry-run` and for-real, confirms all four dotfiles link
      correctly and zero `GLB_SHELL` references remain anywhere.
      `new-to-linux` and `default` now share the exact same shell/
      prompt setup, matching how `new-to-linux` was originally
      described when built ("same unified bash/zsh/fish + Starship
      setup as the default profile").
  - **Considered and deliberately rejected** as over-complicating GLB
    for its actual scope: templating (different values per machine),
    encrypted secrets, a plugin system — the kind of thing chezmoi/
    dotbot offer. Doesn't fit "curate, don't reinvent."
  - **Reference point, not a model to port:** DHH's *Omakub* is doing
    something similar in spirit (curated, opinionated fresh-Ubuntu
    setup, interactive TUI menu, one confident choice per category —
    close to what `new-to-linux` already does) and has had a lot of
    public feedback on this exact "what does a stranger want" question.
    It's Ruby-based, so nothing to port directly given GLB's
    intentional Bash-only constraint — just worth a look for
    inspiration if picking this back up.
- **Sudo-gated install pause/resume built (2026-08-06):** `glb_install_package`
  (`lib/package.sh`) now catches a failed install and pauses via a new
  `glb_prompt_manual_step` helper — prints the exact resolved command
  (e.g. `sudo apt install -y fresh`) and waits on stdin for Enter
  (continue, rechecking via `glb_package_installed`) or `s` (skip). If
  stdin has nothing to give (EOF, no interactive input available at
  all), it doesn't hang — treats that the same as skip. This is the
  roadmap item recorded earlier today after cross-distro testing kept
  hitting manual sudo installs; closes it out. Scoped to installs only
  (not `remove`/`update`) since that's what testing actually surfaced.
  5 new tests in `tests/package.bats` cover pause-then-confirm,
  pause-then-skip, no-input-available, and the post-manual-step
  recheck.
- **bats test suite actually run for the first time on this laptop
  (2026-08-06):** installed via `sudo apt install -y bats` (Greg ran it
  manually — same sudo/TTY limitation as everything else). First run
  surfaced a real pre-existing gap: `tests/profile.bats`'s `setup()`
  only stubbed `glb_package_installed`/`glb_install_package`, not
  `glb_install_starship`/`glb_install_zsh_plugins` (also called
  unconditionally by `glb_apply_profile`) — two tests were crashing on
  "command not found", a third silently passed for the wrong reason.
  Fixed by stubbing those too, same isolation pattern as the existing
  ones. Also added: coverage for the new `firefox:zypper`/
  `libreoffice:pacman` overrides, and a `dispatcher.bats` test that
  copies the *real* `profiles/new-to-linux` directory (not a synthetic
  fixture) into the sandbox and restores it end-to-end, checking the
  right dotfiles land and `.gitconfig`/ranger are correctly absent.
  All 55 tests pass as of this note.
- **`profiles/new-to-linux` built (2026-08-06):** the first profile
  beyond `default`, picked as the next multi-profile step since
  `docs/ROADMAP.md` flags it as highest-leverage — a different value
  prop from the rest of GLB ("here's what's good" vs. "restore my exact
  setup") for someone switching from Windows/macOS. Confirmed with
  Greg: Firefox (browser), **Fresh** (`getfresh.dev` — a Rust terminal
  IDE, GPL-2.0) for code editor, LibreOffice, GIMP, VLC — plus the same
  unified bash/zsh/fish + Starship + `GLB_SHELL` shell setup as
  `default` (Greg's choice: not app-only). Fresh has no native
  apt/dnf/pacman/zypper package (curl script/AUR/`.deb`/Flatpak/cargo/
  npm only) — originally listed aspirationally in `packages.txt`
  (would silently fail), moved to `extras.txt` on 2026-08-06 once the
  non-package-manager install mechanism was built (see Roadmap), where
  it now actually installs.
  Notably `default`'s dotfiles already had unused `editbash`/
  `editstarship` aliases checking for `fresh-editor`/`fresh` on `$PATH`
  before this — the pick lines up with groundwork already in place.
  Dotfiles reused from `default` as-is (`.bashrc`, `.zshrc`,
  `.config/fish/config.fish`, `.config/starship.toml`) but *excluding*
  `.gitconfig` (Greg's personal git identity — wrong to ship to someone
  else's restore) and `ranger`/WezTerm config (paired with packages not
  in this profile). Added two `_GLB_PACKAGE_OVERRIDES` entries in
  `lib/package.sh`: `firefox:zypper` → `MozillaFirefox`,
  `libreoffice:pacman` → `libreoffice-fresh` — both well-known distro
  conventions but **unverified empirically** (unlike every other
  override, which was confirmed via real per-distro testing); flag for
  verification next time a zypper or pacman restore is tested.
  - **Fixed (2026-08-06):** the `update`/`install`/`remove`/`search`
    aliases in all three shells (`.bashrc`, `.zshrc`, `config.fish`)
    were hardcoded to `apt` (comment header even said "Pop!_OS / Ubuntu
    / Debian") with no dnf/pacman/zypper branch — a pre-existing gap in
    `default`, already shipped as-is to the Fedora/CachyOS/openSUSE
    test VMs during cross-distro testing (which checked package
    installs and symlinks, never exercised these aliases), and
    duplicated into `new-to-linux` when that profile was built. Now
    auto-detects apt/dnf/pacman/zypper via `command -v`/`command -q`
    (same detection order as `lib/package.sh`) in all three shells and
    both profiles. Verified apt still resolves correctly post-fix on
    this machine (bash, zsh, fish) — behavior on dnf/pacman/zypper
    machines not yet re-verified live, same "confirm empirically" caveat
    as the new `firefox`/`libreoffice` overrides above.
  - **Superseded (2026-08-09):** Firefox/LibreOffice/GIMP/VLC were
    removed from `new-to-linux` entirely — GLB no longer installs GUI
    applications at all. See the "Removed entirely" Roadmap entry under
    the WezTerm history further up this file for the full reasoning.
    `new-to-linux` is now just the shared shell/prompt setup plus Fresh.
- **New roadmap item (agreed 2026-08-06): pause/resume for sudo-gated
  installs.** Across every distro tested in cross-distro testing, at
  least one package needed a manual `sudo install` because the testing
  shell had no TTY for the password prompt — Greg had to switch to a
  real terminal each time. That was a testing-environment limitation,
  not a GLB bug, but Greg pointed out the real product gap it exposes:
  a real user hitting *any* sudo prompt GLB can't satisfy (password
  needed, package held back, etc.) currently has no graceful path — the
  restore should be able to pause with a clear "run this yourself, then
  press enter to continue" instead of just failing. Greg was explicit
  this wasn't a real inconvenience during testing itself — Claude handed
  him one copy-paste command each time, and all he had to do was paste
  it, enter his password, and press enter — so the ask isn't to eliminate
  that step, just to make sure the real `glb restore` flow degrades to
  something equally low-effort (stop, show the exact command, wait for
  enter) if the sudo step genuinely can't be automated, rather than
  failing outright. Added to `docs/ROADMAP.md` under Version 0.2
  (Installation Engine), alongside the existing "Error recovery" item.
  Not started — captured as a roadmap item only.
- **Debian (apt) result (2026-08-06, tested via Claude Code on Greg's real
  Debian 13 machine, the one linked to GitHub — a genuine daily-driver
  restore, not a throwaway VM):** `glb info` detected `apt` correctly.
  `git`, `zsh`, `fish`, `curl`, `fzf`, `eza`, `zoxide`, `ranger`,
  `fastfetch` were already present; `bat` was too, installed as `batcat`
  (Debian's package-name convention) — confirmed the dotfiles' existing
  `command -v batcat` fallback (present in `.bashrc`/`.zshrc`/
  `config.fish`) already handles this correctly, no gap. **No apt
  `_GLB_PACKAGE_OVERRIDES` gaps found**, closing out the last untested
  package manager (apt itself was only previously validated via Pop!_OS/
  Zorin VMs, not Debian directly). `tmux`, `neovim`, `ripgrep` were
  missing — same sandboxed-shell-has-no-TTY-for-sudo limitation as every
  other distro, Greg ran `sudo apt install -y tmux neovim ripgrep`
  directly. Dotfiles + plugin restore path passed cleanly: all 7
  dotfiles backed up to `*.glb-backup` and symlinked, Starship (already
  present) and both zsh plugins installed fine. **Confirmed:** Greg ran
  the sudo install manually and all three came up cleanly — `tmux 3.5a`,
  `nvim 0.10.4`, `ripgrep 14.1.1`. `packages.txt` is fully covered on
  apt/Debian with zero overrides needed. **All five
  GLB-supported/tested package managers (apt, dnf, pacman, zypper, plus
  apt again here on real hardware) are now confirmed clean end-to-end.**
- **Next priority (agreed 2026-08-06, after cross-distro testing wrapped
  up): multi-profile support.** Greg agreed this is the next area of
  focus — see the "Support multiple named profiles" bullet further down
  for the reasoning (it's the prerequisite for the "New to Linux"
  profile, called out there as probably the highest-leverage way to
  make GLB useful to people beyond Greg). Not started yet as of this
  note — pick up here.
- **Done (2026-08-05 to 2026-08-06): Greg cross-distro tested `glb
  restore default` on his ~10 VirtualBox VMs, then personally reviewed
  the full terminal output and signed off — "we're good to go."** All
  four GLB-supported package managers are now confirmed clean
  end-to-end: apt (Debian-family — Pop!_OS/Zorin, previously
  validated), dnf (Fedora), pacman (Arch-family — CachyOS), and zypper
  (openSUSE). Tested both existing VMs (may already have some tools
  manually installed, masking gaps) and fresh-install signal (missing
  tools that genuinely needed installing). Goal was finding real gaps
  in `_GLB_PACKAGE_OVERRIDES` (`lib/package.sh`) — which started with
  only one entry (`fd` → `fd-find` on apt) — for `eza`, `bat`,
  `zoxide`, `fastfetch`, `fish`, etc. across dnf/pacman/zypper.
  **Zero gaps found on any of them** — every name in
  `profiles/default/packages.txt` matches the real package name on
  every tested distro/package manager. The only recurring friction was
  sudo-gated installs (`zsh`/`neovim` on Fedora, `tmux`/`neovim` on
  CachyOS, `tmux`/`neovim`/`ripgrep` on openSUSE) that Greg had to run
  manually in a real terminal, since the sandboxed Claude Code shell
  has no TTY for a sudo password prompt — an environment limitation of
  testing this way, not a GLB bug. Mint (apt-based, lowest priority)
  was never separately tested but didn't need to be — apt was already
  validated via Pop!_OS/Zorin. Full per-distro results below.
  **This cross-distro testing effort is complete.**
  - **Fedora 44 (dnf) result (2026-08-05, tested via Claude Code on a
    Fedora Workstation test VM, confirmed a throwaway machine — not a
    real install):** `glb info` detected `dnf` correctly. This was an
    *existing* VM, so most of `packages.txt` was already present:
    `git`, `fish`, `tmux`, `curl`, `ripgrep`, `fzf`, `eza`, `bat`,
    `zoxide`, `ranger`, `fastfetch` were all already installed. `zsh`
    and `neovim` were missing, so this test did cover real fresh-install
    signal for those two. **No dnf `_GLB_PACKAGE_OVERRIDES` gaps
    found** — every package name in `packages.txt` matches the real dnf
    package name, confirmed via `dnf info`'s "From repository" field to
    come from the official `fedora`/`updates` repos specifically (not
    the Terra/RPM Fusion/COPR third-party repos this VM happened to have
    enabled — important since a fresh Fedora install wouldn't have
    those). As with CachyOS, the sandboxed Claude Code shell has no TTY
    for the sudo password prompt, so `sudo dnf install -y zsh neovim`
    couldn't be run end-to-end from within the session — Greg ran it
    directly in a real terminal on the VM instead, and both installed
    cleanly (`zsh-5.9-21.fc44`, `neovim-0.12.4-3.fc44`, verified via
    `rpm -q` and `command -v zsh nvim`). Dotfiles + plugin restore path
    also passed cleanly: `~/.bashrc`, `~/.config/fish/config.fish`,
    `~/.config/starship.toml` were correctly backed up to
    `*.glb-backup` and all 7 dotfiles symlinked (including
    `.config/ranger/rc.conf` and `.config/wezterm/wezterm.lua`);
    Starship (already present) plus both zsh plugins installed fine.
    **`packages.txt` is fully covered on dnf/Fedora with zero overrides
    needed**, same conclusion as pacman/CachyOS.
  - **CachyOS (pacman) result (2026-08-05, tested via Claude Code in a
    sandboxed shell on a CachyOS test VM):** `glb info` detected `pacman`
    correctly. This was an *existing* VM (not fresh), so most of
    `packages.txt` was already installed and the test mostly confirms
    the dotfiles/plugin path rather than fresh-repo package availability:
    `git`, `zsh`, `fish`, `curl`, `ripgrep`, `fzf`, `eza`, `bat`,
    `zoxide`, `fastfetch`, `ranger` were all already present (ranger's
    presence here is in fact what prompted adding it to `packages.txt`
    — see the ranger bullet below). **No pacman
    `_GLB_PACKAGE_OVERRIDES` gaps found** — none of the tested names
    needed a pacman-specific override. `tmux` and `neovim` were not yet
    installed; both are valid, unambiguous pacman package names (no
    override needed), but the actual `sudo pacman -S` install couldn't
    be verified end-to-end because the sandboxed shell has no TTY for
    the sudo password prompt (`sudo: a terminal is required...`) and its
    sudo timestamp cache doesn't share with a real terminal session
    either — an environment limitation of testing via Claude Code, not a
    GLB bug. Dotfiles + plugins path worked cleanly: `~/.bashrc`,
    `~/.config/fish/config.fish`, `~/.config/starship.toml`, `~/.zshrc`
    were all correctly backed up to `*.glb-backup` and symlinked;
    Starship, `zsh-autosuggestions`, `zsh-syntax-highlighting` all
    installed fine. Separately noted: `/etc/os-release` on CachyOS (a
    rolling release) has no `VERSION_ID`, so `glb info` shows a blank
    Version field — cosmetic, `glb_detect_version` isn't relied on
    anywhere for logic, not worth fixing unless it starts to matter.
    **Confirmed:** Greg ran `sudo pacman -S --noconfirm tmux neovim`
    directly in a real terminal on the VM, and both installed cleanly
    (`tmux 3.7_b-1.1`, `neovim 0.12.4-1.1`, verified via `pacman -Q`) —
    so `packages.txt` is fully covered on pacman/CachyOS with zero
    overrides needed.
  - Mid-testing, CachyOS (rolling release) pushed a major system upgrade
    on its own. Greg waited for it to finish and re-ran a test
    afterward — nothing broke, `glb restore default` still worked fine
    post-upgrade. Not a rigorous regression test, just a good sign that
    GLB doesn't depend on anything fragile enough to be upset by a
    rolling-release update.
  - Also on that CachyOS VM (2026-08-05, Greg's own notes, not part of
    the GLB restore test itself): Claude Desktop installed easily —
    Greg's preferred way to work over the web UI. Unrelated to GLB
    functionality, noted for context only.
  - **openSUSE Tumbleweed (zypper) result (2026-08-06, tested via Claude
    Code running directly on the openSUSE VM itself — this session's own
    machine, not inspected remotely):** `glb info` detected `zypper`
    correctly and reported the distro as `opensuse-tumbleweed`. This was
    an *existing* VM, so most of `packages.txt` was already present:
    `git`, `zsh`, `fish`, `curl`, `fzf`, `eza`, `bat`, `zoxide`, `ranger`,
    `fastfetch` were all already installed. `tmux`, `neovim`, and
    `ripgrep` were missing, so this test covered real fresh-install
    signal for those three. **No zypper `_GLB_PACKAGE_OVERRIDES` gaps
    found** — every name in `packages.txt` matches the real zypper/RPM
    package name exactly, confirmed via `zypper info`. As with
    CachyOS/Fedora, the sandboxed Claude Code shell has no TTY for the
    sudo password prompt, so `sudo zypper install -y tmux neovim
    ripgrep` couldn't be run end-to-end from within the session — Greg
    needs to run it directly in a real terminal on the VM. One false
    alarm caught and ruled out mid-test: `rg` initially looked like it
    resolved to an installed binary, but turned out to be a shell
    function Claude Code itself injects into the session (a wrapper
    around its own ripgrep tool) — `rpm -q ripgrep` confirmed ripgrep is
    genuinely not installed, not a GLB bug. Dotfiles + plugin restore
    path passed cleanly: all 7 dotfiles (`.bashrc`, `.zshrc`,
    `.gitconfig`, `.config/fish/config.fish`, `.config/starship.toml`,
    `.config/ranger/rc.conf`, `.config/wezterm/wezterm.lua`) were
    correctly backed up to `*.glb-backup` and symlinked; Starship
    (already present) and both zsh plugins installed fine.
    **`packages.txt` is fully covered on zypper/openSUSE with zero
    overrides needed**, same conclusion as dnf/Fedora and pacman/CachyOS.
    **Confirmed:** Greg ran `sudo zypper install -y tmux neovim ripgrep`
    directly in a real terminal on the VM; despite some install-time
    messages Greg flagged as possible errors, all three installed
    cleanly — verified via `rpm -q` (`tmux-3.7b-1.2`, `neovim-0.12.4-1.1`,
    `ripgrep-15.2.0-1.2`) and functionally: `tmux -V`/`nvim --version`
    both ran fine, and a detached `tmux new-session`/`kill-session`
    round-trip produced no errors with no `~/.tmux.conf` present. The
    flagged install-time messages didn't reproduce as any functional
    problem, most likely a benign zypper notice (e.g. a vendor-change
    confirmation or dependency note) rather than a real failure.
  - **ranger added to `profiles/default` (2026-08-05):** originally just
    a `docs/PHILOSOPHY.md` example of a "curate, don't reinvent"
    candidate tool, ranger is now a real part of Greg's base profile —
    he asked for it in after noticing it was already on the CachyOS VM
    and liking it, borders and all. Added `ranger` to `packages.txt` and
    a new `dotfiles/.config/ranger/rc.conf`. The rc.conf explicitly
    turns on `vcs_aware`/`vcs_backend_git` so git status shows via
    ranger's *built-in* colored-letter indicators — this sidesteps the
    icon-based git-status indicator that failed to render on the
    CachyOS VM (a Nerd Font glyph gap, never root-caused) rather than
    fixing it directly. `draw_borders` is also set explicitly since
    that's what looked good on CachyOS.
    **Confirmed working again on the new Pop!_OS test VM (2026-08-06,
    see "Test environments"):** borders and the letter-based git-status
    indicators both render correctly after `glb restore default` there
    too, matching the CachyOS result. If Greg later wants icon-based
    (not letter-based) git status, that likely means a `devicons`-style
    ranger plugin, which needs an actual plugin-install step (like
    `lib/plugins.sh` does for zsh) — dotfiles alone can't do it.
    **Per-profile scope:** ranger is default-on for Greg's own
    `profiles/default` only. Once the multi-profile system in
    `docs/ROADMAP.md` V0.3 (Minimal/Developer/Server/Custom/etc.) is
    built, ranger should be an *optional* package for those other
    profiles, not mandatory — not every profile needs a TUI file
    manager. Not yet enforceable in code since only `default` exists
    today.
- WezTerm config is done (see "Current state"). Ghostty turned out to
  **not** be installed or available via Flatpak on this machine (the
  original "Greg already uses both" premise was wrong) — dropped from
  active scope; revisit only if Greg actually starts using it.
- Add a Homebrew/Linuxbrew repository as an install source
- Support multiple named profiles, not just `default` — `docs/ROADMAP.md`'s
  Version 0.3 already envisions Minimal/Developer/Server/Custom, plus a new
  "New to Linux" profile: curated, opinionated software picks (one solid
  browser/editor/office-suite/image-editor/media-player, not a menu) aimed
  at people switching from Windows/macOS who don't know the Linux-native
  options yet. This is a different value proposition from the rest of
  GLB — "restore my exact setup" doesn't help someone who has no setup to
  restore, "here's what's good" does. Probably the highest-leverage way to
  make GLB useful to people beyond Greg.
  - **Developer/Server profile content — brainstormed 2026-08-06, not
    built, revisit when picked up:**
    - Developer candidates: Docker or Podman (containers — real fork to
      decide, not just a name swap: Docker is more familiar, Podman is
      daemonless/rootless and fits GLB's philosophy better), the C/C++
      build toolchain meta-package (another per-distro naming override
      like `libreoffice`/`firefox` — `build-essential`/`base-devel`/
      dnf's `Development Tools` group/zypper equivalent), a language
      version-manager story (per-language like `nvm`/`pyenv`/`rustup`
      vs. a universal one like `asdf`/`mise` — also a real fork to
      decide deliberately), `gh` (GitHub CLI), maybe `lazygit`/`delta`,
      `postgresql-client`/`sqlite3`, `jq`.
    - Server candidates: `htop`/`btop` (see cross-cutting gap below),
      a firewall tool (`ufw` vs `firewalld` — same kind of per-distro
      fork as Docker/Podman), unattended security updates
      (`unattended-upgrades`/`dnf-automatic`/equivalents), `rsync` +
      a backup tool (`restic`/`borgbackup`), `fail2ban`. Keep the
      `GLB_SHELL` indicator — arguably *more* useful here than
      anywhere else, for telling apart SSH sessions into different
      boxes.
    - **Design nuance Greg raised, not yet resolved:** someone who
      already identifies as "a developer" or "a server admin" likely
      already knows what tools they want and how to install them
      themselves — a rigid curated list may add little value for that
      audience (unlike `new-to-linux`, where the audience by
      definition doesn't know the options). The real target for a
      built-out Developer/Server profile may be someone newer to that
      role who wants "give me a solid complete kit" without having to
      research it — closer in spirit to `new-to-linux`'s value prop
      than to `default`'s "restore my exact setup." Worth deciding
      explicitly who each profile is *for* before building it out, not
      just what packages to put in it.
    - **Cross-cutting gap found while brainstorming, independent of
      any new profile — fixed (2026-08-06):** no profile — including
      `default` — had a live resource monitor (`htop`/`btop`).
      `fastfetch` is a one-shot system-info banner, not a monitor.
      Added `htop` to `profiles/default/packages.txt` (picked over
      `btop`: htop's been the zero-doubt universal pick across every
      distro's base repos for over a decade, no strong reason to carry
      both). Scoped to `default` only, not `new-to-linux` — a process
      monitor is the same kind of power-user CLI tool as
      `tmux`/`neovim`/`ripgrep`, already excluded there for the same
      reason.
- **Non-package-manager install mechanism — built (2026-08-06).** New
  `lib/extras.sh` + a per-profile `extras.txt` manifest
  (`<method> <name> <spec>` per line, comments/blank lines stripped
  like `packages.txt`). Supports `curl` (runs `curl -fsSL <url> | sh`,
  tracked via `command -v <name>`) and `flatpak` (ensures the flathub
  remote, `flatpak install -y flathub <app-id>`, tracked via
  `flatpak info`) — not AppImage, no real candidate for it yet, but
  the format doesn't need a redesign to add it later.
  `glb_apply_profile` (`lib/profile.sh`) now calls
  `glb_apply_profile_extras` after packages, before Starship/dotfiles.
  On a failed install, reuses `glb_prompt_manual_step`
  (`lib/package.sh`, built earlier today for sudo-gated package
  installs) — same pause/print-the-command/wait-for-confirm-or-skip
  UX, now shared across both install paths. Closes two real gaps this
  session surfaced:
  - **Fresh** (the `new-to-linux` code editor) was listed
    "aspirationally" in `packages.txt` and silently failed every
    restore — moved to `extras.txt` (`curl`) in both `default` and
    `new-to-linux`, where it now actually installs. `default`'s
    dotfiles already had unused `editbash`/`editstarship` aliases
    checking for `fresh`/`fresh-editor` on `$PATH`; this is what
    finally makes those real.
  - **WezTerm**: `default`'s dotfiles symlink
    `.config/wezterm/wezterm.lua`, but `glb restore` never installed
    the app itself (Greg set it up manually via Flatpak). Added to
    `default/extras.txt` (`flatpak`, app id
    `org.wezfurlong.wezterm`); also added plain `flatpak` to
    `default/packages.txt` since the extras entry needs the `flatpak`
    binary itself first.
  - A real bash gotcha caught while building this: `PIPESTATUS` gets
    clobbered by the very next simple command — even a plain
    assignment — so reading `${PIPESTATUS[0]}` then `${PIPESTATUS[1]}`
    on separate lines silently lost the second value. Fixed by
    capturing the whole array in one shot:
    `pipe_status=("${PIPESTATUS[@]}")`.
  - New `tests/extras.bats` (manifest parsing, both methods,
    pause/confirm/skip, the PIPESTATUS-masking case explicitly) plus
    real end-to-end restores of both actual profiles in
    `tests/dispatcher.bats`. All 68 tests pass.
  - **Not done, deliberately:** no live `glb restore` was run for real
    on this laptop — everything above was built and verified entirely
    through stubbed `curl`/`sh`/`flatpak` in bats, never touching the
    real network or actually installing Fresh/WezTerm. Running a real
    restore to verify the actual installs work is something Greg would
    do himself in a real terminal, not something run automatically
    here — deliberately the same category of boundary as the sudo
    installs earlier (don't execute a downloaded script/perform a real
    install without Greg's own hands on it), just for a different
    reason (untrusted-execution caution, not a TTY limitation).
- Terminal prompt/shell customization for `profiles/default` is **done**
  (see "Current state" above — Starship + unified bash/zsh/fish +
  framework-free plugins, locked in as standard). One narrower piece
  remains open: the `glb prompt` *command itself* (`lib/prompt.sh` —
  interactive preset picker for someone with an existing `.zshrc`, not
  tied to `profiles/default`) is still zsh-only; bash/fish support for
  that standalone command hasn't been built. Starship presets themselves
  turned out to be whole standalone configs, not composable modules —
  even starship.rs has no way to mix e.g. Pastel Powerline's layout with
  Plain Text symbols — so `glb prompt`'s menu picks one full preset
  outright rather than mixing-and-matching (no TOML parser to lean on,
  Bash-only).

## Testing

- **`bats` is not installed on the EndeavourOS VM** (2026-08-08), same
  no-TTY-for-sudo-install limitation as every other machine — ran via
  the same locally-cloned `bats-core` workaround. 197/202 tests pass
  after this session's `tests/export.bats` fix (see Roadmap entry
  above for the fix itself); the 5 remaining failures are the same
  pre-existing `fresh`-genuinely-on-PATH gap this VM now has from its
  own real `default` restore earlier this session.
- **`bats` is not installed on the openSUSE VM** (2026-08-07), same
  no-TTY-for-sudo-install limitation as every other machine — ran via
  the same locally-cloned `bats-core` workaround. 182/186 tests pass
  (up from 121 after this session's new `tests/export.bats`,
  `tests/diff.bats`, `tests/restore_snapshot.bats`, `tests/repair.bats`,
  and updates to `tests/profile.bats`/`tests/dispatcher.bats` for the
  guided wizard); the 4 failures are the same pre-existing,
  already-documented `fresh`-genuinely-on-PATH gap this VM now has from
  its own real
  `new-to-linux` restore earlier this session (see Roadmap
  entry above), confirmed via `command -v fresh` directly.
- `tests/` has a bats suite (`tests/detect.bats`, `package.bats`,
  `profile.bats`, `dispatcher.bats`) covering package manager detection,
  packages.txt parsing, dotfiles symlink/backup, per-distro package
  overrides, and the dispatcher's remove/update/restore/profiles commands.
  Runs in an isolated `GLB_ROOT`/`HOME` with sudo and package managers
  stubbed, so nothing touches the real system. Run with `bats tests/`
  — installed on the Dell laptop as of 2026-08-06 (`sudo apt install -y
  bats`); all 55 tests pass as of that date (see Roadmap section for
  what surfaced the first time it was actually run here).
- **`bats` is not installed on the Linux Mint test machine** (2026-08-07)
  either, same no-TTY-for-sudo-install limitation — ran via the same
  locally-cloned `bats-core` workaround. 116/119 tests pass; see the
  Roadmap entry above for the 3 pre-existing, environment-specific
  failures (this machine now has `fresh-editor` genuinely installed for
  real) and the new `font` method's own test coverage.
- **`bats` is not installed on the new Pop!_OS test VM** (2026-08-06) and
  couldn't be via `sudo apt install` from a sandboxed Claude Code shell
  (no TTY, same limitation as every package install elsewhere in this
  file). Ran the suite there via a locally cloned `bats-core`
  (`git clone --depth 1 https://github.com/bats-core/bats-core` into the
  scratchpad, then its `bin/bats` directly — no install/sudo needed) —
  works fine as a one-off but isn't persisted anywhere on that VM, so a
  future session there will need to either re-clone it or actually
  install the package for real (in a real terminal). 113 tests total as
  of that date; 3 fail specifically on that VM because it happens to
  already have `fresh-editor` at `/usr/bin/fresh` pre-installed, which
  a few tests don't isolate against — see the manual-step bug entry in
  Roadmap for details, confirmed via `git stash` to be pre-existing and
  unrelated to that session's fix.

## Conventions

- Bash only — no dependency on Python/Node/etc. for core functionality
- Keep the "customize a fresh install fast" goal central — prefer one clear
  path over many configurable options unless a real need shows up
- Since this may be shared publicly later, avoid hardcoding anything
  specific to Greg's personal setup unless it's clearly marked as an
  example/default that others would edit
- **End-of-session standing instruction (added 2026-08-08, per Greg):**
  whenever a session and Greg agree the session is ending, commit and push
  *all* outstanding project files — code, docs, and this file — before
  wrapping up. That specifically includes writing a session wrap-up/handoff
  note (this file's Working notes / Roadmap sections) documenting what
  changed and what's still open, since Greg works across multiple
  machines/VMs and each one's next session depends on `git pull`ing a
  fully caught-up `main` to have real continuity. Don't leave a session's
  real work uncommitted or unpushed, and don't end a session with a stale
  CLAUDE.md that doesn't reflect what actually happened.

## Working notes

- This file is read by Claude Code at the start of every session in this
  repo — update it as decisions get made so context isn't lost between
  sessions.
- **Going-public decision made (2026-08-09):** repo stays private until
  GLB is fully tested and vetted, open timetable, no fixed date. Greg's
  plan: fresh VMs, connected to the GLB GitHub repo, for real-world
  testing — not resurrecting the older test VMs listed in "Test
  environments" above, which are being retired. See `docs/PROJECT.md`'s
  Release Strategy for the durable record of this decision. This closes
  the one item left open on the "what's left before stable" list from
  earlier today — everything now has either a resolution or an explicit
  owner/plan, nothing left dangling.
- **Session wrap-up (2026-08-09, cloud session, continued after the
  entry directly below this one) — the "what's left before stable"
  punch list is now fully closed except one decision that's Greg's to
  make, not work to do.** Picking up right after the scope-narrowing/
  messaging session documented in the next entry down:
  - **GUI-vs-terminal scope line made explicit with concrete
    examples** in `docs/PHILOSOPHY.md`: full-screen TUI apps (Ranger,
    Midnight Commander, htop, btop, even the Claude Code CLI) are
    unambiguously in scope no matter how complex, since the test is
    "does it ever open a window separate from the terminal," not
    "how much does it do." Prompted by Greg naming those exact
    examples and asking for the point to be nailed down for future
    sessions.
  - **`pam_faillock` sudo-lockout bug fixed** — the one confirmed,
    reproducible bug on the "what's left" list. New `glb_sudo` helper
    (`lib/utils.sh`) picks plain `sudo` when a real TTY is on stdin,
    `sudo -n` otherwise — fixes the lockout without breaking normal
    interactive use. See its own dedicated Roadmap entry above for
    the full design reasoning (a naive global `sudo -n` swap would
    have broken real terminal use, which is why this needed a TTY
    check rather than a blind find-and-replace) and the test-isolation
    fixes it required.
  - **Installation manifests built** — `glb restore --from-manifest
    <path>`, closing out Version 0.6 entirely. Confirmed via
    `AskUserQuestion` which of three candidate meanings Greg actually
    wanted (bring-your-own external manifest, won over a per-run audit
    trail or a version-pinned lockfile) before building, same
    scope-first discipline as every other Version 0.6 item.
  - **Full bats suite run for real** for the first time this session
    — 207/211 pass, the 4 failures fully explained by this sandbox
    running as root (permission-check tests that `chmod 555` a
    directory don't work when root bypasses permission bits). Confirms
    the whole session's test edits are internally consistent.
  - **Roadmap bookkeeping caught up to match reality**: Version 0.4
    was stale and self-contradictory (unmarked despite most of it
    shipping elsewhere, two bullets contradicting the later
    framework-free-plugins decision) — fixed. "Minimal" and "Custom"
    profiles (Version 0.3) were undefined placeholders since first
    written — dropped per Greg's decision, since `default`/`developer`/
    `server` cover every real need identified so far and `new-to-linux`
    was retired rather than becoming "Minimal."
  - **Where things stand now, for whoever picks this up next:** every
    item on the "what's left before Version 1.0 (stable)" list is
    resolved except one — deciding if/when this repo goes public
    (currently private, no `CONTRIBUTING.md`) — which is explicitly
    Greg's call, not a task to pick up unprompted. Real-hardware
    verification of everything built across today's sessions (WezTerm
    removal, `new-to-linux` retirement, the sudo fix, the manifest
    feature) is still open but deliberately deferred — Greg's plan is
    fresh test VMs later rather than re-validating the current ones,
    which are being retired. No other specific next item is scoped;
    next session should either wait for Greg's direction or treat this
    as a natural checkpoint to ask what's next, same as this session
    did.
- **Session wrap-up (2026-08-09, Dell laptop, cloud session) — GLB's
  scope just got meaningfully narrower, and its messaging resharpened
  to match.** Long session, several distinct threads:
  - **Real bug found and fixed on the laptop:** `eza --icons` aliases
    across every profile/shell never passed `--git`, so per-file git
    status never showed in `ls`/`ll`/`la`/`l` (only in Ranger). Fixed
    (12 files) and confirmed working for real — see the dedicated
    Roadmap entry above for the full diagnosis, including the
    stale-fish-alias/`exec fish` gotcha.
  - **A long, disruptive live WezTerm troubleshooting detour** on
    Greg's real daily driver (Flatpak process caching, a stray
    `~/.wezterm.lua` shadowing the managed config, a COSMIC
    window-decoration mismatch, a `pkill`-vs-`flatpak kill`-vs-exact-
    PID saga) — see the "Removed entirely" Roadmap entry for the full
    blow-by-blow. Ended with Greg calling it: GLB should stop managing
    terminal emulators and GUI applications entirely, not just
    WezTerm. WezTerm was fully removed from both the project (repo)
    and the laptop itself (Flatpak app uninstalled, leftover config
    archived/removed).
  - **Scope narrowed project-wide:** GLB only configures things that
    run inside whatever terminal a distro already ships — no GUI
    applications, full stop. Two removals followed from this:
    WezTerm (from `default`) and `new-to-linux`'s curated desktop apps
    (Firefox/LibreOffice/GIMP/VLC). Written up in `docs/PHILOSOPHY.md`
    ("Enhance the Terminal You Have, Don't Replace It") and
    `docs/PROJECT.md`'s Non-Goals. If a future session is ever tempted
    to add a terminal emulator, a browser, an editor-with-a-window, or
    anything similar to a profile, read that PHILOSOPHY.md section
    first — this was tried twice in one day and reversed both times.
  - **`new-to-linux` retired entirely**, same day, as a direct
    follow-on: once its desktop-app picks were gone, it had shrunk to
    a near-duplicate of `default`. See the dedicated Roadmap entry
    above for the full reasoning and the exact files/tests touched.
  - **Project messaging resharpened to lead with the terminal itself**
    — same name (Greg was explicit: no rename), but README.md,
    docs/PROJECT.md, docs/PHILOSOPHY.md, docs/ROADMAP.md, and this
    file's own "Why it exists" now consistently frame GLB's purpose as
    "the terminal is the biggest barrier for anyone switching from
    Windows/macOS, and GLB makes it approachable" rather than a
    generic "Linux workstation builder." This is really the same
    principle as the GUI-apps removal, stated as the project's core
    purpose rather than just a boundary.
  - **Deliberately not re-tested on real hardware** — Greg's explicit
    call: the existing test VMs are being retired once this project
    reaches a stable point, and real-world verification will happen
    against fresh VMs later rather than re-validating on machines
    about to be thrown away. So everything in this session is verified
    by code/doc review only, not a live restore — that's expected and
    fine per Greg's plan, not an open gap to chase.
- **Session wrap-up (2026-08-08, EndeavourOS VM, second session same
  day) — WezTerm made actually usable: a real Flatpak-sandbox bug
  fixed, plus wallpaper/opacity/keybindings added on request.** Picked
  up right after the earlier same-day restore-verification session
  (entry right below this one) closed out, in a fresh Claude Code
  conversation continuing the WezTerm-install thread from even earlier
  that day. See the Roadmap's WezTerm bullet (under "Current state")
  for the full writeup:
  - Root-caused and fixed `tty: ttyname failed: No such device`
    printing on every WezTerm launch — the Flatpak sandbox's default
    `devices=dri`-only permissions don't bind `/dev/pts`, so
    `/etc/profile.d/gpm.sh`'s `tty` call can't resolve WezTerm's own
    pty. Fixed with `flatpak override --user org.wezfurlong.wezterm
    --device=all` plus a full kill/relaunch (a running GUI instance
    keeps its old sandbox permissions otherwise). **Per-machine
    Flatpak state, not a GLB code change** — nothing in `lib/` or
    `extras.txt` needed to change, but worth knowing if another
    machine's WezTerm-via-Flatpak install hits the same symptom.
  - Added gradient background + `window_background_opacity = 0.9` +
    a full tmux-style `Ctrl+a` leader keybinding set to `default`'s
    `wezterm.lua`, per Greg's direct ask. Validated via
    `wezterm show-keys` and confirmed rendering live (KWin/Wayland
    composites the opacity natively on this VM). This **is** a real
    `default`-profile dotfile change — will apply to every machine
    that restores `default` and re-syncs this repo, not just this VM.
  - Committed as three separate commits (`0859fda` test-isolation fix,
    `fd570f2` this session's own wrap-up note, `e6cbf6d` the wezterm.lua
    change, plus this note) and pushed to `origin/main` — confirm with
    `git log` on the laptop that all four landed before assuming this
    machine's work is fully synced.
  - **Pull first** (`git fetch && git log main..origin/main`) before
    assuming any other machine is caught up.
- **Session wrap-up (2026-08-08, EndeavourOS VM) — real `default`
  restore verified end-to-end, plus a real test-suite bug found and
  fixed.** See the Roadmap entry above for the full writeup: zero
  pacman override gaps, all four extras methods confirmed installed
  for real, a clean idempotent second restore, the `pam_faillock`
  root-cause finding, and a genuine `tests/export.bats` isolation bug
  (two tests assumed apt/zypper detection that only ever worked by
  accident on non-pacman hosts) found and fixed via a
  `glb_detect_package_manager` function override rather than a PATH
  restriction. 197/202 bats pass; the rest are the same pre-existing
  `fresh`-on-PATH class documented everywhere else in this file.
  Committed as `0859fda` (the test fix) and `fd570f2` (this note),
  and pushed to `origin/main` along with the WezTerm work in the
  session note directly above this one.
- **Session wrap-up (2026-08-07, Dell laptop) — pausing here by Greg's
  choice.** Everything below is pushed to `origin/main`, `55abb65` is
  the latest commit as of this note (fast-forwarded cleanly, no other
  machine had pushed ahead of it).
  - Built, tested, and shipped `glb update`'s component-update
    extension (Starship, zsh plugins, per-profile `extras.txt`) — see
    the Roadmap entry above and the handoff right below this one for
    the full build.
  - **Verified for real on this laptop, not just bats:** ran `./glb
    update` live — `starship` updated to `1.26.0`, both zsh plugins
    pulled cleanly (`zsh-syntax-highlighting` fast-forwarded a real
    upstream commit). The two sudo-gated steps (`apt upgrade`, the
    Starship reinstall itself) were run by Greg in a real terminal
    after this session's sandboxed attempt failed cleanly on the
    no-TTY limitation, same pattern as every other sudo-gated step in
    this project.
  - **Next session: pick up with installation manifests** — the last
    item in Version 0.6 (Configuration Management) and the only
    genuinely unscoped one left anywhere in the roadmap (no
    `docs/design/*.md` written for it yet, unlike
    update-components/repair/the guided wizard, which were each
    scoped via `AskUserQuestion` before being built same-day). Start
    by reviewing what "installation manifest" should actually mean in
    GLB's context — likely something like a lockfile capturing exact
    installed versions (distinct from `glb export`'s already-built
    snapshot mechanism, which captures package *names* for
    reproducing a similar setup, not exact pinned versions) — same
    "check what already exists first" discipline used for every prior
    Version 0.5/0.6 item.
  - Nothing else outstanding needs this specific machine.
- **Handoff from the Dell laptop session (2026-08-07): built "updating
  installed components," closing out Version 0.6 entirely.** Picked
  up exactly where the openSUSE VM session's wrap-up note (right below
  this one) left off — the scoping in `docs/design/
  update-components.md` was already done, this session just built it.
  See the Roadmap entry above for the full build: `glb_update_starship`
  (`lib/prompt.sh`), `glb_update_zsh_plugins` (`lib/plugins.sh`),
  `glb_update_profile_extras`/`_glb_update_extra` (`lib/extras.sh`),
  and `glb update [profile]`'s new optional argument in the dispatcher.
  17 new bats tests, 201/202 passing (one pre-existing, unrelated
  zypper-detection failure on this apt machine). **Then run for real
  on this laptop**, Greg's actual daily driver: `./glb update` for
  real, the two sudo-gated steps run by Greg himself afterward,
  confirmed via `starship --version` (`1.26.0`) that the update
  genuinely took — see the Roadmap entry above for the full
  verification. `glb update <profile>`'s extras-re-run path is still
  only bats-verified. **Version 0.6 (Configuration Management) is now
  fully done**: installation manifests is the only genuinely unscoped
  item left in the whole roadmap. **Pull first** (`git fetch && git
  log main..origin/main`) before assuming any other machine is caught
  up.
- **Session wrap-up (2026-08-07, openSUSE VM) — paused here by Greg's
  choice, VM being shut down, picking back up on the Dell laptop next.**
  Everything below is pushed to `origin/main`
  (`bb6c37d` is the latest commit as of this note) — the detailed
  per-item entries are further down in this Roadmap section and in the
  Working notes handoffs right below this one, but the short version:
  - Verified `new-to-linux`'s `firefox:zypper` override for real — item
    1 (per-distro override verification) is now **fully closed**
    across both pacman and zypper.
  - Built the entire `docs/design/state-export-import.md` plan for
    real: `glb export`, `glb diff`, `glb restore --from-snapshot`.
  - Cleaned up `docs/ROADMAP.md`'s Version 0.7 target-distro list to
    reflect real testing evidence, and removed a stale bullet.
  - Scoped and built the guided configuration wizard, closing
    **Version 0.5 entirely**.
  - Scoped and built `glb repair`, closing "repairing existing
    installations."
  - Scoped (**not yet built**) `glb update`'s extension to cover
    Starship/zsh plugins/extras — see
    `docs/design/update-components.md`. This is the natural next
    session's starting point: already scoped, ready to build, same as
    the wizard and repair were before each got built same-day.
  - The only item in Version 0.6 with **no plan written at all yet** is
    installation manifests — would need scoping from scratch, unlike
    update-components.
  - This VM (openSUSE Tumbleweed) is being shut down after this
    session — it won't be reachable for the next session. Nothing left
    outstanding needs this specific machine; every command actually
    built this session was already verified live on it before this
    note was written. **Pull first** (`git fetch && git log
    main..origin/main`) on the Dell laptop before assuming it's caught
    up, per the standing multi-machine workflow note below.
- **Handoff from the openSUSE VM session (2026-08-07, still going):
  scoped "updating installed components," didn't build it.** Same
  approach as the wizard/repair scoping earlier this session: `glb
  update` already covers system packages; the gap is Starship/zsh
  plugins/`extras.txt` entries, none of which currently have an update
  path. Confirmed via `AskUserQuestion`: extend `glb update` rather
  than add a new command, and leave GLB updating its own code out of
  scope. Wrote `docs/design/update-components.md`. Next session can go
  straight to building it. Docs-only, no code changed.
- **Handoff from the openSUSE VM session (2026-08-07, still going):
  built `glb repair`, closing out "repairing existing installations."**
  Followed the scoping (see the entry right below this one) immediately
  after writing it, same session. New `lib/repair.sh`, wired in as
  `repair <profile>` — see the Roadmap entry above for the full build,
  including a real test gap caught (the dispatcher-level `glb repair`
  test needed the same curl/sh/flatpak/unzip/fc-cache stub set the
  existing default-profile restore test already uses, not just
  starship/git). 182/186 bats tests pass — same 4 pre-existing
  failures. Verified for real on this VM (declining the fix, confirming
  zero on-disk trace left behind). This commit changes code — confirm
  it's pushed before assuming another machine has it.
- **Handoff from the openSUSE VM session (2026-08-07, still going):
  scoped "repairing existing installations," didn't build it.** Same
  approach as the wizard scoping earlier this session: checked what
  already exists first (restore is already idempotent), found the real
  gap is just a one-shot check-then-fix command, confirmed the
  direction via `AskUserQuestion`, wrote
  `docs/design/repair.md`. Deliberately deferred a second real gap
  (shallow zsh-plugin existence check) as a separate future item rather
  than scope-creeping this one. Docs-only, no code changed.
- **Handoff from the openSUSE VM session (2026-08-07, one more time):
  built the guided configuration wizard, closing out Version 0.5
  entirely.** Confirmed the design doc's one open question via
  `AskUserQuestion` (new default behavior for bare `glb restore`, not
  opt-in), then built it: `_glb_profile_description` +
  `profiles/*/description.txt` (new file per profile) and a rewritten
  `glb_restore_interactive` (`lib/profile.sh`) that previews then
  confirms before applying. See the Roadmap entry above for the full
  build, including a real `read -p`/bats-capture gotcha (unrelated to
  GLB itself, just a testing quirk worth knowing) and why existing
  interactive-picker tests needed updating, not just extending, since
  the default behavior genuinely changed. This commit changes code —
  confirm it's pushed before assuming another machine has it.
- **Handoff from the openSUSE VM session (2026-08-07, yet further
  continued): scoped the guided configuration wizard, didn't build it.**
  Reviewed what already exists (the no-argument `glb restore` picker,
  `--dry-run`, existing step-by-step logging) and found the four vague
  Version 0.5 bullets (express install, guided wizard, configuration
  summary, progress reporting) collapse into one small feature, not
  four. Confirmed via `AskUserQuestion`: discovery-only (no per-package
  customization — matches GLB's existing curated/opinionated
  philosophy), express install needs zero new code (it's the existing
  direct `glb restore <profile>` path), progress reporting needs zero
  new code (existing logging already does this). Wrote
  `docs/design/guided-wizard.md` capturing the scope: enhance the
  existing picker with a one-line description per profile (recommended
  source: a new `profiles/<name>/description.txt` per profile, not
  parsing `packages.txt`'s prose comments) plus an automatic
  `--dry-run` preview and confirm step before applying. One open
  question left in the doc for next time, same pattern as the
  in-repo-snapshots question that preceded `glb export`: should this
  become bare `glb restore`'s new default behavior (changes existing
  test assertions that expect immediate-apply) or stay opt-in behind a
  new flag. Docs-only, no code changed this round.
- **Handoff from the openSUSE VM session (2026-08-07, further
  continued):** `docs/ROADMAP.md`'s Version 0.7 (Cross-Distribution
  Support) target-distro list was just a flat, unchecked bullet list
  even though every distro on it except Manjaro has real testing
  evidence already sitting in this file's own Roadmap section — cleaned
  it up to mark Debian/Ubuntu(-via-derivatives)/Pop!_OS/Fedora/Arch ✅
  with a one-line pointer to the evidence for each, leaving Manjaro
  genuinely unmarked (never tested, even though pacman itself is
  proven via CachyOS). Also flagged that zypper/openSUSE isn't on the
  target list at all despite now having the deepest real testing of
  any distro here (this whole session) — noted as a gap, not added
  unilaterally, since expanding the target list is a real scope
  decision, not just marking existing work done. Docs-only, no code
  changed.
- **Handoff from the openSUSE VM session (2026-08-07, continued):**
  same session as the `firefox:zypper` verification below also built
  and finished `glb export`, `glb diff`, and `glb restore
  --from-snapshot` — **all three pieces of item 4 (Version 0.6
  Configuration Management)**, following the already-scoped plan in
  `docs/design/state-export-import.md` end to end. See the three
  Roadmap entries above for the full build: new `lib/export.sh` +
  `export` command, two new `lib/package.sh` functions, new
  `lib/diff.sh` + `diff` command (generalized beyond the doc's literal
  signature to resolve either argument as a profile or a snapshot),
  `glb_apply_snapshot` (deliberately duplicating rather than
  refactoring `glb_apply_profile`, to avoid risking its many existing
  exact-wording test assertions) + the dispatcher's `restore
  --from-snapshot <name>` flag parsing, a real zypper
  manual-vs-dependency limitation worked around via
  `/var/lib/zypp/AutoInstalled`, a real scope gap (extras.txt packages
  like Fresh aren't reverse-mapped yet), 42 new bats tests total, and
  real live verification chaining all three commands together on this
  VM (export, diffed against `default`, then restored from that
  snapshot with `--dry-run`) — the real snapshot was deleted before
  committing each time, per Greg's choice via `AskUserQuestion`.
  **State-export-import is fully built, nothing left in that design
  doc.** These commits do change code (unlike the verification-only one
  below) — confirm they're actually pushed before assuming another
  machine has them.
- **Handoff from the openSUSE VM session (2026-08-07):** verified
  `new-to-linux`'s `firefox:zypper` override for real on this VM (the
  same one from the original 2026-08-06 zypper cross-distro test) — see
  Roadmap above for the full writeup. This was the last open piece of
  item 1 — **all three per-distro overrides
  (`firefox:zypper`/`libreoffice:pacman`/`gh:pacman`) are now confirmed
  on real hardware, item 1 is fully closed.** Not pushed yet as of this
  note — no code changed this session (verification-only), so this
  commit is docs-only. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming any other
  machine is caught up.
- **Handoff from the CachyOS VM session (2026-08-07):** verified
  `new-to-linux`'s pacman package overrides for real on this VM (the
  same one from the original 2026-08-05 cross-distro test) — see
  Roadmap above for the full writeup, including a real `pam_faillock`
  lockout detour that turned out to be an environment gotcha, not a GLB
  issue. `libreoffice:pacman`/`gh:pacman` were confirmed there;
  `firefox:zypper` was confirmed the next day on the openSUSE VM (see
  entry above) — item 1 is now fully closed. Not pushed yet as of this
  note — no code changed this session (verification-only), so this
  commit is docs-only. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming any other
  machine is caught up.
- **Handoff from the Pop!_OS test VM session (2026-08-07):** ran
  `glb restore developer` for real here (see Roadmap above) — first
  live, non-sandboxed verification of the profile built the day before
  on the Dell laptop. Clean end-to-end after Greg manually ran the two
  sudo-gated installs (`podman`, `gh`); mise and the Nerd Font extras
  methods both confirmed working for real too. One real (non-GLB) gap
  noted: this VM already had a Nerd Font installed by hand before this
  session, so it's no longer a clean "fresh install" test bed for that
  specific gap.
  Same session also tested `glb restore --undo` for real here (Greg's
  ask: confirm a user can get fully back to pre-GLB state before trying
  a new profile) — found and fixed a real bug where restoring a second
  profile silently overwrote the first restore's `.glb-backup`,
  destroying this VM's true original dotfiles permanently (see Roadmap
  entry above for the full root cause and fix). `--undo` itself works
  correctly as one level of history (confirmed: landed back on
  `default`, not stock defaults, exactly as the now-understood bug
  predicts) — left this VM on `default` afterward, Greg's call. The fix
  prevents this for every future multi-profile switch, but this VM's
  own pre-GLB baseline is gone for good.
  Same session, finally, also ran `glb restore server` for real (see
  Roadmap above) — first live verification of that profile too, and a
  second real-world exercise of the backup-overwrite fix (switching
  `default` -> `server` correctly created a fresh backup, no
  clobbering). Clean end-to-end after Greg manually ran the two
  sudo-gated installs (`restic`, `fail2ban`). **All five GLB profiles
  are now confirmed working via a real restore on at least one
  machine** — `new-to-linux`/`developer`/`server` all on this VM,
  `default` on many. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming any other
  machine is caught up.
- **Handoff from the Dell laptop session (2026-08-07):** built
  `profiles/developer` and `profiles/server` (see Roadmap above) —
  item 2 of the agreed next-steps order, resolved the "who is each
  profile for" design question via `AskUserQuestion` (newcomer to the
  role, for both), plus three tool forks (Podman, mise, ufw, restic).
  All 121 bats tests pass. Not pushed as of this note — confirm with
  Greg before pushing. Item 1 (verifying `new-to-linux`'s zypper/pacman
  overrides, now also covering the new `gh:pacman` override) is still
  open and needs real hardware. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming any other
  machine is caught up.
- Greg develops across multiple machines (Dell E7450 laptop, a VirtualBox
  VM — Zorin OS as of 2026-08-05) with Claude Code sessions running
  independently on each, not always in sync in real time. **Before
  pushing, check for commits on `origin/main` you don't have locally**
  (`git fetch && git log main..origin/main`) — this file was committed
  specifically because a VM session had already pushed 3 real commits
  (per-distro package overrides, `glb restore` error handling, the bats
  test suite) that the laptop session only found out about when a push
  was rejected. Don't assume you have the full picture from this file
  alone if it's been a while since the last pull on this machine.
- **Handoff to the Dell laptop session (2026-08-06):** Greg just ran
  `glb restore default` for real on the Debian machine (see "Debian
  (apt) result" in Roadmap above) and pushed the result — commit
  `b36c5f2` is the latest on `origin/main` as of this note. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming the laptop
  is caught up; it was ~24 commits behind at one point earlier this week
  and there's no guarantee it's been synced since. Cross-distro testing
  is now fully done (apt/dnf/pacman/zypper, five machines total) — **the
  agreed next step is multi-profile support** (see the "Next priority"
  bullet at the top of Roadmap and the "Support multiple named profiles"
  bullet further down for the full reasoning). Nothing has been started
  on it yet; that's the right place to pick up.
- **Handoff from the Linux Mint test machine session (2026-08-07):**
  first session on this machine (see "Test environments" above) — ran
  `glb restore default` for real here for the first time, which
  surfaced and led to fixing the Nerd Font provisioning gap (new `font`
  extras method) and a WezTerm window-decorations bug, plus a
  gnome-terminal/VTE caching gotcha worth knowing about if it comes up
  again elsewhere (see Roadmap entry above for all three). **Pull
  first** (`git fetch && git log main..origin/main`) before assuming
  any other machine is caught up.
- **Handoff from the new Pop!_OS test VM session (2026-08-06):** first
  session on this VM (see "Test environments" above) — ran
  `glb restore default` for real here for the first time, which
  surfaced and led to fixing a genuine manual-step-pause bug (see the
  Roadmap entry above for the full root cause). Pushed as commit
  `19b13ff`, the latest on `origin/main` as of this note. **Pull first**
  (`git fetch && git log main..origin/main`) before assuming any other
  machine is caught up. Multi-profile support (the agreed next
  priority, noted just above) was not touched this session — this was
  purely a real-restore-and-fix session, not a feature session.
- State export/import (see docs/design/state-export-import.md)