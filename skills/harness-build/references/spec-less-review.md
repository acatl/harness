# Spec-less review — one lightweight lens against the plan

The review pass for a **spec-less** build. Replaces the heavy `harness:architecture` +
`harness:design` passes (which read `specs/` scenarios that a spec-less change doesn't have) with a
**single consolidated lightweight lens** grounded on the **plan** — `proposal.md` (what) +
`design.md` (how). Run **inline by `harness:build`** in spec-less mode (precedent: build's Step F
skeptical-review runs inline against QUALITY_SCORE). The heavy review skills are never invoked here
and never edited — they are what an escalation restores.

**Why still review at all:** small ≠ safe. A version bump can leak a security hole, break a consumer,
or corrupt data. The value of architectural/security scrutiny doesn't disappear because the change is
small — so spec-less keeps it, just condensed and grounded on the plan instead of a formal spec.

## When

`harness:build` Step B/C, **spec-less mode only**. Scale to the change — a one-line version bump is a
2-minute pass; a moderate fix is fuller. Full-spec mode never runs this (it runs the heavy reviews).

## Ground truth

Read before opining: `proposal.md`, `design.md`, `tasks.md`, the touched code surface (from the diff /
surface map). **No `specs/`** — the plan is the contract here.

## The consolidated lens (the high-value union)

One pass, these dimensions — the subset of the heavy reviews that catches the leaks that hurt:

| Dimension | Ask |
|-----------|-----|
| **Security & data safety** | new attack surface, exposure, auth/permission gap, secret/PII handling, destructive op without a guard? |
| **Contract & boundaries** | changes a public interface, API, schema, event, or another module's assumptions? (if yes → this is likely **spec-worthy** — see Escalation) |
| **Failure modes** | what breaks, how does it propagate, is failure isolated + recoverable? unhandled error path? |
| **Correctness** | does the plan actually do what the proposal claims? edge cases, off-by-one, wrong default for existing rows/data? |
| **Altitude & simplicity** | simplest correct approach? unjustified abstraction / speculative complexity for a small change? |

Keep it tight — this is the lightweight pass, not the 15/11-lens deep dives. Depth scales with the diff.

## Discipline (same rigor, smaller surface)

- **Severity** each finding `🔴` critical / `🟠` major / `🟡` minor.
- **Auto-apply** unambiguous, in-scope fixes (like the heavy reviews); re-verify after.
- **Stop on a genuine fork** — a design-level problem, a tradeoff, or a needed decision → surface as a
  walk-me-through fork card (`references/walk-me-through.md`), never silently patch.
- **Gate artifact:** write `<change-state-dir>/spec-less-review.md` — findings table + per-finding
  **Problem / Impact / Evidence / Resolution** (applied AND deferred) + any forks resolved. Same durable
  record shape as the heavy reviews' artifacts; always written in full.
- **Load-bearing decisions** → `decisions.md` per `references/decision-log.md` (`🤖 build` /
  `👤 human`).

## Escalation catch (the early tripwire)

This review runs **before** impl, so it's the first place a mis-triage surfaces. If the **Contract &
boundaries** dimension (or any triage disqualifier, `references/triage-lenses.md`) shows the change is
actually **spec-worthy** — it changes an observable behavior or contract — that's **not** a review
finding to patch. **Stop and recommend escalation:** author `specs/`, flip the marker `spec-less → full`,
and run the heavy reviews (build's Step E escalation, surfaced early). Better to catch it here than
mid-impl.
