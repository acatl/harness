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

> **Inputs (bundled in this skill dir; paths below are relative to it):** `templates/HARNESS.md` (schema
> to fill), `references/harness-runs.SCHEMA.md` (run-log contract). Behavioral-verify model:
> `references/runtime-verification-binding.md`. Read before generating.

**Principle: detect → confirm → ask only what can't be inferred.** Never interrogate for what the repo
already states. One question at a time (tight question, indexed options, recommendation + escape hatch).
Never block on optional capabilities.

## Steps

### 0. Idempotency
`docs/HARNESS.md` exists → read it; this run = gap-fill + update. Keep set bindings; propose only for
missing/placeholder rows. Never overwrite a set binding without confirming.

**Multi-gate resume — any one gate stops a pass; all must clear before init writes `docs/HARNESS.md` + seeds config:**
- **OpenSpec preconditions (Step 1):** CLI not installed, OR `openspec/` not initialized (operator runs `openspec init` themselves — init never scaffolds it) → STOP, ask, wait, re-run.
- **Baseline-sensor gate (Step 2a):** any essential sensor (build/test/lint/type-check) missing → STOP, list the missing essentials, operator sets up the tooling (init does NOT install it), re-run.
- **Author-required context docs (Step 5 gate):**
  - **Pass 1** — generate `QUALITY_SCORE.md` (canonical rubric) + drop templates for any unauthored gated docs (ARCHITECTURE / PRODUCT / RELIABILITY / SECURITY), then **STOP**: do NOT write `docs/HARNESS.md` or seed `openspec/config.yaml` in a stopped pass. Print the files needing authorship + paths.
  - **Pass 2 (re-run after the operator authors them)** — a doc is authored when it exists and the `<!-- HARNESS TEMPLATE` marker line is gone. All four authored (and OpenSpec + sensor gates clear) → proceed to HARNESS.md + config seed.

### 1. Scan (detect — don't ask yet), parallel where possible
- **Stack:** `Package.swift`→Swift · `package.json`(+`nx.json`/`turbo.json`/workspaces)→Node · `Cargo.toml`→Rust · `go.mod`→Go · `pyproject.toml`/`setup.py`→Python · else ask.
- **Sensors:** infer format/lint/test/build from configs + scripts (`.swiftlint.yml`, `.swift-format`, eslint/biome, `package.json` scripts, `Makefile`, `justfile`, CI).
- **Paths:** sources dir, tests dir, rules dir, existing run/launch script (`run.sh`, `dev`).
- **OpenSpec — two hard preconditions, init never sets either up:**
  - **CLI installed:** `command -v openspec`. Missing → **STOP:** tell the operator to install OpenSpec (hard dep), **wait** for confirmation, re-check.
  - **Initialized in the project:** `openspec/` present (with `openspec/config.yaml`). Absent / no trace → **STOP:** tell the operator to initialize it themselves — `openspec init` (vendor CLI) — then re-run `/harness:init`. **init does NOT run `openspec init` or scaffold `openspec/` itself.**
- **PR host:** `git remote -v` (GitHub via `gh`) — needed by ship/finish + run-log backfill.
- **Task tracker:** look for hints (available `mcp__*`, Jira/Linear config) — expect to ask.
- **Optional capabilities:** session-chapter tool, behavioral driver (computer-use / chrome MCP) — note availability.
- **Context docs — discover by ROLE, never assume a fixed name/path.** For each role (product charter · architecture · reliability · security · quality-score · design refs), scan the repo root + `docs/` (+ any obvious docs dir) for matches by filename + keyword — e.g. architecture: `ARCHITECTURE*`/`docs/architecture*`/`ARCH*`; product: `PRODUCT*`/`CHARTER*`/`OVERVIEW*` (north-star/non-goals); reliability: `RELIABILITY*`; security: `SECURITY*`/threat-model; quality-score: `QUALITY_SCORE*`; design: `DESIGN*`/`docs/design*`/`docs/screens/`. **Filter decoys** — ignore `*.old.*` / `*.bak` / `*~` / `*.draft.*` / `archive|backup` dirs; record them separately as "found, ignored (looks non-canonical)" and NEVER auto-select one. Result: a candidate list per role.

Summarize detections before asking anything.

### 2. Confirm detected sensors
Present inferred commands + order; ask to confirm/correct (recommend + escape hatch).

### 2a. Baseline sensor assessment (gate)
After detecting sensors, assess the toolchain against the stack baseline (`references/sensor-baseline.md`). Tier each sensor:
- **Essential (HARD-STOP if missing):** build/compile gate · test runner · linter · type-check. NOTE: for compiled stacks the build gate IS the type-check (e.g. `swift build`, `cargo build`, `go build`) — don't double-count; type-check hard-stops only where it's a *separate* expected gate (e.g. `tsc`, `mypy`) and absent.
- **Recommended (WARN, proceed):** formatter · structured logging.
- **logging is warn/ASK only** — no canonical marker, can't be reliably auto-detected. Ask the operator to confirm structured logging exists (it feeds behavioral-verify's log signal); never hard-stop on it.

Detect each per the baseline matrix (config files / deps / scripts). Print a baseline report: `✅ present` / `⚠️ missing-recommended` / `⛔ missing-essential`, each ⚠️/⛔ with the concrete degradation:
- no linter → weaker pre-push gate; convention/correctness findings slip through.
- no type-check (separate-gate stacks) → a class of correctness errors uncaught.
- no structured logging → behavioral-verify loses its log signal (liveness + visual only).
- no formatter → style drift, noisy diffs.

Any ⛔ → **STOP this pass:** list the missing essentials + why each matters; state init does NOT install/configure them (operator sets them up); wait, then re-run `/harness:init` to continue. (Same two-phase stop+resume pattern as the context-doc gate.)
⚠️ only → warn + proceed.

### 3. Interview the rest (one question per turn; skip what the scan answered)
1. Task tracker — backend + 5 verbs (`resolve`/`start`/`link`/`review`/`done`) + id prefix.
2. Per-stage hooks (optional) — move/status/label at refined/building/verified/PR-open/merged.
3. Conventions — branch prefixes, commit contract, version source, PR merge style.
4. Runtime verification — applies-when / skip-when / launch (or a project launch-verify script for multi-process) / readiness / driver / liveness / log source / expected (model: `references/runtime-verification-binding.md`).
5. Finish merge mode — two-merge (default) or single-merge.
6. Observability — run-log path (default `.claude/harness/runs.jsonl`), review cadence, extra fields.
7. Build state — progress-file path (default under change-state dir).
8. Session chapters — tool name or none.
9. OpenSpec — schema, changes/specs paths, expected CLI version.

### 4. Write `docs/HARNESS.md`
Fill template with confirmed + answered values; delete N/A rows; **keep section headings**. Preserve
pre-existing bindings. OpenSpec CLI + `openspec/` init are Step-1 preconditions (both operator-provided) — by here they're satisfied; write the section against the initialized `openspec/`.
- **Never write absolute machine paths** (e.g. `/Users/.../harness-pipeline/...`) into the generated
  HARNESS.md — reference the harness pipeline's own docs (the runtime-verification binding contract, the
  run-log schema) generically. The consuming HARNESS.md must be self-contained + portable across
  machines/teammates.

### 5. Scaffolding (confirm before editing files)
- **Confirm the role→file mapping first.** Present a table: each role → its canonical candidate (or NEEDS-DECISION when a role has 0, >1, or only-decoy candidates), plus any ignored decoys listed. Ask the operator — ONE consolidated confirmation, not per-role spam — "are these the right files?" Never silently pick when ambiguous; let them correct a mapping or point at a differently-named file. Record the confirmed paths in HARNESS.md › Context docs. THEN apply the tiers below to the CONFIRMED set (a confirmed file that still contains `<!-- HARNESS TEMPLATE` counts as unauthored).
- **Context docs — tiered. Two tiers; never fabricate load-bearing project knowledge.**
  - **quality-score (init GENERATES — canonical):** quality-score role has no confirmed candidate → write `docs/QUALITY_SCORE.md` in full from the bundled canonical rubric template (`templates/context-docs/QUALITY_SCORE.md`). Real, ready file — categories (correctness / convention / simplification / efficiency / altitude) MUST match the run-log schema. Operator may add project-specific examples later. Not a stop.
  - **Author-required roles (init TEMPLATES + HARD-STOPS — never fabricated):** architecture · product charter · reliability · security. A role is **satisfied** when its confirmed file exists and is authored; **unauthored** when it has no real candidate OR the confirmed file still contains the line `<!-- HARNESS TEMPLATE` (the template marker). For each unauthored role, copy its bundled template (`templates/context-docs/<NAME>.md`) to the confirmed path (or the conventional path when the role had no candidate — e.g. the confirmed architecture doc wherever it lives, defaulting to `docs/ARCHITECTURE.md` when none exists). Never invent their content — they are load-bearing project knowledge (architecture/design reviews + refine's scope-guard ground on them; a fabricated one makes reviews confidently wrong).
  - **Hard gate + resume:** ANY of the four author-required roles unauthored after templating → **STOP this pass.** Print the list of files needing authorship + their confirmed paths; tell the operator: author them (remove the `<!-- HARNESS TEMPLATE` marker line when done), then **re-run `/harness:init`** to continue. Do NOT write `docs/HARNESS.md` or seed `openspec/config.yaml` in a stopped pass. On re-run, a role is satisfied when its confirmed file exists and the marker line is gone; all four authored → proceed.
  - Record all confirmed role→file paths in HARNESS.md › Context docs. Never overwrite an authored doc — link it.
- **Seed the OpenSpec feedforward** (only when `openspec/config.yaml` exists — it's a Step-1 precondition). If its `context:` is empty, author it against the standard OpenSpec spec-driven config shape — do NOT probe the CLI for a schema: `schema: spec-driven`; `context: |` a block distilled from the confirmed context docs (north-star + IS/IS-NOT + tech constraints + key invariants + task-tracker note); `rules:` per artifact (proposal: enforce non-goals/scope guard; design: dependency + architecture invariants, no speculative abstractions; tasks: final task is the HARNESS.md sensor gate, pure-logic ships with tests, non-unit-tested surfaces get a runtime-verify task). Preserve any non-`context` keys already present.
- Git-ignore the run-log path, app runtime-log path, build progress dir (append to `.gitignore`).
- Optional pre-push gate stub if wanted.

### 6. Report
Bindings written; rows left as placeholders the operator must fill; missing hard deps (OpenSpec /
tracker). Point to the next skill (`harness:refine` or `harness:build`).

## Don't
- Never assume a context doc's name/path — discover candidates, drop decoys (`.old`/`.bak`/`.draft`), and confirm the mapping with the operator before gating or templating. Never auto-pick among ambiguous candidates.
- Never fabricate ARCHITECTURE/PRODUCT/RELIABILITY/SECURITY content — template + stop + wait for the operator. Never proceed past the gate with an unauthored (marker-present) doc.
- Don't invent commands — uninferred + operator-unknown → marked placeholder, say so.
- Don't add a machine-parsed config format — the agent reads this file; prose tables are correct.
- Don't write absolute machine paths into the generated HARNESS.md — pipeline doc refs stay generic; the consuming file must be self-contained + portable.
- Don't modify source — only `docs/HARNESS.md`, context-doc stubs, and (with confirmation) `.gitignore` / a hook stub.
- Never auto-install or configure tooling — assess + warn/stop only; setup is the operator's job.
- **init gates, it never sets up.** Never run `openspec init` / scaffold `openspec/`, never install the CLI, never install/configure sensors, never author context docs. Each missing precondition (OpenSpec CLI, OpenSpec init, essential sensors, author-required docs) → halt + ask + wait + resume on re-run. Never probe the CLI to discover a config schema — author config against the known spec-driven shape.
- Don't treat a missing optional capability as an error — note + continue.
