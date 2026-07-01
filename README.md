# Harness Pipeline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A set of **stack-agnostic** Claude Code skills that compose into a spec-driven engineering harness —
ticket → spec → implementation → verification → PR → close. Built to be pulled into other projects
(Swift, web, API, whatever) and shared with a team.

The design goal: the **skills are generic mechanism; a per-project `docs/HARNESS.md` is the only
place stack-specifics live.** The same `harness:build` runs against a Swift app and a web service —
it just reads a different HARNESS.md.

## Install

Pull the skills into a project with [vercel-labs/skills](https://github.com/vercel-labs/skills):

```bash
npx skills add acatl/harness
```

It discovers the `skills/<name>/SKILL.md` layout automatically. Or wire them by hand — symlink (live
edits) or copy each skill dir into the consuming project's `.claude/skills/`:

```bash
ln -s /path/to/harness/skills/harness-build .claude/skills/harness-build
```

Then run **`/harness:init`** once in the project to generate its `docs/HARNESS.md` (the binding layer
every other skill reads). Until that exists, the rest of the pipeline is inert.

### Also included: `walk-me-through` (general-purpose)

[`walk-me-through`](skills/walk-me-through/SKILL.md) is a standalone, **multi-purpose** skill — not tied to
the harness. Working with an agent, your job is mostly *deciding*; it turns a wall of questions into a
clean one-at-a-time flow (indexed options, tradeoffs, a recommendation, an escape hatch). The harness uses
it for its forks, but it's useful in any project. Install just this one:

```bash
npx skills add acatl/harness --skill walk-me-through
```

## Namespace

Every **pipeline** skill is namespaced **`harness:`** (e.g. `/harness:build`) so it's clear where it came
from when shared. The general-purpose [`walk-me-through`](skills/walk-me-through/SKILL.md) is the
exception — deliberately un-namespaced so it's useful standalone in any project.

## The pipeline

| Skill | Role |
|-------|------|
| `harness:init` | Scan a project, interview the operator, generate its `docs/HARNESS.md` (the binding layer). Run this first — every other skill is inert without it. |
| `harness:refine` | Turn a rough ticket into a well-formed, spec-ready task. |
| `harness:explore` | Optional. Thinking partner for big codebases (improved OpenSpec Explore, digestible output). |
| `harness:build` | The workhorse. Author the spec (proposal → recon → design → reviews → tasks) if none exists, else resume; then implement → verify. `gated` (default) / `yolo`. Stops at *verified, not shipped*. |
| `harness:fine-tune` | Sticky polish loop after build (fix → test → approve → commit). Exits only on explicit signal. |
| `harness:test-guide` | Read-only test companion. Derives a change's test scenarios from spec scenarios + AC + decisions, skips what automated tests already cover, and walks you through the gap one at a time (ROI-first) with how-to-drive steps + pass/fail/skip. Persists nothing. |
| `harness:ship` | Push + open the PR. Deliberate, post-test. |
| `harness:finish` | Post-merge close: sync specs + archive. Confirmable merge-gate; two-merge or single-merge. Backfills run-log reality fields. |
| `harness:address-pr-comments` | Triage + resolve PR review comments. |
| `harness:review` | Aggregate the harness run-log, surface recurring friction, propose harness improvements (data-backed, never auto-applied). |
| `harness:status` | Read-only. Derive where a change is in the pipeline and the one next step from live state (openspec, the change's `harness/` artifacts, git/PR, tracker). Works cold — no stored pointer. |

`harness:build` calls three **review sub-skills** during authoring — `harness:recon` (prior-art reuse
ledger), `harness:architecture` (engineering gate), `harness:design` (UX gate) — each with its own full
lenses reference. They're invoked by `build` but also run standalone.

The pipeline is **self-observing**: `harness:build` logs each run to a JSONL run-log; `harness:review`
turns that data into concrete improvements to the skills/config. Schema in
[templates/harness-runs.SCHEMA.md](templates/harness-runs.SCHEMA.md).

Shared rule: [rules/recon-first.md](rules/recon-first.md) — search for prior art before authoring any
exported/shared symbol (the contributor-level twin of `harness:recon`).

Full chain with all forks and gates: [docs/pipeline.md](docs/pipeline.md).

## Dependencies

- **[OpenSpec](https://github.com/Fission-AI/OpenSpec)** — a **hard dependency**. The harness is a
  spec-driven pipeline built on OpenSpec: skills call its CLI (`openspec list`, `openspec status`,
  `openspec validate`, …) and its vendor skills, and the change state lives under
  `openspec/changes/<change>/`. Install the CLI (`npm install -g @fission-ai/openspec@latest`) and run
  `openspec init --tools claude` in the consuming project **before** `harness:init`. Without it,
  `build`/`status`/`finish` cannot resolve change state.
- **A task tracker** — Kino / Jira / Linear / GitHub Issues, reached through a verb contract declared
  in HARNESS.md. Swappable per project.

## What the harness creates

Beyond the code your change introduces, the pipeline writes a small set of **per-change artifacts** so
a run is auditable and resumable cold (by you later, or a teammate who wasn't there):

| Artifact | Written by | Purpose |
|----------|-----------|---------|
| `docs/HARNESS.md` | `harness:init` | The per-project binding layer (sensors, tracker verbs, runtime-verification recipe, paths). |
| `openspec/changes/<change>/` | `harness:build` | The OpenSpec change: `proposal.md`, `design.md`, `tasks.md`, `specs/<cap>/spec.md` (Given/When/Then scenarios). |
| `…/<change>/harness/recon.md` | `harness:recon` | Prior-art reuse ledger. |
| `…/<change>/harness/architecture-review.md` · `design-review.md` | `harness:architecture` · `harness:design` | The engineering + UX review gates. |
| `…/<change>/harness/decisions.md` | every stage | Load-bearing decision ledger (attributed); folded into the PR body. |
| `…/<change>/harness/pr-body.md` | `harness:build` | The PR description, folded from the run + decisions; reused by `harness:ship`. |
| `…/<change>/harness/progress.md` | `harness:build` | Resume state for an interrupted build. |
| `.claude/harness/runs.jsonl` | `harness:build` | Self-observation run-log (JSONL); `harness:review` aggregates it. See [templates/harness-runs.SCHEMA.md](templates/harness-runs.SCHEMA.md). |

`harness:status` and `harness:test-guide` are **read-only** — they derive from the above and persist
nothing. On `harness:finish`, the change's specs are merged into the main specs and the change dir is
moved to `openspec/changes/archive/`.

## Layout

```text
README.md
docs/          design + reference (blueprint, pipeline, porting plan, runtime-verification binding)
templates/     HARNESS.md template that harness:init fills in per project
skills/        the harness:* skills (skills/harness-<name>/SKILL.md)
rules/         shared contributor rules (e.g. recon-first)
scripts/       sync-skill-resources.sh (bundle drift guard) + skill-frontmatter check
```

## Status

Early — design locked, porting in progress. The source of truth for progress is
[docs/PORTING-PLAN.md](docs/PORTING-PLAN.md) (read its Status pointer to see where things stand).

## Contributing & license

See [CONTRIBUTING.md](CONTRIBUTING.md) for commit conventions, skill-authoring rules, and local checks
(`npm run check`). Licensed under [MIT](LICENSE).
