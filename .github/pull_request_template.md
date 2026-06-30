<!--
PR body should explain WHAT (behavior level), WHY (trajectory / prerequisites /
alternatives considered), and the RISK surface (what to watch, what was deferred).
One-line bodies are defects on non-trivial changes.
-->

## What

<!-- Behavior-level summary of the change. -->

## Why

<!-- Trajectory, prerequisites (with causal framing), alternatives considered. -->

## Risk surface

<!-- What to watch; what was deferred to follow-up. -->

## Checklist

- [ ] Conventional Commit subject(s)
- [ ] `npm run check` passes locally (markdown lint · spell · bundle drift · skill frontmatter)
- [ ] Edited a canonical template/doc? Ran `scripts/sync-skill-resources.sh`
- [ ] New skills carry `name` + `description` + `metadata.author`, breadcrumbs, and the `👉` block
