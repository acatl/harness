# recon-first

RULE: before authoring any new exported/shared symbol, search for prior art; emit a verdict
(reuse|extend|build-new) BEFORE writing. No write until searched.

WHY: LLM duplication = a knowledge failure (existing code absent from context), not a values failure.
Linters / structural dup-detectors catch textual/structural copy-paste only — blind to semantic
re-implementation (same logic, different text). Recon is the only prevention. Target: zero *unwitting*
duplication, not zero duplication.

TRIGGER (recon required):
- any symbol intended to be exported/shared (fn|hook|component|service/repo method|type|schema|reusable
  const) — regardless of current path or export state (authoring locally now to export later still triggers)
- a util doing format|serialize|validate|parse|date|id|money|slug — any "surely exists" op
- a service/repo method whose shape mirrors an existing entity's
- a UI component → defer to the project's component-placement rule (grep-before-create) if it has one

EXEMPT (no recon):
- a non-exported helper used once in the current file
- test scaffolding/fixtures local to one spec
- glue with no reusable surface (wiring existing calls)
- unsure → grep anyway (search is cheap; a duplicate is not)

SEARCH (escalate by ambiguity):
1. name + synonyms (`format|serialize|to<X>`, `validate|assert|check`, `friendlyId|shortId`) — a
   single-name miss ≠ absence
2. known homes — the project's shared / util / component dirs + each package's export list (resolve from
   the rules dir / HARNESS.md › Paths)
3. non-trivial / multi-home concept → an `Explore` subagent (search by concept, not name guesses)
4. an OpenSpec-scoped change → the `harness:recon` skill (the ledger gate)

VERDICT (record per Decision Visibility; home = PR/commit body for a new capability, inline chat only if
it changes the next turn):
- `reuse <sym>` — fits; call it
- `extend <sym>` — almost fits; add param/overload/variant. PREFER over a near-duplicate
- `build-new (no prior art for <concept>; searched <where>)` — a recorded decision, never a default
  reached by not looking

BUILD-NEW valid iff: no prior art, OR reuse would couple independent parts (over-DRY worse than
duplication). Extraction still owes the committed-use bar: ≥2 named committed uses + a shape stable to a
third use.

SEE: the project's component-placement rule (UI instance) · `harness:recon` (OpenSpec gate) · your
linters / dup-detectors (detection backstop, not prevention).
