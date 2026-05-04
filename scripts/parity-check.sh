#!/usr/bin/env bash
# Local parity check against fmalcher/soundcraft-ui.
# Mirrors .github/workflows/parity-watch.yml but prints to stdout instead of opening an issue.
#
# Usage: scripts/parity-check.sh
#
# Requires: curl, jq

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PARITY_FILE="$ROOT/PARITY.md"

if [ ! -f "$PARITY_FILE" ]; then
  echo "PARITY.md not found at $PARITY_FILE" >&2
  exit 1
fi

BASE=$(grep -oE 'fmalcher/soundcraft-ui/commit/[a-f0-9]{40}' "$PARITY_FILE" | head -1 | grep -oE '[a-f0-9]{40}')
if [ -z "$BASE" ]; then
  echo "Could not extract baseline SHA from PARITY.md" >&2
  exit 1
fi

HEAD=$(curl -fsSL https://api.github.com/repos/fmalcher/soundcraft-ui/commits/main | jq -r '.sha')

echo "Baseline:     ${BASE:0:7}  ($BASE)"
echo "Upstream HEAD: ${HEAD:0:7}  ($HEAD)"
echo

if [ "$BASE" = "$HEAD" ]; then
  echo "✓ No drift — baseline matches upstream HEAD."
  exit 0
fi

echo "⚠ Drift detected. Compare:"
echo "  https://github.com/fmalcher/soundcraft-ui/compare/${BASE}...${HEAD}"
echo

COMPARE=$(curl -fsSL "https://api.github.com/repos/fmalcher/soundcraft-ui/compare/${BASE}...${HEAD}")

CHANGED=$(echo "$COMPARE" | jq -r '.files[]?.filename' \
  | grep -E '^packages/mixer-connection/src/lib/' \
  | grep -vE '\.spec\.ts$' \
  || true)

SPECS=$(echo "$COMPARE" | jq -r '.files[]?.filename' \
  | grep -E '^packages/mixer-connection/src/lib/.*\.spec\.ts$' \
  || true)

echo "Source files changed:"
if [ -n "$CHANGED" ]; then
  echo "$CHANGED" | sed 's/^/  /'
else
  echo "  (none)"
fi
echo

echo "Spec files changed:"
if [ -n "$SPECS" ]; then
  echo "$SPECS" | sed 's/^/  /'
else
  echo "  (none)"
fi
echo

echo "To reconcile:"
echo "  1. Review the compare link above"
echo "  2. Port relevant changes into matching Swift files (see PARITY.md)"
echo "  3. Update the baseline SHA in PARITY.md to $HEAD"

exit 2
