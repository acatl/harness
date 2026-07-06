# Quality Score (the judge rubric)

The rubric the **judge** grades a change against — the skeptical-review half of the pipeline (doer ≠ judge)
and the bar for code review. A clean build and green tests are **necessary, not sufficient**: the judge's
job is to **grade, not praise** — correctness is the bar, not a green check.

Findings are categorized with the **same vocabulary the harness run-log uses**
(`runs.jsonl` → `judge_findings[].category`), so review output aggregates into harness telemetry instead of
vanishing. **The category names below MUST match the run-log schema** — do not rename them.

---

## Categories

Every finding is tagged with exactly one category and a disposition (`applied` / `refuted` / `design-stop`):

| Category | What it catches |
|----------|-----------------|
| **correctness** | The behavior is wrong, or right only on the happy path — missed edge cases, broken invariants, silent data loss, races, unhandled failures. |
| **convention** | Diverges from repo idiom or the project's documented contracts — naming, structure, untestable shapes, non-Conventional commits, hardcoding what should be read from the binding layer. |
| **simplification** | Same behavior with less code/concepts — duplication that should collapse, or coupling that shouldn't exist; an abstraction with no committed use. |
| **efficiency** | Wasteful at runtime without cause — redundant work, missing memoization/debounce, polling where events exist, re-computing unchanged results. |
| **altitude** | Right idea, wrong layer or scope — logic in the wrong tier, a change that quietly expands product scope, a concern leaking across a boundary. |

---

## Lenses (what to look for → which category)

The five categories are the *buckets*; these lenses are the concrete *what-to-look-for* that fills them.
A reviewer sweeps the lenses and tags each finding with the category it rolls up to. The map is **not
rigid** — a lens rolls up by *why the finding matters* (a missing error-path test is `correctness` when
it hides a real bug, `convention` when it's just uncovered logic). The full checklists (how to recognize
each) live in the `harness:review-change` framework (`references/framework.md`); this is the calibration
map only.

| Category | Lenses that typically roll up here |
|----------|-------------------------------------|
| **correctness** | Security · Type safety & language rigor · Defensive programming · Database migration safety · Spec-code consistency (behavioral mismatch) · Testing gaps (when a gap hides a bug) |
| **convention** | Behavioral consistency · Developer experience & repo integrity · Accessibility · Localization · Testing gaps (uncovered pure logic) |
| **simplification** | Dead code & unused definitions · Architecture (collapsible duplication / coupling that shouldn't exist) |
| **efficiency** | Performance & scalability |
| **altitude** | Architecture & separation of concerns (logic in the wrong tier / scope leak) |

Skip any lens that doesn't apply to the stack; add a project-specific lens if the stack demands one
(name it so the addition is visible).

---

## What raises severity

- **Touches a load-bearing contract** declared in the project's context docs (ARCHITECTURE / RELIABILITY /
  SECURITY). A miss here outranks a cosmetic nit elsewhere.
- **Removes or regresses existing behavior** silently.
- **Crosses a scope edge** defined in PRODUCT. This is a **design-stop**, not a nit — surface for a human,
  don't "fix" it by building it.
- **Untested pure logic** — new logic that could be unit-tested but ships without tests is a convention
  failure by default.

## Disposition & the pass-bar

- **applied** — high-confidence finding, fixed in the same change; then re-run the sensors (a fix can break a gate).
- **refuted** — considered and rejected, with a reason. Honest refutation is signal.
- **design-stop** — a design-level problem (not a nit): stop and surface for a human.

A change **passes** when: sensors are green (per the binding layer), spec-conformance is verified, there are
no open **correctness** findings, no unaddressed **design-stop**, and the scope edge is respected.
Convention / simplification / efficiency / altitude findings are applied when high-confidence, logged when deferred.

## Honesty (anti-gaming)

The run-log exists because an LLM grading its own work skews optimistic. **Prefer deterministic facts over
self-assessment**; keep `judge_findings` honest — don't pad the log with phantom findings, and don't bury real
ones. An over-rosy review poisons the aggregate review. **A clean run that ships a bug — caught later by review
comments or CI — is still a bad run.**
