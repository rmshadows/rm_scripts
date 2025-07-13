#!/bin/bash

# =========================
# 远程打印 Bash 脚本
# 通过 IPP 协议发送 PDF 到电脑 B 的共享打印机
# =========================

REMOTE_IP="192.168.1.93"          # 电脑B的IP
PRINTER_NAME="NS1020"   # CUPS中显示的打印机名
FILE="$1"                          # 要打印的文件（PDF等）

if [ -z "$FILE" ] || [ ! -f "$FILE" ]; then
  echo "❌ 请输入有效的PDF文件路径"
  echo "用法: $0 文件路径"
  exit 1
fi

echo "📤 正在发送打印任务到 $REMOTE_IP/$PRINTER_NAME ..."
lpr -H "$REMOTE_IP" -P "$PRINTER_NAME" "$FILE"
