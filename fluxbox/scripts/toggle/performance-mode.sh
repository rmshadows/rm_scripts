#!/bin/bash
# 性能模式：关闭拖动实渲染与伪透明，减轻弱显卡负担

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

STATE="${HOME}/.fluxbox/config/performance.mode"
NORMAL="${HOME}/.fluxbox/config/performance.normal"

if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "on" ]; then
    # 恢复 eye-candy
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        key="${line%%=*}"
        val="${line#*=}"
        fluxbox_set_init "$key" "$val"
    done < "$NORMAL"
    echo off > "$STATE"
    msg="性能模式：关闭（已恢复透明/动效）"
else
    fluxbox_set_init "session.screen0.opaqueMove" "false"
    fluxbox_set_init "session.forcePseudoTransparency" "false"
    fluxbox_set_init "session.screen0.window.focus.alpha" "255"
    fluxbox_set_init "session.screen0.window.unfocus.alpha" "255"
    fluxbox_set_init "session.screen0.menu.alpha" "255"
    fluxbox_set_init "session.screen0.toolbar.alpha" "255"
    echo on > "$STATE"
    msg="性能模式：开启（拖动更流畅）"
fi

fluxbox_reconfigure
