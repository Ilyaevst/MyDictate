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

flatten_whisper_framework_for_legacy_updaters() {
    # MyDictate 1.0.3 rejected every symlink while inspecting an update
    # archive.  Apple's normal macOS framework layout uses several internal
    # symlinks (Versions/Current), so turn this one bundled framework into a
    # valid flat framework before archiving.  That lets existing installs
    # reach the fixed updater without any manual app replacement.
    local framework_path="$APP_PATH/Contents/Frameworks/whisper.framework"
    local source_root
    local source_framework

    [[ -L "$framework_path/Versions/Current" ]] || return 0
    [[ -d "$framework_path/Versions/A" ]] || {
        printf 'MyDictate: Whisper framework has an unexpected layout.\n' >&2
        exit 1
    }

    source_root="$(mktemp -d "${TMPDIR:-/tmp}/mydictate-flat-framework.XXXXXX")"
    source_framework="$source_root/whisper.framework"
    mv "$framework_path" "$source_framework"
    mkdir -p "$framework_path"
    ditto "$source_framework/Versions/A/Resources" "$framework_path/Resources"
    ditto "$source_framework/Versions/A/Headers" "$framework_path/Headers"
    ditto "$source_framework/Versions/A/Modules" "$framework_path/Modules"
    ditto "$source_framework/Versions/A/whisper" "$framework_path/whisper"

    # The executable is linked to the versioned framework path.  In the flat
    # release bundle it must load the copied library at the new path instead.
    install_name_tool \
        -change @rpath/whisper.framework/Versions/Current/whisper \
        @rpath/whisper.framework/whisper \
        "$APP_PATH/Contents/MacOS/MyDictate"
    rm -rf "$source_root"

    codesign --force --deep --sign - "$APP_PATH"
    codesign --verify --deep --strict "$APP_PATH"
}

"$ROOT_DIR/scripts/build-app.sh" "$APP_PATH"
flatten_whisper_framework_for_legacy_updaters
rm -f "$ARCHIVE_PATH"
ditto -c -k --sequesterRsrc --keepParent "$APP_PATH" "$ARCHIVE_PATH"

CHECKSUM="$(shasum -a 256 "$ARCHIVE_PATH" | awk '{print $1}')"
printf '{\n  "version": "%s",\n  "sha256": "%s"\n}\n' "$VERSION" "$CHECKSUM" >"$MANIFEST_TMP"
mv -f "$MANIFEST_TMP" "$MANIFEST_PATH"

printf 'Prepared:\n  %s\n  %s\n\n' "$ARCHIVE_PATH" "$MANIFEST_PATH"
printf 'After committing and pushing update.json, publish the archive with:\n'
printf '  gh release create v%s "%s" --title "MyDictate v%s" --generate-notes\n' \
    "$VERSION" "$ARCHIVE_PATH" "$VERSION"
