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
  version: "1.3.2" # x-release-please-version
---

# harness:address-pr-comments — PR comment triage + auto-resolve

End-to-end PR review-comment resolution. Arg: `/harness:address-pr-comments #21`. No number → infer
from current branch; else list open PRs and ask.

> **Bindings.** PR host per `docs/HARNESS.md` (GitHub via `gh` shown — substitute the project's host).
> Verify commands resolve from **HARNESS.md › Sensors** (fallback: dynamic derivation in Phase 3a).
> Project standards = the rules dir + context docs (HARNESS.md). Conventions (branch/commit) per HARNESS.md.
> **Finish › merge mode** (`single-merge` | `two-merge`) per HARNESS.md — governs the end-stop Next pointer.

## Breadcrumbs
Emit one line at start + one at end — so harness iteration can trace this run in the session transcript.
- **start:** `▶ harness:address-pr-comments` + any mode/target this run has (e.g. ` · gated · <change>`, ` · <task-id>`, ` · #<pr>`).
- **end:** `■ harness:address-pr-comments v<hash8> → <outcome>` — one-line result; add `stopped: <fork>` / `skipped: <reason>` when applicable. `<hash8>` = first 8 chars of `git hash-object` on this SKILL.md — compute it (run the command) in the end-of-run commands; never a placeholder.

## Operator input
`👉` = operator's turn. Prefix any line needing their answer (question / confirm / pick) and make it the **terminal block** — below the breadcrumb/trail/next, nothing actionable under it (a blocking ask buried above a ready action gets skipped; the eye must land on it last). While a `👉` is open, don't render a runnable `/harness:` next — show it gated behind the answer. Reserved marker, distinct from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).

Act as a Principal Engineer. Every valid finding gets fixed, every invalid finding refuted, every
direction-affecting ambiguity surfaces to the operator. **Default bias: correctness, not scope.**

**Operating principles (override defaults):**
1. **Correctness over PR scope.** A valid finding gets fixed even outside the PR's stated scope. No
   "OUT OF SCOPE — defer" verdict. The only defer reason is a fix needing a load-bearing operator decision.
2. **Auto-fix is the default** for findings with a clear correct answer — implement immediately, no prompt.
3. **Only walk the operator through decisions that genuinely need judgment** (Decision Gate below).
4. **Stop only at genuine forks — no plan-approval gate.** After analysis, walk DECISION-NEEDED forks
   (5d), then run end-to-end with no per-step gates. Zero forks → straight to execution. Only stops: a
   DECISION-NEEDED finding (5d), a mid-flight cascading Decision-Gate hit (6b.1), the convergence
   brake (run #≥3 on this PR — 5c.1), an unrecognized dirty path at 6b.2 (aborts), or corrective
   re-entries exhausted (6c). Invocation is consent
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
 └ Sub-agent → Phases 1–4.5 (read-only fetch + analysis)
      1 resolve PR, metadata, diff, linked issues, scope
      2 fetch all comment threads + thread IDs (GraphQL), idempotency filter
      3 read project standards + derive verify commands
      4 per-thread verdict (fan out when N>10)
      4.5 class-of-issue sweep (rg for siblings → classify vs hunks: tier-1 fix / tier-2 surface; per-candidate gate)
 ├ Phase 5: overview + thread table + decision wizard (DECISION-NEEDED forks only)
 └ Phase 6: execute end-to-end (implement → verify → self-check → commit → push → reply → dismiss → resolve → report)
```

## Phase 1 — resolve PR + scope
1. PR number: explicit arg → `gh pr view --json number --jq '.number'` → `gh pr list` + ask.
2. `gh pr view <n> --json number,title,headRefName,url,author,state,reviewDecision,body,baseRefName`.
3. Repo coords: `gh repo view --json owner,name --jq '{owner:.owner.login,name:.name}'` → store `$OWNER/$NAME` (never re-fetch).
4. Linked issues: `gh pr view <n> --json closingIssuesReferences --jq '.closingIssuesReferences[]'`.
5. Diff: `gh pr diff <n> --name-only` (file list for scope) **+ `gh pr diff <n>`** (full patch — Phase 4.5 needs hunk boundaries to classify tier-1 vs tier-2).
6. Scope statement (linked issue → title/desc → diff) — context only; does not gate fixes (principle 1).

## Phase 1.5 — pre-flight git state (HARD GATE; abort on any failure)
1. Current branch = `headRefName` (`git branch --show-current`), else abort `error: on branch <X>, PR is on <Y>. checkout <Y> first.`
2. Working tree clean (`git status --porcelain` empty), else abort `error: uncommitted changes in <files>. commit/stash first.`
3. **Synced with origin both ways** (`git fetch origin <branch>; git rev-list --left-right --count HEAD...origin/<branch>` → `0\t0`; **left = ahead, right = behind**): **first match wins**: both non-zero → abort `error: <branch> has diverged from origin (N ahead, M behind). reconcile before re-invoking.`; else right non-zero → abort `error: behind origin/<branch> by N. pull first.`; else **left non-zero → abort** (see below) — the ahead message must carry **both** exits — `error: N unpushed commit(s) on <branch>. push them — or, if a prior run stopped rather than push (6c path-set guard), rework or drop that commit first; never push it as-is.` — because the wrong exit re-introduces the very unreviewed path that guard refused. A prior run that committed without pushing otherwise poisons two invariants: `region_map` line numbers come from the PR host in `origin/<branch>` coordinates and would be compared against a `START_SHA` that differs from them, and this run would resolve threads citing commits the remote lacks.
4. `START_SHA=$(git rev-parse HEAD)` — this run's diff base (never advances). `EXPECTED_HEAD=$START_SHA` — the race-check baseline; **advances to each commit this run verifies** (6c), so a corrective second commit isn't blocked by its own predecessor.
5. `GH_USER=$(gh api user --jq '.login')` — for the Phase 2 idempotency filter.

## Phase 2 — fetch comments + thread IDs
Use `$OWNER/$NAME` from Phase 1. **jq safety:** use `select(.body | length > 0)` — never `select(.body != "")` (the `!=` form can corrupt to the Unicode not-equal char and fail jq parse).
- **2a inline:** `gh api repos/$OWNER/$NAME/pulls/<n>/comments --paginate | jq '[.[] | {id,path,line,start_line,original_line,original_start_line,side,start_side,body,user:.user.login,in_reply_to_id,diff_hunk}] | map(select(.body|length>0))'` (all four line fields are load-bearing: an outdated comment has `line:null` → use `original_line`; a multi-line comment's `line` is the **end** of the range → without `start_line` the 4d `region_map` misses edits at the start or middle of it)
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
**Run counter:** `RUN_N` = 1 + count of **distinct** `commit:<sha7>` values across prior trailered
`fixed:` replies by **any author** (the trailer identifies the skill — team PRs run it from different
accounts; only `fixed:` — an `already:` sha or the literal `pre-existing` isn't a patch by this
skill), computed over the **raw 2a–2c fetch, before the skip/filter steps above** —
prior-run replies live in threads that are already resolved/skipped, so a post-filter count always
reads 1. This run's patch-round ordinal on the PR (feeds the 5c.1 convergence brake).

## Phase 3 — project standards + verify commands
Read in parallel: context docs + the rules dir entries matching the diff (HARNESS.md), architecture docs,
root + touched-workspace package manifests. These are authority — a reviewer contradicting them → DECLINE
(cite), unless the comment finds a genuine bug in the standard → DECISION-NEEDED.
**3a verify commands (`VERIFY_CMDS` for Phase 6b):** **prefer HARNESS.md › Sensors** (the project's
declared format/lint/test/typecheck). If absent, derive (first match wins): explicit "how to test" in
context docs → its commands; Nx (`nx.json`) → `npx --no-install nx affected -t typecheck lint test`;
Turborepo (`turbo.json`) → `npx --no-install turbo run typecheck lint test` (**`--no-install` on every
`npx`** — bare `npx` silently fetches from the registry when the tool isn't installed locally, running
unvetted code in the consuming project; absent binary must fail closed, then fall through to the next
match); package scripts → an **aggregate gate script if
one exists** (`check` / `validate` / `verify` / `ci` — it's what CI runs, and it catches the linters a
name-by-name scan misses), else per typecheck/lint/test individually; fallback → test only. The names
are the ecosystem's, not npm's — `make check`, `tox`, `swift test`, `npm run check` are the same rule;
npm shown as the example. Note in the report if only the fallback was found. **Cross-check against
CI**: a gate the PR's workflow runs but `VERIFY_CMDS` omits → add it (6b green while CI fails is a
defect) — **but only when it's already project-declared** (a manifest script / HARNESS.md sensor); a
raw inline workflow step is surfaced in the report, never lifted into local execution (it may deploy,
publish, or reach the network).

## Phase 4 — per-thread analysis (thread = unit)
Parallelism: N≤10 single pass; N>10 fan out to nested sub-agents in batches of 5–8, all in parallel
(one message, multiple Agent calls); N>40 cap batch at 5. Group same-file threads within a sub-agent.
- **4a context:** read the file ±20 lines around the flagged line; follow cross-file refs; grep actual usage for proposed abstractions (YAGNI).
- **4b verdict (first match wins):** ALREADY ADDRESSED → DECLINE (cite standard / concrete reason; optional regression-lock test for non-obvious declines) → UNCLEAR → DECISION-NEEDED (state which gate criterion) → AUTO-FIX.
- **4c fix plan** (AUTO-FIX + DECISION-NEEDED): files, exact change, tests. DECISION-NEEDED → two options (recommended + alternative) + `Blocker: <one-line | none>` (reachable this session? default none).
- **4d return:** one preamble block (PR/branch/author/url/repo/review-status/linked-issues/scope/files/total/counts/**`RUN_N`** — Phase 5 renders from returned data and must not re-fetch, so an unreturned `RUN_N` means the 5c.1 brake silently never fires)
  + **`region_map`** — the intervals **earlier runs already patched**, taken from the **raw 2a fetch**.
  Mechanical membership (no "which round" judgment — nothing tags a comment with a round): include a
  thread iff it carries a prior trailered **`fixed:`** reply **by any author** (team PRs run this skill
  from different accounts — the `$GH_USER` scope used by the skip predicate would empty the map) — the only evidence *this skill patched
  that interval*. Not bare `isResolved` (a human-resolved discussion or a DECLINE/ALREADY close was
  never patched, and including it fires the region check on ordinary nearby fixes);
  **Exclude only the interval of the thread whose own verdict this edit implements** — otherwise a
  reopened thread's re-fix trips a finding no fold can discharge (the reviewer's verdict *is* that line),
  looping to a fork with no terminating exit. Every **other** interval stays, including other reopened
  threads': a different thread's fix landing in a previously patched region is exactly the repeat-patch
  case the map exists to catch. (A first-time finding has no prior `fixed:` reply and fails membership
  anyway, so the exclusion is narrow by construction.) Store the **whole interval**, not one line:
  `start_line..line`, or for an outdated comment `original_start_line..original_line` is in the **old commit's** coordinates —
  **re-anchor before storing**: anchor the hunk's **space-prefixed context runs** (exclude `-`/`+`),
  whitespace-normalized — **each run separately, in order**, never concatenated into one block: a
  replacement hunk has context before and after the change, and the new-side replacement line still
  separates them in the current file, so a contiguous match finds nothing. Stored entry = `{thread_id, start..end}` — the owning thread travels with the interval, or 6b.2b
  cannot evaluate the exclusion below. Interval = the comment's **own** range, shifted —
  **not the context span** (that would swallow the hunk's context and false-fire when a later fix touches
  an unrelated context line in the same old hunk). `original_*` are in the **reviewed commit's RIGHT-side**
  coordinates, so seed the run from the header's **`+c`, advancing on `+` and context lines** — *not* `-a`
  (6b.2b's cursor walks `-a`; these are different frames and confusing them shifts every interval by the
  file's earlier-hunk delta). `delta = matched_current_start − run_start_in_reviewed_commit`; store
  `original_start_line + delta .. original_line + delta`. (`side: LEFT` → seed from `-a` and advance on `-`
  and context instead; `side` defaults to RIGHT.) **`diff_hunk` is tail-truncated — its body ends at the
  commented line — so ONE context run (the leading one) is the normal case**: only that run needs a unique
  match, and it supplies the anchor by itself. A trailing run, when present, is an optional drift
  cross-check, never a requirement — demanding two runs would drop nearly every interval and blind the
  lens. **Sanity-check** in mapped hunk coordinates: result within `c + delta .. c + d − 1 + delta` (use
  the header's declared counts, not the truncated body's length). Fails → **drop the interval**. no unique match → **drop the interval** (a stale coordinate would fire the region
  check on an unrelated current line and miss the real one). Single-line (`start_line`/`original_start_line` null) → use that branch's end field: `line..line`, or
  for an outdated comment the **re-anchored** `original_line..original_line` — never a null bound (a
  null-bounded interval can never overlap, silently unguarding the region). Phase 5 forbids re-fetch, so without this the
  6b.2b region check is blind in the normal (prior-`fixed:`-reply) case.
  + per-thread block (`#`, `ThreadID`, `RootCommentID`, `File L<line>`, `Reviewer`, `Summary`, `Verdict`, `Gate`, `Reasoning` citing standards, `Fix plan`/`Option A`/`Option B`/`Blocker`, `Reply tag`, `Code context`).

## Phase 4.5 — class-of-issue sweep (kill repeat bot rounds)
Sweep only classes whose fix is **AUTO-FIX-taxonomy mechanical** (Decision Gate); a DECISION-NEEDED class
isn't swept. For each such finding, derive a **class signature** — the transformable pattern, not the
literal line (e.g. "mapper returns raw Date", "handler missing null-guard on a route param", "exported fn
missing return type"). Goal: the bot flags 1 of N identical spots → all N die this round, no round 2.
- **Discover with `rg`, not the diff** — a diff omits unchanged lines + untouched files, so grepping it
  can never find tier-2. Two steps:
  1. **`rg` the signature** across the touched files **and** the wider repo (scope the repo pass to the
     language/dirs the class can occur in; cap results + note if capped). For a behavioral-claim /
     doc-assertion class the repo pass MUST include prose artifacts (`docs/`, `openspec/`, `README*`,
     `.claude/`), not just code dirs — a claim in code has identical siblings in the specs and docs
     (one finding, not three).
  2. **Classify each hit against the PR patch hunks** (the full patch from Phase 1): tier-1 **only** when
     the hit is on an **added line** (a `+` line — the new side this PR introduced). **Everything else is
     tier-2** — a context line *inside* a hunk (unchanged, space-prefixed), an unchanged line outside any
     hunk, or an untouched file. Key tier-1 off added lines, **never** off "inside a hunk" (hunks carry
     pre-existing context lines that aren't PR-introduced).
- **Two tiers by locality:**
  - **Tier 1 (auto-fix):** this-PR-introduced sibling → add to the owning finding's fix batch, same commit.
  - **Tier 2 (surface only):** pre-existing sibling → **never auto-fix** (separate blast radius). Collect
    for the report + a copy-paste follow-up-issue command. Don't smuggle a repo-wide refactor into a
    comment-resolution run.
- **Per-candidate Decision Gate (not just the class):** the class being AUTO-FIX authorizes the *sweep*,
  not each sibling. Re-run the Decision Gate on **every confirmed tier-1 candidate** — a sibling matching a
  mechanical signature can still sit on a public-contract / schema / architectural / load-bearing surface.
  Any candidate that trips a gate criterion → **DECISION-NEEDED** (5d wizard if interactive, else report),
  never auto-fixed — even though the originating class was AUTO-FIX.
- **Candidate ≠ confirmed:** `rg` yields *candidates* by signature; the Phase-6a implementer verifies each
  genuinely matches the class before fixing — no blind find-replace.
- **Dedup vs reviewer:** a sibling already covered by another thread is **already handled**, not swept —
  count only instances no thread flagged.
- **Emit** per swept class: `{class, source_thread, tier1_siblings:[file:line], tier2_instances:[file:line],
  gate_deferred:[file:line]}` → tier1 → 6a; tier2 + gate_deferred → report (gate_deferred also → 5d when interactive).

## Phase 5 — overview + decision-only wizard
Main agent renders from returned data (no re-fetch).
- **5.0 announce (one line):** `PR #N · K threads → A auto-fix · D decisions · X decline · Y already · U unclear · S skipped. Walking D decisions now.` (D==0 → "No decisions needed — proceeding to implementation."; RUN_N>1 → append ` · run #<RUN_N>`.)
- **5a/5b/5c:** PR overview table · verdict counts · full thread table (orientation only; emoji markers 🔧 AUTO-FIX · 🤔 DECISION · 🚫 DECLINE · ✅ ALREADY · ❓ UNCLEAR · ⏭️ SKIPPED).
- **5c.1 convergence brake (after the 5a–5c tables, before 5d/Phase 6):** `RUN_N ≥ 3` **and** (A>0 or
  D>0) → do NOT auto-proceed (a no-op rerun — zero auto-fix, zero decisions — never brakes; 6c.1
  short-circuits it anyway). Emit `⚠️ run #<RUN_N> on this PR — patch rounds not converging; recommend
  root-causing the change instead of another round`, then a one-line 👉 proceed-anyway gate (terminal
  block). Explicit yes → continue (5d wizard, then Phase 6); else stop — don't walk 5d forks for a run
  that won't execute.
- **Option-pick format:** render a walk-me-through fork card (`references/walk-me-through.md`) — `Q<N> of <total>` + `#<N>` title, framing (comment / why-it-needs-a-decision), options table (terse Pros/Cons), grounded Recommendation (pick + reasoning + `Cost if`), `Escape:` + `Pick:` lines; operator replies by letter. **Never `AskUserQuestion` or a native picker.** One fork per turn. Yes/no gates one line.
- **5d wizard (DECISION-NEEDED only):** zero → skip, "No forks — proceeding." For each, in order: render the card (decision #, file:line, comment quote, code context, which gate criterion, options table A/B + C `Decline finding` + D `Defer (blocked)` only when a concrete blocker exists, Recommendation, plus `Escape:`/`Pick:` lines); operator replies by letter — `A — <name> (Recommended)`, `B — <name>`, `C — Decline finding`, `D — Defer (blocked)`; never `AskUserQuestion`. **Offer D only when genuinely unreachable this session** (separate spec / external decision / blocking upstream) — never for "out of scope" or "big change" (correctness over scope). One-line confirm, continue. Don't wizard AUTO-FIX/DECLINE/ALREADY/UNCLEAR.

## Phase 6 — execute end-to-end
Runs after the 5d wizard, or immediately if no forks. Invocation is consent; no per-step re-confirm. Stop only for a mid-flight cascading decision (6b.1), the 5c.1 convergence brake, an unrecognized dirty path (6b.2), corrective re-entries exhausted (6c), or a hard-gate failure.

**Certification contract (governs 6a→6c; each state below names who advances it):**
| Name | Set at | Advanced by | Read by |
|---|---|---|---|
| `START_SHA` | 1.5 | never | 6b.2b diff base · 6c post-commit path-set + bytes checks |
| `EXPECTED_HEAD` | 1.5 (`=START_SHA`) | 6c, after each **verified** commit | 6c race check |
| `FIX_SET` | 6a (union of batch `files_touched`) | **6b** diagnosis fixes · **6b.1** cascading fixes · **6b.2** unrecorded fixes · **6b.2b** own findings — every file this run authors, always added on write | 6b.2 staging · 6c path-set check 1 |

**Invariant: what gets committed is exactly what was certified.** A file this run edits but never adds
to `FIX_SET` is a defect (silently dropped from the commit); a staged file the run didn't author is a
defect (uncertified bytes). Both are 6b.2 findings.
- **6a implement (sub-agent fan-out default):** build the batch graph (independent → parallel, dependent → sequential; same-file grouped; structural items single-threaded); dispatch one sub-agent per independent batch in a single message. Each sub-agent gets its items + fix plans, the scope statement, the Phase-3 standards summary, and `VERIFY_CMDS`; implements, verifies its batch, returns `{batch_id, files_touched, artifacts_observed, verify_status, errors, cascading_findings}` — the union of `files_touched` seeds `FIX_SET`; `artifacts_observed` (per 6b's snapshot rule) is evidence about **untracked** paths only — it decides *which ask* 6b.2 raises, never that a path may be deleted, and never ownership of a **tracked** path. **Keep on main agent (don't fan out)** when: ≤3 mechanical items; any item touches load-bearing shared config (serialize); operator chose Other with no concrete plan. **Fold in Phase-4.5 tier-1 swept siblings** — each rides its owning finding's batch; the implementer confirms every candidate genuinely matches the class before fixing (per 4.5), skipping any that don't. **Always update tests inline** with each behavioral change.
- **6b verify:** **snapshot `git status --porcelain` immediately before and after every `VERIFY_CMDS` invocation** (here and inside each 6a sub-agent, which returns `artifacts_observed:[path]` alongside `files_touched`) — absent-before/present-after is the *only* evidence 6b.2 accepts for an **untracked** path; it never authorizes deletion, and it never establishes ownership of a tracked path (6b.2 routes those to a fork). Then run `VERIFY_CMDS` (typecheck → lint → test). Fail → diagnose root cause, fix, re-run; don't proceed until clean. **Failure because the runner binary is absent** (not because the code is wrong — e.g. `--no-install` fired) → re-derive per 3a from the next match and note it; **never install anything to make a sensor run.** **Every file touched while diagnosing (fixture, shared helper, new test) → `FIX_SET`** — verification passes against the whole worktree, so an unrecorded file passes 6b and then vanishes from the commit.
- **6b.1 cascading-finding policy** (something found during the fix loop, not in the comments): AUTO-FIX class → fix silently in the batch, track for the report; Decision-Gate hit → stop the batch, mid-execution walk-me-through fork card (same shape + letters as 5d — A/B + C `Decline finding` + D `Defer (blocked)` when a concrete blocker exists, then `Escape:`/`Pick:`), resume after; genuinely blocked → stop batch, file a follow-up, `deferred:` reply, continue other batches. Never silently expand beyond AUTO-FIX class. Any file a cascading fix touches → `FIX_SET`.
- **6b.2 stage + reconcile (inline, no sub-agent; certification is 6b.2b):** stage exactly
  `FIX_SET` — `git add -- <FIX_SET>` (never `-A`/`.` — a stray verify artifact must not enter the
  certified payload; staging applies clean filters and makes new files visible). **Reconcile before
  certifying:** `git status --porcelain`, classified **by what this run recorded — never by inference**:
  - in `FIX_SET` → staged, certified.
  - **recorded** as this run's own output — a path a 6a/6b/6b.1 step reported writing, or an **untracked** path
    **observed** to appear across a `VERIFY_CMDS` invocation (snapshot `git status --porcelain` before
    and after each; absent-before/present-after qualifies **for untracked paths only** — "looks like a test artifact" is a belief,
    not a record) → an unrecorded fix goes to `FIX_SET` + re-stage. **An observed untracked path is NOT
    auto-deleted**: temporal appearance is not authorship — an operator or another process can create a
    file during a 90s verify run, and a path the project considered disposable would be gitignored and
    so absent from `porcelain` entirely. **Never delete it.** Instead stop with its own ask (not bullet 3's, whose "stash or commit" cannot
    clear an untracked dir): `⚠️` the path, then one `👉` — *gitignore it, or remove it yourself, then
    re-invoke*. A dirty tree is recoverable; a deleted file is not. Recurring artifact → gitignoring it
    is the permanent fix, after which it never reaches `porcelain` again. A **tracked-modified** path is **never owned by observation** — the operator can edit a tracked file
    during the verify window and before/after snapshots cannot say who wrote it (this is the same
    inference that was wrong for untracked paths; it is wrong here too, and worse, because the content
    is real work). Ownership for tracked paths comes only from a step **recording** that it wrote them
    (`FIX_SET`). An observed-but-unrecorded tracked change (a verify step refreshing a tracked lockfile or snapshot is
    the common case, and a terminal stop would make such a project unrunnable) → **6b.1 fork card**: the
    operator adjudicates ownership once, **both outcomes defined**: *verify output, take it* → `FIX_SET`
    + re-stage + re-enter 6b → 6b.2 → 6b.2b → 6c; *my work, stop* → `COMMITTED_SHA` set → push it (6d)
    **subject to the same check-1 path-set guard as the exhaustion stop**, then abort; unset → abort clean.
    A **recorded** tracked change still doesn't auto-certify: a path matching a **Decision-Gate criterion** (lockfile / CI workflow / root-build
    config / schema-migration) → **6b.1 fork card**, never silent certification (6b.2b's lenses don't
    test the gate, so a lockfile would otherwise ride the commit unreviewed); anything else → add to
    `FIX_SET` and certify with the rest. Never `git restore` it.  Name what was cleaned in the
    report. A run that **completes** must end with a clean tree, or the next invocation's 1.5 hard gate aborts on
    debris this run created; a run that stops at a `👉` ask instead names the paths the operator clears
    before re-invoking.
  - **anything else → STOP. Never delete or restore an unrecognized path.** The tree being clean at 1.5
    does *not* prove a dirty path is ours: the operator or another process can write during a
    long-running session, and the HEAD race check cannot see working-tree edits. Treat un-owned
    uncommitted work as unrecoverable, because it is. List them under `⚠️`, then **one** `👉` terminal
    ask (stash or commit them, re-invoke). Never offer to discard them, and **never commit `FIX_SET` around an unrecognized path** — that ends the run dirty. **Continuation depends on commit
    state:** *no commit yet* → abort clean, commit unmade (nothing was pushed; the run is idempotent).
    *A commit already landed* (post-commit re-entry) → the commit stands, so **push it first (6d), then**
    abort — never claim idempotence once a commit exists; the next run's 1.5 gate hard-aborts on it,
    blocking the PR until the operator resolves it.
- **6b.2b certify** — runs after reconciliation on every path that continues (the certification lives here, not inside 6b.2's STOP bullet; a run that took STOP has aborted and never reaches it): `git diff --cached $START_SHA --stat` + `git diff
  --cached $START_SHA`; judge the full diff — added lines **and** deletions/modification pairs —
  against: **new surface** (fresh null/bounds gap, type hole, dead code, over-claiming comment/doc
  phrase, lint/complexity ceiling just crossed) · **lost surface** (a deletion that removes a
  guard/validation/behavior with no replacement on the added side) · **class sibling** (re-run the
  Phase-4.5 signature on this diff — a fix can create a fresh sibling of the class it fixed) ·
  **cross-batch** (two 6a sub-agents on one surface) · **region** (this run touched a line **inside any
  interval** the 4d `region_map` carries — resolved threads included, **except the entry whose
  `thread_id` is the thread this edit's verdict implements** (per 4d: a reopened thread's own re-fix must
  not trip a finding no fold can discharge). Attribution comes from the 4c fix plan + the owning batch's
  `items`/`files_touched` — the same batch→surface mapping the cross-batch lens above already relies on.
  **Ambiguous** (two threads' items in one file, can't tell which produced the line) → **do not exclude,
  emit the finding**: a spurious fork is recoverable, a silently unguarded repeat patch is not. **Compare in old-side coordinates** — the frame `region_map` uses,
  which 1.5 step 3 guarantees equals `$START_SHA` by refusing to run ahead of origin. Per hunk
  `@@ -a,b +c,d @@` of the diff under certification (staged, or `$START_SHA..$COMMITTED_SHA` on the
  byte-mismatch path), walk the body with an old-side cursor starting at `a`, advancing
  on every `-` and context line; **test only `-` and `+` lines** — a `-` line at its cursor value, a `+`
  line at **cursor − 1** (the last old-side line consumed); **every** `+` is a zero-width insertion sitting in a gap, so test it **both ways** — `cursor − 1` and
  `cursor` (a leading `+`: `a-1` and `a`) — one-sided attribution silently unguards an interval starting
  at the line below. Exception: a `+` immediately following a `-` in the same hunk is that `-`'s
  replacement — `cursor − 1` only, else every replacement pair double-fires. **Context lines advance the cursor
  and are never tested**, else the hunk's ±3 context fires the check on lines this run never touched.
  Never test new-side numbers: this run's own inserts above a saved region shift them, so a repeat patch
  slips out of its interval and an unrelated edit slips in. Test range *overlap*, not
  equality with the end line → fix the region's root cause, NOT the line; a re-patched line draws a fresh comment
  next round). The skill's
  own gate on its own output — **not** a review pass; never spawn `harness:review-change` /
  `code-review` here. **Emit findings only** (one `file:line — <finding>` each; no per-check "clean"
  tokens), then one mandatory closing line: `self-check: <N> added / <R> removed lines / <M> files · <F> findings`.
  Findings → fix, re-stage, re-run 6b → 6b.2 → 6b.2b, commit once; **cap 2 passes — the initial certify is pass 1, so at most one fix-fold re-run** — a pass-2 survivor is a
  **known defect: never commit it silently** — stop, walk it as a 6b.1 fork (fix now / commit
  disclosed + follow-up issue / decline); never resolve its owning thread `fixed:` while the defect
  survives. Decision-Gate hit → 6b.1. Skip only on empty staged diff (6c.1) — never for "only prose/config".
- **6c commit:** **precondition** — a non-empty staged diff commits only with a `self-check:` line
  emitted against these exact staged bytes: none yet → run 6b.2 → 6b.2b first; staged diff changed since the
  check → stale, re-run 6b → 6b.2 → 6b.2b (the certify step is what emits the line — never stop at 6b.2). **Cap accounting, by trigger identity** (the rules must not
  collide): a pass is consumed **only** by a re-run following a fix folded from a 6b.2b finding **on the
  pre-commit path**. Every re-run triggered by bytes changing with no finding folded (re-stage of
  equivalent content, hook-fail fix) is free, and **every post-commit re-entry — byte-mismatch branch
  and dirty-tree branch alike — is free but separately bounded: at most 2 corrective re-entries (byte-mismatch, dirty-tree, and path-set branches all count), then
  **push what already landed (6d) — but only if that commit's path set satisfies check 1; a commit
  carrying a path outside `FIX_SET` is never pushed, exhausted or not** (check 1's invariant outranks
  the never-hold-unpushed rule below: pushing an unreviewed lockfile/workflow is the worse failure). Path
  set clean → push, then stop with the threads left open. Not clean → **don't push**: `⚠️` naming `$COMMITTED_SHA` and the extra path, one `👉` — the operator
  accounts for it or reworks the commit; the next run's 1.5 gate hard-aborts on the unpushed commit until
  they do. **Either branch:** **any hook output still uncommitted** stays in place — name it in the report as the
  reason the next run's 1.5 gate will need a stash (a path-set-only exhaustion leaves the tree clean and
  needs no such note).
  Never stop holding unpushed commits (the next run's 1.5 gate hard-aborts on them, blocking the PR until the operator resolves the commit)** (a hook that stamps a timestamp on every commit would otherwise re-enter
  forever, each pass free and the empty-diff check never firing). An operator picking "fix now" at the
  6b.1 pass-2 fork **resets the cap** (they explicitly authorized another round). Empty staged diff → **6b.2b** skipped (6b.2's reconciliation still runs — it's what removes verify
  debris), the empty-diff check below short-circuits.
  **race check** — `test "$(git rev-parse HEAD)" = "$EXPECTED_HEAD"` else abort (foreign commit landed). **Empty-diff** — `git diff --cached --quiet $EXPECTED_HEAD` (`$EXPECTED_HEAD`, not `$START_SHA` — on a corrective re-entry the index already carries the first commit's content, so a `$START_SHA` base reads non-empty and drives `git commit` on an empty index; `$START_SHA` stays the *certification* base only). Empty **and `COMMITTED_SHA` unset** → `SKIP_COMMIT=true` (6c.1). Empty **with `COMMITTED_SHA` set** → the correction is already contained: skip only the *commit* and **fall through to 6d** with the existing `COMMITTED_SHA` — never to 6c.1, which skips the push and would resolve threads against an unpushed commit (the staged payload is the candidate — a stray unstaged/untracked verify artifact is not work and must not enter the commit path). Else semantic commit of the staged payload (staged in 6b.2 — no re-add here). **The body quotes review text, which any commenter controls — write it to `"$(git rev-parse --git-dir)/HARNESS_COMMIT_MSG"` and `git commit -F` that path — inside `.git`, so it never appears in `porcelain` and can't trip the run's own reconciliation; never build the message inline in shell source.** Body lists `Addresses PR #N review:` with `<reviewer> L<line>: <one-line> (<comment-url>)`, prerequisite inline fixes named with causal reason. **Validate the message against HARNESS.md › Conventions before committing** — subject matches the project's declared commit contract, plus every trailer it requires; a non-conforming subject is a defect, not a style nit (on projects whose release derives from it, it silently breaks the release). **Never `--no-verify`**; pre-commit hook fail → diagnose, fix, **new commit (never amend)**.
  **Pin the commit, then advance** — the post-commit checks must not read a moving `HEAD`:
  `COMMITTED_SHA=$(git rev-parse HEAD)`; assert it's ours — `test "$(git rev-parse "$COMMITTED_SHA^")" = "$EXPECTED_HEAD"` else abort (a concurrent commit would otherwise be adopted as this run's baseline);
  then `EXPECTED_HEAD=$COMMITTED_SHA`, **before** post-commit verification and any corrective work
  (advancing later strands every correction — its race check would still read `$START_SHA`).
  **Post-commit verification** — two checks on the *committed* object, both before 6d:
  1. **Path set** — `git diff --name-only $START_SHA $COMMITTED_SHA` (never `$EXPECTED_HEAD`: it was
     advanced to `$COMMITTED_SHA` above, so that diff is `X..X` and always empty) must contain **no path
     outside** `FIX_SET` — a subset test, not equality: `FIX_SET` is append-only and a corrective commit
     carries only its own delta, so equality would fail on every re-entry. A hook that **creates and stages** a file puts it in the commit while
     leaving the tree clean, so 6b.2's reconciliation can never see it. Any extra path → gate it **at 6b.1** (a hook-generated
     lockfile / workflow / build config is exactly the load-bearing class that must not ride an
     unreviewed commit) → record in `FIX_SET` or resolve at the fork. **Not** 6b.2's bucket 3: that
     branch's push-then-abort is written for *uncommitted* un-owned work, and the path here is already
     inside the commit — following it would push the very path this check forbids pushing. **Never push a committed path `FIX_SET` doesn't account for.**
  2. **Bytes** — `git diff $START_SHA $COMMITTED_SHA` must byte-match the certified diff (a *successful*
     pre-commit hook can rewrite staged bytes silently). Mismatch → **the committed tree has never been
     verified**: re-run **`VERIFY_CMDS` (6b) first**, then 6b.2b against `$START_SHA..$COMMITTED_SHA` —
     a self-check judges text, not behavior, so a zero-finding self-check on formatter/generator output
     is not evidence the commit works. Either producing work → fix → stage into `FIX_SET` → **re-enter
     6c** (race check reads the advanced baseline), new commit, which pins and advances again.
  Both are free of the 2-pass cap; any corrective commit they produce — byte-mismatch, dirty-tree, or
  path-set — counts against the corrective-re-entry limit above. **Re-run the 6b.2 dirty-path reconciliation after every successful commit, byte-match or
  not** — a passing pre-commit hook can rewrite the *working tree* without staging, which leaves the
  committed diff matching the certified one (so the mismatch branch never fires) while the formatter's
  output sits uncommitted. **Post-commit, ANY `FIX_SET` path still showing in `git status --porcelain` — staged (`M `), unstaged
  (` M`), or both — is uncommitted output, NOT "staged, certified"** (a post-commit hook can modify
  *and stage* a path, leaving the committed diff byte-matching while the index holds newer bytes) (that bullet assumes staging just ran) → stage it and **re-enter
  6b → 6b.2 → 6b.2b → 6c** for a corrective commit. Never fall through to 6d with post-commit dirt: the remote
  would get the pre-rewrite bytes while the threads are resolved as fixed. Reconciliation alone doesn't
  discharge it — verification, self-check, and a commit do.
- **6c.1 empty-diff short-circuit:** SKIP_COMMIT=true (nothing to commit **and no commit made this run** — typically all DECLINE/ALREADY/UNCLEAR) → skip commit + push, **set `PUSH_OK=n/a`** (nothing cites a commit, so 6e/6f run normally while **6e.1 and 6h are skipped** — their messages would cite a commit that doesn't exist); go to reply/resolve; report `Commits: none — no fixes required.`
- **6d push:** push **the exact certified object**, never the moving branch tip (a bare `git push` would carry a concurrent local commit along with it): `git push origin "${COMMITTED_SHA}:refs/heads/<branch>"` — **quote the refspec**; unquoted `$VAR:` is a zsh history modifier and silently mangles the ref. `HEAD != $COMMITTED_SHA` (a commit landed after the last race check) → **still push `$COMMITTED_SHA`** — that is what the exact refspec is for — and report the foreign commit as unpushed; never abort holding a certified commit. No upstream yet → set it after a successful push (`git branch --set-upstream-to=origin/<branch>`); `-u` is inert with a SHA source. Never force-push without explicit request.
  **Confirm the commit is actually on the remote** — `git rev-parse origin/<branch>` contains
  `$COMMITTED_SHA` (`git merge-base --is-ancestor $COMMITTED_SHA origin/<branch>`) → **`PUSH_OK=true`**
  (assign it explicitly; downstream steps read it positively and must never read it unset). **Push failed or
  unconfirmed → `PUSH_OK=false`, which gates every **commit-citing** PR mutation** — 6e `fixed:` /
  `already: … commit:<this run's sha>` replies, 6e.1 dismissals, 6f resolves **of implemented-fix
  threads**, 6h re-request, and the report's PR-body refresh. The remote still lacks the fixes, so a
  `fixed:` reply makes the next run skip real work and dismissing the blocking review makes an unfixed
  PR look merge-ready. **Commit-independent work still runs** — `wontfix:` / `unclear:` /
  `already: … pre-existing` / `deferred:` replies and the DECLINE/ALREADY resolves they justify never
  depended on the push; suppressing them would close threads with no rationale. Report the `PUSH FAILED`
  lead + retry block alongside them. **No commit this run (6c.1)** → nothing cites a commit, so
  `PUSH_OK` is moot for replies + resolves — run them normally — but **6e.1 and 6h are skipped**: their
  messages cite a commit that doesn't exist, and there's no truthful dismissal to post. Capture CI URL: `CI_RUN_URL=$(gh run list --branch "<branch>" --limit 1 --json url --jq '.[0].url // ""')` (empty ok; 6c.1 skipped 6d → no CI link, render `➖`).
- **6e reply in-thread (machine-readable)** — **`PUSH_OK` gates only tags citing this run's commit**
  (`fixed:` / `already: … commit:<**this run's** sha>` — an `already:` citing a previously-pushed commit
  is already true on the remote and posts freely): `PUSH_OK=false` → withhold those, leave their threads open.
  Every commit-independent tag (`wontfix:` / `unclear:` / `already: … pre-existing` / `deferred:`)
  posts regardless. Tags — `fixed: <what>. commit:<sha7>` (when Phase-4.5 tier-1 siblings were fixed under this thread, append ` swept:<N> same class` before `commit:` — tells the reviewer/bot the class was cleared; add up to 2 file **basenames** only if the fully-serialized body incl. trailer stays ≤200, else emit the count alone — the report's Class-sweep section carries the full file list) · DECISION-NEEDED `fixed: <what>. choice:<A|B|custom>. commit:<sha7>` · `wontfix: <reason>. ref:<path/rule>` · `already: <where>. commit:<sha7|pre-existing>` · `unclear: <question>` · `deferred: <issue-url>`. **For `fixed:` tags (incl. the DECISION-NEEDED form), `<sha7>` is always the run's FINAL `$COMMITTED_SHA`** (the one the remote has), never a per-thread landing commit — a multi-commit run otherwise seeds two distinct `commit:` values and inflates the next run's `RUN_N` into a false brake. **`already:` is exempt**: it cites the commit that actually made it true — **verified present on the remote** (`git merge-base --is-ancestor <sha> origin/<branch>`), else emit `pre-existing` rather than a sha a reviewer cannot find — this run may have made no commit at all. No greetings/thanks/backticks; ASCII; ≤200 chars (hard cap 500 excl. trailer); tag is first token (parsers split on `:`). **Validate the serialized body length (incl. trailer) before the API call** — over 200 → drop the `swept` file list first, then truncate `<what>`; never exceed the 500 hard cap. **Mandatory signature trailer** — blank line then `[harness:address-pr-comments]` on its own final line (idempotency). Post: inline reply `gh api repos/$OWNER/$NAME/pulls/$PR/comments/$ROOT_COMMENT_ID/replies -f body="$(printf '%s\n\n[harness:address-pr-comments]\n' "$BODY")"` (use `-f body=`, not `--input -`); top-level review/issue → issue comment with a parseable `Re-review-<review-id>:` header line + the tagged reply. Throttle `sleep 2`; on 422 abuse / 403 Retry-After honor header or wait 60s, retry. >20 replies → single aliased GraphQL mutation.
- **6e.1 dismiss stale top-level reviews** (`PUSH_OK` required — never dismiss a blocking review while the fixes are local-only): for each `CHANGES_REQUESTED` review whose inline findings were all handled — **bot reviewers** (login ends `[bot]`) auto-dismiss (`gh api -X PUT repos/$OWNER/$NAME/pulls/$PR/reviews/$REVIEW_ID/dismissals --field message='superseded by commit:<sha7>'`); **human reviewers** → surface command in report, don't auto-dismiss. Failures non-fatal.
- **6e.2 bulk reply (N>20):** one aliased GraphQL mutation (`r1: addPullRequestReviewThreadReply(...)`, `r2: ...`), two requests total. REST fallback ≤20 with throttle.
- **6e.3 failure handling:** continue on failure; per call capture stderr+status, retry once on 422 abuse / 403 Retry-After, then record `{ids, command, error}` in `FAILURES`; surface a copy-paste retry block in the report.
- **6f resolve threads** (**skip every implemented-fix thread when `PUSH_OK=false`** — only
  DECLINE/ALREADY, whose verdicts don't depend on a commit, may resolve, **and only once their 6e
  rationale reply actually posted** — resolving a thread whose explanation was withheld closes it
  silently): for
  AUTO-FIX(implemented)/DECISION-NEEDED(implemented)/DECLINE/ALREADY — `gh api graphql -f query='mutation($threadId:ID!){resolveReviewThread(input:{threadId:$threadId}){thread{id isResolved}}}' -F threadId=<id>`. Don't resolve UNCLEAR. Skip `ThreadID: none` (top-level — dismissed via 6e.1) and already-resolved. >20 → aliased mutation. Failures per 6e.3.
- **6g deferred follow-ups (option D):** **review-derived text is attacker-controlled** (any commenter
  picks the title/body text) — never interpolate it into shell source. Write the body to a file and pass
  values as separately-quoted arguments: write **both** title and body to files with the file tool (never assign review text in shell source — a `'` in a comment breaks out of the assignment), then `gh issue create --title "$(cat <title-file>)" --body-file <body-file> --label "${DEFERRED_LABEL:-deferred}"` (host per HARNESS.md; label from HARNESS.md when declared, else `deferred`). **Search for an existing follow-up citing this comment URL first** — reuse it rather than filing a duplicate when a prior run created the issue but its reply failed. Then post the
  `deferred: <url>` reply. **Resolve the source thread only after BOTH the issue creation and the reply
  succeed** — either failing leaves the thread open and takes 6e.3 failure handling, so a lost follow-up
  never looks handled.
- **6h re-request review** (`PUSH_OK` required): if `CHANGES_REQUESTED` and ≥1 fix — bots auto `gh pr edit <n> --add-reviewer <user>`; humans → suggest in report.

## Final report (rendered markdown, never a code fence; omit zero-count rows)
Lead (bold, one line) — **form follows the push outcome**: commit pushed → `✅ PR #N — <title> · X fixed · Y resolved · pushed <sha7>`; no commit (6c.1) → `✅ PR #N — <title> · Y resolved · no commit — no fixes required`; push failed → `⚠️ PR #N — <title> · X fixed · committed <sha7>, PUSH FAILED — <reason>` (never claim a push that didn't land). (⚠️ + failure count if anything else failed.) Then: **Outcome table** (status/count/detail — 🔧 Fixed · 🤔 Decided · 🚫 Declined · ✅ Already · ❓ Unclear · ⏭️ Deferred · ⏭️ Skipped); **Decisions table** (only if ≥1 operator decision); **Verification + GitHub** (Typecheck/Lint/Tests ✅/❌/➖ · Self-check `<N> added / <R> removed lines / <M> files · <F> findings folded` (`<F>` = **cumulative across passes**, not the final pass's line — that one is 0 by construction whenever findings were folded) (2-pass-cap survivors, if any: `> ⚠️` callout under this section, one `file:line — <finding>` each; empty-diff run (6c.1) → `Self-check ➖ skipped — empty diff`, never fabricated counts) · Threads resolved · Replies posted · Stale reviews dismissed · Re-request review · CI run link); **Files touched** (clickable bullets); **Tail** (cascading auto-fixes if any); **Class sweep** (only if
Phase 4.5 found siblings) — per class: `<class> — <T1> tier-1 fixed · <T2> tier-2 surfaced · <G> gate-deferred`
(omit a zero term), then the **tier-1 `file:line` list** (the full swept-file list a 6e reply may abbreviate); for
tier-2 a `> ⚠️` callout listing `file:line` instances + a copy-paste `gh issue create` command (never
auto-filed — pre-existing debt, operator's call); for gate-deferred a `> 🤔` callout listing `file:line` +
gate criterion (also walked in 5d / shown in the Decisions table when interactive). **Failures block** (only if non-empty): `> ⚠️` callout + fenced bash of copy-paste retry commands. **Decision log** (when this PR maps to a harness change with a `harness/` dir): append each *load-bearing* decision — a `🔧 fix`, `🚫 decline`, or `⏭️ defer` with its reasoning, and any 5d-wizard pick the **human** made — to `<change-state-dir>/decisions.md` per `references/decision-log.md` (`🤖 address-pr-comments` / `👤 human`). Skip routine auto-fixes. **Refresh PR summary** (same condition — this PR maps to a harness change with a `harness/` dir, and a commit landed this run **and `PUSH_OK`** — never describe local-only commits in the remote PR body): after the decision-log append, re-fold `<change-state-dir>/pr-body.md` per `references/pr-summary.md` (it now carries the new commits + decisions) and update the PR description with it (`gh pr edit <n> --body-file <change-state-dir>/pr-body.md`, rewriting only inside the managed region). **Idempotency key:** if no commit landed this run (empty-diff short-circuit 6c.1) the body is unchanged → **skip the refresh.** On a fold, stamp the footer (`folded-against` = pushed HEAD; `generated-by: harness:address-pr-comments v<hash8>`). **Pipeline trail** (one line, before the next pointer): the "you are here" trail for the `address-pr-comments` end stop per `references/pipeline-map.md`. **Next pointer** (one line) — **branch on the resolved Finish merge mode** (one runnable command rule): **two-merge** → finish is post-merge; name **only the immediately-runnable action — review + merge the PR** (human action, no command yet), **do NOT print `/harness:finish` or "run X after merge"** (premature, mis-fire risk); finish surfaces as the trail's `◦ finish` label only. **single-merge** → finish rides the still-open PR (archive-before-merge), so `/harness:finish` **is** runnable now; Next = `/harness:finish` (don't tell the operator to merge first — that inverts single-merge).

## Principles
Correctness over scope · standards are authority · auto-fix is default (Decision Gate is the filter) ·
sweep the class not just the instance (rg → tier-1 added-line auto-fixed, tier-2 surfaced; per-candidate gate) ·
self-check own fix diff before commit (6b.2b) · convergence brake at run #3 (5c.1) ·
parallelize aggressively · idempotent by trailer (`[harness:address-pr-comments]`) · YAGNI before
accepting abstractions · machine-readable replies (trailer mandatory) · resolve what you fixed (dismiss
stale bot reviews) · stop only at genuine forks (no plan-approval gate) · report is rendered markdown ·
end-to-end in one run.
