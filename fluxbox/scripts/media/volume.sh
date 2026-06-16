#!/bin/bash
# 音量媒体键：up | down | mute

set -euo pipefail

ACTION="${1:-}"
STEP="${MEDIA_VOLUME_STEP:-5%}"

case "$ACTION" in
    up)
        if command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ "+${STEP}"
        else
            amixer -q set Master "${STEP}+" unmute
        fi
        ;;
    down)
        if command -v pactl >/dev/null 2>&1; then
            pactl set-sink-volume @DEFAULT_SINK@ "-${STEP}"
        else
            amixer -q set Master "${STEP}-" unmute
        fi
        ;;
    mute)
        if command -v pactl >/dev/null 2>&1; then
            pactl set-sink-mute @DEFAULT_SINK@ toggle
        else
            amixer -q set Master toggle
        fi
        ;;
    *)
        echo "用法: $0 up|down|mute" >&2
        exit 1
        ;;
esac
