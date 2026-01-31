#!/bin/bash
# 将 frp 管理页面的 nginx 片段写入 nginx 配置目录，不覆盖原机 site。
# 用户只需在自己的 site 里加一行 include。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNIPPET_SRC="$SCRIPT_DIR/frp-snippet.conf"
NGINX_SNIPPET="/etc/nginx/snippets/frp.conf"

# 由 frp.sh 传入或使用默认值（FRP Admin 默认端口 7500）
RUN_PORT="${RUN_PORT:-7500}"
REVERSE_PROXY_URL="${REVERSE_PROXY_URL:-/frp/}"

# 1. 确保 nginx snippets 目录存在
sudo mkdir -p /etc/nginx/snippets

# 2. 将片段写入 nginx 配置目录，并填入端口与路径
sudo sed -e "s|__RUN_PORT__|$RUN_PORT|g" \
    -e "s|__REVERSE_PROXY_URL__|$REVERSE_PROXY_URL|g" \
    "$SNIPPET_SRC" | sudo tee "$NGINX_SNIPPET" > /dev/null
echo "已写入 $NGINX_SNIPPET（$REVERSE_PROXY_URL -> 127.0.0.1:$RUN_PORT）"

# 3. 提示用户：只需在自己的 site 里加一行 include
echo ""
echo "=============================================="
echo "接下来您只需编辑一次自己的 site-enabled："
echo "在要用 frp 管理页面的那个 server { } 内加一行："
echo ""
echo "    include /etc/nginx/snippets/frp.conf;"
echo ""
echo "然后执行： sudo nginx -t && sudo systemctl reload nginx"
echo "=============================================="
