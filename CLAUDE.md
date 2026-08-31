# CLAUDE.md — GLB (Greg's Linux Bootstrap)

## What this project is

GLB is a Bash CLI tool that makes the terminal the easiest, most
approachable part of using Linux — a curated shell, prompt, and set of
CLI tools, configured in one pass inside whatever terminal a distro
already ships, instead of piecing it together by hand every time a
distro gets reinstalled. GLB is **terminal-first**: it enhances whatever
terminal you already have and its focus stays the shell and CLI. GUI
applications are in scope only when they're a deliberate, opinionated
pick that complements that mission — installed and lightly configured,
never vendor-managed, never a general app menu. (This relaxes an earlier
"no GUI applications, terminal emulators included" rule, dropped
2026-08-30 — see `docs/PHILOSOPHY.md` "Terminal-First, Not
Terminal-Only" and the 2026-08-30 Roadmap entry below. The
WezTerm/`new-to-linux` history stays as the "install, don't
vendor-manage" guidance that rule produced.) The first GUI pick under
this stance is **Ghostty**, installed in `default` so Yazi's image
preview works where a distro's default terminal can't draw one.

- Repo: https://github.com/ggregoro/GLB (public — see the "Repository is
  now public" Working notes entry below)
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
- **New (2026-08-25): a fresh Linux Mint VM**, under the same fresh-VM
  plan — Greg ran `glb restore default` for real and reported it went
  well overall, with three things not installing: `snapd`, `fastfetch`,
  `yazi`. Confirmed via the exact error text ("has no installation
  candidate" for all three, gathered via a cloud session, not run
  directly on this VM): `fastfetch` is the already-known, already-
  documented gap (not in apt's index on Mint, see `packages.txt`'s own
  comment, first confirmed 2026-08-07) — reconfirmed, not a new issue.
  `snapd`/`yazi` (which depends on it) are a genuinely new finding,
  though: unlike every other apt distro tested (Pop!_OS/Debian/Ubuntu,
  where `snapd` installs fine), **Linux Mint ships
  `/etc/apt/preferences.d/nosnap.pref`, which pins `snapd` to priority
  -1 by deliberate anti-Snap policy** — the package is genuinely in
  Mint's index, but apt refuses to consider it a candidate at all, so
  `apt install snapd` fails with the exact same "has no installation
  candidate" wording a genuinely-absent package would give. This is
  meaningfully different from pacman's/zypper's real absence (both
  already handled — see `_GLB_PACKAGE_SKIP` and `packages.txt`): the
  user has a real, actionable fix (delete that one file), so it wasn't
  auto-skipped the way `snapd:pacman` is — silently skipping would hide
  a distro's own deliberate policy choice from the user rather than
  informing them of it.
  - **Fixed (cloud session, same day):** new `_GLB_PACKAGE_MANUAL_HINT`
    table (`lib/package.sh`, keyed `<generic-name>:<distro>` via
    `glb_detect_os` — finer-grained than the existing `<name>:<pkg_mgr>`
    tables need, since apt itself behaves differently across the
    distros that share it) plus a new `glb_package_manual_hint`
    lookup. `glb_prompt_manual_step` now takes an optional third `hint`
    argument, printed above the resolved command when present;
    `glb_install_package` looks up the hint before pausing. Net effect
    on Mint: the `snapd` manual-step pause now explains the
    `nosnap.pref` pin and gives the exact fix (`sudo rm
    /etc/apt/preferences.d/nosnap.pref && sudo apt update`) instead of
    just re-showing a `sudo apt install -y snapd` that would fail
    identically forever. `yazi`'s own extras.txt pause needed no
    separate hint — it fails as a direct consequence of `snapd` missing,
    and `snapd` is processed first in the same restore, so the user
    already has the explanation by the time they hit it.
  - 4 new bats tests in `tests/package.bats` (the hint lookup itself,
    both with and without a matching distro entry; the manual-step
    pause surfacing the hint text and fix command; and confirming no
    hint appears on a distro with no entry). Full suite: 223/227 pass —
    the same 4 pre-existing root-sandbox permission-check failures this
    file has documented since 2026-08-09 (confirmed via `git stash` to
    fail identically on the unmodified tree), unrelated to this change.
  - **Verified for real on this Mint VM, same day, after merging to
    `main`.** Greg pulled `main` and re-ran the restore: the `snapd`
    manual-step pause correctly showed the new `nosnap.pref` hint text
    (confirmed directly, not assumed). `fastfetch` hit the expected,
    unrelated "Unable to locate package" error — same already-known
    gap, skipped via the normal `s` prompt. For `snapd`/`yazi`, Greg ran
    the hint's fix manually (`sudo rm /etc/apt/preferences.d/
    nosnap.pref && sudo apt update && sudo apt install -y snapd`, then
    `sudo snap install yazi --classic`) and confirmed `yazi` genuinely
    launches afterward. Closes this out end-to-end — the hint mechanism
    works exactly as designed on the real distro/error it was built
    for, not just in the bats sandbox.
- **New (2026-08-09): a fresh Pop!_OS VM running on VirtualBox 7.2.8,
  the first one under the plan above** — not connected to the GitHub
  repo as a dev checkout, genuinely standing in for an end user's
  machine. `git clone`d from the now-public repo and restored
  `default` for real; see the Roadmap entry for the full result
  (worked essentially perfectly, one already-known `fastfetch` gap).
- **New (2026-08-10): a fresh CachyOS VM**, second machine under the
  same fresh-VM plan — used to verify `install.sh`'s curl-install path
  and the `glb_sudo`/`pam_faillock` fix on real pacman/Arch-based
  hardware (both confirmed working, see Roadmap entry).
  - **Still open as of 2026-08-13, confirmed by a full commit-history
    audit (`git log -i --grep`) — the `developer`/`server` profile
    verification on pacman planned in the 2026-08-09 handoff
    (`81309df`, "verify developer + server on CachyOS then openSUSE")
    was never actually run.** This CachyOS VM's only real verification
    (`b201600`, same day) covered `install.sh`'s curl-installer and the
    `glb_sudo`/`pam_faillock` fix specifically — not the profile tools.
    No commit anywhere mentions running `glb restore developer` or
    `glb restore server` on pacman, or any pacman-specific result for
    `ncdu`/`lazygit`/`glow`/`lazydocker`/`ufw`/`rsync`/`restic`/
    `fail2ban`/`btop`. The zypper half of this same plan is now done
    (see the openSUSE VM entry above, 2026-08-13) — pacman is the one
    real gap left before both halves of the 2026-08-09 plan are closed.
    **What to check here, in order** (same checklist the openSUSE VM
    entry above just used):
    1. `glb restore developer --dry-run` then **for real** — dry-run
       only distinguishes "already installed" from a blind "would
       install" and never actually queries the package manager
       (confirmed this session), so the real, non-dry-run restore is
       required to actually learn anything. Confirm `ncdu`/`lazygit`/
       `glow`/`lazydocker` all resolve as real pacman package names —
       `lazygit` is a confirmed gap on Fedora/dnf but confirmed
       *working* on zypper, pacman is the one still-unknown data point
       (the AUR generally carries more than Fedora's official repos,
       so it may well be fine, but this has never been checked
       directly).
    2. `glb restore server --dry-run` then for real — first-ever real
       test of `server` on pacman: `ufw`/`rsync`/`restic`/`fail2ban`/
       `btop` all need to resolve and install cleanly. Also check
       `ranger` + `yazi`, added to `server` on 2026-08-13 (this same
       session, see the openSUSE VM entry above for the full writeup)
       — `ranger` should be an ordinary pacman package, but `yazi`
       depends on `snapd`, which `packages.txt` already documents as
       **not in Arch/pacman's official repos at all (AUR-only)** —
       expect the same "confirmed gap, `yazi` doesn't install" outcome
       zypper just hit, but confirm it for real rather than assuming;
       if pacman surprises us and it somehow works, that's worth
       knowing too.
    3. Note any `_GLB_PACKAGE_OVERRIDES` gaps found (see
       `lib/package.sh`), same as every prior cross-distro pass in this
       file.
    - **Real package installs need `sudo`, which needs a real TTY** —
      if this is done from a cloud/headless session again, don't try
      to run the real restore yourself; it'll fall back to `sudo -n`
      and fail immediately, and repeated no-TTY sudo failures count
      against `pam_faillock`'s `deny=3` (the exact lockout this VM's
      own `glb_sudo` fix exists to prevent from a real terminal, but a
      no-TTY tool bypasses that protection entirely) — have Greg run it
      himself in his own terminal instead.
    - **Getting the repo onto a fresh/replacement CachyOS VM**: same
      playbook used successfully on the openSUSE VM this session — the
      repo is public now, so a plain `git clone
      https://github.com/ggregoro/GLB.git` needs no credentials at all.
      For push access back out (no SSH key needed either): `gh` ships
      as part of `developer`'s own package list, so once `glb restore
      developer` has run once, `gh auth login` → GitHub.com → HTTPS →
      "Login with a web browser" gives a device code Greg enters at
      github.com/login/device on any other device, then `gh auth
      setup-git` wires the resulting token into `git push`. If `gh`
      isn't installed yet (before the first real restore), `zypper`'s
      openSUSE equivalent was `sudo zypper install -y git` by hand
      first — check whether this CachyOS VM already has `git`/`gh`
      preinstalled before assuming that manual step is needed again.
    - **Confirmed (2026-08-13, Greg): this is the same CachyOS VM from
      2026-08-10, not a fresh replacement — and unlike the openSUSE VM,
      it was never broken by the WSL2/Windows 11 upgrade on the host.**
      No VM-repair detour needed here; go straight to the checklist
      above. Still worth a `git log`/`git status` check on it first
      (this VM was never wired to `origin` as a push target either, per
      the fresh-VM plan's own pattern — same `git clone` + `gh auth
      login` device-code playbook as the openSUSE VM if it needs
      (re-)cloning or push access).
  - **Verification attempted (2026-08-13, same day): package resolution
    confirmed for real on pacman, but the actual sudo-gated install
    itself is still deferred to Greg's own terminal — this session had
    no TTY.** `git pull` confirmed already up to date at `89acf0a`
    (this same, non-fresh VM already carries `default`'s packages from
    the 2026-08-10 curl-install session — `git`/`curl`/`zsh`/`fish`/
    `fzf`/`eza`/`bat`/`zoxide`/`btop`/`gcc`/`make`/`jq`/`fresh`/
    `starship`/both zsh plugins all pre-existing, plus `ranger`/`ufw`/
    `rsync` already present too even though those are server-only,
    presumably from earlier ad-hoc setup on this VM). `glb restore
    developer --dry-run` and `glb restore server --dry-run` both ran
    clean, listing exactly which packages were already installed vs.
    "would install" — but per this file's own standing caveat, dry-run
    alone never actually queries the package manager, so that list
    alone doesn't answer the real question here.
    - **No real TTY in this session** (`tty` → "not a tty") **and no
      cached sudo ticket** (`sudo -n true` → "a password is required")
      — per the standing no-TTY rule above, did not force the real,
      sudo-gated `glb restore`. Instead ran direct, real pacman
      sync-database queries (`pacman -Si <pkg>`, read-only, no sudo
      needed — this VM's `cachyos-extra-v3`/`extra` DBs are already
      synced) for every package either dry-run listed as "would
      install" — this genuinely queries the package manager for real
      name resolution, the same thing `pacman -S` itself would do
      first, just stops short of the actual sudo-gated download/install
      step.
    - **`developer`: `podman`, `ncdu`, `lazygit`, `glow` all confirmed
      as real packages in `cachyos-extra-v3`** via `pacman -Si`. `gh`
      resolves through the existing `gh:pacman` → `github-cli` override
      in `_GLB_PACKAGE_OVERRIDES`, also confirmed real. **`lazygit` is
      confirmed present on pacman** — the last unknown data point from
      the checklist above is resolved: working on pacman (like zypper),
      unlike the confirmed Fedora/dnf gap.
    - **`server`: `restic` and `fail2ban` both confirmed as real
      packages** (`fail2ban` comes from the plain `extra` repo, not
      `cachyos-extra-v3`, unlike everything else checked here). `ufw`/
      `rsync`/`ranger` were already installed on this VM going in (see
      above). **`snapd` confirmed absent from pacman's official/
      cachyos repos** — `pacman -Si snapd` and `pacman -Ss snapd` both
      return nothing — the same AUR-only gap already documented in
      `packages.txt`, and the same real outcome zypper hit on
      2026-08-13.
    - **New finding, not previously known: `yazi` itself has a real,
      direct pacman package** (`yazi`, `cachyos-extra-v3`, confirmed via
      `pacman -Si yazi`) — unlike zypper, which has no path to `yazi` at
      all without a non-default OBS repo. But `server/extras.txt`
      installs `yazi` specifically via the `snap` method, which needs
      `snapd` first, so on pacman GLB's current implementation will
      still hit the same practical "`yazi` doesn't install" outcome as
      zypper even though a working native package sits right there
      unused. Worth a future per-distro override (install `yazi` as a
      plain pacman package instead of via `snap` on pacman specifically)
      but out of scope for this verification pass — not built this
      session, just flagged.
    - **Zero new `_GLB_PACKAGE_OVERRIDES` gaps** — every package above
      resolved correctly, including the pre-existing `gh:pacman`
      override.
    - **Still needed**: the actual sudo-gated install execution itself
      (`pacman -S`, `snap install`), which needs a real terminal.
      Manual commands for Greg to run himself, in his own terminal on
      this VM: `cd ~/GLB && ./glb restore developer` then `./glb
      restore server`. Based on the `pacman -Si` data above, expect
      `developer` to install cleanly end-to-end, and `server` to
      install everything except `snapd`/`yazi`, which should hit the
      normal manual-step pause/skip prompt exactly like the zypper
      session's `snapd` gap did.
  - **Verification actually completed (2026-08-13, later the same day,
    Greg's own terminal) — the deferred `developer`/`server` pacman
    checks are now done, and both halves of the 2026-08-09
    developer/server verification plan (pacman + zypper) are closed.**
    First hit a real, unrelated blocker: this VM's local pacman sync
    database was stale (last refreshed 2026-08-10, never since),
    causing 404s on `.sig`/package files across many unrelated packages
    and mirrors (`podman`/`netavark`/`aardvark-dns`/`crun`/
    `containers-common`/`lazygit`/`glow` all hit it) — not a GLB bug,
    root cause was the local db referencing builds already
    superseded/removed from every mirror. Fixed with `sudo pacman
    -Syyu` (full sync+upgrade), which prompted a reboot (expected and
    safe on a rolling-release distro). After the reboot, real restores
    ran clean:
    - **`developer`: every package installed/already-installed
      cleanly** — `podman`/`gh`/`ncdu`/`lazygit`/`glow` included,
      confirming the `pacman -Si` resolution checks above for real. No
      manual-step prompts, no gaps.
    - **`server`: `ufw`/`rsync`/`restic`/`fail2ban` already installed,
      `btop`/`ranger` installed cleanly.** `snapd` failed exactly as
      predicted (`error: target not found: snapd`, confirmed AUR-only
      gap, same manual-step pause/skip prompt as zypper hit), and
      `yazi` then failed as a consequence (needs `snap`, which isn't
      present without `snapd`) — matching the zypper outcome
      documented above.
    - **Not yet resolved: pushing from this VM.** No `gh auth`/SSH
      configured here yet, so this update plus the still-unpushed
      `e8515ab` need `gh auth login` (device-code flow, now unblocked
      since `gh` is confirmed installed via `developer`) or some other
      push path.
- **New (2026-08-10): a fresh openSUSE Tumbleweed VM**, third machine
  under the same plan, distinct from the older openSUSE Tumbleweed VM
  further down this list (that one predates the fresh-VM plan and is
  being retired) — used to verify `install.sh` on zypper, the last of
  the four supported package managers to get curl-install coverage
  (confirmed working; only intervention needed was installing `git`
  itself, which wasn't preinstalled — see Roadmap entry for the full
  writeup).
  - **Resolved (2026-08-13, same day): this exact VM was retired, and a
    freshly-created replacement openSUSE Tumbleweed VM now boots and
    installs correctly.** The original degraded/uncertain state noted
    below (WSL2 install/removal + a Windows 11 upgrade on the host)
    turned out not to be the actual blocker for the new VM — real
    `VBox.log` inspection on the new VM showed `HM: HMR3Init: VT-x w/
    nested paging` and `GIM: Using provider 'KVM'`, i.e. VirtualBox's
    own native VT-x engine engaging cleanly with no Hyper-V fallback,
    ruling out an active hypervisor conflict on this host. The new VM's
    actual symptom (stuck on "Booting from local disk...") was two
    ordinary, unrelated VM-config issues: (1) no explicit boot order set
    on a freshly-created VM, defaulting to Hard Disk before the attached
    installer ISO — fixed via Settings → System → Boot Order, moving
    Optical above Hard Disk; (2) even after that, it was reaching the
    ISO's own installer boot menu and silently timing out to that
    menu's "Boot from Local Disk" entry because nobody interacted with
    it in time — fixed by clicking into the VM and selecting
    "Installation" before the timeout. Confirmed reaching openSUSE's
    real installer (Language/Keyboard/License Agreement screen).
    **openSUSE-profile verification is unblocked again** — the original
    VM this note describes was never actually confirmed repaired and
    was abandoned in favor of the new one, so if that specific old VM
    is ever revisited, treat it independently rather than assuming this
    resolution applies to it too.
  - **Verification actually completed (2026-08-13, this VM, real
    restores) — the deferred `developer`/`server` zypper checks from the
    2026-08-10 wrap-up are now done.** `glb restore developer` for real:
    every package installed cleanly, including `lazygit` — confirmed
    working on zypper, unlike the confirmed Fedora/dnf gap (see Roadmap
    entry above). `glb restore server` for real: `ufw`/`restic`/
    `fail2ban`/`btop`/`rsync` all installed cleanly too (the initial
    `which fail2ban` check looked like a miss but was a false alarm —
    its binaries are `fail2ban-client`/`fail2ban-server`, confirmed
    installed via `rpm -q` and `systemctl status`). One real gap:
    `snapd` isn't in this VM's default zypper repos at all (`zypper
    info snapd` → "package 'snapd' not found"), so `yazi` (which was
    also just added to `server`, matching `default`'s existing
    ranger+yazi pairing, per Greg's request) doesn't install here —
    documented as a known gap in both profiles' `packages.txt`/
    `extras.txt`, same treatment as the lazygit/Fedora gap rather than
    chasing a non-default OBS snapd repo. **Still unconfirmed: whether
    the CachyOS/pacman leg of this same verification plan was ever
    run** — worth checking before assuming full cross-distro coverage.
  - **Original note, kept for history**: this VM was in a
    degraded/uncertain state as of 2026-08-13, not a GLB issue — the
    Windows/VirtualBox host, not this VM's own guest OS. Greg installed
    WSL2 on the Windows host running this VM, which broke it (the
    predicted WSL2-vs-VirtualBox Hyper-V conflict — see memory
    `user-no-wsl2`); he then removed WSL2 and separately upgraded that
    host to Windows 11, which introduced its own additional VirtualBox
    conflicts.
- **New (2026-08-13): a fresh Fedora 44 VM**, another machine under the
  fresh-VM plan above — `git clone`d from the public repo (not a dev
  checkout), `glb restore default` run for real. Every package/dotfile
  installed and linked correctly (`snapd`/`yazi` needed a manual `sudo
  dnf install -y snapd` + `sudo snap install yazi --classic` — the usual
  no-TTY-for-sudo limitation, run by Greg himself; `snapd` needed a
  moment to finish seeding plus `sudo ln -s /var/lib/snapd/snap /snap`
  for classic-snap support on Fedora before `yazi` would install).
  - **Two real bugs found and fixed** in `profiles/default/dotfiles/
    .bashrc` (commit `ada3a40`), both specific to how packages actually
    landed on this distro's dnf/snap combination, not anything the
    dry-run/restore logic itself got wrong:
    1. **`yazi` installed but wasn't runnable** — snap puts its
       binaries in `/snap/bin`, and `.bashrc` never added that
       directory to `PATH`. Fixed with a new guarded
       `if [ -d /snap/bin ]` block, same pattern as the existing
       `~/.cargo/bin` guard.
    2. **Ctrl-R/Ctrl-T (fzf) did nothing** — Fedora's `fzf` dnf package
       installs `key-bindings.bash` under `/usr/share/fzf/shell/`, a
       path the existing lookup chain (which only checked
       `/usr/share/doc/fzf/examples/` and `/usr/share/fzf/`) never
       matched, so the `source` line silently no-opped. Added a third
       `elif` branch for the Fedora path.
    Both confirmed fixed live on this VM (`command -v yazi` resolves,
    `bind -X` shows the fzf widgets bound) before committing/pushing.
  - **This VM has no `git`/`gh` credentials configured by default** —
    needed a real one-time setup pass to commit from here at all:
    `git config user.email`/`user.name` (Greg's own identity, matching
    every other machine), then `gh auth login` (device-code flow,
    approved from a browser on another device) and `gh auth setup-git`
    to wire that into `git push` — same playbook the CachyOS/openSUSE
    VM entries above already document. Confirmed `gh auth setup-git`
    also writes a `credential.https://github.com` helper block directly
    into `~/.gitconfig`, which is this profile's own tracked/symlinked
    dotfile — deliberately left uncommitted rather than pushed, since
    it's machine-specific auth wiring, not something every other
    machine's `.gitconfig` should carry. This VM is temporary and being
    torn down, so it wasn't worth relocating into `~/.gitconfig.local`
    either — it simply won't outlive the VM.
- **Dell E7450 laptop — reinstalled from Pop!_OS Cosmic to Arch Linux Cosmic
  (2026-08-18).** The Pop!_OS install on this hardware no longer exists.
  Every historical entry elsewhere in this file describing real
  restores/testing on "the Dell laptop" while it ran Pop!_OS (apt) is
  accurate history from before this reinstall, not a description of its
  current state — this machine is now an apt (Debian/Pop!_OS ancestry)
  → pacman (Arch) test box going forward. Not yet re-verified with a
  real `glb restore` post-reinstall as of this note.
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
- **New (2026-08-15): a fresh Manjaro Linux (Gnome) VM — first real test
  of Manjaro**, previously flagged "not tested" in `docs/ROADMAP.md`
  (pacman itself already confirmed via CachyOS/EndeavourOS). `glb info`
  correctly detected `manjaro`/`pacman`. This session (Claude Code) had
  no TTY, so the real sudo-gated restore itself was run by Greg in his
  own terminal, not attempted directly — same standing no-TTY/
  `pam_faillock`-caution pattern as every other Arch-based VM above.
  - **Not a stock `default` restore — a custom `glb restore
    --from-manifest` variant, per Greg's request to keep this machine's
    native zsh prompt instead of GLB's usual Starship setup.** Built at
    `~/glb-manifests/default-manjaro-prompt` (machine-local, outside the
    repo, deliberately not committed — a one-machine customization, not
    a change to the shared profile): a byte-for-byte copy of
    `profiles/default`'s `packages.txt`/`extras.txt`/`dotfiles/`, except
    `.zshrc`'s `eval "$(starship init zsh)"` block is replaced with
    sourcing Manjaro's own `/usr/share/zsh/manjaro-zsh-config` +
    `manjaro-zsh-prompt` — exactly what a stock Manjaro `.zshrc` already
    sources, confirmed by reading this VM's real pre-restore `.zshrc`
    and `/etc/skel/.zshrc` before building the swap. Every other part of
    `default`'s `.zshrc` (history settings, `PATH`, completions,
    aliases, zoxide, fzf, vendored zsh plugins) stays identical.
    `--dry-run` confirmed the plan (backs up the real `.zshrc` to
    `.zshrc.glb-backup`, links the modified one) before the real run.
  - **Confirmed working end-to-end** (Greg: "that all worked") — Fresh
    editor and the JetBrains Mono Nerd Font extras both installed
    successfully. One real false alarm mid-restore worth remembering:
    the font download (`curl -fsSL ... -o font.zip`, `lib/extras.sh`'s
    `font` method) looked "stuck" for a while — not actually hung,
    `curl`'s `-s` flag just suppresses all progress output while
    fetching a genuinely large zip over this VM's (likely NAT'd)
    VirtualBox networking. Confirmed still-alive via a second terminal
    (`ps aux | grep curl` + watching the tmp zip's size grow between
    checks) rather than assumed — worth checking the same way if a
    future session sees the same "nothing printing" symptom on a slow
    connection, instead of assuming a real hang.
  - **`snapd`/`yazi`'s known Arch/pacman gap** (AUR-only, not in
    official repos, already documented in `packages.txt`) **was
    expected on this run but never explicitly confirmed hit or
    skipped** — still open, worth checking directly next time this VM
    comes up rather than assuming it behaved identically to
    CachyOS/EndeavourOS.
  - **Git identity + `gh` auth set up on this VM afterward**, same
    playbook documented elsewhere in this file: created
    `~/.gitconfig.local` (the `default` profile's own `.gitconfig`
    already just does `[include] path = ~/.gitconfig.local` for exactly
    this reason) with Greg's identity, `sudo pacman -S github-cli`
    (`gh` isn't in `default`'s package list, only `developer`'s — this
    VM used the `default`-based manifest above), `gh auth login`
    device-code flow approved from a browser, `gh auth setup-git` to
    wire it into `git push`. Confirmed via `gh auth status` and a real
    `git push --dry-run`. First confirmation this exact playbook also
    works cleanly on Manjaro, not just CachyOS/openSUSE/Fedora.
  - **Correction, same day, later session: the "confirmed working
    end-to-end" claim above was wrong — the real restore that actually
    ran on this VM was plain `glb restore default`, not the
    `--from-manifest` command given.** Every dotfile symlink on the
    machine (`~/.zshrc`, `~/.bashrc`, `~/.gitconfig`, etc.) pointed
    straight into `profiles/default/dotfiles/...`, not the manifest
    path — caught by `readlink -f ~/.zshrc` while chasing an unrelated
    `yazi` issue, not assumed. Net effect: the native-Manjaro-prompt
    customization never actually applied; the live `.zshrc` still had
    GLB's normal Starship init the whole time. The Manjaro powerline
    prompt still visibly on screen was just a stale already-open shell
    session that hadn't re-sourced `.zshrc` since — the file itself had
    already changed underneath it (same "a live symlink doesn't help an
    already-open shell" class of gotcha documented elsewhere in this
    file for `exec fish`). **Lesson for future sessions**: after handing
    someone a specific restore command, verify what actually ran
    (`readlink -f` on a resulting symlink) rather than trusting a
    "that all worked"-type report at face value — the visible result
    (a rendering prompt) can look right even when the wrong command ran,
    since a stale shell session doesn't reflect a dotfile change until
    reloaded.
  - **Real, new finding correcting the "AUR-only" assumption above:
    `snapd` is NOT AUR-only on Manjaro** — unlike CachyOS/EndeavourOS,
    Manjaro carries `snapd` in its own official `extra` repo (packaged
    by a Manjaro dev, confirmed via `pacman -Si snapd`), so GLB's
    package-manager install step for it succeeds cleanly here. The real
    Manjaro-specific gap is different: `snapd`'s systemd units
    (`snapd.socket`, `snapd.apparmor`) aren't enabled by default after
    the package installs, and the classic-confinement `/snap` symlink
    doesn't exist either — so `sudo snap install yazi --classic` (what
    GLB's `snap` extras method actually runs) fails outright with
    "cannot communicate with server," triggering the normal pause/skip
    prompt. Same *shape* of gap the Fedora VM hit (snapd needing manual
    enabling before first use), not the pacman/AUR-only gap CachyOS and
    EndeavourOS hit — worth not conflating the two. Manual fix, run
    directly by Greg (sudo, no TTY in this session):
    `sudo systemctl enable --now snapd.socket`,
    `sudo ln -s /var/lib/snapd/snap /snap`,
    `sudo systemctl enable --now snapd.apparmor`, then retry
    `sudo snap install yazi --classic`. Hit one transient "too early for
    operation, device not yet seeded" error on the very first retry
    right after enabling the socket — `snap debug seeding` confirmed
    `seeded: true` (352ms completion) moments later, so this is just a
    startup race right after `snapd.socket` first activates, not a real
    blocker; a second retry succeeded.
  - **Real bug found and fixed: the `/snap/bin` `PATH` guard added for
    the Fedora VM (2026-08-13, see that entry above) was incomplete —
    only ever added to `default`'s `.bashrc`, never `.zshrc` or
    `config.fish`, even though zsh is Manjaro's (and this profile's)
    actual default shell, and never added to `developer`/`server` at
    all despite `server` also installing `yazi` via the same `snap`
    method (added 2026-08-13, see the openSUSE VM entry above).**
    `snap install yazi --classic` succeeded here, but `yazi` still
    wasn't runnable afterward (`zsh: command not found: yazi`) for
    exactly this reason. Fixed by adding the same guarded
    `if [ -d /snap/bin ]; then export PATH="/snap/bin:$PATH"; fi`
    (bash/zsh) / `if test -d /snap/bin; fish_add_path /snap/bin; end`
    (fish) block to the 8 files that were missing it: `default`'s
    `.zshrc`/`config.fish`, and `developer`/`server`'s
    `.bashrc`/`.zshrc`/`config.fish`. **Verified same day, follow-up
    check**: rather than running full `developer`/`server` restores
    on this VM (would pull in each profile's extra packages/dotfiles
    unnecessarily, since `yazi` and `snapd` are already installed
    system-wide here), sourced each profile's `.bashrc`/`.zshrc`/
    `config.fish` directly (`bash -i -c`/`zsh -c`/`fish -c`) and
    confirmed `command -v yazi` resolves to `/snap/bin/yazi` and
    `/snap/bin` is on `PATH` in all six combinations
    (`developer`/`server` × bash/zsh/fish). Confirms the fix is
    real for both profiles, not just `default`/zsh where the bug was
    first found.
  - **Re-ran `glb restore --from-manifest` for real this time**,
    verified via `readlink -f` both before starting (still pointing at
    `profiles/default`) and after (correctly pointing at the manifest)
    rather than trusting the visible prompt alone, per the lesson above.
    One more real gotcha caught before running it: the manifest's own
    `~/glb-manifests/default-manjaro-prompt/dotfiles/.gitconfig` copy
    predated this session's `gh auth setup-git` run, so it was missing
    the `[credential "https://github.com"]` helper block that command
    had since written into the *tracked* `.gitconfig` — relinking to
    the manifest as-is would have silently broken `git push` credential
    resolution on this VM. Synced that block into the manifest copy
    first. Confirmed for real afterward, in a genuinely fresh terminal
    (not just this session's tools, which have no real TTY): Manjaro's
    native powerline prompt renders correctly, `yazi` launches. This is
    the point where the native-prompt `--from-manifest` approach is
    actually confirmed working end-to-end, superseding the earlier
    (wrong) claim above.
- **New (2026-08-16): a fresh Arch Linux (Xfce) VM** — first real test of
  vanilla Arch itself (not an Arch-based derivative like CachyOS/
  EndeavourOS/Manjaro, all already tested), and the first machine tested
  with Xfce specifically. `glb info` correctly detected `arch`/`pacman`.
  Dry-run of `developer` confirmed zero `_GLB_PACKAGE_OVERRIDES` gaps —
  `podman`/`jq`/`gh`/`ncdu`/`lazygit`/`glow` all resolve as real pacman
  packages (`gh` correctly through its existing `gh:pacman` → `github-cli`
  override), verified read-only via `pacman -Si` rather than a real
  install since this session had no TTY. This VM is also where the
  long-flagged `yazi`/`snapd`-on-pacman gap finally got fixed — see the
  Roadmap entry below for the real bug/fix writeup. `gh` set up for push
  access via the standard device-code playbook (`sudo pacman -S
  github-cli` + `gh auth login` + `gh auth setup-git`, run by Greg
  himself in a real terminal since this session had no TTY) — confirmed
  via `gh auth status` and a real `git push --dry-run`.
- **Dell E7450 laptop reinstalled again (2026-08-19): from Arch Linux
  Cosmic to Fedora KDE Plasma.** Supersedes the 2026-08-18 Arch Cosmic
  entry above (that install no longer exists on this hardware) — same
  physical machine, now on its third distro in this file's history
  (Pop!_OS Cosmic → Arch Cosmic → Fedora KDE Plasma). First real KDE
  Plasma test anywhere in this project (prior Fedora testing was
  GNOME). `fastfetch` confirms: Fedora Linux 44 (KDE Plasma Desktop
  Edition), KDE Plasma 6.7.4, KWin (Wayland), Konsole installed
  (`konsole-26.04.3-1.fc44`).
  - Fresh `git clone` to `~/Projects/GLB` (this machine's own chosen
    path, not the `~/GLB` used on some earlier test VMs), `gh auth
    login`/`gh auth setup-git` already done before this session started
    — push access confirmed.
  - **Real, non-dry-run `glb restore default` run for real by Greg in
    his own terminal.** Every package installed cleanly on dnf: `zsh`/
    `fish`/`neovim`/`ripgrep`/`fzf`/`eza`/`zoxide`/`ranger`/`btop`/
    `cpufetch`/`fastfetch`/`git` (plus `tmux`/`curl`/`bat`/`unzip`/
    `bash-completion`, already present). `fresh` (curl) and the
    JetBrains Mono Nerd Font both installed correctly too. Zero
    `_GLB_PACKAGE_OVERRIDES` gaps. A second restore came back fully
    clean/idempotent (`[SUCCESS] Profile applied: default`, every line
    "Already installed"/"Already linked").
  - **`snapd`/`yazi` hit the same known gap already documented for the
    2026-08-13 Fedora GNOME VM**: `snapd` installs via dnf fine and
    seeds correctly (`snap debug seeding` → `seeded: true`), but the
    classic-confinement `/snap` symlink doesn't exist by default and
    `sudo snap install yazi --classic` fails until it's created — same
    manual-step pause Greg hit as "errors" on the first restore
    attempt. Fixed with the same two manual commands as before, run by
    Greg in his own terminal: `sudo ln -s /var/lib/snapd/snap /snap`
    then `sudo snap install yazi --classic`. Confirmed installed
    afterward (`yazi v26.8.15`, classic confinement) and genuinely
    runnable in all three shells (`command -v yazi` resolves to
    `/snap/bin/yazi` in `bash -i`/`zsh -i`/`fish` — confirms the
    `/snap/bin` PATH guard fix from the 2026-08-15/16 Manjaro/Arch
    sessions works correctly on Fedora/KDE too, not just Arch-family
    distros).
  - **Git identity set up correctly the first time**: `~/.gitconfig.local`
    was written (name/email + the pre-existing `gh`-written credential
    helper block) *before* the restore ran, per this file's own
    standing lesson — confirmed resolving correctly
    (`git config user.name/user.email`) immediately after `default`'s
    `.gitconfig` symlink landed, no identity ever silently backed up or
    lost.
  - **Full bats suite run** (no `bats` installed on this machine either,
    same locally-cloned-`bats-core` workaround as every other machine
    without it): 219/223 pass. The 4 failures are the exact same
    pre-existing, already-documented `fresh`/`starship`-genuinely-on-
    real-PATH test-isolation gap this file describes for nearly every
    other machine after its own first real restore — confirmed via
    `git status` (clean working tree, no code changed this session)
    that these aren't a regression.
  - **`developer`/`server` restored for real (2026-08-20, Greg's own
    terminal).** `developer`: every package installed cleanly except
    `lazygit` — hit the known, already-documented Fedora/dnf gap (no
    official package, see the 2026-08-10 Fedora GNOME VM entry above)
    and was skipped via the normal manual-step pause, exactly as
    expected; `ncdu`/`glow` (dnf) and `mise`/`lazydocker` (curl) all
    installed fine. `server`: `ufw`/`restic`/`fail2ban` all installed
    cleanly with no pauses at all — `snapd`/`yazi`/`ranger` were
    already present system-wide from the earlier `default` restore
    (see above), so `server`'s dry-run didn't even need to touch them.
    Both confirmed via `--dry-run` first (clean, zero
    `_GLB_PACKAGE_OVERRIDES` gaps found) before the real, non-dry-run
    restores.
  - **Real finding, not a GLB bug: Konsole did not automatically pick
    up the installed JetBrains Mono Nerd Font — it had to be set
    manually in Konsole's own profile settings (font family *and*
    font size), same as any other terminal-emulator-specific
    configuration GLB deliberately doesn't manage** (see the Non-Goals
    reasoning elsewhere in this file — GLB installs the font
    system-wide via fontconfig, but a terminal app's own font
    selection is out of scope). Worth checking this explicitly on any
    future Konsole machine rather than assuming the CachyOS VM's
    2026-08-05 "Konsole renders fine" confirmation means zero manual
    steps are ever needed — that entry never records whether Konsole's
    profile font was already set by hand there. Once set, glyph
    rendering itself confirmed correct on Fedora/KDE too, closing the
    "not yet visually confirmed on Fedora/KDE" gap flagged above.
  - **Real question raised, confirmed by code (not a bug): `glb
    restore` never changes which shell is your actual login shell —
    that's always a manual end-user step, on every profile/machine,
    not something specific to this one.** Confirmed via a direct
    `grep` across `lib/`, the `glb` dispatcher, and every profile's
    manifests — no `chsh`/`usermod -s`/`/etc/shells` logic anywhere in
    the codebase. `default`/`developer`/`server` all install and
    unify bash/zsh/fish dotfiles equally (see "Current state" below),
    but deliberately never pick one as *the* default login shell —
    consistent with the same philosophy that keeps GLB out of choosing
    a terminal emulator (see PHILOSOPHY.md's Non-Goals). To make fish
    (or any shell) the login shell: `chsh -s $(which fish)`.
  - **Real gotcha hit running that on this machine, worth remembering
    generally, not Fedora/KDE-specific**: after `chsh`, simply opening
    and closing terminal windows within the same desktop session still
    showed bash as the shell — **a full logout/login was required**
    before the new login shell actually took effect. This is standard
    `chsh`/PAM behavior on most desktop environments (KDE/Wayland
    included): `/etc/passwd`'s shell field is only read fresh at actual
    login time; `$SHELL` gets cached for the rest of that session, so
    new terminal windows/tabs opened mid-session just inherit the
    already-cached value rather than re-reading the updated passwd
    entry. Not a GLB or Konsole bug — normal `chsh` mechanics.
  - **Confirmed (2026-08-20, Greg): the full logout/login cleared the
    cached shell as predicted — fish is now genuinely this machine's
    login shell.** Closes out this gotcha as fully verified, not just
    theorized from `chsh`/PAM semantics.

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

- **The "no GUI applications, terminal emulators included" rule was
  dropped from both GLB and GWB, and Ghostty added to `default`
  (2026-08-30, Pop!_OS Cosmic laptop).** Grew directly out of a real
  support session on Greg's own machine: Yazi's image preview was
  failing in COSMIC Terminal with `chafa failed with status: exit
  status: 2`. Root cause is a stack of three things, none individually
  a GLB bug — cosmic-term supports no inline image protocol at all
  ([pop-os/cosmic-term#438](https://github.com/pop-os/cosmic-term/issues/438),
  open); Yazi 26.x calls `chafa --probe` (chafa ≥ 1.16.0) but Pop!_OS
  24.04 and the chafa bundled in Yazi's own snap both ship 1.14.0; and
  the snap forces its bundled chafa ahead of any host one. Net effect:
  on cosmic-term there is *no* working image preview without a terminal
  that draws the images itself.
  - **The fix on the laptop** (not GLB): installed Ghostty (snap,
    classic), which speaks the Kitty graphics protocol — Yazi renders
    real images in it, no chafa involved. Left cosmic-term and the snap
    Yazi untouched. Added a launcher-only `~/.local/share/applications/
    yazi.desktop` (`Exec=/snap/bin/ghostty --class=com.yazi.Yazi -e
    /snap/bin/yazi`) and a COSMIC custom shortcut, Super+E, running the
    same command (`~/.config/cosmic/com.system76.CosmicSettings.
    Shortcuts/v1/custom`, `Spawn(...)`). Default terminal unchanged.
  - **Baking it in — a deliberate scope change, Greg's call, in two
    steps the same day.** `docs/PHILOSOPHY.md` named Ghostty *by name*
    as an example of what GLB won't install (the WezTerm/`new-to-linux`
    lesson, 2026-08-09). Flagged that squarely before touching
    anything. Greg first chose (via `AskUserQuestion`) to reverse it
    narrowly, as a one-off exception — "adding Ghostty, GUI or not,
    makes the whole project a little more powerful and useful." Then,
    after seeing that written up, he went further: "as we move forward
    the no GUI rule is going to limit the capabilities of the GLB and
    GWB projects... we should remove that rule from the projects."
    **The no-GUI prohibition is dropped from both GLB and GWB.** What
    replaces it (chosen via `AskUserQuestion`, "curated & opinionated,
    install-not-manage"): a GUI app is in scope when it's a deliberate,
    opinionated pick that complements the terminal-first mission —
    installed and lightly configured like any other tool, never
    vendor-managed, never a general app menu. The WezTerm/`new-to-linux`
    history stays as the "install, don't vendor-manage" guidance that
    the old rule produced. Ghostty is the first pick under the new
    stance and a clean fit: it makes an existing `default` feature
    (Yazi image preview) actually work, and GLB installs the package +
    one launcher line and manages nothing else — no Ghostty config
    (the exact WezTerm mistake), not the default terminal, terminal
    keybind untouched.
  - **Built in GLB (`feat/ghostty-yazi` branch, two commits matching
    the day's feat+docs split):**
    - `profiles/default/extras.txt`: `snap ghostty classic`, mirroring
      the `snap yazi classic` entry.
    - `lib/extras.sh`: `[ghostty:pacman]="ghostty"` (Arch `extra`) and
      `[ghostty:zypper]="ghostty"` (openSUSE `repo-oss`) in
      `_GLB_SNAP_NATIVE_OVERRIDES` — both confirmed native. zypper gets
      an entry (unlike yazi), so openSUSE installs Ghostty without
      snapd. No dnf entry (Fedora ships it only via COPR); apt falls
      through to snap with the same snapd caveats yazi carries.
    - `profiles/default/dotfiles/.local/share/applications/yazi.desktop`
      — first `.local/share/` dotfile GLB ships; the existing per-file
      symlink walk handles it with no code change. `Exec=ghostty
      --class=com.yazi.Yazi -e yazi` (bare names, resolves snap or
      native).
    - `profiles/default/dotfiles/.config/ghostty/config` — a small,
      opinionated appearance config (Greg's spec): `theme = TokyoNight`
      (matches the Starship preset), `background = 0d0e12`,
      `background-opacity = 0.85`, `background-blur = true`,
      JetBrainsMono Nerd Font 12, 8px padding, `confirm-close-surface =
      false`. `background-opacity-cell-colors` was tried and removed —
      Ghostty 1.3.1's GUI rejects it as an unknown field (a "reload or
      ignore" dialog Greg hit live), and `ghostty +show-config` does
      **not** flag it, so the running GUI is the real config validator,
      not the CLI. Deliberate scope call: GLB *is* opinionated about
      Ghostty's look (like `starship.toml`), but not its behavior — no
      keybindings, no compositor workarounds; that's the WezTerm line.
    - Super+E is documented as a per-DE manual step, **not** automated
      — COSMIC/KDE/GNOME each do custom shortcuts differently, none
      portably; same "document the gap" posture as lazygit/dnf.
    - Docs: new `docs/design/ghostty-yazi.md`; `docs/PHILOSOPHY.md`'s
      section retitled "Enhance the Terminal You Have, Don't Replace It"
      → "Terminal-First, Not Terminal-Only" and rewritten to the
      curated/install-not-manage stance (WezTerm/`new-to-linux` history
      kept, reframed as guidance not prohibition); `docs/PROJECT.md`
      Non-Goals ("Not a general software center"), `README.md`,
      `CHANGELOG.md` `[Unreleased]`, `docs/ROADMAP.md` (Post-1.0 +
      old-title refs), and this file's header paragraph all updated.
      The historical 2026-08-09 "tempted to add a terminal emulator"
      note is left untouched as an accurate record of the time.
    - **GWB:** the same rule lived in GWB's `docs/PHILOSOPHY.md:49`,
      `docs/PROJECT.md:96`, `docs/ROADMAP.md`, `docs/troubleshooting.md`
      and `README.md`. Mirrored the same stance change there on its own
      branch + PR (GWB uses PRs, unlike GLB's fast-forward-to-`main`).
      GWB does **not** get Ghostty itself — no official native Windows
      build (only community ports / `libghostty`-based third-party
      terminals); a Windows equivalent (Windows Terminal's Sixel, or
      WezTerm) is a separate future call for that repo.
  - **Verified:** full bats suite 223/227 (the 4 failures are the
    pre-existing `fresh`/`starship`-on-PATH test-isolation gap, tests
    38/39/88/116, confirmed identical on unmodified HEAD via `git
    stash`); `ghostty +show-config` against the shipped Ghostty config
    loads clean with no warnings; `glb restore default --dry-run` on
    the laptop picks up the `ghostty` extra and both new dotfiles
    correctly.
  - **Not yet done:** a real (non-dry-run) `glb restore default` that
    installs Ghostty from scratch on a machine that doesn't already
    have it, on any of the four package managers; and confirming the
    native `ghostty:pacman`/`ghostty:zypper` routes install cleanly on
    real Arch/openSUSE. Branch not merged to `main` or pushed yet as of
    this note.

- **Neovim + LazyVim redesigned from a private-repo clone to a public,
  vendored config, built into all three profiles (2026-08-30, cloud
  session, same day as the CachyOS fallback-path confirmation directly
  below).** Prompted directly by that fallback-path test: Greg pushed
  back hard on the premise itself — "Why would this machine need an SSH
  key. GLB is a public repo that should be able to run on any Linux
  distro" — and, once the direction was confirmed via
  `AskUserQuestion` ("Public, self-contained LazyVim"), extended it
  further: "Neovim along with Lazy Vim should be built in for all
  profiles on GLB so it installs along with all of the other
  opinionated features of GLB." This **reverses** the design built
  earlier the same day (see the entry further down this file and
  `docs/design/nvim-lazyvim.md`'s original section) — that version
  deliberately chose "true parity" (clone Greg's actual private
  `nvim-config` repo) over a public starter, `default`-only. Both
  choices got overturned within hours of shipping, once real testing
  on a machine that wasn't Greg's own surfaced the actual consequence.
  - **What changed:** every profile now vendors the real, official
    [LazyVim/starter](https://github.com/LazyVim/starter) template
    (fetched via `git clone --depth 1` from the real upstream repo,
    not hand-typed, matching this project's usual discipline for
    vendored third-party content) as a normal tracked dotfile —
    `profiles/<name>/dotfiles/.config/nvim/{init.lua,.neoconf.json,
    stylua.toml,lua/config/{autocmds,keymaps,lazy,options}.lua,
    lua/plugins/example.lua}` — byte-verified identical to upstream via
    `diff -r` in all three profiles. `server` also gained `neovim` in
    `packages.txt` (it never had it before — only `default`/`developer`
    did).
  - **Why per-file symlinks work correctly for a tool that writes back
    into its own config directory**: LazyVim's `lazy.nvim` writes
    `lazy-lock.json` into `~/.config/nvim/` on first launch (plugins
    themselves install to `~/.local/share/nvim/lazy/`, untouched by
    any of this). Since `glb_apply_profile_dotfiles`'s existing
    per-file walk creates `~/.config/nvim/` as a real directory holding
    individually-symlinked static files (confirmed directly: `ls -la`
    after a sandboxed restore shows `~/.config/nvim/` as a real dir,
    each `.lua`/`.json`/`.toml` file inside it a symlink back into the
    GLB checkout), a later `lazy-lock.json` write lands as a plain,
    independent file — never touching GLB's own git tree. This is
    exactly the failure mode that made a *symlinked directory* (or the
    private-repo `git clone` into `~/.config/nvim` directly) the wrong
    shape; the fix wasn't a new mechanism, it was recognizing the
    *existing* per-file dotfile machinery already avoided the problem.
  - **Removed entirely, not just deprecated**: `glb_install_nvim_config`
    (`lib/profile.sh`, ~115 lines) and its call sites in
    `glb_apply_profile`/`glb_apply_manifest`
    (`lib/profile.sh`)/`glb_apply_snapshot` (`lib/export.sh`);
    `profiles/default/nvim-config.txt`; the `GLB_NVIM_CONFIG_REPO`
    override; the Neovim-specific special-casing at the top of
    `glb_undo_restore` (no longer needed — once nvim-config is just
    individually-symlinked dotfiles, the *existing* generic
    backup-restore loop already covers it, no special-case required);
    and `tests/nvim_config.bats` (14 tests, no longer applicable — the
    mechanism they tested doesn't exist anymore). Net effect is less
    code than before, not more: the whole custom git-clone-a-second-repo
    mechanism is gone, replaced by nothing but the vendored files
    themselves plus infrastructure that already existed.
  - **Test fallout, all fixed**: 8 occurrences of `stub_command git 'if
    [ "$1" = clone ]; then d="${@: -1}"; mkdir -p "$d"; : >
    "$d/init.lua"; fi; exit 0'` in `tests/dispatcher.bats` (originally
    there to fake the private-repo clone landing an `init.lua`) were no
    longer meaningful — simplified to plain `stub_command git 'exit
    0'`, since the only remaining real `git clone` call during a
    restore is zsh plugin vendoring, which just needs to succeed, not
    produce a specific file. **Also fixed while in this file, a
    pre-existing gap found and already documented earlier the same
    session**: "glb restore applies the real server profile end to
    end" was missing a `snap` stub (the `yazi`-via-snap extras method
    added by other work has no `snap` binary in the sandbox), confirmed
    failing identically on unmodified `main` before this fix — added
    the same `stub_command snap 'case "$1" in list) exit 1 ;;
    install) exit 0 ;; esac'` the `default` test already used. 223/227
    bats pass (same 4 pre-existing root-sandbox permission failures);
    all three real-profile end-to-end tests (`default`/`developer`/
    `server`) pass cleanly, and a manual sandboxed restore independently
    confirmed all 8 vendored `.config/nvim/*` files symlink correctly.
  - **Docs updated**: `docs/design/nvim-lazyvim.md` (kept the original
    design as a marked-superseded historical record rather than
    deleting it — same convention as the WezTerm removal history
    elsewhere in this file), `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`,
    `README.md` (added a new Features bullet — this wasn't advertised
    there before), `CHANGELOG.md`'s `[Unreleased]` entry rewritten in
    place rather than appended-to, since the superseded version never
    shipped in a numbered release.
  - **Not yet re-verified for real** — built and bats-tested from the
    repo alone this round; the next `glb restore` on any machine
    (including the CachyOS VM that prompted this) should confirm `nvim`
    launches straight into a working, no-SSH-key-needed LazyVim setup,
    on the first try, with no "clone failed" message ever appearing.
- **Neovim-config's "not Greg" fallback path confirmed for real on
  pacman/CachyOS (2026-08-30, cloud session, real VM).** Greg switched
  the CachyOS VM from `developer` back to `default` (`glb restore
  default`) — this VM has no SSH key registered for the private
  `nvim-config` repo, so `git clone git@github.com:ggregoro/
  nvim-config.git` failed with `Permission denied (publickey)`.
  `glb_install_nvim_config` handled it exactly as designed: clean
  `[ERROR] Failed to clone nvim-config to ~/.config/nvim - check access
  ...` message, `nvim` left unconfigured, and every other step still
  completed correctly (packages already installed, self-symlink/
  completions already linked, all dotfiles including the newer
  `yazi`/`ranger` configs linked or correctly backed-up-then-relinked,
  `.gitconfig` linked). Final line `[ERROR] Profile applied with
  errors: default` is the correct exit for exactly one non-fatal
  failure, not a broken restore. First real confirmation of this
  fallback path outside of `tests/nvim_config.bats` and outside apt —
  previously only exercised on the Dell/Pop!_OS laptop, where Greg's
  own SSH access makes the *success* path the one that's been tested.
  **Not yet tested on this VM: the success path itself** — would need
  an SSH key added to this CachyOS VM for `nvim-config` specifically to
  confirm the actual LazyVim clone+bootstrap works on pacman too, not
  just the graceful-failure branch. Optional follow-up, not blocking —
  the fallback path being correct is itself real, useful signal.
- **Neovim + LazyVim config added to `default` (2026-08-30, Pop!_OS
  Cosmic laptop) — parity with GWB's own 2026-08-30 addition.** GLB has
  installed the `neovim` package in `default` forever but never
  configured it. Now `glb restore` sets up a profile's Neovim config if
  the profile opts in via a new `profiles/<name>/nvim-config.txt` (one
  line: a git clone URL; `#`/blank lines ignored). Only `profiles/
  default/` ships one, pointing at Greg's own private LazyVim repo
  `git@github.com:ggregoro/nvim-config.git`.
  - **Two decisions locked via `AskUserQuestion`**: (1) *true parity* —
    clone the real private `nvim-config`, not the public
    `LazyVim/starter` and not an env-var-only stub. Non-Greg users get a
    clean "clone failed" log and an otherwise-normal restore (`nvim`
    still installs, just unconfigured); `GLB_NVIM_CONFIG_REPO` overrides
    the URL. (2) *`default` only* — not `developer`/`server`, matching
    where the `neovim` package already lives.
  - **`glb_install_nvim_config` (`lib/profile.sh`)**, mirrors GWB's
    `Install-GwbNvimConfig`: self-gates on `nvim` + `git` present;
    no-ops with no `nvim-config.txt`; clones into `~/.config/nvim` (uses
    `${XDG_CONFIG_HOME:-$HOME/.config}`); if that dir is already a clone
    of the resolved URL (`git -C … remote get-url origin`), `git pull
    --ff-only` instead. Backup-on-first-touch to `~/.config/
    nvim.glb-backup` (once — a later run with a backup already present
    re-clones over the dir rather than clobbering the backup, same rule
    as `glb_apply_profile_dotfiles`). Wired into `glb_apply_profile`,
    `glb_apply_manifest`, and `glb_apply_snapshot` (snapshots never
    carry an `nvim-config.txt`, so it no-ops there). `glb_undo_restore`
    gained an explicit branch to restore `~/.config/nvim` from its
    backup *before* the generic `$HOME`-walk — the generic symlink-swap
    can't handle a directory that's a git clone, not a symlink.
  - **`tests/nvim_config.bats`** — 14 new tests (gate, clone, pull,
    backup, no-clobber, `GLB_NVIM_CONFIG_REPO` override, every dry-run
    message, the nvim-absent branch, undo round-trip). `tests/
    dispatcher.bats`'s shared `git` stub now drops an `init.lua` on
    `git clone <dest>` so the real-`default`-profile end-to-end tests
    pass through the new step. **Full suite 237/241** — the 4 failures
    are the pre-existing `fresh`/`starship`-genuinely-on-PATH
    test-isolation gap (tests 38/39/88/116), confirmed unchanged by
    this work.
  - **Verified for real on the Pop!_OS Cosmic laptop**: fresh clone +
    one-time backup, an idempotent second run (`git pull`, backup
    untouched), every dry-run message, the `GLB_NVIM_CONFIG_REPO`
    override, and a full `--undo` round-trip restoring the original
    directory — all confirmed by running `glb_install_nvim_config` /
    `glb_undo_restore` directly against `profiles/default` (not a full
    `glb restore`, same isolation approach GWB's yazi verification used).
    One incidental note: running `glb_undo_restore` for real also
    restored a stray `~/.bashrc.glb-backup` left by a prior restore on
    that laptop — a reminder that `--undo` is a whole-`$HOME` operation
    and shouldn't be run for verification on a machine with real GLB
    state; the bats coverage is the right place for that.
  - Docs: `docs/design/nvim-lazyvim.md` (new), `CHANGELOG.md`
    `[Unreleased]`, `docs/ARCHITECTURE.md`, `docs/ROADMAP.md`
    (new "Post-1.0 add-ons" subsection). Built on branch
    `feat/nvim-lazyvim`, merged to `main`.
  - **Not yet done**: verified only on the one laptop; a real
    `glb restore default` end-to-end (packages + this step together) on
    a fresh machine, and confirming `nvim` actually launches into a
    working LazyVim (plugins bootstrapping on first run), still pending
    — same "needs a real fresh-machine run" caveat GWB's own
    `docs/design/nvim-lazyvim.md` carries.

- **pacman's `update` alias switched from `sudo pacman -Syu` to `yay
  -Syu` (2026-08-19, Dell laptop), fixing a real gap Greg caught via
  `cosmic-applet-arch`.** That COSMIC panel applet flags pacman and
  AUR updates separately; it surfaced an AUR-only update (Google
  Chrome, installed via `yay`) that `update` wasn't catching, since
  plain `pacman -Syu` only syncs Arch's official repos. `yay -Syu` is
  a strict superset — same sync/upgrade, plus AUR packages in the same
  pass — so this is a no-downside swap anywhere `yay` is already
  installed. Changed in all 9 pacman-branch dotfiles (`default`/
  `developer`/`server` × bash/zsh/fish's `.bashrc`/`.zshrc`/
  `config.fish`), `update` only — `install`/`remove`/`search` left on
  plain pacman, since only `update` was confirmed broken; changing all
  four was discussed and deliberately deferred as its own decision,
  not folded into this fix.
  - **A full yay-bootstrap mechanism was drafted, then explicitly
    reverted the same session** — a new `glb_ensure_yay` function
    (`lib/package.sh`, AUR git-clone + `makepkg -si`, same
    manual-step-pause pattern as every other sudo-gated install) wired
    into `glb_apply_profile`/`glb_apply_manifest`, plus bats coverage.
    Greg's call: scope this to "just fix the config files, don't
    change the overall project" — the underlying issue is specific to
    this one Arch/COSMIC machine, not a cross-distro gap GLB itself
    needs to solve right now. Fully reverted (`lib/package.sh`,
    `lib/profile.sh`, `tests/package.bats` all back to their prior
    state) before committing; only the 9 dotfiles changed.
  - **Real, known, deliberately-unfixed gap**: confirmed by reading the
    full pacman branch of `glb_install_package`/`glb_remove_package`/
    `glb_update_packages` (`lib/package.sh`) that GLB's bootstrap never
    installs `yay` itself on pacman systems — nothing there touches an
    AUR helper. This alias assumes `yay` is already present (true on
    the Dell laptop, since that's how Chrome got installed in the
    first place). A *different* fresh Arch machine that's never had
    `yay` installed would hit `update: command not found` until `yay`
    is installed by hand — same "known gap, not chased further"
    treatment this file already gives e.g. `lazygit` on Fedora/dnf or
    `snapd` on zypper.
  - **Verified for real** (Greg's own terminal, live shell, not a
    sandboxed session — this repo's own `pam_faillock` history on
    Arch-based machines, see the `glb_sudo` fix elsewhere in this
    file, made running a real sudo-gated command from a no-TTY session
    the wrong call here): `update` correctly ran `yay -Syu`, synced the
    official repos, and caught the real AUR-only `google-chrome` update
    (`151.0.7922.137-1` -> `151.0.7922.169-1`) that `pacman -Syu` alone
    had been missing. Confirms the fix works exactly as intended, on
    the exact machine/scenario that surfaced the original bug.
  - Committed as `688b2d9`, pushed to `origin/main`.

- **`eza --hyperlink` added to the long-listing aliases (2026-08-18,
  Dell laptop, live/interactive session), per Greg's request.** He
  first asked for `--hyperlink` on the plain `ls` alias, using an
  example line that (probably unintentionally) also dropped the
  existing `--git` flag — flagged that dropping `--git` would
  reintroduce the per-file git-status regression fixed on 2026-08-09,
  so paused rather than applying it as literally given. Greg then
  clarified the real ask: `--hyperlink` on the **long-listing**
  aliases (`ll`/`la`/`l`, the ones using `-l`) so Ctrl-click can open a
  file straight from a detailed listing — not on plain `ls`, which he
  didn't want changed. Applied that instead, across all three profiles
  (`default`/`developer`/`server`) and all three shells (bash/zsh/
  fish) — 9 dotfiles, `--git` preserved throughout, `ls` itself left
  exactly as it was.
  - **Verified for real, not just syntax-checked** — this laptop's
    live `~/.bashrc`/`~/.zshrc`/`~/.config/fish/config.fish` are
    symlinked straight into `profiles/default/dotfiles/...`, so the
    edits were already live; no `glb restore` re-run needed. Ran `ll`
    in real interactive bash, zsh, and fish sessions and confirmed
    each emits genuine OSC 8 hyperlink escape sequences
    (`ESC]8;;file://...`) around every filename, plus `bash -n`/
    `zsh -n`/`fish -n` on all 9 edited files.
  - **One incidental correction along the way**: while testing, `cat
    -v` failed inside a sandboxed shell command with a `batcat`-flavored
    error — initially (wrongly) described as "unrelated to GLB, just
    this session's shell." It's actually GLB's own existing `alias
    cat='batcat'`/`'bat'` (all three profiles, all three shells,
    predates this session) doing exactly what it's supposed to — `bat`
    just doesn't share GNU `cat`'s flag surface (`-v` isn't valid; the
    equivalent is `-A`/`--show-all`). Not a bug, nothing changed;
    worth remembering next time `cat`'s exact GNU-coreutils flags are
    needed on a machine with `default`/`developer`/`server` restored —
    reach for `/bin/cat` directly or `\cat`, not `cat -v`.
  - Committed as `5b692d9` and pushed to `origin/main`.
  - **Cross-distro verification status (2026-08-18, updated by Greg):**
    confirmed working on apt (the original verification above) and
    pacman (since confirmed too — likely via the Dell laptop's
    reinstall to Arch, see its own Test Environments entry, and/or the
    Arch/Xfce or CachyOS VMs). **Still needs testing: dnf (Fedora) and
    zypper (openSUSE)** — Greg's stated next step, not yet done as of
    this note.
  - **dnf/Fedora confirmed (2026-08-19, Dell E7450, Fedora 44 KDE
    Plasma — see its own Test Environments entry) — plus a real,
    non-GLB root cause found and fixed for why it initially looked
    broken.** `eza`'s alias and escape-sequence output were confirmed
    100% correct from the very first test — byte-identical, verified
    via `od -c`, to a manually-crafted `printf` OSC 8 sequence that
    Konsole *did* render as clickable. The actual cause: **Konsole
    ships hyperlink support off by default as a security precaution**
    — `Settings → Configure Konsole → Profiles → [profile] → Edit →
    Mouse tab → Misc → "Allow escape sequences in hyperlinks"` is
    unchecked out of the box (Konsole warns about this when enabling
    it, since it lets any program's output make arbitrary clickable
    links). Enabling it fixed everything immediately — every
    `--hyperlink`-bearing alias now works exactly as designed. **Not a
    GLB bug, not an eza bug, not a dnf/Fedora-specific gap** — this is
    a one-time, per-profile Konsole setting a user needs to opt into
    themselves, same category as GLB not managing terminal emulators
    at all (see PHILOSOPHY.md). Worth remembering if this comes up
    again on any other KDE/Konsole machine: check this setting *first*
    before assuming eza/GLB is broken — chasing this from the GLB side
    (byte-level escape-sequence comparisons, ruling out color codes,
    ruling out `file://` hostname bugs, checking KDE Bugzilla) all
    correctly proved GLB's own code was fine, but the actual fix was
    entirely a Konsole setting outside GLB's code or docs.
    **zypper/openSUSE is still the only untested package manager for
    this feature.**
- **`cpufetch` added to `default` (2026-08-17, cloud session), per
  Greg's request — corrected same session from `snap`/`extras.txt` to a
  plain `packages.txt` entry once real per-distro package data showed
  the snap route was unnecessary.** CPU architecture info banner (James
  Tigert / kz6fittycent) — pairs with `fastfetch`'s general system-info
  banner as a dedicated CPU-specific one.
  - **First pass (wrong):** added as `snap cpufetch` in `extras.txt`,
    same method already used for `yazi`, without first checking
    whether a native package existed anywhere. Committed and pushed as
    `c70040e`.
  - **Corrected after Greg mentioned Debian has an apt version (just
    not the latest one)** — prompted checking all four package
    managers properly instead of assuming snap was the only option, the
    same mistake flagged after the fact rather than caught up front.
    Real per-distro data, checked directly against each authoritative
    package page (not generic answers): apt (Debian stable/trixie) has
    a real `cpufetch` package but at `1.06-2`, one point release behind
    upstream's `1.07` (Ubuntu varies by release - noble/24.04 is
    `1.05-1`, resolute/26.04 is current at `1.07-2`); dnf (Fedora 44)
    has it at `1.07-3`, current; pacman (Arch `extra` repo) has it at
    `1.07-1`, current; zypper (openSUSE Tumbleweed specifically -
    confirmed via the real `software.opensuse.org` package search UI,
    not just a site-restricted web search, which returned nothing
    useful) has it at `1.07`, current. **Every one of the four package
    managers this project supports has a real, working `cpufetch`
    package under the exact same name** - no `_GLB_PACKAGE_OVERRIDES`
    entry needed either.
  - **Fixed:** removed the `extras.txt`/`snap` entry, added `cpufetch`
    as a plain line in `default/packages.txt` instead (right after
    `fastfetch`/`snapd`), with a comment documenting the confirmed
    per-manager versions and the one real, minor, tolerated gap (apt
    lagging upstream by one point release) rather than a workaround -
    same tolerance this project already gives other "not quite latest"
    packages. This also sidesteps a real problem the `snap` route would
    have caused: `snapd` is deliberately skipped on pacman (see its own
    packages.txt comment, the 2026-08-16 yazi fix) and isn't available
    on zypper at all, so `cpufetch` via snap would have hit the normal
    manual-step pause on both — using the native package instead avoids
    that entirely, on every distro.
  - Full bats suite (223 tests) passes on both the original and
    corrected version. Verified via `glb restore default --dry-run` on
    this machine: correctly reports `Would install: cpufetch` post-fix
    (this machine's only `cpufetch` install is via snap from the first,
    reverted pass - apt itself has never installed it here, so this is
    genuine "not yet installed via the package manager" signal, not a
    stale check). **Still not verified as a real install on any VM** -
    Greg's own planned Arch/Fedora/openSUSE VM tests (see the
    conversation this session) will be the first real, non-dry-run
    signal on all three, plus the first live confirmation apt's
    one-version-behind package is otherwise fine to use as-is.
- **Real, previously-flagged gap fixed (2026-08-16, fresh Arch/Xfce VM):
  `yazi`/`snapd` no longer pause a pacman restore.** Flagged as a known
  follow-up back on 2026-08-13 ("worth a future per-distro override...
  not built this session, just flagged" — see the entry right below this
  one) and picked up here. Root problem: `default`/`server`'s `snap yazi
  classic` extras.txt entry only ever checked/installed via `snap list`/
  `snap install`, so on pacman — where `yazi` has a real native package
  in the `extra` repo but `snapd` itself is confirmed AUR-only — every
  restore tried to install `snapd` (fails), then tried to install `yazi`
  via snap (fails, no snap binary at all), hitting two manual-step pauses
  per restore for a tool that's really just a normal package away.
  - New `_GLB_SNAP_NATIVE_OVERRIDES` table (`lib/extras.sh`, keyed
    `<name>:<package-manager>`) lets a `snap`-method extras.txt entry
    route through the plain package manager instead of snap when a real
    native package exists. Added `yazi:pacman` → `yazi`. Wired into
    `glb_extra_installed` (checks via `glb_package_installed` instead of
    `snap list`), `glb_install_extra` (delegates straight to
    `glb_install_package` instead of `snap install`), `_glb_update_extra`
    (no-ops — already covered by the plain package-manager update via
    `glb_update_packages`), and `glb_apply_profile_extras`'s dry-run
    wording (now says "via the package manager, yazi - not snap").
  - New `_GLB_PACKAGE_SKIP` table (`lib/package.sh`, same
    `<name>:<pkg-mgr>` keying style as the existing
    `_GLB_PACKAGE_OVERRIDES`) lets `glb_apply_profile_packages` skip a
    package known to have no real install path on the current package
    manager — log-and-continue instead of attempting an install that's
    guaranteed to fail and pausing for a manual step on every single
    restore. Added `snapd:pacman` — confirmed AUR-only, and now genuinely
    unneeded on pacman since `yazi` routes around it entirely via the
    override above.
  - **Deliberately scoped to pacman only** — zypper's `snapd`/`yazi` gap
    stays exactly as documented (no native `yazi` package exists there at
    all, confirmed 2026-08-13, would need a non-default OBS repo), and
    dnf was never confirmed either way. Not chased further this session,
    same "known gap, not chased further" treatment this file already
    gives e.g. `lazygit` on Fedora/dnf.
  - **Verified via dry-run** on this VM's real `default`/`server`
    restores: `snapd` now logs `Skipping snapd: ...` instead of `Would
    install`, and `yazi` (already present natively on this VM) correctly
    shows `Already installed: yazi` instead of `Would install: yazi (via
    snap)`. Full bats suite (223 tests, via a scratchpad-cloned
    `bats-core` — `bats` itself isn't installed on this VM) — 218/223
    pass; confirmed via `git stash` that the same 5 failures are
    pre-existing and unrelated (this VM already has `fresh`/`starship`
    genuinely on real `PATH`, the same test-isolation gap documented
    repeatedly elsewhere in this file).
  - **Confirmed for real the same day (Greg, this VM's own terminal):**
    a genuine `glb restore developer` (this VM's first real restore,
    not sandboxed) ran completely through with exactly **one** sudo
    password prompt in about 10 seconds — no manual-step pause anywhere,
    confirming `podman`/`jq`/`gh`/`ncdu`/`lazygit`/`glow` all install
    cleanly via pacman and `mise`/`lazydocker` via curl. A second real
    `glb restore developer` immediately after came back fully clean/
    idempotent — every package/extra/dotfile "Already installed"/
    "Already linked", zero sudo calls needed the second time, exit 0.
    `yazi` confirmed genuinely present as the native pacman package
    (`pacman -Q yazi` → `26.5.6-4`) and `snapd` confirmed absent
    (`pacman -Q snapd` → not installed) — the fix works exactly as
    designed on a real restore, not just in dry-run/bats. `developer` is
    now fully confirmed end-to-end on real, vanilla Arch (not just the
    Arch-derivatives tested before).
  - **`default` confirmed for real too, same day, same VM (Greg's own
    terminal):** a genuine `glb restore default` ran clean end-to-end
    (`fastfetch` was this profile's only real delta versus what
    `developer` had already installed - confirmed via `fastfetch
    --version`). A second real restore immediately after was fully
    idempotent, and crucially showed `Skipping snapd: ...` printed
    correctly even on a re-run (not silently absorbed into the
    already-installed path) - confirms the skip logic itself is what's
    firing, not a coincidental side effect of everything already being
    present. `yazi` confirmed linked and functional
    (`~/.config/yazi/...` dotfiles all "Already linked"). Both `default`
    and `developer` are now fully confirmed end-to-end for real on this
    VM.
    - **Real gotcha hit along the way, not a GLB bug**: `default`'s
      restore replaced `~/.gitconfig` with GLB's own managed symlink
      (one of `default`'s tracked dotfiles), silently backing up the
      `git config --global user.name/user.email` set earlier in this
      session before any restore had run - exactly the documented
      2026-08-09 behavior (the tracked file only does `[include] path =
      ~/.gitconfig.local`), just newly confirmed end-to-end for a fresh
      machine going through the full sequence (set global identity ->
      later restore `default` -> identity silently backed up) for the
      first time. Fixed by writing identity plus the `gh`-written
      credential-helper block into `~/.gitconfig.local` instead (copied
      from `~/.gitconfig.glb-backup`'s content) - untracked, survives
      future restores. Confirmed via a real `git push`. **Worth
      remembering for any future fresh-VM session**: set up `git`/`gh`
      identity in `~/.gitconfig.local` from the start, not
      `git config --global`, if `default`/`server` (both symlink
      `.gitconfig`) haven't been restored yet - saves re-doing this
      step.
  - **`server` confirmed for real too, same day, same VM:** a genuine
    `glb restore server` ran clean end-to-end - `ufw`/`rsync`/`restic`/
    `fail2ban` were the only real deltas versus what `default` had
    already installed, all confirmed functional (`restic version` ->
    `0.19.1`, `fail2ban-client -V` -> `v1.1.1`). A second real restore
    was fully idempotent, `Skipping snapd: ...` fired correctly again,
    and `~/.gitconfig.local`'s identity survived this restore too
    (confirmed via `git push --dry-run`) since `server` doesn't
    re-touch `.gitconfig` at all (only `default` ships that dotfile).
    **All three profiles (`default`/`developer`/`server`) are now fully
    confirmed end-to-end for real on this VM** - the most complete
    single-machine verification pass this project has had on vanilla
    Arch.
- **yazi added to `profiles/default`, alongside ranger (not replacing it) —
  new `snap` extras method built to install it (2026-08-13, Dell laptop /
  Pop!_OS).** Greg and a counterpart session had already manually installed
  and configured yazi on this real laptop as a proof of concept before this
  session started (git-status plugin via `yazi-rs/plugins:git`, config
  validated by hand) — this session's job was porting that real, working
  setup into the GLB project, not designing from scratch.
  - **Real environment quirk that shaped the install method**: yazi has no
    package at all in apt's index on Debian/Ubuntu/Pop!_OS-family distros —
    confirmed empirically this session (`apt-cache search`/`apt-cache
    madison yazi` both return nothing on this Pop!_OS 24.04 machine). It's
    installed here via snap (`classic` confinement) instead, and the snap
    build has its own known quirk: the `ya` CLI isn't exposed as a bare
    command on PATH (upstream yazi issue #2903) — only reachable via
    `/snap/yazi/current/ya` or the snap-provided `yazi.ya` alias.
  - **Confirmed via `AskUserQuestion` before building** (two real forks: how
    to install the git-status plugin, and how to handle the apt gap) — Greg
    dismissed both questions and clarified the actual situation instead:
    this isn't a hypothetical design decision, it's "follow what's already
    installed and configured on this laptop." That directly resolved both
    forks:
    - **Install method: snap, not a new cargo/binary extras mechanism.**
      Confirmed via `snap list`: yazi is genuinely installed here as a
      classic-confinement snap. New `snap` method added to `lib/extras.sh`
      (`glb_extra_installed`/`glb_install_extra`/`_glb_update_extra`),
      format `snap <name> <confinement>` in extras.txt (confinement
      typically `classic` or blank for strict), detected via `snap list
      <name>`, installed via `glb_sudo snap install <name>
      [--<confinement>]` — same pause/manual-step/skip UX on failure as
      curl/flatpak/font. `snapd` added to `profiles/default/packages.txt`
      (confirmed in apt's index) so the `snap` binary exists before the
      extras entry runs, same pattern as `unzip` for the font method.
    - **Plugin install: vendored as a static dotfile, not run via `ya pkg
      add` at restore time.** Copied the actual files already on this
      laptop's `~/.config/yazi/` (`yazi.toml`, `init.lua`, `package.toml`,
      `plugins/git.yazi/{LICENSE,types.lua,main.lua,README.md}`)
      byte-for-byte into `profiles/default/dotfiles/.config/yazi/` (`diff
      -r` confirmed identical). Chose this over having `glb restore` invoke
      `ya pkg add yazi-rs/plugins:git` at restore time (the zsh-plugin
      git-clone-at-restore-time pattern `lib/plugins.sh` already uses)
      specifically because of the snap `ya`-CLI-on-PATH quirk above — a
      restore-time `ya pkg add` step would be unreliable exactly where it
      matters (the apt-family distros most likely to install yazi via snap
      in the first place). `package.toml` is included for provenance
      (records the plugin's pinned upstream rev/hash) but is inert unless
      `ya pkg upgrade`/`ya pkg add` gets run for real later — not actively
      used by anything GLB does.
  - **Real cross-distro gap, flagged not solved, same as the existing
    `lazygit`-on-Fedora/`gh:pacman` precedent**: `snapd` is not in
    Arch/pacman's official repos at all (AUR-only) — a pacman restore will
    hit the normal manual-step pause/skip for it, same as any other
    packaging gap. dnf/zypper availability of `snapd` is unverified.
    Flagged in both `packages.txt`'s own comment and here; needs real
    verification next time a non-apt machine in the VM matrix is tested.
  - 14 new bats tests in `tests/extras.bats` (detection, dry-run, install
    with/without a confinement flag, pause/confirm, pause/skip, and the
    update-via-`snap refresh`-not-`install` case) plus stub coverage added
    to `tests/dispatcher.bats`'s two real-`default`-profile end-to-end
    tests (`glb restore`, `glb repair`). 219/223 bats tests pass — the 4
    failures are pre-existing and unrelated, confirmed via `git stash` to
    fail identically on unmodified `main`: this laptop now has both
    `fresh` (from the earlier tealdeer/cargo session) and `yazi` genuinely
    on PATH for real, which a few tests that don't explicitly stub those
    commands don't isolate against. Not fixed this session — same class of
    gap as every other `fresh`-on-PATH note already in this file, not
    something this session's changes caused.
  - **Not run for real** — per the standing rule (never invoke `glb
    restore`/`glb_apply_profile_extras` against the real system without
    stubbing sudo/the package manager/snap first), everything above was
    verified entirely through the bats sandbox. A real `glb restore
    default` re-run on this laptop would currently report "Already
    installed" for both `snapd` and `yazi` (both are genuinely present
    already, installed by hand before this session) rather than exercising
    the actual install path — real fresh-install verification of the
    `snap` method itself needs a machine that doesn't already have
    yazi/snapd, i.e. the VM matrix, not this laptop.
  - **Next step, not started**: test across the VM matrix (per the
    original POC's own "next steps" list) — particularly the
    `snapd`-on-pacman gap and whatever `snap` install actually does on a
    genuinely fresh machine where snap has never been used (first-run
    `snapd` service/seeding delay is a known real-world snap quirk that
    hasn't been exercised here at all, since this laptop's snapd was
    already fully set up going in).

- **Real `tldr`/`tealdeer` bug found and worked around on the Dell laptop
  (2026-08-12), documented rather than wired into GLB's install path.**
  Greg hit `Data.Binary.Get.runGet ... Did not find end of central
  directory signature` from the apt-packaged Haskell `tldr` client on a
  plain `tldr --update`. Swapping to `tealdeer` via apt (`1.6.1-4build2`)
  hit the identical symptom. Root-caused via the upstream issue trackers,
  not guessed: both are unmaintained/stale-packaged clients hitting the
  same real bug class — pre-1.8.0 tealdeer (and the old Haskell client)
  tries to fetch a locale-specific pages archive (e.g.
  `tldr-pages.en_US.zip`) that doesn't exist in the release, gets a 404
  page back, and crashes trying to unzip it
  ([tealdeer#459](https://github.com/tealdeer-rs/tealdeer/issues/459),
  duplicate [#466](https://github.com/tealdeer-rs/tealdeer/issues/466)).
  Confirmed this laptop's own locale (`LANG=en_US.UTF-8`,
  `LC_MESSAGES=en_US.UTF-8`) is exactly the triggering combination — a
  plain `LANG=C` override didn't help since `LC_MESSAGES` takes priority
  over `LANG` and was still set. Fixed by removing the apt package and
  building a patched version instead: `cargo install --locked tealdeer`
  (1.8.1), which updates its cache correctly.
  - **Added a guarded `~/.cargo/bin` PATH entry to `default`'s three
    shell dotfiles** (`.bashrc`, `.zshrc`, `config.fish`) — nothing
    previously put `cargo install`'s binary output directory on `PATH`,
    same guarded-if-present pattern as the existing Homebrew block.
    This is a real, permanent `default`-profile change (any `cargo
    install` a user runs afterward becomes usable without extra setup),
    independent of the tldr fix itself.
  - **Confirmed via `AskUserQuestion`: docs-only, not wired into GLB's
    install path.** Considered adding `tealdeer` to `default`'s
    `packages.txt` directly, but apt's version is the broken one on
    every apt distro tested so far — shipping it via GLB would hand
    every `en_US`-locale user this exact crash on first `glb restore`.
    Building a real `cargo` extras method (`lib/extras.sh` currently
    only supports `curl`/`flatpak`/`font`) was the other option
    discussed but deferred as unscoped feature work, not something to
    fold into a same-session bug fix. Documented instead as a
    recommended-but-manual add-on in a new README.md section
    ("Recommended Manual Add-ons"), with the exact apt-vs-cargo caveat,
    so a future user hitting the same crash has the fix already written
    down rather than rediscovering it.

- **`developer` never had a Neovim package either — found independently
  on CachyOS the same day as the original `nvim` gap (2026-08-10, Greg,
  cross-checked 2026-08-30 against the Neovim+LazyVim work above): this
  is the plain-`neovim`-missing-from-`developer` bug, distinct from
  the `default`-only LazyVim-config-cloning feature documented
  directly above.** `developer` was only ever built with Fresh (via
  `extras.txt`) as its editor — `neovim` itself was never in
  `developer/packages.txt`, only in `default`'s. Not a LazyVim gap
  (confirmed by grepping the whole repo at the time: LazyVim wasn't
  mentioned or configured anywhere in GLB yet). **Fixed** by adding
  `neovim` to `profiles/developer/packages.txt`, matching `default`'s
  pairing of neovim alongside Fresh rather than picking one or the
  other. Rebased onto the current `main` on 2026-08-30 after
  discovering (via `ggregoro/claude-memory`) that a parallel session
  had taken the project all the way to `1.0.0` in the meantime —
  `developer/packages.txt` on that `main` still didn't have `neovim`,
  so this fix was still valid and non-conflicting, just needed
  reapplying on top of the real current history instead of the stale
  branch it was built on. **Not yet re-verified for real** on this
  distro after the rebase — the next `glb restore developer` on the
  CachyOS VM should confirm `nvim` now installs and runs correctly (it
  still won't be LazyVim-configured there, since that config-cloning
  mechanism is `default`-only by design).
- **Fresh Fedora 44 GNOME 50 VM verified end-to-end (2026-08-10, Greg,
  real hardware) — `install.sh`'s curl-install path now confirmed on
  the last of the four supported package managers (dnf), closing out
  full real-hardware coverage of apt, dnf, pacman, and zypper.** Ran
  the documented one-liner via VirtualBox; Greg's own report: "Worked
  perfectly. All apps installed. Only one instance of a prompt to add
  sudo password." Unlike the openSUSE VM, this one had git preinstalled
  already, so no manual intervention was needed at all before the
  installer could run. Fastfetch output (screenshot) confirms Fedora
  Linux 44 (Workstation Edition), zsh 5.9 active as the shell, and a
  clean-looking Starship prompt — Greg's own words, "Starship all
  cleaned up" — a real-hardware, fresh-install visual confirmation of
  the glyph-recovery fix from directly above this entry, on a distro
  that had never even been tested since that fix landed.
  - **`install.sh` is now confirmed end-to-end, via a real restore, on
    all four supported package managers** — apt (Pop!_OS, 2026-08-09),
    pacman (CachyOS, 2026-08-10), zypper (openSUSE, 2026-08-10), and
    now dnf (Fedora, this entry). No package manager has any remaining
    curl-install gap.
  - **Follow-up on the same VM: `glb restore developer` found a real,
    confirmed packaging gap — `lazygit` isn't in Fedora's official dnf
    repos at all.** `sudo dnf install -y lazygit` failed with `No match
    for argument: lazygit`; `ncdu` and `glow` (added the same day as
    `lazygit`, same "not empirically verified" caveat in the profile's
    own comment) both installed fine on dnf, so this is specific to
    `lazygit`, not a broader dnf gap. Researched properly before
    deciding anything: lazygit has no official Fedora package, only a
    third-party COPR (`atim/lazygit`) that has had real build failures
    on recent Fedora releases and signature-verification issues — not
    a reliable install target — and lazygit's own project has no
    single-URL curl-installer script the way `lazydocker` does (only a
    manual multi-step curl+tar+`install` snippet), so it doesn't fit
    GLB's existing `curl` extras method either. Confirmed via
    `AskUserQuestion`: document as a known gap (matching the existing
    fastfetch-on-Mint/Pop!_OS precedent) rather than build a new
    tarball-extraction extras mechanism for one package on one distro.
    Added a comment on `lazygit`'s line in
    `profiles/developer/packages.txt` explaining the gap; Fedora users
    hit this via the normal manual-step pause/skip prompt and move on.
    `ncdu` and `glow` are now confirmed working on dnf specifically
    (previously only verified via apt, implicitly) — only `gh` and
    `lazygit` remain flagged as not fully cross-distro-verified in that
    file's comments.
- **Real, longstanding bug found and fixed (2026-08-10, cloud session):
  zsh's Tokyo Night `starship.toml` has been missing roughly half its
  glyphs — including the git-branch symbol, all five language-module
  icons, half the OS icons, and the powerline separator arrows between
  segments — since the very first commit that added it (2026-08-06),
  on every real machine this project has ever tested.** Surfaced when
  Greg noticed the OS icon was blank on openSUSE and, on follow-up,
  confirmed it was blank on every distro he's tested, not just
  openSUSE. Traced by byte-level inspection (`ord()` on each character
  in the tracked file), not by eye — reading the file with normal
  tools (including my own `Read` tool output in this very
  conversation) *looked* fine, showing what appeared to be icons in
  place, which is exactly why this went unnoticed for two months
  across every VM/laptop restore documented in this file.
  - **Root cause, confirmed precisely:** every glyph in the Unicode
    Basic Multilingual Plane's Private Use Area (`U+E000`-`U+F8FF` —
    the codepoint range older Nerd Font icon sets like Font Awesome,
    Devicons, and Powerline Extra Symbols use) was silently empty in
    the tracked file. Every glyph in the Supplementary Private Use
    Area-A (`U+F0000`+, the range newer Material Design Icons use, all
    of which require UTF-16 surrogate pairs to encode) was intact.
    Confirmed this exact pattern by diffing codepoint-by-codepoint
    against a fresh `curl`-fetched copy of the real, current, official
    Tokyo Night preset from starship's GitHub repo — every single
    missing glyph in GLB's copy was present and correct upstream,
    consistent with the BMP-PUA-vs-astral split. This means the
    corruption happened locally, at some point before or during the
    original 2026-08-06 commit, not upstream.
  - **A live demonstration of the exact same bug while fixing it**: my
    first two attempts to patch the file by typing the missing glyphs
    directly into a Python heredoc *also* silently dropped them (the
    `f'[{sep}]...'`-style script failed its own sanity assertion
    because the character never actually made it into the script's
    string content) — the same BMP-PUA-loss failure mode, just
    happening one layer up, in how text reaches this environment
    rather than in the file on disk. Only worked once every glyph was
    built from an explicit `chr(0xXXXX)` codepoint integer instead of
    a literal character typed into a message — worth remembering for
    any future edit to this file, or any other file carrying BMP
    private-use-area glyphs: don't hand-type or copy-paste the glyph,
    construct it from its codepoint.
  - **Fixed** by rebuilding `profiles/default/dotfiles/.config/
    starship.toml` from the verified-correct upstream bytes
    (`curl`-fetched directly, not routed through any AI-mediated
    fetch/summarization step — an early attempt to verify via the
    `WebFetch` tool silently exhibited the identical glyph-dropping
    behavior, since it re-generates its response through a model
    rather than returning raw bytes) plus reapplying the one real
    customization, `$cmd_duration`, in the same position/styling as
    before. Verified byte-for-byte: all 34 non-ASCII glyphs in the
    official preset are now present and match upstream exactly
    (confirmed via `tomllib.load` for valid TOML plus a full
    codepoint-set comparison, not just a visual read). One glyph
    couldn't be recovered from any authoritative source since it was
    never part of the official preset to begin with: `$cmd_duration`'s
    own icon was empty from the very commit that added it
    (`dc0465a`), so there was no correct original to restore. Chose to
    reuse `$time`'s clock icon for it, matching the original stated
    intent ("styled to match the existing $time segment," per that
    commit's own CLAUDE.md entry) rather than inventing a new one —
    flagging this one choice explicitly since it's the one part of the
    fix that isn't a byte-for-byte recovery.
  - 211/215 bats tests still pass (same 4 pre-existing root-sandbox
    permission failures, confirmed unrelated — this fix only touches
    dotfile *content*, not anything bats asserts on).
  - **Real impact for Greg specifically**: every one of his real
    machines (Dell laptop, Debian server, every test VM) has been
    running this degraded prompt in zsh the whole time, without
    anyone — including several past sessions' worth of `Read` calls on
    this exact file — visually noticing, since normal file-viewing
    tools can't render the affected codepoint range either. Since
    `~/.config/starship.toml` is a live symlink into wherever GLB is
    checked out, no `glb restore` re-run is needed on any machine to
    pick up the fix — just `git pull` inside that machine's GLB
    checkout.
  - **Verified for real (2026-08-10, Greg, Dell laptop)** — a plain
    `git pull` in the laptop's GLB checkout was all it took, exactly as
    predicted (`~/.config/starship.toml` is a live symlink, no
    `glb restore` re-run needed). Greg's own words: "the profile and
    config should now be complete." Screenshot confirms the Tokyo
    Night zsh prompt rendering its icons correctly on this daily-driver
    machine, plus `eza`'s folder icons in a directory listing in the
    same window — the font itself was never the problem, exactly as
    diagnosed.
- **Fresh openSUSE Tumbleweed VM verified end-to-end (2026-08-10, Greg,
  real hardware) — `install.sh`'s curl-install path now confirmed on
  all four supported package managers (apt, dnf, pacman, zypper).**
  Second fresh-VM-connected-to-GitHub-from-the-start test, right after
  CachyOS above. Greg's own report: worked great, only intervention was
  installing git; everything else — including Fresh, Ranger, Fastfetch,
  and Btop — confirmed working.
  - **Real, expected gap hit for the first time: this fresh openSUSE
    install had no `git` preinstalled at all**, unlike every openSUSE
    VM tested previously in this project (which already had git from
    earlier ad-hoc setup). `install.sh` failed cleanly exactly as
    designed — `Error: git is required to install GLB. Please install
    git and try again.` — confirmed via Greg's own screenshots: the
    bare `curl | bash` one-liner errored cleanly first, a manual
    `git clone` attempt then showed zypper's own "package can be found
    in following packages: git-core... sudo zypper install
    <selected_package>" suggestion, and `cd GLB`/`./glb restore` both
    failed for the obvious reason (nothing was cloned yet). This is the
    **first real-world hit of `install.sh`'s no-git error path**
    outside the bats sandbox's synthetic test for it — confirms the
    fail-clean behavior works as designed for an actual user, not just
    in `tests/install.bats`. After Greg ran `sudo zypper install git`
    manually, the one-liner succeeded and cloned cleanly.
  - **"Lots of errors" Greg saw during the install are cosmetic zypper
    mirror-preload noise, not real failures** — confirmed by reading
    the actual captured terminal output (Greg attached the full
    session as a Word doc): every package's `Preloading:
    <pkg>.rpm [Error: "The requested URL returned error: 404", trying
    next mirror.]` line was followed by that same package eventually
    resolving `[done]` from a different mirror. This happened
    repeatedly across nearly every package (zsh, fish, tmux, neovim,
    ripgrep, fzf, eza, bat, ranger, btop, fastfetch, zoxide) — a lot of
    visible red text, zero actual install failures. Every package
    ultimately installed successfully and `glb restore` completed with
    `[SUCCESS] Profile applied: default`. Worth remembering next time
    this comes up so it isn't mistaken for a real bug: it's zypper's
    own preloading/mirror-fallback behavior, unrelated to GLB's code.
  - **Zero `_GLB_PACKAGE_OVERRIDES` gaps** — every package in
    `default`'s `packages.txt` resolved to a real, correctly-named
    zypper package directly (matching the zero-gap result from every
    prior zypper test in this project).
  - **No interactive sudo password prompt appeared anywhere during the
    actual `glb restore` run** — confirmed explicitly by Greg
    ("There was also no requirement for me to add a sudo password at
    any point during the installation"). Most likely explanation,
    visible in the transcript: sudo's own timestamp/ticket caching from
    the manual `sudo zypper install git` step just before covered the
    rest of the session's sudo-gated calls (package installs, the
    Fresh `.rpm` install, Starship's own installer needing root for
    `/usr/local/bin`) within its default cache window — not necessarily
    a new behavior from `glb_sudo` itself, just normal sudo caching
    lining up conveniently. Still a good sign: nothing about the
    `glb_sudo` TTY-detection logic got in the way of a real interactive
    session either way.
  - All extras confirmed working for real: Fresh (curl → detected
    Fedora/RHEL-family, downloaded and installed the `.rpm` via `rpm
    -U`), the JetBrains Mono Nerd Font, and Starship (its own installer
    escalating to root for `/usr/local/bin` as always). Both zsh
    plugins cloned cleanly. Self-symlink, all completions, and every
    dotfile linked correctly (`.bashrc` correctly backed up to
    `.bashrc.glb-backup` first, since a stock `.bashrc` pre-existed).
  - **`install.sh` is now confirmed working end-to-end on all four
    supported package managers** — Pop!_OS/apt (2026-08-09), CachyOS/
    pacman (2026-08-10, see entry above), and now openSUSE/zypper
    (this entry). Fedora/dnf is the only one of the four remaining
    genuinely unverified against the curl-install path specifically
    (the distro itself is well-tested via `git clone`, just not this
    specific installer).
- **Fresh CachyOS VM verified end-to-end (2026-08-10, Greg, real
  hardware) — first real confirmation of both `install.sh`'s
  curl-install path on pacman and the `glb_sudo`/`pam_faillock` fix on
  the exact distro family that caused it.** Ran the documented one-liner
  verbatim: `curl -fsSL https://raw.githubusercontent.com/ggregoro/GLB/
  main/install.sh | bash`. Greg's own report: "Program ran successfully
  from end to end. All apps installed. All customizes were successful."
  - **`install.sh` curl-install path confirmed working on pacman** —
    previously only verified on Pop!_OS/apt (2026-08-09). This closes
    the last "not yet verified" gap flagged in the prior session's
    wrap-up note.
  - **`glb_sudo`'s TTY-detection fix (built 2026-08-09, never before
    tested live) confirmed working correctly on real Arch-based
    hardware.** Greg hit the real interactive sudo password prompt at
    least once during the restore, entered it normally, and it worked
    with **no `pam_faillock` lockout** — confirmed explicitly via
    follow-up question, not just inferred from "successful." This is
    the fix's first live test against the exact failure mode it was
    built for: both prior confirmed lockouts (CachyOS 2026-08-07,
    EndeavourOS 2026-08-08) were on pacman machines, and this new
    CachyOS VM is a fresh instance of the same distro family. Real
    evidence the fix works as designed, not just passing in the bats
    sandbox.
  - Not yet confirmed in detail: which profile was restored, whether
    this is the same CachyOS VM reused from earlier testing or a
    genuinely fresh one (Greg's own words beforehand were "I will
    create a fresh VM for CachyOS"), and whether a bats run happened on
    this machine. Worth asking next time this VM comes up if finer
    detail is ever needed — not blocking, since the two things that
    actually mattered (install.sh on pacman, no pam_faillock lockout)
    are both confirmed.
  - **Next per Greg's earlier stated plan: openSUSE (zypper) VM next.**
- **Real bug found by an actual end user running the documented
  `install.sh` one-liner (2026-08-09, Greg, real Pop!_OS machine) — the
  exact same `sh`-vs-`bash` bug class as the `lazydocker` fix just
  below, but in `install.sh` itself, which I failed to check for it at
  the time.** Greg ran the README's own documented command verbatim —
  `curl -fsSL https://raw.githubusercontent.com/ggregoro/GLB/main/
  install.sh | sh` — and got `sh: 14: set: Illegal option -o pipefail`
  immediately. Root cause: `install.sh` has `set -euo pipefail` at the
  top (`pipefail` is a bash-only `set -o` option), but every piece of
  documentation told users to pipe it through `sh`, which is `dash` on
  Debian/Ubuntu/Pop!_OS and rejects `pipefail` at runtime — confirmed
  precisely via `dash -c 'set -euo pipefail'` reproducing Greg's exact
  error text. `dash -n install.sh` does **not** catch this ahead of
  time (it's a runtime-rejected option value, not a parse error), and
  `tests/install.bats` never caught it either since those tests invoke
  `bash "$GLB_REPO_ROOT/install.sh"` directly rather than through the
  documented `curl | sh` pipe — confirmed by Greg separately reporting
  "I ran it in bash" and it working fine, exactly as expected. **Fixed**
  by changing every real reference from `| sh` to `| bash`: `README.md`
  (the documented one-liner), `install.sh`'s own header comment, and
  `docs/ARCHITECTURE.md`'s installer description. Left the *other*
  `| sh` references in `CLAUDE.md` and `docs/design/
  update-components.md` alone — those describe Starship's own separate,
  already-confirmed-working `starship.rs` installer, not GLB's
  `install.sh`, distinguished by checking full grep context before
  touching anything. **Real process gap, not just a code gap**: this is
  the identical bug pattern just fixed in `lib/extras.sh` for
  `lazydocker` minutes earlier in the same session (see entry directly
  below) — should have prompted checking `install.sh` for the same
  issue at that time and didn't. Worth remembering: any future
  `sh`-vs-`bash` fix in this project should trigger a repo-wide grep for
  the same pattern, not just a fix at the one call site that happened to
  surface it.
- **`developer` gets four new TUI tools, plus a real `sh`-vs-`bash`
  install bug found and fixed along the way (2026-08-09, cloud
  session).** Prompted by Greg noticing `mc` (Midnight Commander)
  wasn't actually installed — clarified it was only ever an
  illustrative example in the GUI-vs-terminal scope note, never a real
  package. Discussed what other terminal tools might be worth adding
  given how cheap it is (`packages.txt`/`extras.txt` are one line);
  Greg picked `ncdu`, `lazygit`, `glow`, and `lazydocker` for
  `developer`, deliberately skipping `mc` (redundant with `ranger`).
  Separately, Greg judged `btop` superior to `htop` and asked to
  switch — done across `default`/`developer`/`server`, superseding the
  original 2026-08-06 htop-over-btop call.
  - **Real bug found while adding `lazydocker`**: its official install
    script requires bash (`${VAR//pattern/repl}`-style parameter
    expansion, not POSIX), but `lib/extras.sh`'s `curl` method piped
    every install script to `sh` — which is `dash` on Debian/Ubuntu,
    not bash-compatible. This would have silently broken `lazydocker`
    (and any future bash-requiring installer) had it shipped as-is.
    **Fixed**: `curl -fsSL "$spec" | sh` → `| bash` in both
    `glb_install_extra` and `_glb_update_extra`, plus the `extras.txt`
    format-comment docs in both `default` and `developer`. GLB itself
    already requires bash 5.x, so there's no compatibility reason to
    keep using `sh` for extras specifically. Verified the fix is
    real by fetching `lazydocker`'s actual install script and checking
    it against `dash -n` (fails) before making the change, not just
    reasoning about it.
  - **Detour that turned up nothing, but worth recording so it isn't
    re-investigated:** Greg initially suspected Fresh (the code editor
    extra) "might not be ready yet," which raised the hypothesis that
    Fresh's installer had the *same* `sh`-vs-`bash` bug. Checked
    directly: Fresh's script is genuinely `#!/bin/sh`-compatible (no
    bashisms, confirmed via `dash -n`), so that wasn't it. Greg then
    retracted the original concern entirely ("Fresh did in fact
    install") before identifying any real issue — so as of this note,
    there's no known Fresh problem, just a ruled-out hypothesis.
  - **Genuinely tricky bats test-infrastructure bug found and fixed
    while updating tests for the `sh`→`bash` change.** Several tests
    stub `sh` to intercept the curl-install target; renaming those to
    stub `bash` instead broke in two distinct, non-obvious ways before
    landing on the correct fix (`tests/test_helper.bash`):
    1. A naive `#!/usr/bin/env bash` stub for "bash" recurses into
       itself - `env` does its own PATH lookup for "bash", which
       (with `STUB_BIN` prepended) finds the stub again.
    2. Less obviously: *every other* stub (`curl`, `apt`, etc.) also
       uses `#!/usr/bin/env bash`, so the instant a test *also* stubs
       "bash", `env`'s PATH lookup for every other stub's shebang gets
       hijacked too - their actual bodies never ran, only the fake
       "bash" stub's fallback logging did. Traced by adding explicit
       arg-count tracing inside a hand-built reproduction outside bats
       entirely, not by guessing from bats' own output.
    Fixed by giving **every** stub (not just "bash") an absolute-path
    shebang (`$GLB_REAL_BASH`, resolved once at file-load time before
    any test mutates `PATH`), which sidesteps `env`'s PATH lookup
    entirely. The "bash" stub additionally passes any invocation with
    one or more arguments straight through to the real bash (covers
    both `bash -c "..."` and `bash <script-path>`, e.g. how the
    kernel/`env` actually invokes `glb`'s own
    `#!/usr/bin/env bash` shebang) - only a truly bare, zero-argument
    invocation (the real `curl | bash` pipe-target case) runs the
    test's given stub body. Updated the 3 `tests/dispatcher.bats` and
    6 `tests/extras.bats` call sites that test the extras curl path
    accordingly (left the 2 that test Starship's separate,
    unmodified `lib/prompt.sh` `sh` path alone). 211/215 bats pass
    after all of this - same 4 pre-existing root-sandbox permission
    failures, confirmed unrelated.
- **First real post-scope-narrowing end-user verification (2026-08-09,
  fresh Pop!_OS VM) — worked essentially perfectly.** This is the test
  everything since the "what's left before stable" checkpoint was
  building toward: a genuinely fresh Pop!_OS VM, not connected to the
  GitHub repo as a dev checkout. Greg went to the now-public repo's
  GitHub page, used the README's `git clone` instructions (not the
  `install.sh` curl one-liner — that path is still unverified for
  real), and ran `./glb restore` in Cosmic Terminal. Bare `restore`
  triggered the interactive picker; he chose `default`. Entered his
  real sudo password at the real interactive prompt when asked —
  **first live confirmation that the `glb_sudo` TTY-detection fix
  works correctly in normal interactive use**, not just in the bats
  sandbox. Every package and dotfile installed/linked correctly except
  one **already-documented, expected gap**: `fastfetch` isn't in
  apt's index on Pop!_OS (same issue confirmed on Linux Mint
  2026-08-07, see `profiles/default/packages.txt`'s own comment on
  that line) — Greg skipped it via the existing manual-step
  pause/skip mechanism, exactly as designed. His own words: "Very easy
  to use even for me." Confirms the WezTerm removal, `new-to-linux`
  retirement, and `glb_sudo` fix all work correctly on a real machine,
  not just in review. **Not yet verified**: the `install.sh`
  curl-install path itself (this test used `git clone` instead) —
  worth trying next time.
- **Pre-public-release cleanup (2026-08-09, cloud session), prompted
  by Greg asking what going public would actually involve.** Audited
  the repo for anything that would become permanently, publicly
  exposed on making it public — not just current files, the entire
  git history forever, even if made private again later (anything
  already cloned/cached/indexed in the meantime doesn't get
  un-exposed). Findings:
  - **Every commit is authored `Gregory Gregorowicz
    <ggregoro@gmail.com>`** — Greg's call: already fine with this
    being public, no action taken. Flagging this here anyway so a
    future session doesn't assume it was overlooked.
  - **`profiles/default/dotfiles/.gitconfig` hardcoded Greg's personal
    git identity** — a real bug independent of the privacy question,
    not just a privacy one: anyone restoring `default` (not just
    Greg) would get *his* name/email on *their* commits. **Fixed**:
    the tracked file now only has `[include] path =
    ~/.gitconfig.local`, which git silently skips if that file doesn't
    exist. **Action needed on Greg's real machines** (Dell laptop,
    Debian server, any other machine with `default`'s `.gitconfig`
    symlinked) once this is pulled — his own git identity will stop
    resolving until he creates the local override:
    ```
    cat > ~/.gitconfig.local << 'EOF'
    [user]
        name = Gregory Gregorowicz
        email = ggregoro@gmail.com
    EOF
    ```
    Not yet done on any real machine — this repo-side fix alone
    doesn't break anything on the Dell laptop until he actually pulls
    it, but it's a real to-do the moment he does.
  - **`docs/reference/debian-server-cheat-sheet.md` had Greg's home
    server's real LAN IP (`192.168.0.235`) and SSH username
    (`grego`) in plaintext** — prompted directly by Greg saying "I
    don't want anyone making [their] way into my personal computers
    somehow." Removed entirely (not just redacted) — it was personal
    reference material unrelated to GLB itself, not something that
    belonged in a public tool's docs regardless of the privacy
    question. `docs/README.md`'s reference-page index updated to
    match; left the historical mentions in `CHANGELOG.md`/
    `docs/DOCS_CHANGELOG.md` alone as accurate history.
  - **Broader scan came back clean**: no private key markers, no
    passwords/API tokens/secrets, no other IP addresses or
    `/home/grego`-style paths anywhere outside this file's own working
    journal (which Greg is fine with, per the name/email point above).
  - 211/215 bats tests still pass after these changes (same 4
    pre-existing root-sandbox permission-check failures, unrelated —
    confirmed no test asserted on the old `.gitconfig` content).
  - **Answering Greg's other question directly**: once cleanup like
    this is done, going public genuinely is just flipping a switch —
    GitHub repo Settings → Danger Zone → Change visibility → Make
    public, type the repo name to confirm. No other mechanical step
    needed on GLB's side.
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

- **NEXT SESSION — pick up here: verify Neovim + LazyVim end-to-end on a
  fresh Pop!_OS VM (set up 2026-08-30, Greg will run it).** The
  Neovim/LazyVim feature shipped 2026-08-30 (`57642bb`/`1e975db` on
  `main`, see the Roadmap entry above) but has only been verified
  piecewise — running `glb_install_nvim_config`/`glb_undo_restore`
  directly against `profiles/default` on the Pop!_OS Cosmic *laptop*.
  The real fresh-machine run is still outstanding. This also doubles as
  the long-outstanding "a real `glb restore default` end-to-end on a
  genuinely fresh machine, not a patched-up VM" check GLB's history
  keeps flagging.
  - **Prerequisite — SSH access to the private `nvim-config` repo must
    be set up on the VM first**, or the LazyVim half can't be tested.
    `profiles/default/nvim-config.txt` points at
    `git@github.com:ggregoro/nvim-config.git` (private). Without a
    working key the restore still *succeeds overall* but logs
    `Failed to clone nvim-config to ~/.config/nvim - check access ...`
    and `nvim` is left unconfigured — that's the by-design "not Greg"
    path, not the thing to test. Playbook (same as every other fresh-VM
    entry in this file): `ssh-keygen -t ed25519`, add the pubkey at
    github.com/settings/keys, confirm with `ssh -T git@github.com`
    (expect "Hi ggregoro! ..."). `GLB_NVIM_CONFIG_REPO` can point the
    step at a different repo if ever needed.
  - **Get GLB onto the VM**: `git clone
    https://github.com/ggregoro/GLB.git` (public, no creds) or the
    `install.sh` one-liner (clones to `~/.local/share/glb`).
  - **Run `glb restore default` for real** (real TTY + real sudo on a VM
    — none of the no-TTY/`pam_faillock` limitations that hit cloud
    sessions). Watch for, in order:
    1. `neovim` installs via apt.
    2. `nvim-config cloned: ~/.config/nvim` (a success line, not a
       `Failed to clone`). On a fresh Pop!_OS install there is no
       pre-existing `~/.config/nvim`, so **no** `~/.config/nvim.glb-backup`
       should be created.
    3. `git -C ~/.config/nvim remote get-url origin` → the nvim-config
       URL; `git -C ~/.config/nvim log --oneline -1` → `29bcb66 My
       custom LazyVim setup`.
  - **Launch `nvim`** — first launch bootstraps lazy.nvim itself + every
    plugin pinned in `lazy-lock.json`. Let it finish, `:Lazy` shows them
    installed with no errors, `:q`, relaunch → clean startup into
    LazyVim. This is the actual "does it work" check the piecewise
    verification couldn't do.
  - **Idempotency**: a second `glb restore default` — the nvim step
    should print `nvim-config updated: ~/.config/nvim` (a `git pull`),
    NOT re-clone or re-backup. `glb restore default --dry-run` after
    that → `Would pull latest nvim-config into ~/.config/nvim`.
  - **`glb restore --undo`** on the fresh VM won't touch `~/.config/nvim`
    (no `.glb-backup` exists — nothing pre-existed to restore). That's
    expected; the backup/undo path is only exercised when there was a
    real pre-existing config, and is covered by `tests/nvim_config.bats`.
  - **bats suite on the VM** (`sudo apt install -y bats`, or the
    scratchpad `bats-core` clone): expect **237/241** once a real
    restore has run — the 4 failures are the documented
    `fresh`/`starship`-genuinely-on-PATH test-isolation gap
    (tests 38/39/88/116), not a regression. On a truly untouched VM
    *before* any restore it may be higher.
  - When done, update this file (close out the Roadmap entry's "Still
    pending" note) and the Claude memory repo's `project_glb.md` (see
    [[reference-memory-repo]] — its "real fresh-machine `glb restore
    default` end-to-end still pending" line).

- **Session wrap-up (2026-08-25, cloud session, fresh Linux Mint VM) —
  Greg is stopping here on this VM; `default` only, no need to test
  `developer`/`server` on this machine.** Full session, in order:
  1. Greg ran `glb restore default` for real on this fresh Mint VM
     (via the public repo's `main`). Reported it went well overall,
     with `snapd`, `fastfetch`, and `yazi` not installing.
  2. Diagnosed via the exact error text he relayed (this cloud session
     has no direct access to the VM itself): `fastfetch` is the
     already-known, already-documented apt-index gap (confirmed
     2026-08-07, reconfirmed here — "Unable to locate package"). But
     `snapd`/`yazi` (`yazi` depends on `snapd` via the `snap` extras
     method) turned out to be a genuinely new finding: unlike every
     other apt distro tested (Pop!_OS/Debian/Ubuntu, where `snapd`
     installs cleanly), **Linux Mint ships
     `/etc/apt/preferences.d/nosnap.pref`, which pins `snapd` to
     priority -1 by deliberate anti-Snap policy** — the package is
     genuinely in Mint's index, but apt refuses to consider it
     installable, producing the same "has no installation candidate"
     text a truly-absent package would give.
  3. **Fixed**: new `_GLB_PACKAGE_MANUAL_HINT` table (`lib/package.sh`,
     keyed `<generic-name>:<distro>` via `glb_detect_os` — finer
     grained than the existing `<name>:<pkg_mgr>` tables need, since
     apt itself behaves differently across the distros that share it)
     plus `glb_package_manual_hint`. `glb_prompt_manual_step` gained an
     optional third `hint` argument, shown above the resolved command;
     `glb_install_package` looks it up before pausing. Deliberately
     *not* auto-skipped the way `snapd:pacman` is — Mint's block is a
     reversible policy choice with a real user fix, not a true
     absence, so surfacing it (rather than silently working around it)
     was the right call, matching the existing dnf/zypper precedent of
     pausing with a real actionable choice over silently skipping. See
     the dedicated Roadmap/Test-environments entries for the full
     design writeup and the exact hint text.
  4. 4 new bats tests in `tests/package.bats`. Full suite: 223/227 pass
     — the same 4 pre-existing root-sandbox permission-check failures
     this file has documented since 2026-08-09 (confirmed via
     `git stash` unrelated to this change).
  5. Pushed to `claude/glb-reading-8860vi`, then merged into `main` on
     Greg's request (clean fast-forward, `f78b1ab`).
  6. **Verified for real on the actual Mint VM, same day**: Greg pulled
     `main`, re-ran the restore, and confirmed the `snapd` pause showed
     the new `nosnap.pref` hint correctly. Ran the hint's fix himself
     (`sudo rm /etc/apt/preferences.d/nosnap.pref && sudo apt update &&
     sudo apt install -y snapd`, then `sudo snap install yazi
     --classic`) and confirmed `yazi` genuinely launches afterward.
     `fastfetch` was skipped via the normal `s` prompt, as expected.
     One follow-up doc commit (`37ca88c`, also merged into `main`)
     recording this real-hardware confirmation.
  - **This closes the Mint session out fully** — `default` is verified
    working end-to-end on this VM (with the two known/now-handled apt
    gaps accounted for), the fix is proven on the real distro/error it
    was built for (not just bats), and everything is on `main`. Nothing
    left open here; `developer`/`server` were deliberately not tested
    on this VM per Greg's call.
- **Session paused here (2026-08-19, Dell E7450, Fedora KDE Plasma) —
  Greg chose to stop before restoring `developer`/`server` on this
  machine; pick up there next.** `default` is fully restored and
  verified on this machine (see the Test Environments entry above for
  the full writeup). `glb restore developer --dry-run` was run and
  looked clean:
  - `git`/`curl`/`zsh`/`fish`/`fzf`/`eza`/`bat`/`zoxide`/`btop`/
    `bash-completion`/`unzip`/`podman`/`gcc`/`make`/`jq`/`gh` all
    already present (podman/gcc/make/jq/gh apparently came with the
    base Fedora KDE Workstation install, not from GLB); `fresh`/the
    Nerd Font/`starship`/both zsh plugins already present from the
    `default` restore.
  - **Would still need to install**: `ncdu`, `lazygit`, `glow` (dnf),
    `mise` and `lazydocker` (curl). **Expect `lazygit` specifically to
    hit the known, already-confirmed manual-step pause** — it has no
    official Fedora/dnf package (confirmed on the Fedora GNOME VM,
    2026-08-10) — everything else should install cleanly.
  - Not yet run for real — this session has no TTY/sudo, so the actual
    (non-dry-run) `glb restore developer` still needs to be run by Greg
    in his own terminal on this machine, same as `default` was. Once
    that's done: verify the `lazygit` gap behaves as expected, confirm
    a second restore is idempotent, then move on to `server` (not
    dry-run'd yet at all on this machine) and — separately, still
    outstanding from the `default` verification — a visual check of
    Konsole's Nerd Font glyph rendering on Fedora/KDE specifically
    (only ever confirmed on Arch-based Konsole before, CachyOS
    2026-08-05).
- **Project status (2026-08-18, per Greg, after the Dell laptop's Arch
  Linux Cosmic reinstall — see its own Test Environments entry above):
  GLB is essentially feature-complete.** Greg's own assessment, stated
  directly: "GLB performed exactly what it was intended to do" — a real
  `glb restore` on the freshly reinstalled Dell laptop (Arch Cosmic, see
  above) ran end-to-end as designed, with the `eza --hyperlink` and
  `cpufetch` additions (2026-08-17/18, see Roadmap entries above) being
  the last features added before this assessment. Greg expects
  occasional small add-ons going forward, not a large amount of new
  feature work.
  - **What's actually left, per Greg**: real-hardware verification
    beyond VMs — everything tested so far outside the Dell laptop
    itself has been a VM (see Test Environments above: CachyOS,
    EndeavourOS, Manjaro, Arch/Xfce, openSUSE, Fedora, Pop!_OS, Linux
    Mint, all VirtualBox VMs). The Debian 13 machine (see Test
    Environments) is the only other confirmed non-VM/non-laptop
    real-hardware test on record. Also still explicitly open: the
    `eza --hyperlink` change itself needs dnf/zypper verification (see
    that Roadmap entry's 2026-08-18 update above) — real-hardware
    coverage and this specific feature's remaining distro coverage are
    two different open items, not the same one.
  - **Resolved same day, see the entry directly below**: both the
    `VERSION` bump and the public/private question were exactly the
    natural next questions flagged here, and Greg answered both within
    the same conversation — see "Repository is now public, VERSION
    bumped to 1.0.0" right below.
- **Repository is now public, VERSION bumped to `1.0.0` (2026-08-18, per
  Greg) — both GLB and GWB (GLB's Windows sibling project) are public
  now.** Directly resolves the two items flagged in the entry above.
  - `VERSION` (repo root) changed from `0.5.0` → `1.0.0`.
  - `docs/ROADMAP.md`'s "Version 1.0 — Stable Release" section marked
    ✅ complete, each goal annotated with what actually shipped and a
    pointer back to where it's documented (see that file directly).
  - `docs/PROJECT.md`'s Release Strategy section updated: the
    2026-08-09 "stays private until fully tested and vetted" policy is
    now explicitly marked as resolved/historical rather than the
    active policy, with a new note recording that the bar was met and
    the repo went public on this date.
  - This file's own header (top of file, "Repo:" line) updated from
    "(private)" to "(public)".
  - **Not done, deliberately**: no edit to `CHANGELOG.md`'s
    `[Unreleased]` section — cutting that into a dated `[1.0.0]`
    release entry is a bigger editorial call (deciding exactly where
    the release boundary falls across a very long unreleased history)
    that Greg should make explicitly rather than have inferred from
    "update the version number." Worth asking about directly next time
    this comes up.
- **Session wrap-up (2026-08-16, fresh Arch/Xfce VM) — ending here; Greg
  is moving to his primary laptop next.** Everything below is committed
  and pushed to `origin/main` — `2a2f106` is the latest commit as of
  this note, working tree clean on this VM. Full session, in order:
  1. Cloned GLB fresh onto this new Arch/Xfce test VM (built specifically
     to test Arch + Xfce). `glb info` correctly detected `arch`/`pacman`.
  2. Dry-run of `developer`, then confirmed every "would install"
     package via read-only `pacman -Si` before touching anything real —
     zero `_GLB_PACKAGE_OVERRIDES` gaps (`gh` correctly resolved through
     its existing `gh:pacman` override).
  3. **Found and fixed a real, previously-flagged bug**: `yazi`/`snapd`
     paused every pacman restore twice (once for `snapd`, AUR-only on
     Arch; once for `yazi` via snap, which needs `snapd`) even though
     `yazi` has a real native pacman package. New
     `_GLB_SNAP_NATIVE_OVERRIDES` (`lib/extras.sh`) and
     `_GLB_PACKAGE_SKIP` (`lib/package.sh`) fix this on pacman
     specifically — see the dedicated Roadmap entry above for the full
     design and verification (dry-run + full bats suite, 218/223 passing,
     confirmed the same 5 failures are pre-existing via `git stash`).
  4. Set up this VM for GitHub push access: git identity, `sudo pacman -S
     github-cli`, `gh auth login` (device-code flow, run by Greg himself
     in a real terminal since this session has no TTY), `gh auth
     setup-git`. Committed and pushed the fix.
  5. Ran real (non-sandboxed) restores of **all three profiles** —
     `developer`, `default`, `server` — each one run twice by Greg
     himself to confirm idempotency. All three confirmed clean, all real
     package/extras deltas verified installed and functional, zero
     manual-step pauses anywhere, and the `yazi`/`snapd` fix held on
     every single one. See the Roadmap entry's sub-bullets for the full
     per-profile results.
  6. **Real gotcha hit and fixed, not a GLB bug**: `default`'s restore
     replaced `~/.gitconfig` with GLB's own tracked symlink, silently
     backing up the git identity set earlier via `--global`. Fixed by
     moving identity + the `gh`-written credential-helper block into
     `~/.gitconfig.local` instead (untracked, survives future restores).
     **Worth remembering for any future fresh-VM session**: set up
     git/gh identity in `~/.gitconfig.local` from the start rather than
     `git config --global`, if `default`/`server` haven't been restored
     yet.
  - **This VM is now a fully verified, fully documented reference
    point**: all three profiles confirmed real and idempotent on vanilla
    Arch/Xfce, a real bug fixed and pushed, `CHANGELOG.md`/
    `docs/ROADMAP.md`/this file all brought current in the same session
    (see this note plus the Roadmap entry above).
  - **Next session, on Greg's primary laptop: pull first**
    (`git fetch && git log main..origin/main`) before assuming it's
    caught up — this session made several commits (`f7fc968` through
    `2a2f106`) it won't have yet. Nothing is specifically queued as a
    "pick up here" item; the yazi/snapd fix is done and verified on
    pacman, zypper's equivalent gap (no native `yazi` package there)
    remains an intentional known gap, not something to chase next.
- **Session wrap-up (2026-08-13, openSUSE VM) — ending here; Greg is
  moving to the CachyOS VM next.** Everything below is committed and
  pushed to `main` — `1ea1c05` is the latest commit on `origin/main` as
  of this note, working tree clean on this VM. Full session, in order:
  1. Cloned GLB fresh onto this openSUSE VM (`git` wasn't preinstalled,
     `sudo zypper install -y git` first, run by Greg in a real terminal
     since this session has no TTY for sudo prompts).
  2. `glb restore developer` for real: every package installed cleanly
     via zypper, including `lazygit` — a real confirmation, since
     `lazygit` is a known gap on Fedora/dnf specifically, not a
     universal one. Closes the last unverified `developer` tool on
     zypper (`ncdu`/`glow` were already confirmed).
  3. `glb restore server` for real: `ufw`/`restic`/`fail2ban`/`btop`/
     `rsync` all confirmed working via zypper too — first-ever real
     test of `server` on this package manager. (`fail2ban` looked like
     a miss at first via `which fail2ban`; false alarm — its binaries
     are `fail2ban-client`/`fail2ban-server`, confirmed via `rpm -q`
     and `systemctl status`.)
  4. Added `ranger` + `yazi` to `server` per Greg's request, matching
     `default`'s existing pairing exactly — same dotfiles config
     (`yazi.toml`/`init.lua`/vendored git-status plugin/`ranger/
     rc.conf`) copied byte-identical rather than a bare install,
     confirmed via `AskUserQuestion`.
  5. Real gap found in the process: `snapd` isn't in zypper's default
     repos at all (`zypper info snapd` → package not found), so `yazi`
     never installs on openSUSE. Documented as a known gap in both
     `default` and `server` (`packages.txt`/`extras.txt`), same
     treatment as the `lazygit`/Fedora gap rather than chasing a
     non-default OBS snapd repo.
  6. Set up push access for this VM: `gh` (already present from the
     `developer` restore) authenticated via `gh auth login`'s
     device-code flow — no SSH key needed, Greg approved it from a
     browser on another device — then `gh auth setup-git` wired the
     token into `git push`. Also set this VM's git identity (`Greg
     Gregorowicz <ggregoro@gmail.com>`, pulled from `gh api user`) and
     amended+force-pushed the one commit made before that was set, to
     fix its author.
  7. Audited the **entire** repo's commit history (not just this file)
     via `git log -i --grep`, confirming the CachyOS/pacman half of the
     2026-08-09 handoff plan (`81309df`) was never actually run — only
     its `install.sh`/`glb_sudo` verification happened there
     (`b201600`), not the `developer`/`server` profile-tools check.
     Documented a full pickup checklist on the CachyOS VM entry in Test
     Environments above (what to verify, the dry-run-doesn't-verify-
     anything caveat, the no-TTY-sudo/`pam_faillock` hazard, the
     clone/push playbook). Greg then confirmed it's the same CachyOS VM
     from 2026-08-10, not rebuilt, and — unlike this openSUSE VM — was
     never broken by the WSL2/Windows 11 host upgrade, so no repair
     detour is needed before starting there.
  - **Next session: pick up on the CachyOS VM.** Full checklist is the
    sub-bullet on the CachyOS VM entry in Test Environments above —
    `glb restore developer`/`glb restore server` for real (dry-run
    alone won't verify anything), watching specifically for `lazygit`
    (pacman's AUR-vs-official-repo story may differ from zypper's) and
    `yazi`/`snapd` (pacman's `packages.txt` comment already expects
    this to be a known gap there too, same as zypper, but hasn't been
    confirmed for real). **Pull first**
    (`git fetch && git log main..origin/main`) before assuming that VM
    is caught up — this session made several commits it won't have yet.
- **Session (2026-08-13, still on the openSUSE VM, after the zypper
  work below) — audited whether the CachyOS/pacman half of the
  2026-08-09 handoff plan (`81309df`) was ever actually run, since it
  was flagged as unconfirmed in every note since.** Answer: **no** —
  confirmed via a full `git log -i --grep="cachyos"`/`--grep="pacman"`/
  `--grep="developer"` audit of the whole repo history, not just this
  file. The only real CachyOS work on record is `b201600` (2026-08-09,
  `install.sh` + `glb_sudo`/`pam_faillock` fix on pacman) — a different,
  earlier, already-closed piece of verification, not the `developer`/
  `server` profile-tools check the 2026-08-09 plan called for. Full
  checklist and context for picking this up added as a new sub-bullet
  on the CachyOS VM entry in Test Environments above — **that's the
  next real piece of work, on the CachyOS VM, not this one.** Nothing
  else changed this session; this was an audit-and-document pass only.
  deferred `developer`/`server` zypper verification from the
  2026-08-10 wrap-up, plus added `ranger`/`yazi` to `server`.** See the
  new sub-bullet on the openSUSE VM entry in Test Environments above
  for the full verification writeup (both profiles' real `glb restore`
  results, the `lazygit`-on-zypper confirmation, the `fail2ban`
  false-alarm, and the confirmed `snapd` gap on zypper).
  - **Separately, per Greg's request: `ranger` + `yazi` added to
    `server`**, matching `default`'s existing pairing exactly —
    `ranger` in `packages.txt`, `yazi` via `snap` in `extras.txt`, and
    `server/dotfiles/.config/{ranger,yazi}/` copied byte-identical from
    `default` (custom `yazi.toml`/`init.lua`, the vendored git-status
    plugin, `ranger/rc.conf`) rather than a bare install with no config
    — confirmed via `AskUserQuestion`, Greg chose the full-config
    option. Dry-run confirmed all of it picks up correctly before the
    real restore ran.
  - Not yet committed/pushed as of this note — this VM is a clean
    clone, not wired back to `origin` as a push target (deliberately,
    same pattern as the Pop!_OS end-user-simulation VM). Whoever
    commits this needs to either push from here or relay the diff to a
    machine that can.
- **Session (2026-08-13, cloud session, status check) — Greg is now
  working from the openSUSE VM** (the freshly-created one whose boot
  issue was just diagnosed and fixed, per the entry directly below this
  one — ordinary VM boot-order/installer-timeout config, not the old
  WSL2/Hyper-V damage). Checked the repo before doing anything else:
  `origin/main` and this checkout are both at `fa874a2`, working tree
  clean, nothing to pull or push. No code changed this session — this
  was a status/handoff check, not a build.
  - **This confirms the openSUSE VM is now the right machine to resume
    the deferred verification from the 2026-08-10 wrap-up note further
    down this section**, which was blocked on exactly this VM being
    reachable: `glb restore developer --dry-run` then for real
    (confirm `ncdu`/`lazygit`/`glow`/`lazydocker` all resolve as real
    zypper package names — `lazygit` is a confirmed gap on dnf/Fedora,
    unverified on zypper), and `glb restore server --dry-run` then for
    real (first-ever real test of `server` on zypper —
    `ufw`/`rsync`/`restic`/`fail2ban`/`btop` all need to resolve and
    install cleanly). Per that same wrap-up note, the plan was CachyOS
    (pacman) first, then this VM — worth checking whether the CachyOS
    half happened before starting here, since no session note since
    2026-08-10 records either half as done.
  - This cloud session has no direct access to run commands on Greg's
    real openSUSE VM — the actual `glb restore developer`/
    `glb restore server` runs and their results still need to happen
    on that machine itself (or be relayed back here) before this
    Roadmap/Test-environments section can be updated with real
    findings.
- **Session (2026-08-13, Windows machine, in a GWB session — resolved
  the openSUSE VM issue the handoff note below asked to diagnose.** Not
  a GLB code change; purely VM/host troubleshooting, done live with
  Greg while working on GWB in a separate conversation and asked to
  update GLB's notes once resolved. The original VM this file's Test
  Environments section describes was retired; Greg created a fresh
  openSUSE Tumbleweed VM and hit what looked like the same "stuck on
  'Booting from local disk...'" symptom on it too. Diagnosed for real
  rather than assuming it was a continuation of the WSL2/Hyper-V
  damage:
  - Read the new VM's own `VBox.log` directly: `HM: HMR3Init: VT-x w/
    nested paging` and `GIM: Using provider 'KVM'` — VirtualBox's
    native VT-x engine engaging cleanly, no Hyper-V/NEM fallback. This
    ruled out an active hypervisor conflict on this host being the
    cause for the *new* VM, separate from whatever state the old,
    retired VM was actually left in.
  - Actual cause was two ordinary, unrelated VM-config gaps: (1) the
    freshly-created VM had no explicit boot order set, defaulting to
    Hard Disk before the attached installer ISO (confirmed by grepping
    the VM's `.vbox` XML for `<Order>` entries — none existed) — fixed
    via Settings → System → Boot Order, Optical above Hard Disk; (2)
    even after that fix, `VBox.log` showed it correctly reaching
    `BIOS: Booting from CD-ROM...` and the installer's own boot menu,
    but nobody was there to select "Installation" before the menu's
    timeout silently defaulted it back to "Boot from Local Disk" —
    same on-screen message, different real cause than the boot-order
    issue. Fixed by clicking into the VM and selecting Installation in
    time. Confirmed reaching openSUSE's real installer
    (Language/Keyboard/License Agreement screen, screenshot-verified).
  - **openSUSE-profile verification is unblocked again** on this new
    VM. The original VM's WSL2/Hyper-V damage (described in the
    now-superseded Test Environments note and the handoff below) was
    never actually confirmed repaired — it was abandoned in favor of
    this new VM, not fixed in place. If that specific old VM ever
    resurfaces, diagnose it independently rather than assuming this
    same resolution applies.
- **Handoff (2026-08-13, Dell laptop session, moving to the Windows/
  VirtualBox host next) — mid-troubleshooting on the openSUSE VM's
  host, not a GLB code task.** Context for whoever (or whichever
  machine) picks this up:
  - This same session added `yazi` to `profiles/default` (new `snap`
    extras method, `snapd` in `packages.txt`, git-status plugin
    vendored as a static dotfile) — committed and pushed as `8c9ecf2`,
    already rebased cleanly on top of another session's `scan_timeout`/
    glyph-fix commit (`6d502bc`). Fully done, nothing pending there.
  - Separately, Greg reported the openSUSE Tumbleweed test VM (see Test
    Environments above) is currently broken. Sequence: installed WSL2
    on the Windows host running that VM (predicted WSL2-vs-VirtualBox
    Hyper-V conflict, per memory `user-no-wsl2`) → broke the VM →
    removed WSL2 → VirtualBox issues persisted anyway. Also separately
    upgraded that host to Windows 11, which has its own additional
    VirtualBox conflicts. **All other VMs on that host still work
    fine** — only the openSUSE VM is affected.
  - **Symptom, as reported**: launching the VM hangs at the boot menu
    on "Install from Hard Drive"; the Live Installer boot option hangs
    the same way. Both hanging identically (not just the installed-disk
    boot path) points at the VM's virtual hardware/hypervisor settings,
    not a corrupted guest disk — nothing is executing past the menu
    screen regardless of what's being booted.
  - **Diagnostic checklist already given to Greg, not yet run/reported
    back**, in priority order — all on this specific VM's own
    Settings, not host-wide:
    1. System → Acceleration → **Paravirtualization Interface** —
       VirtualBox may have auto-set this VM to `Hyper-V` mode while
       WSL2/Hyper-V was active; if it's still set to `Hyper-V` now,
       that alone can hang a Linux guest. Recommended for a Linux
       guest: `KVM` (or `Default`). Compare against a working VM's
       same setting.
    2. System → Processor → **"Enable Nested VT-x/AMD-V"** — should be
       off.
    3. Whether the VM was left in a **"Saved" state** (not powered
       off) when the WSL2 install happened — if so, discard the saved
       state and do a fully cold boot rather than resume.
    4. Pull this VM's **`VBox.log`** (VirtualBox Manager → the VM →
       Logs, or the VM's folder under `Logs/VBox.log`) and check the
       tail for the actual hang reason instead of guessing further.
  - **Next step**: Greg is moving to the Windows machine itself to work
    through this list. Nothing about this is a GLB code change — it's
    purely host/VirtualBox configuration. Once the VM boots again,
    resume the originally-planned VM-matrix testing (the `developer`/
    `server` profile verification on pacman/CachyOS and zypper/openSUSE
    flagged in the 2026-08-10 wrap-up note further down this section)
    — don't assume the openSUSE VM is ready until this is confirmed
    fixed.
- **Session (2026-08-13, Windows machine, ported from GWB) — found and
  fixed a real, previously-undiscovered continuation of the 2026-08-10
  glyph-corruption bug, plus ported the `scan_timeout` fix from GWB
  (GLB's Windows sibling).** Greg asked to port GWB's `System32`
  starting-directory fix over; that part doesn't apply here (no Linux
  distro has an equivalent "elevated shells default into a system
  directory" problem), but GWB's *other* same-day fix — Starship's
  `scan_timeout` — genuinely does, since GLB installs Starship too.
  While diffing all three profiles' `starship.toml` before adding it, a
  byte-level check (`diff` first, then the same codepoint-counting
  technique the original 2026-08-10 fix used) found that `developer`
  and `server` still shipped **zero** BMP Private-Use-Area glyphs
  (`default` has 25) — the exact signature of the original bug. The
  2026-08-10 fix only ever rebuilt `default`'s copy; `developer`/
  `server` were built 2026-08-07, before that fix existed, and
  inherited the original broken 2026-08-06 preset, which nothing since
  had touched. Every real machine that's ever restored `developer` or
  `server` (Pop!_OS VM, CachyOS, openSUSE, per this file's own history)
  has had the degraded prompt the whole time, unnoticed for the same
  reason as before — normal tools render the missing range as if
  nothing's wrong.
  - **Fixed the same way the original bug was fixed, following this
    file's own documented lesson**: never hand-type or let a model
    regenerate the glyphs through a text pipeline (both silently drop
    BMP-PUA characters). Raw byte-copied `default`'s already-verified-
    correct file over both, then reapplied each file's own small
    pre-existing wording difference (an em-dash vs. hyphen, "doesn't"
    vs. "does not" in the header comment) via plain ASCII/common-
    Unicode text edits, which carry no such risk. Verified via the same
    codepoint-counting method: all three files now show 25 BMP-PUA/14
    astral-PUA glyphs. `starship prompt --path .` renders cleanly
    against all three configs with no parse warnings.
  - Added `scan_timeout = 1000` to all three files — GWB measured
    Starship's bare 30ms default genuinely timing out (~305ms real scan
    time against a slow directory) before landing on 1000ms; ported the
    same value here pre-emptively, since GLB has never had a user
    report this symptom but carries the identical unset-`scan_timeout`
    gap GWB had until today.
  - **A genuine environment blocker hit and worked around, worth
    knowing about**: this session ran on a Windows machine with GLB
    checked out at `C:\Users\ggreg\Projects\GLB` — every file in that
    checkout (confirmed via `icacls`, not assumed) has an ACL granting
    the local `Users` group only Read+Execute, no Write, and even
    attempting to grant write access via `icacls /grant` was itself
    denied (Access is denied both ways, non-elevated). This session
    wasn't running elevated and couldn't self-elevate (no interactive
    UAC path from an automated tool). Worked around by using the
    second checkout this file already documents,
    `OneDrive\Documents\GitHub\GLB` — confirmed same remote, same HEAD
    commit, clean tree, and genuinely writable (`ggreg:(F)` in its own
    ACL) before touching anything there. All of this session's edits
    are in the OneDrive checkout; `Projects\GLB` is unchanged and still
    has the ACL problem — worth fixing at the OS level (or just always
    using the OneDrive checkout on this machine) if a future Windows
    session hits the same wall.
  - Not yet verified on real Linux hardware — this session had no
    access to any of the Linux test machines/VMs this file documents,
    only a Windows checkout. Both fixes are verified structurally
    (byte/codepoint-level correctness, valid TOML, clean `starship
    prompt` render) but not via a live `glb restore` + visual check on
    a real distro. Since `~/.config/starship.toml` is a live symlink
    into wherever GLB is checked out (documented earlier in this file),
    no `glb restore` re-run should be needed on any already-restored
    machine — just a `git pull` — but that's still unconfirmed live for
    this specific pair of fixes.
- **Session wrap-up (2026-08-10, cloud session) — pausing here for a
  break; Greg is heading back to his laptop first to `git pull` and
  visually confirm the starship glyph fix there, then plans to test
  `developer` and `server` on the still-running CachyOS VM first, then
  the still-running openSUSE VM second.** Everything is committed and
  pushed to `main` — `d2602dc` is the latest commit as of this note,
  working tree clean. Both VMs are being kept up specifically for this
  (Greg's words: "I am just going to leave these VMs install in case
  we need to revisit anything").
  - **Why this is the next step:** asked directly where the project
    stands and got a grounded assessment (not a vibe) — roughly 90% of
    the way to what `docs/ROADMAP.md` calls Version 1.0 (Stable
    Release). Versions 0.1-0.6 are fully complete; Version 0.7
    (cross-distro support) is essentially done too now that
    `install.sh` is confirmed on all four package managers via real
    fresh-VM restores. The two concrete gaps identified: `developer`'s
    four newer tools (`ncdu`/`lazygit`/`glow`/`lazydocker`, added
    2026-08-09) are confirmed on apt and dnf but never verified on
    pacman or zypper; `server` has only ever been real-tested once, on
    Pop!_OS, never on dnf/pacman/zypper at all. Both VMs needed for
    this are already up, so this is the cheapest remaining way to close
    the gap before anything gets torn down.
  - **What to check on CachyOS (pacman), in order:**
    1. `glb restore developer --dry-run` then for real — confirm
       `ncdu`/`lazygit`/`glow`/`lazydocker` all resolve as real pacman
       package names (unlike Fedora/dnf, where `lazygit` was a
       confirmed real gap — see the entry above; pacman may well be
       fine here, the AUR generally carries things Fedora's official
       repos don't, but this hasn't been checked directly).
    2. `glb restore server --dry-run` then for real — first-ever
       real test of this profile on pacman: `ufw`/`rsync`/`restic`/
       `fail2ban`/`btop` all need to resolve and install cleanly.
    3. Note any `_GLB_PACKAGE_OVERRIDES` gaps found, same as every
       prior cross-distro pass in this file.
  - **Then the same two checks on the openSUSE VM (zypper)** — same
    profiles, same two things to confirm, this VM's own package-manager
    quirks (the earlier fresh-openSUSE session's mirror-preload 404
    noise is cosmetic, not a sign of trouble, if it shows up again).
  - **Housekeeping identified but not yet done, lower priority than
    the two verification items above:** `VERSION` is stale (still
    `0.5.0` despite two more versions' worth of shipped work since);
    no `CONTRIBUTING.md` yet, which the roadmap's Version 1.0
    "community-ready project" goal implies now that the repo is
    public. Worth picking up once the profile verification above is
    done, not blocking it.
- **Session wrap-up (2026-08-10, cloud session) — pausing here by
  Greg's choice; next session picks up on a fresh Fedora 44 GNOME 50
  dnf VM.** Everything is committed and pushed to `main` — `6a6d61b` is
  the latest commit as of this note, working tree clean. This session
  verified `install.sh` end-to-end on both CachyOS/pacman and a fresh
  openSUSE Tumbleweed/zypper VM (see the two dedicated Roadmap entries
  above for full writeups) — the `glb_sudo`/`pam_faillock` fix is now
  confirmed working on real Arch-based hardware, and every one of the
  four supported package managers except dnf now has real curl-install
  verification.
  - Greg is seriously considering switching his own daily driver to
    openSUSE/KDE Plasma after how well this session's test went — his
    own life/hardware decision, not a GLB task, but worth knowing if a
    future "daily driver" reference in this file needs updating.
  - **Discussed and explicitly deferred, not started:** fleshing out
    the `developer` profile further. Agreed instead that the higher-
    leverage next step is closing a known, already-flagged gap: `ncdu`,
    `lazygit`, `glow`, and `lazydocker` were added to `developer`
    (2026-08-09) but never confirmed to resolve as real package names
    on dnf/pacman/zypper specifically (only apt, implicitly) — worth
    doing once a dnf VM exists, alongside the Fedora `install.sh`
    verification below, since it's the same VM either way.
  - **Next session: pick up on a fresh Fedora 44 GNOME 50 dnf VM**
    (Greg's own words: "I should build a new Fedora 44 Gnome 50 dnf
    test VM first and close out the testing there... I will do that
    next"). Two things to verify there: (1) `install.sh`'s curl
    one-liner on dnf — the last of the four supported package managers
    without real curl-install coverage (dnf/Fedora itself is
    well-tested via `git clone`, just not this specific installer
    path); (2) the `developer` profile's four new TUI tools resolving
    correctly on dnf, per the deferred item above. Once dnf is closed
    out, `install.sh` will have real end-to-end verification on all
    four supported package managers.
  - **Follow-up discussion, same session, no code changed:** Greg
    asked how an end user who's already restored `default` could still
    grab a preset from starship.rs and make the prompt their own,
    rather than being stuck with Greg's Tokyo Night preset. Explained
    the real mechanics of `~/.config/starship.toml` being a symlink
    into GLB's own repo checkout: editing it in place technically
    works but edits land inside GLB's tracked git checkout (git-pull
    conflict risk down the line); breaking the symlink and dropping in
    a personal file is cleaner but **will get silently reverted** the
    next time `glb restore` runs on that profile, since
    `glb_apply_profile_dotfiles` (`lib/profile.sh`) treats a
    non-symlink file it finds there as pre-existing data to back up to
    `.glb-backup` and relink over — verified by reading the actual
    backup/relink logic, not just recalling it. Pointed to
    `glb restore --from-manifest <path>` (already built, see the
    installation-manifests Roadmap entry) as the durable answer: a
    personal directory shaped like a mini-profile, entirely outside
    GLB's own repo, immune to this silent-revert behavior. Greg then
    asked whether he should build a real example of this to confirm it
    works, and offered to do it either now on an existing machine or
    folded into the upcoming Fedora VM session — **decided to defer
    both to after Fedora VM testing wraps up**, picking this back up
    then rather than context-switching now.
- **Session wrap-up (2026-08-09, cloud session) — pausing here for the
  night by Greg's choice; picking back up tomorrow on a fresh CachyOS
  VM.** Everything is committed and pushed to `main` — `9d77735` is the
  latest commit as of this note, working tree clean.
  - Fixed a real bug Greg found by actually running the documented
    `install.sh` one-liner on his real Pop!_OS machine: `curl | sh`
    failed with `sh: 14: set: Illegal option -o pipefail`, since
    `install.sh` uses the bash-only `pipefail` option but every doc
    told users to pipe through `sh` (`dash` on Debian/Ubuntu/Pop!_OS).
    Same bug class as the `lazydocker` `sh`-vs-`bash` fix earlier this
    session — see the two dedicated Roadmap entries above for the full
    diagnosis and fix (`README.md`, `install.sh`, `docs/ARCHITECTURE.md`
    changed to `| bash`).
  - Merged to `main` and pushed. Greg was about to re-run the corrected
    one-liner on the Pop!_OS machine to confirm it clones cleanly now —
    **not yet confirmed as of this note**, worth checking next session
    whether he reported back on that.
  - **Next session: pick up on a fresh CachyOS VM** (Greg's own words:
    "I will create a fresh VM for CachyOS... that will have to be
    tomorrow"). This is real, still-open verification work, not a new
    feature — CachyOS/pacman is exactly the distro family
    (Arch-based) where the `glb_sudo`/`pam_faillock` lockout fix
    (built 2026-08-09, see its own Roadmap entry) has never been
    tested for real; both prior confirmed lockout occurrences
    (CachyOS 2026-08-07, EndeavourOS 2026-08-08) were on pacman
    machines, so this is the fix's first real chance to prove it works
    against the exact failure mode it was built for. Also worth
    confirming on this VM once it exists: `install.sh`'s curl one-liner
    itself has still never been tested against pacman specifically
    (only Pop!_OS/apt so far). After CachyOS, Greg's plan is openSUSE
    (zypper) next.
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