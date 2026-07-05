<!-- harness:workflow START — managed by harness:init; edit outside the markers, not inside -->
## Development workflow — the `harness:` pipeline

Engineering work runs through the **harness** pipeline, not ad-hoc edits. Route *every* change through it —
small changes don't opt out, they run **spec-less** (lighter: no formal spec, still sensors + review + ship).

- **New work** → `/harness:refine <intent>` → `/harness:build` (full-spec *or* spec-less → implement → verify)
  - `refine` picks the weight: **full** spec for behavior/contract changes · lightweight **spec-less** for
    small ones (`build` records the mode and adapts, escalating to full if a small change turns spec-worthy).
- **Where am I / what's next** → `/harness:status`
- **Test what was built** → `/harness:test-guide`
- **Ship** → `/harness:ship` → PR review → `/harness:finish` (close + archive)

Bindings (sensors · paths · tracker): `docs/HARNESS.md`.
<!-- harness:workflow END -->
