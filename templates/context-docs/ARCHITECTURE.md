<!-- HARNESS TEMPLATE — author this file, then delete this line. harness:init will not proceed while this marker is present. -->
# Architecture

How the system is built. Load-bearing: architecture/design reviews ground on this. Get the contracts exact.

## Shape & layering
- One-paragraph topology: the major parts and how they fit (a diagram helps).
- Name the layers/tiers and what each owns.

## Boundaries
- Where the seams are; what crosses each seam and what must not.
- Which concerns are forbidden from leaking across a boundary.

## Key contracts (load-bearing — get these exact)
- The protocols/interfaces/message shapes other code depends on; treat names + shapes as a contract.
- For each: who calls it, the payload/signature, the effect. Don't rename or "simplify" without updating both sides and this doc.

## Dependencies
- External deps and why each earns its place; the rule for adding a new one.
- What is vendored vs packaged vs called as a service.

## Testability
- What is pure/unit-testable and where it must live so tests can reach it.
- What is NOT unit-tested (and is verified by build/run instead) — name those surfaces.
- The layering rule a change must respect (e.g. keep logic out of the untestable surface).
