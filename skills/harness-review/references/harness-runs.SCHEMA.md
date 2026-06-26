# Harness run-log schema (TEMPLATE)

`<run-log path>` (e.g. `.claude/harness/runs.jsonl`) — one JSON object per line, appended by
`harness:build` as its final step. It exists so the harness can be **reviewed and improved from
data**, not memory (`harness:review` aggregates it).

**Storage:** git-ignored (local-only telemetry) so it stays out of PR diffs. Lost on a fresh clone —
acceptable for a solo/local workflow; snapshot manually if cross-machine durability is needed.

## Principle

The harness is an LLM-driven runbook, so agent self-reported fields can be optimistic
(self-praising-agent problem). **Prefer deterministic fields** harvested from real command output;
treat inferred fields as secondary. The signal that improves the harness is **friction** (failures,
iterations, judge catches, human stops) — not happy-path runs.

Tags: **[D]** deterministic (command output / git) · **[I]** inferred (agent judgement) · **[E]**
enriched later by `harness:finish` / `harness:review` (null at write time). Write `null` for
unknown/N-A — never omit a field (keeps the JSONL columnar for `jq`).

## Core fields (stack-agnostic)

| field | tag | meaning |
|-------|-----|---------|
| `ts` | D | ISO-8601 UTC at run completion (`date -u +%FT%TZ`) |
| `task` | D | task-tracker id (prefix per HARNESS.md) |
| `change` | D | OpenSpec change name |
| `skill_version` | D | **keystone** — `git hash-object .claude/skills/harness-build/SKILL.md` (abbreviated). Content hash of the exact skill that ran; attributes metric shifts to skill edits |
| `model` | D | model id running the loop |
| `mode` | D | `gated` \| `yolo` |
| `diff` | D | `{files, added, removed}` from `git diff --stat` of the impl |
| `config_context_bytes` | D | injected OpenSpec `context` byte count (`openspec instructions … --json`). **Tripwire:** `0` ⇒ `openspec/config.yaml` silently broke |
| `sensors` | D | map keyed by the project's sensor names (from HARNESS.md › Sensors), each `pass`\|`fail`\|`null` |
| `sensor_failures` | D | array of `{sensor, error_class}` across all attempts |
| `iterations_to_green` | D | sensor re-run cycles before all green (0 = first-pass clean) |
| `fix_caused_regression` | D | bool: an applied judge fix broke a sensor |
| `verify_gaps` | D | spec-vs-impl mismatches found at the openspec-verify step |
| `judge_findings` | I | array of `{summary, category, disposition}`; categories per the project review rubric; disposition ∈ applied/refuted/design-stop |
| `scope_stops` | D | count: out-of-scope guard fired (reason is project-defined) |
| `human_interventions` | D | times the loop stopped for human input |
| `clean_autonomous` | D | bool: reached the verified stop with zero human input |
| `intervention_stages` | I | which stages needed a human |
| `behavioral_check` | D | `ran` \| `skipped:<reason>` \| `n/a:pure-logic` (the runtime-verification launch) |
| `runtime_signal` | D | `{errors, warnings}` from the runtime log while exercising, or `null` if no launch. An `error`-level line is a runtime failure even on a green build |
| `spec_reworks` | I | artifacts regenerated mid-run |
| `duration_sec` | D | total wall-clock (trend only) |
| `tokens` | I | output tokens if known, else `null` |
| `outcome` | D | `verified-not-shipped` \| `stopped-needs-human` \| `discarded` |
| `pr_url` | E | filled by `harness:finish` / `harness:review` from `ship`/GH |
| `merged` | E | bool, backfilled from GH |
| `ci_passed` | E | bool, backfilled from GH |
| `review_comments` | E | count, backfilled from GH — a clean run that ships a bug is still a bad run |

## Project-specific fields (optional)

Projects may declare extra fields in HARNESS.md › Observability and emit them here — e.g. a
vendored-asset tripwire for web projects. Keep them tagged [D]/[I]/[E]. Don't bake project-specifics
into the core above; `harness:review` tallies whatever fields are present.
