#!/bin/bash
# 启动 Conky 主题（configs/conky_theme 下）

set -euo pipefail

THEME="${1:-}"
BASE="${HOME}/.fluxbox/configs/conky_theme"

if [ -z "$THEME" ]; then
    themes=()
    for d in "$BASE"/*; do
        [ -d "$d" ] && themes+=("$(basename "$d")")
    done
    command -v zenity >/dev/null 2>&1 && \
        THEME=$(zenity --list --title="Conky 主题" --column="Theme" "${themes[@]}") || exit 0
fi

DIR="${BASE}/${THEME}"
if [ ! -d "$DIR" ]; then
    echo "找不到主题: $DIR" >&2
    exit 1
fi

pkill conky 2>/dev/null || true
sleep 0.5

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LANGUAGE=en_US

if [ -x "${DIR}/start.sh" ]; then
    bash "${DIR}/start.sh"
    exit 0
fi

# 无 start.sh 时尝试目录内第一个 .conf
conf=$(find "$DIR" -maxdepth 1 -name '*.conf' | head -1)
if [ -n "$conf" ]; then
    conky -c "$conf" &>/dev/null &
    exit 0
fi

echo "主题 ${THEME} 下没有 start.sh 或 .conf" >&2
exit 1
