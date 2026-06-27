---
name: harness:ship
description: >-
  Commit the current work and open a PR following the repo's release-automation contract — Conventional
  Commit subjects and a Conventional squash-merge title (the version is derived from that title). Use
  when asked to ship / commit / open a PR / land a change — typically after harness:build reaches
  verified-not-shipped and you've tested, or as the chore-PR step of harness:finish. Encodes the branch
  → format → test → commit → PR flow so a wrong subject never silently breaks the release. Confirms
  before the high-blast-radius push.
argument-hint: "[pr-title]"
metadata:
  author: acatl
  version: "0.1.0"
---

# harness:ship — push + open PR

Versioning is **driven by commit subjects**: a non-conforming subject produces **no release —
silently**. This skill exists so that never happens.

> **Bindings.** Resolve from `docs/HARNESS.md`: format sensor, branch/commit conventions, version
> source, pre-push gate, task-tracker `link` verb + `PR open` stage hook, PR host. Never hardcode.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:ship v<hash8>` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`). `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars.
- **end:** `■ harness:ship → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable.

## Contract (load-bearing)
- **No direct commits to the default branch.** Branch → PR → squash-merge.
- **Conventional Commits** on every commit subject **and** the PR squash title (the release tool
  parses the title): `feat:`→minor · `fix:`→patch · `feat!:`/`BREAKING CHANGE:`→major ·
  `chore/ci/docs/refactor/test/style:`→no release.
- **Pure-logic changes ship with tests in the same PR** (framework per HARNESS.md). Changed a
  parser/derivation/matcher/formatter without a test → stop, add one before shipping.
- **Substantive PR body** — what (behavior), why (trajectory/prerequisites), risk surface. One-line
  bodies are defects on non-trivial changes.

## Flow
1. **Verify cleanliness & branch.** On the default branch → create one first (`<type>-<slug>` prefix
   per HARNESS.md). Never commit to the default branch.
2. **Format.** Run the `format` sensor (HARNESS.md), re-stage. (The pre-push gate enforces strict lint
   + tests; formatting now avoids a blocked push.)
3. **Stage & review.** `git add -A`, show the diff summary, confirm it matches intent before committing.
4. **Commit** with a Conventional subject; body explains *why* when not obvious. Add the
   `Co-Authored-By` trailer if the environment requires one.
5. **Push** — high-blast-radius. **Confirm with the user before pushing.** The pre-push gate runs the
   project's sensors; if it blocks, fix and retry — never bypass it.
6. **Open the PR** (PR host per HARNESS.md, e.g. `gh pr create`). The **PR title MUST be a Conventional
   Commit** matching the intended release bump — it's the squash title the release tool reads. Write a
   substantive body (what / why / risk).
7. **Report** the PR URL. Task tracker: set the `link` verb (`pullRequestUrl` + `branchName`) and fire
   the `PR open` stage hook (HARNESS.md) — **ask before writing to the tracker.**
8. **Next pointer.** End by telling the operator: once the PR is **merged**, run `harness:finish` to
   sync delta specs, archive the change, close the task, and backfill the run-log (two-merge mode:
   `finish` opens the chore PR for the second merge). Closes the pipeline loop — don't leave it implicit.

## Don't
- **Don't squash-merge yourself** unless asked — merging the auto-generated release PR is a separate,
  deliberate act.
- **Docs/CI-only → `docs:` / `ci:`** — those intentionally produce no release.
- **Never hardcode or bump the version by hand** — the release tool owns the version source (HARNESS.md).
- **Never push without the confirm.**
