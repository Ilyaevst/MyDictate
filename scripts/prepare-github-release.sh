#!/bin/bash

# Creates the exact two files needed for a GitHub release consumed by the
# in-app updater: MyDictate-X.Y.Z.zip and update.json. It does not publish or
# create a repository; that remains an explicit developer action.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-$(plutil -extract CFBundleShortVersionString raw -o - "$ROOT_DIR/swift/Info.plist")}"

if [[ ! "$VERSION" =~ ^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$ ]]; then
    printf 'MyDictate: version must be X.Y.Z (got %s)\n' "$VERSION" >&2
    exit 1
fi

APP_PATH="$ROOT_DIR/dist/MyDictate.app"
ARCHIVE_PATH="$ROOT_DIR/dist/MyDictate-$VERSION.zip"
MANIFEST_PATH="$ROOT_DIR/update.json"
MANIFEST_TMP="$ROOT_DIR/.update.json.$$"

"$ROOT_DIR/scripts/build-app.sh" "$APP_PATH"
rm -f "$ARCHIVE_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"

CHECKSUM="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
printf '{\n  "version": "%s",\n  "sha256": "%s"\n}\n' "$VERSION" "$CHECKSUM" >"$MANIFEST_TMP"
mv -f "$MANIFEST_TMP" "$MANIFEST_PATH"

printf 'Prepared:\n  %s\n  %s\n\n' "$ARCHIVE_PATH" "$MANIFEST_PATH"
printf 'After committing and pushing update.json, publish the archive with:\n'
printf '  gh release create v%s "%s" --title "MyDictate v%s" --generate-notes\n' \
    "$VERSION" "$ARCHIVE_PATH" "$VERSION"
