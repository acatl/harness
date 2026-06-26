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
- Applies to the **SKILL.md body** (and references/).
- **Frontmatter `description` stays natural-language and trigger-rich** — the router reads it to
  decide activation; keyword/trigger coverage matters more than brevity there. Do not telegraph it.

## Tooling
- `compress-skill` (installed) does a behavior-preserving compression with oracle falsification — use
  it for a rigorous pass on an existing verbose skill. New skills: author telegraphic from the start.
