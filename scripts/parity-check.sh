#!/usr/bin/env bash
# Local + CI parity check against fmalcher/soundcraft-ui.
#
# Reads the baseline SHA from PARITY.md, fetches upstream HEAD,
# and reports source/spec files that have changed since.
#
# Usage: scripts/parity-check.sh
#
# Exit codes:
#   0 — no drift
#   1 — error (couldn't read PARITY.md or reach GitHub)
#   2 — drift detected
#
# When run under GitHub Actions ($GITHUB_OUTPUT is set), the script also
# writes machine-readable outputs: base, head, drift, changed, specs.
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

emit_output() {
  if [ -n "${GITHUB_OUTPUT:-}" ]; then
    {
      echo "base=$BASE"
      echo "head=$HEAD"
      echo "drift=$1"
      echo "changed<<PARITY_EOF"
      echo "${2:-}"
      echo "PARITY_EOF"
      echo "specs<<PARITY_EOF"
      echo "${3:-}"
      echo "PARITY_EOF"
    } >> "$GITHUB_OUTPUT"
  fi
}

echo "Baseline:      ${BASE:0:7}  ($BASE)"
echo "Upstream HEAD: ${HEAD:0:7}  ($HEAD)"
echo

if [ "$BASE" = "$HEAD" ]; then
  echo "✓ No drift — baseline matches upstream HEAD."
  emit_output false "" ""
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

emit_output true "$CHANGED" "$SPECS"
exit 2
