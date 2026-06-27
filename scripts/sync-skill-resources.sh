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
  "templates/context-docs/QUALITY_SCORE.md::skills/harness-init/templates/context-docs/QUALITY_SCORE.md"
  "templates/context-docs/ARCHITECTURE.md::skills/harness-init/templates/context-docs/ARCHITECTURE.md"
  "templates/context-docs/PRODUCT.md::skills/harness-init/templates/context-docs/PRODUCT.md"
  "templates/context-docs/RELIABILITY.md::skills/harness-init/templates/context-docs/RELIABILITY.md"
  "templates/context-docs/SECURITY.md::skills/harness-init/templates/context-docs/SECURITY.md"
  "templates/sensor-baseline.md::skills/harness-init/references/sensor-baseline.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-init/references/harness-runs.SCHEMA.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-build/references/harness-runs.SCHEMA.md"
  "templates/harness-runs.SCHEMA.md::skills/harness-review/references/harness-runs.SCHEMA.md"
  "docs/runtime-verification-binding.md::skills/harness-init/references/runtime-verification-binding.md"
  "docs/runtime-verification-binding.md::skills/harness-build/references/runtime-verification-binding.md"
  "rules/walk-me-through.md::skills/harness-refine/references/walk-me-through.md"
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
  [ "$drift" -eq 0 ] && echo "✅ skill resource bundles in sync" || {
    echo "Run: scripts/sync-skill-resources.sh" >&2; exit 1; }
else
  echo "✅ synced ${#MAP[@]} skill resources"
fi
