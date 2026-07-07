---
name: harness:retro
description: >-
  Retrospective on the harness's own runs — reads the accumulated run-log, aggregates metrics grouped by
  skill_version, surfaces recurring friction, and proposes concrete improvements to the harness itself.
  Proposes — never auto-applies. Use when asked to "run a harness retro", "review the harness", "improve
  the harness", "look at harness data", or on a periodic cadence (after N build runs). Aggregates the
  run-log (JSONL), backfills reality fields from the PR host + task tracker, and proposes specific edits
  to the skills or openspec/config.yaml. Triggers on "/harness:retro", "harness retro", "harness
  retrospective", "review the harness", "improve the harness". (Not code review of a change — that's
  `harness:review-change`.)
metadata:
  author: acatl
  version: "1.0.0" # x-release-please-version
---

# harness:retro — close the loop from data to a better harness

`harness:build` logs each run to the run-log (JSONL). This skill reads it and turns it into **concrete
harness improvements**. The log matters only because this reads it — a log nobody aggregates is theater.

> **Bindings.** Run-log path + schema from `docs/HARNESS.md › Observability` (schema:
> `references/harness-runs.SCHEMA.md`). Reality backfill via the PR host + task tracker (HARNESS.md).

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:retro` + any target this run has (e.g. ` · <N> runs`, ` · since v<x>`).
- **end:** `■ harness:retro v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**This skill proposes; it does not auto-apply.** Skill/config edits change how every future run behaves —
surface them for human approval.

## Steps

### 1. Load
- Read the run-log (one JSON object per line) + the schema.
- Fewer than ~3 rows → say so (trends aren't meaningful yet); report the raw rows and stop.

### 2. Backfill reality (`[E]` fields)
For rows where `pr_url`/`merged`/`ci_passed`/`review_comments` are `null` but the change shipped:
- Find the PR (by branch / change name on the PR host) and fill `pr_url`, `merged`, `ci_passed`,
  `review_comments`. Optionally confirm the task state via the tracker.
- Rewrite the affected lines in place (same field order; keep it valid JSONL).
- Throttle PR-host calls per environment (`sleep` in loops; honor `Retry-After`).
- (`harness:finish` backfills at close-time; this catches rows it missed.)

### 3. Aggregate (deterministic first)
- **Autonomy:** % `clean_autonomous`, total `human_interventions`, which `intervention_stages` recur.
- **Reliability:** % all-green first pass; mean `iterations_to_green`; `fix_caused_regression` rate.
- **Failure modes:** tally `sensor_failures[].error_class` and `judge_findings[].category` — what keeps
  recurring is the next thing to fix in the harness.
- **Spec health:** any `config_context_bytes == 0` (config silently broke — urgent); mean `verify_gaps`
  **over full runs only** (`spec_mode=full` — spec-less rows are `null` by design; don't average them in);
  `spec_reworks` rate.
- **Spec-mode & triage:** split every metric by `spec_mode` (full vs spec-less — a spec-less run *should*
  show `verify_gaps=null`, that's not a regression). Track the spec-less **escalation rate** (spec-less
  runs that flipped to full mid-build): high ⇒ the spec-worthiness **triage lenses** (`triage-lenses.md`,
  bundled in `harness:build` + `harness:refine` — edit them there) are under-catching at triage time —
  feed it back to sharpen the disqualifier lenses.
- **Scope intake:** `scope_stops` rate (high ⇒ tasks mis-scoped upstream, not a harness bug).
- **Reality (post-backfill):** % `merged`, % `ci_passed`, mean `review_comments` — does the harness ship
  changes that hold up, not just green ones?
- **Attribution:** group all of the above by `skill_version` (and `model`). Did a skill edit move the
  numbers? Without the before/after split the metrics are noise.

### 4. Propose improvements
For each **recurring** friction pattern (not one-offs):
- A repeated `sensor_failures.error_class` / `judge_findings.category` ⇒ encode the fix as a rule in
  `openspec/config.yaml` (so specs/impl avoid it up front) or a note in the relevant skill.
- A recurring `intervention_stage` ⇒ make that stage more autonomous or document the decision.
- `config_context_bytes == 0` ⇒ the YAML-parse-swallow gotcha; fix `config.yaml`, re-verify.
- **Cite the exact rows/metric** behind each proposal. No proposal without data.
- Respect "less is more" — one sharp rule over broad scaffolding. Don't propose a metrics stack or new
  tooling; the win is tightening the existing runbook/config.

### 5. Output
- Short report: the aggregates (grouped by `skill_version`), the top 1–3 friction patterns, the proposed
  edits with their justifying rows.
- Ask which proposals to apply — as a walk-me-through fork card (`references/walk-me-through.md`), one per
  turn, reply by letter; never `AskUserQuestion`. Apply only the approved ones; if a proposal edits a skill,
  note that the next run's `skill_version` changes so the effect is measurable.

## Don't
- **Propose, don't auto-apply** — these edits change every future run.
- **Data-backed only** — every proposal cites the rows/metric behind it; no vibes.
- **Don't grow the system** — the deliverable is a tighter runbook/config, not new infrastructure.
