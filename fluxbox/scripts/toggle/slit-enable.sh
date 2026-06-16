#!/bin/bash
# Slit 停靠区开关：通过 alpha + autoHide 隐藏/显示

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

STATE="${HOME}/.fluxbox/config/slit.enabled"

if [ -f "$STATE" ] && [ "$(cat "$STATE")" = "on" ]; then
    fluxbox_set_init "session.screen0.slit.alpha" "0"
    fluxbox_set_init "session.screen0.slit.autoHide" "true"
    echo off > "$STATE"
    msg="Slit：关闭"
else
    fluxbox_set_init "session.screen0.slit.alpha" "255"
    fluxbox_set_init "session.screen0.slit.autoHide" "false"
    fluxbox_set_init "session.screen0.slit.onhead" "0"
    echo on > "$STATE"
    msg="Slit：开启"
fi

fluxbox_reconfigure
