#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
DERIVED_DATA_DIR="/tmp/resty-xcode-derived"
BUILD_APP_DIR="$DERIVED_DATA_DIR/Build/Products/Debug/Resty.app"
OUTPUT_APP_DIR="$ROOT_DIR/.build/Resty.app"

cd "$ROOT_DIR"
xcodebuild \
  -project Resty.xcodeproj \
  -scheme Resty \
  -configuration Debug \
  -destination 'generic/platform=macOS' \
  -derivedDataPath "$DERIVED_DATA_DIR" \
  build

rm -rf "$OUTPUT_APP_DIR"
mkdir -p "$ROOT_DIR/.build"
cp -R "$BUILD_APP_DIR" "$OUTPUT_APP_DIR"

echo "Built $OUTPUT_APP_DIR"
