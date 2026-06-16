#!/bin/bash
# 关机 / 重启（支持确认对话框与密码开关）

set -euo pipefail

ACTION="${1:-}"
CONF="${HOME}/.fluxbox/config/power.conf"

REQUIRE_CONFIRM=1
REQUIRE_PASSWORD=0
if [ -f "$CONF" ]; then
    # shellcheck source=/dev/null
    source "$CONF"
fi

case "$ACTION" in
    reboot|poweroff) ;;
    *)
        echo "用法: $0 reboot|poweroff" >&2
        exit 1
        ;;
esac

label="重启"
cmd_reboot="systemctl reboot"
cmd_poweroff="systemctl poweroff"
sudo_reboot="sudo shutdown -r now"
sudo_poweroff="sudo shutdown -P now"

if [ "$ACTION" = "poweroff" ]; then
    label="关机"
fi

if [ "$REQUIRE_CONFIRM" = "1" ] && command -v zenity >/dev/null 2>&1; then
    zenity --question --text="确认${label}？" --ok-label="${label}" --cancel-label="取消" || exit 0
fi

if [ "$REQUIRE_PASSWORD" = "1" ]; then
    if [ "$ACTION" = "reboot" ]; then
        exec sudo shutdown -r now
    else
        exec sudo shutdown -P now
    fi
else
    if [ "$ACTION" = "reboot" ]; then
        exec systemctl reboot
    else
        exec systemctl poweroff
    fi
fi
