---
name: harness:ship
description: >-
  Commit the current work and open a PR following the repo's release-automation contract — Conventional
  Commit subjects and a Conventional squash-merge title (the version is derived from that title). Use
  when asked to ship / commit / open a PR / land a change — typically after harness:build reaches
  verified-not-shipped and you've tested, or as the chore-PR step of harness:finish. Encodes the branch
  → format → test → commit → PR flow so a wrong subject never silently breaks the release. Pushes +
  opens the PR on invocation — no push yes/no (the pre-push gate is the guard).
argument-hint: "[pr-title]"
metadata:
  author: acatl
  version: "0.2.0" # x-release-please-version
---

# harness:ship — push + open PR

Versioning is **driven by commit subjects**: a non-conforming subject produces **no release —
silently**. This skill exists so that never happens.

> **Bindings.** Resolve from `docs/HARNESS.md`: format sensor, branch/commit conventions, version
> source, pre-push gate, task-tracker `link` verb + `PR open` stage hook, PR host, change-state dir.
> Never hardcode.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:ship` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:ship v<hash8> → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable. `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

## Contract (load-bearing)
- **No direct commits to the default branch.** Branch → PR → squash-merge.
- **Conventional Commits** on every commit subject **and** the PR squash title (the release tool
  parses the title): `feat:`→minor · `fix:`→patch · `feat!:`/`BREAKING CHANGE:`→major ·
  `chore/ci/docs/refactor/test/style:`→no release.
- **Pure-logic changes ship with tests in the same PR** (framework per HARNESS.md). Changed a
  parser/derivation/matcher/formatter without a test → stop, add one before shipping.
- **Substantive PR body** — what (behavior), why (trajectory/prerequisites), risk surface. One-line
  bodies are defects on non-trivial changes.
- **No internal yes/no gates.** Invoking `ship` is consent through commit → push → PR; **announce and
  proceed, never gate** (no push confirm, no pre-commit confirm). A genuine ≥2-option fork (e.g. PR-scoping,
  or a **decision-needing pre-ship review finding** — Step 3) still renders as a walk-me-through fork card
  (`references/walk-me-through.md`), reply by letter; never `AskUserQuestion`. A **clean** pre-ship review
  is not a fork — it never stops; ship proceeds to push exactly as today.

## Flow
1. **Verify cleanliness & branch.** On the default branch → create one first (`<type>-<slug>` prefix
   per HARNESS.md). Never commit to the default branch.
2. **Format.** Run the `format` sensor (HARNESS.md), re-stage. (The pre-push gate enforces strict lint
   + tests; formatting now avoids a blocked push.)
3. **Pre-ship review (`harness:review-change`).** Invoke `harness:review-change` (Skill tool) in
   **`pre-ship`** mode. It reviews the whole branch (`origin/main...HEAD`) **thin** — the cross-commit
   seams + any commit no `build-run` review covered — through the 13 lenses / 4 stances, and **applies
   clear fixes to the working tree**. Runs **here, before Step 4 stages**, so those fixes ride the one
   atomic ship commit (never a second commit or an amend). **A clean review does not stop** — announce
   "review clean" and continue. Only **decision-needing** findings open the review's fork-card wizard;
   resolve them, apply the chosen fixes, then continue — this is the Contract's genuine-fork carve-out,
   not a new push gate. Skip only for a docs/CI-only change with no reviewable code surface.
4. **Refresh the PR-body artifact, then stage & review (announce, don't gate).** If the change has a build
   handoff at `<change-state-dir>/pr-body.md`, **re-fold it now** per `references/pr-summary.md`
   (idempotency: skip the fold if the footer's `folded-against` still matches HEAD, excluding summary-only
   commits) — **before** staging, so the refreshed audit artifact is committed + pushed with this ship
   commit and never left dirty. On a fold, stamp the footer (`folded-against` = `git rev-parse HEAD`;
   `generated-by: harness:ship v<hash8>`). Then `git add -A`, **show the diff summary** so what's being
   committed is visible — then proceed (no confirm). If the summary surfaces something clearly unintended
   (a stray/secret file), stop and surface that; otherwise commit.
5. **Commit** with a Conventional subject; body explains *why* when not obvious. Add the
   `Co-Authored-By` trailer if the environment requires one.
6. **Announce, then push — no confirm (invoking `ship` IS consent).** Push + open-PR is ship's declared
   purpose, so running it is the consent; **never ask a push yes/no.** First **announce the planned PR** —
   the Conventional squash **title** (it drives the release bump), a one-line body summary, and the bump —
   so the release-driving title is visible before it's public; then push immediately. The **pre-push gate**
   runs automatically and is the real guard: if it blocks, fix and retry — never bypass. (Same consent
   model whether standalone or as `finish`'s chore-PR step.)
7. **Open the PR** (PR host per HARNESS.md, e.g. `gh pr create`). The **PR title MUST be a Conventional
   Commit** matching the intended release bump — it's the squash title the release tool reads.
   **Body:** if the change has `<change-state-dir>/pr-body.md`, use it **as-is** for the PR body
   (`gh pr create --body-file <change-state-dir>/pr-body.md`) — it was refreshed + committed in **Step 4**,
   so it's on the branch and matches what's shipped. **Do NOT re-fold or write it here** — a post-commit
   write dirties the worktree and desyncs the artifact from the branch (that's the bug this ordering
   avoids). The decision log must reach the PR. **No artifact** (e.g. a non-build change with no
   change-state dir) → compose a substantive body inline for `gh pr create` folded per
   `references/pr-summary.md` (what / why / risk); there's nothing on-branch to keep in sync.
8. **Report** the PR URL. Task tracker: set the `link` verb (`pullRequestUrl` + `branchName`) and fire
   the `PR open` stage hook (HARNESS.md). **Active-ticket tracker writes are autonomous** — invoking
   `ship` is consent to drive *its own* ticket through the pipeline; fire the `link` verb + `PR open` hook
   without asking. (Only mutations to a *different* ticket, or creating/closing tickets outside this one,
   need a confirm.)
9. **Pipeline trail + Next pointer.** Emit the "you are here" trail for the `ship` end stop per
   `references/pipeline-map.md` (one line) — its `◦ finish` label carries the after-merge step, so the loop
   isn't silent. Then a `Next:` line naming **only the immediately-runnable action: review + merge the PR**
   (a human action — no command to run yet). **Do NOT print `/harness:finish` or "then run X after merge"
   here** — finish is premature until the PR merges, and naming a not-yet-runnable command invites a
   mis-fire (one runnable command rule, `references/pipeline-map.md`). finish surfaces as the trail's
   `◦ finish` label only.

## Don't
- **Don't squash-merge yourself** unless asked — merging the auto-generated release PR is a separate,
  deliberate act.
- **Docs/CI-only → `docs:` / `ci:`** — those intentionally produce no release.
- **Never hardcode or bump the version by hand** — the release tool owns the version source (HARNESS.md).
- **No push yes/no** — invoking `ship` is consent to push + open the PR (the pre-push gate is the guard).
  Still **never force-push** without an explicit request, and never squash-merge it yourself.
