# Skill authoring style

Skills are read by a machine, not a human. Optimize the **body** for an LLM executor.

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
Every skill body emits a start line `▶ harness:<name> v<hash8> …` and an end line
`■ harness:<name> → <outcome>`. These land in the Claude Code session transcript so harness iteration
can grep it to locate every skill run, attribute it to a skill content-version, and read its outcome.
- The `## Breadcrumbs` block is **self-contained in each SKILL.md** — skills travel as standalone dirs
  and cannot reference repo docs at runtime.
- `<hash8>` = first 8 chars of `git hash-object` of the skill's own SKILL.md — its content version, so
  transcript friction can be attributed to a specific skill version.

## Tooling
- `compress-skill` (installed) does a behavior-preserving compression with oracle falsification — use
  it for a rigorous pass on an existing verbose skill. New skills: author telegraphic from the start.
