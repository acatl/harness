# Verification Matrix

## Approach: soft per-task + hard per-group (two layers)

Neither layer requires a static config file. Commands resolve from **HARNESS.md › Sensors** — never
hardcode a runner.

## Layer 1 — Soft per-task verification

After each task edit, the implementing agent:

1. Identifies the **narrowest applicable sensor** from context (commands per HARNESS.md):
   - Changed a source file → its co-located / sibling test, scoped to that file's test.
   - Changed a typed source with no obvious test → the package typecheck sensor.
   - Changed a doc/markdown file → the docs/lint sensor.
   - Changed an i18n/locale file → the i18n/typecheck sensor.
   - No clear match → the project's "affected" / fallback sensor (typecheck + test).
2. Reports green or red before flipping `- [ ]` → `- [x]`:
   - Green → flip checkbox, continue.
   - Red → **yolo**: fix the failure the task caused, re-run, loop until green; escalate to a stop only
     on a genuine fork (standard/contract/design) or no green after a focused attempt. **gated**: stop,
     surface the error + which task, await direction.

**This is soft enforcement** — the agent uses judgment to pick the command. It may occasionally pick
too narrow (misses a side effect) or too broad (runs more than needed). The hard layer compensates.

## Layer 2 — Hard per-group pre-commit gate

Auto-commit per group triggers the project's pre-commit gate (HARNESS.md › Gates) on every group
boundary. **Hard enforcement** — the commit passes or fails, no judgment. If it fails after all tasks
in the group passed their soft checks:
- A task's soft check was too narrow (missed a cross-file type error).
- An earlier task introduced a regression caught by a later task's test.

Either case: **yolo** — diagnose + fix the cause, then a **new commit** (never amend), loop until the
gate passes; escalate to a stop only on a genuine fork or unrecoverable failure. **gated** — stop,
surface the gate output, identify which file/package failed, await direction. Never amend — a fix is
always a new commit.

## Why two layers

| Concern | Soft (per-task) | Hard (per-group gate) |
|---------|-----------------|------------------------|
| Catches breakage early (per task) | ✅ | ❌ |
| Deterministic enforcement | ❌ trust-based | ✅ gate passes or fails |
| Catches cross-task regressions | ❌ narrow scope | ✅ full affected graph |
| Token/time cost | small, per task | none extra (gate fires anyway) |
| Works without project knowledge | ✅ agent infers from sensors | ✅ gate is the project's own |

Together: the per-task layer catches most breakage where it happens; the per-group layer is the safety
net for what slips through. (Step F then adds the full sensor pass + behavioral-verify + spec-conformance
on top of these per-group checks.)
