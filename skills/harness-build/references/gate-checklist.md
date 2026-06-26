# Surface Inference & Waiver Log

In `harness:build` the operator gate is the **H2 spec-review** (gated mode, after tasks, before impl) —
not a pre-apply review checklist (build runs `harness:architecture`/`harness:design` itself in Step C).
This reference covers the two reusable pieces from the original gate skill: **surface inference**
(feeds Step B review routing and Step E surface mapping) and the **waiver-log format**.

## Surface inference rules

Scan task/spec descriptions for these signals. Match by content category, adapt vocabulary to the
project — the goal is classification, not term-matching:

| Signal in description | Inferred surface |
|----------------------|-----------------|
| `.tsx`, `.css`, component names, UI, layout, animation, tooltip, panel, sheet | frontend |
| routes, services, repositories, migrations, entities, API contract, controller, schema | backend |
| `docs/`, `.md`, ADR | docs |
| Multiple signals | mixed |

- **frontend** → routes to `harness:design` (and architecture if it also has component internals).
- **backend** → routes to `harness:architecture`.
- **mixed / full-stack** → both (run-when-in-doubt).
- **docs-only / pure refactor / trivial** → may select no review.

## Skip conditions (a surface legitimately needs no review)

- Pure backend refactor with no user-visible surface (still architecture-eligible if non-trivial).
- Schema/migration-only with no UI or error-message impact → architecture only.
- Doc-only changes.
- Trivial fixes (typo, rename within one file).

## Waiver-log format

When build records a deliberate skip — a surface that selected **no** reviews, or **yolo** skipping
the H2 gate — append to the change-state dir's waiver log:

```text
<change-state-dir>/waivers.md (append or create):

- <what was skipped and why — e.g. "Surface selected no reviews (docs-only)." /
  "H2 spec-review skipped (yolo mode — invocation is consent).">
  Date: <ISO timestamp>
```

## Why inference, not artifact detection

Detecting a marker file from each review skill only works if every review writes to a known path —
coupling to one review ecosystem. In a project with different review tools, artifact detection would
always report "not run." Surface inference + the operator's own knowledge (at H2) is portable across
any project.
