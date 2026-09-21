# Design: Update Notifier (Arch only)

**Status:** Built (2026-09-21)
**Added:** 2026-09-21

## Motivation

Arch is rolling-release: updates arrive continuously and nothing tells
you they exist until you run `pacman -Syu` and see. A small desktop
notification when updates are waiting closes that gap without adding a
package-management GUI.

This sits at the edge of GLB's terminal-first scope
([`docs/PHILOSOPHY.md`](../PHILOSOPHY.md)), so it is deliberately
narrow: a ~60-line script and two systemd units that use tools already
on the machine. It does not update anything itself — the notification
just says updates exist; the user runs `paru` or `sudo pacman -Syu`.

## What ships (all in the `default` profile)

| Piece | Where |
|---|---|
| Script | `dotfiles/.local/bin/update-check-notify` |
| Units | `dotfiles/.config/systemd/user/update-check.{service,timer}` |
| Package | `pacman-contrib` in `packages.txt` (provides `checkupdates`) |
| Enable step | `update-check.timer    pacman` in `timers.txt` |

The timer runs 5 minutes after boot, then every 6 hours.

## How the script decides

1. **Not Arch → quiet no-op.** If `checkupdates` isn't installed it
   exits 0 immediately. (The script is linked on every distro because
   dotfiles are; only the timer's enable step is pacman-gated.)
2. **Repo updates:** `checkupdates` — uses a temporary copy of the sync
   database, so it needs no root and never touches the real one. Exit
   0 = updates, 2 = none, anything else (offline, mirror down) is
   ignored rather than notified.
3. **AUR updates:** `paru -Qua`, when `paru` is present.
4. **Only notify on change.** A hash of the pending set is stored in
   `$XDG_STATE_HOME/update-check/last-notified`. The same set doesn't
   re-notify every 6 hours; a changed set does. The hash is only saved
   if `notify-send` succeeded, so a failed notification retries. When
   nothing is pending the state is cleared, so the next update notifies.

## Why `timers.txt` and `lib/timers.sh`

GLB had no way to enable a systemd unit. Rather than special-casing one
timer inside `profile.sh`, this adds a small general step: a profile's
optional `timers.txt` lists `<unit> [package-manager]`, and
`glb_apply_profile_timers` enables each with
`systemctl --user enable --now` after the dotfiles step (the units are
dotfiles, so they must be linked first).

- A timer restricted to a package manager is skipped, with a note, on
  any other.
- **Failing to enable is a warning, never a failed restore.** No
  reachable user session is normal for a bootstrap tool (a restore over
  ssh, a container). The warning prints the exact command to run later,
  the same spirit as the sudo-gated manual step.
- Already-enabled timers are left alone (idempotent).

## Known limits

- **Arch/pacman only.** apt, dnf and zypper each have their own
  update-notification tooling; writing checks for them without a real
  machine of each kind to verify on would break GLB's "confirmed on real
  machines" standard. `pacman-contrib` is skipped there via
  `_GLB_PACKAGE_SKIP`.
- **`glb restore --undo` doesn't disable the timer.** Undo reverses
  dotfile links; a timer enabled by an earlier restore stays enabled,
  pointing at a unit file that is no longer there. Disable it with
  `systemctl --user disable --now update-check.timer`.
- **`systemctl --user disable` also removes the unit's dotfile link.**
  The unit files are symlinks into the repo, and `disable` deletes a
  linked unit's symlink along with its enable link. That stops the
  alerts, but the next `glb restore` re-links the unit and re-enables
  the timer (the dotfile step tolerates the gone destination — see the
  CHANGELOG entry on stale backups). To opt out for good on a machine,
  drop the `update-check.timer` line from `timers.txt`.
- **Needs a running desktop session** with a notification daemon
  (`notify-send`); without one the check runs but nothing is shown.
