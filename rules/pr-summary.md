# PR summary — `harness/pr-body.md`

A per-change, **committed** PR description **folded** from the change's existing artifacts — never
re-analyzed from the diff. **Composition, not generation:** every line traces to something already on
disk, so the summary is cheap (inputs are pre-distilled) and assumption-free (no claim without a source)
by construction.

## Where
`<change-state-dir>/pr-body.md` (the change's committed `harness/` dir). `harness:ship` opens the PR
**from this file**; later PR-touching skills **refresh** it in place (below).

## The fold — section → source (cite, never re-derive)
| Section | Source artifact(s) |
|---|---|
| Title + lead (≤4 lines prose) | `proposal.md` (Why / What Changes) |
| **Architecture** | `design.md` (load-bearing decisions) + `architecture-review.md` (esp. any 🔴) |
| Diagram | `design.md` — **link iff it authored one; never synthesize** |
| What changed | `tasks.md` + commit groups + `proposal.md` Impact (file/task/commit counts) |
| Decisions & why | `decisions.md` **verbatim** + `More:` pointers (per `decision-log.md`) |
| Verification | run-log + `architecture-review.md` / `design-review.md` outcome lines |
| Deferred | `decisions.md` deferrals + skeptical-review notes |

## Rules
- **Cite-or-cut.** Each section ends with a `<sub>Sources: …</sub>` line naming its on-disk origin.
  No artifact → no section. This is what enforces zero-assumption — it is not optional polish.
- **Empty input → omit the section** (don't fabricate a placeholder).
- **Architecture = prose, ≤4 lines + the 🔴 story.** Distill the *shape* of the change from `design.md`
  decisions; do not dump the review (link it). This is the section a plain commit-group summary lacks.
- **Diagram is link-only.** If `design.md` has a diagram, link it; otherwise omit. Synthesizing a
  diagram from the diff breaks both cheap and zero-assumption — out of scope here (it's a `design` job).
- **Digestible, not exhaustive.** Prose + tight bullets; a reviewer should grasp the change in one read.

## Managed region
Wrap the whole generated body in:
```text
<!-- harness:pr-summary START … --> … <!-- harness:pr-summary END -->
```
Refresh rewrites **only inside** the fence. Anything a human adds outside it (reviewer context, threads)
is preserved.

## Provenance footer (last thing inside the fence)
```text
<!-- harness:pr-summary meta
folded-against: <full-SHA of branch HEAD at fold time>
generated-by:   harness:<skill> v<hash8>     (skill + git hash-object skill-version; never a placeholder)
artifacts:      <comma list of source files folded>
-->
<sub>Last folded against `<short>` · "<subject>" — stale if branch HEAD has moved (excluding summary-only commits).</sub>
```
Two layers (machine block + human line), matching the project's machine/human split. `folded-against` is
`git rev-parse HEAD` **before** committing the refreshed body.

## Refresh — who, when, idempotency
- **build** — initial emit at verified-not-shipped (as today).
- **ship** — re-fold from latest artifacts, then open the PR.
- **address-pr-comments / fine-tune** — after a batch lands (these grow `decisions.md`), re-fold +
  `gh pr edit --body`.
- **Idempotency key = `folded-against`.** Before folding, compute staleness; if **not** stale, the
  refresh is a **no-op — skip the fold entirely** (no LLM call). Refresh only spends tokens when source moved.

### Staleness (deterministic — machine or pre-finish check)
Given footer `folded-against`:
```bash
git merge-base --is-ancestor <folded-against> HEAD   # false → rebased → STALE
git diff --quiet <folded-against>..HEAD -- . ':(exclude)**/pr-body.md'   # diff present → STALE
```
The `:(exclude)**/pr-body.md` is required — the summary commit advances HEAD, so without it every
refresh reports itself stale. `harness:finish` MAY pre-check this and offer a refresh before merge.

## Don't
- No diff re-analysis; no claim without a cited source; no synthesized diagram.
- Don't write outside the fence; don't drop the provenance footer; don't emit a `vTBD`/placeholder version.
- Don't re-dump a review — link it (per `decision-log.md`); don't restate `decisions.md` in prose (fold it).
