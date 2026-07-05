# Staged review — the four internal stances

The review runs **inside a single reviewer-fixer sub-agent**. That one agent loads
`reference/framework.md` (the 13 lenses + return format) once, gathers the diff
once, then runs the four stances below **sequentially in its own context**,
carrying every prior finding in memory and applying clear fixes between stances.

This file is the per-stance payload: what each stance focuses on, in order. The
orchestration loop, fix-vs-queue guardrails, short-circuit, and final gate live in
`SKILL.md` under "How it works".

## How the agent moves between stances

- **One context, one model.** The agent inherits the session model and runs every
  stance at it.
- **Memory.** The agent already holds every finding it raised in earlier stances;
  it must **not** re-report them — build on them instead.
- **Fix as you go.** After each stance, the agent applies that stance's `Fix
  class: clear` fixes to the working tree (obeying the `SKILL.md` guardrails) and
  queues `decision-needing` findings. The next stance reads the **post-fix tree**
  the prior stances just produced — fixed code can no longer re-trigger a finding,
  which reinforces the memory-based dedup.
- **Stances are exclusive, not additive.** Stage 1 is the broad baseline. Each
  later stance runs **only its delta** — it does not re-run the full 13-lens sweep
  the baseline already did. This is what keeps later stances from re-surfacing
  baseline findings.

---

## Stage 1 — Baseline

**Stance: baseline.** The broad first pass. Apply the full 13-lens framework
across the entire diff with no narrowing. The job is coverage: every lens that
applies to this stack, every changed file. Do not go deep on any single
cross-cutting concern yet — later stances do that. Report everything the framework
flags, classified by severity and `Fix class`; apply the clear fixes before moving
on.

---

## Stage 2 — Cross-cutting

**Stance: cross-cutting contracts & invariants.** Stage 1 covered breadth. Go
**deep** on the concerns that span files and layers, where a single change ripples
into a contract or an invariant. Do **not** re-run the baseline sweep — only the
delta below:

- **Wire / contract fidelity**: does the OpenAPI registration match the runtime
  route — methods, params, request/response shapes, status codes, `security`? Do
  the DTO interface, Zod schema, and mapper agree? Does the response shape match
  what the SDK / clients expect?
- **Security boundaries**: ownership scoping on every repository query (`userId`),
  nested-resource parent-chain checks, attribution on every mutation, no internal
  identifiers leaking through DTOs.
- **Concurrency / atomicity**: count-check-then-insert races, row-cap enforcement
  inside transactions, friendly-ID allocation gap-freeness, partial-failure
  rollback on multi-step operations.
- **Edge cases**: empty / null / boundary inputs, the 10x-volume path, the
  mid-transaction failure path.
- **Client-surface & telemetry parity**: a new endpoint with no SDK/MCP/CLI
  decision recorded; a new instrumentable surface with no span and no recorded
  exclusion.

Verify claims by reading both sides (e.g. read the OpenAPI registry AND the route
handler). Build on stage-1 findings; deepen or correct one only if stage 1 got it
wrong — never restate it.

---

## Stage 3 — Adversarial-verify

**Stance: adversarial verification of the fixes already applied.** The clear
findings from stages 1–2 are now fixed in the working tree. Try to **prove those
fixes wrong**, plus a residue sweep. For each applied fix:

- **Regression**: did the fix change behavior somewhere else? Read the call sites
  and siblings of every edited symbol.
- **Missed sibling**: if a fix was applied in one place, does an analogous place
  need the same fix and not get it? (e.g. task-import got a rollback test but
  feature-import didn't.)
- **Dead-test / vacuous assertion**: does a newly added or edited test actually
  assert the named behavior, or does it pass trivially? Does it assert both
  presence AND absence (the side-effect was prevented)?
- **Contract drift introduced by the fix**: did widening a schema or changing a
  signature break another consumer?

Then sweep for anything stages 1–2 missed entirely. Default to skepticism: a fix
is guilty until the code proves it innocent. If a fix introduced a real problem,
report it as a Blocker/Warning with `Fix class` set appropriately (regressions are
usually `clear` — fix them; design reconsiderations are `decision-needing`).

If **no fixes were applied** in stages 1–2, the agent skips this stance
(nothing to refute) — see `SKILL.md` short-circuit.

---

## Stage 4 — Docs-alignment

**Stance: documentation & cross-reference drift, whole-repo.** Code is now in its
final post-fix state. Hunt drift between the code and every prose / config surface
that describes it — not just touched files, the **whole repository**:

- **Rename drift**: every function/route/entity/field/concept renamed in this
  branch — grep `docs/`, `openspec/`, `README` files, `.claude/rules/`, ADRs,
  docstrings, error messages, lint/CI config for the OLD name.
- **Signature / shape drift**: a changed parameter list, field list, or interface
  — find every prose enumeration of it and reconcile.
- **Numeric drift**: phase/step numbers, "N tools / N tables / N steps" counts,
  version labels — grep for the OLD number, verify each hit. (Recurring PR-comment
  issue: hardcoded derivable counts.)
- **OpenAPI / README / spec vs implementation**: usage examples, documented file
  paths, described-but-absent files, OpenAPI shapes vs handlers.
- **Code-comment drift**: in every touched file, re-read each comment/docstring;
  flag any whose premise the change invalidated (a removed cap, an inverted retry
  semantic, a stale cache-key shape).
- **Description vs diff**: verify each bullet in the PR description / proposal /
  commit body against what the code actually does.

Most doc fixes are `Fix class: clear` (update the stale reference) — apply them. A
doc fix that requires a judgment call about intent is `decision-needing`. Do not
touch `openspec/specs/` directly or archived changes — queue those as
`decision-needing` per the OpenSpec workflow rule.
