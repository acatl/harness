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
  decision-bearing datum kept. See [.claude/rules/skill-authoring.md](.claude/rules/skill-authoring.md).
- Frontmatter `description` stays natural-language and trigger-rich (the router reads it).
- Required frontmatter: `name`, `description`, `metadata.author`, and `metadata.version`. CI enforces
  this. (`metadata.version` is release-managed — see Versioning.)
- Every **`harness:` pipeline skill** emits **start/end breadcrumbs** and carries the **Operator-input
  (`👉`)** block — both self-contained per SKILL.md (skills travel as standalone dirs). General
  co-shipped skills like `walk-me-through` aren't part of the pipeline and don't carry these. See
  [.claude/rules/skill-authoring.md](.claude/rules/skill-authoring.md).

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

Versioning follows [Semantic Versioning](https://semver.org/) and is **fully automated by
[release-please](https://github.com/googleapis/release-please)** — you never bump a version by hand:

- Merge normal PRs to `main`. release-please reads the Conventional Commit types since the last
  release and maintains a standing **Release PR** that accumulates the pending bump + changelog
  (patch for `fix:`, minor for `feat:`, major for a `!`/`BREAKING CHANGE:`).
- **Merging that Release PR** is what cuts a release: it bumps `package.json`, stamps the same
  version into every skill's `metadata.version` (one shared version — skills depend on each other),
  regenerates [`CHANGELOG.md`](CHANGELOG.md), tags, and creates a GitHub Release.
- This respects "never commit to `main`": the bump travels through the Release PR, not a direct
  push. There's no npm publish — the harness distributes via `npx skills add acatl/harness` reading
  the repo directly.

Config: [`release-please-config.json`](release-please-config.json) +
[`.release-please-manifest.json`](.release-please-manifest.json); the per-skill stamp target is the
`version: "…" # x-release-please-version` line in each `SKILL.md` frontmatter.

## Local checks

Requires **Node ≥ 22.12** (commitlint 21.x needs it; also matches CI). Check with `node -v`.

```bash
npm install      # one-time: installs markdownlint + cspell + husky/commitlint hook
npm run check    # markdown lint · spell · bundle drift · skill frontmatter
```

New domain terms flagged by the spell checker go in [`project-words.txt`](project-words.txt).
CI runs the same checks plus an offline internal-link check on every PR.
