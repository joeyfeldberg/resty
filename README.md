# Resty

Local macOS break reminder app.

## Run

```bash
swift run Resty
```

## Build `.app`

```bash
env CLANG_MODULE_CACHE_PATH=/tmp/resty-clang-cache swift run --scratch-path .build/spm Resty
```

If you prefer the app bundle:

```bash
./scripts/build_app.sh
open .build/Resty.app
```

To replace a running copy with a fresh build:

```bash
./scripts/relaunch_app.sh
```

## Permissions

For better meeting/video detection, allow the app's macOS prompts for:
- Automation access to Safari/Chrome/Arc/Edge
- Camera access
- Microphone access
