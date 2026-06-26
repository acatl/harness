# Convention Load Map

## Approach: dynamic discovery (inline)

Conventions are discovered at runtime by Step E surface mapping (inline, run by the orchestrator) —
not from a static config file. This keeps the skill portable across projects with different rule sets
without per-project setup.

## How discovery works

1. List all files under the rules dir (HARNESS.md › Paths — e.g. `.claude/rules/`).
2. Read the heading and first paragraph of each rule file.
3. Match rule files to the surface-mapped file set by keyword overlap. Examples:
   - Rule mentions "routes", "controllers" → matches route/controller files
   - Rule mentions "entity", "timestamp" → matches entity files
   - Rule mentions "DTO", "mapper" → matches DTO / shared-package files
   - Rule mentions "migration" → matches migration files
   - Rule mentions "markdown", "ADR" → matches `**/*.md`
   - etc.
4. **Always include** any rule whose heading or first paragraph references git, PR workflow, or
   pre-commit conventions, regardless of detected surface.

## Why no static config

A config file would need to be authored and maintained per-project. Projects with different rule
naming, folder structures, or tooling would all need custom maps. Dynamic discovery adapts
automatically as rules and file structures evolve.

**Trade-off accepted:** discovery is non-deterministic across runs. Two runs of the same change might
load slightly different rule sets if rule file content changes. This is acceptable — rules rarely
change mid-implementation, and the surface map is regenerated fresh each build.

## If discovery misses a rule

If an implementing agent violates a convention that should have been loaded, the fix is to make the
rule file's heading and opening paragraph more explicit about the file patterns it governs. The rule
file is the source of truth; Step E reads it to infer scope.

Example — if a timestamp rule is being missed for entity files:

```text
Current heading: "Entity timestamp columns"
Current opening: "Use the created/updated decorators via the base entity..."

Better opening: "Applies to all entity files under <entities dir>. Use the created/updated decorators
via the base entity..."
```

The added phrase gives discovery the file-path signal it needs to match.
