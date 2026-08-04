#!/bin/bash

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_APP="${1:-$PROJECT_DIR/dist/New MyDictate.app}"
SIGN_IDENTITY="${SIGN_IDENTITY:--}"

swift build -c debug --package-path "$PROJECT_DIR"
BIN_DIR="$(swift build -c debug --package-path "$PROJECT_DIR" --show-bin-path)"
BIN="$BIN_DIR/NewMyDictate"

if [[ ! -x "$BIN" ]]; then
    printf 'New MyDictate: executable was not built: %s\n' "$BIN" >&2
    exit 1
fi

STAGE_DIR="$(mktemp -d "${TMPDIR:-/tmp}/new-mydictate-build.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT
STAGE_APP="$STAGE_DIR/New MyDictate.app"

mkdir -p "$STAGE_APP/Contents/MacOS" "$STAGE_APP/Contents/Resources"
cp "$BIN" "$STAGE_APP/Contents/MacOS/NewMyDictate"
cp "$PROJECT_DIR/Info.plist" "$STAGE_APP/Contents/Info.plist"

if [[ -f "$PROJECT_DIR/Resources/NewMyDictate.icns" ]]; then
    cp "$PROJECT_DIR/Resources/NewMyDictate.icns" "$STAGE_APP/Contents/Resources/NewMyDictate.icns"
fi

chmod 755 "$STAGE_APP/Contents/MacOS/NewMyDictate"

SIGN_ARGS=(--force --deep --sign "$SIGN_IDENTITY" --options runtime --entitlements "$PROJECT_DIR/entitlements.plist")
if [[ "$SIGN_IDENTITY" == "-" ]]; then
    SIGN_ARGS+=(--timestamp=none)
else
    SIGN_ARGS+=(--timestamp)
fi

codesign "${SIGN_ARGS[@]}" "$STAGE_APP"
codesign --verify --deep --strict "$STAGE_APP"

mkdir -p "$(dirname "$OUTPUT_APP")"
if [[ -e "$OUTPUT_APP" ]]; then
    mv "$OUTPUT_APP" "$STAGE_DIR/previous.app"
fi
mv "$STAGE_APP" "$OUTPUT_APP"

printf 'New MyDictate: built %s\n' "$OUTPUT_APP"
