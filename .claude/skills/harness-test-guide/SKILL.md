---
name: harness:test-guide
description: >-
  Interactive test companion — answers "how do I test this?" after a build or during fine-tuning by
  deriving the test scenarios for a change from artifacts that already exist (the OpenSpec spec
  scenarios, the task's acceptance criteria, the decisions log), then WALKING the operator through them
  one at a time, highest-ROI first, in plain language with how-to-drive steps and a pass/fail/skip
  prompt. Read-only and derives-only: it never invents scenarios, never writes a file, never fixes,
  never runs automated tests. Skips scenarios already pinned by an automated test and walks only the
  gap a human must check. Use when the operator asks "what do I test", "how do I test this", "guide me
  through testing", "test this change", "be my test guide", or reaches the test step inside fine-tune.
  Triggers on "/harness:test-guide", "harness test guide", "test companion", "walk me through testing",
  "what should I test".
metadata:
  author: acatl
  version: "1.2.0" # x-release-please-version
---

# harness:test-guide — what do I test, walked one at a time (derived, never persisted)

Answers "how do I test this?" by **deriving the change's test scenarios from ground truth** (spec
scenarios, AC, decisions) — never a stored file — then walking you through the **gap** (what no
automated test already covers) one scenario at a time, highest-ROI first. The fix loop is fine-tune's
job; this only surfaces what to check and how. Works cold.

> **Bindings.** Resolve from `docs/HARNESS.md`: change-state dir, the **Runtime verification** recipe
> (launch / driver / teardown — for the *how to drive each scenario* steps), the `test` sensor command
> (for the coverage check). Never hardcode.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:test-guide` + any target (e.g. ` · <change>`).
- **end:** `■ harness:test-guide v<hash8> → <outcome>` — one-line result (e.g. `web-core · 3 walked · 1 fail` / `nothing to test`). `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**Read-only.** Never writes, commits, opens/edits a file, runs a sensor that mutates, or touches an
artifact. It reads, derives, and guides. Fixing is fine-tune's move; automating is the QA agent's.

## Steps

### 1. Resolve scope
- **Arg = a change name** → guide that change (Steps 2–6).
- **No arg** → `openspec list --json` (open/non-archived). **0** → nothing in flight to test; suggest a
  build first; stop. **1** → guide it. **N** → list them, ask which one (no fork — just pick).
- Also infer from the current branch when it maps to a change (same resolution as `harness:build` Step 0).

### 2. Derive scenarios (READ-ONLY — never invent)
Fold from what already exists; every scenario must trace to a source:
- **Spec scenarios** — `<change>/specs/<cap>/spec.md` `#### Scenario:` blocks (WHEN/THEN). The spine.
  **Spec-less change** (`<change-state-dir>/spec-mode` = `spec-less`, or no `specs/`): there is no spine —
  say so ("spec-less — no spec scenarios; walking AC + decisions"), make the **AC the primary source**, and
  lean harder on `⚠️ edge` for constraint-derived cases a spec would have named.
- **Acceptance criteria** — the task's `Given/When/Then` AC (via tracker `resolve` / `proposal.md`) →
  marks the **core happy paths** (and their priority — see Step 4).
- **Edge cases** — `<change-state-dir>/decisions.md` deferrals (a `⏭️ defer` = an explicit untested
  risk) + the spec/design constraints & non-goals → `⚠️ edge` scenarios.
- A candidate that traces to nothing → a **hypothesis**: flag it as such, don't assert it as required.

### 3. Tag coverage (conservative — never over-claim)
Per scenario, classify from evidence already on disk:

| Tag | when… | walked? |
|-----|-------|---------|
| `✅ automated` | an existing automated test confidently covers it (in the diff **or** already in the suite) | **no — skip** (already netted) |
| `👁 behavioral` | behavioral-verify Observe note (`pr-body.md`/`progress.md`) saw it, **no test pins it** | **yes** (no regression net — highest automate-later value) |
| `🔲 manual` | nothing maps to it (the **default** when unsure) | **yes** |
| `⚠️ edge` | derived from a decision/constraint, unexercised | **yes** |

**Never mark `✅` on doubt** — unmatched defaults to `🔲`. Over-claiming makes the operator skip
something untested; under-claiming only re-checks something safe. Bias to `🔲`.

### 4. Order by ROI
Walk the **gap only** (drop `✅`); mention the dropped count ("9 covered by tests — skipping"). Order:
- **P0** — AC-core (the feature is broken without it) first.
- **P1/P2** — secondary paths, then deferred-behavior checks.
- **`⚠️ edge`** last.
So a product owner can do the top few and stop; deeper testers continue. Priority comes from the AC
(core = P0) and decisions (deferred = usually P1/P2).

### 5. Walk one at a time (the companion)
One scenario per turn — plain language, not raw Gherkin. For each:

```text
Test <N> of <M>  ·  <P#>  ·  <coverage tag>
<scenario title>

Drive:  <concrete steps to exercise it — bring-up + action, from the HARNESS.md Runtime-verification
        recipe (launch/driver). Reuse it; don't reinvent how to launch the app.>
Expect: <the THEN / observable outcome, in plain words>

→ pass / fail / skip?  (or: stop · jump to <n>)
```
Wait for the answer before the next. **Escape always:** the operator can stop anytime (do the P0s, quit),
or jump. Track pass/fail/skip **in-session only** (conversation memory — no file).

### 6. On fail / at the end
- **fail → make it a decision, never auto-advance.** A fail is a fine-tune finding; **stop and offer a
  terminal `👉` fork** (render per `references/walk-me-through.md`) — do NOT silently note-and-continue to
  the next test:
  - **`fix now`** → hand the finding to **`/harness:fine-tune`** (test-guide never edits — fine-tune does
    the fix, with its sensor/commit discipline). Already inside a fine-tune loop → it's just the next fix
    pass; standalone → enter fine-tune for this finding. After the fix lands, **re-walk the failed scenario**
    to confirm it now passes, then continue the walk from where it paused.
  - **`note & continue`** → record the finding (ephemeral) and advance to the next test.
  - **`stop`** → end the walk now and surface the fail list.
- **end** → print an **ephemeral summary** (not saved): `✅ N passed · ❌ N failed · ⏭️ N skipped`, then
  the **fail list** as the handoff into fine-tune. Offer an **export** (Gherkin + a priority table) only
  if the operator asks — for handing a QA dev/agent; default is no file.

## Don't (guardrails — all enforced in the Steps above)
- **Read-only — never mutate.** No writes, commits, file edits, mutating sensors, artifact touches.
- **Derive, never invent.** Untraceable scenario → hypothesis, never asserted as required.
- **Never persist.** The walk is the deliverable; a file is an opt-in `export` only.
- **Never fix or automate.** A fail hands off to `fine-tune`; generating automated tests is the QA agent's job.
- **Conservative coverage.** Never `✅` on doubt — default `🔲`; the `👁`-only scenarios are the real gap.
