#!/bin/bash
set -e

TARGET_FM="org.gnome.Nautilus.desktop"

# 1. 查看当前默认文件管理器
current=$(xdg-mime query default inode/directory)
echo "当前默认文件管理器: $current"

# 2. 询问是否更改
read -p "是否将默认文件管理器设置为 Nautilus? (y/N): " choice

# 3. 判断并设置
if [[ "$choice" =~ ^[Yy]$ ]]; then
    xdg-mime default "$TARGET_FM" inode/directory
    new_current=$(xdg-mime query default inode/directory)
    if [[ "$new_current" == "$TARGET_FM" ]]; then
        echo "✅ 已将默认文件管理器更改为 Nautilus"
    else
        echo "❌ 设置失败，当前为 $new_current"
    fi
else
    echo "ℹ️ 已取消更改"
fi
