---
name: harness:design
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
  version: "1.3.2" # x-release-please-version
---

# harness:design — pre-apply UX/design gate

Pre-apply spec audit, senior-designer stance. **Split topology (doer ≠ judge, main context stays
lean):** an isolated auditor sub-agent loads the lenses + spec, judges, returns a structured payload;
this skill (orchestrator, main context) resolves the target, spawns, runs the fork cards + triage
loop, and owns **all writes**. Lens files never enter main context.

> **Bindings.** Resolve the change-state dir, design references (HARNESS.md › Context docs), and the
> design-system doc from `docs/HARNESS.md`. Never hardcode paths or product specifics.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:design` + any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:design v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

## Modes
- **autonomous** (default): report → auto-apply every unambiguous (Straightforward) finding + Missing
  Journey with proposed language → write all. No per-finding prompt, no final confirm. Invocation =
  consent to write. Genuine forks still stop.
- **gated** (`gated` arg): every finding through the Step 5 triage loop (Apply/Edit/Skip); ask
  spec-now-vs-track for Missing Journeys; confirm before any write. Forks stop too.
- **standalone**: not an arg — the **caller**. Operator invoked this skill directly (vs `harness:build`
  calling it in its Step C chain). Same write behavior as autonomous; **report differs** — a human is
  reading mid-stream, so Step 4 keeps TL;DR / Strengths / Overall Assessment.
- Detect: trailing standalone `gated`/`--gated` (any case) → gated, stripped; remaining token = change
  name. `gated` substring inside a name ≠ mode token. No token → autonomous when build invoked this run,
  else standalone (build passes only `<change-name>`, so args alone can't distinguish them — the caller can).

## Genuine forks — stop in BOTH modes
- **TRADEOFF / UNCLEAR** (Step 3): a genuine design choice / an underspecified spec. Surface as
  walk-me-through fork cards (`references/walk-me-through.md`) before the report.
- **Options-mode findings** (Step 5): a finding with a real choice or a `→ Downstream` annotation.
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

## Step 1 — Resolve target
Locate the change, in order:
1. Explicit arg → `<change-state-dir>/../` for `<change-name>`; verify exists, else stop + list. Via Skill tool, `args` first non-mode token = change name; don't fall through. `args` empty / mode-token-only → fall through.
2. `openspec list --json`; exactly one active → use it, name it in one sentence.
3. Multiple active → stop, ask which (offer list). Never guess.
4. None → stop; tell user to pass a name or create one.
CLI unavailable → list the changes root from the change-state-dir binding (HARNESS.md; the binding minus
`<change>/harness/`), excluding `archive/`; ask. Never default to most-recent.

## Step 2 — Spawn the auditor
One general sub-agent, foreground (result needed before continuing). **Do NOT read
`references/auditor.md` or `references/design-lenses.md` yourself** — they load only in the sub-agent;
pulling them into main context defeats the topology. Spawn prompt, in substance:

> You are the auditor sub-agent for a pre-apply UX/design review. Load and follow
> `<skill-dir>/references/auditor.md` (procedure, lenses pointer, categories, return format).
> Target change dir: **`<abs change dir>`**. Change-state dir: **`<abs path>`**.
> Project bindings file: **`<abs path to docs/HARNESS.md>`** — resolve design references from it.
> Caller context (each item changes what counts as a defect):
> · Held artifacts: **`<roles intentionally not-yet-authored, or "none">`** — absent by design; never a finding.
> · Spec mode: **`<full | spec-less>`** — spec-less has no `specs/` delta by design; never flag its
> absence and never propose capability-spec language.
> **Read-only: never write or edit any file.** Your final message is the structured payload —
> return it exactly per the auditor's Return format, nothing else.

`<skill-dir>` = the absolute **base directory announced when this skill loaded** — a fresh sub-agent
has no cwd context, so hand it resolved, never skill-relative. Never guess it.

**Caller context is load-bearing — forward all of it.** The auditor is a fresh context: anything the
caller knows that makes an absence *intentional* must be passed, or the auditor reads it as a defect and
autonomous mode writes that bogus finding into the spec. Two known items, both from `harness:build`:
- **Held artifacts** — the AUTHOR path holds the task checklist until its Step D, so `tasks.md` is
  legitimately absent at Step C. Build states this in one line; forward it. Nothing held → `none`.
- **Spec mode** — `spec-less` authors no `specs/` delta at all (build › Spec mode), yet build still
  invokes this review for a large / load-bearing user-facing change. Unforwarded, the auditor flags the
  missing capability spec and proposes spec language — **creating the very delta spec-less forbids.**
  Resolve it by the harness-wide **reader rule** — read `<change-state-dir>/spec-mode`, whose producer
  writes the single line `spec_mode: spec-less` (build › Spec mode). **Parse the `spec_mode:` value**;
  spec-less only if that value is exactly `spec-less`. Absent / empty / unreadable / any other value ⇒
  `full`. Don't string-equal the whole file against `spec-less` — it never matches the format build
  writes, and a false `full` tells the auditor to expect capability specs. Applies to **every**
  invocation, standalone included — never skip the read, and **never infer the mode from an absent
  `specs/`**.

Adding a caller with its own intentional-absence rule → add it here **and** to the spawn prompt.

On return:
- `STATUS: skip` → print the one-line skip note + reason, end run (no gate artifact; breadcrumb
  `skipped: <reason>`).
- `STATUS: escalate` → spec-less change found spec-worthy. **Terminal: apply nothing, write no spec
  edits.** Print the reason + the observable behavior/contract it changes, then return it as a
  **blocking signal to the caller** — escalate-vs-defer is the caller's fork, not ours (build's Step E:
  **(A) escalate to full** / **(B) log + defer**; load-bearing, always logged. Row B is admissible despite the `Defer` standing ban — a *recorded terminal disposition*, `walk-me-through.md` carve-out b). Don't author `specs/`,
  don't flip the spec-mode marker, don't pick an outcome. Standalone (no caller to fork) → render that
  same two-option card yourself. Breadcrumb `stopped: spec-worthy → caller fork`. Never downgrade it to
  a finding — an applied finding lets the run continue to task generation and ships the contract change
  with no `specs/` delta.
- `STATUS: reviewed` → print the payload's Setup Confirmation block verbatim, continue.
- Malformed / missing payload → **never fabricate findings.** autonomous: respawn once silently;
  second malformed return → emit a one-line skip note (`skipped: auditor returned no usable payload`)
  and end — never stall a build chain on an unanswerable question. gated: offer one respawn as a
  `👉` terminal-block ask; declined, or the respawn also malformed → same one-line skip note and end.
  Never a third attempt.

## Step 3 — Fork cards (before the report)
Payload's `## Fork cards` non-empty → surface each as a walk-me-through fork card
(`references/walk-me-through.md`), severity order TRADEOFF → UNCLEAR, one at a time. Cards arrive
**complete** (auditor drafts the full shape, counters included) — render verbatim, don't renumber.
Fold each answer into the finding #s the card names — the finding's Proposed language becomes the
**chosen option's own `Proposed` cell** (each option carries one; never draft your own). A `no-write`
cell writes nothing: record the stated outcome as a brief note on the finding. **Mark every folded
finding # locked — Step 5 must not re-ask it.** Types: ⚠️ Tradeoff · ❓ Unclear. None → straight to report.

## Step 4 — Report
Render from the payload; **summary only** (full detail delivered in the triage loop).
Severities: 🔴 Critical Gap · 🟠 Recommended · 🟡 Nice-to-Have; Missing Journeys as J1…. **Omit empty sections — never write "None".** **Mode-aware:** **autonomous** emits
**findings only** — the 🔴/🟠/🟡 + Missing-Journeys tables (the auto-apply loop's input); **omit TL;DR,
Strengths, Overall Assessment** (no reader mid-stream — pure tokens). **gated/standalone** emits the
full template:
```text
# Design Review: [Change]
> Specs reviewed: [...] · UI/UX surface area: [1 sentence]

## TL;DR  *(gated/standalone only — omit in autonomous)*
[from payload]

## 🔴 Critical Gaps
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## 🟠 Recommended Improvements
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## 🟡 Nice-to-Have
| # | Lens | Category | Spec | Summary |
|---|------|----------|------|---------|
## Missing Journeys
| # | Journey | Category | Who needs it | Risk if absent |
|---|---------|----------|--------------|----------------|
## Strengths  *(gated/standalone only)*
## Overall Assessment  *(gated/standalone only)*
| Ready to apply | 🔴 Critical | 🟠 Recommended | 🟡 Nice-to-Have | Missing Journeys |
|---|---|---|---|---|
| Yes / No / With caveats | N | N | N | N |
```
After the report, transition straight into the triage loop — don't wait.

## Step 5 — Triage loop
Order: 🔴 → 🟠 → 🟡 → Missing Journeys, one at a time, off the payload. Gated narrates ("Let's go
through these…"); autonomous auto-resolves non-forks silently, surfaces only Options-mode forks.
**Write nothing to files during the loop** — collect all decisions; write in the commit step.
Per finding: number + one-sentence problem + one-sentence user impact.
**Pre-dispatch override — check before reading `Type`:** a finding carrying a `Downstream` annotation
is a fork, whatever its `Type` says. Treat it as Options; never auto-apply it. The invariant outranks
the payload, and every non-`options` type (`straightforward`, `journey`) otherwise auto-applies in
autonomous mode. Then by `Type`:

- **Straightforward** (unambiguous, one correct fix — most 🔴/🟠): use the payload's Proposed language
  (already layered right).
  - autonomous: record approved + move on (no prompt).
  - gated: **Apply / Edit first / Skip**. Edit → ask changes, show revised, "Good?", record on confirm.
- **Options** (real choice or `→ Downstream` — **fork, stops both modes**): **locked by a Step 3 fork
  card → never re-ask; carry it through as Straightforward on the chosen option's `Proposed` language.**
  Otherwise render the payload's options table + recommendation; ask choice or invite their own
  direction; record the picked option's `Proposed` (their own direction → draft from input, "Good?").
  Picked a `no-write` option → record the outcome, write nothing; it counts as skipped, not applied.
  **Exactly ONE admissible option in the payload → render a consent gate, not a table.** A `Downstream`
  finding can legitimately admit a single mitigation, and a one-row fork card is banned
  (`references/walk-me-through.md` › Admissibility). Emit that reference's consent-gate shape instead —
  one line, `👉 <the mitigation> — <blast radius>. Apply?` Yes → record its `Proposed`; no → record
  declined, write nothing (skipped, not applied). **The table goes; the stop stays** — never pad to two
  rows, never auto-apply, and never fall through to Straightforward (the `Downstream` invariant above
  forbids it).
- **Missing Journey**: autonomous → record the payload's drafted requirement as approved (capturing is
  the improvement-aligned default; only a genuine now-vs-later tradeoff → Options fork). gated →
  "Spec now or track as future work?".

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
Read each target spec file before editing it (the sub-agent's reads don't carry over).

Then write the gate artifact `<change-state-dir>/design-review.md` (committed, flat under the change's
`harness/` dir — not a `reviews/` subfolder) — the **durable verification record**.
Build it from the payload + triage outcomes, in FULL **regardless of mode**: the in-stream report may be
terse (Step 4 mode-awareness), but this file always carries every finding's detail so a reader can verify
each one and see its value. **Never reduce it to a bare count stamp** — embed the findings table AND
per-finding detail (applied and skipped):
```text
# Design Review Gate
Date: <ISO> · Skill: harness:design · Change: <name>
Outcome: <N critical, M recommended, K nice-to-have, J missing journeys> · Changes written: <N> · Skipped: <finding #s>

## Findings
| # | Sev | Lens | Category | Spec | Summary |
|---|-----|------|----------|------|---------|
| 1 | 🟠 | <lens> | <category> | `<spec>` | <one-line> |
<one row per finding, 🔴 first; include Missing Journeys as J1…>

## Detail
**#1 — <title>** · <🔴/🟠/🟡> · `<category>` · `<spec path>`
- **Problem:** <what's wrong / missing>
- **Impact:** <user-facing / second-order consequence — why it's worth fixing>
- **Evidence:** <the spec quote or screen/flow that grounds the finding>
- **Resolution:** <exact language written to the spec> — or **Skipped:** <reason>
---
<repeat for EVERY finding, applied and skipped — nothing reduced to a count>

## Forks resolved
<TRADEOFF / UNCLEAR title → chosen option + one-line rationale> — omit the section if none
```
After the gate artifact, append load-bearing calls to the **decision log** (`<change-state-dir>/decisions.md`,
per `references/decision-log.md`): each **fork resolved** (TRADEOFF/UNCLEAR — the human's pick → `👤 human`)
and any **auto-applied 🔴 critical** (→ `🤖 design`) — one line + `More: design-review.md #<n>`. Don't
re-dump 🟠/🟡 findings; the review holds those.

Final one-line: "Done — N changes written, M skipped." List skipped numbers so nothing vanishes.

## Don't
- Never silently default to the most-recently-modified change.
- Never load the lens/auditor references in main context — sub-agent only.
- Never write files mid-loop — only in the commit step.
- Never auto-decide a fork the operator didn't answer (record skipped).
- Never edit vendor files (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
