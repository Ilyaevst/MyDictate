#!/bin/bash

set -euo pipefail

APP_PATH="${MYDICTATE_APP_PATH:-/Applications/MyDictate.app}"
AGENT_LABEL="com.local.mydictate.agent"
AGENT_PLIST="$HOME/Library/LaunchAgents/$AGENT_LABEL.plist"

/bin/launchctl bootout "gui/$UID/$AGENT_LABEL" >/dev/null 2>&1 || true
/usr/bin/pkill -x MyDictate >/dev/null 2>&1 || true
rm -f "$AGENT_PLIST"
rm -rf "$APP_PATH"

printf 'MyDictate удалён. История и локальные модели сохранены.\n'
