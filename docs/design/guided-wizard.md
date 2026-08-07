# Design: Guided Configuration Wizard

**Status:** Proposed — not yet implemented
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

Recommended approach: a small explicit `profiles/<name>/description.txt`
— a single line, the same kind of narrowly-scoped-per-concern file GLB
already uses (`packages.txt` for packages, `extras.txt` for extras).
Keeps the picker's data source explicit and stable instead of scraping
developer-facing comments. Would need one new file added per existing
profile (`default`, `new-to-linux`, `developer`, `server`) as part of
building this.

## Open design question

Should the richer picker flow (list with descriptions → dry-run preview
→ confirm) become the **new default** behavior of a bare `glb restore`
with no arguments, or should it be opt-in behind some new flag?

Making it the new default is the more useful outcome (it's the whole
point of "guided" — someone who runs bare `glb restore` presumably wants
guidance) but it's a real behavior change: today, `glb_restore_interactive`
picks a profile and applies it immediately with no extra confirmation
step. Existing bats tests (`tests/dispatcher.bats`,
`tests/profile.bats`) that exercise this path assert on that immediate-
apply behavior and would need updating to feed the new confirmation
prompt, not just extended with new cases.

Leaning toward "yes, make it the new default" — the express path
(`glb restore <profile>` with a name) is unaffected and remains the
zero-friction option for anyone who wants it — but this is worth
confirming explicitly before implementation, the same way the
in-repo-snapshots question was confirmed before building `glb export`.

## Why this is viable rather than scope creep

No new subsystem: `glb_restore_interactive` and the `--dry-run` machinery
it would call already exist. The only genuinely new pieces are one short
description file per profile and a confirmation prompt reusing the same
`read -r -p` pattern already used elsewhere (`glb_prompt_manual_step`,
`glb_restore_interactive`'s own profile-number prompt).
