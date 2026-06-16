#!/bin/bash
# Conky 字号调整：+2 / -2 / 指定数字
# 用法: conky-resize.sh +2|-2|14

set -euo pipefail

CONF_DIR="${HOME}/.fluxbox/config"
SIZE_FILE="${CONF_DIR}/conky.size"
MIN=10
MAX=32
STEP=2
DEFAULT=14

mkdir -p "$CONF_DIR"

current="$DEFAULT"
if [ -f "$SIZE_FILE" ]; then
    current="$(tr -d '[:space:]' < "$SIZE_FILE")"
fi

arg="${1:-}"
case "$arg" in
    +2|+)
        new=$((current + STEP))
        ;;
    -2|-)
        new=$((current - STEP))
        ;;
    *)
        new="$arg"
        ;;
esac

if ! [[ "$new" =~ ^[0-9]+$ ]]; then
    echo "用法: $0 +2|-2|字号(10-32)" >&2
    exit 1
fi

if [ "$new" -lt "$MIN" ]; then new=$MIN
elif [ "$new" -gt "$MAX" ]; then new=$MAX
fi

echo "$new" > "$SIZE_FILE"

rc="${HOME}/.fluxbox/configs/conky/conkyrc-${new}"
if [ ! -f "$rc" ]; then
    echo "找不到配置: $rc" >&2
    exit 1
fi

cp "$rc" "${HOME}/.conkyrc"

pkill conky 2>/dev/null || true
sleep 0.3
conky &>/dev/null &
