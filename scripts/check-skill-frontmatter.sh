#!/usr/bin/env bash
# Validate that every skill carries the required frontmatter: name, description,
# an author, and a version. Keeps the skill catalog uniform (and authored) for
# sharing / vercel-labs/skills consumption; the version is release-managed
# (release-please stamps it, so a new skill must ship the field). Exit 1 on any
# violation.
set -euo pipefail

cd "$(dirname "$0")/.."

fail=0
shopt -s nullglob
skills=(skills/*/SKILL.md)

if [ ${#skills[@]} -eq 0 ]; then
  echo "no skills found under skills/*/SKILL.md" >&2
  exit 1
fi

for f in "${skills[@]}"; do
  # Frontmatter = lines between the first two '---' markers.
  fm="$(awk 'NR==1 && $0=="---"{f=1;next} f && $0=="---"{exit} f{print}' "$f")"

  miss=()
  grep -qE '^name:[[:space:]]*\S'        <<<"$fm" || miss+=("name")
  grep -qE '^description:[[:space:]]*\S|^description:[[:space:]]*[>|]' <<<"$fm" || miss+=("description")
  grep -qE '^[[:space:]]*author:[[:space:]]*\S' <<<"$fm" || miss+=("author")
  grep -qE '^[[:space:]]*version:[[:space:]]*\S' <<<"$fm" || miss+=("version")

  if [ ${#miss[@]} -gt 0 ]; then
    echo "✗ $f — missing frontmatter: ${miss[*]}" >&2
    fail=1
  fi
done

if [ "$fail" -eq 0 ]; then
  echo "✓ all ${#skills[@]} skills have name + description + author + version"
fi
exit "$fail"
