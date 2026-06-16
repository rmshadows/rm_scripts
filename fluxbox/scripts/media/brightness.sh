#!/bin/bash
# 亮度媒体键：up | down（优先硬件背光 brightnessctl，否则 xrandr）

set -euo pipefail

ACTION="${1:-}"
STEP="${MEDIA_BRIGHTNESS_STEP:-5%}"
XRANDR="${HOME}/.fluxbox/scripts/brightnessControl/xrandrBrightnessControl.sh"

case "$ACTION" in
    up|down)
        if command -v brightnessctl >/dev/null 2>&1 && \
           brightnessctl -l 2>/dev/null | grep -q "class 'backlight'"; then
            if [ "$ACTION" = "up" ]; then
                brightnessctl set "+${STEP}"
            else
                brightnessctl set "${STEP}-"
            fi
        elif [ -x "$XRANDR" ]; then
            if [ "$ACTION" = "up" ]; then
                "$XRANDR" 1
            else
                "$XRANDR" 0
            fi
        else
            echo "未找到 brightnessctl 或 xrandr 亮度脚本" >&2
            exit 1
        fi
        ;;
    *)
        echo "用法: $0 up|down" >&2
        exit 1
        ;;
esac
