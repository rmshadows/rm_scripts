#!/bin/bash
# 切换工具栏所在显示器 session.screen0.toolbar.onhead（0=主屏，1=副屏）

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

fluxbox_toggle_init "session.screen0.toolbar.onhead" "0" "1"
fluxbox_reconfigure
