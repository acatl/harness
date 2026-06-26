# Harness Pipeline

A set of **stack-agnostic** Claude Code skills that compose into a spec-driven engineering harness —
ticket → spec → implementation → verification → PR → close. Built to be pulled into other projects
(Swift, web, API, whatever) and shared with a team.

The design goal: the **skills are generic mechanism; a per-project `docs/HARNESS.md` is the only
place stack-specifics live.** The same `harness:build` runs against a Swift app and a web service —
it just reads a different HARNESS.md.

## Namespace

Every skill is namespaced **`harness:`** (e.g. `/harness:build`) so it's clear where it came from
when shared. See [docs/PORTING-PLAN.md](docs/PORTING-PLAN.md) for the rationale.

## The pipeline

| Skill | Role |
|-------|------|
| `harness:init` | Scan a project, interview the operator, generate its `docs/HARNESS.md` (the binding layer). Run this first — every other skill is inert without it. |
| `harness:refine` | Turn a rough ticket into a well-formed, spec-ready task. |
| `harness:explore` | Optional. Thinking partner for big codebases (improved OpenSpec Explore, digestible output). |
| `harness:build` | The workhorse. Author the spec (proposal → recon → design → reviews → tasks) if none exists, else resume; then implement → verify. `gated` (default) / `yolo`. Stops at *verified, not shipped*. |
| `harness:fine-tune` | Sticky polish loop after build (fix → test → approve → commit). Exits only on explicit signal. |
| `harness:ship` | Push + open the PR. Deliberate, post-test. |
| `harness:finish` | Post-merge close: sync specs + archive. Confirmable merge-gate; two-merge or single-merge. Backfills run-log reality fields. |
| `harness:address-pr-comments` | Triage + resolve PR review comments. |
| `harness:review` | Aggregate the harness run-log, surface recurring friction, propose harness improvements (data-backed, never auto-applied). |

The pipeline is **self-observing**: `harness:build` logs each run to a JSONL run-log; `harness:review`
turns that data into concrete improvements to the skills/config. Schema in
[templates/harness-runs.SCHEMA.md](templates/harness-runs.SCHEMA.md).

Full chain with all forks and gates: [docs/pipeline.md](docs/pipeline.md).

## Dependencies

- **OpenSpec** — a hard dependency (CLI + its vendor skills). The harness skills call it and assume
  it's installed in the consuming project.
- **A task tracker** — Kino / Jira / Linear / GitHub Issues, reached through a verb contract declared
  in HARNESS.md. Swappable per project.

## Layout

```
README.md
docs/          design + reference (blueprint, pipeline, porting plan, runtime-verification binding)
templates/     HARNESS.md template that harness:init fills in per project
skills/        the harness:* skills (skills/harness-<name>/SKILL.md)
rules/         shared contributor rules (e.g. recon-first)
```

## Status

Early — design locked, porting in progress. The source of truth for progress is
[docs/PORTING-PLAN.md](docs/PORTING-PLAN.md) (read its Status pointer to see where things stand).
