#!/bin/bash
#
# 🖨️ 远程双面打印上传脚本
# 功能：上传 odd_debug.pdf 和 even_debug.pdf 并发送打印指令
# 使用配套服务端（支持 /upload 和 /print 接口）
#
# 用法：
#   ./remote_doubleSided.sh [远程IP] [端口]
# 示例：
#   ./remote_doubleSided.sh 192.168.1.93 8081
#

# ==== 配置 ====
REMOTE_IP="${1:-192.168.1.93}"
REMOTE_PORT="${2:-8081}"

ODD_FILE="odd_debug.pdf"
EVEN_FILE="even_debug.pdf"

ENABLE_EXTENSION_CHECK=true
ALLOWED_EXTENSIONS=("pdf")

# ==== 工具函数 ====

function check_extension() {
  local file="$1"
  local ext="${file##*.}"
  for allowed in "${ALLOWED_EXTENSIONS[@]}"; do
    if [[ "$ext" == "$allowed" ]]; then
      return 0
    fi
  done
  return 1
}

function upload_and_print() {
  local FILE="$1"
  local NAME="$2"

  if [ ! -f "$FILE" ]; then
    echo "❌ 文件不存在：$FILE"
    exit 1
  fi

  if $ENABLE_EXTENSION_CHECK; then
    if ! check_extension "$FILE"; then
      echo "❌ 不允许的文件扩展名：$FILE"
      echo "✅ 允许扩展名：${ALLOWED_EXTENSIONS[*]}"
      exit 1
    fi
  fi

  local FILE_NAME
  FILE_NAME=$(basename "$FILE")
  local ENCODED_NAME
  ENCODED_NAME=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$FILE_NAME")

  echo "📤 正在上传 $NAME ($FILE_NAME) 到 http://$REMOTE_IP:$REMOTE_PORT"
  curl -s -X POST --data-binary @"$FILE" "http://$REMOTE_IP:$REMOTE_PORT/upload?filename=$ENCODED_NAME"

  echo "🖨️ 发送 $NAME 打印指令 ..."
  curl -s -X POST "http://$REMOTE_IP:$REMOTE_PORT/print?filename=$ENCODED_NAME"
}

# ==== 主流程 ====

# 第一步：上传并打印奇数页
upload_and_print "$ODD_FILE" "奇数页"

echo
read -p "🖐️ 请将纸张翻面并放入打印机，然后按 Enter 继续..."

# 第二步：上传并打印偶数页
upload_and_print "$EVEN_FILE" "偶数页"

echo
echo "✅ 远程双面打印任务完成"

