#!/bin/bash
# 将 linx-server 的 nginx 片段写入 nginx 配置目录，不覆盖原机 site。
# 用户只需在自己的 site 里加一行 include。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNIPPET_SRC="$SCRIPT_DIR/linx-snippet.conf"
NGINX_SNIPPET="/etc/nginx/snippets/linx.conf"

# 端口：环境变量 RUN_PORT 或默认 8087
RUN_PORT="${RUN_PORT:-8087}"

# 1. 确保 nginx snippets 目录存在
sudo mkdir -p /etc/nginx/snippets

# 2. 将片段写入 nginx 配置目录，并填入端口
sudo sed "s|__RUN_PORT__|$RUN_PORT|g" "$SNIPPET_SRC" | sudo tee "$NGINX_SNIPPET" > /dev/null
echo "已写入 $NGINX_SNIPPET（fastcgi_pass 127.0.0.1:$RUN_PORT）"

# 3. 提示用户：只需在自己的 site 里加一行 include
echo ""
echo "=============================================="
echo "接下来您只需编辑一次自己的 site-enabled："
echo "在要用 linx 的那个 server { } 内加一行："
echo ""
echo "    include /etc/nginx/snippets/linx.conf;"
echo ""
echo "然后执行： sudo nginx -t && sudo systemctl reload nginx"
echo "=============================================="
