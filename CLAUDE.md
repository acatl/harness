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

- [docs/PORTING-PLAN.md](docs/PORTING-PLAN.md) — the living plan. Its **Status pointer** says where
  things stand and what's next. Read it first to resume.
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
  [docs/SKILL-STYLE.md](docs/SKILL-STYLE.md) — structured, deduplicated, zero rhetoric, every
  decision-bearing datum kept. Only a machine reads them. The frontmatter `description` stays
  natural-language and trigger-rich (the router reads it).
- **State files:** agent-read state (resume/progress) → Markdown; machine-aggregated telemetry
  (the run-log) → JSONL. See [templates/harness-runs.SCHEMA.md](templates/harness-runs.SCHEMA.md).
- **Skills are self-contained.** A skill reads only inputs bundled in its own dir (`templates/` for
  files it emits, `references/` for files it reads) — never repo-root `templates/`/`docs/` at runtime
  (skills are symlinked/copied into other projects). Repo root is canonical; bundles are kept in sync by
  `scripts/sync-skill-resources.sh`. After editing a canonical template/doc, run it. See
  [docs/SKILL-STYLE.md](docs/SKILL-STYLE.md) › Bundled resources.

## Layout

```
docs/        design + reference (blueprint, pipeline, porting-plan, runtime-verification binding)
templates/   HARNESS.md (binding template) + harness-runs.SCHEMA.md (run-log contract)
skills/      the harness:* skills (skills/harness-<name>/SKILL.md)
rules/       shared contributor rules
```

## Dependencies

- **OpenSpec** — a hard dependency; skills call its CLI/vendor skills and assume it's installed.
- **A task tracker** (Kino / Jira / Linear / GitHub Issues) — reached via a verb contract in
  HARNESS.md; swappable per project.
