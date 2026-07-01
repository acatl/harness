---
name: harness:status
description: >-
  Report where a change is in the harness pipeline and what to run next — derived LIVE from real state
  (task tracker, openspec status, the change's harness/ artifacts, git/PR), so it's accurate even in a
  fresh session or for a teammate who wasn't there. Use when the operator asks "what's next", "where am
  I", "what do I run next", "status of <change>", "is this ready to ship / finish", or is resuming after
  a break or context loss. With no argument, lists every in-flight change + its next step; with a change
  name, details that one. Read-only — never mutates anything. Triggers on "/harness:status", "harness
  status", "what's the next step", "where are we on <change>", "what do I run now".
metadata:
  author: acatl
  version: "0.1.0"
---

# harness:status — where am I, what's next (derived, never persisted)

Answers "what's the next step?" by **reconstructing the pipeline position from ground truth** — not a
stored pointer (those drift). Reads the tracker, `openspec status`, the change's `harness/` artifacts, and
git/PR; computes the position; renders the trail + the one runnable next step. Works cold.

> **Bindings.** Resolve from `docs/HARNESS.md`: change-state dir, task-tracker verbs (`resolve`), PR host,
> Finish merge mode. Never hardcode.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:status` followed by any target (e.g. ` · <change>`).
- **end:** `■ harness:status v<hash8> → <outcome>` — one-line result (e.g. `web-core @ ship` / `3 changes in flight`). `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**Read-only.** Never writes, commits, moves a tracker column, opens/merges a PR, or touches an artifact.
It only reports. Any action is the operator's next move.

## Steps

### 1. Resolve scope
- **Arg = a change name** → detail that change (Steps 2–4).
- **No arg** → `openspec list --json` (open/non-archived). **0** → nothing in flight; suggest starting
  (`/harness:refine <intent>` or `/harness:build <task>`); stop. **1** → detail it. **N** → one-line
  position per change (Step 4 compact), then offer to detail one (no fork needed — just list).
- Also infer from the current branch when it maps to a change (same resolution as `harness:build` Step 0).

### 2. Gather evidence (READ-ONLY)
Per change, collect — never write:
- `openspec status --change "<name>" --json` → artifacts authored / apply-ready / archived.
- `ls <change-state-dir>/` → which `harness/` artifacts exist (`recon.md`, `architecture-review.md`,
  `design-review.md`, `progress.md`, `pr-body.md`, `decisions.md`).
- **git/PR** (PR host, e.g. `gh pr view` / `gh pr list --head <branch>`) → branch pushed? PR open? merged?
- **Tracker** (`resolve` verb) → the linked task's column/status.

### 3. Derive position (evidence → stage)
Mark a stage `✓` only on real evidence (honest, not assumed):

| Stage | `✓` when… |
|-------|-----------|
| refine | linked ticket well-formed (Story + GWT AC) / tracker off "todo" |
| spec | `proposal.md` + `design.md` + `specs/` authored (`openspec status`) |
| review | `<change-state-dir>/architecture-review.md` **and** `design-review.md` exist |
| implement | tasks checked / `progress.md` complete / group commits present |
| verify | `<change-state-dir>/pr-body.md` exists (build reached verified-not-shipped) |
| ship | PR open on the PR host |
| address comments | PR open **with unresolved review threads** |
| finish | change archived (`openspec/changes/archive/…`) **and** tracker = done |

The **first not-`✓` stage is `▸ here`**; the stage after it is `◦ next`. A gap (a later stage `✓` but an
earlier one not) → flag it ("PR open but no review artifacts — reviews may have been skipped"), don't hide it.

### 4. Render (pipeline trail + evidence + one next step)
Per `references/pipeline-map.md`: the trail with all `✓`, the `▸ here`, and **one** `◦ next`. Add a short
evidence line per `✓` so the operator trusts it. End with the **single immediately-runnable next step**
(the one-runnable-command rule: a human-action step — "review + merge the PR", "test it yourself" — shows
the *action*, not a `/harness:` command; downstream stays a trail label).

```text
Change: <name>  (<task-id>)
✓ refine     — <evidence>
✓ spec       — <evidence>
✓ review     — <evidence>
▸ <stage>    — you are here: <why it's the current point>
◦ next: <the one runnable command, OR the human action if gated behind one>
```
Compact form (N changes, no arg): one line each — `<name> · ▸ <stage> · next: <…>`.

Edge cases: nothing in flight → suggest refine/build. Everything done (archived + merged) → "shipped +
finished — nothing to do." Can't resolve the change → say what's ambiguous, list candidates.

## Don't
- **Read-only — never mutate.** No writes, commits, tracker moves, PR open/merge, artifact edits. Report only.
- **Derive, never persist.** Compute the position from live evidence every time; never write or trust a
  stored `stage:` pointer (it drifts from reality).
- **One next step.** Show only the immediately-runnable command; a step gated behind a human action shows
  the action, not a premature command (per `references/pipeline-map.md`).
- **Honest gaps.** A later stage done with an earlier one missing → surface the anomaly, don't paper over it.
