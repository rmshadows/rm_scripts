#!/bin/bash
# 写入 /etc/nginx/snippets/goaccess.conf（主站子路径 /goaccess/ 提供报告目录）
# 用户在主站 server { } 内 include 一行即可；不改任何站点文件。
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../GlobalVariables.sh"
source "$SCRIPT_DIR/../Lib.sh"

REPORTS_DIR="$HOME/Applications/goaccess/reports"
mkdir -p "$REPORTS_DIR"

if [ ! -d /etc/nginx ]; then
  echo "未检测到 /etc/nginx，跳过。"
  exit 0
fi

sudo mkdir -p /etc/nginx/snippets
sudo sed "s|__REPORTS_DIR__|$REPORTS_DIR|g" "$SCRIPT_DIR/goaccess-snippet.conf.src" | sudo tee /etc/nginx/snippets/goaccess.conf >/dev/null
echo "已写入 /etc/nginx/snippets/goaccess.conf（/goaccess/ -> $REPORTS_DIR）"
echo "启用：在主站 server { } 内加一行  include /etc/nginx/snippets/goaccess.conf;"
echo "然后： sudo nginx -t && sudo systemctl reload nginx"
echo "访问： https://<你的域名>/goaccess/"
