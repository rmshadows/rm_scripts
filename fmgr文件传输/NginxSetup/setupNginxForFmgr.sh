#!/bin/bash
# 将 fmgr 的 nginx 片段写入 nginx 配置目录，并确保安装 php-fpm。
# 不覆盖原机 nginx 主配置、不删除 default、不写入新 site；用户只需在自己的 site 里加一行 include。

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FMGR_DIR="$(dirname "$SCRIPT_DIR")"
FMGR_PARENT="$(dirname "$FMGR_DIR")"
SNIPPET_SRC="$SCRIPT_DIR/fmgr-snippet.conf"
NGINX_SNIPPET="/etc/nginx/snippets/fmgr.conf"

# 1. 安装 php-fpm（fmgr 需要跑 PHP）
if ! command -v php-fpm &>/dev/null; then
    echo "安装 php-fpm（fmgr 需要）..."
    sudo apt update
    sudo apt install -y php-fpm
else
    echo "php-fpm 已安装。"
fi

# 2. 确保 nginx snippets 目录存在
sudo mkdir -p /etc/nginx/snippets

# 3. 将片段写入 nginx 配置目录，并填入 fmgr 父目录路径
sudo sed "s|__FMGR_PARENT__|$FMGR_PARENT|g" "$SNIPPET_SRC" | sudo tee "$NGINX_SNIPPET" > /dev/null
echo "已写入 $NGINX_SNIPPET（root = $FMGR_PARENT）"

# 4. 提示用户：只需在自己的 site 里加一行 include
echo ""
echo "=============================================="
echo "接下来您只需编辑一次自己的 site-enabled："
echo "在要用 fmgr 的那个 server { } 内加一行："
echo ""
echo "    include /etc/nginx/snippets/fmgr.conf;"
echo ""
echo "然后执行： sudo nginx -t && sudo systemctl reload nginx"
echo "=============================================="
