---
name: harness:init
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

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:init v<hash8>` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`). `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars.
- **end:** `■ harness:init → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable.

> **Inputs (bundled):** `templates/HARNESS.md` (schema to fill), `templates/harness-runs.SCHEMA.md`
> (run-log contract). Behavioral-verify model: `docs/runtime-verification-binding.md`. Read before generating.

**Principle: detect → confirm → ask only what can't be inferred.** Never interrogate for what the repo
already states. One question at a time (tight question, indexed options, recommendation + escape hatch).
Never block on optional capabilities.

## Steps

### 0. Idempotency
`docs/HARNESS.md` exists → read it; this run = gap-fill + update. Keep set bindings; propose only for
missing/placeholder rows. Never overwrite a set binding without confirming.

**Two-phase when author-required context docs are missing (Step 5 gate):**
- **Pass 1** — generate `QUALITY_SCORE.md` (canonical rubric) + drop templates for any unauthored gated docs (ARCHITECTURE / PRODUCT / RELIABILITY / SECURITY), then **STOP**: do NOT write `docs/HARNESS.md`, scaffold openspec, or seed `openspec/config.yaml` in a stopped pass. Print the files needing authorship + paths.
- **Pass 2 (re-run after the operator authors them)** — a doc is authored when it exists and the `<!-- HARNESS TEMPLATE` marker line is gone. All four authored → proceed to HARNESS.md + openspec scaffold + config seed.

### 1. Scan (detect — don't ask yet), parallel where possible
- **Stack:** `Package.swift`→Swift · `package.json`(+`nx.json`/`turbo.json`/workspaces)→Node · `Cargo.toml`→Rust · `go.mod`→Go · `pyproject.toml`/`setup.py`→Python · else ask.
- **Sensors:** infer format/lint/test/build from configs + scripts (`.swiftlint.yml`, `.swift-format`, eslint/biome, `package.json` scripts, `Makefile`, `justfile`, CI).
- **Paths:** sources dir, tests dir, rules dir, existing run/launch script (`run.sh`, `dev`).
- **OpenSpec (hard dependency):** `command -v openspec`. **Missing → STOP:** tell the operator OpenSpec must be installed (hard dep), **wait** for them to confirm it's installed, then re-check. Never proceed without the CLI. Present but `openspec/` dir absent → scaffold in Step 5 via `openspec init --tools claude`.
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
pre-existing bindings. CLI confirmed in Step 1; `openspec/` dir absent → write the section noting it'll be scaffolded in Step 5 (`openspec init --tools claude`).
- **Never write absolute machine paths** (e.g. `/Users/.../harness-pipeline/...`) into the generated
  HARNESS.md — reference the harness pipeline's own docs (the runtime-verification binding contract, the
  run-log schema) generically. The consuming HARNESS.md must be self-contained + portable across
  machines/teammates.

### 5. Scaffolding (confirm before editing files)
- **Context docs — tiered. Two tiers; never fabricate load-bearing project knowledge.**
  - **QUALITY_SCORE.md (init GENERATES — canonical):** `docs/QUALITY_SCORE.md` absent → write it in full from the bundled canonical rubric template (`templates/context-docs/QUALITY_SCORE.md`). Real, ready file — categories (correctness / convention / simplification / efficiency / altitude) MUST match the run-log schema. Operator may add project-specific examples later. Not a stop.
  - **Author-required docs (init TEMPLATES + HARD-STOPS — never fabricated):** `ARCHITECTURE.md`, `docs/PRODUCT.md`, `docs/RELIABILITY.md`, `docs/SECURITY.md`. A doc is **unauthored** if absent OR still contains the line `<!-- HARNESS TEMPLATE` (the template marker). For each unauthored one, copy its bundled template (`templates/context-docs/<NAME>.md`) to the project path. Never invent their content — they are load-bearing project knowledge (architecture/design reviews + refine's scope-guard ground on them; a fabricated one makes reviews confidently wrong).
  - **Hard gate + resume:** ANY of the four unauthored after templating → **STOP this pass.** Print the list of files needing authorship + their paths; tell the operator: author them (remove the `<!-- HARNESS TEMPLATE` marker line when done), then **re-run `/harness:init`** to continue. Do NOT write `docs/HARNESS.md`, seed `openspec/config.yaml`, or scaffold openspec in a stopped pass. On re-run, a doc is authored when it exists and the marker line is gone; all four authored → proceed.
  - Record all five paths in HARNESS.md › Context docs. Never overwrite an authored doc — link it.
- **Scaffold OpenSpec (after the gate).** Reached only once the CLI is confirmed (Step 1) and all four author-required docs are authored. `openspec/` absent → run `openspec init --tools claude` (announce it first), then seed config (next bullet).
- **Seed the OpenSpec feedforward.** `openspec/config.yaml` `context:` empty → author it from the Context
  docs: distill the product charter/north-star + what-it-is / is-NOT (non-goals) + tech constraints + key
  runtime invariants into the `context:` block, and add per-artifact `rules:` (proposal: enforce
  non-goals/scope guard; design: dependency + architecture invariants, no speculative abstractions; tasks:
  the final task is the sensor gate from HARNESS.md, pure-logic changes ship with tests, non-unit-tested
  surfaces get a runtime-verify task). Schema stays `spec-driven`. Else spec generation is blind
  (`config_context_bytes=0`).
- Git-ignore the run-log path, app runtime-log path, build progress dir (append to `.gitignore`).
- Optional pre-push gate stub if wanted.

### 6. Report
Bindings written; rows left as placeholders the operator must fill; missing hard deps (OpenSpec /
tracker). Point to the next skill (`harness:refine` or `harness:build`).

## Don't
- Never fabricate ARCHITECTURE/PRODUCT/RELIABILITY/SECURITY content — template + stop + wait for the operator. Never proceed past the gate with an unauthored (marker-present) doc.
- Don't invent commands — uninferred + operator-unknown → marked placeholder, say so.
- Don't add a machine-parsed config format — the agent reads this file; prose tables are correct.
- Don't write absolute machine paths into the generated HARNESS.md — pipeline doc refs stay generic; the consuming file must be self-contained + portable.
- Don't modify source — only `docs/HARNESS.md`, context-doc stubs, and (with confirmation) `.gitignore` / a hook stub.
- Don't treat a missing optional capability as an error — note + continue.
