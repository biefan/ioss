#!/bin/bash
set -euo pipefail

PREFS="/var/mobile/Library/Preferences/com.biefan.storagesweep.plist"
DEFAULT_DAYS=7

enabled="$(defaults read "$PREFS" enabled 2>/dev/null || echo 1)"
if [[ "$enabled" == "0" ]]; then
    exit 0
fi

days="$(defaults read "$PREFS" olderThanDays 2>/dev/null || echo "$DEFAULT_DAYS")"

for caches_dir in /var/mobile/Containers/Data/Application/*/Library/Caches; do
    [[ -d "$caches_dir" ]] || continue
    find "$caches_dir" -mindepth 1 -mtime "+${days}" -exec rm -rf {} + 2>/dev/null || true
done

exit 0
