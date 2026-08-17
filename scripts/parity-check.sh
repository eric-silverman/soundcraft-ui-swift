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
#   1 — error (couldn't read PARITY.md, or couldn't resolve upstream HEAD)
#   2 — drift detected
#
# If upstream HEAD resolves but the compare call fails, that is still exit 2:
# the drift is real and worth reporting even when the file list is missing.
#
# When run under GitHub Actions ($GITHUB_OUTPUT is set), the script also
# writes machine-readable outputs: base, head, drift, changed, specs.
#
# Set PARITY_API to point at a different API host (used to test failure paths).
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

API="${PARITY_API:-https://api.github.com}"

# GitHub's API returns transient 5xx/404s during incidents, so retry before
# giving up. Prints the response body on success.
fetch_json() {
  local url="$1" attempt
  for attempt in 1 2 3; do
    if curl -fsSL "$url"; then
      return 0
    fi
    if [ "$attempt" -lt 3 ]; then
      sleep $((attempt * 3))
    fi
  done
  return 1
}

if ! HEAD=$(fetch_json "$API/repos/fmalcher/soundcraft-ui/commits/main" | jq -r '.sha') \
  || [ -z "$HEAD" ] || [ "$HEAD" = "null" ]; then
  echo "Could not fetch upstream HEAD from the GitHub API." >&2
  exit 1
fi

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

# A failed compare must not look like "no files changed" — an empty list is
# meaningful (drift that needs no porting), so name the unknown explicitly.
UNAVAILABLE="(unavailable — GitHub compare API unreachable)"

if COMPARE=$(fetch_json "$API/repos/fmalcher/soundcraft-ui/compare/${BASE}...${HEAD}"); then
  CHANGED=$(echo "$COMPARE" | jq -r '.files[]?.filename' \
    | grep -E '^packages/mixer-connection/src/lib/' \
    | grep -vE '\.spec\.ts$' \
    || true)

  SPECS=$(echo "$COMPARE" | jq -r '.files[]?.filename' \
    | grep -E '^packages/mixer-connection/src/lib/.*\.spec\.ts$' \
    || true)
else
  echo "⚠ Could not reach the compare API — reporting drift without the file list." >&2
  CHANGED="$UNAVAILABLE"
  SPECS="$UNAVAILABLE"
fi

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
