#!/bin/bash

FILE_PATH="$1"
REMOTE_IP="${2:-192.168.1.93}"
REMOTE_PORT=8081

if [ -z "$FILE_PATH" ]; then
  echo "❌ 请提供文件路径"
  echo "用法：$0 文件路径 [电脑B_IP]"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "❌ 文件不存在：$FILE_PATH"
  exit 1
fi

FILE_NAME=$(basename "$FILE_PATH")
ENCODED_NAME=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$FILE_NAME")

echo "📤 上传文件到 $REMOTE_IP ..."
curl -s -X POST --data-binary @"$FILE_PATH" "http://$REMOTE_IP:$REMOTE_PORT/upload?filename=$ENCODED_NAME"

echo "🖨️ 发送打印指令 ..."
curl -s -X POST "http://$REMOTE_IP:$REMOTE_PORT/print?filename=$ENCODED_NAME"

