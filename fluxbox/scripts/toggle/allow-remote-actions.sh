#!/bin/bash
# 切换 session.screen0.allowRemoteActions（默认建议 true）

set -euo pipefail
source "${HOME}/.fluxbox/scripts/lib/fluxbox-init.sh"

fluxbox_toggle_init "session.screen0.allowRemoteActions" "true" "false"
fluxbox_reconfigure
