#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WHISPER_VERSION="1.9.1"
WHISPER_SHA256="8c3ecbe73f48b0cb9318fc3058264f951ab336fd530e82c4ccdd2298d1311a4c"
VENDOR_DIR="$ROOT_DIR/vendor/whisper"
ARCHIVE="$VENDOR_DIR/whisper-v${WHISPER_VERSION}-xcframework.zip"
FRAMEWORK="$VENDOR_DIR/build-apple/whisper.xcframework"
DOWNLOAD_URL="https://github.com/ggml-org/whisper.cpp/releases/download/v${WHISPER_VERSION}/whisper-v${WHISPER_VERSION}-xcframework.zip"

say() {
    printf 'SuperDictate: %s\n' "$*"
}

verify_archive() {
    [[ -f "$ARCHIVE" ]] || return 1
    [[ "$(shasum -a 256 "$ARCHIVE" | awk '{print $1}')" == "$WHISPER_SHA256" ]]
}

if [[ -d "$FRAMEWORK" ]]; then
    exit 0
fi

mkdir -p "$VENDOR_DIR"
if ! verify_archive; then
    rm -f "$ARCHIVE"
    say "Downloading whisper.cpp v${WHISPER_VERSION} framework..."
    curl --fail --location --retry 3 --output "$ARCHIVE" "$DOWNLOAD_URL"
fi

verify_archive || {
    printf 'SuperDictate: whisper.cpp framework checksum mismatch.\n' >&2
    exit 1
}

say "Extracting whisper.cpp framework..."
ditto -x -k "$ARCHIVE" "$VENDOR_DIR"
[[ -d "$FRAMEWORK" ]] || {
    printf 'SuperDictate: whisper.cpp framework was not found after extraction.\n' >&2
    exit 1
}
