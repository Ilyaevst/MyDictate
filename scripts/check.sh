#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

bash -n install.sh uninstall.sh scripts/build-app.sh scripts/check.sh scripts/prepare-whisper.sh scripts/prepare-github-release.sh
plutil -lint swift/Info.plist entitlements.plist

app_version="$(plutil -extract CFBundleShortVersionString raw -o - swift/Info.plist)"
[[ "$app_version" == "1.0.9" ]] || {
    printf 'Unexpected MyDictate version: %s\n' "$app_version" >&2
    exit 1
}

grep -q 'com.apple.security.device.audio-input' entitlements.plist
grep -q 'com.apple.security.device.microphone' entitlements.plist
grep -q 'com.apple.security.cs.disable-library-validation' entitlements.plist

git diff --check
printf 'MyDictate checks passed (v%s).\n' "$app_version"
