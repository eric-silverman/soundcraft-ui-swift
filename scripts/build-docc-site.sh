#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_NAME="SoundcraftUI"
CATALOG_PATH="$ROOT_DIR/Sources/SoundcraftUI/SoundcraftUI.docc"
BUILD_ROOT="${BUILD_ROOT:-$ROOT_DIR/.build/docc-site}"
SWIFT_BUILD_DIR="$BUILD_ROOT/swiftpm"
SYMBOL_GRAPH_DIR="$BUILD_ROOT/symbol-graphs"
SITE_DIR="$BUILD_ROOT/site"
HOSTING_BASE_PATH="${HOSTING_BASE_PATH:-/soundcraft-ui-swift}"
SOURCE_SERVICE_BASE_URL="${SOURCE_SERVICE_BASE_URL:-https://github.com/eric-silverman/soundcraft-ui-swift/blob/main}"
CLANG_MODULE_CACHE_PATH="${CLANG_MODULE_CACHE_PATH:-/tmp/clang-module-cache}"
SWIFTPM_MODULECACHE_OVERRIDE="${SWIFTPM_MODULECACHE_OVERRIDE:-/tmp/clang-module-cache}"

rm -rf "$BUILD_ROOT"
mkdir -p "$SWIFT_BUILD_DIR" "$SYMBOL_GRAPH_DIR" "$SITE_DIR" "$CLANG_MODULE_CACHE_PATH"

CLANG_MODULE_CACHE_PATH="$CLANG_MODULE_CACHE_PATH" \
SWIFTPM_MODULECACHE_OVERRIDE="$SWIFTPM_MODULECACHE_OVERRIDE" \
swift build \
  --scratch-path "$SWIFT_BUILD_DIR" \
  --target "$TARGET_NAME" \
  -Xswiftc -emit-symbol-graph \
  -Xswiftc -emit-symbol-graph-dir \
  -Xswiftc "$SYMBOL_GRAPH_DIR" \
  -Xswiftc -symbol-graph-minimum-access-level \
  -Xswiftc public

xcrun docc convert "$CATALOG_PATH" \
  --additional-symbol-graph-dir "$SYMBOL_GRAPH_DIR" \
  --output-path "$SITE_DIR" \
  --transform-for-static-hosting \
  --hosting-base-path "$HOSTING_BASE_PATH" \
  --fallback-display-name "$TARGET_NAME" \
  --fallback-bundle-identifier "com.ericsilverman.soundcraftui" \
  --checkout-path "$ROOT_DIR" \
  --source-service github \
  --source-service-base-url "$SOURCE_SERVICE_BASE_URL"

cat > "$SITE_DIR/index.html" <<EOF
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0; url=/${HOSTING_BASE_PATH#/}/documentation/soundcraftui/">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>SoundcraftUI Documentation</title>
  <script>
    window.location.replace("/${HOSTING_BASE_PATH#/}/documentation/soundcraftui/");
  </script>
</head>
<body>
  <p><a href="/${HOSTING_BASE_PATH#/}/documentation/soundcraftui/">Open SoundcraftUI documentation</a></p>
</body>
</html>
EOF

touch "$SITE_DIR/.nojekyll"
echo "DocC site built at: $SITE_DIR"
