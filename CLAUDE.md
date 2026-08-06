# CLAUDE.md — GLB (Greg's Linux Bootstrap)

## What this project is

GLB is a Bash CLI tool that bootstraps and customizes fresh Linux installs —
installing software and applying shell configs in one pass instead of doing
it manually item by item every time a distro gets reinstalled.

- Repo: https://github.com/ggregoro/GLB (private)
- License: MIT
- Language: Bash

## Why it exists

Greg distro-hops a lot and got tired of manually reconfiguring each fresh
install by hand. GLB automates that setup. It's built with the idea that it
might eventually be shared publicly if there's interest — so keep code
reasonably clean and documented, not just "works on my machine."

## Test environments

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

When suggesting changes, keep portability across distros in mind — don't
assume a single package manager or init system unless the script already
branches on it.

## Current state (as of 2026-08-06)

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update`, `restore [profile] [--undo|--dry-run]` (no profile name
  shows an interactive picker), `profiles`, `prompt`.
- Modules: `lib/banner.sh`, `lib/logging.sh`, `lib/utils.sh`,
  `lib/detect.sh`, `lib/package.sh`, `lib/extras.sh`, `lib/profile.sh`,
  `lib/prompt.sh`, `lib/plugins.sh`, `lib/completions.sh` — all sourced
  by the `glb` dispatcher.
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
- **Next session: pick up here, in this order (agreed 2026-08-06).**
  All four items from the prior session-wrap-up brainstorm just below
  (rollback/undo, dry-run, interactive profile picker, shell
  completions) are done, plus a follow-up resyncing `new-to-linux`'s
  prompt dotfiles to match `default`. Greg then asked for a
  recommendation on what's next and confirmed taking the list "in
  order" — nothing on this list is built yet:
  1. **Verify `new-to-linux`'s per-distro package overrides on real
     hardware.** `firefox:zypper` → `MozillaFirefox` and
     `libreoffice:pacman` → `libreoffice-fresh`
     (`_GLB_PACKAGE_OVERRIDES`, `lib/package.sh`) were added when
     `new-to-linux` was built (2026-08-06) but never empirically
     confirmed, unlike every other override in that table (all of
     which were validated via real per-distro testing during the
     cross-distro effort). Needs an actual `glb restore new-to-linux`
     on a real or VM zypper machine and a real or VM Arch-family
     machine — not something a sandboxed session can verify on its
     own; Greg will need to run it and report back, same pattern as
     the original cross-distro testing.
  2. **Developer/Server profiles.** Candidates already brainstormed
     and recorded further down this file (Docker vs Podman, a
     build-toolchain per-distro override, a language version-manager
     story, `gh`/`lazygit`/`jq` for Developer; `htop`/a firewall
     tool/unattended security updates/`rsync`+backup/`fail2ban` for
     Server) but nothing built. The open design question flagged at
     the time, still unresolved: who is each profile actually *for* —
     someone who already knows what they want (a rigid curated list
     adds little value there), or someone newer to that role who wants
     a complete kit without researching it themselves (closer to
     `new-to-linux`'s "here's what's good" value prop than `default`'s
     "restore my exact setup")? Resolve that before picking packages,
     not after.
  3. **Original Version 0.5 items never promoted to "agreed
     priority": express installation, guided configuration wizard,
     configuration summary, progress reporting.** None of these are
     concretely scoped yet (unlike the four just-finished items, which
     each already had a clear one-line mechanism in mind before
     building) — will need defining/scoping as part of picking this
     up, not just implementing.
  4. **Version 0.6 — Configuration Management: installation
     manifests, configuration export/import, repairing existing
     installations, updating installed components.** Not started, not
     yet scoped in detail. See `docs/ROADMAP.md`.
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
    that's what looked good on CachyOS. If Greg later wants icon-based
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

- `tests/` has a bats suite (`tests/detect.bats`, `package.bats`,
  `profile.bats`, `dispatcher.bats`) covering package manager detection,
  packages.txt parsing, dotfiles symlink/backup, per-distro package
  overrides, and the dispatcher's remove/update/restore/profiles commands.
  Runs in an isolated `GLB_ROOT`/`HOME` with sudo and package managers
  stubbed, so nothing touches the real system. Run with `bats tests/`
  — installed on the Dell laptop as of 2026-08-06 (`sudo apt install -y
  bats`); all 55 tests pass as of that date (see Roadmap section for
  what surfaced the first time it was actually run here).
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

## Working notes

- This file is read by Claude Code at the start of every session in this
  repo — update it as decisions get made so context isn't lost between
  sessions.
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
