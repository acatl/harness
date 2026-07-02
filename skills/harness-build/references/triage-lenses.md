# Triage lenses — is this change spec-worthy?

Shared decision aid for choosing **full** vs **spec-less** build mode. Read by two consumers:

- **`harness:refine` Step 0** — *upfront*, against the ticket (Story + AC + description). Recommends a
  mode; carries it into the `Next: /harness:build` pointer. refine never creates a change or writes
  the marker — it only recommends.
- **`harness:build` Step E escalation tripwire** — *mid-impl*, against the **diff / discovered
  reality**. Fires when a spec-less change turns out spec-worthy after all.

Same lens set, two vantage points (ticket text vs actual code). The list is the contract; `harness:review`
tunes it from run-log data over time.

## Principle

**Spec-worthy = the change alters what a capability is *specified to do*** — an observable
behavior or contract that a future change, a teammate, or the spec itself needs on record. OpenSpec's
`specs/` delta exists to record exactly that. No behavior/contract change to record → the formal spec
buys nothing → **spec-less**.

Not "user-facing value" (a copy tweak is user-facing but not spec-worthy); not "big" (a one-line auth
change is tiny but spec-worthy). The axis is **does a spec need to assert something new about the
system.**

## The bar is asymmetric — default is FULL

Triage is a **disqualifier hunt, not a judgment.** Easy to route *up* to full; hard to route *down* to
spec-less. **Any doubt → full.** Spec-less is granted only when a change clears **every** disqualifier.
Cost of a wrong "full" = a little ceremony; cost of a wrong "spec-less" = a silent spec drift. Bias to
full.

## Disqualifiers — ANY hit ⇒ full

| Lens | Disqualifier signal |
|------|---------------------|
| **AC count** | more than one acceptance criterion |
| **Spec-touch** | touches a capability already owned by `openspec/specs/**` (editing it out-of-band drifts the spec) |
| **Behavior / contract words** | API, endpoint, route, schema, migration, data model, auth, permission, public interface, event/webhook |
| **Risk words** | security, payment, delete/destroy, irreversible, production, credential, PII |
| **Scope** | "and also…" — more than one distinct change bundled |
| **Ambiguity** | underspecified / vague AC that needs decomposition (that's refine's real job — not a one-off) |

## Clear-to-skip (spec-less) — ALL must hold

- Survives **every** disqualifier above, **and**
- **Blast radius is small** — few files, no shared state, no downstream consumers, no public contract.

**refine** reads blast radius from a cheap **code-peek** it runs *itself* (silently, only for a ticket
that already looks trivial — no "want me to look?" prompt). **build's tripwire** reads it from the diff
in front of it.

## How refine Step 0 applies this (tiered, cheap-first)

1. **Tier 1 (free, ticket/AC only):** scan for disqualifiers. Any hit → recommend **full**, no fork.
   Clears most tickets instantly.
2. **Tier 2 (code-peek):** only for a ticket that survived Tier 1 looking trivial (0 disqualifiers, ≤1
   AC, no spec-touch) → refine silently peeks at the touched surface to confirm small blast radius.
3. **Fork only when genuinely small:** surface a walk-me-through fork
   (`references/walk-me-through.md`) — `[A] spec-less · [B] full (recommended default)`. The common
   case (disqualifier present) never sees a fork.

## How build's tripwire applies this (mid-impl)

While implementing a **spec-less** change, if the work trips any disqualifier against the actual diff
(a new/changed contract, an observable behavior change, a migration, a security boundary) → the change
was mis-triaged. **Stop and fork** (build Step E): escalate to full (author specs, flip the marker) or
log-and-defer. Non-spec-worthy gaps stay on the ordinary decision-log fork.

## Observability

The triage decision is recorded in the run-log (`spec_mode` + which disqualifier fired, if any + whether
it later escalated). `harness:review` aggregates it to tune these lenses from real friction — a lens that
never fires or always mis-fires is a candidate to cut or sharpen.
