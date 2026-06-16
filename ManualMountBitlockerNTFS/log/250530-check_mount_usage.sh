#!/bin/bash

MOUNT_POINT="${1:-/media}"
# MOUNT_POINT="/media/bitlockermount"

echo "正在检查是否有进程占用挂载点：$MOUNT_POINT"
echo "------------------------------------------"

# 用 lsof 检查被占用情况
if ! command -v lsof &>/dev/null; then
    echo "请先安装 lsof：sudo apt install lsof"
    exit 1
fi

# 查找正在占用挂载点的进程
sudo lsof +f -- "$MOUNT_POINT"

# 如果没有输出，就表示没人占用
if [ $? -ne 0 ]; then
    echo "✅ 没有进程占用 $MOUNT_POINT，可以安全弹出。"
else
    echo "⚠️ 以上进程正在使用 $MOUNT_POINT，先关闭或杀掉再弹出磁盘。"
fi

