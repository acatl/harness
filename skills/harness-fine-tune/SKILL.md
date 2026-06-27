---
name: harness:fine-tune
description: >-
  Iterative polishing loop for refining a change after it's implemented — typically after harness:build
  reaches verified-not-shipped and you're testing it. Use when the user says "let's fine-tune", "polish
  this", "fix the change", "iterate on this", or wants to refine something already working. Runs a
  fix → test → approve → sync-and-commit loop with topic-drift detection, accumulation nudges, and a
  session-start git cleanliness gate. It is a STICKY mode: it re-anchors every turn, survives nested
  skills, and exits only on an explicit "exit"/confirmed-yes. Commits locally; hands off to harness:ship
  for push + PR.
metadata:
  author: acatl
  version: "0.1.0"
---

# harness:fine-tune — sticky polish loop

Lightweight session state machine for iterative polishing after a change is implemented.

> **Bindings.** Test step uses the `format`/`lint`/`test`/`typecheck` **sensors** (HARNESS.md ›
> Sensors). Doc-sync targets the change-state dir. Push + PR = `harness:ship`.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:fine-tune v<hash8>` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`). `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars.
- **end:** `■ harness:fine-tune → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable.

## Sticky mode (load-bearing)
Fine-tune is a **persistent mode** — like OpenSpec Explore's "you must exit first." It does NOT
silently end:
- **Re-anchor every turn:** restate "Still fine-tuning `<topic>`."
- **Nested skills are allowed but NON-terminal** — run them, then **resume the loop**. A nested skill
  completing is NOT an exit (this is the bug to prevent).
- **Exit only on an explicit signal:** the operator says "exit" / "done" / "stop fine-tuning", **or**
  you ask "Exit fine-tune?" and they confirm.
- **Marker:** drop `<change-state-dir>/fine-tune-active.md` (topic + status) at start so the mode
  survives nested skills + context loss; clear it on exit. On (re)entry, if the marker exists, resume
  its topic.

## Session-start gate (once per session)
Before the first pass, `git status --porcelain`. Uncommitted changes → stop: "commit or stash first — I
need a clean baseline." Once the operator says they committed, **re-verify** with `git status
--porcelain` before proceeding. Don't trust — check.

## The loop
### 1. Implement
Make exactly what the operator asked. If the request is significantly larger than prior passes
(multi-file restructure, new abstraction) AND there's unsynced work from earlier passes → pause first:
"This is bigger. You have unsynced work — sync & commit that first so this lands as its own clean unit?"
Wait for the answer before implementing.
### 2. Test
Run the affected sensors (HARNESS.md). If tests need updating because of the change, update them now —
don't leave red and hand back.
### 3. Ask for approval
Brief summary of what changed → "Does this look good?" Wait. Don't proceed until yes. (These asks are bare
yes/no / open prompts — keep them one-line. Any ≥2-option choice → a walk-me-through fork card,
`references/walk-me-through.md`, reply by letter; never `AskUserQuestion`.)
### 4. On approval
a. **Verify clean** — sensors green; fix anything red first.
b. **Ask to sync & commit:** "Sync docs and commit?" yes → c; no → d (track that unsynced passes are accumulating).
c. **Sync docs, then commit:** identify change-scoped docs (Doc-Sync Scope below); update them to
   reflect **all unsynced changes since the last commit** (not just this pass); commit with the
   Conventional type matching what was done; reset the unsynced-pass counter.
d. **Ask what's next:** "What do you want to fine-tune next?" Wait. Done → exit (clear the marker).

## Accumulation nudge
Track approved passes without a sync-commit. After 4–5 (related or not), nudge: "You've got N unsynced
passes — sync & commit before continuing? Keeps history readable." (A. yes / B. keep going). Separate
from drift.

## Topic-drift detection
Track the current topic (component/page/concern), set from the first request. Interrupt **before
implementing** when a new request is clearly about a different topic: "This looks like a shift from
`<current>` to `<new>` — sync & commit the current work first?" (A. yes, then ask for a full
description of the new topic before implementing; B. bundle, topic expands to include both). After a B,
drift detection stays active for genuinely new topics.

## Doc-Sync Scope
Branch-scoped only — never global docs, main specs, or anything not derived from the current change.
Find: the active change dir matching the branch (`<change-state-dir>`) → update its task files/notes;
other in-progress branch docs referencing the area; unclear if branch-scoped → ask before touching. No
change-scoped docs → skip the doc step, go straight to commit.

## Handoff
Fine-tune commits **locally**. When the operator is ready to ship, hand off to **`harness:ship`** (push
+ PR). It is **not** a substitute for the PR/review cycle, nor for the final `harness:finish` (main-spec
sync + archive).

## Don't
- **Don't exit on a nested skill completing** — resume the loop.
- **Don't exit** without an explicit "exit" / confirmed-yes.
- Don't leave failing tests and hand back.
- Don't touch global/main-spec docs — branch-scoped only.
- **Don't push or open a PR** — that's `harness:ship`.
