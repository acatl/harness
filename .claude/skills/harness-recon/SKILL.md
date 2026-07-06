---
name: harness:recon
description: >-
  Reconnoiter the codebase for prior art a proposed change could reuse or extend before its design is
  authored. Runs between the proposal and design artifacts in the OpenSpec flow (and is called by
  harness:build after proposal.md). Extracts the capabilities a proposal implies, searches at concept
  altitude, and writes a reuse ledger (reuse / extend / build-new per capability) into the proposal so
  the design author consumes it through OpenSpec's dependency channel. Use to find what already exists
  before building, avoid duplicating a service/util/component, or "understand the landscape" before
  committing a design. Triggers on "recon", "prior art", "what already exists", "before I build this",
  "find reuse", "harness recon", "/harness:recon".
license: MIT
metadata:
  author: acatl
  version: "1.0.0" # x-release-please-version
---

# harness:recon — prior-art recon before design

Answers the one thing the proposal doesn't: **what already exists that this change could reuse or
extend instead of building new?** Records *what exists* + *the reuse verdict* — never the HOW.

> **Bindings.** Resolve rules dir, sources layout, change-state dir from `docs/HARNESS.md` (› Paths).
> Never hardcode a project's directory structure.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:recon` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:recon v<hash8> → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable. `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**Where:** `harness:build` invokes it after `proposal.md`, before `design.md`. Also runs standalone.
**Input:** optional change name; if omitted, infer from context, else `openspec list --json` + a walk-me-through fork card (`references/walk-me-through.md`).

## Steps
1. **Resolve change.** Announce `Using change: <name>`. `openspec status --change "<name>" --json`.
   No `proposal` artifact → stop: "Recon needs a proposal; author it first (`openspec new` / `harness:build`)."
2. **Seam check.** `design.md` exists → prevention impossible → a walk-me-through fork card (`references/walk-me-through.md`): `[R] Review-only` /
   `[S] Stop`. Existing `harness:recon` block in proposal → re-run, replace in place.
3. **Extract capabilities.** Read `proposal.md`. List implied behaviors, **concept-level not
   file-level** (e.g. "rank tasks in a project"). Per capability: label, domain nouns, verb, likely
   layer. <2 emerge → note + continue (all-`build-new` is valid for a novel change).
4. **Search prior art** (read-only; ≥3 capabilities → one parallel agent each, else inline). Per capability:
   - Conventional home via project structure + rules dir (HARNESS.md › Paths).
   - Grep home + module index/barrel/public-API files for nouns + verb.
   - Read candidate signature/doc/exports — judge *purpose* overlap, not name. Discard name-only collisions.
   - Classify overlap: `full` / `partial` / `none`.
5. **Verdict** per capability:
   - `reuse <X>` — `full`, usable as-is.
   - `extend <X>` — `partial`, missing piece cohesive with `X`'s responsibility; record the addition.
   - `build-new` — no candidate, **or** reuse/extend would couple independent concerns (name the coupling).
   - Committed-use guard: new shared abstraction needs ≥2 named consumers today + stable interface, else `build-new` ("write the second use first").
6. **Write two artifacts.**

   a. **Evidence** → `<change-state-dir>/recon.md` (overwrite):
   ```markdown
   # Recon ledger: <change> · against proposal.md · <N> capabilities

   | Capability | Candidate | Location | Overlap | Verdict | Reason |
   | --- | --- | --- | --- | --- | --- |
   | filter tasks by label | TaskRepository | <path> | partial | extend | add `labelId?` to the scoped query |
   | label CRUD service | (none) | — | none | build-new | no labeling domain yet |

   ## Notes
   <One block per row needing nuance — coupling rationale, committed-use deferral, a blocked near-dup. Omit self-evident rows.>
   ```

   b. **Verdicts** → idempotent marked block in `proposal.md` (replace between markers, else append):
   ```markdown
   <!-- harness:recon:start -->

   ## Prior-art recon (advisory)

   > Reuse verdicts for the design author. Advisory — design may override with a stated reason;
   > `harness:architecture` verifies these. Full evidence: `<change-state-dir>/recon.md`.

   | Capability | Verdict |
   | --- | --- |
   | filter tasks by label | **extend** — `TaskRepository` scoped query |
   | label CRUD service | **build-new** — no prior art |

   <!-- harness:recon:end -->
   ```
7. **Confirm.** Show verdict tally. Any judgment call (contested `extend` vs `build-new`, a coupling
   decision) → a walk-me-through fork card: `[Y] Accept` / `[A] Adjust` / `[D] Discuss`. On A/D, revise + rewrite both.
   A *contested* verdict that's resolved → append one line to the **decision log** (`<change-state-dir>/decisions.md`,
   per `references/decision-log.md` — `🤖 recon`, or `👤 human` if the human picked). Obvious verdicts: not logged.

## Output
```text
harness:recon complete — <name>
Verdicts → proposal.md (## Prior-art recon) · evidence → <change-state-dir>/recon.md
Verdicts: <R> reuse · <E> extend · <B> build-new

Next: author design.md (reads the proposal incl. verdicts)
      harness:architecture — gate; verifies design honored the verdicts
```
Review-only mode → replace Next with: "design already exists — feed the ledger to `harness:architecture`."

## Don't
- Writes **two places only** — the marked `harness:recon` block in `proposal.md` + `<change-state-dir>/recon.md`. No other artifact, no code. Never edit vendor files (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
- Never design prose or implementation shape — existence + verdict only (the no-stake searcher seam).
- `build-new` is first-class — never bias toward reuse; discard name-only matches.
- Concept altitude only — file-level near-dupe is `harness:build`'s surface-map job.
- Don't over-DRY — coupling independent modules to remove duplication is the wrong trade.
