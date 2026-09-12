#!/bin/bash
# 写入 /etc/nginx/sites-available/linx.conf。不启用、不改 acme.conf / ssl.conf。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

RUN_PORT="${RUN_PORT:-8087}"
SITE_LISTEN="${SITE_LISTEN:-8083}"
# SITE_NAME：独立站 server_name + 证书文件名前缀，留空则不生成独立站点配置
SITE_NAME="${SITE_NAME:-}"

write_nginx_available_site "$SCRIPT_DIR/linx.conf.src" "linx.conf"
