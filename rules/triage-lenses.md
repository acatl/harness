# Triage lenses — is this change spec-worthy?

Shared decision aid for choosing **full** vs **spec-less** build mode. Read by two consumers:

- **`harness:refine` §5b** — *upfront*, against the well-formed ticket. Recommends a mode; carries it
  into the `Next: /harness:build` pointer. refine never creates a change or writes the marker — only
  recommends.
- **`harness:build` Step E escalation tripwire** — *mid-impl*, against the **diff**. Fires when a
  spec-less change turns out spec-worthy after all.

Same lens set, two vantage points. `harness:review` tunes it from run-log data over time.

## Principle — two independent axes, never conflate them

- **Spec-worthiness** — *does a product capability's specified behavior or contract change?* This, and
  **only** this, decides **full vs spec-less**. OpenSpec's `specs/` delta exists to record a behavior
  change; no behavior change to record ⇒ the spec buys nothing ⇒ **spec-less**.
- **Blast radius / risk** — file count, shared state, load-bearing config, an architectural invariant.
  This decides **review depth**, **not** spec-mode. A big, risky change with no behavior change is
  **spec-less with a heavy review** — *not* full. Authoring GWT spec scenarios for a pure refactor is
  ceremony for nothing; its risk wants **scrutiny**, not a spec.

The classic trap is routing a large, scary, but behavior-neutral change (a monorepo-wide rename, an
import-alias codemod) to full — dragging in a pointless `specs/` delta — when what it actually needs is
a thorough review. Keep the axes apart.

## The bar is asymmetric — default is FULL

Triage is a **spec-worthiness hunt.** Easy to route *up* to full; hard to route *down* to spec-less.
**Any doubt about a behavior/contract change → full.** Cost of a wrong "full" = a little ceremony; cost
of a wrong "spec-less" = a silent spec drift. Bias to full — but bias on **behavior**, not on size.

## Disqualifiers — ANY hit ⇒ full (all are behavior/contract signals)

| Lens | Disqualifier signal |
|------|---------------------|
| **Observable behavior** | introduces / changes / removes a user- or caller-visible behavior |
| **Public contract** | API, endpoint, route, schema, event/webhook, CLI/MCP surface, config a consumer depends on |
| **Spec-touch** | touches a capability already owned by `openspec/specs/**` (editing it out-of-band drifts the spec) |
| **Data / security** | data model, migration, auth, permission, security boundary — behavior *and* risk |
| **Multi-capability** | bundles **>1 distinct capability** ("and also…") — real scope creep, not multiple ACs for one behavior |
| **Underspecified behavior** | unclear *what behavior* is wanted → needs decomposition (refine's job), not a one-off |

## NOT disqualifiers — these set REVIEW DEPTH, not spec-mode

- **AC count.** A single change legitimately carries several Given/When/Then ACs (happy path + a guard
  + a green-gate). **Count distinct capabilities, not AC bullets.** Three ACs for one behavior is one
  behavior. (A well-formed ticket is *expected* to be multi-AC — refine makes it so; don't penalize it.)
- **Blast radius / load-bearing config / wide refactor.** Many files, touching `tsconfig`/`eslint`/CI,
  a monorepo-wide rename — these don't change behavior, so they stay **spec-less**. They raise the
  **review depth** (below). A pure refactor is the canonical spec-less case *however many files it spans.*

## Review depth (independent of spec-mode)

Blast radius + load-bearing surface + an enforcement/architectural invariant decide how hard to review —
in either mode:

- **Small / localized spec-less** → the one lightweight spec-less review
  (`references/spec-less-review.md`) is enough.
- **Large / load-bearing / invariant-bearing spec-less** → still spec-less (no `specs/`), but **also run
  the heavy `harness:architecture` review** (it reads `proposal.md` + `design.md`, works without
  `specs/`); add `harness:design` for a user-facing surface. Triggers: many files, a change to
  `tsconfig`/`eslint`/CI/build config, or a preserved architectural invariant (a boundary rule, a
  tripwire, a dependency direction) the change must not silently break.

## Clear-to-skip (spec-less)

**No behavior/contract disqualifier fires.** Blast radius does **not** block spec-less — it only sets
review depth.

## How refine §5b applies this

1. Scan the well-formed ticket for a **spec-worthiness disqualifier** (behavior · contract · spec-touch ·
   data/security · multi-capability · underspecified). Any hit → recommend **full**, silently. The common case.
2. **None** → recommend **spec-less**. Note the **review depth** (light · or `+architecture`) from a quick
   **code-peek** of the touched surface — the peek confirms no *hidden* contract change and gauges blast radius.
3. **Fork** (walk-me-through card, `references/walk-me-through.md`) only when spec-worthiness is genuinely
   borderline — `[A] spec-less · [B] full (recommended default)`. Never fork on file-count alone.

## How build's tripwire applies this (mid-impl)

While implementing a **spec-less** change, if the diff trips a **behavior/contract** disqualifier above
(a new/changed contract, an observable behavior change, a migration, a security boundary) → it was
mis-triaged. **Stop and fork** (build Step E): escalate to full (author specs, flip the marker) or
log-and-defer. A blast-radius surprise alone (more files than expected, no behavior change) is **not** an
escalation — it raises review depth, not the mode.

## Observability

The triage decision is logged (`spec_mode` + which disqualifier fired, if any + whether it later
escalated). `harness:review` aggregates it to tune these lenses — a lens that never fires or mis-fires is
a candidate to cut or sharpen.
