---
name: harness-recon
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
  version: "0.1.0"
---

# harness:recon — prior-art recon before design

> **Project bindings.** Project-agnostic. Resolve the rules dir, sources layout, and change-state dir
> from `docs/HARNESS.md` (› Paths). Never hardcode a project's directory structure.

Reconnoiter prior art before design. Answers the one thing the proposal does not: **what already
exists that this change could reuse or extend, instead of building new?** Output is split: the
**verdicts** go into the proposal (the file the design author is guaranteed to read via OpenSpec's
`proposal` dependency); the **full evidence** goes into `<change-state-dir>/recon.md` (referenced,
optional depth). Recon does not design — it records *what exists* and *the reuse verdict*, never the HOW.

**Where it runs:** `harness:build` invokes it after `proposal.md` is authored and before `design.md`.
It also runs standalone.

**Input:** Optionally a change name. If omitted, infer from context; else run `openspec list --json`
and select via AskUserQuestion.

## Steps

1. **Resolve change.** Get the name; announce `Using change: <name>`. Run
   `openspec status --change "<name>" --json`. Require a `proposal` artifact — if absent, stop:
   "Recon needs a proposal; author it first (`openspec new` / `harness:build`)."

2. **Seam check.** If `design.md` already exists, prevention is impossible — AskUserQuestion:
   `[R] Review-only` (report missed reuse for the architecture gate) or `[S] Stop`. Otherwise proceed.
   If the proposal already contains a `harness:recon` block, this is a re-run — replace it in place.

3. **Extract capabilities.** Read `proposal.md`. List the discrete behaviors it implies, concept-level
   not file-level (e.g. "rank tasks in a project", "import rows from CSV"). Per capability record:
   label, domain nouns, verb, likely layer (persistence / service / API / component / util / CLI / MCP —
   adapt to the project's layers). If fewer than two emerge, note it and continue — an all-`build-new`
   ledger is a valid result for a novel change.

4. **Search prior art** (read-only; ≥3 capabilities → one parallel search agent each, else inline).
   Per capability:
   - Find the conventional home via the project structure and the rules dir (HARNESS.md › Paths;
     e.g. a services dir, a shared/UI package, a component-placement convention).
   - Grep that home plus the project's module index / barrel / public-API files for the nouns and verb.
   - Read each candidate's signature / doc-comment / exports — judge *purpose* overlap, not name
     similarity. Discard name-only collisions.
   - Classify overlap: `full` / `partial` / `none`.

5. **Verdict.** Assign one verdict per capability:
   - `reuse <X>` — `full` overlap, usable as-is (no change to `X`).
   - `extend <X>` — `partial` overlap, missing piece is cohesive with `X`'s responsibility. Record the
     addition.
   - `build-new` — no candidate, **or** reuse/extend would couple two independent concerns (over-DRY
     guard: duplication is sometimes correct). Name the coupling.

   Committed-use guard: a *new shared abstraction* needs ≥2 named consumers today and a stable
   interface — else `build-new` ("consolidation candidate; write the second use first").

6. **Write two artifacts.**

   a. **Full evidence** → `<change-state-dir>/recon.md` (HARNESS.md › Paths; overwrite):

   ```markdown
   # Recon ledger: <change> · against proposal.md · <N> capabilities

   | Capability | Candidate | Location | Overlap | Verdict | Reason |
   | --- | --- | --- | --- | --- | --- |
   | filter tasks by label | TaskRepository | <path> | partial | extend | add `labelId?` to the scoped query |
   | label CRUD service | (none) | — | none | build-new | no labeling domain yet |

   ## Notes

   <One block per row needing nuance — coupling rationale, committed-use deferral, a near-dup it
   blocked. Omit self-evident rows.>
   ```

   b. **Verdicts** → idempotent marked block in `proposal.md`. If the markers exist, replace between
   them; else append at end of file. Inline the candidate into the verdict cell; the full columns live
   only in (a):

   ```markdown
   <!-- harness:recon:start -->

   ## Prior-art recon (advisory)

   > Reuse verdicts for the design author. Advisory — design may override with a stated reason;
   > `harness:architecture` verifies these. Full evidence (locations, overlap, coupling notes):
   > `<change-state-dir>/recon.md`.

   | Capability | Verdict |
   | --- | --- |
   | filter tasks by label | **extend** — `TaskRepository` scoped query |
   | label CRUD service | **build-new** — no prior art |

   <!-- harness:recon:end -->
   ```

7. **Confirm.** Show the verdict tally. If any row is a judgment call (contested `extend` vs
   `build-new`, a coupling decision), AskUserQuestion: `[Y] Accept` / `[A] Adjust a verdict` /
   `[D] Discuss`. On A/D, revise and rewrite both artifacts.

## Output

```text
harness:recon complete — <name>
Verdicts → proposal.md (## Prior-art recon) · evidence → <change-state-dir>/recon.md
Verdicts: <R> reuse · <E> extend · <B> build-new

Next: author design.md (reads the proposal, incl. the verdicts)
      harness:architecture — gate; verifies design honored the verdicts
```

In review-only mode, replace the Next block with: "design already exists — feed the ledger to
`harness:architecture` as the prior-art reference."

## Guardrails

- Writes **two places only** — the idempotent marked `harness:recon` block in `proposal.md`
  (verdicts) and `<change-state-dir>/recon.md` (evidence, overwritten). Touches no other artifact and
  no code. Never edit vendor files (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
- Records existence + verdict only — **never design prose or implementation shape**. A no-stake
  searcher finds reuse the builder misses; keep that seam.
- `build-new` is first-class. Never bias toward reuse; discard name-only matches.
- Honor the over-DRY and committed-use guards — coupling independent modules to remove duplication is
  the wrong trade.
- Concept altitude only — file-level near-dupe detection is `harness:build`'s surface-map job.
- Pause on ambiguity; the ledger is advisory, design owns the final call.
