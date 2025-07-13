#!/bin/bash

# ========== 可配置项 ==========
REMOTE_IP="${1:-192.168.1.93}"
REMOTE_PORT=8081

# ========== 执行取消指令 ==========
echo "🛑 正在请求取消 $REMOTE_IP 上的所有打印任务..."

RESPONSE=$(curl -s -w "%{http_code}" -o /dev/null -X POST \
  "http://$REMOTE_IP:$REMOTE_PORT/cancel")

if [ "$RESPONSE" == "200" ]; then
  echo "✅ 所有打印任务已取消"
else
  echo "❌ 取消失败，HTTP 状态码：$RESPONSE"
  exit 1
fi
