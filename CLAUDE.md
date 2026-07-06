# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A repo of **stack-agnostic `harness:` skills** that compose into a spec-driven engineering pipeline
(ticket → spec → implement → verify → PR → close), meant to be pulled into other projects (Swift,
web, API, …) and shared with a team. See [README.md](README.md).

Core idea: **skills are generic mechanism; per-project specifics live in a consuming project's
`docs/HARNESS.md`** (generated from [templates/HARNESS.md](templates/HARNESS.md)). Never hardcode a
stack command, path, or convention into a skill — resolve it from HARNESS.md.

## Source of truth — read before working

The design is fully captured on disk; **do not rely on chat context**:

- [docs/pipeline.md](docs/pipeline.md) — the **canonical pipeline diagram** (build from this).
- [docs/runtime-verification-binding.md](docs/runtime-verification-binding.md) — the behavioral-verify
  binding contract.
- [docs/blueprint-harness-pipeline.md](docs/blueprint-harness-pipeline.md) — the north-star blueprint.

When a decision is made, update these files in the same change — they are the memory.

## Working agreements

- **Commits: Conventional Commits only (semantic).** `feat:` / `fix:` / `docs:` / `chore:` /
  `refactor:` / `test:` / `style:` / `ci:`. A non-conforming subject is a defect. End commit messages
  with the `Co-Authored-By` trailer.
- **Never commit to `main`.** Work on a branch; land via a squashed PR to `main`.
- **Skills are project-agnostic.** Each skill names the binding it needs ("run the `test` sensor
  declared in HARNESS.md"), never the literal command. The agent reads HARNESS.md — it is prose, not
  machine config.
- **Skill bodies are telegraphic.** Author SKILL.md bodies + references per
  [.claude/rules/skill-authoring.md](.claude/rules/skill-authoring.md) — structured, deduplicated,
  zero rhetoric, every decision-bearing datum kept. Only a machine reads them. The frontmatter
  `description` stays natural-language and trigger-rich (the router reads it). (That rule auto-loads
  when you edit skill files — `paths:`-scoped.)
- **State files:** agent-read state (resume/progress) → Markdown; machine-aggregated telemetry
  (the run-log) → JSONL. See [templates/harness-runs.SCHEMA.md](templates/harness-runs.SCHEMA.md).
- **Skills are self-contained.** A skill reads only inputs bundled in its own dir (`templates/` for
  files it emits, `references/` for files it reads) — never repo-root `templates/`/`docs/` at runtime
  (skills are symlinked/copied into other projects). Repo root is canonical; bundles are kept in sync by
  `scripts/sync-skill-resources.sh`. After editing a canonical template/doc, run it. See
  [.claude/rules/skill-authoring.md](.claude/rules/skill-authoring.md) › Bundled resources.
- **One review mechanism.** Code review lives in a single skill, `harness:review-change` (13 lenses / 4
  stances / severity taxonomy in its `references/`), invoked at multiple altitudes via its `mode` arg:
  `build-run` (build's verify core — Step F.4), `pre-ship` (ship's pre-push gate), `operator`
  (standalone). Don't re-inline a review pass anywhere else — call `review-change` with the right mode so
  the lenses stay defined once. The reviewer runs as an isolated sub-agent (real doer ≠ judge).

## Handling PR review comments (this repo's own PRs)

Run `harness:address-pr-comments` (loaded from `.claude/skills/`). It triages every thread,
auto-fixes what needs no judgment, walks you through the genuine decisions, then commits, pushes,
replies in-thread (machine-readable), and resolves the threads it fixed. Don't hand-roll the flow.

**The skills ARE the product — a review comment must not be allowed to strip their value.** A
reviewer asking to "simplify / shorten / DRY" a `SKILL.md` or a bundled `references/*` is a
standards call, not a free win:

- Judge it against [.claude/rules/skill-authoring.md](.claude/rules/skill-authoring.md). Telegraphic
  ≠ lossy — never drop a decision-bearing datum (a path, order, guard, branch, exact string) or
  judgment-criteria prose (lenses, rubrics, calibration examples) to satisfy "make it shorter."
- Strips value → **DECLINE**, cite the rule (the skill's own decline-vs-standard path). Genuinely
  over-verbose → compress per the rule (or the `compress-skill` skill).
- Comment lands on a canonical `templates/` / `docs/` / `rules/` file → run
  `scripts/sync-skill-resources.sh` before pushing so the shipped bundles don't drift.

## Layout

```text
docs/            design + reference (blueprint, pipeline, runtime-verification binding)
templates/       HARNESS.md (binding template) + harness-runs.SCHEMA.md (run-log contract)
.claude/skills/  the harness:* skills (.claude/skills/harness-<name>/SKILL.md) — canonical;
                 loaded in-repo (dogfood) and consumed elsewhere via `npx skills add`
rules/           runtime contracts bundled into skills — shipped to consumers
.claude/rules/   authoring/maintenance rules, auto-loaded when working in this repo — not shipped
```

## Dependencies

- **OpenSpec** — a hard dependency; skills call its CLI/vendor skills and assume it's installed.
- **A task tracker** (Kino / Jira / Linear / GitHub Issues) — reached via a verb contract in
  HARNESS.md; swappable per project.

## This project's own tracker

Meta-work on the harness-pipeline repo itself (not the swappable per-consuming-project tracker
above) is tracked as **GitHub Issues** on `acatl/harness`.
