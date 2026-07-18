#!/bin/bash

set -euo pipefail

REPOSITORY="shlgd/SuperDictate"
REF="${SUPERDICTATE_REF:-main}"
APP_PATH="/Applications/SuperDictate.app"
AGENT_LABEL="com.local.superdictate.agent"

say() {
    printf '\033[1;36mSuperDictate:\033[0m %s\n' "$*"
}

fail() {
    printf '\033[1;31mSuperDictate:\033[0m %s\n' "$*" >&2
    exit 1
}

version_at_least_14() {
    local major
    major="$(sw_vers -productVersion | cut -d. -f1)"
    [[ "$major" =~ ^[0-9]+$ ]] && (( major >= 14 ))
}

run_as_admin() {
    if [[ -w /Applications ]]; then
        "$@"
    else
        sudo "$@"
    fi
}

[[ "$(uname -s)" == "Darwin" ]] || fail "Работает только на macOS."
[[ "$(uname -m)" == "arm64" ]] || fail "Нужен Mac с Apple Silicon (M1 или новее)."
version_at_least_14 || fail "Нужна macOS 14 или новее."

if ! command -v swift >/dev/null 2>&1; then
    say "Сначала нужны бесплатные инструменты Apple. Открываю их установку..."
    xcode-select --install >/dev/null 2>&1 || true
    printf '\nПосле установки снова запустите эту же команду.\n'
    exit 0
fi

command -v curl >/dev/null 2>&1 || fail "Не найден curl."
command -v ditto >/dev/null 2>&1 || fail "Не найден ditto."

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/superdictate-install.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

say "Скачиваю открытый исходный код..."
ARCHIVE_URL="https://github.com/$REPOSITORY/archive/$REF.zip"
curl --fail --location --silent --show-error "$ARCHIVE_URL" -o "$WORK_DIR/source.zip"
ditto -x -k "$WORK_DIR/source.zip" "$WORK_DIR/source"
SOURCE_DIR="$(find "$WORK_DIR/source" -mindepth 1 -maxdepth 1 -type d -print -quit)"
[[ -n "$SOURCE_DIR" ]] || fail "Не удалось распаковать исходный код."

"$SOURCE_DIR/scripts/build-app.sh" "$WORK_DIR/SuperDictate.app"

say "Устанавливаю приложение в /Applications..."
/bin/launchctl bootout "gui/$UID/$AGENT_LABEL" >/dev/null 2>&1 || true
/usr/bin/pkill -x SuperDictate >/dev/null 2>&1 || true

INCOMING="/Applications/.SuperDictate.install.$$"
run_as_admin rm -rf "$INCOMING"
run_as_admin ditto "$WORK_DIR/SuperDictate.app" "$INCOMING"
run_as_admin rm -rf "$APP_PATH"
run_as_admin mv "$INCOMING" "$APP_PATH"

codesign --verify --deep --strict "$APP_PATH" || fail "Проверка установленного приложения не прошла."
say "Готово. Открываю SuperDictate..."
open "$APP_PATH"

printf '\nВыдайте приложению три разрешения в открывшейся панели.\n'
printf 'Первый запуск также скачает локальную модель распознавания.\n\n'
