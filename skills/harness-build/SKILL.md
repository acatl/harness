---
name: harness:build
description: >-
  The workhorse: take a task (or an existing OpenSpec change) all the way to a verified, ready-to-ship
  change — author the spec if none exists (proposal → recon → design → reviews → tasks), then implement
  it with surface mapping, convention pre-load, parallel execution, per-task + sensor verification,
  behavioral verification, and spec-conformance check. Stops at "verified, NOT shipped" — shipping is a
  separate, deliberate step. Use when the user wants to build/implement a tracked task or change end to
  end. Triggers on "build this", "/harness:build", "implement this task", "spec and build this", "take
  this to apply-ready and implement", "run the change". Default mode is gated (stops to let you review
  the spec before code); pass `yolo` to run straight through. Both stop at genuine forks. Auto-detects
  whether to author a new change or resume an existing one. Calls harness:recon, harness:architecture,
  harness:design, and the vendor openspec-verify-change.
argument-hint: "[change-name | idea] [yolo]"
metadata:
  author: acatl
  version: "0.2.0" # x-release-please-version
---

# harness:build — task → verified change (stop before ship)

One skill, full cycle. Authors the spec (if none) **+** implements it, verified. **Ends at
verified-not-shipped** — never pushes, never opens a PR (that's `harness:ship`).

> **Bindings.** Resolve from `docs/HARNESS.md`: sensors, task-tracker verbs + stage hooks, rules dir,
> change-state dir, run-log path, runtime-verification recipe, context docs. Never hardcode a command,
> path, or convention. `Co-Authored-By` trailer per environment.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:build` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:build v<hash8> → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable. `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

## Modes
- **gated** (default): stops at the **H2 spec-review gate** (after tasks, before impl) and loops
  "ready?" until you approve or request edits; restores the impl **plan-approval gate** (`ExitPlanMode`)
  and **stop-on-failure** during execution.
- **yolo**: skips H2; plan printed not gated; apply-caused verification failures fixed + re-verified
  (not halted). **Both modes stop at genuine forks.**
- **Reviews always run autonomous** inside build (auto-apply unambiguous findings, stop on their own
  forks). Build's mode does not forward to reviews — the operator reviews the fully-reviewed spec once
  at H2. (For per-finding review control, run `harness:architecture`/`harness:design` standalone first.)
- Detect: trailing standalone `yolo`/`--yolo` (any case) → yolo, stripped; rest = change-name/idea.
  `yolo` substring inside a name ≠ token. Natural-language idea carve-out: bare trailing `yolo` selects
  mode only when preceded by empty/single token; trailing a multi-word idea → stays part of idea, use
  `--yolo`. Echo parsed interpretation (mode + derived id) for a multi-word idea before creating
  anything. No token → gated.

## Spec mode (orthogonal to gated/yolo)
`spec_mode ∈ {full (default), spec-less}` — independent of gated/yolo. **full** authors the OpenSpec
spec (proposal → recon → design → `specs/` → heavy reviews → tasks). **spec-less** skips the `specs/`
delta only — for a small change that alters no spec-worthy behavior (`references/triage-lenses.md`);
it still authors proposal + a lean design + tasks and keeps sensors, a review, behavioral-verify, ship.
Default is **full**; spec-less is opt-in.
- **Source (AUTHOR path):** an explicit `--spec-less` token in the invocation, or the mode carried from
  `harness:refine`'s `Next:` pointer. No signal → **full**.
- **Marker (deterministic single source of truth):** on the AUTHOR path build **writes**
  `<change-state-dir>/spec-mode` — one line `spec_mode: spec-less` — at Step 0, **before** Step A,
  **only when the resolved mode is `spec-less`**. A **full** change writes **no marker** — the reader
  rule's `absent ⇒ full` default covers it, so full PRs carry no new artifact (marker *presence* ⇒
  spec-less). Written once; only the Step E escalation tripwire rewrites it (`spec-less → full`, which
  reads as full — identical to absent).
- **Reader rule (everywhere, incl. IMPL/resume, finish, status):** read `<change-state-dir>/spec-mode`;
  treat as **spec-less only if the file exists and literally says `spec-less`** — absent, empty,
  unreadable, or `full` ⇒ **full**. On IMPL/resume build does **not** write the marker (reads it). This
  default-to-full rule keeps every legacy / full / mid-authoring change byte-for-byte unaffected.
- **What spec-less changes (each a guarded branch; full/absent runs the step VERBATIM):** Step A drops
  `specs` from the artifacts to author · Step B/C runs the inline spec-less review
  (`references/spec-less-review.md`) vs `design.md` in place of the heavy reviews — **and, when blast
  radius / load-bearing surface warrants (`references/triage-lenses.md` › review depth), ALSO runs the
  heavy `harness:architecture` review** (review depth is independent of spec-mode) · Step E arms the
  escalation tripwire · Step F never calls `openspec validate --strict` (vendor verify degrades) ·
  Step G logs `spec_mode` + `verify_gaps=null`.

## Genuine forks — stop in BOTH modes (union of authoring + impl)
- **Start-state ambiguity** (Step 0): >1 open change and which-one is genuinely ambiguous.
- **Critically-unclear artifact context** (Author): can't author a section without an operator-only
  decision. Prefer reasonable defaults; stop only when genuinely missing, not merely thin.
- **A review fork** (Reviews): any review hits its own fork (tradeoff/unclear/options) → surfaces
  mid-chain; answer it, the review continues.
- **Design gap mid-task** (Impl): spec didn't anticipate a case / conflicts with the codebase / left a
  decision unresolved → offer "update the spec now" vs "log in `<change-state-dir>/decisions.md`".
- **Verification failure whose fix needs a standard / public contract / design decision** (Impl).
- Everything else (which reviews, applying unambiguous findings, generating tasks, clear-correct fixes)
  proceeds without a stop.

## Asking the user to choose between options
Pick-between-alternatives (not yes/no): render a walk-me-through fork card (`references/walk-me-through.md`)
— one per turn, `Q<N> of <total>`, TLDR + why-it-matters + options table (terse Pros/Cons) + grounded
Recommendation + `Cost if` + `Escape:` + `Pick:`; operator replies by letter. **Never `AskUserQuestion`
or any native picker.** Yes/no gates (H2, plan-approval) and plain selections stay one line.

---

## Step 0 — Resolve change + auto-detect start state
1. Parse args (gated/yolo + change-name/idea per the carve-out above). **Also parse `spec_mode`:** a
   `--spec-less` token (stripped like `--yolo`), or the mode carried from a `harness:refine` handoff;
   else `full`. (Orthogonal to gated/yolo — see **Spec mode**.)
2. **Resolve the change id.** Passed name/idea → derive a kebab-case id (never pass a sentence to the
   CLI). Inferred from conversation (build runs after `harness:explore`/`harness:refine`) → echo a
   one-line confirmation before creating anything. Else ask once, derive kebab.
3. **Detect start state** via `openspec list --json` + `openspec status --change "<name>" --json`:
   - No change dir for `<name>` → **AUTHOR** (Step A).
   - Change exists, authoring incomplete (spec gates not all `done`/`ready`) → **AUTHOR (resume)** —
     Step A's loop skips `done` artifacts.
   - Change exists, apply-ready or in-progress (`HELD`/tasks present) → **IMPL** (Step E) — skip authoring.
   - `state: all_done` → congratulate, suggest `harness:finish`, stop.
   - >1 open change and ambiguous which → walk-me-through fork card pick (open/non-archived only). Never guess.
4. **Write the spec-mode marker (AUTHOR path, spec-less only), before Step A.** If the resolved mode is
   `spec-less`, write `<change-state-dir>/spec-mode` = `spec_mode: spec-less`. If **full**, write
   **nothing** (absent ⇒ full, per the **Spec mode** reader rule). On the IMPL/resume path do **not**
   write it — read it. Then announce `Using change: <name>` (+ resolved `spec_mode`) + how to override.
5. **Task tracker:** `start` verb (HARNESS.md › Task tracker) — move to in-progress; fire the
   `building` stage hook. No-op if not configured / no linked task.
6. **Progress file:** read `<change-state-dir>/progress.md` if present → resume where build left off
   (which phase, which groups done). Create/update it as phases complete.

---

## Step A — Author the spec (AUTHOR path only; stop before tasks)
Drive the OpenSpec artifact loop directly (not `ff`) — hold the terminal checklist (`HELD`) back until
after reviews so it derives from the reviewed spec.

1. Create if absent: `openspec new change "<name>"`.
2. `openspec status --change "<name>" --json` → `applyRequires` + per-artifact `id`/`outputPath`/
   `status`(done/ready/blocked)/`missingDeps`. No static dependency list — derive from status + missingDeps.
3. **Identify `HELD`:** terminal gate = no other `applyRequires` gate lists it in its `missingDeps`.
   `HELD` = terminal gates **minus** spec-content artifacts (`proposal`/`design`/`specs` — reviews need
   them, never hold). Default schema: `applyRequires=["tasks"]`, `HELD=tasks`. Fallback: the gate whose
   `outputPath` is the task list. Determinism: **0** terminals → `HELD` empty, note the
   derive-from-reviewed-spec guarantee is N/A, skip Step D. **1** → normal. **N** → hold + later
   generate all members.
4. **Author proposal first**, then **recon**, then the rest:
   - Author `proposal.md` (the `proposal` prerequisite) via `openspec instructions proposal --change
     "<name>" --json`; author from `template`; apply `context`/`rules` as constraints, never copy those
     blocks into the file.
   - **Wire recon:** invoke `harness:recon` with `<name>` (writes prior-art verdicts into `proposal.md`
     + evidence to `<change-state-dir>/recon.md`). This is the gap-fix — author proposal → recon →
     design.
   - **Author remaining prerequisites loop:** run `status`; needed = `missingDeps` of not-yet-ready
     `applyRequires` gates (transitive). **Spec-less guard:** if `spec_mode = spec-less`, remove `specs`
     from `needed` — never author a `specs/` delta (keep proposal · a lean `design` · tasks). **Consequence
     (verified):** with `specs` un-authored, the HELD checklist (`tasks`) stays `blocked` on `specs` — this
     is the **intended** spec-less state, **not** a failure. Stop the author loop once the non-`specs`
     prerequisites (proposal, design) are `ready`/`done` — do **not** wait for `tasks` to leave `blocked`.
     Step D then generates `tasks` **directly** (the `openspec instructions tasks` generator emits its
     template despite the `blocked`-on-`specs` status — confirmed; writing `tasks.md` flips it to `done` →
     apply-ready, `applyRequires` = `tasks` only). **full/absent:** `needed` and the `ready`/`blocked`
     handling are exactly as derived above — no change.
     Author every artifact that is `ready` AND needed AND **not in
     `HELD`** via `openspec instructions <id> --json` (read the dependency files it reports; author from
     `template`). Re-run `status`, repeat. **Stop when every `HELD` member is `ready`/`done`** (spec-less:
     when the non-`specs` prerequisites are, per the guard above). Do not author any `HELD` member (Step D).
   - Artifacts never in any gate's `missingDeps` (optional/post-apply/archive) are not apply-readiness
     inputs — don't author/block on them.
   - Critically-unclear artifact → fork (prefer a reasonable default over stopping when merely thin).
   - **Permanent-gap detection:** each pass authors ≥1 artifact; a zero-author pass while some `HELD`
     member is still not `ready`/`done` = fixed point (missing dep / cycle) → stop + surface the
     still-blocked artifacts with their `missingDeps`. **Spec-less exception:** a HELD `tasks` left
     `blocked` **solely on `specs`** (the intentionally-skipped artifact) is **not** a fixed-point failure —
     it's the intended spec-less state; proceed to Step D. No retry counter.

## Step B — Classify surface + route (AUTHOR path)
**Spec-less guard (`spec_mode = spec-less`):** skip the heavy-review *routing* below; run the
**inline spec-less review** (`references/spec-less-review.md`) against `proposal.md` + `design.md` (the
plan is the contract — there is no `specs/`). It self-scales to the diff, auto-applies unambiguous fixes,
stops on genuine forks, and writes `<change-state-dir>/spec-less-review.md` (same durable shape as the
heavy review artifacts). **Review depth (independent of spec-mode):** for a large / load-bearing /
invariant-bearing change (`references/triage-lenses.md` › review depth — many files, a change to
`tsconfig`/`eslint`/CI/build config, or a preserved architectural invariant), **also invoke the heavy
`harness:architecture` review** (and `harness:design` for a user-facing surface) — they read
`proposal.md`+`design.md` and work without `specs/`; small/localized → the spec-less review alone. If any
review finds the change is actually spec-worthy → escalate (Step E). Then go to Step D. **full/absent:**
run Steps B–C **verbatim** below (heavy architecture/design routing).

Read whichever of `proposal.md`/`design.md`/`specs/<cap>/spec.md` exist; classify surface, select
reviews (match by content category, adapt to project vocabulary):
| Surface signal | Review |
|---|---|
| schema, migration, endpoint, service, state machine, background job, error handling, data model, component internals | **harness:architecture** |
| user flow, form, user-visible state, navigation, components, user-surfaced error messages | **harness:design** |
- Full-stack user-facing → both. Schema-only → architecture only. Pure docs/rename → none (say so, skip to Step D).
- **Run-when-in-doubt:** ambiguous/mixed → include the review (self-validates, short-circuits cheap). A single-surface spec is not "in doubt" — don't pull the other in on future-feature theory. Routing is not a fork; don't ask.
- Announce routing in one line.

## Step C — Run reviews (AUTHOR path; sequential, autonomous)
Run only selected reviews, order **architecture → design**. Skip excluded. Sequential never parallel
(shared spec files); each re-reads from disk → sees prior amendments.
- Preempt a spurious "missing checklist" finding: note in one line that the `HELD` checklist is
  intentionally not yet authored (name by role, not filename).
- Invoke each via the Skill tool, args = `<change-name>` (autonomous — build does not forward its mode).
  The review treats args as its explicit change-name (first non-mode token) → no multi-change stall.
- Each review auto-applies unambiguous findings, stops on its own forks (may fire before its report +
  per Options finding). Let the review drive its own questions; don't preempt.
- **Completion contract:** a review completes by (a) writing its gate artifact
  `<change-state-dir>/<review>-review.md` (committed, flat under `harness/`) + final summary line, **or**
  (b) self-calibrating to out-of-scope/minimal and printing a one-line skip note (no gate artifact). Treat
  either as complete.
  On completion, **proceed to the next review without yielding to the user** (even after a fork answer,
  even on self-skip). Don't wait for a gate artifact a self-skip never writes. Chain isn't complete
  until every selected review completed + Step D ran. Pause once per genuine fork.

## Step D — Generate the held-back checklist (AUTHOR path; post-review)
Re-run `status`; per `HELD` member: `ready` → generate via `openspec instructions <HELD-id> --json`
(author from `template` + the now-amended dependencies); `done` → regenerate/overwrite (predates the
reviews; not a blocker); `blocked` → surface the blocking artifact, don't call the generator blindly —
**except in spec-less, when `tasks` is `blocked` solely on the intentionally-skipped `specs`: generate it
anyway** (`openspec instructions tasks --json` emits its template regardless of the blocked-on-`specs`
status — confirmed; writing `tasks.md` flips it to `done` → apply-ready). `HELD` empty → skip + note. Both
modes (mechanical; not gated).

## H2 — Spec-review gate (gated only; AUTHOR path)
**gated:** present the reviewed spec + generated tasks; loop: operator reviews → requests edits (apply,
re-show) or approves ("proceed"). Re-ask until approved. **yolo:** skip H2, go straight to impl.
(This is the only operator gate the authoring half adds; reviews already ran autonomously.)
At the gate, emit the **pipeline trail** for the `build · spec-review gate` stop per
`references/pipeline-map.md` (one line) so the operator sees where this pause sits.

---

## Step E — Implement (IMPL path; resume or post-H2)
1. `openspec instructions apply --change "<name>" --json` → store `contextFiles`/`tasks`/`progress`/
   `dynamicInstruction` for all later steps. `dynamicInstruction` present+non-empty → print verbatim.
2. **Schema check:** read `schemaName`; scan task descriptions for `^\d+\.\d+`. <half match →
   **serial-fallback** (all tasks one group, serial in JSON order, single commit) + tell operator.
   `schemaName` absent/not `spec-driven` but prefix holds → proceed + note. Else proceed silently.
3. **Surface mapping** (resume: if `<change-state-dir>/surface-map.md` exists → read + reuse, announce
   "Resuming…"). Orchestrator does it directly (batch Reads parallel; no subagents):
   - **File extraction:** regex-scan task descriptions for path-like strings (contains `/`, ends in a
     common ext — `.ts .tsx .js .jsx .py .go .rs .md .json .css .scss .sql .yaml …`); record task IDs
     per file; group by `N.M` prefix.
   - **Dependency mapping:** for each extracted existing file, Read + record first-level imports;
     locate co-located tests (`<name>.spec.*`, `__tests__/<name>.spec.*`, `<name>_test.*`).
   - **Convention discovery:** list the rules dir (HARNESS.md › Paths); read each rule's heading +
     first paragraph; match to the file set by keyword overlap; **always include any rule referencing
     git / PR / pre-commit**.
   - **Persist** to `<change-state-dir>/surface-map.md` (template: `references/surface-map-template.md`).
   - **Sparse warning:** <half tasks yield a file path → warn (parallelism defaults serial; dep graph
     conservative). Continue regardless.
4. **Convention pre-load:** read the full contents of every rule matched above into context before any
   implementing agent; surface the loaded list (rule + matched-because).
5. **Execution plan:** serial-fallback → one group, skip to commit-type. Else: group by major-`N`;
   intra-group dep graph (same group+same file → serialize; disjoint → parallel cluster; test depends
   on its subject impl task, same base name); inter-group order ascending `N` (never parallelize across
   major groups). Classify each group's commit type (`references/commit-grouping.md`): new files →
   `feat`; modify existing → `refactor`; tests → `test`; verification gates → `chore(verify)`; doc-only
   → `docs`; operator-owned (sync/PR/archive) → mark operator-owned (don't commit/implement; defer).
   Draft commit msg per group: `<type>(<scope>): <summary> (N.first–N.last)` (scope = primary
   package/dir, project convention, omit in single-package; serial-fallback drops the range suffix).
6. **Plan gate:** print the full plan (both modes): surface, conventions loaded, execution rounds per
   group, deferred (operator-owned) section, progress (done/total/remaining). **gated** → `ExitPlanMode`,
   touch no files until approved. **yolo** → informational, proceed.
7. **Execute** per group in planned order:
   - **Focused-attempt bound** (autonomous fix loop): bounded fix-and-re-verify on the task's caused
     failure, confined to the task's assigned files. Escalate to a stop when (a) green needs editing
     files outside task scope; (b) the fix hits a genuine fork (standard/contract/design); (c) ~3
     iterations without green. Same bound governs the pre-commit-hook fix loop.
   - **Skip already-completed tasks** (`- [x]` in `tasks.md`); all-done group → skip (no re-commit).
   - **Dispatch implementing agents** — one Task agent per parallel cluster; serial clusters sequential.
     Each agent prompt includes **verbatim** (not by reference): full content of every pre-loaded rule
     file; the surface map (≥ Parallel clusters + Transitive dependencies); spec `contextFiles`; the
     assigned task IDs + descriptions. (Fresh subagents don't inherit context.)
   - **Each agent:** implements only its tasks (minimal, focused); reports per-task `[<id>] <summary>`
     + `files: <paths>` (orchestrator surfaces the summary immediately, accumulates files for the
     commit); after each edit runs **soft per-task verification** — narrowest applicable sensor (test
     for the changed source, else typecheck for the package, else the doc/locale check, else the
     fallback affected sensor — all resolved from HARNESS.md › Sensors). Red → **gated** stop+report+await;
     **yolo** fix own-task failure + re-run until green (escalate per the bound). Green → flip
     `- [ ]`→`- [x]` in `tasks.md`.
   - **After all group tasks complete:** stage exactly the files agents reported (incl. new); if an
     agent didn't report, fall back to `git status --porcelain` + confirm only this run's changes.
     Commit (planned subject + `Tasks:` body listing each id + `Co-Authored-By`). **Pre-commit hook
     fires** → **gated** stop+surface+await; **yolo** diagnose+fix (lint/format/type/test) + **new
     commit** (never amend), loop until pass (escalate per the bound).
   - **Red mid-group:** **gated** stop+surface (failing task, error, completed tasks)+await; **yolo**
     agent resolves its own failure + continues; stop only on a genuine fork / unrecoverable failure.
   - **Design gap mid-task** (fork both modes): stop the task, surface (what / where / what the spec
     would need); offer (A) update the spec artifact now + continue, or (B) append the call to the
     **decision log** (`<change-state-dir>/decisions.md`, format + bar per `references/decision-log.md` —
     `## D<N> · 🤖 build · <decision>`) + proceed. Never silently invent. Routine spec/rule-dictated choices
     are not logged — the log is **load-bearing only**. A fork the **human** resolves here → log as `👤 human`.
   - **Spec-worthy tripwire (spec-less only; fork both modes):** if — mid-impl — the change trips a
     `references/triage-lenses.md` disqualifier against the actual diff (new/changed contract, observable
     behavior change, migration, security boundary), it was mis-triaged as spec-less. **Stop + fork**
     (walk-me-through card): **(A) escalate to full** — author the `specs/` delta (+ fuller `design.md`),
     **rewrite the marker to `spec_mode: full`**, re-run `openspec status`, run the heavy
     architecture/design reviews spec-less skipped (Steps B–C), regenerate the held checklist (Step D),
     then **resume impl** honoring `tasks.md` `- [x]` + `progress.md` (never redo completed work).
     **(B) log + defer** — append `## D<N> · <👤 human|🤖 build> · <decision>` to `decisions.md` and stay
     spec-less. The flip is load-bearing → always logged. **full/absent:** inert (specs already authored,
     nothing to escalate) — the design-gap fork above runs verbatim.
   - Update `progress.md` as each group commits. Repeat per group.

## Step F — Verify (the harness verification core)
Run in order; each must pass:
1. **Sensors** (HARNESS.md › Sensors, in declared order — format → lint → test → build). Mirrors the
   pre-push gate.
2. **Behavioral-verify** (HARNESS.md › Runtime verification): bring up → exercise → observe → **release**
   → verdict. Liveness always; logs + behavioral per the binding. **Release the operator's machine the
   instant signals are captured** — tear down per HARNESS.md `teardown` (quit the app/processes, drop
   computer-use/screen focus) **before** running steps 3–4 below; never hold the screen through the
   verify tail. **Minimize the borrow window** (interactive drivers): batch exercise+capture into the
   fewest driver round-trips (one `computer_batch`: type+key+screenshot — not serial calls), and make
   `teardown` the **literal next action after the final capture** (read logs / compute verdict only
   after Release — nothing, incl. a Keychain dialog, between capture and teardown). **Skip for
   pure-logic-only changes** (no runtime surface). See
   `references/runtime-verification-binding.md`.
3. **openspec-verify-change** (vendor skill) — spec conformance against the artifacts. Resolve gaps.
   **Spec-less:** run it as-is — with no `specs/` the vendor degrades to task-completion verification;
   **never** invoke `openspec validate --strict` (the one command that rejects a spec-less change).
4. **Skeptical review** (doer ≠ judge) — invoke `harness:review-change` (Skill tool) in **`build-run`**
   mode, args = `build-run <change-name>`. It spawns an **isolated** reviewer sub-agent (fresh context —
   a real doer ≠ judge, stronger than an inline self-review) that grades this run's diff against the
   QUALITY_SCORE rubric through the 13 lenses / 4 stances. **Hand it build's warm context** so it doesn't
   re-flag already-resolved calls: name `<change-state-dir>/surface-map.md`, `decisions.md`, and the
   reviewed spec for it to read. It **applies clear fixes to the working tree but does not commit and does
   not re-run sensors** (build owns both — Model-A). It returns `judge_findings`
   (`{summary, category, disposition}` per finding) + writes `<change-state-dir>/review-change-review.md`
   with a `reviewed-range` footer. **Then build:** commit the applied fixes (its own group/commit model,
   never amend) and **re-run the sensor gate (F.1)**; if any applied fix **touched runtime behavior**,
   **re-run behavioral-verify (F.2)** too — a runtime fix invalidates the pre-fix verdict. A
   `design-stop` disposition is a **genuine fork** — surface for a human (build is autonomous, so the
   review raises no wizard). Keep the returned `judge_findings` verbatim for the Step G.3 run-log row.
   **Spec-less runs this identically** — its proportional depth (trivial diff → baseline stance only) *is*
   the post-impl code review; the pre-impl inline `spec-less-review.md` (Step B/C) already reviewed the
   plan, so the two occupy different pipeline stages (plan vs code) with no duplication.
On any failure not caused by this change → STOP + surface (don't patch around a broken gate).

## Step G — Stop at verified-not-shipped
**Do not ship, push, or open a PR.**
1. Emit `<change-state-dir>/pr-body.md` (handoff for `harness:ship`) by **folding the committed
   artifacts** per `references/pr-summary.md` — never re-analyze the diff. Sections: Title+lead
   (`proposal.md`) · **Architecture** (≤4 lines from `design.md` decisions + the 🔴 story from
   `architecture-review.md`) · Diagram (link iff `design.md` authored one — never synthesize) · What
   changed (group/task/commit counts) · Decisions made (`decisions.md` verbatim if non-empty, else omit)
   · Verification (sensors + behavioral + openspec-verify + review outcomes) · Deferred. Each section
   ends `<sub>Sources:…</sub>` (cite-or-cut); empty input → omit the section. Wrap the whole body in the
   `<!-- harness:pr-summary START/END -->` managed region and end it with the **provenance footer**
   (`folded-against` = `git rev-parse HEAD`; `generated-by: harness:build v<hash8>`; `artifacts:` list)
   per the rule. **Spec-less:** the Architecture section's review source is `spec-less-review.md` (there is
   no `architecture-review.md`); Verification reads `openspec-verify: task-completion` and omits
   spec-verify gaps. **full/absent:** sections fold exactly as above.
2. **Task tracker:** fire the `verified` stage hook (HARNESS.md). Do not move to a review/done state —
   that's ship/finish.
3. **Append one run-log row** to the run-log (HARNESS.md › Observability; schema:
   `references/harness-runs.SCHEMA.md`). Deterministic fields from real output; `judge_findings` =
   the `{summary, category, disposition}` array **lifted verbatim** from Step F.4's `harness:review-change`
   return (no re-summary — the reviewer already tagged category + disposition); `outcome` =
   `verified-not-shipped` (or `stopped-needs-human`/`discarded`); `[E]` fields `null`. **Record
   `spec_mode`** (`full`|`spec-less`) from the marker; in **spec-less**, `verify_gaps` = `null` (no
   spec-verify step ran).
4. **Completion summary:**
   ```text
   ## harness:build complete — <change> (verified, NOT shipped)
   Authored:  <artifacts | resumed existing>
   Reviews:   architecture <N🔴/N🟠/N🟡, M applied> → <change-state-dir>/architecture-review.md   (n/a|skipped if so)
              design <N🔴/N🟠/N🟡, M applied> → <change-state-dir>/design-review.md   (n/a|skipped if so)
   <!-- ALWAYS cite the artifact path so the reviews are findable. If any 🔴 critical was found and
        auto-applied (esp. in yolo, where it happened silently), call it out: "⚠️ 1🔴 auto-applied — read it."
        SPEC-LESS: replace the two heavy review lines with one — spec-less <N🔴/N🟠/N🟡, M applied> →
        <change-state-dir>/spec-less-review.md (+ the architecture row only if +architecture depth ran). -->
   Impl:      <N>/<total> tasks · <N> group commits · mode <gated|yolo> · spec_mode <full|spec-less>
   Verify:    sensors <pass> · behavioral <ran|skipped:reason|n/a> · openspec-verify <pass>
              review <N🔴/N🟠/N🟡, M applied> → <change-state-dir>/review-change-review.md   (skipped if so)
   <!-- Cite the review artifact so the skeptical review is findable (like the architecture/design rows).
        If build-run auto-applied a 🔴 critical (silent in yolo), call it out: "⚠️ 1🔴 auto-applied — read it." -->
   ```
   **Then two real lines below the fence — the operator reads only these, so the actionable one goes
   last:**
   1. The **pipeline trail** for the `build · verified-not-shipped` stop per `references/pipeline-map.md`.
   2. The **terminal handoff** — the **last line**, real markdown (bold + inline-code render; **never**
      inside the fence). Lead with testing, bold the encouraged path, inline-code commands, ship reads
      as later-gated. Exact shape:
      > **Next — test it first.** Run it yourself, then **`/harness:fine-tune`** to polish · **`/harness:ship`** only when you're happy.

   Runnable-now commands only (`fine-tune`/`ship`) — **never `/harness:finish`** (premature until the PR
   merges; `◦ finish` is a trail label, not a command here).

---

## Guardrails
- **Never ship/push/PR** — build ends at verified-not-shipped; `harness:ship` owns push + PR.
- **Hold the checklist (`HELD`) until after reviews** — it must derive from the reviewed spec.
- **Reviews sequential, architecture → design** — they share spec files.
- **Recon after proposal, before design** (the gap-fix).
- **Never modify vendor files** (`.claude/skills/openspec-*`, `.claude/commands/opsx/*`).
- **Never flip `- [ ]`→`- [x]` without soft verification passing.**
- **One commit per major group; never amend** — a fix is always a new commit.
- **Stop at every genuine fork** in both modes. yolo auto-fixes only clear, in-scope failures; an
  unclear fix is a fork.
- **Invocation is consent** for authoring, review amendments, generating tasks, implementing, and
  committing locally — not for shipping.
- **Don't re-implement the reviews** — invoke `harness:recon`/`harness:architecture`/`harness:design`.
- **Don't implement operator-owned tasks** (sync/PR/archive).
- **Spec-less is `specs/`-only.** Spec-less still authors proposal · a lean design · tasks and runs the
  spec-less review + sensors + behavioral-verify; it drops the `specs/` delta + strict-verify, nothing
  else. Default is **full** (marker absent/`full` ⇒ full — never infer mode from missing `specs/`).
- Resume safety: honor `progress.md` + `surface-map.md` + `tasks.md` checkboxes — never redo completed work.

## References
- `references/surface-map-template.md` — Step E surface-map output shape.
- `references/commit-grouping.md` — group commit-type classification + message format.
- `references/convention-load-map.md` — dynamic rule discovery (Step E).
- `references/verification-matrix.md` — soft per-task + hard pre-commit two-layer rationale.
- `references/gate-checklist.md` — surface inference + waiver-log format.
- `references/triage-lenses.md` — spec-worthy disqualifiers (spec_mode source + Step E tripwire).
- `references/spec-less-review.md` — the inline consolidated review for spec-less (Step B/C).

## Composition
- Consumes (vendor CLI, untouched): `openspec new change`, `openspec list --json`,
  `openspec status --json`, `openspec instructions <artifact> --json`, `openspec-verify-change`.
- Invokes (Skill tool): `harness:recon`, `harness:architecture`, `harness:design`, `harness:review-change`
  (`build-run` mode — Step F.4 skeptical review).
- Runs after: `harness:explore` / `harness:refine`. Hands off to: `harness:fine-tune` (polish) and
  `harness:ship` (push + PR) once you've tested.
