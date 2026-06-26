---
name: harness:finish
description: >-
  One-command closeout for a completed OpenSpec change: syncs the delta specs into the main specs,
  archives the change, lands that per the project's merge mode (single-merge rides the feature PR;
  two-merge opens a chore PR), then (operator-confirmed) marks the linked task done, and backfills the
  run-log's reality fields. Use when the work is verified and you want to finalize without hand-running
  sync + archive and tidying the tracker. Triggers on "/harness:finish", "finish this change", "close
  it out", "sync and archive", "wrap up the change". Never closes the task without asking; the
  merge-gate asks rather than hard-stopping when it can't confirm the change landed.
argument-hint: "[change-name]"
metadata:
  author: acatl
  version: "0.1.0"
---

# harness:finish — closeout (sync + archive + land + close)

Closeout orchestrator. Chains the vendor `openspec-sync-specs` then `openspec-archive-change`, lands
them per the merge mode, offers to mark the task done, and backfills the run-log. Does **not** merge
the feature PR.

> **Bindings.** Resolve from `docs/HARNESS.md`: change-state dir, task-tracker verbs (`done`) +
> `merged` stage hook, **Finish › merge mode** (`single-merge` | `two-merge`), run-log path, PR host.

The done-move is **operator-gated by design** — review comments can still land after sync, so the
operator decides whether the task is actually done. Sync + archive proceed without a confirm
(invocation is consent to finalize); only the task close asks.

## Steps

1. **Resolve the change.** Passed arg if present; else infer from branch / conversation (same
   resolution as `harness:build` Step 0); else `openspec list --json` + `AskUserQuestion`. Announce
   `Finishing change: <name>`. Read the merge mode from HARNESS.md.

2. **Merge-gate (confirmable — never a hard wall).**
   - **two-merge:** confirm the feature PR merged (PR host — e.g. `gh pr view --json state,mergedAt`).
     Can't confirm → **ASK**: _"Can't confirm the feature landed — already merged / tested in prod /
     single-merge flow?"_ Proceed on confirmation; otherwise stop.
   - **single-merge:** runs against the **open feature branch/PR** (archive-before-merge — sync+archive
     ride the feature PR). Confirm an appropriate feature branch/PR exists; can't → ASK before proceeding.

3. **Sync the delta specs.** Invoke `openspec-sync-specs` (vendor) via the Skill tool with the change
   name — merges the change's delta specs into the main specs.

4. **Archive the change.** Invoke `openspec-archive-change` (vendor) with the change name — moves
   `openspec/changes/<name>` → `openspec/changes/archive/`.
   > Archive may itself offer to sync first; step 3 already synced → decline / confirm nothing's left.

5. **Land it (per merge mode).**
   - **single-merge:** commit the sync+archive onto the **feature branch** (Conventional `chore:`
     subject) and push — it rides the open PR. **No new PR.**
   - **two-merge:** create a `chore-` branch off the landed base, commit the sync+archive, and open a
     **chore PR** via `harness:ship` (Conventional `chore:` title). This is the second, final merge.

6. **Close the linked task (operator-confirmed).** Ask whether to mark the task `done` + clear any
   in-review label. On yes → task-tracker `done` verb + `merged` stage hook (HARNESS.md). On no →
   leave as-is. No-op (no prompt) if no linked task.

7. **Backfill the run-log.** Find this change's run-log row(s) (HARNESS.md › Observability) and fill
   the `[E]` reality fields from the PR host + tracker: `pr_url`, `merged`, `ci_passed`,
   `review_comments`. Rewrite the line(s) in place, valid JSONL. Throttle bulk PR-host calls per
   environment.

8. **Out.** One line: change archived · merge mode · task-close state (or "no linked task") ·
   run-log backfilled.

## Don't
- **Don't merge the feature PR** — that's the human gate (two-merge) or it rides the PR (single-merge).
- **Don't archive before the feature merged in two-merge** unless the confirmable gate was answered yes.
- **Don't move the task to `done` without the confirm.**
- **Don't re-implement sync or archive** — invoke the vendor skills.
