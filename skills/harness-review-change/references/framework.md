# Review framework

This document is the **reviewer's instruction set**. It defines the 13 lenses,
Phase 0/1, the severity taxonomy, the `Fix class` field, and the return format.
The reviewer is a Senior Staff Engineer performing a self-review of local commits
before they become a Pull Request. Catch issues while they are still cheap to fix.

The skill runs one reviewer-fixer agent through four sequential stances (see
`deep-stances.md`) in a single context. Each stance narrows focus; this framework
is the common baseline. The agent **applies `Fix class: clear` fixes itself** as
it goes and queues `decision-needing` findings for the operator — see the
guardrails in `SKILL.md`. This framework defines _what to look for_; `SKILL.md`
owns the fix-vs-queue behavior.

---

## Phase 0: Orient to the project (all projects)

Before reviewing, build a working understanding of the codebase. You know
nothing about this project yet. **Run these reads in the first batch alongside
the git commands.**

1. **Read project instructions** — Look for `CLAUDE.md`, `README.md`, or similar
   root-level documentation that describes the stack, architecture, and
   conventions.
2. **Identify the tech stack** — Check package manifests (`package.json`,
   `Cargo.toml`, `go.mod`, `pyproject.toml`, `Gemfile`, `pom.xml`, etc.) to
   understand languages, frameworks, and dependencies.
3. **Note existing conventions** — Observe naming patterns, error handling style,
   test organization, and any project-specific patterns from the project
   instructions.

Keep this context for the entire review. Adapt your review dimensions to what
this project actually uses — skip sections that don't apply, add concerns that
the stack demands.

---

## Phase 1: OpenSpec alignment (conditional)

This phase activates when the project uses OpenSpec and there are active changes
on the branch. If no OpenSpec changes are detected, skip to the review framework
— the generic Spec-Code Consistency lens (section 6) still applies.

### Detection

1. `openspec list --json` runs in the first batch. If the `changes` array is
   empty, skip this phase entirely.
2. For each active change, gather context — all of the following are independent
   and run in parallel:
   - `openspec show <change-name> --json` — structured deltas (requirements +
     scenarios)
   - `openspec status --change <change-name> --json` — artifact completion
   - Read `openspec/changes/<name>/proposal.md` — intent, scope, and motivation
   - Read `openspec/changes/<name>/design.md` — architectural decisions and
     constraints
   - Read `openspec/changes/<name>/tasks.md` — implementation breakdown and
     completion status
   - Read `openspec/changes/<name>/specs/` — delta spec files with detailed
     requirements

### Analysis

Cross-reference the diff against the spec artifacts. This is **bidirectional** —
neither the spec nor the code is automatically correct.

For each delta requirement and its scenarios from `openspec show --json`:

1. **Locate the implementation** — Find where in the diff (or existing code
   touched by the diff) this requirement is realized.
2. **Verify scenario coverage** — Each scenario is a concrete assertion. Check
   that the code behavior matches the WHEN/THEN conditions. Check that tests
   exercise these scenarios.
3. **Check design adherence** — Compare implementation approach against
   `design.md` decisions. Flag deviations, but evaluate whether the deviation is
   an improvement or a regression.

### Classification of findings

Classify each finding into exactly one category:

- **Spec gap** — The spec requires X but the implementation doesn't do it. A
  potential missing feature or behavior.
- **Implementation exceeds spec** — The code does something useful that the spec
  didn't anticipate. Recommend whether the spec should be updated to capture
  this, or whether the code is doing unnecessary work.
- **Contradiction** — The spec and code disagree on behavior (e.g., spec says
  throw `ForbiddenException`, code returns a 401). One of them must change.
- **Stale assumption** — A spec assumption was invalidated during implementation
  (e.g., spec assumed a table exists that doesn't, or assumed a pattern that the
  codebase doesn't use). The spec needs updating.
- **Task completeness** — Cross-reference `tasks.md` checkboxes against actual
  implementation. Flag tasks marked complete but not evidenced in the diff, or
  work done that isn't reflected in tasks.

### Critical stance

- **Do not assume the spec is gospel.** Specs are written before implementation —
  reality may force better solutions. When the code deviates from spec, ask: "Is
  this deviation an improvement or a bug?"
- **Do not assume the code is correct just because it passes tests.** Tests may
  not cover the spec's scenarios. A test passing doesn't mean the behavior
  matches the spec's intent.
- **Evaluate the gap, not just its existence.** A trivial naming difference is
  noise. A behavioral mismatch in error handling is signal.

---

## Reviewer mandate

You must review as a senior engineer responsible for:

- Security
- Architecture integrity
- Maintainability
- Long-term scalability
- Type safety and language rigor
- Spec-code consistency
- Behavioral consistency across modules

You do NOT:

- Nitpick formatting (formatters handle that)
- Rewrite entire files unnecessarily
- Introduce unrelated refactors
- Change product scope

You MUST:

- Identify real risks
- Think beyond surface-level issues
- Consider misuse and edge cases
- Consider performance implications
- Re-evaluate your own conclusions before finalizing

---

## Review framework — the 13 lenses

Analyze through the following lenses. **Skip any lens that doesn't apply to this
project's stack.** Add project-specific lenses if the stack demands it (e.g.,
Electron boundary review, database migration safety, API versioning).

### 1. Security review

Evaluate:

- Input validation and sanitization at system boundaries
- Authentication and authorization correctness
- Injection risks (SQL, command, XSS, path traversal)
- Sensitive data exposure (secrets, tokens, PII in logs)
- Trust boundary violations

Flag:

- Unsanitized user input flowing into dangerous operations
- Missing auth checks on new endpoints or handlers
- Hardcoded secrets or credentials
- Real email addresses, passwords, or API keys in any file including docs,
  runbooks, test fixtures, and planning documents — use `@example.com` and
  `<PLACEHOLDER>`
- Controllers or webhook handlers that forward raw `req.body` fields to service
  methods without explicit validation or narrowing

### 2. Architecture & separation of concerns

Evaluate:

- Clear separation between layers (routing, business logic, data access, UI)
- No circular dependencies
- No implicit global state
- Logic lives in the right layer

Detect:

- Hidden coupling between modules
- Business logic embedded in UI components or route handlers
- Improper state propagation

### 3. Type safety & language rigor

Evaluate:

- Proper use of the language's type system
- Exhaustive handling of variants/enums/unions
- Nullable/optional handling correctness
- Strict mode compliance (if applicable)

Flag:

- Unsafe casting or type escape hatches (e.g., `any`, `as unknown as` in
  TypeScript; `unsafe` in Rust; unchecked casts in Java/Go)
- Missing return types on public APIs
- Non-null assertions without justification
- For TypeScript projects: `as` casts on data from external sources (request
  bodies, query params, webhook payloads, database row mappers, third-party API
  responses) — these must use runtime guards instead
- For other typed languages: equivalent type escape hatches that bypass
  compile-time safety on external data

### 4. Performance & scalability

Evaluate:

- Algorithm complexity appropriate for expected data sizes
- Unnecessary recomputation or repeated I/O
- Missing debouncing, caching, or batching where needed
- Large state updates causing cascading effects

Consider:

- 10x current data volume
- Concurrent usage patterns
- Resource cleanup (connections, handles, subscriptions)

### 5. Testing gaps

Evaluate:

- Is new logic covered by tests?
- Are edge cases tested?
- Are error paths tested?
- Do tests validate behavior, not implementation details?
- **Assertion completeness — does each test prove both presence _and_ absence?**
  If a test asserts that an error message renders, does it also assert that the
  side-effect the error was supposed to prevent did _not_ happen? If a test name
  claims "memoizes input", does the assertion actually count cache hits — or does
  it pass trivially because the output is deterministic? If a test name claims
  "focus stays on trigger after Escape", does it assert focus position, or only
  that the popup closed?

Flag:

- Untested core logic
- Tests that only cover the happy path
- Missing regression tests for bug fixes
- Test data that violates production constraints: invalid UUID format, enum
  values not in the production enum, fields that would fail NOT NULL or CHECK
  constraints, string matching on error messages instead of exception class
  assertions
- **Presence-without-absence asymmetry**: a test that asserts an error UI
  rendered but does not assert that the network request / mutation / side-effect
  was prevented — a buggy validator that surfaces the message _and_ still submits
  will pass
- **Test name implies an assertion that the body does not make**: "memoizes",
  "focuses", "deduplicates", "throttles", "rolls back" in the test name with no
  assertion proving the named behavior
- **Mock-only verification**: a router / fetch / mutation is mocked but the test
  never asserts the mock was (or was not) called with the expected arguments —
  regressions in call shape pass silently

### 6. Spec-code consistency

**If Phase 1 (OpenSpec Alignment) produced findings, reference them here and skip
the generic checks below.** Phase 1 is the structured, authoritative version of
this lens when OpenSpec changes are active.

When no OpenSpec changes are active, or for files outside the change's scope:

Evaluate:

- Do specification docs match the actual implementation?
- Do multiple docs contradict each other on the same fact?
- Are test fixtures aligned with the contracts they exercise?

For every package or app touched by the diff, read its `README.md` (if one
exists) and verify:

- Usage examples match the current API signatures (function names, parameter
  shapes, return types)
- File structure descriptions match the actual directory contents
- "How to add..." or setup guides reference correct file paths and patterns
- Listed exports match what the package's public entrypoint actually exports
- Documented constraints or design decisions still hold after the change

Flag:

- Docs claiming different behavior than the code
- Stale documentation not updated alongside code changes
- Stale documentation after renames: if the diff renames a function, route,
  entity, field, or concept, check `docs/`, `openspec/`, README files, and
  docstrings for the old name
- README content that contradicts the implementation — wrong signatures, missing
  parameters, outdated file paths, or described files that don't exist
- OpenAPI/Swagger definitions that use different HTTP methods, parameter names,
  or request body shapes than the corresponding route handler implementations
- Field counts, step numbers, or path references in docs that no longer match the
  implementation
- A scenario, example, or sub-claim inside a spec or doc file that contradicts
  the requirement or top-level statement in the same file

#### Mechanical-change drift checks

When the diff contains any mechanical change — rename, renumber, count change,
scope flip, namespace move, field add/remove — run drift checks across the
_whole_ repository, not just touched files. The diff captures the primary
surface; stale references survive in adjacent prose, headers, and config.

- **Numeric references**: phase / step numbers, version labels, "N items / N
  steps / N tables" statements. Grep every doc and config file for the OLD
  number; verify each hit.
- **Renamed identifiers (paths, routes, symbols, keys, namespaces)**: grep for
  the OLD string across docs, top-level and per-directory project-instruction
  files, project rules, route handlers, error messages, lint and format config,
  and CI config.
- **Shape statements**: when a field list, parameter list, or interface gains or
  loses a member, locate every prose enumeration of that list and reconcile.
- **Description vs implementation**: read the PR description / proposal / commit
  body's bullet claims and verify each against the actual diff. A claim like "X
  consumes Y directly" must match how the code wires up.
- **Filesystem-path references in error messages, lint rules, or docs**: if a
  config message or doc references a file path, confirm that path exists in the
  current diff. Pre-sync references are a common silent failure until the sync
  step runs.

#### Code-comment drift checks

When a file is touched, re-read every block comment, docstring, and inline
comment in the touched file. A refactor often updates the implementation while
leaving prose that describes the previous shape.

- **File-header / module / component comments**: if the comment states the
  file's role, composition, or layout, verify each claim still matches the
  implementation below.
- **Identifier-naming comments**: if the comment names an API, hook, service, or
  symbol, grep to confirm that symbol still exists at the named location and
  still behaves as described.
- **Reason / rationale notes**: when a behavior is dropped or inverted (a cap
  removed, an optimistic update replaced, retry semantics flipped), the "why"
  sentence in nearby tests or component comments becomes a lie. Flag any
  rationale sentence whose premise is gone.
- **Cache-key / query-key / config-key shape comments**: if a comment lists keys
  as one shape (e.g. `['a','b']`) but code uses a different shape (e.g. `'a-b'`),
  the comment is wrong.

### 7. Dead code & unused definitions

Evaluate:

- Defined but unreferenced functions, components, or types
- Imports no longer used after the change
- Constants or config entries nothing reads

Flag:

- Exported symbols with zero call sites
- Type definitions with no consumers

### 8. Behavioral consistency

Evaluate:

- Do similar modules follow the same patterns?
- If one module guards on a condition, do its siblings?
- Are shared patterns (error handling, validation, logging) applied uniformly?
- **Data-fetch error / loading / not-found branches are explicit, not
  fall-through.** When a component fetches data (query disabled because a
  prerequisite isn't ready, query failed, query returned empty, query returned a
  value the schema rejects), every state must render an explicit branch — not
  silently fall through to the default body. The most common failure: an upstream
  identifier resolves to an empty string, the dependent query is disabled, and
  the component renders the create form / empty list as if everything succeeded.

Flag:

- Inconsistent guard logic between analogous modules
- Missing safeguards present in similar code paths
- Log statements for state-changing operations missing structured context fields
  (acting user ID, target entity ID, before/after state)
- Inconsistent logger API usage
- **Data-fetch fall-through**: a component whose `useQuery` / loader is disabled
  by an empty / missing prerequisite (unresolved namespace, missing route param,
  failed upstream lookup) renders the default success-state UI instead of an
  explicit loading / not-found / error branch
- **Missing query-error branch**: queries with `isError` not handled, so failure
  renders as "no data" instead of a retry / error state — particularly on
  landing pages and top-level shells where the create / empty-list view is the
  fall-through default

### 9. Developer experience & repo integrity

Evaluate:

- Script and config changes aligned with existing conventions
- Build and CI pipeline correctness
- Git hook and lint-staged correctness (per-file vs project-wide commands)
- Dependency additions justified and compatible
- Consistent terminology across docs — no stale references to renamed concepts

### 10. Defensive programming

Evaluate each method in isolation — not just the system as a whole. Ask: what
does this method assume, and what happens when those assumptions are wrong?

- **Nested resource ownership**: when a method takes a sub-resource ID (e.g.
  `taskId` on a feature route, or `featureId` on a milestone route), does it
  verify the resource belongs to the parent in the route? Project-scoping
  middleware only covers the outermost (Project) scope.
- **Count-check atomicity**: any pattern of read-count → conditional insert is a
  race condition. Is the cap enforced inside a transaction?
- **Buffer/array access**: any access at a fixed index — is there a length guard
  before it?
- **Error exhaustiveness**: catch blocks and status-to-state mappers — does each
  one handle every HTTP status the endpoint documents, or does a catch-all
  default mask distinct failure modes?
- **Partial failure**: if step 1 of N succeeds and step 2 fails, is the system
  left in a consistent state?
- **Client cap ↔ server validator alignment**: when a server validator
  transforms input before measuring (trim, normalize, lowercase), the
  client-side cap must be either absent (let the validator enforce) or strictly
  larger than the post-transform cap with the validator as final authority. A
  pre-transform client cap can silently truncate input that would have been valid
  after the transform. Conversely, omitting the client cap entirely on
  inline-create surfaces means the user types past the limit and only sees a
  generic server failure.

Flag:

- Service methods that operate on a sub-resource ID without verifying
  parent-chain ownership
- Read-then-write patterns on shared counters without transactional protection
- Array index access without a preceding length check
- Catch blocks with a generic fallback that swallows 4xx/5xx codes the endpoint
  is documented to return
- Multi-step operations with no rollback or cleanup on mid-sequence failure
- Client-side input caps (HTML `maxLength`, character-count cutoffs) that run
  _before_ the server validator's transform step when the validator trims or
  normalizes first — silently truncates input that would have been valid
  post-transform
- Destructive over-limit UI branches (red counter, disabled submit, inline
  validator error) made unreachable by a stricter HTML / client cap that blocks
  input before the branch can fire
- Inline-create / quick-add surfaces with no client-side feedback for the
  server's length / format cap — user discovers the limit only after submit fails

### 11. Database migration safety

_(Skip this lens if the diff does not include database migrations.)_

Evaluate:

- Constraint modification ordering: drop old constraints before data transforms,
  add new constraints after
- Down migration fidelity: exact reversal of up — same column types, same
  constraints, same indexes
- Statement-by-statement validity: each statement must be valid against the
  schema state at that point in the migration sequence

Flag:

- Data modifications that run while a blocking constraint is still active
- Down migrations that leave the database in an inconsistent state
- Migrations that modify already-deployed migration files instead of creating
  new ones

### 12. Accessibility

_(Skip this lens if the diff has no user-facing UI surface.)_

Evaluate:

- Every focusable interactive control (input, textarea, contenteditable, button,
  link, custom widget) has an accessible name. Confirm by reading the control's
  own attributes — wrapper elements above the focusable target do not contribute
  the name unless an explicit association exists.
- ARIA wiring between label, control, and validation / help text uses stable ids
  — not just visual proximity. The control references its error / help elements
  through `aria-describedby` and signals invalidity through `aria-invalid`.
- Dynamic feedback regions (`role="alert"`, `aria-live` regions) only mount when
  they have content. An always-mounted alert with empty children produces silent
  announcements.
- Accessible names are _unique_ within a list or repeating surface. "Board",
  "Planning", "Open menu" repeated across rows leave assistive-tech users with
  indistinguishable items — include the row's identifier in each label.
- Accessible names describe the action the control actually performs. A menu
  trigger that opens Edit / Delete must not be labelled with one of those
  actions; it should describe the menu itself.
- `aria-current="page"` is set only when the link's target matches the current
  URL. Setting it on links that point elsewhere mis-signals which item is
  "current."
- Keyboard navigation is _complete_, not partial. If the surface specifies
  arrow-key navigation, both directions are bound. If a custom widget renders as
  an anchor or button, Space activation works as a native control would.
- Roving-tabindex state updates when the underlying selection changes (route
  change, programmatic selection). A stale roving index sends Tab into the wrong
  row.
- Color and contrast claims documented in the codebase (palette utility
  comments, "WCAG AA" assertions) are exercised by at least one test or visible
  computation, not just promised in prose.
- Screen-reader strings (`aria-label`, `aria-busy`, status announcements) are
  routed through the same internationalization layer the rest of the UI uses —
  hard-coded English inside an `aria-*` attribute in an otherwise-localized
  component is a defect.

Flag:

- ARIA attributes applied to a non-focusable wrapper above a focusable inner
  element (the focused element receives no accessible name from the wrapper)
- `<Label htmlFor={id}>` without a matching `id` on the focusable control
  underneath
- Error / counter / help text that is not associated with its control via
  `aria-describedby`
- `role="alert"` elements that render with empty / nullable children
- Repeated identical accessible names across list items
- `aria-label` whose text describes a different action than the control performs
- `aria-current="page"` on links whose href does not equal the current pathname
- Missing reverse-direction key bindings on a widget that documents arrow-key
  navigation
- Custom anchor / button widgets that don't activate on Space when the spec calls
  for it
- Hard-coded user-facing strings inside `aria-*` attributes in components that
  otherwise use the project's i18n layer
- Controls whose only text label is responsively hidden (`hidden md:inline`,
  breakpoint-dropped `sr-only`) while their icons are `aria-hidden` — empty
  accessible name at the hidden breakpoint unless a persistent `aria-label`
  stays on the control

### 13. Localization and user-facing strings

_(Skip this lens if the project does not use an internationalization layer.)_

Evaluate:

- Every user-facing string is routed through the project's i18n accessor —
  visible labels, screen-reader-only strings (`aria-label`, `aria-busy`,
  `<title>`, tooltips), error / status copy, and CLI / API output messages.
- Variable interpolation uses the i18n library's placeholder syntax with
  variables passed as a second argument, not manual string substitution. Calling
  `t("greet").replace("{name}", name)` skips the library's formatter —
  pluralization, select, escaping, and locale-specific word-order reordering all
  silently break.
- Translated sentences are _whole sentences_ inside the message — never assembled
  from `t("prefix") + value + t("suffix")`. Word order differs the moment a
  second locale lands.
- New strings live in the canonical locale file at the correct namespace depth,
  not inlined at the call site even temporarily.
- Tests that exercise localized components assert against the locale value (or
  its key), not against a hard-coded string copy.

Flag:

- Manual `.replace("{var}", value)` against the return value of `t(...)` /
  `useTranslations()` — bypasses ICU formatter
- Hard-coded user-facing English strings in `aria-label`, `aria-busy`, tooltip
  text, status announcements, page titles, or counters inside components that
  import the i18n accessor for other strings
- Translated-fragment concatenation: `t("a") + " " + t("b")`, `t("intro") + name
  + t("suffix")`
- Counter / progress strings hard-coded as JSX expressions (`{n} / {max}`) when
  an ICU pattern exists in the locale file
- New user-facing strings introduced at the call site that should have landed in
  the locale file

---

## Deep thinking requirement

Before finalizing your review:

- Re-evaluate your own findings — discard false alarms.
- Consider second-order effects of the changes.
- Consider how this change impacts long-term maintainability.
- Consider how a new developer would understand this code.

---

## Severity taxonomy

Classify every finding into exactly one severity level. The main agent's wizard
keys off this severity.

|     | Severity | Definition                                                                                    | Action required             |
| --- | -------- | -------------------------------------------------------------------------------------------- | --------------------------- |
| 🔴  | Blocker  | Security bug, multi-tenant leak, typecheck/lint/test failure, error-handling contract broken | Must fix before shipping    |
| 🟠  | Warning  | Unsafe cast, missing validation, architectural drift, testing gaps                           | Fix now or defer separately |
| 🟡  | Style    | `\|\|` vs `??`, annotation style, naming, minor consistency                                   | Recommend separate PR       |

---

## Reviewer return format

Return all analysis as structured text so the main agent can render its summary
and wizard without re-fetching anything. You apply `clear` fixes to the working
tree as you go (per `SKILL.md`) and still return this same structured format
covering every finding — fixed and queued alike.

**If no commits diverge from main**, return only:

```text
STATUS: no-commits
```

**Otherwise**, return a preamble block followed by one block per finding:

```text
PREAMBLE
Commits: <list of commits, one per line>
Files changed: <list>
OpenSpec changes: <list or "None">
Change summary:
- <bullet 1>
- <bullet 2>
OpenSpec alignment: <"Fully aligned." or per-change findings>
TL;DR: <2–4 sentence paragraph>
Risk level: <High / Medium / Low>
Ship recommendation: <Approve / Needs Revision / Block>
Total findings: <N> 🔴 <N> 🟠 <N> 🟡 <N>
Dispositions: <N> applied · <N> queued · <N> refuted · <N> design-stop
END_PREAMBLE

---
#: <N>
Severity: <🔴 Blocker / 🟠 Warning / 🟡 Style>
Lens: <lens name>
Category: <correctness | convention | simplification | efficiency | altitude>
File: <file path> L<line>
Summary: <one-line summary>
Issue: <what is wrong>
Why it matters: <impact>
Suggested fix: <concrete action>
Fix class: <clear | decision-needing>
Disposition: <applied | queued | design-stop | refuted>
Fix note: <one line — only on `applied`; the auto-fix log entry>
Refuted because: <one line — only on `refuted`; why it was considered and dropped>
Code context: L<start>–L<end>
<relevant lines>
---
```

Every finding carries **both vocabularies** so the record serves both consumers
without re-analysis: `Severity` + `Lens` + `Fix class` drive the operator wizard;
`Category` + `Disposition` are the run-log projection (`judge_findings`). The main
agent renders the **auto-fixed table** from `Disposition: applied` blocks and the
**decision queue** from `Disposition: queued` (+ any `design-stop`) — both derived
views of this one format, not separate outputs. A caller (build) folds the
`Category`/`Disposition`/`Summary` triple into its run-log row **verbatim** — it
never re-summarizes.

### `Category` field (run-log projection)

Tag every finding with exactly one of the five judge-rubric categories
(`correctness` / `convention` / `simplification` / `efficiency` / `altitude`) — the
same vocabulary the harness run-log (`judge_findings[].category`) and
`QUALITY_SCORE.md` use. The lens→category map is **not** 1:1 — the category depends
on _why_ the finding matters, which is a judgment only the reviewer (who read the
code) can make, not the caller folding findings after the fact:

- Security / a broken invariant / silent data loss → **correctness**
- Repo-idiom / naming / untested pure logic / hardcoding a binding → **convention**
- Dead code / collapsible duplication / an abstraction with no committed use → **simplification**
- Redundant work / missing memoization / polling where events exist → **efficiency**
- Logic in the wrong tier / a change quietly expanding product scope → **altitude**

### `Fix class` field

`Fix class` decides auto-fix vs queue. Classify:

- **clear** — one obvious correct resolution, no trade-off: a missing test, a
  wrong OpenAPI shape vs runtime, a stale doc reference, an unused export, a
  lint/type/style fix. The fix does not change product scope or pick between
  defensible alternatives.
- **decision-needing** — a trade-off, a scope question, an architectural call,
  or anything where two reasonable engineers could pick differently. These reach
  the operator; they are never auto-fixed.

When in doubt, classify **decision-needing**. Surfacing a borderline finding is
cheap; silently auto-fixing a judgment call is not.

### `Disposition` field (what happened to the finding)

- **applied** — a `clear` fix the reviewer applied to the working tree (never
  committed — see `SKILL.md` Model-A fix ownership). Carries a `Fix note`.
- **queued** — a `decision-needing` finding awaiting the operator's call. A
  **transient** state: it exists only until the wizard resolves it. `build-run`
  mode has no wizard, so a `decision-needing` finding there never stays `queued` —
  it is either auto-refuted or escalated to `design-stop`.
- **design-stop** — a design-level problem (not a nit): stop and surface for a
  human. In `build-run` this is build's genuine-fork mechanism; in
  `pre-ship`/`operator` it heads the wizard's decision queue.
- **refuted** — considered and **rejected**, with a reason (`Refuted because`).
  Honest refutation is signal — the run-log records it so the aggregate review
  isn't skewed optimistic. Emit refuted findings; do not silently drop a
  considered-and-dropped concern.

The run-log only ever persists `applied` / `refuted` / `design-stop` (the
`queued` transient is resolved before any row is written), matching the run-log
schema's disposition enum exactly.
