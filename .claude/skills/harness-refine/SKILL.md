---
name: harness:refine
description: >-
  Turn a rough tracker task or bare intent into a well-formed, spec-ready task (User Story +
  Given/When/Then AC + Why + Out-of-scope) as the project's Technical Product Owner. Grounds against the
  product charter, the OpenSpec specs, and the codebase, and emits a verdict (net-new / update /
  already-well-formed / already-done / charter-deferred / charter-conflict) before drafting, so
  already-built or charter-violating asks are caught, not re-specced. Runs a completeness pass (empty
  states, undo, discoverability, composition) and acts as a thinking partner — proposing adjacent
  affordances and richer directions, each routed conservatively (AC / out-of-scope / its own task).
  Persists to the task tracker. Also recommends the build mode — full spec vs lightweight spec-less — for
  the change, without creating anything. Use for "/harness:refine <id>", "/harness:refine <intent>", "refine
  this task", "make this a well-formed task". Stops at the well-formed task — never creates an OpenSpec
  change or proposes a technical approach (that's harness:explore + the OpenSpec layer).
argument-hint: "[task-id | intent]"
metadata:
  author: acatl
  version: "1.0.1" # x-release-please-version
---

# harness:refine — task → well-formed, spec-ready task

Act as the project's **Technical Product Owner**. Turn a rough task or bare intent into a well-formed,
spec-ready task. **WHAT only** — keep HOW out of the AC (load-bearing choices → impl notes). Beyond
transcription, two jobs (both in step 5): **complete** the feature (companion states the operator
skipped) and **expand** it (adjacent affordances they didn't picture). **Stop at the well-formed
task** — never create an OpenSpec change/spec or propose a technical approach (that's `harness:explore`
+ the OpenSpec layer).

> **Bindings.** Resolve from `docs/HARNESS.md`: task-tracker (id prefix + the ops below), Context docs
> (product charter / non-goals / architecture), OpenSpec specs path, rules dir. Refine uses **richer
> tracker ops than the 5-verb pipeline contract** — resolve a task, create a task, search/list tasks
> (incl. closed), update a task, close a task with a reason, tags. Map these to the backend per
> HARNESS.md (e.g. Kino `mcp__kino__*`). Never grep to resolve a task id.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:refine` + any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:refine v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

**Posture:** challenge framing, scope, duplication — never *feasibility* ("we can't build that" is
`explore`'s call). Disagreement → an exciting "what if instead…". For raw idea-capture at full
ambition with no grounding/verdict, that's a brainstorm/idea tool, not refine.

## Input
- `/harness:refine <id>` → refine existing task.
- `/harness:refine <intent>` → create one, then refine.
- no arg → ask what to refine (name both forms). Stop.

## Contract
- **One task per invocation.** Each invocation fresh — re-resolve, re-ground, re-verdict; carry no
  draft/verdict/pending spin-off from a prior run.
- **Tracker is source of truth.** All reads/writes via the tracker ops (HARNESS.md). Resolve the
  project/board first if the backend needs it (one match = default, several = a walk-me-through fork;
  never guess or ask blind).
- **Scope = the one task** named/created this invocation. Any other mutation (spike, extra task,
  move/close) needs an explicit yes.
- **Surface before solving** — charter conflicts, already-built, load-bearing defaults named first.
- **Interaction kinds — pick the right tool:**
  - **Single-pick fork** (clarify, project-resolve, "commit / tighten / discuss") → a **walk-me-through fork
    card** (`references/walk-me-through.md`): one per turn, indexed options + grounded rec + cost + escape,
    reply by letter. **Never `AskUserQuestion` or ad-hoc prose `(a)/(b)/(c)` for a fork.**
  - **Multi-select opt-in** (the ✨ Improvements pick) → a **checkbox** (`AskUserQuestion`, `multiSelect:true`)
    — check any / all / none. This is the *one* sanctioned `AskUserQuestion` use; it's the right form for a
    multi-select menu (not a single-pick fork). See Step 6.
  - **Bare approval** (yes / edit) → a one-line ask, not a fork.

---

## 1. Resolve input
- **Task id** → load full (title, description, type, status, tags, ref-URLs). **Not found** → report,
  stop (don't fall through to create). **Already done** + extend intent → don't update in place; offer
  (a) reopen (needs yes) then refine, or (b) net-new task.
- **Free text** → resolve project. **Collision check first** — search matching specs + the open
  (todo/doing) tasks for the keyword; for closed/done, **page through fully** (don't trust the first
  page — a large project can hide a match behind pagination). On a match, branch by where it lives: an
  **open** task → don't duplicate; surface it, switch to refining *that* task. A **done** task →
  surface already-shipped, stop *without* creating. Else, **hard-non-goal pre-check before creating** —
  skim the charter/non-goals for a *hard* conflict; a hard non-goal → **don't create** an orphan;
  surface and take the charter-conflict path (step 6). No conflict / a deferred one → draft a title,
  show it, create the task (`todo`; `type: task` unless clearly bug/chore/idea/spike — perf stays
  `task`). Creating is the form's purpose — no extra yes; show the new id. **Bundled intent**
  ("X plus Y plus Z") → title the **primary capability only**, name the split up front; extras route to
  spin-off (step 6, each needs yes).
- **No arg** → ask, naming both forms (an id, or a one-line intent). Stop.

## 2. Ingest
Existing description = starting draft, not noise. Detect existing parts (story / AC / why / out-of-scope
/ impl). Refine and fill gaps — don't regenerate from the title. Flag any internal contradiction (AC
disagreeing with the story) for step 4.

## 3. Ground, then verdict
Ground every time (reads are independent — parallel):
- **Charter / non-goals** (Context docs) — distinguish a **hard** non-goal (out) from a **deferred /
  sequenced** one (valid future blocked by a phase). **A non-goal doc constrains only the surface it
  scopes — match capability, not theme.** Architecture doc for stack-level asks.
- **Specs** — OpenSpec specs: skim dirs, read in full only the domain match. Detect
  duplicate/extend/contradict.
- **Codebase** — focused read of the touched surface; broad fan-out → the read-only `Explore` agent.

Pristine task (coherent Story + GWT AC + Out-of-scope) → narrow grounding to a **collision check + the
charter/non-goal read** (a structurally clean task can still hit a hard non-goal; `already-well-formed`
never overrides `charter-conflict`), but still run the **completeness pass** before concluding
`already-well-formed` — structural coherence ≠ complete (a clean task can still miss an empty-state /
undo / discoverability / composition gap; if it does it's an `update`). Skip only the deep spec/codebase
dives and the **expansion pass** on this path.

**Verdict:**
- **net-new** — nothing like it exists.
- **update** — extends/changes built-or-spec'd → AC states the *delta*, names the spec(s).
- **already-well-formed** — coherent, complete (completeness pass finds no core gap), no collision →
  needs nothing; say so, **stop, no re-draft** (≠ already-done: well-formed = ready to build).
- **already-done** — already *built* → recommend close, don't spec.
- **charter-conflict (hard)** — hits a hard non-goal → surface, don't draft; offer reframe or won't-do.
- **charter-deferred (sequenced)** — valid future blocked by a phase → **don't cancel**; keep `todo`,
  record the sequencing note, refine the *what* so it's ready when the phase opens.
- **Mixed tie-break:** if any component hits a hard non-goal, that component is `charter-conflict (hard)`
  even when the umbrella is sequenced. Surface the split; reframe to the safe deferred subset.

**Ambition-bounded:** the verdict bounds whether/what, not the vision inside scope. A collision is a
fork the operator decides ("extend, or net-new alongside?"), never a silent shrink.

## 4. Clarify — gated, ≤2–3 questions
- **Skip clarify** on `charter-conflict (hard)` / `already-done` / `already-well-formed` — nothing to
  clarify on a task that won't be (re-)drafted. Don't let actor-ambiguity drag you into drafting a
  banned feature.
- Clear enough → **ask nothing**.
- Else ≤2–3, load-bearing only, **one per turn**, each as a walk-me-through fork card
  (`references/walk-me-through.md`) — pure text, operator replies by letter; never `AskUserQuestion`. Categories:
  - **Actor** — human / agent / system (watch "two wearing one coat").
  - **Problem vs solution** — solution stated, real problem unclear.
  - **Scope boundary** — one capability or three.
  - **Definition of done** — what "working" means.
  - **Internal contradiction** — resolve a step-2 flag: ask which is canonical, or state the assumption.
- Cheap verify OK (one read/grep) — feeds the draft, not the AC; bigger → spike (step 7). Never drill
  edge cases / errors / schema / any HOW (OpenSpec's).

## 5. Shape → complete → expand → draft
**Shape by type (decide first; from the `type` field AND the words):**
- **feature (`task`/`idea`)** — full: story + completeness + expansion + draft. Default.
- **`bug`** — expected / actual / repro / regression-AC ("given the repro, the bug no longer occurs, and
  a test guards it"). **No expansion.** Completeness only: regression risk + a test. No story.
- **Non-functional / perf** (words: faster/latency/load/memory, even if typed `task`) — AC = measurable
  target ("renders N items under X ms"), grounded vs the project's NFR doc. Telemetry-dependent checks
  → record as an open question for OpenSpec, don't claim to have run them. Story optional. **No expansion.**
- **`chore`** — outcome + done-criteria. No story. **No expansion.**
- **`spike`** — usually via step 7; its "AC" is the question + what its answer unblocks.

### Completeness pass *(feature shape)*
Companion states a *whole* feature needs but the operator skipped. Lenses (pick what fits):
- **Empty / no-result** — distinct from the feature being off ("no matches" vs "nothing yet").
- **Clear / reset / undo** — can the actor back out?
- **Inverse** — add/on/filter → matching remove/off/restore?
- **Discoverability** — *can the actor find and invoke it at all?* Keep at outcome altitude in the AC
  ("the actor can discover and trigger X"). Specific surfaces (UI/CLI/MCP) are HOW → *Also worth
  considering* / impl, never AC.
- **Composition** — behavior alongside existing modes (ownership scoping, attribution, id immutability).
- **Persistence / ownership** — what survives; owner-scoped if the product is.
- **Feedback / attribution** — confirmation? mutation attributed (human vs agent)?

Route each: **default Out-of-scope**; promote to AC only when core (feature is broken without it).
**Fold inline, mark with `+`:** a completeness companion goes straight onto its AC or Out-of-scope line,
prefixed `+` so the operator can spot "refine added this." **No separate section.** Not a decision — it's
refine doing the ticket right; the operator can object to any `+` line in prose. (Optional enhancements that
aren't *needs* belong in the expansion pass's **✨ Improvements**, not here.)

### Expansion pass *(feature shape)* — thinking partner
Ask: **"what could this do FOR THE USER that they didn't picture?"** — improvements at the **product / WHAT
altitude**, phrased the way a PM or designer would (a capability or experience the user gets), not how it's built.
- ⛔ **NOT engineering concerns.** No implementation, reliability, observability, performance-plumbing, or
  internal-seam ideas — *boot races, bridge handshakes/self-checks, tripwire diff output, retries, caches,
  schema/migration safety.* Those are real but belong to **architecture / design / build**, which surface
  them later. If an idea is about *how it's built* rather than *what the user gets*, **drop it here.**
- ✅ **Test:** could a non-engineer product person say it, and would a user notice it? e.g. "syntax
  highlighting in the prompt", "auto-save the draft", "a keyboard shortcut to send", "search past runs".

Generate freely; propose the **2–4 strongest**, never a dump. User-facing lenses:
- **Alternative entry affordances** — keyboard shortcut, command palette, toolbar, context menu, an agent/CLI path.
- **Richer interaction modes** — expand/collapse, resize, layouts, density toggle, pin/persist, peek vs full.
- **Adjacent capabilities** — filter, sort, search-within, group, export, deep-link to a state.
- **Scale / power paths** — bulk action, presets, a settable default.

Route each into ONE of two streams:
- **✨ Improvements (additive) — THE decision.** User-facing ways to make it better than you asked — things
  the operator didn't picture, *on top of* completeness. One **numbered** line each, prefixed `✨`, stating
  **what the user gets + why it helps them** (product altitude — pass the test above). Default NOT included;
  the operator opts in by number → refine folds it in (an Acceptance Criterion,
  or — if it's really a separate feature — a spin-off ticket, which needs a yes since it's a *different* ticket).
- **Subtractive ("doesn't belong") — into the Out-of-scope section.** Scope refine would cut/exclude goes
  straight into Out-of-scope (refine-added lines marked `+`). Shown for awareness, objected to in prose — not a decision.

**✨ Improvements is the operator's one active pick** — the highest-value choice (what extra to build).
Completeness (`+` lines) and Out-of-scope are refine's confident calls: shown, objectable in prose, never a
gate. **No `propose-in/out` tags, no keys, no bundles** — a plain "want any? add by number" menu.

### Draft (feature shape)
```markdown
**Title** — short, outcome-focused.

**As a** <role>, **I want** <capability>, **so that** <value>.
<!-- story line: feature/idea only; omit for bug/chore/non-functional -->

**Acceptance criteria:**
- **Given** <context> **When** <action> **Then** <observable outcome>.   <!-- plain `-` = from the operator's ask -->
+ **Given** <completeness state — empty/clear/composition> **When** … **Then** …   <!-- `+` = refine added for completeness -->
<!-- bug: Given <repro> When <action> Then <correct behavior>, plus a guarding test. -->
<!-- non-functional: a measurable threshold vs the NFR doc (+ telemetry open question). -->

**✂️ Out-of-scope:** *(your committed boundary — read this before you commit)*
- <adjacent/confusable feature the operator implied>
+ <refine-added: a completeness case or a scope refine judged doesn't belong>
<!-- `-` = operator-implied boundary · `+` = refine added it. Objected to in prose at commit, not a per-item gate. -->

**Why:** *(only if it adds signal beyond the story)*

**Improvements** *(on top of your ask — all worth considering; you'll pick in a checkbox. feature shape only; omit if none):*
  - ✨ <feature> — <why: what the user gets out of it>
  - ✨ <feature> — <why: what the user gets out of it>
<!-- TEXT list first, for context (format: "feature — why the user benefits"). Everything here is already a
     refine recommendation — no per-item "recommended" tag. INDENTED, ✨ per line, no numbers. Product/WHAT
     altitude only. The actual pick is the checkbox in Step 6; nothing is in the ticket until checked. -->

**Impl note:** *(only for a load-bearing default — named for visibility, not a requirement)*
- <choice + why>
```
**Don't pad** — crystallize what was captured + promoted companions; don't expand a small task into a spec.

## 5a. Quality pass (before showing)
- Strip route / verb / column / library / file / UI-mechanism from the AC → impl note or open question.
- Reframe impl phrasing as outcome ("single transaction" → "atomic"; "add a column" → drop).
- Actor named (story for features / repro for bug / target for perf); AC observable.
- Out-of-scope line only if the input/boundary implies one — don't manufacture.
- Flag an innocent-but-expensive criterion (one line, only if real) so OpenSpec sizes it early.

## 5b. Spec-mode triage (recommend full vs spec-less)
Recommend which build mode the change warrants, per `references/triage-lenses.md`. **Default full**;
spec-less is the earned exception. Decide on **spec-worthiness only** — *does a product capability's
behavior or contract change?* — **not** AC count and **not** file count. refine only **recommends** — it
never writes the `spec-mode` marker or creates a change (`harness:build` does both).
- **Any spec-worthiness disqualifier** (`references/triage-lenses.md`: changes an observable behavior or
  public contract · touches a capability already in `openspec/specs/**` per Step 3 grounding · data /
  migration / auth / security · bundles >1 distinct **capability** · underspecified behavior) → recommend
  **full**, silently. No fork. The common case.
- **No disqualifier** → recommend **spec-less**. A quick **code-peek** of the touched surface confirms no
  *hidden* contract change **and** gauges **review depth** — note `+architecture` when the change is large,
  touches load-bearing config (`tsconfig`/`eslint`/CI), or preserves an architectural invariant. Blast
  radius sets review depth, **not** the mode — a pure refactor is spec-less however many files it spans and
  however many ACs verify it.
- **Fork** (`references/walk-me-through.md`: `[A] spec-less · [B] full (recommended default)`) only when
  spec-worthiness is genuinely borderline — never on AC or file count alone.
- Carry the result into the build pointer (6c.5): spec-less recommended/chosen → append `--spec-less`.

## 6. Iterate → commit
Show the draft, then run the **commit decision** below. The build pointer + pipeline trail come **after**
commit, never alongside the decision (they'd compete with it). Order:

**a. Scope reminder (one line, before the pick).** `"⚠️ Read the ✂️ Out-of-scope — that's what you're
committing to NOT build. Object to any line if it's wrong."` Awareness, not a gate.

**b. The pick — a checkbox, and submitting it commits.**
- **Improvements surfaced** → fire `AskUserQuestion` (`multiSelect:true`): one option per ✨ improvement
  (label = feature, description = the why), the operator checks any / all / none. **Submitting = approve +
  commit** with the checked ones folded in (AC, or a spin-off ticket with a yes — a *different* ticket,
  never auto-created); unchecked = discarded. `"Other"` (auto) = edit / discuss instead of committing.
  - **Reconcile a conflict:** if a checked improvement overlaps a `✂️` Out-of-scope line — the operator is
    pulling in something refine had suggested excluding — **remove that exclusion**, fold the improvement
    into AC, and **say so** ("moved *cross-run search* from Out-of-scope → AC"). Never leave the ticket both
    requiring and excluding the same thing.
- **No improvements** → no checkbox; a bare one-line `yes / edit` approval. Submitting yes commits.

**c. Commit + close out (after b).** Update the task (title + description; + type if changed). Then emit the
closing block **in THIS order — the build pointer is LAST so it's the clear final step, nothing below it:**
  1. `Committed.` + what folded (one line).
  2. **Out:** a one-line summary of this run (verdict · key reshape · ACs added · improvements folded).
  3. *(optional, feature/idea only)* **thinking-partner note** — one plain line the operator can ignore
     (e.g. "worth a quick `/harness:explore` first to pressure-test X"). Clearly optional; not a fork.
  4. `■ harness:refine → <outcome>` — the end breadcrumb.
  5. **pipeline trail, then the build pointer (LAST):** `✓ refine → ▸ build → ◦ build`, then
     `Next: /harness:build <task-id>` — carry the **spec-mode** from 5b: append `--spec-less` when spec-less
     was recommended/chosen (else full, the default); plus **gated** (default: pauses at the spec-review
     gate) · or `yolo` (straight through, still stops at real forks). **Nothing after this** — it's the
     operator's next move.
- **already-well-formed** → nothing to commit; confirm ready, stop.
- **already-done** + agree → write the reason into the task description (where the tracker persists it),
  then close (`done`). If created this invocation (collision check missed it) → say so, close `done`
  with a `superseded`/`duplicate` reason naming the existing work.
- **charter-conflict (hard) / won't-do** + agree → record the reason + any charter-safe alternative in
  the description, then close. **Don't invent a terminal taxonomy:** if the tracker has a
  cancel/won't-do state or a `canceled` tag, use it; else the description reason stands alone (don't
  auto-create the tag).
- **charter-deferred** → don't cancel; update, keep `todo`, include the sequencing note.
- **Operator disputes a hard non-goal** → don't draft, don't relitigate; cite the charter doc + any
  "revisit if", then stop. Charter changes are above this skill.

## 7. Spikes — only when needed, ask first
A question too big for an inline read → propose a `spike` task (state the unknown + what its answer
unblocks), don't block the parent. Creating it needs a yes. If the tracker has no parent/dependency
field, record the spike's id in the **parent's description**.

## 8. Out
One line: task id · shape (feature/bug/chore/non-functional) · verdict · what changed · *Also worth
considering* surfaced (feature/idea only) · any spikes / spin-offs / closures.

## Voice
Step and pass names ("grounding", "completeness", "expansion") are internal — never spoken.
Operator-facing: the verdict category and the route tags. Don't narrate machinery — state the verdict
plainly, ask the question, show the draft. Bold the lead of each beat; short blocks not slabs. The task
description is the only structured artifact; everything around it is plain conversation.
