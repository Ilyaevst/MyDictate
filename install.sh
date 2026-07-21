#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${MYDICTATE_APP_PATH:-/Applications/MyDictate.app}"
NO_OPEN="${MYDICTATE_NO_OPEN:-0}"
AGENT_LABEL="com.local.mydictate.agent"

say() { printf '\033[1;36mMyDictate:\033[0m %s\n' "$*"; }
fail() { printf '\033[1;31mMyDictate:\033[0m %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == "Darwin" ]] || fail "Работает только на macOS."
[[ "$(uname -m)" == "arm64" ]] || fail "Нужен Mac с Apple Silicon (M1 или новее)."

WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/mydictate-install.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT
BUILT_APP="$WORK_DIR/MyDictate.app"

say "Собираю локальную версию из этого проекта…"
"$ROOT_DIR/scripts/build-app.sh" "$BUILT_APP"

[[ -x "$BUILT_APP/Contents/MacOS/MyDictate" ]] || fail "Сборка не создала MyDictate."
[[ "$(plutil -extract CFBundleShortVersionString raw -o - "$BUILT_APP/Contents/Info.plist")" == "1.0.3" ]] \
    || fail "Неожиданная версия приложения."
codesign --verify --deep --strict "$BUILT_APP" || fail "Проверка подписи не прошла."

say "Устанавливаю приложение в $APP_PATH…"
/bin/launchctl bootout "gui/$UID/$AGENT_LABEL" >/dev/null 2>&1 || true
/usr/bin/pkill -x MyDictate >/dev/null 2>&1 || true
/usr/bin/pkill -x SuperDictate >/dev/null 2>&1 || true

INCOMING="$(dirname "$APP_PATH")/.MyDictate.install.$$"
BACKUP="$(dirname "$APP_PATH")/.MyDictate.previous.$$"
rm -rf "$INCOMING" "$BACKUP"
ditto "$BUILT_APP" "$INCOMING"
if [[ -e "$APP_PATH" ]]; then mv "$APP_PATH" "$BACKUP"; fi
if ! mv "$INCOMING" "$APP_PATH"; then
    [[ -e "$BACKUP" ]] && mv "$BACKUP" "$APP_PATH"
    fail "Не удалось заменить приложение; предыдущая версия восстановлена."
fi
codesign --verify --deep --strict "$APP_PATH" || fail "Установленная копия повреждена."
rm -rf "$BACKUP"
if [[ "$NO_OPEN" != "1" ]]; then
    open "$APP_PATH"
fi
say "Готово. Установлена MyDictate 1.0.3."
