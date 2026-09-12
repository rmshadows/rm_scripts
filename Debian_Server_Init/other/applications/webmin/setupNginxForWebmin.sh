#!/bin/bash
# 写入 /etc/nginx/sites-available/webmin.conf。不启用、不改 acme.conf / ssl.conf。
# 用户启用：sudo ngx-site

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

NEW_PORT="${NEW_PORT:-20001}"
SITE_LISTEN="${SITE_LISTEN:-2053}"
# SITE_NAME：独立站 server_name + 证书文件名前缀，留空则从 ssl.conf/acme.conf 读取
SITE_NAME="${SITE_NAME:-}"

write_nginx_available_site "$SCRIPT_DIR/webmin.conf.src" "webmin.conf"
