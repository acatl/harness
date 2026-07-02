# Contributing

Thanks for helping improve the harness. This repo is **mostly Markdown** — skills,
references, and design docs — so "contributing" is mostly writing clear, machine-readable
prose. A few rules keep it consistent.

## Ground rules

- **Conventional Commits only** (`feat:` / `fix:` / `docs:` / `chore:` / `refactor:` /
  `test:` / `style:` / `ci:`). A non-conforming subject is a defect — enforced by a husky
  `commit-msg` hook running commitlint (`commitlint.config.cjs`); `npm install` wires it up via
  the `prepare` script.
- **Never commit to `main`.** Work on a branch; land via a squashed PR to `main`.
- **Skills are stack-agnostic.** A skill names the binding it needs ("run the `test` sensor
  declared in HARNESS.md"), never a literal command. Per-project specifics live in a consuming
  project's `docs/HARNESS.md` — never hardcode a stack command, path, or convention into a skill.

## Authoring skills

- Skill bodies are **telegraphic** — structured, deduplicated, zero rhetoric, every
  decision-bearing datum kept. See [docs/SKILL-STYLE.md](docs/SKILL-STYLE.md).
- Frontmatter `description` stays natural-language and trigger-rich (the router reads it).
- Required frontmatter: `name`, `description`, and `metadata.author`. CI enforces this.
- Every **`harness:` pipeline skill** emits **start/end breadcrumbs** and carries the **Operator-input
  (`👉`)** block — both self-contained per SKILL.md (skills travel as standalone dirs). General
  co-shipped skills like `walk-me-through` aren't part of the pipeline and don't carry these. See SKILL-STYLE.md.

## Bundled resources (drift guard)

Skills are **self-contained**: a skill reads only inputs bundled in its own dir
(`templates/`, `references/`) — never repo-root `templates/`/`docs/` at runtime (skills are
symlinked/copied into other projects). Repo root is canonical; bundles are kept in sync by
`scripts/sync-skill-resources.sh`. **After editing a canonical template/doc, run it:**

```bash
scripts/sync-skill-resources.sh        # copy canonical → bundles
scripts/sync-skill-resources.sh check  # CI mode: exit 1 on drift
```

## Versioning

`package.json` version follows [Semantic Versioning](https://semver.org/). There's no npm-registry
consumer — the harness distributes via `npx skills add acatl/harness` reading the repo directly —
so this is a lightweight manual scheme, not full automated release tooling:

- Bump the version and add a [`CHANGELOG.md`](CHANGELOG.md) entry on any notable change: a new
  skill, a breaking change to an existing skill's behavior, or a new binding contract in
  `templates/HARNESS.md`.
- Commit-type discipline (`feat:`/`fix:`/etc., enforced above) is what makes bump-size judgment
  possible — patch for `fix:`, minor for `feat:`, major for a documented breaking change.

## Local checks

```bash
npm install      # one-time: installs markdownlint + cspell + husky/commitlint hook
npm run check    # markdown lint · spell · bundle drift · skill frontmatter
```

New domain terms flagged by the spell checker go in [`project-words.txt`](project-words.txt).
CI runs the same checks plus an offline internal-link check on every PR.
