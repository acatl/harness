---
paths:
  - ".claude/skills/**"
  - "rules/**"
  - "templates/**"
---

# Skill authoring style

Skills are read by a machine, not a human. Optimize the **body** for an LLM executor.
This rule auto-loads (path-scoped) whenever you edit a skill body, a bundled `references/` input,
or a canonical `rules/`/`templates/` source — the moments skill-authoring judgment applies.

## Form
- Structured, telegraphic, deduplicated. Zero rhetoric — no prose, motivation, transitions, hedging.
- **Every decision-bearing datum kept.** Telegraphic ≠ lossy. Compress wording, never drop a fact that
  changes behavior (a path, an order, a guard, a branch, an exact string).
- Prefer: imperative fragments, tables, numbered steps, `key → value`. Drop articles/filler.

## Do / Don't
- **Drop** a `Don't` that is just the inverse of a `Do` (redundant).
- **Keep** a `Don't` / out-of-scope line when it states a non-redundant boundary:
  - a tempting-but-wrong path,
  - an assumed-in-scope-but-isn't,
  - a foot-gun with no positive-form home.

## Scope of the rule
- Applies to **procedural SKILL.md bodies** — steps, modes, taxonomies, templates, flow. These
  compress safely (imperative/structured; telegraphic loses nothing).
- **Frontmatter `description` stays natural-language and trigger-rich** — the router reads it to
  decide activation; keyword/trigger coverage matters more than brevity there. Do not telegraph it.

## Do NOT compress (completeness > brevity — compressing risks value)
- **Judgment-criteria references** (review *lenses*, rubrics): the prose carries the *why* and the
  *how-to-recognize* a model uses for borderline calls. Genericize, but keep them full.
- **Calibration / worked examples** that teach *how to judge* (e.g. second-order-thinking examples):
  the explanation IS the value; a bare bullet list drops it.
- Rule: if a passage teaches *judgment* rather than *procedure*, preserve it. When unsure whether
  compressing a passage loses value, **don't** — leave it fuller.

## Breadcrumbs
Every **`harness:` pipeline skill** body emits a start line `▶ harness:<name> …` (a hash-free locator) and
an end line `■ harness:<name> v<hash8> → <outcome>`. (General co-shipped skills that aren't part of the
pipeline — e.g. `walk-me-through` — don't carry breadcrumbs.) These land in the Claude Code session
transcript so harness iteration can grep it to locate every skill run, attribute it to a skill content-version, and read its
outcome.
- The `## Breadcrumbs` block is **self-contained in each SKILL.md** — skills travel as standalone dirs
  and cannot reference repo docs at runtime.
- `<hash8>` = first 8 chars of `git hash-object` of the skill's own SKILL.md — its content version, so
  transcript friction can be attributed to a specific skill version. **It goes on the END line, not the
  start.** The start line is the first thing emitted — pure text, before any tool call — so a start-line
  hash reliably under-fires (the agent emits a placeholder rather than stopping to run a command). At end
  the skill is already running its wrap-up Bash (git/gh/run-log), so the `git hash-object` rides that
  rhythm and computes for real; it also pairs version + outcome on one greppable line. (Finding AE.)

## Operator input (👉)
Any line that needs the operator's answer — a question, a confirm, a pick — is prefixed `👉` and placed
as the **terminal block** of the message: below the breadcrumb / pipeline-trail / next-step, with nothing
actionable under it. The failure this prevents: a blocking question rendered *above* more text and a
ready-to-run action gets skipped — the operator's eye lands on the action and executes it, ignoring the
question. The eye must land on the `👉` last.
- **Self-contained in each SKILL.md** (like Breadcrumbs) — skills travel standalone, can't reference this
  doc at runtime. Each skill carries a `## Operator input` block.
- **No false-ready next.** While a `👉` prompt is open, don't print a runnable `/harness:` next as the
  move — show it as gated behind the answer.
- **Reserved marker.** `👉` means *blocking on the operator only* — not status, not the trail. Distinct
  from `⚠️` (warning) / `✨` (improvement) / `❓` (unclear-status).
- **Fork cards are already the terminal block — don't `👉`-prefix their lines.** A walk-me-through fork
  card (`rules/walk-me-through.md`) *is* the operator-input block; reproduce its lines (incl. `Pick:`)
  **verbatim**. `👉` is for a **bare inline ask** (a one-line question/confirm that isn't a fork card) —
  put that ask, `👉`-prefixed, as the terminal block. A fork card needs no `👉`; it just needs to be last.

## Bundled resources
A skill is a **standalone dir** — it's symlinked into consuming projects (and may later be copied or
plugin-packaged), so it cannot reach repo-root `templates/` or `docs/` at runtime. Every input a skill
reads at runtime must live **inside the skill dir**, referenced by a skill-relative path:
- `templates/` — files the skill *emits* into a project (e.g. `harness:init` writes `HARNESS.md`, the
  context-doc templates).
- `references/` — files the skill *reads* (schemas, lenses, the runtime-verification binding, the
  sensor baseline).
- SKILL.md refs these as `references/foo.md` / `templates/foo.md` — never `../../templates/...` (a
  relative climb out of the dir breaks when the dir is copied/packaged) and never an absolute path.

**Single source of truth + sync.** The canonical copy of a shared input stays at repo root
(`templates/`, `docs/`); the bundles are copies kept in sync by `scripts/sync-skill-resources.sh`
(manifest of canonical→bundle pairs). After editing a canonical template/doc, run it (`sync`); CI/pre-push
runs `check` and fails on drift. Add a new bundled input → add its pair to the manifest.

## Tooling
- `compress-skill` (installed) does a behavior-preserving compression with oracle falsification — use
  it for a rigorous pass on an existing verbose skill. New skills: author telegraphic from the start.
