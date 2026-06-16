#!/bin/bash
# 应用显示器 profile（读取 config/display.profiles）

set -euo pipefail

PROFILE="${1:-}"
CONF="${HOME}/.fluxbox/config/display.profiles"

if [ -z "$PROFILE" ]; then
    names=()
    while IFS='|' read -r name desc _; do
        [[ "$name" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${name// }" ]] && continue
        names+=("$name")
    done < "$CONF"
    command -v zenity >/dev/null 2>&1 && \
        PROFILE=$(zenity --list --title="显示器布局" --column="Profile" "${names[@]}") || exit 0
fi

cmd=""
while IFS='|' read -r name desc xcmd; do
    [[ "$name" =~ ^[[:space:]]*# ]] && continue
    [ "$name" = "$PROFILE" ] && cmd="$xcmd" && break
done < "$CONF"

if [ -z "$cmd" ]; then
    echo "未找到 profile: $PROFILE" >&2
    exit 1
fi

eval "$cmd"
