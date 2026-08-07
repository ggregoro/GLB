# Design: Repairing Existing Installations

**Status:** Implemented (2026-08-07)
**Added:** 2026-08-07

## Motivation

`glb restore <profile>` is already fully idempotent — every session that
has run a second restore on the same machine (documented repeatedly in
CLAUDE.md's Roadmap section) confirms it comes back fully clean:
missing packages get reinstalled, missing dotfile links get relinked,
missing extras get reinstalled. That already covers the most obvious
"repair" scenario — something got uninstalled or unlinked, just run
restore again.

So the real gap isn't detection-and-fix logic that doesn't already
exist — it's that checking whether a live machine still matches a
profile currently takes two manual steps (`glb export`, which also
saves a snapshot to disk you may not want, then `glb diff <snapshot>
<profile>`), and there's no built-in offer to fix what's found. Repair
should be a one-shot convenience command, not a new detection
mechanism.

## Scoping decision (2026-08-07, via `AskUserQuestion`)

Two candidate gaps were considered:

1. A one-shot check-then-fix command (chosen).
2. Deepening the installed-checks themselves to catch real corruption —
   concrete known weak spot: `glb_install_zsh_plugins`
   (`lib/plugins.sh`) only checks `[[ -d "$dest" ]]`, so a directory
   left behind by an interrupted `git clone` (network drop, disk full)
   would be reported "already installed" forever and never get fixed
   by a plain restore re-run. Packages/dotfiles/font/flatpak checks are
   all reasonably robust already; zsh plugins are the one clear known
   gap.

**Chose (1), deliberately deferring (2).** Auditing/deepening every
installed-check across the codebase is a broader, more invasive change
that's only worth doing once real corruption cases actually show up in
practice, not pre-emptively. Revisit (2) as a separate future item if
that happens.

## Scope

**In scope:**

- `glb repair <profile>`: an ephemeral export (packages + dotfiles
  only — no `shell.txt`/`metadata.yaml`, no snapshot saved to disk)
  diffed against the named profile, reusing `lib/export.sh`'s and
  `lib/diff.sh`'s existing internal building blocks directly rather
  than the full `glb_export_snapshot`/`glb_diff_snapshot` entry points.
- No drift found: report clean, exit 0.
- Drift found: print the same package/dotfile diff report `glb diff`
  already produces, then ask "Re-run `glb restore <profile>` now to fix
  this?" — reusing the confirm-prompt pattern just built for the guided
  wizard (`docs/design/guided-wizard.md`). Declining, or no input
  available to answer with, leaves the machine untouched and exits 1
  (same fail-safe posture as everywhere else GLB asks for
  confirmation).
- Confirming re-runs the real `glb_apply_profile <profile>` (no
  `--dry-run`) and returns its own exit status.
- Takes a profile name only, not a snapshot name — "repair" means "get
  this machine back to matching the profile I set it up with." A
  snapshot from a different machine or point in time isn't a sensible
  repair target.

**Explicitly out of scope:**

- Deepening/auditing existing installed-checks for real corruption
  (deferred, see above).
- A `--dry-run` flag — redundant here. The diff report itself already
  is the preview, and the fix step has its own separate confirm gate;
  a dry-run flag would just be a second way to ask for the same thing.
- Repairing against an arbitrary snapshot instead of a profile.

## How it's built (reusing existing pieces, no new mechanism)

1. `mktemp -d` an ephemeral directory.
2. Call `glb_export_packages`/`glb_export_dotfiles` (`lib/export.sh`)
   directly against it — not the public `glb_export_snapshot` entry
   point, since `shell.txt`/`metadata.yaml` aren't used by the diff at
   all, and printing "Exported snapshot: ..." makes no sense for an
   invisible, ephemeral, never-saved operation.
3. Call `lib/diff.sh`'s existing `_glb_diff_packages`/`_glb_diff_dotfiles`
   directly, comparing (ephemeral dir, labeled "current state") against
   (the profile's real directory, labeled with the profile name) —
   bypassing `_glb_diff_resolve_dir`'s name-based `profiles/`/
   `snapshots/` lookup entirely, since real paths are already in hand.
4. `rm -rf` the ephemeral directory unconditionally before returning,
   regardless of which path was taken.
5. No drift → log success, return 0. Drift → print the report, prompt
   to fix, and either apply for real (returning `glb_apply_profile`'s
   status) or cancel cleanly (return 1).

New `lib/repair.sh`, wired into the dispatcher as a `repair <profile>`
command. Every step above is an existing function already built this
session (`glb_export_packages`, `glb_export_dotfiles`,
`_glb_diff_packages`, `_glb_diff_dotfiles`, `glb_apply_profile`, the
confirm-prompt pattern) — the only genuinely new code is the temp-dir
plumbing and the small orchestrating function that glues them together.
