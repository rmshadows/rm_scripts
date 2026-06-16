#!/bin/bash
# 播放控制媒体键（需 playerctl）

set -euo pipefail

ACTION="${1:-}"

if ! command -v playerctl >/dev/null 2>&1; then
    exit 0
fi

case "$ACTION" in
    play-pause) playerctl play-pause ;;
    next)       playerctl next ;;
    prev)       playerctl previous ;;
    stop)       playerctl stop ;;
    *)
        echo "用法: $0 play-pause|next|prev|stop" >&2
        exit 1
        ;;
esac
