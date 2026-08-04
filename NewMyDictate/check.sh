#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

plutil -lint "$PROJECT_DIR/Info.plist" "$PROJECT_DIR/entitlements.plist"

BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$PROJECT_DIR/Info.plist")"
if [[ "$BUNDLE_ID" != "com.local.newmydictate.dev" ]]; then
    printf 'Unexpected development bundle identifier: %s\n' "$BUNDLE_ID" >&2
    exit 1
fi

swift test --package-path "$PROJECT_DIR"
"$PROJECT_DIR/build-app.sh"

codesign --verify --deep --strict "$PROJECT_DIR/dist/New MyDictate.app"
printf 'New MyDictate: all checks passed\n'
