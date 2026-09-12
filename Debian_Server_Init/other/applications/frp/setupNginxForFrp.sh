#!/bin/bash
# 写入 nginx 配置。两种模式（由 REVERSE_PROXY_PATH 决定）：
#   1. 子路径反代（REVERSE_PROXY_PATH 非空，如 /frp/）：
#      写 /etc/nginx/snippets/frp.conf，用户在主站 include。
#   2. 独立站点（REVERSE_PROXY_PATH 为空）：
#      写 /etc/nginx/sites-available/frp.conf，独立端口监听，sudo ngx-site 启用。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

RUN_PORT="${RUN_PORT:-7500}"
REVERSE_PROXY_PATH="${REVERSE_PROXY_PATH:-/frp/}"
SITE_LISTEN="${SITE_LISTEN:-7501}"

if [ -n "$REVERSE_PROXY_PATH" ]; then
    # ---- 子路径反代模式 ----
    write_nginx_snippet "$SCRIPT_DIR/frp.conf.src" "frp.conf"
    echo "已写入 /etc/nginx/snippets/frp.conf（子路径 $REVERSE_PROXY_PATH -> 127.0.0.1:$RUN_PORT）"
    echo "启用：在主站 server { } 内加 include /etc/nginx/snippets/frp.conf; 然后 sudo nginx -t && sudo systemctl reload nginx"
else
    # ---- 独立站点模式 ----
    write_nginx_available_site "$SCRIPT_DIR/frp-site.conf.src" "frp.conf"
    echo ""
    echo "独立站模式：监听 $SITE_LISTEN，反代 127.0.0.1:$RUN_PORT"
    echo "证书路径：/etc/ssl/\${SITE_NAME}.pem（用 generate_ssl_cert 生成，或手动放置）"
    echo "启用： sudo ngx-site"
fi
