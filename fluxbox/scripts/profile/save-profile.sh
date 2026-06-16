#!/bin/bash
# 将当前 init 关键项保存为 profile

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

NAME="${1:-}"
PROFILES_DIR="${HOME}/.fluxbox/profiles"

if [ -z "$NAME" ]; then
    command -v zenity >/dev/null 2>&1 && \
        NAME=$(zenity --entry --title="保存场景" --text="Profile 名称（英文）:") || exit 0
fi

[ -z "$NAME" ] && exit 0
FILE="${PROFILES_DIR}/${NAME}.profile"

{
    echo "# 保存于 $(date '+%Y-%m-%d %H:%M:%S')"
    echo "session.screen0.workspaces=$(fluxbox_get_init session.screen0.workspaces)"
    echo "session.screen0.windowPlacement=$(fluxbox_get_init session.screen0.windowPlacement)"
    echo "session.styleFile=$(fluxbox_get_init session.styleFile)"
    if pgrep -x conky >/dev/null 2>&1; then
        echo "CONKY=conky&"
    else
        echo "CONKY=off"
    fi
} > "$FILE"

echo "已保存: $FILE"
