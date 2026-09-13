#!/bin/bash
# 写入 /etc/nginx/sites-available/xui.conf。不启用、不改 acme.conf / ssl.conf。
# 用户启用：sudo ngx-site

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

# RUN_PORT：3x-ui 面板实际监听端口（由 3x-ui.sh 读取后传入）
RUN_PORT="${RUN_PORT:-2053}"
SITE_LISTEN="${SITE_LISTEN:-2053}"
# SITE_NAME：独立站 server_name + 证书文件名前缀，留空则从 ssl.conf/acme.conf 读取
SITE_NAME="${SITE_NAME:-}"

write_nginx_available_site "$SCRIPT_DIR/xui.conf.src" "xui.conf"
