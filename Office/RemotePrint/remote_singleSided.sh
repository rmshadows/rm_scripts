#!/bin/bash

# ========== 可配置项 ==========
REMOTE_PORT=8081
REMOTE_IP="${2:-192.168.1.93}"

ENABLE_EXTENSION_CHECK=true     # 是否启用扩展名检查
ALLOWED_EXTENSIONS=("pdf" "txt")  # 允许的扩展名（小写）
ENABLE_PRINT=true               # 是否自动发送打印指令

# ========== 参数检查 ==========
FILE_PATH="$1"

if [ -z "$FILE_PATH" ]; then
  echo "❌ 请提供文件路径"
  echo "用法：$0 文件路径 [电脑B_IP]"
  exit 1
fi

if [ ! -f "$FILE_PATH" ]; then
  echo "❌ 文件不存在：$FILE_PATH"
  exit 1
fi

# ========== 扩展名检查 ==========
EXT="${FILE_PATH##*.}"
EXT="${EXT,,}"  # 转小写

if $ENABLE_EXTENSION_CHECK; then
  VALID=false
  for allowed in "${ALLOWED_EXTENSIONS[@]}"; do
    if [ "$EXT" = "$allowed" ]; then
      VALID=true
      break
    fi
  done

  if ! $VALID; then
    echo "❌ 不允许的文件类型：.$EXT"
    echo "仅允许的扩展名为：${ALLOWED_EXTENSIONS[*]}"
    exit 1
  fi
fi

# ========== 上传文件 ==========
FILE_NAME=$(basename "$FILE_PATH")
ENCODED_NAME=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$FILE_NAME")

echo "📤 上传文件到 $REMOTE_IP ..."
UPLOAD_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST \
  --data-binary @"$FILE_PATH" "http://$REMOTE_IP:$REMOTE_PORT/upload?filename=$ENCODED_NAME")

if [ "$UPLOAD_RESPONSE" != "200" ]; then
  echo "❌ 上传失败，HTTP状态码：$UPLOAD_RESPONSE"
  exit 1
fi

echo "✅ 上传成功：$FILE_NAME"

# ========== 发送打印 ==========
if $ENABLE_PRINT; then
  echo "🖨️ 发送打印指令 ..."
  PRINT_RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST \
    "http://$REMOTE_IP:$REMOTE_PORT/print?filename=$ENCODED_NAME")

  if [ "$PRINT_RESPONSE" != "200" ]; then
    echo "❌ 打印失败，HTTP状态码：$PRINT_RESPONSE"
    exit 1
  fi

  echo "✅ 打印指令已发送"
fi

