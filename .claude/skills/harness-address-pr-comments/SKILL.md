---
name: harness:address-pr-comments
description: >
  Use when a PR has review comments (from bots, teammates, or external reviewers) that need structured
  triage and end-to-end resolution. Evaluates every comment thread, auto-fixes everything that does not
  require a load-bearing operator decision, walks the operator through only the decisions that genuinely
  need human judgment, then implements, commits, pushes, replies in-thread (machine-readable), resolves
  the threads it fixed, and reports. Triggers on "/harness:address-pr-comments", "address PR comments",
  "resolve the review comments", "close out CHANGES_REQUESTED". Not for: draft PRs with no comments,
  self-review, or PRs where all threads are already resolved. Not a code-review tool.
license: MIT
compatibility: Requires git + a PR host CLI (GitHub `gh` shown) + jq.
argument-hint: "#<pr-number>"
metadata:
  author: acatl
  version: "1.0.0" # x-release-please-version
---

# harness:address-pr-comments — PR comment triage + auto-resolve

End-to-end PR review-comment resolution. Arg: `/harness:address-pr-comments #21`. No number → infer
from current branch; else list open PRs and ask.

> **Bindings.** PR host per `docs/HARNESS.md` (GitHub via `gh` shown — substitute the project's host).
> Verify commands resolve from **HARNESS.md › Sensors** (fallback: dynamic derivation in Phase 3a).
> Project standards = the rules dir + context docs (HARNESS.md). Conventions (branch/commit) per HARNESS.md.

## Breadcrumbs
Emit one line at start and one at end — so harness iteration can trace this run in the session transcript:
- **start:** `▶ harness:address-pr-comments` followed by any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:address-pr-comments v<hash8> → <outcome>` — one-line result, including `stopped: <fork>` or `skipped: <reason>` when applicable. `<hash8>` = `git hash-object` of this SKILL.md, first 8 chars — compute it (run the command) as part of the end-of-run commands; never a placeholder.

## Operator input
👉 **marks the operator's turn.** Prefix any line that needs their answer — a question, a confirm, a pick — with `👉`, and make it the **terminal block**: below the breadcrumb/trail/next, nothing actionable under it. A blocking question buried above a ready action gets skipped — the eye must land on it last. While a `👉` prompt is open, don't render a runnable `/harness:` next as the move; show it as gated behind the answer. Distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

Act as a Principal Engineer. Every valid finding gets fixed, every invalid finding refuted, every
direction-affecting ambiguity surfaces to the operator. **Default bias: correctness, not scope.**

**Operating principles (override defaults):**
1. **Correctness over PR scope.** A valid finding gets fixed even outside the PR's stated scope. No
   "OUT OF SCOPE — defer" verdict. The only defer reason is a fix needing a load-bearing operator decision.
2. **Auto-fix is the default** for findings with a clear correct answer — implement immediately, no prompt.
3. **Only walk the operator through decisions that genuinely need judgment** (Decision Gate below).
4. **Stop only at genuine forks — no plan-approval gate.** After analysis, walk DECISION-NEEDED forks
   (5d), then run end-to-end with no per-step gates. Zero forks → straight to execution. Only stops: a
   DECISION-NEEDED finding (5d) or a mid-flight cascading Decision-Gate hit (6b.1). Invocation is consent
   for the full pipeline (commit/push/reply/resolve); a hard-gate failure (1.5) still aborts.
5. **Replies are machine-readable** — terse tagged format, no prose/gratitude.

## Decision Gate — when to ask the operator
**Positive test, not negative.** Default AUTO-FIX. A finding → DECISION-NEEDED **only** if a criterion
below clearly applies. Can't name the criterion → stays AUTO-FIX. "Might be load-bearing" isn't enough.

**Decision-needed (ask)** — any one true:
- **Public contract change** — exported API, response DTO shape, route shape, CLI flag, any symbol re-exported from a package index.
- **Schema / migration** — DB schema, add/remove column, migration behavior, default values for existing rows.
- **Architectural pattern** — new abstraction / dependency / directory pattern, or contradicts a load-bearing convention (rules dir / context docs).
- **Load-bearing config** — CI workflows, lockfiles, root/build config, shared tsconfig.
- **Equally-correct paths with different long-term tradeoffs** — ≥2 correct fixes, no ecosystem default, choice locks in downstream shape.
- **Reviewer contradicts an existing project standard** — decline with citation, or update the standard.
- **Irreversible / destructive** — deletion, public-symbol rename, breaking change.

**NOT decision-needed (auto-fix even though they touch real code):** typo/grammar/comment/doc-drift/
broken-link; missing null/bounds guard, off-by-one; wrong type / missing return type / `any` narrowing;
missing test for just-introduced behavior; dead code / unused import / unreachable branch; lint/format
violation; microcopy (contract stable); regex tightening; add `const` / narrow type / extract local;
mapper fixes (Date→ISO); race guard inside an existing transaction; per-user `Cache-Control: private`;
swap raw error for the project's typed exception; add prescribed middleware; import reorder/path style;
fill an established-pattern registration; **any change that's a 1-commit revert with no downstream consequences.**
**Rule of thumb:** one obviously-correct form any senior would write the same → AUTO-FIX, regardless of
file count. Volume isn't gate-triggering; ambiguity is.

## Verdict vocabulary
| Verdict | Meaning | Path |
|---|---|---|
| AUTO-FIX | Valid, clear correct answer. Fix without asking. | Implement |
| DECISION-NEEDED | Valid, fix needs operator judgment (Decision Gate). | Walk operator |
| DECLINE | Reviewer is wrong / contradicts a load-bearing standard / YAGNI. | Reply, resolve |
| ALREADY ADDRESSED | Already fixed in current code, or thread resolved. | Resolve |
| UNCLEAR | Too vague to act on. | Reply + ask |

No OUT OF SCOPE — a real finding gets fixed; a non-finding declined; an unfixable-without-judgment one → DECISION-NEEDED.

## Execution strategy
```text
Main agent
 ├ Announce: "Triaging PR #N — fetching comments and analyzing."
 ├ Phase 1.5: pre-flight git state (HARD GATE; abort on failure)
 └ Sub-agent → Phases 1–4 (read-only fetch + analysis)
      1 resolve PR, metadata, diff, linked issues, scope
      2 fetch all comment threads + thread IDs (GraphQL), idempotency filter
      3 read project standards + derive verify commands
      4 per-thread verdict (fan out when N>10)
 ├ Phase 5: overview + thread table + decision wizard (DECISION-NEEDED forks only)
 └ Phase 6: execute end-to-end (implement → verify → commit → push → reply → dismiss → resolve → report)
```

## Phase 1 — resolve PR + scope
1. PR number: explicit arg → `gh pr view --json number --jq '.number'` → `gh pr list` + ask.
2. `gh pr view <n> --json number,title,headRefName,url,author,state,reviewDecision,body,baseRefName`.
3. Repo coords: `gh repo view --json owner,name --jq '{owner:.owner.login,name:.name}'` → store `$OWNER/$NAME` (never re-fetch).
4. Linked issues: `gh pr view <n> --json closingIssuesReferences --jq '.closingIssuesReferences[]'`.
5. Diff: `gh pr diff <n> --name-only`.
6. Scope statement (linked issue → title/desc → diff) — context only; does not gate fixes (principle 1).

## Phase 1.5 — pre-flight git state (HARD GATE; abort on any failure)
1. Current branch = `headRefName` (`git branch --show-current`), else abort `error: on branch <X>, PR is on <Y>. checkout <Y> first.`
2. Working tree clean (`git status --porcelain` empty), else abort `error: uncommitted changes in <files>. commit/stash first.`
3. Synced with origin (`git fetch origin <branch>; git rev-list --count HEAD..origin/<branch>` == 0), else abort `error: behind origin/<branch> by N. pull first.`
4. `START_SHA=$(git rev-parse HEAD)` — Phase 6c re-checks before commit; HEAD moved → abort.
5. `GH_USER=$(gh api user --jq '.login')` — for the Phase 2 idempotency filter.

## Phase 2 — fetch comments + thread IDs
Use `$OWNER/$NAME` from Phase 1. **jq safety:** use `select(.body | length > 0)` — never `select(.body != "")` (the `!=` form can corrupt to the Unicode not-equal char and fail jq parse).
- **2a inline:** `gh api repos/$OWNER/$NAME/pulls/<n>/comments --paginate | jq '[.[] | {id,path,line,body,user:.user.login,in_reply_to_id,diff_hunk}] | map(select(.body|length>0))'`
- **2b review bodies:** `gh api repos/$OWNER/$NAME/pulls/<n>/reviews --paginate | jq '[.[] | {id,body,state,user:.user.login}] | map(select(.body|length>0))'`
- **2c issue comments:** `gh api repos/$OWNER/$NAME/issues/<n>/comments --paginate`
- **2d review threads (GraphQL)** — map root comment `databaseId` → `threadId` for later resolve.
  **Paginate** (`--paginate` + `pageInfo`/`$endCursor`): bare `first:100` silently drops threads past
  page 1 on large PRs, leaving them unresolved. Collect all pages before treating this as the source of truth.
  ```bash
  gh api graphql --paginate -f query='query($owner:String!,$name:String!,$number:Int!,$endCursor:String){repository(owner:$owner,name:$name){pullRequest(number:$number){reviewThreads(first:100,after:$endCursor){pageInfo{hasNextPage endCursor} nodes{id isResolved isOutdated comments(first:1){nodes{databaseId}}}}}}}' -F owner=<owner> -F name=<name> -F number=<n>
  ```
**Processing:** group inline by `in_reply_to_id` → threads; `isResolved:true` → **ALREADY HANDLED**, skip
entirely (one counted line in report); **prior agent reply** (a comment by `$GH_USER` whose body
contains the trailer `[harness:address-pr-comments]`) → already handled, skip **only if** that reply is
the thread's **latest substantive comment** (no newer reviewer comment after it). A reviewer comment
posted *after* the agent reply re-opens the thread → re-triage, don't skip; reviewer-acknowledged
closure ("done"/"thanks"/"lgtm now") → **ALREADY ADDRESSED** (→ `already:` reply + resolve); filter
noise (LGTMs, bot status, empty bodies); dedup (keep inline over review-body repeat); group related
(one finding, multiple locations); carry `threadId` to every finding.
**Idempotency contract:** rerun on the same PR with no new comments = no-op (zero new replies/resolves/commits).

## Phase 3 — project standards + verify commands
Read in parallel: context docs + the rules dir entries matching the diff (HARNESS.md), architecture docs,
root + touched-workspace package manifests. These are authority — a reviewer contradicting them → DECLINE
(cite), unless the comment finds a genuine bug in the standard → DECISION-NEEDED.
**3a verify commands (`VERIFY_CMDS` for Phase 6b):** **prefer HARNESS.md › Sensors** (the project's
declared format/lint/test/typecheck). If absent, derive (first match wins): explicit "how to test" in
context docs → its commands; Nx (`nx.json`) → `npx nx affected -t typecheck lint test`; Turborepo
(`turbo.json`) → `npx turbo run typecheck lint test`; package scripts → `npm run <script>` per
typecheck/lint/test; fallback → test only. Note in the report if only the fallback was found.

## Phase 4 — per-thread analysis (thread = unit)
Parallelism: N≤10 single pass; N>10 fan out to nested sub-agents in batches of 5–8, all in parallel
(one message, multiple Agent calls); N>40 cap batch at 5. Group same-file threads within a sub-agent.
- **4a context:** read the file ±20 lines around the flagged line; follow cross-file refs; grep actual usage for proposed abstractions (YAGNI).
- **4b verdict (first match wins):** ALREADY ADDRESSED → DECLINE (cite standard / concrete reason; optional regression-lock test for non-obvious declines) → UNCLEAR → DECISION-NEEDED (state which gate criterion) → AUTO-FIX.
- **4c fix plan** (AUTO-FIX + DECISION-NEEDED): files, exact change, tests. DECISION-NEEDED → two options (recommended + alternative) + `Blocker: <one-line | none>` (reachable this session? default none).
- **4d return:** one preamble block (PR/branch/author/url/repo/review-status/linked-issues/scope/files/total/counts) + per-thread block (`#`, `ThreadID`, `RootCommentID`, `File L<line>`, `Reviewer`, `Summary`, `Verdict`, `Gate`, `Reasoning` citing standards, `Fix plan`/`Option A`/`Option B`/`Blocker`, `Reply tag`, `Code context`).

## Phase 5 — overview + decision-only wizard
Main agent renders from returned data (no re-fetch).
- **5.0 announce (one line):** `PR #N · K threads → A auto-fix · D decisions · X decline · Y already · U unclear · S skipped. Walking D decisions now.` (D==0 → "No decisions needed — proceeding to implementation.")
- **5a/5b/5c:** PR overview table · verdict counts · full thread table (orientation only; emoji markers 🔧 AUTO-FIX · 🤔 DECISION · 🚫 DECLINE · ✅ ALREADY · ❓ UNCLEAR · ⏭️ SKIPPED).
- **Option-pick format:** render a walk-me-through fork card (`references/walk-me-through.md`) — `Q<N> of <total>` + `#<N>` title, framing (comment / why-it-needs-a-decision), options table (terse Pros/Cons), grounded Recommendation (pick + reasoning + `Cost if`), `Escape:` + `Pick:` lines; operator replies by letter. **Never `AskUserQuestion` or a native picker.** One fork per turn. Yes/no gates one line.
- **5d wizard (DECISION-NEEDED only):** zero → skip, "No forks — proceeding." For each, in order: render the card (decision #, file:line, comment quote, code context, which gate criterion, options table A/B + C `Decline finding` + D `Defer (blocked)` only when a concrete blocker exists, Recommendation, plus `Escape:`/`Pick:` lines); operator replies by letter — `A — <name> (Recommended)`, `B — <name>`, `C — Decline finding`, `D — Defer (blocked)`; never `AskUserQuestion`. **Offer D only when genuinely unreachable this session** (separate spec / external decision / blocking upstream) — never for "out of scope" or "big change" (correctness over scope). One-line confirm, continue. Don't wizard AUTO-FIX/DECLINE/ALREADY/UNCLEAR.

## Phase 6 — execute end-to-end
Runs after the 5d wizard, or immediately if no forks. Invocation is consent; no per-step re-confirm. Stop only for a mid-flight cascading decision (6b.1) or a hard-gate failure.
- **6a implement (sub-agent fan-out default):** build the batch graph (independent → parallel, dependent → sequential; same-file grouped; structural items single-threaded); dispatch one sub-agent per independent batch in a single message. Each sub-agent gets its items + fix plans, the scope statement, the Phase-3 standards summary, and `VERIFY_CMDS`; implements, verifies its batch, returns `{batch_id, files_touched, verify_status, errors, cascading_findings}`. **Keep on main agent (don't fan out)** when: ≤3 mechanical items; any item touches load-bearing shared config (serialize); operator chose Other with no concrete plan. **Always update tests inline** with each behavioral change.
- **6b verify:** run `VERIFY_CMDS` (typecheck → lint → test). Fail → diagnose root cause, fix, re-run; don't proceed until clean.
- **6b.1 cascading-finding policy** (something found during the fix loop, not in the comments): AUTO-FIX class → fix silently in the batch, track for the report; Decision-Gate hit → stop the batch, mid-execution walk-me-through fork card (same shape + letters as 5d — A/B + C `Decline finding` + D `Defer (blocked)` when a concrete blocker exists, then `Escape:`/`Pick:`), resume after; genuinely blocked → stop batch, file a follow-up, `deferred:` reply, continue other batches. Never silently expand beyond AUTO-FIX class.
- **6c commit:** **race check** — `test "$(git rev-parse HEAD)" = "$START_SHA"` else abort. **Empty-diff** — `git diff --quiet HEAD && SKIP_COMMIT=true`. Else semantic commit, `git add <specific files — never -A>`, body lists `Addresses PR #N review:` with `<reviewer> L<line>: <one-line> (<comment-url>)`, prerequisite inline fixes named with causal reason (HARNESS.md conventions). **Never `--no-verify`**; pre-commit hook fail → diagnose, fix, **new commit (never amend)**.
- **6c.1 empty-diff short-circuit:** SKIP_COMMIT=true (all DECLINE/ALREADY/UNCLEAR) → skip commit + push, go to reply/resolve; report `Commits: none — no fixes required.`
- **6d push:** `git push` (`-u origin <branch>` if no upstream; never force-push without explicit request). Capture CI URL: `CI_RUN_URL=$(gh run list --branch "$BRANCH" --limit 1 --json url --jq '.[0].url // ""')` (empty ok).
- **6e reply in-thread (machine-readable):** tags — `fixed: <what>. commit:<sha7>` · DECISION-NEEDED `fixed: <what>. choice:<A|B|custom>. commit:<sha7>` · `wontfix: <reason>. ref:<path/rule>` · `already: <where>. commit:<sha7|pre-existing>` · `unclear: <question>` · `deferred: <issue-url>`. No greetings/thanks/backticks; ASCII; ≤200 chars (hard cap 500 excl. trailer); tag is first token (parsers split on `:`). **Mandatory signature trailer** — blank line then `[harness:address-pr-comments]` on its own final line (idempotency). Post: inline reply `gh api repos/$OWNER/$NAME/pulls/$PR/comments/$ROOT_COMMENT_ID/replies -f body="$(printf '%s\n\n[harness:address-pr-comments]\n' "$BODY")"` (use `-f body=`, not `--input -`); top-level review/issue → issue comment with a parseable `Re-review-<review-id>:` header line + the tagged reply. Throttle `sleep 2`; on 422 abuse / 403 Retry-After honor header or wait 60s, retry. >20 replies → single aliased GraphQL mutation.
- **6e.1 dismiss stale top-level reviews:** for each `CHANGES_REQUESTED` review whose inline findings were all handled — **bot reviewers** (login ends `[bot]`) auto-dismiss (`gh api -X PUT repos/$OWNER/$NAME/pulls/$PR/reviews/$REVIEW_ID/dismissals --field message='superseded by commit:<sha7>'`); **human reviewers** → surface command in report, don't auto-dismiss. Failures non-fatal.
- **6e.2 bulk reply (N>20):** one aliased GraphQL mutation (`r1: addPullRequestReviewThreadReply(...)`, `r2: ...`), two requests total. REST fallback ≤20 with throttle.
- **6e.3 failure handling:** continue on failure; per call capture stderr+status, retry once on 422 abuse / 403 Retry-After, then record `{ids, command, error}` in `FAILURES`; surface a copy-paste retry block in the report.
- **6f resolve threads:** for AUTO-FIX(implemented)/DECISION-NEEDED(implemented)/DECLINE/ALREADY — `gh api graphql -f query='mutation($threadId:ID!){resolveReviewThread(input:{threadId:$threadId}){thread{id isResolved}}}' -F threadId=<id>`. Don't resolve UNCLEAR. Skip `ThreadID: none` (top-level — dismissed via 6e.1) and already-resolved. >20 → aliased mutation. Failures per 6e.3.
- **6g deferred follow-ups (option D):** `gh issue create --title '<t>' --body '<links PR #N comment>' --label deferred`; post `deferred: <url>` reply; resolve the source thread.
- **6h re-request review:** if `CHANGES_REQUESTED` and ≥1 fix — bots auto `gh pr edit <n> --add-reviewer <user>`; humans → suggest in report.

## Final report (rendered markdown, never a code fence; omit zero-count rows)
Lead (bold, one line): `✅ PR #N — <title> · X fixed · Y resolved · pushed <sha7>` (⚠️ + failure count if anything failed). Then: **Outcome table** (status/count/detail — 🔧 Fixed · 🤔 Decided · 🚫 Declined · ✅ Already · ❓ Unclear · ⏭️ Deferred · ⏭️ Skipped); **Decisions table** (only if ≥1 operator decision); **Verification + GitHub** (Typecheck/Lint/Tests ✅/❌/➖ · Threads resolved · Replies posted · Stale reviews dismissed · Re-request review · CI run link); **Files touched** (clickable bullets); **Tail** (cascading auto-fixes if any). **Failures block** (only if non-empty): `> ⚠️` callout + fenced bash of copy-paste retry commands. **Decision log** (when this PR maps to a harness change with a `harness/` dir): append each *load-bearing* decision — a `🔧 fix`, `🚫 decline`, or `⏭️ defer` with its reasoning, and any 5d-wizard pick the **human** made — to `<change-state-dir>/decisions.md` per `references/decision-log.md` (`🤖 address-pr-comments` / `👤 human`). Skip routine auto-fixes. **Refresh PR summary** (same condition — this PR maps to a harness change with a `harness/` dir, and a commit landed this run): after the decision-log append, re-fold `<change-state-dir>/pr-body.md` per `references/pr-summary.md` (it now carries the new commits + decisions) and update the PR description with it (`gh pr edit <n> --body-file <change-state-dir>/pr-body.md`, rewriting only inside the managed region). **Idempotency key:** if no commit landed this run (empty-diff short-circuit 6c.1) the body is unchanged → **skip the refresh.** On a fold, stamp the footer (`folded-against` = pushed HEAD; `generated-by: harness:address-pr-comments v<hash8>`). **Pipeline trail** (one line, before the next pointer): the "you are here" trail for the `address-pr-comments` end stop per `references/pipeline-map.md` — its `◦ finish` label carries the after-merge step. **Next pointer** (one line): name **only the immediately-runnable action — review + merge the PR** (human action, no command yet). **Do NOT print `/harness:finish` or "run X after merge"** — premature, mis-fire risk (one runnable command rule); finish surfaces as the trail's `◦ finish` label only.

## Principles
Correctness over scope · standards are authority · auto-fix is default (Decision Gate is the filter) ·
parallelize aggressively · idempotent by trailer (`[harness:address-pr-comments]`) · YAGNI before
accepting abstractions · machine-readable replies (trailer mandatory) · resolve what you fixed (dismiss
stale bot reviews) · stop only at genuine forks (no plan-approval gate) · report is rendered markdown ·
end-to-end in one run.
