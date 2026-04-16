# Resty

Local macOS break reminder app.

## Run

```bash
xcodebuild -project Resty.xcodeproj -scheme Resty -configuration Debug -destination 'generic/platform=macOS' -derivedDataPath /tmp/resty-xcode-derived build
open /tmp/resty-xcode-derived/Build/Products/Debug/Resty.app
```

## Build `.app`

```bash
./scripts/build_app.sh
open .build/Resty.app
```

To replace a running copy with a fresh build:

```bash
./scripts/relaunch_app.sh
```

## macOS Tahoe Controls

The app includes a macOS 26 Tahoe WidgetKit control extension with:
- `Resty Reminders`: pause/resume reminders
- `Start Resty Break`: start a break immediately
- `Skip Resty Round`: skip the next round

The local `./scripts/build_app.sh` flow embeds the extension at:

```text
.build/Resty.app/Contents/PlugIns/RestyControlsExtension.appex
```

The repo now includes a real Xcode project at `Resty.xcodeproj` with:
- `Resty` macOS app target
- `RestyControlsExtension` WidgetKit extension target
- `RestyShared` shared static library target

The current local build uses a shared `UserDefaults` suite for app/extension commands. For production distribution, this should move to proper App Group entitlements and signed release identities.

## Permissions

For better meeting/video detection, allow the app's macOS prompts for:
- Automation access to Safari/Chrome/Arc/Edge
- Camera access
- Microphone access
