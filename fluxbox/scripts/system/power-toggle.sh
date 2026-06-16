#!/bin/bash
# 切换 power.conf 中的 REQUIRE_CONFIRM / REQUIRE_PASSWORD

set -euo pipefail

KEY="${1:-}"
CONF="${HOME}/.fluxbox/config/power.conf"

[ ! -f "$CONF" ] && exit 1

case "$KEY" in
    confirm)
        if grep -q '^REQUIRE_CONFIRM=1' "$CONF"; then
            sed -i 's/^REQUIRE_CONFIRM=.*/REQUIRE_CONFIRM=0/' "$CONF"
            msg="关机确认：关闭"
        else
            sed -i 's/^REQUIRE_CONFIRM=.*/REQUIRE_CONFIRM=1/' "$CONF"
            msg="关机确认：开启"
        fi
        ;;
    password)
        if grep -q '^REQUIRE_PASSWORD=1' "$CONF"; then
            sed -i 's/^REQUIRE_PASSWORD=.*/REQUIRE_PASSWORD=0/' "$CONF"
            msg="关机密码(sudo)：关闭（使用 systemctl + polkit）"
        else
            sed -i 's/^REQUIRE_PASSWORD=.*/REQUIRE_PASSWORD=1/' "$CONF"
            msg="关机密码(sudo)：开启"
        fi
        ;;
    *)
        echo "用法: $0 confirm|password" >&2
        exit 1
        ;;
esac

echo "$msg"
