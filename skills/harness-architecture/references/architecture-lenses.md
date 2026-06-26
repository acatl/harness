# Architecture Review Lenses

Detailed criteria per review area. Apply only relevant lenses. **Layer-general principles,
backend-shaped examples** — on other layers apply the lens *kernel*, not the literal example (a
"service" may be a container component; an "endpoint" any consumed interface). Each lens has an
`Applies to:` tag; skip a lens only when its tag excludes the surface, never because examples look
backend-shaped.

## 1. API Design Quality
**Applies to:** any callable interface (HTTP/RPC/CLI/SDK). Kernel (predictable, idempotent, bounded contracts) = all; HTTP mechanics = HTTP only.
- **Verbs:** GET = safe + idempotent (state change on GET = correctness error); POST = create/non-idempotent (return created resource); PUT = full replace (idempotent); PATCH = partial; DELETE = idempotent (already-gone → 404/204, not error). Wrong verb → flag.
- **Status codes:** 201 (+Location/body) create; 200 update-with-body / 204 no-body; 400 client validation; 401 unauth; 403 authenticated-no-permission; 404 missing **or unauthorized-owned** (avoid leaking existence); 409 conflict (dup key, invalid transition); 422 valid-but-business-rule-fail; 500 unexpected only. Error condition with no status code → flag.
- **Naming:** plural nouns (`/tasks` not `/getTask`); nested = ownership (`/projects/:id/tasks`); consistent casing.
- **Idempotency:** any queue/job-invoked op must be idempotent (at-least-once delivery); spec states semantics or review flags.
- **Pagination:** every unbounded list defines strategy; cursor > offset for time-ordered/changing data; spec defines cursor + page-size limit + envelope.
- **Param placement:** path = primary id; query = filters/sort/page/optional on GET; body = POST/PUT/PATCH. Sensitive data never in query (logs, referrers).

## 2. API Contract Consistency
**Applies to:** any layer (HTTP fields, component props, module exports, event shapes, CLI flags).
- **Naming:** match existing case + field names (`createdAt` not `created_at`/`dateCreated`).
- **Error shape:** match established error body; new codes follow convention (UPPER_SNAKE); reuse generic codes, don't invent per-endpoint ones.
- **Auth pattern:** same mechanism as siblings; same gating (skipping ownership "internal only" = security gap).
- **Envelope:** single = object directly; list = items + pagination meta, matching existing shape.
- **Versioning:** new surface fits the existing versioning strategy.

## 3. Data Model Decisions
**Applies to:** persistence only — skip when no storage touched.
- **Column types:** match semantics not immediate use; money/business calc = exact decimal/numeric, never float.
- **Constraints:** NOT NULL default; UNIQUE at DB level (app-level is racy); CHECK for fixed ranges/sets; FK explicit with documented CASCADE (CASCADE silently deletes children — RESTRICT safer; state which + why).
- **Normalization:** denormalization intentional + documented + has a sync/consistency strategy; stored derived values need a maintenance contract (trigger/job/event).
- **Indexes:** every WHERE/JOIN/ORDER BY column indexed (missing FK index = full scan = most common+expensive miss); composite ordered by selectivity, matching WHERE order; unique index doubles as constraint + lookup.
- **NULL semantics:** NULL = unknown/absent, not a sentinel for false/zero/N-A (breaks comparisons/aggregates). Sentinel NULL → flag; use default or separate boolean.
- **Enum vs lookup table:** enum/constants for app-defined fixed sets; lookup table for operator-editable values. Wrong choice = join pain or deploy friction.
- **Soft delete:** every "active" query filters the flag; unique constraints must account for soft-deleted rows (re-register collision); spec defines filtering + uniqueness + restore.

## 4. Separation of Concerns
**Applies to:** any layer (controller/service/repo = presentational/container = pure-core/effectful-shell = command/handler/store).
- **Controller:** only extract+validate input, call service, write response. Conditional logic / queries / business rules → flag. Controller→repo (bypassing service) = correctness risk.
- **Service:** domain logic, orchestration, ownership, repo coordination. Constructing/parsing HTTP objects = framework coupling (untestable). Complex ORM-entity construction belongs in repo.
- **Repository:** owns domain↔persistence mapping; no business rules; repo→repo = implicit coupling (coordinate in a service).
- **Validation placement:** at the system boundary (controller/first external-data layer); service-only validation bypassed by internal callers.
- **Shared logic:** used by >1 app → shared package, not duplicated, not buried in one app's internals.
- **Framework coupling:** domain code must not import framework types (`import { Request } from 'express'` in a service = violation).

## 5. Security Surface
**Applies to:** mixed. Boundary-validation + sensitive-data-in-logs = any-layer; ownership/SQLi/rate-limit = backend (frontend analogs XSS/CSRF/bundle-secrets = different surface).
- **Auth:** every endpoint returning/modifying user data authenticated (state it / reference convention); public reads explicitly marked.
- **Ownership:** every owned-resource access path verifies requester owns it before read/modify — security invariant, not convention. By-ID with no ownership check = enumeration vuln → **Critical**. Return 404 (not 403) for unauthorized-owned (don't leak existence).
- **Input validation at boundary:** all external input (bodies, query, path, webhooks, uploads) validated at entry; spec defines per-field type/range/format/required.
- **Sensitive data:** never store/log plaintext passwords; secrets via env (never hardcode/commit); PII logged only as spec-defined; no real PII/keys in the spec.
- **Rate limiting:** auth endpoints (login/register/reset), account-modification, external-comms (email/SMS) specify limits (else enumeration/brute-force/abuse).
- **Injection:** external data into SQL strings = injection; require parameterized/ORM-mediated queries.

## 6. Error Handling & Failure Modes
**Applies to:** any layer.
- **Defined error conditions:** per op, min: invalid input, not-found, unauthorized, unexpected failure. Precondition-not-met → defined error + code + message.
- **External dependency failure:** per external call (auth/LLM/email/storage/API), state strategy: fail-fast / retry-backoff / enqueue / degrade. None = implicit unchecked propagation.
- **Background job failure:** retry count + backoff, exhausted-state, idempotency. Non-idempotent jobs documented + partial-completion strategy.
- **Partial failure:** multi-resource ops wrapped in a transaction OR compensating actions defined. Multi-table write with no transaction = accepted inconsistency.
- **Message quality:** specific enough to diagnose, no internal details; never return stack traces / ORM errors / internal ids; spec defines messages or their specificity.

## 7. Observability
**Applies to:** any layer (server logs, client error tracking, analytics, breadcrumbs).
- **Structured logging:** every state change logged with actor id + target id + prev→new state + timestamp.
- **Business events:** track intent-relevant events (task created/moved/completed, project created) with properties — answers "is it working as intended?".
- **Error observability:** logged with reproduce/diagnose context; unhandled errors surfaced to monitoring, not dropped.
- **Job observability:** log start/complete/fail with job id + entity ids; aggregate ("processed N, M failed") over per-record noise; failed jobs surfaced not silently retried.
- **Audit trail:** compliance/accountability ops (admin, permission change, deletion, financial) → audit entry identifying the natural person + target + before/after.

## 8. Concurrency & Race Conditions
**Applies to:** mixed. Principle (shared mutable state under concurrency needs coordination) universal; backend examples; frontend instances = stale closures, out-of-order async, double-submit, optimistic rollback.
- **Shared mutable state:** concurrent-writable field with no coordination = race. Counters (read-modify-write) lose updates → need atomic op / locking / serialized queue.
- **Find-or-create:** check-then-create is racy → unique constraint + handle violation, or lock.
- **State-machine transitions:** concurrent transitions → invalid state. Prevent via optimistic locking / row locks / atomic compare-and-swap.
- **Cache coherence:** define invalidation + acceptable staleness window.
- **Queue/job dedup:** same-entity jobs that must not run concurrently → dedup strategy (at-least-once = concurrent duplicates).

## 9. Performance Shape
**Applies to:** any layer ("algorithmic shape, cheap hot paths" — N+1 renders/fetch waterfalls too; main-thread sync too). Reason from shape, not benchmarks.
- **N+1:** list + per-item related fetch = N+1. Spec defines joins/eager/batching.
- **Hot paths:** every-request / high-frequency code must be cheap; expensive op on hot path → justify or mitigate (cache/async/precompute).
- **Sync vs async:** >few-hundred-ms / external-dep / decoupled-side-effect ops → background job. Image processing / email / webhooks / aggregation in a sync handler = blocking in the wrong place; spec states rationale.
- **Data volumes:** evaluate list/queries against realistic scale; full scan at 10M rows.
- **Expensive aggregates:** real-time count/sum/avg over large tables → precomputed / cached / justified at expected volume.

## 10. Dependency Decisions
**Applies to:** any layer (bundle/maintenance/security more acute on frontend).
- **New package:** widely used + maintained? solves a problem existing tools/stdlib can't? right-sized? (200KB transitive for a 20-line problem = poor trade).
- **Stdlib-doable:** utility packages for native runtime features = unnecessary.
- **Version constraints:** pinned or compatible range; known upcoming breaking change acknowledged + migration path.
- **External service:** how authenticated, what on unavailable, fallback/degraded mode. Assuming 100% availability = underspecified.
- **Build/deploy:** new env vars / credentials / infra / build-pipeline changes called out.

## 11. Testability
**Applies to:** any layer (hook, CLI command, service identical).
- **Injectability:** external deps (DB, APIs, clock, RNG) passed in, not created internally (else untestable without the real dep).
- **Side-effect isolation:** I/O / network / time / randomness separated from pure logic; core decision logic testable without infrastructure.
- **Seams:** async work has a verifiable "done" definition; avoid timing/sleep/poll/prod-infra integration tests.
- **Test data:** required states reachable via normal lifecycle, or describe how to simulate time-only states (expiry, scheduled completion).
- **Happy vs error path:** spec readable as test spec (clear input → expected output per requirement); external-failure errors simulable without the real service.

## 12. Migration & Backwards Compatibility
**Applies to:** mixed. Schema migrations = persistence; "breaking change to a consumed contract" = any-layer (props, signatures, event/queue schemas).
- **Completeness:** schema change includes a migration (up + down). New column/rename/constraint with no migration = incomplete.
- **Operation ordering:** don't modify data before altering the constraint it must satisfy. Correct: drop old constraint → transform data → add new constraint. Trace steps in sequence.
- **Down completeness:** restore exact pre-state (types, constraints, indexes, NOT NULL); down that restores structure but not populated data (NOT NULL) → flag.
- **Large-table risk:** add-with-default / type-change / index / constraint-rebuild can lock + cause downtime → state strategy (add column without default, batch backfill, NOT VALID then validate async).
- **Breaking API change:** removing/retyping/renaming a field or changing status codes is breaking → identify consumers + migration path (new version / deprecation / coordinated deploy). Adding optional fields/endpoints = non-breaking.
- **Backwards-compatible data migration:** changing meaning of existing data (re-label status, redefine NULL) must migrate existing records.

## 13. Evolvability
**Applies to:** any layer (extension points, config-vs-hardcode, coupling, pattern replication, interface stability).
- **Extension points:** natural place to add the next case vs modifying core logic everywhere. Hardcoded `if status===...` for a growing field → flag. "Works for today's 3 cases" insufficient if a 4th is signaled.
- **Config vs hardcoding:** likely-to-change values (rate limits, page sizes, timeouts, retries, caps, flags, thresholds) externalized as named constants/config, not magic numbers. "retry 3 times" / "max 50/page" with no home = hardcoded.
- **Horizontal coupling:** new dependency between previously-independent modules; shared structures read by many, events with many handlers, state written by many services = coupling. Acceptable if intentional + documented, not incidental.
- **Pattern introduction:** a new pattern (error handling, response shape, service structure, job type) will be replicated → documented clearly or referenced to an existing one (else replicated by inference, intent lost).
- **Interface stability:** multi-consumer interfaces (shared APIs, event/queue schemas) = stable contracts; change needs versioning/migration. Single-consumer-but-likely-to-grow → design for stability now (retrofitting later is costly).
- **Document non-obvious decisions:** why-this-over-simpler, why-a-constraint-exists, what-invariant-is-maintained documented where made (else next engineer breaks the invariant or fears to touch it).

## 14. Missing Technical Concerns
**Applies to:** any layer (catch-all). "Implied but never specified?" is universal.
- Schema change without migration.
- API endpoint without defined error contract.
- Background job enqueue without a handler spec.
- New filter/sort/join without index analysis.
- External integration without credentials/env documentation.
- New secrets without rotation/revocation strategy.
- State machine without enumerated valid/invalid transitions + guards.
- Async op without a completion signal (poll? webhook? DB state?).
- Admin operation without access control.

## 15. Frontend Component Architecture
**Applies to:** frontend component-facing changes only. Skip for backend/schema/integration/doc-only. Reviews *code structure* (placement, boundaries, composition, abstraction, state branches), **not** visual/interaction design (design review) or render perf/hooks/effects (code-time review).
- **Placement by use, not resemblance:** tier chosen by where consumed (route-private / app-shared / design-system). Spec states tier + consumer count. Single-consumer in shared, or reaching into another feature's private components → boundary violation, flag.
- **Data vs presentational boundary:** spec states who owns fetching, i18n, navigation. Shared component fetching its own data / resolving routes / reaching global state = coupled, breaks the reuse it was promoted for. Durable: shared/leaf take data + callbacks as props; owner injects. Data hook / router dep on a would-be-shared component → flag.
- **Abstraction justification (committed-use):** extract only with ≥2 named committed consumers today + stable interface. Generic configurable component with one consumer = speculative → write second concrete use first. Resemblance = consolidation candidate, not promotion reason.
- **Composition over configuration:** accumulating boolean/mode props (`isCompact`, `variant`, `showHeader`…) = two/three components in one; each flag multiplies branching + tests. Diverging uses → composition (slots/children/sub-components). Flag a prop interface growing flags to fork behavior.
- **State coverage as structure:** loading/empty/error/partial-failure = real render branches owned at the right level (list's empty state belongs to the list). Narrow structural question (committed + correct level), don't restate the design lens.
- **Convention conflicts:** documented frontend invariants (prefer the primitives lib, a server-owned value the client must not compute, an established state/data-fetch pattern) must not be contradicted. Hand-rolling a provided primitive / client-computing a backend-owned value → flag against the rule.
