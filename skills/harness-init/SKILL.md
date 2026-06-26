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

This skill is the **inverse of every other harness skill**. They *read* `docs/HARNESS.md`; this one
*writes* it. Until a correct `docs/HARNESS.md` exists, the rest of the pipeline is inert.

> **Inputs it works from (bundled with the harness):** `templates/HARNESS.md` (the binding schema to
> fill) and `templates/harness-runs.SCHEMA.md` (the run-log contract). The behavioral-verification
> model is `docs/runtime-verification-binding.md`. Read these before generating.

**Governing principle: detect first, confirm, then ask only what can't be inferred.** Never
interrogate the operator blindly for something the repo already tells you. Ask **one question at a
time** (walk-me-through style: tight question, indexed options where useful, a recommendation + an
escape hatch). Never block on optional capabilities.

---

## Steps

### 0. Idempotency check
- If `docs/HARNESS.md` already exists, read it. Treat this run as **gap-fill + update**: keep every
  binding already set; only propose values for missing or placeholder rows. **Never overwrite a
  filled binding without confirming.**

### 1. Scan the project (detect — don't ask yet)
Run read-only detection, in parallel where possible:
- **Stack:** `Package.swift` → Swift/SwiftPM · `package.json` (+ `nx.json`/`turbo.json`/workspaces) →
  Node/web (mono)repo · `Cargo.toml` → Rust · `go.mod` → Go · `pyproject.toml`/`setup.py` → Python ·
  else ask.
- **Sensors:** infer `format`/`lint`/`test`/`build` from config + scripts (`.swiftlint.yml`,
  `.swift-format`, eslint/biome config, `package.json` scripts, `Makefile`, `justfile`, CI workflows).
- **Paths:** sources dir, tests dir, rules dir (e.g. `.claude/rules/`), any existing run/launch
  script (`run.sh`, `dev` script).
- **OpenSpec (hard dep):** `openspec/` + `openspec/config.yaml` present? If absent, flag it — the
  pipeline requires OpenSpec.
- **VCS / PR host:** `git remote -v` (GitHub via `gh`) — needed by `ship`/`finish` and run-log backfill.
- **Task tracker:** look for hints (available `mcp__*` tools, a Jira/Linear config) but expect to ask.
- **Optional capabilities:** session-chapter tool, behavioral driver (computer-use / chrome MCP) —
  note availability; never require them.

**Summarize what was detected** before asking anything.

### 2. Confirm detected sensors
Present the inferred sensor commands **and their order**; ask the operator to confirm or correct.
Recommend-with-escape-hatch: propose the default, let them edit. Don't invent a command you couldn't
infer — leave it a placeholder and say so.

### 3. Interview for the rest (one question per turn)
Skip anything the scan already answered. Queue (drain one at a time):
1. **Task tracker** — backend + the 5 verbs (`resolve`/`start`/`link`/`review`/`done`) + id prefix.
2. **Per-stage hooks** (optional) — move/status/label at refined / building / verified / PR-open / merged.
3. **Conventions** — branch prefixes, commit contract, version source, PR merge style.
4. **Runtime verification** — applies-when / skip-when / launch (or a project launch-verify script for
   multi-process) / readiness / driver / liveness / log source / expected. Use
   `docs/runtime-verification-binding.md` as the model.
5. **Finish merge mode** — two-merge (default) or single-merge.
6. **Observability** — run-log path (default `.claude/harness/runs.jsonl`), review cadence, extra fields.
7. **Build state** — progress-file path (default under the change-state dir).
8. **Session chapters** — tool name, or none.
9. **OpenSpec** — schema, changes/specs paths, expected CLI version.

Never batch into a wall. Ask, wait, next.

### 4. Write `docs/HARNESS.md`
- Fill the template with confirmed + answered values. Delete rows that don't apply. **Keep the
  section headings** so skills can find their bindings.
- Preserve any pre-existing bindings (idempotency).
- If OpenSpec is absent, still write the section but flag the missing hard dependency.

### 5. Scaffolding (confirm before editing files)
- **Context docs.** Scaffold minimal stubs for any missing project-knowledge docs the skills ground
  on — `docs/PRODUCT.md`, `ARCHITECTURE.md`, `docs/RELIABILITY.md`, `docs/SECURITY.md`,
  `docs/QUALITY_SCORE.md` — and record their paths in HARNESS.md › Context docs. Keep stubs minimal
  (a few lines); the operator fleshes them out. **`QUALITY_SCORE.md` must seed the standard judge
  categories** (correctness / convention / simplification / efficiency / altitude) so they match the
  run-log schema. Never overwrite a doc that already exists — link it instead.
- Ensure the run-log path, the app runtime-log path, and the build progress dir are **git-ignored**
  (append to `.gitignore` — confirm first).
- Optionally create a pre-push gate stub if the project wants it (ask).

### 6. Report
- Summarize the bindings written, any rows left as placeholders the operator must fill, and any
  missing hard deps (OpenSpec / a task tracker). Point them at the next skill (`harness:refine` or
  `harness:build`).

---

## Guardrails
- **Detect before asking; confirm before overwriting; one question at a time.**
- **Never block on optional capabilities** (session chapters, behavioral driver) — note the absence
  and continue; never treat it as an error.
- **Don't invent commands.** If a sensor can't be inferred and the operator doesn't know, leave a
  clearly-marked placeholder rather than guessing.
- The output is a file the **agent** reads — prose tables are correct; do not add a machine-parsed
  config format.
- This skill only writes `docs/HARNESS.md` + (with confirmation) `.gitignore`/a hook stub. It does
  not modify source.
