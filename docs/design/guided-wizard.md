# Design: Guided Configuration Wizard

**Status:** Implemented (2026-08-07)
**Added:** 2026-08-07

## Motivation

Version 0.5's original planned list had four separate, unscoped bullets:
express installation, guided configuration wizard, configuration summary,
progress reporting. Reviewing what already exists (`glb restore` with no
profile name already shows a numbered profile picker; `--dry-run` already
produces a full install preview; the existing `[INFO]`/`[SUCCESS]`/
`[WARNING]`/`[ERROR]` log lines already show real-time step-by-step
progress) shows these aren't four separate features — they collapse into
one small enhancement of the existing interactive picker.

## Scoping decisions (2026-08-07, via `AskUserQuestion`)

- **Discovery only, not customization.** The wizard helps someone pick
  the right *whole* profile — it does not let them opt individual
  packages in or out of a profile. Per-package customization would need
  a new data model and UI, and cuts against GLB's established
  "curate, don't reinvent, one clear path per category" philosophy
  (Podman over Docker, mise over per-language managers, etc. — every
  prior profile decision picked one opinionated option, not a menu).
- **Express installation needs no new code.** It's the existing direct
  `glb restore <profile>` command, for someone who already knows which
  profile they want — the wizard is the alternative path for someone
  who doesn't. Nothing to build here beyond documenting the two-path
  story (this doc + `docs/ROADMAP.md`).
- **Progress reporting needs no new code.** The existing per-step log
  lines already show real-time progress through packages/extras/
  dotfiles. This bullet folds into the wizard's dry-run-based preview
  rather than becoming separate progress UI (counters, bars).

Net effect: three of the four original Version 0.5 bullets need zero new
mechanism. The only real feature here is the fourth — a richer version of
the existing no-argument `glb restore` picker.

## Scope

**In scope:**

- `glb_restore_interactive` (`lib/profile.sh`) gains a one-line
  description shown next to each profile name in the picker.
- After a profile is chosen, automatically show the same output
  `--dry-run` already produces (what would install/link/back up), then
  ask for confirmation before actually applying.
- If the user declines, exit cleanly with nothing changed — same
  fail-safe posture as the rest of GLB's confirmation-style prompts
  (`glb_prompt_manual_step`).

**Explicitly out of scope:**

- Per-package opt-in/opt-out within a chosen profile.
- A multi-step wizard beyond "pick a profile, see a preview, confirm."
- Any change to the direct `glb restore <profile>` path — it keeps
  applying immediately with no picker, no preview, no confirmation
  prompt, exactly as it does today. Only the *no-argument* path gets
  richer.
- New progress-reporting mechanism (counters, percentages, bars).

## Where the description text comes from

Each profile's `packages.txt` already opens with a prose comment
explaining who it's for (e.g. developer's: "Aimed at someone newer to
development work who wants a solid, complete kit without researching
every tool choice themselves..."), but that prose is written for someone
editing the file, not for a one-line picker display, and parsing it out
would be fragile (no fixed format, several sentences long).

Built as a small explicit `profiles/<name>/description.txt` — a single
line, the same kind of narrowly-scoped-per-concern file GLB already
uses (`packages.txt` for packages, `extras.txt` for extras). Keeps the
picker's data source explicit and stable instead of scraping
developer-facing comments. Added to all four existing profiles
(`default`, `new-to-linux`, `developer`, `server`); optional — a
profile with no `description.txt` just shows its bare name in the
picker (`_glb_profile_description`, `lib/profile.sh`).

## Resolved: new default (2026-08-07, via `AskUserQuestion`)

The richer picker flow (descriptions → dry-run preview → confirm) is
bare `glb restore`'s new default behavior, not opt-in behind a flag —
someone who runs `glb restore` with no arguments presumably wants
guidance. The express path (`glb restore <profile>` with a name) is
unaffected: it still applies immediately, no picker, no preview, no
confirmation. `tests/dispatcher.bats` and `tests/profile.bats`'s
existing interactive-picker tests were updated to feed the new
confirmation answer rather than just extended with new cases, as
anticipated when this question was first written.

## Why this is viable rather than scope creep

No new subsystem: `glb_restore_interactive` and the `--dry-run` machinery
it would call already exist. The only genuinely new pieces are one short
description file per profile and a confirmation prompt reusing the same
`read -r -p` pattern already used elsewhere (`glb_prompt_manual_step`,
`glb_restore_interactive`'s own profile-number prompt).
