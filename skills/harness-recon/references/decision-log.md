# Decision log — `harness/decisions.md`

A per-change, **committed** ledger of every **load-bearing** decision, by anyone, in order — so a PR
reviewer reads the whole "why is it like this" trail in one place. **Lightweight: terse, scannable,
pointers over dumps.**

## Where
`<change-state-dir>/decisions.md` (the change's committed `harness/` dir). `harness:build` folds it
**verbatim into `pr-body.md`**, so it rides into the PR. Append-only; create on first write.

## Entry format — keep it 2–3 lines
```text
## D<N> · <actor> · <one-line decision>
<why — one line>.  [More: <pointer to the review artifact / spec section, if any>]
```
- **N** — sequential (read the last `D<N>` in the file, +1). Chronological order = the trail.
- **actor** — `👤 human` · `🤖 <stage>` (`recon` / `architecture` / `design` / `build` / `address-pr-comments`).
  The stage implies the agent; don't name sub-agents (stage-level is enough).

Example:
```text
## D7 · 🤖 architecture · require native has current input before submit
Debounced `inputChanged` could arrive after ⌘↩ → stale request. More: architecture-review.md #1 (🔴).

## D9 · 👤 human · model field = free-text id (not a curated dropdown)
Endpoint-agnostic, never goes stale; accepts typo risk.
```

## The bar — load-bearing ONLY (else it rots to noise)
- ✅ **Log:** resolves a genuine fork/gap · changes the shape of the work · hard to reverse · a non-obvious
  call with downstream consequence · **any fork a human resolved** (human judgment is rare + high-signal).
- ❌ **Never:** routine · rule-dictated · spec-dictated · mechanical · cosmetic.

Widen *which stages contribute*, never the noise threshold. If unsure whether it's load-bearing, it isn't.

## Who appends, when
- **recon** — a *contested* reuse/extend/build-new verdict (not the obvious ones).
- **architecture / design** — each fork *resolved* (the human's pick, or an auto-applied 🔴 critical) — one
  line + `More:` pointer to the review artifact. **Don't re-dump the review's findings.**
- **build** — impl-time spec gaps + skeptical-review deferrals (the choice made).
- **address-pr-comments** — each fix / decline / defer with its reasoning.
- **any skill** — a fork the **human** answered → a `👤` entry with their choice + why.
- (`refine` runs before the change exists — its decisions live in the refined ticket, not here.)

## Don't
- No routine/mechanical entries; no re-dumping a review — log the call + a pointer.
- Don't rewrite prior entries — append. The order is the history.
