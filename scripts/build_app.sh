#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SCRATCH_DIR="$ROOT_DIR/.build/spm"
BUILD_DIR="$SCRATCH_DIR/debug"
APP_DIR="$ROOT_DIR/.build/Resty.app"

cd "$ROOT_DIR"
swift build --scratch-path "$SCRATCH_DIR"

mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cat > "$APP_DIR/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>Resty</string>
    <key>CFBundleIdentifier</key>
    <string>local.resty.app</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Resty</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSCameraUsageDescription</key>
    <string>Resty can optionally pause reminders during video calls.</string>
    <key>NSMicrophoneUsageDescription</key>
    <string>Resty can optionally pause reminders during video calls.</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Resty inspects the active browser tab to detect meetings and video playback.</string>
</dict>
</plist>
EOF

cp "$BUILD_DIR/Resty" "$APP_DIR/Contents/MacOS/Resty"

echo "Built $APP_DIR"
