# Contributing

Thanks for helping improve the harness. This repo is **mostly Markdown** — skills,
references, and design docs — so "contributing" is mostly writing clear, machine-readable
prose. A few rules keep it consistent.

## Ground rules

- **Conventional Commits only** (`feat:` / `fix:` / `docs:` / `chore:` / `refactor:` /
  `test:` / `style:` / `ci:`). A non-conforming subject is a defect.
- **Never commit to `main`.** Work on a branch; land via a squashed PR to `main`.
- **Skills are stack-agnostic.** A skill names the binding it needs ("run the `test` sensor
  declared in HARNESS.md"), never a literal command. Per-project specifics live in a consuming
  project's `docs/HARNESS.md` — never hardcode a stack command, path, or convention into a skill.

## Authoring skills

- Skill bodies are **telegraphic** — structured, deduplicated, zero rhetoric, every
  decision-bearing datum kept. See [docs/SKILL-STYLE.md](docs/SKILL-STYLE.md).
- Frontmatter `description` stays natural-language and trigger-rich (the router reads it).
- Required frontmatter: `name`, `description`, and `metadata.author`. CI enforces this.
- Every skill emits **start/end breadcrumbs** and carries the **Operator-input (`👉`)** block —
  both self-contained per SKILL.md (skills travel as standalone dirs). See SKILL-STYLE.md.

## Bundled resources (drift guard)

Skills are **self-contained**: a skill reads only inputs bundled in its own dir
(`templates/`, `references/`) — never repo-root `templates/`/`docs/` at runtime (skills are
symlinked/copied into other projects). Repo root is canonical; bundles are kept in sync by
`scripts/sync-skill-resources.sh`. **After editing a canonical template/doc, run it:**

```bash
scripts/sync-skill-resources.sh        # copy canonical → bundles
scripts/sync-skill-resources.sh check  # CI mode: exit 1 on drift
```

## Local checks

```bash
npm install      # one-time: installs markdownlint + cspell
npm run check    # markdown lint · spell · bundle drift · skill frontmatter
```

New domain terms flagged by the spell checker go in [`project-words.txt`](project-words.txt).
CI runs the same checks plus an offline internal-link check on every PR.
