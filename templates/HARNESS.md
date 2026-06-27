<!--
  HARNESS.md — TEMPLATE.
  This is the binding layer for the harness pipeline. `/harness:init` generates a filled-in copy of
  this into a consuming project's docs/HARNESS.md by scanning the project and interviewing the
  operator. You can also hand-edit it.

  RULE FOR EVERY SKILL: resolve project specifics from this file. Never hardcode a command, path, or
  convention in a skill. A skill says "run the `test` sensor declared in HARNESS.md," not "run
  `swift test`." When this file and a skill disagree, THIS FILE WINS. The agent reads this file — it
  is not machine-parsed — so prose tables are fine; keep them accurate.

  Replace every <PLACEHOLDER>. Delete rows/sections that don't apply. Keep the section headings so
  skills can find their bindings.
-->

# <PROJECT> — Harness Profile

**Stack:** <e.g. Swift / macOS app · TypeScript / web · Node / API · web+API monorepo>

---

## Sensors (deterministic gates, run in order)

Each must pass before the next. This set also defines the pre-push gate (see *Gates*).

| Sensor | Command | Notes |
|--------|---------|-------|
| `format` | `<format command>` | auto-fix first, then re-stage |
| `lint`   | `<lint command, strict>` | |
| `test`   | `<unit test command>` | <framework> |
| `build`  | `<build command>` | must always succeed; see *Runtime verification* for the launch/behavioral check |

<!-- Add project-specific sensors as needed (e.g. a vendored-asset tripwire, typecheck). Keep order meaningful. -->

- On failure: fix the cause, re-run from the top. A failure NOT caused by the change → STOP and
  surface, never patch around it.
- Skip the launch/behavioral check for pure-logic-only changes fully covered by unit tests.

## Paths

| Key | Value | Notes |
|-----|-------|-------|
| sources dir | `<path>` | |
| tests dir   | `<path>` | |
| rules dir   | `<path, e.g. .claude/rules/>` | convention files skills pre-load |
| change state dir | `<path, e.g. openspec/changes/<change>/.specd/>` | where `build` keeps its progress/resume files |
| <other load-bearing configs> | `<path>` | |

## Conventions

| Key | Value |
|-----|-------|
| task-id prefix | `<e.g. PROJ->` |
| commit contract | Conventional Commits (release automation reads subjects): `feat:`→minor, `fix:`→patch, `feat!:`/`BREAKING CHANGE:`→major, `chore/ci/docs/refactor/test/style`→no release |
| branch prefixes | `<feat- / fix- / chore-> off latest origin/main`; never commit to `main` |
| PR merge | `<squash-merge with a Conventional title>` |
| version source | `<path / tool that owns the version>` — never hardcode the version |

## Context docs (project knowledge the skills ground on)

Skills read these for product scope, the architecture/runtime/security contracts, and the review
rubric. `harness:init` scaffolds minimal stubs if absent.

| Doc | Path | Read by |
|-----|------|---------|
| product charter | `<docs/PRODUCT.md>` | `refine` (scope/non-goals), `build` (scope guard) |
| architecture | `<ARCHITECTURE.md>` | architecture review, `build` |
| reliability | `<docs/RELIABILITY.md>` | architecture/design review, `build` |
| security | `<docs/SECURITY.md>` | architecture review, `build` |
| quality score (judge rubric) | `<docs/QUALITY_SCORE.md>` | the judge in `build`, `review` |
| design references | `<docs/DESIGN.md / docs/design-docs/, or none>` | `refine`, design review |

- The judge rubric's categories (correctness / convention / simplification / efficiency / altitude)
  must match the run-log `judge_findings[].category` (see the harness run-log schema).

## Gates (local pre-push hook)

`<path to pre-push hook, or "none">` — runs the PR-blocking sensors locally before a push. Fix
locally; never bypass. Should no-op in unrelated repos (guard on a project marker file).

## Task tracker

The backend is reached through a stable **verb contract** so skills never name a specific tracker.

| Key | Value |
|-----|-------|
| backend | `<kino / jira / linear / github-issues>` |
| resolve | `<how to fetch a task's title + description + acceptance criteria; e.g. mcp__kino__get_task / Atlassian MCP getJiraIssue / acli issue view>` |
| start   | `<move to in-progress / set status>` |
| link    | `<attach the PR url + branch to the task>` |
| review  | `<move to a review state>` |
| done    | `<close / resolve>` |

### Per-stage hooks (all optional)

At each pipeline stage the harness can perform a tracker action — move a column, set a status, add a
label. Declare only what the project wants; leave blank to do nothing at that stage.

| Stage | Action |
|-------|--------|
| refined (task well-formed) | `<e.g. label: refined>` |
| building (build started) | `<e.g. move → In Progress>` |
| verified (local, not shipped) | `<e.g. label: needs-test>` |
| PR open | `<e.g. move → In Review · set pullRequestUrl>` |
| merged | `<e.g. move → Done>` |

## Runtime verification (behavioral-verify binding)

How `build` exercises the running system and judges whether the change actually works. Contract +
rationale: see the harness pipeline's runtime-verification binding contract. The skill owns the 4-step contract
(bring up → exercise → observe → verdict) and signal interpretation; you declare the recipe here.

| Key | Value |
|-----|-------|
| applies-when | `<surfaces that need a launch, e.g. any view/WebView/FSEvents change; any route/endpoint change>` |
| skip-when    | `<pure-logic-only changes fully covered by unit tests>` |
| launch       | `<command(s) or a project script that brings the system up; for multi-process, point at one launch/verify script that owns the topology>` |
| readiness    | `<how to know each process is up before exercising>` |
| driver       | `<how to exercise: computer-use MCP / chrome-devtools MCP / HTTP client / Claude Code preview>` |
| liveness     | `<how to detect alive vs crashed — always-on signal, no UI access needed>` |
| log source   | `<where runtime logs go + what an error looks like>` |
| expected     | `<events/observations that SHOULD appear when exercised>` |

- **Liveness is never best-effort** — it needs no UI access, so it runs even when the behavioral
  driver is unavailable. A green build + clean log is NOT proof the system stayed up.

## Build state

| Key | Value |
|-----|-------|
| progress file | `<path, e.g. <change state dir>/progress.md>` — Markdown; `build` records which tasks are done + where it left off so it can resume across sessions and across gated/yolo |

## Finish (merge mode)

| Key | Value |
|-----|-------|
| merge mode | `<two-merge \| single-merge>` |
| two-merge  | feature PR is merged by a human, then `finish` opens a chore PR for sync+archive (second merge) |
| single-merge | `finish` folds sync+archive into one landing — no second PR |

- The merge-gate is **confirmable**: if `finish` can't confirm the feature landed, it ASKS
  (already merged / tested in prod / single-merge flow?) rather than hard-stopping.

## Observability (harness self-improvement)

`harness:build` appends one row per run to the run-log; `harness:review` aggregates it and proposes
harness improvements. Schema: the harness run-log schema.

| Key | Value |
|-----|-------|
| run-log path | `<path, e.g. .claude/harness/runs.jsonl>` — JSONL, git-ignored, append-only |
| review cadence | `<e.g. after N build runs / weekly>` |
| extra fields | `<optional project-specific run-log fields, or "none">` |

- Distinct from *Build state* above: that's Markdown resume state; this is JSONL cross-run telemetry.
- `harness:finish` / `harness:review` backfill the `[E]` reality fields (merged, ci_passed, …) from
  the PR host + task tracker.

## Session chapters (optional)

| Key | Value |
|-----|-------|
| tool | `<session-chapter tool if available, e.g. mcp__ccd_session__mark_chapter; else "none">` |

If absent, skills skip chapter-marking silently — never block on it.

## OpenSpec (vendor dependency)

| Key | Value |
|-----|-------|
| config | `openspec/config.yaml` — the spec feedforward (product context + per-artifact rules) |
| schema | `<e.g. spec-driven>`; artifacts: `proposal`, `design`, `specs`, `tasks` |
| changes / specs | `openspec/changes/` (active + `archive/`), `openspec/specs/` (main specs) |
| expected CLI | `<pinned/known-good openspec version>` |
