# Commit Grouping

## Approach: auto-commit per group

One commit per major-`N` task group. No escape hatches, no staging-only mode. The pre-commit gate
fires on each commit — this is the correctness mechanism.

## Group type classification

Classify each group's commit type by what its tasks predominantly do:

| Group nature | Commit type | Example scope |
|-------------|-------------|---------------|
| Creates new components or files | `feat` | the primary package |
| Modifies existing components | `refactor` | the primary package |
| All tasks are test files | `test` | the primary package |
| Renames keys, moves namespaces | `refactor(<area>)` | — |
| Deletes files, removes dead code | `refactor` | the primary package |
| Doc-only changes | `docs` | — |
| Verification gates (run-many, grep audits) | `chore(verify)` | — |
| Mixed (impl + tests in same group) | `feat` or `refactor` | primary package |

**Scope** = primary package/dir touched by the group, expressed in the project's own convention.
When multiple packages: use the one with the most task touchpoints. When equal, use the app-level
package over the library package. Omit `(<scope>)` entirely in a single-package project.

## Commit message format

```text
<type>(<scope>): <summary> (<N.first>–<N.last>)

Tasks:
- N.1: <one-line description copied from task>
- N.2: <one-line description copied from task>
...

Co-Authored-By: <per environment>
```

Subject line rules:
- ≤72 characters including the task-range suffix.
- Summary is the group's purpose in plain English — not a list of files.
- Task range is always included (`(1.1–1.5)`, `(6.1–6.7)`) for traceability.
- **Serial-fallback** (no `N.M` task IDs): drop the trailing range suffix; single subject describing
  the change as a whole.

## Groups that are NOT committed by build

Classified by predominant task content (not by group number):

| Predominant content | Reason |
|--------------------|--------|
| Sync deltas, open PR, archive change | Operator-owned. Sync/archive (`harness:finish`) and PR (`harness:ship`) are separate steps. |

## Prerequisite inline fixes

If a task requires fixing an adjacent issue to ship correctly (per Decision Visibility), the fix is
included in the group's commit. The body must name the fix **and its causal reason**:

```text
feat(<scope>): add feature repository and service (2.1–2.4)

Tasks:
- 2.1: Create FeatureRepository
- 2.2: Create FeatureService
- 2.3: Add FeatureResponseDto to shared
- 2.4: Add toFeatureResponseDto mapper

Prerequisite: fixed BaseEntity import in shared barrel — the mapper would have shipped with a broken
import because the barrel export was missing the new DTO file.

Co-Authored-By: <per environment>
```

## Rationale

One commit per group gives:
- **Bisectable history** — bisect can isolate which group introduced a regression.
- **Atomic rollback** — `git reset --soft HEAD~1` reverts exactly one group.
- **Pre-commit gate per group** — the project's verification fires N times, not once at the end.
- **PR review readability** — reviewers see N logical commits, not one blob.
