# Architecture Review Lenses

Detailed criteria for each review area. Apply the lenses relevant to what's being built — don't force all of them onto every spec.

**Layer-general principles, backend-shaped examples.** Most specs touch the server, so examples are HTTP/schema/service-shaped. On other layers (component, CLI, library, function) apply the lens *kernel*, not its literal example — a "service" may be a container component, an "endpoint" any consumed interface. Each lens carries an `Applies to:` tag. Skip a lens only when its tag excludes the surface in front of you, never because the examples look backend-shaped.

---

## 1. API Design Quality

**Applies to:** any callable interface (HTTP/REST, RPC, CLI, SDK). The kernel — predictable, idempotent, bounded contracts — applies to all; the HTTP-specific mechanics (verbs, status codes, pagination) apply only to HTTP/REST surfaces.

Checks the mechanics — HTTP semantics, naming, contract shape — not whether the endpoint exists.

**HTTP method correctness:**

- GET for reads — must be safe (no side effects) and idempotent. A GET that triggers a state change is a correctness error.
- POST for creation and non-idempotent operations. POST responses for creation should return the created resource, not just an acknowledgment.
- PUT for full replacement (idempotent — calling it twice produces the same result as calling it once). PATCH for partial updates.
- DELETE for removal (idempotent — deleting something that's already gone should return 404 or 204, not an error).
- Verify the spec uses the right verb for the described operation. Mismatched verbs produce confusing API surfaces that break client expectations.

**Status code correctness:**

- 201 Created (with Location header or body) for successful resource creation via POST.
- 200 OK for updates that return the updated resource; 204 No Content for updates or deletes that don't return a body.
- 400 Bad Request for client-caused validation failures.
- 401 Unauthorized for unauthenticated requests to protected resources.
- 403 Forbidden for authenticated requests that lack permission.
- 404 Not Found for missing resources — and for resources the user doesn't own (to avoid leaking existence of unauthorized resources).
- 409 Conflict for state conflicts (e.g., duplicate unique key, invalid state transition).
- 422 Unprocessable Entity for structurally valid requests that fail business rules.
- 500 Internal Server Error is for unexpected failures only — not for validation or business rule violations.
- If a spec describes an error condition without specifying a status code, flag it.

**Resource naming:**

- Resources are plural nouns: `/tasks`, `/projects`, `/features` — not `/getTask`, `/createProject`, `/fetchFeature`.
- Nested resources should reflect ownership: `/projects/:projectId/tasks`, not a flat `/tasks?projectId=...` for access-controlled resources.
- Consistent casing: if the API uses kebab-case in paths, all new paths should follow suit.

**Idempotency:**

- Any operation that will be called from a queue or background job must be idempotent. A message may be delivered more than once. An operation that creates duplicate records or double-charges is a correctness failure.
- The spec should either describe idempotency semantics explicitly, or the review should flag that they're needed.

**Pagination for list endpoints:**

- Every endpoint that returns a potentially unbounded list must define a pagination strategy.
- Cursor-based pagination is preferable for time-ordered data or data that changes frequently. Offset-based is simpler but produces gaps/duplicates when records are added or removed mid-pagination.
- The spec should define: what the cursor is, what the page size limit is, and what the response envelope looks like (total count, next cursor, items).

**Request body vs. query parameter vs. path parameter:**

- Path parameters (`/tasks/:id`) for the primary resource identifier.
- Query parameters (`?status=active`) for filters, sorting, pagination, and optional modifiers on GET requests.
- Request body (JSON) for POST/PUT/PATCH payloads.
- Sensitive data (auth tokens, passwords, PII) must never appear in query parameters — they end up in server logs and referrer headers.

---

## 2. API Contract Consistency

**Applies to:** any layer. "Match sibling-interface conventions" — HTTP fields, component props, module exports, event shapes, CLI flags.

A new surface that introduces patterns inconsistent with the rest of the API creates an incoherent one.

**Naming conventions:**

- Does the new endpoint follow the same naming conventions as existing ones? If the API uses camelCase in JSON bodies, the new endpoint should too. If existing paths are kebab-case, new paths should match.
- Field names should be consistent with semantically equivalent fields elsewhere in the API. If existing resources use `createdAt`, a new resource should not use `created_at` or `dateCreated`.

**Error response shape:**

- Does the error response body follow the established error contract? If the API returns `{ "error": { "code": "...", "message": "..." } }`, new endpoints must return the same shape.
- New error codes should follow the existing naming convention (e.g., UPPER_SNAKE_CASE).
- Generic error codes (`BAD_REQUEST`, `NOT_FOUND`) should be used consistently — don't invent endpoint-specific error codes for common conditions.

**Authentication and authorization patterns:**

- If the API uses a specific auth mechanism (bearer token, session cookie, API key), new endpoints must use the same mechanism — not a different one for convenience.
- If the API gates endpoints by role or ownership, new endpoints must follow the same gating pattern. An endpoint that skips the ownership check because it's "internal use only" is a security gap, not an exception.

**Response envelope consistency:**

- Single resources: return the object directly. List resources: return an envelope with items and pagination metadata.
- If existing list responses include `{ "data": [...], "meta": { "total": N, "next": "..." } }`, new list endpoints should match that shape.
- Partial responses, sparse fieldsets, or field inclusions should be consistent with how other endpoints handle them.

**Versioning:**

- Does the API have an explicit versioning strategy? New endpoints must fit it. Introducing an unversioned endpoint in a versioned API, or a versioned endpoint in an unversioned one, creates an inconsistency that's expensive to unify later.

---

## 3. Data Model Decisions

**Applies to:** persistence. No non-backend instance — skip when the spec doesn't touch storage.

Schema decisions are the most expensive to reverse. A wrong column type, a missing constraint, or a normalization choice made without considering query patterns will constrain every future feature that touches this data.

**Column type choices:**

- Types must match the semantic meaning of the data, not just the immediate use case. Storing a monetary amount as an integer (cents) or as a decimal? Storing a percentage as an integer or a float? Storing a UUID as a string or a native UUID type? Each choice has downstream implications for precision, comparison behavior, and type-safety.
- Numeric columns intended for business calculations must use exact types (decimal/numeric), not floating-point. Floating-point arithmetic on financial data produces subtle, hard-to-reproduce bugs.

**Constraints:**

- NOT NULL should be the default. A nullable column that is never intended to be null is a correctness gap — it allows a class of invalid state to exist in the database that the application must defensively handle everywhere.
- UNIQUE constraints should be applied at the database level, not just enforced by application logic. Application-level uniqueness is racy under concurrent writes.
- CHECK constraints should be used for values with fixed valid ranges or sets that are unlikely to change. They prevent invalid data from ever entering the database.
- Foreign key constraints should be explicit with documented CASCADE behavior. ON DELETE CASCADE on a parent record can silently remove large amounts of child data. ON DELETE RESTRICT is safer and forces intentional cleanup. The spec should state which is appropriate and why.

**Normalization decisions:**

- Denormalization is sometimes the right call for read performance, but it must be intentional and documented. Denormalized data must have a defined consistency strategy — how is it kept in sync with its source?
- Storing computed or derived values (totals, counts, aggregate states) is a denormalization. These are valid but require an explicit maintenance contract (triggers, job, event handler).

**Index strategy:**

- Every column used in a WHERE clause, JOIN condition, or ORDER BY in a described query needs an index. A missing index on a foreign key is the most common and most expensive oversight — without it, every JOIN involving that key causes a full table scan.
- Composite indexes should be ordered by selectivity (most selective column first) and should match the WHERE clause field order.
- Unique indexes serve double duty: they enforce uniqueness and speed up lookups. If a combination of fields must be unique, a composite unique index is the right tool.

**NULL semantics:**

- NULL means "unknown" or "absent" — it is not a sentinel value. Using NULL to mean "false," "zero," or "not applicable" produces unexpected behavior in comparisons and aggregate functions (`NULL != NULL`, `SUM()` ignores NULLs, `COUNT(*)` vs `COUNT(col)` differ).
- If a column uses NULL as a sentinel, flag it. Define a non-NULL default or a separate boolean column instead.

**Enum vs. lookup table:**

- Use database enums (or application-level constants mapped to strings) for sets of values that are defined by the application and will not be changed by operators at runtime.
- Use a lookup table for values that operators may need to add, remove, or rename without a code deployment.
- The wrong choice in either direction causes operational pain: a lookup table for something that should be an enum creates unnecessary joins and fragile string matching; an enum for something operators need to manage creates deployment friction for trivial changes.

**Soft delete implications:**

- Soft delete (marking a record as deleted rather than removing it) has performance and correctness implications that are often underspecified.
- Every query that returns "active" records must filter on the soft-delete flag — this is a class of bugs that appears gradually as deleted records surface in unexpected places.
- Unique constraints must account for soft-deleted records. A unique constraint on `email` will fail if a soft-deleted user tries to re-register with the same email.
- The spec should define: how soft-deleted records are filtered in queries, how uniqueness is enforced, and whether/how soft-deleted records can be restored.

---

## 4. Separation of Concerns

**Applies to:** any layer. Controller/service/repository = presentational/container = pure-core/effectful-shell = command/handler/store: one boundary, different names.

The right logic in the right layer. Violations here create tangled, hard-to-test code that gradually degrades the ability to change any part of the system without touching everything else.

**Controller responsibility:**

- Controllers should do exactly three things: extract and validate input from the request, call a service with that input, and write the response.
- A controller that contains conditional logic, database queries, or business rules is out of scope. Flag it.
- A controller that calls a repository directly (bypassing the service layer) is bypassing the ownership and validation logic that lives in the service. This is a correctness risk, not just a style issue.

**Service responsibility:**

- Services contain domain logic: orchestration, business rules, ownership enforcement, and coordination between repositories.
- A service that constructs or parses HTTP request/response objects has framework coupling — domain logic should not know it's being called over HTTP. This makes it untestable without an HTTP stack.
- A service that directly constructs ORM entities in complex ways that belong in the repository layer is over-reaching. The repository should own the mapping between domain data and persistence.

**Repository responsibility:**

- Repositories own the mapping between domain objects and the persistence layer. They should not contain business rules.
- A repository that calls other repositories (rather than a service coordinating across repositories) creates implicit coupling between persistence concerns.

**Validation placement:**

- Input validation must happen at the system boundary — the controller or the first layer that accepts external data. Validation that lives only in the service layer is bypassed by any internal caller.
- The spec should state where validation occurs, especially for fields that have complex rules.

**Shared logic placement:**

- Logic that will be used by more than one application (API and worker, for example) must live in a shared package — not duplicated across applications, and not in a single application's internal modules where the other can't import it.
- If the spec describes logic that clearly belongs in a shared location but places it inside a single application, flag it.

**Framework coupling in domain code:**

- Domain logic (service layer, repositories, domain models) must not import framework-specific types or utilities. Framework code stays at the edges (controllers, middleware, entry points).
- An `import { Request } from 'express'` inside a service file is a separation of concerns violation.

---

## 5. Security Surface

**Applies to:** mixed. Boundary-validation and sensitive-data-in-logs are any-layer; ownership, SQLi, rate-limiting are backend instances (frontend analogs — XSS, CSRF, client-bundle secrets — are a different surface).

Where specs commonly leave the security surface unaddressed.

**Authentication on protected endpoints:**

- Every endpoint that returns or modifies user data must be authenticated. The spec should either state the authentication requirement explicitly or reference an established convention.
- Unauthenticated read endpoints (public content) should be explicitly marked as such — not left ambiguous.

**Ownership enforcement:**

- Every data-access path that touches user-owned resources must verify that the requesting user owns the resource before returning or modifying it.
- This is a security invariant, not a convention. An endpoint that retrieves a resource by ID without checking ownership allows any authenticated user to access any other user's data by guessing or enumerating IDs.
- The spec should explicitly state ownership verification for every endpoint that touches owned resources. If it doesn't, flag it as a Critical finding.
- Returning 404 for unauthorized access (rather than 403) is the correct behavior for user-owned resources — it avoids leaking the existence of resources the requester doesn't own.

**Input validation at the boundary:**

- All data that enters the system from outside — request bodies, query parameters, path parameters, webhook payloads, file uploads — must be validated at the point it enters.
- Validation that happens only later in the call stack can be bypassed by internal callers. It also means invalid data may propagate further into the system before being caught, making errors harder to trace.
- The spec should define validation rules for each input field: type, range, format, required/optional. If it doesn't, the implementation will invent them inconsistently.

**Sensitive data handling:**

- Passwords must never be stored or logged in plain text.
- Tokens, API keys, and secrets must be handled via environment variables — never hardcoded or committed.
- PII (email addresses, names, payment data) should be logged only in circumstances explicitly defined by the spec. The spec should call out which fields are sensitive and how they're handled.
- The spec should not contain real email addresses, API keys, or PII — only placeholder examples.

**Rate limiting on sensitive endpoints:**

- Authentication endpoints (login, registration, password reset), account modification endpoints, and any endpoint that sends external communications (email, SMS) should specify rate limiting.
- Without rate limiting, these endpoints are vulnerable to enumeration, brute force, and abuse at scale.

**SQL injection and parameterization:**

- Query construction that interpolates untrusted input directly into SQL strings is an injection vulnerability. All queries involving external data must use parameterized queries or ORM-mediated access.
- If the spec describes raw SQL queries, verify that parameters are handled safely.

---

## 6. Error Handling and Failure Modes

**Applies to:** any layer. A component calling an API has the same questions as a service calling a dependency: error states, dependency-down, partial-failure, user-safe messages.

A spec that defines the happy path without defining failure behavior is half a spec.

**Defined error conditions:**

- For every operation the spec describes, what are the error conditions? At minimum: invalid input, resource not found, unauthorized access, and unexpected failure.
- If an operation depends on external state (a resource must be in a specific status before the operation is valid), what happens when that precondition isn't met? The spec should define the error, its code, and its message.

**External dependency failures:**

- If the spec introduces a call to an external service (auth provider, LLM provider, email provider, storage service, another API), what happens when that service is unavailable or returns an error?
- Options include: fail fast and surface the error to the caller; retry with backoff; enqueue for retry; degrade gracefully with a fallback. The spec should state which applies and why.
- An external call with no failure strategy is an implicit decision to let the failure propagate to the user unchecked.

**Background job failure handling:**

- If the spec introduces a background job, what happens when the job fails?
- The spec should define: retry behavior (how many times, with what backoff), the failure state when retries are exhausted, and whether the job is idempotent (safe to retry without side effects).
- Jobs that are not idempotent should be explicitly documented as such, with a strategy for handling partial completion.

**Partial operation failures:**

- If an operation modifies multiple resources (multiple DB writes, a DB write + an external call), what happens if it fails midway?
- Operations that modify multiple resources should either be wrapped in a transaction (atomic), or the spec should define compensating actions for partial failure.
- A spec that writes to multiple tables without a transaction is implicitly accepting the possibility of inconsistent state.

**Error message quality:**

- Error messages returned to callers should be specific enough to diagnose the problem without exposing internal implementation details.
- Stack traces, ORM error objects, and internal identifiers must never be returned to external callers.
- The spec should define error messages or at least their level of specificity.

---

## 7. Observability

**Applies to:** any layer. Server logs, client error tracking, analytics events, breadcrumbs — same "operable and diagnosable?" question.

Without observability, problems in production take longer to detect and diagnose.

**Structured logging for state changes:**

- Every state-changing operation (record created, updated, deleted; status changed; permission granted or revoked) should be logged with structured context: who did it, what was affected, what changed.
- The minimum useful log entry for a state change contains: acting entity identifier, target entity identifier, previous state, new state, and timestamp.
- A spec that describes state-changing operations without specifying what gets logged is leaving observability to chance.

**Business event tracking:**

- Beyond technical logging, business-relevant events should be tracked. Not for vanity metrics — for understanding whether the feature is working as intended.
- Examples: "task created", "task moved to in-progress", "task completed by agent", "project created". These events answer questions like "are agents and humans both producing mutations as expected?" and "how long do tasks sit in each column?"
- The spec should identify which business events are worth tracking and what properties should be included.

**Error observability:**

- Errors should be logged with enough context to reproduce and diagnose without access to the user's session or request.
- Unhandled errors should be surfaced to monitoring, not silently dropped.
- The spec should describe what happens to errors — logged and surfaced, or handled and swallowed.

**Background job observability:**

- Background jobs should log their start, completion, and failure with job ID and relevant entity identifiers.
- If a job touches many records, per-record logging at INFO level may produce noise; aggregate logging ("processed N records, M failed") is often more useful.
- Failed jobs should be surfaced to monitoring, not just retried silently.

**Audit trail requirements:**

- Operations that have compliance or accountability implications (admin actions, permission changes, data deletions, financial events) should produce an audit log entry.
- Audit logs need to identify the natural person responsible for the action (not just a system or service identifier), the target, and the full before/after state.
- The spec should identify which operations require audit logging and what the audit entry contains.

---

## 8. Concurrency and Race Conditions

**Applies to:** mixed. Principle (shared mutable state under concurrency needs coordination) is universal; examples are backend/distributed. Frontend instances differ — stale closures, out-of-order async, double-submit, optimistic rollback.

Races are invisible at development traffic and appear suddenly at scale.

**Shared mutable state:**

- Any field that can be modified by concurrent processes without a coordination mechanism is a potential race condition.
- Counter columns (incrementing a count, decrementing a balance, updating a sum) are the most common example. Two concurrent increments that both read the same value and write value+1 will lose one of the increments.
- The spec should describe how concurrent writes to shared state are handled: database-level atomic operations, pessimistic locking, optimistic locking with retry, or serialized access through a queue.

**Find-or-create patterns:**

- A pattern that checks for the existence of a record and creates it if absent is racy. Two concurrent requests that both miss the read and both attempt the create will produce a duplicate key violation (if there's a unique constraint) or silent duplicates (if there isn't).
- The spec should describe how this pattern is handled: a unique constraint at the database level with application-level handling of the constraint violation, or a locking mechanism.

**Status machine transitions:**

- If an entity has a state machine (status transitions from A to B to C), concurrent transitions can move the entity into an invalid state.
- The spec should describe how invalid transitions are prevented: check-then-act patterns protected by optimistic locking, row-level locks, or atomic compare-and-swap operations.

**Cache coherence:**

- If a spec introduces or modifies caching, it should define when cached values are invalidated.
- A cached value written by one process that's read by another before invalidation produces stale reads. The spec should define the acceptable staleness window and the invalidation mechanism.

**Queue and job deduplication:**

- If a spec enqueues jobs that should not run concurrently for the same entity (e.g., two "rebuild project rank index" jobs for the same project ID), it should describe the deduplication strategy.
- Without deduplication, at-least-once delivery guarantees mean the same job may run concurrently on multiple workers, producing duplicate effects.

---

## 9. Performance Shape

**Applies to:** any layer. "Algorithmic shape, cheap hot paths" — N+1 renders and fetch waterfalls as much as N+1 queries; sync-vs-async on the main thread as much as the request handler.

Whether the design has an acceptable performance profile — reasoned from algorithmic shape, not benchmarking.

**Query patterns and N+1 risks:**

- A spec that describes fetching a list of resources and then fetching related data for each one is describing an N+1 query pattern. At 10 items, this is fast. At 1,000 items, it's catastrophic.
- Look for list operations that imply related data access per item. The spec should describe how related data is fetched (joins, eager loading, batching) — not leave it to the implementer.

**Operations on hot paths:**

- Hot paths — code executed on every request, or on high-frequency operations — must be cheap. Expensive operations (external API calls, large DB queries, complex aggregations) on hot paths create bottlenecks.
- The spec should acknowledge if it's placing an expensive operation on a hot path, and justify or mitigate it (caching, async offloading, pre-computation).

**Sync vs. async decisions:**

- Operations that take more than a few hundred milliseconds, depend on external services, or produce side effects decoupled from the user's immediate need should run asynchronously in a background job.
- A spec that places image processing, email sending, external webhook calls, or aggregation computations inside synchronous request handlers is describing a blocking operation on a path where it doesn't belong.
- The spec should state the rationale for synchronous vs. asynchronous execution, not leave it implicit.

**Expected data volumes:**

- List endpoints and queries should be evaluated against realistic data volumes. A query that scans a table of 1,000 rows is fine; the same query against 10 million rows may be a full table scan.
- The spec should describe the expected scale, and the review should check whether the described data access pattern holds at that scale.

**Expensive aggregate queries:**

- Counting, summing, or averaging large datasets in a synchronous query is expensive. If the spec introduces real-time aggregates over large tables, it should describe whether these are pre-computed, cached, or acceptably expensive at the expected data volume.

---

## 10. Dependency Decisions

**Applies to:** any layer. Bundle size, maintenance, and security surface are more acute on the frontend.

Every new dependency is a bet: that the package solves the problem well, that it will be maintained, that it won't introduce breaking changes, and that its cost in bundle size, security surface, and cognitive overhead is worth the benefit.

**New packages introduced:**

- Is a new package being introduced? If so: is it widely used and actively maintained? Is the package solving a problem that existing tools (in the project or in the standard library) couldn't handle? Is it right-sized for the problem, or is a large package being pulled in for a small feature?
- A package that adds 200KB of transitive dependencies to solve a 20-line problem is a poor trade.

**Package for something the standard library can do:**

- Utility packages introduced for functionality that modern runtimes provide natively are unnecessary dependencies. The spec should be checked against what the project's runtime provides before recommending a new package.

**Version constraints:**

- Are new packages pinned to a specific version, or constrained to a compatible range? Pinning prevents unexpected breaking changes; overly wide ranges allow them.
- If a package has a known breaking change in an upcoming major version, the spec should acknowledge this and describe the migration path.

**External service integrations:**

- If the spec introduces a dependency on an external service (third-party API, cloud service, authentication provider), it should describe: how the integration is authenticated, what happens when the service is unavailable, and whether there's a fallback or degraded mode.
- External services go down, change their APIs, and impose rate limits. A spec that assumes 100% availability of an external service is underspecified.

**Build and deployment implications:**

- Does the new dependency require new environment variables, credentials, or infrastructure? If so, the spec should document them.
- Does the dependency require changes to the build pipeline (new build steps, different transpilation, native module compilation)? These should be called out explicitly.

---

## 11. Testability

**Applies to:** any layer. Injectability and pure/effectful separation are identical for a hook, a CLI command, and a service.

A design without a viable test strategy goes untested or accretes brittle, hard-to-maintain tests.

**Injectability and dependency isolation:**

- Services and other units with external dependencies (database, external APIs, clock, random number generation) should receive those dependencies as constructor or function arguments, not create them internally.
- A service that instantiates its own database connection or HTTP client internally cannot be tested without the real dependency. The spec should describe the dependency interface, and the design should make it injectable.

**Side effect isolation:**

- Side effects (I/O, network calls, time-dependent behavior, randomness) should be isolated from pure business logic.
- A function that mixes computation with I/O is harder to test than one that separates them. The spec's described logic should be evaluable: can the core decision-making logic be tested without setting up infrastructure?

**Seams for verification:**

- Background jobs, event handlers, and queued work are harder to test than synchronous request handlers. The spec should describe what constitutes "done" for an asynchronous operation in a way that's verifiable in a test.
- Integration tests that require specific timing, sleep/polling, or production infrastructure are fragile. The spec should describe an interface that tests can interact with deterministically.

**Test data requirements:**

- Does the described feature require specific data states to test? If so, are those states achievable through the normal application lifecycle, or do they require manual database manipulation?
- A spec that introduces states that are only reachable through time (expiry, scheduled job completion) should describe how those states can be simulated in tests.

**Happy path vs. error path testability:**

- Error paths are often harder to test than happy paths. The spec should be readable as a test specification: for each requirement, is there a clear input that exercises it and a clear expected output?
- If the spec describes error conditions that depend on external service failures, it should be possible to simulate those failures in tests without involving the real external service.

---

## 12. Migration and Backwards Compatibility

**Applies to:** mixed. Schema migrations are persistence-specific; "breaking change to a consumed contract" is any-layer — component props, util signatures, event schemas, queue messages.

A wrong migration can corrupt data or take down a service; a breaking API change can silently break consumers.

**Migration completeness:**

- If the spec changes the data schema, it must include a migration. A spec that describes a new column, a renamed field, or a changed constraint without a migration is incomplete.
- The migration should describe both the up (forward) migration and the down (rollback) migration.

**Migration operation ordering:**

- Within a migration, the order of operations matters. The most common ordering error: modifying data (UPDATE, INSERT) before altering the constraint that the data must satisfy.
- The correct order for modifying a constraint: drop the old constraint, transform the data to satisfy the new constraint, add the new constraint.
- The review should trace through the migration steps in sequence to verify ordering.

**Down migration completeness:**

- A down migration must restore the schema to its exact pre-migration state: column types, constraints, indexes, and NOT NULL properties — not an approximation.
- Down migrations that restore structure without restoring data (for columns that were added with data populated during the up migration) should be flagged — rolling back the migration will leave the column empty, which may violate NOT NULL.

**Large table migration risk:**

- Migrations that add columns with defaults, change column types, add indexes, or rebuild constraints on large tables can lock the table for extended periods, causing downtime.
- The spec should acknowledge if it involves a table with significant data volume, and describe the strategy for running the migration without downtime (e.g., adding the column without a default, backfilling in batches, adding the constraint as NOT VALID then validating asynchronously).

**Breaking API changes:**

- Any change to an existing API endpoint that removes a field, changes a field's type, renames a field, or changes status codes is a breaking change.
- The spec should identify existing consumers of the modified endpoint and describe the migration path: a new endpoint version, a deprecation period, or a coordinated deployment.
- Adding optional fields or new endpoints is non-breaking. Removing or modifying existing contracts is breaking.

**Backwards-compatible data migration:**

- If the spec changes the meaning of existing data (re-labeling a status value, changing what NULL means in a column), it must describe how existing records are migrated.
- A migration that changes the schema without migrating existing data leaves the application in a state where old records behave differently from new ones — a class of bugs that's hard to diagnose.

---

## 13. Evolvability

**Applies to:** any layer. Extension points, config-vs-hardcoding, coupling, pattern replication, interface stability — surface-independent.

Can the design accommodate its next version, or will extending it require a rewrite? Evolvability problems are invisible at initial delivery and expensive once data, integrations, and habits have formed around the wrong design.

**Extension points and dead-end designs:**

- Does the design have a natural place to add the next case, or does adding it require modifying core logic everywhere?
- A status field with hardcoded branching logic (`if status === 'A' ... else if status === 'B'`) is harder to extend than a state machine with a registry of handlers. A spec that describes the former for a field that will clearly grow should flag the extensibility gap.
- "Works for the three cases we have today" is not sufficient if the spec's own non-goals or background suggests a fourth case is likely. Flag it, even if addressing it is explicitly deferred.

**Configuration vs. hardcoding:**

- Values that are likely to change — rate limits, page sizes, timeout durations, retry counts, price caps, feature flags, thresholds — should be externalized as named constants or configuration, not embedded as magic numbers in logic.
- A spec that describes "retry up to 3 times" or "maximum 50 items per page" without specifying where that value lives is implicitly describing a hardcoded value. When the business needs to change it, the change requires a code deploy and a search-and-replace, not a config update.
- This is especially important for values that operations teams may need to adjust without a code deployment.

**Horizontal coupling between modules:**

- Does this change introduce a dependency between two modules that were previously independent? A feature that works fine as a standalone concern but imports from three other domains to function is creating coupling that will make future changes painful — modifying any of those domains requires reasoning about the effect on this one.
- The spec should be evaluated for implicit coupling: shared data structures that will be read by multiple consumers, events that multiple handlers will subscribe to, state that multiple services will write to. Each of these is coupling, and coupling accumulates.
- Coupling is sometimes necessary. What matters is whether it's intentional and documented, or incidental and invisible.

**Pattern introduction and documentation:**

- If the spec introduces a new pattern — a new way of handling errors, a new response shape, a new service structure, a new job type — that pattern will be replicated when the next similar thing is built. Is it documented clearly enough to be replicated correctly?
- A pattern introduced without documentation will be replicated by inference. Developers will infer from the first implementation, not from intent. Subtle aspects of the original design will be misunderstood or dropped.
- The spec should either reference an existing documented pattern, or describe the new pattern with enough specificity that its intent is clear.

**Interface stability:**

- Interfaces consumed by more than one part of the system (shared package APIs, event schemas, queue message shapes) should be treated as stable contracts. A spec that changes these without an explicit versioning or migration strategy is introducing a breaking change that may not surface until another part of the system fails.
- Internal APIs that are currently consumed by only one caller but are likely to gain consumers should be designed with stability in mind from the start. Retrofitting stability onto an interface that has grown organically across multiple callers is significantly more expensive.

**Documentation of non-obvious decisions:**

- Decisions that are not obvious from the code — why a particular approach was chosen over a simpler one, why a constraint exists, what invariant a particular structure is maintaining — should be documented where the decision was made.
- A spec that describes a non-obvious implementation choice without explaining the reason will produce code with a comment-less decision. The next engineer will either leave it alone (even if it should change) or change it (breaking the invariant it was maintaining).
- The review should flag non-obvious decisions in the spec and ask whether they're documented with sufficient rationale.

---

## 14. Missing Technical Concerns

**Applies to:** any layer (catch-all). Listed patterns are backend-shaped because the project is; the "implied but never specified?" question is universal.

Gaps between what the spec describes and what the implementation will actually need — often the most impactful findings.

**Common patterns to look for:**

**Schema changes without migrations.** The spec describes a new field, a changed relationship, or a new table but contains no migration. The implementation will need one. Flag it.

**API endpoints without defined error contracts.** The spec describes what the endpoint does when it succeeds but doesn't define the error codes and messages for failure cases. The implementation will invent them inconsistently.

**Background jobs without worker handlers.** The spec describes enqueueing a job but doesn't describe the handler that processes it. Both halves of the system need to be specced.

**New query patterns without index analysis.** The spec introduces a new filter, sort, or join that implies a query. The query may require a new index. If the spec doesn't mention it, it won't be created.

**External integrations without credentials documentation.** The spec describes calling an external service but doesn't list the environment variables needed to configure the integration. Deployment will fail silently.

**New secrets without rotation strategy.** The spec introduces new API keys or credentials without describing how they're managed, rotated, or revoked. This is an operational gap that becomes a security gap over time.

**State machines without transition diagrams.** The spec introduces entity status transitions but doesn't enumerate all valid transitions, invalid transitions, and the guards that enforce them. Implementations without this will handle edge cases inconsistently.

**Async operations without completion signals.** The spec describes an asynchronous operation but doesn't describe how callers or dependent systems know when it's done. Polling? Webhook? Database state? The absence of a defined completion signal makes integration fragile.

**Admin operations without access control.** The spec introduces an administrative operation but doesn't define who can perform it and under what conditions. Admin endpoints that aren't explicitly access-controlled are a security gap.

---

## 15. Frontend Component Architecture

**Applies to:** frontend — component-facing changes only. Spec-time complement to the any-layer lenses; covers what has no backend instance.

This lens applies only when the change introduces or restructures UI components. It reviews the *code-structure* decisions a spec makes or omits — placement, ownership boundaries, composition, abstraction, and state branches — not visual or interaction design (that is the design review's job). The goal is to catch structural decisions that are cheap to fix in the spec and expensive once the component tree and its import graph have formed.

Skip this lens entirely for backend-only, schema-only, integration-only, or doc-only specs.

**Placement by use, not resemblance:**

- A component belongs in a tier chosen by *where it is consumed*, not by what it resembles. Most frontends have an implicit or documented hierarchy: route/page-private components, an app-shared tier, and a cross-app design-system/primitives tier. If the project documents a placement convention, read it and hold the spec to it; if not, apply the general principle.
- The spec should state, for each new component, which tier it lives in and the consumer count that justifies that tier. A component used by one screen is private to that screen.
- A spec that places a single-consumer component in a shared location, or that reaches into another route/feature's private components, describes a boundary violation. Flag it — this is the drift that erodes a placement convention, and it is invisible once the import exists.

**Data vs. presentational boundary:**

- The spec should state who owns data fetching, string/i18n resolution, and navigation for the new component. A shared/reusable component that fetches its own data, resolves its own routes, or reaches global state is coupled to one context and cannot be reused in another — the reuse it was promoted for is the thing it breaks.
- The durable pattern: shared/leaf components receive data and callbacks as props; the owning route/page performs fetching and navigation and injects them. If the spec hangs a data hook or a router dependency on a would-be-shared component, flag it — in projects that enforce this boundary with lint, it also fails at apply.

**Abstraction justification (committed-use):**

- Extracting a shared or design-system component is a bet that it will be reused. The bet is justified only when there are at least two *named, committed* consumers today and the interface is stable enough that a third consumer won't force a rewrite. "Might be reused" is not a committed use.
- A spec that introduces a generic, configurable component with a single consumer is speculative abstraction — flag it and recommend writing the second concrete use first, then extracting. Resemblance between two single-consumer components is a consolidation candidate, not a promotion reason.

**Composition over configuration:**

- A component whose spec accumulates many boolean/mode props (`isCompact`, `isInline`, `variant`, `showHeader`, `withFooter`…) to serve divergent uses is usually two or three components wearing one name. Each flag multiplies the internal branching and the test surface.
- When uses diverge, the spec should prefer composition (slots/children/sub-components) over a widening prop matrix. Flag a prop interface that grows flags to fork behavior — it is cheaper to split at spec time than after every call site depends on the combined component.

**State coverage as component structure:**

- Loading, empty, error, and partial-failure are *rendered states*, not afterthoughts. The spec should commit each relevant state to a real render branch on the new component, owned at the right level (a list's empty state belongs to the list, not its parent page).
- This overlaps the design review, which asks whether each state is *designed*. This lens asks the narrower structural question: does the spec commit the component to handling them, and at the correct level? Keep the finding to the structural gap; don't restate the design lens.

**Convention conflicts and load-bearing invariants:**

- If the project documents frontend invariants — a primitives library to prefer over hand-rolling, a value the server owns that the client must never compute, an established state-management or data-fetching pattern — the spec must not contradict them. A component spec that hand-rolls a primitive the design system already provides, or that computes client-side a value the backend owns, is a convention conflict. Flag it against the documented rule.
