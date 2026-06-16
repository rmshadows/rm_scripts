#!/bin/bash
# 自动检测输出并切换显示器布局
# 用法: xrandr-layout.sh extend|extend-left|mirror|internal|external|status

set -euo pipefail

MODE="${1:-status}"
CONF="${HOME}/.fluxbox/config/display.conf"

# 可选：在 display.conf 中手动指定输出名（取消注释并修改）
# INTERNAL=eDP-1
# EXTERNAL=DP-1
if [ -f "$CONF" ]; then
    # shellcheck source=/dev/null
    source "$CONF"
fi

list_connected() {
    xrandr --query | awk '/ connected/{print $1}'
}

list_disconnected_ext() {
    xrandr --query | awk '/ disconnected/{print $1}' | grep -E '^(HDMI|DP|DVI|VGA|DisplayPort)' || true
}

guess_internal() {
    if [ -n "${INTERNAL:-}" ]; then
        echo "$INTERNAL"
        return
    fi
    xrandr --query | awk '/ connected/{print $1}' | grep -E '^(eDP|LVDS|DSI)' | head -1
}

guess_external() {
    if [ -n "${EXTERNAL:-}" ]; then
        echo "$EXTERNAL"
        return
    fi
    xrandr --query | awk '/ connected/{print $1}' | grep -E '^(HDMI|DP|DVI|VGA|DisplayPort)' | head -1
}

notify() {
    echo "$1"
}

fail() {
    echo "$1" >&2
    exit 1
}

internal="$(guess_internal)"
external="$(guess_external)"

case "$MODE" in
    status)
        msg="内屏: ${internal:-无}\n外屏: ${external:-无（未连接）}"
        connected=($(list_connected))
        msg="${msg}\n已连接: ${connected[*]:-无}"
        notify "$msg"
        exit 0
        ;;
    internal|laptop)
        if [ -z "$internal" ]; then
            fail "未检测到内置屏（eDP/LVDS/DSI）"
        fi
        xrandr --output "$internal" --primary --auto
        for out in $(list_connected); do
            [ "$out" != "$internal" ] && xrandr --output "$out" --off
        done
        notify "仅内置屏: ${internal}"
        ;;
    external|hdmi)
        if [ -z "$external" ]; then
            fail "未检测到外接显示器\n请确认 DP/HDMI 已连接\n可用: $(list_disconnected_ext | tr '\n' ' ')"
        fi
        xrandr --output "$external" --primary --auto
        [ -n "$internal" ] && xrandr --output "$internal" --off
        notify "仅外接屏: ${external}"
        ;;
    extend|extend-right|dual)
        if [ -z "$internal" ] || [ -z "$external" ]; then
            fail "扩展需要内外屏同时连接\n内屏: ${internal:-无}\n外屏: ${external:-无}"
        fi
        xrandr --output "$internal" --primary --auto \
               --output "$external" --auto --right-of "$internal"
        notify "双屏扩展: ${internal}（主） + ${external}（右侧）"
        ;;
    extend-left)
        if [ -z "$internal" ] || [ -z "$external" ]; then
            fail "扩展需要内外屏同时连接\n内屏: ${internal:-无}\n外屏: ${external:-无}"
        fi
        xrandr --output "$external" --primary --auto \
               --output "$internal" --auto --right-of "$external"
        notify "双屏扩展: ${external}（主，左） + ${internal}（右侧）"
        ;;
    mirror)
        if [ -z "$internal" ] || [ -z "$external" ]; then
            fail "镜像需要内外屏同时连接\n内屏: ${internal:-无}\n外屏: ${external:-无}"
        fi
        xrandr --output "$internal" --primary --auto \
               --output "$external" --same-as "$internal" --auto
        notify "镜像: ${internal} ↔ ${external}"
        ;;
    *)
        echo "用法: $0 extend|extend-left|mirror|internal|external|status" >&2
        exit 1
        ;;
esac
