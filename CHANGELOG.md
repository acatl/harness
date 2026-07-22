# Changelog

All notable changes to this project are documented here. Versioning follows
[Semantic Versioning](https://semver.org/).

From the next release onward this file is maintained **automatically by
[release-please](https://github.com/googleapis/release-please)** from Conventional Commit messages —
don't hand-edit released sections. Pending changes live in the standing "Release PR", not in an
`Unreleased` heading here.

## [1.3.1](https://github.com/acatl/harness/compare/harness-pipeline-v1.3.0...harness-pipeline-v1.3.1) (2026-07-22)


### Bug Fixes

* de-fence test-guide scenario cards and stop review-change gating obvious fixes ([#42](https://github.com/acatl/harness/issues/42)) ([7826a03](https://github.com/acatl/harness/commit/7826a038f3e7b9a0e6f152d76b6f3f6f8d87e4aa))
* **review-change:** de-fence fork-card templates so they render as markdown ([#40](https://github.com/acatl/harness/issues/40)) ([c919648](https://github.com/acatl/harness/commit/c919648eaebc40be988b33677cca2f0c47ee1926))

## [1.3.0](https://github.com/acatl/harness/compare/harness-pipeline-v1.2.2...harness-pipeline-v1.3.0) (2026-07-16)


### Features

* **chart:** refocus explore into harness:chart — chart the how, advisory to build ([#35](https://github.com/acatl/harness/issues/35)) ([5af3bde](https://github.com/acatl/harness/commit/5af3bde7d7e246d25056e3e8e1bd9a855c3cd6fc))

## [1.2.2](https://github.com/acatl/harness/compare/harness-pipeline-v1.2.1...harness-pipeline-v1.2.2) (2026-07-14)


### Bug Fixes

* **walk-me-through:** fix fork card rendering and fence callout markup ([#32](https://github.com/acatl/harness/issues/32)) ([b4ea161](https://github.com/acatl/harness/commit/b4ea161587d19b3b6895fdc8f41c4657bcdc115b))

## [1.2.1](https://github.com/acatl/harness/compare/harness-pipeline-v1.2.0...harness-pipeline-v1.2.1) (2026-07-13)


### Bug Fixes

* **fine-tune:** guard exit handoff against premature /harness:finish pointer ([#30](https://github.com/acatl/harness/issues/30)) ([d2fc7f4](https://github.com/acatl/harness/commit/d2fc7f4f3ad216ad64db4e162adff74c8fedfa9b))

## [1.2.0](https://github.com/acatl/harness/compare/harness-pipeline-v1.1.0...harness-pipeline-v1.2.0) (2026-07-12)


### Features

* **explore:** sequence threads build-order with auto-advance and escape hatches ([#28](https://github.com/acatl/harness/issues/28)) ([5533497](https://github.com/acatl/harness/commit/55334974f17cb8f0ee47cd627def30d86ab15e60))
* **skills:** class-of-issue sweep + guided test-guide ([#27](https://github.com/acatl/harness/issues/27)) ([18c6767](https://github.com/acatl/harness/commit/18c67678e3ee9d8695b3fcbb06335e1a12e50b4f))

## [1.1.0](https://github.com/acatl/harness/compare/harness-pipeline-v1.0.1...harness-pipeline-v1.1.0) (2026-07-09)


### Features

* **harness:** version-stamp the workflow block + drift-detect from status ([#24](https://github.com/acatl/harness/issues/24)) ([9038ec1](https://github.com/acatl/harness/commit/9038ec12281fe56569df16e859231e9f860b2de9))


### Bug Fixes

* **pipeline:** resolve Finish merge mode in end-stop next-pointers ([#26](https://github.com/acatl/harness/issues/26)) ([e3c91be](https://github.com/acatl/harness/commit/e3c91be1c941a889f7c035cbd74a45752c14a3fe))

## [1.0.1](https://github.com/acatl/harness/compare/harness-pipeline-v1.0.0...harness-pipeline-v1.0.1) (2026-07-07)


### Bug Fixes

* **init:** complete injected workflow block and document refresh path ([#21](https://github.com/acatl/harness/issues/21)) ([002adbc](https://github.com/acatl/harness/commit/002adbca20392f5a6112a34802376faba117e9cd))
* **skills:** defer release-model + default-branch conventions to HARNESS.md ([#23](https://github.com/acatl/harness/issues/23)) ([799bb71](https://github.com/acatl/harness/commit/799bb7152a755254c7b13f86dd020f9ae18daf23))

## [1.0.0](https://github.com/acatl/harness/compare/harness-pipeline-v0.2.0...harness-pipeline-v1.0.0) (2026-07-06)


### ⚠ BREAKING CHANGES

* canonical skill path moved to `.claude/skills/`.  Hand-rolled symlinks to `skills/` break; re-consume via  `npx skills add --copy acatl/harness#<tag>`.
* **review-change:** `harness:review` (the run-log aggregator) is renamed `harness:retro`; `/harness:review` no longer resolves.

### Features

* **build:** spec-less build mode for small changes ([#14](https://github.com/acatl/harness/issues/14)) ([fb275fb](https://github.com/acatl/harness/commit/fb275fbc2219f6a896d9cfe004583803251cf8fd))
* **review-change:** extract shared 3-mode review engine; rename review→retro ([#12](https://github.com/acatl/harness/issues/12)) ([b260957](https://github.com/acatl/harness/commit/b26095785de78dfe9d5d58b40d69e074bee91ac6))


### Code Refactoring

* relocate skills to .claude/skills and add authoring governance ([#15](https://github.com/acatl/harness/issues/15)) ([abf0651](https://github.com/acatl/harness/commit/abf065154496cc8051ab6036dce7a1810d6fa87a))

## [0.2.0](https://github.com/acatl/harness/compare/harness-pipeline-v0.1.0...harness-pipeline-v0.2.0) (2026-07-02)


### Features

* add HARNESS.md binding template and run-log schema ([dc9f951](https://github.com/acatl/harness/commit/dc9f95131c35cf67da1b4c34a269c7ef5df0dc2a))
* **architecture:** add harness:architecture skill + telegraphic skill style ([c8134e3](https://github.com/acatl/harness/commit/c8134e351a52aaeaca29811200bb34d13f8f1bb7))
* **build:** assemble harness:build from verified source map ([7a12c88](https://github.com/acatl/harness/commit/7a12c888d00b16b759fe20e518a585f5b8ea4fd5))
* **design:** add harness:design skill + full design lenses ([0846c94](https://github.com/acatl/harness/commit/0846c949957d303699e58ace587e800e9dfde006))
* **explore,fine-tune:** port harness:explore + harness:fine-tune ([3ecda06](https://github.com/acatl/harness/commit/3ecda0633dae6bc9a83fc2a94535156632ac8646))
* **finish:** add harness:finish skill — Phase 3 complete ([02db7ad](https://github.com/acatl/harness/commit/02db7add8b5f92eeb8c525b670c467ac594f1b89))
* harness pipeline foundation — stack-agnostic spec-driven skills ([46605e1](https://github.com/acatl/harness/commit/46605e1018c1df3ddb231afb38fd87ae06bcd840))
* **harness:** comprehensive pipeline skill suite with walk-me-through decisions, artifact management, and operator orientation (AC-final) ([#2](https://github.com/acatl/harness/issues/2)) ([465cdc9](https://github.com/acatl/harness/commit/465cdc9383893fd1769f630cc560ae37e94be6d2))
* **init:** add harness:init skill ([81f7376](https://github.com/acatl/harness/commit/81f73764ccf23a1eaa18bbc454bf1d0eef92c836))
* **init:** gate OpenSpec CLI + tier context docs (generate rubric, template+stop the rest) ([1850888](https://github.com/acatl/harness/commit/1850888538f3455238261a0831f398d0aa231353))
* **init:** stack-aware baseline-sensor gate + per-stack matrix ([5d0e0d2](https://github.com/acatl/harness/commit/5d0e0d203b4a074bf87acd65804688939652c4c2))
* **recon:** add harness:recon skill + wire project context docs ([631a2a1](https://github.com/acatl/harness/commit/631a2a12eb9c810fb7931e0967696f859471471f))
* **refine:** pure-text walk-me-through forks + visible completeness additions ([b0f2d62](https://github.com/acatl/harness/commit/b0f2d6223587103a720e0d63d090e783e544cd23))
* **review,address-pr-comments:** port remaining skills + fold run into binding ([6b52a55](https://github.com/acatl/harness/commit/6b52a559d4b0f8f3a9b7fb85e3b2471b197915f1))
* **ship,refine:** port harness:ship + harness:refine ([2b6ddbd](https://github.com/acatl/harness/commit/2b6ddbd63b783413065aa3838702135ff5a560c9))
* **skills:** add start/end breadcrumbs for transcript-based harness observability ([713feb3](https://github.com/acatl/harness/commit/713feb31d584982cbd41e86d797cadd53b3a6bc4))


### Bug Fixes

* **architecture:** keep judgment criteria full, telegraphic only the procedure ([dbfc75b](https://github.com/acatl/harness/commit/dbfc75bfc790e26dc12ff2613c2d7a086c22d5c5))
* **init:** discover+confirm context docs by role, not fixed paths ([bcb1cac](https://github.com/acatl/harness/commit/bcb1cac0cc814bff6d32f051d4134728d9e769d8))
* **init:** halt when OpenSpec not initialized — never auto-scaffold ([cfdb00b](https://github.com/acatl/harness/commit/cfdb00b77a4261d3ad1977772fe03dd24455ffb8))
* **init:** self-contained HARNESS.md refs + seed openspec config feedforward ([c2d59e7](https://github.com/acatl/harness/commit/c2d59e7fe29425350f0949e6fac520c35d275d9b))
* **sensor-baseline:** require explicit Python typing config to gate type-check ([772cbde](https://github.com/acatl/harness/commit/772cbdef4a5f69edfd62fc128cbb7223cbdb7ec3))
* **sensor-baseline:** section-qualify Python test/lint config markers ([64d5fda](https://github.com/acatl/harness/commit/64d5fdaed4a1860cf7818852b2284796b42038bf))
* **skills,docs:** address CodeRabbit review on PR [#1](https://github.com/acatl/harness/issues/1) ([a41ff95](https://github.com/acatl/harness/commit/a41ff952c812e3345e68bdf390c6d01f565258c6))
* **skills:** bundle runtime inputs in-dir so skills are self-contained ([33f038b](https://github.com/acatl/harness/commit/33f038b5557f39f0ac88a49aaaefbf3347a93b60))

## [0.1.0] - 2026-06-29

Initial harness pipeline: the full `harness:*` skill suite (`init`, `recon`, `architecture`, `design`,
`build`, `ship`, `refine`, `explore`, `fine-tune`, `review`, `address-pr-comments`, `finish`, `status`,
`test-guide`) plus `walk-me-through`, the `docs/HARNESS.md` binding template, the run-log schema, and
the repo-health pass (MIT license, lint/spell/link CI, CONTRIBUTING, PR template). See `git log` for
the full commit history.

[0.1.0]: https://github.com/acatl/harness/releases/tag/v0.1.0
