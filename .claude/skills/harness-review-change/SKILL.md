---
name: harness:review-change
description: >-
  Reviews a code change through 13 lenses and four escalating stances (baseline → cross-cutting →
  adversarial-verify → docs-alignment) in one isolated reviewer-fixer sub-agent (doer ≠ judge), fixing
  clear no-trade-off findings and surfacing only decision-needing ones. One engine, three modes:
  `build-run` (harness:build's Step F.4 — this run's diff, autonomous, returns judge_findings for the
  run-log), `pre-ship` (harness:ship's pre-push gate — whole branch, thin, fork-card wizard), `operator`
  (bare invocation — self-review out-of-pipeline changes). Use when the user wants to review or
  self-review a change before shipping, or says "review this change", "self-review this branch",
  "critique my changes", "review before shipping", "pre-ship review", "/harness:review-change". Not
  for: reviewing someone else's PR (use the `code-review` skill), resolving existing PR review comments
  (use `harness:address-pr-comments`), or running the full PR submission workflow (use `harness:ship`).
argument-hint: "[build-run|pre-ship|operator] [change-name|scope]"
metadata:
  author: acatl
  version: "1.0.0" # x-release-please-version
---

# harness:review-change — one review engine, three altitudes

One review **mechanism** (13 lenses + four escalating stances), run in **one spawned reviewer-fixer
sub-agent** in a warm isolated context (doer ≠ judge — the judge cannot see the implementer's
reasoning). The same engine serves three callers via a **mode** parameter: `build-run` (build's
verify core), `pre-ship` (ship's pre-push gate), `operator` (manual, out-of-pipeline). The skill (main
context) owns mode-parsing, the operator wizard, and each caller's return contract. Large diffs may fan
out to N sub-agents.

> **Bindings.** Resolve from `docs/HARNESS.md`: rules dir (Paths — load-bearing guardrail), Sensors
> (final verification gate), Context docs › quality score (the judge rubric the reviewer grades
> against — resolve via the binding, never bundle). Never hardcode a lint/test/build command.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:review-change` followed by the mode/target this run has (e.g. ` · build-run · <change>`, ` · pre-ship`, ` · operator`).
- **end:** `■ harness:review-change v<hash8> → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable. `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status). A walk-me-through fork card is already the terminal block — reproduce its `Pick:` line verbatim; it needs no additional `👉`.

The review framework (13 lenses, Phase 0/1, severity taxonomy, `Category`/`Disposition`/`Fix class`,
return format) lives in `references/framework.md`. The four internal stances live in
`references/deep-stances.md`. Every single-pick decision renders as a pure-text fork card per
`references/walk-me-through.md` — **never** `AskUserQuestion` or any native picker. The pipeline "you
are here" trail follows `references/pipeline-map.md`.

---

## Modes (load-bearing)

**Mode = the first arg token** when it's exactly `build-run` / `pre-ship` / `operator`. Bare invocation
— **or an unrecognized first token** (e.g. a stray change-name) — → `operator` mode (treat the token as
the scope/target). The mode drives scope, depth, the clean-tree gate, the wizard-vs-fork behavior, and
the return contract — the engine itself is identical.

| Mode | Caller | Scope | Depth | Clean-tree gate | Fork behavior | Returns |
|------|--------|-------|-------|-----------------|---------------|---------|
| `build-run` | `harness:build` Step F.4 | this run's diff (`<change-name>`) | full¹ | **skip** (tree dirty by design — build commits per group) | design-stop → build's fork · **no wizard** | writes `<change-state-dir>/review-change-review.md` (+ `reviewed-range` footer) · returns `judge_findings` |
| `pre-ship` | `harness:ship` pre-push | whole branch `origin/main...HEAD` | **thin** (see below) | **no hard abort** (ship's `git add -A` sweeps); show diff summary | decision-needing → wizard | hands back to ship (ship commits) |
| `operator` | bare `/harness:review-change` | committed `origin/main...HEAD` **+ any uncommitted working-tree changes** | full¹ | **none** — reviewing uncommitted work is the point (review-before-commit); fixes blend into your WIP | decision-needing → wizard | summary + uncommitted-changes handoff |

¹ **full = all four stances _eligible_** — each runs only when its trigger surface is present (Adaptivity
› Scale depth to the diff); stage 3 short-circuits when stages 1–2 applied no fixes. "Full" ≠ "all four
always run" — a trivial single-surface diff may run only the baseline.

**`pre-ship` thin depth.** Stages 2–4 (cross-cutting, adversarial, docs-alignment) run over the
**whole branch always** — the cross-commit seams are exactly what per-run `build-run` review
structurally misses, and where the real bugs hide. Stage 1 (baseline lens sweep) is scoped to the
commits `build-run` never reviewed:
- Read each `<change-state-dir>/review-change-review.md` on the branch; take its `reviewed-range`
  footer. The **union** of reviewed ranges = already-lens-reviewed.
- `origin/main..HEAD` **minus** that union = baseline-priority commits (fine-tune commits, hand-edits,
  or a build that stopped before F.4 — none carry a reviewed-range).
- Do **not** use the commit `Tasks:` trailer as the signal — it marks _authored_, not _reviewed_, and
  misfires when a build stopped at a fork before F.4.
- **Fallbacks:** no review artifact on the branch → run full baseline (prioritize nothing). No / several
  change-state dirs → handle gracefully; never crash on a missing dir.

**`build-run` reviewed-range footer.** In `build-run`, stamp the review artifact with a provenance
footer `reviewed-range: <base>..<head>` (`<base>` = `origin/main` merge-base, `<head>` = `git rev-parse
HEAD` at review time) so `pre-ship` can compute the un-reviewed complement deterministically. Mirrors
`pr-body.md`'s `folded-against` footer.

---

## How it works

One **reviewer-fixer sub-agent** runs the whole review in a single warm context: gathers the diff once,
runs the stances back-to-back, applies clear fixes between stances, carries every prior finding in
memory. The skill (main agent) renders the summary + wizard (interactive modes) or writes the artifact
+ returns findings (build-run).

### Mode-branched pre-flight (clean working tree)

The reviewer-fixer **edits the working tree**, so how each mode treats uncommitted work differs:

- **`operator`** — **no hard gate.** Reviewing _current_ work **before committing** is a first-class use
  (a plain "review my code" moment). If the tree is dirty, **include the uncommitted (staged + unstaged)
  changes in scope** and say so (_"reviewing N committed + M uncommitted changes"_). The agent's clear
  fixes land on top of your working tree and **blend with your WIP by design** — you're about to review +
  commit the whole tree anyway. End with `git status --short` so your changes and the fixes are both
  visible before you commit. (Clean tree → just review the committed branch `origin/main..HEAD`.)
- **`pre-ship`** — **no hard abort, committed-only scope.** Review the committed range
  `origin/main..HEAD`; ship's Step 4 `git add -A` then sweeps the fixes + any mechanical stragglers
  (format pass, refreshed pr-body) into one atomic ship commit, and its diff-summary surfaces the mixing.
  (`operator` also reviews uncommitted work; `pre-ship` doesn't — we never want to ship a dirty tree, and
  ship commits everything itself.)
- **`build-run`** — **skip.** At build's Step F the tree is dirty by design (build commits per major
  group, may hold tail work). Build owns the tree; the agent's fixes land on top and build commits them.

### Topology

```text
Skill (main context) — parse mode → set scope · depth · clean-tree · fork · return
  │
  └── Spawn ONE reviewer-fixer sub-agent (warm context for the whole review)
        │  Gather bundle ONCE: Phase 0 + Phase 1 + diff (per mode scope) + source
        │  Gate: nothing in scope (no diverging commits; operator: none + clean tree) → STATUS: no-commits, stop.
        │  Stage 1 baseline       → fix clear · note decision-needing   (thin: scoped per above)
        │  Stage 2 cross-cutting  → (remembers S1; delta only) fix clear · note
        │  Stage 3 adversarial    → refute own fixes + residue sweep; fix regressions   (skip if no fixes)
        │  Stage 4 docs-alignment → whole-repo drift; fix clear · note
        │  build-run: NO final gate, NO commit — return.   pre-ship/operator: run final sensor gate.
        │  return: references/framework.md return format (preamble + per-finding blocks + refuted)
        │
  ├── Receive results
  ├── build-run → write artifact (+ reviewed-range footer) + return judge_findings to build
  └── pre-ship/operator → Output Format: auto-fixed table + fork-card wizard on the decision queue
```

The four stances live in `references/deep-stances.md`; the agent loads `references/framework.md` once
and applies each stance's lenses.

### Spawning the agent

Spawn **one** general sub-agent (able to edit files and, except in `build-run`, run the sensor gate).
The spawn prompt is **mode-aware** — say, in substance:

> You are the reviewer-fixer for a code-change review (**mode: `<mode>`**). Load and follow
> `references/framework.md` (13 lenses, severity taxonomy, `Category`/`Fix class`/`Disposition`, return
> format) and `references/deep-stances.md` (the four stances). Grade against the project's quality-score
> rubric (`docs/HARNESS.md` › Context docs). Review the change in scope: **`<scope for this mode>`**.
>
> Gather the diff and project context **once**, then run the eligible stances sequentially **in this
> single context**. Carry every finding in memory — **never re-report** a finding from an earlier
> stage; build on it. Apply `Fix class: clear` fixes to the working tree as you go, obeying every
> project rule loaded (`CLAUDE.md` + the rules dir in `docs/HARNESS.md` › Paths). **Never commit.**
> Return the structured format in `references/framework.md` (preamble + one block per finding, each
> tagged Severity + Lens + Category + Fix class + Disposition; plus a `refuted` block for
> considered-and-dropped concerns).

Mode-specific spawn-prompt additions:
- **`build-run`** — hand the agent build's **warm-context artifacts verbatim**: `surface-map.md`,
  `decisions.md`, the reviewed spec (`proposal.md`/`design.md`/`specs`). Tell it: "these decisions were
  already resolved deliberately — do not re-flag them as findings." **Autonomous:** apply clear fixes;
  a `decision-needing` finding is either `refuted` (with reason) or escalated to `design-stop` — there
  is **no wizard**. **Do NOT run the final sensor gate and do NOT commit** — build owns both. Stamp the
  `reviewed-range` footer in the returned artifact.
- **`pre-ship`** — thin scope per Modes above. Run the final sensor gate before returning. `queued`
  findings flow to the skill's wizard.
- **`operator`** — full depth, whole scope. Run the final sensor gate. `queued` findings → wizard.

The agent gathers data in batches (parallelism per the framework):
- **Batch 1** (parallel): `git fetch origin main && git log --oneline <scope>`; `git diff --name-only
  <scope>`; `openspec list --json`; read `CLAUDE.md`, the package manifest, `README.md` (Phase 0);
  in `build-run`, the handed build artifacts.
- **Gate**: nothing in scope — no diverging commits (and, in `operator` mode, no uncommitted changes) →
  return `STATUS: no-commits`, stop.
- **Batch 2** (parallel): `git diff <scope>` split by top-level directory; Phase 1 artifacts if OpenSpec
  changes detected.
- **Batch 3** (parallel): read full source files for context, batched by area.
- **Batch 4** (parallel): targeted grep/read verification for specific concerns.

Gathered **once**; stays in the agent's context for all stances.

### Model-A fix ownership (load-bearing)

The sub-agent **applies `clear` fixes to the working tree and returns — it never commits.** Who
commits + re-runs sensors depends on the mode:
- **`build-run`** — the agent does **not** run the final sensor gate and does **not** commit. **Build**
  commits the fixes (its own group/commit model) and re-runs its sensor gate — single source of truth
  for "sensors green after the fix" (what the run-log `fix_caused_regression` / `iterations_to_green`
  observe). **If a build-run fix touches runtime behavior, build must re-run behavioral-verify (F.2),
  not just sensors (F.1)** — a runtime fix invalidates the pre-fix behavioral verdict.
- **`pre-ship`** — the agent applies fixes + runs the final sensor gate; **ship** stages + commits them
  in its one atomic ship commit (Step 3).
- **`operator`** — the agent applies fixes + runs the final sensor gate; the **operator** commits (the
  uncommitted-changes handoff).

### Fix guardrails (the agent obeys these)

- **Clear → fix now.** One obvious correct resolution, no trade-off. Apply it; `Disposition: applied`
  with a `Fix note`.
- **Decision-needing → queue** (interactive modes) **/ refute or design-stop** (`build-run`). Never
  auto-fix a trade-off, scope question, or architectural call. When in doubt, decision-needing.
- **Load-bearing is never auto-fixed.** Any fix touching a scope-axis / load-bearing convention (per
  `CLAUDE.md` + the rules dir) is decision-needing regardless of how "clear" it looks.
- **No re-report.** All prior-stage findings live in context — the queue is already deduplicated.
- **Refute honestly.** A considered-and-dropped concern is a `refuted` block, not a silent drop — the
  run-log records honest refutation.

### Adaptivity (rigid ≠ dumb)

- **Short-circuit stage 3** — stages 1–2 applied **no** fixes → skip the adversarial stance (nothing to
  refute); note the skip.
- **Scale depth to the diff (proportional review).** Beyond the baseline, each stance runs only when its
  trigger surface is present — don't sweep a trivial diff four times:
  - **Stage 1 baseline** — always.
  - **Stage 2 cross-cutting** — only when the diff spans ≥2 files/layers or touches a contract/boundary;
    a single-file localized change has nothing to cross.
  - **Stage 3 adversarial** — per the short-circuit above (skip if stages 1–2 applied no fixes).
  - **Stage 4 docs-alignment** — only when the diff has a mechanical change (rename / renumber /
    signature / count / scope-flip) or touches docs; else nothing can have drifted.
  A tiny single-surface diff thus runs baseline only (plus adversarial iff it fixed something); a large
  branch trips every trigger and runs all four. This preserves the proportionality build's inline review
  had (_"small → one pass"_) inside the isolated-sub-agent model. **`pre-ship` is exempt for stages 2 & 4
  whole-branch** — the cross-commit seams are its whole point (see Modes › thin); its scaling is on the
  baseline scope, not on skipping 2/4.
- **Escape hatch** — a stance may add an ad-hoc lens for a surface none of the four cover (e.g. new
  infra); it must name the added lens in its findings.

### Final verification gate (pre-ship / operator only)

After stage 4, before returning, the agent runs the **sensors declared in `docs/HARNESS.md`** most
relevant to a code fix — typically `lint` → `test` (+ any `typecheck`), and `build` only if the diff
touches a build-sensitive surface — in declared order, scoped to affected code where tooling supports
it. (`build-run` skips this — build owns the gate.)
- **Green** → return.
- **Red** → a fix broke something. Treat each failure as a new adversarial finding: root-cause, fix (if
  clear) or queue (if decision-needing), re-run. Don't return a red gate unless the only red items are
  queued decision-needing findings — surface those at the top of the decision queue.

### What the agent returns

Per `references/framework.md` return format — preamble + one block per finding (both vocabularies) + a
`refuted` block. The skill then, per mode:
- **`build-run`** — write `<change-state-dir>/review-change-review.md` (findings + `reviewed-range`
  footer) and return the `judge_findings` triple (`{summary, category, disposition}` per finding) to
  build **verbatim** for its Step G.3 run-log row. No wizard, no operator handoff.
- **`pre-ship` / `operator`** — the **auto-fixed table** (from `Disposition: applied` blocks) as
  reporting; the **decision queue** (`Disposition: queued` + any `design-stop`) into the wizard below.
  If the queue is empty, skip the wizard; report the auto-fixed table + gate result + the mode's
  handoff.
  - **`pre-ship`** handoff: hand back to ship — "review clean, fixes staged for the ship commit" (clean)
    or the resolved decisions.
  - **`operator`** handoff: run `git status --short`, list modified files, tell the operator the
    auto-fixes are **uncommitted** — review + commit them. Never auto-commit. If the tree was **dirty
    going in** (review-before-commit), say so plainly: the listed files mix your pre-existing WIP with the
    agent's fixes — review the diff before committing. Only say "branch ready" when the tree is actually
    clean (nothing auto-fixed and no prior WIP).

---

## Output Format (interactive modes: `pre-ship` · `operator`)

_(`build-run` renders none of this — it returns findings to build. This section governs the two
wizard modes.)_

Two stages: a **static summary** (TL;DR + findings overview), then a **fork-card wizard** — one
decision-needing finding at a time, pure-text single-pick fork cards per `references/walk-me-through.md`,
**never** `AskUserQuestion`. Every finding gets a sequential `#N` index. "Findings" here = the decision
queue only; the auto-fixed table renders first, above the summary, as reporting. Severity taxonomy is in
`references/framework.md`.

### Stage 1: Static summary

Output only these — no commits list, no change-summary wall, no overall assessment yet. Readable in 30s.

#### TL;DR

One short paragraph (2–4 sentences): commits reviewed, files touched, finding counts per severity,
whether any blockers prevent shipping, how many clear fixes were auto-applied, the gate result.

Example: _"4 stances run; stage 3 short-circuited (no code fixes). 6 clear findings auto-fixed and
verified (sensors green). 2 decisions need your call."_

#### OpenSpec alignment

_(Only when Phase 1 detected active OpenSpec changes **with findings**. Omit if aligned or none.)_ For
each active change with findings, list grouped by category — **Spec gaps** / **Implementation exceeds
spec** / **Contradictions** / **Stale assumptions** / **Task completeness** — per `references/framework.md`
Phase 1, one line each.

#### Findings Overview

Bird's-eye table of every decision-queue finding — no decisions, just orientation. Ordered by severity
(Blockers → Warnings → Style), then `#`.

**If the decision queue is empty**, output instead — closing per the mode's handoff:

> No decisions needed.
> _pre-ship, review clean:_ Review clean — proceeding to push. _(fixes, if any, ride the ship commit.)_
> _operator, tree clean (nothing auto-fixed):_ Branch looks clean — ready to ship.
> _operator, auto-fixes uncommitted:_ Fixes applied and verified — commit them before `harness:ship`.

Then stop. Skip the wizard. (Still render the auto-fixed table + gate result above this line.)

| #   | Severity                           | Lens          | File            | Summary              |
| --- | ----------------------------------- | ------------- | ---------------- | --------------------- |
| N   | 🔴 Blocker / 🟠 Warning / 🟡 Style | `<lens name>` | `<file path>`   | `<one-line summary>` |

### Transition fork

After Stage 1, before the wizard, render one single-pick fork card (`references/walk-me-through.md`
shape — pure text, reply by letter):

```text
Q1 of 1: Ready to walk through the findings?

TLDR: N decision-needing findings queued — pick how much of the queue to walk now.
Why it matters: scopes the wizard; any severity you skip still ships with the branch.

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | All of them | full coverage before shipping | most time now |
| B | Blockers only | fastest unblock | Warnings/Style ship unreviewed |
| C | Blockers + Warnings | skips only Style | Style ships unreviewed |
| D | Show the change summary first | concept-level orientation before deciding | one extra step |

Recommendation: **A — All of them.** Cheapest point to catch issues is pre-ship, and N findings is a
small queue.
Cost if A: ~N cards, a few minutes.

Escape: E discuss / propose other.

Pick: A / B / C / D / E?
```

If the operator picks **D**: output the Change Summary (concept-level bullets derived from the diff,
max 5, verb-led past tense), then re-render this same fork card. Honor the scope pick throughout the
wizard — skip excluded severity levels entirely.

### Stage 2: Wizard

**Main agent runs this.** Do not re-fetch anything — render cards from reviewer results.

For each finding in scope (Blockers → Warnings → Style, respecting the scope pick), render one fork
card:

```text
#<N> of <total in scope> — <short summary> <🔴/🟠/🟡>

`<file path>` | Lens: <lens name>

TLDR: <what is wrong — be specific, not generic>
Why it matters: <impact — security, correctness, maintainability, data integrity, etc.>

Suggested fix: <concrete action to resolve — specific enough to act on>

Code context (L<start>–L<end>):
    <relevant lines — at least 5 before and after the flagged line>

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | <option name> | <terse pro> | <terse con> |
| B | <option name> | <terse pro> | <terse con> |

Recommendation: **<letter> — <option name>.** <one-line reasoning>
Cost if <letter>: <concrete>

Escape: <next-letter> discuss / propose other.

Pick: A / B / C / <escape-letter>?
```

**Option sets by severity** — fill the card's options table with the matching set below. The escape
letter always means "discuss later" (deferred to a post-wizard discussion) — do not add it as a lettered
row; it is the fork's built-in escape hatch.

**🔴 Blocker** — no "do nothing"; blockers prevent shipping by definition:

| #   | Option                  | Pros                     | Cons                |
| --- | ------------------------ | ------------------------- | -------------------- |
| A   | Fix now _(Recommended)_ | unblocks shipping         | adds time now        |
| B   | Revert the change        | fast path to clean state  | loses the work        |
| C   | Explain more              | full reasoning first       | —                     |

Escape (`D`): discuss later.

**🟠 Warning:**

| #   | Option                  | Pros                  | Cons                     |
| --- | ------------------------ | ----------------------- | -------------------------- |
| A   | Fix now _(Recommended)_ | ships clean              | adds scope to this PR      |
| B   | Defer                    | keeps PR focused         | risk ships temporarily     |
| C   | Accept risk               | no added scope           | technical debt accepted    |

Escape (`D`): discuss later.

**🟡 Style:**

| #   | Option                                | Pros                  | Cons                        |
| --- | -------------------------------------- | ----------------------- | ----------------------------- |
| A   | Fix now                                | clean from the start     | adds noise to the PR diff     |
| B   | Defer to separate PR _(Recommended)_  | keeps PR focused         | may never get done            |
| C   | Ignore                                  | no added scope           | inconsistency stays           |

Escape (`D`): discuss later.

The escape's free-text reply also serves "explain / why": present which lens flagged it, what the
reviewer verified, what would change the assessment, and any alternative interpretations considered —
then re-render the same card without recording a decision.

**After each reply:**

- **A/B/C (a decision, non-explain)**: Record the decision. Confirm in one line: _"Got it — #<N> →
  <option name>."_ Immediately move to the next card.
- **"Explain more" (Blocker option C, or `explain`/`why` via the escape)**: present which lens flagged
  it, what the reviewer verified, what would change the assessment, and any alternative interpretations
  considered — then **re-render the same card without recording a decision**.
- **Escape → free text (a decision)**: Ask them to type their decision. Record it. Confirm in one line
  and move on.
- **Escape → "discuss later"**: Add to the flagged list. Confirm: _"Flagged #<N> for discussion after
  the wizard."_ Move to the next card immediately.

Do not elaborate, re-explain, or offer follow-up on confirmed decisions. Momentum matters.

**Bulk decision shortcuts — between severity groups:**

After the **last Blocker card** (before starting Warnings), if Warnings are in scope, render:

```text
Blockers done. Handle Warnings one by one, or decide for all?

TLDR: N Warnings queued — pick per-item review or one bulk call for all of them.
Why it matters: a bulk pick applies the same decision to every remaining Warning.

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | One by one | per-item judgment | slower |
| B | Fix all Warnings now | ships clean | adds scope to this PR |
| C | Defer all Warnings | keeps PR focused | tracked as separate work |
| D | Accept risk on all Warnings | fastest | debt accepted across the board |

Recommendation: **A — One by one**, unless the Warnings are visibly homogeneous (same lens, same file
family) — then a bulk pick is safe.
Cost if A: N more cards.

Escape: E discuss / propose other.

Pick: A / B / C / D / E?
```

After the **last Warning card** (before starting Style), if Style findings are in scope, render the
same shape with options: One by one / Defer all to separate PR _(Recommended)_ / Ignore all / Fix all
now.

If the operator picks a bulk option, record that decision for all remaining findings in the group,
confirm in one line (_"Got it — all N Warnings → Defer."_), and move on.

**After the final card:**

If nothing was flagged → go directly to Decisions Summary.

If items were flagged → say:

> "Wizard complete. You flagged <#N, #M, …> for deeper discussion. Let's go through them now, one at a
> time."

For each flagged item: switch to **open conversation mode** (no fork card). Present the same card
again, then discuss until the operator arrives at a decision. Confirm before moving to the next.

### Decisions Summary

After all items are resolved (wizard + any discussion), show the consolidated outcome:

| #   | Severity | File     | Summary     | Decision    | How        |
| --- | -------- | -------- | ----------- | ----------- | ---------- |
| 1   | 🔴       | `<file>` | \<summary\> | **Fix now** | Wizard     |
| 2   | 🟠       | `<file>` | \<summary\> | **Defer**   | Discussion |

**How** values: Wizard · Bulk · Discussion

### Overall Assessment

Computed **after** decisions — reflects what the operator actually decided, not the raw findings. Count
auto-fixed clear findings as resolved.

|                       |                                                                   |
| --------------------- | ------------------------------------------------------------------ |
| Risk Level            | 🔴 High / 🟠 Medium / 🟡 Low                                      |
| Ship Recommendation   | Approve / Needs Revision / Block                                  |
| Findings              | N 🔴 N 🟠 N 🟡 (decision queue) + N auto-fixed                    |
| Deferred              | List any deferred or accepted-risk items — these ship with the PR |

**Risk derivation rules:**

- 🔴 High / Block: any Blocker not marked "Fix now" (deferred or accepted-risk)
- 🟠 Medium / Needs Revision: no unaddressed Blockers, but Warnings accepted as risk
- 🟡 Low / Approve: all Blockers fixed or reverted; Warnings either fixed or deferred (not
  accepted-risk)

### Action Plan

Organize "Fix now" decisions into **batches**. Omit if no "Fix now" decisions were made. (Clear
findings are already fixed — this plan covers only operator-approved fixes from the decision queue.)

**Batching rules:**

1. **Blockers first**: Blocker fixes form their own batch (or batches if they have internal
   dependencies).
2. **Dependencies**: If fixing A changes context for B, sequence them.
3. **Same-file grouping**: Independent fixes to the same file go in the same batch.
4. **Independent batches can run in parallel** via sub-agents.

**Format:**

#### Batch 1: \<short description\>

_Highest severity: 🔴_ | _Can parallel: Yes/No_

| #   | File | Change | Severity | From Lens |
| --- | ---- | ------ | -------- | --------- |
| 1   | ...  | ...    | 🔴       | Security  |

#### Batch 2: \<short description\> _(depends on Batch 1)_

_Highest severity: 🟠_ | _Can parallel: No — depends on Batch 1_

| #   | File | Change | Severity | From Lens |
| --- | ---- | ------ | -------- | --------- |
| ... | ...  | ...    | ...      | ...       |

After presenting the action plan, render one fork card:

```text
Ready to proceed?

TLDR: N batches of operator-approved fixes queued for implementation.
Why it matters: this is the last checkpoint before implementing them.

| # | Option | Pros | Cons |
|---|--------|------|------|
| A | Go — implement all batches in order | fully resolved before shipping | no partial checkpoint |
| B | Go, but skip [#] | ships everything else now | skipped items tracked separately |
| C | Just batch [N] | tightest scope | remaining batches still open |

Recommendation: **A — Go.** Unless a batch is risky enough to want isolated verification.
Cost if A: implements every listed change now.

Escape: D discuss / adjust first.

Pick: A / B / C / D?
```

**When the operator says "go" (or equivalent):** Proceed directly to implementation. Do not re-plan or
ask for further confirmation.

_(In `pre-ship` mode the resolved decisions hand back to ship, which commits them in the ship commit;
the wizard does not push. In `operator` mode approved fixes are applied to the working tree and left
uncommitted for the operator.)_

---

## Pipeline trail (`operator` mode)

`build-run` and `pre-ship` are internal to build/ship — those skills emit their own trail. In
**`operator`** mode, emit the "you are here" trail per `references/pipeline-map.md` at the end: `… ·
verify` on the done side, `▸ here` = branch clean (ready to ship) or fixes applied and uncommitted, `◦
next` = ship. The `Next:` line names the immediately-runnable action — commit the auto-fixes, then
`harness:ship` — and does **not** print `/harness:ship` while fixes sit uncommitted (one runnable
command rule); once the tree is clean, `harness:ship` is runnable now.

---

You are expected to be rigorous, precise, and thoughtful.

Do not overreact. Do not underreact.

Think like the engineer responsible for this codebase 2 years from now.
