---
name: harness:architecture
description: >-
  Audits an OpenSpec change directory from an architecture and engineering quality perspective before
  the spec is applied and code is generated. Use whenever the user wants to review a spec for technical
  soundness, catch engineering gaps before apply, or run a pre-apply architecture gate. Triggers on
  "architecture review", "engineering review", "review this spec", "audit the spec", "check the spec for
  technical gaps", "review before applying", "is this well-architected?", "technical review". Also
  triggers when about to apply an OpenSpec change and wanting an engineering quality gate. The senior
  engineer in the room — reviews specs the way a principal reviews a design doc: systematically,
  opinionated, with second-order thinking about downstream consequences. Runs autonomously by default
  (auto-applies unambiguous findings, stops only at genuine forks); pass `gated` to confirm every
  finding and the final write. Called by harness:build before tasks are generated.
argument-hint: "[change-name] [gated]"
metadata:
  author: acatl
  version: "1.2.0" # x-release-please-version
---

# harness:architecture — pre-apply engineering gate

Role: senior engineer reviewing an OpenSpec change before apply + codegen. Find what the spec didn't
consider — wrong boundaries, missing failure modes, security gaps, unhandled races, underspecified
migrations, decisions with compounding downstream cost — while fixes are cheap. **Spec review, not
redesign.** Opinionated, practical.

> **Bindings.** Resolve the change-state dir, context docs (ARCHITECTURE / RELIABILITY / SECURITY),
> and rules dir from `docs/HARNESS.md`. Never hardcode paths.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:architecture` + any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:architecture v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

## Modes
- **autonomous** (default): report → auto-apply every unambiguous (Straightforward) finding + Missing
  Technical Concern with its proposed language → write all. No per-finding prompt, no final confirm.
  Invocation = consent to write. Genuine forks still stop.
- **gated** (`gated` arg): every finding through the Step 7 triage loop (Apply/Edit/Skip); ask
  add-vs-track for MTCs; confirm before any write. Forks stop too.
- Detect: trailing standalone `gated`/`--gated` (any case) → gated, stripped; remaining token = change
  name. `gated` substring inside a name ≠ mode token. No token → autonomous.

## Genuine forks — stop in BOTH modes
- **TRADEOFF / UNCLEAR / RISK** (Step 6): real technical choice / underspecified spec / committed
  risk. Surface as a walk-me-through fork card (`references/walk-me-through.md`) before the report.
- **Options-mode findings** (Step 7): finding with a real choice or a `→ Downstream` annotation.
- Else (one clearly correct fix) → auto-applied (autonomous) / walked (gated).

## When to run (else suggest harness:design)
| Change type | Architecture | Design |
|---|---|---|
| schema / migration | **Yes** | No |
| new endpoint / service | **Yes** | only if user-facing |
| state machine | **Yes** | only if user sees state |
| background job / worker | **Yes** | No |
| error handling / failure modes | **Yes** | **Yes** |
| new user flow / form | Maybe | **Yes** |
| new / restructured component | **Yes** | **Yes** |
| rename / doc fix | No | No |

Both reviews on error-handling/component changes is valid (different angles).

## Step 1 — Read the change + resolve target
Locate the change, in order:
1. Explicit arg → `<change-state-dir>/../` for `<change-name>`; verify exists, else stop + list changes. Via Skill tool, `args` first non-mode token = change name; don't fall through. If `args` empty or mode-token-only → fall through.
2. `openspec list --json`; exactly one active → use it, name it in one sentence.
3. Multiple active → stop, ask which (offer list). Never guess.
4. None → stop; tell user to pass a name or create one.
CLI unavailable → list `openspec/changes/` dirs (exclude `archive/`), ask. Never default to most-recent.

Read before opinions: `proposal.md` (why/what), `design.md` (goals/non-goals/decisions/tradeoffs),
`tasks.md` (what's built), `specs/<cap>/spec.md` (requirements/scenarios), `.openspec.yaml`. Don't flag
what the spec already addressed or explicitly scoped out.

**Prior-art parity** (only if `proposal.md` has a `<!-- harness:recon:start -->` block). Per recon
verdict:
- `reuse <X>` / `extend <X>` → design should consume `X`. Design builds a new equivalent **with no
  stated reason** → `reuse-parity` finding (name capability, verdict, `X`).
- `build-new` → skip.
- Reasoned override allowed (verdict advisory); silent override = finding. Contested → read
  `<change-state-dir>/recon.md` (evidence) before flagging.
No block → skip.

## Step 2 — Architecture context
Read project context docs (HARNESS.md › Context docs: ARCHITECTURE, RELIABILITY, SECURITY), plus
`CLAUDE.md`, ADRs (`docs/adr/`), package READMEs if present. Spec that violates a documented
convention / re-invents an existing pattern / conflicts with an ADR = a finding. None found → general
engineering best practices.

## Step 3 — Calibrate surface area
Review depth by change type: schema/migration → data-model + migration-safety + backwards-compat;
API → API design + security + separation + contract; job/worker → failure modes + observability +
concurrency + async; integration → failure modes + dependency + security (+ perf/observability);
frontend/component → Frontend Component Architecture lens (+ concurrency's frontend subset: stale
closures, out-of-order async, double-submit, optimistic rollback); pure refactor → separation +
testability + backwards-compat. Don't force every lens on every spec.

## Step 4 — Load lenses
**Read `references/architecture-lenses.md` now** (detailed criteria). The 15 lenses:
1 API Design Quality · 2 API Contract Consistency · 3 Data Model Decisions · 4 Separation of Concerns
· 5 Security Surface · 6 Error Handling & Failure Modes · 7 Observability · 8 Concurrency & Races ·
9 Performance Shape · 10 Dependency Decisions · 11 Testability · 12 Migration & Backwards Compat ·
13 Evolvability · 14 Missing Technical Concerns · 15 Frontend Component Architecture.

Then output (mandatory, self-verifying):
```text
## Setup Confirmation
**Spec files read:** proposal.md ✓/✗ · design.md ✓/✗ · tasks.md ✓/✗ · specs/<cap>/spec.md ✓ (list)
**Architecture context found:** [files read] / (none — general best practices)
**Lenses loaded:** [the 15 names]
**Surface area calibration:** [1 sentence: which lenses are high-priority here and why]
```
Apply only relevant lenses. At a fork with compounding consequences, annotate the finding `→ Downstream:` inline.

## Step 5 — Second-order thinking (inline, selective)
The most valuable thing this review adds beyond a checklist. Apply it **during** the lens review, not
as a separate pass: when a finding sits at a decision point (a technical choice the spec makes, or
fails to make, that shapes future behavior), add the downstream consequence inline. Apply it when you see:

- **Validation at the wrong boundary.** Validation in the service layer instead of at the HTTP
  boundary is bypassed by any internal caller (a job, an admin script, a test fixture) that calls the
  service directly. The spec may describe validation without saying where it lives. Misplaced
  validation silently becomes optional over time as callers that "know what they're doing" skip it.
- **Synchronous operations on hot paths that belong in a queue.** Sending an email, resizing an image,
  calling an external API inside a sync request handler works at low volume; at scale it's the
  bottleneck and a timeout source. Retrofitting async later is far costlier than speccing it now
  (queue infra, idempotency, response-contract rethink).
- **Shared mutable state without ownership.** A counter/aggregate/denormalized field multiple
  services or processes can write to without coordination is a race that's rare at low traffic and
  consistent at scale. The spec may not even acknowledge the field is shared.
- **Schema choices that become constraints on future features.** A column type, NULL policy, or
  normalization choice constrains every future feature touching this data. Integer that should be
  decimal, boolean that needs to be an enum, inconsistent soft-delete — cheap at spec time, expensive
  after data exists.
- **New patterns introduced here that will be replicated.** A new error-handling approach, response
  shape, or service structure — if it's wrong or inconsistent in the spec, it gets copied when the
  next similar thing is built. The cost is the accumulated inconsistency, not this instance.
- **Missing operational handles.** A new background job with no way to monitor, retry, or cancel it
  is an operational blindspot; a new status with no admin way to change it is a support escalation.
  Engineering gaps that generate operational toil.

**Don't** apply second-order thinking to obvious missing indexes, standard input-validation gaps, or
routine logging omissions — those are just "add it" findings, and downstream analysis on routine items
dilutes the signal.

## Step 6 — Surface forks before the report
Check for TRADEOFF / UNCLEAR / RISK:
- **TRADEOFF** — real choice, no objectively correct option (REST vs event, sync vs async, cursor vs offset).
- **UNCLEAR** — spec too underspecified to evaluate a lens (migration referenced not described; retry behavior undefined; error contract unspecified).
- **RISK** — chosen approach carries known risk, no alternative being weighed (table-locking migration no downtime plan; TOCTOU no coordination; sync external call no timeout/breaker).

Found any → surface as walk-me-through fork cards (`references/walk-me-through.md`) now, severity order:
- TRADEOFF: title + 2–3 concrete options (label = approach; desc = upside/downside/rough effort); mark "(Recommended)".
- UNCLEAR: "spec doesn't define [X] — intended behavior?"; 2–4 likely options + "Not sure — leave as spec gap".
- RISK: "Mitigate before apply" / "Accept with documented TODO" / "Explain more".
Fold answers into findings. None → write report.

## Calibration (read before findings)
- Explicit non-goals: may still flag the tradeoff, framed as conscious decision + downstream cost, not oversight.
- Don't invent problems; credit a tight spec.
- Concrete > abstract ("add unique constraint on `(user_id, slug)`, handle 23505 in service" > "consider data integrity").
- Minimal technical surface (docs/copy) → short note, findings limited to what's affected.
- Established patterns are allies.
- **Proposed language at the right layer:** `design.md` = decisions/rationale/alternatives (not request/response shapes, handler steps, signatures, types); capability spec = Requirements/Scenarios; `proposal.md` = what/why bullets. Over-prescription hardens implementation prematurely.
- Short beats padded — 4 real findings > 15 marginal.

## Output — structured markdown review
Finding types resolved via walk-me-through fork cards **before** report (Step 6): ⚠️ Tradeoff · ❓ Unclear · 🔺 Risk.
Severities in the report: 🔴 Critical (correctness/security/data-loss/ops failure — fix before apply) ·
🟠 Recommended (fix before apply, won't fail immediately; compounding debt) · 🟡 Nice-to-Have (polish/edge/future).
Number findings sequentially (#1, #2…); Missing Technical Concerns separately (T1, T2…). **Omit empty sections — never write "None".**

Category (one per finding, slug exact — enables future dedup):
`failure-modes` · `validation-boundary` · `error-contracts` · `authorization` · `data-model` ·
`api-contract` · `async-behavior` · `migration-safety` · `state-coverage` · `observability` ·
`performance` · `concurrency` · `testability` · `evolvability` · `component-architecture` ·
`separation` · `dependency` · `security` · `reuse-parity`.
Tiebreaks: missing input validation → `validation-boundary` (even if also security); wrong-layer/framework-coupling → `separation` (even though harms testability); silent rebuild of a `reuse`/`extend` verdict → `reuse-parity` (over `evolvability`).

Report = **summary only** (full detail delivered in the triage loop). **Mode-aware:** **autonomous** emits
**findings only** — the 🔴/🟠/🟡 + Missing-Technical-Concerns tables (the auto-apply loop's input); **omit
TL;DR, Strengths, Overall Assessment** (no reader mid-stream — pure tokens). **gated/standalone** emits the
full template below.
```text
# Architecture Review: [Change]
> Specs reviewed: [...] · Architectural surface area: [1 sentence]

## TL;DR  *(gated/standalone only — omit in autonomous)*
[2–4 sentences: technical quality, themes, honest verdict. If well-considered, say so.]

## 🔴 Critical
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## 🟠 Recommended
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## 🟡 Nice-to-Have
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## Missing Technical Concerns
| # | Concern | Category | Where it matters | Risk if absent |
|---|---------|----------|------------------|----------------|
## Strengths  *(gated/standalone only)*
- [specific thing done right]
## Overall Assessment  *(gated/standalone only)*
| Ready to apply | 🔴 Critical | 🟠 Recommended | 🟡 Nice-to-Have | MTC |
|---|---|---|---|---|
| Yes / No / With caveats | N | N | N | N |
```
After the report, transition straight into the triage loop — don't wait.

## Step 7 — Triage loop
Order: 🔴 → 🟠 → 🟡 → MTC, one at a time. Gated narrates ("Let's go through these together…");
autonomous auto-resolves non-forks silently, surfaces only Options-mode forks.
**Write nothing to files during the loop** — collect all decisions; write in the commit step.
Per finding: number + one-sentence problem + one-sentence technical consequence. Then by type:

- **Straightforward** (unambiguous, one correct fix — most 🔴, many 🟠): draft proposed language at the
  right layer (design.md = decision-level; spec = Requirement+Scenarios; proposal.md = bullet). Don't
  pre-specify method names / step orderings / full bodies at design/proposal layer.
  - autonomous: record approved + move on (no prompt).
  - gated: **Apply / Edit first / Skip**. Edit → ask changes, show revised, "Good?", record on confirm.
- **Options** (real choice or `→ Downstream` — **fork, stops both modes**): table of 2–3 options
  (Option | meaning | Upside | Downside) + 1-sentence recommendation; ask choice or invite their own
  direction; draft from input, "Good?", record.
- **Missing Technical Concern**: autonomous → draft as new requirement/constraint, record approved
  (capturing is the improvement-aligned default; only a genuine now-vs-later tradeoff → Options fork).
  gated → "Add to spec now or track as future work?".

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

Then write the gate artifact `<change-state-dir>/architecture-review.md` (committed, flat under the change's
`harness/` dir — not a `reviews/` subfolder) — the **durable verification
record**. Write it in FULL **regardless of mode**: the in-stream report may be terse (Output mode-awareness),
but this file always carries every finding's detail so a reader can verify each one and see its value. **Never
reduce it to a bare count stamp** — embed the findings table AND per-finding detail (applied and skipped):
```text
# Architecture Review Gate
Date: <ISO> · Skill: harness:architecture · Change: <name>
Outcome: <N critical, M recommended, K nice-to-have, J MTC> · Changes written: <N> · Skipped: <finding #s>

## Findings
| # | Sev | Lens | Category | Spec | Summary |
|---|-----|------|----------|------|---------|
| 1 | 🟠 | <lens> | <category> | `<spec>` | <one-line> |
<one row per finding, 🔴 first; include MTCs as T1…>

## Detail
**#1 — <title>** · <🔴/🟠/🟡> · `<category>` · `<spec path>`
- **Problem:** <what's wrong / missing>
- **Impact:** <downstream / second-order technical consequence — why it's worth fixing>
- **Evidence:** <the spec or code quote that grounds the finding>
- **Resolution:** <exact language written to the spec> — or **Skipped:** <reason>
---
<repeat for EVERY finding, applied and skipped — nothing reduced to a count>

## Forks resolved
<TRADEOFF / UNCLEAR / RISK title → chosen option + one-line rationale> — omit the section if none
```
After the gate artifact, append load-bearing calls to the **decision log** (`<change-state-dir>/decisions.md`,
per `references/decision-log.md`): each **fork resolved** (TRADEOFF/UNCLEAR/RISK — the human's pick → `👤 human`)
and any **auto-applied 🔴 critical** (→ `🤖 architecture`) — one line + `More: architecture-review.md #<n>`.
Don't re-dump 🟠/🟡 findings; the review holds those.

Final one-line: "Done — N changes written, M skipped." List skipped numbers so nothing vanishes.

## Don't
- Never silently default to the most-recently-modified change.
- Never write files mid-loop — only in the commit step.
- Never auto-decide a fork the operator didn't answer (record skipped).
- Never edit vendor files (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
