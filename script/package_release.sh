#!/bin/bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD="${MT_TRAINER_BUILD_DIR:-$HOME/Documents/Codex/Builds/LiesOfPTrainer}"
python3 - "$ROOT" "$BUILD" <<'CHECK'
from pathlib import Path
import sys
source,build=map(lambda s:Path(s).expanduser().resolve(),sys.argv[1:])
if source==build or source in build.parents:
    raise SystemExit('Release build folder must be outside source.')
CHECK
APP="$BUILD/Lies of P Trainer.app"
OUT="$BUILD/release"
[[ "$(plutil -extract CFBundleIdentifier raw "$APP/Contents/Info.plist")" == local.mactrainer.liesofp ]]
[[ "$(plutil -extract CFBundleIconFile raw "$APP/Contents/Info.plist")" == AppIcon.icns ]]
[[ -s "$APP/Contents/Resources/AppIcon.icns" ]]
codesign --verify --deep --strict "$APP"
xcrun lipo "$APP/Contents/MacOS/MacTrainer" -verify_arch arm64
xcrun lipo "$APP/Contents/Resources/TrainerOverlay.dylib" -verify_arch arm64
mkdir -p "$OUT"
CHECK="$(mktemp -d "$BUILD/.package-check.XXXXXX")"
trap 'rm -rf "$CHECK"' EXIT
NAME="Lies-of-P-Trainer-macOS-arm64.zip"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$OUT/$NAME"
ditto -x -k "$OUT/$NAME" "$CHECK"
codesign --verify --deep --strict "$CHECK/Lies of P Trainer.app"
[[ -s "$CHECK/Lies of P Trainer.app/Contents/Resources/AppIcon.icns" ]]
(cd "$OUT" && shasum -a 256 "$NAME" > SHA256SUMS.txt)
printf 'Release package verified: %s\n' "$OUT/$NAME"
