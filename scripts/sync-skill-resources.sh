#!/usr/bin/env bash
# Sync canonical templates/docs into the skill bundles that ship them.
#
# WHY: skills travel as standalone dirs (symlinked into consuming projects, or
# copied/plugin-packaged later), so each skill must carry the inputs it reads at
# runtime — it cannot reach repo-root templates/ or docs/. The repo root stays the
# single source of truth; this script copies it into the bundles and (in check
# mode) fails if a bundle has drifted.
#
#   sync   (default) copy canonical -> bundle
#   check            diff only; exit 1 on any drift (use in pre-push / CI)
#
# Manifest format: "<canonical path>::<bundle path>", both repo-relative.

set -euo pipefail
cd "$(dirname "$0")/.."

MAP=(
  "templates/HARNESS.md::skills/harness-init/templates/HARNESS.md"
  "templates/claude-workflow.md::skills/harness-init/templates/claude-workflow.md"
  "templates/context-docs/QUALITY_SCORE.md::skills/harness-init/templates/context-docs/QUALITY_SCORE.md"
  "templates/context-docs/ARCHITECTURE.md::skills/harness-init/templates/context-docs/ARCHITECTURE.md"
  "templates/context-docs/PRODUCT.md::skills/harness-init/templates/context-docs/PRODUCT.md"
  "templates/context-docs/RELIABILITY.md::skills/harness-init/templates/context-docs/RELIABILITY.md"
  "templates/context-docs/SECURITY.md::skills/harness-init/templates/context-docs/SECURITY.md"
  "templates/sensor-baseline.md::skills/harness-init/references/sensor-baseline.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-init/references/harness-runs.SCHEMA.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-build/references/harness-runs.SCHEMA.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-retro/references/harness-runs.SCHEMA.md"
  "docs/runtime-verification-binding.md::skills/harness-init/references/runtime-verification-binding.md"
  "docs/runtime-verification-binding.md::skills/harness-build/references/runtime-verification-binding.md"
  "rules/walk-me-through.md::skills/walk-me-through/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-test-guide/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-refine/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-address-pr-comments/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-architecture/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-build/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-design/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-explore/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-finish/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-recon/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-ship/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-init/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-fine-tune/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-retro/references/walk-me-through.md"
  "rules/walk-me-through.md::skills/harness-review-change/references/walk-me-through.md"
  "rules/pipeline-map.md::skills/harness-refine/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-build/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-fine-tune/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-ship/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-address-pr-comments/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-finish/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-status/references/pipeline-map.md"
  "rules/pipeline-map.md::skills/harness-review-change/references/pipeline-map.md"
  "rules/decision-log.md::skills/harness-recon/references/decision-log.md"
  "rules/decision-log.md::skills/harness-architecture/references/decision-log.md"
  "rules/decision-log.md::skills/harness-design/references/decision-log.md"
  "rules/decision-log.md::skills/harness-build/references/decision-log.md"
  "rules/decision-log.md::skills/harness-address-pr-comments/references/decision-log.md"
  "rules/pr-summary.md::skills/harness-build/references/pr-summary.md"
  "rules/pr-summary.md::skills/harness-ship/references/pr-summary.md"
  "rules/pr-summary.md::skills/harness-address-pr-comments/references/pr-summary.md"
  "rules/triage-lenses.md::skills/harness-refine/references/triage-lenses.md"
  "rules/triage-lenses.md::skills/harness-build/references/triage-lenses.md"
  "rules/spec-less-review.md::skills/harness-build/references/spec-less-review.md"
)

mode="${1:-sync}"
drift=0

for pair in "${MAP[@]}"; do
  src="${pair%%::*}"
  dst="${pair##*::}"
  [ -f "$src" ] || { echo "⛔ canonical missing: $src" >&2; exit 2; }
  case "$mode" in
    sync)
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      ;;
    check)
      if [ ! -f "$dst" ] || ! cmp -s "$src" "$dst"; then
        echo "⛔ drift: $dst out of sync with $src" >&2
        drift=1
      fi
      ;;
    *)
      echo "usage: $0 [sync|check]" >&2; exit 2;;
  esac
done

if [ "$mode" = check ]; then
  if [ "$drift" -eq 0 ]; then
    echo "✅ skill resource bundles in sync"
  else
    echo "Run: scripts/sync-skill-resources.sh" >&2
    exit 1
  fi
else
  echo "✅ synced ${#MAP[@]} skill resources"
fi
