#!/bin/bash

# 获取系统中所有的挂载点
MOUNT_POINTS=$(mount | grep -oP '(?<= on )[^ ]+')

# 检查是否有挂载点
if [ -z "$MOUNT_POINTS" ]; then
    echo "没有发现挂载点。"
    exit 1
fi

# 输出挂载点列表
echo "检测到以下挂载点："
i=1
for MOUNT_POINT in $MOUNT_POINTS; do
    echo "$i. $MOUNT_POINT"
    ((i++))
done

# 提示用户选择挂载点
read -p "请输入挂载点的编号进行检查: " choice

# 获取用户选择的挂载点
SELECTED_MOUNT_POINT=$(echo "$MOUNT_POINTS" | sed -n "${choice}p")

# 如果选择无效，退出
if [ -z "$SELECTED_MOUNT_POINT" ]; then
    echo "无效的选择。"
    exit 1
fi

echo "您选择的挂载点是: $SELECTED_MOUNT_POINT"

# 使用 lsof 检查占用挂载点的进程
echo "使用 lsof 检查占用挂载点的进程..."
lsof +D "$SELECTED_MOUNT_POINT" 2>/dev/null

# 如果 lsof 没有找到，可以尝试使用 fuser
if [ $? -ne 0 ]; then
    echo "尝试使用 fuser 检查占用挂载点的进程..."
    fuser -m "$SELECTED_MOUNT_POINT"
fi

