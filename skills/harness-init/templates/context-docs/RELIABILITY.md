<!-- HARNESS TEMPLATE — author this file, then delete this line. harness:init will not proceed while this marker is present. -->
# Reliability

The invariants that cause real bugs if violated. These set what the sensors (and a reviewer) must confirm.
Every change touching the areas below is checked against this list.

## Runtime invariants

- The "always true" rules of the running system (concurrency/threading, ordering, idempotency, resource limits).
- For each: what breaks if it's violated.

## State & persistence

- What must survive (crash, restart, reload) and what is derived/recomputable.
- Consistency rules — what must never drift from its source of truth.

## Failure modes

- The expected failure cases and the required behavior for each (degrade, retry, notify, never silently lose).
- What must NOT happen on failure (e.g. don't blank healthy state, don't auto-discard user work).

## What "green" means

- The full bar a change must clear to count as passing (sensors + any runtime/behavioral confirmation).
- When a build+test pass is sufficient vs when observing the running behavior is required.
