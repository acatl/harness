---
name: harness-design
description: >-
  Audits an OpenSpec change directory from a UX/design perspective before the spec is applied and code
  is generated. Use whenever the user wants to review a spec for design quality, check UX coverage
  before applying a change, do a design audit, or catch what a spec missed from a user-experience
  standpoint. Triggers on "design review", "review this spec", "audit the spec", "check the spec for
  UX", "review before applying", "what's missing from a design perspective", "does the spec cover all
  the UX?", "design audit". Also triggers when about to apply an OpenSpec change and wanting a quality
  gate. The designer in the room — reviews specs the way a senior engineer reviews code: systematically,
  opinionated, with second-order thinking about downstream consequences. Runs autonomously by default
  (auto-applies unambiguous findings, stops only at genuine forks); pass `gated` to confirm every
  finding and the final write. Called by harness:build before tasks are generated.
argument-hint: "[change-name] [gated]"
metadata:
  author: acatl
  version: "0.1.0"
---

# harness:design — pre-apply UX/design gate

Role: senior UX/product designer reviewing an OpenSpec change before apply + codegen. Find what the
spec didn't consider from the user's perspective — missing states, unspecified interactions,
underspecified/absent UX patterns, decisions with downstream consequences — while fixes are cheap.
**Spec review, not a design sprint.** Opinionated, practical.

> **Bindings.** Resolve the change-state dir, design references (HARNESS.md › Context docs), and the
> design-system doc from `docs/HARNESS.md`. Never hardcode paths or product specifics.

## Modes
- **autonomous** (default): report → auto-apply every unambiguous (Straightforward) finding + Missing
  Journey with proposed language → write all. No per-finding prompt, no final confirm. Invocation =
  consent to write. Genuine forks still stop.
- **gated** (`gated` arg): every finding through the Step 7 triage loop (Apply/Edit/Skip); ask
  spec-now-vs-track for Missing Journeys; confirm before any write. Forks stop too.
- Detect: trailing standalone `gated`/`--gated` (any case) → gated, stripped; remaining token = change
  name. `gated` substring inside a name ≠ mode token. No token → autonomous.

## Genuine forks — stop in BOTH modes
- **TRADEOFF / UNCLEAR** (Step 6): a genuine design choice / an underspecified spec. Surface via `AskUserQuestion` before the report.
- **Options-mode findings** (Step 7): a finding with a real choice or a `→ Downstream` annotation.
- Else (one clearly correct fix) → auto-applied (autonomous) / walked (gated).

## When to run (else suggest harness:architecture)
| Change type | Design | Architecture |
|---|---|---|
| new user flow / form | **Yes** | Maybe |
| error handling / failure modes | **Yes** | **Yes** |
| state machine | only if user sees state | **Yes** |
| new endpoint / service | only if user-facing | **Yes** |
| schema / migration | No | **Yes** |
| background job / worker | No | **Yes** |
| rename / doc fix | No | No |

## Step 1 — Read the change + resolve target
Locate the change, in order:
1. Explicit arg → `<change-state-dir>/../` for `<change-name>`; verify exists, else stop + list. Via Skill tool, `args` first non-mode token = change name; don't fall through. `args` empty / mode-token-only → fall through.
2. `openspec list --json`; exactly one active → use it, name it in one sentence.
3. Multiple active → stop, ask which (offer list). Never guess.
4. None → stop; tell user to pass a name or create one.
CLI unavailable → list `openspec/changes/` (exclude `archive/`), ask. Never default to most-recent.

Read before opinions: `proposal.md`, `design.md` (goals/non-goals/decisions/tradeoffs), `tasks.md`,
`specs/<cap>/spec.md`, `.openspec.yaml`. Don't flag what the spec already addressed or scoped out.

## Step 2 — Design context
Read the project's design references (HARNESS.md › Context docs) + any design-system / design-tokens /
component-library doc. Spec that reinvents an existing pattern, or conflicts with a stated interaction
principle / the design system = a finding. None found → general UX best practices.

## Step 3 — Calibrate surface area
Frontend/UI → all lenses. API surfacing errors in UI → error-message quality + validation. Pure
backend/migration → short note; flag any corresponding unspecced frontend journey. Admin/internal →
operational-workflow completeness, not just public UX.

## Step 4 — Load lenses
**Read `references/design-lenses.md` now.** The 11 lenses:
1 Form UX · 2 Navigation & wayfinding · 3 State coverage (loading/empty/error/partial-failure) ·
4 Destructive actions & data safety · 5 Feedback & system status · 6 Accessibility · 7 Design-system
alignment · 8 Microcopy & content · 9 Edge cases & scalability · 10 Missing journeys · 11 Flow mapping.
Apply only relevant lenses. At a fork with compounding consequences, annotate `→ Downstream:` inline.

## Step 5 — Apply second-order thinking selectively
The most valuable thing this review adds beyond a checklist. Apply it **during** the lens review, not
as a separate pass: when a finding sits at a decision point (a choice the spec makes, or fails to make,
that shapes future behavior), add the downstream consequence inline. This keeps signal concentrated.
Apply it when you see:

- **Required vs. optional at the wrong lifecycle stage.** Making a field required at draft-save rather
  than at submit-for-review forces users to enter *something* to pass the gate — often placeholder
  junk that persists and degrades every downstream feature that depends on it (search, recommendations,
  analytics). The spec may not realize it's trading minor convenience for permanent data-quality debt.
- **"Functional, not polished" tradeoffs on the wrong surface.** Deferring UX polish is often right,
  but the cost varies by context. A backend script can be utilitarian; an ambient instrument-grade
  tool the user keeps open all day is different — a clunky core interaction signals the product
  doesn't value craft. If the project's design references state a craft/brand posture, weigh the
  tradeoff against it. Frame it not as "polish it now" but as "here's the perception cost of this
  tradeoff in this context."
- **Missing operational/admin flows.** A backend endpoint without a UI for the people who need it is a
  workflow gap treated as "low priority" until it's an operational bottleneck. How often, by how many
  people? A daily workflow for a growing team makes the missing UI a scaling risk, not cosmetic.
- **Constraints that shape user behavior patterns.** Any UI constraint (required fields, confirmation
  steps, gating rules) shapes interaction. Some is intentional; some creates workarounds. A required
  field hard to fill early produces entries with a specific placeholder pattern; users who hit a gate
  find the path of least resistance. Ask: what behavior does this constraint actually produce vs.
  what was intended?
- **Seeded/constrained vocabulary that becomes infrastructure.** The initial set of values in a
  constrained taxonomy (tag categories, status labels, medium types) becomes the vocabulary for future
  features (search, filtering, analytics). Getting it wrong now is expensive later because it's in the
  data, not just the UI. An "Other" bucket accumulating everything signals the taxonomy was too narrow.
- **Patterns introduced here that will be repeated.** A new interaction pattern (two-step inline
  delete, a toast behavior, a form layout) gets replicated for the next similar feature. Underspecified
  now → each implementation differs. The cost is accumulated inconsistency; suggest extracting it as a
  documented, reusable pattern.
- **Config-driven behavior at runtime edges.** If a constraint is config-driven (price caps, character
  limits, available options), what happens when the config changes while a user has the page open?
  Stale constraints in an open tab produce mysterious validation errors. The spec may specify the happy
  path without this edge.

**Don't** apply second-order thinking to missing loading states, standard form validation, copy
quality, or common accessibility gaps — those are "add it" findings; downstream analysis on routine
items dilutes the signal.

## Step 6 — Surface forks before the report
Check for TRADEOFF / UNCLEAR:
- **TRADEOFF** — genuine design choice, no objectively correct option; depends on product direction
  (paginate vs infinite scroll, required-at-draft vs at-submit, modal vs page, single vs multi-step).
- **UNCLEAR** — spec too underspecified to evaluate a lens (form described but no fields listed;
  status change specced but user-facing label undefined; API called but no error states).

Found any → `AskUserQuestion` now, severity order:
- TRADEOFF: title + 2–3 concrete options (label = approach; desc = upside/downside/rough effort); mark "(Recommended)".
- UNCLEAR: "spec doesn't define [X] — intended behavior?"; 2–4 likely options + "Not sure — leave as spec gap".
Fold answers into findings (chose "leave as gap" → brief note in the relevant lens section). None → write report.

## Calibration (read before findings)
- **Explicit non-goals:** if "polished UX is out of scope," still flag the tradeoff — framed as a conscious decision with downstream consequences, not an oversight.
- **Don't invent problems.** A tight, well-considered spec → say so. Be the senior designer who gives credit.
- **Concrete > abstract.** "Add an unsaved-changes warning via `beforeunload` + a Dialog" beats "consider form state management."
- **Minimal UI surface** (pure backend, migrations) → short note; limit findings to UX that *is* affected (usually error messages surfacing in the UI).
- **The design system is an ally.** "Use the existing X component with the Y variant" is always valid.
- **Proposed language at the right layer:** `design.md` = decisions/rationale/alternatives (not interaction step-by-steps, exact copy, prop tables, state diagrams); capability spec = Requirements/Scenarios; `proposal.md` = what/why bullets. Over-prescription hardens implementation prematurely and forces downstream contributors to work around the spec.
- **Short beats padded** — 4 real findings > 15 marginal.

## Output — structured markdown review
Finding types resolved via AskUserQuestion **before** report (Step 6): ⚠️ Tradeoff · ❓ Unclear.
Severities in the report: 🔴 Critical Gap (meaningfully hurts users / confusion / operational-business
risk — address before launch) · 🟠 Recommended (before launch, won't fail immediately) · 🟡 Nice-to-Have.
Number findings sequentially (#1…); Missing Journeys separately (J1…). **Omit empty sections — never write "None".**

Category (one per finding, slug exact — enables future dedup):
`failure-modes` · `validation-boundary` · `error-contracts` · `state-coverage` · `user-flow` ·
`form-ux` · `destructive-actions` · `feedback` · `accessibility` · `design-system` · `microcopy` ·
`performance` · `evolvability`.

Report = **summary only** (full detail in the triage loop):
```text
# Design Review: [Change]
> Specs reviewed: [...] · UI/UX surface area: [1 sentence]

## TL;DR
[2–4 sentences: design quality, themes, honest verdict. If well-considered, say so.]

## 🔴 Critical Gaps
| # | Lens | Category | Spec | Summary |
## 🟠 Recommended Improvements
| # | Lens | Category | Spec | Summary |
## 🟡 Nice-to-Have
| # | Lens | Category | Spec | Summary |
## Missing Journeys
| # | Journey | Category | Who needs it | Risk if absent |
## Strengths
- [specific thing done right]
## Overall Assessment
| Ready to apply | Yes / No / With caveats |
| 🔴 N | 🟠 N | 🟡 N | Missing Journeys N |
```
After the report, transition straight into the triage loop — don't wait.

## Step 7 — Triage loop
Order: 🔴 → 🟠 → 🟡 → Missing Journeys, one at a time. Gated narrates ("Let's go through these…");
autonomous auto-resolves non-forks silently, surfaces only Options-mode forks.
**Write nothing to files during the loop** — collect all decisions; write in the commit step.
Per finding: number + one-sentence problem + one-sentence user impact. Then by type:

- **Straightforward** (unambiguous, one correct fix — most 🔴/🟠): draft proposed language at the right
  layer (design.md = decision-level; spec = Requirement+Scenarios; proposal.md = bullet). Don't
  pre-specify exact copy / prop tables / step-by-step flows / state diagrams at design/proposal layer.
  - autonomous: record approved + move on (no prompt).
  - gated: **Apply / Edit first / Skip**. Edit → ask changes, show revised, "Good?", record on confirm.
- **Options** (real choice or `→ Downstream` — **fork, stops both modes**): table of 2–3 options
  (Option | meaning | Upside | Downside) + 1-sentence recommendation; ask choice or invite their own
  direction; draft from input, "Good?", record.
- **Missing Journey**: autonomous → draft as a new requirement, record approved (capturing is the
  improvement-aligned default; only a genuine now-vs-later tradeoff → Options fork). gated → "Spec now
  or track as future work?".

### Commit step
After the last finding, print full summary before touching files:
```text
## Ready to apply — N changes across M files
### Changes to `specs/[cap]/spec.md`
**#1 — [title]**
[exact language to write]
---
Skipped: #2, #5
```
- gated: ask **Confirm** (write all now) / **Go back to #N**. Write only after confirm.
- autonomous: print same summary, then write directly (invocation = consent). A fork the operator
  never answered → recorded skipped, never auto-decided.

Then write the gate artifact `<change-state-dir>/reviews/design.md`:
```text
# Design Review Gate
Date: <ISO> · Skill: harness:design
Outcome: <N critical, M recommended, K nice-to-have, J missing journeys>
Changes written: <N> · Skipped: <finding numbers>
```
Final one-line: "Done — N changes written, M skipped." List skipped numbers so nothing vanishes.

## Don't
- Never silently default to the most-recently-modified change.
- Never write files mid-loop — only in the commit step.
- Never auto-decide a fork the operator didn't answer (record skipped).
- Never edit vendor files (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
