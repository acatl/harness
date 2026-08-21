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
  version: "1.3.2" # x-release-please-version
---

# harness:review-change — one review engine, three altitudes

One review **mechanism** (13 lenses + four escalating stances), run in **one spawned reviewer-fixer
sub-agent** in a warm isolated context (doer ≠ judge — the judge cannot see the implementer's
reasoning). The same engine serves three callers via a **mode** parameter: `build-run` (build's / address-pr-comments 6b.2b's
verify core), `pre-ship` (ship's pre-push gate), `operator` (manual, out-of-pipeline). The skill (main
context) owns mode-parsing, the operator wizard, and each caller's return contract. Large diffs may fan
out to N sub-agents.

> **Bindings.** Resolve from `docs/HARNESS.md`: **default branch** (the review base —
> `origin/<default-branch>...HEAD`; never hardcode `main`), rules dir (Paths — load-bearing guardrail),
> Sensors (final verification gate), Context docs › quality score (the judge rubric the reviewer grades
> against — resolve via the binding, never bundle). Never hardcode a lint/test/build command.
> **Fork-card contract (hard dependency):** cards render per the co-shipped `walk-me-through`
> skill — resolve `../walk-me-through/references/walk-me-through.md` **from this skill's injected
> base directory** (never the project cwd). Installed alongside like OpenSpec; absent → stop and
> tell the operator to install `walk-me-through`, never improvise a card format.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:review-change` + the mode/target this run has (e.g. ` · build-run · <change>`, ` · pre-ship`, ` · operator`).
- **end:** `■ harness:review-change v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status). A walk-me-through fork card is already the terminal block — reproduce its `Pick:` line verbatim; it needs no additional `👉`.

The review framework (13 lenses, Phase 0/1, severity taxonomy, `Category`/`Disposition`/`Fix class`,
return format) lives in `references/framework.md`. The four internal stances live in
`references/deep-stances.md`. Every single-pick decision renders as a pure-text fork card per
`../walk-me-through/references/walk-me-through.md` — **never** `AskUserQuestion` or any native picker. Emit each card as
**live rendered markdown** (the table renders), **never** wrapped in a code fence — a fenced card shows
raw `|` pipes to the operator and breaks the interaction; the example cards below are written unfenced for
exactly this reason. The pipeline "you are here" trail follows `references/pipeline-map.md`.

---

## Modes (load-bearing)

**Mode = the first arg token** when it's exactly `build-run` / `pre-ship` / `operator`. Bare invocation
— **or an unrecognized first token** (e.g. a stray change-name) — → `operator` mode (treat the token as
the scope/target). The mode drives scope, depth, the clean-tree gate, the wizard-vs-fork behavior, and
the return contract — the engine itself is identical.

| Mode | Caller | Scope | Depth | Clean-tree gate | Fork behavior | Returns |
|------|--------|-------|-------|-----------------|---------------|---------|
| `build-run` | `harness:build` Step F.4 · `harness:address-pr-comments` 6b.2b | this run's diff (`<change-name>`) / from 6b.2b: the staged fix diff (`git diff --cached $START_SHA`; artifact only when the PR maps to a harness change, else return-only) | full¹ | **skip** (tree dirty by design — build commits per group) | design-stop → build's fork · **no wizard** | writes `<change-state-dir>/review-change-review.md` (+ `reviewed-range` footer); from 6b.2b: writes **`<change-state-dir>/pr-fix-review.md`** instead (+ `reviewed-scope` line, **never** `reviewed-range`) — a distinct artifact, so a fix-round pass never overwrites F.4's findings record and its footer · returns `judge_findings` + `files_touched` + `design_stops` (full finding blocks — the triple can't fill a fork card) |
| `pre-ship` | `harness:ship` pre-push | whole branch `origin/<default-branch>...HEAD` | **thin** (see below) | **no hard abort** (ship's `git add -A` sweeps); show diff summary | decision-needing → wizard | hands back to ship (ship commits) |
| `operator` | bare `/harness:review-change` | committed `origin/<default-branch>...HEAD` **+ any uncommitted working-tree changes** | full¹ | **none** — reviewing uncommitted work is the point (review-before-commit); fixes blend into your WIP | decision-needing → wizard | summary + uncommitted-changes handoff |

**Autonomous by default — every mode.** The review runs to completion without permission checkpoints:
clear fixes are applied, results reported (plus the final sensor gate in `pre-ship` / `operator` — in
`build-run` build owns that gate; see Final verification gate). Interactive modes stop only at:
a **genuine fork** (≥2 admissible resolutions, per `Fix class: decision-needing`) — one card per
finding; a **one-option consent gate** (a must-stop rule — `Load-bearing is never auto-fixed` — leaves
a single admissible repair; one-line apply-or-not — **`build-run` has no wizard: it escalates that
finding to `design-stop` and returns it in `design_stops`**, never refutes it); a **design-stop on invalid reviewer data** (queued
finding missing its `Admissible options:` block, the block is empty, its `Recommended option`
names no row in it, or its `Cost if recommended` describes a different row — `references/framework.md` › return format). Never ask whether to walk the
queue, whether to apply decisions already made, or whether to proceed to the next stage — those are
ceremony, not decisions, and the operator's answer is always the same. A ceremony stop — one carrying
no pick, no consent ask, no design-stop — → announce and continue; never read that as license to skip
a consent gate or a design-stop.

¹ **full = all four stances _eligible_** — each runs only when its trigger surface is present (Adaptivity
› Scale depth to the diff); stage 3 short-circuits when stages 1–2 applied no fixes. "Full" ≠ "all four
always run" — a trivial single-surface diff may run only the baseline.

**`pre-ship` thin depth.** Stages 2–4 (cross-cutting, adversarial, docs-alignment) run over the
**whole branch always** — the cross-commit seams are exactly what per-run `build-run` review
structurally misses, and where the real bugs hide. Stage 1 (baseline lens sweep) is scoped to the
commits `build-run` never reviewed:
- Read each `<change-state-dir>/review-change-review.md` on the branch; take its `reviewed-range`
  footer. The **union** of reviewed ranges = already-lens-reviewed.
- `origin/<default-branch>..HEAD` **minus** that union = baseline-priority commits (fine-tune commits, hand-edits,
  or a build that stopped before F.4 — none carry a reviewed-range).
- Do **not** use the commit `Tasks:` trailer as the signal — it marks _authored_, not _reviewed_, and
  misfires when a build stopped at a fork before F.4.
- **Fallbacks:** no review artifact on the branch → run full baseline (prioritize nothing). No / several
  change-state dirs → handle gracefully; never crash on a missing dir.

**`build-run` reviewed-range footer.** In `build-run`, stamp the review artifact with a provenance
footer `reviewed-range: <base>..<head>` (`<base>` = `origin/<default-branch>` merge-base, `<head>` = `git rev-parse
HEAD` at review time) so `pre-ship` can compute the un-reviewed complement deterministically. Mirrors
`pr-body.md`'s `folded-against` footer.
**From the 6b.2b caller (staged-fix diff) — NEVER stamp `reviewed-range`.** That pass inspected only
`git diff --cached $START_SHA`, not a commit range; a `reviewed-range: <merge-base>..HEAD` stamp would
feed pre-ship's complement math commits this pass never inspected. When the artifact is written at all,
write it to **`<change-state-dir>/pr-fix-review.md`** — never `review-change-review.md`, whose
`reviewed-range` footer and F.4 findings an overwrite would destroy (pre-ship would then re-review
already-reviewed commits and the F.4 record would be gone) — stamped `reviewed-scope: staged-fix diff
at <START_SHA> (no commit range — excluded from pre-ship complement)`. Pre-ship reads only
`review-change-review.md` and counts **only** `reviewed-range` footers — `pr-fix-review.md` never
enters the union.

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
  visible before you commit. (Clean tree → just review the committed branch `origin/<default-branch>..HEAD`.)
- **`pre-ship`** — **no hard abort, committed-only scope.** Review the committed range
  `origin/<default-branch>..HEAD`; ship's Step 4 `git add -A` then sweeps the fixes + any mechanical stragglers
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
        │  Gate (scope-aware) → STATUS: no-commits, stop: commit-range scope = no diverging commits (operator: none + clean tree);
        │        caller-provided non-commit scope (6b.2b staged fix diff) = git diff --cached --quiet <base> (non-empty staged diff IS in scope).
        │  Stage 1 baseline       → fix clear · note decision-needing   (thin: scoped per above)
        │  Stage 2 cross-cutting  → (remembers S1; delta only) fix clear · note
        │  Stage 3 adversarial    → refute own fixes + residue sweep; fix regressions   (skip if no fixes)
        │  Stage 4 docs-alignment → whole-repo drift; fix clear · note
        │  build-run: NO final gate, NO commit — return.   pre-ship/operator: run final sensor gate.
        │  return: references/framework.md return format (preamble + per-finding blocks + refuted)
        │
  ├── Receive results
  ├── build-run → write artifact (+ provenance footer per caller) + return judge_findings to build
  └── pre-ship/operator → Output Format: auto-fixed table + fork-card wizard on the decision queue
```

The four stances live in `references/deep-stances.md`; the agent loads `references/framework.md` once
and applies each stance's lenses.

### Spawning the agent

Spawn **one** general sub-agent (able to edit files and, except in `build-run`, run the sensor gate).
The spawn prompt is **mode-aware** — say, in substance:

> You are the reviewer-fixer for a code-change review (**mode: `<mode>`**). Load and follow
> `references/framework.md` (13 lenses, severity taxonomy, `Category`/`Fix class`/`Disposition`, return
> format) and `references/deep-stances.md` (the four stances). The walk-me-through fork-card contract is
> at **`<abs path, resolved by the orchestrator from ../walk-me-through/references/walk-me-through.md>`**
> — read it for option admissibility. Grade against the project's quality-score
> rubric (`docs/HARNESS.md` › Context docs). Review the change in scope: **`<scope for this mode>`**.
>
> Gather the diff and project context **once**, then run the eligible stances sequentially **in this
> single context**. Carry every finding in memory — **never re-report** a finding from an earlier
> stage; build on it. Apply `Fix class: clear` fixes to the working tree as you go, obeying every
> project rule loaded (`CLAUDE.md` + the rules dir in `docs/HARNESS.md` › Paths). **Never commit.**
> **Edit only the files a finding names** (plus its pinning test) — no repo-wide sweeps, no untouched
> surfaces. **No destructive operations** (`git reset --hard` / `checkout --` / `clean`, `rm -rf`,
> deleting branches or stashes). **Network only for** the Batch 1 `git fetch origin <default-branch>`
> (required — a stale base ref reviews the wrong delta) and whatever the declared sensors do
> themselves. Rationale: the tree may hold the operator's uncommitted work, and losing it is
> unrecoverable.
> Return the structured format in `references/framework.md` (preamble + one block per finding, each
> tagged Severity + Lens + Category + Fix class + Disposition; plus a `refuted` block for
> considered-and-dropped concerns).

Mode-specific spawn-prompt additions:
- **`build-run`** — hand the agent build's **warm-context artifacts verbatim**: `surface-map.md`,
  `decisions.md`, the reviewed spec (`proposal.md`/`design.md`/`specs`). Tell it: "these decisions were
  already resolved deliberately — do not re-flag them as findings." **From `address-pr-comments`
  6b.2b** those artifacts don't exist — hand the caller's Phase-3 standards summary + 4c fix plans +
  its two focus hints instead; same autonomy, same no-gate/no-commit rules; skip the artifact when the
  caller passed return-only. **Autonomous:** apply clear fixes;
  a `decision-needing` finding is either `refuted` (with reason) or escalated to `design-stop` — there
  is **no wizard**. **Do NOT run the final sensor gate and do NOT commit** — build owns both. Stamp the
  `reviewed-range` footer in the returned artifact (from 6b.2b: the `reviewed-scope` line instead,
  never `reviewed-range` — Modes › reviewed-range footer).
- **`pre-ship`** — thin scope per Modes above. Run the final sensor gate before returning. `queued`
  findings flow to the skill's wizard.
- **`operator`** — full depth, whole scope. Run the final sensor gate. `queued` findings → wizard.

The agent gathers data in batches (parallelism per the framework):
- **Batch 1** (parallel): `git fetch origin <default-branch> && git log --oneline <scope>`; `git diff --name-only
  <scope>`; `openspec list --json`; read `CLAUDE.md`, the package manifest, `README.md` (Phase 0);
  in `build-run`, the handed build artifacts. **Caller-provided non-commit scope** (6b.2b's staged fix
  diff): **skip `git log`** — no commits exist by construction (Gate below) and the range form is
  ill-formed against a `git diff --cached` scope; the name list is `git diff --cached --name-only <base>`.
- **Gate** (scope-aware): nothing in scope → return `STATUS: no-commits` (token unchanged across
  scopes — callers branch on it), stop. **Commit-range scope** (build's F.4 · `pre-ship` · `operator`):
  no commits diverge from `origin/<default-branch>` (and, in `operator` mode, no uncommitted
  working-tree changes either). **Caller-provided non-commit scope** (6b.2b's staged fix diff):
  emptiness is `git diff --cached --quiet <base>` — a non-empty staged diff **IS** in scope; never test
  it with `git log <base>..HEAD`, which is empty by construction there (6b.2b runs pre-commit;
  Phase 1.5 guarantees `HEAD == START_SHA == origin/<branch>`) and would no-op the mandatory pass.
- **Batch 2** (parallel): `git diff <scope>` (**non-commit scope:** `git diff --cached <base>`) split by
  top-level directory; Phase 1 artifacts if OpenSpec changes detected.
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
- **Edits stay inside the finding's blast radius.** A fix touches only the files the finding names (plus
  the test that pins it). Autonomy is over _what_ to fix, never over _how far_ to reach: a repo-wide
  sweep, a refactor of untouched files, or a fix in a surface no finding flagged is out of bounds — that
  is a decision-needing scope question, not a clear fix.
- **Non-destructive, no side channels.** The agent edits files and runs the declared sensors. It never
  runs destructive git or filesystem operations (`reset --hard`, `checkout --` over operator work,
  `clean`, `rm -rf`, branch/stash deletion), never commits or pushes (Model-A fix ownership), and makes
  no network calls beyond the **Batch 1 base-branch `git fetch`** (required — reviewing against a stale
  `origin/<default-branch>` reads the wrong delta) and what the sensors themselves do. Read-only git
  (`log` / `diff` / `rev-parse`) is gathering, not a side channel. Reviewing uncommitted work (`operator` mode)
  means the operator's WIP is in the tree — destroying it is unrecoverable, and no finding justifies it.
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
  footer; from 6b.2b: `<change-state-dir>/pr-fix-review.md` with `reviewed-scope`, never
  `reviewed-range`) and return **`judge_findings` + `files_touched` + `design_stops`**:
  - `judge_findings` — the triple (`{summary, category, disposition}` per finding) to build
    **verbatim** for its Step G.3 run-log row.
  - `files_touched` — the preamble's `Files fixed` list (`references/framework.md` › return format)
    verbatim: every path the reviewer-fixer wrote to, `[]` when none. Load-bearing — the fixes are
    **uncommitted working-tree edits** and the caller stages them (`harness:address-pr-comments`
    6b.2b → `FIX_SET`); omitted, they reach the caller's post-commit reconciliation unowned, bucket
    at b5, and abort the run.
  - `design_stops` — for **every** finding with `Disposition: design-stop`, its **full
    `references/framework.md` finding block verbatim** (File / Summary / Issue / Why it matters /
    Suggested fix / Admissible options / Recommended option / Cost if recommended / Code context);
    `[]` when none. **A one-option must-stop block is legal here** (`Load-bearing is never
    auto-fixed` leaves a single admissible repair): carry the single option — the caller renders it
    as a consent gate, not a card. `framework.md`'s "never a design-stop" scopes to the interactive
    modes, which have a wizard; `build-run` does not, so this is that finding's only route out.
    **Load-bearing** — the caller renders these (the ≥2-option ones) as fork cards
    (`harness:address-pr-comments` 6b.1) and the `judge_findings` triple
    (`{summary, category, disposition}`) **cannot fill one**: no `File L<line>`, no `Admissible
    options` with their executable outcomes, no `Recommended option`, no `Cost if recommended`. On the
    **return-only** path (6b.2b when the PR maps to no harness change with a `harness/` dir) **no
    artifact is written**, so this return is the caller's only channel for the block. Purely
    **additive**: `judge_findings`' shape is unchanged — build's Step G.3 folds it verbatim into the
    run-log and the run-log schema (`harness-runs.SCHEMA.md`) pins its disposition enum.

  No wizard, no operator handoff.
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
decision-needing finding at a time, pure-text single-pick fork cards per `../walk-me-through/references/walk-me-through.md`,
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

### No transition fork

**Never ask "ready to walk through the findings?" or offer a queue-scope pick.** Stage 1 → Stage 2
directly, walking the **whole** queue (Blockers → Warnings → Style). Reaching the wizard at all means
genuine forks exist; asking permission to ask them is a stop with no decision in it (the answer is
always "all"). The only stops in interactive modes: the **finding fork cards** — each a real
≥2-admissible-option pick, one per finding — plus the **one-option consent gates** (must-stop rule,
single admissible repair), the **design-stops on invalid reviewer data** (missing or empty
`Admissible options:` block, a `Recommended option` naming no row, or a `Cost if recommended` describing a
different row), and the flagged-item discussion
the operator opts into.

Announce instead, one line, then start card #1: _"N decisions need your call — walking them now,
Blockers first."_

### Stage 2: Wizard

**Main agent runs this.** Do not re-fetch anything — render cards from reviewer results.

For each queued finding (Blockers → Warnings → Style — the whole queue), render one fork card:

**Two independent indices — never one placeholder for both.** `Q<C> of <total cards>` is the card's
position in the wizard (C = how many cards rendered so far; total = the queued findings that will
render fork cards — one-option consent gates render as `👉` lines, not cards, so they are **excluded
from the count** while still walked in queue order and recorded in the Decisions Summary); `Finding #<F>` is the
finding's own number from Stage 1. They coincide only by accident (skips, re-renders, non-contiguous
finding numbers) — compute each separately, and record decisions against `#<F>`, never against `Q<C>`.

Q<C> of <total cards> — Finding #<F>: <short summary> <🔴/🟠/🟡>

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

_(rows = this finding's `Admissible options:` from the reviewer — two shown as the minimum, not a fixed count)_

Recommendation: **<letter> — <option name>.** <one-line reasoning>
Cost if <letter>: <concrete>

Escape: <next-letter> discuss / propose other.

Pick: <each lettered option, slash-separated> / <escape-letter>?

**Options are DERIVED per finding — there is no per-severity option set.** Enumerate the resolutions
this specific finding actually admits, then gate each through `../walk-me-through/references/walk-me-through.md` ›
Admissibility (live · non-dominated · value-positive · terminal, plus the standing bans). Never paste a
generic ladder (`Fix now / Defer / Accept risk / Ignore / Revert / Explain more`) — those rows are
pre-written, so they cannot be live for _this_ finding, and four of them are standing-banned. The escape
carries the **next free letter** — `../walk-me-through/references/walk-me-through.md` › Rules requires it
so `Pick:` can name it — but is **never a table row**. Its letter is a channel, not a disposition: the
reply dispatches per **After each reply** below — `explain` / `why` → re-render the same card, record
nothing · free text naming a resolution → record it as given (open form when non-terminal) · explicit
"discuss later" → the flagged list, walked after the wizard.

**Render the options the reviewer returned.** Each queued finding carries an `Admissible options:`
block (`references/framework.md` › return format) — the resolutions the reviewer weighed when it
classified the finding `decision-needing`. Those are the card's rows. Stage 2 forbids re-fetching, so
re-deriving rows here from an abbreviated code excerpt is exactly the invention this gate exists to
stop. A queued finding that arrives without the block, **with an empty one**, with a `Recommended option`
naming no row in it, or with a `Cost if recommended` describing a different row is a **reviewer contract violation** — surface it as a design-stop, don't fabricate
rows for it.

Typical shape of a **real** decision queue entry: `A` = the fix the reviewer proposes · `B` = a
materially different fix (different mechanism, different blast radius, different thing preserved) ·
`C` = `Decline — <why the finding is wrong>`, present only when declining is defensible on the merits.

**Severity constrains what can be admissible — it does not supply the rows:**

| Severity | Constraint |
|---|---|
| 🔴 Blocker | no do-nothing row — a Blocker prevents shipping by definition. `Decline — <why the finding is wrong>` stays admissible when defensible on the merits (a refuted Blocker is a reviewer misfire, not a shipped defect — Risk derivation rules). `Revert` only when the finding indicts the change's **premise**, not a fixable part of it |
| 🟠 Warning | `Defer` only under a concrete blocker (external decision · blocking upstream · separate spec) **or as a recorded terminal disposition** (the row's whole content is a durable written record — `walk-me-through.md` › standing bans, carve-out b) — never for scope, PR focus, or size |
| 🟡 Style | same bar. "Adds noise to the diff" is not a reason to defer; in-branch findings get fixed in the branch |

**The queue is whatever the reviewer classified `decision-needing`** — this gate shapes the rows a card
offers, it does not re-triage findings. A queued finding whose `Admissible options:` collapses to one row
is a **reviewer contract violation** — surface it as a design-stop — **unless a must-stop rule forced the
stop** (`Load-bearing is never auto-fixed`), which legitimately yields one option: render the one-option
consent gate (`../walk-me-through/references/walk-me-through.md`), one line, apply-or-not. Yes → apply, record
`How: Consent`. **No → the finding stays OPEN** — denial rejects the repair, not the finding; record it
unaddressed in the Decisions Summary and Overall Assessment, never as resolved. Never fabricate a second
row; never silently auto-apply.

**After each reply:**

- **A lettered pick (a decision)**: Record the decision. Confirm in one line: _"Got it — #<F> →
  <option name>."_ Immediately move to the next card.
- **`explain` / `why` via the escape**: present which lens flagged it, what the reviewer verified, what
  would change the assessment, and any alternative interpretations considered — then **re-render the
  same card without recording a decision**.
- **Escape → free text (a decision)**: Record it as given — the operator's own call is not gated by
  admissibility (`../walk-me-through/references/walk-me-through.md` › Scope of the gate), and re-rendering to make them
  answer again is a ceremony fork. **A non-terminal or do-nothing outcome is recorded as what it is:**
  the finding stays **open** in the Decisions Summary (`Decision: **Open — <what they said>**`, the summary's open form — never "resolved"), and
  the Overall Assessment counts it unaddressed. Confirm in one line and move on. Re-render the card
  **only** when the reply names no resolution at all.
- **Escape → "discuss later"**: Add to the flagged list. Confirm: _"Flagged #<F> for discussion after
  the wizard."_ Move to the next card immediately.

Do not elaborate, re-explain, or offer follow-up on confirmed decisions. Momentum matters.

**No bulk shortcut, no merged cards.** Walk every queued finding as its own card. Never ask "one by
one, or all at once?" — queue scope is not a resolution and is banned outright
(`../walk-me-through/references/walk-me-through.md` › Never a fork at all · Terminal).

**After the final card:**

If nothing was flagged → go directly to Decisions Summary.

If items were flagged → say:

> "Wizard complete. You flagged <#F, #G, …> for deeper discussion. Let's go through them now, one at a
> time."

For each flagged item: switch to **open conversation mode** (no fork card). Present the same card
again, then discuss until the operator arrives at a decision. Confirm before moving to the next.

### Decisions Summary

After every queued item has been walked (wizard + any discussion), show the consolidated outcome:

| #   | Severity | File     | Summary     | Decision                                 | How        |
| --- | -------- | -------- | ----------- | ---------------------------------------- | ---------- |
| F   | 🔴       | `<file>` | \<summary\> | **\<picked option name\>**               | Wizard     |
| G   | 🟠       | `<file>` | \<summary\> | **Open — \<repair declined \| what they said\>** | Consent |

**Decision** = the picked option's name (the derived row, verbatim), the operator's own escape-provided
resolution as given (recorded per After each reply; How: Discussion), or the open form
`**Open — <repair declined | what they said>**`, legal only with How: Consent (denied repair) or
How: Discussion (non-terminal / do-nothing escape reply). An open row stays unresolved and counts
unaddressed in the Overall Assessment.
**How** values: Wizard · Consent · Discussion

### Overall Assessment

Computed **after** decisions — reflects what the operator actually decided, not the raw findings. Count
auto-fixed clear findings as resolved.

|                       |                                                                   |
| --------------------- | ------------------------------------------------------------------ |
| Risk Level            | 🔴 High / 🟠 Medium / 🟡 Low                                      |
| Ship Recommendation   | Approve / Needs Revision / Block                                  |
| Findings              | N 🔴 N 🟠 N 🟡 (decision queue) + N auto-fixed                    |
| Not fixed             | List declined, deferred, and open items — these ship with the PR  |

**Risk derivation rules** — classify each decision by its resolution's executable outcome (the picked
row, or the operator's escape-provided call): **write**
(the pick edits the tree — a fix, a revert, a pinning test) · **declined on merits** (the operator
adjudicated the finding wrong — `Decline — <why the finding is wrong>`; **resolved, not unaddressed**:
a refuted Blocker must not force Block, else a reviewer misfire can never yield Approve, and the
summary would contradict "reflects what the operator actually decided" — it still lists under _Not
fixed_ so the call stays visible) vs **unaddressed** (deferred under a carve-out · **open**: denied
consent, or a non-terminal / do-nothing escape reply):

- 🔴 High / Block: any Blocker with an unaddressed outcome — deferred or open
- 🟠 Medium / Needs Revision: every Blocker resolved (write or declined on merits), but ≥1 Warning
  **open** (deferred under a carve-out ≠ open — the Warning severity row admits it; never drives
  Needs Revision)
- 🟡 Low / Approve: every Blocker resolved, every Warning resolved or deferred under a carve-out —
  write outcome, declined on merits, auto-fixed, or (Warnings only) deferred; Style outcomes never gate

### Action Plan

Organize every decision whose resolution — picked row or escape-provided fix — carries a **write**
executable outcome into **batches** — the batch executes exactly that outcome. Omit if no decision
carries a write outcome. (Clear findings are already fixed and consent-approved repairs were applied at
the gate — neither re-enters; this plan covers only operator-approved decisions from the queue; open /
declined / deferred decisions never enter a batch.)

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

**No "ready to proceed?" confirm.** Each fix in the plan was already picked by the operator, card
by card — re-confirming the batch asks the same question twice. Print the plan as an announcement and
**implement immediately** — dependent batches in their sequenced order, independent batches in parallel
per Batching rule 4. Do not re-plan, do not ask.

**Re-validate each remaining fix against the tree as its batch starts** — an earlier batch changed the
same files, so a queued fix can already be resolved or no longer fit. Already resolved → `Disposition:
applied` with a `Fix note` naming the batch that resolved it, and skip the edit (never re-apply); still
valid but the surface moved → adjust the fix to the current code. **Not `refuted`** — the finding was
real and is now fixed; `refuted` means considered-and-rejected (`references/framework.md` › Disposition)
and using it here would skew the run-log optimistic. This re-checks the _fix_, not the operator's
decision — it is not re-planning and never re-asks.

**Any re-validation change makes the already-rendered outcome stale** (Decisions Summary + Overall
Assessment print before this plan). After execution, emit a short **delta** — only the affected rows,
their corrected disposition, and the updated counts — not a re-render of the whole outcome. No change →
emit nothing.

The only stop after the plan: a batch turns out to need a decision the wizard didn't cover (a fix has no
single correct shape, or it reaches a scope-axis surface) → render that as its own fork card, resolve,
continue.

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
