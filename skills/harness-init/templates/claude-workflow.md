<!-- harness:workflow START — managed by harness:init; edit outside the markers, not inside -->
## Development workflow — the `harness:` pipeline

Engineering work runs through the **harness** pipeline, not ad-hoc edits. For any feature, bug, or
non-trivial change, route it through the harness (or note an explicit opt-out).

- **New work** → `/harness:refine <intent>` → `/harness:build` (spec → implement → verify)
- **Where am I / what's next** → `/harness:status`
- **Test what was built** → `/harness:test-guide`
- **Ship** → `/harness:ship` → PR review → `/harness:finish` (close + archive)

Bindings (sensors · paths · tracker): `docs/HARNESS.md`.
<!-- harness:workflow END -->
