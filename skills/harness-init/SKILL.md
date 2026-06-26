---
name: harness-init
description: >
  Initialize the harness pipeline in a project — scan what's already there, interview the operator
  for what can't be inferred, and generate docs/HARNESS.md (the binding layer every other harness
  skill reads). Use when setting up the harness in a new project, when asked to "init the harness",
  "set up the harness", "create HARNESS.md", "onboard this repo to the harness", or when another
  harness skill reports that docs/HARNESS.md is missing. Idempotent: re-running fills gaps without
  clobbering bindings already set.
---

# harness:init — generate the binding layer

Inverse of every other harness skill: they *read* `docs/HARNESS.md`; this *writes* it. Until it
exists + is correct, the rest of the pipeline is inert.

> **Inputs (bundled):** `templates/HARNESS.md` (schema to fill), `templates/harness-runs.SCHEMA.md`
> (run-log contract). Behavioral-verify model: `docs/runtime-verification-binding.md`. Read before generating.

**Principle: detect → confirm → ask only what can't be inferred.** Never interrogate for what the repo
already states. One question at a time (tight question, indexed options, recommendation + escape hatch).
Never block on optional capabilities.

## Steps

### 0. Idempotency
`docs/HARNESS.md` exists → read it; this run = gap-fill + update. Keep set bindings; propose only for
missing/placeholder rows. Never overwrite a set binding without confirming.

### 1. Scan (detect — don't ask yet), parallel where possible
- **Stack:** `Package.swift`→Swift · `package.json`(+`nx.json`/`turbo.json`/workspaces)→Node · `Cargo.toml`→Rust · `go.mod`→Go · `pyproject.toml`/`setup.py`→Python · else ask.
- **Sensors:** infer format/lint/test/build from configs + scripts (`.swiftlint.yml`, `.swift-format`, eslint/biome, `package.json` scripts, `Makefile`, `justfile`, CI).
- **Paths:** sources dir, tests dir, rules dir, existing run/launch script (`run.sh`, `dev`).
- **OpenSpec (hard dep):** `openspec/` + `openspec/config.yaml` present? Absent → flag.
- **PR host:** `git remote -v` (GitHub via `gh`) — needed by ship/finish + run-log backfill.
- **Task tracker:** look for hints (available `mcp__*`, Jira/Linear config) — expect to ask.
- **Optional capabilities:** session-chapter tool, behavioral driver (computer-use / chrome MCP) — note availability.

Summarize detections before asking anything.

### 2. Confirm detected sensors
Present inferred commands + order; ask to confirm/correct (recommend + escape hatch).

### 3. Interview the rest (one question per turn; skip what the scan answered)
1. Task tracker — backend + 5 verbs (`resolve`/`start`/`link`/`review`/`done`) + id prefix.
2. Per-stage hooks (optional) — move/status/label at refined/building/verified/PR-open/merged.
3. Conventions — branch prefixes, commit contract, version source, PR merge style.
4. Runtime verification — applies-when / skip-when / launch (or a project launch-verify script for multi-process) / readiness / driver / liveness / log source / expected (model: `docs/runtime-verification-binding.md`).
5. Finish merge mode — two-merge (default) or single-merge.
6. Observability — run-log path (default `.claude/harness/runs.jsonl`), review cadence, extra fields.
7. Build state — progress-file path (default under change-state dir).
8. Session chapters — tool name or none.
9. OpenSpec — schema, changes/specs paths, expected CLI version.

### 4. Write `docs/HARNESS.md`
Fill template with confirmed + answered values; delete N/A rows; **keep section headings**. Preserve
pre-existing bindings. OpenSpec absent → write the section + flag the missing hard dep.

### 5. Scaffolding (confirm before editing files)
- **Context docs.** Scaffold minimal stubs for missing project-knowledge docs — `docs/PRODUCT.md`,
  `ARCHITECTURE.md`, `docs/RELIABILITY.md`, `docs/SECURITY.md`, `docs/QUALITY_SCORE.md` — record paths
  in HARNESS.md › Context docs. Stubs minimal (operator fleshes out). **`QUALITY_SCORE.md` seeds the
  standard judge categories** (correctness / convention / simplification / efficiency / altitude) to
  match the run-log schema. Never overwrite an existing doc — link it.
- Git-ignore the run-log path, app runtime-log path, build progress dir (append to `.gitignore`).
- Optional pre-push gate stub if wanted.

### 6. Report
Bindings written; rows left as placeholders the operator must fill; missing hard deps (OpenSpec /
tracker). Point to the next skill (`harness:refine` or `harness:build`).

## Don't
- Don't invent commands — uninferred + operator-unknown → marked placeholder, say so.
- Don't add a machine-parsed config format — the agent reads this file; prose tables are correct.
- Don't modify source — only `docs/HARNESS.md`, context-doc stubs, and (with confirmation) `.gitignore` / a hook stub.
- Don't treat a missing optional capability as an error — note + continue.
