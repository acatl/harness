# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versioning follows
[Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- `CODE_OF_CONDUCT.md`, `SECURITY.md`.
- Shellcheck CI gate over `scripts/*.sh`.
- Husky + commitlint, enforcing the existing Conventional Commits rule mechanically.
- Explicit task-tracker declaration (GitHub Issues) for this project's own meta-work.

### Removed

- `docs/PORTING-PLAN.md` — personal planning diary; its still-open threads were filed as individual
  GitHub issues before removal.

## [0.1.0] - 2026-06-29

Initial harness pipeline: the full `harness:*` skill suite (`init`, `recon`, `architecture`, `design`,
`build`, `ship`, `refine`, `explore`, `fine-tune`, `review`, `address-pr-comments`, `finish`, `status`,
`test-guide`) plus `walk-me-through`, the `docs/HARNESS.md` binding template, the run-log schema, and
the repo-health pass (MIT license, lint/spell/link CI, CONTRIBUTING, PR template). See `git log` for
the full commit history.

[Unreleased]: https://github.com/acatl/harness/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/acatl/harness/releases/tag/v0.1.0
